Config = {
    SpawnDistance = 80.0, -- Distancia para spawnear los props
    
    Props = {
        lift_2 = {
            name = "prompt_sandy_is_lift_2",
            model = "prompt_sandy_is_lift_2",
            coords = vector3(1708.439, 3692.678, 34.249),
            rotation = vector3(0.0, 0.0, 0.0),
            collision = {
                name = "prompt_sandy_is_lift_col_2",
                model = "prompt_sandy_is_lift_col_2",
                coords = vector3(1708.439, 3692.678, 33.4975),
                rotation = vector3(0.0, 0.0, 0.0),
                startCoords = vector3(1708.439, 3692.678, 33.4975),
                endCoords = vector3(1708.439, 3692.678, 35.4),
                moveType = "coords",
                liftSettings = {
                    upDelay = 300,
                    upSpeedFactor = 0.9,
                    downSpeedFactor = 0.9,
                    upCurve = "easeInQuad",
                    downCurve = "easeOutQuad" 
                }
            },
            animations = {
                dict = "prompt_sandy_is_lift_new_new",
                open = "prompt_sandy_is_lift_opened",
                close = "prompt_sandy_is_lift_closed",
                static = "prompt_sandy_is_lift_static",
                duration = 5000 
            },
            interactionZone = {
                coords = vector3(1707.439, 3693.778, 34.249),
                size = vector3(2.0, 2.0, 2.0),
                rotation = 0.0
            }
        },

        -- Lift 3
        lift_3 = {
            name = "prompt_sandy_is_lift_3",
            model = "prompt_sandy_is_lift_2",
            coords = vector3(1705.495, 3697.778, 34.2498),
            rotation = vector3(0.0, 0.0, 0.0),
            collision = {
                name = "prompt_sandy_is_lift_col_3",
                model = "prompt_sandy_is_lift_col_2",
                coords = vector3(1705.495, 3697.778, 33.4973),
                rotation = vector3(0.0, 0.0, 0.0),
                startCoords = vector3(1705.495, 3697.778, 33.4973),
                endCoords = vector3(1705.495, 3697.778, 35.4),
                moveType = "coords",
                liftSettings = {
                    upDelay = 300,
                    upSpeedFactor = 0.9,
                    downSpeedFactor = 0.9,
                    upCurve = "easeInQuad",
                    downCurve = "easeOutQuad"
                }
            },
            animations = {
                dict = "prompt_sandy_is_lift_new_new",
                open = "prompt_sandy_is_lift_opened",
                close = "prompt_sandy_is_lift_closed",
                static = "prompt_sandy_is_lift_static",
                duration = 5000
            },
            interactionZone = {
                coords = vector3(1704.495, 3698.778, 34.2498),
                size = vector3(2.0, 2.0, 2.0),
                rotation = 0.0
            }
        },

        -- Lift 4
        lift_4 = {
            name = "prompt_sandy_is_lift_4",
            model = "prompt_sandy_is_lift_2",
            coords = vector3(1711.326, 3687.679, 34.2498),
            rotation = vector3(0.0, 0.0, 0.0),
            collision = {
                name = "prompt_sandy_is_lift_col_4",
                model = "prompt_sandy_is_lift_col_2",
                coords = vector3(1711.326, 3687.679, 33.4973),
                rotation = vector3(0.0, 0.0, 0.0),
                startCoords = vector3(1711.326, 3687.679, 33.4973),
                endCoords = vector3(1711.326, 3687.679, 35.4),
                moveType = "coords",
                liftSettings = {
                    upDelay = 300,
                    upSpeedFactor = 0.9,
                    downSpeedFactor = 0.9,
                    upCurve = "easeInQuad",
                    downCurve = "easeOutQuad"
                }
            },
            animations = {
                dict = "prompt_sandy_is_lift_new_new",
                open = "prompt_sandy_is_lift_opened",
                close = "prompt_sandy_is_lift_closed",
                static = "prompt_sandy_is_lift_static",
                duration = 5000
            },
            interactionZone = {
                coords = vector3(1710.326, 3688.679, 34.2498),
                size = vector3(2.0, 2.0, 2.0),
                rotation = 0.0
            }
        },
        garage_rollup_1 = {
            name = "garage_rollup_1",
            model = "prompt_sandy_is_garage_rollup_2",
            coords = vector3(1714.93091, 3689.38037, 33.22947),
            rotation = vector3(0.0, 0.0, 30.0),
            collision = {
                name = "garage_rollup_col_1",
                model = "prompt_sandy_is_garage_rollup_col_2",
                coords = vector3(1714.885, 3689.190, 35.282),
                rotation = vector3(0.0, 0.0, 0.0),
                startCoords = vector3(1714.885, 3689.190, 35.724),
                endCoords = vector3(1714.885, 3689.190, 39.059),
                moveType = "coords",
                openDelay = 0,
                closeDelay = 0.1
            },
            animations = {
                dict = "anim@prompt_sandy_is_lift_new",
                open = "prompt_sandy_is_garage_rollup",
                close = "prompt_sandy_is_garage_rollup_closing",
                static = "prompt_sandy_is_garage_rollup_static",
                duration = 5000
            },
            interactionZone = {
                coords = vector3(1714.93091, 3689.38037, 33.22947),
                size = vector3(8.0, 8.0, 3.0),
                rotation = 0.0
            }
        },

        garage_rollup_2 = {
            name = "garage_rollup_2",
            model = "prompt_sandy_is_garage_rollup_2",
            coords = vector3(1712.00476, 3694.44873, 33.22947),
            rotation = vector3(0.0, 0.0, 30.0),
            collision = {
                name = "garage_rollup_col_2",
                model = "prompt_sandy_is_garage_rollup_col_2",
                coords = vector3(1711.945, 3694.260, 35.282),
                rotation = vector3(0.0, 0.0, 0.0),
                startCoords = vector3(1711.945, 3694.260, 35.724),
                endCoords = vector3(1711.945, 3694.260, 39.059),
                moveType = "coords",
                openDelay = 0,
                closeDelay = 0.1
            },
            animations = {
                dict = "anim@prompt_sandy_is_lift_new",
                open = "prompt_sandy_is_garage_rollup",
                close = "prompt_sandy_is_garage_rollup_closing",
                static = "prompt_sandy_is_garage_rollup_static",
                duration = 5000
            },
            interactionZone = {
                coords = vector3(1711.872, 3694.372, 33.22947),
                size = vector3(8.0, 8.0, 3.0),
                rotation = 0.0
            }
        },

        garage_rollup_3 = {
            name = "garage_rollup_3",
            model = "prompt_sandy_is_garage_rollup_2",
            coords = vector3(1709.12146, 3699.44287, 33.22947),
            rotation = vector3(0.0, 0.0, 30.0),
            collision = {
                name = "garage_rollup_col_3",
                model = "prompt_sandy_is_garage_rollup_col_2",
                coords = vector3(1709.065, 3699.260, 35.282),
                rotation = vector3(0.0, 0.0, 0.0),
                startCoords = vector3(1709.065, 3699.260, 35.724),
                endCoords = vector3(1709.065, 3699.260, 39.059),
                moveType = "coords",
                openDelay = 0,
                closeDelay = 0.1
            },
            animations = {
                dict = "anim@prompt_sandy_is_lift_new",
                open = "prompt_sandy_is_garage_rollup",
                close = "prompt_sandy_is_garage_rollup_closing",
                static = "prompt_sandy_is_garage_rollup_static",
                duration = 5000
            },
            interactionZone = {
                coords = vector3(1708.996, 3699.302, 33.22947),
                size = vector3(8.0, 8.0, 3.0),
                rotation = 0.0
            }
        },

        garage_rollup_4 = {
            name = "garage_rollup_4",
            model = "prompt_sandy_is_garage_rollup_2",
            coords = vector3(1706.1272, 3704.629, 33.22947),
            rotation = vector3(0.0, 0.0, 30.0),
            collision = {
                name = "garage_rollup_col_4",
                model = "prompt_sandy_is_garage_rollup_col_2",
                coords = vector3(1706.065, 3704.450, 35.282),
                rotation = vector3(0.0, 0.0, 0.0),
                startCoords = vector3(1706.065, 3704.450, 35.724),
                endCoords = vector3(1706.065, 3704.450, 39.059),
                moveType = "coords",
                openDelay = 0,
                closeDelay = 0.1
            },
            animations = {
                dict = "anim@prompt_sandy_is_lift_new",
                open = "prompt_sandy_is_garage_rollup",
                close = "prompt_sandy_is_garage_rollup_closing",
                static = "prompt_sandy_is_garage_rollup_static",
                duration = 5000
            },
            interactionZone = {
                coords = vector3(1706.1272, 3704.629, 33.22947),
                size = vector3(8.0, 8.0, 3.0),
                rotation = 0.0
            }
        },

        garage_rollup_5 = {
            name = "garage_rollup_5",
            model = "prompt_sandy_is_garage_rollup_2",
            coords = vector3(1703.093, 3709.88428, 33.22947),
            rotation = vector3(0.0, 0.0, 30.0),
            collision = {
                name = "garage_rollup_col_5",
                model = "prompt_sandy_is_garage_rollup_col_2",
                coords = vector3(1703.035, 3709.690, 35.282),
                rotation = vector3(0.0, 0.0, 0.0),
                startCoords = vector3(1703.035, 3709.690, 35.724),
                endCoords = vector3(1703.035, 3709.690, 39.059),
                moveType = "coords",
                openDelay = 0,
                closeDelay = 0.1
            },
            animations = {
                dict = "anim@prompt_sandy_is_lift_new",
                open = "prompt_sandy_is_garage_rollup",
                close = "prompt_sandy_is_garage_rollup_closing",
                static = "prompt_sandy_is_garage_rollup_static",
                duration = 5000
            },
            interactionZone = {
                coords = vector3(1703.093, 3709.88428, 33.22947),
                size = vector3(8.0, 8.0, 3.0),
                rotation = 0.0
            }
        }
    },
}
