RepActors = {
    peds = {},
    vehicles = {},
}

local UNARMED = `WEAPON_UNARMED`
local FIRING_PATTERN = `FIRING_PATTERN_FULL_AUTO`
local FLAGS = RepUtils.FLAGS

local SetPedShootsAtCoord = SetPedShootsAtCoord
local SetPedDesiredMoveBlendRatio = SetPedDesiredMoveBlendRatio
local SetEntityCoordsNoOffset = SetEntityCoordsNoOffset
local SetEntityHeading = SetEntityHeading
local SetEntityVisible = SetEntityVisible
local GetEntityHeading = GetEntityHeading
local GetGameTimer = GetGameTimer
local DoesEntityExist = DoesEntityExist
local IsPedRagdoll = IsPedRagdoll

local SAFETY_REFRESH = 4000
local AHEAD_DISTANCE = 60.0
local TRAVEL_ANGLE_THRESHOLD = 22.0
local AIM_ANGLE_THRESHOLD = 7.0
local MOVE_HYSTERESIS = 0.45
local HEADING_DEADZONE = 2.0
local SHOOT_LATCH = 260
local AIM_LATCH = 450

local MOVE_TIERS = {
    { name = 'idle', min = 0.0, ratio = 0.0, speed = 0.0 },
    { name = 'walk', min = 0.7, ratio = 1.0, speed = 1.0 },
    { name = 'run', min = 2.4, ratio = 2.0, speed = 2.0 },
    { name = 'sprint', min = 5.2, ratio = 3.0, speed = 3.0 },
}

local function loadModel(model)
    if not IsModelInCdimage(model) then return false end

    lib.requestModel(model, 10000)
    return HasModelLoaded(model)
end

local function spawnPed(model)
    if not loadModel(model) then
        model = `mp_m_freemode_01`

        if not loadModel(model) then return nil end
    end

    local ped = CreatePed(4, model, 0.0, 0.0, 0.0, 0.0, false, false)

    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdoll(ped, true)
    SetEntityCollision(ped, false, false)
    SetPedCanBeTargetted(ped, false)
    SetPedSuffersCriticalHits(ped, false)
    SetPedDiesWhenInjured(ped, false)
    SetPedCanSwitchWeapon(ped, false)
    SetPedAccuracy(ped, 100)
    SetPedSeeingRange(ped, 0.0)
    SetPedHearingRange(ped, 0.0)
    SetPedConfigFlag(ped, 185, true)
    SetPedConfigFlag(ped, 108, true)
    SetEntityAlpha(ped, 255, false)
    SetModelAsNoLongerNeeded(model)

    return ped
end

local function spawnVehicle(model)
    if not loadModel(model) then return nil end

    local vehicle = CreateVehicle(model, 0.0, 0.0, 0.0, 0.0, false, false)

    SetEntityInvincible(vehicle, true)
    SetEntityCollision(vehicle, false, false)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleDoorsLocked(vehicle, 4)
    SetModelAsNoLongerNeeded(model)

    return vehicle
end

local function aimCoords(data)
    if data.ax then
        return vector3(data.ax, data.ay, data.az)
    end

    local heading = math.rad(data.h)
    return vector3(data.x, data.y, data.z + 0.6) + vector3(-math.sin(heading), math.cos(heading), 0.0) * RepCfg.aimRayLength
end

local function moveTier(entry, data)
    local speed = data.speed or 0.0
    local index = 1

    for i = #MOVE_TIERS, 1, -1 do
        if speed >= MOVE_TIERS[i].min then
            index = i
            break
        end
    end

    local current = entry.moveIndex or 1

    if index < current and speed > MOVE_TIERS[current].min - MOVE_HYSTERESIS then
        index = current
    end

    entry.moveIndex = index
    return MOVE_TIERS[index]
end

local function travelDirection(data, nextData)
    local target = nextData or data
    local direction = vector3(target.x - data.x, target.y - data.y, 0.0)

    if #direction < 0.01 then
        local heading = math.rad(data.h)
        return vector3(-math.sin(heading), math.cos(heading), 0.0)
    end

    return direction / #direction
end

local function angleBetween(a, b)
    if not a or not b then return 180.0 end

    local dot = math.max(-1.0, math.min(1.0, a.x * b.x + a.y * b.y + a.z * b.z))
    return math.deg(math.acos(dot))
end

local function aimDirection(data, aimAt)
    local direction = aimAt - vector3(data.x, data.y, data.z + 0.6)

    if #direction < 0.01 then return nil end

    return direction / #direction
end

local function applyBehaviour(entry, ped, data, nextData)
    local now = GetGameTimer()
    local tier = moveTier(entry, data)
    local flags = data.f or 0

    if flags & FLAGS.shooting ~= 0 then entry.shotAt = now end
    if flags & FLAGS.aiming ~= 0 then entry.aimedAt = now end

    local shooting = flags & FLAGS.shooting ~= 0 or (entry.shotAt and now - entry.shotAt < SHOOT_LATCH)
    local aim = shooting or flags & FLAGS.aiming ~= 0 or (entry.aimedAt and now - entry.aimedAt < AIM_LATCH)
    local state

    if flags & FLAGS.dead ~= 0 then
        state = 'dead'
    elseif flags & FLAGS.ragdoll ~= 0 then
        state = 'ragdoll'
    elseif flags & FLAGS.reloading ~= 0 then
        state = 'reload'
    elseif aim then
        state = tier.name == 'idle' and 'aim' or 'aimmove'
    elseif flags & FLAGS.melee ~= 0 then
        state = 'melee'
    else
        state = tier.name
    end

    local aimAt = aim and aimCoords(data) or nil
    local aimDir = aimAt and aimDirection(data, aimAt) or nil
    local travelDir = travelDirection(data, nextData)

    if shooting and aimAt then
        SetPedShootsAtCoord(ped, aimAt.x, aimAt.y, aimAt.z, true)
    end

    if state ~= 'idle' and state ~= 'aim' and state ~= 'dead' and state ~= 'ragdoll' then
        SetPedDesiredMoveBlendRatio(ped, tier.ratio)
    end

    local reissue = entry.state ~= state or now - entry.taskAt >= SAFETY_REFRESH

    if not reissue and (state == 'aim' or state == 'aimmove') then
        reissue = angleBetween(aimDir, entry.aimDir) > AIM_ANGLE_THRESHOLD
    end

    if not reissue and (state == 'aimmove' or state == 'walk' or state == 'run' or state == 'sprint') then
        reissue = angleBetween(travelDir, entry.travelDir) > TRAVEL_ANGLE_THRESHOLD
    end

    if not reissue then return end

    local previous = entry.state

    entry.state = state
    entry.taskAt = now
    entry.aimDir = aimDir
    entry.travelDir = travelDir

    if state == 'dead' then
        if not entry.killed then
            entry.killed = true
            ClearPedTasksImmediately(ped)
            SetEntityHealth(ped, 0)
        end

        return
    end

    if entry.killed then
        entry.killed = false
        SetEntityHealth(ped, GetEntityMaxHealth(ped))
        ClearPedTasksImmediately(ped)
    end

    if state == 'ragdoll' then
        if not IsPedRagdoll(ped) then
            SetPedToRagdoll(ped, 4000, 4000, 0, true, true, false)
        end

        return
    end

    if previous == 'ragdoll' and IsPedRagdoll(ped) then
        ClearPedTasksImmediately(ped)
    end

    local ahead = vector3(data.x, data.y, data.z) + travelDir * AHEAD_DISTANCE

    if state == 'reload' then
        TaskReloadWeapon(ped, true)
    elseif state == 'aim' then
        TaskAimGunAtCoord(ped, aimAt.x, aimAt.y, aimAt.z, -1, false, false)
    elseif state == 'aimmove' then
        TaskGoToCoordWhileAimingAtCoord(ped, ahead.x, ahead.y, ahead.z, aimAt.x, aimAt.y, aimAt.z, tier.speed, false, 2.0, 3.0, true, 0, false, FIRING_PATTERN)
    elseif state == 'melee' then
        TaskPlayAnim(ped, 'melee@unarmed@streamed_core', 'heavy_punch_a', 8.0, -8.0, -1, 0, 0.0, false, false, false)
    elseif state == 'idle' then
        TaskStandStill(ped, -1)
    else
        TaskGoStraightToCoord(ped, ahead.x, ahead.y, ahead.z, tier.speed, -1, data.h, 0.0)
    end
end

local function applyWeapon(entry, ped, data)
    local weapon = data.weapon or UNARMED

    if entry.weapon == weapon then return end

    entry.weapon = weapon
    RemoveAllPedWeapons(ped, true)

    if weapon ~= UNARMED then
        GiveWeaponToPed(ped, weapon, 250, false, true)
        SetCurrentPedWeapon(ped, weapon, true)
        SetPedInfiniteAmmo(ped, true, weapon)
        SetPedInfiniteAmmoClip(ped, true)
    end
end

local function ensureEntry(id, data)
    local entry = RepActors.peds[id]

    if entry and entry.model ~= data.model then
        DeletePed(entry.ped)
        RepActors.peds[id] = nil
        entry = nil
    end

    if not entry then
        local ped = spawnPed(data.model)

        if not ped then return nil end

        entry = { ped = ped, model = data.model, taskAt = 0 }
        RepActors.peds[id] = entry
    end

    if not DoesEntityExist(entry.ped) then
        RepActors.peds[id] = nil
        return nil
    end

    return entry
end

local function applyVehicle(id, entry, ped, data)
    local vehEntry = RepActors.vehicles[id]

    if vehEntry and vehEntry.model ~= data.vehicle.model then
        if DoesEntityExist(vehEntry.vehicle) then
            DeleteVehicle(vehEntry.vehicle)
        end

        RepActors.vehicles[id] = nil
        vehEntry = nil
    end

    if not vehEntry then
        local vehicle = spawnVehicle(data.vehicle.model)

        if not vehicle then return false end

        vehEntry = { vehicle = vehicle, model = data.vehicle.model, seated = false }
        RepActors.vehicles[id] = vehEntry
    end

    local vehicle = vehEntry.vehicle

    SetEntityCoordsNoOffset(vehicle, data.vehicle.x, data.vehicle.y, data.vehicle.z, false, false, false)
    SetEntityRotation(vehicle, data.vehicle.rx, data.vehicle.ry, data.vehicle.rz, 2, true)
    SetVehicleForwardSpeed(vehicle, data.vehicle.speed)

    if not vehEntry.seated or GetVehiclePedIsIn(ped, false) ~= vehicle then
        SetPedIntoVehicle(ped, vehicle, data.seat or -1)
        vehEntry.seated = true
        entry.state = nil
    end

    local flags = data.f or 0

    if flags & FLAGS.driveby ~= 0 then
        local aimAt = aimCoords(data)
        local aimDir = aimDirection(data, aimAt)
        local now = GetGameTimer()

        if entry.state ~= 'driveby'
            or angleBetween(aimDir, entry.aimDir) > AIM_ANGLE_THRESHOLD
            or now - entry.taskAt >= SAFETY_REFRESH
        then
            entry.state = 'driveby'
            entry.taskAt = now
            entry.aimDir = aimDir
            TaskDriveBy(ped, 0, 0, aimAt.x, aimAt.y, aimAt.z, 100.0, 0, flags & FLAGS.shooting ~= 0, FIRING_PATTERN)
        end
    elseif entry.state == 'driveby' then
        entry.state = 'seated'
        ClearPedTasks(ped)
    end

    SetEntityVisible(ped, true, false)
    return true
end

function RepActors.apply(id, data, nextData)
    local entry = ensureEntry(id, data)

    if not entry then return end

    local ped = entry.ped

    applyWeapon(entry, ped, data)

    if data.vehicle then
        if applyVehicle(id, entry, ped, data) then return end
    elseif RepActors.vehicles[id] then
        local vehEntry = RepActors.vehicles[id]

        if DoesEntityExist(vehEntry.vehicle) then
            DeleteVehicle(vehEntry.vehicle)
        end

        RepActors.vehicles[id] = nil
        entry.state = nil
    end

    applyBehaviour(entry, ped, data, nextData)

    SetEntityCoordsNoOffset(ped, data.x, data.y, data.z, false, false, false)

    if (data.f or 0) & (FLAGS.ragdoll | FLAGS.dead) == 0 then
        local delta = math.abs((GetEntityHeading(ped) - data.h + 180.0) % 360.0 - 180.0)

        if delta > HEADING_DEADZONE then
            SetEntityHeading(ped, data.h)
        end
    end

    SetEntityVisible(ped, true, false)
end

function RepActors.hide(id)
    local entry = RepActors.peds[id]

    if entry and DoesEntityExist(entry.ped) then
        SetEntityVisible(entry.ped, false, false)
    end

    local vehEntry = RepActors.vehicles[id]

    if vehEntry and DoesEntityExist(vehEntry.vehicle) then
        SetEntityVisible(vehEntry.vehicle, false, false)
    end
end

function RepActors.getPed(id)
    local entry = RepActors.peds[id]
    return entry and DoesEntityExist(entry.ped) and entry.ped or nil
end

function RepActors.clear()
    for id, entry in pairs(RepActors.peds) do
        if DoesEntityExist(entry.ped) then
            DeletePed(entry.ped)
        end

        RepActors.peds[id] = nil
    end

    for id, entry in pairs(RepActors.vehicles) do
        if DoesEntityExist(entry.vehicle) then
            DeleteVehicle(entry.vehicle)
        end

        RepActors.vehicles[id] = nil
    end
end
