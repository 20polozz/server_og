fx_version 'cerulean'
game 'gta5'

version '1.0.0'

lua54 'yes'

author 'Origen Network'
description 'Origen Waypoints'

shared_scripts {
    '@ox_lib/init.lua',
}

client_scripts {
    'client/manager/*.lua',
    'client/classes/*.lua',
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
}

files {
    'config/*.lua',
    'ui/index.html',
    'ui/assets/*.*',
}