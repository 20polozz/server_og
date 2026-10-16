fx_version 'cerulean'
game 'gta5'

description 'Origen Visuals: luces, noche, niebla y tono de imagen del servidor'
version '1.3.0'
lua54 'yes'

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    'config.lua',
    'data/base.lua',
    'data/texturas.lua',
    'client.lua',
    'texturas.lua',
}

-- El panel «Origen Gráficos». Sale de source-ui (npx vite build).
ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/assets/*.*',
}
