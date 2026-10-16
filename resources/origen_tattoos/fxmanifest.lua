fx_version 'cerulean'

game 'gta5'

author 'Origen Network'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/*.lua',
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    '@origen_map/shared/marcar.lua',

    '@qbx_core/modules/playerdata.lua',
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

ui_page 'ui/index.html'
-- ui_page 'http://localhost:5173/'

files {
    'ui/index.html',
    'ui/assets/*.*',
    'assets_tattoos/*.json',
}

dependencies {
    'qbx_core',
    'ox_lib',
    'oxmysql'
}