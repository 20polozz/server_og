Interior = {
    vehicles = {},
    shell = nil,
    exitPoint = nil,
    parkPoints = {},
}

local activeInterior = nil

function Interior:new(data)
    data = data or {}
    local instance = setmetatable({}, self)
    self.__index = self
    
    instance.id = data.id
    instance.name = data.name
    instance.interior = data.interior
    instance.isShell = data.isShell or false
    instance.entry = data.entry or vector4(0.0, 0.0, 0.0, 0.0)
    instance.spawnPoints = data.spawnPoints or {}
    instance.coords = data.coords or vector3(0.0, 0.0, 0.0)
    instance.shared = data.shared or false
    instance.minMax = nil
    instance.zone = {}
    instance.polyzone = nil

    LocalPlayer.state.interiorId = instance.id

    return instance
end

function Interior:Enter()
    local playerIds = {}

    table.insert(playerIds, cache.serverId)

    if cache.vehicle then
        for i = 0, GetVehicleNumberOfPassengers(cache.vehicle) - 1 do
            local playerPed = GetPedInVehicleSeat(cache.vehicle, i)
            if playerPed and playerPed ~= cache.ped then
                local id = GetPlayerServerId(NetworkGetPlayerIndexFromPed(playerPed))
                table.insert(playerIds, id)
            end
        end
    end

    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end
    Wait(500)

    TriggerServerEvent('origen_garages:sv:enterGarage', self.id, playerIds, {
        id = self.id,
        name = self.name,
        shared = self.shared,
        interior = self.interior,
        coords = self.coords,
        isShell = self.isShell,
        entry = self.entry,
        spawnPoints = self.spawnPoints
    })

    SetLocalPlayerAsGhost(true)
    Internal.DisableWeatherSync()
    local offset = GetOffsetFromEntityInWorldCoords(self.entity, self.interior.exit.x, self.interior.exit.y, self.interior.exit.z)

    Wait(500)

    SetPedCoordsKeepVehicle(cache.ped, offset.x, offset.y, offset.z)
    SetEntityHeading(cache.ped, self.interior.exit.w)
    cGarage.Utils.centerCamera()

    SetLocalPlayerAsGhost(false)

    return #playerIds
end

function Interior:EnterBringed()
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end
    SetLocalPlayerAsGhost(true)
    Internal.DisableWeatherSync()
    cGarage.Utils.centerCamera()
    SetLocalPlayerAsGhost(false)
end

function Interior:CreateExitPoint()
    local coords

    if self.isShell then
        coords = GetOffsetFromEntityInWorldCoords(self.entity, self.interior.exit.x, self.interior.exit.y, self.interior.exit.z)
    else
        coords = vector3(self.interior.exit.x, self.interior.exit.y, self.interior.exit.z)
    end

    self.exitPoint = lib.points.new({
        coords = coords,
        distance = 2.0,
    })

    self.exitPoint.onEnter = function()
        Custom.DrawText(locale('garage_exit'), 'E')
    end

    self.exitPoint.onExit = function()
        Custom.HideText()
    end

    self.exitPoint.nearby = function()
        if IsControlJustReleased(0, 38) then
            if cache.vehicle and cache.seat ~= -1 then
                return
            end
            Custom.HideText()
            self:Exit()
        end
    end
end

function Interior:CreateParkPoints()
    self.parkPoints = {}
    for i, spawn in pairs(self.interior.spawns) do
        local coords

        if self.isShell then
            local tempcoords = GetOffsetFromEntityInWorldCoords(self.entity, spawn.x, spawn.y, spawn.z)
            coords = vector4(tempcoords.x, tempcoords.y, tempcoords.z, spawn.w)
        else
            coords = vector4(spawn.x, spawn.y, spawn.z, spawn.w)
        end

        local lastFrozenState = nil
        local isTextActive = false

        local parkPoint = lib.points.new({
            coords = coords,
            distance = 2.0,
            label = 'Estacionar vehículo',
        })

        parkPoint.onExit = function()
            Custom.HideText()
            isTextActive = false
            lastFrozenState = nil
        end

        parkPoint.nearby = function()
            if cache.vehicle and cache.seat == -1 then
                local frozen = IsEntityPositionFrozen(cache.vehicle)

                if lastFrozenState ~= frozen then
                    if isTextActive then
                        Custom.HideText()
                    end
                    
                    if frozen then
                        Custom.DrawText(locale('garage_unpark_vehicle'), 'E')
                    else
                        Custom.DrawText(locale('garage_park_vehicle'), 'E')
                    end
                    
                    lastFrozenState = frozen
                    isTextActive = true
                end

                if IsControlJustReleased(0, 38) then
                    if frozen then
                        local plate = GetVehicleNumberPlateText(cache.vehicle)
                        local canUnpark = lib.callback.await('origen_garages:cb:UnParkVehicle', false, plate)

                        FreezeEntityPosition(cache.vehicle, false)
                    else
                        local mods = lib.getVehicleProperties(cache.vehicle)
                        mods.fuelLevel = Custom.GetFuel and Custom.GetFuel(cache.vehicle) or mods.fuelLevel
                        local canPark = lib.callback.await('origen_garages:cb:ParkVehicle', false, self.name..'_'..i, mods.plate, mods)

                        if not canPark then
                            Custom.Notify(locale('vehicle_not_owned'), 'error')
                            return
                        end

                        Custom.SaveVehicleHealth(cache.vehicle)

                        SetEntityCoords(cache.vehicle, coords.x, coords.y, coords.z, false, false, false, true)
                        SetEntityHeading(cache.vehicle, coords.w)
                        FreezeEntityPosition(cache.vehicle, true)
                    end
                end
            end
        end

        table.insert(self.parkPoints, parkPoint)
    end
end

function Interior:Exit()
    activeInterior = nil
    
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end
    local playersInside = lib.callback.await('origen_garages:cb:getPlayersInside', false, self.id) or {}

    if #playersInside <= 1 then
        local vehiclesInside = lib.callback.await('origen_garages:cb:getVehiclesInside', false, self.id) or {}

        for _, veh in pairs(vehiclesInside) do
            local vehicle = NetToVeh(veh.entity)
            if vehicle and DoesEntityExist(vehicle) and vehicle ~= cache.vehicle then
                DeleteEntity(vehicle)
            end
        end
    end

    local playerIds = {}

    table.insert(playerIds, cache.serverId)

    if cache.vehicle then
        for i = 0, GetVehicleNumberOfPassengers(cache.vehicle) - 1 do
            local playerPed = GetPedInVehicleSeat(cache.vehicle, i)
            if playerPed and playerPed ~= cache.ped then
                local id = GetPlayerServerId(NetworkGetPlayerIndexFromPed(playerPed))
                table.insert(playerIds, id)
            end
        end
    end

    TriggerServerEvent('origen_garages:sv:exitGarage', self.id, playerIds)

    Wait(500)
    
    local coords = cache.vehicle and self.spawnPoints[1] or vec4(self.entry.x, self.entry.y, self.entry.z - 1.0, self.entry.w)

    SetPedCoordsKeepVehicle(cache.ped, coords.x, coords.y, coords.z)
    SetEntityHeading(cache.ped, coords.w)
    cGarage.Utils.centerCamera()

    if self.onExit then
        self.onExit() 
    end

    if self.isShell then
        self:RemoveShell()
        self:DestroyZone()
        Internal.EnableWeatherSync()
    end

    for _, point in pairs(self.parkPoints) do
        if point then
            point:remove()
        end
    end

    Wait(500)

    SetLocalPlayerAsGhost(false)
    DoScreenFadeIn(500)
    while not IsScreenFadedIn() do Wait(0) end
end

function Interior:ExitBringed()
    activeInterior = nil

    Custom.HideText()
    
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end

    cGarage.Utils.centerCamera()

    if self.isShell then
        self:RemoveShell()
        self:DestroyZone()
        Internal.EnableWeatherSync()
    end

    if self.onExit then
        self.onExit() 
    end

    for _, point in pairs(self.parkPoints) do
        if point then
            point:remove()
        end
    end

    SetLocalPlayerAsGhost(false)
    DoScreenFadeIn(500)
    while not IsScreenFadedIn() do Wait(0) end
end

function Interior:CreateVehicles()
    local garage = cGarage.Get(self.id)
    local coords

    local vehicles = lib.callback.await('origen_garages:cb:getVehicles', false, {
        garage = self.name,
        states = { Config.VehicleStates.STORED },
        select = { 'mods', 'garage', 'owner' },
        interior = true
    }) or {}

    local createdVehicles = {}
    local occupiedSlots = {}

    for i, v in pairs(vehicles) do
        lib.requestModel(v.mods.model)
        local spawnIndex = tonumber(v.garage:sub(#self.name + 2)) or 1
        if occupiedSlots[spawnIndex] then
            spawnIndex = spawnIndex + 1
            while occupiedSlots[spawnIndex] do
                spawnIndex = spawnIndex + 1
            end
        end
        occupiedSlots[spawnIndex] = true

        if self.interior.spawns[spawnIndex] then
            if self.isShell then
                coords = self.interior.spawns[spawnIndex] or vector4(0.0, 0.0, 0.0, 0.0)
                local tempcoords = GetOffsetFromEntityInWorldCoords(self.entity, coords.x, coords.y, coords.z)
                coords = vector4(tempcoords.x, tempcoords.y, tempcoords.z, coords.w)
            else
                coords = self.interior.spawns[spawnIndex].xyzw
            end

            local veh = CreateVehicle(v.mods.model, coords.xyz, coords.w, true, true)
            SetEntityAsMissionEntity(veh, true, true)
            SetVehicleHasBeenOwnedByPlayer(veh, true)
            
            lib.setVehicleProperties(veh, v.mods)
            cGarage.Utils.applyVehicleDamage(veh, v.mods)
            if Custom.SetFuel then
                Custom.SetFuel(veh, v.mods.fuelLevel)
            end
            SetVehicleOnGroundProperly(veh)
            FreezeEntityPosition(veh, true)

            table.insert(createdVehicles, {
                entity = VehToNet(veh),
                owner = v.owner,
            })
        end
    end

    return createdVehicles
end

local function getMinMax(coords, min, max)
    local min = vector3(coords.x + min.x, coords.y + min.y, coords.z + min.z)
    local max = vector3(coords.x + max.x, coords.y + max.y, coords.z + max.z)
    
    return {min = min, max = max}
end

function Interior:CreateShell(data, bringed)
    activeInterior = self

    self.onEnter = data.onEnter
    self.onExit = data.onExit
    
    self.model = GetHashKey(self.interior.model)

    if not IsModelValid(self.model) then debugger('Model not valid', self.model) return end

    lib.requestModel(self.model)

    self.entity = CreateObjectNoOffset(self.model, self.coords.x, self.coords.y, 2000.0, false, false, false)
    FreezeEntityPosition(self.entity, true)
    SetModelAsNoLongerNeeded(self.model)

    while not HasCollisionLoadedAroundEntity(cache.ped) do
		Wait(200)
	end

    local min, max = GetModelDimensions(self.model)

    self.minMax = getMinMax(vector3(self.coords.x, self.coords.y, 2000.0), min, max)

    self:CreateZone()

    if self.onEnter then
        self.onEnter(self.entity)
    end

    if not bringed then
        local players = self:Enter()
        local playersInside = lib.callback.await('origen_garages:cb:getPlayersInside', false, self.id) or {}
        if (#playersInside - players) == 0 then
            self.vehicles = self:CreateVehicles()
            if cache.vehicle then
                table.insert(self.vehicles, {
                    entity = VehToNet(cache.vehicle),
                    owner = Framework.GetPlayerIdentifier(),
                })
            end
            TriggerServerEvent('origen_garages:sv:registerInteriorVehicles', self.id, self.vehicles)
        else
            self.vehicles = lib.callback.await('origen_garages:cb:getVehiclesInside', false, self.id) or {}
            if cache.vehicle then
                table.insert(self.vehicles, {
                    entity = VehToNet(cache.vehicle),
                    owner = Framework.GetPlayerIdentifier(),
                })
                TriggerServerEvent('origen_garages:sv:registerInteriorVehicles', self.id, self.vehicles)
            end
        end

        local identifier = Framework.GetPlayerIdentifier()
        for _, veh in pairs(self.vehicles) do
            if self.shared or (veh.owner and veh.owner == identifier) then
                if not cache.vehicle or (cache.vehicle and NetToVeh(veh.entity) ~= cache.vehicle) then
                    Internal.GiveVehicleKeys(veh.entity, GetVehicleNumberPlateText(NetToVeh(veh.entity)), true)
                end
            end
        end
    else
        self:EnterBringed()
        self.vehicles = lib.callback.await('origen_garages:cb:getVehiclesInside', false, self.id) or {}
        local identifier = Framework.GetPlayerIdentifier()
        for _, veh in pairs(self.vehicles) do
            if self.shared or (veh.owner and veh.owner == identifier) then
                if not cache.vehicle or (cache.vehicle and NetToVeh(veh.entity) ~= cache.vehicle) then
                    Internal.GiveVehicleKeys(veh.entity, GetVehicleNumberPlateText(NetToVeh(veh.entity)), true)
                end
            end
        end
    end

    DoScreenFadeIn(500)
    while not IsScreenFadedIn() do Wait(0) end
    self:CreateExitPoint()
    self:CreateParkPoints()
end

function Interior:CreateZone()
    local function onExit(data)
        Wait(1000)
        if not LocalPlayer.state.interiorId then
            return
        end
        self:Exit()
    end

    local height = self.minMax.max.z - self.minMax.min.z

    if not next(self.zone) then
        self.zone[#self.zone+1] = vector3(self.minMax.min.x, self.minMax.max.y, self.minMax.max.z - height / 2)
        self.zone[#self.zone+1] = vector3(self.minMax.min.x, self.minMax.min.y, self.minMax.max.z - height / 2)
        self.zone[#self.zone+1] = vector3(self.minMax.max.x, self.minMax.min.y, self.minMax.max.z - height / 2)
        self.zone[#self.zone+1] = vector3(self.minMax.max.x, self.minMax.max.y, self.minMax.max.z - height / 2)
    end
    
    self.polyzone = lib.zones.poly({
        points = self.zone,
        debug = false,
        thickness = height * 2,
        onExit = onExit
    })
end

function Interior:DestroyZone()
    if self.polyzone and next(self.polyzone) then
        self.polyzone:remove()
        self.polyzone = nil
    end
end

function Interior:RemoveShell()
    if self.entity and DoesEntityExist(self.entity) then
        DeleteObject(self.entity)
        self.entity = nil
    end

    if self.exitPoint then
        self.exitPoint:remove()
        self.exitPoint = nil
    end
end

function Interior:EnterIPL(data, bringed)
    activeInterior = self
    self.onEnter = data.onEnter
    self.onExit = data.onExit

    if self.onEnter then
        self.onEnter()
    end
    
    local playerIds = {}

    if not bringed then
        table.insert(playerIds, cache.serverId)

        if cache.vehicle then
            for i = 0, GetVehicleNumberOfPassengers(cache.vehicle) - 1 do
                local playerPed = GetPedInVehicleSeat(cache.vehicle, i)
                if playerPed and playerPed ~= cache.ped then
                    local id = GetPlayerServerId(NetworkGetPlayerIndexFromPed(playerPed))
                    table.insert(playerIds, id)
                end
            end
        end

        TriggerServerEvent('origen_garages:sv:enterGarage', self.id, playerIds, {
            id = self.id,
            name = self.name,
            shared = self.shared,
            interior = self.interior,
            coords = self.coords,
            isShell = self.isShell,
            entry = self.entry,
            spawnPoints = self.spawnPoints
        })
    end

    SetLocalPlayerAsGhost(true)
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end

    if not bringed then
        SetPedCoordsKeepVehicle(cache.ped, self.interior.exit.x, self.interior.exit.y, self.interior.exit.z)
        SetEntityHeading(cache.ped, self.interior.exit.w)
        cGarage.Utils.centerCamera()
    end

    while not HasCollisionLoadedAroundEntity(cache.ped) do
		Wait(200)
	end

    SetLocalPlayerAsGhost(false)

    if not bringed then
        local playersInside = lib.callback.await('origen_garages:cb:getPlayersInside', false, self.id) or {}
        
        if (#playersInside - #playerIds) == 0 then
            self.vehicles = self:CreateVehicles()
            if cache.vehicle then
                table.insert(self.vehicles, {
                    entity = VehToNet(cache.vehicle),
                    owner = Framework.GetPlayerIdentifier(),
                })
            end
            TriggerServerEvent('origen_garages:sv:registerInteriorVehicles', self.id, self.vehicles)
        else
            self.vehicles = lib.callback.await('origen_garages:cb:getVehiclesInside', false, self.id) or {}
            if cache.vehicle then
                table.insert(self.vehicles, {
                    entity = VehToNet(cache.vehicle),
                    owner = Framework.GetPlayerIdentifier(),
                })
                TriggerServerEvent('origen_garages:sv:registerInteriorVehicles', self.id, self.vehicles)
            end
        end

        local identifier = Framework.GetPlayerIdentifier()
        for _, veh in pairs(self.vehicles) do     
            if self.shared or (veh.owner and veh.owner == identifier) then
                if not cache.vehicle or (cache.vehicle and NetToVeh(veh.entity) ~= cache.vehicle) then
                    Internal.GiveVehicleKeys(veh.entity, GetVehicleNumberPlateText(NetToVeh(veh.entity)), true)
                end
            end
        end
    else
        self.vehicles = lib.callback.await('origen_garages:cb:getVehiclesInside', false, self.id) or {}
        local identifier = Framework.GetPlayerIdentifier()
        for _, veh in pairs(self.vehicles) do
            if self.shared or (veh.owner and veh.owner == identifier) then
                if not cache.vehicle or (cache.vehicle and NetToVeh(veh.entity) ~= cache.vehicle) then
                    Internal.GiveVehicleKeys(veh.entity, GetVehicleNumberPlateText(NetToVeh(veh.entity)), true)
                end
            end
        end
    end

    DoScreenFadeIn(500)
    while not IsScreenFadedIn() do Wait(0) end
    self:CreateExitPoint()
    self:CreateParkPoints()
end

RegisterNetEvent('origen_garages:cl:enterGarageBringed', function(data)
    local interior = Interior:new({
        id = data.id,
        name = data.name,
        shared = data.shared,
        interior = data.interior,
        coords = data.coords,
        isShell = data.isShell,
        entry = data.entry,
        spawnPoints = data.spawnPoints
    })

    if data.isShell then
        local furniture = lib.callback.await('origen_garages:cb:server:getFurniture', false, data.id)
        interior:CreateShell({
            onEnter = function(entity)
                local garage = cGarage.Get(data.id)
                if garage then
                    garage.furniture = furniture or {}
                    garage.shell = entity
                    garage.shellPoints = interior.zone
                    garage:LoadFurniture()
                end
                LocalPlayer.state.interiorId = data.id
            end,
            onExit = function()
                local garage = cGarage.Get(data.id)
                if garage then
                    garage:DeleteFurniture()
                    garage.shell = nil
                    garage.shellPoints = nil
                end
                LocalPlayer.state.interiorId = nil
            end
        }, true)
    else
        local tempGarage = {
            id = data.id,
            furniture = {},
            isShell = false,
            createdFurniture = {},
            LoadFurniture = cGarage.LoadFurniture,
            DeleteFurniture = cGarage.DeleteFurniture,
            UpdateObject = cGarage.UpdateObject
        }
        
        interior:EnterIPL({
            onEnter = function()
                local garage = cGarage.Get(data.id)
                local furniture = lib.callback.await('origen_garages:cb:server:getFurniture', false, data.id)
                
                if garage then
                    garage.furniture = furniture or {}
                    garage:LoadFurniture()
                else
                    tempGarage.furniture = furniture or {}
                    tempGarage:LoadFurniture()
                end
                
                LocalPlayer.state.interiorId = data.id
            end,
            onExit = function()
                local garage = cGarage.Get(data.id)
                
                if garage then
                    garage:DeleteFurniture()
                else
                    tempGarage:DeleteFurniture()
                end
                
                LocalPlayer.state.interiorId = nil
            end
        }, true)
    end
end)

RegisterNetEvent('origen_garages:cl:exitGarageBringed', function()
    if activeInterior then
        activeInterior:ExitBringed()
    end
end)