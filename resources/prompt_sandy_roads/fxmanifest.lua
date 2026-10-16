fx_version 'cerulean'
game 'gta5'
description 'maps'
version '1.0.3'
lua54 'yes'
this_is_a_map 'yes'

escrow_ignore {
    'stream/unlocked/**',
    'ReadMe.txt',
    'nobridge/**',
    'stream/*.ymf',
    'stream/*.ytyp',
    'stream/**/*.ymap',
    'stream/**/*.ymap.xml',
    'stream/**/*.ymf',
    'stream/**/*.ytyp',
    'stream/**/*.ytd',
    'stream/**/*.ybn',
    'stream/**/*.ydd',
    'stream/**/*.ynd',
    'mapdata/**/*.ymap',
    'mapdata/**/*.ybn',
}

server_scripts {
	'sv_loader.lua'
}
dependency '/assetpacks'