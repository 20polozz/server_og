return {
    Debug = false,

    ---- PED
    InitiatorPed = {
        model = `a_m_m_farmer_01`,
        position = vec4(1299.07, 4215.15, 32.91, 171.64),
        scenario = 'WORLD_HUMAN_STAND_FISHING',
        menu = 'OpenFishingMenu',
        blip = {
            name = 'Pesca',
            sprite = 68,
            color = 4
        }
    },

    GameZone = {
        coords = vector3(1108.9309, -634.5004, 56.8161),
        radius = 60.0,
        timeLeft = {

        },
        zones = {
            {
                name = "fishZone1",
                points = {
                    vec3(1713.83, 4516.5, 33.25),
                    vec3(1473.38, 4338.56, 32.13),
                    vec3(1385.76, 4274.51, 35.82),
                    vec3(1268.47, 4322.22, 35.33),
                    vec3(1099.01, 4274.08, 31.32),
                    vec3(1074.93, 4202.63, 31.8),
                    vec3(857.14, 4426.81, 31.95),
                    vec3(897.36, 4340.68, 31.12),
                    vec3(921.12, 4224.42, 33.01),
                    vec3(832.29, 4047.83, 29.67),
                    vec3(622.37, 4046.6, 33.68),
                    vec3(570.93, 4153.46, 34.66),
                    vec3(511.36, 4152.76, 45.96),
                    vec3(412.24, 4330.14, 38.66),
                    vec3(306.52, 4233.19, 36.5),
                    vec3(244.17, 4282.0, 32.48),
                    vec3(142.86, 4311.5, 44.8),
                    vec3(-22.37, 4383.27, 39.3),
                    vec3(-89.33, 4257.03, 32.56),
                    vec3(-174.29, 4214.93, 32.54),
                    vec3(-225.11, 4071.32, 31.7),
                    vec3(-184.59, 3985.74, 31.73),
                    vec3(-151.01, 3847.23, 30.9),
                    vec3(-80.01, 3733.31, 32.1),
                    vec3(42.02, 3804.24, 31.65),
                    vec3(143.03, 3771.48, 31.61),
                    vec3(174.78, 3648.02, 31.49),
                    vec3(149.37, 3518.2, 31.53),
                    vec3(199.51, 3455.42, 31.43),
                    vec3(270.13, 3506.93, 31.35),
                    vec3(305.17, 3559.66, 32.03),
                    vec3(329.66, 3609.77, 32.28),
                    vec3(369.86, 3632.32, 32.0),
                    vec3(498.17, 3610.47, 33.03),
                    vec3(644.52, 3606.86, 32.39),
                    vec3(764.88, 3645.42, 31.78),
                    vec3(886.04, 3699.54, 31.37),
                    vec3(976.68, 3662.55, 31.2),
                    vec3(1172.33, 3648.27, 32.19),
                    vec3(1276.26, 3672.98, 32.36),
                    vec3(1432.28, 3756.96, 31.75),
                    vec3(1537.89, 3821.22, 32.32),
                    vec3(1702.91, 3943.84, 32.16),
                    vec3(1819.0, 3988.9, 31.25),
                },
                thickness = 30.0,
                waitTime = { min = 30, max = 50 },
                fishList = {
                    'grouper', 'tuna', 'shark', 'salmon', 'mahi_mahi', 'red_snapper', 'trout',
                    'anchovy', 'haddock', 'piranha', 'sardina', 'rutilo', 'pejerrey', 'perca',
                    'caballa', 'mojarra', 'anguila', 'lucio', 'rocote', 'calico_bass', 'sargo',
                    'siluro', 'lingcod', 'corvina', 'corvina_blanca', 'pez_globo', 'pez_gota',
                    'raya', 'halibut_california', 'halibut_pacifico', 'medregal', 'barracuda',
                    'pez_espada', 'tiburon_cornudo', 'tiburon_gris', 'tiburon_blanco',
                    'cangrejo', 'langosta', 'pulpo', 'mejillon', 'ostras', 'tortuga_verde',
                    'tortuga_olivacea', 'tortuga_laud', 'ballena_gris', 'ballena_jorobada',
                    'ballena_azul', 'bota_vieja', 'coral_negro', 'coral_pilar',
                    'llave_oxidada', 'cofre_oxidado'
                }
            },
            -- {
            --     name = "fishZone2",
            --     points = {
            --         vector3(1135.4248, -593.7076, 54.0),
            --         vector3(1073.8926, -579.1883, 54.0),
            --         vector3(1047.3610, -632.6810, 54.0),
            --         vector3(1117.5259, -632.9846, 54.0),
            --     },
            --     thickness = 4.0,
            --     waitTime = { min = 40, max = 65 },
            --     fishList = { 'mahi_mahi', 'red_snapper', 'shark', 'trout' }
            -- },
            -- {
            --     name = "fishZone3",
            --     points = {
            --         vector3(1112.7637, -636.5954, 54.0),
            --         vector3(1018.8344, -671.8329, 54.0),
            --         vector3(1092.5035, -744.1648, 54.0),
            --         vector3(1146.6046, -707.3939, 54.0),
            --     },
            --     thickness = 4.0,
            --     waitTime = { min = 25, max = 40 },
            --     fishList = { 'piranha', 'tuna', 'shark', 'salmon' }
            -- }
        }
    },

    Progression = {
        maxLevel = 20,
        xpCurve = function(level) return math.floor(110 * (level - 1) ^ 1.8) end,
        bonusCurve = function(level) return math.floor((level - 1) * 1.3) end,
        rankName = function(level)
            if level >= 20 then return 'Leyenda'
            elseif level >= 16 then return 'Maestro'
            elseif level >= 13 then return 'Patrón'
            elseif level >= 10 then return 'Experto'
            elseif level >= 7 then return 'Marinero'
            elseif level >= 4 then return 'Pescador'
            else return 'Novato' end
        end,
        tiers = {
            [1] = { name = 'Costa',       minLevel = 1  },
            [2] = { name = 'Bajura',      minLevel = 4  },
            [3] = { name = 'Altura',      minLevel = 8  },
            [4] = { name = 'Mar abierto', minLevel = 12 },
            [5] = { name = 'Abisal',      minLevel = 16 },
            [6] = { name = 'Leyenda',     minLevel = 20 },
        },
        tierDecay = 0.06,
        weightBiasBase = 2.6,
        weightBiasPerLevel = 0.08,
        weightBiasFloor = 1.05,
    },

    Fishes = {
        anchovy     = { price = { min = 8,      max = 14    }, weight = { min = 0.05, max = 0.25 }, rarity = 40, tier = 1, lineStrength = 1, tournamentPoints = 15,   skillcheck = { 'easy', 'medium' }, xp = 5 },
        trout       = { price = { min = 10,     max = 18    }, weight = { min = 0.4, max = 3.5 }, rarity = 35, tier = 1, lineStrength = 4, tournamentPoints = 10,   skillcheck = { 'easy', 'medium' }, xp = 8 },
        haddock     = { price = { min = 12,     max = 22    }, weight = { min = 0.6, max = 4.5 }, rarity = 30, tier = 1, lineStrength = 5, tournamentPoints = 20,   skillcheck = { 'easy', 'medium' }, xp = 10 },
        salmon      = { price = { min = 20,     max = 35    }, weight = { min = 1.5, max = 12.0 }, rarity = 20, tier = 2, lineStrength = 12, tournamentPoints = 40,   skillcheck = { 'easy', 'medium', 'medium' }, xp = 15 },
        grouper     = { price = { min = 15,     max = 25    }, weight = { min = 2.0, max = 18.0 }, rarity = 25, tier = 2, lineStrength = 18, tournamentPoints = 35,   skillcheck = { 'easy', 'medium', 'medium', 'medium' }, xp = 12 },
        piranha     = { price = { min = 25,     max = 40    }, weight = { min = 0.4, max = 3.0 }, rarity = 15, tier = 2, lineStrength = 3, tournamentPoints = 35,   skillcheck = { 'easy', 'medium', 'hard' }, xp = 18 },
        red_snapper = { price = { min = 30,     max = 45    }, weight = { min = 1.0, max = 9.0 }, rarity = 15, tier = 3, lineStrength = 9, tournamentPoints = 40,   skillcheck = { 'easy', 'medium', 'medium', 'medium' }, xp = 20 },
        mahi_mahi   = { price = { min = 35,     max = 55    }, weight = { min = 3.0, max = 20.0 }, rarity = 10, tier = 3, lineStrength = 20, tournamentPoints = 40,   skillcheck = { 'easy', 'medium', 'medium', 'medium' }, xp = 25 },
        tuna        = { price = { min = 50,     max = 80    }, weight = { min = 15.0, max = 120.0 }, rarity = 5, tier = 4, lineStrength = 120,  tournamentPoints = 45,   skillcheck = { 'easy', 'medium', 'hard' }, xp = 35 },
        shark       = { price = { min = 100,    max = 200   }, weight = { min = 40.0, max = 300.0 }, rarity = 2, tier = 5, lineStrength = 300,  tournamentPoints = 50,   skillcheck = { 'easy', 'medium', 'hard' }, xp = 100 },

        -- Catalogo ampliado
        sardina              = { price = { min = 6,   max = 11   }, weight = { min = 0.03,     max = 0.2      }, rarity = 45, tier = 1, lineStrength = 1, tournamentPoints = 8,   skillcheck = { 'easy', 'medium' }, xp = 4 },
        rutilo               = { price = { min = 8,   max = 14   }, weight = { min = 0.1,      max = 1.2      }, rarity = 42, tier = 1, lineStrength = 2, tournamentPoints = 10,  skillcheck = { 'easy', 'medium' }, xp = 6 },
        pejerrey             = { price = { min = 9,   max = 16   }, weight = { min = 0.15,     max = 1.4      }, rarity = 40, tier = 1, lineStrength = 2, tournamentPoints = 10,  skillcheck = { 'easy', 'medium' }, xp = 6 },
        perca                = { price = { min = 11,  max = 19   }, weight = { min = 0.15,     max = 1.6      }, rarity = 38, tier = 1, lineStrength = 2, tournamentPoints = 12,  skillcheck = { 'easy', 'medium' }, xp = 8 },
        caballa              = { price = { min = 12,  max = 21   }, weight = { min = 0.3,      max = 2.5      }, rarity = 35, tier = 1, lineStrength = 3, tournamentPoints = 14,  skillcheck = { 'easy', 'medium' }, xp = 9 },
        mojarra              = { price = { min = 12,  max = 20   }, weight = { min = 0.2,      max = 1.8      }, rarity = 35, tier = 1, lineStrength = 2, tournamentPoints = 12,  skillcheck = { 'easy', 'medium' }, xp = 8 },
        anguila              = { price = { min = 18,  max = 30   }, weight = { min = 0.4,      max = 4.5      }, rarity = 28, tier = 2, lineStrength = 5, tournamentPoints = 22,  skillcheck = { 'easy', 'medium', 'medium' }, xp = 14 },
        lucio                = { price = { min = 22,  max = 36   }, weight = { min = 1.0,      max = 9.0      }, rarity = 25, tier = 2, lineStrength = 9, tournamentPoints = 26,  skillcheck = { 'easy', 'medium', 'medium' }, xp = 16 },
        rocote               = { price = { min = 20,  max = 33   }, weight = { min = 0.6,      max = 5.0      }, rarity = 27, tier = 2, lineStrength = 5, tournamentPoints = 24,  skillcheck = { 'easy', 'medium', 'medium' }, xp = 15 },
        calico_bass          = { price = { min = 21,  max = 34   }, weight = { min = 0.5,      max = 4.0      }, rarity = 26, tier = 2, lineStrength = 4, tournamentPoints = 24,  skillcheck = { 'easy', 'medium', 'medium' }, xp = 15 },
        sargo                = { price = { min = 24,  max = 38   }, weight = { min = 1.5,      max = 14.0     }, rarity = 22, tier = 2, lineStrength = 14, tournamentPoints = 28,  skillcheck = { 'easy', 'medium', 'medium', 'medium' }, xp = 18 },
        siluro               = { price = { min = 26,  max = 42   }, weight = { min = 2.0,      max = 25.0     }, rarity = 20, tier = 3, lineStrength = 25, tournamentPoints = 30,  skillcheck = { 'easy', 'medium', 'medium', 'medium' }, xp = 20 },
        lingcod              = { price = { min = 28,  max = 45   }, weight = { min = 2.0,      max = 16.0     }, rarity = 20, tier = 3, lineStrength = 16, tournamentPoints = 30,  skillcheck = { 'easy', 'medium', 'medium', 'medium' }, xp = 20 },
        corvina              = { price = { min = 27,  max = 43   }, weight = { min = 1.0,      max = 3.5      }, rarity = 22, tier = 2, lineStrength = 4, tournamentPoints = 28,  skillcheck = { 'easy', 'medium', 'medium' }, xp = 18 },
        corvina_blanca       = { price = { min = 34,  max = 54   }, weight = { min = 3.0,      max = 30.0     }, rarity = 16, tier = 3, lineStrength = 30, tournamentPoints = 36,  skillcheck = { 'easy', 'medium', 'medium', 'medium' }, xp = 24 },
        pez_globo            = { price = { min = 40,  max = 65   }, weight = { min = 0.3,      max = 2.0      }, rarity = 10, tier = 4, lineStrength = 2, tournamentPoints = 42,  skillcheck = { 'easy', 'medium', 'hard' }, xp = 30 },
        pez_gota             = { price = { min = 45,  max = 75   }, weight = { min = 0.5,      max = 4.0      }, rarity = 7, tier = 5, lineStrength = 4,  tournamentPoints = 46,  skillcheck = { 'easy', 'medium', 'hard' }, xp = 34 },
        raya                 = { price = { min = 38,  max = 60   }, weight = { min = 2.0,      max = 40.0     }, rarity = 12, tier = 3, lineStrength = 40, tournamentPoints = 40,  skillcheck = { 'easy', 'medium', 'hard' }, xp = 28 },
        halibut_california   = { price = { min = 42,  max = 68   }, weight = { min = 2.0,      max = 25.0     }, rarity = 11, tier = 3, lineStrength = 25, tournamentPoints = 44,  skillcheck = { 'easy', 'medium', 'medium', 'medium' }, xp = 30 },
        halibut_pacifico     = { price = { min = 50,  max = 80   }, weight = { min = 5.0,      max = 90.0     }, rarity = 8, tier = 4, lineStrength = 90,  tournamentPoints = 50,  skillcheck = { 'easy', 'medium', 'hard' }, xp = 38 },
        medregal             = { price = { min = 44,  max = 70   }, weight = { min = 3.0,      max = 35.0     }, rarity = 10, tier = 4, lineStrength = 35, tournamentPoints = 46,  skillcheck = { 'easy', 'medium', 'hard' }, xp = 32 },
        barracuda            = { price = { min = 48,  max = 78   }, weight = { min = 2.0,      max = 20.0     }, rarity = 9, tier = 4, lineStrength = 20,  tournamentPoints = 48,  skillcheck = { 'easy', 'medium', 'hard' }, xp = 35 },
        pez_espada           = { price = { min = 70,  max = 115  }, weight = { min = 20.0,     max = 250.0    }, rarity = 5, tier = 5, lineStrength = 250,  tournamentPoints = 60,  skillcheck = { 'easy', 'medium', 'hard', 'hard' }, xp = 55 },
        tiburon_cornudo      = { price = { min = 55,  max = 90   }, weight = { min = 3.0,      max = 12.0     }, rarity = 8, tier = 4, lineStrength = 12,  tournamentPoints = 52,  skillcheck = { 'easy', 'medium', 'hard' }, xp = 40 },
        tiburon_gris         = { price = { min = 80,  max = 140  }, weight = { min = 15.0,     max = 120.0    }, rarity = 4, tier = 5, lineStrength = 120,  tournamentPoints = 65,  skillcheck = { 'easy', 'medium', 'hard', 'hard' }, xp = 70 },
        tiburon_blanco       = { price = { min = 160, max = 280  }, weight = { min = 400.0,    max = 1100.0   }, rarity = 1, tier = 6, lineStrength = 1100,  tournamentPoints = 90,  skillcheck = { 'easy', 'hard', 'hard', 'hard' }, xp = 130 },
        cangrejo             = { price = { min = 14,  max = 24   }, weight = { min = 0.2,      max = 2.5      }, rarity = 30, tier = 1, lineStrength = 3, tournamentPoints = 16,  skillcheck = { 'easy', 'medium' }, xp = 10 },
        langosta             = { price = { min = 55,  max = 90   }, weight = { min = 0.5,      max = 6.0      }, rarity = 8, tier = 4, lineStrength = 6,  tournamentPoints = 50,  skillcheck = { 'easy', 'medium', 'medium' }, xp = 36 },
        pulpo                = { price = { min = 46,  max = 74   }, weight = { min = 1.0,      max = 15.0     }, rarity = 10, tier = 3, lineStrength = 15, tournamentPoints = 44,  skillcheck = { 'easy', 'medium', 'hard' }, xp = 32 },
        mejillon             = { price = { min = 5,   max = 9    }, weight = { min = 0.03,     max = 0.3      }, rarity = 48, tier = 1, lineStrength = 1, tournamentPoints = 6,   skillcheck = { 'easy', 'medium' }, xp = 3 },
        ostras               = { price = { min = 16,  max = 28   }, weight = { min = 0.05,     max = 0.5      }, rarity = 26, tier = 2, lineStrength = 1, tournamentPoints = 18,  skillcheck = { 'easy', 'medium' }, xp = 12 },
        tortuga_verde        = { price = { min = 90,  max = 150  }, weight = { min = 70.0,     max = 190.0    }, rarity = 3, tier = 5, lineStrength = 190,  tournamentPoints = 70,  skillcheck = { 'easy', 'medium', 'hard', 'hard' }, xp = 80 },
        tortuga_olivacea     = { price = { min = 85,  max = 140  }, weight = { min = 30.0,     max = 50.0     }, rarity = 3, tier = 5, lineStrength = 50,  tournamentPoints = 68,  skillcheck = { 'easy', 'medium', 'hard', 'hard' }, xp = 75 },
        tortuga_laud         = { price = { min = 140, max = 230  }, weight = { min = 250.0,    max = 700.0    }, rarity = 1, tier = 6, lineStrength = 700,  tournamentPoints = 88,  skillcheck = { 'easy', 'hard', 'hard', 'hard' }, xp = 120 },
        ballena_gris         = { price = { min = 260, max = 420  }, weight = { min = 15000.0,  max = 30000.0  }, rarity = 1, tier = 6, lineStrength = 30000,  tournamentPoints = 110, skillcheck = { 'easy', 'hard', 'hard', 'hard' }, xp = 200 },
        ballena_jorobada     = { price = { min = 300, max = 480  }, weight = { min = 25000.0,  max = 36000.0  }, rarity = 1, tier = 6, lineStrength = 36000,  tournamentPoints = 118, skillcheck = { 'easy', 'hard', 'hard', 'hard' }, xp = 220 },
        ballena_azul         = { price = { min = 420, max = 700  }, weight = { min = 90000.0,  max = 150000.0 }, rarity = 1, tier = 6, lineStrength = 150000,  tournamentPoints = 140, skillcheck = { 'easy', 'hard', 'hard', 'hard' }, xp = 300 },
        bota_vieja           = { price = { min = 0,   max = 0    }, weight = { min = 0.6,      max = 1.4      }, rarity = 30, tier = 1, lineStrength = 2, tournamentPoints = 2,   skillcheck = { 'easy', 'medium' }, xp = 2 },
        coral_negro          = { price = { min = 30,  max = 50   }, weight = { min = 0.1,      max = 1.0      }, rarity = 10, tier = 2, lineStrength = 1, tournamentPoints = 20,  skillcheck = { 'easy', 'medium' }, xp = 14 },
        coral_pilar          = { price = { min = 34,  max = 56   }, weight = { min = 0.2,      max = 1.5      }, rarity = 9, tier = 3, lineStrength = 2,  tournamentPoints = 22,  skillcheck = { 'easy', 'medium' }, xp = 16 },
        llave_oxidada        = { price = { min = 0,   max = 0    }, weight = { min = 0.02,     max = 0.1      }, rarity = 6, tier = 3, lineStrength = 1,  tournamentPoints = 12,  skillcheck = { 'easy', 'medium' }, xp = 10 },
        cofre_oxidado        = { price = { min = 0,   max = 0    }, weight = { min = 1.0,      max = 6.0      }, rarity = 4, tier = 4, lineStrength = 6,  tournamentPoints = 25,  skillcheck = { 'easy', 'medium', 'medium' }, xp = 20 },
    },

    FishingRods = {
        basic_rod    = { price = 150,   breakChance = 20, minLevel = 1,  maxLoad = 5,      weightBias = 1.25, description = 'Una caña de pescar básica para principiantes' },
        graphite_rod = { price = 500,   breakChance = 12, minLevel = 3,  maxLoad = 25,     weightBias = 1.12, description = 'Caña de grafito. Aguanta hasta 25 kg' },
        carbon_rod   = { price = 1200,  breakChance = 8,  minLevel = 7,  maxLoad = 90,     weightBias = 1.00, description = 'Ligera y rígida. Aguanta hasta 90 kg' },
        titanium_rod = { price = 4000,  breakChance = 4,  minLevel = 12, maxLoad = 400,    weightBias = 0.92, description = 'Caña de titanio. Aguanta hasta 400 kg' },
        master_rod   = { price = 15000, breakChance = 2,  minLevel = 17, maxLoad = 200000, weightBias = 0.82, description = 'La última caña que vas a necesitar' },
    },

    Bait = {
        worms           = { price = 5,   minLevel = 1,  waitDivisor = 1.0,  tierWeights = { 2.5, 1.0, 0.3, 0.1,  0.05, 0.02 }, description = 'Gusanos básicos' },
        crickets        = { price = 8,   minLevel = 1,  waitDivisor = 1.05, tierWeights = { 2.2, 1.2, 0.3, 0.1,  0.05, 0.02 }, description = 'Saltan. Y atraen a los que saltan' },
        seaweed         = { price = 10,  minLevel = 1,  waitDivisor = 1.1,  tierWeights = { 2.0, 1.4, 0.5, 0.2,  0.1,  0.03 }, description = 'Para los que pastan en el fondo' },
        artificial_bait = { price = 15,  minLevel = 2,  waitDivisor = 1.5,  tierWeights = { 1.0, 1.0, 1.0, 1.0,  1.0,  1.0  }, description = 'Cebo artificial. No sesga nada, pero pican rapidísimo' },
        grasshopper     = { price = 12,  minLevel = 4,  waitDivisor = 1.15, tierWeights = { 1.2, 2.2, 0.8, 0.2,  0.1,  0.04 }, description = 'Grande y ruidoso en la superficie' },
        leech           = { price = 18,  minLevel = 4,  waitDivisor = 1.2,  tierWeights = { 0.8, 2.4, 1.2, 0.3,  0.15, 0.05 }, description = 'Repugnantes. Y muy eficaces' },
        minnows         = { price = 22,  minLevel = 8,  waitDivisor = 1.35, tierWeights = { 0.4, 1.4, 2.4, 1.0,  0.4,  0.1  }, description = 'Pez pequeño para pescar pez grande' },
        shrimp          = { price = 25,  minLevel = 8,  waitDivisor = 1.3,  tierWeights = { 0.5, 1.2, 2.2, 1.2,  0.5,  0.15 }, description = 'Camarones. Atrae peces grandes' },
        squid           = { price = 30,  minLevel = 12, waitDivisor = 1.4,  tierWeights = { 0.2, 0.6, 1.6, 2.6,  1.4,  0.5  }, description = 'Trozo de calamar. Para piezas marinas' },
        pig_bait        = { price = 120, minLevel = 16, waitDivisor = 1.5,  tierWeights = { 0.1, 0.3, 0.8, 2.2,  2.8,  1.4  }, description = 'Casquería. Huele a kilómetros' },
        cow_bait        = { price = 350, minLevel = 20, waitDivisor = 1.6,  tierWeights = { 0.05,0.1, 0.4, 1.4,  2.6,  3.0  }, description = 'Una pieza entera. Para lo más grande' },
    },

    --[[ Agotamiento del spot: tirar siempre desde el mismo punto castiga el tiempo
         de picada y el pool. Alejarse de `radius` reinicia el punto. ]]
    Depletion = {
        radius = 20.0,
        freeCasts = 4,
        secondsPerCast = 6,
        maxPenaltySeconds = 45,
        tierPenalty = 0.05,
        warnAt = 5,
        warnEvery = 3,
        recoverySeconds = 600,
    },

    Tournament = {
        duration = 30 * 60,
        intervalHours = 5,
        announce = true,

        leaderboardSize = 3,
        leaderboardInterval = 3,

        -- Cada edicion sortea una modalidad de esta lista. Quitar una entrada
        -- basta para sacarla de la rotacion.
        --   points  -> suma los tournamentPoints de cada pieza
        --   biggest -> puntua solo la pieza mas pesada, en kg
        --   species -> solo cuentan las capturas de la especie sorteada
        --   volume  -> una unidad por pieza, sin importar cual
        modes = {
            { id = 'points',  label = 'Puntuación',       unit = 'pts' },
            { id = 'biggest', label = 'Pieza mayor',      unit = 'kg'  },
            { id = 'species', label = 'Especie objetivo', unit = 'pts' },
            { id = 'volume',  label = 'Volumen',          unit = 'piezas' },
        },

        -- Premio del ganador. Se aplican TODAS las entradas de la lista, en orden.
        --   { type = 'money',  account = 'bank'|'cash', amount = n }
        --   { type = 'item',   name = 'item_name', amount = n, metadata = {} }
        --   { type = 'custom', fn = function(source) end }
        rewards = {
            { type = 'money', account = 'bank', amount = 5000 },
            { type = 'item',  name = 'artificial_bait', amount = 10 },
        },
    },

    Messages = {
        OnFish = {
            'Este pez es tan grande que casi te arrastra al agua.',
            '¡Felicidades! Acabas de pescar la cena... o la mascota.',
            '¡Lo lograste! Ahora, ¿cómo lo vas a explicar al veterinario?',
            '¡Has pescado un pez! Ahora solo falta enseñarle a ladrar.',
            '¡Victoria acuática! Ahora el pez es todo tuyo... ¡y de la sartén!',
            '¡Eso es! El pez ya está en tu lista de contactos... justo entre "cena" y "almuerzo".',
            '¡Felicidades! Este pez ahora tiene un nuevo propósito: alimentar a un campeón.'
        },

        OnFail = {
            '¡Wow! Este pez tiene más músculos que tú.',
            '¡Ese pez ya tiene más seguidores en Instagram que tú!',
            '¡Cuidado! Ese pez tiene cara de querer cobrarte por la foto.',
            '¡Ups! Ese pez te dejó en visto.',
            'A ese pez no le gustó tu cebo... ¿Probaste con sushi?',
            'El pez ha decidido que no eres su tipo... de pescador.',
            'Parece que el pez está más interesado en su carrera de natación que en tu anzuelo.'
        },

        OnDepleted = 'Por acá ya no pica nada. Probá moverte unos metros y volvé a tirar.'
    },

    OnReward = function(playerId)
        
    end
}