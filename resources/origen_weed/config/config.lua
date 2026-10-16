Config = Config or {}
Config.Weed = {}

Config.Weed.CopJob = 'police'
Config.Weed.Debug = false

Config.Weed.Items = {
    maleSeed    = 'weedplant_seedm',
    femaleSeed  = 'weedplant_seedf',
    plantTub    = 'plant_tub',
    emptyCan    = 'empty_watering_can',
    fullCan     = 'full_watering_can',
    fertilizer  = 'weed_nutrition',
    waterSource = 'water_bottle',
    clone       = 'weed_clone',
}

-- Cepas disponibles: cada una define su comportamiento único
-- growMultiplier > 1 = crece más LENTO | waterBonus/fertBonus > 1 = cada cuidado da más genética
Config.Weed.Strains = {
    og_kush = {
        label          = 'OG Kush',
        growMultiplier = 1.0,
        maxGenetics    = 70,
        waterDecay     = 1.0,
        fertDecay      = 1.0,
        waterBonus     = 1.0,
        fertBonus      = 1.0,
        maleBonus      = 1.0,
        seedBonusOnLegendary = false,
    },
    white_widow = {
        label          = 'White Widow',
        growMultiplier = 0.75,  -- 25% más rápida
        maxGenetics    = 55,    -- tope en Rara
        waterDecay     = 1.3,   -- seca más rápido
        fertDecay      = 0.8,
        waterBonus     = 1.4,   -- responde muy bien al agua
        fertBonus      = 1.0,
        maleBonus      = 1.0,
        seedBonusOnLegendary = false,
    },
    northern_lights = {
        label          = 'Northern Lights',
        growMultiplier = 1.5,   -- 50% más lenta
        maxGenetics    = 100,   -- puede llegar a Legendaria
        waterDecay     = 0.7,   -- muy resistente
        fertDecay      = 0.7,
        waterBonus     = 1.0,
        fertBonus      = 1.6,   -- fertilizante le da mucho más
        maleBonus      = 1.2,
        seedBonusOnLegendary = true,
    },
    gorilla_glue = {
        label          = 'Gorilla Glue',
        growMultiplier = 1.2,
        maxGenetics    = 85,
        waterDecay     = 1.0,
        fertDecay      = 1.4,   -- consume fertilizante rápido
        waterBonus     = 1.0,
        fertBonus      = 1.5,   -- pero le saca partido
        maleBonus      = 1.3,
        seedBonusOnLegendary = true,
    },
    blue_dream = {
        label          = 'Blue Dream',
        growMultiplier = 0.85,  -- ligeramente más rápida
        maxGenetics    = 65,
        waterDecay     = 1.5,   -- necesita mucha agua
        fertDecay      = 0.9,
        waterBonus     = 1.6,   -- pero el agua la impulsa mucho
        fertBonus      = 1.0,
        maleBonus      = 1.0,
        seedBonusOnLegendary = false,
    },
    purple_haze = {
        label          = 'Purple Haze',
        growMultiplier = 2.0,   -- la más lenta (vale la pena)
        maxGenetics    = 100,
        waterDecay     = 1.0,
        fertDecay      = 1.0,
        waterBonus     = 1.3,
        fertBonus      = 1.3,
        maleBonus      = 1.5,   -- la cruzación la dispara
        seedBonusOnLegendary = true,
    },
}

Config.Weed.DefaultStrain = 'og_kush'

-- Al cosechar Legendaria en cepas que lo permiten, probabilidad de obtener semilla extra
Config.Weed.LegendarySeedChance = 0.40  -- 40%

-- Configuración del sistema de clones
Config.Weed.Clone = {
    minStage         = 3,    -- stage mínimo para tomar esqueje
    minHealth        = 60,   -- salud mínima requerida
    geneticsVariance = 5,    -- el clon hereda genética ±5 del padre
    maxPerPlant      = 2,    -- máximo de esquejes que se pueden sacar de una misma planta
    healthCost       = 15,   -- salud que pierde la planta al tomar un esqueje
}

-- Sistema de genética: cuanto mejor cuides la planta, mejor rareza obtienes al cosechar
Config.Weed.Genetics = {
    -- Genética inicial al plantar (aleatoria entre min y max)
    initial = { min = 5, max = 20 },

    -- Bonus al regar
    waterBoost = { min = 2, max = 4 },

    -- Bonus al fertilizar
    fertilizerBoost = { min = 3, max = 6 },

    -- Bonus al cruzar con semilla macho (polinización)
    -- Bajado de 15-25 para que épica requiera varias generaciones o cepa avanzada
    maleSeedBoost = { min = 8, max = 15 },

    -- Tiers de calidad: umbrales subidos para hacer épica y legendaria más exigentes
    tiers = {
        { min = 0,  max = 25,  rarity = 'common',    branches = 1, label = 'Común',      item = 'weedplant_branch_common'    },
        { min = 26, max = 50,  rarity = 'uncommon',  branches = 2, label = 'Poco Común', item = 'weedplant_branch_uncommon'  },
        { min = 51, max = 70,  rarity = 'rare',      branches = 3, label = 'Rara',        item = 'weedplant_branch_rare'      },
        { min = 71, max = 88,  rarity = 'epic',      branches = 4, label = 'Épica',       item = 'weedplant_branch_epic'      },
        { min = 89, max = 100, rarity = 'legendary', branches = 5, label = 'Legendaria',  item = 'weedplant_branch_legendary' },
    }
}

-- Maceta de tela (08/10, prop propio de [assets]/[props]/origen_modelos):
-- va debajo de cada planta y esconde la maceta negra de plástico que traen los
-- modelos bkr_prop_weed_* (0,47 m de alto). Fuente: origen_weed/fuente/cultivo.py
Config.Weed.Pot = {
    prop = 'origen_weed_maceta',
}

-- Lo que se lleva en la mano al regar y al abonar (props propios, 08/10).
-- Antes: prop_wateringcan del juego y un bidón de gasolina (w_am_jerrycan_sf).
-- Los dos tienen el origen en el asa: con la animación de verter del bidón
-- (weapon@w_sp_jerrycan) la mano derecha (28422) agarra el asa y el chorro
-- sale de la alcachofa hacia la planta. Medido con fotos en el juego (08/10).
Config.Weed.HandProps = {
    water      = { model = 'origen_weed_regadera', bone = 28422, pos = vector3(0.0, 0.0, 0.0), rot = vector3(90.0, 180.0, 0.0),
                   ptfx = vector3(0.33, 0.0, -0.04) },   -- la alcachofa, en el espacio del prop
    fertilizer = { model = 'origen_weed_abono',    bone = 28422, pos = vector3(0.0, 0.0, 0.0), rot = vector3(90.0, 180.0, 0.0) },
}

-- Bidón de agua (08/10): se coloca junto al cultivo, llena la regadera sin
-- gastar botellas y se recarga con la lluvia (lleva un embudo) o con botellas.
Config.Weed.Bidon = {
    item            = 'bidon_agua',
    prop            = 'origen_weed_bidon',
    maxPorJugador   = 2,
    capacidad       = 20,   -- regaderas
    aguaInicial     = 5,
    lluviaPorMinuto = 2,    -- con lluvia o tormenta (con 'CLEARING', 1)
    botellasPorVez  = 1,    -- una por pulsación: las botellas también son para beber
}

Config.Weed.Props = {
    [1] = `bkr_prop_weed_01_small_01c`,
    [2] = `bkr_prop_weed_med_01a`,
    [3] = `bkr_prop_weed_med_01b`,
    [4] = `bkr_prop_weed_lrg_01a`,
    [5] = `bkr_prop_weed_lrg_01b`
}

Config.Weed.Growth = {
    growTimeMinutes = 40,
    updateEveryMinutes = 1,
    stageSizePercent = 20
}

Config.Weed.Decay = {
    waterPerMinute      = 0.4,   -- tasa base: 100/0.4 = 250 min para vaciar
    fertilizerPerMinute = 0.4,

    -- Factor de varianza por planta (multiplicador sobre la tasa base).
    -- Con 0.6–1.5 cada planta tiene entre ~167 min y ~417 min para vaciarse.
    -- Agua y fertilizante calculan factores distintos → nunca bajan igual.
    decayVariance = { min = 0.6, max = 1.5 },

    waterThreshold      = 25,
    fertilizerThreshold = 25,
    healthLoss          = { 7, 10 },   -- ya no se usa: ver damagePerMinute

    --[[ La salud se acumula (08/10). Antes se recalculaba al mirarla y una
         planta sin agua durante días solo bajaba a ~80: nunca moría. Ahora,
         cada minuto por debajo del umbral le quita salud de verdad, y bien
         cuidada (sin plaga y con agua y abono) la va recuperando.
         Una planta crece en 40-80 min: sin regar ni abonar nunca (1,8/min)
         muere en ~55 min; con un riego y un abono al plantar llega sana. ]]
    damagePerMinute   = { water = 1.2, fertilizer = 0.6 },
    recoveryPerMinute = 0.25,
    warnBelowHealth   = 35,   -- aviso al dueño (una vez por bajada)
}

Config.Weed.World = {
    raycastDistance     = 7.0,
    objectZOffset       = 0.0,
    fireTimeMs          = 10000,
    interactDistance    = 2.5,
    maxActionDistance   = 10.0,
    clearDeadOnStartup  = false,
    streamDistance      = 150.0,  -- radio en metros para hacer spawn/despawn del prop
    streamCheckInterval = 3000,   -- ms entre comprobaciones de distancia
}

Config.Weed.Planting = {
    maxPlantsPerPlayer = 6,
    enforceValidZones  = true,
    validZones = {
        { label = 'Zona 1', coords = vector3(-665.37,  4148.93, 159.04), radius = 200.0 },
        { label = 'Zona 2', coords = vector3(-399.53,  4712.31, 264.0),  radius = 200.0 },
        { label = 'Zona 3', coords = vector3(-907.7,   4812.2,  304.66), radius = 200.0 },
    }
}

--[[ Aviso a la policía (08/10): al plantar o cosechar hay esta probabilidad
     (en %) de que salte un aviso con la zona aproximada (±60 m), como la caza
     furtiva de origen_hunting. ]]
Config.Weed.Police = {
    jobs        = { 'police' },
    -- A cero (09/10): ni plantar ni cosechar avisan a la policía. Un cultivo
    -- se encuentra por el olor y la cámara térmica (abajo), no por un chivatazo.
    -- Son tantos por ciento: para que vuelvan a avisar, se sube el número.
    alertChance = { plant = 0, harvest = 0 },

    -- Olor (08/10): un agente de servicio que pasa cerca de una planta lo nota,
    -- con la dirección. Más radio cuanto más grande (fase 1: 19 m, fase 5: 47 m).
    olor = { base = 12, porFase = 7, cadaSeg = 180 },

    -- Cámara térmica del helicóptero (08/10): con la visión térmica puesta, las
    -- plantas desde esta fase brillan, hasta esta distancia.
    termica = { desdeFase = 4, distancia = 450.0 },

    -- Testigos (08/10): excursionistas que pasean por las zonas de cultivo. Si
    -- uno te ve plantar o cosechar (a la vista y a menos de `radio`), saca el
    -- móvil; si en `segundos` no lo espantas (apuntarle, que huya o caiga),
    -- avisa a la policía. Apagados (09/10) con `activo = false`: ni salen
    -- excursionistas a pasear ni se chiva nadie.
    testigos = {
        activo   = false,
        radio    = 40.0,
        segundos = 8,
        paseo    = { cadaMin = 120, cadaMax = 240, prob = 60, max = 2, vida = 300 },
        modelos  = { 'a_m_y_hiker_01', 'a_f_y_hiker_01', 'a_m_m_hillbilly_01', 'a_f_y_tourist_01' },
    },
}

Config.Weed.Security = {
    plantCooldownSeconds = 20,
    actionCooldownSeconds = 1
}

Config.Weed.Progress = {
    placePlant  = 2000,
    harvest     = 8500,
    clearDead   = 8500,
    addMaleSeed = 8500,
    water       = 6000,
    fertilizer  = 6000,
    fillCan     = 2000,
    burn        = 4000,
    cure        = 6000,   -- duración barra de progreso al curar plaga
}

-- ─────────────────────────────────────────────
--  Sistema de Plagas y Enfermedades
-- ─────────────────────────────────────────────
-- Probabilidades por hora calculadas como por-tick (1 tick = 1 min):
--   P(tick) ≈ chancePerHour / 6000  →  math.random(6000/chancePerHour) == 1
-- Ejemplo: 4%/h → 1/1500 por tick → P(infectar en 60 ticks) ≈ 3.9%
Config.Weed.Pests = {
    enabled = true,

    types = {
        acaros = {
            label         = 'Ácaros',
            chancePerHour = 4.0,    -- 4% por hora  → ~4% chance en la primera hora de vida
            healthDecay   = 1.0,    -- -1 de salud por minuto infectada (se acumula: ~1 h 40 min hasta matarla)
            cure          = 'pesticida_organico',
            cureTime      = 5000,
            cureLabel     = 'Aplicando pesticida orgánico...',
        },
        hongos = {
            label          = 'Hongos',
            chancePerHour  = 2.5,   -- 2.5% por hora → menos frecuente pero muy dañino
            geneticPenalty = 8,     -- genética perdida INMEDIATAMENTE al infectarse
            decayMult      = 2.0,   -- agua y fertilizante se gastan el doble de rápido
            cure           = 'fungicida',
            cureTime       = 6000,
            cureLabel      = 'Aplicando fungicida...',
        },
        podredumbre = {
            label          = 'Podredumbre',
            chancePerHour  = 1.5,   -- 1.5% por hora, pero solo si agua > 90%
            waterThreshold = 90,    -- solo aparece si el nivel de agua supera el 90%
            healthDecay    = 2.5,   -- muy destructiva: -2,5 salud/min (se acumula: ~40 min)
            spreadRadius   = 5.0,   -- metros de radio de propagación a otras plantas
            spreadChance   = 8,     -- 8% de probabilidad por minuto de propagarse
            drainWater     = true,  -- al curar, se drena el agua (evita reinfección)
            cure           = 'fungicida',
            cureTime       = 8000,
            cureLabel      = 'Aplicando tratamiento antifúngico...',
        },
    },

    -- Notificación al dueño: máximo 1 vez cada X minutos por planta
    notifyCooldownMinutes = 30,
}

-- ─────────────────────────────────────────────
--  Sistema de Mutaciones Genéticas
-- ─────────────────────────────────────────────
-- Las mutaciones ocurren al polinizar (AddMaleSeed) con una probabilidad base.
-- Solo puede haber UNA mutación por planta.
-- Pesos: suman 100. Cuanto menor sea el peso, más rara es la mutación.
Config.Weed.Mutations = {
    enabled = true,

    -- % de probabilidad de mutación al polinizar exitosamente
    baseChance = 8,

    -- % de probabilidad de que un clon herede la mutación del padre
    cloneInheritChance = 60,

    types = {
        auto_flowering = {
            label  = 'Auto-floración',
            badge  = '◆ AUTO',
            weight = 30,
            -- Efecto: el fertilizante no se consume (fertDecay ≈ 0)
        },
        resistant = {
            label  = 'Resistente',
            badge  = '◆ RES',
            weight = 30,
            -- Efecto: la planta es inmune a todas las plagas
        },
        super_yield = {
            label  = 'Gran cosecha',
            badge  = '◆ GRC',
            weight = 15,
            -- Efecto: cosecha x1.5 ramas (redondeado hacia arriba)
        },
        photoperiod = {
            label  = 'Fotoperiodo',
            badge  = '◆ FOTO',
            weight = 15,
            -- Efecto: crecimiento x2 más lento (simula ciclo día/noche)
        },
        albino = {
            label  = 'Albina',
            badge  = '◆ ALB',
            weight = 10,
            -- Efecto: genética siempre al máximo de la cepa pero salud al 60%
        },
    },
}

-- ─────────────────────────────────────────────
--  Sistema de Tendal (secado de ramas)
-- ─────────────────────────────────────────────
Config.Weed.Tendal = {
    item             = 'tendal',
    prop             = 'origen_tenderomaria',
    maxPerPlayer     = 5,       -- tendales máximos por jugador
    slots            = 6,       -- huecos de secado

    dryTimeMinutes   = 15,      -- tiempo base de secado en minutos reales
    interactDistance = 3.0,
    streamDistance   = 150.0,
    streamCheckInterval = 3000,
    placeCooldownSec = 20,      -- cooldown entre colocaciones

    -- Una pinza por hueco en la cuerda del tendal (origen_tenderomaria, hecho en
    -- origen_weed/fuente/construir.py: la cuerda va a lo largo de X a 1,90 m con
    -- su comba). La rama cuelga de su punta, 0,49 m por encima de su origen; el
    -- giro en Z, un poco distinto en cada una para que no parezcan clonadas.
    slotOffsets = {
        { x = -1.250, y = 0.0, z = 1.410, rx = 0.0, ry = 0.0, rz =  12.0 },
        { x = -0.750, y = 0.0, z = 1.397, rx = 0.0, ry = 0.0, rz = -20.0 },
        { x = -0.250, y = 0.0, z = 1.391, rx = 0.0, ry = 0.0, rz =   5.0 },
        { x =  0.250, y = 0.0, z = 1.391, rx = 0.0, ry = 0.0, rz = 160.0 },
        { x =  0.750, y = 0.0, z = 1.397, rx = 0.0, ry = 0.0, rz = -170.0 },
        { x =  1.250, y = 0.0, z = 1.410, rx = 0.0, ry = 0.0, rz = 190.0 },
    },

    -- Prop que representa la rama colgando en la cuerda del tendal
    branchProp = 'bkr_prop_weed_drying_01a',

    -- Multiplicadores de velocidad según hora GTA (enviada por el cliente al añadir rama)
    dayStart = 6,
    dayEnd   = 20,
    timeMultipliers = {
        day   = 1.3,    -- 6AM-20PM: 30% más rápido → ~11.5 min
        night = 0.7,    -- 20PM-6AM: 30% más lento  → ~21.4 min
    },

    -- Más cosas del tendal (08/10)
    voltearBonus   = 1.25,  -- voltear una rama (una vez): seca un 25 % más rápido desde entonces
    pasadaMinutos  = 60,    -- una rama seca que se queda más de esto colgada baja un escalón de rareza
    lluviaPara     = true,  -- con lluvia o tormenta no se seca (está al aire libre)

    -- Conversión rama fresca → rama seca (misma rareza, mayor valor)
    dryOutput = {
        ['weedplant_branch_common']    = 'weedplant_branch_dried_common',
        ['weedplant_branch_uncommon']  = 'weedplant_branch_dried_uncommon',
        ['weedplant_branch_rare']      = 'weedplant_branch_dried_rare',
        ['weedplant_branch_epic']      = 'weedplant_branch_dried_epic',
        ['weedplant_branch_legendary'] = 'weedplant_branch_dried_legendary',
    },
}

-- ─────────────────────────────────────────────
--  Mesa de Procesado (desojado + empaquetado)
-- ─────────────────────────────────────────────
Config.Weed.Table = {
    item             = 'mesa_procesado',
    -- Mesa plegable de camping montada (08/10, prop propio): a escala de
    -- cultivo casero. Antes, la mesa industrial del búnker (2,2 m y lámpara).
    prop             = 'origen_weed_mesa',
    -- Encima, cosas del juego: cogollos en la bandeja, tijeras, báscula digital
    -- y bolsitas (posición respecto al centro de la mesa, que está a 0,74 m;
    -- la bandeja va a la izquierda y la envasadora detrás a la derecha). La
    -- balanza de platos del búnker (bkr_prop_weed_scales_01a) tapaba la bandeja.
    decor = {
        { model = 'bkr_prop_weed_dry_01a',        pos = vector3(-0.30, 0.03, 0.775), rot = 20.0 },
        { model = 'bkr_prop_weed_dry_02a',        pos = vector3(-0.17, -0.07, 0.775), rot = -35.0 },
        { model = 'prop_cs_scissors',             pos = vector3(-0.06, -0.12, 0.741), rot = 60.0 },
        { model = 'bkr_prop_coke_scale_01',       pos = vector3(0.34, -0.08, 0.74), rot = 0.0 },
        { model = 'bkr_prop_weed_bud_pruned_01a', pos = vector3(0.34, -0.08, 0.80), rot = 0.0 },
        { model = 'bkr_prop_weed_bag_pile_01a',   pos = vector3(0.07, 0.14, 0.741), rot = 10.0 },
    },
    chairProp        = 'prop_off_chair_01',
    maxPerPlayer     = 3,
    interactDistance = 2.0,
    streamDistance   = 100.0,
    streamCheckInterval = 3000,
    placeCooldownSec = 30,

    -- Offset de la silla respecto al centro de la mesa (espacio local)
    chairOffset    = { x = 0.000, y = -0.620, z = 0.000 },   -- la mesa mide 0,6 de fondo
    chairRotOffset = 180.0,
    chairProp      = 'prop_off_chair_01',

    -- Offset del jugador dentro de la posición de la silla (espacio local de la silla)
    pedOffset      = { x = 0.060, y = 0.000, z = 0.440 },
    pedRotOffset   = 170.0,

    -- Modelos de silla (los probaba el editor /table_dev, quitado el 07/10)
    chairModels = {
        'prop_off_chair_01',
        'prop_chair_01a',
        'prop_chair_02',
        'prop_bar_chair_01',
        'prop_chair_farm01',
    },

    -- Animación de brazos mientras se procesa (upper-body overlay, no interrumpe el sentado)
    processAnim = {
        dict  = 'mini@repair',
        clip  = 'fixing_a_loop',
        flags = 48,   -- upper body overlay (no override seated scenario)
    },
    processTimeMs = 6000,  -- duración de la barra de progreso por lote

    -- Más cosas de la mesa (08/10)
    bolsa            = 'bolsa_envasar', -- empaquetar gasta bolsas: una por paquete
    bolsasPorPaquete = 1,
    maxTanda         = 20,   -- unidades por tanda
    maxTodo          = 40,   -- «Procesar todo»: operaciones como mucho de una vez
    -- Minijuego de manicura al desojar: bien hecho, uno más; mal, uno menos
    manicura         = { perfect = 1, good = 0, miss = -1 },
    -- Olor: una tanda de este tamaño o más tiene esta probabilidad (%) de aviso
    aviso            = { desde = 10, prob = 20 },

    -- ── Desojado: solo ramas SECAS del tendal → brotes desojados ─────────────
    -- Las ramas frescas deben pasar primero por el tendal antes de desojarse
    desojado = {
        label = 'Desojado',
        output = {
            ['weedplant_branch_dried_common']    = 'weed_trimmed_common',
            ['weedplant_branch_dried_uncommon']  = 'weed_trimmed_uncommon',
            ['weedplant_branch_dried_rare']      = 'weed_trimmed_rare',
            ['weedplant_branch_dried_epic']      = 'weed_trimmed_epic',
            ['weedplant_branch_dried_legendary'] = 'weed_trimmed_legendary',
        },
    },

    -- ── Empaquetado: solo brotes desojados → paquetes finales ────────────────
    -- Cadena obligatoria: rama fresca → tendal → desojar → empaquetar
    -- No se puede saltarse ningún paso
    empaquetado = {
        label = 'Empaquetado',
        output = {
            ['weed_trimmed_common']    = 'weed_packed_common',
            ['weed_trimmed_uncommon']  = 'weed_packed_uncommon',
            ['weed_trimmed_rare']      = 'weed_packed_rare',
            ['weed_trimmed_epic']      = 'weed_packed_epic',
            ['weed_trimmed_legendary'] = 'weed_packed_legendary',
        },
        -- Bolsas que se obtienen por cada brote desojado según rareza
        outputQty = {
            ['weed_trimmed_common']    = 2,
            ['weed_trimmed_uncommon']  = 3,
            ['weed_trimmed_rare']      = 5,
            ['weed_trimmed_epic']      = 8,
            ['weed_trimmed_legendary'] = 12,
        },
    },
}
