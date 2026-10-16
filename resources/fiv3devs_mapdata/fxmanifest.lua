fx_version 'cerulean'
game 'gta5'
author 'Fiv3Devs'
version '1.0.4'

replace_level_meta 'gta5'

client_scripts {
	'client.lua'
}

files {
	'sp_manifest.ymt',
	'gta5.meta',
    'doortuning.ymt',
	'water.xml'
}

data_file 'SCENARIO_POINTS_OVERRIDE_PSO_FILE' 'sp_manifest.ymt'
dependency '/assetpacks'