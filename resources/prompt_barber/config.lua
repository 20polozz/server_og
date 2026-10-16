Config = {}

-- Barber Shop Locations Configuration
-- Set to true to ENABLE interior, false to DISABLE interior
Config.Locations = {
    paleto = {
        enabled = false,  -- DISABLED - we put a new interior here
        coords = vector3(-278.324158, 6228.18164, 30.7110977),
        interior_type = 'v_barbers'
    },
    city = {
        enabled = false,  -- DISABLED - we put a new interior here
        coords = vector3(-33.0160065, -152.317963, 56.0920944),
        interior_type = 'v_barbers'
    },
    vespucci = {
        enabled = false,  -- DISABLED - we put a new interior here
        coords = vector3(-1282.87061, -1117.27551, 6.005688),
        interior_type = 'v_barbers'
    },
    mirror_park = {
        enabled = false,  -- DISABLED - we put a new interior here
        coords = vector3(1212.29236, -472.808533, 65.22362),
        interior_type = 'v_barbers'
    },
    ghetto = {
        enabled = false,  -- DISABLED - we put a new interior here
        coords = vector3(136.937012, -1708.16211, 28.3071842),
        interior_type = 'v_barbers'
    },
    sandy = {
        enabled = false,  -- DISABLED - we put a new interior here
        coords = vector3(1931.78516, 3730.23828, 31.8600159),
        interior_type = 'v_barbers'
    }
}

-- Debug mode - set to true to see console messages about interior status
Config.Debug = false 