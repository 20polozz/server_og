author 'Origen Network'
description 'Bussiness System'
version '1.0.0'

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

dependency 'origen_inventory'

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    '@origen_map/shared/marcar.lua',

    'source/client/classes/*.lua',
    'source/client/creation.lua',
    'source/client/*.lua',
    'custom/client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config/server.lua',
    'source/server/classes/*.lua',
    'source/server/*.lua',
    'custom/server/*.lua'
}

shared_scripts {
    '@ox_lib/init.lua',
    'source/shared/*.lua',
    -- A mano y no con 'config/*.lua': el comodín metía también config/server.lua,
    -- que lleva los webhooks de Discord, y todo lo compartido se descarga en el
    -- cliente. Un config nuevo que necesite el cliente hay que añadirlo aquí.
    'config/camaras.lua',
    'config/carteles.lua',
    'config/cocina.lua',
    'config/crafting.lua',
    'config/documentos.lua',
    'config/compraventa.lua',
    'config/main.lua',
    'config/taller.lua',
    'config/tienda.lua',
    'config/carga.lua',
    'config/gimnasio.lua',
    'config/pos.lua',
    'custom/shared/*.lua'
}

files {
    'locales/*.json',
    'ui/build/images/*.png',
    'ui/build/images/food/*.webp',
    'ui/build/food-props.json',
    'ui/build/index.html',
    'ui/build/lienzo.html',
    'ui/build/pos-screen.html',
    'ui/build/pos-screen.css',
    'ui/build/pos-screen.js',
    'ui/build/assets/*.js',
    'ui/build/assets/*.css',
    'ui/build/assets/*.wav'
}

ui_page 'ui/build/index.html'
-- ui_page 'http://localhost:5173/'
