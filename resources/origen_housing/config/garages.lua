Config.CustomGarage = false -- Set to true if you want to use a custom garage system

Config.GarageInteriors = {
    {
        label = 'Garaje básico',
        model = 'basic',
        cam = vector4(178.6739, -1007.4586, -99.0000, 58.9382),
        coords = vector4(171.2532, -1004.6526, -98.9999, 357.35),
        slots = {
            { coords = vector4(175.01, -1003.60, -99.18, 157.96) },
        },
        floors = {},
        images = {
            'basic.png',
        },
    },
    {
        label = 'Garaje mediano',
        model = 'medium',
        cam = vector4(191.9722, -1006.5375, -99.0000, 303.5745),
        coords = vector4(202.1999, -1004.4500, -98.9999, 2.3074),
        slots = {
            { coords = vector4(203.5676, -997.8387, -99.0000, 177.1650) },
            { coords = vector4(198.1634, -997.8378, -99.0000, 177.9458) },
            { coords = vector4(193.7832, -997.6540, -99.0000, 179.1584) },
            { coords = vector4(194.8356, -1003.9368, -99.0000, 269.3047) },
        },
        floors = {},
        images = {
            'medium.png',
        },
    },
    {
        label = 'Garaje grande',
        model = 'large',
        cam = vector4(235.5941, -1004.8665, -99.0000, 23.0640),
        coords = vector4(228.4644, -1003.3825, -99.0000, 356.3074),
        slots = {
            { coords = vector4(224.500, -998.695, -99.0000, 225.0) },
            { coords = vector4(224.500, -994.630, -99.0000, 225.0) },
            { coords = vector4(224.500, -990.255, -99.0000, 225.0) },
            { coords = vector4(224.500, -986.628, -99.0000, 225.0) },
            { coords = vector4(224.500, -982.496, -99.0000, 225.0) },
            { coords = vector4(232.500, -982.496, -99.0000, 135.0) },
            { coords = vector4(232.500, -986.628, -99.0000, 135.0) },
            { coords = vector4(232.500, -990.255, -99.0000, 135.0) },
            { coords = vector4(232.500, -994.630, -99.0000, 135.0) },
            { coords = vector4(232.500, -998.695, -99.0000, 135.0) },
        },
        floors = {},
        images = {
            'large.png',
        },
    },
    {
        label = 'Garaje prémium',
        model = 'premium',
        cam = vector4(-1077.0859, -85.1324, -90.2000, 315.6656),
        coords = vector4(-1072.6851, -66.7694, -99.2195, 180.2243),
        slots = {
            -- Floor 1
            { coords = vector4(-1066.0608, -66.8215, -99.3096, 148.3916) },
            { coords = vector4(-1065.9014, -75.2346, -99.3096, 148.3916) },
            { coords = vector4(-1066.0887, -81.1227, -99.3096, 90.7014) },
            { coords = vector4(-1079.1125, -68.0828, -99.3096, 269.9612) },
            { coords = vector4(-1079.6432, -74.8921, -99.3096, 212.6530) },
            { coords = vector4(-1079.1287, -83.0487, -99.3096, 212.6530) },

            -- Floor 2
            { coords = vector4(-1066.0608, -66.8215, -94.9238, 148.3916) },
            { coords = vector4(-1065.9014, -75.2346, -94.9238, 148.3916) },
            { coords = vector4(-1066.0887, -81.1227, -94.9238, 90.7014) },
            { coords = vector4(-1079.1125, -68.0828, -94.9238, 269.9612) },
            { coords = vector4(-1079.6432, -74.8921, -94.9238, 212.6530) },
            { coords = vector4(-1079.1287, -83.0487, -94.9238, 212.6530) },

            -- Floor 3
            { coords = vector4(-1065.0786, -74.8115, -90.5196, 90.2314) },
            { coords = vector4(-1079.1125, -68.0828, -90.5196, 269.9612) },
            { coords = vector4(-1079.6432, -74.8921, -90.5196, 212.6530) },
            { coords = vector4(-1079.1287, -83.0487, -90.5196, 212.6530) },
        },
        floors = {
            { coords = vector4(-1072.8025, -82.7791, -99.2195, 1.4717) },
            { coords = vector4(-1072.8025, -82.7791, -94.9238, 1.4717) },
            { coords = vector4(-1072.8025, -82.7791, -90.5196, 1.4717) },
        },
        images = {
            'premium.png',
        },
    },
}