fx_version 'cerulean'
lua54 'yes'
game 'gta5'

author 'OrigenNetwork'
description 'Origen Games: minijuegos con salas, apuestas y ranking'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    -- La general la primera: las de cada juego se enganchan a Config.Juegos.
    'config/general.lua',
    'config/escondite.lua',
    'config/patata.lua',
    'config/colina.lua',
    'config/derbi.lua',
    'config/impostor.lua',
    'config/paintball.lua',
    'config/dardos.lua',
    'config/karts.lua',
    'config/karts_circuitos.lua',
    'shared/util.lua',
    'shared/escondite_props.lua',
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    '@origen_map/shared/marcar.lua',

    'client/core/nui.lua',
    'client/core/punto.lua',
    'client/core/menu.lua',
    'client/core/espectador.lua',
    'client/core/partida.lua',

    'client/juegos/escondite_prop.lua',
    'client/juegos/escondite.lua',
    'client/juegos/patata.lua',
    'client/juegos/colina.lua',
    'client/juegos/derbi.lua',
    'client/juegos/impostor.lua',
    'client/juegos/paintball.lua',
    'client/juegos/dardos.lua',
    'client/juegos/karts.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    -- El núcleo primero y en este orden: datos monta las tablas y carga las
    -- zonas de las que tiran las salas y la partida.
    'server/core/datos.lua',
    'server/core/dinero.lua',
    'server/core/salas.lua',
    'server/core/partida.lua',

    'server/juegos/escondite.lua',
    'server/juegos/patata.lua',
    'server/juegos/colina.lua',
    'server/juegos/derbi.lua',
    'server/juegos/impostor.lua',
    'server/juegos/paintball.lua',
    'server/juegos/dardos.lua',
    'server/juegos/karts.lua',
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/assets/*',
}

dependencies {
    'ox_lib',
    'oxmysql',
}
