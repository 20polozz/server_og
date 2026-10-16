fx_version 'cerulean'
game 'gta5'

name 'origen_dealerships'
author 'Origen'
description 'Dealership system for FiveM'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'init.lua',
    'config/*.lua',
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    '@origen_map/shared/marcar.lua',

    'custom/client/**/*.lua',
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/classes/*.lua',
    'custom/server/*.lua',
    'server/*.lua'
}

ui_page 'html/index.html'

files {
    'html/**/*.*',
    'locales/*.json',
    'stream/dealer_green_screen.ytyp'
}

-- La caja verde de las fotos automaticas de los coches (client/fotos.lua).
-- Va registrada suelta, sin ymap: no aparece en el mapa, solo se crea con
-- CreateObject mientras se sacan las fotos y se borra al terminar.
data_file 'DLC_ITYP_REQUEST' 'stream/dealer_green_screen.ytyp'

-- Escrow
escrow_ignore {
    'config/*.lua',
    'locales/*.json',
    'custom/**/*.lua',
}