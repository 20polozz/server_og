Config.Debug = false
Config.Language = 'es'

Config.LoadDistance = 50.0
Config.UnloadDistance = 100.0
Config.UpdateInterval = 1000

Config.NPCInteractDistance = 3.0

Config.SetupMenu = {
    vehiclePlacing = 'adder'
}

Config.DealershipMenu = {
    defaultVehicleModel = 'sultan'
}

Config.TestDrive = {
    Timer = 60 * 1000,
    plate = 'TESTDRIVE',
}

Config.VehiclePurchase = {
    defaultGarage = 'garaje_central', -- Default garage where the vehicle will be saved
    spawnVehicle = true, -- If true, the vehicle will be spawned when buying it, if false only save it in the garage
    giveKeysOnPurchase = true, -- If true, give the keys of the vehicle when buying it
    useOxLibProps = true, -- If true, use ox_lib for the vehicle properties
}

Config.CustomCurrency = GetConvar('origen:marca', 'origen') == 'nacion' and {
    resource = 'origen_vipsystem', -- Resource that owns the wallet
    key      = 'xp',               -- Config.Currencies key inside origen_vipsystem (Farm XP)
} or nil

Config.JobVehicleLimits = {
    enabled = true, -- If true, limits the amount of vehicles of the SAME MODEL a player can buy in a job dealership category
    defaultLimit = 1, -- Default limit of same model vehicles a player can buy
    limits = {
        ['police'] = 1,
        ['ambulance'] = 1,
        ['sheriff'] = 1,
        ['sapd'] = 1,
    }
}

Config.Markers = {
    blips = {
        sprite = 524,
        color = 5,
        scale = 0.7,
        name = "Dealership",
    }
}

Config.FinancingConfig = {
    enabled = true,
    timeUnit = 'days', -- days, weeks, months, years
    maxPeriods = 12, -- max time in datatype
    interestRate = 5, -- interest rate in percentage per datatype time
    payInitialPercentage = 30, -- initial payment percentage or 0 to disable
    cronExpression = '*/10 * * * *', -- Check every 10 minutes using cron
    maxDelayedPayments = 3, -- Número máximo de cuotas que se pueden retrasar
}

Config.Camera = {
    enableCollisionCheck = false, -- Enable/Disable camera collision check
}

-- Configuración de grupos de administrador
Config.AdminGroups = {
    ['qb-core'] = {
        'admin',
        'god',
        'superadmin'
    },
    ['esx'] = {
        'admin',
        'superadmin',
        'mod'
    },
    ['qbx'] = {
        'admin',
        'god',
        'superadmin'
    }
}
-- ══ Fotos automaticas de los coches ══════════════════════════════════════
-- Panel de admin > Vehiculos > «Sacar fotos». Cada coche se saca solo delante
-- de una caja verde, la interfaz recorta el fondo y la foto se sube a
-- fivemanage por origen_uploader. Hace falta screencapture (o screenshot-basic)
-- y origen_uploader arrancados; si falta uno, el boton sale apagado.
Config.VehiclePhotos = {
    enabled = true,

    -- Donde se saca el coche. Mar abierto a proposito: nada del mapa se puede
    -- colar dentro de la caja y salir en la foto.
    captureCoords = vec3(-2900.0, -3200.0, 120.0),
    captureHeading = 235.0,

    -- Donde espera el admin mientras tanto, respecto a captureCoords
    hiddenOffset = vec3(0.0, -60.0, 0.0),

    -- La caja verde. Se coloca por su propia caja de colision, asi que el coche
    -- queda siempre apoyado en su suelo. model = false saca la foto contra lo
    -- que haya y apaga el recorte.
    backdrop = {
        model = 'dealer_green_screen',
        heading = 0.0,
        offset = vec3(0.0, 0.0, 0.0),
    },

    -- Los coches se repintan antes de la foto para que su pintura no se
    -- confunda con el verde. Cada modelo sale siempre del mismo color (se elige
    -- por su nombre). Los verdes, turquesas y amarillos chillones se rechazan
    -- al arrancar con un aviso en la consola, porque el recorte se comeria el
    -- coche. false = pintura de serie, y entonces chromaToleranceEdge a 0.24.
    vehicleColours = {
        { r = 205, g = 205, b = 210 }, -- plata
        { r = 240, g = 240, b = 245 }, -- blanco
        { r = 26,  g = 28,  b = 32  }, -- negro
        { r = 70,  g = 72,  b = 78  }, -- grafito
        { r = 150, g = 26,  b = 32  }, -- rojo
        { r = 28,  g = 62,  b = 130 }, -- azul
        { r = 200, g = 90,  b = 30  }, -- naranja
        { r = 80,  g = 35,  b = 120 }, -- morado
    },

    camera = {
        distance = 2.0, -- metros de mas sobre el tamaño del coche
        orbit = 40.0,   -- angulo alrededor del coche, en grados
        fov = 60.0,
    },

    output = {
        width = 512,
        height = 320,
        padding = 16,
        removeBackground = true,

        -- Cuanto se puede alejar un pixel del verde para cortarse en cualquier
        -- parte de la foto (limpia los cristales). 0.12 si vehicleColours = false.
        chromaTolerance = 0.3,
        -- Umbral mas suelto, solo para pixeles pegados a fondo ya cortado (el
        -- verde lavado que se ve a traves de las ventanillas). 0.24 si
        -- vehicleColours = false, o se disuelve un coche verde entero.
        chromaToleranceEdge = 0.39,
        -- Cuanto tiene que sacar el verde al rojo y al azul para mirarse el
        -- pixel. Por debajo de 4 los casi negros dejan de estar protegidos.
        minGreenDominance = 8,

        -- El juego pinta sus avisos en la captura (el de descarga de assets).
        -- Solo se queda la pieza grande y lo que tenga pegado.
        subjectMinRatio = 0.005,
        subjectGapRatio = 0.03,
    },

    delays = {
        -- Milisegundos tras sacar el coche y tras colocar la camara
        spawn = 250,
        settle = 400,
    },
}
