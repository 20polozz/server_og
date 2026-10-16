fx_version 'cerulean'
game 'gta5'

description 'Origen Notify'
version '1.0.0'
lua54 'yes'

--- Escritos uno a uno y en este orden: el catalogo de remitentes antes que
--- quien lo usa. Con el glob cargaba por orden alfabetico y `main` iba antes.
client_scripts {
    --- El puente de la interfaz (marca y silencio), identico en todos los
    --- recursos con interfaz.
    '@origen_map/shared/tema.lua',
    'client/remitentes.lua',
    'client/main.lua',
    'client/drawtext.lua',
}

files {
    'ui/index.html',
    'ui/assets/*.*',
}

ui_page {
    'ui/index.html'
    -- 'http://localhost:5173/'
}