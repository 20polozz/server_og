fx_version "bodacious"

game "gta5"

author "OrigenNetwork"

version "0.0.2"

shared_scripts {
    "config/*.lua",
    "locales.lua",
}

client_scripts {
	'@origen_map/shared/foco.lua',
	'@origen_map/shared/tema.lua',
	"custom/client/*.lua",
	"client/modules/tables.lua",
	"client/init.lua",
	"client/functions.lua",
	"client/events.lua",
	"client/main.lua",
	"client/**/*.lua",
}

server_scripts {
	"@oxmysql/lib/MySQL.lua",
	"custom/server/*.lua",
	"utils/*.lua",
	"server/init.lua",
	"server/**/*.lua",
}

ui_page 'ui/index.html'

files {
	'ui/index.html',
	'ui/assets/*',
}

-- Escrow
lua54 'yes'

dependencies {
    "pma-voice"
}

escrow_ignore {
    "config/*.lua",
    "locales.lua",
    "custom/**/*.lua",
}

dependency '/assetpacks'