local stationRepairState = {}
local RepairingVehicles = {}
local isThreadRunning = false

RegisterNetEvent("origen_police:client:ActiveStationRepair", function(data)
    if data and data.station then
        stationRepairState[data.station] = (data.active == true or data.active == 1 or data.active == '1')
    end
end)

RegisterNetEvent("origen_police:client:syncSingleStationData", function(stationName, stationData)
    if stationData and stationData.Options and stationData.Options.repair_active ~= nil then
        stationRepairState[stationName] = (stationData.Options.repair_active == true or stationData.Options.repair_active == 1 or stationData.Options.repair_active == '1')
    end
end)

local function IsStationRepairActive(stationName)
    if stationRepairState[stationName] ~= nil then
        return stationRepairState[stationName]
    end
    if CachedMapData and CachedMapData[stationName] and CachedMapData[stationName].Options and CachedMapData[stationName].Options.repair_active ~= nil then
        local optActive = CachedMapData[stationName].Options.repair_active
        return (optActive == true or optActive == 1 or optActive == '1')
    end
    return true
end

-- (Aqui iba DrawSubtitle, un subtitulo nativo al que ya nadie llamaba:
-- la reparacion se enseña con la barra y las teclas del HUD.)

--- Lo que se ve dentro del coche en reparacion: barra de progreso y tecla X.
local mostrandoEn = nil

local function MostrarReparacion(netId, restanteMs)
    mostrandoEn = netId
    pcall(function() exports.origen_hud:ShowProgress(restanteMs, 'Mantenimiento en curso') end)
    pcall(function() exports.origen_hud:setupControls({ { key = 'X', text = 'Cancelar' } }) end)
end

local function OcultarReparacion()
    if not mostrandoEn then return end
    mostrandoEn = nil
    pcall(function() exports.origen_hud:HideProgress() end)
    pcall(function() exports.origen_hud:hideControls() end)
end

local function StartRepairWatchThread()
    if isThreadRunning then return end
    isThreadRunning = true

    CreateThread(function()
        while next(RepairingVehicles) ~= nil do
            local sleep = 500
            local ped = PlayerPedId()
            local currentVeh = GetVehiclePedIsIn(ped, false)
            local visto = false

            for netId, data in pairs(RepairingVehicles) do
                if NetworkDoesNetworkIdExist(netId) then
                    local veh = NetworkGetEntityFromNetworkId(netId)
                    if veh and veh ~= 0 and DoesEntityExist(veh) then
                        -- Mantener el vehículo estático y motor apagado mientras se repara
                        FreezeEntityPosition(veh, true)
                        SetVehicleHandbrake(veh, true)

                        local remainingMs = math.max(0, data.endTime - GetGameTimer())
                        local remainingSec = math.ceil(remainingMs / 1000)
                        local timeStr = string.format("%02d:%02d", math.floor(remainingSec / 60), remainingSec % 60)

                        -- Si el jugador está dentro de este vehículo
                        if currentVeh == veh then
                            sleep = 0
                            -- Desactivar aceleración, freno y dirección
                            DisableControlAction(0, 71, true) -- Accelerate
                            DisableControlAction(0, 72, true) -- Brake/Reverse
                            DisableControlAction(0, 63, true) -- Vehicle Steer Left
                            DisableControlAction(0, 64, true) -- Vehicle Steer Right

                            -- Con la barra y las ayudas de tecla del HUD (nuestro estilo), no con
                            -- el subtitulo de GTA. Se ponen una vez al subir y se quitan al bajar.
                            if mostrandoEn ~= netId then
                                MostrarReparacion(netId, remainingMs)
                            end
                            visto = true

                            -- Detectar cancelación con tecla [X] (control 73)
                            if IsControlJustPressed(0, 73) then
                                TriggerServerEvent("origen_police:server:cancelVehicleRepair", netId)
                            end
                        end
                    else
                        RepairingVehicles[netId] = nil
                    end
                else
                    RepairingVehicles[netId] = nil
                end
            end

            -- Se bajo del coche o la reparacion acabo: fuera la barra y la tecla.
            if not visto then OcultarReparacion() end

            Wait(sleep)
        end
        OcultarReparacion()
        isThreadRunning = false
    end)
end

RegisterNetEvent("origen_police:client:setVehicleRepairState", function(netId, isRepairing, duration)
    local netIdNum = tonumber(netId)
    if not netIdNum then return end

    if isRepairing then
        RepairingVehicles[netIdNum] = {
            endTime = GetGameTimer() + (tonumber(duration or 120) * 1000),
            totalDuration = duration or 120
        }
        if NetworkDoesNetworkIdExist(netIdNum) then
            local vehicle = NetworkGetEntityFromNetworkId(netIdNum)
            if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
                FreezeEntityPosition(vehicle, true)
                SetVehicleHandbrake(vehicle, true)
                SetVehicleEngineOn(vehicle, false, false, true)
            end
        end
        StartRepairWatchThread()
    else
        RepairingVehicles[netIdNum] = nil
        if NetworkDoesNetworkIdExist(netIdNum) then
            local vehicle = NetworkGetEntityFromNetworkId(netIdNum)
            if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
                FreezeEntityPosition(vehicle, false)
                SetVehicleHandbrake(vehicle, false)
            end
        end
    end
end)

local function IsPoliceAdminVehicle(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return false end
    local modelHash = GetEntityModel(vehicle)

    if Config.ExtraVehiclesHashes and Config.ExtraVehiclesHashes[modelHash] then
        return true
    end

    if Config.ExtraVehicles then
        for modelName, _ in pairs(Config.ExtraVehicles) do
            local clean = tostring(modelName):lower():gsub("%s+", "")
            if GetHashKey(clean) == modelHash or GetHashKey(modelName) == modelHash then
                return true
            end
        end
    end

    return false
end

RegisterNetEvent("origen_police:client:repairveh", function(mapIndex, markerIndex, stationName)
    if stationName and not IsStationRepairActive(stationName) then
        ShowNotification("El punto de reparación de esta comisaría se encuentra desactivado por administración.", "error")
        return
    end

    local ped = PlayerPedId()
    local insideVehicle = IsPedInAnyVehicle(ped, false)
    local targetVeh = 0

    if insideVehicle then
        targetVeh = GetVehiclePedIsIn(ped, false)
    else
        local pCoords = GetEntityCoords(ped)
        targetVeh = GetClosestVehicle(pCoords.x, pCoords.y, pCoords.z, 6.0, 0, 71)
    end

    if not targetVeh or targetVeh == 0 or not DoesEntityExist(targetVeh) then
        ShowNotification("No hay ningún vehículo cerca para reparar.", "error")
        return
    end

    local netId = NetworkGetNetworkIdFromEntity(targetVeh)
    if not netId or netId == 0 then
        ShowNotification("No se ha podido sincronizar el vehículo.", "error")
        return
    end

    if RepairingVehicles[netId] then
        ShowNotification("Este vehículo ya está en proceso de mantenimiento.", "info")
        return
    end

    local function proceedWithRepair()
        if not IsPoliceAdminVehicle(targetVeh) then
            ShowNotification("Solo los vehículos configurados en el police admin se pueden reparar.", "error")
            return
        end

        TriggerServerEvent("origen_police:server:startVehicleRepair", netId, stationName)
    end

    if not Config.ExtraVehicles or next(Config.ExtraVehicles) == nil then
        FW_TriggerCallback("origen_police:admin:getExtraVehicles", function(extraVehs)
            if extraVehs then
                Config.ExtraVehicles = extraVehs
                Config.ExtraVehiclesHashes = {}
                for model, data in pairs(Config.ExtraVehicles) do
                    Config.ExtraVehiclesHashes[GetHashKey(model)] = data
                end
            end
            proceedWithRepair()
        end)
    else
        proceedWithRepair()
    end
end)

RegisterNetEvent("origen_police:client:finishRepairVehicle", function(netId)
    local netIdNum = tonumber(netId)
    if not netIdNum then return end

    if not NetworkDoesNetworkIdExist(netIdNum) then return end
    local vehicle = NetworkGetEntityFromNetworkId(netIdNum)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end

    FreezeEntityPosition(vehicle, false)
    SetVehicleHandbrake(vehicle, false)
    SetVehicleFixed(vehicle)
    SetVehicleDeformationFixed(vehicle)
    SetVehicleUndriveable(vehicle, false)
    SetVehicleEngineOn(vehicle, true, true)
    SetVehicleEngineHealth(vehicle, 1000.0)
    SetVehicleBodyHealth(vehicle, 1000.0)
    SetVehiclePetrolTankHealth(vehicle, 1000.0)
    SetVehicleDirtLevel(vehicle, 0.0)
    WashDecalsFromVehicle(vehicle, 1.0)
    RemoveDecalsFromVehicle(vehicle)

    for i = 0, 7 do
        SetVehicleTyreFixed(vehicle, i)
    end

    SetVehicleFuelLevel(vehicle, 100.0)
    if GetResourceState('LegacyFuel') == 'started' then
        exports['LegacyFuel']:SetFuel(vehicle, 100.0)
    elseif GetResourceState('origen_fuel') == 'started' then
        exports['origen_fuel']:SetFuel(vehicle, { fuel = 100.0 })
    end
end)

-- Solicitar reparaciones activas y sincronización de vehículos al cargar el recurso
CreateThread(function()
    Wait(2000)
    TriggerServerEvent("origen_police:server:requestRepairingVehicles")
    TriggerServerEvent("origen_police:admin:requestExtraVehiclesSync")
end)
