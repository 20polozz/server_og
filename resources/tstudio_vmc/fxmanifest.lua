fx_version 'cerulean'
lua54 'yes'
game "gta5"

author 'tstudio - TurboSaif'
description 'Vespucci Medical Center'
version '1.0.2'

this_is_a_map "yes"

dependencies {
    'tstudio_zmapdata',  -- ⚠️PLEASE READ⚠️; Requires to be started before this resource (elevators load from zmapdata).
}

-- data_file "DLC_ITYP_REQUEST" "stream/custom/ytyp/*.ytyp"

escrow_ignore {
    'stream/vanilla/*.*',
    'stream/custom/ytd/*.ytd',
    'stream/custom/yft/*^^.yft',
}

dependency '/assetpacks'