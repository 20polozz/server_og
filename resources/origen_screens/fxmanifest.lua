fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Origen Network'
description 'Teles y pantallas: YouTube y Twitch sobre la pantalla de los props'
version '2.0.0'

ui_page 'html/index.html'

dependencies {
    'ox_lib',
    -- origenweb NO: reiniciarlo paraba las teles. Solo se carga su pagina al encender una.
}

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/enlaces.lua',
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    'client/motor.lua',
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

files {
    'html/index.html',
    'html/style.css',
    'html/plantilla-admin.css',
    'html/script.js',
}
