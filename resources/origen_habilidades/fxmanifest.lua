fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'origen_habilidades'
author 'ORIGEN'
description 'Lleva la cuenta de las habilidades del personaje: conduccion, mecanica, hackeo, ganzua, robo y pilotaje.'
version '1.0.0'

shared_script 'config.lua'

client_script 'client/main.lua'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}
