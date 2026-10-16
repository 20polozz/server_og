fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'origen_crashlog'
description 'Apunta donde estaba cada jugador al caerse, para cazar crasheos por zona'
version '1.0.0'

-- TEMPORAL: esto es una herramienta de diagnostico, no una pieza del servidor.
-- Cuando se cierre el crasheo de Mission Row, quitar el recurso entero.

server_scripts {
    'server/main.lua',
}
