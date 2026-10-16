fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'origen_map'
author 'ORIGEN'
description 'El minimapa de Leaflet y el registro de puntos del servidor'
version '0.2.0'

ui_page 'html/index.html'

--- El catalogo de categorias. Compartido porque tambien lo mira el servidor
--- cuando hay que validar lo que llega de un panel de administracion.
shared_scripts {
    'shared/categorias.lua',
}

client_scripts {
    --[[ El vigilante del raton, el primero de todos como en cada recurso con
         interfaz. Hasta ahora aqui no hacia falta --el minimapa nunca cogia el
         foco--, pero el modo posicionar (client/main.lua) si lo coge, y sin el
         vigilante el comando `raton` no lo soltaria ni los demas sabrian que
         este recurso tiene el cursor. Es un fichero de ESTE recurso, asi que va
         sin la @. ]]
    'shared/foco.lua',

    --- El registro va PRIMERO: main.lua lee de el, y los otros recursos le
    --- mandan puntos en cuanto arrancan.
    'client/registro.lua',
    'client/main.lua',

    --- El silencio de la interfaz. Solo se carga
    --- aqui: los demas recursos cargan '@origen_map/shared/tema.lua'.
    'client/tema.lua',

    --[[ Y el PUENTE (marca y silencio), tambien aqui: la pantalla de este
         recurso es el minimapa, y SendNUIMessage solo llega a la pantalla del
         recurso que lo llama. ]]
    'shared/tema.lua',
}

files {
    'html/index.html',
    'html/estilo.css',
    'html/mapa.js',

    --[[ Las teselas y Leaflet de TODOS los mapas del servidor (inventario,
         movil, policia, menu de inicio, admin...). Antes venian de gtamap.xyz y
         unpkg, y a quien no le llegaba esa web le salia el mapa en negro con
         los puntos encima (17/09). Los demas los piden por
         https://cfx-nui-origen_map/html/teselas/<estilo>/{z}/{x}/{y}.jpg y
         .../html/leaflet/<version>/leaflet.js. Por eso tambien tienen que
         estar declarados: sin esto el recurso no los entrega. ]]
    'html/teselas/**/*.jpg',
    'html/leaflet/**/*',

    --[[ El ayudante que cargan los demas recursos con
         '@origen_map/shared/marcar.lua'.

         TIENE QUE ESTAR AQUI. Un fichero que otro recurso va a leer con @ no
         se busca en el disco: se pide a ESTE recurso, y este solo entrega los
         que ha declarado. Sin esta linea el fichero existe, se ve en la
         carpeta, y aun asi el otro recurso arranca sin el —sin un solo aviso—
         y se queda con `OrigenMapa` a nil.

         Es lo mismo que hace qbx_core con 'modules/*.lua' para poder servir
         @qbx_core/modules/playerdata.lua. ]]
    'shared/marcar.lua',

    --[[ El vigilante del foco de la NUI, que cargan con
         '@origen_map/shared/foco.lua' todos los recursos con interfaz. Vive
         aqui y no en origen_hud por lo mismo que marcar.lua: este recurso
         arranca antes que nadie (ver cfg/resources.cfg), y un fichero
         prestado solo se puede cargar si su recurso ya esta arrancado. ]]
    'shared/foco.lua',

    --[[ El puente de la interfaz (marca y silencio), que cargan con
         '@origen_map/shared/tema.lua' todos los recursos con interfaz. Mismo
         motivo que los de arriba para vivir aqui, y misma trampa: sin esta
         linea el fichero existe pero este recurso no lo entrega, y el otro
         arranca sin el sin un solo aviso. ]]
    'shared/tema.lua',
}
