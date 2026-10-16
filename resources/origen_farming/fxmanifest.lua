fx_version 'cerulean'
game 'gta5'
lua54 'yes'

-- 30/09: lleva ymaps que cambian el mapa del juego (stream/). Sin esto, en un
-- servidor con muchos recursos el mapa original ya está cargado cuando este
-- recurso termina de montarse en el cliente, y el cambio no se ve (en local sí,
-- porque monta antes). Con esto se cargan en la pantalla de carga.
this_is_a_map 'yes'

author 'OrigenNetwork'
description 'Granja de ORIGEN'
version '1.0.0'

dependencies {
    'ox_lib',
    'oxmysql',
    'qbx_core',
    'origen_inventory',
}

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/util.lua',
    'shared/maquina.lua',
}

client_scripts {
    '@origen_map/shared/marcar.lua',
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',

    'client/rastro.lua',
    'client/estado.lua',
    'client/equipo.lua',
    'client/relleno.lua',
    'client/plantas.lua',
    'client/campo.lua',
    'client/manos.lua',
    'client/tractor.lua',
    'client/cooperativa.lua',
    'client/maquina.lua',
    'client/procesado.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/base.lua',
    'server/datos.lua',
    'server/equipo.lua',
    'server/tope.lua',
    'server/cultivo.lua',
    'server/carga.lua',
    'server/procesado.lua',
    'server/vehiculos.lua',
    'server/mercado.lua',
    'server/panel.lua',
}

-- La interfaz es Vue + Vite: la fuente está en `source-ui/` y se compila con
-- `npx vite build` desde ahí; el resultado sale a `ui/`.
ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/assets/*',
}

-- Las máquinas propias (modelos, ytyp y texturas) van en stream/.
data_file 'DLC_ITYP_REQUEST' 'stream/origen_farming_planta.ytyp'
