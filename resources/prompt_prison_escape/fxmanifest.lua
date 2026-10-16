fx_version "cerulean"
use_fxv2_oal "yes"
lua54 'yes'
game "gta5"

author "Adaz"
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    'client/utils.lua',
    'client/main.lua',
    'client/events.lua'
}

server_scripts {
    'server/**/*',
}

escrow_ignore {
    'server/**',
    'locales/**',
    'config/**',
    'client/**',
    'web/**'
}

dependencies {
    'ox_lib'
}

files {
    'locales/*.json',
    'config/config_c.lua',
    'stream/**/*',
    'client/minigame/camera_manager.lua',
    'client/minigame/animation_controller.lua',
    'client/minigame/screw_game.lua',
    'client/editable/interaction.lua',
    'web/index.html'
}

ui_page 'web/index.html'
dependency '/assetpacks'