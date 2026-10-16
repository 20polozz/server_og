fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'OrigenNetwork'
description 'Autoescuela de Los Santos: el carné de conducir'
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
    -- El recorrido va ANTES de los exámenes: son ellos los que lo usan.
    'config/ruta.lua',
    'shared/examenes.lua',
}

client_scripts {
    '@origen_map/shared/marcar.lua',
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    'client/estado.lua',
    'client/escuela.lua',
    'client/intermitentes.lua',
    'client/teorico.lua',
    'client/practico.lua',
    'client/licencia.lua',
    'client/editor.lua',
    'client/admin.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    -- Las preguntas SOLO en el servidor: con ellas en shared, cualquiera
    -- tendría las respuestas en la caché de su cliente.
    'server/preguntas.lua',
    'server/base.lua',
    'server/datos.lua',
    'server/rutas.lua',
    'server/licencia.lua',
    'server/teorico.lua',
    'server/practico.lua',
    'server/escuela.lua',
    'server/intermitentes.lua',
    'server/staff.lua',
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/assets/*',
}
