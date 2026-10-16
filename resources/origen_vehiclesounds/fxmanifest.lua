fx_version 'cerulean'
game 'gta5'

author 'OrigenNetwork'
description 'Premium Dynamic Vehicle Engine Sound Override & Customizer'
version '1.0.0'

ui_page 'ui/index.html'

shared_script '@ox_lib/init.lua'

files {
    'ui/index.html',
    -- El juego de piezas de la tablet va antes que el estilo del recurso.
    'ui/ogn.css',
    'ui/style.css',
    'ui/main.js'
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    'config/shared.lua',
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config/shared.lua',
    'server/main.lua'
}

client_exports {
    'openManagement',
    'OpenSoundsMenu'
}
