Config = {
    -- Configuración general
    SpawnDistance = 50.0, -- Distancia para spawnear los props

    Props = {
        lift = {
            allowedJobs     = { "mechanic" }, -- who can use it (needs Config.Permissions.enabled = true in open_config.lua)
            name            = "prompt_sandy_is_lift",
            label           = {
                open = "Move Carlift Up",
                close = "Move Carlift Down"
            },
            model           = "prompt_sandy_is_lift",
            coords          = vector3(1997.284546, 3788.210449, 31.955318),
            rotation        = vector4(0.000000, 0.000000, 0.000000, 1.000000),
            collision       = {
                name = "prompt_sandy_is_lift_col",
                model = "prompt_sandy_is_lift_col",
                coords = vector3(1997.407715, 3788.036865, 31.222282),
                rotation = vector4(0.000000, 0.000000, 0.000000, 1.000000),
                startCoords = vector3(1997.408, 3788.037, 31.082),
                endCoords = vector3(1997.408, 3788.037, 33.366),
                moveType = "coords",
                liftSettings = {
                    upDelay = 300,
                    upSpeedFactor = 0.9,
                    downSpeedFactor = 0.9,
                    upCurve = "easeInQuad",
                    downCurve = "easeOutQuad"
                }
            },
            animations      = {
                dict = "prompt_sandy_is_lift_new",
                open = "prompt_sandy_is_lift_opened",
                close = "prompt_sandy_is_lift_closed",
                static = "prompt_sandy_is_lift_static",
                duration = 5000
            },
            interactionZone = {
                coords = vector3(1996.0273, 3789.3616, 32.2377),
                size = vector3(2.0, 2.0, 2.0),
                rotation = 0.0
            }
        },

        -- Puerta de garaje enrollable
        garage_rollup = {
            allowedJobs     = { "mechanic" }, -- who can use it (needs Config.Permissions.enabled = true in open_config.lua)
            name            = "prompt_sandy_is_garage_rollup",
            label           = {
                open = "Open Garage Door",
                close = "Close Garage Door"
            },
            model           = "prompt_sandy_is_garage_rollup",
            coords          = vector3(2002.761, 3791.376, 30.992),
            rotation        = vector4(0.000, 0.000, 31.100, 0.965926),
            collision       = {
                name = "prompt_sandy_is_garage_rollup_col",
                model = "prompt_sandy_is_garage_rollup_col",
                coords = vector3(2002.692017, 3791.269043, 32.968868),
                rotation = vector4(0.000000, 0.000000, 0.000000, 1.000000),
                startCoords = vector3(2002.692, 3791.269, 33.410),
                endCoords = vector3(2002.692, 3791.269, 36.745),
                moveType = "coords",
                openDelay = 0,   -- 2.3s para desactivar colisión al abrir
                closeDelay = 0.1 -- 1.9s para activar colisión al cerrar
            },
            animations      = {
                dict = "anim@prompt_sandy_is_lift",
                open = "prompt_sandy_is_garage_rollup",
                close = "prompt_sandy_is_garage_rollup_closing",
                static = "prompt_sandy_is_garage_rollup_static",
                duration = 5000
            },
            interactionZone = {
                coords = vector3(2002.792114, 3791.323730, 30.991865),
                size = vector3(8.0, 8.0, 3.0),
                rotation = 0.0
            }
        },

        -- Puerta de piso
        floorgate = {
            allowedJobs     = { "mechanic" }, -- who can use it (needs Config.Permissions.enabled = true in open_config.lua)
            name            = "prompt_sandy_is_floorgate",
            label           = {
                open = "Open Secret Floor Door",
                close = "Close Secret Floor Door"
            },
            model           = "prompt_sandy_is_floorgate",
            coords          = vector3(2001.281128, 3790.399414, 31.222427),
            rotation        = vector4(0.000000, 0.000000, 0.000000, 1.000000),
            collision       = {
                name = "prompt_sandy_is_floorgate_col",
                model = "prompt_sandy_is_floorgate_col",
                coords = vector3(2001.281128, 3790.399414, 31.222427),
                rotation = vector4(0.000000, 0.000000, 0.000000, 1.000000),
                startRotation = vector3(0.0, 0.0, 0.0),
                endRotation = vector3(9.047, -15.247, -1.275),
                moveType = "rotation"
            },
            animations      = {
                dict = "anim@prompt_sandy_is_lift",
                open = "prompt_sandy_is_floorgate",
                close = "prompt_sandy_is_floorgate_closing",
                static = "prompt_sandy_is_floorgate_static",
                duration = 5000
            },
            interactionZone = {
                coords = vector3(2000.1112, 3793.0527, 32.2390),
                size = vector3(2.0, 2.0, 2.0),
                rotation = 0.0
            },

            -- ADD THIS:
            extraZones      = {
                {
                    coords = vector3(1990.121, 3781.935, 28.93), -- example coords for the second button
                    size = vector3(2.0, 2.0, 2.0),
                    rotation = 0.0
                }
            },

            onExecute       = function()
                local liftState = GlobalState.ilegal_carwash and GlobalState.ilegal_carwash["prompt_sandy_is_lift"] or
                    false
                if not liftState then
                    animateProp('prompt_sandy_is_lift', true)
                end
            end
        },

        -- Puerta secreta
        secret_door = {
            allowedJobs     = { "mechanic" },    -- who can use it (needs Config.Permissions.enabled = true in open_config.lua)
            name            = "prompt_sandy_is_secret_door",
            label           = {
                open = "Open Secret Wall Door",
                close = "Close Secret Wall Door"
            },
            model           = "prompt_sandy_is_secret_door",
            coords          = vector3(1991.845, 3779.848, 35.512),
            rotation        = vector4(0.000000, 0.000000, 0.000000, 1.000000),
            linkedProps     = {
                {
                    name = "prompt_sandy_is_statue_secret_door",
                    model = "prompt_sandy_is_statue_secret_door",
                    coords = vector3(1991.845, 3779.848, 35.512),
                    rotation = vector4(0.000000, 0.000000, 0.000000, 1.000000)
                }
            },
            animations      = {
                dict = "prompt_sandy_is_secret_door@anim",
                open = "prompt_sandy_is_secret_door_opened",
                close = "prompt_sandy_is_secret_door_closed",
                static = "prompt_sandy_is_secret_door_static",
                duration = 5000,
                linkedAnims = {
                    {
                        open = "prompt_sandy_is_statue_secret_door",
                        close = "prompt_sandy_is_statue_secret_door_closed",
                        static = "prompt_sandy_is_statue_secret_door_static"
                    }
                }
            },
            playerAnimation = {
                dict = "prompt@sandy_garage_ped",
                name = "open_wall",
                closeName = "close_wall",
                position = vector3(1992.1984, 3780.3716, 35.3605),
                heading = 112.5768,
                duration = 2000
            },
            interactionZone = {
                coords = vector3(1991.834, 3779.848, 35.51481),
                size = vector3(2.0, 2.0, 2.0),
                rotation = 0.0
            }
        },

        -- Motor completo
        engine_full = {
            allowedJobs     = { "mechanic" },    -- who can use it (needs Config.Permissions.enabled = true in open_config.lua)
            name            = "prompt_sandy_is_engine_full",
            model           = "prompt_sandy_is_engine_full",
            label           = {
                open = "Put Engine Up",
                close = "Put Engine Down"
            },
            coords          = vector3(1992.80, 3786.095, 32.73153),
            rotation        = vector4(0.000000, 0.000000, -19.35, 1.000000),
            collision       = {
                name = "prop_engine_collision_static",
                model = "prop_engine_collision_static",
                coords = vector3(1992.80, 3786.095, 32.73153),
                rotation = vector4(0.000000, 0.000000, -19.35, 1.000000)
            },
            animations      = {
                dict = "prompt@sandy_is_engine",
                open = "prompt_sandy_is_engine_up",
                close = "prompt_sandy_is_engine_down",
                static = "prompt_sandy_is_engine_static",
                duration = 5000
            },
            playerAnimation = {
                dict = "prompt@sandy_garage_ped",
                name = "domkrat_up",
                closeName = "domkrat_down",
                position = {
                    domkrat_down = vector3(1990.832, 3786.292, 32.73153),
                    domkrat_up = vector3(1990.892, 3786.592, 32.73153)
                },
                heading = {
                    domkrat_down = 271.406,
                    domkrat_up = 260.406
                },
                duration = 2000
            },
            interactionZone = {
                coords = vector3(1990.9272, 3786.5369, 32.7456),
                size = vector3(2.0, 2.0, 2.0),
                rotation = 0.0
            }
        }
    }
}
