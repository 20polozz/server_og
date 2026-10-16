fx_version 'cerulean'
game 'gta5'
lua54 'yes'


author 'OrigenNetwork'
description 'Recogida de basuras de Davis'
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
}

client_scripts {
    '@origen_map/shared/marcar.lua',
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    'client/rastro.lua',
    'client/estado.lua',
    'client/equipo.lua',
    'client/dibujo.lua',
    'client/maquina.lua',
    'client/trabajo.lua',
    'client/vehiculos.lua',
    'client/prensa.lua',
    'client/deposito.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/base.lua',
    'server/datos.lua',
    'server/equipo.lua',
    'server/tope.lua',
    'server/trabajo.lua',
    'server/vehiculos.lua',
    'server/prensa.lua',
    'server/panel.lua',
}

-- La planta de compactación (modelos, ytyp y texturas propias)
-- va en stream/. El mapa del depósito (el patio limpio) es un recurso aparte,
-- origen_mapa_davis, que carga como mapeado.
data_file 'DLC_ITYP_REQUEST' 'stream/origen_garbage_planta.ytyp'

-- La interfaz es Vue + Vite: la fuente está en `source-ui/` y se compila con
-- `npx vite build` desde ahí; el resultado sale a `ui/`.
ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/assets/*',
}
