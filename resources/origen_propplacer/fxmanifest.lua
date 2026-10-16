fx_version 'bodacious'
game 'gta5'
lua54 'yes'
author 'ORIGEN Store'
description 'origen_propplacer — Advanced prop placement system — ESX / QBCore / QBX / Standalone'
version '2.2.0'

shared_scripts {
    'config.lua',
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    'client/gizmo/dataview.lua',
    'client/gizmo/main.lua',
    'client/freecam.lua',
    'client/placement.lua',
    'client/main.lua',
}

exports {
    'openManagement'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/assets/*.js',
    'ui/assets/*.css',
}
