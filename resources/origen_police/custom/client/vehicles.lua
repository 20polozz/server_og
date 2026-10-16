function ConfiscateVeh(stationName, actionType)
    local vehicle = GetVehicleInCamera()

    if vehicle ~= 0 and #(GetEntityCoords(vehicle) - GetEntityCoords(PlayerPedId())) < 5 then
        if IsEntityPositionFrozen(vehicle) then
            ShowNotification(Config.Translations.InvalidVehicleToConfiscate)
            return
        end

        local attempt = 0
        while not NetworkHasControlOfEntity(vehicle) and attempt < 100 and DoesEntityExist(vehicle) do
            Wait(100)
            NetworkRequestControlOfEntity(vehicle)
            attempt = attempt + 1
        end

        if DoesEntityExist(vehicle) and NetworkHasControlOfEntity(vehicle) then
            local plate = GetVehiclePlate(vehicle)
            
            if actionType == 'confiscate' then
                local elements = {
                    {
                        header = "Selecciona una comisaría",
                        isMenuHeader = true
                    },
                    {
                        header = "Cerrar menú",
                        txt = "Cancelar",
                        params = {
                            isAction = true,
                            event = function() end
                        }
                    }
                }
                
                local hasStations = false
                if Config.Maps then
                    for mapIndex, mapName in pairs(Config.Maps) do
                        if SpawnConfiscatedVehicles and SpawnConfiscatedVehicles[mapIndex] then
                            hasStations = true
                            local label = (MapOptions and MapOptions[mapIndex] and MapOptions[mapIndex].label) or mapName
                            table.insert(elements, {
                                header = label,
                                txt = "Confiscar en la base de " .. label,
                                icon = "fa-solid fa-building-shield",
                                params = {
                                    isAction = true,
                                    event = function()
                                        local billPrice = 0
                                        OpenMenu('dialog', GetCurrentResourceName(), 'confiscate_price', {
                                            title = "MULTA DE CONFISCACIÓN"
                                        }, function(data, menu)
                                            if data and data.value and tonumber(data.value) then
                                                billPrice = tonumber(data.value)
                                                
                                                if GetResourceState("org_parking") == "started" then
                                                    pcall(function()
                                                        exports['org_parking']:confiscateVehicle(vehicle)
                                                    end)
                                                end
                                                
                                                TriggerServerEvent("origen_police:server:ImpoundCust", plate, billPrice, mapName)
                                                ExecuteCommand("do Llegaría una grúa y se llevaría el vehículo")
                                                for i = 100, 0, -1 do
                                                    SetEntityAlpha(vehicle, i, false)
                                                    Wait(15)
                                                end
                                                SetEntityAsMissionEntity(vehicle, 1, 1)
                                                DeleteVehicle(vehicle)
                                                ShowNotification(Config.Translations.VehicleConfiscated)
                                                menu.close()
                                            else
                                                ShowNotification(Config.Translations.MustEnterNumber)
                                            end
                                        end, function(data, menu)
                                            menu.close()
                                        end)
                                    end
                                }
                            })
                        end
                    end
                end

                if not hasStations then
                    table.insert(elements, {
                        header = "Depósito por defecto",
                        txt = "Confiscar en base general",
                        icon = "fa-solid fa-warehouse",
                        params = {
                            isAction = true,
                            event = function()
                                local billPrice = 0
                                OpenMenu('dialog', GetCurrentResourceName(), 'radarmaxspeed', {
                                    title = "Precio"
                                }, function(data, menu)
                                    if data and data.value and tonumber(data.value) then
                                        billPrice = tonumber(data.value)
                                        
                        if GetResourceState("org_parking") == "started" then
                                                    pcall(function()
                                                        exports['org_parking']:confiscateVehicle(vehicle)
                                                    end)
                                                end
                                                
                                                TriggerServerEvent("origen_police:server:ImpoundCust", plate, billPrice, stationName)
                                        ExecuteCommand("do Llegaría una grúa y se llevaría el vehículo")
                                        for i = 100, 0, -1 do
                                            SetEntityAlpha(vehicle, i, false)
                                            Wait(15)
                                        end
                                        SetEntityAsMissionEntity(vehicle, 1, 1)
                                        DeleteVehicle(vehicle)
                                        ShowNotification(Config.Translations.VehicleConfiscated)
                                        menu.close()
                                    else
                                        ShowNotification(Config.Translations.MustEnterNumber)
                                    end
                                end, function(data, menu)
                                    menu.close()
                                end)
                            end
                        }
                    })
                end

                OpenMenu(elements)
            else
                -- DV behavior with Depot Selection
                local garages = {}
                if GetResourceState("origen_garages") == "started" then
                    garages = lib.callback.await('origen_garages:cb:getGarages', false)
                end
                
                local elements = {
                    {
                        header = "Selecciona un depósito o garaje",
                        icon = "fa-solid fa-truck-pickup",
                        isMenuHeader = true
                    },
                    {
                        header = "Cerrar menú",
                        icon = "fa-solid fa-xmark",
                        txt = "Cancelar confiscación",
                        params = {
                            isAction = true,
                            event = function() end
                        }
                    }
                }
                
                if not garages or #garages == 0 then
                    table.insert(elements, {
                        header = "Depósito por defecto",
                        icon = "fa-solid fa-warehouse",
                        txt = "Enviar al depósito predeterminado",
                        params = {
                            isAction = true,
                            event = function()
                                if GetResourceState("org_parking") == "started" then
                                    pcall(function()
                                        exports['org_parking']:confiscateVehicle(vehicle)
                                    end)
                                end
                                
                                TriggerServerEvent("origen_police:server:DVVehicle", plate, "deposito")
                                ExecuteCommand("do Llegaría una grúa y se llevaría el vehículo")
                                
                                for i = 100, 0, -1 do
                                    SetEntityAlpha(vehicle, i, false)
                                    Wait(15)
                                end
                                SetEntityAsMissionEntity(vehicle, 1, 1)
                                DeleteVehicle(vehicle)
                                ShowNotification("Vehículo confiscado al depósito por defecto")
                            end
                        }
                    })
                else
                    for _, garage in pairs(garages) do
                        local isValidDepot = false
                        if type(garage.states) == "table" then
                            for _, state in ipairs(garage.states) do
                                if tonumber(state) == 0 then
                                    isValidDepot = true
                                    break
                                end
                            end
                        end
                        
                        if isValidDepot then
                            table.insert(elements, {
                                header = garage.label or garage.name,
                                icon = "fa-solid fa-warehouse",
                                txt = "Enviar a " .. garage.name,
                                params = {
                                    isAction = true,
                                    event = function()
                                        if GetResourceState("org_parking") == "started" then
                                            pcall(function()
                                                exports['org_parking']:confiscateVehicle(vehicle)
                                            end)
                                        end
                                        
                                        TriggerServerEvent("origen_police:server:DVVehicle", plate, garage.name)
                                        ExecuteCommand("do Llegaría una grúa y se llevaría el vehículo")
                                        
                                        for i = 100, 0, -1 do
                                            SetEntityAlpha(vehicle, i, false)
                                            Wait(15)
                                        end
                                        SetEntityAsMissionEntity(vehicle, 1, 1)
                                        DeleteVehicle(vehicle)
                                        ShowNotification("Vehículo enviado a " .. (garage.label or garage.name))
                                    end
                                }
                            })
                        end
                    end
                end
                
                OpenMenu(elements)
            end
        end
    else
        ShowNotification(Config.Translations.MustLook)
    end
end

function AddVehicleExtras(vtype, vehicle, model)
    -- @vtype: vehicle type (car, boat, helicopter)
    -- @vehicle: vehicle entity id
    -- @model: vehicle model name
    
    -- if vtype == 'car' then
    --     SetVehicleMod(vehicle, 11, 2, false) -- Engine
    --     SetVehicleMod(vehicle, 12, 2, false) -- Brakes
    -- elseif vtype == 'boat' then

    -- elseif vtype == 'helicopter' then

    -- end
end

function GetVehiclePlate(vehicle)
    return GetVehicleNumberPlateText(vehicle)
end

function GiveKeys(vtype, vehicle)
    -- @vtype: vehicle type (car, boat, helicopter)
    -- @vehicle: vehicle entity id
end

function RemoveKeys(vehicle)
    -- @vehicle: vehicle entity id
end

function SetVehicleFuel(vehicle, fuel)
    -- @vehicle: vehicle entity id
    -- @fuel: fuel level (0-100)
    if GetResourceState("LegacyFuel") == "started" then
        exports['LegacyFuel']:SetFuel(vehicle, fuel)
    else
        SetVehicleFuelLevel(vehicle, fuel)
    end
end