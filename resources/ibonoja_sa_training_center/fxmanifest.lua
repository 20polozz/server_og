
fx_version 'cerulean'
game 'gta5'
lua54 'yes'
this_is_a_map 'true'

data_file 'AUDIO_GAMEDATA' 'audio/edf_in_1_game.dat' -- dat151
data_file 'AUDIO_GAMEDATA' 'audio/edf_in_2_game.dat'
data_file 'AUDIO_GAMEDATA' 'audio/h_heli_game.dat'
data_file 'AUDIO_GAMEDATA' 'audio/h_kill_game.dat'

files {
'audio/edf_in_1_game.dat151.rel',
'audio/edf_int_2_game.dat151.rel',
'audio/h_heli_game.dat151.rel',
'audio/h_kill_game.dat151.rel',
'sp_manifest.ymt',
}

data_file 'SCENARIO_POINTS_OVERRIDE_FILE' 'sp_manifest.ymt'



escrow_ignore {
  'stream/editable',
}

dependency '/assetpacks'