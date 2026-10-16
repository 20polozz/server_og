if not Config.Confiscate then return end

function TakeOutImpound(vehicle, station)
    local coords = SpawnConfiscatedVehicles[station]
    if not coords then return ShowNotification("Esta comisaría no tiene punto de salida para los vehículos confiscados") end
    FW_TriggerCallback("origen_police:server:TakeOutConfiscatedVehicle", function(data)
        if not data then return end
        DoScreenFadeOut(250)
        Wait(1000)
        local vehModel = Config.Framework == "qbcore" and data.vehicle or json.decode(data.vehicle).model
        RequestModel(vehModel)
        while not HasModelLoaded(vehModel) do Wait(0) end
        local veh = CreateVehicle(vehModel, coords.x, coords.y, coords.z, coords.w, true, true)
        local vehProps = Config.Framework == "qbcore" and json.decode(data.mods) or json.decode(data.vehicle)
        if vehProps ~= nil and vehProps ~= {} then
            FW_SetVehicleProperties(veh, vehProps)
        end
        SetVehicleNumberPlateText(veh, data.plate)
        SetVehicleDirtLevel(veh, 0.0)
        SetEntityHeading(veh, coords.w)
        TriggerEvent('vehiclekeys:client:SetOwner', data.plate)
        SetVehicleEngineOn(veh, true, true)
        SetPedIntoVehicle(PlayerPedId(), veh, -1)
        Wait(600)
        DoScreenFadeIn(250)
    end, vehicle)
end

RegisterNetEvent("origen_police:client:openConfiscatedMenu", function(i, station, searchFilter)
    if not Config.Confiscate then
        return ShowNotification("El depósito de vehículos está desactivado")
    end
    local confiscatedVehs = nil
    local mapName = Config.Maps and Config.Maps[station] or station
    FW_TriggerCallback("origen_police:server:GetPlayerConfiscatedVehicles", function(data)
        if data == false then
            confiscatedVehs = false
        else
            confiscatedVehs = data or {}
        end
    end, mapName)
    while confiscatedVehs == nil do Wait(0) end

    if confiscatedVehs == false then
        return ShowNotification("No tienes autorización para acceder a los vehículos confiscados.", "error")
    end

    local menu = {
        {
            header = Config.Translations.ImpoundedVehicles or "Vehículos Confiscados",
            isMenuHeader = true,
        },
        {
            header = "🔍 Buscar Vehículo",
            txt = searchFilter and ("Filtro actual: " .. searchFilter) or "Filtrar por nombre o matrícula...",
            icon = "fa-solid fa-magnifying-glass",
            params = {
                isAction = true,
                event = function()
                    local input = exports['org-input']:ShowInput({
                        header = "Buscar Vehículo",
                        inputs = {
                            {
                                name = "value",
                                text = "Nombre de modelo, matrícula... etc",
                                type = "text",
                                isRequired = true
                            }
                        }
                    })
                    if input and input.value then
                        TriggerEvent("origen_police:client:openConfiscatedMenu", i, station, string.lower(input.value))
                    else
                        TriggerEvent("origen_police:client:openConfiscatedMenu", i, station, false)
                    end
                end
            }
        }
    }
    
    if searchFilter then
        table.insert(menu, {
            header = "❌ Borrar Búsqueda",
            txt = "Mostrar todos los vehículos.",
            icon = "fa-solid fa-xmark",
            params = {
                isAction = true,
                event = function()
                    TriggerEvent("origen_police:client:openConfiscatedMenu", i, station, false)
                end
            }
        })
    end

    if type(confiscatedVehs) ~= "table" then confiscatedVehs = {} end
    local count = 0
    for _, vehicle in pairs(confiscatedVehs) do
        local ownerName = "Desconocido"
        if vehicle.firstname and vehicle.lastname then
            ownerName = vehicle.firstname .. " " .. vehicle.lastname
        end
        local vehicleName = vehicle.vehicle or "Modelo Desconocido"
        
        -- Lógica de búsqueda
        local match = true
        if searchFilter and searchFilter ~= "" then
            local keyword = string.lower(searchFilter)
            local txtToSearch = string.lower(vehicleName .. " " .. vehicle.plate .. " " .. ownerName)
            if not string.find(txtToSearch, keyword) then
                match = false
            end
        end
        
        if match then
            count = count + 1
            table.insert(menu, {
                header = string.upper(vehicleName) .. " | " .. vehicle.plate,
                txt = "Propietario: " .. ownerName .. " - Multa: $" .. (vehicle.billPrice or 0),
                icon = "fa-solid fa-car",
                params = {
                    isAction = true,
                    event = function()
                        TakeOutImpound(vehicle.plate, station)
                    end
                }
            })
        end
    end

    if count == 0 then
        table.insert(menu, {
            header = searchFilter and "No hay resultados" or "Impound vacío",
            txt = searchFilter and "Ningún vehículo coincide con la búsqueda." or "No hay ningún vehículo confiscado actualmente.",
            icon = "fa-solid fa-xmark",
            isMenuHeader = true
        })
    end

    OpenMenu(menu)
end)