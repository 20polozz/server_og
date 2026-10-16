fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name        'origen_plates'
description 'Sistema de matrículas personalizadas y falsas'
version     '1.0.0'
author      'ORIGEN'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    '@origen_map/shared/marcar.lua',

    'client/main.lua',
    'client/sabotaje.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/sabotaje.lua',
}

ui_page 'ui/index.html'

files {
    'ui/**/*'
}

dependencies {
    'ox_lib',
    'oxmysql'
}
