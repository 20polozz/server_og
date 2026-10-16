fx_version 'cerulean'
game 'gta5'

author 'OrigenNetwork'
description 'Sistema de clasificación de vehículos por rendimiento (PI)'
version '1.0.0'

shared_scripts {
    'shared/config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

exports {
    'GetVehicleClass',
    'GetVehiclePI',
    'GetVehicleStats'
}
