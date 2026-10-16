-- ============================================
-- NAVMESH BLOCKING CONFIGURATION
-- ============================================
-- Configure zones where AI pathfinding should be blocked

Config.Scenarios = Config.Scenarios or {}

Config.Scenarios.NavmeshZones = {
    {
        -- Mission Row Park 1
        coords = vector3(309.928, -1095.26, 28.3818),
        size = vector3(60, 160.0, 20.0),
        heading = 0.0
    },
    {
        -- Mission Row Park 2
        coords = vector3(327.116, -997.822, 28.3818),
        size = vector3(68.0, 120.0, 5.0),
        heading = 0.0
    },
    {
        -- Legion Square
        coords = vector3(196.914, -929.164, 28.3818),
        size = vector3(160.0, 95.0, 10.0),
        heading = -20.0
    },
    {
        -- Jurassic Jackpot (Zone A)
        coords = vector3(-260.1594, -892.5989, 31.2198),
        size = vector3(10.0, 10.0, 10.0),
        heading = 160
    },
    {
        -- Jurassic Jackpot (Zone B)
        coords = vector3(-277.1366, -915.6442, 31.2141),
        size = vector3(8.0, 4.0, 5.0),
        heading = 160
    },
    {
        -- Pearls Resort
        coords = vector3(-1800.4041, -1196.9731, 15.2750),
        size = vector3(203.0, 120.0, 20.0),
        heading = 140
    },
    {
        -- Mission Row Police Station
        coords = vector3(449.917, -999.535, 28.287),
        size = vector3(100, 80, 25.0),
        heading = 0.0
    }
}
