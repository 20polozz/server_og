-- ═══════════════════════════════════════════════════════════════════════════
--  ORG Parking — Client Main  (store edition)
-- ═══════════════════════════════════════════════════════════════════════════

local _vehicleCache   = cache.vehicle
local _enableParking  = true
local _saving         = false
local _blacklistModel = {}
local _playerIdent    = nil

-- ── Blip management ────────────────────────────────────────────────────────
local _blips          = {}   -- vehicleId → blipHandle
local _ownedIds       = {}   -- vehicleId → true  (our parked vehicles)
local _ownedPositions = {}   -- vehicleId → {x, y, label}

-- label format: "SULTAN · 08PYI754"
local function _blipLabel(model, plate)
    local m = model and model:upper() or ''
    local p = plate or ''
    if m ~= '' and p ~= '' then return m .. ' · ' .. p end
    return m ~= '' and m or (p ~= '' and p or T('blip_parked_vehicle'))
end

--[[ El coche aparcado, en el mapa.

     Ya no es un blip del juego: es un punto de origen_map. Va con prioridad
     alta, que es lo que antes decia SetBlipAsShortRange(false): tu coche tiene
     que verse desde cualquier punto del mapa, porque justo para eso se mira. ]]
local function _createBlip(id, x, y, label)
    label = label or T('blip_parked_vehicle')
    _ownedPositions[id] = { x = x, y = y, label = label }
    if not Config.BlipEnabled then return end

    local clave = 'aparcado_' .. tostring(id)
    _blips[id] = clave

    OrigenMapa.Poner(clave, {
        x = x, y = y, z = 0.0,
        cat = 'garages',
        icono = 'parking',
        nombre = label,
        prioridad = 10,
        --- El color que diga el panel de admin. Sigue escrito como el numero
        --- de GTA de siempre; traducirlo es cosa de OrigenMapa.Color, y si el
        --- numero no esta en su tabla manda el color de la categoria.
        color = OrigenMapa.Color(Config.BlipColor),
    })
end

local function _removeBlip(id)
    if _blips[id] then OrigenMapa.Quitar(_blips[id]); _blips[id] = nil end
    _ownedIds[id]       = nil
    _ownedPositions[id] = nil
end

local function _refreshAllBlips()
    for _, clave in pairs(_blips) do OrigenMapa.Quitar(clave) end
    _blips = {}
    if Config.BlipEnabled then
        for id, pos in pairs(_ownedPositions) do
            _createBlip(id, pos.x, pos.y, pos.label)
        end
    end
end

-- Build blacklist index
CreateThread(function()
    for _, m in ipairs(Config.BlacklistedModels or {}) do
        _blacklistModel[m] = true
    end
end)

-- ── Player identifier ──────────────────────────────────────────────────────

local function loadIdentifier()
    local tries = 0
    while tries < 60 do
        local id = Framework.GetLocalIdentifier()
        if id then
            _playerIdent = id
            return
        end
        Wait(500)
        tries = tries + 1
    end
end

CreateThread(function()
    loadIdentifier()
    TriggerServerEvent('orp:server:playerReady')
    if _playerIdent then
        local owned = lib.callback.await('orp:server:getOwnedVehicles', false, _playerIdent)
        if owned then
            for _, v in ipairs(owned) do
                if Config.GiveKeysOnSpawn then
                    TriggerEvent('org_parking:client:keysDelivered', v.plate)
                end
                -- Register as owned and create blip (always visible, even far away)
                _ownedIds[v.id] = true
                if v.coords then
                    _createBlip(v.id, v.coords.x, v.coords.y, _blipLabel(v.model, v.plate))
                end
            end
        end
    end
end)

-- Re-identify on framework player-loaded event (reconnect / re-spawn)
Framework.OnPlayerLoaded(function()
    loadIdentifier()
end)

-- Blip management
_ownedIds = _ownedIds or {}
_blips = _blips or {}
_ownedPositions = _ownedPositions or {}

RegisterNetEvent('orp:client:addPosition')
RegisterNetEvent('orp:client:removePosition')

-- Server confirms our vehicle was parked (new park only, not re-park).
-- Creates the blip and registers the id as owned so addPosition updates it.
RegisterNetEvent('orp:client:ownVehicleParked', function(pos)
    _ownedIds[pos.id] = true
    _createBlip(pos.id, pos.x, pos.y, _blipLabel(pos.model, pos.plate))
end)

-- A position was updated (re-park, collision move). Sent to all clients but we
-- only update the blip if this vehicle belongs to us (is in _ownedIds).
-- cl_tracker.lua handles updating _positions for the proximity tracker.
AddEventHandler('orp:client:addPosition', function(entry)
    if not _ownedIds[entry.id] then return end
    local label = (_ownedPositions[entry.id] and _ownedPositions[entry.id].label)
               or _blipLabel(entry.model, entry.plate)
    _ownedPositions[entry.id] = { x = entry.x, y = entry.y, label = label }
    --- Volver a ponerlo con la misma clave lo mueve: el registro actualiza el
    --- punto que ya hubiera en vez de crear otro.
    _createBlip(entry.id, entry.x, entry.y, label)
end)

-- A vehicle was removed from the parking system (unpark / confiscate).
AddEventHandler('orp:client:removePosition', function(id)
    _removeBlip(id)
end)

-- Admin changed blip config via settings panel — hot-reload.
RegisterNetEvent('orp:client:updateBlipConfig', function(cfg)
    Config.BlipEnabled = cfg.enabled
    Config.BlipColor   = cfg.color
    Config.BlipSprite  = cfg.sprite
    _refreshAllBlips()
end)

-- ── Zone + state helpers ───────────────────────────────────────────────────

local function isNearBlacklistedZone(coords)
    for _, zone in ipairs(Config.BlacklistedZones or {}) do
        if #(coords - zone.coords) < zone.radius then return true end
    end
    return false
end

local function isVehicleEmpty(vehicle)
    if GetVehicleNumberOfPassengers(vehicle) > 0 then return false end
    if GetPedInVehicleSeat(vehicle, -1) ~= 0     then return false end
    return true
end

local function isVehicleLocked(vehicle)
    return Keys.IsLocked(vehicle)
end

local function isBicycle(vehicle)
    return GetVehicleType(vehicle) == 'bicycle'
end

-- ── Vehicle data capture ───────────────────────────────────────────────────

local function getVehicleData(vehicle)
    local coords  = GetEntityCoords(vehicle)
    local heading = GetEntityHeading(vehicle)
    local statePlate = Entity(vehicle).state.orp_plate
    local rawPlate   = GetVehicleNumberPlateText(vehicle):gsub('%s+', '')
    local plate      = (statePlate and statePlate ~= '') and statePlate or rawPlate
    return {
        id          = Entity(vehicle).state.orp_id,
        plate       = plate,
        model       = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)):lower(),
        hash        = GetEntityModel(vehicle),
        coords      = { x = coords.x, y = coords.y, z = coords.z, w = heading },
        netID       = NetworkGetNetworkIdFromEntity(vehicle),
        mods        = captureVehicleProps(vehicle),
        vehicleType = GetVehicleType(vehicle),
    }
end

-- ── Vehicle properties capture / apply ────────────────────────────────────

-- Use ox_lib's getVehicleProperties / setVehicleProperties as the canonical
-- property system — same format as qbx_customs, so tuning is always preserved.
-- We add two custom fields on top: `doors` (exposition mode) and override
-- `fuelLevel` through our Fuel bridge when Config.SaveFuel is active.

function captureVehicleProps(vehicle)
    if not DoesEntityExist(vehicle) then return {} end
    local props = lib.getVehicleProperties(vehicle)

    -- Override fuel with our multi-resource bridge
    if Config.SaveFuel then
        props.fuelLevel = math.floor(Fuel.Get(vehicle) * 10 + 0.5) / 10
    end

    -- Door states (exposition mode)
    local doors = {}
    for i = 0, 5 do
        if IsVehicleDoorFullyOpen(vehicle, i) then
            doors[tostring(i)] = true
        end
    end
    props.doors = doors

    return props
end

function applyVehicleProps(vehicle, p)
    if not DoesEntityExist(vehicle) or not p then return end

    -- Old-format detection: mods stored before the ox_lib migration used the
    -- American spelling 'tireBurstState'. ox_lib uses 'tyreBurstCompletely'
    -- (British). This field is the ONLY reliable discriminator — do NOT check
    -- 'headlightColor' because ox_lib also includes that field for vehicles
    -- with custom headlight colours, causing a false positive that silently
    -- discards all mods for those vehicles.
    if p.tireBurstState ~= nil then
        dbg('[applyVehicleProps] old-format mods — skipping (plate=' .. tostring(p.plate) .. ')')
        return
    end

    -- Stash and strip custom fields that lib.setVehicleProperties does not accept.
    local doors     = p.doors
    local fuelLevel = p.fuelLevel
    p.doors         = nil
    p.fuelLevel     = nil

    dbg(string.format('[applyVehicleProps] plate=%s color1=%s modEngine=%s',
        tostring(p.plate), tostring(p.color1), tostring(p.modEngine)))

    local ok, err = pcall(lib.setVehicleProperties, vehicle, p)
    if not ok then
        print(string.format('^1[ORG PARKING]^7 applyVehicleProps error plate=%s: %s',
            tostring(p.plate), tostring(err)))
    end

    -- Restore custom fields
    p.doors     = doors
    p.fuelLevel = fuelLevel

    if fuelLevel and Config.SaveFuel then
        Fuel.Set(vehicle, fuelLevel)
    end

    if doors then
        for idx, open in pairs(doors) do
            if open then
                SetVehicleDoorOpen(vehicle, tonumber(idx), false, true)
            end
        end
    end
end

-- ── Vehicle damage apply (second pass) ────────────────────────────────────
-- lib.setVehicleProperties already sets body/engine/tank health and tyre/window
-- states, but GTA can overwrite those values during the initial entity sync.
-- This function re-applies only the damage-relevant fields ~500 ms after spawn
-- once the physics engine has settled, ensuring the saved state sticks.

function applyVehicleDamage(vehicle, p)
    if not DoesEntityExist(vehicle) or not p then return end

    -- Health values
    if p.bodyHealth   then SetVehicleBodyHealth(vehicle,       p.bodyHealth   + 0.0) end
    if p.engineHealth then SetVehicleEngineHealth(vehicle,     p.engineHealth + 0.0) end
    if p.tankHealth   then SetVehiclePetrolTankHealth(vehicle, p.tankHealth   + 0.0) end
    if p.dirtLevel    then SetVehicleDirtLevel(vehicle,        p.dirtLevel    + 0.0) end

    -- Tyre burst (completely flat)
    if p.tyreBurstCompletely then
        for tyre, burst in pairs(p.tyreBurstCompletely) do
            if burst then
                SetVehicleTyreBurst(vehicle, tonumber(tyre), true, 1000.0)
            end
        end
    end

    -- Tyre burst (partially damaged)
    if p.tyresBurst then
        for tyre, burst in pairs(p.tyresBurst) do
            if burst then
                SetVehicleTyreBurst(vehicle, tonumber(tyre), false, 1000.0)
            end
        end
    end

    -- Window damage
    if p.windowsDamaged then
        for win, dmg in pairs(p.windowsDamaged) do
            if dmg then SmashVehicleWindow(vehicle, tonumber(win)) end
        end
    end

    -- Broken doors
    if p.doorsBroken then
        for door, broken in pairs(p.doorsBroken) do
            if broken then SetVehicleDoorBroken(vehicle, tonumber(door), true) end
        end
    end
end

-- ── Automatic parking ──────────────────────────────────────────────────────

local _pendingParkVehicle = nil

lib.onCache('vehicle', function(value)
    if not Config.AutomaticParking then return end

    if value then
        _pendingParkVehicle = nil
        _vehicleCache       = value
        if not isBicycle(value) then
            local orp_id = Entity(value).state.orp_id
            if orp_id then
                TriggerServerEvent('orp:server:unparkVehicle', { id = orp_id })
            else
                -- Fallback: If state bag is missing due to sync delays, use the plate
                local rawPlate = GetVehicleNumberPlateText(value)
                if rawPlate then
                    TriggerServerEvent('orp:server:unparkVehicle', { plate = rawPlate:gsub('%s+', '') })
                end
            end
        end
    else
        if not _enableParking or _saving then return end
        local vehicle = _vehicleCache
        if not vehicle or not DoesEntityExist(vehicle) then return end
        if isBicycle(vehicle) then return end

        local modelName = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)):lower()
        if _blacklistModel[modelName] then return end

        _saving             = true
        _pendingParkVehicle = vehicle

        local plate = GetVehicleNumberPlateText(vehicle):gsub('%s+', '')
        dbg('[CLIENT] Waiting for lock: plate=' .. plate)

        CreateThread(function()
            local ok, err = pcall(function()
                local deadline = GetGameTimer() + (Config.AutomaticParkingTimeout * 1000)
                while true do
                    Wait(250)
                    if _pendingParkVehicle ~= vehicle then
                        dbg('[CLIENT] Cancelled (entered another vehicle): plate=' .. plate)
                        _saving = false; return
                    end
                    if not DoesEntityExist(vehicle) then
                        dbg('[CLIENT] Cancelled (entity deleted): plate=' .. plate)
                        _saving = false; _pendingParkVehicle = nil; return
                    end
                    if not isVehicleEmpty(vehicle) then
                        dbg('[CLIENT] Cancelled (someone entered): plate=' .. plate)
                        _saving = false; _pendingParkVehicle = nil; return
                    end
                    if isVehicleLocked(vehicle) then
                        dbg('[CLIENT] Lock detected → parking: plate=' .. plate)
                        -- Brief pause so GTA finishes applying any pending tuning
                        -- state transitions (custom paint, extras) before capture.
                        Wait(200)
                        break
                    end
                    if GetGameTimer() > deadline then
                        dbg('[CLIENT] Timeout without locking → not parked: plate=' .. plate)
                        _saving = false; _pendingParkVehicle = nil; return
                    end
                end

                _pendingParkVehicle = nil

                if not DoesEntityExist(vehicle) then _saving = false; return end
                if not isVehicleEmpty(vehicle)  then _saving = false; return end

                local pedCoords = GetEntityCoords(PlayerPedId())
                if isNearBlacklistedZone(pedCoords) then
                    dbg('[CLIENT] Blocked zone'); _saving = false; return
                end

                local speedDeadline = GetGameTimer() + 5000
                while GetEntitySpeed(vehicle) > 0.1 do
                    Wait(100)
                    if GetGameTimer() > speedDeadline then break end
                end

                local data = getVehicleData(vehicle)
                dbg('[CLIENT] Sending parkVehicle: plate=' .. tostring(data.plate))
                TriggerServerEvent('orp:server:parkVehicle', data)
                _vehicleCache = nil
                _saving       = false
            end)
            if not ok then
                print(string.format('^1[ORG CLIENT]^7 Error in park thread (plate=%s): %s', plate, tostring(err)))
                _saving             = false
                _pendingParkVehicle = nil
            end
        end)
    end
end)

-- ── Manual park ────────────────────────────────────────────────────────────

local function parkVehicle(vehicle)
    if not _enableParking then return end
    TriggerServerEvent('orp:server:parkVehicle', getVehicleData(vehicle))
end
exports('parkVehicle', parkVehicle)

-- ── Manual unpark ──────────────────────────────────────────────────────────

local function unparkVehicle(data)
    if type(data) == 'number' then
        local orp_id = Entity(data).state.orp_id
        if orp_id then TriggerServerEvent('orp:server:unparkVehicle', { id = orp_id }) end
    elseif type(data) == 'string' then
        -- Normalize plate to same format used for server-side indexing
        TriggerServerEvent('orp:server:unparkVehicle', { plate = data:gsub('%s+', '') })
    elseif type(data) == 'table' then
        if data.plate then data.plate = data.plate:gsub('%s+', '') end
        TriggerServerEvent('orp:server:unparkVehicle', data)
    end
end
exports('unparkVehicle', unparkVehicle)

-- ── Confiscate ─────────────────────────────────────────────────────────────
-- Unified export used by both the admin panel and origen_police.
--   · Table arg { id=... } or { plate=... }  → admin/internal confiscation
--                                               (ownership validated server-side)
--   · Entity handle (number + DoesEntityExist) → police confiscation
--                                               (no ownership check; origen_police
--                                                validates the officer's job first)

exports('confiscateVehicle', function(arg)
    if type(arg) == 'table' then
        TriggerServerEvent('orp:server:confiscateVehicle', arg)
    elseif type(arg) == 'number' and DoesEntityExist(arg) then
        local plate = GetVehicleNumberPlateText(arg):gsub('%s+', '')
        if plate ~= '' then
            TriggerServerEvent('orp:server:policeConfiscate', plate)
        end
    end
end)

-- ── Toggle auto-park ───────────────────────────────────────────────────────

exports('toggleLocalParking', function(state)
    _enableParking = state ~= nil and state or not _enableParking
end)

-- ── Anti-theft notification (fired locally by qbx_vehiclekeys on lockpick) ─
AddEventHandler('orp:client:notifyAntiTheft', function()
    Framework.NotifyClient(T('notify_antitheft'), 'error')
end)

-- ── Anti-theft eject (fired by server on unauthorised unpark attempt) ───────
RegisterNetEvent('orp:client:antiTheftEject', function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh and veh ~= 0 then TaskLeaveVehicle(ped, veh, 0) end
    Framework.NotifyClient(T('notify_antitheft'), 'error')
end)

-- ── Parking cost blocked (server: player cannot afford the fee) ─────────────
RegisterNetEvent('orp:client:parkingCostBlocked', function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh and veh ~= 0 then TaskLeaveVehicle(ped, veh, 0) end
end)

-- ── Debug commands ─────────────────────────────────────────────────────────

if Config.Debug then
    RegisterCommand('orp_park', function()
        local v = lib.getClosestVehicle(GetEntityCoords(PlayerPedId()), 5.0, true)
        if v then parkVehicle(v) end
    end, false)

    RegisterCommand('orp_unpark', function()
        local v = lib.getClosestVehicle(GetEntityCoords(PlayerPedId()), 5.0, true)
        if v then unparkVehicle(v) end
    end, false)

    RegisterCommand('orp_status', function()
        local positions = exports['org_parking']:GetParkingPositions()
        local count = 0
        for _ in pairs(positions) do count = count + 1 end
        lib.notify({ title = 'Aparcamiento', description = 'Posiciones: ' .. count, type = 'inform' })
    end, false)
end
