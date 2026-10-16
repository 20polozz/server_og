fx_version "bodacious"
game 'gta5'
this_is_a_map 'yes'
lua54 'yes'

shared_script 'config.lua'

client_scripts {
    'notifications.lua',
    'client.lua'
}

server_script 'server.lua'

escrow_ignore {
    'config.lua',
    'notifications.lua'
}

author 'JustGameEnjoy x Origen Store'

dependency '/assetpacks'
dependency '/assetpacks'