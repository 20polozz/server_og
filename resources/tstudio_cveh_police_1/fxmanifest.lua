fx_version "cerulean"
game "gta5"

lua54 "yes"

author "TStudio - https://discord.gg/tstudio"
description "Police & Government Pack"
version '1.0.30'

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

-- Vehicle layouts (base-game-compatible at sv_enforceGameBuild 2545)
data_file 'VEHICLE_LAYOUTS_FILE' 'data/[tstudio_polapc]/vehiclelayouts.meta'
data_file 'VEHICLE_LAYOUTS_FILE' 'data/[tstudio_polballer8]/vehiclelayouts.meta'
data_file 'VEHICLE_LAYOUTS_FILE' 'data/[tstudio_polbanshee3]/vehiclelayouts.meta'
data_file 'VEHICLE_LAYOUTS_FILE' 'data/[tstudio_polbarrage]/vehiclelayouts.meta'
data_file 'VEHICLE_LAYOUTS_FILE' 'data/[tstudio_polbati]/vehiclelayouts.meta'
data_file 'VEHICLE_LAYOUTS_FILE' 'data/[tstudio_polbike]/vehiclelayouts.meta'
data_file 'VEHICLE_LAYOUTS_FILE' 'data/[tstudio_polbuffalo4]/vehiclelayouts.meta'
data_file 'VEHICLE_LAYOUTS_FILE' 'data/[tstudio_polbuffalo5]/vehiclelayouts.meta'
data_file 'VEHICLE_LAYOUTS_FILE' 'data/[tstudio_polburrito]/vehiclelayouts.meta'
data_file 'VEHICLE_LAYOUTS_FILE' 'data/[tstudio_polcaracara2]/vehiclelayouts.meta'
data_file 'VEHICLE_LAYOUTS_FILE' 'data/[tstudio_polcargobob5]/vehiclelayouts.meta'
data_file 'VEHICLE_LAYOUTS_FILE' 'data/[tstudio_polcastigator]/vehiclelayouts.meta'
data_file 'VEHICLE_LAYOUTS_FILE' 'data/[tstudio_polcavalcade3]/vehiclelayouts.meta'
data_file 'VEHICLE_LAYOUTS_FILE' 'data/[tstudio_polcheetah2]/vehiclelayouts.meta'
data_file 'VEHICLE_LAYOUTS_FILE' 'data/[tstudio_polcomet6]/vehiclelayouts.meta'
data_file 'VEHICLE_LAYOUTS_FILE' 'data/[tstudio_polcoquette4]/vehiclelayouts.meta'
data_file 'VEHICLE_LAYOUTS_FILE' 'data/[tstudio_polcypher]/vehiclelayouts.meta'
data_file 'VEHICLE_LAYOUTS_FILE' 'data/[tstudio_poldeity]/vehiclelayouts.meta'
data_file 'VEHICLE_LAYOUTS_FILE' 'data/[tstudio_poldominator9]/vehiclelayouts.meta'
data_file 'VEHICLE_LAYOUTS_FILE' 'data/[tstudio_poll352]/vehiclelayouts.meta'
data_file 'VEHICLE_LAYOUTS_FILE' 'data/[tstudio_polmenacer]/vehiclelayouts.meta'
data_file 'VEHICLE_LAYOUTS_FILE' 'data/[tstudio_polsentinel5]/vehiclelayouts.meta'
data_file 'VEHICLE_LAYOUTS_FILE' 'data/[tstudio_polterminus]/vehiclelayouts.meta'

-- Audio: SINGLE combined files (matches proven mpsum2 pack; avoids the
-- RAGE audio-metadata file limit that silenced per-car files).
data_file "AUDIO_SYNTHDATA" "audio/tstudiopol_combined_amp.dat10"
data_file "AUDIO_SOUNDDATA" "audio/tstudiopol_combined_sounds.dat54"
data_file "AUDIO_GAMEDATA"  "audio/tstudiopol_combined_game.dat151"
data_file "AUDIO_WAVEPACK"  "sfx/dlc_tstpol"

client_scripts {
    "vehicle_names.lua",
}

escrow_ignore {
    "data/**/*.meta",
    "vehicle_names.lua",
    "audio/**/*.rel",
    "sfx/**/*.awc",
    "stream/**/*.ytd",
    "stream/**/*+hi.ytd",
    "stream/**/liveries/*.yft",
}

dependencies {
    'tstudio_aveh_metadata',
}
dependency '/assetpacks'