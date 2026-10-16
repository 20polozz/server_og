fx_version 'cerulean'

game 'gta5'

author 'OrigenNetwork'

version '1.0.2'

shared_scripts {
	'@ox_lib/init.lua',
	'init.lua',
	'config/config.lua',
	'config/translations/*.lua',
}

client_scripts {
	'@origen_map/shared/foco.lua',
	'@origen_map/shared/tema.lua',
	'custom/client/*.lua',
	'client/*.lua',
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'config/server/*.lua',
	'custom/server/*.lua',
	'server/door.lua',
	'server/main.lua',
	'server/ganzua.lua',
}

ui_page 'ui/index.html'

files {
	'ui/*.*',
	'ui/**/*.*',
}

--Escrow

lua54 'yes'

escrow_ignore {
    'config/*.lua',
    'config/**/*.lua',
	'custom/**/*.lua',
}