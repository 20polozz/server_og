-- ## Interior Configurations
Config = {
    Debug = false, -- Enable debug prints for this map-data resource and all other TStudio maps (they log through its shared logger)

    -- Feature toggles: set any to false to fully disable that system.
    ElevatorsEnabled = true,        -- All elevator logic (markers, blips, menus)
    ElevatorDisplays = true,        -- In-world HTML elevator panels (maps that ship one)
    NpcRemovalEnabled = true,       -- Population-removal zones (scenarios/npc_removal.lua)
    ScenarioBlockingEnabled = true, -- GTA scenario-blocking areas (scenarios/areas.lua)
    NavmeshBlockingEnabled = true,  -- AI navmesh-blocking zones (scenarios/navmesh.lua)

    -- Floors from different elevator entries within this distance (metres) auto-merge
    -- into one marker. Keep small so nearby-but-separate shafts aren't merged.
    ElevatorMergeDistance = 1.5,

    -- Elevator panels only render (and only cost anything) within this many
    -- metres of the elevator they belong to.
    DisplayRenderDistance = 12.0,

    -- Language = the code of a file in locales/ ("en" and "de" ship). Texts missing
    -- from that file fall back to English, so nothing disappears. To add a language,
    -- copy locales/en.lua to e.g. locales/fr.lua, translate it and set Locale = "fr".
    -- Per-map overrides live in the `locales` blocks of elevators/*.lua and of
    -- SmartSwitches / PrivacySwitches below.
    Locale = "en",

    -- Default interact keys; players can rebind each one for themselves in
    -- GTA Settings > Key Bindings > FiveM. Key names:
    -- https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard/
    UIPrompts = true, -- false = classic GTA help text (top left) instead of the bottom-screen prompt
    InteractionKeys = {
        elevators     = "E",
        carElevators  = "E",
        smartSwitches = "E",
        privacyGlass  = "E",
    },

    -- ProximityMenu UI defaults. position: left/right/center, size: small/medium/large
    MenuUI = {
        elevators    = { position = "left", size = "medium" },
        carElevators = { position = "left", size = "medium" },
        smartSwitches = { position = "left", size = "medium" },
    },

    -- Scenario data is loaded from scenarios/*.lua (npc_removal, navmesh, areas).
    -- Toggle each system with the *Enabled flags above.
    Scenarios = {},
    
    -- Optional custom help-notify function; nil uses the default. Called as
    -- function(text, info) with info = { system, key, plain, formatted, hasKey }:
    --   system    = "elevators" / "carElevators" / "smartSwitches" / "privacyGlass"
    --   key       = the player's current key label (e.g. "E")
    --   plain     = the text without ~INPUT_...~ tokens and colour codes (for text UIs)
    --   formatted = the text prepared for GTA's native help text
    --   hasKey    = true if the text contains a ~INPUT_...~ key token
    -- e.g. CustomHelpNotify = function(text, info) exports['your_notify']:ShowHelp(("[%s] %s"):format(info.key, info.plain)) end
    CustomHelpNotify = nil,

    -- Loaded dynamically from entitysets/ (one file per location),
    -- via client/entitysets_file_loader.lua
    EntitySets = {},

    -- Exterior analog of EntitySets: toggles whole ymap IPLs on/off for
    -- mutually-exclusive map variants. Loaded from iplvariants/ (see _template.lua),
    -- applied by client/iplvariants_loader.lua. Pick a variant via enable = true/false.
    IplVariants = {},


    -- Privacy-glass switch groups per interior; each switch toggles independently
    -- and syncs to players inside (in-memory, resets on restart).
    -- Fields: name (a label for you only, not shown in-game), resourceName (the group
    -- is only active while this map is started), coords (GetInteriorAtCoords),
    -- switches[] {pos, entitySetOn, entitySetOff}.
    -- Optional: marker {type,r,g,b,alpha} (default 6,19,87,66,100), range (default 2.0),
    -- locales = { ["<lang>"] = { ["help-notify"] = "..." } } to change the prompt for
    -- this group only; without it the text comes from locales/<lang>.lua.
    PrivacySwitches = {
        {
            name = "Pillbox MD Privacy Glass",
            resourceName = "tstudio_pillbox_md",
            coords = vector3(306.003, -568.511, 63.181),
            switches = {
                { pos = vector3(306.003, -568.511, 63.181), entitySetOn = "r7_privacy_on", entitySetOff = "r7_privacy_off" }, -- Office 1
                { pos = vector3(305.963, -568.432, 67.184), entitySetOn = "r7_privacy_on", entitySetOff = "r7_privacy_off" }, -- Office 2
                { pos = vector3(306.056, -568.902, 59.229), entitySetOn = "r7_privacy_on", entitySetOff = "r7_privacy_off" }, -- Office 3
            },
            marker = {type = 6, r = 19, g = 87, b = 66, alpha = 100},
            range = 2.0,
            -- locales = {
            --     ["en"] = { ["help-notify"] = "~INPUT_CONTEXT~ Toggle Privacy Glass" },
            --     ["de"] = { ["help-notify"] = "~INPUT_CONTEXT~ Sichtschutzglas umschalten" },
            -- },
        },
    },

    -- Loaded dynamically from patches/ (one file per creator) via patch_loader.lua.
    CompatibilityPatches = {},

    -- Section for automatic floor ipl loading configurations
    FloorConfigs = {
        pillbox = {
            resourceName = "tstudio_pillbox_md", -- Added name for debug purposes
            center = vector3(306.003, -568.511, 63.181), -- Center of the area for checking player position
            floors = {
                [0] = {height = 64.159, ipls = {"johanni_pillbox_e03_01_milo_"}},
                [1] = {height = 68.162, ipls = {"johanni_pillbox_e03_02_milo_"}},
                [2] = {height = 60.025, ipls = {"johanni_pillbox_e03_03_milo_"}}
            }
        },
        opium = {
            resourceName = "tstudio_opium_nights", -- Added name for debug purposes
            center = vector3(-720.0305, -2268.00635, 16.2695923), -- Center of the area for checking player position
            floors = {
                [0] = {
                    height = 28.00,
                    ipls = {
                        "johanni_opium_penthouse_e01_milo_",
                        "johanni_opium_hallway_e01_milo_",
                        "johanni_opium_hotel_e01_r01_milo_",
                        "johanni_opium_hotel_e01_r02_milo_",
                        "johanni_opium_hotel_e01_r03_milo_",
                        "johanni_opium_hotel_e01_r04_milo_",
                        "johanni_opium_hotel_e01_r05_milo_",
                        "johanni_opium_hotel_e01_r06_milo_",
                        "johanni_opium_hotel_e01_r07_milo_",
                        "johanni_opium_hotel_e01_r08_milo_",
                        "johanni_opium_hotel_e01_r09_milo_",
                        "johanni_opium_hotel_e01_r10_milo_",
                        "johanni_opium_hotel_e01_r11_milo_",
                        "johanni_opium_hotel_e01_r12_milo_"
                    }
                },
                [1] = {
                    height = 38.14,
                    ipls = {
                        "johanni_opium_penthouse_e02_milo_",
                        "johanni_opium_hallway_e02_milo_",
                        "johanni_opium_hotel_e02_r01_milo_",
                        "johanni_opium_hotel_e02_r02_milo_",
                        "johanni_opium_hotel_e02_r03_milo_",
                        "johanni_opium_hotel_e02_r04_milo_",
                        "johanni_opium_hotel_e02_r05_milo_",
                        "johanni_opium_hotel_e02_r06_milo_",
                        "johanni_opium_hotel_e02_r07_milo_",
                        "johanni_opium_hotel_e02_r08_milo_",
                        "johanni_opium_hotel_e02_r09_milo_",
                        "johanni_opium_hotel_e02_r10_milo_",
                        "johanni_opium_hotel_e02_r11_milo_",
                        "johanni_opium_hotel_e02_r12_milo_"
                    }
                },
                [2] = {
                    height = 47.04,
                    ipls = {
                        "johanni_opium_penthouse_e03_milo_",
                        "johanni_opium_hallway_e03_milo_",
                        "johanni_opium_hotel_e03_r01_milo_",
                        "johanni_opium_hotel_e03_r02_milo_",
                        "johanni_opium_hotel_e03_r03_milo_",
                        "johanni_opium_hotel_e03_r04_milo_",
                        "johanni_opium_hotel_e03_r05_milo_",
                        "johanni_opium_hotel_e03_r06_milo_",
                        "johanni_opium_hotel_e03_r07_milo_",
                        "johanni_opium_hotel_e03_r08_milo_",
                        "johanni_opium_hotel_e03_r09_milo_",
                        "johanni_opium_hotel_e03_r10_milo_",
                        "johanni_opium_hotel_e03_r11_milo_",
                        "johanni_opium_hotel_e03_r12_milo_"
                    }
                },
                [3] = {
                    height = 55.88,
                    ipls = {
                        "johanni_opium_penthouse_e04_milo_",
                        "johanni_opium_hallway_e04_milo_",
                        "johanni_opium_hotel_e04_r01_milo_",
                        "johanni_opium_hotel_e04_r02_milo_",
                        "johanni_opium_hotel_e04_r03_milo_",
                        "johanni_opium_hotel_e04_r04_milo_",
                        "johanni_opium_hotel_e04_r05_milo_",
                        "johanni_opium_hotel_e04_r06_milo_",
                        "johanni_opium_hotel_e04_r07_milo_",
                        "johanni_opium_hotel_e04_r08_milo_",
                        "johanni_opium_hotel_e04_r09_milo_",
                        "johanni_opium_hotel_e04_r10_milo_",
                        "johanni_opium_hotel_e04_r11_milo_",
                        "johanni_opium_hotel_e04_r12_milo_"
                    }
                },
                [4] = {
                    height = 64.55,
                    ipls = {
                        "johanni_opium_penthouse_e05_milo_",
                        "johanni_opium_hallway_e05_milo_",
                        "johanni_opium_hotel_e05_r01_milo_",
                        "johanni_opium_hotel_e05_r02_milo_",
                        "johanni_opium_hotel_e05_r03_milo_",
                        "johanni_opium_hotel_e05_r04_milo_",
                        "johanni_opium_hotel_e05_r05_milo_",
                        "johanni_opium_hotel_e05_r06_milo_",
                        "johanni_opium_hotel_e05_r07_milo_",
                        "johanni_opium_hotel_e05_r08_milo_",
                        "johanni_opium_hotel_e05_r09_milo_",
                        "johanni_opium_hotel_e05_r10_milo_",
                        "johanni_opium_hotel_e05_r11_milo_",
                        "johanni_opium_hotel_e05_r12_milo_"
                    }
                },
                [5] = {
                    height = 73.35,
                    ipls = {
                        "johanni_opium_penthouse_e06_milo_",
                        "johanni_opium_hallway_e06_milo_",
                        "johanni_opium_hotel_e06_r01_milo_",
                        "johanni_opium_hotel_e06_r02_milo_",
                        "johanni_opium_hotel_e06_r03_milo_",
                        "johanni_opium_hotel_e06_r04_milo_",
                        "johanni_opium_hotel_e06_r05_milo_",
                        "johanni_opium_hotel_e06_r06_milo_",
                        "johanni_opium_hotel_e06_r07_milo_",
                        "johanni_opium_hotel_e06_r08_milo_",
                        "johanni_opium_hotel_e06_r09_milo_",
                        "johanni_opium_hotel_e06_r10_milo_",
                        "johanni_opium_hotel_e06_r11_milo_",
                        "johanni_opium_hotel_e06_r12_milo_"
                    }
                }
            }
        },
        peaktower_apa = {
            resourceName = "tstudio_peak_towers_zdlc_apartments", -- Added name for debug purposes
            center = vector3(57.393196, -930.921143, 192.874359), -- Center of the area for checking player position
            floors = {
                [0] = {
                    height = 192.874359, 
                    ipls = {
                        "tstudio_hg_peaktowers_apa_floor1_hallway_milo",
                        "tstudio_hg_peaktowers_apa_floor1_l1_milo",
                        "tstudio_hg_peaktowers_apa_floor1_l2_milo",
                        "tstudio_hg_peaktowers_apa_floor1_r1_milo",
                        "tstudio_hg_peaktowers_apa_floor1_r2_milo",
                    },
                },
                [1] = {
                    height = 197.643738, 
                    ipls = {
                        "tstudio_hg_peaktowers_apa_floor2_hallway_milo",
                        "tstudio_hg_peaktowers_apa_floor2_l1_milo",
                        "tstudio_hg_peaktowers_apa_floor2_l2_milo",
                        "tstudio_hg_peaktowers_apa_floor2_r1_milo",
                        "tstudio_hg_peaktowers_apa_floor2_r2_milo",
                    },
                },
                [2] = {
                    height = 202.043030, 
                    ipls = {
                        "tstudio_hg_peaktowers_apa_floor3_hallway_milo",
                        "tstudio_hg_peaktowers_apa_floor3_l1_milo",
                        "tstudio_hg_peaktowers_apa_floor3_l2_milo",
                        "tstudio_hg_peaktowers_apa_floor3_r1_milo",
                        "tstudio_hg_peaktowers_apa_floor3_r2_milo",
                    },
                },
                [3] = {
                    height = 206.442368, 
                    ipls = {
                        "tstudio_hg_peaktowers_apa_floor4_hallway_milo",
                        "tstudio_hg_peaktowers_apa_floor4_l1_milo",
                        "tstudio_hg_peaktowers_apa_floor4_l2_milo",
                        "tstudio_hg_peaktowers_apa_floor4_r1_milo",
                        "tstudio_hg_peaktowers_apa_floor4_r2_milo",
                    },
                },
                [4] = {
                    height = 237.238556, 
                    ipls = {
                        "tstudio_hg_peaktowers_apa_floor6_hallway_milo",
                        "tstudio_hg_peaktowers_apa_floor6_l1_milo",
                        "tstudio_hg_peaktowers_apa_floor6_l2_milo",
                        "tstudio_hg_peaktowers_apa_floor6_r1_milo",
                        "tstudio_hg_peaktowers_apa_floor6_r2_milo",
                    },
                },
                [5] = {
                    height = 241.637894, 
                    ipls = {
                        "tstudio_hg_peaktowers_apa_floor7_hallway_milo",
                        "tstudio_hg_peaktowers_apa_floor7_l1_milo",
                        "tstudio_hg_peaktowers_apa_floor7_l2_milo",
                        "tstudio_hg_peaktowers_apa_floor7_r1_milo",
                        "tstudio_hg_peaktowers_apa_floor7_r2_milo",
                    },
                },
                [6] = {
                    height = 246.037231, 
                    ipls = {
                        "tstudio_hg_peaktowers_apa_floor8_hallway_milo",
                        "tstudio_hg_peaktowers_apa_floor8_l1_milo",
                        "tstudio_hg_peaktowers_apa_floor8_l2_milo",
                        "tstudio_hg_peaktowers_apa_floor8_r1_milo",
                        "tstudio_hg_peaktowers_apa_floor8_r2_milo",
                    },
                },
                [7] = {
                    height = 250.436569, 
                    ipls = {
                        "tstudio_hg_peaktowers_apa_floor9_hallway_milo",
                        "tstudio_hg_peaktowers_apa_floor9_l1_milo",
                        "tstudio_hg_peaktowers_apa_floor9_l2_milo",
                        "tstudio_hg_peaktowers_apa_floor9_r1_milo",
                        "tstudio_hg_peaktowers_apa_floor9_r2_milo",
                    },
                },
                [8] = {
                    height = 254.835907, 
                    ipls = {
                        "tstudio_hg_peaktowers_apa_floor10_hallway_milo",
                        "tstudio_hg_peaktowers_apa_floor10_l1_milo",
                        "tstudio_hg_peaktowers_apa_floor10_l2_milo",
                        "tstudio_hg_peaktowers_apa_floor10_r1_milo",
                        "tstudio_hg_peaktowers_apa_floor10_r2_milo",
                    },
                },
                [9] = {
                    height = 281.231873, 
                    ipls = {
                        "tstudio_hg_peaktowers_apa_floor11_hallway_milo",
                        "tstudio_hg_peaktowers_apa_floor11_l1_milo",
                        "tstudio_hg_peaktowers_apa_floor11_l2_milo",
                        "tstudio_hg_peaktowers_apa_floor11_r1_milo",
                        "tstudio_hg_peaktowers_apa_floor11_r2_milo",
                    },
                },
                [10] = {
                    height = 285.631256, 
                    ipls = {
                        "tstudio_hg_peaktowers_apa_floor12_hallway_milo",
                        "tstudio_hg_peaktowers_apa_floor12_l1_milo",
                        "tstudio_hg_peaktowers_apa_floor12_l2_milo",
                        "tstudio_hg_peaktowers_apa_floor12_r1_milo",
                        "tstudio_hg_peaktowers_apa_floor12_r2_milo",
                    },
                },
                [11] = {
                    height = 290.030670, 
                    ipls = {
                        "tstudio_hg_peaktowers_apa_floor13_hallway_milo",
                        "tstudio_hg_peaktowers_apa_floor13_l1_milo",
                        "tstudio_hg_peaktowers_apa_floor13_l2_milo",
                        "tstudio_hg_peaktowers_apa_floor13_r1_milo",
                        "tstudio_hg_peaktowers_apa_floor13_r2_milo",
                    },
                },
                [12] = {
                    height = 294.430054, 
                    ipls = {
                        "tstudio_hg_peaktowers_apa_floor14_hallway_milo",
                        "tstudio_hg_peaktowers_apa_floor14_l1_milo",
                        "tstudio_hg_peaktowers_apa_floor14_l2_milo",
                        "tstudio_hg_peaktowers_apa_floor14_r1_milo",
                        "tstudio_hg_peaktowers_apa_floor14_r2_milo",
                    },
                },
                [13] = {
                    height = 298.829437, 
                    ipls = {
                        "tstudio_hg_peaktowers_apa_floor15_hallway_milo",
                        "tstudio_hg_peaktowers_apa_floor15_l1_milo",
                        "tstudio_hg_peaktowers_apa_floor15_l2_milo",
                        "tstudio_hg_peaktowers_apa_floor15_r1_milo",
                        "tstudio_hg_peaktowers_apa_floor15_r2_milo",
                    },
                },
            }
        },
        vinewood_residence_apa = {
            resourceName = "tstudio_vinewood_residence", -- Added name for debug purposes
            center = vector3(697.188843, 137.854599, 126.563774), -- Center of the area for checking player position
            floors = {
                [0] = {
                    height = 103.153008,
                    ipls = {
                        "tstudio_vw_park_apa_hallway_floor1_milo_",
                        "tstudio_vw_park_apa_floor1_l1_milo_",
                        "tstudio_vw_park_apa_floor1_l2_milo_",
                        "tstudio_vw_park_apa_floor1_r1_milo_",
                        "tstudio_vw_park_apa_floor1_r2_milo_",
                    },
                },
                [1] = {
                    height = 111.953018,
                    ipls = {
                        "tstudio_vw_park_apa_hallway_floor2_milo_",
                        "tstudio_vw_park_apa_floor2_l1_milo_",
                        "tstudio_vw_park_apa_floor2_l2_milo_",
                        "tstudio_vw_park_apa_floor2_r1_milo_",
                        "tstudio_vw_park_apa_floor2_r2_milo_",
                    },
                },
                [2] = {
                    height = 120.753036,
                    ipls = {
                        "tstudio_vw_park_apa_hallway_floor3_milo_",
                        "tstudio_vw_park_apa_floor3_l1_milo_",
                        "tstudio_vw_park_apa_floor3_l2_milo_",
                        "tstudio_vw_park_apa_floor3_r1_milo_",
                        "tstudio_vw_park_apa_floor3_r2_milo_",
                    },
                },
                [3] = {
                    height = 129.553024,
                    ipls = {
                        "tstudio_vw_park_apa_hallway_floor4_milo_",
                        "tstudio_vw_park_apa_floor4_l1_milo_",
                        "tstudio_vw_park_apa_floor4_l2_milo_",
                        "tstudio_vw_park_apa_floor4_r1_milo_",
                        "tstudio_vw_park_apa_floor4_r2_milo_",
                    },
                },
                [4] = {
                    height = 138.353027,
                    ipls = {
                        "tstudio_vw_park_apa_hallway_floor5_milo_",
                        "tstudio_vw_park_apa_floor5_l1_milo_",
                        "tstudio_vw_park_apa_floor5_l2_milo_",
                        "tstudio_vw_park_apa_floor5_r1_milo_",
                        "tstudio_vw_park_apa_floor5_r2_milo_",
                    },
                },
                [5] = {
                    height = 147.15303,
                    ipls = {
                        "tstudio_vw_park_apa_hallway_floor6_milo_",
                        "tstudio_vw_park_apa_floor6_l1_milo_",
                        "tstudio_vw_park_apa_floor6_l2_milo_",
                        "tstudio_vw_park_apa_floor6_r1_milo_",
                        "tstudio_vw_park_apa_floor6_r2_milo_",
                    },
                },
                [6] = {
                    height = 155.953033,
                    ipls = {
                        "tstudio_vw_park_apa_hallway_floor7_milo_",
                        "tstudio_vw_park_apa_floor7_l1_milo_",
                        "tstudio_vw_park_apa_floor7_l2_milo_",
                        "tstudio_vw_park_apa_floor7_r1_milo_",
                        "tstudio_vw_park_apa_floor7_r2_milo_",
                    },
                },
            }
        },
    },

    -- Interior blocking. Fields: enabled (required), name (interior to disable via
    -- GetInteriorAtCoordsWithType), ipl (IPL to RemoveIpl), coords (required with name).
    -- Patterns: name+coords | name+ipl+coords | ipl-only (coords optional, removed globally).
    Interiors = {
        ["tstudio_tattoo_studio"] = {
            [1] = { enabled = true, name = "v_tattoo", coords = vec3(-3171.2937, 1076.24451, 19.8303947) },
            [2] = { enabled = true, name = "v_tattoo", coords = vec3(322.967865, 181.942917, 102.587761) },
            [3] = { enabled = true, name = "v_tattoo", coords = vec3(1323.765, -1653.43164, 51.27684) },
            [4] = { enabled = true, name = "v_tattoo", coords = vec3(-1153.18408, -1427.0127, 3.955685) },
        },
        ["tstudio_ammunation"] = {
            [1] = { enabled = true, name = "v_gun", coords = vec3(821.144043, -2154.8916, 28.61892) },      -- Cypress
            [2] = { enabled = true, name = "v_gun2", coords = vec3(843.2987, -1028.10669, 27.1947746) },    -- LaMesa
            [3] = { enabled = true, name = "v_gun", coords = vec3(10.9070005, -1105.65833, 28.7969322) },   -- Legion
            [4] = { enabled = true, name = "v_gun2", coords = vec3(247.371582, -47.245163, 68.9409943) },   -- Hawick
            [5] = { enabled = true, name = "v_gun2", coords = vec3(-1310.87659, -392.009644, 35.6957169) }, -- MorningWood
            [6] = { enabled = true, name = "v_gun2", coords = vec3(-663.1717, -940.758057, 20.8291473) },   -- Little Seoul
            [7] = { enabled = true, name = "v_gun2", coords = vec3(-3167.29614, 1084.70984, 19.8386574) },  -- Chumash
            [8] = { enabled = true, name = "v_gun2", coords = vec3(2568.834, 299.788116, 107.734818) },     -- East Highway
            [9] = { enabled = true, name = "v_gun2", coords = vec3(1696.95251, 3755.445, 33.7052574) },     -- Sandy Shores
            [10] = { enabled = true, name = "v_gun2", coords = vec3(-327.1706, 6079.257, 30.4546967) },     -- Paleto Bay
            [11] = { enabled = true, name = "v_gun2", coords = vec3(-1114.84509, 2693.80957, 17.55406) }    -- Route 68
        },
        ["tstudio_fleeca"] = {
            [1] = { enabled = true, name = "v_genbank", coords = vec3(-355.435852, -48.5326, 48.1063843) },    -- Vinewood
            [2] = { enabled = true, name = "v_genbank", coords = vec3(309.74646, -277.644165, 53.2345963) },   -- Vinewood (Lower Level)
            [3] = { enabled = true, name = "v_genbank", coords = vec3(145.416824, -1039.277, 28.4378834) },    -- Legion Square
            [4] = { enabled = true, name = "v_genbank", coords = vec3(-1216.7616, -333.000763, 36.85084) },    -- Movie Studio
            [5] = { enabled = true, name = "hei_generic_bank_dlc", coords = vec3(-2962.59131, 478.238037, 14.7668953) },  -- West Highway
            [6] = { enabled = true, name = "v_genbank", coords = vec3(1179.74475, 2706.985, 37.15784) }        -- Sandy Shores
        },
        ["tstudio_pillbox_md"] = {
            [1] = { enabled = true, name = "rc12b_default", ipl = "rc12b_default", coords = vec3(307.1680, -590.807, 43.280) },    -- Pillbox Hill
        },
        ["tstudio_mrpd"] = {
            [1] = { enabled = true, name = "hei_heist_police_dlc", ipl = "hei_heist_police_dlc", coords = vec3(442.429565, -985.067, 29.8852863) },    -- preparation for MRPD
            [2] = { enabled = true, name = "v_policehub", ipl = "v_policehub", coords = vec3(442.429565, -985.0669, 29.8852863) },    -- preparation for MRPD        },
        },
        ["tstudio_peak_towers"] = {
            [1] = { enabled = true, ipl = "uniqx_flecca_lods_l3" },    -- TStudio Fleeca Legion Square LOD (IPL-only, no coords)
            [2] = { enabled = true, name = "uniqx_flecca_col", ipl = "uniqx_flecca_l3_milo_", coords = vec3(145.416824, -1039.277, 28.4378834) },    -- TStudio Fleeca Legion Square
            [3] = { enabled = true, name = "v_genbank", coords = vec3(145.416824, -1039.277, 28.4378834) },    -- Legion Square
        },
        ["tstudio_ushero_nightclub"] = {
            [1] = { enabled = true, name = "v_strip3", coords = vec3(128.79303, -1292.10437, 27.8926239) },    -- Unicorn
        },
        ["tstudio_binco"] = {
            [1] = { enabled = true, name = "v_clotheslo", coords = vec3(425.244934, -805.33136, 28.3117485) },    -- Mission Row
            [2] = { enabled = true, name = "v_clotheslo", coords = vec3(75.7078857, -1393.81848, 28.19675) },    -- Strawberry
            [3] = { enabled = true, name = "v_clotheslo", coords = vec3(-823.0248, -1074.29822, 10.14872) },    -- Vespucci Canals
            [4] = { enabled = true, name = "v_clotheslo", coords = vec3(5.263491, 6513.293, 30.6984558) },    -- Paleto Bay
            [5] = { enabled = true, name = "v_clotheslo", coords = vec3(1693.45923, 4823.674, 40.8837166) },    -- Grapeseed
            [6] = { enabled = true, name = "v_clotheslo", coords = vec3(1195.75842, 2709.89478, 37.043232) },    -- Harmony
            [7] = { enabled = true, name = "v_clotheslo", coords = vec3(-1101.90662, 2709.70752, 17.9284725) },    -- Zancudo River
        },
        ["tstudio_suburban"] = {
            [1] = { enabled = true, name = "v_clothesmid", coords = vec3(-3171.55444, 1048.27844, 5.461563) },    -- Chumash
            [2] = { enabled = true, name = "v_clothesmid", coords = vec3(-1194.5177, -772.458069, -2.16186714) },    -- Del Perro
            [3] = { enabled = true, name = "v_clothesmid", coords = vec3(124.497406, -219.317551, 38.6773758) },    -- Hawick
            [4] = { enabled = true, name = "v_clothesmid", coords = vec3(617.226, 2759.21631, 29.1352654) },    -- Sandy
        },
        ["tstudio_ponsonby"] = {
            [1] = { enabled = true, name = "v_clotheshi", coords = vec3(-1448.0999, -236.84204, 48.15098) },    -- Morningwood (bh1_33)
            [2] = { enabled = true, name = "v_clotheshi", coords = vec3(-709.81195, -150.62666, 35.753117) },   -- Rockford Hills (bh1_15)
            [3] = { enabled = true, name = "v_clotheshi", coords = vec3(-165.24973, -304.3988, 38.07126) },     -- Rockford Plaza (bt1_04)
        },
    },

    -- Prop-based smart switches: interacting opens a menu to toggle room entity
    -- sets (e.g. blinds). Active only when resourceName is started.
    -- Texts come from locales/<lang>.lua (smart-switch-*). A switch may add its own
    -- locales = { ["<lang>"] = { ... } } to override help-notify, menu-title,
    -- menu-description, open-blinds or close-blinds for that switch only.
    SmartSwitches = {
        peaktowers_apa = {
            resourceName = "tstudio_peak_towers_zdlc_apartments",
            center = vector3(57.393196, -930.921143, 192.874359),
            props = {
                "tstudio_hg_peaktowers_apa_smartswitch",
                "tstudio_hg_peaktowers_apa_smartswitchmain"
            },
            interactionRange = 1.0,
            outlineColor = {r = 128, g = 64, b = 0},
            roomBlinds = {
                main    = { open = "apa_main_blinds_open",    closed = "apa_main_blinds_closed" },
                bedroom = { open = "apa_bedroom_blinds_open",  closed = "apa_bedroom_blinds_closed" },
                closet  = { open = "apa_closet_blinds_open",   closed = "apa_closet_blinds_closed" },
            },
            header = {
                topColor = {r = 128, g = 64, b = 0},
                bottomColor = {r = 64, g = 32, b = 0}
            },
            -- locales = { ... } optional override (help-notify, menu-title, menu-description, open-blinds, close-blinds)
        },
        vinewood_residence = {
            resourceName = "tstudio_vinewood_residence",
            center = vector3(697.188843, 137.854599, 126.563774),
            props = {
                "tstudio_vw_park_apa_asset_smartswitch",
                "tstudio_vw_park_apa_asset_smartswitchmain"
            },
            interactionRange = 1.0,
            outlineColor = {r = 128, g = 64, b = 0},
            roomBlinds = {
                main    = { open = "set_living_curtains_open",    closed = "set_living_curtains_closed" },
                bedroom = { open = "set_bedroom_curtains_open",  closed = "set_bedroom_curtains_closed" },
            },
            header = {
                topColor = {r = 128, g = 64, b = 0},
                bottomColor = {r = 64, g = 32, b = 0}
            },
            -- This map has curtains, so only the texts that differ from the
            -- central blind texts are overridden here. Add a block for every
            -- other language you use (e.g. ["fr"] = { ... }), otherwise the
            -- blind texts from locales/<lang>.lua show here.
            locales = {
                ["en"] = {
                    ["menu-description"] = "Curtain Controls",
                    ["open-blinds"] = "Open Curtains",
                    ["close-blinds"] = "Close Curtains",
                },
                ["de"] = {
                    ["menu-description"] = "Vorhangsteuerung",
                    ["open-blinds"] = "Vorhänge öffnen",
                    ["close-blinds"] = "Vorhänge schließen",
                }
            }
        }
    },

    -- Dry volumes stop water rendering in an area (min/max coords); multiple per project.
    DryVolumes = {
        ["tstudio_missionrow_park"] = {
            {
                name = "Mission Row Park IPL Patch Fix 1",
                minX = 337.012115,
                minY = -1013.49805,
                minZ = -100.221939,
                maxX = 353.21637,
                maxY = -992.301636,
                maxZ = -97.20087
            },
            {
                name = "Mission Row Park IPL Patch Fix 2",
                minX = 281.538,
                minY = -1002.9624,
                minZ = -100.007484,
                maxX = 313.910767,
                maxY = -984.104553,
                maxZ = -90.30185
            }
        },
        ["tstudio_peak_towers"] = {
            {
                name = "Peak Towers Horizon Link Fix",
                minX = 89.316505,
                minY = -1046.967651,
                minZ = 27.972031,
                maxX = 153.239319,
                maxY = -990.951172,
                maxZ = 208.340683
            }
        },
        ["tstudio_vinewood_residence"] = {
            {
                name = "Vinewood Residence Rooftop Fix",
                minX = 675.625,
                minY = 117.309,
                minZ = 74.701,
                maxX = 690.147,
                maxY = 152.376,
                maxZ = 160.878
            },
            {
                name = "Vinewood Residence Rooftop Fix 2",
                minX = 704.351,
                minY = 123.421,
                minZ = 74.701,
                maxX = 718.662,
                maxY = 158.442,
                maxZ = 160.878
            }
        },
        ["tstudio_lacima_estate"] = {
            {
                name = "La Cima Estate Rooftop Fix",
                minX = 666.4924,
                minY = 1213.6172,
                minZ = 322.0107,
                maxX = 672.9302,
                maxY = 1222.5798,
                maxZ = 361.7197
            },
            {
                name = "La Cima Estate Rooftop Fix 2",
                minX = 611.8985,
                minY = 1218.7430,
                minZ = 310.8206,
                maxX = 642.6098,
                maxY = 1242.1300,
                maxZ = 360.2251
            }
        }
    }
}
