return {
    resourceName = "tstudio_ushero_nightclub",
    
    -- Map-specific texts: menu-title, menu-description. Elevator and panel
    -- texts from locales/en.lua (e.g. display-help-notify or other display-*
    -- keys) can be overridden here too (menu-close and keybind-* are
    -- server-wide); everything not listed comes from
    -- locales/<lang>.lua. Floor names are translated with
    -- floors = { ["English name"] = "Translation" } inside a language block.
    locales = {
        ["en"] = {
            ["menu-title"] = "Ushero Nightclub",
            ["menu-description"] = "Ushero Nightclub"
        },
        ["de"] = {
            ["menu-title"] = "Ushero Nightclub",
            ["menu-description"] = "Ushero Nightclub",
            floors = {
                ["Nightclub"] = "Nachtclub",
                ["Vanilla Unicorn Rooftop"] = "Vanilla Unicorn – Dach"
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
    --  panel = the prop that carries the screen. Once a map declares one, its
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
        style = "ushero_nightclub",
        txn = "01_custom_ushero_elevator_display",
        txds = {
            "tstudio_jhn_ushero_txt_assets",
        },
        resolution = { width = 512, height = 1024 },
        building = "Ushero Nightclub",

        panel = {
            model = "tstudio_jhn_ushero_asset_elevator_screen",
            interactDistance = 1.8 -- how close to the panel the prompt appears
            -- searchRadius: how far from the PLAYER a panel still counts.
            -- Defaults to interactDistance + 1.0, which is right for almost
            -- everything; only raise it if panels sit oddly far apart.
        }
    },
    
    -- ========================================================================
    --  Ushero Nightclub elevators
    -- ========================================================================
    --  Each street entrance is its own simple elevator (Lobby <-> Nightclub) and
    --  they all share the SAME interior point (-1023.4138, -3192.0181, -65.9482).
    --  At a lobby you only see that entrance's own floors. Inside the club the
    --  loader AUTO-MERGES all the overlapping interior markers into ONE marker
    --  whose menu lists every lobby you can leave by (see client/elevator_loader.lua
    --  and Config.ElevatorMergeDistance). So no manual "hub" is needed and there is
    --  no wrong-lobby teleport.
    --
    --  IMPORTANT: give each lobby a UNIQUE descriptive name (not just "Lobby"),
    --  also in the floors translations above, so the merged in-club menu is readable.
    --
    --  To DISABLE a location: delete its whole elevator block below (and remove that
    --  location's stream folder). It drops out of the merged in-club menu by itself.
    -- ========================================================================
    elevators = {
        {
            floors = { -- Burton entrance
                [1] = {
                    name = "Burton Lobby",
                    pos = vector4(-475.2523, -80.9544, 40.4027, 53.9934)
                },
                [2] = {
                    name = "Nightclub",
                    pos = vector4(-1023.4138, -3192.0181, -65.9482, 178.9715)
                }
            }
        },
        {
            floors = { -- Vinewood Hills entrance
                [1] = {
                    name = "Vinewood Hills Lobby",
                    pos = vector4(365.0890, 234.8327, 103.0057, 339.7982)
                },
                [2] = {
                    name = "Nightclub",
                    pos = vector4(-1023.4138, -3192.0181, -65.9482, 178.9715)
                }
            }
        },
        {
            floors = { -- Vanilla Unicorn entrance (also serves the Unicorn rooftop)
                [1] = {
                    name = "Vanilla Unicorn Lobby",
                    pos = vector4(119.2576, -1282.4839, 29.2486, 212.8084)
                },
                [2] = {
                    name = "Nightclub",
                    pos = vector4(-1023.4138, -3192.0181, -65.9482, 178.9715)
                },
                [3] = {
                    name = "Vanilla Unicorn Rooftop",
                    pos = vector4(101.8482, -1297.4547, 35.3082, 298.6503)
                }
            }
        },
        {
            floors = { -- Peak Tower entrance (Ushero side)
                [1] = {
                    name = "Ushero Nightclub Lobby",
                    pos = vector4(364.911, 234.748, 3.005, 340.04)
                },
                [2] = {
                    name = "Nightclub",
                    pos = vector4(-1023.4138, -3192.0181, -65.9482, 178.9715)
                }
            }
        },
        {
            floors = { -- Peak Tower connector: Peak Tower Lobby <-> Ushero Nightclub Lobby.
                       -- Does NOT touch the club interior, so it never merges.
                [1] = {
                    name = "Peak Tower Lobby",
                    pos = vector4(126.284, -1067.309, 30.582, 8.739),
                    marker = true -- sits in another map, so no panel here
                },
                [2] = {
                    name = "Ushero Nightclub Lobby",
                    pos = vector4(375.7585, 241.7496, 3.0057, 73.8090),
                    marker = true -- sits in another map, so no panel here
                }
            }
        }
    }
}
