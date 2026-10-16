--[[ ── Karts · el cliente ───────────────────────────────────────────────────

     Meterse en el kart que crea el servidor, la física de los turbos y de los
     golpes en MI kart, dibujar cajas, bandas, plátanos y misiles, y la ficha
     del HUD.

     Aquí no se decide la carrera: el puesto, las vueltas, qué sale de una
     caja y a quién le da un misil llegan del servidor. Lo que sí se hace aquí
     es lo que solo puede hacer el dueño de red de un vehículo: empujarlo en
     un turbo, frenarlo en la hierba, girarlo en un trompo. El servidor vigila
     que nadie corra más de la cuenta.

     Meterse en el kart y tenerlo a punto es lo mismo que en el derbi (ver
     client/juegos/derbi.lua). ]]

local C = Config.Juegos.karts
local T = C.Teclas
local TB = C.Turbo
local ID = 'karts'

local M = {}
local st = { token = 0 }

--- Lo que tenía el personaje antes de la partida, para dejarlo igual.
local original = {}

--- Los plátanos que hay puestos: [id] = { x, y, z, obj }. Fuera de `st`
--- porque llevan objetos del mundo que hay que borrar pase lo que pase.
local platanos = {}

local BLOQUEADOS = { 24, 25, 68, 69, 70, 91, 92, 99, 100, 104, 114, 140, 141, 142, 143, 257, 263, 264 }

local function Reset()
    st = {
        token = (st.token or 0) + 1,
        net = nil,
        buscando = false,
        congelado = nil,
        reafirmar = 0,
        cuenta = nil,
        -- la carrera
        circuito = nil,
        tope = 22.0,
        vueltas = 3,
        prog = 0,
        rutaIdx = 1,
        hierba = false,
        meta = nil,
        vueltaVista = 1,
        -- turbos
        turboHasta = 0, turboExtra = 0, turboNombre = nil,
        bandas = {},
        derrape = nil, derrapeNivel = 0,
        rebufo = 0,
        gasDesde = nil,
        -- objetos y golpes
        objeto = nil,
        cajas = {}, cajaPedida = 0,
        usarPedido = 0,
        golpeHasta = 0, giro = 0,
        lentoHasta = 0,
        quietoHasta = 0,
        volverListo = 0,
        escudos = {},
        misiles = {},
        ondas = {},
        rivales = {},
    }
end
Reset()

local function Activo() return Juego.activo and Juego.juego == ID end
local function Vivo() return Activo() and not Juego.eliminado end
local function Corriendo() return Juego.fase == 'carrera' or Juego.fase == 'meta' end

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

local function MiKart() return CocheDeNet(st.net) end

local function EsKart(veh)
    if veh == 0 then return false end
    if veh == MiKart() then return true end
    local ok, marca = pcall(function() return Entity(veh).state.kart end)
    return ok and marca ~= nil
end

local function Bajar()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 and EsKart(veh) then ClearPedTasksImmediately(ped) end
end

--[[ ── Conseguir el kart ──────────────────────────────────────────────────── ]]
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
    SetVehicleDoorsLocked(veh, 4)
    -- En una carrera de karts nada se rompe: ni chapa, ni motor, ni ruedas.
    SetEntityProofs(veh, true, true, true, true, true, true, true, true)
    SetVehicleTyresCanBurst(veh, false)
    SetVehicleStrong(veh, true)
    Opcional('SetDisableVehiclePetrolTankFires', veh, true)
    Opcional('SetDisableVehiclePetrolTankDamage', veh, true)
    Opcional('SetDisableVehicleEngineFires', veh, true)
    Opcional('SetVehicleCanLeakPetrol', veh, false)
    Opcional('SetVehicleCanLeakOil', veh, false)
    local color = tonumber((Juego.datosRonda or {}).color)
    if color then SetVehicleColours(veh, color, color) end
    SetVehicleOnGroundProperly(veh)
    SetVehicleEngineOn(veh, true, true, false)
    SetVehicleMaxSpeed(veh, st.tope)

    local congelar = not Corriendo()
    FreezeEntityPosition(veh, congelar)
    st.congelado = congelar

    SetPedConfigFlag(PlayerPedId(), 32, false)
end

local function Conseguir(sigue)
    st.buscando = true
    local hasta = GetGameTimer() + C.Coche.espera * 1000
    local veh = MiKart()
    while veh == 0 and GetGameTimer() < hasta do
        Wait(100)
        if not sigue() then return false end
        veh = MiKart()
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
        TriggerServerEvent('origen_games:karts:s:sinKart')
        Core.Aviso('Tu kart no aparece: pidiendo otro...', 'mal')
    end
    return ok
end

--[[ ── La pista ───────────────────────────────────────────────────────────── ]]

--- A cuántos metros está el kart de la línea central. Busca alrededor del
--- último punto conocido; si se ha perdido, en toda la vuelta.
local function DistanciaALaPista(c)
    local ruta = st.circuito and st.circuito.ruta
    if not ruta then return 0.0 end
    local n = #ruta

    local function Mirar(desde, hasta)
        local mejor, cual = 1e9, st.rutaIdx
        for k = desde, hasta do
            local i = ((k - 1) % n) + 1
            local p = ruta[i]
            local dx, dy = c.x - p[1], c.y - p[2]
            local d = dx * dx + dy * dy
            if d < mejor then mejor, cual = d, i end
        end
        return math.sqrt(mejor), cual
    end

    local d, i = Mirar(st.rutaIdx - 6, st.rutaIdx + 12)
    if d > 18.0 then d, i = Mirar(1, n) end
    st.rutaIdx = i
    return d
end

--- Las mismas puertas que cuenta el servidor, contadas aquí para pintar la
--- vuelta y la flecha sin esperar al estado. Manda el servidor: si no
--- coinciden, se toma lo suyo (M.Estado).
local function AvanzarPuertas(c)
    local puertas = st.circuito and st.circuito.puertas
    if not puertas or st.meta then return end
    for _ = 1, 3 do
        local p = puertas[(st.prog % #puertas) + 1]
        local dx, dy = c.x - p.x, c.y - p.y
        if math.sqrt(dx * dx + dy * dy) > C.Puertas.radio or math.abs(c.z - p.z) > 6.0 then break end
        st.prog = st.prog + 1
    end
end

local function VueltaActual()
    local n = st.circuito and #st.circuito.puertas or 1
    if st.prog <= 0 then return 1 end
    return math.min(st.vueltas, math.floor((st.prog - 1) / n) + 1)
end

--[[ ── Los turbos ─────────────────────────────────────────────────────────── ]]
local HUESOS_ESCAPE = { 'exhaust', 'exhaust_2' }

local function Escape(veh, segundos)
    CreateThread(function()
        local huesos = {}
        for _, nombre in ipairs(HUESOS_ESCAPE) do
            local i = GetEntityBoneIndexByName(veh, nombre)
            if i ~= -1 then huesos[#huesos + 1] = i end
        end
        for _ = 1, math.max(1, math.floor(segundos * 4)) do
            if not Activo() or not DoesEntityExist(veh) then return end
            UseParticleFxAssetNextCall('core')
            local h
            if #huesos > 0 then
                h = StartParticleFxLoopedOnEntityBone('veh_backfire', veh, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, huesos[1], 1.6, false, false, false)
            else
                h = StartParticleFxLoopedOnEntity('veh_backfire', veh, 0.0, -1.0, 0.1, 0.0, 0.0, 0.0, 1.6, false, false, false)
            end
            if h and h ~= 0 and h ~= -1 then StopParticleFxLooped(h, true) end
            Wait(250)
        end
    end)
end

--- Un turbo en MI kart. Si ya hay uno más fuerte en marcha, se alarga.
local function Turbo(segundos, extra, nombre)
    local ahora = GetGameTimer()
    local veh = MiKart()
    if veh == 0 or st.meta then return end
    st.turboHasta = math.max(st.turboHasta, ahora + math.floor(segundos * 1000))
    st.turboExtra = math.max(st.turboHasta > ahora and st.turboExtra or 0, extra)
    st.turboNombre = nombre
    AnimpostfxPlay('RaceTurbo', 0, false)
    Escape(veh, segundos)
end

--[[ ── Ganchos del núcleo ─────────────────────────────────────────────────── ]]
local function BorrarPlatanos()
    for _, p in pairs(platanos) do
        if p.obj and DoesEntityExist(p.obj) then DeleteEntity(p.obj) end
    end
    platanos = {}
end

function M.Empezar()
    Reset()
    local ped = PlayerPedId()
    original.parabrisas = GetPedConfigFlag(ped, 32, true)
    SetPlayerCanDoDriveBy(PlayerId(), false)
    RequestNamedPtfxAsset('core')
    RequestModel(GetHashKey(C.Platano.modelo))
end

function M.AntesDeRonda()
    BorrarPlatanos()
    Reset()
end

function M.Ronda(d)
    local datos = d.datos or {}
    st.net = st.net or tonumber(datos.coche)
    st.circuito = C.Circuitos[datos.circuito] or C.Circuitos.bennys
    st.tope = tonumber(datos.tope) or 22.0
    st.vueltas = tonumber(datos.vueltas) or 3
    st.objetos = datos.objetos ~= false
    st.rondaLista = Juego.ronda

    local sigue = NuevaBusqueda()
    st.buscando = true
    CreateThread(function() Conseguir(sigue) end)
    return false
end

function M.Fase(d)
    if not Vivo() then return end
    if d.fase == 'meta' and not st.meta then
        Core.Banner('¡Alguien ha llegado!', 'Último esfuerzo', ('Tienes %d segundos para cruzar la meta.'):format(d.segundos or 0), 2.5)
        return
    end
    if d.fase ~= 'carrera' then return end

    local veh = MiKart()
    if veh ~= 0 and NetworkHasControlOfEntity(veh) then
        FreezeEntityPosition(veh, false)
        st.congelado = false
        SetVehicleEngineOn(veh, true, true, false)
    end
    Core.Sonido('claxon')

    --[[ La salida: quien empieza a acelerar justo al final de la cuenta sale
         con turbo; quien se adelanta, cala. `gasDesde` lo apunta Frame. ]]
    local S = TB.salida
    local ahora = GetGameTimer()
    if st.gasDesde then
        local antes = ahora - st.gasDesde
        if antes <= S.desde and antes >= S.hasta then
            Turbo(S.segundos, S.extra, 'Salida perfecta')
            Core.Banner('¡Ya!', 'Salida perfecta', nil, 1.6)
            Core.Sonido('turbo')
            return
        elseif antes > S.desde then
            st.quietoHasta = ahora + S.calado
            Core.Banner('¡Ya!', 'Has calado', 'Te has adelantado con el gas.', 1.6)
            Core.Sonido('fallo')
            return
        end
    end
    Core.Banner('¡Ya!', '¡A correr!', nil, 1.6)
end

function M.Estado(d)
    local yo = d.yo or {}
    local prog = tonumber(yo.prog)
    -- Manda el servidor: si voy por detrás de él o muy por delante, lo suyo.
    if prog and (prog > st.prog or st.prog > prog + 3) then st.prog = prog end
    if yo.meta then st.meta = st.meta or {} end
end

local function Parar()
    st.turboHasta = 0
    st.token = st.token + 1
    st.buscando = false
    AnimpostfxStop('RaceTurbo')
    local veh = MiKart()
    if veh ~= 0 and NetworkHasControlOfEntity(veh) then
        FreezeEntityPosition(veh, true)
        st.congelado = true
    end
end

function M.FinRonda()
    Parar()
    BorrarPlatanos()
end

function M.Eliminado()
    st.token = st.token + 1
    st.turboHasta = 0
    st.buscando = false
    Bajar()
end

local function Limpieza()
    Bajar()
    BorrarPlatanos()
    AnimpostfxStop('RaceTurbo')
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
local function Evento(nombre, f)
    RegisterNetEvent('origen_games:karts:c:' .. nombre, function(d)
        if not Activo() then return end
        f(type(d) == 'table' and d or {})
    end)
end

Evento('kart', function(d)
    if not Vivo() then return end
    local net = tonumber(d.coche)
    if not net then return end

    local mismo = net == st.net
    st.net = net
    if st.rondaLista ~= Juego.ronda then return end
    local veh = MiKart()
    if mismo and (st.buscando or (veh ~= 0 and GetVehiclePedIsIn(PlayerPedId(), false) == veh)) then return end
    if Juego.fase ~= 'preparacion' and not Corriendo() then return end
    local sigue = NuevaBusqueda()
    st.buscando = true
    CreateThread(function() Conseguir(sigue) end)
end)

Evento('meter', function(d)
    if not Vivo() or st.buscando then return end
    local net = tonumber(d.coche)
    if net then st.net = net end
    local veh = MiKart()
    if veh == 0 then
        TriggerServerEvent('origen_games:karts:s:sinKart')
        return
    end
    local sigue = NuevaBusqueda()
    CreateThread(function()
        if Meter(veh, sigue) and sigue() then Preparar(veh, sigue) end
    end)
end)

--- El servidor me devuelve a la pista: mi kart a la última puerta, parado.
Evento('recolocar', function(d)
    if not Vivo() then return end
    local x, y, z, h = tonumber(d.x), tonumber(d.y), tonumber(d.z), tonumber(d.h)
    if not x or not y or not z then return end
    local veh = MiKart()
    local ahora = GetGameTimer()
    st.turboHasta, st.golpeHasta, st.derrape = 0, 0, nil
    st.quietoHasta = ahora + C.Recolocar.quieto
    st.volverListo = ahora + C.Recolocar.cada * 1000

    if veh ~= 0 and NetworkHasControlOfEntity(veh) then
        SetEntityCoordsNoOffset(veh, x, y, z + 0.6, false, false, false)
        SetEntityHeading(veh, (h or 0.0) + 0.0)
        SetEntityVelocity(veh, 0.0, 0.0, 0.0)
        SetVehicleOnGroundProperly(veh)
        if GetVehiclePedIsIn(PlayerPedId(), false) ~= veh then SetPedIntoVehicle(PlayerPedId(), veh, -1) end
    end
    st.rutaIdx = 1
    DistanciaALaPista(vector3(x, y, z))
    local TEXTO = { volcado = 'Habías volcado', perdido = 'Te habías salido del circuito', zona = 'Te habías salido de la zona' }
    Core.Aviso((TEXTO[d.motivo] or 'De vuelta a la pista') .. '.', 'info')
end)

Evento('vuelta', function(d)
    if not Vivo() then return end
    local vuelta, vueltas = tonumber(d.vuelta) or 1, tonumber(d.vueltas) or st.vueltas
    local ms = tonumber(d.tiempo) or 0
    local tiempo = ('%d:%02d.%d'):format(math.floor(ms / 60000), math.floor(ms / 1000) % 60, math.floor((ms % 1000) / 100))
    if vuelta >= vueltas then
        Core.Banner(tiempo, '¡Última vuelta!', nil, 2.2)
        Core.Sonido('alarma')
    else
        Core.Banner(tiempo, ('Vuelta %d de %d'):format(vuelta, vueltas), nil, 2.0)
        Core.Sonido('pase')
    end
end)

Evento('meta', function(d)
    local ms = tonumber(d.tiempo) or 0
    st.meta = { puesto = tonumber(d.puesto) or 0, tiempo = ms }
    st.turboHasta = 0
    st.objeto = nil
    AnimpostfxStop('RaceTurbo')
    Core.Sonido('corona')

    -- Unos metros de inercia y el kart se quita de en medio, para no ser un
    -- estorbo en la recta de meta mientras llegan los demás.
    local ronda = Juego.ronda
    CreateThread(function()
        Wait(2500)
        if not Activo() or Juego.ronda ~= ronda or not st.meta then return end
        local veh = MiKart()
        if veh ~= 0 and NetworkHasControlOfEntity(veh) then
            SetEntityVelocity(veh, 0.0, 0.0, 0.0)
            FreezeEntityPosition(veh, true)
            st.congelado = true
            SetEntityCollision(veh, false, false)
            SetEntityAlpha(veh, 90, false)
        end
    end)
end)

Evento('objeto', function(d)
    local def = C.Objetos[d.id]
    if not def then st.objeto = nil return end
    local ruleta = tonumber(d.ruleta) or 0
    st.objeto = { id = d.id, usos = tonumber(d.usos) or 1, listo = GetGameTimer() + ruleta }
    if ruleta > 0 then Core.Sonido('voto') end
end)

Evento('caja', function(d)
    local i = tonumber(d.i)
    if i then st.cajas[i] = GetGameTimer() + (tonumber(d.segundos) or C.Cajas.reaparece) * 1000 end
end)

Evento('turbo', function(d)
    local veh = CocheDeNet(d.coche)
    if d.id == Core.Yo() and Vivo() then
        Turbo(TB.objeto.segundos, TB.objeto.extra, 'Turbo')
    elseif veh ~= 0 then
        Escape(veh, TB.objeto.segundos)
    end
end)

Evento('platano', function(d)
    local id, x, y, z = tonumber(d.id), tonumber(d.x), tonumber(d.y), tonumber(d.z)
    if not id or not x or not y or not z then return end
    local p = { x = x, y = y, z = z, desde = GetGameTimer() }
    platanos[id] = p
    local modelo = GetHashKey(C.Platano.modelo)
    if HasModelLoaded(modelo) then
        local obj = CreateObjectNoOffset(modelo, x, y, z, false, false, false)
        if obj and obj ~= 0 then
            PlaceObjectOnGroundProperly(obj)
            FreezeEntityPosition(obj, true)
            SetEntityCollision(obj, false, false)
            p.obj = obj
        end
    end
end)

Evento('platanoFuera', function(d)
    local id = tonumber(d.id)
    local p = id and platanos[id]
    if not p then return end
    if p.obj and DoesEntityExist(p.obj) then DeleteEntity(p.obj) end
    platanos[id] = nil
end)

Evento('misil', function(d)
    local id = tonumber(d.id)
    if not id then return end
    local origen = CocheDeNet(d.cocheDe)
    local desde = origen ~= 0 and GetEntityCoords(origen) or nil
    local ahora = GetGameTimer()
    st.misiles[id] = {
        desde = desde, cocheA = tonumber(d.cocheA), tipo = d.tipo,
        sale = ahora, llega = ahora + (tonumber(d.segundos) or 2) * 1000,
    }
end)

Evento('impacto', function(d)
    local id = tonumber(d.id)
    if id then st.misiles[id] = nil end
    local x, y, z = tonumber(d.x), tonumber(d.y), tonumber(d.z)
    if x and y and z then
        -- Explosión de mentira: solo partículas (el anticheat escucha las de verdad).
        UseParticleFxAssetNextCall('core')
        StartParticleFxNonLoopedAtCoord('exp_grd_bzgas_smoke', x, y, z + 0.5, 0.0, 0.0, 0.0, 1.0, false, false, false)
        UseParticleFxAssetNextCall('core')
        StartParticleFxNonLoopedAtCoord('ent_dst_elec_fire_sp', x, y, z + 0.4, 0.0, 0.0, 0.0, 1.5, false, false, false)
    end
end)

Evento('escudo', function(d)
    local id = tonumber(d.id)
    if id then st.escudos[id] = { hasta = GetGameTimer() + (tonumber(d.segundos) or C.Escudo.segundos) * 1000, coche = tonumber(d.coche) } end
end)

Evento('onda', function(d)
    local x, y, z = tonumber(d.x), tonumber(d.y), tonumber(d.z)
    if not x or not y or not z then return end
    st.ondas[#st.ondas + 1] = { x = x, y = y, z = z, radio = tonumber(d.radio) or C.Onda.radio, desde = GetGameTimer() }
end)

--- Me han dado: trompo y unos segundos sin gas.
Evento('golpe', function(d)
    if not Vivo() or st.meta then return end
    local ahora = GetGameTimer()
    local segundos = tonumber(d.segundos) or C.Golpe.segundos
    st.golpeHasta = ahora + segundos * 1000
    st.turboHasta = 0
    st.derrape = nil
    AnimpostfxStop('RaceTurbo')
    local veh = MiKart()
    if veh ~= 0 and NetworkHasControlOfEntity(veh) then
        SetVehicleForwardSpeed(veh, GetEntitySpeed(veh) * C.Golpe.frenada)
        st.giro = (math.random(2) == 1) and 1 or -1
    end
    ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.25)
end)

Evento('golpeVisto', function(d)
    local veh = CocheDeNet(d.coche)
    if veh == 0 then return end
    local c = GetEntityCoords(veh)
    UseParticleFxAssetNextCall('core')
    StartParticleFxNonLoopedAtCoord('ent_dst_elec_fire_sp', c.x, c.y, c.z + 0.3, 0.0, 0.0, 0.0, 1.2, false, false, false)
end)

Evento('lento', function(d)
    if not Vivo() or st.meta then return end
    st.lentoHasta = GetGameTimer() + (tonumber(d.segundos) or C.Rayo.segundos) * 1000
    st.turboHasta = 0
    AnimpostfxStop('RaceTurbo')
end)

--[[ ── Cada fotograma ─────────────────────────────────────────────────────── ]]

--- Los colores del arcoíris de las cajas, según el reloj.
local function Arcoiris(ahora, fase)
    local t = (ahora / 400.0) + (fase or 0)
    return math.floor(127 + 127 * math.sin(t)), math.floor(127 + 127 * math.sin(t + 2.1)), math.floor(127 + 127 * math.sin(t + 4.2))
end

--[[ Hacia dónde mira un rumbo de GTA. Las flechas del suelo se orientan con el
     vector de dirección del marcador y tumbadas 90° en X: girarlas con la
     rotación en Z no hace nada una vez tumbadas (probado en el juego). ]]
local function Hacia(h)
    local r = math.rad(h or 0.0)
    return -math.sin(r), math.cos(r)
end

local function Dibujar(ahora, yo)
    local circuito = st.circuito
    if not circuito then return end

    -- Las cajas sorpresa: un interrogante que gira dentro de una burbuja.
    if st.objetos then
        for i, p in ipairs(circuito.cajas) do
            if (st.cajas[i] or 0) <= ahora then
                local dx, dy = yo.x - p.x, yo.y - p.y
                if dx * dx + dy * dy < 150.0 * 150.0 then
                    local r, g, b = Arcoiris(ahora, i)
                    local z = p.z + 1.0 + math.sin(ahora / 350.0 + i) * 0.12
                    DrawMarker(32, p.x, p.y, z, 0.0, 0.0, 0.0, 0.0, 0.0, (ahora / 8.0 + i * 40) % 360.0,
                        1.1, 1.1, 1.1, 255, 255, 255, 235, false, false, 2, false, nil, nil, false)
                    DrawMarker(28, p.x, p.y, z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        1.05, 1.05, 1.05, r, g, b, 95, false, false, 2, false, nil, nil, false)
                end
            end
        end
    end

    -- Las bandas de turbo: tres flechas en el suelo que apuntan hacia delante.
    for _, p in ipairs(circuito.turbos) do
        local dx, dy = yo.x - p.x, yo.y - p.y
        if dx * dx + dy * dy < 120.0 * 120.0 then
            local pulso = 170 + math.floor(70 * math.sin(ahora / 140.0))
            DrawMarker(1, p.x, p.y, p.z + 0.03, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                TB.banda.radio * 1.7, TB.banda.radio * 1.7, 0.12, 255, 150, 0, 120, false, false, 2, false, nil, nil, false)
            local dx, dy = Hacia(p.h)
            DrawMarker(22, p.x, p.y, p.z + 0.2, dx, dy, 0.0, 90.0, 0.0, 0.0,
                3.0, 3.0, 3.0, 255, 190, 20, pulso, false, false, 2, false, nil, nil, false)
            -- Desde el kart la cámara va baja y de lejos las flechas se ven de
            -- canto: la luz es lo que avisa de que ahí hay una banda.
            DrawLightWithRange(p.x, p.y, p.z + 0.8, 255, 150, 0, 7.0, 3.0)
        end
    end

    -- Los plátanos: el racimo y un aro amarillo para que se vean venir.
    for _, p in pairs(platanos) do
        DrawMarker(25, p.x, p.y, p.z - 0.2, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            1.6, 1.6, 1.0, 255, 220, 0, 200, false, false, 2, false, nil, nil, false)
        if not p.obj then
            DrawMarker(28, p.x, p.y, p.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                0.35, 0.35, 0.35, 255, 220, 0, 220, false, false, 2, false, nil, nil, false)
        end
    end

    -- Los misiles en vuelo: una bola que va del que dispara al objetivo.
    for id, m in pairs(st.misiles) do
        if ahora > m.llega + 800 then
            st.misiles[id] = nil
        else
            local blanco = CocheDeNet(m.cocheA)
            if blanco ~= 0 and m.desde then
                local a = GetEntityCoords(blanco)
                local t = math.min(1.0, (ahora - m.sale) / math.max(1, m.llega - m.sale))
                local x = m.desde.x + (a.x - m.desde.x) * t
                local y = m.desde.y + (a.y - m.desde.y) * t
                local z = m.desde.z + (a.z - m.desde.z) * t + 0.7
                local r, g, b = 255, 40, 40
                if m.tipo == 'azul' then
                    r, g, b = 40, 120, 255
                    z = z + math.sin(t * math.pi) * 10.0
                end
                DrawMarker(28, x, y, z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.55, 0.55, 0.55, r, g, b, 235, false, false, 2, false, nil, nil, false)
                DrawLightWithRange(x, y, z, r, g, b, 6.0, 4.0)
            end
        end
    end

    -- Los escudos: una burbuja alrededor del kart.
    for id, e in pairs(st.escudos) do
        if ahora > e.hasta then
            st.escudos[id] = nil
        else
            local veh = CocheDeNet(e.coche)
            if veh ~= 0 then
                local c = GetEntityCoords(veh)
                local r, g, b = Arcoiris(ahora, id)
                local alfa = (e.hasta - ahora < 1500) and (60 + math.floor(60 * math.sin(ahora / 60.0))) or 90
                DrawMarker(28, c.x, c.y, c.z + 0.2, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.6, 1.6, 1.3, r, g, b, alfa, false, false, 2, false, nil, nil, false)
            end
        end
    end

    -- Las ondas: un aro que se abre.
    for i = #st.ondas, 1, -1 do
        local o = st.ondas[i]
        local t = (ahora - o.desde) / 500.0
        if t >= 1.0 then
            table.remove(st.ondas, i)
        else
            local r = o.radio * 2.0 * t
            DrawMarker(1, o.x, o.y, o.z - 0.4, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, r, r, 1.2,
                120, 200, 255, math.floor(160 * (1.0 - t)), false, false, 2, false, nil, nil, false)
        end
    end

    -- La flecha de la siguiente puerta: en este circuito las pistas pasan
    -- unas junto a otras y sin ella es fácil equivocarse de carril.
    if not st.meta and Corriendo() then
        local puertas = circuito.puertas
        local p = puertas[((st.prog + 1) % #puertas) + 1]
        local dx, dy = Hacia(p.h)
        DrawMarker(21, p.x, p.y, p.z + 0.15, dx, dy, 0.0, 90.0, 0.0, 0.0,
            2.4, 2.4, 2.4, 216, 27, 85, 130, false, false, 2, false, nil, nil, false)
    end
end

function M.Frame(ahora)
    for _, c in ipairs(BLOQUEADOS) do DisableControlAction(0, c, true) end
    DisableControlAction(0, T.objeto.control, true)
    DisableControlAction(0, T.volver.control, true)
    DisablePlayerFiring(PlayerId(), true)

    if not Vivo() then return end
    local veh = MiKart()
    local ped = PlayerPedId()
    local yo = GetEntityCoords(veh ~= 0 and veh or ped)
    Dibujar(ahora, yo)

    -- La cuenta atrás: se apunta cuándo empieza a pisar el gas.
    if Juego.fase == 'preparacion' then
        if IsControlPressed(0, 71) then
            st.gasDesde = st.gasDesde or ahora
        else
            st.gasDesde = nil
        end
        return
    end

    if not Corriendo() or veh == 0 or GetVehiclePedIsIn(ped, false) ~= veh then return end
    if st.meta then
        DisableControlAction(0, 71, true)
        return
    end
    local mio = NetworkHasControlOfEntity(veh)

    -- Parado a la fuerza: calado en la salida o recién devuelto a la pista.
    if ahora < st.quietoHasta then
        DisableControlAction(0, 71, true)
        DisableControlAction(0, 72, true)
    end

    -- El trompo de un golpe.
    if ahora < st.golpeHasta then
        DisableControlAction(0, 71, true)
        DisableControlAction(0, 72, true)
        if mio and st.golpeHasta - ahora > (C.Golpe.segundos * 1000 - 900) and not IsEntityInAir(veh) then
            SetEntityAngularVelocity(veh, 0.0, 0.0, 7.0 * st.giro)
        end
        return
    end

    -- Usar el objeto.
    if IsDisabledControlJustPressed(0, T.objeto.control) and st.objeto and ahora >= st.objeto.listo and ahora >= st.usarPedido then
        st.usarPedido = ahora + 400
        TriggerServerEvent('origen_games:karts:s:usar')
    end

    -- Volver a la pista.
    if IsDisabledControlJustPressed(0, T.volver.control) and ahora >= st.volverListo then
        st.volverListo = ahora + C.Recolocar.cada * 1000
        TriggerServerEvent('origen_games:karts:s:volver')
    end

    local vel = GetEntitySpeed(veh)
    local enSuelo = not IsEntityInAir(veh)

    -- Las cajas: tocarlas es cosa de un fotograma; el servidor lo comprueba.
    if st.objetos and not st.objeto and ahora >= st.cajaPedida then
        for i, p in ipairs(st.circuito.cajas) do
            if (st.cajas[i] or 0) <= ahora then
                local dx, dy = yo.x - p.x, yo.y - p.y
                if dx * dx + dy * dy < C.Cajas.radio * C.Cajas.radio and math.abs(yo.z - p.z) < 3.0 then
                    st.cajaPedida = ahora + 500
                    -- Se da por cogida aquí para que desaparezca en el acto.
                    st.cajas[i] = ahora + 1500
                    TriggerServerEvent('origen_games:karts:s:caja', i)
                    break
                end
            end
        end
    end

    -- Los plátanos.
    for id, p in pairs(platanos) do
        if ahora - p.desde > C.Platano.armado and ahora >= (p.avisado or 0) then
            local dx, dy = yo.x - p.x, yo.y - p.y
            if dx * dx + dy * dy < C.Platano.radio * C.Platano.radio and math.abs(yo.z - p.z) < 3.0 then
                p.avisado = ahora + 1000
                TriggerServerEvent('origen_games:karts:s:platano', id)
            end
        end
    end

    -- Las bandas de turbo.
    for i, p in ipairs(st.circuito.turbos) do
        if ahora >= (st.bandas[i] or 0) then
            local dx, dy = yo.x - p.x, yo.y - p.y
            if dx * dx + dy * dy < TB.banda.radio * TB.banda.radio and math.abs(yo.z - p.z) < 3.0 then
                st.bandas[i] = ahora + TB.banda.cada
                Turbo(TB.banda.segundos, TB.banda.extra, 'Banda de turbo')
                Core.Sonido('turbo')
            end
        end
    end

    --[[ El derrape: freno de mano girando y con velocidad. Mientras se
         aguanta sube de nivel; al soltar, el turbo del nivel alcanzado.
         Chocar o quedarse parado lo pierde. ]]
    local D = TB.derrape
    local girando = math.abs(GetControlNormal(0, 59)) >= D.giroMin
    if IsControlPressed(0, T.derrape.control) and girando and vel >= D.velocidadMin and enSuelo and ahora >= st.lentoHasta then
        st.derrape = st.derrape or ahora
        local llevo = (ahora - st.derrape) / 1000.0
        local nivel = 0
        for n, def in ipairs(D.niveles) do
            if llevo >= def.tras then nivel = n end
        end
        if nivel ~= st.derrapeNivel then
            st.derrapeNivel = nivel
            if nivel > 0 then Core.Sonido('pase') end
        end
        if nivel > 0 then
            local c = GetOffsetFromEntityInWorldCoords(veh, 0.0, -0.9, -0.1)
            if nivel == 1 then DrawLightWithRange(c.x, c.y, c.z, 40, 140, 255, 2.5, 6.0)
            else DrawLightWithRange(c.x, c.y, c.z, 255, 130, 20, 3.0, 8.0) end
        end
    elseif st.derrape then
        local nivel = st.derrapeNivel
        st.derrape, st.derrapeNivel = nil, 0
        if nivel > 0 and vel >= D.velocidadMin * 0.6 and not HasEntityCollidedWithAnything(veh) then
            local def = D.niveles[nivel]
            Turbo(def.segundos, def.extra, def.nombre)
            Core.Sonido('turbo')
        end
    end

    -- El empuje del turbo: hacia delante, con las ruedas en el suelo y sin
    -- pasar del tope de la cilindrada más lo que da ese turbo.
    if st.turboHasta > ahora then
        if mio and enSuelo and vel < math.min(st.tope + st.turboExtra, TB.velocidadMaxima - 4.0) then
            ApplyForceToEntityCenterOfMass(veh, 1, 0.0, TB.fuerza * GetFrameTime(), 0.0, false, true, true, false)
        end
    elseif st.turboExtra > 0 then
        st.turboExtra = 0
        AnimpostfxStop('RaceTurbo')
    end
end

--[[ ── Cada 250 ms ────────────────────────────────────────────────────────── ]]
local function RefrescarRivales()
    local lista = {}
    local yo = Core.Yo()
    for _, fila in ipairs(Juego.marcador or {}) do
        if fila.vivo and fila.id ~= yo and fila.coche and not fila.meta then
            local veh = CocheDeNet(fila.coche)
            if veh ~= 0 then lista[#lista + 1] = { veh = veh, id = fila.id, nombre = fila.nombre } end
        end
    end
    st.rivales = lista
end

--- El rebufo: un rato pegado detrás de otro kart y en su misma dirección.
local function Rebufo(veh, vel)
    local R = TB.rebufo
    if vel < 10.0 or st.turboHasta > GetGameTimer() then st.rebufo = 0 return end
    local c, delante = GetEntityCoords(veh), GetEntityForwardVector(veh)
    local coseno = math.cos(math.rad(R.angulo))
    for _, r in ipairs(st.rivales) do
        if DoesEntityExist(r.veh) then
            local dif = GetEntityCoords(r.veh) - c
            local dist = #dif
            if dist > 3.0 and dist < R.distancia then
                local hacia = (dif.x * delante.x + dif.y * delante.y) / dist
                local suyo = GetEntityForwardVector(r.veh)
                if hacia >= coseno and (suyo.x * delante.x + suyo.y * delante.y) > 0.8 then
                    st.rebufo = st.rebufo + 0.25
                    if st.rebufo >= R.tras then
                        st.rebufo = 0
                        Turbo(R.segundos, R.extra, 'Rebufo')
                        Core.Sonido('turbo')
                    end
                    return
                end
            end
        end
    end
    st.rebufo = 0
end

function M.Lento(ahora)
    if not Vivo() then return end
    local fase = Juego.fase

    if fase == 'preparacion' then
        local n = Core.Resta(Juego.finFase)
        if n >= 1 and n <= 3 and st.cuenta ~= n and not IsScreenFadedOut() then
            st.cuenta = n
            Core.Banner('Preparados', tostring(n), nil, 0.9)
            Core.Sonido('cuenta')
        end
    end

    RefrescarRivales()

    local veh = MiKart()
    if veh == 0 then return end
    local ped = PlayerPedId()
    local dentro = GetVehiclePedIsIn(ped, false) == veh
    if dentro then SetPedConfigFlag(ped, 32, false) end

    if not NetworkHasControlOfEntity(veh) then
        if dentro then NetworkRequestControlOfEntity(veh) end
        return
    end

    -- Quieto salvo en carrera (y ya en meta, cuando se aparta).
    local congelar = not Corriendo() or (st.meta ~= nil and st.congelado == true)
    if st.congelado ~= congelar or (congelar and ahora >= st.reafirmar) then
        FreezeEntityPosition(veh, congelar)
        st.congelado = congelar
        st.reafirmar = ahora + 2000
    end

    if GetVehicleDoorLockStatus(veh) ~= 4 then SetVehicleDoorsLocked(veh, 4) end
    if GetVehicleFuelLevel(veh) < 30.0 then SetVehicleFuelLevel(veh, 100.0) end
    if GetVehicleEngineHealth(veh) < 900.0 then SetVehicleEngineHealth(veh, 1000.0) end
    if dentro and (Corriendo() or fase == 'preparacion') and not GetIsVehicleEngineRunning(veh) then
        SetVehicleEngineOn(veh, true, true, false)
    end

    if not Corriendo() or not dentro then return end

    local c = GetEntityCoords(veh)
    AvanzarPuertas(c)

    -- Vuelta nueva vista aquí: por si el aviso del servidor tarda.
    st.vueltaVista = VueltaActual()

    -- La hierba y el tope de velocidad de este momento.
    local fuera = DistanciaALaPista(c)
    st.hierba = fuera > (st.circuito.ancho / 2.0 + C.Hierba.margen)

    local enTurbo = st.turboHasta > ahora
    local conEscudo = st.escudos[Core.Yo()] ~= nil
    local tope = st.tope
    if st.meta then
        tope = 7.0
    elseif enTurbo then
        tope = math.min(st.tope + st.turboExtra, TB.velocidadMaxima - 3.0)
    else
        if st.hierba and not conEscudo then tope = tope * C.Hierba.factor end
        if ahora < st.lentoHasta then tope = tope * C.Rayo.factor end
    end
    SetVehicleMaxSpeed(veh, tope + 0.0)

    if not st.meta then Rebufo(veh, GetEntitySpeed(veh)) end
end

--[[ ── El HUD ─────────────────────────────────────────────────────────────── ]]
local RULETA = C.ObjetosOrden

local function TextoObjeto(ahora)
    local o = st.objeto
    if not o then return 'Sin objeto', nil, true end
    if ahora < o.listo then
        -- La ruleta: va pasando nombres hasta que se para en el bueno.
        local i = (math.floor(ahora / 110) % #RULETA) + 1
        return C.Objetos[RULETA[i]].nombre, '...', true
    end
    local def = C.Objetos[o.id]
    return def.nombre, o.usos > 1 and ('x' .. o.usos) or nil, false
end

local function Puesto()
    local yo = Juego.yo or {}
    return tonumber(yo.puesto) or 1, tonumber(yo.corredores) or #(Juego.marcador or {})
end

function M.Ficha()
    if Juego.eliminado then return nil end
    local ahora = GetGameTimer()
    local yo = Juego.yo or {}
    local puesto, total = Puesto()

    if st.meta then
        return {
            tono = 'prop', icono = 'corona',
            rol = 'En meta',
            nombre = ('%dº'):format(st.meta.puesto or puesto),
            renglon = 'Esperando a los demás',
            puntos = yo.puntos or 0,
        }
    end

    local veh = MiKart()
    local dentro = veh ~= 0 and GetVehiclePedIsIn(PlayerPedId(), false) == veh

    local renglon
    if not dentro and (Juego.fase == 'preparacion' or Corriendo()) then
        renglon = st.buscando and 'Buscando tu kart...' or 'Vuelve a tu kart'
    elseif ahora < st.golpeHasta then
        renglon = '¡Trompo!'
    elseif ahora < st.lentoHasta then
        renglon = 'Frenado por un rayo'
    elseif st.turboHasta > ahora then
        renglon = st.turboNombre or 'Turbo'
    elseif st.hierba and Corriendo() then
        renglon = 'Fuera de pista: vas frenado'
    else
        renglon = ('%d km/h'):format(veh ~= 0 and math.floor(GetEntitySpeed(veh) * 3.6) or 0)
    end

    -- La barra: el turbo que queda o, derrapando, lo que falta para el siguiente nivel.
    local barra
    if st.turboHasta > ahora then
        barra = { tipo = 'progreso', etiqueta = 'Turbo', pct = math.min(100, math.floor((st.turboHasta - ahora) / 26)), cifra = '' }
    elseif st.derrape then
        local llevo = (ahora - st.derrape) / 1000.0
        local ultimo = TB.derrape.niveles[#TB.derrape.niveles].tras
        barra = {
            tipo = 'progreso',
            etiqueta = st.derrapeNivel > 0 and TB.derrape.niveles[st.derrapeNivel].nombre or 'Derrape',
            pct = math.min(100, math.floor(llevo / ultimo * 100)),
            cifra = '',
        }
    end

    local nombreObjeto, extra, apagada = TextoObjeto(ahora)
    local acciones = {}
    if st.objetos ~= false then
        acciones[#acciones + 1] = { id = 'objeto', tecla = T.objeto.texto, nombre = nombreObjeto, extra = extra, apagada = apagada }
    end
    acciones[#acciones + 1] = { id = 'derrape', tecla = T.derrape.texto, nombre = 'Derrape', apagada = not Corriendo() }
    acciones[#acciones + 1] = { id = 'volver', tecla = T.volver.texto, nombre = 'Volver a pista', apagada = ahora < st.volverListo or not Corriendo() }

    return {
        tono = puesto == 1 and 'prop' or 'caza',
        icono = st.turboHasta > ahora and 'rayo' or 'coche',
        rol = ('Vuelta %d/%d'):format(st.vueltaVista or 1, st.vueltas),
        nombre = ('%dº de %d'):format(puesto, total),
        renglon = renglon,
        puntos = yo.puntos or 0,
        vida = barra,
        acciones = acciones,
    }
end

function M.Cartel()
    if Juego.eliminado then return nil end

    if Juego.fase == 'preparacion' then
        local nombre = st.circuito and st.circuito.nombre or 'Karts'
        return {
            k = ('Carrera %d de %d'):format(Juego.ronda or 0, Juego.rondas or 0),
            t = nombre,
            cifra = Core.Resta(Juego.finFase),
            m = ('%d vueltas. Acelera justo al final de la cuenta para salir con turbo.'):format(st.vueltas),
        }
    end

    if st.meta and Corriendo() then
        local ms = st.meta.tiempo or 0
        return {
            k = '¡Meta!',
            t = ('%dº'):format(st.meta.puesto or 0),
            m = ('Tu tiempo: %d:%02d.%d'):format(math.floor(ms / 60000), math.floor(ms / 1000) % 60, math.floor((ms % 1000) / 100)),
        }
    end

    if Corriendo() then
        local veh = MiKart()
        if veh == 0 and st.buscando then
            return { k = 'Un momento', t = 'Buscando tu kart', m = 'Si no aparece, te sacamos otro.' }
        elseif veh ~= 0 and math.abs(GetEntityRoll(veh)) > 100.0 then
            return { tipo = 'fuera', k = '¡Volcado!', t = 'Pulsa ' .. T.volver.texto, m = 'Te devolvemos a la pista.' }
        end
    end
    return nil
end

RegistrarJuego(ID, M)
