fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'OrigenNetwork'
description 'Caza de ORIGEN'
version '2.0.0'

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
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    '@origen_map/shared/marcar.lua',

    'client/estado.lua',
    'client/presas.lua',
    'client/interaccion.lua',
    'client/campamento.lua',
    'client/admin.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    -- Los ajustes primero: pisan a shared/config.lua con lo que un admin haya
    -- cambiado desde el panel.
    'server/ajustes.lua',
    'server/datos.lua',
    'server/registro.lua',
    'server/main.lua',
    'server/grupos.lua',
    'server/torneo.lua',
    'server/panel.lua',
    'server/admin.lua',
}

-- La interfaz es Vue + Vite: la fuente está en `source-ui/` y se compila con
-- `npx vite build` desde ahí; el resultado sale a `ui/`.
ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/assets/*',
}
