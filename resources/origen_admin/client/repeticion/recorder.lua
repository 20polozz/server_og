RepRecorder = {
    active = false,
    buffer = nil,
    events = nil,
    startedAt = 0,
}

local GetGameTimer = GetGameTimer
local GetEntityCoords = GetEntityCoords
local GetEntityHeading = GetEntityHeading
local GetEntityModel = GetEntityModel
local GetEntityHealth = GetEntityHealth
local GetEntitySpeed = GetEntitySpeed
local GetEntityRotation = GetEntityRotation
local GetPedArmour = GetPedArmour
local GetSelectedPedWeapon = GetSelectedPedWeapon
local GetVehiclePedIsIn = GetVehiclePedIsIn
local GetPedInVehicleSeat = GetPedInVehicleSeat
local GetVehicleMaxNumberOfPassengers = GetVehicleMaxNumberOfPassengers
local GetVehicleNumberPlateText = GetVehicleNumberPlateText
local GetPedLastWeaponImpactCoord = GetPedLastWeaponImpactCoord
local GetCurrentPedWeaponEntityIndex = GetCurrentPedWeaponEntityIndex
local GetEntityBoneIndexByName = GetEntityBoneIndexByName
local GetWorldPositionOfEntityBone = GetWorldPositionOfEntityBone
local GetPedBoneCoords = GetPedBoneCoords
local GetActivePlayers = GetActivePlayers
local GetPlayerPed = GetPlayerPed
local GetPlayerServerId = GetPlayerServerId
local GetPlayerName = GetPlayerName
local NetworkGetPlayerIndexFromPed = NetworkGetPlayerIndexFromPed
local NetworkIsPlayerActive = NetworkIsPlayerActive
local IsPedShooting = IsPedShooting
local IsPedReloading = IsPedReloading
local IsPedRagdoll = IsPedRagdoll
local IsPedInCover = IsPedInCover
local IsPedInMeleeCombat = IsPedInMeleeCombat
local IsPedJumping = IsPedJumping
local IsPedFalling = IsPedFalling
local IsPedClimbing = IsPedClimbing
local IsPedDeadOrDying = IsPedDeadOrDying
local IsPedArmed = IsPedArmed
local IsPedAPlayer = IsPedAPlayer
local IsEntityAPed = IsEntityAPed
local IsPlayerFreeAiming = IsPlayerFreeAiming
local DoesEntityExist = DoesEntityExist
local GetGamePool = GetGamePool

local UNARMED = `WEAPON_UNARMED`
local FLAGS = RepUtils.FLAGS

local pedToActor = {}
local seatCache = {}
local seenActors = {}
local pedScratch = {}

local function actorIdFor(ped)
    local player = NetworkGetPlayerIndexFromPed(ped)

    if player and player ~= -1 and NetworkIsPlayerActive(player) then
        return ('p%d'):format(GetPlayerServerId(player)), GetPlayerName(player), player
    end

    return ('e%d'):format(ped), nil, nil
end

local function aimRayFor(ped, weapon)
    if weapon == UNARMED then return nil end

    local weaponObject = GetCurrentPedWeaponEntityIndex(ped)

    if weaponObject and weaponObject ~= 0 and DoesEntityExist(weaponObject) then
        local muzzleBone = GetEntityBoneIndexByName(weaponObject, 'gun_muzzle')

        if muzzleBone ~= -1 then
            local muzzle = GetWorldPositionOfEntityBone(weaponObject, muzzleBone)
            local root = GetEntityCoords(weaponObject)
            local direction = muzzle - root

            if #direction > 0.02 then
                return muzzle + (direction / #direction) * RepCfg.aimRayLength, muzzle
            end
        end
    end

    local head = GetPedBoneCoords(ped, 31086, 0.0, 0.0, 0.0)
    local heading = math.rad(GetEntityHeading(ped))

    return head + vector3(-math.sin(heading), math.cos(heading), 0.0) * RepCfg.aimRayLength, head
end

local function seatOf(ped, vehicle)
    local cached = seatCache[ped]

    if cached and cached.vehicle == vehicle then
        return cached.seat
    end

    local seat = -2

    for index = -1, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
        if GetPedInVehicleSeat(vehicle, index) == ped then
            seat = index
            break
        end
    end

    if not cached then
        cached = {}
        seatCache[ped] = cached
    end

    cached.vehicle = vehicle
    cached.seat = seat

    return seat
end

local function fillVehicle(actor, vehicle)
    local target = actor.vehicle

    if not target then
        target = {}
        actor.vehicle = target
    end

    local coords = GetEntityCoords(vehicle)
    local rotation = GetEntityRotation(vehicle, 2)

    target.model = GetEntityModel(vehicle)
    target.x, target.y, target.z = coords.x, coords.y, coords.z
    target.rx, target.ry, target.rz = rotation.x, rotation.y, rotation.z
    target.speed = GetEntitySpeed(vehicle)
    target.plate = GetVehicleNumberPlateText(vehicle)
end

local function fillActor(actor, ped, player)
    local coords = GetEntityCoords(ped)
    local weapon = GetSelectedPedWeapon(ped)
    local shooting = IsPedShooting(ped)
    local aiming = shooting or (player and IsPlayerFreeAiming(player)) or (IsPedInCover(ped, false) and IsPedArmed(ped, 6))
    local flags = 0

    if IsPedDeadOrDying(ped, true) then flags = flags | FLAGS.dead end
    if IsPedRagdoll(ped) then flags = flags | FLAGS.ragdoll end
    if shooting then flags = flags | FLAGS.shooting end
    if aiming then flags = flags | FLAGS.aiming end
    if IsPedReloading(ped) then flags = flags | FLAGS.reloading end
    if IsPedInMeleeCombat(ped) then flags = flags | FLAGS.melee end
    if IsPedInCover(ped, false) then flags = flags | FLAGS.cover end
    if IsPedJumping(ped) or IsPedFalling(ped) or IsPedClimbing(ped) then flags = flags | FLAGS.jumping end

    actor.model = GetEntityModel(ped)
    actor.x, actor.y, actor.z = coords.x, coords.y, coords.z
    actor.h = GetEntityHeading(ped)
    actor.speed = GetEntitySpeed(ped)
    actor.health = GetEntityHealth(ped)
    actor.armour = GetPedArmour(ped)
    actor.weapon = weapon
    actor.ax, actor.ay, actor.az = nil, nil, nil
    actor.mx, actor.my, actor.mz = nil, nil, nil
    actor.ix, actor.iy, actor.iz = nil, nil, nil

    if aiming then
        local aimAt, muzzle = aimRayFor(ped, weapon)

        if aimAt then
            actor.ax, actor.ay, actor.az = aimAt.x, aimAt.y, aimAt.z
            actor.mx, actor.my, actor.mz = muzzle.x, muzzle.y, muzzle.z
        end
    end

    if shooting then
        local hit, impact = GetPedLastWeaponImpactCoord(ped)

        if hit then
            actor.ix, actor.iy, actor.iz = impact.x, impact.y, impact.z
        end
    end

    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle ~= 0 then
        fillVehicle(actor, vehicle)
        actor.seat = seatOf(ped, vehicle)

        if aiming then flags = flags | FLAGS.driveby end
    else
        actor.vehicle = nil
        actor.seat = nil
    end

    actor.f = flags
end

local function collectPeds()
    local count = 0

    for _, player in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(player)

        if ped ~= 0 and DoesEntityExist(ped) then
            count = count + 1
            pedScratch[count] = ped
        end
    end

    local playerCount = count

    if RepCfg.recordNpcs then
        for _, ped in ipairs(GetGamePool('CPed')) do
            if not IsPedAPlayer(ped) and DoesEntityExist(ped) then
                count = count + 1
                pedScratch[count] = ped
            end
        end
    end

    for i = count + 1, #pedScratch do
        pedScratch[i] = nil
    end

    return count, playerCount
end

local function captureInto(frame)
    local origin = GetEntityCoords(cache.ped)
    local playerRadiusSq = RepCfg.captureRadius * RepCfg.captureRadius
    local npcRadiusSq = RepCfg.npcRadius * RepCfg.npcRadius
    local actors = frame.actors

    frame.t = GetGameTimer() - RepRecorder.startedAt

    table.wipe(seenActors)
    table.wipe(pedToActor)

    local count, playerCount = collectPeds()

    for i = 1, count do
        local ped = pedScratch[i]
        local coords = GetEntityCoords(ped)
        local dx, dy, dz = coords.x - origin.x, coords.y - origin.y, coords.z - origin.z

        if dx * dx + dy * dy + dz * dz <= (i <= playerCount and playerRadiusSq or npcRadiusSq) then
            local id, name, player = actorIdFor(ped)
            local actor = actors[id]

            if not actor then
                actor = {}
                actors[id] = actor
            end

            fillActor(actor, ped, player)
            actor.name = name
            seenActors[id] = true
            pedToActor[ped] = id
        end
    end

    for id in pairs(actors) do
        if not seenActors[id] then
            actors[id] = nil
        end
    end
end

local function resolveEventActor(entity)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return nil, nil end

    local cached = pedToActor[entity]

    if cached then return cached, nil end

    if not IsEntityAPed(entity) then
        return ('v%d'):format(entity), GetDisplayNameFromVehicleModel(GetEntityModel(entity))
    end

    return actorIdFor(entity)
end

AddEventHandler('gameEventTriggered', function(name, args)
    if not RepRecorder.active or name ~= 'CEventNetworkEntityDamage' then return end

    local victim, attacker = args[1], args[2]

    if not victim or not DoesEntityExist(victim) or not IsEntityAPed(victim) then return end
    if not IsPedAPlayer(victim) and not RepCfg.recordNpcs then return end

    local victimId, victimName = resolveEventActor(victim)

    if not victimId then return end

    local attackerId, attackerName = resolveEventActor(attacker)
    local coords = GetEntityCoords(victim)
    local slot = RepRecorder.events:recyclableSlot() or {}

    slot.t = GetGameTimer() - RepRecorder.startedAt
    slot.victim = victimId
    slot.victimName = victimName
    slot.attacker = attackerId
    slot.attackerName = attackerName
    slot.weapon = args[7] or 0
    slot.fatal = args[6] == 1 or IsPedDeadOrDying(victim, true)
    slot.health = GetEntityHealth(victim)
    slot.x, slot.y, slot.z = coords.x, coords.y, coords.z

    RepRecorder.events:push(slot)
end)

function RepRecorder.start()
    if RepRecorder.active then return false end

    RepRecorder.buffer = RepRecorder.buffer or RepUtils.createRingBuffer(RepCfg.maxFrames)
    RepRecorder.events = RepRecorder.events or RepUtils.createRingBuffer(RepCfg.maxEvents)
    RepRecorder.buffer:clear()
    RepRecorder.events:clear()

    table.wipe(seatCache)

    RepRecorder.startedAt = GetGameTimer()
    RepRecorder.active = true
    RepRecorder.paused = false

    CreateThread(function()
        local interval = math.floor(1000 / RepCfg.captureRate)

        while RepRecorder.active do
            if RepRecorder.paused then
                Wait(250)
            else
                local frame = RepRecorder.buffer:recyclableSlot()

                if not frame then
                    frame = { t = 0, actors = {} }
                end

                captureInto(frame)
                RepRecorder.buffer:push(frame)

                Wait(interval)
            end
        end
    end)

    return true
end

function RepRecorder.stop()
    if not RepRecorder.active then return false end

    RepRecorder.active = false
    return true
end

function RepRecorder.getStats()
    local buffer = RepRecorder.buffer

    if not buffer or buffer.count == 0 then
        return { frames = 0, duration = 0, actors = 0, events = 0 }
    end

    local first = buffer:get(1)
    local last = buffer:get(buffer.count)
    local actors = 0

    for _ in pairs(last.actors) do
        actors = actors + 1
    end

    return {
        frames = buffer.count,
        duration = last.t - first.t,
        actors = actors,
        events = RepRecorder.events and RepRecorder.events.count or 0,
    }
end

function RepRecorder.buildClip(seconds)
    local buffer = RepRecorder.buffer

    if not buffer or buffer.count < 2 then return nil end

    local last = buffer:get(buffer.count)
    local cutoff = seconds and (last.t - seconds * 1000) or -1
    local first, firstIndex

    for i = 1, buffer.count do
        local frame = buffer:get(i)

        if frame.t >= cutoff then
            first, firstIndex = frame, i
            break
        end
    end

    if not first or buffer.count - firstIndex < 1 then return nil end

    local offset = first.t
    local clip = { frames = {}, events = {}, duration = last.t - offset }

    for i = firstIndex, buffer.count do
        local frame = buffer:get(i)
        clip.frames[#clip.frames + 1] = { t = frame.t - offset, actors = frame.actors }
    end

    if RepRecorder.events then
        for i = 1, RepRecorder.events.count do
            local event = RepRecorder.events:get(i)

            if event.t >= offset and event.t <= last.t then
                local copy = {}

                for key, value in pairs(event) do
                    copy[key] = value
                end

                copy.t = event.t - offset
                clip.events[#clip.events + 1] = copy
            end
        end
    end

    return clip
end
