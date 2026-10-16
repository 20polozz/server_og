fx_version 'cerulean'
games { 'gta5' }

author 'Origen Network'
description 'Script de imagen para Origen'
version '1.0'

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    'client/client.lua'
}

server_scripts {
    'server/server.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}
