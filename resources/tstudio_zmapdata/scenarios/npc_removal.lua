-- ============================================
-- NPC POPULATION REMOVAL CONFIGURATION
-- ============================================
-- Configure areas where NPC population should be reduced or removed
-- Supports both spherical and rectangular areas

Config.Scenarios = Config.Scenarios or {}
Config.Scenarios.DrawAreas = false -- Toggle for drawing areas

-- Spherical areas (using AddPopMultiplierSphere)
-- Format: { coords = vector3(x, y, z), radius = float, pedMult = float, vehMult = float }
Config.Scenarios.Spheres = {
    {
        coords = vector3(-1812.805, -1193.441, -5.25),
        radius = 255.0,
        pedMult = 0.0,  -- Pedestrian multiplier (0.0 = no peds, 1.0 = normal)
        vehMult = 0.0   -- Vehicle multiplier (0.0 = no vehicles, 1.0 = normal)
    },
    -- Add more spheres here
    -- {
    --     coords = vector3(100.0, 200.0, 30.0),
    --     radius = 150.0,
    --     pedMult = 0.0,
    --     vehMult = 0.0
    -- },
}

-- Rectangular areas (using AddPopMultiplierArea)
-- Format: { pos1 = vector3(x, y, z), pos2 = vector3(x, y, z), pedMult = float, vehMult = float }
Config.Scenarios.PopAreas = {
    {
        pos1 = vector3(492.168, -963.729, 27.241),
        pos2 = vector3(407.666, -1035.340, 29.332),
        pedMult = 0.0,
        vehMult = 0.0
    },
    -- Example:
    -- {
    --     pos1 = vector3(100.0, 200.0, 20.0),
    --     pos2 = vector3(200.0, 300.0, 40.0),
    --     pedMult = 0.0,
    --     vehMult = 0.0
    -- },
}
