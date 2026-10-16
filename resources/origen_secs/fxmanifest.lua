fx_version 'bodacious'
game 'gta5'

author 'Origen Network'
description 'ORIGEN Security - DevTools Protection'
version '1.0.0'

shared_scripts {
	'@qb-core/shared/locale.lua',
}

client_script '@origen_map/shared/tema.lua'
client_script "client/main.lua"

server_script {
	'@oxmysql/lib/MySQL.lua',
	"server/main.lua",
	"server/permissions.lua"
}

ui_page 'html/index.html'

files {
	'html/index.html',
    'html/app.js'
    
}
