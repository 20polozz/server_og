fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'OrigenNetwork'
description 'Gruas de coches: gancho y plataforma'
version '1.0.0'

dependencies {
    'ox_lib',
    'qbx_core',
}

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
    'shared/config.lua',
    'shared/util.lua',
}

client_scripts {
    'client/plataforma.lua',
    'client/gancho.lua',
    'client/estado.lua',
    'client/interaccion.lua',
    'client/ajuste.lua',
    'client/diag.lua',
}

server_scripts {
    'server/main.lua',
}
