---------------------------------------------------------------------
-- PROMPT SANDY MECHANIC — Target System Wrapper
-- Supports ox_target and qb-target. All call sites use these globals;
-- the wrapper translates internally. Falls back to E-key (lib.zones)
-- when neither target system is available.
---------------------------------------------------------------------

-- Detected target system: 'ox_target' | 'qb-target' | 'none'
-- Synchronous (no CreateThread) — downstream files read at load time.
TargetSystem = 'none'
useTarget = false

do
    -- Config.UseOxTarget = false means "disable all target systems" (E-key only)
    -- Config.UseOxTarget = true (or nil/missing) means "auto-detect best available"
    local enableTargets = Config.UseOxTarget ~= false
    if enableTargets then
        if GetResourceState('ox_target') == 'started' then
            TargetSystem = 'ox_target'
        elseif GetResourceState('qb-target') == 'started' then
            TargetSystem = 'qb-target'
        end
    end
    useTarget = TargetSystem ~= 'none'

    if Config.Debug then
        if useTarget then
            print('[COMPOUND] Target system: ' .. TargetSystem)
        else
            print('[COMPOUND] No target system — using E-key zones')
        end
    end
end

-- ── Helpers ──────────────────────────────────────────────────────────

local function TranslateOption(opt)
    return {
        name        = opt.name,
        label       = opt.label,
        icon        = opt.icon,
        action      = opt.onSelect,
        canInteract = opt.canInteract,
    }
end

local function TranslateOptions(options)
    local out = {}
    for _, opt in ipairs(options) do
        out[#out + 1] = TranslateOption(opt)
    end
    return out
end

-- ── Wrapper Functions ────────────────────────────────────────────────

-- Add a box zone with target options
-- data: { name, coords, size (vec3), rotation, options, debug }
function TargetAddBoxZone(data)
    if TargetSystem == 'ox_target' then
        exports.ox_target:addBoxZone(data)
    elseif TargetSystem == 'qb-target' then
        exports['qb-target']:AddBoxZone(data.name, data.coords, data.size.x, data.size.y, {
            name    = data.name,
            heading = data.rotation or 0.0,
            debugPoly = data.debug or false,
            minZ    = data.coords.z - (data.size.z or 2.0),
            maxZ    = data.coords.z + (data.size.z or 2.0),
        }, {
            options  = TranslateOptions(data.options),
            distance = 2.5,
        })
    end
end

-- Remove a zone by name
function TargetRemoveZone(name)
    if TargetSystem == 'ox_target' then
        exports.ox_target:removeZone(name)
    elseif TargetSystem == 'qb-target' then
        exports['qb-target']:RemoveZone(name)
    end
end
