fx_version 'bodacious'
game 'gta5'
this_is_a_map 'yes'



files {
	'prompt_barber_new.xml'
}

data_file 'TIMECYCLEMOD_FILE' 'prompt_barber_new.xml'

escrow_ignore {
    'stream/ghetto/**',
    'stream/city/**',
    'stream/mirror_park/**',
    'stream/paleto/**',
    'stream/sandy/**',
    'stream/vespucci/**',
    'stream/interior/unlocked/**',
  	'client.lua',
    'config.lua'
}

-- scripts --
lua54 'yes'

shared_script 'config.lua'
client_script 'client.lua'


escrow_ignore {
    'stream/unlocked/**'
}
dependency '/assetpacks'