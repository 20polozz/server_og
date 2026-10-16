local haveOxLib = GetResourceState('ox_lib') == 'started'
local config

-- Load config
if haveOxLib then
    local success, result = pcall(function()
        return require 'config'
    end)
    config = success and result or { Debug = true, GymLocations = {} }
else
    local configFile = LoadResourceFile(GetCurrentResourceName(), 'config.lua')
    if configFile then
        local configFunc = load(configFile, '@@' .. GetCurrentResourceName() .. '/config.lua')
        config = configFunc and configFunc() or { Debug = true, GymLocations = {} }
    else
        config = { Debug = true, GymLocations = {} }
    end
end

-- Debug print helper
local function debugPrint(...)
    if config.Debug then
        print('[prison_gym] CLIENT:', ...)
    end
end

-- Check for animation core
local function checkAnimCore()
    for i = 0, GetNumResources() - 1 do
        local resourceName = GetResourceByFindIndex(i)
        if resourceName and string.sub(resourceName, 1, 18) == 'prompt_anim_core_2' then
            if GetResourceState(resourceName) == 'started' then
                return true
            end
        end
    end
    return GetResourceState('prompt_anim_core') == 'started' or GetResourceState('prompt_anim_core_limited') == 'started'
end

local haveAnimCore = checkAnimCore()
debugPrint('haveAnimCore = ' .. tostring(haveAnimCore))

-- Function to get interior ID for a location
local function getInteriorId(locationName)
    local locationData = config.GymLocations and config.GymLocations[locationName]
    if locationData and locationData.coords then
        return GetInteriorAtCoords(locationData.coords.x, locationData.coords.y, locationData.coords.z)
    end
    return nil
end

-- Apply entity sets from GlobalState to interior
local function applyEntitySets(locationName, entitySetsState)
    local interiorId = getInteriorId(locationName)
    if not interiorId or interiorId == 0 then
        debugPrint('Interior not found for: ' .. locationName)
        return false
    end
    
    debugPrint(string.format('Applying entity sets for %s (interior: %d)', locationName, interiorId))
    
    for entitySetName, isEnabled in pairs(entitySetsState) do
        if isEnabled then
            ActivateInteriorEntitySet(interiorId, entitySetName)
            debugPrint('Activated: ' .. entitySetName)
        else
            DeactivateInteriorEntitySet(interiorId, entitySetName)
            debugPrint('Deactivated: ' .. entitySetName)
        end
    end
    
    RefreshInterior(interiorId)
    return true
end

-- STATE BAG HANDLER: React to GlobalState.prisonGymEntitySets changes
-- ONLY apply entity sets if NO anim core is running (static mode)
AddStateBagChangeHandler('prisonGymEntitySets', 'global', function(bagName, key, value, _unused, replicated)
    if not value then return end
    
    -- Skip if anim core is handling props
    if haveAnimCore then
        debugPrint('StateBag changed but anim core is active - skipping entity sets (animated props will be used)')
        return
    end
    
    debugPrint('StateBag changed - applying entity sets (static mode)...')
    
    for locationName, entitySetsState in pairs(value) do
        if config.GymLocations and config.GymLocations[locationName] then
            applyEntitySets(locationName, entitySetsState)
        end
    end
end)

-- Apply initial entity sets on script load
-- ONLY if NO anim core is running (static mode fallback)
CreateThread(function()
    Wait(2000) -- Wait for GlobalState to be ready
    
    -- Skip if anim core is handling props
    if haveAnimCore then
        debugPrint('Anim core detected - skipping entity set activation (animated props will be used)')
        return
    end
    
    if GlobalState.prisonGymEntitySets then
        debugPrint('Applying initial entity sets from GlobalState (static mode)...')
        
        for locationName, entitySetsState in pairs(GlobalState.prisonGymEntitySets) do
            if config.GymLocations and config.GymLocations[locationName] then
                applyEntitySets(locationName, entitySetsState)
            end
        end
    else
        debugPrint('No initial entity sets in GlobalState')
    end
end)

-- ox_lib menu stuff (only if ox_lib is present)
if haveOxLib then
    RegisterNetEvent('prison_gym:openSetsMenu', function(data)
        if not data then return end
        
        local options = {}
        for setName, setData in pairs(data) do
            table.insert(options, {
                title = setName:sub(1,1):upper() .. setName:sub(2),
                description = 'Manage the ' .. setName .. ' entity set',
                icon = 'cubes',
                menu = 'prison_gym_entity_set_' .. setName,
            })
            
            local setOptions = {}
            for entitySet, isActive in pairs(setData) do
                table.insert(setOptions, {
                    title = (isActive and 'Disable' or 'Enable') .. ' ' .. entitySet,
                    icon = isActive and 'toggle-on' or 'toggle-off',
                    onSelect = function()
                        lib.callback.await('prison_gym:toggleEntitySet', 300, {
                            location = setName,
                            entitySet = entitySet,
                            enable = not isActive
                        })
                    end,
                })
            end
            
            lib.registerContext({
                id = 'prison_gym_entity_set_' .. setName,
                title = 'Entity Set: ' .. setName,
                menu = 'prison_gym_entity_sets',
                options = setOptions
            })
        end
        
        lib.registerContext({
            id = 'prison_gym_entity_sets',
            title = 'Prison Gym Entity Sets',
            options = options
        })
        lib.showContext('prison_gym_entity_sets')
    end)
end

debugPrint('Client initialized')
