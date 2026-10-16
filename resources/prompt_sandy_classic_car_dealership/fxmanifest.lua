fx_version 'bodacious'
game 'gta5'
this_is_a_map 'yes'
author 'Prompt Studio'
version "1.0.1"

escrow_ignore {
    'stream/unlocked/**',
  	'client.lua'
}

-- scripts --
lua54 'yes'

client_script 'client.lua'

server_scripts{
	'sv_loader.lua'
}
dependency '/assetpacks'