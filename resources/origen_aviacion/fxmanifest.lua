fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'OrigenNetwork'
description 'Escuela de vuelo de Sandy Shores: licencia de piloto'
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
    'shared/examenes.lua',
}

client_scripts {
    '@origen_map/shared/marcar.lua',
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    'client/estado.lua',
    'client/escuela.lua',
    'client/teorico.lua',
    'client/practico.lua',
    'client/licencia.lua',
    'client/editor.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    -- Las preguntas SOLO en el servidor: con ellas en shared, cualquiera
    -- tendría las respuestas en la caché de su cliente.
    'server/preguntas.lua',
    'server/base.lua',
    'server/datos.lua',
    'server/licencia.lua',
    'server/teorico.lua',
    'server/practico.lua',
    'server/escuela.lua',
    'server/staff.lua',
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/assets/*',
}
