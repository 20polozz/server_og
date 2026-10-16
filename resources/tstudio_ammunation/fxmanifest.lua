fx_version 'cerulean'
lua54 'yes'
game "gta5"

author 'tstudio'
description 'Ammu Nation'
version '1.0.0'

this_is_a_map "yes"

dependencies { 
    '/server:4960',     -- ⚠️PLEASE READ⚠️; Requires at least SERVER build 4960.
    '/gameBuild:2545',  -- ⚠️PLEASE READ⚠️; Requires at least GAME build 2545.
    'tstudio_zmapdata',  -- ⚠️PLEASE READ⚠️; Requires to be started before this resource.
}

escrow_ignore {
  'stream/ytd/*.ytd',
  'stream/vanilla/*.*',
  'stream/tstudio_location_*/*.*',
  'client/interior.lua',
}
dependency '/assetpacks'