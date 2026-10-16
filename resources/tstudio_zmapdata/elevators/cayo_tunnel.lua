return {
    resourceName = "tstudio_cayo_tunnel",
    
    -- Map-specific texts: menu-title, menu-description, car-menu-description.
    -- Elevator, car elevator and panel (display-*) texts from locales/en.lua
    -- can be overridden here too (menu-close and keybind-* are server-wide);
    -- everything not listed comes from locales/<lang>.lua. Floor and destination
    -- names are translated with floors = { ["English name"] = "Translation" }
    -- inside a language block.
    locales = {
        ["en"] = {
            ["menu-title"] = "Cayo Tunnel",
            ["menu-description"] = "Cayo Tunnel Elevator",
            ["car-menu-description"] = "Cayo Tunnel Vehicle Transport"
        },
        ["de"] = {
            ["menu-title"] = "Cayo Tunnel",
            ["menu-description"] = "Aufzug – Cayo Tunnel",
            ["car-menu-description"] = "Fahrzeugtransport – Cayo Tunnel",
            floors = {
                ["Crime Entry Point A"] = "Crime-Einstieg A",
                ["Crime Entry Point B"] = "Crime-Einstieg B",
                ["Crime Tunnel Point A"] = "Crime-Tunnelpunkt A",
                ["Crime Tunnel Point B"] = "Crime-Tunnelpunkt B"
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
    
    -- No walk-in elevators on this map, only the car elevators below.
    elevators = {},

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
                name = "Crime Entry Point A",
                pos = vector4(1471.865, -2785.974, -52.883, 229.521) -- where the vehicle is placed (x, y, z, heading)
            },
            sources = {
                [1] = {
                    name = "Crime Tunnel Point A",
                    pos = vector4(680.936, -2680.148, 6.487, 92.946) -- where the vehicle is placed (x, y, z, heading)
                },
            }
        },
        {
            destination = {
                name = "Crime Entry Point B",
                pos = vector4(3783.599, -4680.369, -52.85, 59.025) -- where the vehicle is placed (x, y, z, heading)
            },
            sources = {
                [1] = {
                    name = "Crime Tunnel Point B",
                    pos = vector4(4482.846, -4450.955, 4.62, 194.972) -- where the vehicle is placed (x, y, z, heading)
                },
            }
        }
    }
}
