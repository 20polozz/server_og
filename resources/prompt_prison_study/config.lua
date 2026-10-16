return {
    Debug = true, -- Enable to see debug logs in console

    gymSets = { -- /prisongymsets command
        enable = true,
        restricted = 'group.admin', -- ox_lib's addCommand restriction string, set to false to disable restriction

        ---@param source number
        ---@return boolean
        canAccess = function(source)
            -- additional checks can be added here
            return true
        end
    },

    ---@param source number
    ---@param title string
    ---@param message string
    ---@param type 'success' | 'error' | 'info'
    notify = function(source, title, message, type)
        TriggerClientEvent('ox_lib:notify', source, {
            title = title,
            description = message,
            type = type,
        })
    end,

    -- Prison gym location configuration
    -- Interior coordinates for entity set detection: vec3(1735.73657, 2644.48071, 52.7696571)
    GymLocations = {
        ['prison'] = {
            enabled = true,
            coords = vec3(1735.73657, 2644.48071, 52.7696571), -- Interior coords for entity set detection
            entitySets = {
                gym = true, -- The "gym" entity set for the prison interior
            },

            -- Props that always spawn (not tied to entity sets)
            props = {},

            -- Props tied to entity sets (spawned when entity set is active)
            entitySetProps = {
                gym = {
                    speedbag = {
                        vec4(1737.090, 2637.229, 45.99, 359.293),
                        vec4(1723.039, 2641.248, 45.99, 178.622),
                        vec4(1737.105, 2631.034, 45.99, 0.454),
                    },
                    gymbike = {
                        vec4(1728.650, 2629.374, 44.604, 178.871),
                        vec4(1729.987, 2629.365, 44.604, 179.099),
                        vec4(1731.657, 2629.324, 44.604, 179.099),
                    },
                    gymrowpull = {
                        vec4(1736.358, 2632.488, 44.604, 88.930),
                        vec4(1729.649, 2637.952, 44.604, 270.749),
                        vec4(1723.853, 2638.866, 44.604, 0.267),
                    },
                    gymlatpull = {
                        vec4(1736.884, 2634.262, 44.606, 1.648),
                        vec4(1728.906, 2637.961, 44.606, 358.580),
                        vec4(1725.410, 2638.316, 44.606, 269.039),
                    },
                    gympullmachine1 = {
                        vec4(1728.314, 2640.917, 44.604, 231.362),
                        vec4(1729.236, 2639.548, 44.604, 50.662),
                    },
                    bench = {
                        {
                            coords = vec4(1725.580, 2635.954, 44.814, 268.803),
                            bar = vec4(1725.100, 2636.082, 45.111, 273.803)
                        },
                        {
                            coords = vec4(1725.590, 2634.306, 44.814, 268.803),
                            bar = vec4(1724.655, 2634.428, 44.765, 268.803)
                        },
                        {
                            coords = vec4(1725.863, 2632.536, 44.814, 269.987),
                            bar = vec4(1725.227, 2632.455, 45.111, 269.987)
                        },
                        {
                            coords = vec4(1725.902, 2630.652, 44.814, 269.987),
                            bar = vec4(1726.376, 2630.748, 45.111, 269.987)
                        },
                    },
                    gymspeedbag = {
                        vec4(1736.417, 2636.112, 44.608, 74.461),
                        vec4(1733.745, 2634.463, 44.608, 260.483),
                        vec4(1732.309, 2635.038, 44.608, 259.609),
                        vec4(1732.316, 2633.904, 44.608, 271.117),
                    },
                    vin_chu = {
                        vec4(1730.642, 2635.111, 44.607, 92.900),
                        vec4(1730.686, 2633.915, 44.607, 272.104),
                        vec4(1729.056, 2634.503, 44.607, 180.203),
                    },
                    leg_press = {
                        vec4(1733.056, 2640.379, 44.607, 248.812),
                        vec4(1733.039, 2638.301, 44.607, 253.311),
                    },
                    gympullmachine2 = {
                        vec4(1728.501, 2639.465, 44.602, 140.477),
                        vec4(1729.042, 2641.002, 44.602, 321.528),
                    },
                },
            },
        },
    },
}
