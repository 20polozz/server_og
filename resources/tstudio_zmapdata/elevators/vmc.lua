return {
    resourceName = "tstudio_vmc",
    
    -- Map-specific texts: menu-title, menu-description. Elevator, car elevator
    -- and panel (display-*) texts from locales/en.lua can be overridden here too
    -- (menu-close and keybind-* are server-wide); everything not listed
    -- comes from locales/<lang>.lua. Floor names are translated with
    -- floors = { ["English name"] = "Translation" } inside a language block
    -- ("Floor 1", "Floor 2"... are translated automatically unless listed).
    locales = {
        ["en"] = {
            ["menu-title"] = "Vespucci Medical Center",
            ["menu-description"] = "Vespucci Medical Center"
        },
        ["de"] = {
            ["menu-title"] = "Vespucci Medical Center",
            ["menu-description"] = "Vespucci Medical Center",
            floors = {
                ["Helipad"] = "Hubschrauberlandeplatz",
                ["Floor 1"] = "Erdgeschoss", -- street level
                ["Floor 2"] = "1. Etage"
            }
        }
    },
    
    header = {
        topColor = {r = 0, g = 255, b = 255},    -- Cyan
        bottomColor = {r = 0, g = 0, b = 255}   -- Blue
    },
    
    marker = {
        type = 2,
        r = 52,
        g = 235,
        b = 183,
        alpha = 50
    },
    
    elevators = {
        {
            floors = { -- Left elevator
                [1] = {
                    name = "Floor 2",
                    pos = vector4(-799.164, -1243.154, 11.314, 52.592)
                },
                [2] = {
                    name = "Floor 1",
                    pos = vector4(-799.395, -1243.015, 6.720, 50.103)
                }
            }
        }, 
        {
            floors = { -- Right elevator
                [1] = {
                    name = "Floor 2",
                    pos = vector4(-801.178, -1245.363, 11.314, 56.841)
                },
                [2] = {
                    name = "Floor 1",
                    pos = vector4(-801.561, -1245.693, 6.720, 54.621)
                }
            }
        }, 
        {
            floors = { -- Heli elevator
                [1] = {
                    name = "Helipad",
                    pos = vector4(-836.430, -1254.273, 13.127, 332.033)
                },
                [2] = {
                    name = "Floor 1",
                    pos = vector4(-839.186, -1251.753, 6.720, 316.017)
                }
            }
        }
    }
}
