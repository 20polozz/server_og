--[[
    ============================================================
    LABS SETTINGS
    ============================================================
    Definition of lab types and interiors.
    - The type is persisted in DB per lab.
    - Interior coordinates are ALWAYS resolved from this config.
    - Shared bucket per lab/entry point (1 bucket per lab).
    ============================================================
--]]

Config.Labs = {
    Bucket = {
        -- Base value used to generate bucket per lab: base + lab_id
        Base = 42000,
    },

    Interactions = {
        EntryDistance  = 2.0,
        ExitDistance   = 2.0,
        LaptopDistance = 2.0,
    },

    -- Jobs that can enter labs marked as "raidable".
    -- Independent from Config.DrugSales.PoliceJobs to avoid coupling logic.
    -- Key = job name, value = true.
    RaidPoliceJobs = {
        ['police']  = true,
        ['sheriff'] = true,
    },
}

Config.LabTypes = {
    weed = {
        label = 'Laboratorio de maría',
        interior = {
            spawn  = vector4(1066.2063, -3183.4253, -40.1635, 92.9268),
            laptop = vector4(1044.5106, -3194.8826, -38.1580, 268.2953),
        }
    },

    coke = {
        label = 'Laboratorio de coca',
        interior = {
            spawn  = vector4(1088.6075, -3187.6018, -39.9934, 174.4182),
            laptop = vector4(1087.0756, -3194.2019, -38.9934, 94.9825),
        }
    },

    meth = {
        label = 'Laboratorio de meta',
        interior = {
            spawn  = vector4(997.1718, -3200.6497, -37.3937, 270.0),
            laptop = vector4(1002.0104, -3194.8918, -38.9931, 356.9845),
        }
    },

    bunker = {
        label = 'Búnker',
        interior = {
            spawn  = vector4(892.2524, -3245.8599, -99.2660, 85.2783),
            laptop = vector4(908.6752, -3207.3086, -97.1880, 178.7403),
        }
    },

    counterfeit = {
        label = 'Dinero falso',
        interior = {
            spawn  = vector4(1138.04, -3199.09, -40.67, 356.90),
            laptop = vector4(1129.58, -3194.13, -40.40, 358.20),
        }
    },
}
