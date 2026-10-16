-- ============================================
-- SCENARIO BLOCKING AREA CONFIGURATION
-- ============================================
-- Configure areas where default GTA scenarios should be blocked

Config.Scenarios = Config.Scenarios or {}

Config.Scenarios.ScenarioAreas = {
    {
        name = "banning",
        min = vector3(-648.0176, -2338.24927, 4.371068),
        max = vector3(582.782166, -1421.21069, 24.8253784)
    },
    {
        name = "cluckin_bell",
        min = vector3(-454.328979, 5989.87, 29.8901081),
        max = vector3(75.62528, 6630.45166, 34.5059624)
    },
    {
        name = "downtown",
        min = vector3(-861.851, -1466.205, 27.78532),
        max = vector3(465.6922, -328.0931, 345.991669)
    },
    {
        name = "downtown_construction_site",
        min = vector3(-403.828461, -1241.02209, 17.6384735),
        max = vector3(100.695183, -781.737549, 107.848366)
    },
    {
        name = "elysian_island",
        min = vector3(-51.13555, -3512.33813, 0),
        max = vector3(754.220459, -2382.12256, 16.0925465)
    },
    {
        name = "lsia_terminal",
        min = vector3(-1366.84216, -2809.98315, -9.323433),
        max = vector3(-530.295837, -1829.41064, 19.708353)
    },
    {
        name = "pacific_bluffs",
        min = vector3(-2687.56885, -585.526733, 7.001978),
        max = vector3(-1471.19373, 230.468109, 149.995)
    },
    {
        name = "pillbox_hill",
        min = vector3(-266.560364, -1139.88977, 8.148654),
        max = vector3(405.2953, -423.2211, 178.1748)
    },
    {
        name = "south_los_santos",
        min = vector3(-357.9139, -2032.66785, 22.0288353),
        max = vector3(557.4948, -1112.92419, 94.12113)
    },
    {
        name = "vespucci_beach",
        min = vector3(-2209.89063, -1893.0603, -15.2268124),
        max = vector3(-1093.64612, -427.156616, 75)
    },
    {
        name = "vinewood_park",
        min = vector3(69.89189, 462.887146, 117.856224),
        max = vector3(1224.86108, 1790.67542, 363.078247)
    },
    {
        name = "pier",
        min = vector3(-2049.71362, -1424.12708, -8.133315),
        max = vector3(-1455.5918, -772.0315, 22.7525616)
    },
    {
        name = "mission_row",
        min = vector3(196.448761, -1183.968, -100.23024),
        max = vector3(534.5499, -824.6625, 42.6917419)
    }
}
