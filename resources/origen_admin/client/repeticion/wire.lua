RepWire = {}

local VERSION = 1

local CORE_STRIDE = 8
local COMBAT_STRIDE = 10
local VEHICLE_STRIDE = 9
local WEAPON_STRIDE = 2

local POS_SCALE = 100
local ANGLE_SCALE = 10
local SPEED_SCALE = 100

local floor = math.floor

local function toFixed(value, scale)
    if not value then return 0 end

    return floor(value * scale + 0.5)
end

local function fromFixed(value, scale)
    return value / scale
end

local function indexOf(list, value)
    for i = 1, #list do
        if list[i] == value then return i end
    end

    list[#list + 1] = value
    return #list
end

function RepWire.pack(seconds)
    local buffer = RepRecorder.buffer

    if not buffer or buffer.count < 2 then return nil end

    local last = buffer:get(buffer.count)
    local cutoff = last.t - seconds * 1000
    local step = math.max(1, floor(RepCfg.captureRate / RepCfg.transmitRate))

    local origin, times = nil, {}
    local tracks, byId = {}, {}
    local frameCount = 0

    for i = 1, buffer.count, step do
        local frame = buffer:get(i)

        if frame.t >= cutoff then
            if not origin then origin = frame.t end

            frameCount = frameCount + 1
            times[frameCount] = frame.t - origin

            for id, actor in pairs(frame.actors) do
                local track = byId[id]

                if not track then
                    track = {
                        id = id,
                        name = actor.name or false,
                        model = actor.model,
                        fr = {},
                        d = {},
                        c = {},
                        v = {},
                        w = {},
                        vm = {},
                    }

                    byId[id] = track
                    tracks[#tracks + 1] = track
                end

                local n = #track.fr + 1
                track.fr[n] = frameCount

                local base = (n - 1) * CORE_STRIDE
                local d = track.d

                d[base + 1] = toFixed(actor.x, POS_SCALE)
                d[base + 2] = toFixed(actor.y, POS_SCALE)
                d[base + 3] = toFixed(actor.z, POS_SCALE)
                d[base + 4] = toFixed(actor.h, ANGLE_SCALE)
                d[base + 5] = toFixed(actor.speed, SPEED_SCALE)
                d[base + 6] = actor.health or 0
                d[base + 7] = actor.armour or 0
                d[base + 8] = actor.f or 0

                if track.lastWeapon ~= actor.weapon then
                    track.lastWeapon = actor.weapon
                    local wn = #track.w
                    track.w[wn + 1] = frameCount
                    track.w[wn + 2] = actor.weapon or 0
                end

                if actor.ax then
                    local cn = #track.c
                    track.c[cn + 1] = frameCount
                    track.c[cn + 2] = toFixed(actor.ax, POS_SCALE)
                    track.c[cn + 3] = toFixed(actor.ay, POS_SCALE)
                    track.c[cn + 4] = toFixed(actor.az, POS_SCALE)
                    track.c[cn + 5] = toFixed(actor.mx, POS_SCALE)
                    track.c[cn + 6] = toFixed(actor.my, POS_SCALE)
                    track.c[cn + 7] = toFixed(actor.mz, POS_SCALE)
                    track.c[cn + 8] = toFixed(actor.ix, POS_SCALE)
                    track.c[cn + 9] = toFixed(actor.iy, POS_SCALE)
                    track.c[cn + 10] = toFixed(actor.iz, POS_SCALE)
                end

                local vehicle = actor.vehicle

                if vehicle then
                    local vn = #track.v
                    track.v[vn + 1] = frameCount
                    track.v[vn + 2] = indexOf(track.vm, vehicle.model)
                    track.v[vn + 3] = toFixed(vehicle.x, POS_SCALE)
                    track.v[vn + 4] = toFixed(vehicle.y, POS_SCALE)
                    track.v[vn + 5] = toFixed(vehicle.z, POS_SCALE)
                    track.v[vn + 6] = toFixed(vehicle.rx, ANGLE_SCALE)
                    track.v[vn + 7] = toFixed(vehicle.ry, ANGLE_SCALE)
                    track.v[vn + 8] = toFixed(vehicle.rz, ANGLE_SCALE)
                    track.v[vn + 9] = toFixed(vehicle.speed, SPEED_SCALE)
                end
            end
        end
    end

    if frameCount < 2 then return nil end

    for i = 1, #tracks do
        tracks[i].lastWeapon = nil
    end

    local events = {}

    if RepRecorder.events then
        for i = 1, RepRecorder.events.count do
            local event = RepRecorder.events:get(i)

            if event.t >= origin and event.t <= last.t then
                events[#events + 1] = {
                    t = event.t - origin,
                    victim = event.victim,
                    victimName = event.victimName or false,
                    attacker = event.attacker or false,
                    attackerName = event.attackerName or false,
                    weapon = event.weapon or 0,
                    fatal = event.fatal and 1 or 0,
                    health = event.health or 0,
                    x = toFixed(event.x, POS_SCALE),
                    y = toFixed(event.y, POS_SCALE),
                    z = toFixed(event.z, POS_SCALE),
                }
            end
        end
    end

    return {
        v = VERSION,
        n = frameCount,
        t = times,
        duration = times[frameCount],
        tracks = tracks,
        events = events,
    }
end

function RepWire.unpack(payload)
    if type(payload) ~= 'table' or payload.v ~= VERSION or not payload.tracks then return nil end

    local frames = {}

    for i = 1, payload.n do
        frames[i] = { t = payload.t[i], actors = {} }
    end

    for _, track in ipairs(payload.tracks) do
        local combat = {}
        local vehicles = {}
        local weapon, weaponIndex = 0, 1

        for i = 1, #track.c, COMBAT_STRIDE do
            combat[track.c[i]] = i
        end

        for i = 1, #track.v, VEHICLE_STRIDE do
            vehicles[track.v[i]] = i
        end

        for n = 1, #track.fr do
            local frameIndex = track.fr[n]
            local base = (n - 1) * CORE_STRIDE
            local d = track.d

            while track.w[weaponIndex] and track.w[weaponIndex] <= frameIndex do
                weapon = track.w[weaponIndex + 1]
                weaponIndex = weaponIndex + WEAPON_STRIDE
            end

            local actor = {
                model = track.model,
                name = track.name or nil,
                x = fromFixed(d[base + 1], POS_SCALE),
                y = fromFixed(d[base + 2], POS_SCALE),
                z = fromFixed(d[base + 3], POS_SCALE),
                h = fromFixed(d[base + 4], ANGLE_SCALE),
                speed = fromFixed(d[base + 5], SPEED_SCALE),
                health = d[base + 6],
                armour = d[base + 7],
                f = d[base + 8],
                weapon = weapon,
            }

            local c = combat[frameIndex]

            if c then
                actor.ax = fromFixed(track.c[c + 1], POS_SCALE)
                actor.ay = fromFixed(track.c[c + 2], POS_SCALE)
                actor.az = fromFixed(track.c[c + 3], POS_SCALE)
                actor.mx = fromFixed(track.c[c + 4], POS_SCALE)
                actor.my = fromFixed(track.c[c + 5], POS_SCALE)
                actor.mz = fromFixed(track.c[c + 6], POS_SCALE)

                if track.c[c + 7] ~= 0 or track.c[c + 8] ~= 0 then
                    actor.ix = fromFixed(track.c[c + 7], POS_SCALE)
                    actor.iy = fromFixed(track.c[c + 8], POS_SCALE)
                    actor.iz = fromFixed(track.c[c + 9], POS_SCALE)
                end
            end

            local v = vehicles[frameIndex]

            if v then
                actor.vehicle = {
                    model = track.vm[track.v[v + 1]],
                    x = fromFixed(track.v[v + 2], POS_SCALE),
                    y = fromFixed(track.v[v + 3], POS_SCALE),
                    z = fromFixed(track.v[v + 4], POS_SCALE),
                    rx = fromFixed(track.v[v + 5], ANGLE_SCALE),
                    ry = fromFixed(track.v[v + 6], ANGLE_SCALE),
                    rz = fromFixed(track.v[v + 7], ANGLE_SCALE),
                    speed = fromFixed(track.v[v + 8], SPEED_SCALE),
                }
                actor.seat = -1
            end

            frames[frameIndex].actors[track.id] = actor
        end
    end

    local events = {}

    for _, event in ipairs(payload.events or {}) do
        events[#events + 1] = {
            t = event.t,
            victim = event.victim,
            victimName = event.victimName or nil,
            attacker = event.attacker or nil,
            attackerName = event.attackerName or nil,
            weapon = event.weapon,
            fatal = event.fatal == 1,
            health = event.health,
            x = fromFixed(event.x, POS_SCALE),
            y = fromFixed(event.y, POS_SCALE),
            z = fromFixed(event.z, POS_SCALE),
        }
    end

    return { frames = frames, events = events, duration = payload.duration }
end

function RepWire.measure(payload)
    local values = 0

    for _, track in ipairs(payload.tracks) do
        values = values + #track.fr + #track.d + #track.c + #track.v + #track.w
    end

    return values + payload.n
end
