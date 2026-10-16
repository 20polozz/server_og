fx_version 'cerulean'
games { 'gta5' }
lua54 'yes'

author 'KuzQuality | Kuzkay'
description 'Emergency Vehicles Creator by KuzQuality'
version '1.7.1'

data_file 'DLC_ITYP_REQUEST' 'stream/kq_emergency.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/kq_emergency_decals.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/kq_emergency_decals2.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/kq_emergency_decals_custom.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/kq_emergency_callsigns.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/kq_police_workshop.ytyp'

ui_page 'nui/dist/nui.html'

shared_scripts {
    'config.lua',
    'settings.lua',

    'shared/cache.lua',
    'shared/locale.lua',
    'shared/utils.lua',
    'shared/shared.lua',
    'shared/hasher.lua',

    'extras/**.lua',

    'shared/classes/playerVehicle.lua',
}

client_scripts {
    '@origen_map/shared/foco.lua',
    -- La marca (origen / nacion): contesta a la pagina `origen:marca:dame`.
    -- De ella cuelga el estilo pegatina del final de nui/dist/app.css.
    '@origen_map/shared/tema.lua',
    -- Las ayudas de teclas del gizmo, con las del servidor (origen_hud) en vez
    -- de los botones de GTA. Tiene que ir ANTES que los ficheros cifrados.
    'client/editable/ayudas.lua',
    'client/utils.lua',
    'client/editable/debug.lua',
    'client/editable/editable.lua',

    'client/gizmo/kqGizmo.lua',

    'client/nui.lua',

    'client/functions.lua',

    'client/editor/editor.lua',
    'client/editor/spawner.lua',

    'client/classes/playerVehicle.lua',

    'client/siren/placement.lua',
    'client/siren/spawning.lua',
    'client/soundControl.lua',
    'client/lightControl.lua',

    'client/vehicleClone.lua',

    'client/client.lua',
    'client/admin.lua',
    'client/apply.lua',

    'client/customDecals.lua',

    'client/traffic.lua',

    'client/editable/applicator.lua',
}

server_scripts {
    'server/editable/debug.lua',
    'server/editable/init.lua',
    'server/editable/editable.lua',
    'server/editable/sql.lua',
    'server/server.lua',
    'server/callbacks.lua',

    'server/beacon.lua',

    'server/manager.lua',

    'server/classes/playerVehicle.lua',
}

files {
    'locales/*.json',

    'nui/dist/nui.html',
    'nui/dist/app.js',
    'nui/dist/app.css',
    'nui/dist/assets/*.*',

    'client/admin.lua',
    'client/editor/editor.lua',
    'shared/classes/playerVehicle.lua',
    'shared/utils.lua',
    'custom_decals/*.png',
}

escrow_ignore {
    'config.lua',
    'settings.lua',

    'client/editable/**.*',
    'extras/**.lua',

    'server/editable/**.*',
    'locales/*.json',

    'stream/kq_police_stop_sign.ydr',
    'stream/[other]/kq_police_stop_sign.ydr',
    'stream/kq_emergency_decals_custom.ytyp',
    'stream/[custom_decals]/kq_emergency_decals_custom.ytyp',
    'stream/kq_emergency_decals.ytd',
}

dependency '/assetpacks'