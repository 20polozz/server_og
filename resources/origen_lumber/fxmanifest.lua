fx_version 'cerulean'
game 'gta5'
lua54 'yes'

-- 30/09: lleva ymaps que cambian el mapa del juego (stream/). Sin esto, en un
-- servidor con muchos recursos el mapa original ya está cargado cuando este
-- recurso termina de montarse en el cliente, y el cambio no se ve (en local sí,
-- porque monta antes). Con esto se cargan en la pantalla de carga.
this_is_a_map 'yes'

author 'OrigenNetwork'
description 'Aserradero de Paleto'
version '1.0.0'

dependencies {
    'ox_lib',
    'oxmysql',
    'qbx_core',
}

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/util.lua',
    'shared/maquina.lua',
    'shared/puntos.lua',
}

client_scripts {
    '@origen_map/shared/marcar.lua',
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    'client/rastro.lua',
    'client/estado.lua',
    'client/equipo.lua',
    'client/monte.lua',
    'client/trabajo.lua',
    'client/vehiculos.lua',
    'client/aserradero.lua',
    'client/maquina.lua',
    'client/linea.lua',
    'client/editor.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/base.lua',
    'server/datos.lua',
    'server/equipo.lua',
    'server/tope.lua',
    'server/trabajo.lua',
    'server/vehiculos.lua',
    'server/linea.lua',
    'server/panel.lua',
    'server/editor.lua',
}

ui_page 'ui/index.html'

files {
    'shared/puntos.json',
    'ui/index.html',
    'ui/assets/*',
}

-- Las máquinas propias (modelos, ytyp y texturas) van en stream/.
data_file 'DLC_ITYP_REQUEST' 'stream/origen_lumber_planta.ytyp'
