fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'origen_livery'
description 'Liveries por matrícula con editor dentro del juego'
version '1.0.0'

-- La interfaz es Vue: la fuente está en source-ui/ y se compila a ui/ con
-- `npm run build`. html/dui.html NO es la interfaz: es la página que la DUI
-- pinta encima de la textura del coche.
ui_page 'ui/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    'client/main.lua',
    'client/editor.lua',
    'client/nui.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/db.lua',
    'server/packs.lua',
    'server/slots.lua',
    'server/storage.lua',
    'server/http.lua',
    'server/main.lua',
    'server/editor.lua',
}

files {
    'ui/index.html',
    'ui/assets/*',
    -- Las plantillas UV de cada modelo, <modelo>.webp. Para añadir una, se
    -- deja en source-ui/public/plantillas y se compila.
    'ui/plantillas/*',
    'html/dui.html',
}
