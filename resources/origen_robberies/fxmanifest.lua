fx_version "cerulean"
author "Origen Network"
game "gta5"
lua54 'yes'

ui_page 'ui/build/index.html'
-- ui_page 'http://localhost:5173/'

-- Por nombre no: cada build cambia lo que hay dentro de assets (las fuentes
-- ya no se empaquetan y Leaflet trae sus propios PNG). Con el glob no hay
-- que tocar esto cada vez.
files {
    'ui/build/index.html',
    'ui/build/assets/**',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config/*.lua',
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    '@origen_map/shared/marcar.lua',

    'client/**/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua',
}