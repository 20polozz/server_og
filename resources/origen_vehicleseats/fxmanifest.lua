fx_version 'bodacious'
game 'gta5'
lua54 'yes'
author 'ORIGEN Store'
description 'origen_vehicleseats — Advanced vehicle seat creator with live preview and gizmo'
version '1.0.0'

shared_scripts {
    -- Any shared config or utils
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    'client/gizmo/dataview.lua',
    'client/gizmo/main.lua',
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/script.js',
    'ui/gestion/index.html',
    'ui/gestion/assets/*',
    'data/seats.json',
}
