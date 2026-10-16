fx_version 'cerulean'

game 'gta5'

author 'OrigenNetwork'

version '1.0.0'

lua54 'yes'

-- UI Actualizado (Vue 3 + Vite)
ui_page 'ui-vue-dist/index.html'
-- ui_page 'http://localhost:5173/'

files {
    'ui-vue-dist/**',
	'locales/*.json'
}

shared_scripts {
	'@ox_lib/init.lua',
	'init.lua',
	'config/*.lua',
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    '@origen_map/shared/marcar.lua',

	'custom/client/*.lua',
	'client/*.lua',
}

server_scripts {
	"@oxmysql/lib/MySQL.lua",
	'custom/server/*.lua',
	'server/*.lua',
}

dependencies {
	'oxmysql',
	'ox_lib',
	-- origen_notify NO: reiniciarlo paraba este recurso y no volvia a arrancar.
	-- Se le llama al usarlo, con NotifySeguro (client/menu_point.lua).
}

escrow_ignore {
	'config/*.*',
	'locales/*.*',
	'custom/**/*.*',
}
