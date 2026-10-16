fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Origen Network'
description 'Image Uploader Standalone'
version '1.0.0'

ui_page 'ui/dist/index.html'

files {
    'ui/dist/index.html',
    'ui/dist/assets/*'
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config_sv.lua',
    'server.lua'
}

shared_scripts {
    '@ox_lib/init.lua'
}
