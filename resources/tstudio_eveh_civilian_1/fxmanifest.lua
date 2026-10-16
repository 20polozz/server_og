fx_version "cerulean"
game "gta5"

lua54 "yes"

author "TStudio - https://discord.gg/tstudio"
description "Civilian Pack"
version '1.0.21'

-- Audio (combined; backported)
data_file "AUDIO_SYNTHDATA" "audio/tstudioeveh_combined_amp.dat10"
data_file "AUDIO_SOUNDDATA" "audio/tstudioeveh_combined_sounds.dat54"
data_file "AUDIO_GAMEDATA" "audio/tstudioeveh_combined_game.dat151"
data_file "AUDIO_WAVEPACK" "sfx/dlc_tsteveh"

files {
    "data/**/*.meta",
    "audio/**/*.dat151.rel",
    "audio/**/*.dat54.rel",
    "audio/**/*.dat10.rel",
    "sfx/**/*.awc",
}

data_file "HANDLING_FILE" "data/**/handling*.meta"
data_file "VEHICLE_METADATA_FILE" "data/**/vehicles*.meta"
data_file "CARCOLS_FILE" "data/**/carcols*.meta"
data_file "VEHICLE_VARIATION_FILE" "data/**/carvariations*.meta"
data_file "VEHICLE_LAYOUTS_FILE" "data/**/vehiclelayouts*.meta"

client_scripts {
    "vehicle_names.lua",
}

escrow_ignore {
    "data/**/*.meta",
    "vehicle_names.lua",
    "stream/**/*.ytd",
    "stream/**/*+hi.ytd",
    "stream/**/liveries/*.yft",
    "audio/**/*.rel",
    "sfx/**/*.awc",
}

dependency '/assetpacks'