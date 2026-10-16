fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'origen_phone'
description 'Origen Phone - telefono completo para ORIGEN Network'
author 'Origen Network'
version '2.0.0'

shared_scripts {
    '@ox_lib/init.lua',

    --[[ La carpeta que puede tocar quien lo instale.

         Va delante de todo: cuando el nucleo pregunte por `Custom`, la tabla
         tiene que existir. Y se queda fuera del cifrado (ver `escrow_ignore`),
         que es justo lo que la hace util. ]]
    'custom/shared/*.lua',

    'config/config.lua',
    'config/integraciones.lua',
    'config/apps.lua',
    'config/widgets.lua',
    'shared/*.lua',
}

--[[ El orden importa.

     Con el comodin `client/modules/*.lua` los ficheros se cargan por orden
     alfabetico, y calls.lua y camera.lua registran acciones con Nui.On nada
     mas cargarse: con la n de nui.lua detras de la c, eso es un error al
     arrancar. Van escritos uno a uno a proposito. ]]
client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/marcar.lua',

    'custom/client/*.lua',
    'client/modules/nui.lua',
    'client/modules/foco.lua',
    'client/modules/framework.lua',
    'client/modules/phone.lua',
    'client/modules/calls.lua',
    'client/modules/fans.lua',
    'client/modules/camera.lua',
    'client/modules/pescabichos.lua',
    'client/modules/upload.lua',
    'client/modules/alarms.lua',
    'client/modules/admin.lua',
    'client/modules/colocar_cargador.lua',
    'client/modules/linterna.lua',
    'client/modules/voz.lua',
    'client/modules/servidor.lua',
    'client/modules/entorno.lua',
    'client/modules/ruta.lua',
    'client/modules/reparto.lua',
    'client/modules/taxi_npc.lua',
    'client/modules/valet.lua',
    'client/modules/tienda.lua',
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'custom/server/*.lua',
    'server/db.lua',
    'server/framework.lua',
    'server/inventory.lua',
    'server/employment.lua',
    'server/registro.lua',
    'server/settings.lua',
    'server/bridges.lua',
    'server/appaccess.lua',
    'server/externas.lua',
    'server/rpc.lua',
    'server/turn.lua',
    'server/phones.lua',
    'server/linterna.lua',
    'server/voz.lua',
    'server/profiles.lua',
    -- Los datos de Pescabichos solo los necesita el servidor: al cliente no le llegan.
    'config/pescabichos.lua',
    'config/pescabichos_combate.lua',
    'config/pescabichos_ataques.lua',
    'config/pescabichos_especies2.lua',
    'config/pescabichos_especies3.lua',
    'config/pescabichos_progreso.lua',
    'server/api/*.lua',
    'server/fans_imagen.js',
    'server/exports.lua',
    'server/migracion.lua',
    'server/seed.lua',
    'server/main.lua',
    -- El armazon primero: las tandas se registran en el al cargarse.
    'server/selftest/harness.lua',
    'server/selftest/core.lua',
    'server/selftest/players.lua',
    'server/selftest/grupo.lua',
    'server/selftest/apps.lua',
    'server/selftest/rides.lua',
    'server/selftest/dating.lua',
    'server/selftest/fans.lua',
    'server/selftest/delivery.lua',
    'server/selftest/market.lua',
    'server/selftest/videocall.lua',
    'server/selftest/lives.lua',
    'server/selftest/webrtc.lua',
    'server/selftest/dinero.lua',
    'server/selftest/moderacion.lua',
    'server/selftest/recovery.lua',
    'server/selftest/tienda.lua',
    'server/selftest/numbers.lua',
    'server/selftest/bridges.lua',
    'server/selftest/appaccess.lua',
    'server/selftest/darkchat.lua',
    'server/selftest/borrar.lua',
    'server/selftest/blackmarket.lua',
    'server/selftest/extras.lua',
    'server/selftest/avisos.lua',
    'server/selftest/security.lua',
}

ui_page 'ui/index.html'
-- ui_page 'http://localhost:5276/' -- desarrollo: descomentar y comentar la de arriba

files {
    'ui/index.html',
    'ui/**/*',
    'locales/*.json',
}

dependencies {
    'ox_lib',
    'oxmysql',
    --- Presta el vigilante del foco y el marcador del mapa (@origen_map/shared).
    'origen_map',
}

--[[ QUE SE QUEDA ABIERTO AL CIFRAR EN KEYMASTER

     Todo lo que no salga en esta lista viaja cifrado. Lo que sale, viaja tal
     cual y el que lo compra puede leerlo y tocarlo.

     La regla para decidir es una: **si un servidor tiene que cambiarlo para
     usar el recurso, va abierto**. Cifrar la configuracion o los idiomas es
     vender algo que no se puede instalar sin abrir un ticket.

       config/     Todo lo que se ajusta: precios, topes, integraciones, los
                   nombres de los exports de cada sistema de fuera. Es el
                   fichero que se toca el primer dia.

       locales/    Los cinco idiomas, y el sexto que quiera hacer cada uno.
                   Un idioma cifrado no se puede corregir ni ampliar.

       sql/        El instalador. Hay que poder leerlo antes de importarlo a la
                   base de datos de un servidor en produccion.

       README.md   La documentacion.

     La logica —client, server, shared— y la interfaz ya compilada van
     cifradas, que es lo que se esta vendiendo. ]]
escrow_ignore {
    'config/*.lua',
    'custom/**/*.lua',
    'locales/*.json',
    'sql/*.sql',
    'README.md',
}
