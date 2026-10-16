fx_version 'adamant'
game 'gta5'
description 'Origen LoadingScreen'
version '1.0.0'

loadscreen_manual_shutdown "yes"

loadscreen 'ui/index.html'

files {
    'ui/*.html', 
    'ui/css/*.css', 
    'ui/js/*.js', 
    'ui/img/*.*', 
    'ui/fonts/*.*', 
    'ui/media/*.*'
}

client_script '@origen_map/shared/tema.lua'
client_script 'client.lua'

-- Le entrega la marca del servidor (origen o nacion) a la pantalla de carga.
server_script 'server.lua'

