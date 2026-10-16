fx_version 'cerulean'
lua54 'yes'
game "gta5"
replace_level_meta 'gta5'

author 'TStudio'
description 'Overrides GTA Vanilla doortuning to adapt with TStudio MLOs'
version '1.0.0'

dependencies { 
    '/gameBuild:2545',  -- ⚠️PLEASE READ⚠️; Requires at least GAME build 2545.
    -- 'tstudio_zmapdata',  -- ⚠️PLEASE READ⚠️; Requires to be started before this resource.
}

data_file 'AUDIO_GAMEDATA' 'audio/tstudio_door_game.dat'

files {
  'gta5.meta',
  'doortuning.ymt',
  'heightmap.dat',
  'audio/tstudio_door_game.dat151.rel'
}

escrow_ignore {
  'gta5.meta',
  'doortuning.ymt',
  'heightmap.dat',
  'audio/*.*'
}
dependency '/assetpacks'