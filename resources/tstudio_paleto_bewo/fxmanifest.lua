fx_version 'cerulean'
lua54 'yes'
game "gta5"

author 'TStudio - Bennys Paleto'
description 'Bennys Motorworks Paleto Bay'
version '1.0.2'

this_is_a_map "yes"

file 'dist/**'
ui_page 'dist/index.html'

client_scripts {
  'config.lua',
  'client/*.lua'
}

escrow_ignore {
  'stream/vanilla/*.*',
  'stream/ytd/*.ytd',
  'config.lua', 
  'client/*.lua'
}

dependency '/assetpacks'