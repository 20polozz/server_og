local function FindInterior(location)
    local interior = GetInteriorAtCoords(location.x, location.y, location.z)
    if interior == 0 then
        return nil
    end
    return interior
end

-- Check if a house is a VA house by its ID
local function IsVAHouse(houseId)
    return string.match(houseId, "^va_") ~= nil
end

local function GetHouseModeEntitySets(interior, houseMode)
    -- Get the house's default configuration ONLY
    local sets = {}
    if interior.defaults and interior.defaults.sets then
        for _, set in ipairs(interior.defaults.sets) do
            table.insert(sets, set)
        end
    end
    
    -- For furnished mode, also add furniture
    if houseMode == "furnished" then
        table.insert(sets, "furniture")
    end

    return sets
end

local function HandleHouseEntitySets(interior, entitySets)
    local interiorId = FindInterior(interior.coords)
    
    if not interiorId then
        print("^3[EntitySet] Warning: Could not find interior for house '" .. interior.name .. "' at location " .. tostring(interior.coords))
        return
    end
    
    -- Store interior reference
    interior.interior = interiorId
    
    -- First, deactivate ALL possible entity sets to ensure clean state
    if interior.entitySets then
        for _, entitySetData in pairs(interior.entitySets) do
            DeactivateInteriorEntitySet(interiorId, entitySetData.set)
            if Config.Debug and Config.Debug.logEntitySets then
                print("^1[EntitySet] Deactivated entity set: " .. entitySetData.set .. " for house: " .. interior.name)
            end
        end
    end
    
    -- Wait a frame to ensure deactivation completes
    Citizen.Wait(0)
    
    -- Then activate ONLY the required entity sets
    for _, entitySetName in pairs(entitySets) do
        ActivateInteriorEntitySet(interiorId, entitySetName)
        if Config.Debug and Config.Debug.logEntitySets then
            print("^2[EntitySet] Activated entity set: " .. entitySetName .. " for house: " .. interior.name)
        end
    end
end

local function InitializeHouses()
    -- Wait a bit to ensure all interiors are loaded
    Citizen.Wait(2000)
    
    -- Get house mode from config (default to shells_only if not set)
    local houseMode = Config.HouseMode or "shells_only"
    
    if Config.Debug and Config.Debug.logEntitySets then
        print("^6[EntitySet] Initializing houses in mode: " .. houseMode)
    end
    
    if GetResourceState("FS-InteriorManager") == "started" or GetResourceState("FS-InteriorManager") == "starting" then
	    print("^1[EntitySet] Not loading EntitySet; FS-InteriorManager is running. Use it instead.^0")
	    return
	end

    -- Process all houses from Config.InteriorFolders
    if Config.InteriorFolders then
        for _, folder in pairs(Config.InteriorFolders) do
            if folder.interiors then
                for _, interior in pairs(folder.interiors) do
                    local entitySets = GetHouseModeEntitySets(interior, houseMode)
                    HandleHouseEntitySets(interior, entitySets)
                end
            end
        end
    end
    
    -- Process VA houses separately
    if Config.VAHouses then
        for _, interior in pairs(Config.VAHouses) do
            local entitySets = GetHouseModeEntitySets(interior, houseMode)
            HandleHouseEntitySets(interior, entitySets)
        end
    end
end

-- Initialize when resource starts
Citizen.CreateThread(function()
    InitializeHouses()
end)