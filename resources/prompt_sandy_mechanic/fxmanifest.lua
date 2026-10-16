fx_version 'bodacious'
game 'gta5'
this_is_a_map 'yes'
lua54 'yes'

-- map by---:
author 'Prompt Studio'
scripts_author 'Infames Dev'
description 'Sandy Shores Mechanic'
version '1.2.4'


data_file 'DLC_ITYP_REQUEST' 'stream/anims/prompt_sandy_compound_anims.ytyp'

files {
	'stream/anims/prompt_sandy_compound_anims.ytyp'
}

escrow_ignore {
    'stream/exterior/unlocked/**',
    'stream/interior/unlocked/**',
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
	'sv_loader.lua',
    'server/*.lua',
    --[['sv_Tokens.lua',
	'sv_MapChainHandler.lua',
	'sv_MapVersionCheck.lua'--]]
}

dependency '/assetpacks'
dependency '/assetpacks'