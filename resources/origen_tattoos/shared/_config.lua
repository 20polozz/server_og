Config = {}

Config.Stores = {
    {
        coords = vector3(-1146.5, -1427.5, 1.31), 
        blip = true,
        customer = {
            chair = vector4(-1146.84, -1425.47, 1.48, 184.49),
            coords = vector4(-1146.88, -1425.04, 0.3, 187.93),
            anim = 'customer_loop',
            dict = 'misstattoo_parlour@shop_ig_4',
        },
        employee = {
            idle = {
                coords = vector4(-1149.1, -1425.74, 1.31, 227.56),
                anim = 'base',
                dict = 'rcmnigel1a',
            },
            tattoo = {
                coords = vector4(-1147.63, -1424.74, 1.31, 285.69),
                anim = 'tattooist_loop',
                dict = 'misstattoo_parlour@shop_ig_4',
            },
            model = 'IG_DJSolMike',
        },
    },

    {
        coords = vector3(319.77, 187.65, 99.88), 
        blip = true,
        customer = {
            chair = vector4(317.68, 185.73, 100.39, 317.38),
            coords = vector4(317.49, 185.72, 98.79, 317.38),
            anim = 'customer_loop',
            dict = 'misstattoo_parlour@shop_ig_4',
        },
        employee = {
            idle = {
                coords = vector4(319.66, 184.86, 99.88, 356.7),
                anim = 'base',
                dict = 'rcmnigel1a',
            },
            tattoo = {
                coords = vector4(317.78, 185.01, 99.88, 40.35),
                anim = 'tattooist_loop',
                dict = 'misstattoo_parlour@shop_ig_4',
            },
            model = 'IG_DJSolMike',
        },
    },

    {
        coords = vector3(1952.92, 3817.78, 32.48), 
        blip = true,
        customer = {
            chair = vector4(1952.09, 3816.97, 31.98, 274.35),
            coords = vector4(1952.09, 3816.97, 31.28, 274.35),
            anim = 'customer_loop',
            dict = 'misstattoo_parlour@shop_ig_4',
        },
        employee = {
            idle = {
                coords = vector4(1952.37, 3815.11, 32.47, 298.76),
                anim = 'base',
                dict = 'rcmnigel1a',
            },
            tattoo = {
                coords = vector4(1951.92, 3816.1, 32.48, 1.17),
                anim = 'tattooist_loop',
                dict = 'misstattoo_parlour@shop_ig_4',
            },
            model = 'IG_DJSolMike',
        },
    }
}

Config.Prop = {
    model = 'v_ilev_ta_tatgun',
    bone = 60309,
    xPos = 0.09,
    yPos = 0.06,
    zPos = 0.036,
    xRot = 0.0,
    yRot = -110.0,
    zRot = -90.0,
}

Config.TattooListsPath = 'assets_tattoos/'

Config.TattooLists = { 
    'BaseTattoos',
    'DLC_enterprise',
    'DLC_mpchristmas3',
    'DLC_mpheist3',
    'DLC_mpheist4',
    'DLC_mpsecurity',
    'DLC_mpvinewood',
    'HairFades',
    'HairFades2',
    'ogntattoo'
    -- 'spain',
}

Config.Cameras = {
    ['default'] = {
        vec3(0, 2.2, 0.2),
        vec3(0, 0, -0.05),
    },
    ['head'] = {
        vec3(0, 0.9, 0.65),
        vec3(0, 0, 0.6),
    },
    ['torso'] = {
        vec3(0, 1.2, 0.2),
        vec3(0, 0, 0.2),
    },
    ['arms'] = {
        vec3(0.0, 1.0, 0.1),
        vec3(0.0, 0.0, 0.1)
    },
    ['legs'] = {
        vec3(0.0, 1.2, -0.6),
        vec3(0.0, 0.0, -0.6)
    },
    ['degradado'] = {
        vec3(0, 0.6, 0.8),
        vec3(0, 0, 0.7),
    },
    ['customs'] = {
        vec3(0, 1.2, 0.2),
        vec3(0, 0, 0.2),
    },

    ['tattoo'] = {
        vec3(0.0, 2.0, 0.4),
        vec3(0.0, 0.0, 0.2),
    },
}

Config.ZoneLabels = {
    ['head'] = 'Cabeza',
    ['torso'] = 'Torso',
    ['arms'] = 'Brazos',
    ['legs'] = 'Piernas',
    ['degradado'] = 'Degradados',
    ['customs'] = 'Personalizados',
}

--[[ Lo que lleva el personaje mientras esta en el tatuador: todo fuera menos
     la ropa interior, para que se vean los tatuajes de cualquier zona.
     Hombre con el pantalon 0 (4:0, el "sin pantalon" del menu de ropa; el
     4:61 de antes ahora es un pantalon y tapaba las piernas); mujer en bikini negro (arriba 11:15,
     abajo 4:15; el 4:10 es un pantalon corto). Visto en el juego el 17/09.
     [componente] = {dibujo, textura}. Los props (gorra, gafas, pendientes,
     reloj, pulsera) se quitan todos. ]]
Config.Clothes = {
    male = {
        [1]  = {0, 0},   -- mascara
        [3]  = {15, 0},  -- brazos al aire
        [4]  = {14, 0},  -- pantalon corto de deporte: lo mas corto que hay (el 0 son vaqueros y el 61 ya no son calzoncillos)
        [5]  = {0, 0},   -- mochila
        [6]  = {5, 0},   -- chanclas (el 34 aqui son zapatillas; descalzo no hay)
        [7]  = {0, 0},   -- collar / corbata
        [8]  = {15, 0},  -- camiseta interior
        [9]  = {0, 0},   -- chaleco
        [10] = {0, 0},   -- parches
        [11] = {15, 0},  -- torso al aire
    },
    female = {
        [1]  = {0, 0},   -- mascara
        [3]  = {15, 0},  -- brazos al aire
        [4]  = {15, 0},  -- bikini (abajo)
        [5]  = {0, 0},   -- mochila
        [6]  = {5, 0},   -- chanclas (el 35 aqui son zapatillas; descalza no hay)
        [7]  = {0, 0},   -- collar
        [8]  = {14, 0},  -- camiseta interior
        [9]  = {0, 0},   -- chaleco
        [10] = {0, 0},   -- parches
        [11] = {15, 0},  -- bikini (arriba)
    },
}