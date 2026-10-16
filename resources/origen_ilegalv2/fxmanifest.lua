fx_version 'cerulean'
game 'gta5'

description 'Origen Ilegal Store V2 - Gang Management System'
author 'Origen Network'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'bridge/**/shared.lua',
    'init.lua',

    'config/*.lua',

    'locales/translations/*.lua',
    'locales/locales.lua',
    'components/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config_sv.lua',
    'bridge/**/server.lua',
    'bridge/**/server/*.lua',
    'server/modules/radio/state.lua',
    'server/modules/radio/validators.lua',
    'server/modules/radio/core.lua',
    'server/modules/radio/callbacks.lua',
    'server/modules/radio/events.lua',
    'server/modules/radio/preferences.lua',
    'server/modules/radio/sin_radio.lua',
    'server/db.lua',
    'server/classes/*.lua',
    'server/functions/*.lua',
    'custom/server/*.lua',
    'server/lab_process_runner.lua',
    'server/*.lua',
    'server/exports.lua',
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    '@origen_map/shared/marcar.lua',

    'bridge/**/client.lua',
    'bridge/**/client/*.lua',
    'custom/client/*.lua',
    'client/functions/*.lua',
    'client/lab_process_runner.lua',
    'client/**/*.lua',
}

ui_page 'ui/index.html'

files {
    'ui/**/*',
    'ui/assets/**/*',
    'ui/*.html',
    'ui/*.js',
    'ui/graffiti_viewer.html',
}

escrow_ignore {
    'config/*.lua',
    'config_sv.lua',
    'locales/**/*.lua',
    'custom/**/*.lua',
}

