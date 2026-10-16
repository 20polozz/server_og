-- ========================================
-- CLIENTE: CONTRARRELOJ (a solas, contra un fantasma)
-- ========================================

--[[ Lo del cliente de la contrarreloj (el servidor esta en
     server/contrarreloj.lua):

       1. La ficha del circuito pide «Contrarreloj» (preparar). Si estas lejos
          de la salida, se marca en el GPS; al llegar al volante y despacio,
          se pide empezar. El fantasma elegido llega antes, latente.
       2. La salida la manda el servidor y se corre con el flujo de siempre
          (racing:startRaceCountdown de client/racing.lua), con el fantasma
          metido en los datos: la reproduccion es la misma de los records.
       3. Mientras corres, la diferencia con el fantasma en cada checkpoint
          (sacada de DatosHudCarrera, sin tocar los hilos de la carrera) y en
          cada vuelta (con el tiempo del servidor).
       4. En la meta, el resultado del servidor con «Repetir» y «Salir».
          Mantener Retroceso vuelve a empezar desde la salida en cualquier
          momento. ]]

--- Mantener la tecla de reintentar este tiempo (ms) para que no salte sola.
local MANTENER_REINTENTO = 1000
--- Por debajo de esta velocidad (m/s) se puede empezar en la salida.
local VELOCIDAD_SALIDA = 8.0

local sesion = nil        -- la contrarreloj en curso (ver Preparar)
local fantasmas = {}      -- [token] = texto JSON del fantasma que ha mandado el servidor
local misMejores = {}     -- [circuitId] = ms de tu mejor vuelta, o false si no tienes

local function avisar(titulo, texto, tipo, ms)
    lib.notify({ title = titulo, description = texto, type = tipo or 'inform', duration = ms or 5000 })
end

local function alVolante()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    return veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped and veh or nil
end

--- Tu mejor vuelta en un circuito: ms, false si no tienes, nil si no se sabe.
--- La mira FantasmaMejora (client/racing.lua) para mandar tu fantasma.
function MiMejorVueltaEn(circuitId)
    circuitId = tonumber(circuitId)
    if not circuitId then return nil end
    return misMejores[circuitId]
end

-- En las carreras normales tambien: se pregunta al salir, sin esperar.
RegisterNetEvent('racing:startRaceCountdown', function(data)
    if type(data) ~= 'table' or data.prueba or data.contrarreloj or data.copiloto then return end
    local id = tonumber(data.circuitId)
    if not id then return end
    CreateThread(function()
        local ok, r = pcall(lib.callback.await, 'racing:contrarreloj:miMejor', false, { circuitId = id })
        if ok and r ~= nil then misMejores[id] = r end
    end)
end)

-- ── El fantasma ─────────────────────────────────────────────────────────────

RegisterNetEvent('racing:contrarreloj:fantasma', function(d)
    if type(d) ~= 'table' or not d.token or type(d.datos) ~= 'string' then return end
    fantasmas = { [d.token] = d.datos }   -- solo el ultimo
end)

--[[ Cuando pasa el fantasma por cada checkpoint, en tiempo de su vuelta: el
     fotograma mas cercano a cada uno, buscando siempre hacia delante (en un
     circuito que se cruza consigo mismo, el punto mas cercano de toda la
     vuelta podria ser el de otro tramo). ]]
local function TiemposDelFantasma(texto, checkpoints)
    if type(texto) ~= 'string' or type(checkpoints) ~= 'table' then return nil end
    local ok, g = pcall(json.decode, texto)
    local frames = ok and type(g) == 'table' and g.frames
    if type(frames) ~= 'table' or #frames < 2 then return nil end

    local tiempos = { total = tonumber(frames[#frames].t) }
    local desde = 1
    for k = 2, #checkpoints do
        local cp = checkpoints[k]
        local punto = vector3(cp.coord_x + 0.0, cp.coord_y + 0.0, cp.coord_z + 0.0)
        local mejor, mejorJ = math.huge, nil
        for j = desde, #frames do
            local f = frames[j]
            local d = #(vector3(f.x + 0.0, f.y + 0.0, f.z + 0.0) - punto)
            if d < mejor then mejor, mejorJ = d, j end
            -- Ya paso cerca y se esta alejando: este checkpoint esta visto.
            if mejor < 45.0 and d > mejor + 150.0 then break end
        end
        if mejorJ and mejor < 60.0 then
            tiempos[k] = tonumber(frames[mejorJ].t)
            desde = mejorJ
        end
    end
    return tiempos
end

-- ── Salir y limpiar ─────────────────────────────────────────────────────────

local function Cerrar(texto, tipo)
    local s = sesion
    sesion = nil
    fantasmas = {}
    if s and s.estado == 'yendo' then SetWaypointOff() end
    if EnCarrera() then
        LimpiarCarrera()
        TriggerEvent('racing:localRaceFinished')
    end
    SendNUIMessage({ action = 'contrarreloj:fin' })
    SoltarFocoCarreras(false)
    if texto then avisar('Contrarreloj', texto, tipo or 'inform') end
end

local function Salir(texto)
    CreateThread(function()
        pcall(lib.callback.await, 'racing:contrarreloj:salir', false, {})
    end)
    Cerrar(texto)
end

AddEventHandler('racing:contrarreloj:abandonar', function()
    if sesion then Salir('Has dejado la contrarreloj') end
end)

RegisterNetEvent('racing:contrarreloj:cancelada', function(d)
    if sesion then Cerrar(type(d) == 'table' and d.motivo or 'Contrarreloj cancelada', 'error') end
end)

-- El DNF por FPS (client/racing.lua): el servidor ya la ha cerrado.
RegisterNetEvent('racing:playerDnf', function(data)
    if sesion and type(data) == 'table' and data.raceId ~= nil and data.raceId == sesion.raceId then
        sesion = nil
        SendNUIMessage({ action = 'contrarreloj:fin' })
    end
end)

RegisterCommand('salircontrarreloj', function()
    if sesion then Salir('Has dejado la contrarreloj') end
end, false)

-- ── Ir a la salida y empezar ────────────────────────────────────────────────

--- Al llegar a la salida, al volante y despacio, se pide empezar. Lejos, se
--- marca en el GPS (como la siguiente carrera de una sesion).
local function IrALaSalida(s)
    local salida = s.salida
    local lejos = #(GetEntityCoords(PlayerPedId()) - salida) > s.radio
    if lejos then
        SetNewWaypoint(salida.x, salida.y)
        avisar('Contrarreloj', ('La salida de %s está marcada en el GPS. Al llegar, empieza sola.'):format(s.nombre), 'inform', 8000)
    end

    local siguiente, ultimoMotivo, ultimoAviso = 0, nil, 0
    while sesion == s and s.estado == 'yendo' do
        local ahora = GetGameTimer()
        local veh = alVolante()
        local dist = #(GetEntityCoords(PlayerPedId()) - salida)

        if ahora - ultimoAviso > 1000 then
            ultimoAviso = ahora
            SendNUIMessage({ action = 'contrarreloj:yendo', data = { metros = math.floor(dist), circuito = s.nombre } })
        end

        -- El fantasma viaja latente: se le esperan unos segundos.
        local fantasmaListo = not s.conFantasma or fantasmas[s.token] ~= nil or ahora > s.esperaFantasma
        if veh and dist < s.radio and ahora >= siguiente and fantasmaListo and GetEntitySpeed(veh) < VELOCIDAD_SALIDA then
            s.estado = 'empezando'
            local nombre = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
            local ok, r = pcall(lib.callback.await, 'racing:contrarreloj:empezar', false, { vehiculo = nombre })
            if sesion ~= s then return end
            if ok and r and r.success then
                return   -- la salida llega con racing:contrarreloj:salida
            end
            s.estado = 'yendo'
            local motivo = (ok and r and r.message) or 'No se ha podido empezar'
            if motivo ~= ultimoMotivo then
                ultimoMotivo = motivo
                avisar('Contrarreloj', motivo, 'error')
            end
            siguiente = GetGameTimer() + 4000
        end
        Wait(250)
    end
end

--- La salida, del servidor: se corre con el flujo de siempre.
RegisterNetEvent('racing:contrarreloj:salida', function(data)
    local s = sesion
    if not s or type(data) ~= 'table' or EnCarrera() then return end
    s.estado = 'corriendo'
    s.raceId = data.raceId
    SetWaypointOff()
    SendNUIMessage({ action = 'contrarreloj:yendo', data = nil })

    local texto = fantasmas[s.token]
    data.ghost = texto
    s.cpsFantasma = TiemposDelFantasma(texto, data.checkpoints)

    TriggerEvent('racing:startRaceCountdown', data)
    SendNUIMessage({
        action = 'contrarreloj:empezar',
        data = {
            circuito = s.nombre,
            vueltas  = s.vueltas,
            fantasma = texto and s.fantasma or nil,
            miMejor  = misMejores[s.circuitId] or nil,
        },
    })

    -- La diferencia en cada checkpoint: se mira cuando cambia el siguiente.
    CreateThread(function()
        local antesCp, antesVuelta = nil, nil
        Wait(500)
        while sesion == s and s.estado == 'corriendo' and s.raceId == data.raceId do
            if EnCarrera() then
                local d = DatosHudCarrera()
                if d then
                    if antesVuelta and d.currentLap ~= antesVuelta then
                        -- vuelta cerrada: la cuenta racing:contrarreloj:vuelta
                    elseif antesCp and d.nextCheckpoint ~= antesCp and antesCp > 1 then
                        local tg = s.cpsFantasma and s.cpsFantasma[antesCp]
                        if tg then
                            SendNUIMessage({ action = 'contrarreloj:delta', data = { ms = d.currentLapTime - tg } })
                        end
                    end
                    antesCp, antesVuelta = d.nextCheckpoint, d.currentLap
                end
            end
            Wait(50)
        end
    end)
end)

--- Cada vuelta, con el tiempo del servidor.
RegisterNetEvent('racing:contrarreloj:vuelta', function(d)
    local s = sesion
    if not s or type(d) ~= 'table' then return end
    local total = s.cpsFantasma and s.cpsFantasma.total
    SendNUIMessage({
        action = 'contrarreloj:vuelta',
        data = {
            vuelta = d.vuelta, tiempo = d.tiempo, mejor = d.mejor,
            delta = total and d.tiempo and (d.tiempo - total) or nil,
        },
    })
end)

--- La meta: el resultado del servidor, con raton para los botones.
RegisterNetEvent('racing:contrarreloj:resultado', function(d)
    local s = sesion
    if not s or type(d) ~= 'table' then return end
    s.estado = 'terminada'
    if d.esMejor and d.mejor and d.mejor > 0 then
        misMejores[s.circuitId] = d.mejor
    elseif d.anterior then
        misMejores[s.circuitId] = d.anterior
    end
    SendNUIMessage({ action = 'contrarreloj:resultado', data = d })
    SetNuiFocusKeepInput(false)
    SetNuiFocus(true, true)
end)

RegisterNetEvent('racing:contrarreloj:fantasmaGuardado', function()
    if sesion then SendNUIMessage({ action = 'contrarreloj:fantasmaGuardado' }) end
end)

-- ── Volver a empezar ────────────────────────────────────────────────────────

--- El coche, detras de la linea de salida y mirando hacia la carrera.
local function LlevarALaSalida(veh, salida)
    local h = math.rad(salida.h or 0.0)
    local x = salida.x + math.sin(h) * 8.0
    local y = salida.y - math.cos(h) * 8.0
    local z = salida.z
    RequestCollisionAtCoord(x, y, z)
    SetEntityCoordsNoOffset(veh, x, y, z + 0.6, false, false, false)
    SetEntityHeading(veh, salida.h or 0.0)
    local hasta = GetGameTimer() + 2000
    while not HasCollisionLoadedAroundEntity(veh) and GetGameTimer() < hasta do Wait(0) end
    local hay, suelo = GetGroundZFor_3dCoord(x, y, z + 3.0, false)
    if hay and math.abs(suelo - z) < 6.0 then SetEntityCoordsNoOffset(veh, x, y, suelo + 0.6, false, false, false) end
    SetVehicleOnGroundProperly(veh)
    SetVehicleForwardSpeed(veh, 0.0)
    SetGameplayCamRelativeHeading(0.0)
end

local function Reintentar()
    local s = sesion
    if not s or s.ocupado or s.estado == 'yendo' or s.estado == 'empezando' then return end
    s.ocupado = true
    CreateThread(function()
        local ok, r = pcall(lib.callback.await, 'racing:contrarreloj:repetir', false, {})
        if sesion ~= s then return end
        if not (ok and r and r.success and type(r.salida) == 'table') then
            s.ocupado = false
            avisar('Contrarreloj', (ok and r and r.message) or 'No se ha podido repetir', 'error')
            return
        end

        -- La vuelta a medias, fuera (sin pantallas de abandono).
        if EnCarrera() then
            LimpiarCarrera()
            TriggerEvent('racing:localRaceFinished')
        end
        SendNUIMessage({ action = 'contrarreloj:reinicio' })
        SoltarFocoCarreras(false)

        local veh = alVolante()
        if veh then
            DoScreenFadeOut(250)
            local hasta = GetGameTimer() + 600
            while not IsScreenFadedOut() and GetGameTimer() < hasta do Wait(0) end
            LlevarALaSalida(veh, r.salida)
            Wait(400)   -- que el servidor vea ya la posicion nueva
            DoScreenFadeIn(250)
        else
            avisar('Contrarreloj', 'Súbete al volante y vuelve a la salida', 'inform')
        end

        s.estado = 'yendo'
        s.ocupado = false
        s.esperaFantasma = 0
        IrALaSalida(s)
    end)
end

-- La tecla: Retroceso mantenido (se puede cambiar en los ajustes de teclas).
do
    local pulsada = 0
    RegisterCommand('+racing_reintentar', function()
        if not sesion or (sesion.estado ~= 'corriendo' and sesion.estado ~= 'terminada') then return end
        local mia = GetGameTimer()
        pulsada = mia
        CreateThread(function()
            local hasta = mia + MANTENER_REINTENTO
            while pulsada == mia and GetGameTimer() < hasta do Wait(0) end
            if pulsada == mia then
                pulsada = 0
                Reintentar()
            end
        end)
    end, false)
    RegisterCommand('-racing_reintentar', function() pulsada = 0 end, false)
    RegisterKeyMapping('+racing_reintentar', 'Contrarreloj: volver a empezar desde la salida (mantener)', 'keyboard', 'BACK')
    RegisterCommand('reintentar', function() Reintentar() end, false)
end

-- ── Lo que pide la interfaz ─────────────────────────────────────────────────

RegisterNUICallback('racing:contrarreloj:ficha', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:contrarreloj:ficha', data)
end)

RegisterNUICallback('racing:contrarreloj:preparar', function(data, cb)
    if EnCarrera() then
        cb({ success = false, message = 'Ya estás corriendo' })
        return
    end
    if not alVolante() then
        cb({ success = false, message = 'Súbete a un coche, al volante, para la contrarreloj' })
        return
    end
    local ok, r = pcall(lib.callback.await, 'racing:contrarreloj:preparar', false, data)
    if not ok or type(r) ~= 'table' or not r.success then
        cb(ok and type(r) == 'table' and r or { success = false, message = 'Sin respuesta del servidor' })
        return
    end
    cb(r)

    if sesion and sesion.estado == 'yendo' then SetWaypointOff() end
    local id = tonumber(r.circuitId)
    if id then misMejores[id] = r.miMejor end
    sesion = {
        token          = r.token,
        circuitId      = id,
        nombre         = r.nombre or 'Circuito',
        vueltas        = r.vueltas or 1,
        salida         = vector3(r.salida.x + 0.0, r.salida.y + 0.0, r.salida.z + 0.0),
        radio          = math.max(10.0, (tonumber(r.radio) or 40.0) - 5.0),
        conFantasma    = r.conFantasma == true,
        fantasma       = r.fantasma,
        esperaFantasma = GetGameTimer() + 15000,
        estado         = 'yendo',
    }
    local s = sesion
    CreateThread(function() IrALaSalida(s) end)
end)

RegisterNUICallback('racing:contrarreloj:repetir', function(_, cb)
    cb({ success = true })
    SoltarFocoCarreras(false)
    Reintentar()
end)

RegisterNUICallback('racing:contrarreloj:salir', function(_, cb)
    cb({ success = true })
    if sesion then Salir() else SoltarFocoCarreras(false) end
end)

AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    if sesion and sesion.estado == 'yendo' then SetWaypointOff() end
    sesion = nil
end)
