return {
    resourceName = "tstudio_pillbox_md",
    
    -- Map-specific texts: menu-title, menu-description. Elevator, car elevator
    -- and panel (display-*) texts from locales/en.lua can be overridden here too
    -- (menu-close and keybind-* are server-wide); everything not listed
    -- comes from locales/<lang>.lua. Floor names are translated with
    -- floors = { ["English name"] = "Translation" } inside a language block.
    locales = {
        ["en"] = {
            ["menu-title"] = "Pillbox Hill",
            ["menu-description"] = "Pillbox Hill Medical Center"
        },
        ["de"] = {
            ["menu-title"] = "Pillbox Hill",
            ["menu-description"] = "Pillbox Hill Medical Center",
            floors = {
                ["Emergency Garage"] = "Notaufnahme-Garage",
                ["Lobby Back Entrance"] = "Lobby – Hintereingang",
                ["Lobby Front Entrance"] = "Lobby – Haupteingang",
                ["Main Lobby ER Elevator"] = "Hauptlobby – Notaufnahme-Aufzug",
                ["Helipad Roof"] = "Hubschrauberlandeplatz"
            }
        }
    },
    
    header = {
        topColor = {r = 0, g = 255, b = 0},      -- Green
        bottomColor = {r = 0, g = 255, b = 255} -- Cyan
    },
    
    marker = {
        type = 2,
        r = 19,
        g = 87,
        b = 66,
        alpha = 100
    },
    
    elevators = {
        {
            floors = { -- Lobby left
                [1] = {
                    name = "Emergency Garage",
                    pos = vector4(362.627, -648.566, 22.540, 69.457)
                },
                [2] = {
                    name = "Lobby Back Entrance",
                    pos = vector4(347.663, -594.554, 28.771, 254.873)
                },
                [3] = {
                    name = "Lobby Front Entrance",
                    pos = vector4(313.115, -578.836, 43.192, 69.171)
                },
                [4] = {
                    name = "Station 1",
                    pos = vector4(336.795, -581.162, 59.231, 339.18)
                },
                [5] = {
                    name = "Station 2",
                    pos = vector4(336.844, -580.957, 63.183, 342.843)
                },
                [6] = {
                    name = "Station 3",
                    pos = vector4(336.898, -580.772, 67.186, 342.921)
                },
                [7] = {
                    name = "Helipad Roof",
                    pos = vector4(329.108, -581.592, 74.215, 255.826)
                }
            }
        },
        {
            floors = { -- Lobby right
                [1] = {
                    name = "Emergency Garage",
                    pos = vector4(359.699, -657.480, 22.540, 76.791)
                },
                [2] = {
                    name = "Lobby Back Entrance",
                    pos = vector4(352.339, -581.102, 28.770, 249.924)
                },
                [3] = {
                    name = "Lobby Front Entrance",
                    pos = vector4(312.724, -581.540, 43.192, 72.158)
                },
                [4] = {
                    name = "Station 1",
                    pos = vector4(334.186, -580.420, 59.231, 338.353)
                },
                [5] = {
                    name = "Station 2",
                    pos = vector4(334.186, -580.957, 63.183, 342.843)
                },
                [6] = {
                    name = "Station 3",
                    pos = vector4(334.186, -580.772, 67.186, 342.921)
                },
                [7] = {
                    name = "Helipad Roof",
                    pos = vector4(330.372, -579.158, 74.215, 250.327)
                }
            }
        },
        {
            floors = { -- Lobby Main backside
                [1] = {
                    name = "Emergency Garage",
                    pos = vector4(359.699, -657.480, 22.540, 76.791)
                },
                [2] = {
                    name = "Lobby Back Entrance",
                    pos = vector4(352.339, -581.102, 28.770, 249.924)
                },
                [3] = {
                    name = "Main Lobby ER Elevator",
                    pos = vector4(329.491, -594.709, 43.260, 326.745)
                },
                [4] = {
                    name = "Station 1",
                    pos = vector4(334.186, -580.420, 59.231, 338.353)
                },
                [5] = {
                    name = "Station 2",
                    pos = vector4(334.186, -580.957, 63.183, 342.843)
                },
                [6] = {
                    name = "Station 3",
                    pos = vector4(334.186, -580.772, 67.186, 342.921)
                },
                [7] = {
                    name = "Helipad Roof",
                    pos = vector4(330.372, -579.158, 74.215, 250.327)
                }
            }
        },
        {
            floors = { -- Garage elevator
                [1] = {
                    name = "Emergency Garage",
                    pos = vector4(295.408, -629.233, 22.540, 247.896)
                },
                [2] = {
                    name = "Lobby Back Entrance",
                    pos = vector4(352.339, -581.102, 28.770, 249.924)
                }
            }
        }
    }
}
