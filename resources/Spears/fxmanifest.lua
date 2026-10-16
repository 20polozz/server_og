fx_version 'adamant'
version '2.00'

game 'gta5'

files {
    'audioconfig/*.dat151.rel',
    'audioconfig/*.dat54.rel',
    'sfx/**/*.awc',
	'data/**/carcols.meta',
	'data/**/carvariations.meta',
	'data/**/handling.meta',
	'data/**/vehiclelayouts.meta',
	'data/**/vehicles.meta',
	'data/**/weapons.meta',
	'data/**/weaponarchetypes.meta'
}

	data_file 'VEHICLE_LAYOUTS_FILE'	'data/**/vehiclelayouts.meta'
	data_file 'HANDLING_FILE'			'data/**/handling.meta'
	data_file 'VEHICLE_METADATA_FILE'	'data/**/vehicles.meta'
	data_file 'CARCOLS_FILE'			'data/**/carcols.meta'
	data_file 'VEHICLE_VARIATION_FILE'	'data/**/carvariations.meta'
	data_file 'WEAPONINFO_FILE'			'data/**/weapons.meta'
	data_file 'WEAPON_METADATA_FILE'	'data/**/weaponarchetypes.meta'

	escrow_ignore {
  'stream/*.ytd',     -- Ignore all .yft files in that folder

}
dependency '/assetpacks'