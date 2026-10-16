fx_version 'cerulean'
game 'gta5'
author 'OrigenStore'

shared_scripts {
	'@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_script {
	'@oxmysql/lib/MySQL.lua',
	'server.lua',
	'cdn.js',
	'server.js',
}

files {
    'creationtime.xml'
}

data_file 'TIMECYCLEMOD_FILE' 'creationtime.xml'

dependencies {
	'ox_lib',
    'yarn'
}

escrow_ignore {
	'cdn.js',
    'config.lua',
}