fx_version 'bodacious'
game 'gta5'
this_is_a_map 'yes'
lua54 'yes'

-- map by---:
author 'Prompt Studio'
description 'Sandy Shores Illegal Garage & Gas Station & Car Wash'
scripts_author 'Infames Dev'
version '1.1.4'

-- dat151 (was already commented out here) merged into shared prompt_audio 2026-06-10;
-- zip backup: C:\Scripts\_backups\prompt_audio\illegal_garage_audio_2026-06-10_night_pre-merge.zip
-- data_file 'DLC_ITYP_REQUEST' 'stream/unlocked/illegal_garage/prompt_sandy_illegal_garage.ytyp'

escrow_ignore {
    'stream/unlocked/**',
    'config.lua',
    'open_config.lua',
    'open_functions.lua',
    'client/target_wrapper.lua'
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'open_config.lua'
}

client_scripts {
	'open_functions.lua',
    'client/target_wrapper.lua',
    'client/utils.lua',
    'client/client.lua'
}

server_scripts {
    'server/*.lua',
    'sv_loader.lua'
 }

dependency '/assetpacks'
dependency '/assetpacks'