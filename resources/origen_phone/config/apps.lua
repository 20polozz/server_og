--[[ Catalogo de aplicaciones.

     Esta lista es la fuente de verdad del servidor: que apps existen, cuales
     vienen instaladas y donde se colocan por defecto. La UI trae sus propios
     iconos y componentes, pero es esta tabla la que decide si una app se puede
     abrir. Asi no basta con tocar el cliente para colarse en una app.

     slot:  posicion en la rejilla de la pantalla de inicio (1..24 por pagina).
     dock:  si va en la barra de abajo, en vez de en la rejilla.
     fija:  no se puede desinstalar desde la tienda.

     LO QUE NO SE DESINSTALA

     El telefono, los mensajes y los ajustes: sin ellos el aparato deja de ser
     un telefono y, sobre todo, deja de haber forma de volver atras. Un jugador
     que desinstala Ajustes no puede volver a instalarlo desde Ajustes.

     La tienda y los widgets tambien, por lo mismo: son la puerta de vuelta.
]]

Apps = {
    -- Barra inferior
    { id = 'phone',    label = 'Telefono', dock = 1, default = true, fija = true },
    { id = 'messages', label = 'Mensajes', dock = 2, default = true, fija = true },
    { id = 'ogn',      label = 'OGN',      dock = 3, default = true },
    { id = 'camera',   label = 'Camara',   dock = 4, default = true },

    -- Rejilla
    --[[ La tienda y los widgets: la puerta de vuelta.

         Van fijas porque son de donde se sacan las demas. Una tienda que se
         puede desinstalar deja al jugador sin forma de recuperar nada. ]]
    { id = 'store',    label = 'Tienda',     slot = 1, default = true, fija = true },
    { id = 'widgets',  label = 'Widgets',    slot = 2, default = true, fija = true },

    { id = 'gallery',  label = 'Galeria',    slot = 3, default = true },
    { id = 'settings', label = 'Ajustes',    slot = 4, default = true, fija = true },
    { id = 'notes',    label = 'Notas',      slot = 5, default = true },
    { id = 'calendar', label = 'Calendario', slot = 6, default = true },
    { id = 'map',      label = 'Mapa',       slot = 7, default = true },
    { id = 'weather',  label = 'Tiempo',     slot = 8, default = true },
    { id = 'music',    label = 'Musica',     slot = 9, default = true },
    { id = 'news',     label = 'Noticias',   slot = 10, default = true },
    { id = 'bank',     label = 'Banco',      slot = 11, default = true },
    { id = 'ads',      label = 'Anuncios',   slot = 12, default = true },
    { id = 'services', label = 'Servicios',  slot = 13, default = true },
    { id = 'vehicles', label = 'Garaje',     slot = 14, default = true },
    { id = 'mail',       label = 'Correo',      slot = 15, default = true },
    { id = 'taxi',       label = 'Taxi',        slot = 16, default = true },
    { id = 'go',         label = 'GO',          slot = 17, default = true },
    { id = 'invoices',   label = 'Facturas',    slot = 18, default = true },
    { id = 'fines',      label = 'Multas',      slot = 19, default = true },
    { id = 'clock',      label = 'Reloj',       slot = 20, default = true },
    { id = 'delivery',   label = 'Mandao',      slot = 21, default = true },
    { id = 'dating',     label = 'Beboteo',     slot = 22, default = true },
    { id = 'calculator', label = 'Calculadora', slot = 23, default = true },

    --[[ Propiedades.

         Como el garaje: solo lee. De donde salen las casas lo decide
         `config/integraciones.lua`; si el servidor no tiene ningun recurso de
         viviendas, la aplicacion dice que no hay servicio. ]]
    { id = 'properties',  label = 'Propiedades',    slot = 24, default = true },

    --[[ El navegador y la grabadora.

         El navegador solo abre lo que el servidor haya puesto en su lista: uno
         que abra cualquier direccion no es una aplicacion, es un agujero. ]]
    { id = 'browser',     label = 'Navegador',      slot = 25, default = true },
    { id = 'voicememo',   label = 'Grabadora',      slot = 26, default = true },
    { id = 'sea',         label = 'Alerta SEA',     slot = 27, default = true, fija = true },

    --[[ Monedas. NO viene: en este servidor esta quitada.

         Sale a internet a por los precios, y eso es algo que un servidor tiene
         que decidir encender. Para tenerla: añadir aqui
         { id = 'crypto', label = 'Monedas', slot = 27, default = true },
         volver a poner `crypto = 'crypto'` en AppDomains y encender
         Config.Crypto.Enabled. ]]

    --[[ Las dos de los bajos fondos.

         Vienen instaladas como las demas. Un servidor que no las quiera las
         quita de aqui y desaparecen: no basta con esconderlas en el cliente,
         porque esta tabla es la que decide que se puede abrir. Y quitarselas
         solo a unos —a los civiles, a una banda— se hace desde el panel, sin
         tocar este fichero. ]]
    { id = 'darkchat',    label = 'DarkChat',       slot = 28, default = true },
    { id = 'blackmarket', label = 'Mercado negro',  slot = 29, default = true },

    --[[ OGN Fans: fotos que se desbloquean pagando (18/09).

         Creadores que publican con precio y fans que pagan por verlas, con
         propinas y chat. La configuracion esta en Config.Fans. ]]
    { id = 'fans',        label = 'OGN Fans',       slot = 30, default = true },

    --[[ Pescabichos: salir a la calle a pescar bichos. Los datos de juego en
         config/pescabichos.lua; el servidor, server/api/pescabichos.lua. ]]
    { id = 'pescabichos', label = 'Pescabichos',    slot = 31, default = true },

    --[[ Departamento de Justicia: directorio de abogados de guardia / servicio ]]
    { id = 'doj',         label = 'Justicia',       slot = 32, default = true },
}

--[[ De que aplicacion es cada dominio del API.

     Sirve para una cosa: si a alguien le han quitado una aplicacion, los
     metodos de esa aplicacion dejan de contestarle. Sin esto, quitarle el banco
     a alguien seria esconderle el icono, y bastaria con abrir la consola del
     navegador para seguir moviendo dinero.

     Va aqui, entera y en un sitio, y no repartida en cada fichero del API: la
     pregunta que se hace uno es "que puertas cierro si quito esta aplicacion", y
     esa pregunta se contesta leyendo esta tabla de arriba abajo.

     Un dominio puede ser de VARIAS aplicaciones —taxi y GO comparten los
     viajes, facturas y multas comparten los recibos— y entonces basta con tener
     una para poder llamarlo. Y hay dominios que no son de ninguna: los ajustes,
     la agenda, el aparato y los avisos son del telefono, no de una aplicacion,
     y quitarselos a alguien seria dejarle un ladrillo. ]]
AppDomains = {
    ads = 'ads',
    alarms = 'clock',
    bank = 'bank',
    bills = { 'invoices', 'fines' },
    black = 'blackmarket',
    calendar = 'calendar',
    calls = 'phone',
    camera = 'camera',
    dark = 'darkchat',
    dating = 'dating',
    delivery = 'delivery',
    doj = 'doj',
    fans = 'fans',
    gallery = 'gallery',
    groups = 'messages',
    lives = 'ogn',
    mail = 'mail',
    media = 'gallery',
    messages = 'messages',
    music = 'music',
    news = 'news',
    notes = 'notes',
    ogn = 'ogn',
    pb = 'pescabichos',
    properties = 'properties',
    browser = 'browser',
    memos = 'voicememo',
    sea = 'sea',
    rides = { 'taxi', 'go' },
    services = 'services',
    stickers = 'messages',
    valet = 'vehicles',
    vehicles = 'vehicles',
    voicemail = 'phone',
    world = { 'weather', 'map' },
}

--- Devuelve la definicion de una app por su id.
---@param id string
---@return table|nil
function GetApp(id)
    for i = 1, #Apps do
        if Apps[i].id == id then return Apps[i] end
    end
    return nil
end

--- Conjunto {id = true} con las apps instaladas de serie.
---@return table
function GetDefaultApps()
    local set = {}
    for i = 1, #Apps do
        if Apps[i].default then set[Apps[i].id] = true end
    end
    return set
end
