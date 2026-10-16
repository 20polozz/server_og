--[[
    ============================================================
    GRAFFITI REPUTATION SETTINGS
    ============================================================
    Defines how much reputation is earned or lost through the
    graffiti system. This is separate from Config.Graffiti,
    which controls placement mechanics.
    ============================================================
--]]

Config = Config or {}

Config.GraffitiReputation = {
    Enable = true,

    -- Reputation earned when placing a graffiti, based on territory type.
    --   Own:     Less rep  — you already dominate here, routine tagging
    --   Neutral: Normal rep — unclaimed territory, every tag counts
    --   Enemy:   More rep  — higher risk, higher reward (te arriesgas a que vengan)
    ReputationByType = {
        Own     = 1.0,
        Neutral = 2.5,
        Enemy   = 6.0,
    },

    -- Additional reputation penalty applied to the owning gang when
    -- an enemy tags over their graffiti.
    -- Example: 4 tags × 2.0 = -8 pts por sesión enemiga
    PenaltyToEnemy = 2.0,

    -- Deduct reputation when a player removes their own graffiti.
    -- Discourages spam: place-and-remove loops to exploit the system.
    RemoveGraffitiPenalty = true,

    -- Maximum number of graffiti placements that award reputation
    -- within the rolling time window defined by Cooldown.
    -- Example: 4 graffiti × 6 pts = 24 pts max por ventana de 2h
    MaxGraffitisPerHour = 4,

    -- Rolling time window in minutes for the rate limit (2 hours between sessions)
    Cooldown = 120,

    -- Reputation your gang earns when removing an ENEMY graffiti (retaliation bonus)
    -- Alto porque arriesgarse a borrar un grafiti en zona hostil tiene recompensa
    RetaliationRep = 3.0,
}
