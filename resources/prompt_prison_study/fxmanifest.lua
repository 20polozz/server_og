fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'Prompt Studio | Igro45'
description 'Study in prison Sandy Shores 2025'
version '1.0.0'

this_is_a_map 'yes'

-- Gym scripts for animations and entity set management
shared_script '@ox_lib/init.lua'
client_script 'client.lua'
server_script 'server.lua'
file 'config.lua'

escrow_ignore {
  'stream/unlocked/**',
  'client.lua',
  'server.lua',
  'config.lua'
}


data_file 'DLC_ITYP_REQUEST' 'stream/i45pt_prison_study_int.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/[gym_props]/i45pt_prison_study_gym_props.ytyp'

dependency '/assetpacks'