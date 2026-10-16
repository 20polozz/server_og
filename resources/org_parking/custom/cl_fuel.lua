-- ═══════════════════════════════════════════════════════════════════════════
--  ORG Parking — Client Fuel Bridge
--  ► This file is NOT encrypted. Edit it to match your server setup.
--
--  Config.FuelSystem controls which resource is used:
--    'auto'       → auto-detects the first running compatible resource
--    'ox_fuel'    → ox_fuel  (exports: GetFuel / SetFuel)
--    'LegacyFuel' → LegacyFuel
--    'ps-fuel'    → ps-fuel
--    'cdn-fuel'   → cdn-fuel
--    'native'     → GTA V native only (GetVehicleFuelLevel / SetVehicleFuelLevel)
--    'custom'     → implement Fuel.Get / Fuel.Set below
-- ═══════════════════════════════════════════════════════════════════════════

Fuel = Fuel or {}

-- ── Internal: resolve which system to use ────────────────────────────────

local _resolved = nil

local function _resolveFuelSystem()
    if _resolved then return _resolved end
    local sys = Config.FuelSystem or 'auto'
    if sys ~= 'auto' then
        _resolved = sys
        return _resolved
    end
    -- Auto-detect: first started resource wins
    local candidates = { 'ox_fuel', 'LegacyFuel', 'ps-fuel', 'cdn-fuel' }
    for _, name in ipairs(candidates) do
        if GetResourceState(name) == 'started' then
            _resolved = name
            return _resolved
        end
    end
    _resolved = 'native'
    return _resolved
end

-- ── Fuel.Get(vehicle) ────────────────────────────────────────────────────
--  Returns the current fuel level (0.0 – 100.0) for the given vehicle.

function Fuel.Get(vehicle)
    if not DoesEntityExist(vehicle) then return 100.0 end
    local sys = _resolveFuelSystem()

    if sys == 'ox_fuel' then
        local ok, v = pcall(function() return exports['ox_fuel']:GetFuel(vehicle) end)
        if ok and type(v) == 'number' then return v end

    elseif sys == 'LegacyFuel' then
        local ok, v = pcall(function() return exports['LegacyFuel']:GetFuel(vehicle) end)
        if ok and type(v) == 'number' then return v end

    elseif sys == 'ps-fuel' then
        local ok, v = pcall(function() return exports['ps-fuel']:GetFuel(vehicle) end)
        if ok and type(v) == 'number' then return v end

    elseif sys == 'cdn-fuel' then
        local ok, v = pcall(function() return exports['cdn-fuel']:GetFuel(vehicle) end)
        if ok and type(v) == 'number' then return v end

    elseif sys == 'custom' then
        -- ► Edit here:
        -- return YOUR_FUEL_RESOURCE.GetFuel(vehicle)
    end

    -- Fallback: GTA native
    return GetVehicleFuelLevel(vehicle)
end

-- ── Fuel.Set(vehicle, level) ─────────────────────────────────────────────
--  Sets the fuel level (0.0 – 100.0) on the given vehicle.
--  Always writes the GTA native first so the baseline is always correct.

function Fuel.Set(vehicle, level)
    if not DoesEntityExist(vehicle) then return end
    level = math.max(0.0, math.min(100.0, tonumber(level) or 100.0))

    -- Always set native as baseline
    SetVehicleFuelLevel(vehicle, level + 0.0)

    local sys = _resolveFuelSystem()

    if sys == 'ox_fuel' then
        pcall(function() exports['ox_fuel']:SetFuel(vehicle, level) end)

    elseif sys == 'LegacyFuel' then
        pcall(function() exports['LegacyFuel']:SetFuel(vehicle, level) end)

    elseif sys == 'ps-fuel' then
        pcall(function() exports['ps-fuel']:SetFuel(vehicle, level) end)

    elseif sys == 'cdn-fuel' then
        pcall(function() exports['cdn-fuel']:SetFuel(vehicle, level) end)

    elseif sys == 'custom' then
        -- ► Edit here:
        -- YOUR_FUEL_RESOURCE.SetFuel(vehicle, level)
    end
end
