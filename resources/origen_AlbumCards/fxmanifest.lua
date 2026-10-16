fx_version 'cerulean'
game 'gta5'

author 'Origen Network'
description 'Origen Album Cards System'
version '1.0.0'

ui_page 'html/index.html'

shared_scripts {
    'shared/locales.lua',
    'locales/*.lua',
    'shared/config.lua',
    'bridge/framework/init.lua',
    'bridge/inventory/init.lua',
    'bridge/permissions/init.lua',
    'bridge/menu/init.lua'
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    'bridge/framework/client.lua',
    'bridge/inventory/client.lua',
    'bridge/menu/client.lua',
    'bridge/menu/input.lua',
    'client/main.lua',
    'client/nui.lua',
    'client/shop.lua'
}

server_scripts {
    'bridge/framework/server.lua',
    'bridge/inventory/server.lua',
    'bridge/permissions/server.lua',
    '@oxmysql/lib/MySQL.lua',
    'server/db.lua',
    'server/main.lua',
    'server/trade.lua',
    'server/shop.lua'
}

lua54 'yes'

files {
    'html/index.html',
    'html/origen-pegatina.css',
    'html/assets/*',
    'stream/origen_album.ytyp'
}

data_file 'DLC_ITYP_REQUEST' 'stream/origen_album.ytyp'


escrow_ignore {
	'shared/*.lua',
	'bridge/**/**/*.lua',
	'locales/*.lua',
    'items/*.lua',
}
dependency '/assetpacks'