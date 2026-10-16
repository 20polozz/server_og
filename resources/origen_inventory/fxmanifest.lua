fx_version 'cerulean'
game 'gta5'

description 'origen_inventory'
author ' Origen Network'
version '2.1.10'

lua54 'of course'

integrations '{"lb-phone": "2.3.7", "qs-smartphone-pro": "1.3.3", "esx": "1.13.4", "qbcore": "1.3.0"}'

shared_scripts {
	'config.lua',
	'locales/translations/*.lua',
	'locales/locales.lua',
	'config/*.lua',
	'components/*.lua',
	'modules/*.lua',
	'AutoStart.lua',
	'@ox_lib/init.lua' -- Uncomment this line if you want to use ox_lib
}

server_script {
	'config_sv.lua',
	'middlewares/server.lua',
	'bridge/sql.lua',
	'bridge/**/server/*lua',
	'server/classes/c_*.lua',
	'server/*.lua',
	'server/functions/f_*.lua',
}

client_script {
	'@origen_map/shared/foco.lua',
	'@origen_map/shared/marcar.lua',
	'@origen_map/shared/tema.lua',

	'bridge/**/client/*lua',
	'client/classes/c_*.lua',
	'client/*.lua',
	'client/photomode.lua',
	'client/functions/f_*.lua',
}

ui_page {
	'ui/index.html'
	-- 'http://localhost:5173/'
}

files {
	'ui/**/*',
	'ui/images/*.png',
	'ui/icons/*.png',
	'ui/*',
}

-- Uncomment if you have old scripts that use qb-inventory (no require qb-inventory installed)
-- provide 'qb-inventory'

-- Uncomment if you have qbx_core installed
provide 'ox_inventory'



-- Escrow
escrow_ignore {
	'config.lua',
	'config_sv.lua',
	'bridge/**/**/*.lua',
	'config/*.*',
	'locales/**/*.lua',
	'middlewares/*.lua'
}