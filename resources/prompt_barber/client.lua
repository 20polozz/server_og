-- Barber Shop Interior Management System
local LOG_PREFIX = "Barber Interiors"
local INTERIOR_LOOKUP_ATTEMPTS = 20
local INTERIOR_LOOKUP_WAIT_MS = 250

local function log(message, color)
    print(string.format("%s[%s]^0 %s", color or "^7", LOG_PREFIX, message))
end

local function getAvailableLocationsString()
    local locationNames = {}

    for locationName in pairs(Config.Locations) do
        locationNames[#locationNames + 1] = locationName
    end

    table.sort(locationNames)
    return table.concat(locationNames, ", ")
end

local function getInteriorId(locationData)
    local coords = locationData.coords
    if not coords then
        return 0
    end

    for _ = 1, INTERIOR_LOOKUP_ATTEMPTS do
        local interior = GetInteriorAtCoordsWithType(
            coords.x,
            coords.y,
            coords.z,
            locationData.interior_type
        )

        if (not interior or interior == 0) and coords then
            interior = GetInteriorAtCoords(coords.x, coords.y, coords.z)
        end

        if interior and interior ~= 0 and IsValidInterior(interior) then
            return interior
        end

        Wait(INTERIOR_LOOKUP_WAIT_MS)
    end

    return 0
end

local function applyInteriorState(interior, enabled)
    DisableInterior(interior, not enabled)

    if RefreshInterior then
        RefreshInterior(interior)
    end
end

CreateThread(function()
    Wait(1000) -- Wait for game to fully load

    if Config.Debug then
        log("Starting interior management...", "^2")
    end

    -- Process each location from config
    for locationName, locationData in pairs(Config.Locations) do
        if locationData.coords then
            local interior = getInteriorId(locationData)

            if interior ~= 0 then
                applyInteriorState(interior, locationData.enabled)

                if Config.Debug then
                    if locationData.enabled then
                        log(string.format(
                            "Enabled interior for %s at coords: %.2f, %.2f, %.2f",
                            locationName,
                            locationData.coords.x,
                            locationData.coords.y,
                            locationData.coords.z
                        ), "^2")
                    else
                        log(string.format(
                            "Disabled interior for %s at coords: %.2f, %.2f, %.2f",
                            locationName,
                            locationData.coords.x,
                            locationData.coords.y,
                            locationData.coords.z
                        ), "^1")
                    end
                end
            elseif Config.Debug then
                log(string.format(
                    "Warning: No interior found for %s at coords: %.2f, %.2f, %.2f",
                    locationName,
                    locationData.coords.x,
                    locationData.coords.y,
                    locationData.coords.z
                ), "^3")
            end
        end
    end

    if Config.Debug then
        log("Interior management completed!", "^2")
    end
end)

-- Function to toggle a specific location's interior (for debugging or admin commands)
function ToggleBarberInterior(locationName)
    if not Config.Locations[locationName] then
        log("Error: Location '" .. locationName .. "' not found!", "^1")
        return false
    end

    local locationData = Config.Locations[locationName]
    local interior = getInteriorId(locationData)

    if interior ~= 0 then
        locationData.enabled = not locationData.enabled
        applyInteriorState(interior, locationData.enabled)

        if locationData.enabled then
            log(string.format("Enabled interior for %s", locationName), "^2")
        else
            log(string.format("Disabled interior for %s", locationName), "^1")
        end

        return true
    else
        log(string.format("Warning: No interior found for %s", locationName), "^3")
        return false
    end
end

-- Console command for toggling interiors (optional - for debugging)
RegisterCommand('togglebarber', function(source, args)
    if #args < 1 then
        log("Usage: togglebarber <location>", "^3")
        log("Available locations: " .. getAvailableLocationsString(), "^3")
        return
    end

    ToggleBarberInterior(args[1])
end, false)