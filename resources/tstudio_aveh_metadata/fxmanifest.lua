fx_version "cerulean"
game "gta5"
lua54 "yes"


author "TStudio - https://discord.gg/tstudio"
description "Police, Government & EMS Pack Metadata"
version '1.0.6'


files {
    "data/**/*.meta",
}

-- Meta'
data_file "HANDLING_FILE" "data/**/handling*.meta"
data_file "VEHICLE_LAYOUTS_FILE" "data/**/vehiclelayouts*.meta"
data_file "VEHICLE_METADATA_FILE" "data/**/vehicles*.meta"
data_file "CARCOLS_FILE" "data/**/carcols*.meta"
data_file "VEHICLE_VARIATION_FILE" "data/**/carvariations*.meta"

escrow_ignore {
    "data/**/*.meta",
    "vehicle_names.lua",
    "stream/*.ytd",
}

dependency '/assetpacks'