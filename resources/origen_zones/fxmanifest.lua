fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'OrigenNetwork'
description 'Zonas con reglas: se dibujan en el mapa y dentro mandan ellas'
version '2.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/geometria.lua'
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',

    'client/zonas.lua',
    'client/reglas.lua',
    'client/mapa.lua',
    'client/panel.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/basedatos.lua',
    'server/zonas.lua',
    'server/vigilante.lua'
}

ui_page 'ui/index.html'

files {
    'ui/**/*'
}

dependencies {
    'ox_lib',
    'oxmysql'
}
