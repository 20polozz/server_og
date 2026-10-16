--[[
    ============================================================
    COKE LAB — FULL CONFIGURATION
    ============================================================
    Controls the full cocaine production experience
    inside the 'coke' type laboratory.

    PROCESS STAGES:
      1. make_powder  → Process coca leaves into base powder (consumes coca_leaf).
      2. cut_coke     → Cut powder with baking soda (consumes coke + bakingsoda).
      3. bag_coke     → Bag the final product (consumes loosecoke + empty_weed_bag,
                        gives cokebaggy).

    NOTES:
      - Coordinates were taken from the 'coke' lab interior (bob74_ipl).
      - Same pattern as lab_meth: lib.points + markers, no target.
      - Cooldown applies per lab_id + player after completing one cycle.
    ============================================================
--]]

Config.LabCoke = {

    -- ── Enabled ───────────────────────────────────────────────────────────────
    Enabled = true,

    -- ── Stages (orden de producción) ──────────────────────────────────────────
    -- Usado por LabProcessRunner para generar los puntos, callbacks y secuencia.
    -- El orden del array ES el orden de ejecución obligatorio.
    -- label_key: sufijo de locale para el texto de la progress bar (notify.coke_{label_key})
    Stages = {
        -- label_key:  sufijo de locale para la progress bar  → notify.coke_{label_key}
        -- help_key:   sufijo de locale para el HelpText      → notify.coke_help_{help_key}
        --             (si se omite, usa label_key)
        -- done_key:   sufijo de locale para la notif de etapa completada → notify.coke_{done_key}
        --             (si se omite, usa label_key + '_done'; el último stage usa done_key + arg amount)
        { id = 'make_powder', label_key = 'making_powder', help_key = 'powder', done_key = 'powder_done', timer = 10000 },
        { id = 'cut_coke',    label_key = 'cutting',       help_key = 'cut',    done_key = 'cut_done',    timer = 12000 },
        { id = 'bag_coke',    label_key = 'bagging',       help_key = 'bag',    done_key = 'bag_done',    timer = 8000  },
    },

    -- ── Cooldown Between Full Cycles (ms) ─────────────────────────────────────
    ProductionCooldown = 600000,  -- 10 minutes

    -- ── Interaction Distances ─────────────────────────────────────────────────
    Interactions = {
        PointDistance    = 40.0,
        DrawDistance     = 8.0,
        InteractDistance = 1.8,
    },

    -- ── Markers Per Stage ─────────────────────────────────────────────────────
    Markers = {
        make_powder = {
            type         = 22,
            offset       = { x = 0.0, y = 0.0, z = 0.0 },
            scale        = { x = 0.25, y = 0.25, z = 0.25 },
            color        = { r = 0, g = 0, b = 0, a = 180 },
            bobUpAndDown = true,
            faceCamera   = true,
            rotationOrder = 2,
            rotate       = false,
        },
        cut_coke = {
            type         = 22,
            offset       = { x = 0.0, y = 0.0, z = 0.0 },
            scale        = { x = 0.25, y = 0.25, z = 0.25 },
            color        = { r = 0, g = 0, b = 0, a = 180 },
            bobUpAndDown = true,
            faceCamera   = true,
            rotationOrder = 2,
            rotate       = false,
        },
        bag_coke = {
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
    -- Taken from md-drugs (Config.Cocaine.Locations).
    Coords = {
        make_powder = vector3(1087.17, -3197.33, -38.99),
        cut_coke    = vector3(1095.61, -3195.62, -39.13),
        bag_coke    = vector3(1093.16, -3195.78, -39.19),
    },

    -- ── Timers Per Stage (ms) ─────────────────────────────────────────────────
    Timers = {
        make_powder = 10000,  -- 10 seconds to process powder
        cut_coke    = 12000,  -- 12 seconds to cut
        bag_coke    = 8000,   -- 8 seconds to bag
    },

    -- ── Recipes ────────────────────────────────────────────────────────────────
    -- make_powder → consume coca_leaf, produce coke
    -- cut_coke    → consume coke + bakingsoda, produce loosecoke
    -- bag_coke    → consume loosecoke + empty_weed_bag, produce cokebaggy
    Recipe = {
        make_powder = {
            inputs  = { { item = 'coca_leaf',  amount = 1 } },
            outputs = { { item = 'coke',        amount = 1 } },
        },
        cut_coke = {
            inputs  = {
                { item = 'coke',       amount = 1 },
                { item = 'bakingsoda', amount = 1 },
            },
            outputs = { { item = 'loosecoke', amount = 1 } },
        },
        bag_coke = {
            inputs  = {
                { item = 'loosecoke',     amount = 1 },
                { item = 'empty_weed_bag', amount = 1 },
            },
            outputs = { { item = 'cokebaggy', amount = 1 } },
        },
    },

    -- ── Animations Per Stage ──────────────────────────────────────────────────
    Animations = {
        -- Process powder: md-drugs had no dedicated animation for this stage.
        -- REPLACE dict and clip with your preferred animation.
        make_powder = {
            networked = false,
            dict      = "anim@amb@business@coc@coc_unpack_cut_left@",
            clip      = "coke_cut_v5_coccutter",
            flag      = 49,
            blendIn   = 4.0,
            blendOut  = -8.0,
            freeze    = false,
        },
        -- Cut cocaine: synchronized scene with cutting props
        cut_coke = {
            networked = true,
            dict      = "anim@amb@business@coc@coc_unpack_cut_left@",
            clip      = "coke_cut_v5_coccutter",
            flag      = 49,
            blendIn   = 1.5,
            blendOut  = -4.0,
            freeze    = true,
            offset    = vector3(-1.782227, 0.445068, -0.502701),
            rotation  = vector3(0.0, 0.0, 0.0),
            objects   = {
                { hash = "bkr_prop_coke_bakingsoda_o", clip = "coke_cut_v5_bakingsoda"  },
                { hash = "prop_cs_credit_card",        clip = "coke_cut_v5_creditcard"  },
                { hash = "prop_cs_credit_card",        clip = "coke_cut_v5_creditcard^1"},
            },
        },
        -- Bagging: synchronized scene with bags and scale (same as meth bag)
        bag_coke = {
            networked = true,
            dict      = "anim@amb@business@meth@meth_smash_weight_check@",
            clip      = "break_weigh_char01",
            flag      = 49,
            blendIn   = 1.5,
            blendOut  = -4.0,
            freeze    = true,
            offset    = vector3(4.515137, 2.542969, -0.814194),
            rotation  = vector3(0.0, 0.0, 180.0),
            objects   = {
                { hash = "bkr_prop_coke_cutblock_01",     clip = "break_weigh_box01"    },
                { hash = "bkr_prop_coke_fullmetalbowl_02",clip = "break_weigh_box01^1"  },
                { hash = "xm3_prop_xm3_bag_coke_01a",     clip = "break_weigh_methbag01"},
                { hash = "bkr_prop_coke_fullscoop_01a",   clip = "break_weigh_scoop"    },
                { hash = "bkr_prop_coke_scale_01",        clip = "break_weigh_scale"    },
            },
        },
    },
}
