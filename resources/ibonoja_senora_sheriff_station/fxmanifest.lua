
fx_version 'cerulean'
game 'gta5'
lua54 'yes'
this_is_a_map 'true'

data_file 'DLC_ITYP_REQUEST' 'stream/ibonoja_senora_sheriff_ext.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/ydr/interior/ibonoja_senora_sheriff_interior.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/YMAPS/interior/ibonoja_senora_sheriff_int_props.YTYP'
data_file "SCENARIO_POINTS_OVERRIDE_PSO_FILE" "sp_manifest.ymt"
data_file 'AUDIO_GAMEDATA' 'audio/ibo_senora.dat'
data_file 'AUDIO_GAMEDATA' 'audio/ibo_senora_t.dat'

files {
	'audio/ibo_senora.dat151.rel',
    'audio/ibo_senora_t.dat151.rel',
    'sp_manifest.ymt'
}


escrow_ignore {
	'stream/editable',
    'stream/editable/flags',
  }




dependency '/assetpacks'