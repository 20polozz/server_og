fx_version 'cerulean'
game 'gta5'

name 'origen_emergency_dealership'
description 'Emergency Vehicle Dealership'
version '1.0.0'
author 'OrigenNetwork'

this_is_a_map 'yes'

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/css/style.css',
    'ui/js/app.js'
}

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
    'config.lua'
}

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

dependencies {
    'ox_lib',
    'qbx_core',
    'oxmysql'
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'
