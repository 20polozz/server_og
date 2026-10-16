fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_fxv2_oal 'yes'

name 'Renewed Weather Sync'
author 'FjamZoo - Renewed Scripts'
version '1.1.8'

shared_scripts{
    '@ox_lib/init.lua',
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    'client/*.lua',
    'compatability/**/client.lua',
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/assets/*.*'
}

server_scripts {
    'server/time.lua',
    'server/weather.lua',
    'compatability/**/server.lua',
}

-- provide 'qb-weathersync'
provide 'cd_easytime'