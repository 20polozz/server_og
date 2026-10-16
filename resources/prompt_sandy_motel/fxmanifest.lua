fx_version 'bodacious'
game 'gta5'
this_is_a_map 'yes'
lua54 'yes'

-- map by---:
author 'Prompt Studio'
description 'Sandy Shores Motel'
version '1.1.1'

client_scripts {
    'config.lua',
    'client_entitysets.lua',
    'proximity_loader.lua' 
}

server_scripts {
    'sv_loader.lua',
    -- Room booking. Inert unless prompt_hotel_system is installed.
    'hotel_config.lua',
    'hotel_register.lua'
}

escrow_ignore {
    'stream/unlocked/**',
    'proximity_loader.lua',
    'config.lua',
    'client_entitysets.lua',
    'hotel_config.lua'
}
dependency '/assetpacks'