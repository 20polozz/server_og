return {
    resourceName = "tstudio_vinewood_residence",
    
    -- Map-specific texts: menu-title, menu-description. Elevator and panel
    -- texts from locales/en.lua (e.g. display-help-notify or other display-*
    -- keys) can be overridden here too (menu-close and keybind-* are
    -- server-wide); everything not listed comes from
    -- locales/<lang>.lua. Floor names are translated with
    -- floors = { ["English name"] = "Translation" } inside a language block
    -- ("Floor 1", "Floor 2"... are translated automatically).
    locales = {
        ["en"] = {
            ["menu-title"] = "Vinewood Residence",
            ["menu-description"] = "Vinewood Residence"
        },
        ["de"] = {
            ["menu-title"] = "Vinewood Residence",
            ["menu-description"] = "Vinewood Residence",
            floors = {
                ["Main Lobby"] = "Hauptlobby",
                ["Lobby Park Side"] = "Lobby – Parkseite",
                ["Lobby Pool"] = "Lobby – Pool",
                ["Rooftop"] = "Dach"
            }
        }
    },
    
    header = {
        topColor = {r = 255, g = 192, b = 203},  -- Pink
        bottomColor = {r = 128, g = 0, b = 128} -- Purple
    },
    
    marker = {
        type = 2,
        r = 235,
        g = 52,
        b = 210,
        alpha = 50
    },

    -- ========================================================================
    --  In-world elevator panel (DUI)
    -- ========================================================================
    --  The panel is the screen face baked into the elevator mesh: the live HTML
    --  UI replaces its texture, so the authored image stays visible as the
    --  "off" state whenever the display isn't active.
    --
    --  Nothing here locates the panel: the texture is replaced wherever the game
    --  draws it, so every screen face in the map lights up on its own.
    --
    --  txn  = the screen texture's name.
    --  txds = every dictionary it might live in - the ydr's own name when the
    --         texture is embedded, otherwise the ytd it was packed into. All are
    --         tried; a pair that doesn't exist simply never resolves, so this
    --         keeps working if the texture is repacked later.
    --  style = which look to use (src/web/display/skins/<style>.js). Omit it and
    --         a skin named after this map is used automatically when present.
    --  building = the name on the panel; translate it with floors = { ... }
    --         in the locales block above.
    --  temperatureUnit ("C"/"F") and clock24h (true/false) are optional. Left
    --         out, they follow display-temperature-unit / display-clock-24h in
    --         locales/<lang>.lua (German: °C and 21:30, English: °F and 9:30 PM).
    --
    --  panel = the prop that carries the screen (model may be one name or a list
    --  of names when stops use different props; the nearest instance wins). Once
    --  a map declares one, its
    --  stops drop the floor marker and are used through the panel instead. Any
    --  stop WITHOUT a panel - typically one sitting in another map - opts the
    --  marker back in with `marker = true` on the floor.
    --  Its archetype MUST be flagged dynamic,
    --  otherwise the game bakes it in as static geometry and no script can find
    --  it. The screen's size and centre come from the prop's own bounds, so the
    --  model is the only source of truth; the prop faces the player along its
    --  local +Y (set flip = true if it ends up facing away). Optional overrides
    --  width/height/offset exist for props whose bounds are larger than the
    --  screen face. Remove the whole panel block and the display is a readout
    --  with the marker menu as before.
    --  Set Config.Debug = true to see the detected screen rectangle in-world.
    -- ========================================================================
    display = {
        style = "vinewood_residence",
        -- Optional logo shown in place of the wordmark. Drop the image in
        -- src/web/display/logos/ and point at it relative to the display page,
        -- e.g. logo = "logos/vinewood_residence.png" (png with transparency
        -- works best; it is scaled to fit, so any reasonable size is fine).
        logo = "logos/vinewood_residence.png",
        txn = "01_custom_vwpark_elevator_display",
        txds = {
            "tstudio_vw_park_parrent_txt",
        },
        resolution = { width = 512, height = 1024 },
        building = "Vinewood Residence",

        panel = {
            -- One model, or a list when stops carry different screen props. Every
            -- model is tried and the instance nearest the player is used.
            model = {
                "tstudio_vw_park_apa_asset_elevator_screen",
                "tstudio_vw_park_asset_elevator_screen",
            },
            interactDistance = 1.8, -- how close to the panel the prompt appears
            searchRadius = 5.0      -- how far from the player a panel prop is looked for
        }
    },
    
    -- ========================================================================
    --  Vinewood Residence elevators
    -- ========================================================================
    --  Two shafts, Left and Right, each with its own list of stops: Main Lobby,
    --  Lobby Park Side, Lobby Pool and the apartment floors 1-7. Only the Left
    --  shaft continues up to the Rooftop.
    --
    --  The two shafts sit about 4 m apart (more than Config.ElevatorMergeDistance),
    --  so their stops are never merged: each shaft is used through its own panel.
    --
    --  Floor names show in the menu and on the panel. Keep them unique within a
    --  shaft, and translate them in the locales block above (floors = { ... })
    --  instead of renaming them here.
    -- ========================================================================
    elevators = {
        {
            floors = { -- Left Elevator
                [1] = {
                    name = "Main Lobby",
                    pos = vector4(696.2388, 124.2910, 79.4856, 339.2065)
                },
                [2] = {
                    name = "Lobby Park Side",
                    pos = vector4(678.2133, 125.5977, 88.9834, 250.8250)
                },
                [3] = {
                    name = "Lobby Pool",
                    pos = vector4(698.7910, 155.3929, 89.3335, 70.0632)
                },
                [4] = {
                    name = "Floor 1",
                    pos = vector4(691.4314, 137.3739, 102.2241, 263.7437)
                },
                [5] = {
                    name = "Floor 2",
                    pos = vector4(691.2399, 136.8436, 111.0242, 263.6871)
                },
                [6] = {
                    name = "Floor 3",
                    pos = vector4(691.5454, 136.4139, 119.8241, 288.9538)
                },
                [7] = {
                    name = "Floor 4",
                    pos = vector4(691.9564, 136.0690, 128.6240, 261.8850)
                },
                [8] = {
                    name = "Floor 5",
                    pos = vector4(691.5060, 135.5815, 137.4240, 271.5276)
                },
                [9] = {
                    name = "Floor 6",
                    pos = vector4(692.1541, 135.3263, 146.2240, 281.9209)
                },
                [10] = {
                    name = "Floor 7",
                    pos = vector4(691.9112, 134.9633, 155.0239, 280.2383)
                },
                [11] = {
                    name = "Rooftop",
                    pos = vector4(699.3547, 146.3180, 163.8847, 281.6454)
                }
            }
        },
        {
        floors = { -- Right Elevator
                [1] = {
                    name = "Main Lobby",
                    pos = vector4(692.4586, 125.3028, 79.4855, 339.0736)
                },
                [2] = {
                    name = "Lobby Park Side",
                    pos = vector4(679.7532, 129.1104, 88.9834, 251.7603)
                },
                [3] = {
                    name = "Lobby Pool",
                    pos = vector4(697.4667, 151.7759, 89.3335, 71.5934)
                },
                [4] = {
                    name = "Floor 1",
                    pos = vector4(692.6097, 140.9362, 102.2243, 254.7179)
                },
                [5] = {
                    name = "Floor 2",
                    pos = vector4(692.1508, 140.5153, 111.0242, 270.9263)
                },
                [6] = {
                    name = "Floor 3",
                    pos = vector4(692.1910, 140.3332, 119.8242, 265.5410)
                },
                [7] = {
                    name = "Floor 4",
                    pos = vector4(691.9686, 139.9660, 128.6244, 268.7071)
                },
                [8] = {
                    name = "Floor 5",
                    pos = vector4(691.7085, 139.4773, 137.4243, 270.1126)
                },
                [9] = {
                    name = "Floor 6",
                    pos = vector4(691.4871, 139.1318, 146.2240, 285.1052)
                },
                [10] = {
                    name = "Floor 7",
                    pos = vector4(691.6232, 138.8557, 155.0240, 273.9272)
                }
            }
        }
    }
}
