fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'origen_graffiti'
author 'Origen Store'
description 'Graffiti System for FiveM'
version '1.0.0'

dependencies {
    'ox_lib',
    'oxmysql',
}

shared_scripts {
    '@ox_lib/init.lua',
    -- bridge: shared debe cargarse antes que config para que BridgeConfig ya exista
    'bridge/**/shared.lua',
    'config.advanced.lua',
    'config.lua',
    'shared/locale.lua',
    'shared/plane.lua',
}

client_scripts {
    '@origen_map/shared/foco.lua',
    --- La marca (origen/nacion) para la NUI y los colores que se pintan en el mundo.
    '@origen_map/shared/tema.lua',
    --- El primero, que es de donde sale OrigenMapa: custom/client/mapa.lua lo
    --- usa para poner la tienda en el mapa del servidor.
    '@origen_map/shared/marcar.lua',

    -- bridge: providers de notify, helptext, inventory (client-side)
    'bridge/**/client.lua',
    'client/render.lua',
    'client/dui.lua',
    'client/area_select.lua',
    'client/input.lua',
    'client/anim.lua',
    'client/main.lua',
    'client/shop.lua',
    'custom/client/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    -- bridge: providers de inventory, framework (server-side)
    'bridge/**/server.lua',
    'config.server.lua',
    'config.logs.server.lua',
    'init.lua',
    'server/grid_cache.lua',
    'server/delta_sync.lua',
    'server/main.lua',
    'custom/server/*.lua',
}

files {
    'web/canvas/index.html',
    'web/canvas/app.js',
    'web/dist/index.html',
    'web/dist/**/*',
    'locales/*.json',
}

ui_page 'web/dist/index.html'

escrow_ignore {
    'config.advanced.lua',
    'config.lua',
    'config.server.lua',
    'config.logs.server.lua',
    'items.lua',
    'custom/**/*',
    'locales/**/*',
}

dependency '/assetpacks'