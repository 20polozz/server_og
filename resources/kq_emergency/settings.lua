Settings = {}

-- Max amount of equipment per vehicle
-- We recommend not setting this value too high.
Settings.maxAmount = 30

Settings.equipment = {
    ['kq_police_siren_1_redblue'] = {
        order = 1,
        label = 'Sirena de techo roja y azul',
        icon = 'kq_police_siren_1_redblue.webp',
        animation = {
            dict = 'anim@kq_police_siren_1',
            name = 'kq_police_siren_1',
        },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        },
        -- Set a list of jobs to set a whitelist for this equipment object
        jobsWhitelist = {}
    },
    ['kq_police_siren_1_blueblue'] = {
        order = 2,
        label = 'Sirena de techo azul',
        icon = 'kq_police_siren_1_blueblue.webp',
        animation = {
            dict = 'anim@kq_police_siren_1',
            name = 'kq_police_siren_1',
        },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        },
        -- Set a list of jobs to set a whitelist for this equipment object
        jobsWhitelist = {},
    },
    ['kq_police_siren_1_redred'] = {
        order = 3,
        label = 'Sirena de techo roja',
        icon = 'kq_police_siren_1_redred.webp',
        animation = {
            dict = 'anim@kq_police_siren_1',
            name = 'kq_police_siren_1',
        },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        },
        -- Set a list of jobs to set a whitelist for this equipment object
        jobsWhitelist = {},
    },
    ['kq_police_siren_1_amberamber'] = {
        order = 4,
        label = 'Sirena de techo ámbar',
        icon = 'kq_police_siren_1_amberamber.webp',
        animation = {
            dict = 'anim@kq_police_siren_1',
            name = 'kq_police_siren_1',
        },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        },
        -- Set a list of jobs to set a whitelist for this equipment object
        jobsWhitelist = {},
    },

    ['kq_police_siren_2_redblue'] = {
        order = 5,
        label = 'Sirena de techo roja y azul 2',
        icon = 'kq_police_siren_2_redblue.webp',
        animation = {
            dict = 'anim@kq_police_siren_2',
            name = 'kq_police_siren_2',
        },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },
    ['kq_police_siren_2_blueblue'] = {
        order = 6,
        label = 'Sirena de techo azul 2',
        icon = 'kq_police_siren_2_blueblue.webp',
        animation = {
            dict = 'anim@kq_police_siren_2',
            name = 'kq_police_siren_2',
        },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },
    ['kq_police_siren_2_redred'] = {
        order = 7,
        label = 'Sirena de techo roja 2',
        icon = 'kq_police_siren_2_redred.webp',
        animation = {
            dict = 'anim@kq_police_siren_2',
            name = 'kq_police_siren_2',
        },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },
    ['kq_police_siren_2_amberamber'] = {
        order = 8,
        label = 'Sirena de techo ámbar 2',
        icon = 'kq_police_siren_2_amberamber.webp',
        animation = {
            dict = 'anim@kq_police_siren_2',
            name = 'kq_police_siren_2',
        },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },


    ['kq_police_siren_3_redblue'] = {
        -- Model based on a model by @STILIG8 under their permission.
        -- Heavily modified and animated by Kuz
        order = 9,
        label = 'Sirena de techo roja y azul 3',
        icon = 'kq_police_siren_3_redblue.webp',

        animation = {
            dict = 'anim@kq_police_siren_3',
            name = 'kq_police_siren_3',
        },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },
    ['kq_police_siren_3_blueblue'] = {
        -- Model based on a model by @STILIG8 under their permission.
        -- Heavily modified and animated by Kuz
        order = 10,
        label = 'Sirena de techo azul 3',
        icon = 'kq_police_siren_3_blueblue.webp',

        animation = {
            dict = 'anim@kq_police_siren_3',
            name = 'kq_police_siren_3',
        },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },
    ['kq_police_siren_3_redred'] = {
        -- Model based on a model by @STILIG8 under their permission.
        -- Heavily modified and animated by Kuz
        order = 11,
        label = 'Sirena de techo roja 3',
        icon = 'kq_police_siren_3_redred.webp',

        animation = {
            dict = 'anim@kq_police_siren_3',
            name = 'kq_police_siren_3',
        },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },
    ['kq_police_siren_3_amberamber'] = {
        -- Model based on a model by @STILIG8 under their permission.
        -- Heavily modified and animated by Kuz
        order = 12,
        label = 'Sirena de techo ámbar 3',
        icon = 'kq_police_siren_3_amberamber.webp',

        animation = {
            dict = 'anim@kq_police_siren_3',
            name = 'kq_police_siren_3',
        },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },


    ['kq_police_led_2_redblue'] = {
        order = 101,
        label = 'LED largos rojo y azul',
        icon = 'kq_police_led_2_redblue.webp',
        animation = {
            dict = 'anim@kq_police_led_2',
            name = 'kq_police_led_2',
        },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },
    ['kq_police_led_2_blueblue'] = {
        order = 102,
        label = 'LED largos azul',
        icon = 'kq_police_led_2_blueblue.webp',
        animation = {
            dict = 'anim@kq_police_led_2',
            name = 'kq_police_led_2',
        },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },
    ['kq_police_led_2_redred'] = {
        order = 103,
        label = 'LED largos rojo',
        icon = 'kq_police_led_2_redred.webp',
        animation = {
            dict = 'anim@kq_police_led_2',
            name = 'kq_police_led_2',
        },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },
    ['kq_police_led_2_amberamber'] = {
        order = 104,
        label = 'LED largos ámbar',
        icon = 'kq_police_led_2_amberamber.webp',
        animation = {
            dict = 'anim@kq_police_led_2',
            name = 'kq_police_led_2',
        },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },

    ['kq_police_led_3_red'] = {
        order = 105,
        label = 'LED doble rojo',
        icon = 'kq_police_led_3_red.webp',
        animation = {
            delay = 'auto',
            dict = 'anim@kq_police_led_3',
            name = 'kq_police_led_3',
        },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 180),
        }
    },
    ['kq_police_led_3_blue'] = {
        order = 106,
        label = 'LED doble azul',
        icon = 'kq_police_led_3_blue.webp',
        animation = {
            delay = 'auto',
            dict = 'anim@kq_police_led_3',
            name = 'kq_police_led_3',
        },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 180),
        }
    },
    ['kq_police_led_3_white'] = {
        order = 108,
        label = 'LED doble blanco',
        icon = 'kq_police_led_3_white.webp',
        animation = {
            delay = 'auto',
            dict = 'anim@kq_police_led_3',
            name = 'kq_police_led_3',
        },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 180),
        }
    },
    ['kq_police_led_3_amber'] = {
        order = 109,
        label = 'LED doble ámbar',
        icon = 'kq_police_led_3_amber.webp',
        animation = {
            delay = 'auto',
            dict = 'anim@kq_police_led_3',
            name = 'kq_police_led_3',
        },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 180),
        }
    },

    ['kq_police_led_1_red'] = {
        order = 110,
        label = 'LED sencillo rojo',
        icon = 'kq_police_led_1_red.webp',
        animation = {
            delay = 'auto',
            dict = 'anim@kq_police_led_1',
            name = 'kq_police_led_1',
        },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },
    ['kq_police_led_1_blue'] = {
        order = 111,
        label = 'LED sencillo azul',
        icon = 'kq_police_led_1_blue.webp',
        animation = {
            delay = 'auto',
            dict = 'anim@kq_police_led_1',
            name = 'kq_police_led_1',
        },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },
    ['kq_police_led_1_white'] = {
        order = 112,
        label = 'LED sencillo blanco',
        icon = 'kq_police_led_1_white.webp',
        animation = {
            delay = 'auto',
            dict = 'anim@kq_police_led_1',
            name = 'kq_police_led_1',
        },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },
    ['kq_police_led_1_amber'] = {
        order = 113,
        label = 'LED sencillo ámbar',
        icon = 'kq_police_led_1_amber.webp',
        animation = {
            delay = 'auto',
            dict = 'anim@kq_police_led_1',
            name = 'kq_police_led_1',
        },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },

    ['kq_police_led_4_red'] = {
        order = 114,
        label = 'LED mini rojo',
        icon = 'kq_police_led_4_red.webp',
        animation = {
            delay = 'auto',
            dict = 'anim@kq_police_led_1',
            name = 'kq_police_led_1',
        },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },
    ['kq_police_led_4_blue'] = {
        order = 115,
        label = 'LED mini azul',
        icon = 'kq_police_led_4_blue.webp',
        animation = {
            delay = 'auto',
            dict = 'anim@kq_police_led_1',
            name = 'kq_police_led_1',
        },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },
    ['kq_police_led_4_white'] = {
        order = 116,
        label = 'LED mini blanco',
        icon = 'kq_police_led_4_white.webp',
        animation = {
            delay = 'auto',
            dict = 'anim@kq_police_led_1',
            name = 'kq_police_led_1',
        },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },
    ['kq_police_led_4_amber'] = {
        order = 117,
        label = 'LED mini ámbar',
        icon = 'kq_police_led_4_amber.webp',
        animation = {
            delay = 'auto',
            dict = 'anim@kq_police_led_1',
            name = 'kq_police_led_1',
        },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },

    ['kq_police_led_7_red'] = {
        order = 118,
        label = 'LED discreto rojo',
        icon = 'kq_police_led_7_red.webp',
        animation = {
            delay = 'auto',
            dict = 'anim@kq_police_led_1',
            name = 'kq_police_led_1',
        },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },
    ['kq_police_led_7_blue'] = {
        order = 119,
        label = 'LED discreto azul',
        icon = 'kq_police_led_7_blue.webp',
        animation = {
            delay = 'auto',
            dict = 'anim@kq_police_led_1',
            name = 'kq_police_led_1',
        },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },
    ['kq_police_led_7_white'] = {
        order = 120,
        label = 'LED discreto blanco',
        icon = 'kq_police_led_7_white.webp',
        animation = {
            delay = 'auto',
            dict = 'anim@kq_police_led_1',
            name = 'kq_police_led_1',
        },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },
    ['kq_police_led_7_amber'] = {
        order = 121,
        label = 'LED discreto ámbar',
        icon = 'kq_police_led_7_amber.webp',
        animation = {
            delay = 'auto',
            dict = 'anim@kq_police_led_1',
            name = 'kq_police_led_1',
        },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },

    ['kq_police_led_5_redblue'] = {
        order = 122,
        label = 'Barra LED ancha roja y azul',
        icon = 'kq_police_led_5_redblue.webp',
        animation = {
            delay = 'auto',
            dict = 'anim@kq_police_led_2',
            name = 'kq_police_led_2',
        },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 180),
        }
    },
    ['kq_police_led_5_blueblue'] = {
        order = 123,
        label = 'Barra LED ancha azul',
        icon = 'kq_police_led_5_blueblue.webp',
        animation = {
            delay = 'auto',
            dict = 'anim@kq_police_led_2',
            name = 'kq_police_led_2',
        },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 180),
        }
    },
    ['kq_police_led_5_redred'] = {
        order = 124,
        label = 'Barra LED ancha roja',
        icon = 'kq_police_led_5_redred.webp',
        animation = {
            delay = 'auto',
            dict = 'anim@kq_police_led_2',
            name = 'kq_police_led_2',
        },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 180),
        }
    },
    ['kq_police_led_5_amberamber'] = {
        order = 125,
        label = 'Barra LED ancha ámbar',
        icon = 'kq_police_led_5_amberamber.webp',
        animation = {
            delay = 'auto',
            dict = 'anim@kq_police_led_2',
            name = 'kq_police_led_2',
        },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 180),
        }
    },

    ['kq_police_led_6_red'] = {
        order = 126,
        label = 'Tira LED roja',
        icon = 'kq_police_led_6_red.webp',
        animation = {
            delay = 'auto',
            dict = 'anim@kq_police_led_6',
            name = 'kq_police_led_6',
        },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },
    ['kq_police_led_6_blue'] = {
        order = 127,
        label = 'Tira LED azul',
        icon = 'kq_police_led_6_blue.webp',
        animation = {
            delay = 'auto',
            dict = 'anim@kq_police_led_6',
            name = 'kq_police_led_6',
        },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },
    ['kq_police_led_6_white'] = {
        order = 128,
        label = 'Tira LED blanca',
        icon = 'kq_police_led_6_white.webp',
        animation = {
            delay = 'auto',
            dict = 'anim@kq_police_led_6',
            name = 'kq_police_led_6',
        },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },
    ['kq_police_led_6_amber'] = {
        order = 129,
        label = 'Tira LED ámbar',
        icon = 'kq_police_led_6_amber.webp',
        animation = {
            delay = 'auto',
            dict = 'anim@kq_police_led_6',
            name = 'kq_police_led_6',
        },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },

    ['kq_police_beacon_blue'] = {
        order = 201,
        label = 'Rotativo de techo azul',
        icon = 'kq_police_beacon_blue.webp',

        animation = { dict = 'anim@kq_beacon_light', name = 'kq_beacon_light' },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },

    ['kq_police_beacon_red'] = {
        order = 202,
        label = 'Rotativo de techo rojo',
        icon = 'kq_police_beacon_red.webp',

        animation = { dict = 'anim@kq_beacon_light', name = 'kq_beacon_light' },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },

    ['kq_police_beacon_amber'] = {
        order = 203,
        label = 'Rotativo de techo ámbar',
        icon = 'kq_police_beacon_amber.webp',

        animation = { dict = 'anim@kq_beacon_light', name = 'kq_beacon_light' },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },

    ['kq_police_stop_sign'] = {
        order = 301,
        label = 'Señal de stop',
        icon = 'kq_police_stop_sign.webp',

        animation = { dict = 'anim@kq_police_stop_sign', name = 'kq_police_stop_sign' },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },

    ['kq_police_spotlight_1'] = {
        order = 302,
        label = 'Foco lateral',
        icon = 'kq_police_spotlight_1.webp',
        onHighBeams = true,
        animation = { dict = 'anim@kq_police_spotlight', name = 'kq_police_spotlight' },
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },

    ['kq_police_alpr'] = {
        order = 303,
        label = 'Lector de matrículas',
        icon = 'kq_police_alpr.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },

    ['kq_police_pushbar_1'] = {
        order = 304,
        label = 'Defensa delantera',
        icon = 'kq_police_pushbar_1.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },

    ['kq_police_antenna'] = {
        order = 305,
        label = 'Antena',
        icon = 'kq_police_antenna.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },

    ['kq_police_radio'] = {
        order = 306,
        label = 'Equipo de radio',
        icon = 'kq_police_radio.webp',

        animation = nil,
        offset = {
            position = vec3(0.05, 0.5, -0.7),
            rotation = vec3(0, 0, 0),
        }
    },

    ['kq_police_laptop'] = {
        order = 307,
        label = 'Ordenador portátil',
        icon = 'kq_police_laptop.webp',

        animation = nil,
        offset = {
            position = vec3(0.05, 0.5, -0.7),
            rotation = vec3(0, 0, 0),
        }
    },

    ['kq_police_decal_1'] = {
        order = 401,
        label = 'Vinilo 1',
        icon = 'kq_police_decal_1.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },

    ['kq_police_decal_2'] = {
        order = 402,
        label = 'Vinilo 2',
        icon = 'kq_police_decal_2.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },

    ['kq_police_decal_3'] = {
        order = 403,
        label = 'Vinilo 3',
        icon = 'kq_police_decal_3.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 90),
        }
    },

    ['kq_police_decal_4'] = {
        order = 404,
        label = 'Vinilo 4',
        icon = 'kq_police_decal_4.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },

    ['kq_police_decal_5'] = {
        order = 405,
        label = 'Vinilo 5',
        icon = 'kq_police_decal_5.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },

    ['kq_police_decal_6'] = {
        order = 406,
        label = 'Vinilo 6',
        icon = 'kq_police_decal_6.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },

    ['kq_police_decal_7'] = {
        order = 407,
        label = 'Vinilo 7',
        icon = 'kq_police_decal_7.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },

    ['kq_police_decal_8'] = {
        order = 408,
        label = 'Vinilo 8',
        icon = 'kq_police_decal_8.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },

    ['kq_police_decal_9'] = {
        order = 409,
        label = 'Vinilo 9',
        icon = 'kq_police_decal_9.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },

    ['kq_police_decal_10'] = {
        order = 410,
        label = 'Vinilo 10',
        icon = 'kq_police_decal_10.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },

    ['kq_police_decal_11'] = {
        order = 411,
        label = 'Vinilo 11',
        icon = 'kq_police_decal_11.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },

    ['kq_police_decal_12'] = {
        order = 412,
        label = 'Vinilo 12',
        icon = 'kq_police_decal_12.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },

    ['kq_police_decal_13'] = {
        order = 413,
        label = 'Vinilo 13',
        icon = 'kq_police_decal_13.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },

    ['kq_police_decal_14'] = {
        order = 414,
        label = 'Vinilo 14',
        icon = 'kq_police_decal_14.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },

    ['kq_police_decal_15'] = {
        order = 415,
        label = 'Vinilo 15',
        icon = 'kq_police_decal_15.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },

    ['kq_police_decal_16'] = {
        order = 416,
        label = 'Vinilo 16',
        icon = 'kq_police_decal_16.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },

    ['kq_police_decal_17'] = {
        order = 417,
        label = 'Vinilo 17',
        icon = 'kq_police_decal_17.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },

    ['kq_police_decal_18'] = {
        order = 418,
        label = 'Vinilo 18',
        icon = 'kq_police_decal_18.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },

    ['kq_police_decal_19'] = {
        order = 419,
        label = 'Vinilo 19',
        icon = 'kq_police_decal_19.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },

    ['kq_police_decal_20'] = {
        order = 420,
        label = 'Vinilo 20',
        icon = 'kq_police_decal_20.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },

    ['kq_police_decal_21'] = {
        order = 421,
        label = 'Vinilo 21',
        icon = 'kq_police_decal_21.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },

    ['kq_police_decal_22'] = {
        order = 422,
        label = 'Vinilo 22',
        icon = 'kq_police_decal_22.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },

    ['kq_police_decal_23'] = {
        order = 423,
        label = 'Vinilo 23',
        icon = 'kq_police_decal_23.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },

    ['kq_police_decal_24'] = {
        order = 424,
        label = 'Vinilo 24',
        icon = 'kq_police_decal_24.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },

    ['kq_police_decal_25'] = {
        order = 425,
        label = 'Vinilo 25',
        icon = 'kq_police_decal_25.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },

    ['kq_police_decal_26'] = {
        order = 426,
        label = 'Vinilo 26',
        icon = 'kq_police_decal_26.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },

    ['kq_police_decal_27'] = {
        order = 427,
        label = 'Vinilo 27',
        icon = 'kq_police_decal_27.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },

    ['kq_police_decal_28'] = {
        order = 428,
        label = 'Vinilo 28',
        icon = 'kq_police_decal_28.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        }
    },

    ['kq_police_decal_29'] = {
        order = 429,
        label = 'Vinilo 29',
        icon = 'kq_police_decal_29.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 90),
        }
    },

    ['kq_police_decal_30'] = {
        order = 430,
        label = 'Vinilo 30',
        icon = 'kq_police_decal_30.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 90),
        }
    },

    ['kq_police_decal_31'] = {
        order = 431,
        label = 'Vinilo 31',
        icon = 'kq_police_decal_31.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 90),
        }
    },

    ['kq_police_decal_32'] = {
        order = 432,
        label = 'Vinilo 32',
        icon = 'kq_police_decal_32.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 90),
        }
    },

    ['kq_police_decal_33'] = {
        order = 433,
        label = 'Vinilo 33',
        icon = 'kq_police_decal_33.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 90),
        }
    },

    ['kq_police_decal_34'] = {
        order = 434,
        label = 'Vinilo 34',
        icon = 'kq_police_decal_34.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 90),
        }
    },

    ['kq_police_callsign_0'] = {
        order = 501,
        label = 'Indicativo 0',
        icon = 'kq_police_callsign_0.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, -1),
            rotation = vec3(0, 90, 90),
        }
    },

    ['kq_police_callsign_1'] = {
        order = 502,
        label = 'Indicativo 1',
        icon = 'kq_police_callsign_1.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, -1),
            rotation = vec3(0, 90, 90),
        }
    },

    ['kq_police_callsign_2'] = {
        order = 503,
        label = 'Indicativo 2',
        icon = 'kq_police_callsign_2.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, -1),
            rotation = vec3(0, 90, 90),
        }
    },

    ['kq_police_callsign_3'] = {
        order = 504,
        label = 'Indicativo 3',
        icon = 'kq_police_callsign_3.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, -1),
            rotation = vec3(0, 90, 90),
        }
    },

    ['kq_police_callsign_4'] = {
        order = 505,
        label = 'Indicativo 4',
        icon = 'kq_police_callsign_4.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, -1),
            rotation = vec3(0, 90, 90),
        }
    },

    ['kq_police_callsign_5'] = {
        order = 506,
        label = 'Indicativo 5',
        icon = 'kq_police_callsign_5.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, -1),
            rotation = vec3(0, 90, 90),
        }
    },

    ['kq_police_callsign_6'] = {
        order = 507,
        label = 'Indicativo 6',
        icon = 'kq_police_callsign_6.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, -1),
            rotation = vec3(0, 90, 90),
        }
    },

    ['kq_police_callsign_7'] = {
        order = 508,
        label = 'Indicativo 7',
        icon = 'kq_police_callsign_7.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, -1),
            rotation = vec3(0, 90, 90),
        }
    },

    ['kq_police_callsign_8'] = {
        order = 509,
        label = 'Indicativo 8',
        icon = 'kq_police_callsign_8.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, -1),
            rotation = vec3(0, 90, 90),
        }
    },

    ['kq_police_callsign_9'] = {
        order = 510,
        label = 'Indicativo 9',
        icon = 'kq_police_callsign_9.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, -1),
            rotation = vec3(0, 90, 90),
        }
    },

    ['kq_police_callsign_hash'] = {
        order = 511,
        label = 'Indicativo #',
        icon = 'kq_police_callsign_hash.webp',

        animation = nil,
        offset = {
            position = vec3(0, 0, -1),
            rotation = vec3(0, 90, 90),
        }
    },

    ['kq_police_decal_c_1'] = {
        order = 611,
        label = 'Vinilo propio 1',
        icon = '../../../custom_decals/1.png',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 90),
        }
    },
    ['kq_police_decal_c_2'] = {
        order = 612,
        label = 'Vinilo propio 2',
        icon = '../../../custom_decals/2.png',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 90),
        }
    },
    ['kq_police_decal_c_3'] = {
        order = 613,
        label = 'Vinilo propio 3',
        icon = '../../../custom_decals/3.png',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 90),
        }
    },
    ['kq_police_decal_c_4'] = {
        order = 614,
        label = 'Vinilo propio 4',
        icon = '../../../custom_decals/4.png',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 90),
        }
    },
    ['kq_police_decal_c_5'] = {
        order = 615,
        label = 'Vinilo propio 5',
        icon = '../../../custom_decals/5.png',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 90),
        }
    },
    ['kq_police_decal_c_6'] = {
        order = 616,
        label = 'Vinilo propio 6',
        icon = '../../../custom_decals/6.png',

        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 90),
        }
    },
    ['kq_police_decal_c_7'] = {
        order = 617,
        label = 'Vinilo propio 7',
        icon = '../../../custom_decals/7.png',
        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 90),
        },
    },
    ['kq_police_decal_c_8'] = {
        order = 618,
        label = 'Vinilo propio 8',
        icon = '../../../custom_decals/8.png',
        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 90),
        },
    },
    ['kq_police_decal_c_9'] = {
        order = 619,
        label = 'Vinilo propio 9',
        icon = '../../../custom_decals/9.png',
        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 90),
        },
    },
    ['kq_police_decal_c_10'] = {
        order = 620,
        label = 'Vinilo propio 10',
        icon = '../../../custom_decals/10.png',
        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 90),
        },
    },
    ['kq_police_decal_c_11'] = {
        order = 621,
        label = 'Vinilo propio 11',
        icon = '../../../custom_decals/11.png',
        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 90),
        },
    },
    ['kq_police_decal_c_12'] = {
        order = 622,
        label = 'Vinilo propio 12',
        icon = '../../../custom_decals/12.png',
        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 90),
        },
    },
    ['kq_police_decal_c_13'] = {
        order = 623,
        label = 'Vinilo propio 13',
        icon = '../../../custom_decals/13.png',
        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 90),
        },
    },
    ['kq_police_decal_c_14'] = {
        order = 624,
        label = 'Vinilo propio 14',
        icon = '../../../custom_decals/14.png',
        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 90),
        },
    },
    ['kq_police_decal_c_15'] = {
        order = 625,
        label = 'Vinilo propio 15',
        icon = '../../../custom_decals/15.png',
        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 90),
        },
    },
    ['kq_police_decal_c_16'] = {
        order = 626,
        label = 'Vinilo propio 16',
        icon = '../../../custom_decals/16.png',
        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 90),
        },
    },
    ['kq_police_decal_c_17'] = {
        order = 627,
        label = 'Vinilo propio 17',
        icon = '../../../custom_decals/17.png',
        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 90),
        },
    },
    ['kq_police_decal_c_18'] = {
        order = 628,
        label = 'Vinilo propio 18',
        icon = '../../../custom_decals/18.png',
        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 90),
        },
    },
    ['kq_police_decal_c_19'] = {
        order = 629,
        label = 'Vinilo propio 19',
        icon = '../../../custom_decals/19.png',
        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 90),
        },
    },
    ['kq_police_decal_c_20'] = {
        order = 630,
        label = 'Vinilo propio 20',
        icon = '../../../custom_decals/20.png',
        animation = nil,
        offset = {
            position = vec3(0, 0, 0),
            rotation = vec3(0, 0, 90),
        },
    },
}

Settings.audio = {
    ['OFF'] = { -- DO NOT MODIFY THIS STATE
        order = 1,
        label = 'Apagada',
        sound = nil,
        lights = false,
        required = true,
    },
    ['LIGHTS_ONLY'] = { -- DO NOT MODIFY THIS STATE
        order = 2,
        label = 'Solo luces',
        sound = nil,
        lights = true,
        required = true,
    },
    ['VEHICLES_HORNS_SIREN_1'] = {
        order = 3,
        label = 'Normal principal',
        sound = 'VEHICLES_HORNS_SIREN_1',
        lights = true,
        -- Set a list of jobs to set a whitelist for this equipment object
        jobsWhitelist = {},
    },
    ['VEHICLES_HORNS_SIREN_2'] = {
        order = 4,
        label = 'Normal secundaria',
        sound = 'VEHICLES_HORNS_SIREN_2',
        lights = true,
    },
    ['sirens_slow_dir6'] = {
        order = 5,
        label = 'NOOSE larga',
        sound = 'sirens_slow_dir6',
        lights = true,
    },
    ['fast_9oghrv3'] = {
        order = 6,
        label = 'NOOSE rápida',
        sound = 'fast_9oghrv3',
        lights = true,
    },
    ['RESIDENT_VEHICLES_SIREN_WAIL_02'] = {
        order = 7,
        label = 'FIB larga',
        sound = 'RESIDENT_VEHICLES_SIREN_WAIL_02',
        lights = true,
    },
    ['RESIDENT_VEHICLES_SIREN_QUICK_02'] = {
        order = 8,
        label = 'FIB rápida',
        sound = 'RESIDENT_VEHICLES_SIREN_QUICK_02',
        lights = true,
    },
    ['RESIDENT_VEHICLES_SIREN_WAIL_03'] = {
        order = 9,
        label = 'Moto larga',
        sound = 'RESIDENT_VEHICLES_SIREN_WAIL_03',
        lights = true,
    },
    ['RESIDENT_VEHICLES_SIREN_QUICK_03'] = {
        order = 10,
        label = 'Moto rápida',
        sound = 'RESIDENT_VEHICLES_SIREN_QUICK_03',
        lights = true,
    },
    ['RESIDENT_VEHICLES_SIREN_WAIL_01'] = {
        order = 11,
        label = 'Ambulancia larga',
        sound = 'RESIDENT_VEHICLES_SIREN_WAIL_01',
        lights = true,
    },
    ['RESIDENT_VEHICLES_SIREN_QUICK_01'] = {
        order = 12,
        label = 'Ambulancia rápida',
        sound = 'RESIDENT_VEHICLES_SIREN_QUICK_01',
        lights = true,
    },
    ['RESIDENT_VEHICLES_SIREN_FIRETRUCK_WAIL_01'] = {
        order = 13,
        label = 'Bomberos larga',
        sound = 'RESIDENT_VEHICLES_SIREN_FIRETRUCK_WAIL_01',
        lights = true,
    },
    ['RESIDENT_VEHICLES_SIREN_FIRETRUCK_QUICK_01'] = {
        order = 14,
        label = 'Bomberos rápida',
        sound = 'RESIDENT_VEHICLES_SIREN_FIRETRUCK_QUICK_01',
        lights = true,
    },
}
