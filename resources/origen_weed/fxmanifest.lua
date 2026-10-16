fx_version 'cerulean'
game 'gta5'

name 'origen_weed'
author 'Origen Network'
description 'Optimized weed planting system'
version '1.0.0'

lua54 'yes'

ui_page 'ui/index.html'
-- ui_page 'http://localhost:5173/'  -- descomentar para hot-reload en dev

files {
    'ui/index.html',
    'ui/assets/*.*',
}

-- Los props propios (tendal, maceta, mesa, bidón, regadera y garrafa) viven en
-- [assets]/[props]/origen_modelos, con el resto de modelos del servidor. Si
-- estuvieran aquí, un restart de este recurso con uno de ellos delante tumba
-- el juego.

shared_scripts {
    '@ox_lib/init.lua',
    'config/*.lua'
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    'client/*.lua'
}

exports {
    'UseFemaleSeedItem',
    'UseEmptyCanItem'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

dependencies {
    'qb-core',
    'oxmysql'
}
