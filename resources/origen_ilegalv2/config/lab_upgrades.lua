--[[
    ============================================================
    LAB UPGRADES CATALOG
    ============================================================
    Full catalog of upgrades per laboratory type.
    IPL variants are applied via ActivateInteriorEntitySet
    on the client (without depending on bob74_ipl directly).

    STRUCTURE OF EACH MODULE:
      module_key    → exclusive group key (e.g. 'style', 'security')
      label         → visible name on laptop
      icon          → lucide icon (for UI)
      exclusive     → true = only 1 active variant at a time in this module
      variants[]    → list of purchasable variants:
        variant_key  → unique key in DB
        label        → visible name
        price        → price in player money
        props_on     → entity sets to enable
        props_off    → entity sets to disable (from alternate variants)
        allowed_labs → (OPTIONAL) array of lab IDs where this variant can be bought.
                       If omitted or nil, the variant is available in ALL labs
                       of that type. Already purchased variants are always shown.
                       Example: allowed_labs = { 1, 3 }

    INTERIOR IDs (from bob74_ipl, used in RefreshInterior):
      meth         = 247041
      weed         = 247297
      coke         = 247553
      bunker       = 258561
      counterfeit  = 247809
    ============================================================
--]]

Config.LabUpgrades = {}

-- ─── METH LAB ────────────────────────────────────────────────────────────────
Config.LabUpgrades['meth'] = {
    interior_id = 247041,

    modules = {
        {
            module_key = 'style',
            label      = 'Lab equipment',
            icon       = 'flask-conical',
            exclusive  = true,
            variants   = {
                {
                    variant_key = 'style_empty',
                    label       = 'Unequipped',
                    price       = 0,
                    props_on    = { 'meth_lab_empty' },
                    props_off   = { 'meth_lab_basic', 'meth_lab_setup', 'meth_lab_upgrade' },
                    -- No gameplay: blocks startCook
                },
                {
                    variant_key = 'style_basic',
                    label       = 'Basic equipment',
                    price       = 45000,
                    props_on    = { 'meth_lab_basic', 'meth_lab_setup' },
                    props_off   = { 'meth_lab_empty', 'meth_lab_upgrade' },
                    gameplay    = {
                        process_time_mult  = 0.95,   -- 5% faster (times × 0.95)
                        output_bonus_pct   = 0,      -- no output bonus
                    },
                },
                {
                    variant_key = 'style_upgrade',
                    label       = 'Upgraded equipment',
                    price       = 120000,
                    props_on    = { 'meth_lab_upgrade', 'meth_lab_setup' },
                    props_off   = { 'meth_lab_empty', 'meth_lab_basic' },
                    gameplay    = {
                        process_time_mult  = 0.80,   -- 20% faster (stacks with basic if applicable)
                        output_bonus_pct   = 15,     -- 15% chance of +1 extra batch on completeBag
                    },
                },
            },
        },
        {
            module_key = 'security',
            label      = 'Security',
            icon       = 'shield',
            exclusive  = true,
            variants   = {
                {
                    variant_key = 'security_none',
                    label       = 'No security',
                    price       = 0,
                    props_on    = {},
                    props_off   = { 'meth_lab_security_high' },
                },
                {
                    variant_key = 'security_high',
                    label       = 'High security',
                    price       = 80000,
                    props_on    = { 'meth_lab_security_high' },
                    props_off   = {},
                },
            },
        },
        {
            module_key = 'production',
            label      = 'Visible production',
            icon       = 'zap',
            exclusive  = false,  -- independent toggle
            variants   = {
                {
                    variant_key = 'production_on',
                    label       = 'Show production',
                    price       = 15000,
                    props_on    = { 'meth_lab_production' },
                    props_off   = {},
                },
            },
        },
    },
}

-- ─── WEED FARM ───────────────────────────────────────────────────────────────
Config.LabUpgrades['weed'] = {
    interior_id = 247297,

    modules = {
        {
            module_key = 'style',
            label      = 'Equipment',
            icon       = 'flask-conical',
            exclusive  = true,
            variants   = {
                {
                    variant_key = 'style_basic',
                    label       = 'Basic equipment',
                    price       = 40000,
                    props_on    = { 'weed_standard_equip' },
                    props_off   = { 'weed_upgrade_equip' },
                    gameplay    = {
                        process_time_mult = 0.90,   -- 10% faster processing
                        output_bonus_pct  = 0,
                    },
                },
                {
                    variant_key = 'style_upgrade',
                    label       = 'Upgraded equipment',
                    price       = 95000,
                    props_on    = { 'weed_upgrade_equip' },
                    props_off   = { 'weed_standard_equip' },
                    gameplay    = {
                        process_time_mult = 0.80,   -- 20% faster (stacks with basic: 0.90 × 0.80 = 0.72, cap 0.70)
                        output_bonus_pct  = 0,
                    },
                },
            },
        },
        {
            module_key = 'security',
            label      = 'Security',
            icon       = 'shield',
            exclusive  = true,
            variants   = {
                {
                    variant_key = 'security_basic',
                    label       = 'Basic security',
                    price       = 25000,
                    props_on    = { 'weed_low_security' },
                    props_off   = { 'weed_security_upgrade' },
                },
                {
                    variant_key = 'security_upgrade',
                    label       = 'Upgraded security',
                    price       = 70000,
                    props_on    = { 'weed_security_upgrade' },
                    props_off   = { 'weed_low_security' },
                },
            },
        },
        {
            module_key = 'details',
            label      = 'Lab details',
            icon       = 'layers',
            exclusive  = false,
            variants   = {
                {
                    variant_key = 'fans_setup',
                    label       = 'Fans and molds',
                    price       = 12000,
                    props_on    = { 'weed_set_up' },
                    props_off   = {},
                },
                {
                    variant_key = 'production_tables',
                    label       = 'Production tables',
                    price       = 18000,
                    props_on    = { 'weed_production' },
                    props_off   = {},
                },
                {
                    variant_key = 'drying_weed',
                    label       = 'Ceiling drying',
                    price       = 10000,
                    props_on    = { 'weed_drying' },
                    props_off   = {},
                },
                {
                    variant_key = 'chairs',
                    label       = 'Chairs at tables',
                    price       = 5000,
                    props_on    = { 'weed_chairs' },
                    props_off   = {},
                },
            },
        },
        -- Plants: each one is an independent 3-stage module + light + hose
        -- {
        --     module_key = 'plant_1_stage',
        --     label      = 'Plant 1 — Stage',
        --     icon       = 'sprout',
        --     exclusive  = true,
        --     variants   = {
        --         { variant_key = 'plant1_small',  label = 'Small',  price = 8000,  props_on = { 'weed_growtha_stage1' }, props_off = { 'weed_growtha_stage2', 'weed_growtha_stage3' } },
        --         { variant_key = 'plant1_medium', label = 'Medium', price = 14000, props_on = { 'weed_growtha_stage2' }, props_off = { 'weed_growtha_stage1', 'weed_growtha_stage3' } },
        --         { variant_key = 'plant1_full',   label = 'Full',   price = 22000, props_on = { 'weed_growtha_stage3' }, props_off = { 'weed_growtha_stage1', 'weed_growtha_stage2' } },
        --     },
        -- },
        {
            module_key = 'plant_1_light',
            label      = 'Plant 1 — Lighting',
            icon       = 'lightbulb',
            exclusive  = true,
            variants   = {
                { variant_key = 'plant1_light_basic',   label = 'Basic lighting',    price = 6000,  props_on = { 'light_growtha_stage23_standard' }, props_off = { 'light_growtha_stage23_upgrade' } },
                { variant_key = 'plant1_light_upgrade', label = 'Upgraded lighting',  price = 18000, props_on = { 'light_growtha_stage23_upgrade' },  props_off = { 'light_growtha_stage23_standard' } },
            },
        },
        {
            module_key = 'plant_1_hose',
            label      = 'Plant 1 — Hose',
            icon       = 'droplets',
            exclusive  = false,
            variants   = {
                { variant_key = 'plant1_hose', label = 'Install hose', price = 4000, props_on = { 'weed_hosea' }, props_off = {} },
            },
        },
        -- {
        --     module_key = 'plant_2_stage',
        --     label      = 'Plant 2 — Stage',
        --     icon       = 'sprout',
        --     exclusive  = true,
        --     variants   = {
        --         { variant_key = 'plant2_small',  label = 'Small',  price = 8000,  props_on = { 'weed_growthb_stage1' }, props_off = { 'weed_growthb_stage2', 'weed_growthb_stage3' } },
        --         { variant_key = 'plant2_medium', label = 'Medium', price = 14000, props_on = { 'weed_growthb_stage2' }, props_off = { 'weed_growthb_stage1', 'weed_growthb_stage3' } },
        --         { variant_key = 'plant2_full',   label = 'Full',   price = 22000, props_on = { 'weed_growthb_stage3' }, props_off = { 'weed_growthb_stage1', 'weed_growthb_stage2' } },
        --     },
        -- },
        {
            module_key = 'plant_2_light',
            label      = 'Plant 2 — Lighting',
            icon       = 'lightbulb',
            exclusive  = true,
            variants   = {
                { variant_key = 'plant2_light_basic',   label = 'Basic lighting',   price = 6000,  props_on = { 'light_growthb_stage23_standard' }, props_off = { 'light_growthb_stage23_upgrade' } },
                { variant_key = 'plant2_light_upgrade', label = 'Upgraded lighting', price = 18000, props_on = { 'light_growthb_stage23_upgrade' },  props_off = { 'light_growthb_stage23_standard' } },
            },
        },
        {
            module_key = 'plant_2_hose',
            label      = 'Plant 2 — Hose',
            icon       = 'droplets',
            exclusive  = false,
            variants   = {
                { variant_key = 'plant2_hose', label = 'Install hose', price = 4000, props_on = { 'weed_hoseb' }, props_off = {} },
            },
        },
        -- {
        --     module_key = 'plant_3_stage',
        --     label      = 'Plant 3 — Stage',
        --     icon       = 'sprout',
        --     exclusive  = true,
        --     variants   = {
        --         { variant_key = 'plant3_small',  label = 'Small',  price = 8000,  props_on = { 'weed_growthc_stage1' }, props_off = { 'weed_growthc_stage2', 'weed_growthc_stage3' } },
        --         { variant_key = 'plant3_medium', label = 'Medium', price = 14000, props_on = { 'weed_growthc_stage2' }, props_off = { 'weed_growthc_stage1', 'weed_growthc_stage3' } },
        --         { variant_key = 'plant3_full',   label = 'Full',   price = 22000, props_on = { 'weed_growthc_stage3' }, props_off = { 'weed_growthc_stage1', 'weed_growthc_stage2' } },
        --     },
        -- },
        {
            module_key = 'plant_3_light',
            label      = 'Plant 3 — Lighting',
            icon       = 'lightbulb',
            exclusive  = true,
            variants   = {
                { variant_key = 'plant3_light_basic',   label = 'Basic lighting',   price = 6000,  props_on = { 'light_growthc_stage23_standard' }, props_off = { 'light_growthc_stage23_upgrade' } },
                { variant_key = 'plant3_light_upgrade', label = 'Upgraded lighting', price = 18000, props_on = { 'light_growthc_stage23_upgrade' },  props_off = { 'light_growthc_stage23_standard' } },
            },
        },
        {
            module_key = 'plant_3_hose',
            label      = 'Plant 3 — Hose',
            icon       = 'droplets',
            exclusive  = false,
            variants   = {
                { variant_key = 'plant3_hose', label = 'Install hose', price = 4000, props_on = { 'weed_hosec' }, props_off = {} },
            },
        },
        -- {
        --     module_key = 'plant_4_stage',
        --     label      = 'Plant 4 — Stage',
        --     icon       = 'sprout',
        --     exclusive  = true,
        --     variants   = {
        --         { variant_key = 'plant4_small',  label = 'Small',  price = 8000,  props_on = { 'weed_growthd_stage1' }, props_off = { 'weed_growthd_stage2', 'weed_growthd_stage3' } },
        --         { variant_key = 'plant4_medium', label = 'Medium', price = 14000, props_on = { 'weed_growthd_stage2' }, props_off = { 'weed_growthd_stage1', 'weed_growthd_stage3' } },
        --         { variant_key = 'plant4_full',   label = 'Full',   price = 22000, props_on = { 'weed_growthd_stage3' }, props_off = { 'weed_growthd_stage1', 'weed_growthd_stage2' } },
        --     },
        -- },
        {
            module_key = 'plant_4_light',
            label      = 'Plant 4 — Lighting',
            icon       = 'lightbulb',
            exclusive  = true,
            variants   = {
                { variant_key = 'plant4_light_basic',   label = 'Basic lighting',   price = 6000,  props_on = { 'light_growthd_stage23_standard' }, props_off = { 'light_growthd_stage23_upgrade' } },
                { variant_key = 'plant4_light_upgrade', label = 'Upgraded lighting', price = 18000, props_on = { 'light_growthd_stage23_upgrade' },  props_off = { 'light_growthd_stage23_standard' } },
            },
        },
        {
            module_key = 'plant_4_hose',
            label      = 'Plant 4 — Hose',
            icon       = 'droplets',
            exclusive  = false,
            variants   = {
                { variant_key = 'plant4_hose', label = 'Install hose', price = 4000, props_on = { 'weed_hosed' }, props_off = {} },
            },
        },
        -- {
        --     module_key = 'plant_5_stage',
        --     label      = 'Plant 5 — Stage',
        --     icon       = 'sprout',
        --     exclusive  = true,
        --     variants   = {
        --         { variant_key = 'plant5_small',  label = 'Small',  price = 8000,  props_on = { 'weed_growthe_stage1' }, props_off = { 'weed_growthe_stage2', 'weed_growthe_stage3' } },
        --         { variant_key = 'plant5_medium', label = 'Medium', price = 14000, props_on = { 'weed_growthe_stage2' }, props_off = { 'weed_growthe_stage1', 'weed_growthe_stage3' } },
        --         { variant_key = 'plant5_full',   label = 'Full',   price = 22000, props_on = { 'weed_growthe_stage3' }, props_off = { 'weed_growthe_stage1', 'weed_growthe_stage2' } },
        --     },
        -- },
        {
            module_key = 'plant_5_light',
            label      = 'Plant 5 — Lighting',
            icon       = 'lightbulb',
            exclusive  = true,
            variants   = {
                { variant_key = 'plant5_light_basic',   label = 'Basic lighting',   price = 6000,  props_on = { 'light_growthe_stage23_standard' }, props_off = { 'light_growthe_stage23_upgrade' } },
                { variant_key = 'plant5_light_upgrade', label = 'Upgraded lighting', price = 18000, props_on = { 'light_growthe_stage23_upgrade' },  props_off = { 'light_growthe_stage23_standard' } },
            },
        },
        {
            module_key = 'plant_5_hose',
            label      = 'Plant 5 — Hose',
            icon       = 'droplets',
            exclusive  = false,
            variants   = {
                { variant_key = 'plant5_hose', label = 'Install hose', price = 4000, props_on = { 'weed_hosee' }, props_off = {} },
            },
        },
        -- {
        --     module_key = 'plant_6_stage',
        --     label      = 'Plant 6 — Stage',
        --     icon       = 'sprout',
        --     exclusive  = true,
        --     variants   = {
        --         { variant_key = 'plant6_small',  label = 'Small',  price = 8000,  props_on = { 'weed_growthf_stage1' }, props_off = { 'weed_growthf_stage2', 'weed_growthf_stage3' } },
        --         { variant_key = 'plant6_medium', label = 'Medium', price = 14000, props_on = { 'weed_growthf_stage2' }, props_off = { 'weed_growthf_stage1', 'weed_growthf_stage3' } },
        --         { variant_key = 'plant6_full',   label = 'Full',   price = 22000, props_on = { 'weed_growthf_stage3' }, props_off = { 'weed_growthf_stage1', 'weed_growthf_stage2' } },
        --     },
        -- },
        {
            module_key = 'plant_6_light',
            label      = 'Plant 6 — Lighting',
            icon       = 'lightbulb',
            exclusive  = true,
            variants   = {
                { variant_key = 'plant6_light_basic',   label = 'Basic lighting',   price = 6000,  props_on = { 'light_growthf_stage23_standard' }, props_off = { 'light_growthf_stage23_upgrade' } },
                { variant_key = 'plant6_light_upgrade', label = 'Upgraded lighting', price = 18000, props_on = { 'light_growthf_stage23_upgrade' },  props_off = { 'light_growthf_stage23_standard' } },
            },
        },
        {
            module_key = 'plant_6_hose',
            label      = 'Plant 6 — Hose',
            icon       = 'droplets',
            exclusive  = false,
            variants   = {
                { variant_key = 'plant6_hose', label = 'Install hose', price = 4000, props_on = { 'weed_hosef' }, props_off = {} },
            },
        },
        -- {
        --     module_key = 'plant_7_stage',
        --     label      = 'Plant 7 — Stage',
        --     icon       = 'sprout',
        --     exclusive  = true,
        --     variants   = {
        --         { variant_key = 'plant7_small',  label = 'Small',  price = 8000,  props_on = { 'weed_growthg_stage1' }, props_off = { 'weed_growthg_stage2', 'weed_growthg_stage3' } },
        --         { variant_key = 'plant7_medium', label = 'Medium', price = 14000, props_on = { 'weed_growthg_stage2' }, props_off = { 'weed_growthg_stage1', 'weed_growthg_stage3' } },
        --         { variant_key = 'plant7_full',   label = 'Full',   price = 22000, props_on = { 'weed_growthg_stage3' }, props_off = { 'weed_growthg_stage1', 'weed_growthg_stage2' } },
        --     },
        -- },
        {
            module_key = 'plant_7_light',
            label      = 'Plant 7 — Lighting',
            icon       = 'lightbulb',
            exclusive  = true,
            variants   = {
                { variant_key = 'plant7_light_basic',   label = 'Basic lighting',   price = 6000,  props_on = { 'light_growthg_stage23_standard' }, props_off = { 'light_growthg_stage23_upgrade' } },
                { variant_key = 'plant7_light_upgrade', label = 'Upgraded lighting', price = 18000, props_on = { 'light_growthg_stage23_upgrade' },  props_off = { 'light_growthg_stage23_standard' } },
            },
        },
        {
            module_key = 'plant_7_hose',
            label      = 'Plant 7 — Hose',
            icon       = 'droplets',
            exclusive  = false,
            variants   = {
                { variant_key = 'plant7_hose', label = 'Install hose', price = 4000, props_on = { 'weed_hoseg' }, props_off = {} },
            },
        },
        -- {
        --     module_key = 'plant_8_stage',
        --     label      = 'Plant 8 — Stage',
        --     icon       = 'sprout',
        --     exclusive  = true,
        --     variants   = {
        --         { variant_key = 'plant8_small',  label = 'Small',  price = 8000,  props_on = { 'weed_growthh_stage1' }, props_off = { 'weed_growthh_stage2', 'weed_growthh_stage3' } },
        --         { variant_key = 'plant8_medium', label = 'Medium', price = 14000, props_on = { 'weed_growthh_stage2' }, props_off = { 'weed_growthh_stage1', 'weed_growthh_stage3' } },
        --         { variant_key = 'plant8_full',   label = 'Full',   price = 22000, props_on = { 'weed_growthh_stage3' }, props_off = { 'weed_growthh_stage1', 'weed_growthh_stage2' } },
        --     },
        -- },
        {
            module_key = 'plant_8_light',
            label      = 'Plant 8 — Lighting',
            icon       = 'lightbulb',
            exclusive  = true,
            variants   = {
                { variant_key = 'plant8_light_basic',   label = 'Basic lighting',   price = 6000,  props_on = { 'light_growthh_stage23_standard' }, props_off = { 'light_growthh_stage23_upgrade' } },
                { variant_key = 'plant8_light_upgrade', label = 'Upgraded lighting', price = 18000, props_on = { 'light_growthh_stage23_upgrade' },  props_off = { 'light_growthh_stage23_standard' } },
            },
        },
        {
            module_key = 'plant_8_hose',
            label      = 'Plant 8 — Hose',
            icon       = 'droplets',
            exclusive  = false,
            variants   = {
                { variant_key = 'plant8_hose', label = 'Install hose', price = 4000, props_on = { 'weed_hoseh' }, props_off = {} },
            },
        },
        -- {
        --     module_key = 'plant_9_stage',
        --     label      = 'Plant 9 — Stage',
        --     icon       = 'sprout',
        --     exclusive  = true,
        --     variants   = {
        --         { variant_key = 'plant9_small',  label = 'Small',  price = 8000,  props_on = { 'weed_growthi_stage1' }, props_off = { 'weed_growthi_stage2', 'weed_growthi_stage3' } },
        --         { variant_key = 'plant9_medium', label = 'Medium', price = 14000, props_on = { 'weed_growthi_stage2' }, props_off = { 'weed_growthi_stage1', 'weed_growthi_stage3' } },
        --         { variant_key = 'plant9_full',   label = 'Full',   price = 22000, props_on = { 'weed_growthi_stage3' }, props_off = { 'weed_growthi_stage1', 'weed_growthi_stage2' } },
        --     },
        -- },
        {
            module_key = 'plant_9_light',
            label      = 'Plant 9 — Lighting',
            icon       = 'lightbulb',
            exclusive  = true,
            variants   = {
                { variant_key = 'plant9_light_basic',   label = 'Basic lighting',   price = 6000,  props_on = { 'light_growthi_stage23_standard' }, props_off = { 'light_growthi_stage23_upgrade' } },
                { variant_key = 'plant9_light_upgrade', label = 'Upgraded lighting', price = 18000, props_on = { 'light_growthi_stage23_upgrade' },  props_off = { 'light_growthi_stage23_standard' } },
            },
        },
        {
            module_key = 'plant_9_hose',
            label      = 'Plant 9 — Hose',
            icon       = 'droplets',
            exclusive  = false,
            variants   = {
                { variant_key = 'plant9_hose', label = 'Install hose', price = 4000, props_on = { 'weed_hosei' }, props_off = {} },
            },
        },
    },
}

-- ─── COKE LAB ────────────────────────────────────────────────────────────────
Config.LabUpgrades['coke'] = {
    interior_id = 247553,

    modules = {
        {
            module_key = 'style',
            label      = 'Lab equipment',
            icon       = 'flask-conical',
            exclusive  = true,
            variants   = {
                {
                    variant_key = 'style_none',
                    label       = 'Unequipped',
                    price       = 0,
                    props_on    = {},
                    props_off   = {
                        'set_up', 'equipment_basic', 'coke_press_basic', 'production_basic', 'table_equipment',
                        'equipment_upgrade', 'coke_press_upgrade', 'production_upgrade', 'table_equipment_upgrade'
                    },
                },
                {
                    variant_key = 'style_basic',
                    label       = 'Basic equipment',
                    price       = 50000,
                    props_on    = { 'set_up', 'equipment_basic', 'coke_press_basic', 'production_basic', 'table_equipment' },
                    props_off   = { 'equipment_upgrade', 'coke_press_upgrade', 'production_upgrade', 'table_equipment_upgrade' },
                    gameplay    = {
                        process_time_mult = 0.95,  -- 5% faster
                        output_bonus_pct  = 0,     -- no output bonus
                    },
                },
                {
                    variant_key = 'style_upgrade',
                    label       = 'Upgraded equipment',
                    price       = 130000,
                    props_on    = { 'set_up', 'equipment_upgrade', 'coke_press_upgrade', 'production_upgrade', 'table_equipment_upgrade' },
                    props_off   = { 'equipment_basic', 'coke_press_basic', 'production_basic', 'table_equipment' },
                    gameplay    = {
                        process_time_mult = 0.90,  -- 10% faster (stack with basic: 0.95 × 0.90 = 0.855, cap 0.70)
                        output_bonus_pct  = 15,    -- 15% chance of +1 extra bag on bagCoke
                    },
                },
            },
        },
        {
            module_key = 'security',
            label      = 'Security',
            icon       = 'shield',
            exclusive  = true,
            variants   = {
                {
                    variant_key = 'security_none',
                    label       = 'No security',
                    price       = 0,
                    props_on    = {},
                    props_off   = { 'security_low', 'security_high' },
                },
                {
                    variant_key = 'security_basic',
                    label       = 'Basic security',
                    price       = 30000,
                    props_on    = { 'security_low' },
                    props_off   = { 'security_high' },
                },
                {
                    variant_key = 'security_high',
                    label       = 'High security',
                    price       = 85000,
                    props_on    = { 'security_high' },
                    props_off   = { 'security_low' },
                },
            },
        },
        {
            module_key = 'coke_details',
            label      = 'Coke shipments',
            icon       = 'layers',
            exclusive  = false,
            variants   = {
                { variant_key = 'coke_cut_01', label = 'Basic shipment 1', price = 8000,  props_on = { 'coke_cut_01' }, props_off = {} },
                { variant_key = 'coke_cut_02', label = 'Basic shipment 2', price = 8000,  props_on = { 'coke_cut_02' }, props_off = {} },
                { variant_key = 'coke_cut_03', label = 'Basic shipment 3', price = 8000,  props_on = { 'coke_cut_03' }, props_off = {} },
                { variant_key = 'coke_cut_04', label = 'Premium shipment 1', price = 14000, props_on = { 'coke_cut_04' }, props_off = {} },
                { variant_key = 'coke_cut_05', label = 'Premium shipment 2', price = 14000, props_on = { 'coke_cut_05' }, props_off = {} },
            },
        },
    },
}

-- ─── COUNTERFEIT CASH ────────────────────────────────────────────────────────
Config.LabUpgrades['counterfeit'] = {
    interior_id = 247809,

    modules = {
        {
            module_key = 'printer',
            label      = 'Printer',
            icon       = 'printer',
            exclusive  = true,
            variants   = {
                {
                    variant_key = 'printer_none',
                    label       = 'No printer',
                    price       = 0,
                    props_on    = {},
                    props_off   = {
                        'counterfeit_standard_equip_no_prod',
                        'counterfeit_standard_equip',
                        'counterfeit_upgrade_equip_no_prod',
                        'counterfeit_upgrade_equip',
                    },
                },
                {
                    variant_key = 'printer_basic',
                    label       = 'Basic printer (no production)',
                    price       = 35000,
                    props_on    = { 'counterfeit_standard_equip_no_prod' },
                    props_off   = {
                        'counterfeit_standard_equip',
                        'counterfeit_upgrade_equip_no_prod',
                        'counterfeit_upgrade_equip',
                    },
                },
                -- {
                --     variant_key = 'printer_basic_prod',
                --     label       = 'Basic printer (producing)',
                --     price       = 55000,
                --     props_on    = { 'counterfeit_standard_equip' },
                --     props_off   = {
                --         'counterfeit_standard_equip_no_prod',
                --         'counterfeit_upgrade_equip_no_prod',
                --         'counterfeit_upgrade_equip',
                --     },
                -- },
                {
                    variant_key = 'printer_upgrade',
                    label       = 'Upgraded printer (no production)',
                    price       = 80000,
                    props_on    = { 'counterfeit_upgrade_equip_no_prod' },
                    props_off   = {
                        'counterfeit_standard_equip_no_prod',
                        'counterfeit_standard_equip',
                        'counterfeit_upgrade_equip',
                    },
                },
                -- {
                --     variant_key = 'printer_upgrade_prod',
                --     label       = 'Upgraded printer (producing)',
                --     price       = 120000,
                --     props_on    = { 'counterfeit_upgrade_equip' },
                --     props_off   = {
                --         'counterfeit_standard_equip_no_prod',
                --         'counterfeit_standard_equip',
                --         'counterfeit_upgrade_equip_no_prod',
                --     },
                -- },
            },
        },
        {
            module_key = 'security',
            label      = 'Security',
            icon       = 'shield',
            exclusive  = true,
            variants   = {
                {
                    variant_key = 'security_basic',
                    label       = 'Basic security',
                    price       = 25000,
                    props_on    = { 'counterfeit_low_security' },
                    props_off   = { 'counterfeit_security' },
                },
                {
                    variant_key = 'security_upgrade',
                    label       = 'Upgraded security',
                    price       = 70000,
                    props_on    = { 'counterfeit_security' },
                    props_off   = { 'counterfeit_low_security' },
                },
            },
        },
        {
            module_key = 'dryer_1',
            label      = 'Dryer A',
            icon       = 'wind',
            exclusive  = true,
            variants   = {
                -- Variante comprable: activa el slot de lavado y pone la dryer en off visual.
                -- Los estados 'on' y 'open' los maneja el runtime de lavado (sin costo),
                -- no aparecen en la tienda de upgrades.
                {
                    variant_key = 'dryer1_off',
                    label_key   = 'ui.lab.dryer_state_available',
                    price       = 8000,
                    props_on    = { 'dryera_off' },
                    props_off   = { 'dryera_on', 'dryera_open' },
                },
                {
                    variant_key = 'dryer1_on',
                    label_key   = 'ui.lab.dryer_state_processing',
                    price       = 0,
                    hidden      = true,
                    props_on    = { 'dryera_on' },
                    props_off   = { 'dryera_off', 'dryera_open' },
                },
                {
                    variant_key = 'dryer1_open',
                    label_key   = 'ui.lab.dryer_state_ready',
                    price       = 0,
                    hidden      = true,
                    props_on    = { 'dryera_open' },
                    props_off   = { 'dryera_off', 'dryera_on' },
                },
            },
        },
        {
            module_key = 'dryer_2',
            label      = 'Dryer B',
            icon       = 'wind',
            exclusive  = true,
            variants   = {
                {
                    variant_key = 'dryer2_off',
                    label_key   = 'ui.lab.dryer_state_available',
                    price       = 8000,
                    props_on    = { 'dryerb_off' },
                    props_off   = { 'dryerb_on', 'dryerb_open' },
                },
                {
                    variant_key = 'dryer2_on',
                    label_key   = 'ui.lab.dryer_state_processing',
                    price       = 0,
                    hidden      = true,
                    props_on    = { 'dryerb_on' },
                    props_off   = { 'dryerb_off', 'dryerb_open' },
                },
                {
                    variant_key = 'dryer2_open',
                    label_key   = 'ui.lab.dryer_state_ready',
                    price       = 0,
                    hidden      = true,
                    props_on    = { 'dryerb_open' },
                    props_off   = { 'dryerb_off', 'dryerb_on' },
                },
            },
        },
        {
            module_key = 'dryer_3',
            label      = 'Dryer C',
            icon       = 'wind',
            exclusive  = true,
            variants   = {
                {
                    variant_key = 'dryer3_off',
                    label_key   = 'ui.lab.dryer_state_available',
                    price       = 8000,
                    props_on    = { 'dryerc_off' },
                    props_off   = { 'dryerc_on', 'dryerc_open' },
                },
                {
                    variant_key = 'dryer3_on',
                    label_key   = 'ui.lab.dryer_state_processing',
                    price       = 0,
                    hidden      = true,
                    props_on    = { 'dryerc_on' },
                    props_off   = { 'dryerc_off', 'dryerc_open' },
                },
                {
                    variant_key = 'dryer3_open',
                    label_key   = 'ui.lab.dryer_state_ready',
                    price       = 0,
                    hidden      = true,
                    props_on    = { 'dryerc_open' },
                    props_off   = { 'dryerc_off', 'dryerc_on' },
                },
            },
        },
        {
            module_key = 'dryer_4',
            label      = 'Dryer D',
            icon       = 'wind',
            exclusive  = true,
            variants   = {
                {
                    variant_key = 'dryer4_off',
                    label_key   = 'ui.lab.dryer_state_available',
                    price       = 8000,
                    props_on    = { 'dryerd_off' },
                    props_off   = { 'dryerd_on', 'dryerd_open' },
                },
                {
                    variant_key = 'dryer4_on',
                    label_key   = 'ui.lab.dryer_state_processing',
                    price       = 0,
                    hidden      = true,
                    props_on    = { 'dryerd_on' },
                    props_off   = { 'dryerd_off', 'dryerd_open' },
                },
                {
                    variant_key = 'dryer4_open',
                    label_key   = 'ui.lab.dryer_state_ready',
                    price       = 0,
                    hidden      = true,
                    props_on    = { 'dryerd_open' },
                    props_off   = { 'dryerd_off', 'dryerd_on' },
                },
            },
        },
        {
            module_key = 'details',
            label      = 'Lab details',
            icon       = 'layers',
            exclusive  = false,
            variants   = {
                { variant_key = 'chairs',   label = 'Chairs',                  price = 5000,  props_on = { 'special_chairs' },   props_off = {} },
                { variant_key = 'cutter',   label = 'Bill cutter',           price = 10000, props_on = { 'money_cutter' },     props_off = {} },
                { variant_key = 'setup',    label = 'Papers and machines',     price = 12000, props_on = { 'counterfeit_setup' }, props_off = {} },
            },
        },
        {
            module_key = 'cash_piles',
            label      = 'Cash stacks',
            icon       = 'banknote',
            exclusive  = true,
            variants   = {
                {
                    variant_key = 'cash_none',
                    label       = 'No cash',
                    price       = 0,
                    props_on    = {},
                    props_off   = {
                        'counterfeit_cashpile10a', 'counterfeit_cashpile10b', 'counterfeit_cashpile10c', 'counterfeit_cashpile10d',
                        'counterfeit_cashpile20a', 'counterfeit_cashpile20b', 'counterfeit_cashpile20c', 'counterfeit_cashpile20d',
                        'counterfeit_cashpile100a', 'counterfeit_cashpile100b', 'counterfeit_cashpile100c', 'counterfeit_cashpile100d',
                    },
                },
                -- {
                --     variant_key = 'cash_10a',
                --     label       = '$10 bills — Stack A',
                --     price       = 6000,
                --     props_on    = { 'counterfeit_cashpile10a' },
                --     props_off   = {
                --         'counterfeit_cashpile10b', 'counterfeit_cashpile10c', 'counterfeit_cashpile10d',
                --         'counterfeit_cashpile20a', 'counterfeit_cashpile20b', 'counterfeit_cashpile20c', 'counterfeit_cashpile20d',
                --         'counterfeit_cashpile100a', 'counterfeit_cashpile100b', 'counterfeit_cashpile100c', 'counterfeit_cashpile100d',
                --     },
                -- },
                -- {
                --     variant_key = 'cash_20a',
                --     label       = '$20 bills — Stack A',
                --     price       = 10000,
                --     props_on    = { 'counterfeit_cashpile20a' },
                --     props_off   = {
                --         'counterfeit_cashpile10a', 'counterfeit_cashpile10b', 'counterfeit_cashpile10c', 'counterfeit_cashpile10d',
                --         'counterfeit_cashpile20b', 'counterfeit_cashpile20c', 'counterfeit_cashpile20d',
                --         'counterfeit_cashpile100a', 'counterfeit_cashpile100b', 'counterfeit_cashpile100c', 'counterfeit_cashpile100d',
                --     },
                -- },
                -- {
                --     variant_key = 'cash_100a',
                --     label       = '$100 bills — Stack A',
                --     price       = 18000,
                --     props_on    = { 'counterfeit_cashpile100a' },
                --     props_off   = {
                --         'counterfeit_cashpile10a', 'counterfeit_cashpile10b', 'counterfeit_cashpile10c', 'counterfeit_cashpile10d',
                --         'counterfeit_cashpile20a', 'counterfeit_cashpile20b', 'counterfeit_cashpile20c', 'counterfeit_cashpile20d',
                --         'counterfeit_cashpile100b', 'counterfeit_cashpile100c', 'counterfeit_cashpile100d',
                --     },
                -- },
            },
        },
    },
}

-- ─── BUNKER ──────────────────────────────────────────────────────────────────
Config.LabUpgrades['bunker'] = {
    interior_id = 258561,

    modules = {
        {
            module_key = 'style',
            label      = 'Paint style',
            icon       = 'paintbrush',
            exclusive  = true,
            variants   = {
                {
                    variant_key = 'style_default',
                    label       = 'Default style',
                    price       = 0,
                    props_on    = { 'Bunker_Style_A' },
                    props_off   = { 'Bunker_Style_B', 'Bunker_Style_C' },
                },
                {
                    variant_key = 'style_blue',
                    label       = 'Blue style',
                    price       = 35000,
                    props_on    = { 'Bunker_Style_B' },
                    props_off   = { 'Bunker_Style_A', 'Bunker_Style_C' },
                },
                {
                    variant_key = 'style_yellow',
                    label       = 'Yellow style',
                    price       = 35000,
                    props_on    = { 'Bunker_Style_C' },
                    props_off   = { 'Bunker_Style_A', 'Bunker_Style_B' },
                },
            },
        },
        {
            module_key = 'tier',
            label      = 'Equipment',
            icon       = 'flask-conical',
            exclusive  = true,
            variants   = {
                {
                    variant_key = 'tier_standard',
                    label       = 'Standard',
                    price       = 40000,
                    props_on    = { 'standard_bunker_set' },
                    props_off   = { 'upgrade_bunker_set' },
                },
                {
                    variant_key = 'tier_upgrade',
                    label       = 'Upgraded',
                    price       = 110000,
                    props_on    = { 'upgrade_bunker_set' },
                    props_off   = { 'standard_bunker_set' },
                },
            },
        },
        {
            module_key = 'security',
            label      = 'Security',
            icon       = 'shield',
            exclusive  = true,
            variants   = {
                {
                    variant_key = 'security_standard',
                    label       = 'Standard security',
                    price       = 30000,
                    props_on    = { 'standard_security_set' },
                    props_off   = { 'security_upgrade' },
                },
                {
                    variant_key = 'security_upgrade',
                    label       = 'Upgraded security',
                    price       = 75000,
                    props_on    = { 'security_upgrade' },
                    props_off   = { 'standard_security_set' },
                },
            },
        },
        {
            module_key = 'office',
            label      = 'Office',
            icon       = 'briefcase',
            exclusive  = false,
            variants   = {
                {
                    variant_key = 'office_enabled',
                    label       = 'Enable office',
                    price       = 45000,
                    props_on    = { 'Office_Upgrade_set' },
                    props_off   = { 'Office_blocker_set' },
                },
            },
        },
        {
            module_key = 'locker',
            label      = 'Locker',
            icon       = 'lock',
            exclusive  = false,
            variants   = {
                {
                    variant_key = 'locker_enabled',
                    label       = 'Install locker',
                    price       = 20000,
                    props_on    = { 'gun_locker_upgrade' },
                    props_off   = {},
                },
            },
        },
        {
            module_key = 'range',
            label      = 'Shooting range',
            icon       = 'target',
            exclusive  = false,
            variants   = {
                {
                    variant_key = 'range_lights',
                    label       = 'Shooting range lights',
                    price       = 15000,
                    props_on    = { 'gun_range_lights' },
                    props_off   = { 'gun_wall_blocker', 'gun_range_blocker_set' },
                },
            },
        },
        {
            module_key = 'schematics',
            label      = 'Blueprints and manuals',
            icon       = 'scroll-text',
            exclusive  = false,
            variants   = {
                {
                    variant_key = 'schematics_enabled',
                    label       = 'Install blueprints and manuals',
                    price       = 25000,
                    props_on    = { 'Gun_schematic_set' },
                    props_off   = {},
                },
            },
        },
    },
}
