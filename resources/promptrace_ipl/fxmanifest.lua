fx_version 'cerulean'
game 'gta5'
lua54 'yes'

this_is_a_map 'yes'

files {
    'stream/*.ytd',    -- Textures
    'stream/*.ydr',    -- Models
    'stream/*.yft',    -- Vehicles
    'stream/*.ybn',    -- Collision
    'stream/*.xml',    -- Meta files
}

data_file 'DLC_ITYP_REQUEST' 'stream/box55_waterrace.ytyp'

escrow_ignore {
    'config.lua'
}

shared_scripts {
    "@ox_lib/init.lua",
    "config.lua"
}   

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

dependencies {
    'ox_lib'
}
dependency '/assetpacks'