Config = {}

Config.Debug = false

Config.Fuels = {
    ['C'] = {
        label = 'Queroseno',
        performance = 1.0,
        consumption = 0.0256,
        price = 1.0
    },
    ['B'] = {
        label = '95',
        performance = 2.5,
        consumption = 0.0127,
        price = 2
    },
    ['A'] = {
        label = '98',
        performance = 5.0,
        consumption = 0.0128,
        price = 3
    }
}

Config.Stations = {
    [1] = {
        coords = vec(265.14, -1262.58, 29.29),
        stock = {
            ['C'] = 3000,
            ['B'] = 2000,
            ['A'] = 1000
        },
    },
    [2] = {
        coords = vec3(2005.1, 3774.09, 32.4),
        stock = {
            ['C'] = 3000,
            ['B'] = 2000,
            ['A'] = 1000
        },
    }
}