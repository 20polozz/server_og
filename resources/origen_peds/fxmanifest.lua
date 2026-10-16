author      'Origen Network'
description 'Player owned peds for Nacion'
fx_version  'cerulean'
game        'gta5'
version     '1.0.0'
lua54       'yes'

dependencies {
    'ox_lib',
    'oxmysql',
}

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
}

client_scripts {
    'client/main.lua',
    'client/pedskin.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

server_exports {
    'GivePed',
    'GetPlayerPeds',
    'EquipPed',
    'UnequipPed',
}
