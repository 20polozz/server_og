--[[
    ============================================================
    LOCATIONS SETTINGS
    ============================================================
    Defines the available location types for gang points of
    interest (stashes, garages, clothing rooms, bank spots).
    Each type controls its blip, marker appearance, and the
    permission required to interact with it.

    ── MARKER FIELDS ────────────────────────────────────────────
    type          (int)    marker type id — see fivem.net/docs/game-references/markers/
    offset        (table)  { x, y, z } — offset from the base coord
                           Legacy alias: offsetZ (float) — kept for compatibility.
                           If 'offset' is present it takes precedence over offsetZ.
    scale         (table)  { x, y, z }
    color         (table)  { r, g, b, a }  (0–255 each)
    bobUpAndDown  (bool)   marker floats up and down
    faceCamera    (bool)   marker always faces the camera
    rotationOrder (int)    rotation axis order (default 2)
    rotate        (bool)   marker spins on its axis
    ============================================================
--]]

Config.Locations = {
    -- Maximum distance at which location labels are drawn in the world
    DrawDistance = 50.0,

    -- Distance in meters at which the player can interact with a location
    InteractDistance = 1.5,

    -- Distance at which the 3D marker starts rendering
    MarkerDrawDistance = 15.0,

    -- ── LOCATION TYPES ───────────────────────────────────────────────────────
    -- Each entry is a named location type that can be assigned to gang locations.
    -- 'requiredPermission' maps to the gang rank permission system.

    Types = {
        stash = {
            label              = 'Alijo de banda',
            blip = {
                enabled = false,
                sprite  = 473,
                color   = 4,
                scale   = 0.7,
            },
            marker = {
                type          = 22,
                offset        = { x = 0.0, y = 0.0, z = 1.0 },
                scale         = { x = 0.25, y = 0.25, z = 0.25 },
                color         = { r = 0, g = 0, b = 0, a = 255 },
                bobUpAndDown  = true,
                faceCamera    = true,
                rotationOrder = 2,
                rotate        = false,
            },
            default            = true,
            requiredPermission = 'access_stash',
        },

        personal_stash = {
            label              = 'Alijo personal',
            blip = {
                enabled = false,
                sprite  = 473,
                color   = 4,
                scale   = 0.6,
            },
            marker = {
                type          = 22,
                offset        = { x = 0.0, y = 0.0, z = 1.0 },
                scale         = { x = 0.25, y = 0.25, z = 0.25 },
                color         = { r = 0, g = 0, b = 0, a = 255 },
                bobUpAndDown  = true,
                faceCamera    = true,
                rotationOrder = 2,
                rotate        = false,
            },
            default            = true,
            requiredPermission = 'access_personal_stash',
        },

        garage = {
            label              = 'locations.types.garage.label',
            blip = {
                enabled = false,
                sprite  = 50,
                color   = 4,
                scale   = 0.7,
            },
            marker = {
                type          = 22,
                offset        = { x = 0.0, y = 0.0, z = 1.0 },
                scale         = { x = 0.25, y = 0.25, z = 0.25 },
                color         = { r = 0, g = 0, b = 0, a = 255 },
                bobUpAndDown  = true,
                faceCamera    = true,
                rotationOrder = 2,
                rotate        = false,
            },
            -- Preview de vehículo durante el placement del punto de garage.
            -- El admin puede colocar el punto y girar con la rueda del mouse
            -- para definir el heading exacto en que spawnearán los vehículos.
            placement_preview = {
                vehicle_model = 'sultan',   -- modelo que se muestra en el placement
                vehicle_alpha = 150,        -- transparencia 0–255 (150 = semitransparente)
            },
            default            = true,
            requiredPermission = 'access_garage',
        },

        clothing = {
            label              = 'locations.types.clothing.label',
            blip = {
                enabled = false,
                sprite  = 73,
                color   = 4,
                scale   = 0.7,
            },
            marker = {
                type          = 22,
                offset        = { x = 0.0, y = 0.0, z = 0.0 },
                scale         = { x = 0.25, y = 0.25, z = 0.25 },
                color         = { r = 0, g = 0, b = 0, a = 255 },
                bobUpAndDown  = true,
                faceCamera    = true,
                rotationOrder = 2,
                rotate        = false,
            },
            default            = true,
            requiredPermission = 'access_clothing',
        },

        bank = {
            label              = 'Depositar al banco',
            blip = {
                enabled = false,
                sprite  = 473,
                color   = 4,
                scale   = 0.7,
            },
            marker = {
                type          = 22,
                offset        = { x = 0.0, y = 0.0, z = 0.0 },
                scale         = { x = 0.25, y = 0.25, z = 0.25 },
                color         = { r = 0, g = 0, b = 0, a = 255 },
                bobUpAndDown  = true,
                faceCamera    = true,
                rotationOrder = 2,
                rotate        = false,
            },
            default            = true,
            requiredPermission = 'deposit',
        },

        -- Punto de gestión: abre el panel de banda al interactuar.
        -- Cualquier miembro puede usarlo; solo rangos con manage_locations pueden colocarlo.
        management = {
            label              = 'locations.types.management.label',
            blip = {
                enabled = false,
                sprite  = 473,
                color   = 4,
                scale   = 0.7,
            },
            marker = {
                type          = 22,
                offset        = { x = 0.0, y = 0.0, z = 1.0 },
                scale         = { x = 0.25, y = 0.25, z = 0.25 },
                color         = { r = 0, g = 0, b = 0, a = 255 },
                bobUpAndDown  = true,
                faceCamera    = true,
                rotationOrder = 2,
                rotate        = false,
            },
            default            = true,
            requiredPermission = nil,   -- cualquier miembro puede abrir el panel
        },
    },
}

-- Convenience alias used in some internal systems
Config.LocationTypes = Config.Locations.Types
