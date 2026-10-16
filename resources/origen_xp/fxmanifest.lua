fx_version 'cerulean'

game 'gta5'

dependencies {
    'qbx_core',
    'oxmysql',
    'ox_lib',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    '@ox_lib/init.lua',
    'config.lua',
    'discord.lua',
    'server.lua',
    'commands.lua',
}