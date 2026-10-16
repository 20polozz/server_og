-- ============================================================
-- MRI Scanner – Client-side
-- The patient's client SPAWNS the bed entity so it always has
-- full network control.  Movement is triggered via state bags
-- and animated per-frame on the owning client.
-- ============================================================

local hasOxTarget = GetResourceState('ox_target') == 'started'
local hasOxLib    = GetResourceState('ox_lib')    == 'started'

if not hasOxLib then
    print('[prompt_sandy_hospital2] ^1MRI system disabled – ox_lib not found.^7')
    return
end

local bedModel         = joaat(MRIConfig.bedModel)
local hiddenBedPoint   = nil
local isPatient        = false
local patientBedEntity = nil
local scanLightActive  = false

-- ============================================================
-- Static prop hide / restore  (prison-escape pattern)
-- ============================================================
RegisterNetEvent('prompt_sandy_hospital2:mri:toggleBedVisibility', function(visible, coords)
    -- Tear down any existing proximity point first
    if hiddenBedPoint then
        hiddenBedPoint:onExit(hiddenBedPoint)
        hiddenBedPoint:remove()
        hiddenBedPoint = nil
    end

    -- visible == true  → just restore (point removed above)
    if visible then return end

    -- visible == false → create a proximity point that hides the static prop
    hiddenBedPoint = lib.points.new({
        coords   = coords,
        distance = 50,

        onEnter = function(self)
            for _, obj in pairs(lib.getNearbyObjects(coords, 5.0)) do
                local isStaticBed = GetEntityModel(obj.object) == bedModel
                                    and not Entity(obj.object).state.isDynamicMRIBed
                if isStaticBed then
                    SetEntityVisible(obj.object, false, 0)
                    SetEntityCollision(obj.object, false, false)
                    SetEntityAlpha(obj.object, 0, false)
                    self.entity = obj.object
                    break
                end
            end
        end,

        onExit = function(self)
            if self.entity and DoesEntityExist(self.entity) then
                SetEntityVisible(self.entity, true, 0)
                SetEntityCollision(self.entity, true, true)
                SetEntityAlpha(self.entity, 255, false)
                self.entity = nil
            end
        end,
    })
end)

-- ============================================================
-- Smooth bed movement via state bag  (radius 20m)
-- The entity owner (patient) always has control → guaranteed
-- smooth movement.  Other nearby clients also attempt it.
-- ============================================================
local MRI_MOVE_RADIUS = 20.0

AddStateBagChangeHandler('bedMovement', nil, function(bagName, _key, value)
    -- Only react when movement data is set (not cleared)
    if not value then return end

    -- Extract entity from the bag name  (format: "entity:XXXXX")
    local netID = tonumber(bagName:match('entity:(%d+)'))
    if not netID then return end

    -- Must exist on our client
    if not NetworkDoesNetworkIdExist(netID) then return end
    local entity = NetworkGetEntityFromNetworkId(netID)
    if not entity or not DoesEntityExist(entity) then return end

    -- Radius check – only process if player is within 20m
    local playerCoords = GetEntityCoords(cache.ped or PlayerPedId())
    local midX = (value.from.x + value.to.x) / 2
    local midY = (value.from.y + value.to.y) / 2
    local midZ = (value.from.z + value.to.z) / 2
    local dist = #(playerCoords - vector3(midX, midY, midZ))
    if dist > MRI_MOVE_RADIUS then return end

    -- Run smooth client-side interpolation in a thread
    CreateThread(function()
        local from     = value.from
        local to       = value.to
        local duration = value.duration
        local startMs  = GetGameTimer()

        -- Entity owner (the patient who spawned it) already has control.
        -- Other nearby clients try to get control; if they can't, they
        -- at least see network-replicated movement from the owner.
        if not NetworkHasControlOfEntity(entity) then
            local attempts = 0
            while not NetworkHasControlOfEntity(entity) and attempts < 10 do
                NetworkRequestControlOfEntity(entity)
                Wait(50)
                attempts = attempts + 1
            end
            -- If we still don't have control, bail – the owner handles it
            if not NetworkHasControlOfEntity(entity) then return end
        end

        -- Unfreeze for movement
        FreezeEntityPosition(entity, false)

        while true do
            local elapsed = GetGameTimer() - startMs
            local t = math.min(elapsed / duration, 1.0)

            -- Smoothstep ease-in-out
            t = t * t * (3.0 - 2.0 * t)

            local x = from.x + (to.x - from.x) * t
            local y = from.y + (to.y - from.y) * t
            local z = from.z + (to.z - from.z) * t
            SetEntityCoordsNoOffset(entity, x, y, z, false, false, false)

            if t >= 1.0 then break end
            Wait(0) -- per-frame for buttery smooth movement
        end

        -- Snap to final and re-freeze
        SetEntityCoordsNoOffset(entity, to.x, to.y, to.z, false, false, false)
        FreezeEntityPosition(entity, true)
    end)
end)

-- ============================================================
-- MRI scan light effect  (visible to all nearby clients)
-- Flashing blue light inside the MRI bore during a scan.
-- ============================================================

--- Start the scan light flashing loop for the given duration (ms).
local function startScanLight(duration)
    if scanLightActive then return end
    scanLightActive = true

    CreateThread(function()
        local sl       = MRIConfig.scanLight
        local coords   = sl.coords
        local r, g, b  = sl.color.r, sl.color.g, sl.color.b
        local range    = sl.range
        local peakInt  = sl.intensity
        local hz       = sl.flashHz
        local startMs  = GetGameTimer()

        while scanLightActive and (GetGameTimer() - startMs) < duration do
            -- Sine-wave pulse: 0 → 1 → 0 …
            local elapsed = (GetGameTimer() - startMs) / 1000.0
            local pulse   = (math.sin(elapsed * hz * 2.0 * math.pi) + 1.0) / 2.0

            -- Quick flicker: randomly dim a fraction of frames for realism
            local flicker = 1.0
            if math.random() < 0.15 then
                flicker = 0.3 + math.random() * 0.4
            end

            local intensity = peakInt * pulse * flicker

            if intensity > 0.05 then
                DrawLightWithRange(coords.x, coords.y, coords.z, r, g, b, range, intensity)
            end

            Wait(0) -- per-frame
        end

        scanLightActive = false
    end)
end

--- Broadcast event: all clients start the scan light effect.
RegisterNetEvent('prompt_sandy_hospital2:mri:scanLightStart', function(duration)
    startScanLight(duration)
end)

--- Broadcast event: force-stop the light (e.g. patient released mid-scan).
RegisterNetEvent('prompt_sandy_hospital2:mri:scanLightStop', function()
    scanLightActive = false
end)

-- ============================================================
-- MRI scan progress  (shown to the patient)
-- ============================================================
RegisterNetEvent('prompt_sandy_hospital2:mri:scanProgress', function(duration)
    if not lib.progressCircle then return end
    lib.progressCircle({
        duration = duration,
        label    = MRIConfig.messages.scanInProgress,
        useWhileDead = false,
        canCancel    = false,
        disable = {
            move   = true,
            car    = true,
            combat = true,
        },
    })
end)

RegisterNetEvent('prompt_sandy_hospital2:mri:scanDone', function()
    lib.notify({
        title       = MRIConfig.messages.menuTitle,
        description = MRIConfig.messages.scanComplete,
        type        = 'success',
    })
end)

-- ============================================================
-- Patient — lie on the MRI bed
-- ============================================================

--- Detach and clean up the patient (local only, no server call).
local function detachPatient()
    if not isPatient then return end
    isPatient = false

    local ped = cache.ped or PlayerPedId()
    DetachEntity(ped, true, false)
    ClearPedTasks(ped)

    -- Delete the bed entity we own
    if patientBedEntity and DoesEntityExist(patientBedEntity) then
        DeleteEntity(patientBedEntity)
    end
    patientBedEntity = nil
end

--- Patient voluntarily gets up – detach + tell server.
local function patientGetUp()
    if not isPatient then return end
    detachPatient()
    lib.callback.await('prompt_sandy_hospital2:mri:getUp', false)
end

--- Helper: abort lie-down and tell server to free the slot.
local function abortLieDown()
    lib.callback.await('prompt_sandy_hospital2:mri:abortLieDown', false)
    lib.notify({
        title       = MRIConfig.messages.menuTitle,
        description = 'MRI bed failed to spawn – please try again.',
        type        = 'error',
    })
end

--- Spawn the dynamic bed entity on THIS client.
--- Returns the entity handle, or nil on failure.
local function spawnBedOnClient()
    -- Load the model
    local model = bedModel
    if not HasModelLoaded(model) then
        RequestModel(model)
        local timeout = 0
        while not HasModelLoaded(model) and timeout < 50 do
            Wait(100)
            timeout = timeout + 1
        end
        if not HasModelLoaded(model) then
            print('[prompt_sandy_hospital2] ^1Failed to load MRI bed model^7')
            return nil
        end
    end

    local coords = MRIConfig.bedOutsideCoords

    -- Create the object (networked = true so others see it)
    local entity = CreateObjectNoOffset(model, coords.x, coords.y, coords.z, true, true, false)
    if not entity or entity == 0 then
        print('[prompt_sandy_hospital2] ^1CreateObjectNoOffset returned invalid entity^7')
        SetModelAsNoLongerNeeded(model)
        return nil
    end

    -- Immediately set position, rotation, and freeze BEFORE the next frame renders
    SetEntityCoordsNoOffset(entity, coords.x, coords.y, coords.z, false, false, false)
    SetEntityRotation(entity, 0.0, 0.0, MRIConfig.bedHeading, 2, true)
    FreezeEntityPosition(entity, true)

    -- Mark so clients can tell this apart from the static prop
    Entity(entity).state:set('isDynamicMRIBed', true, true)

    -- Wait a tick for networking to register
    Wait(100)

    local netID = NetworkGetNetworkIdFromEntity(entity)
    if not netID or netID == 0 then
        print('[prompt_sandy_hospital2] ^1Failed to get network ID for bed entity^7')
        DeleteEntity(entity)
        SetModelAsNoLongerNeeded(model)
        return nil
    end

    SetModelAsNoLongerNeeded(model)
    return entity, netID
end

--- Core lie-down logic (non-blocking). Returns true on success.
local function doLieDown()
    if isPatient then return false end

    -- Ask the server to reserve the slot
    local ok = lib.callback.await('prompt_sandy_hospital2:mri:lieDown', false)
    if not ok then return false end

    -- Spawn the bed on our client
    local bedEntity, netID = spawnBedOnClient()
    if not bedEntity then
        abortLieDown()
        return false
    end

    -- Tell the server our netID so it can track the entity
    local registered = lib.callback.await('prompt_sandy_hospital2:mri:registerBed', false, netID)
    if not registered then
        DeleteEntity(bedEntity)
        abortLieDown()
        return false
    end

    isPatient        = true
    patientBedEntity = bedEntity

    local ped       = cache.ped or PlayerPedId()
    local bedCoords = GetEntityCoords(bedEntity)

    -- Load animation
    lib.requestAnimDict(MRIConfig.patientAnim.dict)

    -- Move player to bed and attach
    SetEntityCoords(ped, bedCoords.x, bedCoords.y, bedCoords.z + 0.5, false, false, false, false)
    Wait(100)

    local off = MRIConfig.patientOffset
    local rot = MRIConfig.patientRotation
    AttachEntityToEntity(
        ped, bedEntity, 0,
        off.x, off.y, off.z,
        rot.x, rot.y, rot.z,
        false, false, false, true, 0, true
    )

    -- Play lying animation
    TaskPlayAnim(ped, MRIConfig.patientAnim.dict, MRIConfig.patientAnim.name,
        8.0, -8.0, -1, 1, 0, false, false, false)

    return true
end

--- Full patient interaction – lies down, shows persistent UI, blocks until released.
local function patientLieDown()
    if not doLieDown() then
        lib.notify({
            title       = MRIConfig.messages.menuTitle,
            description = MRIConfig.messages.alreadyInUse,
            type        = 'error',
        })
        return
    end

    -- Persistent get-up button
    lib.showTextUI(MRIConfig.messages.getUpHint)

    -- Input loop – disable movement, wait for get-up key
    while isPatient do
        DisableControlAction(0, 32, true)  -- W
        DisableControlAction(0, 33, true)  -- S
        DisableControlAction(0, 34, true)  -- A
        DisableControlAction(0, 35, true)  -- D
        DisableControlAction(0, 22, true)  -- Space
        DisableControlAction(0, 36, true)  -- Ctrl

        if IsControlJustPressed(0, 194) or IsControlJustPressed(0, 177) then -- Backspace / ESC
            patientGetUp()
            break
        end

        Wait(0)
    end

    lib.hideTextUI()
    RemoveAnimDict(MRIConfig.patientAnim.dict)
end

-- ============================================================
-- Force get-up  (operator-initiated or /testmri cleanup)
-- ============================================================
RegisterNetEvent('prompt_sandy_hospital2:mri:forceGetUp', function()
    if not isPatient then return end
    -- Cancel any active progress circle (scan in progress)
    if lib.cancelProgress then lib.cancelProgress() end
    detachPatient()
end)

-- ============================================================
-- /testmri  –  automated solo test sequence
-- ============================================================
RegisterNetEvent('prompt_sandy_hospital2:mri:runTest', function()
    CreateThread(function()
        lib.notify({ title = 'MRI Test', description = 'Starting automated MRI test...', type = 'info' })

        -- 1. Lie down
        if not doLieDown() then
            lib.notify({ title = 'MRI Test', description = 'Failed to lie down (bed in use?)', type = 'error' })
            return
        end

        Wait(1500)

        -- 2. Move bed inside
        lib.notify({ title = 'MRI Test', description = 'Moving bed inside...', type = 'info' })
        lib.callback.await('prompt_sandy_hospital2:mri:moveBed', false, 'inside')
        Wait(MRIConfig.slideDuration + 1000)

        -- 3. Start scan
        lib.notify({ title = 'MRI Test', description = 'Starting scan...', type = 'info' })
        lib.callback.await('prompt_sandy_hospital2:mri:startScan', false)
        Wait(MRIConfig.scanDuration + 1500)

        -- 4. Move bed outside
        lib.notify({ title = 'MRI Test', description = 'Moving bed outside...', type = 'info' })
        lib.callback.await('prompt_sandy_hospital2:mri:moveBed', false, 'outside')
        Wait(MRIConfig.slideDuration + 1000)

        -- 5. Get up
        lib.notify({ title = 'MRI Test', description = 'Test complete!', type = 'success' })
        patientGetUp()
        RemoveAnimDict(MRIConfig.patientAnim.dict)
    end)
end)

-- ============================================================
-- Operator — MRI controls context menu
-- ============================================================
local function openOperatorMenu()
    local state = lib.callback.await('prompt_sandy_hospital2:mri:getState', false)
    if not state then
        lib.notify({
            title       = MRIConfig.messages.menuTitle,
            description = MRIConfig.messages.accessDenied,
            type        = 'error',
        })
        return
    end

    local options = {}

    -- Move inside (only when patient is on the bed and bed is outside)
    if state.hasPatient and state.bedPosition == 'outside' and not state.scanning then
        options[#options + 1] = {
            title    = MRIConfig.messages.moveInside,
            icon     = 'arrow-right',
            onSelect = function()
                local ok = lib.callback.await('prompt_sandy_hospital2:mri:moveBed', false, 'inside')
                if not ok then
                    lib.notify({ title = MRIConfig.messages.menuTitle, description = MRIConfig.messages.bedMoving, type = 'error' })
                end
            end,
        }
    end

    -- Start scan + move outside (only when bed is inside)
    if state.hasPatient and state.bedPosition == 'inside' and not state.scanning then
        options[#options + 1] = {
            title    = MRIConfig.messages.startScan,
            icon     = 'brain',
            onSelect = function()
                local ok = lib.callback.await('prompt_sandy_hospital2:mri:startScan', false)
                if not ok then
                    lib.notify({ title = MRIConfig.messages.menuTitle, description = MRIConfig.messages.scanInProgress, type = 'error' })
                end
            end,
        }
        options[#options + 1] = {
            title    = MRIConfig.messages.moveOutside,
            icon     = 'arrow-left',
            onSelect = function()
                local ok = lib.callback.await('prompt_sandy_hospital2:mri:moveBed', false, 'outside')
                if not ok then
                    lib.notify({ title = MRIConfig.messages.menuTitle, description = MRIConfig.messages.bedMoving, type = 'error' })
                end
            end,
        }
    end

    -- Release patient (always available when there is a patient)
    if state.hasPatient then
        options[#options + 1] = {
            title    = MRIConfig.messages.releasePatient,
            icon     = 'person-walking-arrow-right',
            onSelect = function()
                lib.callback.await('prompt_sandy_hospital2:mri:releasePatient', false)
            end,
        }
    end

    -- Fallback: no actions available
    if #options == 0 then
        local infoLabel = MRIConfig.messages.noPatient
        if state.scanning then
            infoLabel = MRIConfig.messages.scanInProgress
        elseif state.bedPosition == 'moving' then
            infoLabel = MRIConfig.messages.bedMoving
        end

        options[#options + 1] = {
            title    = infoLabel,
            icon     = 'circle-info',
            disabled = true,
        }
    end

    lib.registerContext({
        id      = 'mri_operator_menu',
        title   = MRIConfig.messages.menuTitle,
        options = options,
    })
    lib.showContext('mri_operator_menu')
end

-- ============================================================
-- Interaction setup  (ox_target or textUI+zones)
-- ============================================================
local function shouldUseOxTarget()
    if MRIConfig.interaction == 'ox_target' then return true end
    if MRIConfig.interaction == 'textui'    then return false end
    return hasOxTarget -- 'auto'
end

local function setupMRIInteractions()
    if shouldUseOxTarget() then
        -- ── ox_target: patient bed zone ──────────────
        exports.ox_target:addBoxZone({
            coords   = MRIConfig.patientInteractCoords,
            size     = MRIConfig.patientInteractSize,
            rotation = MRIConfig.bedHeading,
            debug    = false,
            options  = {
                {
                    name     = 'mri_patient_liedown',
                    icon     = 'fas fa-bed',
                    label    = MRIConfig.messages.patientPrompt,
                    onSelect = function()
                        patientLieDown()
                    end,
                },
            },
        })

        -- ── ox_target: operator desk zone ──────
        exports.ox_target:addBoxZone({
            coords   = MRIConfig.operatorInteractCoords,
            size     = MRIConfig.operatorInteractSize,
            rotation = MRIConfig.operatorInteractHeading or MRIConfig.bedHeading,
            debug    = false,
            options  = {
                {
                    name     = 'mri_operator_controls',
                    icon     = 'fas fa-desktop',
                    label    = MRIConfig.messages.operatorPrompt,
                    onSelect = function()
                        openOperatorMenu()
                    end,
                },
            },
        })
    else
        -- ── textUI + lib.zones ───────────────────────
        local patientUIShown  = false
        local operatorUIShown = false

        lib.zones.box({
            coords   = MRIConfig.patientInteractCoords,
            size     = MRIConfig.patientInteractSize,
            rotation = MRIConfig.bedHeading,

            onEnter = function()
                if not isPatient then
                    lib.showTextUI('[E] ' .. MRIConfig.messages.patientPrompt)
                    patientUIShown = true
                end
            end,
            onExit = function()
                if patientUIShown then
                    lib.hideTextUI()
                    patientUIShown = false
                end
            end,
            inside = function()
                if not isPatient and IsControlJustPressed(0, 38) then
                    if patientUIShown then
                        lib.hideTextUI()
                        patientUIShown = false
                    end
                    patientLieDown()
                end
            end,
        })

        lib.zones.box({
            coords   = MRIConfig.operatorInteractCoords,
            size     = MRIConfig.operatorInteractSize,
            rotation = MRIConfig.operatorInteractHeading or MRIConfig.bedHeading,

            onEnter = function()
                lib.showTextUI('[E] ' .. MRIConfig.messages.operatorPrompt)
                operatorUIShown = true
            end,
            onExit = function()
                if operatorUIShown then
                    lib.hideTextUI()
                    operatorUIShown = false
                end
            end,
            inside = function()
                if IsControlJustPressed(0, 38) then
                    openOperatorMenu()
                end
            end,
        })
    end
end

setupMRIInteractions()

-- ============================================================
-- Cleanup on resource stop
-- ============================================================
AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    -- Stop scan light
    scanLightActive = false

    -- Detach the player if they're on the bed
    detachPatient()

    -- Restore static bed visibility
    if hiddenBedPoint then
        hiddenBedPoint:onExit(hiddenBedPoint)
        hiddenBedPoint:remove()
        hiddenBedPoint = nil
    end
end)
