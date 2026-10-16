fx_version 'bodacious'
game "gta5"
version '1.0.1'
replace_level_meta 'gta5'

files {
	'gta5.meta',
	'prompt_doortuning.ymt'
	--'water.xml'
}

--data_file 'HANDLING_FILE' 'water.xml'

escrow_ignore {
  'stream/*.ymt'
}
dependency '/assetpacks'
dependency '/assetpacks'