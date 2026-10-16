--[[
    ============================================================
    GANGS SETTINGS
    ============================================================
    Defines global gang limits, the bank system, the level/XP
    system, and the default rank hierarchy created when a new
    gang is formed. Permissions within ranks control what each
    member can and cannot do in the gang panel.
    ============================================================
--]]

Config.Gang = {
    -- Maximum number of members allowed per gang
    MaxMembers = 20,

    -- Maximum number of gangs that can exist on the server simultaneously
    MaxGangs = 50,

    -- ── GANG BANK ────────────────────────────────────────────────────────────
    Bank = {
        -- Enable the shared gang bank
        Enable     = true,

        -- Starting balance when a gang is created
        StartMoney = 0,

        -- Maximum balance the gang bank can hold
        MaxMoney   = 10000000,
    },

    -- ── LEVEL SYSTEM ─────────────────────────────────────────────────────────
    LevelSystem = {
        -- Enable the gang leveling/XP system
        Enable      = true,

        -- XP required to advance one level (used when crafting GangLevel formula
        -- is set to 'flat' — otherwise Config.Crafting.GangLevel controls the curve)
        ExpPerLevel = 1000,
    },

    -- ── DEFAULT RANKS ────────────────────────────────────────────────────────
    -- Rank structure automatically created when a new gang is founded.
    -- 'id' must be unique and ordered (1 = highest authority).
    -- 'permissions' are granular access flags checked by the gang panel and server.

    DefaultRanks = {
        {
            id   = 1,
            name = "Leader",
            salary = 0,
            permissions = {
                invite               = true,
                kick                 = true,
                promote              = true,
                demote               = true,
                manage_bank          = true,
                withdraw             = true,
                deposit              = true,
                access_stash         = true,
                access_personal_stash = true,
                access_garage        = true,
                access_clothing      = true,
                manage_stash         = true,
                manage_vehicles      = true,
                manage_ranks         = true,
                manage_locations     = true,
                view_logs            = true,
                disband              = true,
                quick_search         = true,
                quick_handcuff       = true,
                quick_vehicle        = true,
                quick_radio          = true,
            },
        },
        {
            id   = 2,
            name = "Co-Leader",
            salary = 0,
            permissions = {
                invite               = true,
                kick                 = true,
                promote              = true,
                demote               = true,
                manage_bank          = false,
                withdraw             = true,
                deposit              = true,
                access_stash         = true,
                access_personal_stash = true,
                access_garage        = true,
                access_clothing      = true,
                manage_stash         = true,
                manage_vehicles      = true,
                manage_ranks         = false,
                manage_locations     = true,
                view_logs            = true,
                disband              = false,
                quick_search         = true,
                quick_handcuff       = true,
                quick_vehicle        = true,
                quick_radio          = true,
            },
        },
        {
            id   = 3,
            name = "Member",
            salary = 0,
            permissions = {
                invite               = false,
                kick                 = false,
                promote              = false,
                demote               = false,
                manage_bank          = false,
                withdraw             = false,
                deposit              = true,
                access_stash         = true,
                access_personal_stash = true,
                access_garage        = true,
                access_clothing      = true,
                manage_stash         = false,
                manage_vehicles      = false,
                manage_ranks         = false,
                manage_locations     = false,
                view_logs            = false,
                disband              = false,
                quick_search         = true,
                quick_handcuff       = true,
                quick_vehicle        = true,
                quick_radio          = true,
            },
        },
        {
            id   = 4,
            name = "Recruit",
            salary = 0,
            permissions = {
                invite               = false,
                kick                 = false,
                promote              = false,
                demote               = false,
                manage_bank          = false,
                withdraw             = false,
                deposit              = false,
                access_stash         = false,
                access_personal_stash = true,
                access_garage        = false,
                access_clothing      = false,
                manage_stash         = false,
                manage_vehicles      = false,
                manage_ranks         = false,
                manage_locations     = false,
                view_logs            = false,
                disband              = false,
                quick_search         = false,
                quick_handcuff       = false,
                quick_vehicle        = false,
                quick_radio          = false,
            },
        },
    },
}
