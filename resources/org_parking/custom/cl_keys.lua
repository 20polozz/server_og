-- ═══════════════════════════════════════════════════════════════════════════
--  ORG Parking — Client Key System Bridge
--  ► This file is NOT encrypted. Edit it to match your key system.
-- ═══════════════════════════════════════════════════════════════════════════

Keys = Keys or {}

-- ─────────────────────────────────────────────────────────────────────────────
--  IsLocked(vehicle)
--  Returns true if the given vehicle entity is locked.
--  Used to detect when the player locks their vehicle after exiting,
--  which triggers automatic parking.
-- ─────────────────────────────────────────────────────────────────────────────
function Keys.IsLocked(vehicle)
    -- Check state bag first (most key systems write it there)
    local stateBagLock = Entity(vehicle).state.doorslockstate
    if stateBagLock ~= nil then
        return stateBagLock >= 2
    end

    -- Fallback: GTA native lock status
    -- 0=None 1=Unlocked 2=Locked 3=LockedForPlayer 4=StuckForPlayer
    return GetVehicleDoorLockStatus(vehicle) >= 2
end
