fx_version 'cerulean'

game 'gta5'

author 'OrigenNetwork'

version '1.0.3'

shared_scripts {
	'@ox_lib/init.lua',
	'init.lua',
	'config/_main.lua',
	'config/translations/*.lua',
	'config/hotels.lua',
	'config/*.lua',
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    '@origen_map/shared/marcar.lua',

	'custom/client/*.lua',
	'client/classes/*.lua',
	'client/*.lua',
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'config/logs/*.lua',
	'custom/server/*.lua',
	'server/modules/*.lua',
	'server/classes/*.lua',
	'server/*.lua',
}

files {
	'ui/index.html',
	'ui/imagen.html',
	'ui/css/*.css',
	'ui/js/*.js',
	'ui/img/*.*',
	'ui/img/**/*.*',
	'ui/sounds/*.*',
}

ui_page 'ui/index.html'

dependencies {
	'ox_lib',
	'bob74_ipl',
}

--Escrow

lua54 'yes'

escrow_ignore {
    'config/*.lua',
    'config/**/*.lua',
	'custom/**/*.lua',
}

--[[ 10/10 17:24: se metieron aqui los siete int_*.ytyp del propio juego
     (DLC_ITYP_REQUEST) para que los muebles v_res_/v_ret_/... estuvieran
     siempre cargados. Al hacer ensure con 160 jugadores cayeron 55 en cinco
     minutos y siguieron cayendo 3 por minuto (GTA5_b3258.exe+777E75 y
     +168A0BB, nunca vistos antes de esa hora): definir dos veces los mismos
     arquetipos que ya trae el GTA revienta el cliente. Quitado el 10/10 a las
     17:35; los muebles que faltan se arreglan de otra forma (pedir el modelo
     con RequestModel y esperar, no duplicar el ytyp). ]]
