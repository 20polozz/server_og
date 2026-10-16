Config = {}

Config.Classes = {
    ['D'] = {
        label = 'Clase D',
        description = 'Sedanes básicos y utilitarios',
        color = '#0080ff',
        minPI = 0,
        maxPI = 350
    },
    ['C'] = {
        label = 'Clase C',
        description = 'Coupés y turismos equilibrados',
        color = '#00ff00',
        minPI = 351,
        maxPI = 500
    },
    ['B'] = {
        label = 'Clase B',
        description = 'Deportivos de entrada y berlinas potentes',
        color = '#ffd700',
        minPI = 501,
        maxPI = 650
    },
    ['A'] = {
        label = 'Clase A',
        description = 'Deportivos de alto rendimiento',
        color = '#ff6b00',
        minPI = 651,
        maxPI = 800
    },
    ['A+'] = {
        label = 'Clase A+',
        description = 'Deportivos extremos y tuneados',
        color = '#ff7452ff',
        minPI = 801,
        maxPI = 920
    },
    ['S'] = {
        label = 'Clase S',
        description = 'Súper deportivos de élite',
        color = '#ff0000',
        minPI = 921,
        maxPI = 1050
    },
    ['S+'] = {
        label = 'Clase S+',
        description = 'Hypercars y prototipos de competición',
        color = '#ff00ff',
        minPI = 1051,
        maxPI = 3000
    },
    ['M'] = {
        label = 'Motos',
        description = 'Motocicletas y ciclomotores',
        color = '#00ffff',
        isMoto = true
    },
    ['H'] = {
        label = 'Aéreos',
        description = 'Vehículos aéreos, aviones y helicópteros',
        color = '#ffffff',
        isAerial = true
    }
}

-- Excepciones manuales por modelo (ej: si un coche da muy poco PI pero es un deportivo)
Config.ManualClass = {
    -- ['zentorno'] = 'S+',
}

-- Factores de multiplicación para el cálculo del PI
Config.PIFactors = {
    topSpeed = 0.35,
    acceleration = 0.40,
    traction = 0.15,
    braking = 0.10
}
