fx_version 'bodacious'
game      'gta5'

description 'Origen Network'
version     '2.0.0'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}
client_scripts { 'client.lua' }
