fx_version 'cerulean'
game 'gta5'
version '1.2.7'

shared_scripts {
    '@ox_lib/init.lua',
    'config/*.lua',
    'utils/*.lua',
    'shared/*.lua'
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    '@origen_map/shared/marcar.lua',

    'custom/framework/client/*.lua',
    'custom/client/*.lua',
    'hooks/client.lua',
    'client/*.lua',

    -- La repeticion de la pestaña Espectar, en este orden: cada fichero usa
    -- lo que deja el anterior.
    'client/repeticion/utils.lua',
    'client/repeticion/recorder.lua',
    'client/repeticion/wire.lua',
    'client/repeticion/actors.lua',
    'client/repeticion/camera.lua',
    'client/repeticion/playback.lua',
    'client/repeticion/red.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config/server/*.lua',
    'hooks/server.lua',
    'custom/framework/server/*.lua',
    -- El panel web: el puente va antes que todo lo que registra callbacks y
    -- eventos, para apuntarlos (ver el propio fichero).
    'server/web/puente.lua',
    'custom/server/*.lua',
    'server/middlewares/*.lua',
    'server/db_init.lua', -- Inicializar BD primero
    'server/*.lua',
    'server/web/sesiones.lua',
    'server/web/nui.lua',
    'server/web/http.lua',
    'server/web/*.js',
    'utils/*.js',
}

files {
    'locales/*.json',
    'ui/dist/**/*',
}

ui_page 'ui/dist/index.html' -- RELEASE
-- ui_page 'http://localhost:5173' -- DEV

-- Escrow

dependencies {
    'screenshot-basic'
}

lua54 'yes'

escrow_ignore {
    "config/*.lua",
    "custom/client/*.lua",
    "custom/framework/**/*.lua",
    "custom/server/*.lua",
}

dependency '/assetpacks'