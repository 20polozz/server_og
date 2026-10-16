-- ─────────────────────────────────────────────────────────────────────────────
-- USER CONFIG (essential)
-- This file is intended for server owner/admin.
-- Advanced technical tuning lives in `config.advanced.lua`.
-- ─────────────────────────────────────────────────────────────────────────────

-- Bridge providers. Set to 'auto' for auto-detection or specify: 'ox_lib', 'qb-core', etc.
-- See bridge/README.md for available providers.
BridgeConfig = {
    Notify     = 'auto',
    HelpText   = 'auto',
    DebugLevel = 0,   -- 0 = off, 1 = info, 2 = verbose (startup print)
}

Config = Config or {}

-- Locale language (locales/*)
Config.Language = 'es'

-- Admin panel access groups.
-- QB-Core / QBX: Ace Permissions (e.g. add_principal identifier.steam:... qbcore.admin)
-- ESX: group from xPlayer.getGroup() (e.g. 'admin', 'superadmin')
Config.AdminGroups  = { 'admin', 'god', 'superadmin' }
Config.AdminCommand = 'graffiti_admin'
Config.AdminPermission = 'origen_graffiti' -- Specific permission ID registered in origen_admin

-- ─────────────────────────────────────────────────────────────────────────────
-- Graffiti Shop (server configurable)
-- ─────────────────────────────────────────────────────────────────────────────

Config.Shop = {
    enterRadius = 2.5,   -- proximity radius to open shop (meters)

    blip = {
        enabled = true,
        sprite  = 73,      -- spray can icon
        color   = 0,       -- white
        scale   = 0.85,
        label   = 'Tienda de graffiti',
    },

    -- vector4(x, y, z, heading)
    locations = {
        vector4(-1123.5, -1440.04, 5.19, 304.08),
    },

    npc = {
        enabled  = true,
        model    = 'a_m_y_skater_01',
        scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
    },

    -- Item names in origen_inventory. All sprays share sprayItem; color stored in metadata.color.
    sprayItem  = 'graffiti_spray',
    eraserItem = 'graffiti_eraser',

    -- Initial durability stored in metadata.durability on purchase.
    defaultDurability = 100,
    -- Accumulated UV distance (0–1 canvas coords) required to consume 1 durability point.
    -- Canvas diagonal ≈ 1.41 UV. At 0.3 → 100pt spray lasts ~30 UV units.
    durabilityUvThreshold = 0.3,
    -- Durability cost per eraser use (one full tag deletion).
    eraserDurabilityPerUse = 25,

    -- Item catalog.
    -- type: 'eraser' | 'spray_custom' | 'spray_preset'
    -- color: hex #RRGGBB, only for spray_preset
    items = {
        {
            id    = 'borrador',
            type  = 'eraser',
            label = 'Disolvente',
            desc  = 'Borra los trazos del lienzo',
            price = 150,
            icon  = 'lucide:eraser',
        },
        {
            id    = 'spray_custom',
            type  = 'spray_custom',
            label = 'Espray de color libre',
            desc  = 'Elige el color que quieras',
            price = 350,
            icon  = 'lucide:spray-can',
        },
        {
            id    = 'spray_negro',
            type  = 'spray_preset',
            label = 'Espray negro',
            desc  = 'Negro intenso',
            price = 200,
            color = '#111111',
            icon  = 'lucide:spray-can',
        },
        {
            id    = 'spray_blanco',
            type  = 'spray_preset',
            label = 'Espray blanco',
            desc  = 'Blanco puro',
            price = 200,
            color = '#F0F0F0',
            icon  = 'lucide:spray-can',
        },
        {
            id    = 'spray_rojo',
            type  = 'spray_preset',
            label = 'Espray rojo',
            desc  = 'Rojo fuego',
            price = 220,
            color = '#CC2222',
            icon  = 'lucide:spray-can',
        },
        {
            id    = 'spray_azul',
            type  = 'spray_preset',
            label = 'Espray azul',
            desc  = 'Azul eléctrico',
            price = 220,
            color = '#2255CC',
            icon  = 'lucide:spray-can',
        },
        {
            id    = 'spray_amarillo',
            type  = 'spray_preset',
            label = 'Espray amarillo',
            desc  = 'Amarillo limón',
            price = 220,
            color = '#DDC000',
            icon  = 'lucide:spray-can',
        },
        {
            id    = 'spray_verde',
            type  = 'spray_preset',
            label = 'Espray verde',
            desc  = 'Verde urbano',
            price = 220,
            color = '#228822',
            icon  = 'lucide:spray-can',
        },
        {
            id    = 'spray_naranja',
            type  = 'spray_preset',
            label = 'Espray naranja',
            desc  = 'Naranja intenso',
            price = 220,
            color = '#CC6600',
            icon  = 'lucide:spray-can',
        },
        {
            id    = 'spray_violeta',
            type  = 'spray_preset',
            label = 'Espray violeta',
            desc  = 'Violeta intenso',
            price = 220,
            color = '#8822CC',
            icon  = 'lucide:spray-can',
        },
        {
            id    = 'spray_rosa',
            type  = 'spray_preset',
            label = 'Espray rosa',
            desc  = 'Rosa neón',
            price = 220,
            color = '#CC3388',
            icon  = 'lucide:spray-can',
        },
        {
            id    = 'spray_celeste',
            type  = 'spray_preset',
            label = 'Espray celeste',
            desc  = 'Azul cielo',
            price = 220,
            color = '#33AADD',
            icon  = 'lucide:spray-can',
        },
    },
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Auto Purge (startup only)
-- ─────────────────────────────────────────────────────────────────────────────
-- Si enabled=true, al iniciar el recurso se borran graffitis con created_at
-- más antiguo que la cantidad de días configurada.
Config.AutoPurge = {
    enabled = false,
    days    = 30,
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Zone limit (optional)
-- ─────────────────────────────────────────────────────────────────────────────
-- If enabled, players cannot start a NEW graffiti session when the amount
-- of saved graffitis inside the configured radius reaches maxTags.
Config.ZoneGraffitiLimit = {
    enabled = false,
    radius  = 60.0, -- meters
    maxTags = 8,
}
