fx_version "cerulean"
author 'Origen Network'
lua54 'yes'
game "gta5"

client_scripts {
    -- '@ox_lib/init.lua',
    'client/npc_hostage.lua',
    'client/player_hostage.lua'
}

shared_scripts {
    'cfg.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua',
    'server/player_hostage.lua'
}

escrow_ignore {
    'cfg.lua',
}

dependency '/assetpacks'