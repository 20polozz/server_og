fx_version 'cerulean'
game 'gta5'

name 'qbx_smallresources'
description 'Collection of small scripts'
repository 'https://github.com/Qbox-project/qbx_smallresources'
version '0.2.0'

ox_lib 'locale'

ui_page 'ui/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua'
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    '@qbx_core/modules/playerdata.lua',
    '**/client.lua'
}

server_script '**/server.lua'

files {
    'locales/*.json',
    '**/config.json',
    '**/config.lua',
    '**/ui/index.html',
    -- El juego de piezas de la tablet, que index.html carga antes que nada.
    '**/ui/ogn.css'
}

dependencies {
    'ox_lib',
    'qbx_core'
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'

exports {
    'openManagement'
}
