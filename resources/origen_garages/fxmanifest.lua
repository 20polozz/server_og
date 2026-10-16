fx_version 'cerulean'
game 'gta5'

name "origen_garages"
description "Sistema de garajes"
author "Origen Network"
version "1.0.2"
lua54 'yes'

shared_scripts {
	'init.lua',
	'@ox_lib/init.lua',
	'config/*.lua'
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    '@origen_map/shared/marcar.lua',

	'client/*.lua',
	'custom/client/*.lua',
	'client/classes/**/*.lua',
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'custom/server/*.lua',
	'server/classes/*.lua',
	'server/classes/**/*.lua',
	'server/*.lua'
}

files {
    'ui/index.html',
    'ui/assets/*.*',
	'ui/images/*.*',
	'ui/brands/*.*',
	'ui/furniture/*.*',
	'locales/*.json',
}

ui_page 'ui/index.html'

escrow_ignore {
    'config/*.lua',
	'custom/**/*.lua',
}