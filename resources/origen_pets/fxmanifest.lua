fx_version 'cerulean'
lua54 'yes'
game 'gta5'

author 'OrigenNetwork'
description 'Mascotas de ORIGEN'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'config_caballos.lua',
    -- El establo de los caballos (rancho O'Neil): client/ y server/establo.lua.
    'config_establo.lua',
    'config_progreso.lua',
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    '@origen_map/shared/marcar.lua',

    -- La tabla de texturas que existen de verdad en el pack de animales, y lo
    -- que la usa. Antes de mascota.lua, que la llama al sacar la mascota.
    'shared/texturas.lua',
    -- Con que esqueleto se mueve cada modelo del pack: decide la animacion de
    -- sentarse. Generado por herramientas/esqueletos.py.
    'shared/esqueletos.lua',
    'client/estado.lua',
    'client/aspecto.lua',
    -- Montar a caballo. Antes de mascota.lua, que le pregunta si va montada.
    'client/caballos.lua',
    'client/mascota.lua',
    -- Acariciar, pelota, correa, rastrear y lo que hace sola.
    'client/vida.lua',
    'client/laser.lua',
    'client/tienda.lua',
    'client/establo.lua',
    'client/nui.lua',
    'client/admin.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    -- admin.lua primero: siembra y carga el catalogo, del que main.lua saca las
    -- razas. El orden importa solo para el arranque; en caliente da igual.
    'server/admin.lua',
    -- Niveles y especialidades. Antes de main.lua, que los pinta en la ficha.
    'server/progreso.lua',
    'server/main.lua',
    'server/caballos.lua',
    -- Vende los caballos del establo; usa CobrarMascota (admin.lua) y DarMascotaA (main.lua).
    'server/establo.lua',
    -- Trae una vez las mascotas de murderface-pets, donde las haya.
    'server/migrar.lua',
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
