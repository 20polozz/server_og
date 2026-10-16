--[[
    ============================================================
    DRUG SALES SETTINGS
    ============================================================
    Controls the drug selling system: NPC customer spawns,
    police requirements, interaction rules, drug list with
    prices, blacklisted zones, animations, and debug options.
    ============================================================
--]]

Config.DrugSales = {
    -- Enable the drug sales system
    Enable = true,

    -- Enable street sales to nearby peds (passive sell mode)
    EnableStreetSale = true,

    -- Commands used to start and stop an active sell session
    Commands = {
        StartSell = 'startsell',
        StopSell  = 'stopsell',
    },

    -- Minimum number of police officers online required to allow drug sales
    CopRequired = 0,

    -- Duration in milliseconds that the police alert blip stays visible on the map
    CopAlertBlipTime = 200,

    -- Allow players with police jobs to sell drugs
    AllowPoliceToSell = false,

    -- Police alert triggers
    PoliceAlerts = {
        -- Trigger a police alert when a customer rejects the deal
        onReject = true,

        -- Trigger a police alert when a customer accepts the deal
        onAccept = {
            enabled    = true,
            percentage = 20, -- % chance of alerting police on a successful sale
        },
    },

    -- Jobs considered "police" for the CopRequired and AllowPoliceToSell checks
    PoliceJobs = {
        ['police'] = true,
        ['sheriff'] = true,
        ['sapd']   = true,
    },

    -- Maximum total customers a seller can have queued across all sessions
    MaxCustomer = 30,

    -- Maximum number of customers interacting with the seller at the same time
    MaxSimultaneousCustomers = 1,

    -- Percentage chance a customer will reject the deal
    RejectPercentage = 20,

    -- Time range in seconds before a new customer spawns and approaches
    CustomerSpawnTime = { min = 3, max = 7 },

    -- Seconds a customer waits for the seller to interact before leaving
    CustomerInteractionTime = 60,

    -- Priority queue settings for customers waiting their turn
    CustomerPriority = {
        enabled              = true,
        distanceThreshold    = 0.5,   -- meters: customers closer than this are in the "near" group
        priorityByArrival    = true,  -- earlier arrivals get served first
        showWaitingMessages  = true,  -- show queue position messages to waiting customers
        messageUpdateInterval = 0,
        fixedMessages        = true,
    },

    -- NPC ped models used as customers
    CustomerPeds = {
        's_m_y_doorman_01',
        'a_f_m_tourist_01',
        'a_m_m_eastsa_02',
        'a_m_m_polynesian_01',
        'ig_priest',
        'ig_ramp_hipster',
        'ig_rashcosvki',
        'ig_money',
        'ig_hunter',
    },

    -- Use black money (dirty money) as the currency for drug sales
    UseBlackMoney = true,

    -- ── STREET SALE ──────────────────────────────────────────────────────────
    -- Passive sell mode: nearby peds automatically approach and buy from the player.

    StreetSale = {
        Enable            = true,

        -- Maximum distance in meters a ped can be to trigger a street sale
        MaxDistance       = 6.0,

        -- Milliseconds between consecutive street sale attempts (anti-spam)
        CooldownTime      = 5000,

        -- Only allow ped NPCs (not player characters) to buy on the street
        OnlyPeds          = true,

        -- Exclude player-controlled peds from street sale targets
        ExcludePlayerPeds = true,

        -- Skip dead peds as sale targets
        IgnoreDeadPeds    = true,

        -- Price multiplier applied to drug prices during street sales
        PriceMultiplier   = 0.8,
    },

    -- ── DRUG LIST ────────────────────────────────────────────────────────────
    -- Each entry defines an item that can be sold.
    --   label    → display name shown in the interaction UI
    --   quantity → random range of units sold per transaction
    --   price    → random price range per unit (in $)
    --   prop     → world prop shown in the seller's hand during the exchange

    DrugList = {
        -- ['meth_bag'] = {
        --     label    = 'Bolsa de Metanfetamina',
        --     quantity = { min = 1, max = 2 },
        --     price    = { min = 200, max = 350 },
        --     prop     = 'prop_drug_package_02',
        -- },
        -- ['xtcbaggy'] = {
        --     label    = 'Ecstasy Bag',
        --     quantity = { min = 1, max = 3 },
        --     price    = { min = 150, max = 250 },
        --     prop     = 'prop_drug_package_02',
        -- },
        -- ['packaged_weed'] = {
        --     label    = 'Gram of Marijuana',
        --     quantity = { min = 1, max = 3 },
        --     price    = { min = 80, max = 150 },
        --     prop     = 'prop_weed_block_01',
        -- },
        -- -- Origin weed packages (by rarity) — entry-level drug, always priced lower
        -- ['weed_packed_common'] = {
        --     label    = 'Marijuana Pack (Common)',
        --     quantity = { min = 1, max = 5 },
        --     price    = { min = 45, max = 75 },
        --     prop     = 'prop_weed_block_01',
        -- },
        -- ['weed_packed_uncommon'] = {
        --     label    = 'Marijuana Pack (Uncommon)',
        --     quantity = { min = 1, max = 4 },
        --     price    = { min = 60, max = 95 },
        --     prop     = 'prop_weed_block_01',
        -- },
        -- ['weed_packed_rare'] = {
        --     label    = 'Marijuana Pack (Rare)',
        --     quantity = { min = 1, max = 4 },
        --     price    = { min = 80, max = 115 },
        --     prop     = 'prop_weed_block_01',
        -- },
        -- ['weed_packed_epic'] = {
        --     label    = 'Marijuana Pack (Epic)',
        --     quantity = { min = 1, max = 3 },
        --     price    = { min = 95, max = 130 },
        --     prop     = 'prop_weed_block_01',
        -- },
        -- ['weed_packed_legendary'] = {
        --     label    = 'Marijuana Pack (Legendary)',
        --     quantity = { min = 1, max = 3 },
        --     price    = { min = 110, max = 148 },
        --     prop     = 'prop_weed_block_01',
        -- },
        -- ['crack_baggy'] = {
        --     label    = 'Crack Bag',
        --     quantity = { min = 1, max = 2 },
        --     price    = { min = 180, max = 280 },
        --     prop     = 'prop_drug_package_02',
        -- },
        -- ['cokebaggy'] = {
        --     label    = 'Cocaine Bag',
        --     quantity = { min = 1, max = 2 },
        --     price    = { min = 250, max = 400 },
        --     prop     = 'prop_drug_package_02',
        -- },
    },

    -- ── BLACKLISTED ZONES ────────────────────────────────────────────────────
    -- Players cannot initiate drug sales within these areas.

    BlacklistedZones = {
        {
            name   = "Police Station",
            coords = vector3(425.1, -979.5, 30.7),
            radius = 100.0,
        },
        {
            name   = "Hospital",
            coords = vector3(298.7, -584.7, 43.2),
            radius = 100.0,
        },
        {
            name   = "Airport",
            coords = vector3(-1037.45, -2737.04, 20.17),
            radius = 400.0,
        },
    },

    -- Minimum distance in meters between active sell points
    MinDistanceBetweenSales = 50.0,

    -- Radius in meters defining the active sale area around the seller
    SaleRadius = 50.0,

    -- Sell point blip settings (visible on the minimap)
    BlipSettings = {
        enable = false,
    },

    -- ── CUSTOMER ESCAPE ──────────────────────────────────────────────────────
    -- If the seller does not interact in time, the customer flees.

    CustomerEscape = {
        enabled        = true,

        -- Milliseconds before the customer starts running away
        escapeTime     = 20000,

        -- Distance range in meters the customer runs before despawning
        escapeDistance = { min = 40, max = 60 },
    },

    -- ── ANIMATIONS ───────────────────────────────────────────────────────────

    Animations = {
        -- Phone call animation played when a customer contacts the seller
        phoneCall = {
            enabled    = true,
            duration   = 3000,
            phoneModel = "prop_npc_phone_02",
        },

        -- Hand exchange animation played during the transaction
        exchange = {
            enabled     = true,
            duration    = 3000,
            playerAnim  = "givetake1_a",
            npcAnim     = "givetake1_b",
        },
    },

    -- ── MESSAGE KEYS ─────────────────────────────────────────────────────────
    -- Locale keys used for customer response notifications

    Messages = {
        accepted = 'drug_sales.messages.accepted',
        rejected = 'drug_sales.messages.rejected',
        waiting  = 'drug_sales.messages.waiting',
    },

    -- ── DEBUG ────────────────────────────────────────────────────────────────

    Debug = {
        enabled              = false,
        showBlacklistedZones = true,
        showSaleRadius       = true,
        markerSettings       = {
            type          = 1,
            scale         = { x = 1.0, y = 1.0, z = 100.0 },
            color         = { r = 255, g = 0,   b = 0,   a = 100 },
            colorSaleRadius = { r = 0, g = 255, b = 0,   a = 100 },
        },
    },
}
