fx_version 'cerulean'
game 'gta5'
author 'GOM Modeling'
description 'Lore Friendly Vehicles'
version '1.0'
lua54 'yes'

data_file 'HANDLING_FILE' 'data/**/handling.meta'
data_file 'VEHICLE_METADATA_FILE' 'data/**/vehicles.meta'
data_file 'CARCOLS_FILE' 'data/**/carcols.meta'
data_file 'VEHICLE_VARIATION_FILE' 'data/**/carvariations.meta'
data_file 'VEHICLE_LAYOUTS_FILE' 'data/**/vehiclelayouts.meta'
data_file 'WEAPON_METADATA_FILE' 'vehicleweapons_bison5.meta'
data_file 'WEAPON_METADATA_FILE' 'vehicleweapons_phoenix3.meta'
data_file 'WEAPONINFO_FILE' 'vehicleweapons_bison5.meta'
data_file 'WEAPONINFO_FILE' 'vehicleweapons_phoenix3.meta'
data_file 'WEAPON_METADATA_FILE' 'vehicleweapons_shadow.meta'
data_file 'WEAPON_METADATA_FILE' 'vehicleweapons_roadkill.meta'
data_file 'WEAPON_METADATA_FILE' 'weaponturrettechnical.meta'
data_file 'WEAPON_METADATA_FILE' 'vehicleweapons_junkdog.meta'
data_file 'WEAPONINFO_FILE' 'vehicleweapons_shadow.meta'
data_file 'WEAPONINFO_FILE' 'vehicleweapons_roadkill.meta'
data_file 'WEAPONINFO_FILE' 'weaponturrettechnical.meta'
data_file 'WEAPONINFO_FILE' 'vehicleweapons_junkdog.meta'

files {
  'data/**/*.meta'
}

client_script 'vehicle_names.lua'

escrow_ignore {
  'stream/*.ytd',     -- Ignore all .yft files in that folder
  'stream/**/*.ytd',   -- Ignore all .yft files in any subfolder
  '*.meta',   -- Ignore all .yft files in any subfolder
  '*.lua',   -- Ignore all .yft files in any subfolder
  '*.txt',   -- Ignore all .yft files in any subfolder
  'data/*.meta',   -- Ignore all .yft files in any subfolder
  'data/*.lua',   -- Ignore all .yft files in any subfolder
  'data/*.txt',   -- Ignore all .yft files in any subfolder
  'data/**/*.meta',   -- Ignore all .yft files in any subfolder
  'data/**/*.lua',   -- Ignore all .yft files in any subfolder
  'data/**/*.txt'   -- Ignore all .yft files in any subfolder
}
dependency '/assetpacks'