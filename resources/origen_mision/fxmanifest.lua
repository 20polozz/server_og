fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Origen Network'
description 'Origen Encargos: el Notario reparte encargos con historia (matar, robar coches, entregar) que se abren por orden y suben de dificultad.'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    -- El vigilante del raton, el puente de la interfaz (marca y silencio) y los puntos del mapa.
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    '@origen_map/shared/marcar.lua',
    -- Las voces grabadas (herramientas/voces.py): texto -> fichero y segundos.
    'voces.lua',
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
    -- Los iconos de las pistas: los carga el inventario por https://cfx-nui-origen_mision/ui/pistas/...
    'ui/pistas/*.png',
    -- Las voces de los personajes (herramientas/voces.py).
    'ui/voces/*.ogg',
}

dependencies { 'ox_lib', 'oxmysql', 'qbx_core', 'origen_map', 'origen_notify' }
