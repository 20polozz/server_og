return {
    resourceName = "tstudio_mrpd",
    
    -- Map-specific texts: menu-title, menu-description. Elevator, car elevator
    -- and panel (display-*) texts from locales/en.lua can be overridden here too
    -- (menu-close and keybind-* are server-wide); everything not listed
    -- comes from locales/<lang>.lua. Floor names are translated with
    -- floors = { ["English name"] = "Translation" } inside a language block.
    locales = {
        ["en"] = {
            ["menu-title"] = "Mission Row PD",
            ["menu-description"] = "Mission Row Police Department"
        },
        ["de"] = {
            ["menu-title"] = "Mission Row PD",
            ["menu-description"] = "Mission Row Police Department",
            floors = {
                ["Floor 05 - Rooftop Access"] = "Etage 05 - Dachzugang",
                ["Floor 04 - SWAT"] = "Etage 04 - SWAT",
                ["Floor 03 - MRPD Staff"] = "Etage 03 - MRPD-Personal",
                ["Floor 02 - Public Area"] = "Etage 02 - Öffentlicher Bereich",
                ["Floor 01 - Basement"] = "Etage 01 - Keller"
            }
        }
    },
    
    marker = {
        type = 2,
        r = 0,
        g = 32,
        b = 128,
        alpha = 50
    },
    
    -- Header gradient colors (top to bottom)
    header = {
        topColor = {r = 0, g = 32, b = 128},      -- Navy blue top
        bottomColor = {r = 0, g = 16, b = 64}     -- Darker navy bottom
    },
    
    elevators = {
        {
            floors = {
                [1] = {
                    name = "Floor 04 - SWAT",
                    pos = vector4(436.9360, -995.6405, 39.5200, 97.9808)
                },
                [2] = {
                    name = "Floor 03 - MRPD Staff",
                    pos = vector4(436.9116, -995.8160, 35.1322, 97.9808)
                },
                [3] = {
                    name = "Floor 02 - Public Area",
                    pos = vector4(436.1040, -994.7542, 30.6710, 97.9808)
                }
            }
        },
        {
            floors = {
                [1] = {
                    name = "Floor 05 - Rooftop Access",
                    pos = vector4(478.1115, -984.2039, 45.2009, 99.7533)
                },
                [2] = {
                    name = "Floor 04 - SWAT",
                    pos = vector4(478.1115, -984.2039, 39.611, 97.058)
                },
                [3] = {
                    name = "Floor 03 - MRPD Staff",
                    pos = vector4(478.1115, -984.2039, 35.1317, 90.8173)
                },
                [4] = {
                    name = "Floor 02 - Public Area",
                    pos = vector4(478.1115, -984.2039, 30.6608, 92.7480)
                },
                [5] = {
                    name = "Floor 01 - Basement",
                    pos = vector4(478.1115, -984.2039, 21.9014, 84.8478)
                }
            }
        }
    }
}
