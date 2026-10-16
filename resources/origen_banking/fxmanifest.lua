author 'Origen Network'
description 'Origen Bank - A banking system for your server'
version '1.0.0'
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'init.lua',
    'config/*.lua',
    'custom/shared/*.lua'
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    '@origen_map/shared/marcar.lua',

    'client/main.lua',
    'client/nui.lua',
    'client/admin.lua',
    'client/puntos.lua',
    'custom/client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config/server/*.lua',
    'server/logs.lua',
    'server/classes/*.lua',
    'server/hooks.lua',
    'server/banks.lua',
    'server/puntos.lua',
    'server/accounts.lua',
    'server/cbs.lua',
    'server/admin.lua',
    'server/compatibility.lua',
    'custom/server/*.lua'
}

files {
    'ui/index.html',
    'ui/assets/*.*',
}

ui_page 'ui/index.html'
-- ui_page 'http://localhost:5174/'