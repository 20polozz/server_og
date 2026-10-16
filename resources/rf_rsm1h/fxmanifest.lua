fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rf_rsm1h'
author 'racingfreddie'
description 'Riverside Estate Home Control'
version '1.0.2'

ui_page 'html/index.html'

shared_scripts {
    'config.lua',
    'data/settings.lua',
    'data/property.lua',
    'shared/lib.lua',
    'lifts/config.lua',
    'lifts/defaults.lua',
    'lifts/elevators.lua',
    'lifts/path.lua',
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    'client/origen_aviso.lua',
    'client/origen_foco.lua',
    'client/blinds.lua',
    'client/doors.lua',
    'client/mover.lua',
    'client/wave.lua',
    'client/radio.lua',
    'client/screens.lua',
    'client/cameras.lua',
    'client/target.lua',
    'client/handheld.lua',
    'client/doorkey.lua',
    'client/sfx.lua',
    'client/motion.lua',
    'lifts/client.lua',
    'client/main.lua',
}

server_scripts {
    'server/locks.lua',
    'server/main.lua',
    'lifts/server.lua',
}

files {
    'html/index.html',
    'html/es.js',
    'html/origen.css',
    'html/origen.js',
    'html/origen-tokens.css',
    'html/origen-ascensor.css',
    'html/origen-pegatina.css',
    'html/fonts/*',
    'html/style.css',
    'html/app.js',
    'html/travel.js',
    'html/screen.html',
    'html/screen.js',
    'html/logo.png',
    'html/audio/*',
    'html/phone.html',
    'html/phone-runtime.js',
    'html/phone-design.js',
    'html/phone-bridge.js',
    'html/lift.html',
    'html/lift/*',
    'html/cam.html',
    'html/audio/ui/*',
}

data_file 'DLC_ITYP_REQUEST' 'stream/rf_phone_basetype.ytyp'

escrow_ignore {
    'config.lua',
    'server/locks.lua',
}

dependency '/assetpacks'