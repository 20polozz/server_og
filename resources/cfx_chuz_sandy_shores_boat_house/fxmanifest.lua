fx_version 'bodacious'
game 'gta5'
this_is_a_map 'yes'
author 'Prompt Mods'
version "1.0.1"

escrow_ignore {
    'stream/unlocked/**'
}

-- scripts --
lua54 'yes'


server_scripts{
	'sv_loader.lua'
}
dependency '/assetpacks'