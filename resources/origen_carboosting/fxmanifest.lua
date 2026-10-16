fx_version 'cerulean'
game 'gta5'

author 'Origen Network'
description 'Origen Contracts system developed by Origen Network'
version '1.0.1'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'init.lua',
    'config/*.lua',
    'shared/*.lua',
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    '@origen_map/shared/marcar.lua',

    'custom/client/*.lua',
    'client/missions_adapters.lua',
    'client/missions_main.lua',
    'client/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'custom/server/*.lua',
    'server/utils.lua',
    'server/inventory.lua',
    'server/market.lua',
    'server/offers.lua',
    'server/missions_schema.lua',
    'server/missions_points.lua',
    'server/missions_store.lua',
    'server/missions_runtime.lua',
    'server/missions_editor.lua',
    'server/main.lua',
}

files {
    'html/index.html',
    'html/js/*.js',
    'html/css/*.*',
    'html/img/*.*',
    'html/sounds/*.*',
    'locales/*.json',
}

ui_page 'html/index.html'

dependencies {
    'ox_lib',
    -- origen_minijuegos NO: reiniciarlo paraba este recurso y FiveM no lo vuelve a arrancar.
}

escrow_ignore {
    "config/*.lua",
    "custom/**/*.lua",
}