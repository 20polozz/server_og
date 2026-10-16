fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

author 'Ibonoja'
description 'IPL Manager'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'editable/config.lua',
    'shared/init.lua',
    'shared/maps/*.lua',
}

server_scripts {
    'server/setup.lua',
    'server/init.lua',
}

client_scripts {
    'client/utils.lua',
    'client/handlers.lua',
    'client/setup.lua',
    'client/init.lua',
}

dependencies {
    '/server:7290',
    '/onesync',
}

files {
    'editable/config.lua',
    'client/**/*.lua',
    'shared/**/*.lua',

}

escrow_ignore {
    'editable/config.lua',
}

dependency '/assetpacks'