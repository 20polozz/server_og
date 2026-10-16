return {
    resourceName = "tstudio_opium_nights",
    
    -- Map-specific texts: menu-title, menu-description. Elevator, car elevator
    -- and panel (display-*) texts from locales/en.lua can be overridden here too
    -- (menu-close and keybind-* are server-wide); everything not listed
    -- comes from locales/<lang>.lua. Floor names are translated with
    -- floors = { ["English name"] = "Translation" } inside a language block
    -- ("Floor 1", "Floor 2"... are translated automatically).
    locales = {
        ["en"] = {
            ["menu-title"] = "Opium Nights",
            ["menu-description"] = "Opium Nights Hotels"
        },
        ["de"] = {
            ["menu-title"] = "Opium Nights",
            ["menu-description"] = "Opium Nights Hotels"
        }
    },
    
    header = {
        topColor = {r = 255, g = 215, b = 0},    -- Gold
        bottomColor = {r = 255, g = 255, b = 0} -- Yellow
    },
    
    marker = {
        type = 2,
        r = 255,
        g = 154,
        b = 0,
        alpha = 50
    },
    
    elevators = {
        {
            floors = { -- Lobby left 1
                [1] = {
                    name = "Lobby",
                    pos = vector4(-706.110, -2256.275, 13.462, 180.229)
                },
                [2] = {
                    name = "Floor 1",
                    pos = vector4(-706.165, -2251.319, 30.393, 192.299)
                },
                [3] = {
                    name = "Floor 2",
                    pos = vector4(-706.165, -2251.319, 39.0, 192.299)
                },
                [4] = {
                    name = "Floor 3",
                    pos = vector4(-706.165, -2251.319, 48.0, 192.299)
                },
                [5] = {
                    name = "Floor 4",
                    pos = vector4(-706.165, -2251.319, 57, 192.299)
                },
                [6] = {
                    name = "Floor 5",
                    pos = vector4(-706.165, -2251.319, 65.50, 192.299)
                },
                [7] = {
                    name = "Floor 6",
                    pos = vector4(-706.165, -2251.319, 74.50, 192.299)
                }
            }
        },
        {
            floors = { -- Lobby left 2
                [1] = {
                    name = "Lobby",
                    pos = vector4(-709.615, -2256.275, 13.462, 180.229)
                },
                [2] = {
                    name = "Floor 1",
                    pos = vector4(-709.615, -2251.319, 30.393, 192.299)
                },
                [3] = {
                    name = "Floor 2",
                    pos = vector4(-709.615, -2251.319, 39.0, 192.299)
                },
                [4] = {
                    name = "Floor 3",
                    pos = vector4(-709.615, -2251.319, 48.0, 192.299)
                },
                [5] = {
                    name = "Floor 4",
                    pos = vector4(-709.615, -2251.319, 57, 192.299)
                },
                [6] = {
                    name = "Floor 5",
                    pos = vector4(-709.615, -2251.319, 65.50, 192.299)
                },
                [7] = {
                    name = "Floor 6",
                    pos = vector4(-709.615, -2251.319, 74.50, 192.299)
                }
            }
        },
        {
            floors = { -- Lobby right 1
                [1] = {
                    name = "Lobby",
                    pos = vector4(-730.359, -2255.990, 13.462, 180.229)
                },
                [2] = {
                    name = "Floor 1",
                    pos = vector4(-730.359, -2251.164, 30.393, 192.299)
                },
                [3] = {
                    name = "Floor 2",
                    pos = vector4(-730.359, -2251.164, 39.0, 192.299)
                },
                [4] = {
                    name = "Floor 3",
                    pos = vector4(-730.359, -2251.164, 48.0, 192.299)
                },
                [5] = {
                    name = "Floor 4",
                    pos = vector4(-730.359, -2251.164, 57, 192.299)
                },
                [6] = {
                    name = "Floor 5",
                    pos = vector4(-730.359, -2251.164, 65.50, 192.299)
                },
                [7] = {
                    name = "Floor 6",
                    pos = vector4(-730.359, -2251.164, 74.50, 192.299)
                }
            }
        },
        {
            floors = { -- Lobby right 2
                [1] = {
                    name = "Lobby",
                    pos = vector4(-733.811, -2255.925, 13.462, 176.444)
                },
                [2] = {
                    name = "Floor 1",
                    pos = vector4(-734.155, -2251.164, 30.393, 192.299)
                },
                [3] = {
                    name = "Floor 2",
                    pos = vector4(-734.155, -2251.164, 39.0, 192.299)
                },
                [4] = {
                    name = "Floor 3",
                    pos = vector4(-734.155, -2251.164, 48.0, 192.299)
                },
                [5] = {
                    name = "Floor 4",
                    pos = vector4(-734.155, -2251.164, 57, 192.299)
                },
                [6] = {
                    name = "Floor 5",
                    pos = vector4(-734.155, -2251.164, 65.50, 192.299)
                },
                [7] = {
                    name = "Floor 6",
                    pos = vector4(-734.155, -2251.164, 74.50, 192.299)
                }
            }
        }
    }
}
