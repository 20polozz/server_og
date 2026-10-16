fx_version "cerulean"
game "gta5"
lua54 "yes"

author 'MXC'
description 'BLACKMARKET'
version '1.0.3'

this_is_a_map 'yes'

data_file 'TIMECYCLEMOD_FILE' 'mxc_timecycle_list_01.xml'

files {
    'mxc_timecycle_list_01.xml',
}

client_scripts {
    "blackmarket_stands_entityset_mods.lua",
}

escrow_ignore {
    'blackmarket_stands_entityset_mods.lua',
    'stream/[multi-location]/[1-SouthPort]/[gta5files]/*.ydr',
    'stream/[multi-location]/[2-TongvaValley]/[gta5files]/*.ydr',
    'stream/[multi-location]/[3-SanAndreasAvenue]/[gta5files]/*.ydr',
}

dependency '/assetpacks'