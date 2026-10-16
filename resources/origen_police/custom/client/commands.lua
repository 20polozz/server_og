RegisterCommand("qrr", function()
    Calls("QRR")
end)

RegisterCommand("QRR-B", function()
    Calls("QRR-B")
end)

RegisterCommand("QRR-C", function()
    Calls("QRR-C")
end)

RegisterCommand("10-20", function()
    Calls("10-20")
end)

function UseCommand(type, message)
    if type == 'me' then
        ExecuteCommand("me "..message)
    elseif type == 'do' then
        ExecuteCommand("do "..message)
    elseif type == 'rpol' or type == 'rnorte' or type == 'rsur' then
        ExecuteCommand(type.." "..message)
    else
        print("Invalid command type: " .. type)
    end
end

RegisterNetEvent("origen_police:client:onPlayerCall911", function(message)
    ShowNotification(Config.Translations["EntornoSent"] or "Se ha enviado el /entorno correctamente", "success")
end)

RegisterNetEvent("origen_police:client:onPlayerCall911ems", function(message)
    ShowNotification(Config.Translations["AuxilioSent"] or "Se ha enviado el /auxilio correctamente", "success")
end)

Config.PoliceConfig = Config.PoliceConfig or {}

RegisterNetEvent("origen_police:client:syncPoliceConfig", function(config)
    if config and type(config) == "table" then
        Config.PoliceConfig = config
        SendNUIMessage({ action = "syncPoliceConfig", config = config })
    end
end)

CreateThread(function()
    Wait(1500)
    if FW_TriggerCallback then
        FW_TriggerCallback("origen_police:admin:getPoliceConfig", function(config)
            if config and type(config) == "table" then
                Config.PoliceConfig = config
                SendNUIMessage({ action = "syncPoliceConfig", config = config })
            end
        end)
    else
        TriggerServerEvent("origen_police:client:requestPoliceConfig")
    end
end)

RegisterCommand("pboat", function()
    local PlayerData = FW_GetPlayerData(false)
    local isAllowed = false
    
    if PlayerData and PlayerData.job then
        local userData = CanOpenTablet(PlayerData.job.name)
        if userData and userData[1] then
            isAllowed = true
        end
    end

    if not isAllowed then
        ShowNotification(Config.Translations['NoPermission'] or "No tienes permiso para usar este comando.", "error")
        return
    end

    local ped = PlayerPedId()

    -- Si el jugador ya está montado en una embarcación, permitir guardarla
    if IsPedInAnyVehicle(ped, false) then
        local currentVeh = GetVehiclePedIsIn(ped, false)
        if GetVehicleClass(currentVeh) == 14 then -- 14 = Barcos / Embarcaciones
            ProgressBar("stowing_boat", "Guardando embarcación...", 3000, false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }, {}, {}, {}, function() -- Done
                DeleteVehicle(currentVeh)
                ShowNotification("Embarcación guardada con éxito.", "success")
            end, function()
                ShowNotification("Acción cancelada.", "error")
            end)
            return
        end
    end

    if not IsEntityInWater(ped) then
        ShowNotification(Config.Translations['NotInWater'] or "Debes estar en el agua para desplegar la embarcación.", "error")
        return
    end

    -- Obtener modelo de barco configurado desde el police admin
    local jobName = (PlayerData and PlayerData.job) and PlayerData.job.name or nil
    local boatModel = "predator"
    local deployDuration = 15000

    if Config.PoliceConfig then
        if Config.PoliceConfig.boatDeployDuration and tonumber(Config.PoliceConfig.boatDeployDuration) then
            deployDuration = tonumber(Config.PoliceConfig.boatDeployDuration)
        end
        if jobName and Config.PoliceConfig.boatJobModels and Config.PoliceConfig.boatJobModels[jobName] and Config.PoliceConfig.boatJobModels[jobName] ~= "" then
            boatModel = Config.PoliceConfig.boatJobModels[jobName]
        elseif Config.PoliceConfig.boatModel and Config.PoliceConfig.boatModel ~= "" then
            boatModel = Config.PoliceConfig.boatModel
        end
    end

    local modelHash = GetHashKey(boatModel)
    if not IsModelInCdimage(modelHash) or not IsModelAVehicle(modelHash) then
        if boatModel ~= "predator" and IsModelInCdimage(GetHashKey("predator")) then
            ShowNotification("El modelo configurado '" .. tostring(boatModel) .. "' no existe. Usando embarcación predeterminada (predator).", "warning")
            boatModel = "predator"
            modelHash = GetHashKey("predator")
        else
            ShowNotification("El modelo de embarcación ('" .. tostring(boatModel) .. "') no existe o no es válido en el servidor.", "error")
            return
        end
    end

    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    ProgressBar("spawning_boat", "Preparando embarcación...", deployDuration, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = "random@arrests",
        anim = "generic_radio_chatter",
        flags = 49,
    }, {}, {}, function() -- Done
        ClearPedTasks(ped)

        RequestModel(modelHash)
        local loadTimeout = 0
        while not HasModelLoaded(modelHash) and loadTimeout < 300 do
            Wait(10)
            loadTimeout = loadTimeout + 1
        end

        local vehicle = CreateVehicle(modelHash, coords.x, coords.y, coords.z, heading, true, false)
        local timeout = 0
        while not DoesEntityExist(vehicle) and timeout < 100 do
            Wait(10)
            timeout = timeout + 1
        end

        if DoesEntityExist(vehicle) then
            if PlayerData.job then
                local jName = PlayerData.job.name
                local livery = nil
                if jName == "ambulance" then
                    livery = 2
                elseif jName == "police" or jName == "sapd" then
                    livery = 0
                elseif jName == "sheriff" then
                    livery = 1
                end

                if livery then
                    SetVehicleModKit(vehicle, 0)
                    SetVehicleMod(vehicle, 48, livery, false)
                    SetVehicleLivery(vehicle, livery)
                end
            end
            SetPedIntoVehicle(ped, vehicle, -1)
            SetVehicleEngineOn(vehicle, true, true, false)
            SetEntityAsMissionEntity(vehicle, true, true)
            GiveKeys("boat", vehicle)
            SetVehicleFuelLevel(vehicle, 100.0)
            if GetResourceState('LegacyFuel') == 'started' then
                exports['LegacyFuel']:SetFuel(vehicle, 100.0)
            elseif GetResourceState('origen_fuel') == 'started' then
                exports['origen_fuel']:SetFuel(vehicle, { fuel = 100.0 })
            end
            ShowNotification("Embarcación desplegada con éxito.", "success")
        end
    end, function() -- Cancel
        ClearPedTasks(ped)
        ShowNotification("Despliegue cancelado.", "error")
    end)
end)