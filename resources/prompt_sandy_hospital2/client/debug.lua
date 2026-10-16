-- ============================================================
-- Debug Utilities – test scenario anims & collect coordinates
-- Remove this file from fxmanifest before release.
-- ============================================================

local activeScenario = false

-- /scenario [name] — play a scenario animation at your current spot
-- Examples:
--   /scenario PROP_HUMAN_SEAT_ARMCHAIR
--   /scenario PROP_HUMAN_SEAT_CHAIR_MP_PLAYER
--   /scenario PROP_HUMAN_SEAT_CHAIR_UPRIGHT
--   /scenario WORLD_HUMAN_SEAT_LEDGE_EATING
--   /scenario WORLD_HUMAN_SUNBATHE_BACK
--   /scenario anim@gangops@morgue@table@ body_search   (dict + anim name)
RegisterCommand('scenario', function(_, args)
    if not args[1] then
        lib.notify({ title = 'Debug', description = 'Usage: /scenario SCENARIO_NAME', type = 'error' })
        return
    end

    local ped = cache.ped or PlayerPedId()

    -- Stop any current anim first
    ClearPedTasks(ped)
    Wait(100)

    local name = args[1]

    -- If second arg provided, treat as dict + anim (TaskPlayAnim)
    if args[2] then
        local dict = args[1]
        local anim = args[2]
        lib.requestAnimDict(dict)
        TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, 1, 0, false, false, false)
        activeScenario = true
        lib.notify({ title = 'Debug', description = 'Playing anim: ' .. dict .. ' / ' .. anim, type = 'info' })
        return
    end

    -- Otherwise treat as scenario
    local coords  = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    TaskStartScenarioAtPosition(ped, name, coords.x, coords.y, coords.z, heading, 0, true, true)
    activeScenario = true

    lib.notify({ title = 'Debug', description = 'Playing scenario: ' .. name, type = 'info' })
end, false)

-- /scenarioat [name] [x] [y] [z] [heading] — play scenario at specific coords
-- Example: /scenarioat PROP_HUMAN_SEAT_BENCH 1738.7485 3618.663 34.088646 301.829
RegisterCommand('scenarioat', function(_, args)
    if not args[1] or not args[2] or not args[3] or not args[4] then
        lib.notify({ title = 'Debug', description = 'Usage: /scenarioat NAME x y z [heading]', type = 'error' })
        return
    end

    local ped     = cache.ped or PlayerPedId()
    local name    = args[1]
    local x       = tonumber(args[2])
    local y       = tonumber(args[3])
    local z       = tonumber(args[4])
    local heading = tonumber(args[5]) or GetEntityHeading(ped)

    ClearPedTasks(ped)
    Wait(100)

    TaskStartScenarioAtPosition(ped, name, x, y, z, heading, 0, true, true)
    activeScenario = true

    lib.notify({ title = 'Debug', description = 'Scenario at: ' .. string.format('%.2f, %.2f, %.2f h:%.1f', x, y, z, heading), type = 'info' })
end, false)

-- /stopanim — cancel current scenario/animation
RegisterCommand('stopanim', function()
    local ped = cache.ped or PlayerPedId()
    ClearPedTasks(ped)
    activeScenario = false
    lib.notify({ title = 'Debug', description = 'Animation stopped.', type = 'success' })
end, false)

-- /mycoords — print current position + heading to chat & F8 console
RegisterCommand('mycoords', function()
    local ped     = cache.ped or PlayerPedId()
    local coords  = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    local text = string.format('%.6f, %.6f, %.6f, %.3f', coords.x, coords.y, coords.z, heading)
    print('[DEBUG] Coords: ' .. text)
    lib.notify({ title = 'Coords', description = text, type = 'info', duration = 10000 })

    -- Also copy-friendly line in F8
    print(string.format("vector3(%.6f, %.6f, %.6f) -- heading: %.3f", coords.x, coords.y, coords.z, heading))
end, false)

-- /propcoords — print nearest prop's origin + heading (for offset calculation)
RegisterCommand('propcoords', function(_, args)
    local model = args[1]
    if not model then
        lib.notify({ title = 'Debug', description = 'Usage: /propcoords model_name', type = 'error' })
        return
    end

    local ped    = cache.ped or PlayerPedId()
    local coords = GetEntityCoords(ped)
    local hash   = joaat(model)
    local obj    = GetClosestObjectOfType(coords.x, coords.y, coords.z, 50.0, hash, false, false, false)

    if not obj or obj == 0 then
        lib.notify({ title = 'Debug', description = 'Prop not found nearby: ' .. model, type = 'error' })
        return
    end

    local propCoords  = GetEntityCoords(obj)
    local propHeading = GetEntityHeading(obj)

    local text = string.format('%.6f, %.6f, %.6f, heading: %.3f', propCoords.x, propCoords.y, propCoords.z, propHeading)
    print('[DEBUG] Prop ' .. model .. ': ' .. text)
    lib.notify({ title = 'Prop: ' .. model, description = text, type = 'info', duration = 10000 })

    -- Print offset from prop to player
    local myCoords = GetEntityCoords(ped)
    local myHeading = GetEntityHeading(ped)
    local rad = math.rad(propHeading)

    -- Reverse-rotate to get local offset relative to prop
    local dx = myCoords.x - propCoords.x
    local dy = myCoords.y - propCoords.y
    local dz = myCoords.z - propCoords.z
    local localX =  dx * math.cos(rad) + dy * math.sin(rad)
    local localY = -dx * math.sin(rad) + dy * math.cos(rad)

    local headingOffset = myHeading - propHeading

    local offsetText = string.format('offset: %.3f, %.3f, %.3f | headingOff: %.1f', localX, localY, dz, headingOffset)
    print('[DEBUG] ' .. offsetText)
    lib.notify({ title = 'Offset from prop', description = offsetText, type = 'success', duration = 10000 })
end, false)
