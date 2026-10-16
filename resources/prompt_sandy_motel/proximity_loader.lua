-- IPL locations with their coordinates (extracted from XML files)
local iplLocations = {
    -- Ground floor rooms (1-15)
    { name = "prompt_sandy_motel_room_1", x = 1615.8811, y = 3793.392, z = 35.5211754 },
    { name = "prompt_sandy_motel_room_2", x = 1611.48621, y = 3790.025, z = 35.5211754 },
    { name = "prompt_sandy_motel_room_3", x = 1607.138, y = 3786.635, z = 35.5211754 },
    { name = "prompt_sandy_motel_room_4", x = 1602.75232, y = 3783.26978, z = 35.5211754 },
    { name = "prompt_sandy_motel_room_5", x = 1584.32666, y = 3769.15454, z = 35.52501 },
    { name = "prompt_sandy_motel_room_6", x = 1579.42151, y = 3765.361, z = 35.52501 },
    { name = "prompt_sandy_motel_room_7", x = 1584.857, y = 3738.89575, z = 35.50938 },
    { name = "prompt_sandy_motel_room_8", x = 1589.37817, y = 3742.36548, z = 35.50938 },
    { name = "prompt_sandy_motel_room_9", x = 1593.98535, y = 3745.90063, z = 35.50938 },
    { name = "prompt_sandy_motel_room_10", x = 1598.95508, y = 3749.714, z = 35.50938 },
    { name = "prompt_sandy_motel_room_11", x = 1603.93469, y = 3753.53516, z = 35.50938 },
    { name = "prompt_sandy_motel_room_12", x = 1608.90576, y = 3757.34961, z = 35.50938 },
    { name = "prompt_sandy_motel_room_13", x = 1613.88062, y = 3761.167, z = 35.50938 },
    { name = "prompt_sandy_motel_room_14", x = 1618.85693, y = 3764.98535, z = 35.50938 },
    { name = "prompt_sandy_motel_room_15", x = 1623.81409, y = 3768.789, z = 35.50938 },
    
    -- Upper floor rooms (16-32)
    { name = "prompt_sandy_motel_room_16", x = 1623.80627, y = 3768.78271, z = 39.117115 },
    { name = "prompt_sandy_motel_room_17", x = 1618.852, y = 3764.9812, z = 39.117115 },
    { name = "prompt_sandy_motel_room_18", x = 1613.88806, y = 3761.172, z = 39.117115 },
    { name = "prompt_sandy_motel_room_19", x = 1608.92346, y = 3757.36279, z = 39.117115 },
    { name = "prompt_sandy_motel_room_20", x = 1603.94312, y = 3753.54126, z = 39.117115 },
    { name = "prompt_sandy_motel_room_21", x = 1598.96094, y = 3749.71826, z = 39.117115 },
    { name = "prompt_sandy_motel_room_22", x = 1593.97, y = 3745.88867, z = 39.117115 },
    { name = "prompt_sandy_motel_room_23", x = 1589.0061, y = 3742.07983, z = 39.117115 },
    { name = "prompt_sandy_motel_room_24", x = 1584.02722, y = 3738.25928, z = 39.119194 },
    { name = "prompt_sandy_motel_room_25", x = 1571.75745, y = 3759.512, z = 39.1182556 },
    { name = "prompt_sandy_motel_room_26", x = 1576.73694, y = 3763.32861, z = 39.1182556 },
    { name = "prompt_sandy_motel_room_27", x = 1581.64746, y = 3767.10767, z = 39.1182556 },
    { name = "prompt_sandy_motel_room_28", x = 1587.66785, y = 3765.40454, z = 39.46466 },
    { name = "prompt_sandy_motel_room_29", x = 1602.66052, y = 3783.23853, z = 39.1182556 },
    { name = "prompt_sandy_motel_room_30", x = 1607.118, y = 3786.663, z = 39.1182556 },
    { name = "prompt_sandy_motel_room_31", x = 1611.51331, y = 3790.04443, z = 39.1182556 },
    { name = "prompt_sandy_motel_room_32", x = 1615.8811, y = 3793.392, z = 39.1182556 }
}

-- Configuration
local PROXIMITY_DISTANCE = 40.0  -- Distance in units to load/unload IPLs
local INTERIOR_PROXIMITY_DISTANCE = 70.0  -- Distance for interior IPLs
local CHECK_INTERVAL = 1000      -- Check every 1 second (1000ms)
local SPAWN_WALL_POINT_A = vector2(1555.094, 3756.257)
local SPAWN_WALL_POINT_B = vector2(1577.395, 3726.358)
local RESTRICTED_WALL_POINT_A = vector2(1636.3, 3771.54)
local RESTRICTED_WALL_POINT_B = vector2(1580.64, 3728.61)

local interiorIplLocations = {
    { name = "prompt_sandy_motel_int", x = 1575.80334, y = 3747.263, z = 35.82488 },
    { name = "prompt_sandy_motel_poker_int", x = 1577.52856, y = 3746.17773, z = 37.00349 }
}

-- Keep track of loaded IPLs to avoid redundant calls
local loadedIPLs = {}
local fakeDoorsLoaded = false  -- Track if fake doors have been loaded
local restrictedBehindSecondWall = {
    prompt_sandy_motel_room_24 = true,
    prompt_sandy_motel_room_5 = true,
    prompt_sandy_motel_room_7 = true,
    prompt_sandy_motel_int = true,
    prompt_sandy_motel_poker_int = true
}

-- Function to calculate distance between two points
local function GetDistance(x1, y1, z1, x2, y2, z2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2 + (z2 - z1)^2)
end

-- Prevent room spawning when player is on the blocked side of the wall.
local function IsBehindSpawnWall(playerCoords)
    local abX = SPAWN_WALL_POINT_B.x - SPAWN_WALL_POINT_A.x
    local abY = SPAWN_WALL_POINT_B.y - SPAWN_WALL_POINT_A.y
    local apX = playerCoords.x - SPAWN_WALL_POINT_A.x
    local apY = playerCoords.y - SPAWN_WALL_POINT_A.y
    local cross = (abX * apY) - (abY * apX)

    return cross < 0.0
end

local function IsBehindRestrictedWall(playerCoords)
    local abX = RESTRICTED_WALL_POINT_B.x - RESTRICTED_WALL_POINT_A.x
    local abY = RESTRICTED_WALL_POINT_B.y - RESTRICTED_WALL_POINT_A.y
    local apX = playerCoords.x - RESTRICTED_WALL_POINT_A.x
    local apY = playerCoords.y - RESTRICTED_WALL_POINT_A.y
    local cross = (abX * apY) - (abY * apX)

    return cross > 0.0
end

local function IsRestrictedRoomBehindSecondWall(iplName)
    return restrictedBehindSecondWall[iplName] == true
end

-- Function to load an IPL
local function LoadIPL(iplName)
    if not loadedIPLs[iplName] then
        RequestIpl(iplName)
        loadedIPLs[iplName] = true
        --print("^2[MOTEL PROXIMITY LOADER]^7 Loaded IPL: " .. iplName)
    end
end

-- Function to unload an IPL
local function UnloadIPL(iplName)
    if loadedIPLs[iplName] then
        RemoveIpl(iplName)
        loadedIPLs[iplName] = nil
        --print("^1[MOTEL PROXIMITY LOADER]^7 Unloaded IPL: " .. iplName)
    end
end

-- Main proximity check function
local function CheckProximity()
    -- Load fake doors once if numbered rooms are disabled (reception + manager/poker still proximity-load below)
    if not Config.Rooms.enabled and not fakeDoorsLoaded then
        RequestIpl(Config.Rooms.fakedoors_ipl)
        fakeDoorsLoaded = true
        print("^3[MOTEL PROXIMITY LOADER]^7 Loaded fake doors IPL: " .. Config.Rooms.fakedoors_ipl)
    end

    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    if IsBehindSpawnWall(playerCoords) then
        if Config.Rooms.enabled then
            for _, ipl in ipairs(iplLocations) do
                UnloadIPL(ipl.name)
            end
        end
        for _, ipl in ipairs(interiorIplLocations) do
            UnloadIPL(ipl.name)
        end
        return
    end

    local isBehindRestrictedWall = IsBehindRestrictedWall(playerCoords)

    if Config.Rooms.enabled then
        for _, ipl in ipairs(iplLocations) do
            if isBehindRestrictedWall and IsRestrictedRoomBehindSecondWall(ipl.name) then
                UnloadIPL(ipl.name)
            else
                local distance = GetDistance(playerCoords.x, playerCoords.y, playerCoords.z, ipl.x, ipl.y, ipl.z)

                if distance <= PROXIMITY_DISTANCE then
                    LoadIPL(ipl.name)
                else
                    UnloadIPL(ipl.name)
                end
            end
        end
    end

    for _, ipl in ipairs(interiorIplLocations) do
        if isBehindRestrictedWall and IsRestrictedRoomBehindSecondWall(ipl.name) then
            UnloadIPL(ipl.name)
        else
            local distance = GetDistance(playerCoords.x, playerCoords.y, playerCoords.z, ipl.x, ipl.y, ipl.z)

            if distance <= INTERIOR_PROXIMITY_DISTANCE then
                LoadIPL(ipl.name)
            else
                UnloadIPL(ipl.name)
            end
        end
    end
end

-- Start the proximity checker
CreateThread(function()
    while true do
        CheckProximity()
        Wait(CHECK_INTERVAL)
    end
end)
