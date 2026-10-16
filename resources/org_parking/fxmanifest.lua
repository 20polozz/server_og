fx_version 'cerulean'
game      'gta5'
author    'OrigenNetwork'
description 'Advanced street parking system — standalone, any framework, encrypted'
version   '1.0.0'

-- ─────────────────────────────────────────────────────────────────────────
--  Shared (client + server): config → locale → init (T() function)
--  Custom bridges load AFTER config so they can read Config.* values.
-- ─────────────────────────────────────────────────────────────────────────
shared_scripts {
    '@ox_lib/init.lua',
    'config/config.lua',   -- ► edit this
    'init.lua',            -- loads locale, defines T() and dbg()
}

-- ─────────────────────────────────────────────────────────────────────────
--  Server scripts
-- ─────────────────────────────────────────────────────────────────────────
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'custom/sv_framework.lua',   -- ► edit this (framework bridge)
    'custom/sv_keys.lua',        -- ► edit this (key system bridge)
    'custom/sv_mechanic.lua',    -- ► edit this (vehicle health bridge)
    'server/sv_grid.lua',
    'server/sv_store.lua',
    'server/sv_spawn_queue.lua',
    'server/sv_dsp_watcher.lua',
    'server/main.lua',
    'server/sv_admin.lua',
}

-- ─────────────────────────────────────────────────────────────────────────
--  Client scripts
-- ─────────────────────────────────────────────────────────────────────────
client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    '@origen_map/shared/marcar.lua',

    'custom/cl_framework.lua',   -- ► edit this (framework bridge)
    'custom/cl_keys.lua',        -- ► edit this (key system bridge)
    'custom/cl_fuel.lua',        -- ► edit this (fuel system bridge)
    'client/cl_tracker.lua',
    'client/main.lua',
    'client/cl_admin.lua',
}

-- ─────────────────────────────────────────────────────────────────────────
--  NUI
-- ─────────────────────────────────────────────────────────────────────────
ui_page 'ui/index.html'

files {
    'locales/*.lua',     -- needed for client-side LoadResourceFile in init.lua
    'ui/index.html',
    'ui/assets/**',
}

-- ─────────────────────────────────────────────────────────────────────────
--  Dependencies
--  ox_lib and oxmysql are required.
--  Key system resources are optional — only needed based on Config.KeySystem.
-- ─────────────────────────────────────────────────────────────────────────
dependencies {
    'ox_lib',
    'oxmysql',
}

lua54 'yes'
