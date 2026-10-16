__indexGarages = {}
for id, garage in ipairs(Config.GarageInteriors) do
    __indexGarages[garage.model] = id
end

Garage = {
    inside = false,
    floors = {},
}

Garage.CreateInteriorGarage = function(data)
    if not data.coords or not data.exit or not data.id then return end
    local slots = lib.table.deepclone(data.slots)
    data.vehicles = slots

    debugger('Creating interior garage', data.id)
    local vehicles, dimension = lib.callback.await('origen_garages:server:getVehicles', false, data.id, data.houseID)

    if not vehicles then debugger('No vehicles found in garage', data.id) end
    if not dimension then debugger('No dimension found for garage', data.id) end

    for i = 1, #vehicles do
        local index = vehicles[i].garage:gsub(data.id .. "_", "")
        index = tonumber(index)
        if index and data.vehicles and data.vehicles[index] then
            data.vehicles[index].mods = json.decode(vehicles[i].mods)
            data.vehicles[index].vehicle = data.vehicles[index].mods.model
            data.vehicles[index].parked = true
            data.vehicles[index].owner = vehicles[i].identifier
        end
    end

    currentExteriorHouseID = false
    currentInteriorHouseID = false

    debugger('Updating dimension', dimension)    
    Garage.ChangeDimension(dimension)

    Garage.TeleportGarage(data.coords, true)
    Garage.inside = true

    Custom.OnEnterGarage(data.houseID)
    
    if data.on and data.on.join then
        data.on.join(GetVehiclePedIsIn(PlayerPedId()))
    end

    if data.vehicles and next(data.vehicles) then
        Garage.LoadVehicles(data.vehicles, data.houseID)
    end

    DoScreenFadeIn(500)
    
    CreateThread(function()
        while true do
            local sleep = 1000
            local ped = PlayerPedId()
            local pCoords = GetEntityCoords(ped)
            local exit_dist = #(pCoords - vector3(data.coords.x, data.coords.y, data.coords.z))

            if exit_dist < 30 then
                sleep = 0
                DrawMarker(Config.Markers.general.type, vector3(data.coords.x, data.coords.y, data.coords.z), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Markers.general.size.x, Config.Markers.general.size.y, Config.Markers.general.size.z, Config.Markers.general.color[1], Config.Markers.general.color[2], Config.Markers.general.color[3], Config.Markers.general.color[4], Config.Markers.general.bobUpAndDown, Config.Markers.general.faceCamera, 2, Config.Markers.general.rotate, nil, false)
                
                if exit_dist < 3 then 
                    if not data.exitnoty then
                        Internal.DrawText(Config.Translations.drawtext.exit, 'E')
                        data.exitnoty = true
                    end
                    if IsControlJustPressed(0, 38) then
                        if data.exitnoty then
                            Internal.HideText()
                            data.exitnoty = nil
                        end
                        Garage.TeleportGarage(data.exit)
                        Garage.ChangeDimension(0)
                        if data.on and data.on.leave then
                            data.on.leave(GetVehiclePedIsIn(ped))
                        end
                        Custom.OnExitGarage(data.houseID)
                        data = nil
                        Garage.inside = false
                        Garage.ClearCache()
                        break
                    end
                else
                    if data.exitnoty then
                        Internal.HideText()
                        data.exitnoty = nil
                    end
                end
            end

            if data.floors and next(data.floors) then
                Garage.floors = data.floors
                local veh = GetVehiclePedIsIn(ped, false)
                if veh ~= 0 then
                    for id, v in pairs(data.floors) do
                        local floor_dist = #(pCoords - vector3(v.coords.x, v.coords.y, v.coords.z))

                        if floor_dist < 30 then
                            sleep = 0
                            DrawMarker(Config.Markers.general.type, vector3(v.coords.x, v.coords.y, v.coords.z), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Markers.general.size.x, Config.Markers.general.size.y, Config.Markers.general.size.z, Config.Markers.general.color[1], Config.Markers.general.color[2], Config.Markers.general.color[3], Config.Markers.general.color[4], Config.Markers.general.bobUpAndDown, Config.Markers.general.faceCamera, 2, Config.Markers.general.rotate, nil, false)
                            if floor_dist < 3 then
                                if not v.floornoty then
                                    Internal.DrawText(Config.Translations.drawtext.elevator, 'E')
                                    v.floornoty = true
                                end
                                if IsControlJustPressed(0, 38) then     
                                    Nui.ToggleElevatorMenu(true, {
                                        floors = data.floors,
                                        floor = id - 1,
                                    })
                                end
                            else
                                if v.floornoty then
                                    Internal.HideText()
                                    v.floornoty = nil
                                end
                            end
                        else
                            if v.floornoty then
                                Internal.HideText()
                                v.floornoty = nil
                            end
                        end
                    end
                end
            end

            if data.vehicles then
                local veh = GetVehiclePedIsIn(ped, false)
                if veh ~= 0 then
                    sleep = 0
                    if IsEntityPositionFrozen(veh) then
                        if not data.unparknoty then
                            Internal.DrawText(Config.Translations.drawtext.unpark, 'E')
                            data.unparknoty = true
                        end
                        if IsControlJustPressed(0, 38) then
                            for i = 1, #data.vehicles do
                                local v = data.vehicles[i]
                                local plate = nil
                                local vehiclePlate = GetVehicleNumberPlateText(veh):gsub("%s+", "")
                                if v.mods and v.mods.plate then 
                                    plate = tostring(v.mods.plate):gsub("%s+", "")
                                end                                
                                debugger('Checking if vehicle is parked', plate, vehiclePlate)
                                if vehiclePlate == plate then 
                                    if v.parked then
                                        local canUnParkVehicle = lib.callback.await('origen_garages:server:UnParkVehicle', false, plate)
    
                                        if canUnParkVehicle then 
                                            v.parked = false
                                            FreezeEntityPosition(veh, false)
                                            Entity(veh).state:set('parked', false, true)
                                            Entity(veh).state:set('parking', nil, true)
                                            Internal.GiveVehicleKeys(veh, v.mods.plate, 'give')
                                        else
                                            Internal.Notify(Config.Translations.notify.error.noKeyVehicle, 'error', 3000)
                                        end
                                    end
                                    break
                                end
                            end
                        end
                    else
                        if data.unparknoty then
                            Internal.HideText()
                            data.unparknoty = nil
                        end
                        for i = 1, #data.vehicles do
                            local v = data.vehicles[i]
                            local distance = #(pCoords - vector3(v.coords.x, v.coords.y, v.coords.z))
                            if distance < 30 and not v.parked then
                                sleep = 0
                                DrawMarker(Config.Markers.general.type, vector3(v.coords.x, v.coords.y, v.coords.z), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Markers.general.size.x, Config.Markers.general.size.y, Config.Markers.general.size.z, Config.Markers.general.color[1], Config.Markers.general.color[2], Config.Markers.general.color[3], Config.Markers.general.color[4], Config.Markers.general.bobUpAndDown, Config.Markers.general.faceCamera, 2, Config.Markers.general.rotate, nil, false)
                                if distance < 2 then
                                    if not v.parknoty then
                                        Internal.DrawText(Config.Translations.drawtext.park, 'E')
                                        v.parknoty = true
                                    end
                                    if IsControlJustPressed(0, 38) then
                                        if not v.parked then
                                            local mods = Custom.GetVehicleMods(veh)
                                            local canParkVehicle = lib.callback.await('origen_garages:server:ParkVehicle', false, data.id..'_'..i, mods.plate, json.encode(mods))

                                            if canParkVehicle then 
                                                SetEntityCoords(veh, vector3(v.coords.x, v.coords.y, v.coords.z))
                                                SetEntityHeading(veh, v.coords.w)
                                                SetEntityAsMissionEntity(veh, true, true)
                                                FreezeEntityPosition(veh, true)
                                                Entity(veh).state:set('parked', true, true)
                                                Entity(veh).state:set('parking', data.houseID, true)
                                                v.parked = true
                                                v.owner = canParkVehicle
                                                v.mods = mods
                                                Internal.GiveVehicleKeys(veh, v.mods.plate, 'remove')
                                                if v.parknoty then
                                                    Internal.HideText()
                                                    v.parknoty = nil
                                                end
                                            else
                                                Internal.Notify(Config.Translations.notify.error.noKeyVehicle, 'error', 3000)
                                            end
                                        end
                                    end
                                    break
                                elseif v.parknoty then
                                    Internal.HideText()
                                    v.parknoty = nil
                                end
                            elseif v.parknoty then
                                Internal.HideText()
                                v.parknoty = nil
                            end
                        end
                    end
                else
                    if data.unparknoty then
                        Internal.HideText()
                        data.unparknoty = nil
                    end
                end
            end

            Wait(sleep)
        end
    end)
end

Garage.LoadVehicles = function(table, id)
    for i = 1, #table do
        local v = table[i]

        if v.parked then
            local coords = vector3(v.coords.x, v.coords.y, v.coords.z - 1)
            local closestVehicle = Custom.GetClosestVehicle(coords)
            if not NetworkGetEntityIsNetworked(closestVehicle) or (closestVehicle and Entity(closestVehicle).state.parking ~= nil) and tonumber(Entity(closestVehicle).state.parking) ~= id then
                SetEntityAsMissionEntity(closestVehicle, true, true)
                DeleteEntity(closestVehicle)
                closestVehicle = nil
            end

            if closestVehicle and #(coords - GetEntityCoords(closestVehicle)) > 2 then
                local wait = true
                Garage.SpawnVehicle(v.vehicle, function(vehicle)
                    SetEntityCoords(vehicle, coords)

                    if v.mods then
                        v.mods = type(v.mods) == "table" and v.mods or json.decode(v.mods)
                        Custom.SetVehicleProperties(vehicle, v.mods)
                    else
                        SetVehicleExtraColours(vehicle, 0, 0)
                    end

                    if v.plate then
                        SetVehicleNumberPlateText(vehicle, v.plate)
                    end
                    SetEntityHeading(vehicle, v.coords.w)
                    SetEntityAsMissionEntity(vehicle, true, true)
                    FreezeEntityPosition(vehicle, true)
                    SetVehicleDoorsLocked(vehicle, 1)
                    Entity(vehicle).state:set('parked', true, true)
                    Entity(vehicle).state:set('parking', tonumber(id), true)
                    local attempt = 0
                    while not NetworkGetEntityIsNetworked(vehicle) and attempt < 5 do
                        NetworkRegisterEntityAsNetworked(vehicle)
                        Wait(500)
                        attempt = attempt + 1
                    end
                    wait = false
                end, coords, true)
                while wait do
                    Wait(0)
                end

                debugger('Loaded vehicle', v.vehicle, v.coords)
            end
        end
    end
end

Garage.TeleportGarage = function(coords, fade)
    debugger('Teleporting to garage', coords)
    SetLocalPlayerAsGhost(true)
    DoScreenFadeOut(500)
    Wait(650)
    local ped = PlayerPedId()
    SetPedCoordsKeepVehicle(ped, vector3(coords.x, coords.y, coords.z - 1 + 0.0))

    local veh = GetVehiclePedIsIn(ped, false)
    SetEntityHeading(veh ~= 0 and veh or ped, coords.w)
	SetGameplayCamRelativeHeading(0)
    Wait(1000)
    while not HasCollisionLoadedAroundEntity(veh ~= 0 and veh or ped) do
		Wait(200)
	end
    if not fade then
        DoScreenFadeIn(500)
    end
    SetLocalPlayerAsGhost(false)
    debugger('Teleported to garage', coords)
end

Garage.ChangeDimension = function(dim)
    dim = tonumber(dim)
    TriggerServerEvent('origen_housing:server:ChangeDimension', dim)
    debugger('Changed dimension', dim)
end

Garage.ClearCache = function(cid)
    Wait(1000)
    collectgarbage('collect')
    collectgarbage('restart')
end

Garage.SpawnVehicle = function(model, cb, coords, isnetworked, inside)
    local ped = PlayerPedId()
    model = type(model) == 'string' and joaat(model) or model
    if not IsModelInCdimage(model) then return end
    if coords then
        coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords
    else
        coords = GetEntityCoords(ped)
    end
    isnetworked = isnetworked == nil or isnetworked

    lib.requestModel(model)

    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, coords.w, isnetworked, false)
    if not DoesEntityExist(veh) then
        debugger('Failed to create vehicle', model)
        return
    end
    local netid = NetworkGetNetworkIdFromEntity(veh)
    SetVehicleHasBeenOwnedByPlayer(veh, true)
    SetNetworkIdCanMigrate(netid, true)
    SetVehicleNeedsToBeHotwired(veh, false)
    SetVehRadioStation(veh, 'OFF')
    SetVehicleFuelLevel(veh, 100.0)
    SetModelAsNoLongerNeeded(model)
    if inside then TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1) end
    if cb then cb(veh) end
end