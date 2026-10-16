fx_version 'cerulean'
lua54 'yes'
game "gta5"
replace_level_meta 'gta5'

author 'TStudio - mandatory mapdata'
description 'TStudio Mapdata - important for TStudio maps'
version '1.2.14'

this_is_a_map 'yes'

ui_page 'src/web/proximity/index.html'

files {
    'tstudio_timecycles.xml',
    'src/web/proximity/**/*',
    -- Elevator display page + skins. The glob covers skins/, so dropping a new
    -- map skin in that folder is all it takes - the page fetches it by name.
    'src/web/display/**/*',
    'elevators/*.lua',
    'patches/*.lua',
    'entitysets/*.lua',
    'iplvariants/*.lua',
    'scenarios/*.lua',
    'scenarios/sp_manifest.ymt',
    'gta5.meta',
    'doortuning.ymt',
    'heightmap.dat',
    'audio/tstudiodoorsounds_game.dat151.rel'
}

data_file 'TIMECYCLEMOD_FILE' 'tstudio_timecycles.xml'
data_file 'AUDIO_GAMEDATA' 'audio/tstudiodoorsounds_game.dat'
data_file 'SCENARIO_POINTS_OVERRIDE_PSO_FILE' 'scenarios/sp_manifest.ymt'

shared_scripts {
    'config.lua',
    'locales/*.lua',
    'scenarios/npc_removal.lua',
    'scenarios/navmesh.lua',
    'scenarios/areas.lua',
    'utils/utils.lua',
    'utils/locale.lua',
    'utils/misc.lua',
    'utils/zone_utils.lua',
}

client_scripts {
    'src/proximity_menu.lua',
    'client/interaction.lua',
    'client/Elevator.lua',
    'client/CarElevator.lua',
    'client/elevator_loader.lua',
    'client/elevator_display.lua',
    'client/entitysets_file_loader.lua',
    'client/activate_ipl.lua',
    'client/entitysets_loader.lua',
    'client/ipl_blocker.lua',
    'client/iplvariants_file_loader.lua',
    'client/iplvariants_loader.lua',
    'client/privacy_glass.lua',
    'client/smart_switch.lua',
    'client/dry_volume.lua',
    'client/remove_npc.lua',
    'client/navmesh.lua',
    'client/scenarios.lua',
}

server_scripts {
    'server/patch_loader.lua',
    'server/resource_monitor.lua',
    'server/blind_sync.lua',
    'server/privacy_glass.lua',
    'server/menu_settings.lua',
}

dependencies {
    '/server:4960',     -- ⚠️PLEASE READ⚠️; Requires at least SERVER build 4960.
    '/gameBuild:2545',  -- ⚠️PLEASE READ⚠️; Requires at least GAME build 2545.
}

escrow_ignore {
    'stream/*/*.*',
    'config.lua',
    'locales/*.lua',
    'patches/*.lua',
    'elevators/*.lua',
    'entitysets/*.lua',
    'iplvariants/*.lua',
    'scenarios/*.*',
    'gta5.meta',
    'doortuning.ymt',
    'heightmap.dat',
    'audio/*.*'
}
dependency '/assetpacks'