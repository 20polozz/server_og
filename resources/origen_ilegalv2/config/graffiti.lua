--[[
    ============================================================
    GRAFFITI SETTINGS
    ============================================================
    Controls the internal graffiti system (spray placement,
    cleaning, police alerts). The external standalone graffiti
    system (graffiti_external.lua) operates independently and
    is NOT affected by disabling this block.
    ============================================================
--]]

Config.Graffiti = {
    -- Enable or disable the INTERNAL graffiti system.
    -- When false: spray_can, cleaning_rag, NUI editor, placement and
    -- the manager are all disabled. The external system still works.
    Enable = false,

    -- Item required to open the graffiti editor. Consumed on placement.
    SprayItem   = 'graffiti_spray',

    -- Item required to start a clean-up. Consumed on completion.
    CleanerItem = 'graffiti_eraser',

    -- Time in milliseconds to place a graffiti
    SprayDuration = 10000, -- 10 seconds

    -- Time in milliseconds to clean a graffiti
    CleanDuration = 5000,  -- 5 seconds

    -- Police alert triggered when someone starts spraying
    PoliceAlert = {
        Enable = true,

        -- Probability (%) that police will be alerted when spraying begins
        Chance = 40,

        -- Delay in milliseconds before the witness calls the police
        -- (simulates realistic reaction time)
        Delay = 12000, -- 12 seconds

        -- Jobs that receive the dispatch alert
        Jobs = { 'police', 'sheriff' },
    },
}
