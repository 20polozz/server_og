--[[
    ============================================================
    STASH SETTINGS
    ============================================================
    Configures the gang shared stash (storage system).
    Weight and slot limits apply to each gang's shared stash.
    ============================================================
--]]

Config.Stash = {
    -- Enable the gang shared stash system
    Enable = true,

    -- Maximum carry weight of the stash (in grams, depends on inventory system)
    MaxWeight = 500000,

    -- Maximum number of item slots in the stash
    MaxSlots = 50,
}
