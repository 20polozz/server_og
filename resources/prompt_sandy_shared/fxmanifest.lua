fx_version 'bodacious'
game 'gta5'
this_is_a_map 'yes'
author 'Prompt Mods Studio'
version "2.0.3"

-- YTYP Files --
--[[data_file 'DLC_ITYP_REQUEST' 'stream/newstuff/YellowHouse/sm_cs1_07_build2_int.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/bighouses/rck_senora_apps.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/bighouses/rck_senora_apps_b.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/newstuff/va_house16_interior/va_house16_interior.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/newstuff/va_house16_interior/prop_h16_v1.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/newstuff/va_house15_interior/va_h15_interior.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/newstuff/va_house15_interior/prop_h15_1.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/newstuff/va_house14_interior/prop_va_house14.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/newstuff/va_house14_interior/va_house14_interior.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/newstuff/va_house14_interior/va_h14_gar_door.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/newstuff/va_house13_interior/va_h13_door.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/newstuff/va_house13_interior/prop_va_house13.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/newstuff/va_house13_interior/va_house13_interior_01a.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/newstuff/va_house12_interior/va_house12_interior.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/newstuff/va_house12_interior/prop_h12_01.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/newstuff/va_house11_interior/va_house11_interior.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/newstuff/va_house11_interior/va_entity_sets_def.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/newstuff/va_house11_interior/va_entity_sets_01.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/interiors/house2/house2_unfurni.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/interiors/house5/house5_nofurni.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/interiors/house9/house9_nofurni.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/interiors/house8/house8_nofurni.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/interiors/house7/house7_nofurni.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/interiors/house6/house6_nofurni.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/interiors/house4/house4_nofurni.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/interiors/house3/house3_unfurni.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/interiors/house10/house10_nofurni.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/interiors/lods/prompt_houses1_lods.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/interiors/house9/house9_garage.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/interiors/house8/house8_garage.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/interiors/house1/prompt_unfirn.ytyp'--]]
data_file 'DLC_ITYP_REQUEST' 'stream/locked/interiors/lods/prompt_houses1_lods.ytyp'

escrow_ignore {
    'stream/unlocked/**'
}

-- ═══════════════════════════════════════════════════════════════════════════
-- IPL LOADER SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════
-- Optimized proximity-based IPL loading for all Prompt Sandy maps
-- Manages houses, motel rooms, and custom maps in a single efficient thread
dependency '/assetpacks'