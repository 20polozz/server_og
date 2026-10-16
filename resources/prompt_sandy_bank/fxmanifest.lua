lua54 'yes'
fx_version 'cerulean'
game 'gta5'


author 'Prompt Studio | d1n'
description 'Sandy Shores Bank'
version '1.0.2'

this_is_a_map 'yes'

-- audio merged into prompt_audio (shared dat151); local rel removed 2026-06-11
-- (the restored older version re-added it; original zipped in C:\Scripts\_backups\prompt_audio)

server_scripts{
	'sv_loader.lua'
}

escrow_ignore {
    'stream/unlocked/**'
}


--#client_scripts {
--#	'client.lua'
--#}
dependency '/assetpacks'