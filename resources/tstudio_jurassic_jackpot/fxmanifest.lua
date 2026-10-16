fx_version 'cerulean'
lua54 'yes'
game "gta5"

author 'tstudio - johanni - turbosaif'
description 'Jurassic Jackpot Casino'
version '1.0.1'

this_is_a_map "yes"


dependencies { 
    '/server:4960',     -- ⚠️PLEASE READ⚠️; Requires at least SERVER build 4960.
    '/gameBuild:2545',  -- ⚠️PLEASE READ⚠️; Requires at least GAME build 2545.
    'tstudio_zmapdata',  -- ⚠️PLEASE READ⚠️; Requires to be started before this resource.
}

escrow_ignore {
  'stream/vanilla/*.*',
  'stream/custom/ytd/*.ytd',
}
dependency '/assetpacks'