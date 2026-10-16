fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'OrigenNetwork'
description 'Cantera de ORIGEN'
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
    'shared/puntos.lua',
}

client_scripts {
    '@origen_map/shared/marcar.lua',
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    'client/rastro.lua',
    'client/estado.lua',
    'client/equipo.lua',
    'client/cantera.lua',
    'client/trabajo.lua',
    'client/vehiculos.lua',
    'client/planta.lua',
    'client/explosivos.lua',
    'client/editor.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/base.lua',
    'server/datos.lua',
    'server/equipo.lua',
    'server/tope.lua',
    'server/trabajo.lua',
    'server/explosivos.lua',
    'server/vehiculos.lua',
    'server/planta.lua',
    'server/panel.lua',
    'server/editor.lua',
}

-- La interfaz es Vue + Vite: la fuente está en `source-ui/` y se compila con
-- `npx vite build` desde ahí; el resultado sale a `ui/`.
ui_page 'ui/index.html'

files {
    'shared/puntos.json',
    'ui/index.html',
    'ui/assets/*',
}
