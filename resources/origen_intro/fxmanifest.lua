fx_version 'cerulean'
game 'gta5'

name 'origen_intro'
description 'Origen Intro - Llegada cinematica en vehiculo para personajes nuevos'
author 'Origen Network'
version '1.0.0'
lua54 'yes'

dependencies {
    'ox_lib',
    'qbx_core',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config/main.lua',
    'config/camara.lua',
    'shared/ritmo.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
}

client_scripts {
    '@origen_map/shared/tema.lua',
    'client/main.lua',
    'client/telon.lua',
    'client/aviso.lua',
    'client/conduccion.lua',
    'client/camara.lua',
    'client/enganche.lua',
}

server_scripts {
    'server/main.lua',
    'server/comandos.lua',
}
