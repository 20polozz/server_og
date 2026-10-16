-- Barber Shop Interior Management System
CreateThread(function()
    Wait(1000) -- Wait for game to fully load
    
    if Config.Debug then
        print("^2[Barber Interiors]^0 Starting interior management...")
    end
    
    -- Process each location from config
    for locationName, locationData in pairs(Config.Locations) do
        if locationData.coords then
            local interior = GetInteriorAtCoordsWithType(
                locationData.coords.x, 
                locationData.coords.y, 
                locationData.coords.z, 
                locationData.interior_type
            )
            
            if interior and interior ~= 0 then
                if locationData.enabled then
                    -- Enable the interior
                    DisableInterior(interior, false)
                    if Config.Debug then
                        print(string.format("^2[Barber Interiors]^0 Enabled interior for %s at coords: %.2f, %.2f, %.2f", 
                            locationName, locationData.coords.x, locationData.coords.y, locationData.coords.z))
                    end
                else
                    -- Disable the interior
                    DisableInterior(interior, true)
                    if Config.Debug then
                        print(string.format("^1[Barber Interiors]^0 Disabled interior for %s at coords: %.2f, %.2f, %.2f", 
                            locationName, locationData.coords.x, locationData.coords.y, locationData.coords.z))
                    end
                end
            else
                if Config.Debug then
                    print(string.format("^3[Barber Interiors]^0 Warning: No interior found for %s at coords: %.2f, %.2f, %.2f", 
                        locationName, locationData.coords.x, locationData.coords.y, locationData.coords.z))
                end
            end
        end
    end
    
    if Config.Debug then
        print("^2[Barber Interiors]^0 Interior management completed!")
    end
end)

-- Function to toggle a specific location's interior (for debugging or admin commands)
function ToggleBarberInterior(locationName)
    if not Config.Locations[locationName] then
        print("^1[Barber Interiors]^0 Error: Location '" .. locationName .. "' not found!")
        return false
    end
    
    local locationData = Config.Locations[locationName]
    local interior = GetInteriorAtCoordsWithType(
        locationData.coords.x, 
        locationData.coords.y, 
        locationData.coords.z, 
        locationData.interior_type
    )
    
    if interior and interior ~= 0 then
        locationData.enabled = not locationData.enabled
        
        if locationData.enabled then
            DisableInterior(interior, false)
            
            print(string.format("^2[Barber Interiors]^0 Enabled interior for %s", locationName))
        else
            DisableInterior(interior, true)
                    
            print(string.format("^1[Barber Interiors]^0 Disabled interior for %s", locationName))
        end
        
        return true
    else
        print(string.format("^3[Barber Interiors]^0 Warning: No interior found for %s", locationName))
        return false
    end
end

-- Console command for toggling interiors (optional - for debugging)
RegisterCommand('togglebarber', function(source, args)
    if #args < 1 then
        print("^3[Barber Interiors]^0 Usage: togglebarber <location>")
        print("^3[Barber Interiors]^0 Available locations: paleto, city, vespucci, mirror_park, ghetto, sandy")
        return
    end
    
    ToggleBarberInterior(args[1])
end, false)

-- paleto: -278.324158, 6228.18164, 30.7110977
-- city: -33.0160065, -152.317963, 56.0920944
-- vespucci: -1282.87061, -1117.27551, 6.005688
-- mirror: 1212.29236, -472.808533, 65.22362
-- ghetto: 136.937012, -1708.16211, 28.3071842