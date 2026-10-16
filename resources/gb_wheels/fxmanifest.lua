fx_version 'cerulean'
game 'gta5'
author 'Gabz'
description 'Gabz Wheels Pack'	
version '1.0'
lua54 'yes'

data_file 'CARCOLS_FILE' 'carcols.meta'

files {
	'carcols.meta',	
}

client_script 'wheel_names.lua'

escrow_ignore {
  'stream/*.ytd',
  '*.meta'
}
dependency '/assetpacks'