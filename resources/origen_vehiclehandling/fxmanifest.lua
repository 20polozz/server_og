fx_version 'cerulean'
game 'gta5'

description 'Origen Vehicle Handling'
author 'OGN Servers'
version '1.0.0'

shared_scripts {
    'config.lua',
    'shared/campos.lua'
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    'client.lua'
}

server_scripts {
    'server.lua'
}

dependencies {
    'oxmysql'
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/assets/*.*'
}

lua54 'yes'
