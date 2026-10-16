--[[
    ============================================================
    VEHICLES & GARAGE SETTINGS
    ============================================================
    Controls the gang vehicle limit and the garage system,
    including impound fines, spawn behavior, and vehicle
    category labels for the UI.
    ============================================================
--]]

Config.Vehicles = {
    -- Enable the gang vehicle ownership system
    Enable = true,

    -- Maximum number of vehicles a gang can own
    MaxVehicles = 10,
}

Config.Garage = {
    -- Return all spawned vehicles to the garage when the resource restarts
    ReturnVehiclesOnRestart = true,

    -- ── IMPOUND ──────────────────────────────────────────────────────────────
    Impound = {
        -- Enable the impound system (vehicles can be towed and require a fine to retrieve)
        Enable = true,

        -- Fine in $ to retrieve an impounded vehicle
        Fine = 5000,

        -- Deduct the fine from the gang bank instead of the player's personal wallet
        PayFromGangBank = true,
    },

    -- Distance in meters from the spawn point where the vehicle appears
    SpawnDistance = 5.0,

    -- Distance in meters at which a previously spawned vehicle is auto-deleted
    -- when the player drives another one out of the garage
    DeleteDistance = 50.0,

    -- Vehicle category options shown in the garage UI filter
    VehicleCategories = {
        { value = 'cars',        label = 'vehicle_categories.cars'        },
        { value = 'motorcycles', label = 'vehicle_categories.motorcycles' },
        { value = 'boats',       label = 'vehicle_categories.boats'       },
        { value = 'helicopters', label = 'vehicle_categories.helicopters' },
        { value = 'planes',      label = 'vehicle_categories.planes'      },
        { value = 'trucks',      label = 'vehicle_categories.trucks'      },
    },

    -- Fallback spawn points used when a location has no custom spawn defined.
    -- Format: vec4(x, y, z, heading)
    DefaultSpawnPoints = {
        vec4(0.0, 0.0, 0.0, 0.0),
        vec4(0.0, 0.0, 0.0, 0.0),
        vec4(0.0, 0.0, 0.0, 0.0),
        vec4(0.0, 0.0, 0.0, 0.0),
    },
}
