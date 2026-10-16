fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Origen Network'
description 'Sistema de Carreras Callejeras - Origen Racing'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'config_progresion.lua'
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    '@origen_map/shared/marcar.lua',

    'client/proximity.lua',
    'client/decoracion.lua',
    'client/main.lua',
    'client/admin.lua',
    'client/modos.lua',
    'client/ambiente.lua',
    'client/sesiones.lua',
    'client/racing.lua',
    'client/amueblar.lua',
    'client/hud.lua',
    'client/nui_callbacks.lua',
    'client/crews.lua',
    'client/territories.lua',
    'client/streaming.lua',
    'client/dealership.lua',
    -- La base de la crew es su casa de origen_housing (el garaje por niveles
    -- de client/garage.lua se quitó el 14/10; está en el git).
    'client/base.lua',
    'client/temporada.lua',
    'client/ranking.lua',
    'client/policia.lua',
    'client/contrarreloj.lua',
    'client/favoritos.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/hora.lua',
    -- Registro de cambios de admin (racing_admin_log, 16/10)
    'server/registro_admin.lua',
    -- Libro del OGN: cuánto se crea y se destruye cada día (16/10)
    'server/economia.lua',
    'server/main.lua',
    'server/admin.lua',
    -- server/racing.lua era el sistema de carreras ANTERIOR al hub: nadie lo
    -- usaba desde la interfaz, pero sus callbacks seguian abiertos y creaban
    -- carreras sin cobrar. Retirado el 18/09/2026 (esta en el git).
    'server/records.lua',
    'server/valoraciones.lua',
    'server/crews.lua',
    -- El territorio de cada crew (solo para su casa en origen_housing)
    'server/crew_territorio.lua',
    'server/territories.lua',
    'server/vehicle_classes.lua',
    'server/bets.lua',
    -- La base de la crew: su casa de origen_housing y lo que queda del almacén
    -- viejo (server/garage.lua se quitó el 14/10; está en el git).
    'server/base.lua',
    'server/modos.lua',
    -- La sala de una carrera: elegir coche y chat (15/10)
    'server/sala.lua',
    -- «En directo» dentro del hub: torre de tiempos y mapa (15/10)
    'server/directo.lua',
    'server/ambiente.lua',
    'server/sesiones.lua',
    'server/progresion.lua',
    'server/respeto.lua',
    'server/crew_nivel.lua',
    'server/guerras.lua',
    'server/logros.lua',
    -- Ajustes del juego editables desde el admin (racing_ajustes, 15/10)
    'server/ajustes.lua',
    -- Soporte desde el admin: pilotos, carreras, territorios, guerras y crews (16/10)
    'server/admin_soporte.lua',
    -- Ranking semanal de crews y «crew de la semana» (14/10)
    'server/ranking.lua',
    'server/policia.lua',
    'server/contrarreloj.lua'
}

ui_page 'ui/index.html'
--ui_page 'http://localhost:5173/'

files {
    'ui/**/*',
    'ui/index.html',
    'ui/assets/**/*'
}

dependencies {
    'ox_lib',
    'oxmysql'
}

-- Opcional pero recomendado para sistema de permisos
-- 'origen_admin'
