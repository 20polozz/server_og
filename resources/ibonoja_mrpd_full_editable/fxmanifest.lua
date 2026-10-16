fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'IBONOJA'
description 'MRPD21-22'
version '1.1.0'

this_is_a_map 'yes'

data_file 'DLC_ITYP_REQUEST' 'stream/int_corporate.ytyp'
data_file 'INTERIOR_PROXY_ORDER_FILE' 'interiorproxies.meta'
data_file 'AUDIO_GAMEDATA' 'audio/ibonoja_mrpd.dat' -- dat151

files {
	'interiorproxies.meta',
	'audio/ibonoja_mrpd.dat151.rel',
}

escrow_ignore {
	'stream/editable/exterior_lspd_logos.ytd',  
	'stream/editable/ibonoja_exterior_letras_lspd.ydr', 
	'stream/editable/logos', 
  }





dependency '/assetpacks'