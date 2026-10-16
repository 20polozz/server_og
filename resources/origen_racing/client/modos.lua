-- ========================================
-- CLIENTE: MODOS DE CARRERA Y LOBBY
-- ========================================
--[[ Lo que cada modo pinta o toca en el cliente:

       drift    el coche corre con las ruedas de drift desde la salida
       arcade   potenciadores por el recorrido (turbo, reparacion, sorpresa)

     Y el LOBBY: los muebles y las plazas que el creador del circuito coloco
     alrededor de la salida (client/amueblar.lua), que solo se ven mientras
     hay una carrera abierta en ese circuito.

     racing.lua llama a Modos.Empezar al recibir la salida. No hace falta
     avisar del final: el hilo mira EnCarrera() y recoge solo, se acabe la
     carrera como se acabe (meta, abandono, expulsion, cancelacion). ]]

Modos = {}
Lobby = {}

-- ── Pintar: lo comparten la carrera, el lobby y el editor ────────────────────

--- Un potenciador: el simbolo girando y un aro en el suelo.
function Modos.PintarItem(tipo, x, y, z, apagado)
    local t = Config.Arcade.Tipos[tipo]
    if not t then return end
    local c = t.color
    local a = apagado and 45 or 225
    if not apagado then
        DrawMarker(t.marker, x, y, z + 0.75, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.5, 1.5, 1.5,
            c[1], c[2], c[3], a, true, false, 2, true, nil, nil, false)
    end
    DrawMarker(27, x, y, z - 0.42, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 3.4, 3.4, 1.0,
        c[1], c[2], c[3], a, false, false, 2, false, nil, nil, false)
end

--- Una plaza de aparcamiento: el rectangulo en el suelo y la marca del morro.
function Lobby.PintarPlaza(p, r, g, b)
    local h = math.rad(p.h or 0.0)
    local fx, fy = -math.sin(h), math.cos(h)   -- hacia delante
    local dx, dy = math.cos(h), math.sin(h)    -- hacia la derecha
    local ancho, largo = 1.45, 2.8
    local z = p.z + 0.06
    local function esquina(sf, sd)
        return p.x + fx * largo * sf + dx * ancho * sd, p.y + fy * largo * sf + dy * ancho * sd
    end
    local ax, ay = esquina(1, -1)
    local bx, by = esquina(1, 1)
    local cx, cy = esquina(-1, 1)
    local ex, ey = esquina(-1, -1)
    r, g, b = r or 216, g or 27, b or 85   -- rosa pegatina
    DrawLine(ax, ay, z, bx, by, z, r, g, b, 235)
    DrawLine(bx, by, z, cx, cy, z, r, g, b, 235)
    DrawLine(cx, cy, z, ex, ey, z, r, g, b, 235)
    DrawLine(ex, ey, z, ax, ay, z, r, g, b, 235)
    -- El morro: una punta dentro del rectangulo
    local px, py = p.x + fx * (largo - 0.9), p.y + fy * (largo - 0.9)
    DrawLine(ax, ay, z, px, py, z, r, g, b, 150)
    DrawLine(bx, by, z, px, py, z, r, g, b, 150)
end

function Lobby.CargarModelo(nombre)
    local hash = type(nombre) == 'number' and nombre or joaat(nombre)
    if not IsModelInCdimage(hash) then return nil end
    if not HasModelLoaded(hash) then
        RequestModel(hash)
        local hasta = GetGameTimer() + 4000
        while not HasModelLoaded(hash) and GetGameTimer() < hasta do Wait(10) end
        if not HasModelLoaded(hash) then return nil end
    end
    return hash
end

--- Pone un mueble (objeto local, no de red) y devuelve su entidad.
function Lobby.PonerMueble(m)
    local hash = Lobby.CargarModelo(m.m)
    if not hash then return nil end
    local obj = CreateObjectNoOffset(hash, m.x + 0.0, m.y + 0.0, m.z + 0.0, false, false, false)
    if not obj or obj == 0 then return nil end
    SetEntityRotation(obj, (m.rx or 0.0) + 0.0, (m.ry or 0.0) + 0.0, (m.h or 0.0) + 0.0, 2, true)
    FreezeEntityPosition(obj, true)
    SetEntityAsMissionEntity(obj, true, true)
    SetModelAsNoLongerNeeded(hash)
    return obj
end

-- ── El lobby a la vista ──────────────────────────────────────────────────────

local lobbyCache = {}     -- [circuitId] = { muebles, plazas } tal cual viene del servidor
local lobbyPuesto = {}    -- [circuitId] = { objetos = {}, plazas = {} }
local lobbyPausado = false

local function quitarLobby(circuitId)
    local l = lobbyPuesto[circuitId]
    if not l then return end
    for _, obj in ipairs(l.objetos) do
        if DoesEntityExist(obj) then DeleteEntity(obj) end
    end
    lobbyPuesto[circuitId] = nil
end

local function ponerLobby(circuitId)
    if lobbyPuesto[circuitId] then return end
    lobbyPuesto[circuitId] = { objetos = {}, plazas = {} }   -- ya, para no pedirlo dos veces

    if not lobbyCache[circuitId] then
        lobbyCache[circuitId] = lib.callback.await('racing:lobby:get', false, circuitId) or { muebles = {}, plazas = {} }
    end
    local l = lobbyPuesto[circuitId]
    if not l then return end   -- lo han quitado mientras se pedia

    for _, m in ipairs(lobbyCache[circuitId].muebles or {}) do
        local obj = Lobby.PonerMueble(m)
        if obj then l.objetos[#l.objetos + 1] = obj end
        if not lobbyPuesto[circuitId] then
            -- Quitado a medias: lo que se haya puesto, fuera.
            for _, o in ipairs(l.objetos) do if DoesEntityExist(o) then DeleteEntity(o) end end
            return
        end
    end
    l.plazas = lobbyCache[circuitId].plazas or {}
end

--- El editor lo apaga mientras se amuebla, para no ver los muebles dos veces.
function Lobby.Pausar(si)
    lobbyPausado = si == true
    if lobbyPausado then
        for id in pairs(lobbyPuesto) do quitarLobby(id) end
    end
end

RegisterNetEvent('racing:lobby:cambiado', function(circuitId)
    lobbyCache[circuitId] = nil
    quitarLobby(circuitId)
end)

-- Que lobbies tocan: los de circuitos con carrera abierta y la salida cerca.
CreateThread(function()
    while true do
        Wait(1500)
        local activas = GlobalState.activeRaces or {}
        local yo = GetEntityCoords(PlayerPedId())
        local tocan = {}

        if not lobbyPausado then
            for _, c in pairs(CircuitosCliente and CircuitosCliente() or {}) do
                local info = activas[c.id] or activas[tostring(c.id)]
                if info and (info.raceCount or 0) > 0 and c.blip and c.blip.x then
                    if #(yo - vector3(c.blip.x, c.blip.y, c.blip.z or yo.z)) <= Config.Lobby.Distancia then
                        tocan[c.id] = true
                    end
                end
            end
        end

        for id in pairs(lobbyPuesto) do
            if not tocan[id] then quitarLobby(id) end
        end
        for id in pairs(tocan) do
            if not lobbyPuesto[id] then ponerLobby(id) end
        end
    end
end)

-- Las plazas se pintan cada fotograma, solo con un lobby a la vista.
CreateThread(function()
    while true do
        local espera = 800
        for _, l in pairs(lobbyPuesto) do
            if #l.plazas > 0 then
                espera = 0
                local yo = GetEntityCoords(PlayerPedId())
                for _, p in ipairs(l.plazas) do
                    if #(yo - vector3(p.x, p.y, p.z)) < 90.0 then Lobby.PintarPlaza(p) end
                end
            end
        end
        Wait(espera)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for id in pairs(lobbyPuesto) do quitarLobby(id) end
end)

-- ── Arcade ───────────────────────────────────────────────────────────────────

local function avisar(titulo, texto, tipo)
    lib.notify({ title = titulo, description = texto, type = tipo or 'inform', duration = 2500 })
end

local turboHasta = 0

--- Si el turbo esta empujando ahora (client/ambiente.lua no pone la potencia
--- encima mientras tanto: lo hace el turbo, ya con la compensacion).
function Modos.TurboActivo() return GetGameTimer() < turboHasta end

local function darTurbo(ms)
    local ahora = GetGameTimer()
    turboHasta = math.max(turboHasta, ahora) + ms
    AnimpostfxPlay('RaceTurbo', 0, false)
    PlaySoundFrontend(-1, 'Boost_Activate', 'DLC_Stunt_Race_Frontend_Sounds', true)
end

local function reparar(veh)
    local gasolina = GetVehicleFuelLevel(veh)
    SetVehicleFixed(veh)
    SetVehicleEngineHealth(veh, 1000.0)
    SetVehicleBodyHealth(veh, 1000.0)
    SetVehicleFuelLevel(veh, gasolina)
    PlaySoundFrontend(-1, 'PICK_UP', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
end

local function aplicar(tipo, veh)
    if tipo == 'sorpresa' then
        local n = math.random(100)
        if n <= 50 then tipo = 'turbo' elseif n <= 78 then tipo = 'reparar' else tipo = 'megaturbo' end
    end
    if tipo == 'turbo' then
        darTurbo(Config.Arcade.TurboMs)
        avisar('Turbo', 'Pisa a fondo', 'success')
    elseif tipo == 'megaturbo' then
        darTurbo(Config.Arcade.TurboMs * 2)
        avisar('Mega turbo', 'Doble de turbo', 'success')
    elseif tipo == 'reparar' then
        reparar(veh)
        avisar('Reparación', 'Coche como nuevo', 'success')
    end
end

--- Los potenciadores de una carrera: los colocados a mano y, cada tantos
--- checkpoints, una fila de cajas sorpresa a lo ancho de la pista.
local function montarItems(data)
    local items = {}
    for _, it in ipairs(data.items or {}) do
        if Config.Arcade.Tipos[it.t] then
            items[#items + 1] = { t = it.t, x = it.x + 0.0, y = it.y + 0.0, z = it.z + 0.0, vuelve = 0 }
        end
    end

    local cada = Config.Arcade.FilaCada or 0
    if cada > 0 then
        for i, cp in ipairs(data.checkpoints or {}) do
            if i > 1 and (i - 1) % cada == 0 and tonumber(cp.heading) then
                local h = math.rad(cp.heading)
                local dx, dy = math.cos(h), math.sin(h)
                local r = (tonumber(cp.radius) or 10.0) * 0.55
                for _, k in ipairs({ -1, 0, 1 }) do
                    items[#items + 1] = { t = 'sorpresa', x = cp.coord_x + dx * r * k, y = cp.coord_y + dy * r * k, z = cp.coord_z + 0.0, vuelve = 0 }
                end
            end
        end
    end
    return items
end

local function hiloArcade(data)
    local items = montarItems(data)
    local radio = Config.Arcade.RadioCoger

    while EnCarrera() do
        Wait(0)
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        local yo = GetEntityCoords(ped)
        local ahora = GetGameTimer()

        for _, it in ipairs(items) do
            local d = #(yo - vector3(it.x, it.y, it.z))
            if d < 170.0 then
                local apagado = ahora < it.vuelve
                Modos.PintarItem(it.t, it.x, it.y, it.z, apagado)
                if not apagado and d < radio and veh ~= 0 then
                    it.vuelve = ahora + Config.Arcade.Reaparece
                    aplicar(it.t, veh)
                end
            end
        end

        if veh ~= 0 and ahora < turboHasta then
            -- Por la compensacion del copiloto (client/ambiente.lua): con
            -- pasajeros el turbo empuja lo mismo que sin ellos.
            SetVehicleCheatPowerIncrease(veh, (Config.Arcade.TurboFuerza + 0.0) * (Ambiente.Compensacion or 1.0))
            SetVehicleBoostActive(veh, true)
        end
    end

    turboHasta = 0
    AnimpostfxStop('RaceTurbo')
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh ~= 0 then SetVehicleBoostActive(veh, false) end
end

-- ── Drift ────────────────────────────────────────────────────────────────────

--- Las ruedas de drift van por coche: se le ponen al que se conduce y se le
--- quitan a ese mismo al acabar, aunque el piloto ya se haya bajado.
local function hiloDrift()
    local tocados = {}
    while EnCarrera() do
        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
        if veh ~= 0 and not tocados[veh] then
            SetDriftTyresEnabled(veh, true)
            tocados[veh] = true
        end
        Wait(500)
    end
    for veh in pairs(tocados) do
        if DoesEntityExist(veh) then SetDriftTyresEnabled(veh, false) end
    end
end

-- ── Entrada ──────────────────────────────────────────────────────────────────

function Modos.Empezar(data)
    if type(data) ~= 'table' then return end
    if data.raceType == 'arcade' then
        CreateThread(function() hiloArcade(data) end)
    elseif data.raceType == 'drift' then
        CreateThread(hiloDrift)
    end
end
