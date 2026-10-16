fx_version 'cerulean'
lua54 'yes'
game "gta5"

author 'tstudio - turbosaif'
description 'TStudio resource that overrides gta scenarios'
version '1.0.0'

this_is_a_map "yes"

dependencies { 
    '/server:4960',     -- ⚠️PLEASE READ⚠️; Requires at least SERVER build 4960.
    '/gameBuild:2545'  -- ⚠️PLEASE READ⚠️; Requires at least GAME build 2545.
}

files {
    'scenarios/sp_manifest.ymt'
}

data_file "SCENARIO_POINTS_OVERRIDE_PSO_FILE" "scenarios/sp_manifest.ymt"

client_scripts {
    'client/remove_npc.lua',
    'client/navmesh.lua',
    'client/scenarios.lua',
}

escrow_ignore{
    'scenarios/*.*',
    'stream/*/*.*',
}
dependency '/assetpacks'