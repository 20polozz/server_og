fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name "origen_fuel"
description "Recurso de combustible by Origen Network"
author "Origen Network"
version "1.0.0"

shared_scripts {
	'@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
	'config/*.lua',
}

client_scripts {
	'@origen_map/shared/foco.lua',
	'@origen_map/shared/tema.lua',
	'client/utils.lua',
	'client/polyzone.lua',
	'client/admin.lua',
	'client/refuel.lua',
	'client/consumption.lua',
	'client/job.lua',
	'client/test.lua',
    'client/nozzle.lua'
}

server_scripts {
	'server/*.lua'
}

files {
    'ui/index.html',
    'ui/assets/*.*',
}

ui_page 'ui/index.html'