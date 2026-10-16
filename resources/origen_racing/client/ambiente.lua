-- ========================================
-- CLIENTE: TRÁFICO, REBUFO, HORA Y CLIMA DE UNA CARRERA
-- ========================================
--[[ Lo que se elige al crear la carrera además del modo
     (server/ambiente.lua sanea y manda; aquí se aplica).

       Sin tráfico  el corredor atraviesa todo lo que no es de su carrera:
                    coches de NPC, coches y gente de otros jugadores. Eso lo
                    hace su cliente. Y para que la otra parte tampoco choque,
                    su coche lleva la marca `racingTraspasa` (la pone el
                    servidor) y TODOS los clientes, corran o no, dejan de
                    chocar con él y lo ven medio transparente.
       Rebufo       el de GTA: detrás de otro coche coges velocidad.
       Hora/clima   solo para quien corre (y su copiloto): se le quita la
                    sincronía de Renewed-Weathersync y se le devuelve al acabar.

     Todos los hilos acaban solos cuando acaba la carrera (EnCarrera()). ]]

Ambiente = {}

local cfg = Config.Ambiente or {}

-- ── Sin tráfico: el corredor ─────────────────────────────────────────────────

local function hiloSinTrafico(raceId)
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh == 0 then return end
    local netId = NetworkGetNetworkIdFromEntity(veh)
    TriggerServerEvent('racing:traspasa', netId, raceId, true)

    local radio = cfg.RadioTraspasa or 70.0
    local alfa = cfg.AlfaTrafico or 110
    local cerca, tocados = {}, {}   -- tocados[coche] = true: le hemos bajado el alfa
    local proximo = 0

    while EnCarrera() do
        local yo = PlayerPedId()
        local mio = GetVehiclePedIsIn(yo, false)
        local ahora = GetGameTimer()

        -- La lista de lo que hay que atravesar se rehace cuatro veces por
        -- segundo; el «no chocar» se repite en cada fotograma, que es lo que
        -- pide el native.
        if ahora >= proximo then
            proximo = ahora + 250
            cerca = {}
            if mio ~= 0 then
                local pos = GetEntityCoords(mio)
                for _, v in ipairs(GetGamePool('CVehicle')) do
                    if v ~= mio and #(GetEntityCoords(v) - pos) < radio then
                        if Entity(v).state.racingTraspasa == raceId then
                            -- Otro corredor de esta carrera: lo decide el modo de
                            -- colisiones, no el tráfico.
                            if tocados[v] then ResetEntityAlpha(v); tocados[v] = nil end
                        else
                            cerca[#cerca + 1] = v
                            if not tocados[v] then SetEntityAlpha(v, alfa, false); tocados[v] = true end
                        end
                    end
                end
                -- La gente a pie tampoco se atropella.
                for _, p in ipairs(GetGamePool('CPed')) do
                    if p ~= yo and not IsPedInAnyVehicle(p, false) and #(GetEntityCoords(p) - pos) < radio then
                        cerca[#cerca + 1] = p
                    end
                end
                -- Lo que se queda atrás recupera su aspecto.
                for v in pairs(tocados) do
                    if not DoesEntityExist(v) then
                        tocados[v] = nil
                    elseif #(GetEntityCoords(v) - pos) >= radio then
                        ResetEntityAlpha(v)
                        tocados[v] = nil
                    end
                end
            end
        end

        if mio ~= 0 then
            for i = 1, #cerca do
                local e = cerca[i]
                if DoesEntityExist(e) then
                    SetEntityNoCollisionEntity(mio, e, true)
                    SetEntityNoCollisionEntity(e, mio, true)
                end
            end
        end
        Wait(0)
    end

    for v in pairs(tocados) do
        if DoesEntityExist(v) then ResetEntityAlpha(v) end
    end
    TriggerServerEvent('racing:traspasa', netId, raceId, false)
end

-- ── Sin tráfico: los demás ───────────────────────────────────────────────────
--[[ Corre siempre, en todos los clientes, y casi no gasta: una vez por segundo
     mira si algún jugador cercano conduce un coche marcado. Solo si lo hay se
     pone a trabajar en cada fotograma. Además del coche propio, deja sin
     choque contra el corredor lo que ESTE cliente mueve (los NPC que le tocan
     simular): si no, el coche de NPC se lo comería en su pantalla. ]]

CreateThread(function()
    local vistos = {}   -- [coche de corredor] = true: con el alfa bajado
    local yoId = PlayerId()

    while true do
        local yo = PlayerPedId()
        local pos = GetEntityCoords(yo)
        local mio = GetVehiclePedIsIn(yo, false)
        local miCarrera = mio ~= 0 and Entity(mio).state.racingTraspasa or nil

        local lista, enLista = {}, {}
        for _, pid in ipairs(GetActivePlayers()) do
            if pid ~= yoId then
                local v = GetVehiclePedIsIn(GetPlayerPed(pid), false)
                -- La distancia antes que el statebag: leerlo cuesta mas, y de
                -- los que estan lejos no hace falta.
                if v ~= 0 and not enLista[v] and #(GetEntityCoords(v) - pos) < 150.0 then
                    local r = Entity(v).state.racingTraspasa
                    -- Los de MI carrera no: entre corredores manda el modo de colisiones.
                    if r and r ~= miCarrera then
                        lista[#lista + 1] = v
                        enLista[v] = true
                    end
                end
            end
        end

        for v in pairs(vistos) do
            if not enLista[v] then
                if DoesEntityExist(v) then ResetEntityAlpha(v) end
                vistos[v] = nil
            end
        end

        if #lista == 0 then
            Wait(1000)
        else
            for _, v in ipairs(lista) do
                if not vistos[v] then SetEntityAlpha(v, cfg.AlfaCorredor or 150, false); vistos[v] = true end
            end

            -- Lo que mueve este cliente cerca de algún corredor.
            local mios = {}
            for _, e in ipairs(GetGamePool('CVehicle')) do
                if e ~= mio and not enLista[e] and NetworkGetEntityOwner(e) == yoId then
                    local pe = GetEntityCoords(e)
                    for _, v in ipairs(lista) do
                        if #(pe - GetEntityCoords(v)) < 30.0 then mios[#mios + 1] = e; break end
                    end
                end
            end

            local hasta = GetGameTimer() + 500
            while GetGameTimer() < hasta do
                yo = PlayerPedId()
                mio = GetVehiclePedIsIn(yo, false)
                for _, v in ipairs(lista) do
                    if DoesEntityExist(v) then
                        SetEntityNoCollisionEntity(v, yo, true)
                        SetEntityNoCollisionEntity(yo, v, true)
                        if mio ~= 0 then
                            SetEntityNoCollisionEntity(v, mio, true)
                            SetEntityNoCollisionEntity(mio, v, true)
                        end
                        for _, e in ipairs(mios) do
                            if DoesEntityExist(e) then
                                SetEntityNoCollisionEntity(v, e, true)
                                SetEntityNoCollisionEntity(e, v, true)
                            end
                        end
                    end
                end
                Wait(0)
            end
        end
    end
end)

-- ── Rebufo ───────────────────────────────────────────────────────────────────

local function hiloRebufo()
    SetEnableVehicleSlipstreaming(true)
    while EnCarrera() do Wait(500) end
    SetEnableVehicleSlipstreaming(false)
end

-- ── Hora y clima ─────────────────────────────────────────────────────────────

local LLUEVE = { RAIN = true, THUNDER = true, CLEARING = true }

local function hiloHoraYClima(hora, clima)
    local estado = LocalPlayer.state
    local antes = { sync = estado.syncWeather, clima = estado.playerWeather }

    -- Sin clima elegido se queda el que hay en el servidor.
    local servidor = GlobalState.weather
    clima = clima or (type(servidor) == 'table' and servidor.weather) or 'EXTRASUNNY'

    -- Renewed-Weathersync deja de pisar hora y clima y repite `playerWeather`
    -- cada 2,5 s (ver origen_dealership/client/fotos.lua, que hace lo mismo).
    estado.playerWeather = clima
    estado.syncWeather = false
    SetWeatherTypeNowPersist(clima)

    while EnCarrera() do
        if hora then NetworkOverrideClockTime(hora.hora, hora.minuto, 0) end
        -- El sincronizador quita la lluvia cada vez que repite el clima.
        if LLUEVE[clima] then SetRainLevel(-1.0) end
        Wait(500)
    end

    estado.playerWeather = antes.clima
    estado.syncWeather = antes.sync
    if antes.sync == nil then
        ClearOverrideWeather()
        ClearWeatherTypePersist()
        NetworkClearClockTimeOverride()
    end
end

-- ── El coche de carrera: ruedas, copiloto y bordillos ────────────────────────
--[[ Lo que vigila el piloto en cada fotograma mientras corre (14/10):

     - Ruedas: el coche de carrera no revienta ruedas (choques, roces, tiros).
       Se le devuelve como estaba al acabar.
     - Copiloto: en GTA cada ocupante pesa, y llevar copiloto hacia el coche
       mas lento. Con pasajeros se le sube la potencia en proporcion a su peso
       frente al del coche (Ambiente.Compensacion; el turbo del arcade la usa
       tambien). Nunca por encima de lo que el coche haria vacio.
     - Antibordillos (opcion de la carrera): pisar un bordillo en GTA da un
       empujon de velocidad que se usa para ganar. Si el coche gana velocidad
       mas deprisa de lo que pueden darle el motor y la cuesta juntos, se le
       deja con la que llevaba mas lo que si es posible ganar en ese fotograma. ]]
local PESO_OCUPANTE = 80.0     -- kg que suma cada pasajero
local ACEL_MAXIMA   = 26.0     -- m/s²: motor de un super (~12) + bajada fuerte (~10) + margen
local VEL_MINIMA    = 8.0      -- m/s: por debajo no se mira (arrancadas, maniobras)

Ambiente.Compensacion = 1.0

local function pasajeros(veh)
    local n = 0
    for asiento = 0, GetVehicleMaxNumberOfPassengers(veh) - 1 do
        if not IsVehicleSeatFree(veh, asiento) then n = n + 1 end
    end
    return n
end

local function hiloCoche(antibordillo)
    local tocados = {}        -- [veh] = como estaban sus ruedas
    local anterior, vehAnterior = nil, 0
    while EnCarrera() do
        Wait(0)
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh == 0 or GetPedInVehicleSeat(veh, -1) ~= ped then
            Ambiente.Compensacion = 1.0
            anterior = nil
        else
            if not tocados[veh] then
                tocados[veh] = GetVehicleTyresCanBurst(veh)
                SetVehicleTyresCanBurst(veh, false)
            end

            -- Copiloto
            local n = pasajeros(veh)
            if n > 0 then
                local masa = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fMass')
                Ambiente.Compensacion = masa > 0 and (1.0 + n * PESO_OCUPANTE / masa) or 1.0
                if not (Modos.TurboActivo and Modos.TurboActivo()) then
                    SetVehicleCheatPowerIncrease(veh, Ambiente.Compensacion)
                end
            else
                Ambiente.Compensacion = 1.0
            end

            -- Bordillos
            if antibordillo then
                local v = GetEntityVelocity(veh)
                local rapidez = #v
                if anterior and veh == vehAnterior and anterior > VEL_MINIMA
                    and not (Modos.TurboActivo and Modos.TurboActivo()) then
                    local dt = math.max(GetFrameTime(), 0.001)
                    local tope = anterior + ACEL_MAXIMA * dt
                    if rapidez > tope + 0.05 then
                        SetEntityVelocity(veh, v.x * tope / rapidez, v.y * tope / rapidez, v.z * tope / rapidez)
                        rapidez = tope
                    end
                end
                anterior, vehAnterior = rapidez, veh
            end
        end
    end
    Ambiente.Compensacion = 1.0
    for veh, podia in pairs(tocados) do
        if DoesEntityExist(veh) then SetVehicleTyresCanBurst(veh, podia ~= false) end
    end
end

-- ── Entrada ──────────────────────────────────────────────────────────────────

--- Al darse la salida. `soyPiloto`: al volante de su coche de carrera (el
--- copiloto solo ve la hora y el clima).
function Ambiente.Empezar(data, soyPiloto)
    if type(data) ~= 'table' then return end
    if soyPiloto and data.trafico == false and data.raceId then
        CreateThread(function() hiloSinTrafico(data.raceId) end)
    end
    if soyPiloto and data.rebufo == true then
        CreateThread(hiloRebufo)
    end
    -- Ruedas, copiloto y (si la carrera lo pide) bordillos
    if soyPiloto then
        CreateThread(function() hiloCoche(data.antibordillo == true) end)
    end
    if type(data.hora) == 'table' or type(data.clima) == 'string' then
        local hora = type(data.hora) == 'table' and data.hora or nil
        local clima = type(data.clima) == 'string' and data.clima or nil
        CreateThread(function() hiloHoraYClima(hora, clima) end)
    end
end
