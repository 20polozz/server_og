fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'OrigenNetwork'
description 'El casino de ORIGEN: mesas, máquinas, fichas y membresía'
version '1.0.0'

--[[ ── Qué es esto ────────────────────────────────────────────────────────────

     Un casino entero, hecho en casa, con los juegos que hay en el casino de
     GTA: tragaperras, ruleta, blackjack, póker de tres cartas, Texas Hold'em,
     las carreras de caballos de Inside Track y la rueda de la suerte.

     Nada de esto está clavado en el interior del casino: TODO se coloca desde
     el panel de administración —una mesa, una máquina, la caja de fichas, el
     empleado de la membresía— y se guarda en la base de datos con sus
     coordenadas. El recurso sirve igual para el casino de Vinewood que para
     una trastienda con tres tragaperras.

     La regla que manda sobre todas: **las cartas, los números y los premios
     los decide el servidor**. El cliente solo pinta. Ver docs/JUEGOS.md.
   ────────────────────────────────────────────────────────────────────────── ]]

dependencies {
    'ox_lib',
    'oxmysql',
    'qbx_core',
}

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/util.lua',
    'shared/baraja.lua',
    'shared/video.lua',
    'shared/catalogo.lua',
    'shared/mapas.lua',
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    '@origen_map/shared/marcar.lua',

    'client/estado.lua',
    'client/maquinas.lua',
    'client/video.lua',
    'client/mesas.lua',
    'client/ruleta.lua',
    'client/rueda.lua',
    'client/puntos.lua',
    'client/asiento.lua',
    'client/juego.lua',
    'client/caja.lua',
    'client/colocar.lua',
    'client/admin.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    -- Los ajustes primero: pisan a shared/config.lua con lo que un admin haya
    -- cambiado desde el panel.
    'server/ajustes.lua',
    'server/datos.lua',
    'server/registro.lua',
    'server/puntos.lua',
    'server/caja.lua',
    'server/juego.lua',
    'server/juegos/tragaperras.lua',
    'server/juegos/ruleta.lua',
    'server/juegos/blackjack.lua',
    'server/juegos/pokertres.lua',
    'server/juegos/holdem.lua',
    'server/juegos/caballos.lua',
    'server/juegos/rueda.lua',
    'server/juegos/video/motores.lua',
    'server/juegos/video.lua',
    'server/main.lua',
    'server/admin.lua',
}

-- La interfaz es Vue + Vite: la fuente está en `source-ui/` y se compila con
-- `npm run build` desde ahí; el resultado sale a `ui/`.
ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/pantalla.html',
    'ui/assets/*',
}
