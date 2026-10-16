--[[
    ============================================================
    WEED LAB — FULL CONFIGURATION
    ============================================================
    Complete marijuana production system inside the
    'weed' type laboratory.

    FULL FLOW:
      STEP 0 — Plants inside the lab (14 bkr_prop_weed_lrg_01b props)
               Pick each plant with a progress bar → receive wetcannabis × 1.
               The plant disappears and respawns after PlantRespawnTime seconds.

      STEP 1 — 4 independent and simultaneous drying spots.
               Place 1 wetcannabis in each spot → a drying prop appears.
               After DryTime ms, the prop is ready to collect.
               On collect, you receive drycannabis × 1.

      STEP 2 — Grind at the lab grinder.
               You must have weedgrinder in inventory (not consumed).
               Consumes drycannabis × 1 → gives grindedweed × 1.

      STEP 3 — Bagging.
               Consumes grindedweed × 1 + bluntwrap × 1 → gives blunt × 1.

    NOTE: Steps 1-3 are independent from each other — there is no mandatory sequence.
          You only need to have the required input item in inventory.
    ============================================================
--]]

Config.LabWeed = {

    -- ── Enabled ───────────────────────────────────────────────────────────────
    Enabled = true,

    -- ── Interaction Distances ─────────────────────────────────────────────────
    Interactions = {
        PointDistance    = 40.0,   -- lib.points radius (starts rendering here)
        DrawDistance     = 8.0,    -- distance to draw the marker
        InteractDistance = 1.8,    -- distance to show HelpText and [E]
        PlantPickupDist  = 3.0,    -- max distance to collect plant (server)
        DryPickupDist    = 3.0,    -- max distance to collect from drying spot (server)
        GrinderDist      = 3.0,    -- max distance to use grinder (server)
        BagDist          = 3.0,    -- max distance to bag product (server)
    },

    -- ── Timers ────────────────────────────────────────────────────────────────
    Timers = {
        PlantPickup  = 4000,    -- progress-bar ms to collect one plant
        DryWait      = 30000,   -- ms to finish drying (30s for testing, increase in production)
        GrindWeed    = 6000,    -- progress-bar ms to grind
        BagWeed      = 5000,    -- progress-bar ms to bag
    },

    -- ── Plant Respawn ──────────────────────────────────────────────────────────
    PlantRespawnTime = 100,     -- seconds until a collected plant respawns

    -- ── MARKERS ───────────────────────────────────────────────────────────────
    Markers = {
        -- Live plants (interactive)
        -- z offset +2.0 to compensate for the prop pivot being on top (z=-42.70)
        -- and the visual floor being ~2 units higher
        plant = {
            type          = 22,
            offset        = { x = 0.0, y = 0.0, z = 4.0 },
            scale         = { x = 0.25, y = 0.25, z = 0.25 },
            color         = { r = 0,   g = 0, b = 0,   a = 160 },
            bobUpAndDown  = true,
            faceCamera    = true,
            rotationOrder = 2,
            rotate        = false,
        },
        -- Drying spots (available to place)
        dry_spot = {
            type          = 22,
            offset        = { x = 0.0, y = 0.0, z = 0.0 },
            scale         = { x = 0.25, y = 0.25, z = 0.25 },
            color         = { r = 0,  g = 0, b = 0,  a = 180 },
            bobUpAndDown  = true,
            faceCamera    = true,
            rotationOrder = 2,
            rotate        = false,
        },
        -- Drying spots with plant ready to collect
        dry_ready = {
            type          = 22,
            offset        = { x = 0.0, y = 0.0, z = 0.0 },
            scale         = { x = 0.25, y = 0.25, z = 0.25 },
            color         = { r = 0, g = 0, b = 0,   a = 200 },
            bobUpAndDown  = true,
            faceCamera    = true,
            rotationOrder = 2,
            rotate        = false,
        },
        -- Grinder
        grinder = {
            type          = 22,
            offset        = { x = 0.0, y = 0.0, z = 0.0 },
            scale         = { x = 0.25, y = 0.25, z = 0.25 },
            color         = { r = 0, g = 0, b = 0,  a = 180 },
            bobUpAndDown  = true,
            faceCamera    = true,
            rotationOrder = 2,
            rotate        = false,
        },
        -- Bagger
        bagger = {
            type          = 22,
            offset        = { x = 0.0, y = 0.0, z = 0.0 },
            scale         = { x = 0.25, y = 0.25, z = 0.25 },
            color         = { r = 0, g = 0, b = 0, a = 180 },
            bobUpAndDown  = true,
            faceCamera    = true,
            rotationOrder = 2,
            rotate        = false,
        },
    },

    -- ── Plants ────────────────────────────────────────────────────────────────
    -- Exact coordinates from md-drugs (plantSpawns.lua — plants.weed)
    -- Model: bkr_prop_weed_lrg_01b
    Plants = {
        { location = vector3(1064.84, -3199.84, -42.70), heading = 334.49 },
        { location = vector3(1063.88, -3198.69, -42.70), heading = 329.56 },
        { location = vector3(1061.68, -3196.46, -42.70), heading = 25.16  },
        { location = vector3(1061.62, -3199.63, -42.70), heading = 21.52  },
        { location = vector3(1062.82, -3197.70, -42.70), heading = 202.97 },
        { location = vector3(1064.69, -3196.31, -42.70), heading = 202.97 },
        { location = vector3(1062.92, -3198.78, -42.70), heading = 202.97 },
        { location = vector3(1049.73, -3201.92, -42.70), heading = 202.97 },
        { location = vector3(1052.94, -3202.21, -42.70), heading = 202.97 },
        { location = vector3(1051.93, -3201.17, -42.70), heading = 202.97 },
        { location = vector3(1050.98, -3201.13, -42.70), heading = 202.97 },
        { location = vector3(1050.89, -3200.07, -42.70), heading = 202.97 },
        { location = vector3(1050.89, -3198.95, -42.70), heading = 202.97 },
        { location = vector3(1049.72, -3198.95, -42.70), heading = 202.97 },
    },
    PlantModel = 'bkr_prop_weed_lrg_01b',

    -- ── Drying Spots ───────────────────────────────────────────────────────────
    -- 4 independent and simultaneous spots (md-drugs WeedDry)
    DryCoordsModel = 'bkr_prop_weed_drying_01a',
    DrySpots = {
        vector3(1039.05, -3192.04, -38.17),
        vector3(1041.04, -3192.19, -37.91),
        vector3(1043.09, -3192.32, -37.91),
        vector3(1044.96, -3192.29, -37.91),
    },

    -- ── Processing Stations ────────────────────────────────────────────────────
    -- Grinder (grind drycannabis → grindedweed)
    GrinderCoord = vector3(1045.43, -3198.75, -38.15),
    -- Bagger (grindedweed + bluntwrap → blunt)
    BaggerCoord  = vector3(1038.8,  -3198.68, -38.17),

    -- ── Recipes ────────────────────────────────────────────────────────────────
    Recipe = {
        -- Plant → wetcannabis
        plant = {
            outputs = { { item = 'wetcannabis', amount = 1 } },
        },
        -- Dry → drycannabis (wetcannabis is consumed on placement)
        dry = {
            inputs  = { { item = 'wetcannabis', amount = 1 } },
            outputs = { { item = 'drycannabis', amount = 1 } },
        },
        -- Grind → grindedweed (weedgrinder required, not consumed)
        grind = {
            inputs   = { { item = 'drycannabis', amount = 1 } },
            requires = { { item = 'weedgrinder', amount = 1 } },
            outputs  = { { item = 'grindedweed', amount = 1 } },
        },
        -- Bag → blunt
        bag = {
            inputs  = {
                { item = 'grindedweed', amount = 1 },
                { item = 'bluntwrap',   amount = 1 },
            },
            outputs = { { item = 'blunt', amount = 1 } },
        },
    },

    -- ── Animations ─────────────────────────────────────────────────────────────
    Animations = {
        -- Collect plant
        pick_plant = {
            networked = false,
            dict      = "anim@amb@business@weed@weed_inspecting_lo_med_hi@",
            clip      = "weed_stand_checkingleaves_idle_01_inspector",
            flag      = 49,
            blendIn   = 4.0,
            blendOut  = -8.0,
            freeze    = false,
        },
        -- Grind
        grind_weed = {
            networked = false,
            dict      = "anim@amb@business@weed@weed_inspecting_lo_med_hi@",
            clip      = "weed_stand_checkingleaves_idle_01_inspector",
            flag      = 49,
            blendIn   = 4.0,
            blendOut  = -8.0,
            freeze    = false,
        },
        -- Bagging: md-drugs has no synced scene for weed, only progress bar.
        -- Same inspection animation already loaded in this interior.
        bag_weed = {
            networked = false,
            dict      = "anim@amb@business@weed@weed_inspecting_lo_med_hi@",
            clip      = "weed_stand_checkingleaves_idle_01_inspector",
            flag      = 49,
            blendIn   = 4.0,
            blendOut  = -8.0,
            freeze    = false,
        },
    },
}
