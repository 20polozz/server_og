fx_version 'cerulean'
game 'gta5'

dependencies {
    'ox_lib'
}

shared_scripts {
    '@ox_lib/init.lua',
    'init.lua',
    'shared/*.lua',
    'shared/classes/*.lua',
    'config/*.lua',
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    '@origen_map/shared/marcar.lua',

    'custom/client/*.lua',
    'client/classes/*.lua',
    'client/bridge/*.lua',
    'client/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'custom/server/*.lua',
    'server/classes/*.lua',
    'server/migration/*.lua',
    'server/*.lua'
}


files {
    'ui/index.html',
    'ui/assets/*.*',
    'ui/images/*.*',
    'ui/images/**/*.*',
    'locales/*.json'
}

ui_page 'ui/index.html'
lua54 'yes'

escrow_ignore {
    'config/*.lua',
	'custom/**/*.lua',
}

-- provide 'illenium-appearance'