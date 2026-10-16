author 'Origen Network'
description 'Mechanic System - vehicle health state owner'
version '1.0.0'

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/init.lua',
    'config/components.lua',
    'config/services.lua',
    'config/main.lua',
    'config/degradation.lua',
    'config/malfunctions.lua',
    'config/items.lua',
    'config/repair.lua',
    'config/diagnostic.lua',
    'config/workorders.lua',
    'config/body.lua',
    'config/stations.lua',
    'shared/utils.lua',
    'custom/shared/*.lua'
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    '@origen_map/shared/marcar.lua',
    'client/riel.lua',
    'client/main.lua',
    'client/mileage.lua',
    'client/degradation.lua',
    'client/malfunctions.lua',
    'client/minijuego.lua',
    'client/repair.lua',
    'client/diagnostic.lua',
    'client/workorders.lua',
    'client/body.lua',
    'client/stations.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/utils.lua',
    'server/database.lua',
    'server/state.lua',
    'server/degradation.lua',
    'server/main.lua',
    'server/exports.lua',
    'server/admin.lua',
    'server/repair.lua',
    'server/diagnostic.lua',
    'server/workorders.lua',
    'server/body.lua',
    'server/stations.lua',
    'server/precios_admin.lua'
}

files {
    'ui/index.html',
    'ui/assets/*.js',
    'ui/assets/*.css',
    'ui/assets/*.wav'
}

ui_page 'ui/index.html'
