-- ============================================================
-- Hospital Bed Lie Down – Client-side
-- Lets players lie down on hospital beds.
-- Pure client-side – no server needed, beds are not exclusive.
-- ============================================================
local hasOxTarget = GetResourceState('ox_target') == 'started'
local hasOxLib    = GetResourceState('ox_lib')    == 'started'

if not hasOxLib then
    print('[prompt_sandy_hospital2] ^1Bed system disabled – ox_lib not found.^7')
    return
end

-- ────────────────────────────────────────────────────────────
-- State
-- ────────────────────────────────────────────────────────────
local isOnBed      = false
local currentBed   = nil   -- entity handle of the bed we're on

-- Build a lookup: modelHash → bed config entry (for per-bed offsets)
local bedByHash = {}
local bedModelHashes = {}
for _, bed in ipairs(BedConfig.beds) do
    local hash = joaat(bed.model)
    bedByHash[hash] = bed
    bedModelHashes[#bedModelHashes + 1] = hash
end

-- ────────────────────────────────────────────────────────────
-- Helpers
-- ────────────────────────────────────────────────────────────

--- Find the closest bed entity near the player (any of the configured models).
--- Uses a tight radius (1.5m) and line-of-sight check to avoid
--- detecting beds behind walls.
--- For beds with interactCoords (e.g. surgery bed with underground origin),
--- checks player distance to the fixed surface coords instead.
--- @return number|nil entity, table|nil bedCfg
local function findNearestBed()
    local ped    = cache.ped or PlayerPedId()
    local coords = GetEntityCoords(ped)
    local closest, closestDist, closestCfg = nil, 1.5, nil

    for _, bedCfg in ipairs(BedConfig.beds) do
        local hash = joaat(bedCfg.model)

        if bedCfg.interactCoords then
            -- Beds with underground origin: check distance to fixed surface coords
            for _, ic in ipairs(bedCfg.interactCoords) do
                local dist = #(coords - ic)
                if dist < closestDist then
                    -- Find the actual entity to pass along
                    local obj = GetClosestObjectOfType(ic.x, ic.y, ic.z, 10.0, hash, false, false, false)
                    if obj and obj ~= 0 and DoesEntityExist(obj) then
                        closest     = obj
                        closestDist = dist
                        closestCfg  = bedCfg
                    end
                end
            end
        else
            -- Normal beds: use entity origin directly
            local obj = GetClosestObjectOfType(coords.x, coords.y, coords.z, closestDist, hash, false, false, false)
            if obj and obj ~= 0 and DoesEntityExist(obj) then
                local objCoords = GetEntityCoords(obj)
                local dist = #(coords - objCoords)
                if dist < closestDist then
                    local hasLOS = HasEntityClearLosToEntity(ped, obj, 17)
                    if hasLOS then
                        closest     = obj
                        closestDist = dist
                        closestCfg  = bedCfg
                    end
                end
            end
        end
    end

    return closest, closestCfg
end

--- Get the per-bed config for an entity by its model hash.
local function getBedCfgForEntity(entity)
    if not entity or not DoesEntityExist(entity) then return nil end
    return bedByHash[GetEntityModel(entity)]
end

--- Place player on bed using world coordinates (no attachment).
--- Hospital beds are static ytyp props — AttachEntityToEntity doesn't
--- sync to other clients for non-networked entities. Instead we:
---   1. Teleport ped to exact world position
---   2. Play the animation (camera adjusts to lying pose)
---   3. Wait for anim to settle, THEN freeze (avoids camera height bug)
local function attachToBed(bed, bedCfg)
    if isOnBed then return false end

    local anim     = BedConfig.lieAnim
    local offset   = bedCfg.lieOffset
    local rotation = bedCfg.lieRotation

    local ped = cache.ped or PlayerPedId()

    -- Load animation
    lib.requestAnimDict(anim.dict)

    -- Calculate world position: bed origin + offset rotated by bed heading
    local bedCoords  = GetEntityCoords(bed)
    local bedHeading = GetEntityHeading(bed)
    local rad        = math.rad(-bedHeading) -- negate for GTA coord system

    local worldX = bedCoords.x + offset.x * math.cos(rad) - offset.y * math.sin(rad)
    local worldY = bedCoords.y + offset.x * math.sin(rad) + offset.y * math.cos(rad)
    local worldZ = bedCoords.z + offset.z

    -- Teleport ped to the bed position
    SetEntityCoordsNoOffset(ped, worldX, worldY, worldZ, false, false, false)
    SetEntityHeading(ped, bedHeading + rotation.z)

    -- Play animation FIRST so the camera adjusts to lying pose
    TaskPlayAnim(ped, anim.dict, anim.name,
        8.0, -8.0, -1, 1, 0, false, false, false)

    -- Wait for animation to start and camera to settle at lying height
    Wait(500)

    -- NOW freeze — camera is already at correct height, ped won't slide
    FreezeEntityPosition(ped, true)

    isOnBed    = true
    currentBed = bed

    return true
end

--- Release player from bed and clean up.
local function detachFromBed()
    if not isOnBed then return end

    local ped = cache.ped or PlayerPedId()

    -- Unfreeze and stop animation
    FreezeEntityPosition(ped, false)
    ClearPedTasks(ped)
    RemoveAnimDict(BedConfig.lieAnim.dict)

    isOnBed    = false
    currentBed = nil
end

-- ────────────────────────────────────────────────────────────
-- Interaction: lie on bed then input loop
-- ────────────────────────────────────────────────────────────

--- Main interaction flow – attach, show UI, block until get-up.
local function useBed(targetEntity)
    if isOnBed then return end

    local bed, bedCfg

    if targetEntity and DoesEntityExist(targetEntity) then
        bed    = targetEntity
        bedCfg = getBedCfgForEntity(targetEntity)
    end

    if not bed or not bedCfg then
        bed, bedCfg = findNearestBed()
    end

    if not bed or not bedCfg then
        lib.notify({ title = 'Hospital Bed', description = 'No bed nearby.', type = 'error' })
        return
    end

    if not attachToBed(bed, bedCfg) then return end

    -- Show persistent get-up hint
    lib.showTextUI(BedConfig.messages.getUpHint)

    -- Input loop – disable movement, wait for get-up key
    while isOnBed do
        DisableControlAction(0, 32, true)  -- W
        DisableControlAction(0, 33, true)  -- S
        DisableControlAction(0, 34, true)  -- A
        DisableControlAction(0, 35, true)  -- D
        DisableControlAction(0, 22, true)  -- Space
        DisableControlAction(0, 36, true)  -- Ctrl

        if IsControlJustPressed(0, 194) or IsControlJustPressed(0, 177) then -- Backspace / ESC
            detachFromBed()
            break
        end

        Wait(0)
    end

    lib.hideTextUI()
end

-- ────────────────────────────────────────────────────────────
-- Setup interactions
-- ────────────────────────────────────────────────────────────

local function shouldUseOxTarget()
    if BedConfig.interaction == 'ox_target' then return true end
    if BedConfig.interaction == 'textui'    then return false end
    return hasOxTarget -- 'auto'
end

local function setupBedInteractions()
    if shouldUseOxTarget() then
        -- Register ox_target for each bed model
        for _, bed in ipairs(BedConfig.beds) do
            if bed.interactCoords then
                -- Beds whose model origin is underground (e.g. surgery bed):
                -- addModel raycast can never hit them. Use fixed sphere zones
                -- at the actual bed surface coordinates instead.
                local bedModel = bed.model
                local hash     = joaat(bedModel)

                for idx, zoneCoords in ipairs(bed.interactCoords) do

                    exports.ox_target:addSphereZone({
                        coords = zoneCoords,
                        radius = 1.5,
                        options = {
                            {
                                name     = 'bed_lie_' .. bedModel .. '_' .. idx,
                                icon     = 'fas fa-bed',
                                label    = BedConfig.messages.lieDown,
                                canInteract = function()
                                    return not isOnBed
                                end,
                                onSelect = function()
                                    local c = zoneCoords
                                    local entity = GetClosestObjectOfType(c.x, c.y, c.z, 5.0, hash, false, false, false)
                                    if entity and entity ~= 0 then
                                        useBed(entity)
                                    else
                                        useBed()
                                    end
                                end,
                            },
                            {
                                name     = 'bed_getup_' .. bedModel .. '_' .. idx,
                                icon     = 'fas fa-person-walking',
                                label    = BedConfig.messages.getUp,
                                canInteract = function()
                                    return isOnBed
                                end,
                                onSelect = function()
                                    detachFromBed()
                                end,
                            },
                        },
                    })
                end
            else
                -- Normal beds: addModel works fine
                exports.ox_target:addModel(joaat(bed.model), {
                    {
                        name     = 'bed_lie_' .. bed.model,
                        icon     = 'fas fa-bed',
                        label    = BedConfig.messages.lieDown,
                        canInteract = function()
                            return not isOnBed
                        end,
                        onSelect = function(data)
                            useBed(data.entity)
                        end,
                    },
                    {
                        name     = 'bed_getup_' .. bed.model,
                        icon     = 'fas fa-person-walking',
                        label    = BedConfig.messages.getUp,
                        canInteract = function(entity)
                            return isOnBed and currentBed == entity
                        end,
                        onSelect = function()
                            detachFromBed()
                        end,
                    },
                })
            end
        end
    else
        -- Fallback: proximity thread + [E] key for nearest bed
        CreateThread(function()
            local uiShown = false

            while true do
                local sleep = 500

                if not isOnBed then
                    local bed = findNearestBed()
                    if bed then
                        sleep = 0
                        if not uiShown then
                            lib.showTextUI('[E] ' .. BedConfig.messages.lieDown)
                            uiShown = true
                        end

                        -- E = lie down
                        if IsControlJustPressed(0, 38) then
                            lib.hideTextUI()
                            uiShown = false
                            useBed()
                        end
                    else
                        if uiShown then
                            lib.hideTextUI()
                            uiShown = false
                        end
                    end
                else
                    sleep = 0
                end

                Wait(sleep)
            end
        end)
    end
end

setupBedInteractions()

-- ============================================================
-- COUCH / CHAIR SEATING  (scenario-based, server-synced)
-- ============================================================
-- Uses TaskStartScenarioAtPosition for natural sit-down / stand-up.
-- Each seat is an ox_target sphere zone at absolute world coords.
-- Server tracks occupancy — handles crashes, disconnects, conflicts.
-- ============================================================

local isOnSeat      = false
local currentSeatId = nil   -- index of the seat we're on

--- Stand up from the current seat and tell the server.
local function getUpFromSeat()
    if not isOnSeat then return end

    local ped = cache.ped or PlayerPedId()
    ClearPedTasks(ped)

    -- Tell server to free the seat (fire-and-forget)
    lib.callback.await('seats:release', false)

    isOnSeat      = false
    currentSeatId = nil
end

--- Sit down on a specific seat using its scenario animation.
--- Asks server for permission first (checks occupancy + conflicts).
local function sitOnSeat(seatIdx)
    if isOnBed or isOnSeat then return end

    local seat = CouchConfig.seats[seatIdx]
    if not seat then return end

    -- Ask server if seat is available (occupancy + conflict check)
    local granted, reason = lib.callback.await('seats:request', false, seatIdx)

    if not granted then
        local msg = CouchConfig.messages.occupied
        if reason == 'blocked' then
            msg = CouchConfig.messages.blocked
        end
        lib.notify({ title = 'Seat', description = msg, type = 'error' })
        return
    end

    local ped = cache.ped or PlayerPedId()

    ClearPedTasks(ped)
    Wait(50)

    TaskStartScenarioAtPosition(ped, seat.scenario,
        seat.coords.x, seat.coords.y, seat.coords.z,
        seat.heading, 0, true, true)

    isOnSeat      = true
    currentSeatId = seatIdx

    -- Show persistent get-up hint
    lib.showTextUI(CouchConfig.messages.getUpHint)

    -- Input loop – disable movement, wait for get-up key
    while isOnSeat do
        DisableControlAction(0, 32, true)  -- W
        DisableControlAction(0, 33, true)  -- S
        DisableControlAction(0, 34, true)  -- A
        DisableControlAction(0, 35, true)  -- D
        DisableControlAction(0, 22, true)  -- Space
        DisableControlAction(0, 36, true)  -- Ctrl

        if IsControlJustPressed(0, 194) or IsControlJustPressed(0, 177) then -- Backspace / ESC
            getUpFromSeat()
            break
        end

        Wait(0)
    end

    lib.hideTextUI()
end

--- Find nearest configured couch seat for ox_lib fallback mode.
--- @return number|nil seatIdx
local function findNearestSeatIdx()
    if not CouchConfig or not CouchConfig.seats then return nil end

    local ped    = cache.ped or PlayerPedId()
    local coords = GetEntityCoords(ped)
    local maxDist = CouchConfig.interactRadius or 0.6
    local closestIdx, closestDist = nil, maxDist

    for i, seat in ipairs(CouchConfig.seats) do
        -- Skip placeholders
        if not (seat.coords.x == 0.0 and seat.coords.y == 0.0 and seat.coords.z == 0.0) then
            local dist = #(coords - seat.coords)
            if dist < closestDist then
                closestIdx = i
                closestDist = dist
            end
        end
    end

    return closestIdx
end

--- Set up couch interactions:
--- - ox_target: one sphere zone per seat
--- - ox_lib fallback: proximity + [E]
local function setupCouchInteractions()
    if not CouchConfig or not CouchConfig.seats then return end

    if hasOxTarget then
        for i, seat in ipairs(CouchConfig.seats) do
            -- Skip placeholder seats (coords at origin)
            if seat.coords.x == 0.0 and seat.coords.y == 0.0 and seat.coords.z == 0.0 then
                goto continue
            end

            local seatIdx = i
            exports.ox_target:addSphereZone({
                coords = seat.coords,
                radius = CouchConfig.interactRadius or 0.6,
                options = {
                    {
                        name     = 'couch_sit_' .. seatIdx,
                        icon     = 'fas fa-couch',
                        label    = seat.label or CouchConfig.messages.sit,
                        canInteract = function()
                            return not isOnBed and not isOnSeat
                        end,
                        onSelect = function()
                            sitOnSeat(seatIdx)
                        end,
                    },
                    {
                        name     = 'couch_getup_' .. seatIdx,
                        icon     = 'fas fa-person-walking',
                        label    = CouchConfig.messages.getUp,
                        canInteract = function()
                            return isOnSeat and currentSeatId == seatIdx
                        end,
                        onSelect = function()
                            getUpFromSeat()
                        end,
                    },
                },
            })

            ::continue::
        end
        return
    end

    -- ox_lib-only fallback (no ox_target): [E] to sit near seat coords.
    CreateThread(function()
        local uiShown = false

        while true do
            local sleep = 500

            if not isOnBed and not isOnSeat then
                local seatIdx = findNearestSeatIdx()
                if seatIdx then
                    sleep = 0
                    if not uiShown then
                        lib.showTextUI('[E] ' .. (CouchConfig.messages.sit or 'Sit Down'))
                        uiShown = true
                    end

                    if IsControlJustPressed(0, 38) then -- E
                        lib.hideTextUI()
                        uiShown = false
                        sitOnSeat(seatIdx)
                    end
                elseif uiShown then
                    lib.hideTextUI()
                    uiShown = false
                end
            elseif uiShown then
                lib.hideTextUI()
                uiShown = false
            end

            Wait(sleep)
        end
    end)
end

setupCouchInteractions()

-- ────────────────────────────────────────────────────────────
-- Cleanup on resource stop
-- ────────────────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end
    detachFromBed()
    if isOnSeat then
        local ped = cache.ped or PlayerPedId()
        ClearPedTasks(ped)
        isOnSeat      = false
        currentSeatId = nil
    end
end)
