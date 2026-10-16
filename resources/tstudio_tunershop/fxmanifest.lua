fx_version 'cerulean'
lua54 'yes'
game "gta5"
author 'HG-Designs x TStudio'
description 'HG Tuner Shop'
version '1.0.0'

this_is_a_map "yes"

dependencies { 
    '/server:4960',     -- ⚠️PLEASE READ⚠️; Requires at least SERVER build 4960.
    '/gameBuild:2545',  -- ⚠️PLEASE READ⚠️; Requires at least GAME build 2545.
    'tstudio_zmapdata',  -- ⚠️PLEASE READ⚠️; Requires to be started before this resource.
}

files {
    'hg_tunershop_timecycle.xml',
}

data_file 'TIMECYCLEMOD_FILE' 'hg_tunershop_timecycle.xml'

escrow_ignore {
    'stream/ytd/*.ytd',
    'stream/vanilla/*.*',
}
dependency '/assetpacks'