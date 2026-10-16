return {
    resourceName = "tstudio_peak_towers_zdlc_lobbys",
    
    -- Map-specific texts: menu-title, menu-description, car-menu-description.
    -- Elevator, car elevator and panel (display-*) texts from locales/en.lua
    -- can be overridden here too (menu-close and keybind-* are server-wide);
    -- everything not listed comes from locales/<lang>.lua. Floor and destination
    -- names are translated with floors = { ["English name"] = "Translation" }
    -- inside a language block.
    locales = {
        ["en"] = {
            ["menu-title"] = "Peak Towers",
            ["menu-description"] = "Peak Towers Elevator",
            ["car-menu-description"] = "Peak Towers Vehicle Transport"
        },
        ["de"] = {
            ["menu-title"] = "Peak Towers",
            ["menu-description"] = "Aufzug – Peak Towers",
            ["car-menu-description"] = "Fahrzeugtransport – Peak Towers",
            floors = {
                ["Rooftop"] = "Dach",
                ["Reception"] = "Rezeption",
                ["Reception Tower B"] = "Rezeption Tower B",
                ["Parking Garage"] = "Tiefgarage",
                ["Parking Deck"] = "Parkdeck",
                ["Street Level A"] = "Straßenebene A",
                ["Street Level B"] = "Straßenebene B"
            }
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
    
    -- Main shaft: Rooftop - Horizon Link - Business Lounge - Reception - Parking Garage
    -- Tower B shaft: Rooftop - Horizon Link - Reception Tower B
    elevators = {
        {
            floors = {
                [1] = {
                    name = "Rooftop",
                    pos = vector4(60.442, -933.474, 307.531, 240.889)
                },
                [2] = {
                    name = "Horizon Link",
                    pos = vector4(60.164, -959.619, 210.739, 159.569)
                },
                [3] = {
                    name = "Business Lounge",
                    pos = vector4(20.937, -903.484, 39.849, 271.276)
                },
                [4] = {
                    name = "Reception",
                    pos = vector4(21.964, -907.969, 30.408, 312.862)
                },
                [5] = {
                    name = "Parking Garage",
                    pos = vector4(77.273, -909.112, -71.163, 272.234)
                }
            }
        },
        {
            floors = {
                [1] = {
                    name = "Rooftop",
                    pos = vector4(153.707, -1078.353, 263.535, 80.651)
                },
                [2] = {
                    name = "Horizon Link",
                    pos = vector4(153.824, -1064.056, 210.746, 314.166)
                },
                [3] = {
                    name = "Reception Tower B",
                    pos = vector4(136.032, -1066.309, 30.582, 4.116)
                }
            }
        }
    },

    -- Car marker: flat cylinder, larger for vehicles
    carMarker = {
        type = 1,
        r = 128,
        g = 64,
        b = 0,
        alpha = 100,
        scaleX = 5.0,
        scaleY = 5.0,
        scaleZ = 0.5
    },

    -- Car Elevators: multiple sources lead to a single destination
    -- Destination returns randomly to one of the sources
    carElevators = {
        {
            destination = {
                name = "Parking Deck",
                pos = vector4(85.586, -898.033, -71.167, 176.223) -- where the vehicle is placed (x, y, z, heading)
            },
            sources = {
                [1] = {
                    name = "Street Level A",
                    pos = vector4(81.206, -879.657, 27.602, 55.563) -- where the vehicle is placed (x, y, z, heading)
                },
                [2] = {
                    name = "Street Level B",
                    pos = vector4(70.011, -891.686, 27.602, 50.85) -- where the vehicle is placed (x, y, z, heading)
                }
            }
        }
    }
}
