Config.RenderDistance = 200

Config.Ipls = {
    ['3-car-garage'] = {
        type = 'ipl',
        exit = vec4(198.47, -1005.6, -100.0, 359.44),
        spawns = {
            vec4(193.19, -996.12, -99.98, 182.00),
            vec4(197.94, -995.89, -99.98, 182.00),
            vec4(203.66, -997.5, -99.98, 143.03)
        }
    },
    ['bkr_biker_interior_placement_interior_1_biker_dlc_int_02_milo'] = {
        type = 'ipl',
        exit = vector4(999.11, -3164.38, -39.91, 271.9),
        spawns = {
            vector4(1004.87, -3159.28, -39.51, 90.38),
            vector4(1004.94, -3162.46, -39.51, 90.52),
            vector4(1003.07, -3171.13, -39.51,  0.38),
            vector4(1000.01, -3171.30, -39.51,  0.76),
        }
    }
}

Config.Shells = {
    ['aw_origen_garage_deluxe1_shell'] = {
        model = 'aw_origen_garage_deluxe1_shell',
        exit = vector4(1.482544, 7.091827, 0.010033, 182.385559),
        spawns = {
            vector4(6.082733, 5.945587, 0.0, 91.293152),
            vector4(6.106964, 0.883057, 0.0, 90.313957),
            vector4(6.020630, -4.182404, 0.0, 89.694855)
        }
    },
    ['aw_origen_garage_deluxe2_shell'] = {
        model = 'aw_origen_garage_deluxe2_shell',
        exit = vector4(5.477997, -1.569733, 0.026108, 93.841911),
        spawns = {
            vector4(-2.853760, -8.924988, 0.0, 269.663422),
            vector4(-3.100739, -3.912476, 0.0, 269.041687),
            vector4(-3.094574, 1.074371, 0.0, 270.146027),
            vector4(-2.950867, 6.078888, 0.0, 268.903717)
        }
    },  
    ['aw_origen_garage_deluxe3_shell'] = {
        model = 'aw_origen_garage_deluxe3_shell',
        exit = vector4(0.026886, -13.538055, 1.313049, 1.765960),
        spawns = {
            vector4(-5.149658, 11.918640, 0.0, 313.972656),
            vector4(-4.998535, 7.053253, 0.0, 314.115967),
            vector4(-5.211700, 1.846985, 0.0, 314.986084),
            vector4(-5.067200, -3.185364, 0.0, 314.641937),
            vector4(5.108673, 11.964966, 0.0, 44.384274),
            vector4(5.155487, 6.879639, 0.0, 45.541248),
            vector4(5.281403, 1.723663, 0.0, 44.614094),
            vector4(5.229309, -3.263092, 0.0, 44.904591)
        }
    }
}

Config.Interiors = {
    ['3-car-garage'] = {
        name = '3 Cars Garage',
        type = 'ipl',
        interior = Config.Ipls['3-car-garage'],
    },
    ['aw_origen_garage_deluxe1_shell'] = {
        name = 'Deluxe Garage 1',
        type = 'shell',
        interior = Config.Shells['aw_origen_garage_deluxe1_shell'],
    },
    ['aw_origen_garage_deluxe2_shell'] = {
        name = 'Deluxe Garage 2',
        type = 'shell',
        interior = Config.Shells['aw_origen_garage_deluxe2_shell'],
    },
    ['aw_origen_garage_deluxe3_shell'] = {
        name = 'Deluxe Garage 3',
        type = 'shell',
        interior = Config.Shells['aw_origen_garage_deluxe3_shell'],
    },
    ['bkr_biker_interior_placement_interior_1_biker_dlc_int_02_milo'] = {
        name = 'Biker Garage',
        type = 'ipl',
        interior = Config.Ipls['bkr_biker_interior_placement_interior_1_biker_dlc_int_02_milo'],
    }
}