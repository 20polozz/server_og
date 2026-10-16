fx_version 'cerulean'
game 'gta5'

author 'AlexBanPer'
lua54 'of course'


shared_scripts {
    '@ox_lib/init.lua'
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    '@origen_map/shared/marcar.lua',

    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/s_main.lua',
    'server/s_tournament.lua',
}

ui_page 'ui/index.html'

files {
    'shared/config.lua',
    'sounds/*.mp3',

    -- El bundle de Vite. La fuente esta en `source-ui/`; se compila con
    -- `pnpm build` desde ahi y sale aqui.
    'ui/index.html',
    'ui/assets/*',
}