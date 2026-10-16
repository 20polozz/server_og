fx_version 'adamant'

game 'gta5'

description 'Origen LoadingScreen System'

version '1.0.1'

-- Sin `loadscreen`: la pantalla de carga es origen_loadingscreen. Con dos
-- recursos declarandola el juego se queda con una sola, y cual depende de la
-- lista de recursos del servidor: en Nacion ganaba esta pagina, que no tiene
-- nada que ver (solo la musica), y la carga salia en negro.
ui_page 'index.html'

client_script 'client.lua'

files { 'index.html', 'app.js',
       'js/jquery.min.js', 'js/jquery.easings.min.js',
       'media/*.mp3' }