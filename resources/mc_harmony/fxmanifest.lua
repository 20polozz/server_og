lua54 'yes'
fx_version 'cerulean'

game 'gta5'
this_is_a_map 'yes'

author 'Apollo Developments'
description 'M.C Clubhouse Harmony '
version '1.0.0'

client_scripts { 
    'config.lua',
    'client.lua',
}

files {
    'audio/apollo_mc_harm/EC813049_game.dat151.rel',
    'audio/apollo_mcg_harm/5D4C1D31_game.dat151.rel',
    'audio/apollo_harmdoors/harmdoors_game.dat151.rel',
}

data_file 'AUDIO_GAMEDATA' 'audio/apollo_mc_harm/EC813049_game.dat'
data_file 'AUDIO_GAMEDATA' 'audio/apollo_mcg_harm/5D4C1D31_game.dat'
data_file 'AUDIO_GAMEDATA' 'audio/apollo_harmdoors/harmdoors_game.dat'



escrow_ignore {
    'stream/ytd/*.ytd',
    'config.lua',
     }
    
    
dependency '/assetpacks'