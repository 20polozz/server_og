--[[
    ============================================================
    METH LAB — FULL CONFIGURATION
    ============================================================
    Controls the full methamphetamine production experience
    inside the 'meth' type laboratory.

    REQUIREMENTS:
      - 'meth' type lab created from the admin panel.
      - Inventory items: ephedrine, acetone, empty_weed_bag, methbags.

    PROCESS STAGES:
      1. cook       → Mix ephedrine + acetone in the cooker (consumes items).
      2. heat_dials → Adjust dials to heat the mixture.
      3. grab_tray  → Take the tray with crystallized product.
      4. smash      → Crush the product at another station.
      5. bag        → Bag the final product (gives methbags).

    NOTES:
      - All points are INTERIOR coordinates of the lab (inside the bucket).
      - The same lab instance shares state per player (not global).
      - Reuse cooldown applies per lab_id + player.
    ============================================================
--]]

Config.LabMeth = {

    -- ── Enabled ───────────────────────────────────────────────────────────────
    -- Disabling this puts the lab in upgrades-only mode (door and laptop still work).
    Enabled = true,

    -- ── Stages (orden de producción) ──────────────────────────────────────────
    -- Usado por LabProcessRunner para generar los puntos, callbacks y secuencia.
    -- El orden del array ES el orden de ejecución obligatorio.
    -- label_key: sufijo de locale para el texto de la progress bar (notify.meth_{label_key})
    Stages = {
        -- label_key:  sufijo de locale para la progress bar  → notify.meth_{label_key}
        -- help_key:   sufijo de locale para el HelpText      → notify.meth_help_{help_key}
        --             (si se omite, usa label_key)
        -- done_key:   sufijo de locale para la notif de etapa completada → notify.meth_{done_key}
        --             (si se omite, usa label_key + '_done'; el último stage usa done_key + arg amount)
        { id = 'cook',       label_key = 'cooking',   help_key = 'cook',  done_key = 'cook_done',  timer = 12000 },
        { id = 'heat_dials', label_key = 'heating',   help_key = 'heat',  done_key = 'heat_done',  timer = 6000  },
        { id = 'grab_tray',  label_key = 'grab_tray', help_key = 'grab',  done_key = 'tray_grabbed', timer = 3000 },
        { id = 'smash',      label_key = 'smashing',  help_key = 'smash', done_key = 'smash_done', timer = 10000 },
        { id = 'bag',        label_key = 'bagging',   help_key = 'bag',   done_key = 'bag_done',   timer = 8000  },
    },

    -- ── Cooldown Between Full Production Cycles ───────────────────────────────
    -- Time in milliseconds a player must wait before starting another cycle
    -- after completing or canceling the previous one.
    ProductionCooldown = 600000,  -- 10 minutes

    -- ── Interaction Distances ─────────────────────────────────────────────────
    Interactions = {
        -- lib.points radius (point starts rendering within this radius)
        PointDistance  = 40.0,
        -- Distance at which the marker is drawn
        DrawDistance   = 8.0,
        -- Distance at which help text appears and [E] is enabled
        InteractDistance = 1.8,
    },

    -- ── Markers Per Stage ─────────────────────────────────────────────────────
    -- Each stage can have its own marker color and type.
    -- type: https://docs.fivem.net/docs/game-references/markers/
    Markers = {
        cook = {
            type         = 22,
            offset       = { x = 0.0, y = 0.0, z = 0.0 },
            scale        = { x = 0.25, y = 0.25, z = 0.25 },
            color        = { r = 0, g = 0, b = 0, a = 180 },
            bobUpAndDown = true,
            faceCamera   = true,
            rotationOrder = 2,
            rotate       = false,
        },
        heat_dials = {
            type         = 22,
            offset       = { x = 0.0, y = 0.0, z = 0.0 },
            scale        = { x = 0.25, y = 0.25, z = 0.25 },
            color        = { r = 0, g = 0, b = 0, a = 180 },
            bobUpAndDown = true,
            faceCamera   = true,
            rotationOrder = 2,
            rotate       = false,
        },
        grab_tray = {
            type         = 22,
            offset       = { x = 0.0, y = 0.0, z = 0.0 },
            scale        = { x = 0.25, y = 0.25, z = 0.25 },
            color        = { r = 0, g = 0, b = 0, a = 180 },
            bobUpAndDown = true,
            faceCamera   = true,
            rotationOrder = 2,
            rotate       = false,
        },
        smash = {
            type         = 22,
            offset       = { x = 0.0, y = 0.0, z = 0.0 },
            scale        = { x = 0.25, y = 0.25, z = 0.25 },
            color        = { r = 0, g = 0, b = 0, a = 180 },
            bobUpAndDown = true,
            faceCamera   = true,
            rotationOrder = 2,
            rotate       = false,
        },
        bag = {
            type         = 22,
            offset       = { x = 0.0, y = 0.0, z = 0.0 },
            scale        = { x = 0.25, y = 0.25, z = 0.25 },
            color        = { r = 0, g = 0, b = 0, a = 180 },
            bobUpAndDown = true,
            faceCamera   = true,
            rotationOrder = 2,
            rotate       = false,
        },
    },

    -- ── Interior Coordinates ───────────────────────────────────────────────────
    -- Taken from md-drugs. Adjust based on your in-game lab setup.
    -- Points are absolute interior coordinates (inside the routing bucket).
    Coords = {
        cook = vector3(1006.09, -3200.59, -38.52),
        heat_dials = vector3(1007.89, -3201.17, -38.99),
        grab_tray  = vector3(1006.09, -3200.59, -38.52),  -- same point as cook
        smash      = vector3(1012.04, -3194.96, -38.99),
        bag        = vector3(1014.25, -3194.93, -38.99),
    },

    -- ── Timers Per Stage (ms) ─────────────────────────────────────────────────
    -- Progress-bar + animation duration for each step.
    Timers = {
        cook       = 12000,  -- 12 seconds to mix
        heat_dials = 6000,   -- 6 seconds to adjust dials
        grab_tray  = 3000,   -- 3 seconds to grab the tray
        smash      = 10000,  -- 10 seconds to crush
        bag        = 8000,   -- 8 seconds to bag
    },

    -- ── Recipes ────────────────────────────────────────────────────────────────
    -- Split into two moments according to the real production flow:
    --   cook → consumes chemicals when STARTING the cook step
    --   bag  → consumes empty bags and gives product on BAGGING
    Recipe = {
        cook = {
            inputs = {
                { item = 'ephedrine', amount = 1 },
                { item = 'acetone',   amount = 1 },
            },
        },
        bag = {
            inputs = {
                { item = 'empty_weed_bag', amount = 5 },
            },
            outputs = {
                { item = 'methbags', amount = 5 },
            },
        },
    },

    -- ── Animations Per Stage ──────────────────────────────────────────────────
    -- md-drugs base animations, parameterized so client can adjust them.
    --
    -- FIELDS:
    --   dict      → animation AnimDict
    --   clip      → Clip name (animName)
    --   flag      → TaskPlayAnim flags (49 = synchronized looping)
    --   duration  → clip duration in ms (if nil, uses stage Timers value)
    --   blendIn   → blend-in speed
    --   blendOut  → blend-out speed
    --   freeze    → freezes ped during animation
    --   networked → use NetworkCreateSynchronisedScene (true) or TaskPlayAnim (false)
    --   objects   → list of props to spawn in the synchronized scene
    --     { hash, animName }
    --   offset    → scene offset vector3 (if networked = true)
    --   rotation  → scene rotation vector3
    --
    Animations = {
        cook = {
            networked = true,
            dict      = "anim@amb@business@meth@meth_monitoring_cooking@cooking@",
            clip      = "chemical_pour_short_cooker",
            flag      = 49,
            blendIn   = 1.5,
            blendOut  = -4.0,
            freeze    = true,
            offset    = vector3(4.79, 2.13, -0.41),
            rotation  = vector3(0.0, 0.0, 0.0),
            objects   = {
                { hash = "bkr_prop_meth_sacid",    clip = "chemical_pour_short_sacid"   },
                { hash = "bkr_prop_meth_ammonia",  clip = "chemical_pour_short_ammonia" },
            },
        },
        heat_dials = {
            networked = false,
            dict      = "anim@amb@business@meth@meth_monitoring_cooking@",
            clip      = "idle_a",
            flag      = 49,
            blendIn   = 4.0,
            blendOut  = -8.0,
            freeze    = false,
        },
        grab_tray = {
            networked = false,
            dict      = "anim@heists@box_carry@",
            clip      = "idle",
            flag      = 50,
            blendIn   = 5.0,
            blendOut  = -1.0,
            freeze    = false,
            prop      = {
                hash     = "bkr_prop_meth_tray_02a",
                bone     = 28422,   -- right hand
                pos      = vector3(0.01, -0.2, -0.2),
                rot      = vector3(20.0, 0.0, 0.0),
            },
        },
        smash = {
            networked = true,
            dict      = "anim@amb@business@meth@meth_smash_weight_check@",
            clip      = "break_weigh_char02",
            flag      = 49,
            blendIn   = 1.5,
            blendOut  = -4.0,
            freeze    = true,
            offset    = vector3(-3.143311, -1.666748, -1.010128),
            rotation  = vector3(0.0, 0.0, 0.0),
            objects   = {
                { hash = "w_me_hammer",                    clip = "break_weigh_hammer"      },
                { hash = "bkr_Prop_Meth_SmashedTray_01_frag_", clip = "break_weigh_tray01"  },
                { hash = "bkr_Prop_Meth_Tray_02a",        clip = "break_weigh_tray01^1"    },
            },
        },
        bag = {
            networked = true,
            dict      = "anim@amb@business@meth@meth_smash_weight_check@",
            clip      = "break_weigh_char01",
            flag      = 49,
            blendIn   = 1.5,
            blendOut  = -4.0,
            freeze    = true,
            offset    = vector3(-4.9, -1.70, -1.01),
            rotation  = vector3(0.0, 0.0, 0.0),
            objects   = {
                { hash = "bkr_prop_meth_bigbag_04a",  clip = "break_weigh_box01"       },
                { hash = "bkr_prop_meth_bigbag_03a",  clip = "break_weigh_box01^1"     },
                { hash = "bkr_prop_meth_openbag_02",  clip = "break_weigh_methbag01"   },
                { hash = "bkr_prop_meth_scoop_01a",   clip = "break_weigh_scoop"       },
                { hash = "bkr_prop_coke_scale_01",    clip = "break_weigh_scale"       },
            },
        },
    },
}
