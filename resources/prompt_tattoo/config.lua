Config = {}

-- Barber Shop Locations Configuration
-- Set to true to ENABLE interior, false to DISABLE interior
Config.Locations = {
    city = {
        enabled = false,  -- DISABLED - we put a new interior here
        coords = vector3(322.967865, 181.942917, 102.587761),
        interior_type = 'v_tattoo'
    },
    el_burro = {
        enabled = false,  -- DISABLED - we put a new interior here
        coords = vector3(1312.12122, -1662.897, 43.64954),
        interior_type = 'v_tattoo'
    },
    vespucci = {
        enabled = false,  -- DISABLED - we put a new interior here
        coords = vector3(-1164.83655, -1435.17188, -4.84657764),
        interior_type = 'v_tattoo'
    },
    chumach = {
        enabled = false,  -- DISABLED - we put a new interior here
        coords = vector3(-3171.2937, 1076.24451, 19.8303947),
        interior_type = 'v_tattoo'
    }
}

-- Debug mode - set to true to see console messages about interior status
Config.Debug = false 