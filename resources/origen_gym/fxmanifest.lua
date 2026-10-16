fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Origen Network'
description 'Origen Gym: gimnasios con aparatos del propio GTA, puestos desde un configurador dentro del juego.'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    -- El vigilante del raton, la marca y el silencio, y los puntos del mapa.
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    '@origen_map/shared/marcar.lua',
    'juego.lua',
    'client.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua',
}

-- La pantalla se compila desde source-ui/ (npx vite build) a ui/.
ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/assets/*',
}

dependencies { 'ox_lib', 'oxmysql', 'origen_map', 'origen_notify' }
