--@param vehicle Vehicle entity
--@param plate Plate of the vehicle
--@param action Action to perform (give, remove)
Custom.GiveVehicleKeys = function(vehicle, plate, action)
    -- Implement your own vehicle key system here
end

--@param vehicle Vehicle entity
Custom.GetVehicleMods = function(vehicle)
    if Config.Framework == 'qb-core' then
        return Framework.Functions.GetVehicleProperties(vehicle)
    elseif Config.Framework == 'esx' then
        return Framework.Game.GetVehicleProperties(vehicle)
    else
        return {}
    end
end

--@param vehicle Vehicle entity
--@param props Vehicle properties
Custom.SetVehicleProperties = function(vehicle, props)
    if Config.Framework == 'qb-core' then
        Framework.Functions.SetVehicleProperties(vehicle, props)
    elseif Config.Framework == 'esx' then
        Framework.Game.SetVehicleProperties(vehicle, props)
    end
end

-- @param coords Coords to search for vehicles
Custom.GetClosestVehicle = function(coords)
    if Config.Framework == 'qb-core' then
        return Framework.Functions.GetClosestVehicle(coords)
    elseif Config.Framework == 'esx' then
        return Framework.Game.GetClosestVehicle(coords)
    end
end

--@param houseID House ID
--@param garageType Garage type
--@param coords Coords of the garage
Custom.OpenCustomGarage = function(houseID, garageType, coords)
    -- Implement your own garage system here
end

-- These functions only work using the system included in the script
Custom.OnEnterGarage = function(houseID)

end

Custom.OnExitGarage = function(houseID)

end
