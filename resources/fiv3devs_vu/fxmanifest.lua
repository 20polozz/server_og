fx_version 'cerulean'
game 'gta5'
this_is_a_map 'yes'
author 'Fiv3Devs'
description 'Vanilla Unicorn'
version '1.1.7'
lua54 'yes'

files {
	'5d_vu_timecycle_mods.xml',
	'audio/*.dat151.rel'
}

client_scripts {
	'entitysets.lua',
	'dancers.lua',
	'config.lua'
}

escrow_ignore {
  'entitysets.lua',
  'config.lua'
}

dependencies {
    '/gameBuild:2545',               -- requires at least game build 2189
	'fiv3devs_mapdata'
}

data_file 'AUDIO_GAMEDATA' 'audio/fiv3devs_vu_game.dat'
data_file 'AUDIO_DYNAMIXDATA' 'audio/fiv3devs_vu_mix.dat'
data_file 'TIMECYCLEMOD_FILE' '5d_vu_timecycle_mods.xml'
dependency '/assetpacks'