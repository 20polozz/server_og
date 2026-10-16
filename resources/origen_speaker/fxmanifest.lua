fx_version 'cerulean'

game 'gta5'

author 'OrigenNetwork'

version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'init.lua',
    'config/*.lua',
    'locales/locale.lua',
    'locales/es.lua',
    'locales/en.lua',
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    'custom/client/*.lua',
    'client/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'custom/server/*.lua',
    'server/*.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/*.css',
    'html/js/*.js',
}

dependencies {
    'ox_lib',
}

escrow_ignore {
    'config/*.lua',
	'custom/**/*.lua',
}