--[[ ── Derbi · el cliente ───────────────────────────────────────────────────

     Meterse en el coche que crea el servidor, tenerlo a punto (gasolina,
     motor, puertas, sin fuego), avisar de los choques, el turbo, las
     partículas de «destrozado» y la ficha del HUD. Quién queda fuera lo
     decide el servidor con la salud que lee de cada coche.

     Solo el dueño de red de un coche puede tocarlo (congelarlo, empujarlo,
     quitarle motor). El dueño es quien conduce: por eso cada jugador cuida
     SU coche y los demás solo lo miran. ]]

local C = Config.Juegos.derbi
local T = C.Teclas
local ID = 'derbi'

local M = {}
local st = { token = 0 }

--- Lo que tenía el personaje antes de la partida, para dejarlo igual.
local original = {}

--- Llamas de partículas en bucle que hay que apagar: [handle] = true.
local llamas = {}

--- Todo lo que sirve para disparar desde el coche o cambiar de asiento. Salir
--- del coche (75) y la F (23) ya los bloquea el núcleo.
local BLOQUEADOS = { 24, 25, 68, 69, 70, 91, 92, 99, 100, 104, 114, 140, 141, 142, 143, 257, 263, 264 }

local function Reset()
    st = {
        token = (st.token or 0) + 1,
        net = nil,
        nombre = nil,
        buscando = false,
        turboListo = 0,
        turboHasta = 0,
        turboTope = 0,
        turboPedido = 0,
        golpes = {},
        rivales = {},
        rotos = {},
        cuenta = nil,
        velPrev = nil,
        congelado = nil,
        reafirmar = 0,
    }
end
Reset()

local function Activo() return Juego.activo and Juego.juego == ID end
local function Vivo() return Activo() and not Juego.eliminado end

--- Una native que puede no estar en todas las builds: si no está, se salta.
local function Opcional(nombre, ...)
    local f = _G[nombre]
    if f then pcall(f, ...) end
end

local function CocheDeNet(net)
    net = tonumber(net)
    if not net or net == 0 or not NetworkDoesNetworkIdExist(net) then return 0 end
    local veh = NetToVeh(net)
    if veh ~= 0 and DoesEntityExist(veh) then return veh end
    return 0
end

local function MiCoche() return CocheDeNet(st.net) end

local function EsCocheDerbi(veh)
    if veh == 0 then return false end
    if veh == MiCoche() then return true end
    local ok, marca = pcall(function() return Entity(veh).state.derbi end)
    return ok and marca ~= nil
end

--- Saca al personaje de un coche del derbi, en el acto (las puertas van
--- cerradas por dentro y TaskLeaveVehicle no serviría).
local function Bajar()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 and EsCocheDerbi(veh) then
        ClearPedTasksImmediately(ped)
    end
end

--[[ ── Conseguir el coche ─────────────────────────────────────────────────────

     Cada búsqueda lleva su ficha (token): si llega otra (el servidor ha
     creado otro coche) o se acaba la ronda, la vieja se retira sola. Tras
     cada Wait se mira que siga siendo la buena. ]]
local function NuevaBusqueda()
    st.token = st.token + 1
    local token, ronda = st.token, Juego.ronda
    return function() return Vivo() and Juego.ronda == ronda and st.token == token end
end

local function Meter(veh, sigue)
    local ped = PlayerPedId()
    if GetVehiclePedIsIn(ped, false) == veh then return true end

    TaskWarpPedIntoVehicle(ped, veh, -1)
    local hasta = GetGameTimer() + 1500
    while GetVehiclePedIsIn(PlayerPedId(), false) ~= veh and GetGameTimer() < hasta do
        Wait(50)
        if not sigue() or not DoesEntityExist(veh) then return false end
    end
    if GetVehiclePedIsIn(PlayerPedId(), false) ~= veh then
        SetPedIntoVehicle(PlayerPedId(), veh, -1)
    end
    return GetVehiclePedIsIn(PlayerPedId(), false) == veh
end

--- Deja el coche listo. Hace falta ser su dueño de red: al sentarse al volante
--- pasa a serlo en unos fotogramas.
local function Preparar(veh, sigue)
    local hasta = GetGameTimer() + 1500
    while not NetworkHasControlOfEntity(veh) and GetGameTimer() < hasta do
        NetworkRequestControlOfEntity(veh)
        Wait(50)
        if not sigue() or not DoesEntityExist(veh) then return end
    end

    SetVehicleNeedsToBeHotwired(veh, false)
    SetVehicleHasBeenOwnedByPlayer(veh, true)
    SetVehicleFuelLevel(veh, 100.0)
    -- 4: cerrado con el conductor dentro. No se puede bajar.
    SetVehicleDoorsLocked(veh, 4)
    --[[ Nada de fuego ni de explosiones de verdad: el anticheat avisa a la
         primera explosión por minuto. El motor además se sujeta por encima de
         cero en Lento (por debajo, arde). ]]
    Opcional('SetDisableVehiclePetrolTankFires', veh, true)
    Opcional('SetDisableVehiclePetrolTankDamage', veh, true)
    Opcional('SetDisableVehicleEngineFires', veh, true)
    Opcional('SetVehicleCanLeakPetrol', veh, false)
    Opcional('SetVehicleCanLeakOil', veh, false)
    Opcional('SetVehicleExplodesOnHighExplosionDamage', veh, false)
    SetVehicleOnGroundProperly(veh)
    SetVehicleEngineOn(veh, true, true, false)

    local congelar = Juego.fase ~= 'derbi'
    FreezeEntityPosition(veh, congelar)
    st.congelado = congelar

    SetPedConfigFlag(PlayerPedId(), 32, false)
end

--- Espera a que el coche exista para este cliente, se mete y lo prepara. Si
--- no aparece a tiempo, pide al servidor que lo vuelva a mandar o a crear.
local function Conseguir(sigue)
    st.buscando = true
    local hasta = GetGameTimer() + C.Coche.espera * 1000
    local veh = MiCoche()
    while veh == 0 and GetGameTimer() < hasta do
        Wait(100)
        if not sigue() then return false end
        veh = MiCoche()
    end

    local ok = false
    if veh ~= 0 then
        ok = Meter(veh, sigue)
        if not sigue() then return false end
        if ok then Preparar(veh, sigue) end
        if not sigue() then return false end
    end

    st.buscando = false
    if not ok then
        TriggerServerEvent('origen_games:derbi:s:sinCoche')
        Core.Aviso('Tu coche no aparece: pidiendo otro...', 'mal')
    end
    return ok
end

--[[ ── Partículas ─────────────────────────────────────────────────────────── ]]
local HUESOS_ESCAPE = { 'exhaust', 'exhaust_2', 'exhaust_3', 'exhaust_4' }

--- Petardeo del escape durante el turbo. Solo partículas.
local function Escape(veh, segundos)
    CreateThread(function()
        local huesos = {}
        for _, nombre in ipairs(HUESOS_ESCAPE) do
            local i = GetEntityBoneIndexByName(veh, nombre)
            if i ~= -1 then huesos[#huesos + 1] = i end
        end
        for _ = 1, math.max(1, math.floor(segundos * 4)) do
            if not Activo() or not DoesEntityExist(veh) then return end
            if #huesos > 0 then
                for _, hueso in ipairs(huesos) do
                    UseParticleFxAssetNextCall('core')
                    local h = StartParticleFxLoopedOnEntityBone('veh_backfire', veh, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, hueso, 1.8, false, false, false)
                    if h and h ~= 0 and h ~= -1 then StopParticleFxLooped(h, true) end
                end
            else
                UseParticleFxAssetNextCall('core')
                local h = StartParticleFxLoopedOnEntity('veh_backfire', veh, 0.0, -2.2, 0.1, 0.0, 0.0, 0.0, 1.8, false, false, false)
                if h and h ~= 0 and h ~= -1 then StopParticleFxLooped(h, true) end
            end
            Wait(250)
            if not Activo() then return end
        end
    end)
end

local function ApagarLlamas()
    for h in pairs(llamas) do StopParticleFxLooped(h, false) end
    llamas = {}
end

--[[ ── Ganchos del núcleo ─────────────────────────────────────────────────── ]]
function M.Empezar()
    Reset()
    local ped = PlayerPedId()
    original.parabrisas = GetPedConfigFlag(ped, 32, true)
    SetPlayerCanDoDriveBy(PlayerId(), false)
    RequestNamedPtfxAsset('core')
end

function M.AntesDeRonda()
    Reset()
end

function M.Ronda(d)
    local datos = d.datos or {}
    -- Si mientras se teletransportaba llegó el aviso de que el coche ya
    -- existe, ese netId es el bueno (DatosRonda pudo no tenerlo aún).
    st.net = st.net or tonumber(datos.coche)
    st.nombre = st.nombre or datos.nombre
    st.rondaLista = Juego.ronda
    --[[ En su propio hilo: la preparación dura 5 s y esperar aquí dentro
         (hasta 8 s de coche más meterse y prepararlo) dejaría la pantalla en
         negro con la ronda ya empezada. El núcleo hace el fundido en el acto
         y el jugador ve aparecer su coche. Conseguir comprueba tras cada Wait
         que la partida y la ronda siguen (su ficha, NuevaBusqueda). ]]
    local sigue = NuevaBusqueda()
    st.buscando = true
    CreateThread(function() Conseguir(sigue) end)
    return false
end

function M.Fase(d)
    if d.fase ~= 'derbi' or not Vivo() then return end
    local veh = MiCoche()
    if veh ~= 0 and NetworkHasControlOfEntity(veh) then
        FreezeEntityPosition(veh, false)
        st.congelado = false
        SetVehicleEngineOn(veh, true, true, false)
    end
    Core.Banner('¡Ya!', '¡A chocar!', 'Deja a los demás sin motor. El último en marcha gana.', 2.2)
    Core.Sonido('claxon')
end

function M.FinRonda()
    st.turboHasta = 0
    st.token = st.token + 1
    st.buscando = false
    local veh = MiCoche()
    if veh ~= 0 and NetworkHasControlOfEntity(veh) then
        FreezeEntityPosition(veh, true)
        st.congelado = true
    end
end

function M.Eliminado()
    st.token = st.token + 1
    st.turboHasta = 0
    st.buscando = false
    -- Antes de que el núcleo lo suba a mirar: fuera del coche (que se queda
    -- humeando hasta que lo borra el servidor).
    Bajar()
end

local function Limpieza()
    Bajar()
    ApagarLlamas()
    -- Salir y Restaurar llaman los dos: se devuelve una sola vez.
    if original.parabrisas ~= nil then
        SetPedConfigFlag(PlayerPedId(), 32, original.parabrisas)
        original.parabrisas = nil
    end
    SetPlayerCanDoDriveBy(PlayerId(), true)
    Reset()
end
M.Salir = Limpieza
M.Restaurar = Limpieza

function M.BlancoEspectador(fila)
    local veh = CocheDeNet(fila.coche)
    return veh ~= 0 and veh or nil
end

--[[ ── Lo que llega del servidor ──────────────────────────────────────────── ]]

--- El netId de mi coche (al aparecer para el servidor, o uno nuevo).
RegisterNetEvent('origen_games:derbi:c:coche', function(d)
    if not Vivo() or type(d) ~= 'table' then return end
    local net = tonumber(d.coche)
    if not net then return end
    if type(d.nombre) == 'string' then st.nombre = d.nombre end

    local mismo = net == st.net
    st.net = net
    -- Aún en el fundido de la ronda (antes de M.Ronda): basta con apuntarlo,
    -- que meterse ahora sería antes del teletransporte.
    if st.rondaLista ~= Juego.ronda then return end
    local veh = MiCoche()
    if mismo and (st.buscando or (veh ~= 0 and GetVehiclePedIsIn(PlayerPedId(), false) == veh)) then
        return
    end
    if Juego.fase ~= 'preparacion' and Juego.fase ~= 'derbi' then return end
    local sigue = NuevaBusqueda()
    st.buscando = true
    CreateThread(function() Conseguir(sigue) end)
end)

--- Llevo un rato fuera de mi coche: adentro otra vez.
RegisterNetEvent('origen_games:derbi:c:meter', function(d)
    if not Vivo() or st.buscando then return end
    local net = type(d) == 'table' and tonumber(d.coche)
    if net then st.net = net end
    local veh = MiCoche()
    if veh == 0 then
        TriggerServerEvent('origen_games:derbi:s:sinCoche')
        return
    end
    local sigue = NuevaBusqueda()
    CreateThread(function()
        if Meter(veh, sigue) and sigue() then Preparar(veh, sigue) end
    end)
end)

local function QuitarMotor(dano)
    dano = tonumber(dano)
    if not dano or dano <= 0 then return end
    local veh = MiCoche()
    if veh == 0 or st.rotos[st.net] or not NetworkHasControlOfEntity(veh) then return end
    SetVehicleEngineHealth(veh, math.max(1.0, GetVehicleEngineHealth(veh) - dano) + 0.0)
end

--- Me han dado un golpe que cuenta: el motor sufre algo más de lo que dice
--- GTA, para que las rondas no se eternicen.
RegisterNetEvent('origen_games:derbi:c:golpeado', function(d)
    if not Vivo() or Juego.fase ~= 'derbi' or type(d) ~= 'table' then return end
    QuitarMotor(d.dano)
end)

--- Un segundo más fuera de la zona.
RegisterNetEvent('origen_games:derbi:c:fueraZona', function(d)
    if not Vivo() or Juego.fase ~= 'derbi' or type(d) ~= 'table' then return end
    QuitarMotor(d.dano)
end)

RegisterNetEvent('origen_games:derbi:c:turbo', function(d)
    if not Activo() or type(d) ~= 'table' then return end
    local veh = CocheDeNet(d.coche)
    local segundos = tonumber(d.segundos) or C.Turbo.segundos

    if d.id == Core.Yo() and Vivo() then
        local ahora = GetGameTimer()
        st.turboListo = ahora + C.Turbo.enfriamiento * 1000
        st.turboHasta = ahora + segundos * 1000
        local vel = veh ~= 0 and GetEntitySpeed(veh) or 0.0
        st.turboTope = math.min(vel + C.Turbo.subida, C.Turbo.maxima)
    end

    if veh ~= 0 then Escape(veh, segundos) end
end)

--- Un coche destrozado: explosión de mentira (partículas) y llamas que no
--- queman. Su dueño además apaga el motor y lo deja humeando.
RegisterNetEvent('origen_games:derbi:c:roto', function(d)
    if not Activo() or type(d) ~= 'table' then return end
    local net = tonumber(d.coche)
    if net then st.rotos[net] = true end
    local veh = CocheDeNet(net)

    if d.id == Core.Yo() and veh ~= 0 and NetworkHasControlOfEntity(veh) then
        st.turboHasta = 0
        SetVehicleEngineOn(veh, false, true, true)
        SetVehicleUndriveable(veh, true)
        Opcional('SetDisableVehicleEngineFires', veh, true)
        -- Motor muy bajo pero por encima de cero: humo negro sin llegar a arder.
        SetVehicleEngineHealth(veh, 5.0)
    end

    local x, y, z = tonumber(d.x), tonumber(d.y), tonumber(d.z)
    if x and y and z then
        UseParticleFxAssetNextCall('core')
        StartParticleFxNonLoopedAtCoord('exp_grd_train', x, y, z + 0.4, 0.0, 0.0, 0.0, 0.7, false, false, false)
        UseParticleFxAssetNextCall('core')
        StartParticleFxNonLoopedAtCoord('exp_grd_bzgas_smoke', x, y, z + 0.8, 0.0, 0.0, 0.0, 1.2, false, false, false)
    end

    if veh ~= 0 then
        UseParticleFxAssetNextCall('core')
        local llama = StartParticleFxLoopedOnEntity('ent_ray_paleto_gas_flames', veh, 0.0, 1.0, 0.5, 0.0, 0.0, 0.0, 0.7, false, false, false)
        if llama and llama ~= 0 then
            llamas[llama] = true
            SetTimeout((C.Coche.borrarTras + 1) * 1000, function()
                if llamas[llama] then
                    llamas[llama] = nil
                    StopParticleFxLooped(llama, false)
                end
            end)
        end
    end
end)

--[[ ── Los choques ───────────────────────────────────────────────────────────

     Cada cliente mira solo SU coche: si toca a un rival y se acercaban con
     velocidad, avisa, vaya él rápido o esté parado. El servidor decide quién
     embestía (con las velocidades que ve él) y usa el aviso del que recibe
     para confirmar el golpe. Se usan las velocidades del fotograma anterior
     al contacto: en el del contacto ya han frenado. ]]
local function Choques(ahora, veh)
    local miVel = GetEntityVelocity(veh)
    local previa = st.velPrev
    st.velPrev = miVel
    if previa and #previa > #miVel then miVel = previa end

    local antes = st.velRivales or {}
    local ahoraVel = {}
    local mi = GetEntityCoords(veh)
    for _, r in ipairs(st.rivales) do
        if not st.rotos[r.net] and DoesEntityExist(r.veh) then
            local suVel = GetEntityVelocity(r.veh)
            ahoraVel[r.net] = suVel
            local suPrevia = antes[r.net]
            if suPrevia and #suPrevia > #suVel then suVel = suPrevia end

            if ahora >= (st.golpes[r.net] or 0) then
                local dif = GetEntityCoords(r.veh) - mi
                local dist = #dif
                if dist > 0.1 and dist < 7.0 and IsEntityTouchingEntity(veh, r.veh) then
                    local dx, dy, dz = dif.x / dist, dif.y / dist, dif.z / dist
                    local acerca = (miVel.x * dx + miVel.y * dy + miVel.z * dz)
                        - (suVel.x * dx + suVel.y * dy + suVel.z * dz)
                    if acerca >= C.Golpe.velocidadMin then
                        st.golpes[r.net] = ahora + 600
                        TriggerServerEvent('origen_games:derbi:s:golpe', r.net, acerca)
                    end
                end
            end
        end
    end
    st.velRivales = ahoraVel
end

--[[ ── Cada fotograma ─────────────────────────────────────────────────────── ]]
function M.Frame(ahora)
    for _, c in ipairs(BLOQUEADOS) do DisableControlAction(0, c, true) end
    DisableControlAction(0, T.turbo.control, true)
    DisablePlayerFiring(PlayerId(), true)

    if not Vivo() or Juego.fase ~= 'derbi' then st.velPrev = nil return end
    local veh = MiCoche()
    if veh == 0 or st.rotos[st.net] or GetVehiclePedIsIn(PlayerPedId(), false) ~= veh then
        st.velPrev = nil
        return
    end

    if IsDisabledControlJustPressed(0, T.turbo.control) and ahora >= st.turboListo and ahora >= st.turboPedido then
        -- Hasta que conteste el servidor no se vuelve a pedir.
        st.turboPedido = ahora + 1000
        TriggerServerEvent('origen_games:derbi:s:turbo')
    end

    --[[ El turbo: empuje hacia delante mientras dure, solo con las ruedas en
         el suelo y sin pasar del tope de velocidad (que no salga volando). ]]
    if st.turboHasta > ahora and NetworkHasControlOfEntity(veh) and not IsEntityInAir(veh)
        and GetEntitySpeed(veh) < st.turboTope then
        ApplyForceToEntityCenterOfMass(veh, 1, 0.0, C.Turbo.fuerza * GetFrameTime(), 0.0, false, true, true, false)
    end

    Choques(ahora, veh)
end

--[[ ── Cada 250 ms ────────────────────────────────────────────────────────── ]]
local function RefrescarRivales()
    local lista = {}
    local yo = Core.Yo()
    for _, fila in ipairs(Juego.marcador or {}) do
        if fila.vivo and fila.id ~= yo and fila.coche and not st.rotos[fila.coche] then
            local veh = CocheDeNet(fila.coche)
            if veh ~= 0 then lista[#lista + 1] = { net = fila.coche, veh = veh, id = fila.id } end
        end
    end
    st.rivales = lista
end

function M.Lento(ahora)
    if not Vivo() then return end
    local fase = Juego.fase

    -- La cuenta atrás de la salida.
    if fase == 'preparacion' then
        local n = Core.Resta(Juego.finFase)
        if n >= 1 and n <= 3 and st.cuenta ~= n and not IsScreenFadedOut() then
            st.cuenta = n
            Core.Banner('Preparados', tostring(n), nil, 0.9)
            Core.Sonido('cuenta')
        end
    end

    RefrescarRivales()

    -- Mi coche, a punto.
    local veh = MiCoche()
    if veh == 0 or st.rotos[st.net] then return end
    local ped = PlayerPedId()
    local dentro = GetVehiclePedIsIn(ped, false) == veh
    -- origen_admin y el cinturón lo vuelven a encender al entrar en un coche.
    if dentro then SetPedConfigFlag(ped, 32, false) end

    if not NetworkHasControlOfEntity(veh) then
        if dentro then NetworkRequestControlOfEntity(veh) end
        return
    end

    -- Quieto salvo en el derbi. Solo al cambiar (y se reafirma de vez en
    -- cuando mientras toca estar quieto, por si cambió de dueño).
    local congelar = fase ~= 'derbi'
    if st.congelado ~= congelar or (congelar and ahora >= st.reafirmar) then
        FreezeEntityPosition(veh, congelar)
        st.congelado = congelar
        st.reafirmar = ahora + 2000
    end

    if GetVehicleDoorLockStatus(veh) ~= 4 then SetVehicleDoorsLocked(veh, 4) end
    if GetVehicleEngineHealth(veh) < 1.0 then SetVehicleEngineHealth(veh, 1.0) end
    if GetVehiclePetrolTankHealth(veh) < 200.0 then SetVehiclePetrolTankHealth(veh, 1000.0) end
    if GetVehicleFuelLevel(veh) < 30.0 then SetVehicleFuelLevel(veh, 100.0) end
    if dentro and (fase == 'derbi' or fase == 'preparacion') and not GetIsVehicleEngineRunning(veh) then
        SetVehicleEngineOn(veh, true, true, false)
    end
end

--[[ ── El HUD ─────────────────────────────────────────────────────────────── ]]
local function EnMarcha()
    for _, c in ipairs(Juego.contadores or {}) do
        if c.k == 'En marcha' then return tonumber(c.v) or 0 end
    end
    return 0
end

function M.Ficha()
    if Juego.eliminado then return nil end
    local yo = Juego.yo or {}
    local ahora = GetGameTimer()

    local veh = MiCoche()
    -- Lo que marca mi motor, sin pasar de la vida lógica del servidor.
    local motor = veh ~= 0 and GetVehicleEngineHealth(veh) or (tonumber(yo.motor) or 1000.0)
    if tonumber(yo.vida) then motor = math.min(motor, tonumber(yo.vida)) end
    motor = math.max(0.0, math.min(1000.0, motor))
    local pct = math.floor(motor / 10)

    local dentro = veh ~= 0 and GetVehiclePedIsIn(PlayerPedId(), false) == veh
    local n = math.max(0, EnMarcha() - 1)
    local renglon
    if not dentro and (Juego.fase == 'preparacion' or Juego.fase == 'derbi') then
        renglon = st.buscando and 'Buscando tu coche...' or 'Vuelve a tu coche'
    else
        renglon = n == 1 and '1 rival en marcha' or (n .. ' rivales en marcha')
    end

    local enTurbo = st.turboHasta > ahora
    local quedan = Core.Resta(st.turboListo)
    local carga = (quedan > 0 and not enTurbo) and (1 - quedan / C.Turbo.enfriamiento) or nil

    return {
        tono = 'caza', icono = 'coche',
        rol = 'Derbi',
        nombre = st.nombre or 'Tu coche',
        renglon = renglon,
        puntos = yo.puntos or 0,
        vida = { tipo = 'barra', etiqueta = 'Motor', pct = pct, cifra = tostring(math.floor(motor)), mal = pct < 30 },
        acciones = {
            {
                id = 'turbo', tecla = T.turbo.texto,
                nombre = enTurbo and '¡Turbo!' or 'Turbo',
                extra = (quedan > 0 and not enTurbo) and (quedan .. 's') or nil,
                apagada = Juego.fase ~= 'derbi' or (quedan > 0 and not enTurbo),
                carga = carga,
            },
            { id = 'claxon', tecla = 'E', nombre = 'Claxon' },
        },
    }
end

function M.Cartel()
    if Juego.eliminado then return nil end

    if Juego.fase == 'preparacion' then
        return {
            k = ('Ronda %d de %d'):format(Juego.ronda or 0, Juego.rondas or 0),
            t = st.nombre and ('Derbi · ' .. st.nombre) or 'Derbi',
            cifra = Core.Resta(Juego.finFase),
            m = ('Deja a los demás sin motor. %s: turbo. Si vuelcas o te sales de la zona, lo pagas.'):format(T.turbo.texto),
        }
    end

    if Juego.fase == 'derbi' then
        local veh = MiCoche()
        if veh ~= 0 and not st.rotos[st.net] then
            if math.abs(GetEntityRoll(veh)) > 110.0 then
                return { tipo = 'fuera', k = '¡Volcado!', t = 'Dale la vuelta', m = 'Mueve el coche a los lados. Si sigues así unos segundos, quedas fuera.' }
            end
        elseif veh == 0 and st.buscando then
            return { k = 'Un momento', t = 'Buscando tu coche', m = 'Si no aparece, te sacamos otro.' }
        end
    end
    return nil
end

RegistrarJuego(ID, M)
