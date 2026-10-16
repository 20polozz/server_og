fx_version "cerulean"

game 'gta5'

version '1.2.0'

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    'client.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/**/*.*',
}

lua54 'yes'
