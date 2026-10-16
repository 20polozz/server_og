fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Origen Network'
description 'Sistema de Mercado Negro - Zona Capturável por Bandas'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    '@origen_map/shared/marcar.lua',

    'client/main.lua',
    'client/zones.lua',
    'client/zonas.lua',
    'client/nui_callbacks.lua',
    'client/notifications.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/zonas.lua',
    'server/capture.lua',
    'server/products.lua',
    'server/timer.lua',
    'server/tournament.lua'
}

ui_page 'ui/index.html'
--ui_page 'http://localhost:5173/'

files {
    'ui/**/*',
    'ui/index.html',
    'ui/assets/**/*'
}

--[[ Sin origen_inventory ni origen_notify aqui. Una dependencia dura hace que
     reiniciar cualquiera de los dos PARE este recurso, y FiveM no lo vuelve a
     arrancar: el mercado negro se quedaba apagado cada vez que se tocaba el
     inventario. A los dos se les llama solo en el momento de usarlos
     (Config.AddItem, products.lua, zones.lua con NotifySeguro). ]]
dependencies {
    'ox_lib',
    'oxmysql',
    'qbx_core',
}
