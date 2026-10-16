--#--Fx Info--#--
fx_version 'cerulean'
use_fxv2_oal 'yes'
lua54 'yes'
game 'gta5'

--#--Resource Info--#--
version '1.0.4'
author 'OrigenNetwork'
description 'Advanced ambulance job'


--#--Shared Scripts--#--
shared_scripts {
	'@ox_lib/init.lua',
	'modules/utils/shared_config.lua',
}

ox_libs {
	'locale',
}

--#--Cliend-Side Scripts--#--
client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    '@origen_map/shared/marcar.lua',
    -- QBX.PlayerData local: hasJob lo lee cada 500 ms sin pedirlo por export.
    '@qbx_core/modules/playerdata.lua',

	"modules/utils/client/utils.lua",

	"client.lua",

	"modules/compatibility/frameworks/**/client.lua",
	"modules/compatibility/target/*.lua",

	"modules/injuries/client.lua",
	"modules/death/client.lua",
	"modules/stretcher/client.lua",
	"modules/paramedic/client.lua",

	"modules/job/client/main.lua",
	"modules/job/client/garage.lua",
	"modules/job/client/medical_bag.lua",
	"modules/job/client/stashes.lua",
	"modules/job/client/shops.lua",
	"modules/job/client/clothing.lua",
	"modules/job/client/bossmenu.lua",

	"modules/utils/client/coords_debug.lua",
}

--#--Server-Side Scripts--#--
server_scripts {
	"@oxmysql/lib/MySQL.lua",
	"modules/compatibility/frameworks/**/server.lua",
	"server.lua",
	"modules/commands/server.lua",
	"modules/compatibility/txadmin/server.lua",
}

ui_page 'html/index.html'

--#--Additions Files--#--
files {
	'html/index.html',
	'html/style.css',
	'html/script.js',
	'html/img/*.webp',
	'locales/*.json',
	"data/*.lua",
	'config.lua',
}
