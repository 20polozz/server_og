fx_version 'cerulean'
game 'gta5'
use_experimental_fxv2_oal 'yes'

description 'Origen HUD'
version '1.0.0'
lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    'client/lib/*.lua',
    'client/*.lua',
}

server_scripts {
    'server/*.lua',
}

files {
    'ui/index.html',
    'ui/assets/*.*',
}

ui_page 'ui/index.html'