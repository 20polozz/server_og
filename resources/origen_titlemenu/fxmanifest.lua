fx_version "cerulean"

game "gta5"
version '1.1.0.9'

shared_scripts {
    "@ox_lib/init.lua",
    "locales/*.lua",
    "config.lua",
    "init.lua",
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    -- "@qb-apartments/config.lua",
    -- Quitado: qb-apartments no existe en este servidor (va con Qbox, no QBCore)
    -- y el import fallaba con "Failed to load script @qb-apartments/config.lua",
    -- abortando la carga del resto de scripts de cliente del recurso.
    -- El codigo que lo usaba esta muerto: solo corre si Config.Apartment ==
    -- 'qb-apartments', y esa clave no esta definida en config.lua.
    "client/init.lua",
    "custom/client/client.lua",
    "client/main.lua",
    "client/cinematic.lua",
    "client/camara_llegada.lua",
    "client/mugshot.lua",
    "client/peds.lua",
    -- Justo detras de peds.lua, que es de donde usa CARA. Y ANTES de
    -- menu_configurator a proposito: en este servidor, un script de cliente que
    -- falla aborta la carga de los que vienen detras (paso con
    -- @qb-apartments/config.lua), asi que no conviene depender de ellos.
    "client/ajuste_camara.lua",
    -- Detras de peds.lua y de ajuste_camara: usa CAMARAS, HUESO_CABEZA y
    -- PedRetratado.
    "client/retrato.lua",
    "client/spawnselect.lua",
    "client/menu_configurator.lua",
}

server_scripts {
    "server/init.lua",
    "@oxmysql/lib/MySQL.lua",
    -- Antes de server.lua: alli se llama a RetratosDe para meter la cara de
    -- cada personaje en el setup.
    "server/retratos.lua",
    "server/puntos_mapa.lua",
    'custom/server/function.lua',
    "server/server.lua",
    "custom/server/server.lua",
    "custom/server/logs.lua"
}

files {
    "html/**/*.*",
    -- Los encuadres guardados los lee el CLIENTE, y LoadResourceFile solo
    -- alcanza a los ficheros declarados aqui. Sin esta linea el cliente decia
    -- "Sin config/camaras.json" aunque el fichero existiera, y cada reinicio
    -- volvia a los encuadres de fabrica.
    "config/*.json"
}

ui_page "html/index.html"

-- Escrow
lua54 'yes'

escrow_ignore {
    "config.lua",
    "locales/*.lua",
    "custom/**/*.lua",
}

dependency '/assetpacks'