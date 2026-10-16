Config = {}

--[[ Traza por consola. Imprime cada RPC, asi que en produccion va apagado.
     Se puede encender sin tocar este fichero con `set ogphone_debug 1` en el
     cfg del servidor, que es lo comodo para depurar en local. ]]
Config.Debug = GetConvarInt('ogphone_debug', 0) == 1

--[[ FRAMEWORK -----------------------------------------------------------

     'auto' busca cual hay arrancado, en este orden: qbx_core, qb-core,
     es_extended. Con eso no hay que tocar nada en la mayoria de servidores.

     Se puede fijar a mano —'qbox', 'qbcore', 'esx'— si conviven dos cores en
     la carpeta y hay que decidir cual manda, o poner 'standalone' para probar
     el telefono en un servidor pelado, sin core ninguno. ]]
Config.Framework = 'auto'

--[[ Solo para ESX.

     En ESX el identificador es el de la licencia, no el del personaje: en un
     servidor con multipersonaje, todos los personajes de una cuenta comparten
     identificador y por tanto compartirian telefono. Si el servidor guarda el
     personaje en otro campo del xPlayer, se pone aqui su nombre y el telefono
     usara ese. En un ESX de un personaje por cuenta, se deja en nil. ]]
Config.EsxIdentifier = nil

--[[ Avisos del servidor: los de fuera del telefono ("no llevas ningun
     movil"). 'framework' usa el del core. Si el servidor tiene su propio
     recurso de avisos, se pone aqui su nombre y ese recurso tiene que atender
     el evento origen_phone:cl:notify. ]]
Config.Notify = 'origen_notify'

--[[ IDENTIDAD ------------------------------------------------------------
     origen_phone convive con lb-phone, asi que todo lo suyo va con nombres
     propios: item propio, tablas propias, comando propio. Nada se pisa. ]]

Config.Item = {}
Config.Item.Require = true      -- hace falta el item para abrir el telefono
Config.Item.Unique = true       -- cada telefono es un item con su metadata
Config.Item.Name = 'ognphone'
--[[ 'auto' busca cual hay: origen_inventory, ox_inventory, qb-inventory o
     qs-inventory. Se puede fijar al nombre de uno concreto. ]]
Config.Item.Inventory = 'auto'
-- Claves de metadata del item. Con nombres propios para no chocar con lb-phone.
Config.Item.MetaNumber = 'ognPhoneNumber'
Config.Item.MetaFormatted = 'ognFormattedNumber'
Config.Item.MetaName = 'ognPhoneName'

--[[ El id de la ficha, escrito tambien en el item.

     El numero es lo que se lee; esto es lo que dice CUAL de los aparatos que
     dicen ese numero es el bueno. Sin ello, un item robado y una linea
     recuperada abren los dos el mismo telefono.

     Los items de antes no lo llevan: se les graba solo la primera vez que se
     abren. ]]
Config.Item.MetaId = 'ognPhoneId'

--[[ De quien son los datos: del aparato o de la persona.

     'person'  De la persona. Si te roban el telefono, te compras otro y dentro
               esta todo lo tuyo: mismo numero, misma agenda, mismos mensajes y
               mismas fotos. No hay nada que recuperar.

     'item'    Del aparato. Cada item lleva su numero y su contenido dentro, asi
               que robarte el telefono es robarte lo que hay dentro. Mas duro y
               mas rolero, y para eso esta el punto de recuperar la linea.

     Esto NO es un aviso ni un adorno: en modo persona, al abrir un aparato el
     servidor no mira lo que lleva escrito el item, mira de quien es el personaje
     y le abre su linea. De ahi que comprarse otro lo devuelva todo.

     Lo manda el panel de administracion, en caliente. Esto es solo con lo que
     arranca una instalacion que no lo haya tocado nunca. ]]
Config.Item.Owner = 'person'

--[[ NUMEROS --------------------------------------------------------------
     Mismo formato que lb-phone (prefijo de 2 + 4 cifras = 6) para que los
     numeros de los dos telefonos se lean igual dentro del rol. El numero se
     guarda solo con digitos; el guion es de presentacion. ]]
Config.PhoneNumber = {}
Config.PhoneNumber.Format = '{2}-{4}'
Config.PhoneNumber.Length = 4
Config.PhoneNumber.Prefixes = { '55', '60', '62', '68', '70' }

--[[ REGISTRO ------------------------------------------------------------

     Lo que pasa en el telefono, a un canal de Discord. Sirve para lo de
     siempre: alguien dice que le han robado, alguien dice que no hizo esa
     transferencia, y hay que poder mirarlo sin abrir la base de datos.

     Sin webhook puesto no se manda nada y no se intenta nada: no hay peticiones
     al aire ni errores en consola.

     Lo que NO se manda: el contenido de los mensajes, las fotos ni nada
     privado. Se registra que ha pasado y entre quienes, no que se dijeron. Un
     registro que copia las conversaciones de la gente a un Discord es un
     problema legal, no una herramienta de moderacion. ]]
Config.Logs = {}
Config.Logs.Webhook = ''

--- El nombre con el que aparece.
Config.Logs.Name = 'ORIGEN'

--[[ Que se registra. Cada uno se puede apagar por su cuenta.

     Los avisos van encendidos y el resto tambien: es mas facil quitar ruido que
     descubrir que lo que necesitabas no se guardaba. ]]
Config.Logs.What = {
    admin = true,        -- cambios desde el panel
    numbers = true,      -- peticiones de numero y su respuesta
    recovery = true,     -- lineas recuperadas
    transfers = true,    -- envios de dinero
    blackmarket = true,  -- compras del mercado negro
}

--[[ CRIPTO -------------------------------------------------------------

     Comprar y vender monedas con el precio de verdad, el de fuera del juego.
     Es el unico sitio del telefono donde el dinero de alguien depende de algo
     que nadie del servidor controla, y eso es lo que lo hace interesante.

     El precio se pide UNA VEZ para todo el servidor y se guarda unos minutos.
     Con cincuenta personas mirando serian cincuenta peticiones al mismo sitio,
     y quien las recibe acabaria cortandolas todas.

     Si la fuente no contesta, no se opera: un precio inventado aqui es dinero
     inventado. ]]
Config.Crypto = {}
Config.Crypto.Enabled = false

--- De donde salen los precios. Va sin clave: es la parte publica de CoinGecko.
Config.Crypto.Api = 'https://api.coingecko.com/api/v3/simple/price'
Config.Crypto.Currency = 'usd'

--- Cada cuanto se piden, en segundos. Bajarlo mucho da menos precios, no mas.
Config.Crypto.Refresh = 300

--- Que monedas se pueden comprar. Los identificadores son los de CoinGecko.
Config.Crypto.Coins = {
    'bitcoin', 'ethereum', 'solana', 'dogecoin', 'cardano', 'litecoin',
}

--[[ Como se llama cada una en el telefono.

     El precio es el de la moneda de verdad, pero el nombre es del servidor:
     en la pantalla no sale ninguna marca real. Una moneda sin nombre aqui
     sale con su identificador. ]]
Config.Crypto.Names = {
    bitcoin  = 'Bitoro',
    ethereum = 'Etherna',
    solana   = 'Solaris',
    dogecoin = 'Perrocoin',
    cardano  = 'Cardina',
    litecoin = 'Ligera',
}

--[[ Lo que se lleva la casa, en tanto por uno.

     Sin comision, comprar y vender sin que cambie el precio seria gratis, y eso
     convierte el mercado en un boton de recargar hasta que salga bien. ]]
Config.Crypto.Fee = 0.02

--- Tope por operacion. Cero lo quita.
Config.Crypto.MaxPerTrade = 500000

--[[ NAVEGADOR ----------------------------------------------------------

     Lo que permite que un servidor monte sus propias webs —una bolsa de
     trabajo, la web de un concesionario, un periodico— y se abran desde el
     telefono.

     SOLO SE VA A DONDE PONE AQUI, y es una lista BLANCA: lo que no esta, no se
     abre. Una lista negra se esquiva; esta no. Un navegador dentro del juego
     que abre cualquier direccion permite enseñar cualquier cosa en la pantalla
     de otro jugador, y hace responsable al servidor de contenido que nunca ha
     visto.

     Se comparan dominios, no direcciones: poniendo "origen.net" valen todas sus
     paginas y todos sus subdominios. ]]
Config.Browser = {}
Config.Browser.Enabled = true

--- Por donde se empieza. Vacio para empezar en los marcadores.
Config.Browser.Home = ''

--- A donde se puede ir. Sin nada aqui, el navegador no abre nada.
Config.Browser.Sites = {}

--[[ Los marcadores, que son del servidor y no del jugador.

     Un marcador es un sitio al que el servidor quiere que se pueda ir. Dejar
     que cada uno se guarde los suyos no añade nada: de todas formas solo se
     puede abrir lo que esta en la lista de arriba. ]]
Config.Browser.Bookmarks = {}

--[[ MODERACION ---------------------------------------------------------

     Dos filtros distintos, y conviene no confundirlos.

     1. LAS PALABRAS. Se tapan en TODO lo que escribe un jugador: mensajes,
        publicaciones, anuncios, notas. La lista viene VACIA a proposito. No es
        un olvido: que palabras son inaceptables depende del idioma, del pais y
        de lo que quiera cada comunidad, y una lista puesta por nosotros seria a
        la vez insuficiente para unos e insultante para otros. La pone el
        servidor, que es quien responde de su gente.

     2. LOS NOMBRES RESERVADOS. Se prohiben en nombres de usuario, alias y
        nombres de perfil. Esta si viene puesta, porque no es cuestion de gustos:
        alguien que se llame "Admin" o "LSPD" esta engañando a los demas, y eso
        es igual de malo en cualquier servidor.

     Lo que se tapa se tapa; no se rechaza el mensaje. Rechazarlo le dice a quien
     lo escribio exactamente que palabra ha saltado, y a partir de ahi es un
     juego de buscar la que cuela. ]]
Config.Filter = {}
Config.Filter.Enabled = true

--[[ Palabras que se tapan. Vacia de serie: la pone cada servidor.

     Se busca dentro de la palabra, asi que poner "tonto" tapa tambien
     "tontaco". Y no distingue mayusculas ni acentos. ]]
Config.Filter.Words = {}

--- Con que se tapan.
Config.Filter.Mask = '***'

--[[ Lo que nadie puede ponerse de nombre.

     Suplantar a la administracion o a los servicios de emergencia no es una
     palabrota: es engañar a la gente, y por eso esta lista si viene puesta. ]]
Config.Filter.ReservedNames = {
    'admin', 'administrador', 'staff', 'moderador', 'soporte', 'support',
    'police', 'policia', 'lspd', 'bcso', 'sheriff', 'ems', 'sama', 'emergencias',
    'origen', 'ogn', 'sistema', 'system', 'oficial', 'official',
}

--[[ RECUPERAR LA LINEA --------------------------------------------------

     La tienda de la compañia: si te roban el telefono o lo pierdes, vas, pagas
     y te devuelven TU numero en un aparato sin estrenar.

     NO ES UNA COPIA DE SEGURIDAD, y la diferencia importa. Restaurarlo todo
     solo al conseguir otro movil seria mas facil y seria peor: el robo de un
     telefono dejaria de importar, y con el se va media tension del rol. Aqui
     que te lo roben duele —pierdes el aparato, pagas y te desplazas— pero no te
     borra la vida.

     En modo "de la persona" esto no hace falta: alli el numero es del personaje
     y comprarse otro aparato lo devuelve todo. Se deja encendido igual porque
     no estorba, y porque un servidor puede cambiar de modo cualquier dia.

     Los sitios se ponen desde el panel, en Mapa. ]]
Config.Recovery = {}
Config.Recovery.Enabled = true

--- Lo que cobra la compañia. Cero es gratis.
Config.Recovery.Price = 5000

--- A que distancia del mostrador se puede pedir, en metros.
Config.Recovery.Range = 3.0

--[[ LA TIENDA DE TELÉFONOS ------------------------------------------------

     El mostrador donde se compra un móvil, y donde además se recupera una
     línea perdida si el servidor va en modo "del aparato".

     POR QUÉ HACÍA FALTA

     Recuperar tu número pide un teléfono SIN ESTRENAR donde meterlo —igual que
     en la tienda de verdad: vas con un móvil y te ponen tu línea—, y no había
     dónde comprar ese móvil dentro del juego. El item salía de la tienda
     general del inventario, que es otro recurso: quien instale este no tiene
     por qué tenerla, y entonces la recuperación no se puede terminar.

     QUÉ SE PUEDE HACER AQUÍ, SEGÚN EL MODO

     De la persona   Comprar un teléfono. Tus datos son tuyos, así que al
                     abrirlo está todo: tu número, tu agenda y tus fotos.

     Del aparato     Comprar un teléfono, que sale sin estrenar y con un número
                     nuevo. Y recuperar una línea tuya, que te la ponen en uno
                     de esos teléfonos en blanco.

     LOS SITIOS

     Se ponen desde el panel de administración, en Mapa > Tiendas. Son los
     mismos que los de recuperar la línea: es un mostrador, no dos. ]]
Config.Shop = {}
Config.Shop.Enabled = true

--[[ Lo que cuesta un teléfono nuevo. Cero es gratis.

     Es aparte del precio de recuperar la línea: comprarte el aparato y que te
     devuelvan tu número son dos cosas, y en modo "del aparato" se pagan las
     dos. ]]
Config.Shop.PhonePrice = 1500

--[[ El dependiente.

     A false no se pone ninguno y la tienda es solo un punto en el suelo. Con
     una tabla se planta ahí un vecino que no anda ni se asusta.

     'heading' es hacia dónde mira, en grados; a nil, al norte.
     'scenario' es lo que hace mientras espera; a nil, quieto.

     El modelo se puede cambiar por cualquiera de GTA. Si no existe o no llega
     a cargar, la tienda sigue funcionando sin él: un dependiente que no
     aparece no puede dejar sin teléfono a nadie. ]]
Config.Shop.Ped = {
    model = 's_m_m_highsec_01',
    heading = nil,
    scenario = 'WORLD_HUMAN_CLIPBOARD',
}

--[[ La marca del mapa.

     A false no sale ninguna y hay que saberse el sitio, que es más rolero y es
     lo que quieren algunos servidores.

     'sprite' 606 es el del móvil. El color es de la paleta de GTA, no un RGB. ]]
Config.Shop.Blip = {
    sprite = 606,
    color = 3,
    scale = 0.7,
}

--[[ NUMEROS A LA CARTA --------------------------------------------------

     Un servicio VIP: el jugador pide el numero que quiere desde Ajustes y un
     administrador dice si o no desde el panel.

     EL DINERO SE COBRA AL APROBARLO, no al pedirlo. Cobrar antes obligaria a
     devolver el de cada peticion denegada, y devolverselo a alguien que se ha
     desconectado no se puede hacer bien: se quedaria dinero por el camino.

     Con el precio a cero es gratis y la peticion es solo un permiso. Y aunque
     haya precio, el administrador puede aprobarla sin cobrar: hay servidores
     que lo venden fuera del juego y aqui solo dan el visto bueno. ]]
Config.Numbers = {}
Config.Numbers.Enabled = true

--- Lo que cuesta, en dinero del juego. Cero es gratis.
Config.Numbers.Price = 25000

--[[ Si el numero elegido tiene que empezar por uno de los prefijos de arriba.

     Encendido, los numeros a la carta siguen pareciendose a los del servidor y
     no aparece un 12-3456 entre gente con 55 y 70. Apagado, vale cualquier
     combinacion del largo correcto. ]]
Config.Numbers.KeepPrefix = true

--[[ Numeros que no se pueden pedir aunque esten libres.

     De serie los capicuas mas obvios y los repetidos: son los que todo el mundo
     pide el primer dia, y regalarlos por orden de llegada quema el servicio
     entero en una tarde. Un servidor que quiera venderlos los quita de aqui. ]]
Config.Numbers.Reserved = {
    '550000', '551111', '552222', '555555',
    '600000', '601111', '606060', '666666',
    '700000', '707070', '777777',
}

--[[ AVISOS CON EL TELEFONO CERRADO --------------------------------------

     Que se ve cuando llega algo y no estas mirando el movil.

     Hasta ahora, nada: sonaba y ya esta. Un aviso que solo suena obliga a abrir
     el telefono para saber si era un mensaje, una factura o el reparto, y a
     abrirlo cada vez que suena algo.

     Ahora asoma el TELEFONO por el borde de abajo, lo justo para que se lea el
     aviso, y se vuelve a guardar solo. No es una tarjeta suelta flotando en una
     esquina: es el mismo aparato, con su marco, su fondo de pantalla y su hora,
     como cuando lo tienes en la mesa y vibra. No roba el raton ni tapa el
     juego.

     Lo que NO hace es enseñar lo que pone si el jugador ha apagado las vistas
     previas o esta en modo streamer. Ahi sale que hay algo, pero no que dice:
     un aviso que se lee desde fuera del rol es lo mismo que leerle el movil a
     alguien por encima del hombro. ]]
Config.Notifications = {}

--- Con esto en false, el telefono cerrado vuelve a solo sonar.
Config.Notifications.Outside = true

--- Por que lado de la pantalla asoma: 'right', 'center' o 'left'.
Config.Notifications.Side = 'right'

--- Lo que se queda en pantalla, en segundos.
Config.Notifications.Seconds = 6

--[[ Cuantos avisos se apilan a la vez.

     El telefono asoma mas cuantos mas haya, asi que este numero es lo alto que
     puede llegar a subir. Con siete se planta en media pantalla y no se lee
     ninguno. ]]
Config.Notifications.Max = 3

--[[ EL TELEFONO SE ENCIENDE SOLO -----------------------------------------

     Para que te llegue una llamada o un mensaje, el servidor tiene que saber
     que numero llevas encima. Eso se apuntaba al ABRIR el telefono, asi que
     hasta que no lo abrias una vez estabas ilocalizable: no sonaba, no entraba
     nada, y quien te escribia veia el mensaje entregado.

     Con esto, el telefono se enciende solo al aparecer —sin abrir nada, sin
     que se vea— en cuanto se detecta que llevas uno. Es lo que hace un movil
     de verdad al encenderlo: engancharse a la red y quedarse ahi. ]]
Config.Notifications.AutoWake = true

--- Cada cuanto se vuelve a mirar si ya llevas telefono, en segundos.
Config.Notifications.WakeEvery = 20

--[[ ALMACENAMIENTO ------------------------------------------------------

     Lo que ocupa lo que lleva dentro el telefono.

     No es un adorno con un numero inventado: se cuenta lo que hay de verdad en
     la base de datos, y las fotos que traen su tamaño real se apuntan por lo
     que pesan. Lo demas va con un peso fijo, porque una nota es texto y lo que
     pesa en un telefono es simbolico.

     El tope tampoco es inventado: sale del unico limite real que hay, el de
     fotos por telefono. Asi la barra llena significa algo concreto —que la
     galeria esta a punto de empezar a soltar la foto mas vieja que no sea
     favorita— y no un aviso que no lleva a ninguna parte. ]]
Config.Storage = {}

--[[ El tope, en megas.

     Con 0 se calcula solo a partir del limite de fotos, que es lo recomendado:
     si un servidor sube Config.Uploader.MaxPhotos, el telefono crece con el
     sin tener que acordarse de tocar esto. ]]
Config.Storage.Capacity = 0

--- Lo que se apunta por cosa guardada, en kilobytes, cuando no se sabe el real.
Config.Storage.Weights = {
    photo   = 2400,
    video   = 18000,
    memo    = 900,
    note    = 4,
    message = 1,
}

--[[ Hueco para todo lo que no son fotos, en megas, al calcular el tope solo.
     Sin el, un telefono sin ninguna foto y con mil mensajes saldria al 100 %. ]]
Config.Storage.Slack = 120

--[[ APERTURA ------------------------------------------------------------ ]]
Config.Command = 'ogphone'          -- comando para abrir/cerrar (false lo desactiva)

--[[ La tecla, F1.

     Es solo la de FABRICA: RegisterKeyMapping la deja escrita la primera vez
     que un jugador entra, y a partir de ahi manda lo que el tenga puesto en
     los ajustes del juego (Ajustes > Controles > FiveM). Cambiar este valor no
     le pisa la tecla a quien ya haya elegido otra.

     F1 y no otra: el inventario esta en F2 (origen_inventory) y las demas Fx
     que usa el servidor son F11 —ver IDs y radio— asi que la de al lado del
     inventario estaba libre.

     Y solo se abre si llevas el movil encima: eso no lo decide la tecla, lo
     decide CanOpen() en client/modules/phone.lua. ]]
Config.Keybind = 'F1'
Config.CloseOnDeath = true
Config.CloseWhenSwimming = true
Config.AllowInVehicle = true

--[[ ANIMACION Y PROP ---------------------------------------------------- ]]
Config.Animation = {}
Config.Animation.Enabled = true
Config.Animation.Prop = `prop_amb_phone`
Config.Animation.PropBone = 28422
Config.Animation.PropOffset = vector3(0.0, 0.0, 0.0)
Config.Animation.PropRotation = vector3(0.0, 0.0, 0.0)

--[[ LLAMADAS ------------------------------------------------------------ ]]
Config.Calls = {}

--[[ Contestar y colgar sin sacar el telefono (18/09).

     Se pidio poder coger o colgar una llamada con una tecla. Son teclas de
     FiveM: cada jugador las puede cambiar en Ajustes > Asignacion de teclas >
     FiveM, y lo que se pone aqui es solo la de serie (la primera vez).

     Solo hacen algo si hay una llamada: Retroceso rechaza la que suena o
     cuelga la que esta en marcha; Intro coge la que suena. Mientras se escribe
     en el telefono no cuentan: con el teclado en la interfaz las teclas de
     FiveM no llegan. ]]
Config.Calls.KeyAnswer = 'RETURN'
Config.Calls.KeyHangup = 'BACK'
Config.Calls.Voice = 'pma-voice'    -- 'pma-voice' | false
Config.Calls.RingTimeout = 30       -- segundos que suena antes de darse por perdida
Config.Calls.MaxDuration = 60 * 60  -- corte de seguridad, en segundos
Config.Calls.AllowVideo = true

--[[ Grabar llamadas.

     La interfaz solo puede coger TU microfono: la voz del otro va por pma-voice
     y no pasa por la pagina. Para que en la grabacion se oigan los dos, el
     cliente del otro graba su propio microfono y sube su pista.

     Y LO HACE SIN AVISARLE. Al otro no le sale nada en pantalla y no puede
     negarse: grabar a escondidas es la mitad del rol de esto. Queda escrito
     aqui para que se sepa lo que se enciende al poner esto a `true`.

     La grabacion se la queda solo quien le da al boton. ]]
Config.Calls.AllowRecording = true

--[[ El modulador de voz.

     Cambia como suena tu voz para el otro lado de la llamada. No se toca el
     microfono: lo que se hace es que el que ESCUCHA pase esa voz por un filtro
     antes de sonarla, asi que el efecto lo aplica su cliente y no el tuyo.

     Eso tiene una consecuencia que conviene saber: un jugador con el recurso
     tocado podria no aplicar el filtro y oirte con tu voz. Para el rol vale
     —el que hace trampa se estropea su propia partida— pero no sirve para algo
     donde de verdad importe que no te reconozcan.

     Son los filtros de radio de GTA con los cortes movidos: no suenas como otra
     persona, suenas como tu por un aparato distinto. Para taparse en una
     llamada es lo que hace falta. ]]
Config.Calls.AllowVoiceFilter = true

--[[ DARKCHAT ----------------------------------------------------------

     El chat de los bajos fondos. Se entra por codigo o porque alguien de dentro
     te mete estando al lado, y en la pantalla pone que va cifrado.

     LO DE "CIFRADO" ES DE ROL. Por debajo es un chat normal y lo que se dice
     esta en la base de datos como todo lo demas: la administracion puede leerlo
     y debe poder, o no hay forma de moderar nada. El letrero esta para que la
     gente lo interprete, que es de lo que va esto. ]]
Config.DarkChat = {}
Config.DarkChat.Enabled = true

--- Largo del codigo de una sala. Es la llave: quien lo tenga, entra.
Config.DarkChat.CodeLength = 6

--- Cuanta gente cabe en una sala. 0 = sin limite.
Config.DarkChat.MaxMembers = 0

--- Salas que puede tener abiertas una misma persona.
Config.DarkChat.MaxRooms = 8

--- A que distancia se puede meter a alguien sin darle el codigo, en metros.
Config.DarkChat.InviteRadius = 3.0

--[[ Cuanto aguanta un mensaje antes de borrarse solo, en minutos.

     Es lo que hace que una sala sirva para algo que no quieres que quede
     escrito. La sala lo elige al crearse entre estos; el cero es "no se borra".
]]
Config.DarkChat.BurnOptions = { 0, 5, 30, 60, 1440 }

--[[ MERCADO NEGRO --------------------------------------------------------

     El tablon de lo que no se puede anunciar en el otro. Aqui nadie da su
     nombre ni su numero: solo un alias.

     LA ENTREGA ES UN PUNTO MUERTO, y eso es lo que lo diferencia del mercado
     normal. Nadie se ve la cara: el vendedor deja la mercancia en un sitio y
     dice donde, el comprador va y la recoge. Entre una cosa y la otra hay rol —
     y la posibilidad de que alguien este vigilando ese punto. ]]
Config.BlackMarket = {}
Config.BlackMarket.Enabled = true

--- Dias que aguanta un anuncio antes de caer solo.
Config.BlackMarket.Days = 3

--- Anuncios a la vez por persona.
Config.BlackMarket.MaxPerPhone = 6

--- Cosas distintas y unidades por anuncio.
Config.BlackMarket.MaxItems = 6
Config.BlackMarket.MaxStock = 50

--[[ Lo que se lleva quien lo monta, en tanto por uno.

     Mas que en el mercado legal a proposito: aqui el que pone el tablon corre
     mas riesgo, y ademas es lo que hace que vender por lo legal siga teniendo
     sentido cuando la mercancia no lo necesita. ]]
Config.BlackMarket.Commission = 0.1

--[[ A que distancia se recoge un punto muerto, en metros.

     Cinco es "en ese sitio", no "por ahi cerca": si fuera mas, se podria
     recoger desde un coche en marcha y se acabaria el rol de tener que bajar. ]]
Config.BlackMarket.DropRadius = 5.0

--[[ Cuanto aguanta un paquete en el punto muerto, en minutos.

     Pasado ese rato el trato se cae y el dinero vuelve al comprador: un punto
     muerto que aguanta para siempre es un almacen, no un punto muerto. ]]
Config.BlackMarket.DropMinutes = 60

--[[ Lo que NO se puede vender ni aqui.

     La lista es corta a proposito: el sentido de este tablon es justamente que
     se pueda vender lo que en el otro no. Lo que sigue vetado son las llaves y
     los papeles de un coche, por lo mismo que alli: un vehiculo no esta en
     ningun inventario y venderlo por la puerta de atras seria saltarse el
     garaje entero. ]]
Config.BlackMarket.Blocked = {
    'vehiclekey', 'vehicle_key', 'carkeys', 'keys',
    'vehicledocs', 'vehicle_papers', 'documentacion_vehiculo',
}

--[[ WEBRTC ------------------------------------------------------------

     Como viaja la imagen de las videollamadas y de los directos.

     Con esto encendido, la imagen va **directa de un jugador a otro**: video de
     verdad, treinta fotogramas por segundo, y por el servidor solo pasan unas
     lineas de texto para que los dos se encuentren. Es lo que hacen los
     telefonos de pago y por eso no tienen los limites del otro camino.

     Con esto apagado —o cuando dos jugadores no consiguen encontrarse— se cae
     solo al camino de los fotogramas, que pasa por el servidor y por eso va a
     pocos fotogramas por segundo. La llamada funciona igual; se ve peor.

     LO QUE HAY QUE ENTENDER ANTES DE TOCAR ESTO:

     Un STUN es gratis y solo sirve para que cada uno averigue su propia
     direccion. Con eso se conectan la mayoria de las parejas. Los que estan
     detras de un router que no coopera necesitan un TURN, que es un servidor
     que hace de puente y por el que pasa el video de verdad. Un TURN cuesta
     dinero o hay que montarlo (coturn), y lleva usuario y contraseña.

     Sin TURN esto sigue valiendo la pena: a la mayoria le conectara, y al resto
     le queda el camino de los fotogramas. Con TURN, le conecta a todo el mundo.

     Sitios donde sacar uno: Cloudflare Realtime, Metered, o un coturn propio.
     Se rellena aqui tal cual lo den:

         { urls = 'turn:mi.servidor:3478', username = 'usuario', credential = 'clave' }
]]
Config.WebRTC = {}
Config.WebRTC.Enabled = true

--[[ El TURN, que es lo que cierra la videollamada.

     A 'cloudflare' se piden credenciales a Cloudflare Realtime al arrancar y se
     guardan hasta que caduquen. Hace falta sacar un token en su panel —el plan
     gratuito sobra para un servidor de rol— y poner dos convars en el cfg:

         set ogphone_turn_token_id  "..."
         set ogphone_turn_api_token "..."

     A `false` se queda solo con los STUN de abajo. Entonces el camino directo
     le conecta a una parte de la gente y a otra no, y a esos les toca el camino
     de los fotogramas: se ven, pero peor y gastando servidor.

     No es un adorno: los recursos de videollamada que se venden para FiveM
     traen el TURN como pieza obligatoria. ]]
Config.WebRTC.Turn = 'cloudflare'

--- Cuanto duran las credenciales que pide, en segundos. Un dia esta bien.
Config.WebRTC.TurnTtl = 86400

--- Solo STUN de serie: gratis, sin cuentas y sin nada que montar.
Config.WebRTC.IceServers = {
    { urls = 'stun:stun.l.google.com:19302' },
    { urls = 'stun:stun1.l.google.com:19302' },
}

--[[ Segundos que se espera a que conecte antes de tirar por los fotogramas.

     Seis es tiempo de sobra cuando va a funcionar: una conexion que sale suele
     tardar menos de dos. Lo que se esta midiendo es cuanto aguanta el jugador
     mirando una pantalla negra antes de que le demos algo, aunque sea peor. ]]
Config.WebRTC.Timeout = 6

--[[ Lo maximo que sube el video directo, en kilobits por segundo.

     Estaba en 3000 y eso es mas de lo que tiene de subida media España con
     ADSL o con fibra barata compartida. El video directo no pasa por el
     servidor, pero SI por la conexion de casa del jugador, la misma que usa el
     juego: si la llena, el juego deja de llegar al servidor y le echan por
     timeout. Para una pantalla del tamaño de un telefono, 1000 se ve nitido. ]]
Config.WebRTC.MaxKbit = 1000

--[[ La imagen de la videollamada.

     Lo que se manda es lo que ve el otro por su pantalla: su cara y lo que
     tenga detras. La interfaz ya sabe coger el fotograma del juego —es lo mismo
     que hace la camara para sacar fotos—, asi que no hace falta instalar nada:
     se recorta pequeño, se comprime mucho y se manda por el servidor al otro
     lado de la llamada, y a nadie mas.

     ESTO ES EL PLAN B. Lo normal es que la imagen vaya por WebRTC
     —`Config.WebRTC`, mas arriba—: directa de un jugador a otro y sin tocar el
     servidor. Los fotogramas solo viajan mientras el otro lado NO confirma que
     le llega el video directo; en cuanto lo confirma, se paran solos, y vuelven
     si deja de llegarle.

     POR QUE HAY TOPE DE BYTES (15/09). Los fotogramas van por la MISMA conexion
     que el juego. Estaban a 20 por segundo, sin tope de tamaño y encendidos a la
     vez que WebRTC: con un paisaje con detalle eran mas de 1 MB/s de subida por
     jugador. La conexion con FiveM se atragantaba y el servidor echaba a los dos
     de la videollamada por timeout.

     Ahora mandan los bytes, no los fps: cada lado gasta como mucho
     `KBPorSegundo`. Si la imagen tiene mucho detalle, primero baja la calidad
     del JPEG y despues salen menos fotogramas; lo que no pasa nunca es que se
     supere el tope. En una llamada de mas de dos, el tope se reparte.

     SUBIR `KBPorSegundo` ES LO UNICO PELIGROSO DE ESTE BLOQUE. 96 KB/s son unos
     770 kbit/s de subida encima de lo que ya gasta el juego; con conexiones
     modestas no conviene pasar de ahi. ]]
Config.Calls.Video = {}
Config.Calls.Video.Fps = 12             -- techo; con el tope de bytes pueden salir menos
Config.Calls.Video.Width = 240          -- ancho de la imagen, en pixeles
Config.Calls.Video.Quality = 0.5        -- de 0 a 1, la calidad de partida del JPEG
Config.Calls.Video.KBPorSegundo = 96    -- lo maximo que sube cada lado por la red del juego

--[[ Cuantas videollamadas pueden estar mandando imagen a la vez.

     Cuando se llega al tope, las llamadas nuevas siguen funcionando: se oyen y
     se ven las caras con la camara de cada uno, pero no se manda imagen. Vale
     mas eso que quedarse todos sin ancho de banda a la vez. ]]
Config.Calls.Video.MaxConcurrent = 8

--[[ Escribir `video.log` solo mientras haya alguien con la camara puesta.

     Encendido porque es lo unico que dice POR QUE no se ve a alguien, y hay que
     mirarlo mientras pasa: despues, el estado ya no cuenta lo que fallo. Se
     escribe cada tres segundos y una ultima vez al acabar; sin videollamada no
     hace nada.

     En un servidor en produccion y ya rodado, a false. ]]
Config.Calls.Video.AutoLog = false

--[[ El altavoz (18/09, como sd-phone).

     En una llamada normal solo se oyen los de la llamada: nadie de alrededor
     oye nada. Con el altavoz puesto, los que esten a menos de esta distancia
     de quien lo tiene entran en la llamada: oyen al otro lado y pueden
     hablarle. Al alejarse, salen. ]]
Config.Calls.SpeakerRadius = 3.0
--[[ Cuanta gente cabe en una llamada, CONTANDO a los dos que la empezaron.

     Cinco: tu y cuatro mas. Es lo que cabe bien en la pantalla de un telefono
     —dos arriba, dos abajo y tu en el recuadro pequeño— y lo que aguanta la
     imagen sin partirse en sellos.

     Se puede subir. La rejilla esta escrita hasta seis camaras a la vez, y de
     ahi para arriba sigue funcionando: se reparte en dos columnas y las filas
     que hagan falta. Lo que no sube solo es lo que se ve: en una de ocho, cada
     camara es la mitad de alta que en una de cuatro.

     Y el gasto sube con el CUADRADO de la gente: en una de cinco, cada
     fotograma sale del servidor cuatro veces, y son cinco los que mandan. Por
     eso el ritmo baja solo con la gente que hay (ver VideoCall.Ritmo). ]]
Config.Calls.MaxParticipants = 5
Config.Calls.Emergency = {           -- numeros cortos que enrutan a un servicio
    ['911'] = 'police',
    ['112'] = 'police',
    ['police'] = 'police',
    ['061'] = 'ambulance',
    ['ambulance'] = 'ambulance',
    ['mechanic'] = 'mechanic',
    ['doj'] = 'doj',
    ['912'] = 'doj',
}

--[[ MENSAJES ------------------------------------------------------------ ]]
Config.Messages = {}
Config.Messages.MaxLength = 1000
--[[ De quien parecen venir los mensajes que manda el propio servidor cuando
     quien los manda no ha dicho ningun remitente. No es un telefono de nadie:
     al que lo recibe le sale como un numero desconocido, igual que un SMS de
     una empresa. ]]
Config.Messages.SystemNumber = '900100'
Config.Messages.EditWindow = 15 * 60   -- segundos que se puede editar un mensaje
Config.Messages.PageSize = 30        -- mensajes por pagina al hacer scroll
Config.Messages.MaxGroupMembers = 32
Config.Messages.AllowDelete = true
Config.Messages.DeleteWindow = 60 * 60 -- segundos durante los que se puede borrar para todos

--[[ GALERIA Y SUBIDAS --------------------------------------------------- ]]
Config.Uploader = {}
Config.Uploader.Resource = 'origen_uploader'   -- usa su export UploadFileInternal
Config.Uploader.MaxPhotos = 500                 -- fotos por telefono
Config.Uploader.TrashDays = 30                  -- dias en la papelera antes de borrarse

--[[ Videos de la camara.
     Suben directos a Fivemanage (presigned URL), no por la conexion del juego,
     asi que se pueden alargar. Lo que cuesta alargarlos: mas espacio en
     Fivemanage y mas tiempo subiendo en la conexion de casa del jugador.
     Un minuto a 1200 kb/s son unos 9 MB. ]]
Config.Uploader.VideoMaxSeconds = 60            -- de 5 a 180
Config.Uploader.VideoBitrate = 1200             -- calidad en kb/s, de 500 a 4000

--[[ OGN (la red social) ------------------------------------------------- ]]
Config.OGN = {}
Config.OGN.Enabled = true
Config.OGN.UsernamePattern = '^[%w%._]+$'
Config.OGN.UsernameMin = 3
Config.OGN.UsernameMax = 20
Config.OGN.MaxCaption = 2200
Config.OGN.MaxComment = 500
Config.OGN.MaxMediaPerPost = 10
Config.OGN.StoryHours = 24
Config.OGN.FeedPageSize = 12
Config.OGN.CostToVerify = false     -- p.ej. 50000 para cobrar el verificado

--[[ DIRECTOS ------------------------------------------------------------
     Alguien enciende la camara y lo que ve por su pantalla lo ven los demas.
     Es lo mismo que la videollamada, pero un fotograma no sale del servidor
     una vez: sale tantas veces como gente lo este viendo.

     Por eso los numeros son mas bajos que los de una videollamada, y por eso
     hay tope de espectadores. Con 2 fps, 320 px y veinte mirando:

         un fotograma          ->  unos 9 KB
         un directo entero     ->  unos 360 KB/s

     Que es mucho. Es el techo de lo que este telefono puede hacer sin un
     servidor de video de verdad detras, y por eso el tope de directos a la vez
     es tan bajo. Si tu servidor va justo, lo primero que hay que bajar es
     MaxViewers, que es lo que multiplica. ]]
Config.OGN.Live = {}
Config.OGN.Live.Enabled = true
Config.OGN.Live.Fps = 2
Config.OGN.Live.Width = 320         -- lado mayor de la imagen, en pixeles
Config.OGN.Live.Quality = 0.45      -- de 0 a 1, lo que aprieta el JPEG
Config.OGN.Live.MaxConcurrent = 3   -- directos a la vez en todo el servidor
Config.OGN.Live.MaxViewers = 20     -- gente mirando un mismo directo
Config.OGN.Live.ChatLines = 60      -- lineas de chat que se guardan mientras dura

--[[ BATERIA ------------------------------------------------------------- ]]
Config.Battery = {}
Config.Battery.Enabled = true    -- encendida el 30/09 (el usuario: «que se descargue y marque la batería»)
-- 30/09, el usuario: «el móvil debería descargarse cada 2 horas»: 7.200 s / 100 = 72 s por punto,
-- abierto o guardado.
Config.Battery.DrainSeconds = 72        -- segundos por cada 1% con el movil abierto
--[[ Guardado dura tres horas de cien a cero (06/10, el usuario: «sin usarlo
     deberia durar 3 horas»). 108 s por cada 1 % son 10.800 s, que son esas
     tres horas; media hora sin tocarlo baja un 17 % en vez de un 25 %.
     Abierto en la mano sigue gastando mas: dos horas. ]]
Config.Battery.DrainSecondsIdle = 108   -- segundos por cada 1% con el movil cerrado
Config.Battery.ChargePerTick = 5
--- Minutos que tarda en cargarse del todo en un punto de carga.
Config.Battery.ChargeMinutes = 5        -- «en un punto de carga, 5 min al 100 %» (30/09)
--- Con cuanta bateria llega un movil recien comprado: sin nada, hay que cargarlo (30/09).
Config.Battery.NuevoNivel = 0

--[[ LO QUE SE TOCA DESDE EL PANEL --------------------------------------

     Lo que sigue son **valores de partida**. Una vez cambiados desde el panel
     de administracion mandan los de la base de datos, y estos solo vuelven a
     usarse si alguien los devuelve al principio desde ahi.

     Se quedan aqui de todas formas porque son lo que ve una instalacion recien
     hecha, antes de que nadie abra el panel. ]]

--[[ Los fondos que se le ofrecen a todo el mundo.

     `url` puede ser un fichero del propio recurso —como los de serie— o una
     direccion de fuera. Los ficheros van en `ui/images/wallpapers`. ]]
Config.Wallpapers = {
    { id = 'default',  label = 'ORIGEN',     url = 'images/wallpapers/origen.png' },
    { id = 'gradient', label = 'Degradado',  url = 'images/wallpapers/default.svg' },
    { id = 'midnight', label = 'Medianoche', url = 'images/wallpapers/midnight.svg' },
    { id = 'sunset',   label = 'Atardecer',  url = 'images/wallpapers/sunset.svg' },
    { id = 'forest',   label = 'Bosque',     url = 'images/wallpapers/forest.svg' },
    { id = 'carbon',   label = 'Carbono',    url = 'images/wallpapers/carbon.svg' },
    { id = 'light',    label = 'Claro',      url = 'images/wallpapers/light.svg', light = true },
}

--[[ Los colores de acento.

     Cada uno trae sus cinco tonos y no solo el principal: el acento marca lo
     elegido, lo que esta debajo del raton y lo que esta encendido, y si solo se
     cambiara `acc` los bordes y los fondos a media tinta se quedarian rosas.

     `rgb` son los canales sueltos, para poder escribir rgba(...) con ellos. ]]
Config.Accents = {
    { id = 'origen', label = 'ORIGEN',   acc = '#fc0259', rgb = '252, 2, 89',   soft = '#fc0259', pale = '#fd9bbd', deep = '#82173c' },
    { id = 'blue',   label = 'Azul',     acc = '#2f7dff', rgb = '47, 125, 255', soft = '#2f7dff', pale = '#a8c8ff', deep = '#173f82' },
    { id = 'green',  label = 'Verde',    acc = '#12b981', rgb = '18, 185, 129', soft = '#12b981', pale = '#8fe6c8', deep = '#0b5e42' },
    { id = 'yellow', label = 'Amarillo', acc = '#e8b021', rgb = '232, 176, 33', soft = '#e8b021', pale = '#f6dc9c', deep = '#7a5b10' },
    { id = 'red',    label = 'Rojo',     acc = '#e4353f', rgb = '228, 53, 63',  soft = '#e4353f', pale = '#f4a3a8', deep = '#78191e' },
    { id = 'orange', label = 'Naranja',  acc = '#f2711c', rgb = '242, 113, 28', soft = '#f2711c', pale = '#fac093', deep = '#7d3a0d' },
}

--[[ La marca del servidor (`setr origen:marca "nacion"` en el cfg). En nacion
     el acento de la casa es naranja. Conserva el id `origen`, que es el que
     llevan guardado los telefonos: asi no hay que migrar nada.

     El movil va por aqui y NO por el repintado que usan las demas interfaces
     (trozo «ORIGEN · marca»): tocarle la hoja de estilos cuelga el navegador
     del juego (02/10). ]]
if GetConvar('origen:marca', 'origen') == 'nacion' then
    Config.Accents[1] = { id = 'origen', label = 'NACIÓN', acc = '#FD8A23', rgb = '253, 138, 35', soft = '#FFAA5C', pale = '#FFD9B6', deep = '#6A3402' }
    -- El fondo de la casa: la imagen ya sale en naranja (la interfaz elige
    -- origen-nacion.png con imagenDeMarca); aqui solo el nombre.
    Config.Wallpapers[1].label = 'NACIÓN'
end

--[[ PANEL DE ADMINISTRACION --------------------------------------------- ]]
--[[ PERMISOS DE APLICACIONES -------------------------------------------

     Que aplicacion tiene quien se decide desde el panel, no aqui: son reglas
     que un servidor quiere ir moviendo sin reiniciar. Lo unico que hace falta
     en el fichero son los dos nombres que usa el core para decir "este no tiene
     trabajo" y "este no esta en ninguna banda", porque cambian de un core a
     otro y sin ellos todo el mundo saldria como trabajador de algo. ]]
Config.AppRules = {}

--- Como se llama el trabajo de quien no tiene trabajo.
Config.AppRules.Unemployed = 'unemployed'

--- Y la banda de quien no esta en ninguna.
Config.AppRules.NoGang = 'none'

Config.Admin = {}

--- El comando que abre el panel.
Config.Admin.Command = 'telefonoadmin'

--[[ Quien puede abrirlo. Vale con cumplir uno.

     `ace`      permiso de FiveM. Con `add_ace group.admin ogphone.admin allow`
                en el cfg, todos los administradores lo tienen.
     `export`   un recurso al que preguntarle. Se le pasa el source y tiene que
                devolver true o false. Va dentro de pcall: si el recurso no
                esta, se pasa al siguiente sin romper nada.
     `licenses` lista de identificadores sueltos, para servidores sin nada de
                lo anterior. ]]
Config.Admin.Ace = 'ogphone.admin'
Config.Admin.Export = { resource = 'origen_admin', method = 'IsAdmin' }
Config.Admin.Licenses = {}

--[[ FACTURAS Y MULTAS ---------------------------------------------------
     Simbolo del dinero, para las dos aplicaciones y para los avisos. ]]
Config.Currency = '$'

--[[ Cuenta a la que va el dinero de las multas.

     Si se deja vacia, la multa se cobra al jugador y no se ingresa en ningun
     sitio, que es lo que quiere la mayoria de servidores. Poniendo aqui el
     IBAN o el identificador de la cuenta del ayuntamiento, el dinero acaba
     ahi. Quien emite la multa puede decir otra cuenta al crearla. ]]
Config.FineAccount = ''

--[[ VIAJES: TAXI Y GO ---------------------------------------------------

     Dos servicios sobre el mismo sistema. La diferencia esta aqui, no en el
     codigo: quien puede conducir y lo que cuesta el kilometro.

     El taxi sale a la mitad que GO a proposito. La idea es que coger un taxi
     compense, y que trabajar por libre se pague mejor por viaje pero tenga
     menos clientes. ]]
Config.Rides = {}

--- Distancia por debajo de la cual no se acepta un viaje (metros).
Config.Rides.MinDistance = 100

--- Lo que se le queda al conductor, en tanto por uno. El resto se pierde: es
--- lo que se lleva la plataforma, y da margen para ajustar la economia.
Config.Rides.DriverCut = 0.85

--- Minutos que un encargo espera sin que nadie lo coja antes de caducar.
Config.Rides.Timeout = 5

--[[ Minutos desde que el conductor acepta a partir de los cuales el pasajero
     puede cancelar un viaje con el pasajero ya dentro. Antes de eso solo lo
     cancela el conductor: si el pasajero pudiera siempre, cancelaria al
     llegar para no pagar. Si el conductor se va del servidor, puede
     cancelarlo al momento. ]]
Config.Rides.StuckMinutes = 30

--[[ Quien puede conducir cada servicio.

     Vale con cumplir uno de los dos requisitos, asi que se pueden poner los
     dos y funciona igual en un servidor con origen_businesses que en uno donde
     el taxi sea un trabajo del framework:

       businesses = nombres o tipos de negocio de origen_businesses en cuya
                    plantilla hay que estar
       jobs       = nombres de trabajo del framework (ESX, QBCore, Qbox)

     Ponlo a false y podra conducir cualquiera.

     Esto se comprueba cada vez, no solo al darse de alta: a quien le despidan
     deja de ver su perfil de conductor y pasa a ser un usuario mas, sin que
     haya que tocar la base de datos. ]]
Config.Rides.Taxi = {
    label = 'Taxi',
    -- En este servidor el taxi es un negocio de origen_businesses (tipo
    -- «taxi»): contratado y fichado ahí. El trabajo del core no cuenta.
    employer = {
        businesses = { 'taxi' },
    },
    base = 150,
    perKm = 45,
}

--[[ Carreras de NPC para el taxi.

     Hay pocas personas pidiendo taxi, y un taxista de servicio sin encargos
     no factura. Cuando hay taxistas libres y pocos encargos, sale uno de un
     vecino cualquiera: llega por la misma app, se acepta igual, el pasajero
     aparece en la acera, sube, se le lleva y se baja. Lo paga el vecino, asi
     que entra en la caja del negocio como un viaje normal.

     El servidor comprueba donde esta el taxista en cada paso (recogida y
     destino) y que no llegue mas rapido de lo posible: son dinero que sale de
     la nada y no pueden cobrarse pulsando botones desde casa. ]]
Config.Rides.TaxiNpc = {
    enabled = true,
    --- Cada cuantos segundos se mira si toca sacar una carrera.
    every = 45,
    --- Probabilidad de que salga, cada vez que se mira (0-1).
    chance = 0.6,
    --- Como mucho, encargos de NPC esperando a la vez por cada taxista libre.
    perDriver = 1,
    --- Y en total, aunque haya muchos taxistas.
    maxPending = 4,
    --- Recogida a menos de esto de algun taxista libre (metros), si se puede.
    nearDriver = 2500,
    --- Viaje entre estas distancias (metros).
    minTrip = 600,
    maxTrip = 4500,
    --- Radio alrededor del punto donde tiene que estar el taxi (metros).
    radius = 80.0,
    --- Velocidad media maxima creible del viaje (m/s; 30 = 108 km/h).
    maxSpeed = 30,
    --- Lo que paga un NPC respecto a la tarifa normal (1 = igual).
    fareFactor = 1.0,

    models = {
        'a_m_y_downtown_01', 'a_f_y_tourist_01', 'a_m_y_business_03',
        'a_f_y_business_04', 'a_m_m_socenlat_01', 'a_f_m_fatwhite_01',
        'a_m_y_hipster_01', 'a_f_y_hipster_02', 'a_m_m_business_01',
        'a_f_y_genhot_01', 'a_m_y_stbla_02', 'a_f_m_bevhills_01',
    },

    names = {
        'Marta Gil', 'Javier Soto', 'Lucia Ramos', 'Diego Navarro', 'Elena Vidal',
        'Pablo Ortega', 'Sara Molina', 'Hugo Castro', 'Irene Prieto', 'Mario Serrano',
        'Nuria Blanco', 'Adrian Rubio', 'Carla Mendez', 'Raul Iglesias', 'Alba Cano',
    },

    --- Lo que le dice al taxista al pedir. Vacio = sin nota.
    notes = {
        '', '', '', 'Voy con un poco de prisa, por favor.', 'Llevo una maleta.',
        'Estoy en la acera, junto a la parada.', 'Llamo desde el movil de un amigo.',
        'Si puede ser, sin musica alta.', 'Voy a una entrevista de trabajo.',
    },

    --[[ Donde piden y a donde van. Son puntos de calle: el pasajero aparece
         en la acera mas cercana a cada uno (GetSafeCoordForPed), asi que no
         hace falta clavarlos al metro. Los mismos que usaba la central vieja. ]]
    places = {
        { x = 257.61, y = -380.57, z = 44.71, label = 'Mission Row' },
        { x = -48.58, y = -790.12, z = 44.22, label = 'Strawberry' },
        { x = 240.06, y = -862.77, z = 29.73, label = 'Legion Square' },
        { x = 826.0, y = -1885.26, z = 29.32, label = 'Terminal' },
        { x = 350.84, y = -1974.13, z = 24.52, label = 'Rancho' },
        { x = -229.11, y = -2043.16, z = 27.75, label = 'Banning' },
        { x = -1053.23, y = -2716.20, z = 13.75, label = 'Aeropuerto' },
        { x = -774.04, y = -1277.25, z = 5.15, label = 'La Puerta' },
        { x = -1184.30, y = -1304.16, z = 5.24, label = 'Puerto' },
        { x = -1321.28, y = -833.80, z = 16.95, label = 'Del Perro' },
        { x = -1613.99, y = -1015.82, z = 13.12, label = 'Pacific Bluffs' },
        { x = -1392.74, y = -584.91, z = 30.24, label = 'Rockford Hills' },
        { x = -515.19, y = -260.29, z = 35.53, label = 'Morningwood' },
        { x = -760.84, y = -34.35, z = 37.83, label = 'Richman' },
        { x = -1284.06, y = 297.52, z = 64.93, label = 'Banham Canyon' },
        { x = -808.29, y = 828.88, z = 202.89, label = 'Vinewood Hills' },
        { x = -1074.39, y = -266.64, z = 37.75, label = 'Morningwood' },
        { x = -679.90, y = -845.01, z = 23.98, label = 'Little Seoul' },
        { x = -158.05, y = -1565.30, z = 35.06, label = 'Davis' },
        { x = 442.09, y = -1684.33, z = 29.25, label = 'Cypress Flats' },
        { x = 1120.73, y = -957.31, z = 47.43, label = 'El Burro Heights' },
        { x = 1238.85, y = -377.73, z = 69.03, label = 'Mirror Park' },
        { x = 922.24, y = -2224.03, z = 30.39, label = 'Puerto del Sol' },
        { x = 1920.93, y = 3703.85, z = 32.63, label = 'Sandy Shores' },
        { x = 1662.55, y = 4876.71, z = 42.05, label = 'Grapeseed' },
        { x = -9.51, y = 6529.67, z = 31.37, label = 'Paleto Bay' },
        { x = -3232.70, y = 1013.16, z = 12.09, label = 'Chumash' },
        { x = -1604.09, y = -401.66, z = 42.35, label = 'Rockford Hills' },
        { x = -586.48, y = -255.96, z = 35.91, label = 'Burton' },
        { x = 23.66, y = -60.23, z = 63.62, label = 'Hawick' },
        { x = 550.30, y = 172.55, z = 100.11, label = 'Vinewood' },
        { x = -1048.55, y = -2540.58, z = 13.69, label = 'Aeropuerto' },
        { x = -9.55, y = -544.00, z = 38.63, label = 'Alta' },
        { x = -7.86, y = -258.22, z = 46.90, label = 'West Vinewood' },
        { x = 220.64, y = -1010.81, z = 29.22, label = 'Legion Square' },
    },
}

Config.Rides.Go = {
    label = 'GO',
    -- Cualquiera que se registre como conductor: eso es lo que lo diferencia
    -- del taxi, y por eso se paga mejor el kilometro.
    employer = false,
    base = 300,
    perKm = 90,
}

--[[ MERCADO -----------------------------------------------------------
     Los anuncios que se pueden comprar. Lo que se vende sale del inventario
     de quien lo pone y llega al de quien lo compra, y lo lleva un repartidor
     de MANDAO. ]]
Config.Market = {}

--- Cuantas cosas distintas caben en un anuncio.
Config.Market.MaxItems = 6

--- Y cuantas unidades del lote se pueden poner a la venta.
Config.Market.MaxStock = 50

--[[ Lo que se lleva la plataforma de cada venta, en tanto por uno.

     Cero es un mercado gratis. Un pellizco pequeño saca dinero del servidor sin
     que a nadie le duela, que es justo lo que hace falta en una economia donde
     todo lo demas lo imprime. ]]
Config.Market.Commission = 0.05

--[[ Lo que NO se puede vender aqui.

     Los vehiculos no hace falta ponerlos: el mercado mueve lo que alguien lleva
     encima, y un coche del garaje no esta en ningun inventario. Esta lista es
     para lo que **si** cabe en una mochila y abriria la misma puerta por
     detras: llaves, documentacion, papeles de compraventa.

     Se compara por el nombre del objeto, tal cual lo llame el inventario. ]]
Config.Market.Blocked = {
    'vehiclekey', 'vehicle_key', 'carkeys', 'keys',
    'vehicledocs', 'vehicle_papers', 'documentacion_vehiculo',
}

--[[ MANDAO ------------------------------------------------------------
     La aplicacion de reparto: pedidos de mercancia de los negocios y envios
     entre personas. ]]
Config.Delivery = {}

--- Tarifa del reparto: una salida mas lo que marque la distancia.
Config.Delivery.Base = 200
Config.Delivery.PerKm = 60

--- Lo que se le queda al repartidor, en tanto por uno. El resto se pierde: es
--- lo que se lleva la plataforma, y da margen para ajustar la economia.
Config.Delivery.CourierCut = 0.85

--- Minutos que un encargo espera sin que nadie lo coja antes de caducar.
Config.Delivery.Timeout = 20

--[[ Minutos que tiene el repartidor para entregar un encargo que ya ha cogido.

     Sin este plazo, coger un encargo y no llevarlo lo dejaba abierto para
     siempre: el pedido del negocio no llegaba nunca y el repartidor se quedaba
     sin poder coger otro. Al vencer, la mercancia entra igual y quien lo cogio
     se lleva un aviso. ]]
Config.Delivery.Deadline = 10

--[[ Los avisos que se lleva quien deja un encargo tirado.

     `StrikeBans` son los minutos que no puede coger nada, uno por aviso; del
     ultimo en adelante se repite. `StrikeReset` son los minutos que tiene que
     pasar sin fallar para que se le olviden: quien reparte todos los dias
     acabaria con una sancion permanente por dos fallos en dos meses. ]]
Config.Delivery.StrikeBans = { 10, 30, 60 }
Config.Delivery.StrikeReset = 120

--- Distancia minima de un envio, en metros.
Config.Delivery.MinDistance = 150

--- A que distancia hay que estar para poder recoger o entregar, en metros.
Config.Delivery.Reach = 8.0

--- Cuantas cosas distintas caben en un envio entre personas.
Config.Delivery.MaxItems = 8

--[[ Quien puede repartir.

     Igual que en los viajes: vale con cumplir uno de los dos. Puesto a false,
     puede repartir cualquiera, que es lo normal en esta clase de aplicacion.
     Ver la seccion de viajes para el detalle de cada campo. ]]
Config.Delivery.Employer = false

--[[ De donde sale la mercancia de un pedido de negocio.

     El repartidor va al almacen mas cercano de esta lista, la recoge y la lleva
     al negocio. Si se deja vacia, el pedido se recoge en el propio negocio, que
     no tiene mucho sentido rolero pero deja la aplicacion funcionando en un
     servidor recien instalado. ]]
Config.Delivery.Depots = {
    { label = 'Almacen de mercancia · Muelle 1', x = 95.67,  y = -1746.8,  z = 28.7,  h = 140.88 },
    { label = 'Almacen de mercancia · Muelle 2', x = 99.68,  y = -1749.3,  z = 28.71, h = 139.86 },
    { label = 'Almacen de mercancia · Muelle 3', x = 103.73, y = -1751.94, z = 28.72, h = 139.62 },
}

--[[ Si los pedidos de los negocios pasan por el reparto.

     Con esto encendido, un pedido hecho desde el panel de un negocio deja de
     entregarse solo pasado un rato y espera a que alguien lo lleve. Apagado, la
     aplicacion sigue valiendo para los envios entre personas y los negocios
     siguen como antes. ]]
Config.Delivery.HandleBusinessOrders = true

--[[ Lo que paga el negocio por el reparto de su pedido.

     Va aparte del precio de la mercancia, que el negocio ya paga al hacer el
     pedido. Sale de la caja del negocio y acaba en el bolsillo del repartidor. ]]
Config.Delivery.BusinessFee = 450

--[[ OGN FANS ----------------------------------------------------------
     Fotos que se desbloquean pagando (18/09). Un creador publica una foto con
     precio; quien no la ha pagado la ve pixelada, y al pagarla se ve entera. ]]
Config.Fans = {}

--- Lo que se queda el servidor de cada venta y propina, de 0 a 1. OnlyFans se
--- queda un 20 %. Es dinero que sale de la economia: sin comision, dos amigos
--- pueden pasarse dinero sin rastro vendiendose fotos.
Config.Fans.Commission = 0.20

--- Precio de una foto. 0 es gratis (se ve entera sin pagar).
Config.Fans.MinPrice = 0
Config.Fans.MaxPrice = 50000

--- Propinas.
Config.Fans.MinTip = 10
Config.Fans.MaxTip = 100000

--- Cuantas publicaciones por pagina en el feed y en un perfil.
Config.Fans.PageSize = 20

--[[ De donde se dejan descargar fotos para hacer la version pixelada.

     El servidor descarga la foto elegida para que el telefono del creador
     pueda pixelarla: fivemanage no deja leer sus imagenes desde la pagina.
     Solo de estos dominios, para que nadie use el servidor para descargar
     cualquier direccion de internet (ni de la red de dentro). ]]
Config.Fans.ImageHosts = { 'fivemanage.com', 'fmfile.com' }

--- Tamaño maximo de la foto que se descarga para pixelar, en bytes.
Config.Fans.MaxImageBytes = 8 * 1024 * 1024

--[[ BEBOTEO -----------------------------------------------------------
     La aplicacion de conocer gente. ]]
Config.Dating = {}

--- Cuantos "me gusta" al dia puede dar quien no es VIP. El limite es lo que
--- hace que un "me gusta" signifique algo; sin el, todo el mundo le da a todo.
Config.Dating.DailyLikes = 20

--- Cuantas fotos caben en un perfil.
Config.Dating.MaxPhotos = 6

--- El VIP: quita el limite diario y deja ver quien te ha dado "me gusta".
Config.Dating.VipPrice = 5000
Config.Dating.VipDays = 30
Config.Dating.VipLabel = 'BEBOTEO VIP'

--[[ Los generos que se pueden elegir.

     La clave es lo que se guarda y lo que se compara; el valor es la clave de
     texto con la que se enseña. Un servidor puede añadir los suyos aqui y en
     los ficheros de idioma, sin tocar la base de datos. ]]
Config.Dating.Genders = {
    hombre = 'dating_gender_male',
    mujer = 'dating_gender_female',
    otro = 'dating_gender_other',
}

--[[ CORREO --------------------------------------------------------------
     El dominio de las direcciones del servidor. La parte de delante la elige
     cada jugador la primera vez que abre la aplicacion. ]]
Config.Mail = {}
Config.Mail.Domain = 'ogn.net'
Config.Mail.MaxLength = 4000        -- caracteres por correo
Config.Mail.MaxRecipients = 10      -- destinatarios por envio
Config.Mail.MaxAttachments = 6      -- adjuntos por correo (son enlaces, no ficheros)

--[[ IDIOMA -------------------------------------------------------------- ]]
Config.DefaultLanguage = 'es'
--[[ Idiomas disponibles.

     Cada uno necesita su locales/<codigo>.json. Los que vienen con el recurso
     estan completos; para anadir otro basta con copiar en.json, traducirlo y
     meter su codigo en esta lista.

     Con un solo idioma la interfaz se salta el paso de elegirlo en la
     configuracion inicial y esconde el ajuste: un selector con una sola
     opcion no es un selector. ]]
Config.Languages = { 'es', 'en', 'fr', 'de', 'pt' }

--[[ Como se escriben las fechas y los numeros.

     Sale del idioma de cada telefono, no del servidor: en un aleman las fechas
     tienen que salir en aleman, no en el idioma que haya puesto el dueño del
     servidor. Lo de abajo es solo el respaldo para un idioma que se añada y no
     este en esta tabla. ]]
Config.DateLocales = {
    es = 'es-ES',
    en = 'en-GB',
    fr = 'fr-FR',
    de = 'de-DE',
    pt = 'pt-PT',
}

Config.DateLocale = 'es-ES'

--[[ STICKERS -------------------------------------------------------------
     Packs que trae el servidor de serie. Se siembran en la base de datos al
     arrancar (por slug, asi que se puede reordenar sin duplicar). Las urls
     pueden ser externas o del propio recurso: `nui://origen_phone/ui/...`.
     Los packs de jugador se crean desde la galeria y no van aqui. ]]
Config.StickerPacks = {
    {
        slug = 'caras',
        title = 'Caras',
        cover = nil,
        stickers = {
            { emoji = '😀' }, { emoji = '😂' }, { emoji = '🥲' }, { emoji = '😍' },
            { emoji = '😎' }, { emoji = '🤨' }, { emoji = '😴' }, { emoji = '🤒' },
            { emoji = '🤯' }, { emoji = '😱' }, { emoji = '😡' }, { emoji = '🥶' },
            { emoji = '🤝' }, { emoji = '👍' }, { emoji = '👎' }, { emoji = '🙏' },
            { emoji = '💪' }, { emoji = '👀' }, { emoji = '🫡' }, { emoji = '🤙' },
        },
    },
    {
        slug = 'ciudad',
        title = 'Ciudad',
        cover = nil,
        stickers = {
            { emoji = '🚗' }, { emoji = '🏍️' }, { emoji = '🚓' }, { emoji = '🚑' },
            { emoji = '🚁' }, { emoji = '⛽' }, { emoji = '🔧' }, { emoji = '🏁' },
            { emoji = '💸' }, { emoji = '💊' }, { emoji = '🔫' }, { emoji = '🚬' },
            { emoji = '🍔' }, { emoji = '🍺' }, { emoji = '☕' }, { emoji = '🎰' },
            { emoji = '📍' }, { emoji = '⏰' }, { emoji = '🔑' }, { emoji = '🚨' },
        },
    },
    {
        slug = 'reacciones',
        title = 'Reacciones',
        cover = nil,
        stickers = {
            { emoji = '❤️' }, { emoji = '💔' }, { emoji = '🔥' }, { emoji = '💯' },
            { emoji = '✅' }, { emoji = '❌' }, { emoji = '⚠️' }, { emoji = '❓' },
            { emoji = '🎉' }, { emoji = '🎁' }, { emoji = '⭐' }, { emoji = '💤' },
        },
    },
}

--[[ MUSICA ---------------------------------------------------------------
     Emisoras que salen en la aplicacion. La url tiene que ser un flujo que el
     navegador sepa reproducir (mp3, aac o un m3u8 de audio). Suena solo para
     quien la pone: para que la oigan los de alrededor hace falta un recurso de
     audio en 3D, y eso se enchufa aparte. ]]
Config.Music = {}
Config.Music.Stations = {
    -- { id = 'ogn', name = 'Radio OGN', genre = 'Variado', url = 'https://...' },
}
Config.Music.AllowCustomUrl = true   -- permitir pegar una url a mano

--[[ TONOS -----------------------------------------------------------------
     Los tonos son sonidos del propio juego, no ficheros. Es a proposito: un
     recurso que arrastra mp3 pesa mas, tarda mas en descargar al entrar y hay
     que servirlo; los sonidos nativos ya estan en la maquina de todo el mundo.

     Cada entrada es un par de la libreria de audio de GTA: {sonido, conjunto}.
     Para probar otros, la lista esta en cualquier tabla de audio de GTA V. ]]
Config.Sounds = {}

--[[ Los tonos del telefono.

     Son ficheros propios, en `ui/sounds/`, y los suena la interfaz.

     ANTES ERAN SONIDOS DEL JUEGO y eso tenia dos problemas. El primero, que
     solo se podia elegir entre los pitidos que trae GTA, y ninguno se oye como
     un telefono. El segundo, peor: un sonido lanzado con `PlaySoundFrontend` e
     id -1 NO HAY FORMA DE CALLARLO, asi que la muestra de los ajustes se
     quedaba sonando para siempre por debajo del tono de llamada.

     Un fichero se para, y punto.

     Para añadir uno: dejarlo en `source-ui/public/sounds/` y ponerlo aqui. El
     `file` es el nombre tal cual; el `id` es lo que se guarda en los ajustes de
     cada jugador, asi que **no se cambia** una vez publicado o quien lo tuviera
     elegido se queda con el primero de la lista.

     Y suenan con el telefono guardado: la interfaz esta cargada aunque no se
     vea, asi que el audio va igual. ]]
Config.Sounds.Ringtones = {
    { id = 'ring1', label = 'Tono 1', file = 'Ringtone1.mp3' },
    { id = 'ring2', label = 'Tono 2', file = 'Ringtone2.mp3' },
    { id = 'ring3', label = 'Tono 3', file = 'Ringtone3.mp3' },
    { id = 'ring4', label = 'Tono 4', file = 'Ringtone4.mp3' },
    { id = 'ring5', label = 'Tono 5', file = 'Ringtone5.mp3' },
    { id = 'ring6', label = 'Tono 6', file = 'Ringtone6.mp3' },
}

--[[ El tono de "llamando", el que oye quien llama.

     Es el mismo para todos: no es algo que se elija, es como suena la linea.
     Sigue siendo del juego porque para esto el `Remote_Ring` de GTA es
     exactamente lo que hay que oir, y ademas no se elige, asi que no puede
     quedarse colgado por la muestra de nadie. ]]
Config.Sounds.Ringback = {
    sound = 'Remote_Ring', set = 'Phone_SoundSet_Michael', loops = true,
}

--- El clic de colgar. Un golpe corto: se va solo.
Config.Sounds.Hangup = {
    sound = 'Hang_Up', set = 'Phone_SoundSet_Michael',
}

--- Los avisos. El de serie es el primero.
Config.Sounds.Alerts = {
    { id = 'aviso1', label = 'Aviso 1', file = 'Notificacion1.mp3' },
    { id = 'aviso2', label = 'Aviso 2', file = 'Notificacion2.mp3' },
    { id = 'aviso3', label = 'Aviso 3', file = 'Notificacion3.mp3' },
    { id = 'aviso4', label = 'Aviso 4', file = 'Notificacion4.mp3' },
    { id = 'aviso5', label = 'Aviso 5', file = 'Notificacion5.mp3' },
    { id = 'silent', label = 'Sin tono', file = false },
}

--[[ LOS AVISOS DEL PROPIO SERVIDOR ---------------------------------------

     Lo que sale arriba en el medio —lo de `origen_notify`— sale tambien en el
     telefono, con el titulo del servidor y su icono, para que se sepa de un
     vistazo que eso no lo manda una persona: lo manda la ciudad.

     No se guardan en el centro de notificaciones ni cuentan como no leidas: son
     un eco del aviso que ya has visto, y guardar cada "has cobrado 40" llenaria
     el telefono de ruido en media hora.

     Los de ayuda —el "pulsa E para interactuar"— no entran: van por otro camino
     y en el telefono no pintan nada. ]]
Config.ServerNotifications = {}

--[[ Si los avisos del servidor salen tambien en el telefono. APAGADO.

     Decision del 8 de septiembre de 2026: los avisos del servidor salen SIEMPRE
     arriba, como tarjeta de origen_notify, se lleve telefono o no.

     El motivo es que con esto encendido el mismo aviso salia en un sitio o en
     otro segun llevaras el movil encima. Eso hace que el jugador no sepa donde
     mirar: aprender que "los avisos salen ahi" es lo que hace que se lean, y
     un sitio que cambia solo no se aprende.

     Lo de abajo --Replace, Sound, Types, Cooldown-- se queda escrito y sin
     efecto: si algun dia se vuelve a encender esto, el ajuste fino ya esta. ]]
Config.ServerNotifications.Enabled = false

--[[ Si el aviso SE MUEVE al telefono o SE COPIA.

     Movido —lo de serie—: sale solo en el telefono y ya no arriba en el medio.
     Copiado: sale en los dos sitios, que es como se ve dos veces lo mismo.

     Y esto no deja a nadie sin avisos: si no llevas telefono encima, o si el
     tipo de aviso no entra, el de arriba sale igual que siempre. Solo se calla
     cuando el telefono ha dicho que se hace cargo. ]]
Config.ServerNotifications.Replace = true

--[[ Si suenan.

     Movidos al telefono, el tono del movil es el unico que va a sonar, asi que
     esto tiene mas sentido encendido que cuando salian en los dos sitios. Sigue
     apagado de serie porque de estos pasan decenas por sesion y un tono cada
     vez cansa. ]]
Config.ServerNotifications.Sound = false

--[[ Que tipos salen. Sin poner, o vacio, salen todos.

     Para dejar fuera los que mas se repiten:
         Config.ServerNotifications.Types = { error = true, primary = true }
     con eso se quedan fuera los 'success' de cobrar dinero. ]]
Config.ServerNotifications.Types = nil

--- El mismo texto dos veces seguidas antes de estos milisegundos, no se repite.
Config.ServerNotifications.Cooldown = 1500

--[[ ANUNCIOS -------------------------------------------------------------
     El tablon del servidor: se compra, se vende y se ofrecen servicios. ]]
--- Nombre de la compania que sale en la barra de estado. Es decorado, pero
--- "UKNOWN" en pantalla se lee como un fallo del recurso.
Config.Carrier = 'OGN MOVIL'

--[[ AGENDA -----------------------------------------------------------------
     Dar tu numero a alguien que tienes al lado. El alcance se mide en metros
     desde el ped, en el servidor. Cinco metros es hablar cara a cara. ]]
--[[ ALARMAS ----------------------------------------------------------------
     Suenan con la hora del juego. Las vigila el cliente, que es quien tiene el
     reloj delante, tambien con el telefono cerrado. ]]
--[[ BUZON DE VOZ -----------------------------------------------------------
     Solo se puede dejar un mensaje despues de llamar y que no te cojan, y
     dentro de un rato: es un buzon, no una forma de mandar audios a
     desconocidos. ]]
Config.Voicemail = {}
Config.Voicemail.Window = 120      -- segundos desde la llamada para poder dejarlo
Config.Voicemail.MaxSeconds = 30   -- lo que puede durar la grabacion

Config.Alarms = {}
Config.Alarms.Max = 10            -- alarmas por telefono
Config.Alarms.RingSeconds = 30    -- lo que suena antes de callarse sola

Config.Contacts = {}
Config.Contacts.ShareRange = 5.0

--[[ NOTICIAS ------------------------------------------------------------

     Quien puede escribir en el periodico desde el propio telefono.

     Antes solo se podia publicar desde fuera, con el export `PublishNews`, asi
     que la prensa del rol necesitaba a un administrador para sacar cada
     articulo. Con esto, quien tenga el trabajo lo escribe y lo publica el.

     Se cumple con UNA de las dos cosas: estar en la plantilla de uno de esos
     negocios de `origen_businesses`, o llevar uno de esos trabajos del
     framework. A `false` se apaga y se vuelve a publicar solo desde fuera. ]]
Config.News = {}
Config.News.Publishers = {
    businesses = { 'weazel', 'weazelnews', 'cnt' },
    jobs = { 'reporter', 'weazel', 'weazelnews', 'cnt' },
    error = 'err_news_need_job',
}

--- Cuantas noticias puede sacar el mismo telefono al dia. 0 = sin tope.
Config.News.MaxPerDay = 6

Config.Ads = {}
Config.Ads.Days = 7               -- lo que dura un anuncio antes de caducar
Config.Ads.MaxPerPhone = 5        -- anuncios a la vez por telefono
Config.Ads.Cost = 0               -- lo que cuesta publicar (0 = gratis)
Config.Ads.Categories = {
    { id = 'venta',     label = 'Se vende' },
    { id = 'compra',    label = 'Se compra' },
    { id = 'servicios', label = 'Servicios' },
    { id = 'empleo',    label = 'Empleo' },
    { id = 'vivienda',  label = 'Vivienda' },
    { id = 'general',   label = 'General' },
}

--[[ SERVICIOS DE EMERGENCIA ----------------------------------------------
     Avisar desde el telefono manda la alerta al despacho de origen_police con
     la posicion de quien llama. `job` es la categoria de origen_police. ]]
Config.Services = {}
Config.Services.Cooldown = 60     -- segundos entre avisos del mismo telefono
Config.Services.List = {
    {
        id = 'police',
        label = 'Policia',
        description = 'Robos y peleas',
        icon = 'lucide:shield',
        job = 'police',
        alertTitle = 'Aviso ciudadano',
    },
    {
        id = 'ambulance',
        label = 'Emergencias medicas',
        description = 'Heridos y accidentes',
        icon = 'lucide:cross',
        job = 'ambulance',
        alertTitle = 'Aviso medico',
    },
    {
        id = 'doj',
        label = 'Departamento de Justicia',
        description = 'Asistencia judicial y legal',
        icon = 'lucide:scale',
        job = 'doj',
        alertTitle = 'Aviso judicial',
    },
}

--[[ Aqui habia un tercer servicio, «Grua y mecanico», que mandaba el aviso al
     despacho de origen_police con `job = 'mechanic'`.

     Esa categoria NO existe en origen_police (config/jobs.lua solo tiene
     police, ambulance, saspa y fib): el despacho repartia el aviso a cero
     jugadores y el ciudadano veia igualmente «aviso enviado». Por eso los
     mecanicos se habian quedado sin avisos.

     Los talleres de este servidor son NEGOCIOS de origen_businesses, no un
     trabajo del framework, asi que ahora salen en la aplicacion como locales
     —con su grua, su mecanico a domicilio y lo que cada uno encienda— y el
     aviso va a la central de ese negocio (server/api/services.lua). Esta lista
     se queda solo para lo que de verdad es una emergencia. ]]

--[[ BANCO -----------------------------------------------------------------
     Se apoya en origen_banking. Si ese recurso no esta, la app no aparece. ]]
Config.Bank = {}
Config.Bank.MaxTransfer = 500000  -- tope por transferencia desde el telefono

--[[ Y cuanto se puede mover en total.

     El tope por envio solo no sirve de nada: quien quiera mover un millon hace
     dos envios de medio. Estos son los que de verdad limitan, y son los que
     hacen que un exploit encontrado a las tres de la mañana no vacie la economia
     antes de que nadie se entere.

     Cero quita el tope. ]]
Config.Bank.MaxDaily = 2000000
Config.Bank.MaxWeekly = 8000000

--[[ DEPARTAMENTO DE JUSTICIA (DOJ) ---------------------------------------
     Directorio de abogados de guardia / servicio para contactar por llamada
     o mensaje desde la aplicación móvil de Justicia. ]]
Config.DOJ = {
    Job = 'doj',                  -- Job en el core
    RequireDuty = true,           -- Solo mostrar a los que estén de servicio (onduty = true)

    -- Grados autorizados para aparecer en la lista de abogados:
    -- Puede ser una lista con los números de rango exactos ej: { 1, 2, 3 }
    -- (Grado 1 = Abogado Junior, Grado 2 = Abogado Senior, Grado 3 = Director de Buffet)
    -- Si se deja en nil o vacía {}, se mostrarán todos los que tengan grado >= MinGrade.
    AllowedGrades = { 1, 2, 3 },
    MinGrade = 1,                 -- Grado mínimo por si AllowedGrades es nil

    -- Configuración visual y textos
    AppTitle = 'Departamento de Justicia',
    AppSubtitle = 'Colegio de Abogados del Estado',
}
