-- ============================================================
-- ORIGEN POLICE — SISTEMA DE CALLOUTS ALEATORIOS (CLIENT)
-- ============================================================

local activeCallouts = {}
local activeEntities = {} -- [calloutId] = { peds = {}, vehicles = {}, blips = {}, spawned = false }
local currentAcceptedCallout = nil

-- Helper para cargar modelos de entidades de GTA V
local function LoadModel(modelHash)
    if type(modelHash) == "string" then
        modelHash = GetHashKey(modelHash)
    end
    if not IsModelInCdimage(modelHash) then return false end
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 100 do
        Wait(50)
        timeout = timeout + 1
    end
    return HasModelLoaded(modelHash)
end

local configuredCallouts = {}

-- Limpieza de entidades de una llamada
local function CleanupCalloutEntities(calloutId)
    local data = activeEntities[calloutId]
    configuredCallouts[calloutId] = nil
    if not data then return end

    if data.blips then
        for _, b in ipairs(data.blips) do
            OrigenMapa.Quitar(b)
        end
    end

    activeEntities[calloutId] = nil
    if currentAcceptedCallout == calloutId then
        currentAcceptedCallout = nil
        ClearGpsMultiRoute()
    end
end

-- Configurar blip de llamada en el mapa
--[[ El aviso, en el mapa.

     Ya no son blips del juego: es UN punto de origen_map. Antes hacian falta
     dos —la marca y el circulo de la zona de busqueda— porque un blip no sabe
     ser las dos cosas; aqui es el mismo punto con `radio`.

     Prioridad alta: un aviso al otro lado de la ciudad es justamente el que
     hay que ver, y era lo que decia SetBlipAsShortRange(false).

     Devuelve una lista de CLAVES, no de handles, porque es lo que guarda quien
     llama para poder quitarlas luego. ]]
local siguienteAviso = 0

local function CreateCalloutBlip(coords, title, code)
    siguienteAviso = siguienteAviso + 1
    local clave = 'aviso_' .. siguienteAviso

    OrigenMapa.Poner(clave, {
        x = coords.x, y = coords.y, z = coords.z,
        cat = 'avisos',
        nombre = string.format("[%s] %s", code or "10-00", title or "Aviso Policial"),
        radio = 80.0,
        color = '#ff3355',
        prioridad = 10,
    })

    return { clave }
end

-- Configuración de IA sobre las entidades globales creadas por el servidor
local function ConfigureCalloutEntities(callout)
    local id = callout.id
    if configuredCallouts[id] then return end

    local cfg = callout.scenarioConfig or {}
    activeEntities[id] = activeEntities[id] or { peds = {}, vehicles = {}, blips = {} }
    local entData = activeEntities[id]

    local peds = {}
    local vehicles = {}

    -- Resolución de vehículos por Network ID
    if callout.netVehicles then
        for _, netId in ipairs(callout.netVehicles) do
            if NetworkDoesNetworkIdExist(netId) then
                local veh = NetToVeh(netId)
                if DoesEntityExist(veh) then
                    table.insert(vehicles, veh)
                end
            end
        end
    end

    -- Resolución de peds por Network ID
    if callout.netPeds then
        for _, netId in ipairs(callout.netPeds) do
            if NetworkDoesNetworkIdExist(netId) then
                local ped = NetToPed(netId)
                if DoesEntityExist(ped) then
                    table.insert(peds, ped)
                end
            end
        end
    end

    entData.peds = peds
    entData.vehicles = vehicles

    if #peds == 0 and #vehicles == 0 then
        -- Entidades aún no han entrado en el alcance de streaming de este cliente
        return
    end

    local playerPed = PlayerPedId()

    -- 1. FleeingSuspect (Persecución 10-80)
    if cfg.behavior == "flee_vehicle" or cfg.isVehicle then
        if #vehicles > 0 and #peds > 0 then
            local veh = vehicles[1]
            local driver = GetPedInVehicleSeat(veh, -1)
            if DoesEntityExist(driver) then
                SetVehicleEngineOn(veh, true, true, false)
                SetVehicleForwardSpeed(veh, 25.0)
                ModifyVehicleTopSpeed(veh, 1.30)

                SetDriverAbility(driver, 1.0)
                SetDriverAggressiveness(driver, 0.70)
                SetPedCombatAttributes(driver, 46, true)
                SetPedCombatAttributes(driver, 3, false)
                SetPedCombatAttributes(driver, 1, true)
                SetPedCombatAttributes(driver, 2, true)
                SetPedCombatAttributes(driver, 52, true)
                SetPedFleeAttributes(driver, 0, false)
                SetPedFleeAttributes(driver, 512, true)

                local pursuitStyle = 786492
                SetDriveTaskDrivingStyle(driver, pursuitStyle)
                SetDriveTaskCruiseSpeed(driver, 38.0)
                TaskVehicleDriveWander(driver, veh, 38.0, pursuitStyle)
            end

            for i = 2, #peds do
                local pass = peds[i]
                if DoesEntityExist(pass) then
                    SetPedCombatAttributes(pass, 46, true)
                    SetPedCombatAttributes(pass, 2, true)
                    SetPedCombatAttributes(pass, 3, false)
                    SetPedAlertness(pass, 3)
                    TaskCombatPed(pass, playerPed, 0, 16)
                end
            end
        end

    -- 2. Hostile Melee
    elseif cfg.behavior == "hostile_melee" then
        for _, ped in ipairs(peds) do
            if DoesEntityExist(ped) then
                SetPedCombatAttributes(ped, 46, true)
                SetPedCombatAttributes(ped, 5, true)
                SetPedCombatRange(ped, 0)
                TaskCombatPed(ped, playerPed, 0, 16)
            end
        end

    -- 3. Hostile Firearm
    elseif cfg.behavior == "hostile_firearm" then
        for _, ped in ipairs(peds) do
            if DoesEntityExist(ped) then
                SetPedCombatAttributes(ped, 46, true)
                SetPedCombatAttributes(ped, 0, true)
                SetPedCombatRange(ped, 2)
                TaskCombatPed(ped, playerPed, 0, 16)
            end
        end

    -- 4. Gang War / Shootout
    elseif cfg.behavior == "gang_war" or cfg.behavior == "shootout_brawl" then
        local teamAPeds = {}
        local teamBPeds = {}
        local half = math.ceil(#peds / 2)

        for i, ped in ipairs(peds) do
            if DoesEntityExist(ped) then
                SetPedCombatAttributes(ped, 46, true)
                SetPedCombatAttributes(ped, 0, true)
                SetPedCombatRange(ped, 2)

                if i <= half then
                    SetPedRelationshipGroupHash(ped, GetHashKey("GANG_A"))
                    table.insert(teamAPeds, ped)
                else
                    SetPedRelationshipGroupHash(ped, GetHashKey("GANG_B"))
                    table.insert(teamBPeds, ped)
                end
            end
        end

        SetRelationshipBetweenGroups(5, GetHashKey("GANG_A"), GetHashKey("GANG_B"))
        SetRelationshipBetweenGroups(5, GetHashKey("GANG_B"), GetHashKey("GANG_A"))

        for i, pA in ipairs(teamAPeds) do
            local targetB = teamBPeds[((i - 1) % #teamBPeds) + 1]
            if targetB then TaskCombatPed(pA, targetB, 0, 16) end
        end
        for i, pB in ipairs(teamBPeds) do
            local targetA = teamAPeds[((i - 1) % #teamAPeds) + 1]
            if targetA then TaskCombatPed(pB, targetA, 0, 16) end
        end

    -- 5. Brawl
    elseif cfg.behavior == "brawl" or cfg.isFight then
        for i, ped in ipairs(peds) do
            if DoesEntityExist(ped) then
                local nextPed = peds[(i % #peds) + 1]
                if nextPed and DoesEntityExist(nextPed) then
                    TaskCombatPed(ped, nextPed, 0, 16)
                end
            end
        end

    -- 6. Drunk Driver
    elseif cfg.behavior == "drunk_driver" or cfg.isDrunk then
        if #vehicles > 0 and #peds > 0 then
            local veh = vehicles[1]
            local ped = peds[1]
            if DoesEntityExist(ped) and DoesEntityExist(veh) then
                SetDriverAbility(ped, 0.2)
                SetDriverAggressiveness(ped, 0.1)
                TaskVehicleDriveWander(ped, veh, 15.0, 786468)
            end
        end
    end

    configuredCallouts[id] = true
end

-- ─── BUCLE PRINCIPAL DE PROXIMIDAD Y COMPROBACIÓN DE ESTADO ───
CreateThread(function()
    while true do
        Wait(1000)

        local playerPed = PlayerPedId()
        local pCoords = GetEntityCoords(playerPed)

        for id, callout in pairs(activeCallouts) do
            local cCoords = callout.coords
            local dist = #(pCoords - vector3(cCoords.x, cCoords.y, cCoords.z))

            -- Configurar IA de entidades globales cuando el oficial entra a la zona (~200m)
            if dist < 200.0 then
                ConfigureCalloutEntities(callout)
            end

            -- Monitorizar si los NPCs han sido neutralizados o esposados
            if activeEntities[id] and (activeEntities[id].peds and #activeEntities[id].peds > 0) then
                local allNeutralized = true
                local hasPeds = false

                -- Gestión continua de huida y recuperación tras PITs para persecuciones
                if callout.scenarioConfig and (callout.scenarioConfig.behavior == "flee_vehicle" or callout.scenarioConfig.isVehicle) then
                    for _, veh in ipairs(activeEntities[id].vehicles) do
                        if DoesEntityExist(veh) then
                            local driver = GetPedInVehicleSeat(veh, -1)
                            if DoesEntityExist(driver) and not IsEntityDead(driver) and not IsPedCuffed(driver) then
                                local engHealth = GetVehicleEngineHealth(veh)
                                local speed = GetEntitySpeed(veh)

                                if engHealth > 150.0 and not IsVehicleStuckOnRoof(veh) then
                                    if speed < 3.0 then
                                        SetVehicleEngineOn(veh, true, true, false)
                                        SetVehicleForwardSpeed(veh, 18.0)
                                        TaskVehicleDriveWander(driver, veh, 38.0, 786492)
                                    end
                                end
                            end
                        end
                    end
                end

                for _, ped in ipairs(activeEntities[id].peds) do
                    if DoesEntityExist(ped) then
                        hasPeds = true
                        local isDead = IsEntityDead(ped) or IsPedFatallyInjured(ped)
                        local isCuffed = IsPedCuffed(ped) or (GetEntityHealth(ped) <= 100)

                        -- Si el vehículo queda inmovilizado o volcado en persecución, salir y huir a pie
                        if IsPedInAnyVehicle(ped, false) then
                            local veh = GetVehiclePedIsIn(ped, false)
                            if GetVehicleEngineHealth(veh) <= 150.0 or IsVehicleStuckOnRoof(veh) or (GetEntitySpeed(veh) < 1.0 and #(pCoords - GetEntityCoords(veh)) < 20.0) then
                                TaskLeaveVehicle(ped, veh, 256)
                                TaskSmartFleePed(ped, playerPed, 200.0, -1, false, false)
                            end
                        end

                        if not (isDead or isCuffed) then
                            allNeutralized = false
                            break
                        end
                    end
                end

                if hasPeds and allNeutralized then
                    TriggerServerEvent("origen_police:server:completeCallout", id, "neutralized")
                    activeCallouts[id] = nil
                    configuredCallouts[id] = nil
                    CleanupCalloutEntities(id)
                end
            end
        end
    end
end)

-- ─── EVENTOS DE RED DE CLIENTE ────────────────────────────────

-- Recibir nuevo callout desde el servidor
RegisterNetEvent("origen_police:client:newCallout", function(calloutData)
    if not calloutData or not calloutData.id then return end

    -- Comprobar si el jugador tiene empleo policial o permiso de tablet
    local PlayerData = FW_GetPlayerData(false)
    local jobName = PlayerData and PlayerData.job and PlayerData.job.name
    local canOpen = jobName and CanOpenTablet(jobName)
    local isPolice = canOpen and canOpen[1]

    -- Si no es policía, no procesar el aviso ni crear blips
    if not isPolice then return end

    activeCallouts[calloutData.id] = calloutData

    -- Crear blip visible en el mapa directamente para todos los oficiales de servicio
    if not activeEntities[calloutData.id] or not activeEntities[calloutData.id].blips then
        local blips = CreateCalloutBlip(calloutData.coords, calloutData.title, calloutData.code)
        activeEntities[calloutData.id] = activeEntities[calloutData.id] or { peds = {}, vehicles = {}, blips = {}, spawned = false }
        activeEntities[calloutData.id].blips = blips
    end
end)

-- Fijar GPS a un aviso activo (opcional)
RegisterNetEvent("origen_police:client:calloutAccepted", function(callout)
    if not callout then return end

    local id = callout.id
    currentAcceptedCallout = id
    activeCallouts[id] = callout

    SetNewWaypoint(callout.coords.x, callout.coords.y)

    if not activeEntities[id] or not activeEntities[id].blips then
        local blips = CreateCalloutBlip(callout.coords, callout.title, callout.code)
        activeEntities[id] = activeEntities[id] or { peds = {}, vehicles = {}, blips = {}, spawned = false }
        activeEntities[id].blips = blips
    end

    if ShowNotification then
        ShowNotification("Ruta GPS fijada al aviso #" .. id)
    end
end)

-- Cancelar avisos
RegisterNetEvent("origen_police:client:cancelCallout", function(calloutId)
    if activeCallouts[calloutId] then
        activeCallouts[calloutId] = nil
    end
    CleanupCalloutEntities(calloutId)
end)

-- ─── COMANDOS DE JUGADOR ──────────────────────────────────────

RegisterCommand("aceptarcallout", function(source, args)
    local cId = tonumber(args[1])
    if not cId then
        -- Tomar el último callout activo disponible
        for id in pairs(activeCallouts) do
            cId = id
            break
        end
    end

    if cId and activeCallouts[cId] then
        TriggerServerEvent("origen_police:server:acceptCallout", cId)
    else
        if ShowNotification then
            ShowNotification("No hay avisos de callout activos para aceptar.")
        end
    end
end, false)

RegisterCommand("cancelarcallout", function()
    if currentAcceptedCallout then
        CleanupCalloutEntities(currentAcceptedCallout)
        if ShowNotification then
            ShowNotification("Llamada policial cancelada.")
        end
    end
end, false)
