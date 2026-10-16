return {
    resourceName = "tstudio_jurassic_jackpot",
    
    -- Map-specific texts: menu-title, menu-description. Elevator, car elevator
    -- and panel (display-*) texts from locales/en.lua can be overridden here too
    -- (menu-close and keybind-* are server-wide); everything not listed
    -- comes from locales/<lang>.lua. Floor names are translated with
    -- floors = { ["English name"] = "Translation" } inside a language block.
    locales = {
        ["en"] = {
            ["menu-title"] = "Jurassic Jackpot",
            ["menu-description"] = "Jurassic Jackpot: Casino & Bar Club"
        },
        ["de"] = {
            ["menu-title"] = "Jurassic Jackpot",
            ["menu-description"] = "Jurassic Jackpot: Casino & Bar",
            floors = {
                ["Helipad"] = "Hubschrauberlandeplatz",
                ["Boss Room"] = "Chefbüro",
                ["Casino Main Hall"] = "Casino-Haupthalle"
            }
        }
    },
    
    header = {
        topColor = {r = 0, g = 255, b = 0},      -- Green
        bottomColor = {r = 0, g = 100, b = 0}   -- Darker green
    },
    
    marker = {
        type = 2,
        r = 53,
        g = 154,
        b = 71,
        alpha = 50
    },
    
    elevators = {
        {
            floors = {
                [1] = {
                    name = "Helipad",
                    pos = vector4(-271.861, -918.529, 52.734, 340.129)
                },
                [2] = {
                    name = "Boss Room",
                    pos = vector4(-269.587, -918.498, 46.297, 338.799)
                },
                [3] = {
                    name = "Casino Main Hall",
                    pos = vector4(-269.574, -918.395, 32.320, 337.101)
                }
            }
        }
    }
}
