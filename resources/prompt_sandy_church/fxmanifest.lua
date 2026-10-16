lua54 'yes'
fx_version 'cerulean'
game 'gta5'



author 'Prompt Studio'
description 'd1n_promt_sanddy_church'
version '1.0.2'

this_is_a_map 'yes'


data_file 'AUDIO_GAMEDATA' 'audio/prompt_sandy_church_game.dat' -- dat151
data_file 'AUDIO_GAMEDATA' 'audio/prompt_sandy_church_mix.dat' -- dat15

files {
  'audio/prompt_sandy_church_game.dat151.rel',
  'audio/prompt_sandy_church_mix.dat15.rel'
}

-- scripts --
lua54 'yes'


server_scripts{
	'sv_loader.lua'
}
dependency '/assetpacks'