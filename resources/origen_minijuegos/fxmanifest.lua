fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Origen Network'
description 'Sistema de Minijuegos - Lockpicking, Hacking, etc'
version '1.0.0'

shared_scripts {
    'config.lua',
    'config_nuevos.lua'
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    'client/*.lua'
}

server_scripts {
    'server/*.lua'
}

ui_page 'html/lockpick/index.html'

files {
    'html/lockpick/*.html',
    'html/lockpick/*.css',
    'html/lockpick/*.js',
    'html/lockpick/fonts/*.otf',
    'html/nuevos/*.css',
    'html/nuevos/*.js'
}

-- Exports para otros recursos
exports {
    'StartLockpick',
    'StartHacking',
    'StartCodeBreaker',
    'StartWirePuzzle',
    'StartMinesweeper',
    'StartTimingCircles',
    'StartVarHack',
    'StartPowerGrid'
}
