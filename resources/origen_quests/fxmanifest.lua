fx_version 'cerulean'
lua54 'yes'

game 'gta5'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    -- El catalogo de modelos de ped que puede llevar un NPC hostil.
    'config/peds.lua'
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    '@origen_map/shared/marcar.lua',

    'client/*.lua'
}

dependencies {
    'ox_lib'
}

server_script {
    '@oxmysql/lib/MySQL.lua', 
    'server/*.lua'
}

files {
    -- NUI Vue (bundle compilado desde source-ui/).
    'ui/index.html',
    'ui/assets/*',
}

ui_page {
    'ui/index.html'
}