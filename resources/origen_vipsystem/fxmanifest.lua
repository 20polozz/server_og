-- Datos --
author      'Origen Network'
description 'VIP System developed by Origen Network'
fx_version  'cerulean'
game        'gta5'
version     '2.0.0'
lua54       'yes'

dependency 'origen_businesses'

shared_scripts {
    '@ox_lib/init.lua',
    'bridge/**/**/shared.lua',
    'shared/locale.lua',
    'lang.lua',
    'config.lua',
    'init.lua',
}

server_scripts {
    'config_sv.lua',
    'bridge/**/**/server.lua',
    '@oxmysql/lib/MySQL.lua',
    'server/database/*.lua',
    'server/logging.lua',
    'server/ratelimit.lua',
    'server/webhooks.lua',
    'server/managers/*.lua',
    'server/events/notify.lua',
    'server/main.lua',
    'server/callbacks/user.lua',
    'server/callbacks/admin.lua',
    -- La tienda de fichero «Apoya al proyecto» (13/10): qué se vende (catalogo/) y cómo (server/tienda/)
    'catalogo/ajustes.lua',
    -- El texto de venta y la galería de las casas (Catalogo.CasasVenta). Si falta algo en él, valen los textos de productos.lua
    'catalogo/casas_venta.lua',
    'catalogo/productos.lua',
    -- Los tatuajes propios (13/10): qué se vende y a cuánto, y de quién es cada uno. El pack
    -- (origen_tatuajes) y el tatuador (origen_tattoos) NO son `dependency`: se mira si están arrancados.
    'catalogo/tatuajes.lua',
    'catalogo/montar.lua',
    'server/tienda/tatuajes.lua',
    'server/tienda/tienda.lua',
    'custom/server.lua',
}

client_scripts {
    -- La marca (origen/nacion) para la NUI: contesta origen:marca:dame.
    '@origen_map/shared/tema.lua',
    'bridge/**/client.lua',
    'client/nui/admin.lua',
    'client/nui/user.lua',
    'client/nui/tienda.lua',
    'client/editablecl.lua',
    'client/testdrive.lua',
    'client/escaparate.lua',
    'client/tatuajes.lua',
    'client/main.lua',
    'custom/client.lua',
}

ui_page 'web/dist/index.html'

files {
    'web/dist/**',
    'locales/*.json',
}

escrow_ignore {
    'config.lua',
    'config_sv.lua',
    'lang.lua',
    'locales/*.json',
    'client/editablecl.lua',
    'custom/**',
}
