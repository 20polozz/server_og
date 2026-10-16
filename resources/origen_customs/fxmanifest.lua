fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'OrigenNetwork'
description 'ORIGEN Customs · el taller de tuning'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/catalogo.lua',
    'shared/cambios.lua',
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',

    'client/aplicar.lua',
    'client/camara.lua',
    'client/puntos.lua',
    'client/taller.lua',
    'client/cliente.lua',
    'client/precios.lua',
    'client/ajustes.lua',
    'client/admin.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/precios.lua',
    'server/ajustes.lua',
    'server/registro.lua',
    'server/main.lua',
    'server/admin.lua',
}

-- Definiciones y rampas de los colores camaleón personalizados 223-242.
data_file 'CARCOLS_GEN9_FILE' 'data/carcols_gen9.meta'
data_file 'CARMODCOLS_GEN9_FILE' 'data/carmodcols_gen9.meta'

-- La interfaz es Vue + Vite: la fuente está en `source-ui/` y se compila con
-- `npx vite build` desde ahí; el resultado sale a `ui/` con nombres fijos.
ui_page 'ui/index.html'

files {
    'data/carcols_gen9.meta',
    'data/carmodcols_gen9.meta',
    'stream/vehicle_paint_ramps.ytd',
    'ui/index.html',
    'ui/assets/*.*',
}
