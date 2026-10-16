local function GetSeatName(seatIndex)
    if seatIndex == -1 then return locale:t('quickmenu.vehicle.driver') or "Conductor" end
    if seatIndex == 0 then return locale:t('quickmenu.vehicle.copilot') or "Copiloto" end
    return (locale:t('quickmenu.vehicle.rear_seat') or "Asiento Trasero") .. " " .. seatIndex
end

local function GetFreeSeats(vehicle)
    local freeSeats = {}
    local maxSeats = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle))
    
    for i = -1, maxSeats - 2 do
        if IsVehicleSeatFree(vehicle, i) then
            table.insert(freeSeats, {
                index = i,
                name = GetSeatName(i)
            })
        end
    end
    return freeSeats
end

local function GetVehiclePassengers(vehicle)
    local passengers = {}
    local maxSeats = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle))

    for i = -1, maxSeats - 2 do
        if not IsVehicleSeatFree(vehicle, i) then
            local ped = GetPedInVehicleSeat(vehicle, i)
            if ped ~= 0 and IsPedAPlayer(ped) then
                local playerId = NetworkGetPlayerIndexFromPed(ped)
                local serverId = GetPlayerServerId(playerId)
                table.insert(passengers, {
                    seatIndex = i,
                    seatName = GetSeatName(i),
                    serverId = serverId,
                    name = GetPlayerName(playerId)
                })
            end
        end
    end
    return passengers
end

RegisterNetEvent('origen_gang:client:openPutInVehicleMenu', function(targetId)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local vehicle = lib.getClosestVehicle(coords, 5.0, true)
    
    if not vehicle then 
        Notify.SendNotify(locale:t('quickmenu.vehicle.no_vehicle_nearby') or "No hay vehículo cerca", 'error')
        return 
    end

    local freeSeats = GetFreeSeats(vehicle)
    if #freeSeats == 0 then
        Notify.SendNotify(locale:t('quickmenu.vehicle.no_free_seats') or "No hay asientos libres", 'error')
        return
    end

    local menuOptions = {
        {
            header = locale:t('quickmenu.vehicle.select_seat') or "Seleccionar Asiento",
            isMenuHeader = true,
            icon = "fa-solid fa-car"
        }
    }

    for _, seat in ipairs(freeSeats) do
        table.insert(menuOptions, {
            header = seat.name,
            txt = "",
            icon = "fa-solid fa-chair",
            params = {
                isServer = true,
                event = "origen_gang:server:putPlayerInSeat",
                args = {
                    targetId = targetId,
                    vehicleNetId = VehToNet(vehicle),
                    seatIndex = seat.index
                }
            }
        })
    end

    -- Dentro del panel de banda, con su cuadro (ver ElegirEnPanel).
    ElegirEnPanel(menuOptions, {
        confirmar = locale:t('quickmenu.actions.put_in_vehicle.label'),
        etiqueta  = locale:t('quickmenu.vehicle.seat_field'),
    })
end)

RegisterNetEvent('origen_gang:client:openTakeFromVehicleMenu', function(vehicleNetId)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local vehicle = nil
    
    -- If passed netId, try to get it, otherwise find closest
    if vehicleNetId then
        vehicle = NetToVeh(vehicleNetId)
    end
    
    if not vehicle or vehicle == 0 then
        vehicle = lib.getClosestVehicle(coords, 5.0, true)
    end

    if not vehicle or vehicle == 0 then
        Notify.SendNotify(locale:t('quickmenu.vehicle.no_vehicle_nearby') or "No hay vehículo cerca", 'error')
        return
    end

    local passengers = GetVehiclePassengers(vehicle)
    if #passengers == 0 then
        Notify.SendNotify(locale:t('quickmenu.vehicle.no_passengers') or "No hay pasajeros en el vehículo", 'error')
        return
    end

    local menuOptions = {
        {
            header = locale:t('quickmenu.vehicle.select_player') or "Seleccionar Jugador",
            isMenuHeader = true,
            icon = "fa-solid fa-user-minus"
        }
    }

    for _, p in ipairs(passengers) do
        table.insert(menuOptions, {
            header = p.name .. " (" .. p.seatName .. ")",
            txt = "ID: " .. p.serverId,
            icon = "fa-solid fa-user",
            params = {
                isServer = true,
                event = "origen_gang:server:outPlayerFromVehicle",
                args = {
                    targetId = p.serverId
                }
            }
        })
    end

    ElegirEnPanel(menuOptions, {
        confirmar = locale:t('quickmenu.actions.take_out_vehicle.label'),
        etiqueta  = locale:t('quickmenu.vehicle.passenger_field'),
    })
end)

RegisterNetEvent('origen_gang:client:warpIntoVehicle', function(vehicleNetId, seatIndex)
    local vehicle = NetToVeh(vehicleNetId)
    if DoesEntityExist(vehicle) then
        local ped = PlayerPedId()
        TaskWarpPedIntoVehicle(ped, vehicle, seatIndex)
    end
end)

RegisterNetEvent('origen_gang:client:forceExitVehicle', function()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        TaskLeaveAnyVehicle(ped, 0, 0)
    end
end)
