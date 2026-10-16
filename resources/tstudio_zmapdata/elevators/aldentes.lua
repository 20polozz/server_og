return {
    resourceName = "tstudio_aldentes",
    
    -- Map-specific texts: menu-title, menu-description. Elevator, car elevator
    -- and panel (display-*) texts from locales/en.lua can be overridden here too
    -- (menu-close and keybind-* are server-wide); everything not listed
    -- comes from locales/<lang>.lua. Floor names are translated with
    -- floors = { ["English name"] = "Translation" } inside a language block.
    locales = {
        ["en"] = {
            ["menu-title"] = "Al Dente's",
            ["menu-description"] = "Al Dente's: Restaurant & Bar"
        },
        ["de"] = {
            ["menu-title"] = "Al Dente's",
            ["menu-description"] = "Al Dente's: Restaurant & Bar",
            floors = {
                ["Office Space"] = "Büroräume",
                ["Basement"] = "Keller",
                ["Rooftop"] = "Dach"
            }
        }
    },
    
    header = {
        topColor = {r = 255, g = 0, b = 0},      -- Red
        bottomColor = {r = 0, g = 128, b = 0}   -- Green
    },
    
    marker = {
        type = 2,
        r = 95,
        g = 173,
        b = 35,
        alpha = 50
    },
    
    elevators = {
        {
            floors = {
                [1] = {
                    name = "Apartment",
                    pos = vector4(-1193.514, -1398.177, 14.273, 211.087)
                },
                [2] = {
                    name = "Office Space",
                    pos = vector4(-1193.713, -1398.094, 9.912, 215.294)
                },
                [3] = {
                    name = "Restaurant",
                    pos = vector4(-1199.501, -1389.740, 4.584, 296.485)
                },
                [4] = {
                    name = "Basement",
                    pos = vector4(-1199.088, -1391.241, -101.107, 318.631)
                }
            }
        },
        {
            floors = {
                [1] = {
                    name = "Rooftop",
                    pos = vector4(-1191.882, -1400.193, 17.927, 215.03)
                },
                [2] = {
                    name = "Restaurant",
                    pos = vector4(-1188.616, -1396.170, 4.752, 213.178)
                }
            }
        }
    }
}
