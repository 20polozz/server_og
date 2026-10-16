--[[
    ============================================================
    TERRITORIES SETTINGS
    ============================================================
    Controls all territory-related mechanics: presence system,
    reputation gain/decay, drug sale bonuses, passive income
    rewards, capture rules, and death penalties.
    ============================================================
--]]

Config.Territories = {

    -- ── PRESENCE SYSTEM ─────────────────────────────────────────────────────
    -- Awards reputation to gangs that maintain a physical presence in a zone.

    Presence = {
        Enable = true,

        -- How often (in minutes) presence is checked and reputation awarded
        CheckInterval = 15,

        -- Minimum consecutive minutes a member must be in the zone to count
        RequiredTimeInZone = 8,

        -- Minimum number of members from the same gang required in the zone
        MinPlayersRequired = 2,

        -- Base reputation awarded per presence cycle
        ReputationPerCycle = 3.0,

        -- Maximum number of players that scale the reputation bonus
        MaxPlayersCount = 5,

        -- Scale reputation reward based on how many members are in the zone
        ScaleWithPlayers = true,

        -- Extra reputation per additional player beyond the minimum (max +1.5 with 5 players)
        BonusPerExtraPlayer = 0.5,

        -- All players counted must belong to the same gang
        RequireSameGang = true,

        -- Maximum distance from territory center a player can be to count as present
        MaxDistanceFromCenter = 150.0,

        -- Notify gang members when they earn reputation from presence
        NotifyGainReputation = true,

        -- Notify when territory control changes hands
        NotifyControlChange = true,

        -- Prevent presence reputation if enemy gang members are nearby
        PreventIfEnemiesPresent = false,

        -- Radius in meters used to detect enemy players nearby
        EnemyDetectionRadius = 100.0,

        -- ── DECAY ────────────────────────────────────────────────────────────
        -- When no gang member is present, the territory slowly loses reputation.
        --
        -- Example with defaults (DecayAmount = 0.15, DecayInterval = 20 min):
        --   ~0.45 pts/hour → ~10.8 pts/day without any presence.
        --   A territory at 100% takes ~9 days to decay to 0.
        --   A territory at 40% takes ~3.7 days to decay to 0.
        --   1 hour/day of presence (3 pts/cycle × 4 = 12 pts) easily compensates.

        DecayWhenNoPresence = true,

        -- Reputation points lost per decay tick
        DecayAmount = 0.15,

        -- Minutes between each decay tick
        DecayInterval = 20,
    },

    -- ── DRUG SALE REPUTATION ─────────────────────────────────────────────────
    -- Reputation earned when gang members sell drugs inside a territory.

    DrugSales = {
        Enable = true,

        -- Reputation earned per successful drug sale inside a territory
        ReputationPerSale = 1.5,

        -- Restrict reputation gain to sales inside your own controlled territory
        OnlyInGangTerritory = false,

        -- Only gang members earn territory reputation (non-members are ignored)
        RequireGangMembership = true,

        -- Minimum seconds between sales that count for reputation (anti-spam)
        AntispamTime = 0.5,

        -- Maximum number of sales that award reputation per hour per gang
        MaxSalesPerHour = 8,

        -- Notify the selling player when they earn territory reputation
        NotifyReputationGain = true,

        -- Reputation multiplier when selling in your OWN territory (easier = less reward)
        BonusForOwnTerritory = 1.5,

        -- Reputation multiplier when selling in ENEMY territory (riskier = less gain for you)
        PenaltyForEnemyTerritory = 0.5,

        -- ── MONEY MULTIPLIERS BY TERRITORY TYPE ──────────────────────────────
        -- Selling in enemy territory → more money (higher risk)
        MoneyInEnemyTerritory = 1.35, -- +35% of the calculated client price

        -- Selling in own territory → less money (comfort of home turf)
        MoneyInOwnTerritory = 0.75, -- -25% of the calculated client price

        -- Reputation penalty applied to the territory owner when an enemy sells there
        PenaltyToEnemy = 0.3,

        -- Notify the owning gang when an enemy sells in their territory
        NotifyOwnerOnSale = true,

        -- Cooldown in seconds between owner notifications, per gang per territory.
        -- Prevents notification spam if an enemy sells multiple times in a row.
        NotifyOwnerCooldown = 300, -- 1 notification per 5 minutes max
    },

    -- ── PASSIVE INCOME ───────────────────────────────────────────────────────
    -- Gangs that control a territory receive automatic money over time.

    Rewards = {
        Enable = false,

        -- Minutes between each passive income payout
        Interval = 30,

        -- Money paid per controlled territory per payout cycle
        MoneyPerTerritory = 500,

        -- Notify the gang when a passive income reward is distributed
        NotifyGang = true,
    },

    -- ── THREAT THRESHOLD ─────────────────────────────────────────────────────
    -- If the controlling gang's dominance drops below this percentage,
    -- a threat alert is sent to the gang.
    ThreatThreshold = 60,

    -- ── STABILIZATION ────────────────────────────────────────────────────────
    -- Hours a territory stays locked after changing ownership.
    -- Prevents rapid back-and-forth "ping-pong" captures between gangs.
    StabilizationHours = 2,

    -- ── CAPTURE RULES ────────────────────────────────────────────────────────
    -- Conditions required for a gang to claim control of a territory.

    Capture = {
        -- Minimum reputation your gang must hold in a territory to control it.
        -- With slow decay, reaching this requires sustained multi-day sessions.
        MinRepToCapture = 40,

        -- Maximum number of territories a gang can control simultaneously.
        -- The gang's home base does NOT count toward this limit.
        -- Set to 0 to disable the cap.
        MaxTerritoriesPerGang = 10,

        -- Hours a gang must wait before capturing another territory.
        -- After taking one territory, they cannot take another until this expires.
        -- Set to 0 to disable the cooldown between captures.
        CaptureGangCooldownHours = 24,
    },

    -- ── WAR TERRITORY ─────────────────────────────────────────────────────────
    -- To push the defending gang's reputation BELOW 50%, the defending gang must
    -- have at least WarMinDefenders members online. If they don't, the rep gain
    -- that would cross that threshold is blocked for this cycle.
    -- Attackers are notified why they're blocked; defenders are notified when
    -- their territory is actively under attack (with a cooldown to avoid spam).
    -- Set to 0 to disable this mechanic entirely.
    WarMinDefenders = 3,

    -- Duration in minutes for active territory war once it starts.
    WarDurationMinutes = 30,

    -- Cooldown in seconds between "territory under attack" notifications
    -- sent to the defending gang. Prevents notification spam.
    WarAttackNotifyCooldown = 300,

    -- ── DEATH PENALTY ────────────────────────────────────────────────────────
    -- Reputation lost when a gang member dies in an active enemy territory.

    DeathPenalty = {
        Enable = true,

        -- Reputation points lost upon death in enemy territory
        ReputationLoss = 1.5,

        -- Per-player cooldown in seconds (prevents abuse from repeated deaths)
        PlayerCooldown = 600,
    },
}
