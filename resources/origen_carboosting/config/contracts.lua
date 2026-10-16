Config.QueueWaitTime = 3 -- Time in minutes between each contract offer

Config.Zones = {
    ['spawn'] = {
        vector4(646.85, -1732.13, 9.69, 176.64),
        vector4(528.9, -2398.29, 5.87, 17.48),
        vector4(492.49, -2229.99, 5.92, 332.36),
        vector4(484.79, -2159.49, 5.92, 243.99),
        vector4(137.94, -2833.81, 6.0, 268.02),
        vector4(128.86, -3332.25, 6.02, 90.72),
        vector4(-529.19, -2816.31, 6.0, 222.05),
        vector4(-444.31, -2445.65, 6.0, 228.78),
        vector4(-1153.93, 2673.48, 18.09, 311.4),
        vector4(-142.71, 2965.32, 33.12, 279.92),
        vector4(178.46, 3055.77, 43.08, 275.46),
        vector4(313.98, 3451.43, 36.28, 304.38),
        vector4(341.13, 3570.81, 33.47, 352.45),
        vector4(889.76, 3651.61, 32.83, 357.61),
        vector4(1420.78, 3735.32, 32.78, 197.72),
        vector4(2044.3, 3927.8, 33.11, 118.56),
        vector4(2507.5, 4191.19, 39.94, 55.68),
        vector4(2292.41, 4890.67, 41.22, 135.17),
        vector4(1640.61, 4832.63, 42.02, 8.97),
        vector4(1312.54, 4329.82, 38.27, 167.32),
        vector4(713.05, 4175.0, 40.71, 290.34),
        vector4(-1954.83, 4465.75, 34.38, 219.65),
        vector4(-762.39, 5533.25, 33.48, 15.64),
        vector4(-666.26, 5823.93, 17.33, 273.22),
    },
    ['delivery'] = {
        vector4(-218.32, 6254.21, 30.88, 223.84),
        vector4(1540.43, 6335.69, 23.47, 241.07),
        vector4(1694.43, 6427.97, 32.02, 335.33),
        vector4(1971.29, 5165.73, 47.03, 305.67),
        vector4(1725.75, 4801.89, 41.11, 270.08),
        vector4(2553.61, 4670.92, 33.34, 196.29),
        vector4(2879.11, 4488.94, 47.62, 343.04),
        vector4(2660.85, 3273.91, 54.63, 239.07),
        vector4(917.69, 3566.87, 33.16, 86.77),
        vector4(190.43, 2787.08, 45.0, 98.05),
        vector4(1552.27, 2191.55, 78.25, 174.74),
        vector4(752.68, -1857.07, 28.68, 266.01),
        vector4(988.86, -2396.25, 29.9, 96.95),
    },
    ['vin'] = {
        {coords = vector4(-84.58, -2228.82, 7.2, 89.86)},
        {coords = vector4(1563.0, -2170.89, 76.93, 172.22)},
        {coords = vector4(299.72, 2886.64, 42.96, 34.25)},
    }
}


Config.Guards = {
    model = { -- Guards models, randomly chosen
        'u_m_y_party_01',
        'g_m_y_mexgang_01',
        'g_m_y_mexgoon_02',
    },
    difficulties = { -- Each difficulty has a different set of stats
        [0] = { -- Easy
            accuracy = 10, -- Accuracy of the guards
            armor = 0, -- Armor of the guards
            health = 100, -- Health of the guards
        },
        [1] = { -- Normal
            accuracy = 10, -- Accuracy of the guards
            armor = 50, -- Armor of the guards
            health = 200, -- Health of the guards
        },
        [2] = { -- Hard
            accuracy = 10, -- Accuracy of the guards
            armor = 100, -- Armor of the guards
            health = 300, -- Health of the guards
        }
    }
}