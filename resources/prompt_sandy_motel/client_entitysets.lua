local function FindInterior(location)
    local interior = GetInteriorAtCoords(location.x, location.y, location.z)
    if interior == 0 then
        return nil
    end
    return interior
end

local function HandleEntitySet(entitySetName, config)
    local interior = FindInterior(config.location)
    
    if not interior then
        print("^3[EntitySet] Warning: Could not find interior for entity set '" .. entitySetName .. "' at location " .. tostring(config.location))
        return
    end
    
    -- Store interior reference in config
    config.interior = interior
    
    -- Apply the entity set visibility based on config
    if config.enabled then
        ActivateInteriorEntitySet(interior, entitySetName)
        print("^2[EntitySet] Enabled entity set: " .. entitySetName)
    else
        DeactivateInteriorEntitySet(interior, entitySetName)
        print("^3[EntitySet] Disabled entity set: " .. entitySetName)
    end
end

local function InitializeEntitySets()
    -- Wait a bit to ensure all interiors are loaded
    Citizen.Wait(2000)
    
    -- Process all entity sets from config
    for entitySetName, config in pairs(Config.EntitySets) do
        HandleEntitySet(entitySetName, config)
    end
end

-- Initialize when resource starts
Citizen.CreateThread(function()
    InitializeEntitySets()
end)

-- Export function to toggle entity set at runtime (optional)
exports('ToggleEntitySet', function(entitySetName)
    if not Config.EntitySets[entitySetName] then
        print("^1[EntitySet] Error: Entity set '" .. entitySetName .. "' not found in config")
        return false
    end
    
    local config = Config.EntitySets[entitySetName]
    config.enabled = not config.enabled
    
    HandleEntitySet(entitySetName, config)
    
    return config.enabled
end)

-- Export function to set entity set state at runtime (optional)
exports('SetEntitySetState', function(entitySetName, enabled)
    if not Config.EntitySets[entitySetName] then
        print("^1[EntitySet] Error: Entity set '" .. entitySetName .. "' not found in config")
        return false
    end
    
    local config = Config.EntitySets[entitySetName]
    config.enabled = enabled
    
    HandleEntitySet(entitySetName, config)
    
    return config.enabled
end)

-- Command to toggle poker entity set
RegisterCommand('poker', function(source, args, rawCommand)
    local config = Config.EntitySets['poker']
    
    if not config then
        print("^1[EntitySet] Error: Poker entity set not found in config")
        return
    end
    
    -- Toggle the state
    config.enabled = not config.enabled
    
    -- Apply the changes
    HandleEntitySet('poker', config)
    
    -- Provide feedback
    if config.enabled then
        print("^2[EntitySet] Poker entity set has been ^2ENABLED^7")
    else
        print("^3[EntitySet] Poker entity set has been ^3DISABLED^7")
    end
end, false) 