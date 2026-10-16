-- ============================================================
-- ProximityTracker — Client-side proximity detection
--
-- Keeps a lightweight list of parked vehicle positions
-- (just id + coords, received from the server once).
-- Every 1.5 s checks the player's local position against
-- the list using pure Lua arithmetic — zero native calls,
-- zero network traffic unless the set of nearby vehicles changes.
--
-- Only sends ONE event per transition:
--   Entered proximity  → orp:nearVehicles   (ids list)
--   Left proximity     → orp:farFromVehicles (ids list)
--
-- This means: if 30 players stand still for 1 minute,
-- ZERO events are sent to the server.
-- ============================================================

local _positions     = {}    -- [id] = { x, y, z }  (all known parked vehicles)
local _near          = {}    -- [id] = true  (currently within SpawnRadius)
local _vehicleNetId  = {}    -- [vehicleId] = netID  (populated from applyMods)
local _moveLastCheck = {}    -- [vehicleId] = GetGameTimer() of last position report

-- ── Receive initial position list from server ────────────────

RegisterNetEvent('orp:client:initPositions', function(payload)
    _positions = {}
    _near      = {}
    for _, entry in ipairs(payload) do
        _positions[entry.id] = { x = entry.x, y = entry.y, z = entry.z }
    end
    -- Skip the next Wait(500) so proximity is evaluated immediately.
    -- Without this the player would wait up to 500 ms before the first
    -- nearVehicles fires after joining or after a resource restart.
    _immediateCheck = true
    dbg('Tracker: received', #payload, 'positions')
end)

--- Server added a newly parked vehicle.
RegisterNetEvent('orp:client:addPosition', function(entry)
    _positions[entry.id] = { x = entry.x, y = entry.y, z = entry.z }
    -- Reset proximity state so the tracker re-evaluates on the next tick.
    -- This is critical when a vehicle is re-parked while a player is already
    -- within SpawnRadius: without this reset the client never re-sends
    -- nearVehicles and the server (with an empty Watcher after Watcher.Clear)
    -- never queues a new spawn → marker shows but car never appears.
    _near[entry.id]        = nil
    _vehicleNetId[entry.id] = nil
end)

--- Server sends the netID of an already-spawned vehicle when a client enters its
--- proximity. This populates _vehicleNetId so the collision monitor can track it
--- even if applyMods was never sent to this client (vehicle was pre-spawned).
RegisterNetEvent('orp:client:vehicleNetId')
AddEventHandler('orp:client:vehicleNetId', function(vehicleId, netID)
    if vehicleId and netID then
        _vehicleNetId[vehicleId] = netID
    end
end)

--- Server removed an unparked/confiscated vehicle.
RegisterNetEvent('orp:client:removePosition', function(id)
    _positions[id]    = nil
    _near[id]         = nil
    _vehicleNetId[id] = nil
    _moveLastCheck[id] = nil
end)

-- ── Proximity check loop ──────────────────────────────────────

local _heartbeatTimer = 0   -- last time we sent a full-near heartbeat
local _immediateCheck = false  -- set true by initPositions to skip the next Wait

CreateThread(function()
    while true do
        if not _immediateCheck then
            Wait(500)
        end
        _immediateCheck = false

        -- Don't check before positions are loaded
        if not next(_positions) then goto skip end

        local ped = PlayerPedId()
        if not DoesEntityExist(ped) then goto skip end

        local px, py, pz = table.unpack(GetEntityCoords(ped))
        local spawnR2    = Config.SpawnRadius   * Config.SpawnRadius
        local despawnR2  = Config.DespawnRadius * Config.DespawnRadius

        local entered = {}
        local exited  = {}

        for id, pos in pairs(_positions) do
            local dx  = px - pos.x
            local dy  = py - pos.y
            local dz  = pz - pos.z
            local d2  = dx*dx + dy*dy + dz*dz

            local wasNear = _near[id]
            local isNear  = d2 <= spawnR2

            if isNear and not wasNear then
                _near[id]            = true
                entered[#entered + 1] = id
            elseif not isNear and wasNear and d2 > despawnR2 then
                -- Only fire exit once the vehicle is beyond DespawnRadius,
                -- creating a hysteresis gap that prevents rapid enter/exit bouncing.
                _near[id]          = nil
                exited[#exited + 1] = id
            end
        end

        if #entered > 0 then
            TriggerServerEvent('orp:nearVehicles', entered)
            dbg('Tracker: entered', #entered, 'vehicles')
        end
        if #exited > 0 then
            TriggerServerEvent('orp:farFromVehicles', exited)
            dbg('Tracker: exited', #exited, 'vehicles')
        end

        -- Heartbeat: every 15 s re-send ALL currently-near vehicles to the server.
        -- Guarantees that any vehicle whose nearVehicles event was dropped (server
        -- rate-limit hit by a concurrent batch, or any other race) will eventually
        -- spawn. The server handles already-SPAWNED and already-SPAWNING vehicles
        -- as no-ops (just adds the player to the Watcher), so this is always safe.
        -- Only fires when no new entries were sent this tick to avoid hitting the
        -- server-side rate-limit with two events in the same millisecond.
        if #entered == 0 and next(_near) then
            local nowMs = GetGameTimer()
            if (nowMs - _heartbeatTimer) >= 15000 then
                _heartbeatTimer = nowMs
                local hbIds = {}
                for id in pairs(_near) do hbIds[#hbIds + 1] = id end
                if #hbIds > 0 then
                    TriggerServerEvent('orp:nearVehicles', hbIds)
                    dbg('Tracker: heartbeat', #hbIds, 'vehicles')
                end
            end
        end

        ::skip::
    end
end)

-- ── Entity relay: take ownership from departing player ────────
-- The server sends this when the current entity holder (the player who
-- parked) is leaving and wants to pass the client entity to us.
-- We call NetworkRequestControlOfEntity so GTA keeps the entity alive
-- under our ownership until WE eventually leave too.
RegisterNetEvent('orp:client:claimEntity', function(netID)
    CreateThread(function()
        local deadline = GetGameTimer() + 5000
        -- Wait until the entity is in our network bubble.
        while not NetworkDoesEntityExistWithNetworkId(netID) do
            if GetGameTimer() > deadline then
                dbg('claimEntity: timeout waiting for netID', netID)
                return
            end
            Wait(50)
        end
        local entity = NetworkGetEntityFromNetworkId(netID)
        if DoesEntityExist(entity) then
            NetworkRequestControlOfEntity(entity)
            dbg('claimEntity: claimed entity netID=' .. tostring(netID))
        end
    end)
end)

-- ── Anti-duplicate cleanup ────────────────────────────────────
-- After the server spawns an entity for a parked vehicle it broadcasts this
-- event so every client can delete any local copy of the same plate that is
-- NOT the newly spawned server entity.
RegisterNetEvent('orp:client:cleanupDuplicate', function(plate, newNetID)
    -- CRITICAL: wait before processing.
    -- The server sends this event immediately after CreateVehicleServerSetter
    -- completes, but the network ID association takes a few frames to propagate
    -- to clients. Without this Wait, NetworkGetNetworkIdFromEntity(veh) can
    -- return 0 for the freshly streamed server entity, causing the guard below to
    -- fail — and if FiveM already gave this client network control of that entity,
    -- DeleteEntity would kill our own server entity → immediate unexpected entityRemoved
    -- → infinite retry loop (the JRPK4177-style bug seen in production).
    Wait(600)

    local pool = GetGamePool('CVehicle')
    for _, veh in ipairs(pool) do
        local isNetworked = NetworkGetEntityIsNetworked(veh)

        if isNetworked then
            -- Guard 1: skip the freshly spawned server entity by netID.
            if NetworkGetNetworkIdFromEntity(veh) == newNetID then goto continue end

            -- Guard 2: skip ANY entity managed by the parking system.
            -- The orp_id state bag is set server-side on every entity we spawn.
            -- This is the definitive check when netID propagation is still in-flight.
            if Entity(veh).state.orp_id ~= nil then goto continue end
        end

        local vPlate = GetVehicleNumberPlateText(veh):gsub('%s+', '')
        if vPlate == plate then
            -- Never delete the vehicle the player is currently sitting in.
            if GetVehiclePedIsIn(PlayerPedId(), false) == veh then
                dbg('cleanupDuplicate: skipped — local player is inside plate', plate)
                goto continue
            end

            -- Only delete non-networked (local/client-only) entities.
            -- Networked entities are managed by the server or their owning client;
            -- deleting them from a third-party client can race with the server's
            -- view and remove valid server entities (exactly the loop bug above).
            if not isNetworked then
                SetEntityAsMissionEntity(veh, true, true)
                DeleteEntity(veh)
                dbg('cleanupDuplicate: deleted local entity for plate', plate)
            end
        end
        ::continue::
    end
end)

-- ── Mods application queue ────────────────────────────────────
-- All applyMods events are pushed into a FIFO queue.
-- Workers pull from it concurrently — more workers = faster mod application
-- across a zone with many parked vehicles.
--
-- Ownership contention note: each worker targets a DIFFERENT entity, so
-- there is no inter-worker contention on this client. The only contention
-- is when multiple CLIENTS all request control of the same entity at once
-- (rare), which is already handled by the 3-second fallback-apply timeout.
--
-- Workers = Config.SpawnConcurrency + 1 so mods keep pace with spawning.
-- Default: 4 workers → 30 vehicles × 700 ms / 4 = ~5 s (vs ~10 s with 2).

local _modQueue        = {}   -- { netID, mods }
local _modWorkers      = 0
local _MOD_MAX_WORKERS = (Config.SpawnConcurrency or Config.SpawnBatchSize or 3) + 1

local function _applyOneMod(netID, mods)
    local deadline = GetGameTimer() + 12000

    -- Wait for entity to enter this client's network bubble.
    while not NetworkDoesEntityExistWithNetworkId(netID) do
        if GetGameTimer() > deadline then return end
        Wait(50)
    end
    local entity = NetworkGetEntityFromNetworkId(netID)
    while not DoesEntityExist(entity) do
        if GetGameTimer() > deadline then return end
        Wait(50)
        entity = NetworkGetEntityFromNetworkId(netID)
    end

    -- Request ownership. If not granted within 3 s, apply anyway as fallback.
    -- The server already applied physics-critical mods; client pass is cosmetic
    -- only (colours, livery, neon), so applying without ownership is safe.
    NetworkRequestControlOfEntity(entity)
    local ctrlDeadline = GetGameTimer() + 3000
    while not NetworkHasControlOfEntity(entity) do
        if GetGameTimer() > ctrlDeadline then
            dbg('[applyMods] ownership timeout netID=' .. tostring(netID))
            break
        end
        Wait(50)
    end

    if not DoesEntityExist(entity) then return end

    -- Record vehicleId→netID so the collision-position monitor can track this entity.
    local orp_id = Entity(entity).state.orp_id
    if orp_id then
        _vehicleNetId[orp_id] = netID
    end

    -- The server already applied all physics-critical mods (suspension, wheels,
    -- geometry) server-side before freezing the entity at the stored Z. That Z
    -- is the exact on-ground equilibrium for this vehicle with these mods, so
    -- there is nothing to snap or reposition. This pass is a cosmetic supplement
    -- for client-only properties (custom paint sync, neon, extras) that the
    -- server cannot replicate fully.
    applyVehicleProps(entity, mods)

    -- Colour guarantee: GTA can override colour during the first ~500 ms of
    -- entity initialisation on the local client. Wait, then check occupancy
    -- BEFORE the second pass — if the player entered during the Wait we must
    -- not flash their active vehicle with property changes.
    Wait(500)
    if not DoesEntityExist(entity) then return end
    if GetPedInVehicleSeat(entity, -1) ~= 0 then
        -- Vehicle was unparked + entered while we were waiting (park/unpark race).
        -- The player already has the car; skip further processing entirely.
        dbg('[applyMods] aborted — entity occupied after colour-guarantee wait, netID=' .. tostring(netID))
        return
    end
    applyVehicleProps(entity, mods)  -- second pass (colour guarantee)

    -- ── Position is EXCLUSIVELY managed by the server ─────────────────────────
    -- The server called lib.setVehicleProperties → FreezeEntityPosition(true)
    -- in that order, so the entity is already locked at the exact on-ground Z.
    -- We must NEVER call FreezeEntityPosition(false), PlaceObjectOnGroundProperly,
    -- or FreezeEntityPosition(true) from the client. Every time any client
    -- unfreezes a server entity, GTA's physics engine recalculates suspension
    -- equilibrium from scratch, which can push the vehicle up if wheel geometry
    -- differs even slightly between the two calls. With multiple clients each
    -- running their own pass concurrently, the result is random levitation.
    -- ──────────────────────────────────────────────────────────────────────────

    -- Damage/health pass (body health, engine, tyres, dirt, broken parts).
    -- The entity stays frozen throughout — damage state does not affect physics.
    Wait(200)
    if not DoesEntityExist(entity) then return end
    if GetPedInVehicleSeat(entity, -1) ~= 0 then return end
    applyVehicleDamage(entity, mods)

    -- Signal server that the cosmetic pass is complete.
    -- Cancels the 5-second broadcast retry in _pendingMods.
    if DoesEntityExist(entity) then
        TriggerServerEvent('orp:server:modsApplied', netID)
    end
    dbg('[applyMods] cosmetic pass done netID=' .. tostring(netID))
end

local function _startModWorker()
    if _modWorkers >= _MOD_MAX_WORKERS then return end
    _modWorkers = _modWorkers + 1
    CreateThread(function()
        while #_modQueue > 0 do
            local item = table.remove(_modQueue, 1)
            if item then
                local ok, err = pcall(_applyOneMod, item.netID, item.mods)
                if not ok then
                    print(string.format('^1[ORG MODS  ]^7 applyMods error netID=%d: %s',
                        item.netID, tostring(err)))
                end
            end
        end
        _modWorkers = _modWorkers - 1
    end)
end

RegisterNetEvent('orp:client:applyMods', function(netID, mods)
    if not mods or not next(mods) then return end
    -- Deduplicate: if this netID is already queued the server's 5-second retry
    -- fired while the first job is still in progress. Drop the duplicate to
    -- avoid applying cosmetic props twice and causing contention.
    for _, item in ipairs(_modQueue) do
        if item.netID == netID then return end
    end
    _modQueue[#_modQueue + 1] = { netID = netID, mods = mods }
    _startModWorker()
end)

-- ── Parking marker ────────────────────────────────────────────────────────
-- Draws a small floating marker (type 36 — car icon, black, rotating + bobbing)
-- above every nearby parked vehicle so players can identify system-parked cars.
-- Only renders within Config.ParkingMarker.drawDist — no cost for far vehicles.

local _markerEnabled  = Config.ParkingMarker and Config.ParkingMarker.enabled  ~= false or false
local _markerDrawDist = Config.ParkingMarker and (Config.ParkingMarker.drawDist or 20.0)  or 20.0

-- Collision-position detection thresholds.
-- A parked vehicle must move more than this (in metres) before we record a
-- position update. 1 m avoids false positives from physics micro-jitter while
-- still catching any real collision.
local _MOVE_THRESHOLD_SQ = 1.0 * 1.0   -- squared for cheap comparison
local _MOVE_CHECK_INTERVAL = 2000       -- ms between checks per vehicle

-- Hot-reload from admin panel (server broadcasts after "Save Changes")
RegisterNetEvent('orp:client:updateMarkerConfig', function(cfg)
    if not cfg then return end
    if cfg.enabled  ~= nil then _markerEnabled  = cfg.enabled  end
    if cfg.drawDist ~= nil then _markerDrawDist = tonumber(cfg.drawDist) or _markerDrawDist end
end)

CreateThread(function()
    while true do
        if next(_near) then
            local pc    = GetEntityCoords(PlayerPedId())
            local dist2 = _markerDrawDist * _markerDrawDist
            local now   = GetGameTimer()
            -- Solo hace falta ir por fotograma si hay un marcador que pintar
            -- (o a punto de haberlo). Con los coches a 20-200 m el hilo iba a
            -- Wait(0) igual; el control de coches movidos lleva su propio
            -- intervalo de 2 s por coche y no nota la siesta.
            local closeDist = _markerDrawDist + 5.0
            local close2    = closeDist * closeDist
            local anyClose  = false

            for id in pairs(_near) do
                local pos = _positions[id]
                if pos then
                    -- ── Marker draw ──────────────────────────────────────────
                    if _markerEnabled then
                        local dx = pc.x - pos.x
                        local dy = pc.y - pos.y
                        local dz = pc.z - pos.z
                        local d2 = dx*dx + dy*dy + dz*dz
                        if d2 <= close2 then anyClose = true end
                        if d2 <= dist2 then
                            DrawMarker(
                                36,                          -- marker type 36
                                pos.x, pos.y, pos.z + 1.6,  -- slightly above vehicle
                                0.0, 0.0, 0.0,              -- direction
                                0.0, 0.0, 0.0,              -- rotation
                                0.20, 0.20, 0.20,           -- scale (pequeñito)
                                0, 0, 0, 200,               -- black, slight transparency
                                true,                       -- bobUpAndDown
                                false,                      -- faceCamera
                                2, true, nil, nil, false    -- rotate = true
                            )
                        end
                    end

                    -- ── Collision-position monitor ───────────────────────────
                    -- Only check if the vehicle has a known netID and enough
                    -- time has passed since the last check for this vehicle.
                    local netID = _vehicleNetId[id]
                    if netID and (not _moveLastCheck[id] or (now - _moveLastCheck[id]) >= _MOVE_CHECK_INTERVAL) then
                        _moveLastCheck[id] = now
                        if NetworkDoesEntityExistWithNetworkId(netID) then
                            local ent = NetworkGetEntityFromNetworkId(netID)
                            if DoesEntityExist(ent) and GetPedInVehicleSeat(ent, -1) == 0 then
                                local ex, ey, ez = table.unpack(GetEntityCoords(ent))
                                local ddx = ex - pos.x
                                local ddy = ey - pos.y
                                local ddz = ez - pos.z
                                if ddx*ddx + ddy*ddy + ddz*ddz > _MOVE_THRESHOLD_SQ then
                                    -- Vehicle moved from its stored position — notify server.
                                    TriggerServerEvent('orp:server:vehicleMoved', {
                                        id      = id,
                                        netID   = netID,
                                        x       = ex,
                                        y       = ey,
                                        z       = ez,
                                        heading = GetEntityHeading(ent),
                                    })
                                    -- Update local stored position immediately so the
                                    -- marker and the proximity tracker stay accurate
                                    -- without waiting for the server broadcast.
                                    _positions[id] = { x = ex, y = ey, z = ez }
                                end
                            end
                        end
                    end
                end
            end
            Wait(anyClose and 0 or 500)
        else
            Wait(500)
        end
    end
end)

-- ── Expose position list for other client scripts ─────────────

exports('GetParkingPositions', function()
    return _positions
end)

exports('IsVehicleNearby', function(id)
    return _near[id] == true
end)

-- Returns a minimal table if the plate is currently tracked as a street-parked
-- vehicle, or nil if not.  Used by qbx_vehiclekeys to enrich lock notifications.
-- Fully synchronous — just checks the local positions index.
exports('GetVehicleByPlate', function(plate)
    if not plate then return nil end
    local clean = plate:gsub('%s+', '')
    return _positions[clean] and { plate = clean } or nil
end)
