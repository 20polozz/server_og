return {
    resourceName = "tstudio_peak_towers_zdlc_apartments",
    
    -- Map-specific texts: menu-title, menu-description. Elevator, car elevator
    -- and panel (display-*) texts from locales/en.lua can be overridden here too
    -- (menu-close and keybind-* are server-wide); everything not listed
    -- comes from locales/<lang>.lua. Floor names are translated with
    -- floors = { ["English name"] = "Translation" } inside a language block
    -- ("Floor 11", "Floor 12"... are translated automatically).
    locales = {
        ["en"] = {
            ["menu-title"] = "Peak Towers Apartments",
            ["menu-description"] = "Peak Towers Apartment Elevator"
        },
        ["de"] = {
            ["menu-title"] = "Peak Towers Apartments",
            ["menu-description"] = "Aufzug – Peak Towers Apartments"
        }
    },
    
    marker = {
        type = 2,
        r = 128,
        g = 64,
        b = 0,
        alpha = 50
    },
    
    -- Header gradient colors (top to bottom)
    header = {
        topColor = {r = 128, g = 64, b = 0},      -- Orange top
        bottomColor = {r = 64, g = 32, b = 0}     -- Darker orange bottom
    },
    
    elevators = {
        {
            floors = {
                [1] = {
                    name = "Peak Towers Lobby",
                    pos = vector4(42.552, -921.232, 30.406, 3.235)
                },
                [2] = {
                    name = "Floor 11",
                    pos = vector4(57.393196, -930.921143, 192.874359, 80.0)
                },
                [3] = {
                    name = "Floor 12",
                    pos = vector4(57.393196, -930.921143, 197.643738, 80.0)
                },
                [4] = {
                    name = "Floor 13",
                    pos = vector4(57.393196, -930.921143, 202.043030, 80.0)
                },
                [5] = {
                    name = "Floor 14",
                    pos = vector4(57.393196, -930.921143, 206.442368, 80.0)
                },
                [6] = {
                    name = "Floor 16",
                    pos = vector4(57.393196, -930.921143, 237.238556, 80.0)
                },
                [7] = {
                    name = "Floor 17",
                    pos = vector4(57.393196, -930.921143, 241.637894, 80.0)
                },
                [8] = {
                    name = "Floor 18",
                    pos = vector4(57.393196, -930.921143, 246.037231, 80.0)
                },
                [9] = {
                    name = "Floor 19",
                    pos = vector4(57.393196, -930.921143, 250.436569, 80.0)
                },
                [10] = {
                    name = "Floor 20",
                    pos = vector4(57.393196, -930.921143, 254.835907, 80.0)
                },
                [11] = {
                    name = "Floor 21",
                    pos = vector4(57.393196, -930.921143, 281.231873, 80.0)
                },
                [12] = {
                    name = "Floor 22",
                    pos = vector4(57.393196, -930.921143, 285.631256, 80.0)
                },
                [13] = {
                    name = "Floor 23",
                    pos = vector4(57.393196, -930.921143, 290.030670, 80.0)
                },
                [14] = {
                    name = "Floor 24",
                    pos = vector4(57.393196, -930.921143, 294.430054, 80.0)
                },
                [15] = {
                    name = "Floor 25",
                    pos = vector4(57.393196, -930.921143, 298.829437, 80.0)
                }
            }
        }
    }
}
