fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'OrigenNetwork'
description 'Sistema de Remolque con Barcos para Origen'
version '1.0.0'

ui_page 'ui/index.html'

files {
    'ui/index.html'
}

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
    'config.lua'
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}
