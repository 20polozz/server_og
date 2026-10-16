fx_version 'bodacious'
game 'gta5'
this_is_a_map 'yes'


data_file 'AUDIO_GAMEDATA' 'audio/prompt_rdealer_game.dat' -- dat151
data_file 'AUDIO_GAMEDATA' 'audio/rdealer_doors_game.dat' -- dat151

files {
  'audio/prompt_rdealer_game.dat151.rel',
  'audio/rdealer_doors_game.dat151.rel'
}

escrow_ignore {
    'stream/unlocked/**'
}
dependency '/assetpacks'