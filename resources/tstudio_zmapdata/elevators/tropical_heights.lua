return {
    resourceName = "tstudio_tropical_heights",
    
    -- Map-specific texts: menu-title, menu-description. Elevator, car elevator
    -- and panel (display-*) texts from locales/en.lua can be overridden here too
    -- (menu-close and keybind-* are server-wide); everything not listed
    -- comes from locales/<lang>.lua. Floor names are translated with
    -- floors = { ["English name"] = "Translation" } inside a language block.
    locales = {
        ["en"] = {
            ["menu-title"] = "Tropical Heights",
            ["menu-description"] = "Tropical Heights: Bar & Nightclub"
        },
        ["de"] = {
            ["menu-title"] = "Tropical Heights",
            ["menu-description"] = "Tropical Heights: Bar & Nachtclub",
            floors = {
                ["Rooftop"] = "Dach",
                ["Bar & Nightclub"] = "Bar & Nachtclub"
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
    
    elevators = {
        {
            floors = {
                [1] = {
                    name = "Rooftop",
                    pos = vector4(315.935, -913.750, 57.411, 135.65)
                },
                [2] = {
                    name = "Bar & Nightclub",
                    pos = vector4(310.226, -916.654, 52.808, 68.906)
                },
                [3] = {
                    name = "Lobby",
                    pos = vector4(310.696, -916.831, 29.475, 74.755)
                }
            }
        }
    }
}
