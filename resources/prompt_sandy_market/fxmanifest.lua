fx_version 'bodacious'
game 'gta5'
this_is_a_map 'yes'
lua54 'yes'

-- map by---:
author 'Prompt Studio'
description 'Sandy Shores Market'
version '1.0.5'

-- Shared files
shared_scripts {
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'sv_loader.lua',
    'server.lua'
}

escrow_ignore {
    'stream/unlocked/**',
    'client.lua',
    'config.lua',
    'server.lua'
}
dependency '/assetpacks'