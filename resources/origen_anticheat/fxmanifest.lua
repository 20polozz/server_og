fx_version 'cerulean'
game 'gta5'
version '1.0.0'
description 'Origen Anticheat — Sistema de detección y alertas'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/constants.lua',
    'config/config.lua',
}

client_scripts {
    'client/report.lua',
    'client/godmode.lua',
    'client/noclip.lua',
    'client/spectate.lua',
    'client/weapons.lua',
    'client/vehicle.lua',
    'client/explosion.lua',
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/discord.lua',
    'server/violations.lua',
    'server/listablanca.lua',
    'server/checks.lua',
    'server/main.lua',
}

dependencies {
    -- origen_admin NO: reiniciarlo paraba el anticheat y no volvia a arrancar.
    -- Mientras el admin no esta, los controles no castigan (ver checks.lua).
    'oxmysql',
    'ox_lib',
}
