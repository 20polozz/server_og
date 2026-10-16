fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'OrigenNetwork'
description 'Bingo español de 90 bolas: salas con bombo, panel y taquilla propios, puestas desde un configurador dentro del juego.'
version '1.0.0'

--[[ ── Qué es esto ────────────────────────────────────────────────────────────

     Una partida de bingo para todo el servidor, automática: cada X minutos
     se sortea, la gente compra cartones en la taquilla de cualquier sala y ve
     en el panel grande lo que va saliendo. Los props (bombo, jaula, panel,
     pantalla de pared, taquilla y las 90 bolas) son propios: la fuente está
     en fuente/ (Blender + Sollumz, ver construir.py).

     Las bolas, los cartones y los premios los decide el servidor. ]]

dependencies {
    'ox_lib',
    'oxmysql',
    'qbx_core',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/carton.lua',
    'shared/modelos.lua',
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    '@origen_map/shared/marcar.lua',
    'client.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua',
}

-- La interfaz se compila desde source-ui/ (npx vite build) a ui/.
-- ui/pantalla.html es la página de las pantallas (la abre un navegador sin ventana).
ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/pantalla.html',
    'ui/assets/*',
}

data_file 'DLC_ITYP_REQUEST' 'stream/origen_bingo.ytyp'
