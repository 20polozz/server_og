--[[ ═══════════════════════════════════════════════════════════════════════
     origen_map — el minimapa de GTA, hecho con Leaflet

     Este ES el minimapa. El de GTA queda empujado fuera de la pantalla y este
     sale solo al entrar.

     Nacio como prototipo para medir si el rendimiento aguantaba, porque un
     mapa en el menu de pausa esta unos segundos en pantalla y un minimapa esta
     SIEMPRE. La medida se hizo dentro del juego y salio que no cuesta nada
     (229 fps con el puesto), asi que se queda. El contador sigue ahi, y /mapa
     lo sigue apagando y encendiendo, para poder repetir la medida cuando se le
     añada algo.

     El minimapa de GTA se aparta, NO se apaga: DisplayRadar(false) haria que
     el juego dejara de calcular la ruta del GPS, y esa ruta es justo lo que
     este mapa pinta. Sigue vivo fuera de la pantalla y solo se le aprovecha la
     cuenta.

     El marco y el rotulo de la calle los sigue pintando origen_hud: lo que va
     dentro de ese marco somos nosotros, con sus mismas medidas.

     Lo dificil ya estaba resuelto en la casa y aqui solo se reutiliza:

       - pasar de coordenadas del mundo a coordenadas del mapa, con la misma
         transformacion que el mapa del menu de pausa (origen_pausemenu);

       - leer la ruta POR CARRETERA con GetPosAlongGpsTypeRoute, la tecnica de
         origen_pausemenu/client/mapa.lua y origen_racing/client/gps3d.lua. No
         es una ruta inventada por nosotros: es la que calcula el juego.

     Comandos:
       /mapa            enciende y apaga el mapa de Leaflet
       /mapavanilla     enseña u oculta el minimapa de GTA (para comparar)
       /mapahz <n>      cuantas posiciones por segundo se mandan
       /mapafps         escupe la medida por consola
   ═══════════════════════════════════════════════════════════════════════ ]]

local Config = {
    --[[ Ya no se decide aqui. Cuando se ve el mapa es un ajuste del jugador
         —"cuando", mas abajo, de fabrica en "solo en vehiculo"— y quien lo
         aplica es Repasar(). Se deja escrito para que nadie vuelva a buscar
         aqui el interruptor. ]]

    -- Posiciones por segundo. Con 15 el giro se veia a tirones: el JS
    -- interpola entre las que llegan, pero cuanto mas separadas estan, mas
    -- tarda en enterarse de que has empezado a girar. A 30 el retraso baja a
    -- 33 ms y deja de notarse. Medido en el juego: el mapa encendido no movia
    -- los fps (229 con el puesto), asi que hay sitio de sobra.
    hz = 30,

    -- Cada cuanto se rehace la ruta del GPS. Es lo caro de todo esto: una ruta
    -- larga son cientos de llamadas al native, asi que no puede ir por
    -- fotograma.
    --
    -- Un segundo y no dos: el trazado empieza DONDE ESTAS, y a 100 km/h en dos
    -- segundos recorres 55 metros -- los suficientes para ver que la linea
    -- arranca por detras del coche. A un segundo eso se parte por la mitad y
    -- deja de notarse.
    --
    -- Medio segundo desde el 04/10: a un segundo, saltarse un giro tardaba
    -- demasiado en verse. El hilo da una vuelta cada 500 ms, asi que con 450
    -- se lee en todas. Lo que queda entre lectura y lectura lo recorta el
    -- propio mapa (mapa.js, recortarRuta), que sabe donde estas a cada
    -- fotograma.
    rutaCadaMs = 450,

    --[[ Cuando la linea se queda en el camino viejo.

         El juego rehace la ruta solo cuando quiere, y a veces tarda: te saltas
         un giro y la raya sigue por la calle que has dejado atras. Si vas por
         carretera y la ruta empieza a mas de `desvioMetros` de ti durante
         `desvioLecturas` lecturas seguidas, se le pide que la calcule de nuevo.
         No mas de una vez cada `desvioCadaMs`: recalcular deja al juego uno o
         dos segundos sin ruta, y pedirselo sin parar seria no tenerla nunca. ]]
    desvioMetros = 35.0,
    desvioLecturas = 3,
    desvioCadaMs = 5000,

    --[[ La ruta se muestrea en DOS tramos, con dos pasos distintos.

         Cortarla a 600 m fue un error: en un minimapa se ven unos 340 metros a
         la esquina, pero al girar el mapa esa esquina barre mas lejos, y se
         llegaba a ver el punto donde la ruta simplemente se acababa en mitad
         de la nada. Una ruta que se corta sola es peor que ninguna.

         Y muestrearla entera a 6 m serian 1.500 preguntas al native cada
         segundo. La salida es que la finura solo hace falta donde se ve:

           - los primeros 300 m, cada 6 m. Hay 0,44 pixeles por metro, asi que
             son tramos de 2,6 px: una curva de verdad.
           - de ahi al final, cada 30 m. Eso cae fuera de la caja casi siempre,
             y cuando asoma al girar es un trozo lejano donde nadie mira si la
             curva es fina.

         Unas 340 preguntas para una ruta de 9 km, lo mismo que costaba antes a
         25 m fijos, pero con la parte que se mira cuatro veces mas fina. ]]
    pasoRutaFino = 6.0,
    pasoRutaLejos = 30.0,
    metrosFinos = 300.0,
    topePuntos = 420,
    maxMetros = 9000.0,

    -- El rastro de por donde has pasado: cuantos puntos se guardan y cada
    -- cuantos metros se apunta uno.
    rastroPuntos = 400,
    rastroCadaM = 8.0,

    -- Los blips del mundo. Solo los de alrededor: un minimapa enseña un par de
    -- manzanas, y mandar los de toda la ciudad seria pintar cientos de marcas
    -- fuera de la caja para que el navegador las recorte.
    blipsRadio = 420.0,
    blipsCadaMs = 700,
    blipsTope = 70,
}

--[[ ══ Los blips del mundo ═══════════════════════════════════════════════

     Las mismas categorias y los mismos sprites que el mapa del menu de pausa
     (origen_pausemenu/client/mapa.lua): asi los dos mapas enseñan lo mismo y
     una categoria nueva se añade en los dos sitios igual.

     Se pregunta por sprite porque no hay ningun native que diga "dame todos
     los blips": GetFirstBlipInfoId/GetNextBlipInfoId van por tipo. ]]
local CATEGORIAS = {
    { id = 'garages',    icono = 'coche',    sprites = { 357, 524, 400, 350, 624 } },
    { id = 'banking',    icono = 'dinero',   sprites = { 108, 277, 278, 431, 434 } },
    { id = 'shops',      icono = 'cesta',    sprites = { 52, 59, 133, 361, 403, 605 } },
    { id = 'public',     icono = 'edificio', sprites = { 60, 61, 489, 490, 567, 419, 351 } },
    { id = 'housing',    icono = 'casa',     sprites = { 40, 374, 375, 492, 411 } },
    { id = 'illegal',    icono = 'calavera', sprites = { 84, 310, 496, 501, 514 } },
    { id = 'racing',     icono = 'bandera',  sprites = { 315 } },
    { id = 'activities', icono = 'ocio',     sprites = { 73, 75, 71, 106, 266, 311, 480, 614 } },
    -- Las tiendas de mascotas (origen_pets) usan el sprite 442.
    { id = 'mascotas',   icono = 'huella',   sprites = { 442 } },

}

--[[ ── Lo de origen_police ───────────────────────────────────────────────

     Los avisos y las referencias de las unidades no entran por el barrido de
     sprites de arriba, y no es un descuido: ese barrido tiene radio (420 m) y
     tope (70 marcas), que es lo correcto para gasolineras y garajes y lo
     contrario de lo que hace falta aqui. Un aviso al otro lado de la ciudad
     importa mas que la tienda de la esquina, y una unidad que se va lejos no
     puede desaparecer del mapa por alejarse.

     Asi que se piden aparte, sin radio ni tope, a los dos exports que
     origen_police pone para esto. Los dos mapas —este y el del menu de pausa—
     preguntan igual, para que enseñen lo mismo. ]]
local POLICIA = {
    { export = 'AvisosParaMapa',      id = 'aviso',      icono = 'sirena' },
    { export = 'ReferenciasParaMapa', id = 'referencia', icono = 'escudo' },
}

local function PuntosDeAvisos()
    if GetResourceState('origen_police') ~= 'started' then return nil end

    local puntos = {}

    -- Avisos (911 / emergencias estáticas)
    local okAvisos, avisos = pcall(function()
        return exports.origen_police:AvisosParaMapa()
    end)
    if okAvisos and type(avisos) == 'table' then
        for _, p in ipairs(avisos) do
            if p.x and p.y then
                puntos[#puntos + 1] = {
                    x = p.x,
                    y = p.y,
                    cat = 'aviso',
                    icono = 'sirena',
                    color = '#ff3355'
                }
            end
        end
    end

    return puntos
end

local function ReferenciasDePolicia(yo)
    if GetResourceState('origen_police') ~= 'started' then return nil, nil end

    local puntos = {}
    local distMin = nil

    local okRefs, refs = pcall(function()
        return exports.origen_police:ReferenciasParaMapa()
    end)
    if okRefs and type(refs) == 'table' then
        for _, p in ipairs(refs) do
            if p.x and p.y then
                local dx, dy = p.x - yo.x, p.y - yo.y
                local d = math.sqrt(dx * dx + dy * dy)
                if not distMin or d < distMin then
                    distMin = d
                end

                puntos[#puntos + 1] = {
                    x = math.floor(p.x * 10) / 10,
                    y = math.floor(p.y * 10) / 10,
                    dist = math.floor(d),
                    nombre = p.etiqueta or false,
                    color = p.hex or '#2f6bff',
                    spriteUrl = p.url or false,
                    sprite = p.sprite or false,
                    source = p.source or false,
                }
            end
        end
    end

    return puntos, distMin
end

local encendido = false
local vanillaVisible = true
local rutaUltima = 0

--- La ultima linea buena y cuando se leyo, para tapar los huecos del recalculo.
local rutaUltimosPuntos, rutaUltimosCuando, rutaUltimosSlot, rutaUltimosConDestino = nil, 0, nil, false
local rastro = {}
local ultimoRastro = nil

--[[ ── La ruta del GPS ──────────────────────────────────────────────────

     GTA solo calcula la ruta cuando el radar esta ENCENDIDO: la ruta es una
     cosa del minimapa, no del mundo. Por eso este prototipo NO apaga el radar
     con DisplayRadar(false) aunque lo tape: si lo apagara se quedaria sin ruta
     que leer, que es justo lo que queremos enseñar.

     "Ocultarlo" aqui es empujarlo fuera de la pantalla, no apagarlo. ]]

local SLOTS = { 0, 1, 2 }

local function Pedir(desdeJugador, metros, slot)
    if type(GetPosAlongGpsTypeRoute) ~= 'function' then return nil end

    --[[ Tres valores y no dos, y aqui esta el detalle que lo rompia:

         GetPosAlongGpsTypeRoute devuelve DOS cosas -- un booleano de si ha
         encontrado punto y, DETRAS, la posicion (por eso el menu de pausa
         escribe "local _, pos = ..."). Y pcall pone ademas su propio "ha ido
         bien" el primero.

         Cogiendo solo dos valores, lo que caia en "pos" era el booleano. De
         ahi que aqui no hubiera ruta nunca aunque estuviera puesta. ]]
    local ok, _, pos = pcall(GetPosAlongGpsTypeRoute, desdeJugador, metros, slot)
    if not ok or not pos then return nil end
    if pos.x == nil or (pos.x == 0.0 and pos.y == 0.0) then return nil end
    return pos
end

--[[ Que slot tiene ruta ahora mismo. Una ruta puesta por otro recurso puede
     vivir en un slot distinto al del waypoint del jugador, asi que se prueban.

     Se pregunta por el metro 20 y no por el cero (17/09): desde el jugador, el
     metro cero es el jugador mismo y contesta aunque NO haya ruta, asi que el
     slot 0 salia siempre "activo" y la ruta de un trabajo (slot 1) no llegaba
     nunca al minimapa aunque el mapa grande si la enseñara. Es la misma
     comprobacion que hace el mapa grande (origen_inventory, f_origen_mapa.lua).

     `primero` es el slot que corresponde al destino que se enseña: el del
     waypoint (0) si lo hay, y si no el de los blips (1). Asi la linea y la
     chincheta van al mismo sitio. ]]
local function SlotActivo(primero, sinWaypoint)
    if primero and Pedir(true, 20.0, primero) then return primero end
    for _, s in ipairs(SLOTS) do
        --[[ Sin waypoint, el slot 0 no se mira (04/10): es el suyo, y al
             quitar el punto el juego puede tardar en vaciarlo —o no vaciarlo
             nunca, si el radar se apaga justo despues, que es lo que pasa a
             pie—. De ahi que la raya se quedara pintada con la ruta quitada. ]]
        if s ~= primero and not (sinWaypoint and s == 0) and Pedir(true, 20.0, s) then return s end
    end
    return nil
end

--[[ El camino entero, andandolo de 25 en 25 metros.

     El final no se pregunta, se descubre: pasado el ultimo metro el native se
     queda clavado en el mismo punto y sigue contestando lo mismo. Tres
     respuestas iguales seguidas es el final. Preguntar cuanto mide la ruta no
     sirve: GetGpsBlipRouteLength devuelve 0 para la ruta de un waypoint. ]]
local function TrazadoDelGps(primero, sinWaypoint)
    local slot = SlotActivo(primero, sinWaypoint)
    if not slot then return nil end

    local puntos, ultimo, quietos = {}, nil, 0
    local d = 0.0

    while d <= Config.maxMetros and #puntos < Config.topePuntos do
        local pos = Pedir(true, d, slot)
        if not pos then break end

        if ultimo then
            local avance = math.sqrt((pos.x - ultimo.x) ^ 2 + (pos.y - ultimo.y) ^ 2)
            if avance < 0.1 then
                quietos = quietos + 1
                if quietos >= 3 then break end
            else
                quietos = 0
                puntos[#puntos + 1] = {
                    math.floor(pos.x * 10) / 10,
                    math.floor(pos.y * 10) / 10,
                }
            end
        else
            puntos[#puntos + 1] = {
                math.floor(pos.x * 10) / 10,
                math.floor(pos.y * 10) / 10,
            }
        end

        ultimo = pos
        -- Fino mientras se ve, y a zancadas cuando ya no.
        d = d + (d < Config.metrosFinos and Config.pasoRutaFino or Config.pasoRutaLejos)
    end

    if #puntos < 2 then return nil end
    return puntos, slot
end

--[[ ── El minimapa de GTA ───────────────────────────────────────────────

     Se empuja fuera de la pantalla en vez de apagarse, para que el juego siga
     calculando la ruta. origen_hud coloca el minimapa solo cuando cambia la
     resolucion, no por fotograma, asi que no hay pelea: basta con volver a
     ponerlo donde queremos de vez en cuando. ]]
local COMPONENTES = { 'minimap', 'minimap_mask', 'minimap_blur' }

local function ColocarVanilla(visible)
    if visible then
        -- Los mismos valores con los que origen_hud lo deja al pararse.
        SetMinimapComponentPosition('minimap', 'L', 'B', -0.0045, 0.002, 0.150, 0.188888)
        SetMinimapComponentPosition('minimap_mask', 'L', 'B', 0.020, 0.032, 0.111, 0.159)
        SetMinimapComponentPosition('minimap_blur', 'L', 'B', -0.03, 0.022, 0.266, 0.237)
        return
    end

    -- Fuera de la pantalla por la izquierda. Sigue vivo y sigue calculando.
    for _, c in ipairs(COMPONENTES) do
        SetMinimapComponentPosition(c, 'L', 'B', -2.0, 0.0, 0.150, 0.188888)
    end
end

--[[ ── La calle y el rumbo ─────────────────────────────────────────────

     Se calculan aqui y no se le piden a origen_hud a proposito: son cuatro
     natives, y depender de otro recurso para esto significaria que el dia que
     alguien toque su HUD, este mapa se queda mudo sin que nadie relacione una
     cosa con la otra.

     Los mismos nombres de cardinal que usa el HUD (client/player.lua), para
     que nadie oiga "noreste" en un sitio y "NE" en otro. ]]
local RUMBOS = {
    'Norte', 'Noroeste', 'Oeste', 'Suroeste',
    'Sur', 'Sureste', 'Este', 'Noreste',
}

local function CardinalDe(h)
    -- Ocho sectores de 45 grados, con el norte a caballo del 0: por eso el
    -- +22.5 antes de dividir, para que el sector 0 vaya de 337.5 a 22.5.
    return RUMBOS[(math.floor(((h % 360) + 22.5) / 45) % 8) + 1]
end

--[[ La calle en la que estas. SOLO ESA.

     Antes se pegaba la que cruza detras con un "&", y eso no cabe en un
     minimapa: "North Rockford Drive & South Rockford Drive" salia cortado con
     puntos suspensivos, que no dice nada. Un cruce ya se ve dibujado; lo que
     el rotulo tiene que decir es por donde vas. ]]
local function CalleDe(c)
    return GetStreetNameFromHashKey((GetStreetNameAtCoord(c.x, c.y, c.z)))
end

--[[ El barrio, que es lo que de verdad situa.

     "Rockford Hills" te coloca en la ciudad; "North Rockford Drive" solo te
     coloca si ya sabes donde esta esa calle. Va de antetitulo, como en el resto
     de las pantallas del servidor: lo pequeño dice donde estas y lo grande dice
     que es. ]]
local function ZonaDe(c)
    return GetLabelText(GetNameOfZone(c.x, c.y, c.z))
end

--- ── Medida de fotogramas ────────────────────────────────────────────────
--[[ La suma va al dia en cada muestra (se quita la que sale y se pone la que
     entra), asi la media no recorre las 240 en cada envio de posicion. Al dar
     la vuelta se recalcula entera para que no se acumule error de redondeo. ]]
local fps = { muestras = {}, n = 0, i = 0, suma = 0.0 }

local function ApuntarFps()
    local dt = GetFrameTime()
    if dt <= 0.0 then return end

    fps.i = (fps.i % 240) + 1
    local nueva = 1.0 / dt
    fps.suma = fps.suma - (fps.muestras[fps.i] or 0.0) + nueva
    fps.muestras[fps.i] = nueva
    if fps.n < 240 then fps.n = fps.n + 1 end

    if fps.i == 240 then
        local suma = 0.0
        for i = 1, fps.n do suma = suma + fps.muestras[i] end
        fps.suma = suma
    end
end

local function MediaFps()
    if fps.n == 0 then return 0.0 end
    return fps.suma / fps.n
end

local function BorrarFps()
    fps.muestras = {}
    fps.n = 0
    fps.i = 0
    fps.suma = 0.0
end

--[[ ══ Los ajustes ════════════════════════════════════════════════════════

     Los cambia el jugador desde el mapa grande (origen_pausemenu), no desde
     aqui: este recurso no tiene pantalla propia donde poner un panel, y montar
     una solo para cuatro opciones seria una pantalla mas que mantener.

     Se guardan con SetResourceKvp, que es por jugador y por maquina -- que es
     lo que se espera de un ajuste de interfaz: el tamaño del minimapa es cosa
     de tu monitor, no de tu personaje, y no tiene por que viajar a la base de
     datos ni seguirte a otro ordenador. ]]
local AJUSTES = {
    -- clave, valor por defecto, y los valores que admite
    --[[ De serie, solo en coche. Un minimapa permanente es una caja encendida
         en la esquina durante horas de rol a pie, y a pie no hace falta: la
         ciudad se conoce andando. Quien lo quiera siempre lo tiene a un clic
         en los ajustes del mapa grande. ]]
    cuando = { 'vehiculo', { 'vehiculo', 'siempre' } },
    tamano = { 'normal', { 'mini', 'pequeno', 'mediano', 'normal', 'grande', 'enorme' } },
    --[[ La forma de la caja. De serie la cuadrada, que es la de siempre: la
         redonda es la misma pieza con el mapa en un circulo, para quien
         prefiera el radar de toda la vida. ]]
    -- 12/10: la redonda se retira para todos; quien la tuviera guardada cae
    -- en la cuadrada (LeerAjuste descarta lo que ya no esta en la lista).
    forma  = { 'cuadrado', { 'cuadrado' } },
    --[[ Sin las segmentadas («carril», «trozos»): retiradas el 01/10, no
         tienen que salirle a nadie. Quien las tuviera guardadas cae en la de
         serie, porque LeerAjuste descarta un valor que ya no esta en la lista. ]]
    linea  ={ 'bloque', { 'neon', 'ribete', 'bloque', 'cable', 'degradado', 'solida', 'nucleo', 'chevrones', 'desvanecida' } },
    zoom   = { 'normal', { 'cerca', 'normal', 'lejos' } },
    iconos = { 'si', { 'si', 'no' } },
    rastro = { 'no', { 'si', 'no' } },
    --[[ La linea de comida y agua de la esquina (y su surco en el aro de la
         redonda). Quien lleve otro HUD de necesidades, o no la quiera, la
         quita desde los ajustes del minimapa (27/09). ]]
    necesidades = { 'si', { 'si', 'no' } },
}

--[[ Declarado aqui y escrito mas abajo: `ponerAjuste` necesita repasar si el
     mapa toca verse en cuanto cambia el ajuste, y el repaso necesita Encender,
     que todavia no existe a esta altura del fichero. ]]
local Repasar

--- Lo leido, en memoria. `cuando` se pregunta en CADA fotograma (Repasar), y
--- un KVP es una lectura del almacen del cliente: leerlo sesenta veces por
--- segundo para un valor que solo cambia cuando el jugador toca el ajuste era
--- lo que mas pesaba del recurso en el resmon (16/09).
local ajustesLeidos = {}

local function LeerAjuste(k)
    local def = AJUSTES[k]
    if not def then return nil end

    local guardado = ajustesLeidos[k]
    if guardado ~= nil then return guardado end

    local v = GetResourceKvpString('origen_map:' .. k)

    -- Un valor guardado que ya no exista —porque se quito una opcion— vuelve
    -- al de partida en vez de dejar la interfaz en un estado imposible.
    for _, ok in ipairs(def[2]) do
        if v == ok then
            ajustesLeidos[k] = v
            return v
        end
    end
    ajustesLeidos[k] = def[1]
    return def[1]
end

--[[ ── La posicion de la caja ─────────────────────────────────────────

     No va en AJUSTES porque no es un valor de una lista: son dos cifras. Se
     guarda en PROPORCION de pantalla y no en pixeles, para que valga igual a
     1080p que a 1440p o en ventana: `x` es cuanto hay desde el canto
     izquierdo hasta la caja y `y` cuanto hay desde el canto de ABAJO, las dos
     de 0 a 1. Es el ancla que ya usa la caja (left y bottom en estilo.css):
     asi, cuando el piso del coche la hace crecer, crece hacia arriba como
     siempre y no se come lo que tenga debajo.

     Sin nada guardado es la de serie, la esquina de abajo a la izquierda, y
     la pone el CSS. Que la caja no se salga de la pantalla lo resuelve la
     pagina, que es la unica que sabe cuanto mide. ]]
local CLAVE_POSICION = 'origen_map:posicion'

--- Una posicion que se puede guardar: dos numeros finitos entre 0 y 1.
--- `n == n` descarta el NaN; los infinitos se caen por el rango.
local function PosicionValida(p)
    if type(p) ~= 'table' then return nil end
    local x, y = p.x, p.y
    if type(x) ~= 'number' or type(y) ~= 'number' then return nil end
    if x ~= x or y ~= y then return nil end
    if x < 0 or x > 1 or y < 0 or y > 1 then return nil end

    -- Cuatro decimales son una decima de pixel en una 4K: lo demas es ruido.
    return { x = math.floor(x * 10000 + 0.5) / 10000, y = math.floor(y * 10000 + 0.5) / 10000 }
end

local function LeerPosicion()
    local crudo = GetResourceKvpString(CLAVE_POSICION)
    if not crudo or crudo == '' then return nil end

    -- Un KVP roto no puede dejar la caja en un sitio imposible: vuelve a la de serie.
    local ok, p = pcall(json.decode, crudo)
    return ok and PosicionValida(p) or nil
end

--- nil es la de serie: se borra la clave y manda el CSS.
local function GuardarPosicion(p)
    if p then
        SetResourceKvp(CLAVE_POSICION, json.encode(p))
    else
        DeleteResourceKvp(CLAVE_POSICION)
    end
end

local function TodosLosAjustes()
    local t = {}
    for k in pairs(AJUSTES) do t[k] = LeerAjuste(k) end
    --[[ `false` y no nil para la de serie: nil no viaja en el JSON, y la
         pagina tiene que distinguir "no me dicen nada de la posicion" (un
         aviso a medias) de "vuelve a la de serie". ]]
    t.posicion = LeerPosicion() or false
    return t
end

--- Se los manda a la interfaz. Se llama al encender y al cambiar cualquiera.
--- Tambien con el mapa apagado: la linea de comida y agua sale a pie aunque
--- el minimapa no este, y tiene que saber si se ve y donde va la esquina.
local function AplicarAjustes()
    SendNUIMessage({ accion = 'ajustes', ajustes = TodosLosAjustes() })
end

--[[ Lo llama el mapa grande del inventario (origen_inventory, antes
     origen_pausemenu). Se valida aqui y no alli: la interfaz manda lo
     que el jugador toca, y un recurso no puede fiarse de que lo que le llega
     de una pantalla sea uno de los valores que el mismo definio. ]]
RegisterNetEvent('origen_map:ponerAjuste', function(k, v)
    --[[ La posicion entra por aqui SOLO para volver a la de serie: es lo que
         manda «Volver a lo de serie» del mapa grande. Moverla a otro sitio no:
         eso es el modo posicionar, mas abajo, que es donde el jugador la ve. ]]
    if k == 'posicion' then
        if v ~= false and v ~= nil then return end
        GuardarPosicion(nil)
        AplicarAjustes()
        return
    end

    local def = AJUSTES[k]
    if not def then return end

    local vale = false
    for _, ok in ipairs(def[2]) do if v == ok then vale = true end end
    if not vale then return end

    SetResourceKvp('origen_map:' .. k, v)
    ajustesLeidos[k] = v
    AplicarAjustes()

    -- "Cuando se ve" no es un ajuste de aspecto: cambia si el mapa tiene que
    -- estar puesto ahora mismo. Sin esto habria que bajarse del coche para que
    -- el cambio se notara.
    if k == 'cuando' and Repasar then Repasar() end
end)

exports('Ajustes', TodosLosAjustes)

--- ── Encender y apagar ───────────────────────────────────────────────────

--[[ `devolverVanilla` distingue los dos motivos por los que el mapa se apaga,
     que no quieren lo mismo:

       - a mano, con /mapa: se quita el nuestro y se le devuelve al jugador el
         minimapa de GTA, porque si no se queda sin ninguno y sin saber por que;
       - porque toca (vas a pie y el ajuste dice "solo en vehiculo"): entonces
         NO hay minimapa, ni el nuestro ni el de GTA. Ese es justo el efecto
         que se ha pedido, y devolver el de GTA lo estropearia. ]]
local function Encender(si, devolverVanilla)
    encendido = si and true or false

    SendNUIMessage({ accion = 'estado', encendido = encendido })

    -- Los ajustes guardados. Van aqui y no al arrancar el recurso porque la
    -- NUI se entera de los mensajes solo cuando ya esta viva.
    AplicarAjustes()

    if encendido then
        DisplayRadar(true)          -- vivo, aunque no se vea: si no, no hay ruta
        ColocarVanilla(false)
        vanillaVisible = false
        rastro = {}
        ultimoRastro = nil
    elseif devolverVanilla then
        ColocarVanilla(true)
        vanillaVisible = true
    else
        ColocarVanilla(false)
        vanillaVisible = false
        DisplayRadar(false)
    end

    BorrarFps()
end

--[[ ══ Cuando se ve ═══════════════════════════════════════════════════════

     De serie el minimapa sale solo al montarte en un vehiculo. El ajuste
     "cuando" lo cambia, y `/mapa` sigue por encima de los dos: si alguien lo
     quita a mano, quitado se queda hasta que lo vuelva a poner. Un ajuste no
     puede deshacer lo que el jugador acaba de teclear.

     Se mira con un hilo y no con lib.onCache('vehicle') porque este recurso no
     depende de ox_lib y no merece la pena que empiece a depender por esto: es
     una native y una comparacion cada cuarto de segundo. ]]
local apagadoAMano = false

--[[ Si el estado se ha llegado a APLICAR alguna vez, que no es lo mismo que
     cual es. `encendido` empieza en false, y a pie el estado que toca tambien
     es false: sin esta bandera, el primer repaso veia "ya coincide" y no hacia
     nada, asi que nadie llegaba a apartar el minimapa de GTA y el jugador
     entraba al servidor con el de serie puesto en la esquina. Coincidir no es
     estar hecho. ]]
local aplicado = false

--[[ Devuelve SIEMPRE true o false, nunca "algo que vale por true".

     Y esto no es puntilloso: `IsPedInAnyVehicle` no devuelve el booleano `true`,
     y en Lua `1 ~= true` es CIERTO porque son tipos distintos. Con el valor
     crudo, la comparacion de mas abajo nunca coincidia y el estado se volvia a
     aplicar en cada fotograma: 176 avisos por segundo a la interfaz.

     Antes eso no se notaba —la interfaz solo hacia `hidden = !encendido`, que
     da igual repetirlo— pero con una animacion de entrada cada aviso volvia a
     poner el punto de partida, y el minimapa se quedaba en opacidad 0 para
     siempre. Un fallo viejo que solo dolio cuando algo empezo a depender de que
     el aviso llegara UNA vez. ]]
--[[ Si el jugador esta colocando la caja (el modo posicionar, mas abajo).
     Mientras dure, el minimapa se ve SIEMPRE: aunque el ajuste diga «solo en
     vehiculo» y vayas a pie, y aunque lo hayas quitado con /mapa. No se puede
     colocar una caja que no esta. Al salir, el repaso lo deja como tocaba. ]]
local posicionando = false

--[[ Apartado por otro recurso. Hay pantallas en las que el minimapa sobra
     aunque el ajuste diga «siempre»: el menu de inicio y la creacion del
     personaje (origen_titlemenu) y la tienda de ropa (origen_clothing). Cada
     una lo pide con

         exports.origen_map:Apartar(true)    -- al abrir
         exports.origen_map:Apartar(false)   -- al cerrar

     y se apunta a nombre del recurso que llama, asi que dos pantallas a la vez
     no se pisan: el mapa vuelve cuando lo sueltan todas. Si un recurso se para
     sin soltarlo (un restart con el menu abierto), se suelta solo abajo, en
     su onResourceStop. ]]
local apartadoPor = {}

--[[ Lo contrario: pedido A LA VISTA por otro recurso, aunque el ajuste diga
     «solo en vehiculo», vayas a pie o lo hayas quitado con /mapa. Lo usa el
     menu radial de origen_hud mientras esta abierto (16/09/2026, pedido por
     el usuario: con el radial delante el minimapa siempre se ve). Mismo
     trato que Apartar:

         exports.origen_map:Mostrar(true)    -- al abrir
         exports.origen_map:Mostrar(false)   -- al cerrar

     Apartar gana: una pantalla que no quiere mapa (menu de inicio, tienda de
     ropa) no se lo encuentra puesto por otra. ]]
local mostradoPor = {}

local function TocaVerse()
    if posicionando then return true end
    if next(apartadoPor) then return false end
    if next(mostradoPor) then return true end
    if apagadoAMano then return false end
    if LeerAjuste('cuando') == 'siempre' then return true end
    return IsPedInAnyVehicle(PlayerPedId(), false) and true or false
end

Repasar = function()
    local toca = TocaVerse()
    if toca ~= encendido or not aplicado then
        aplicado = true
        Encender(toca, false)
    end
end

exports('Apartar', function(si)
    local quien = GetInvokingResource() or GetCurrentResourceName()
    apartadoPor[quien] = si and true or nil
    Repasar()
    SendNUIMessage({ accion = 'apartar', apartado = next(apartadoPor) ~= nil })
end)

exports('Mostrar', function(si)
    local quien = GetInvokingResource() or GetCurrentResourceName()
    mostradoPor[quien] = si and true or nil
    Repasar()
end)

AddEventHandler('onClientResourceStop', function(recurso)
    if apartadoPor[recurso] or mostradoPor[recurso] then
        apartadoPor[recurso] = nil
        mostradoPor[recurso] = nil
        Repasar()
        SendNUIMessage({ accion = 'apartar', apartado = next(apartadoPor) ~= nil })
    end
end)

--- ── Comida y agua (la tarjeta de abajo a la izquierda) ─────────────────
--[[ Muerto no se avisa de nada: salian el agua y la comida al 0 % encima de
     la pantalla de Estado vital (25/09). Se miraba solo `isDead`, y
     origen_ambulancejob pone `dead` (modules/death/client.lua); `isDead` no lo
     pone nadie. Se miran los dos por si algun dia vuelve.

     `muertoAhora` es el valor que trae el cambio del statebag: el manejador
     corre ANTES de que LocalPlayer.state tenga el valor nuevo, y leyendolo
     de ahi el aviso se quedaba un segundo mas hasta el siguiente repaso. ]]
local function EnviarNecesidades(muertoAhora)
    local pState = LocalPlayer.state
    local muerto = muertoAhora
    if muerto == nil then muerto = pState and (pState.dead or pState.isDead) end
    if muerto then
        -- La tarjeta de comida y agua se quita entera (mapa.js).
        SendNUIMessage({ accion = 'actualizarNecesidades', muerto = true })
        return
    end

    local hambre = pState and pState.hunger or 100
    local sed = pState and pState.thirst or 100

    if (not pState or pState.hunger == nil) then
        local ok, qb = pcall(function() return exports['qb-core']:GetCoreObject() end)
        if ok and qb and qb.Functions and qb.Functions.GetPlayerData then
            local pData = qb.Functions.GetPlayerData()
            if pData and pData.metadata then
                hambre = pData.metadata.hunger or hambre
                sed = pData.metadata.thirst or sed
            end
        end
    end

    SendNUIMessage({
        accion = 'actualizarNecesidades',
        comida = hambre,
        agua = sed
    })
end

local function OnStateBagNeeds(bagName, clave, valor)
    local myServerId = GetPlayerServerId(PlayerId())
    if bagName == ('player:%s'):format(myServerId) then
        if clave == 'dead' or clave == 'isDead' then
            EnviarNecesidades(valor and true or false)
        else
            EnviarNecesidades()
        end
    end
end

--[[ EL MICRO EN EL MINIMAPA (04/10).

     El micro va entre la comida y el agua (pieza .nec-voz de la pagina), en
     Origen y en Nacion: desde el 05/10 las dos marcas son la misma interfaz
     y origen_hud ya no pinta su pastilla del micro en ninguna.

     Se manda SOLO cuando cambia algo: si hablas, el alcance (1 susurro,
     2 normal, 3 grito; lo da pma-voice en el statebag `proximity`) y si es por
     radio (`radioActive` de pma-voice). ]]
do
    local function NivelDeVoz()
        local prox = LocalPlayer.state.proximity
        if type(prox) ~= 'table' then return 2 end
        local i = tonumber(prox.index)
        if i and i >= 1 and i <= 3 then return math.floor(i) end
        local modo = tostring(prox.mode or ''):lower()
        if modo == 'whisper' or modo == 'susurro' then return 1 end
        if modo == 'shouting' or modo == 'shout' or modo == 'gritar' then return 3 end
        return 2
    end

    CreateThread(function()
        local ultimo = ''
        while true do
            local hablando = NetworkIsPlayerTalking(PlayerId())
            local radio = LocalPlayer.state.radioActive and true or false
            local nivel = NivelDeVoz()
            local firma = (hablando and '1' or '0') .. (radio and '1' or '0') .. nivel
            if firma ~= ultimo then
                ultimo = firma
                SendNUIMessage({ accion = 'voz', hablando = hablando or radio, radio = radio, nivel = nivel })
            end
            Wait(120)
        end
    end)
end

AddStateBagChangeHandler('hunger', nil, OnStateBagNeeds)
AddStateBagChangeHandler('thirst', nil, OnStateBagNeeds)
AddStateBagChangeHandler('isDead', nil, OnStateBagNeeds)
AddStateBagChangeHandler('dead', nil, OnStateBagNeeds)

--[[ Lo manda qbx_core en cada cambio de hambre o sed. Pasaba las cifras tal
     cual, sin mirar si estabas muerto: por aqui volvian a salir los avisos
     aunque el repaso de arriba los hubiera quitado. ]]
RegisterNetEvent('hud:client:UpdateNeeds', function(hambre, sed)
    local pState = LocalPlayer.state
    if pState and (pState.dead or pState.isDead) then
        EnviarNecesidades(true)
        return
    end
    SendNUIMessage({
        accion = 'actualizarNecesidades',
        comida = hambre,
        agua = sed
    })
end)

--[[ Con el menu de pausa o el de Ajustes (origen_ajustes) abierto se aparta
     TODO el HUD de esta NUI (mapa.js: body.en-pausa), no solo las alertas.
     El de Ajustes se abre con ActivateFrontendMenu y IsPauseMenuActive() no
     siempre lo ve: GetPauseMenuState() si, y ademas avisa con
     TriggerEvent('origen:ajustes', bool) para que se aparte al momento. ]]
local enAjustes, ultimaPausa = false, false

local function MirarPausa()
    local pausa = enAjustes or IsPauseMenuActive() or GetPauseMenuState() ~= 0
    if pausa ~= ultimaPausa then
        ultimaPausa = pausa
        SendNUIMessage({ accion = 'pausa', pausa = pausa })
    end
end

AddEventHandler('origen:ajustes', function(abierto)
    enAjustes = abierto == true
    MirarPausa()
end)

CreateThread(function()
    while true do
        Wait(1000)
        MirarPausa()
        EnviarNecesidades()
    end
end)

--[[ ── El cielo de la brujula ─────────────────────────────────────────────

     El icono de la derecha de la brujula en el diseño en piezas: sol de dia,
     luna de noche, y el tiempo si no esta despejado. Cada 5 s y solo si
     cambia: el tiempo de GTA no cambia mas deprisa que eso. ]]
local CIELOS = {
    [`CLEAR`] = 'despejado', [`EXTRASUNNY`] = 'despejado', [`NEUTRAL`] = 'despejado',
    [`CLOUDS`] = 'nubes', [`OVERCAST`] = 'nubes', [`SMOG`] = 'niebla', [`FOGGY`] = 'niebla',
    [`RAIN`] = 'lluvia', [`CLEARING`] = 'lluvia', [`THUNDER`] = 'tormenta',
    [`SNOW`] = 'nieve', [`SNOWLIGHT`] = 'nieve', [`BLIZZARD`] = 'nieve', [`XMAS`] = 'nieve',
    [`HALLOWEEN`] = 'niebla',
}

CreateThread(function()
    local ultimo
    while true do
        local tiempo = CIELOS[GetPrevWeatherTypeHashName()] or 'despejado'
        local hora = GetClockHours()
        local icono = tiempo
        if tiempo == 'despejado' then
            icono = (hora >= 21 or hora < 6) and 'luna' or 'sol'
        end
        if icono ~= ultimo then
            ultimo = icono
            SendNUIMessage({ accion = 'cielo', icono = icono })
        end
        Wait(5000)
    end
end)

--[[ ── Cuando la pantalla dice que ya esta ──────────────────────────────

     El estado se manda con SendNUIMessage, y un SendNUIMessage a una pagina que
     todavia no ha cargado NO SE ENCOLA: se pierde. El hilo de aqui abajo corre
     desde el primer fotograma del recurso, o sea mucho antes de que el CEF
     tenga la pagina montada, asi que ese primer aviso —el unico, porque despues
     solo se manda cuando el estado CAMBIA— se iba al vacio.

     Efecto: si el recurso arrancaba contigo ya montado en un coche, el mapa no
     aparecia hasta que te bajabas y volvias a subir. Y al reiniciar el recurso,
     igual.

     Asi que ahora la pagina avisa cuando esta lista y se le vuelve a contar el
     estado desde cero. `aplicado = false` es lo que fuerza a recontarlo aunque
     no haya cambiado nada. ]]
--[[ Tamaño de las referencias de policia en el minimapa (12/10). Lo elige el
     agente en los Ajustes de origen_police, que solo pasa el recado; aqui se
     guarda en su equipo y se le dice a la pagina. ]]
local KVP_REF_TAMANO = 'origen_map:ref_tamano'
local REF_ESCALAS = { pequeno = 0.75, normal = 1.0, grande = 1.35 }

local function EnviarTamanoReferencias()
    SendNUIMessage({ accion = 'refEscala', escala = REF_ESCALAS[GetResourceKvpString(KVP_REF_TAMANO) or 'normal'] or 1.0 })
end

AddEventHandler('origen_map:referencias:tamano', function(tamano)
    if not REF_ESCALAS[tamano] then tamano = 'normal' end
    SetResourceKvp(KVP_REF_TAMANO, tamano)
    EnviarTamanoReferencias()
end)

exports('TamanoReferencias', function()
    local t = GetResourceKvpString(KVP_REF_TAMANO)
    return REF_ESCALAS[t] and t or 'normal'
end)

RegisterNUICallback('listo', function(_, cb)
    aplicado = false
    Repasar()
    AplicarAjustes()
    EnviarTamanoReferencias()
    -- Una pagina recargada a mitad de colocar la caja no sabe que lo estaba:
    -- sin esto se quedaria el raton puesto y ninguna caja que arrastrar.
    if posicionando then SendNUIMessage({ accion = 'posicionar', activo = true }) end
    EnviarNecesidades()
    cb('ok')
end)

--[[ ══ Posicionar el minimapa ════════════════════════════════════════════

     El jugador arrastra la caja a donde la quiera, como el dispatch de la
     policia. Se entra desde los ajustes del minimapa del mapa grande: el
     inventario se cierra, la caja se queda sola en pantalla con el raton y un
     aviso, y al confirmar o cancelar se vuelve a donde se estaba.

     Este recurso no sabe quien le llama ni a donde hay que volver. Quien
     entra le da un `volver` y aqui se le devuelve tal cual al salir, en
     'origen_map:posicionarAcabado'. Asi el inventario no queda cosido a este
     fichero ni este al inventario.

     Evento LOCAL (AddEventHandler) y no de red: coger el foco del raton es
     cosa del propio cliente, y un servidor no tiene por que poder dejarle a
     alguien la pantalla con el cursor puesto.

     El foco se coge sin KeepInput: mientras colocas la caja no se anda ni se
     dispara, y el teclado es de la pagina (ENTER, ESC y R). ]]
local volverA = nil

--- `guardado` solo viaja en el aviso. `avisar` en false es para cuando nos
--- sacan a la fuerza (el comando `raton`): ahi nadie quiere que se le vuelva a
--- abrir un panel encima.
local function SalirDePosicionar(guardado, avisar)
    if not posicionando then return end
    posicionando = false

    SetNuiFocus(false, false)
    SendNUIMessage({ accion = 'posicionar', activo = false })

    -- Si a pie no tocaba verse, la caja se va ahora, ya colocada.
    Repasar()

    local volver = volverA
    volverA = nil
    if avisar then TriggerEvent('origen_map:posicionarAcabado', volver, guardado == true) end
end

AddEventHandler('origen_map:posicionar', function(datos)
    if posicionando then return end

    local volver = type(datos) == 'table' and datos.volver or nil
    volverA = (type(volver) == 'string' and #volver <= 64) and volver or nil
    posicionando = true

    -- Encendida ya, sin esperar al hilo que repasa: el aviso de abajo necesita
    -- la caja puesta para tener algo que arrastrar.
    Repasar()
    AplicarAjustes()

    SetNuiFocus(true, true)
    SendNUIMessage({ accion = 'posicionar', activo = true })
end)

--[[ Confirmar. Llega `{ x, y }` en proporcion de pantalla, o sin ninguna de
     las dos (null en el JSON) si el jugador la ha devuelto a la de serie con
     la R. Lo que no sea ninguna de esas dos cosas no se guarda: se sale como
     si hubiera cancelado. ]]
RegisterNUICallback('posicionHecha', function(datos, cb)
    cb('ok')
    if not posicionando then return end

    local p = nil
    if type(datos) == 'table' and (datos.x ~= nil or datos.y ~= nil) then
        p = PosicionValida(datos)
        if not p then
            AplicarAjustes()
            SalirDePosicionar(false, true)
            return
        end
    end

    GuardarPosicion(p)
    -- Antes de salir: al salir la caja puede apagarse, y apagada no se le
    -- manda nada.
    AplicarAjustes()
    SalirDePosicionar(true, true)
end)

--- Cancelar: la pagina ya ha devuelto la caja a su sitio; se le reenvia la
--- guardada igualmente para que lo que se ve sea lo guardado y no lo que ella crea.
RegisterNUICallback('posicionCancelada', function(_, cb)
    cb('ok')
    if not posicionando then return end
    AplicarAjustes()
    SalirDePosicionar(false, true)
end)

--[[ El vigilante del raton (shared/foco.lua, cargado el primero en el
     fxmanifest). Con el, este recurso cuenta como "tengo el foco" mientras
     colocas la caja --lo ven los demas por 'origen:foco:estado', y la pantalla
     de muerto no le pisa el teclado--, y si alguien lo suelta a la fuerza con
     `raton` en F8 el modo se recoge en vez de quedarse a medias. ]]
if OrigenFoco then
    OrigenFoco.AlSoltar(function()
        if not posicionando then return end
        AplicarAjustes()
        SalirDePosicionar(false, false)
    end)
end

--- El repaso va en el hilo de mas abajo, que corre cada fotograma. Ver alli
--- por que no puede ir con su propio reloj.

--- ── El hilo que manda la posicion ───────────────────────────────────────
local refPolicia = { dato = nil, hasta = 0 }

CreateThread(function()
    while true do
        local espera = 250

        if encendido then
            espera = math.floor(1000 / math.max(1, Config.hz))

            local ped = PlayerPedId()
            local c = GetEntityCoords(ped)

            --[[ El mapa gira con la CAMARA, no con el personaje (22/09/2026,
                 pedido por el usuario: «como el de GTA V»). Antes giraba con
                 GetEntityHeading y al mover el raton el mapa se quedaba
                 quieto. El rumbo de la camara sale de GetGameplayCamRot con la
                 misma convencion que el heading (0 al norte, creciendo hacia
                 el oeste); solo hay que llevarlo a 0..360.

                 El heading del personaje se sigue mandando aparte (`mira`)
                 para la flecha del centro, que apunta a donde mira el
                 personaje aunque la camara este girada. ]]
            local rumbo = GetGameplayCamRot(2).z % 360.0
            local mira = GetEntityHeading(ped)

            --[[ El rastro: un punto cada pocos metros, no cada envio. Si se
                 apuntara en cada envio, estando quieto se llenaria de puntos
                 en el mismo sitio y la linea se comeria memoria sin dibujar
                 nada nuevo. ]]
            local lejos = true
            if ultimoRastro then
                local dx, dy = c.x - ultimoRastro.x, c.y - ultimoRastro.y
                lejos = (dx * dx + dy * dy) > (Config.rastroCadaM * Config.rastroCadaM)
            end

            if lejos then
                rastro[#rastro + 1] = { math.floor(c.x * 10) / 10, math.floor(c.y * 10) / 10 }
                while #rastro > Config.rastroPuntos do table.remove(rastro, 1) end
                ultimoRastro = { x = c.x, y = c.y }
            end

            --[[ La referencia de policia (icono, color, unidad) cambia a mano y
                 muy de vez en cuando: se pregunta una vez por segundo y no en
                 cada envio. Antes eran 30 exports por segundo, con tirones de
                 casi 2 ms en el perfil del 16/09. ]]
            local ahora = GetGameTimer()
            if ahora >= refPolicia.hasta then
                refPolicia.hasta = ahora + 1000
                refPolicia.dato = nil
                if GetResourceState('origen_police') == 'started' then
                    local ok, r = pcall(function()
                        return exports.origen_police:MiReferenciaParaMapa()
                    end)
                    if ok and r then
                        refPolicia.dato = r
                    end
                end
            end
            local refData = refPolicia.dato

            SendNUIMessage({
                accion = 'yo',
                x = math.floor(c.x * 10) / 10,
                y = math.floor(c.y * 10) / 10,
                z = math.floor((c.z or 0.0) * 10) / 10,
                rumbo = math.floor(rumbo * 10) / 10,
                mira = math.floor(mira * 10) / 10,
                enVehiculo = IsPedInAnyVehicle(ped, false),
                velocidad = math.floor(GetEntitySpeed(ped) * 3.6),
                fps = math.floor(MediaFps()),
                referencia = refData,
            })
        end

        Wait(espera)
    end
end)

--[[ ¿Se ha quedado la linea en el camino viejo?

     El primer punto del trazado eres tu (el metro cero), asi que lo que dice
     por donde va la ruta es el segundo, seis metros mas alla. Si ese queda
     lejos, la ruta no pasa por donde estas.

     Solo cuenta yendo en coche y pisando carretera: campo a traves la ruta
     SIEMPRE empieza lejos —en la carretera mas cercana— y no hay nada que
     rehacer. ]]
local desvioSeguidos, desvioUltimo = 0, 0

local function VigilarDesvio(puntos, slot, ahora)
    local p = puntos and puntos[2]
    local ped = PlayerPedId()
    local veh = p and GetVehiclePedIsIn(ped, false) or 0

    if veh == 0 then desvioSeguidos = 0 return end

    local yo = GetEntityCoords(ped)
    local lejos = math.sqrt((p[1] - yo.x) ^ 2 + (p[2] - yo.y) ^ 2)

    if lejos < Config.desvioMetros or not IsPointOnRoad(yo.x, yo.y, yo.z, veh) then
        desvioSeguidos = 0
        return
    end

    desvioSeguidos = desvioSeguidos + 1
    if desvioSeguidos < Config.desvioLecturas or ahora - desvioUltimo < Config.desvioCadaMs then return end

    desvioSeguidos, desvioUltimo = 0, ahora

    if slot == 0 then
        pcall(RefreshWaypoint)
    elseif RegistroRehacerRuta then
        pcall(RegistroRehacerRuta)
    end
end

--- ── El hilo del rastro y la ruta ────────────────────────────────────────
CreateThread(function()
    local destinoActivo = false
    while true do
        if encendido then
            -- El rastro va aparte de la posicion: cambia mucho mas despacio y
            -- mandarlo entero 15 veces por segundo seria tirar trabajo.
            SendNUIMessage({ accion = 'rastro', puntos = rastro })

            local ahora = GetGameTimer()
            if ahora - rutaUltima >= Config.rutaCadaMs then
                rutaUltima = ahora
                --[[ Sin comprobar el waypoint: no toda ruta viene de uno.
                     Un trabajo puede poner la suya en el slot del blip o en la
                     discreta, y SlotActivo() ya devuelve nada cuando no hay
                     ninguna. Preguntar por el waypoint solo servia para
                     descartar rutas buenas. ]]
                --[[ El destino va aparte del trazado. El ultimo punto del
                     muestreo NO sirve: la ruta se corta a los 600 m, asi que
                     ese punto es donde dejamos de mirar, no adonde vas. El
                     destino de verdad es el waypoint.

                     Y si no hay waypoint, la ruta de un trabajo (la del
                     registro), que es la que el mapa grande enseña entonces
                     (17/09). Sin esto el minimapa pintaba la linea sin
                     chincheta, o nada, con el mapa grande marcando un sitio. ]]
                local destino = false
                local slotDestino = nil
                local wp = GetFirstBlipInfoId(8)
                if DoesBlipExist(wp) then
                    local d = GetBlipInfoIdCoord(wp)
                    destino = { math.floor(d.x * 10) / 10, math.floor(d.y * 10) / 10 }
                    slotDestino = 0
                elseif RegistroRutaPuesta then
                    local ok, r = pcall(RegistroRutaPuesta)
                    if ok and type(r) == 'table' and tonumber(r.x) then
                        destino = { math.floor(r.x * 10) / 10, math.floor(r.y * 10) / 10 }
                        slotDestino = 1
                    end
                end

                local hayWaypoint = slotDestino == 0
                local puntos, slotLeido = TrazadoDelGps(slotDestino, not hayWaypoint)

                -- Con la lectura buena en la mano, antes de tirar de la guardada.
                VigilarDesvio(puntos, slotDestino, ahora)

                --[[ Un hueco corto no borra la linea.

                     Cuando el destino cambia —el punto siguiente de un examen,
                     la parada siguiente de un reparto— el juego tarda uno o dos
                     segundos en rehacer el camino, y en ese rato no devuelve
                     nada. Mandando `false` al mapa, la linea desaparece y vuelve:
                     desde el coche se ve como que la ruta «se pierde» (medido el
                     20/09 con el examen de conducir).

                     Asi que se aguanta la ultima linea buena hasta 4 segundos.
                     Pasado ese rato sin nada, ya no es un recalculo: es que no
                     hay ruta, y entonces si se borra. ]]
                --[[ Pero quitar la ruta SI la borra, y en el acto (04/10): la
                     linea guardada solo se aguanta mientras su destino siga
                     puesto —el waypoint, o el punto del registro—. Sin esto,
                     al quitar la ruta la raya se quedaba cuatro segundos mas
                     llevando a ningun sitio. ]]
                local sigue = true
                if rutaUltimosSlot == 0 then
                    sigue = hayWaypoint
                elseif rutaUltimosConDestino then
                    sigue = destino ~= false
                end

                if puntos then
                    rutaUltimosPuntos, rutaUltimosCuando = puntos, ahora
                    rutaUltimosSlot, rutaUltimosConDestino = slotLeido, destino ~= false
                elseif rutaUltimosPuntos and sigue and (ahora - rutaUltimosCuando) < 4000 then
                    puntos = rutaUltimosPuntos
                else
                    rutaUltimosPuntos = nil
                end

                local distancia = nil
                if destino then
                    local ped = PlayerPedId()
                    local yo = GetEntityCoords(ped)
                    local dx = (destino[1] + 0.0) - yo.x
                    local dy = (destino[2] + 0.0) - yo.y
                    local distLinea = math.sqrt(dx * dx + dy * dy)
                    local okCar, carretera = pcall(CalculateTravelDistanceBetweenPoints, yo.x, yo.y, yo.z, destino[1] + 0.0, destino[2] + 0.0, yo.z)
                    if okCar and carretera and carretera > 0 and carretera < 50000 and carretera >= (distLinea * 0.7) then
                        distancia = math.floor(carretera)
                    else
                        distancia = math.floor(distLinea)
                    end
                end
                destinoActivo = destino

                SendNUIMessage({ accion = 'ruta', puntos = puntos or false, destino = destino, distancia = distancia })
            elseif destinoActivo then
                -- Comprobar si el waypoint sigue existiendo en el tick intermedio
                local wp = GetFirstBlipInfoId(8)
                -- Llamandola: la funcion a secas siempre es «verdad», y la
                -- distancia no se borraba nunca al quitar la ruta.
                if DoesBlipExist(wp) or (RegistroRutaPuesta and RegistroRutaPuesta()) then
                    local ped = PlayerPedId()
                    local yo = GetEntityCoords(ped)
                    local dx = (destinoActivo[1] + 0.0) - yo.x
                    local dy = (destinoActivo[2] + 0.0) - yo.y
                    local distLinea = math.sqrt(dx * dx + dy * dy)
                    local okCar, carretera = pcall(CalculateTravelDistanceBetweenPoints, yo.x, yo.y, yo.z, destinoActivo[1] + 0.0, destinoActivo[2] + 0.0, yo.z)
                    local distancia = math.floor((okCar and carretera and carretera > 0 and carretera < 50000 and carretera >= (distLinea * 0.7)) and carretera or distLinea)
                    SendNUIMessage({ accion = 'distancia', distancia = distancia })
                else
                    destinoActivo = false
                    SendNUIMessage({ accion = 'distancia', distancia = nil })
                end
            end
        end

        Wait(500)
    end
end)

--[[ ══ El HUD del coche, dentro del minimapa ═══════════════════════════════

     El diseño del zip «HUD carplay» (OrigenMinimap.vue): la misma tarjeta sirve
     a pie y en coche. En coche el piso de abajo pasa a ser velocidad, marcha,
     gasolina y estado del coche; cinturón y luces van en dos testigos sobre la
     esquina del mapa, y el nitroso es una tira fina en el borde de abajo.

     De donde sale cada cosa:
       · velocidad, marcha, motor, carrocería y luces: natives del coche;
       · gasolina: el statebag `fuel` del coche (el mismo que usa origen_hud),
         y si no lo hay, la native;
       · cuentakilómetros: el statebag `mileage` (en metros);
       · cinturón: `LocalPlayer.state.seatbelt`, que pone qbx_seatbelt;
       · nitroso: el export EstadoNitroso de origen_plates, si está.

     Solo en vehículos de tierra: aviones y helicópteros siguen con su HUD de
     origen_hud, que enseña altura y rumbo (origen_hud ya no tiene HUD de
     coche). origen_plates pregunta con HudDelCoche para no pintar encima. ]]
local hudCocheVisible = false

local SIN_CINTURON = { [8] = true, [13] = true, [14] = true, [15] = true, [16] = true, [21] = true }

local function Marcha(veh)
    local g = GetVehicleCurrentGear(veh)
    local v = GetEntitySpeedVector(veh, true)
    if v and v.y < -0.5 then return 'R' end
    if GetEntitySpeed(veh) < 0.5 and g <= 1 then return 'N' end
    if g == 0 then return 'R' end
    return tostring(g)
end

local function Nitroso()
    if GetResourceState('origen_plates') ~= 'started' then return nil end
    local ok, n = pcall(function() return exports.origen_plates:EstadoNitroso() end)
    if ok and type(n) == 'table' and n.instalado then return n end
    return nil
end

CreateThread(function()
    while true do
        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
        local clase = veh ~= 0 and GetVehicleClass(veh) or -1
        local toca = encendido and veh ~= 0 and clase ~= 15 and clase ~= 16

        if not toca then
            if hudCocheVisible then
                hudCocheVisible = false
                SendNUIMessage({ accion = 'coche', coche = false })
            end
            --[[ 100 y no 300: el minimapa se enciende en el fotograma en que
                 subes (Repasar va cada fotograma) y la coreografia de la
                 interfaz cuenta con que el aviso del coche llegue detras en
                 menos de 380 ms. Con 300 a veces no llegaba y se veia la calle
                 un instante antes de la velocidad. Son dos natives. ]]
            Wait(100)
        else
            hudCocheVisible = true
            local estado = Entity(veh).state
            local gasolina = tonumber(estado.fuel) or GetVehicleFuelLevel(veh)
            local metros = type(estado.mileage) == 'table' and tonumber(estado.mileage.value) or tonumber(estado.mileage)
            local _, luces, largas = GetVehicleLightsState(veh)
            local nos = Nitroso()

            SendNUIMessage({
                accion = 'coche',
                coche = {
                    velocidad = math.floor(GetEntitySpeed(veh) * 3.6 + 0.5),
                    marcha = Marcha(veh),
                    -- La cápsula de la redonda (25/09): la tira de revoluciones
                    -- (0,2 al ralentí, 1 al corte) y el testigo del motor.
                    rpm = math.floor(GetVehicleCurrentRpm(veh) * 100 + 0.5) / 100,
                    encendido = GetIsVehicleEngineRunning(veh),
                    gasolina = math.floor(gasolina or 0),
                    carroceria = math.floor(math.max(0, math.min(1000, GetVehicleBodyHealth(veh))) / 10),
                    --[[ El MOTOR va aparte de la carrocería. Antes solo había un
                         medidor, «Coche», que era la carrocería, y el motor se
                         moría con él todavía al 80 %: vehiclehandler le quita al
                         motor cinco veces lo que pierde la chapa en cada golpe
                         (globalmultiplier), por debajo de 500 le recorta la
                         potencia y a 0 deja el coche sin arrancar. La native va
                         de -4000 a 1000; por debajo de 0 está igual de muerto,
                         así que se recorta a 0-1000 y se pasa a %. ]]
                    motor = math.floor(math.max(0, math.min(1000, GetVehicleEngineHealth(veh))) / 10),
                    km = metros and math.floor(metros / 1000) or nil,
                    -- nil = este vehículo no lleva cinturón (motos, bicis…) y no se pinta
                    cinturon = (not SIN_CINTURON[clase]) and (LocalPlayer.state.seatbelt == true) or nil,
                    luces = (luces == 1 or largas == 1),
                    nos = nos and math.floor(nos.carga or 0) or nil,
                    nosActivo = nos and nos.activo or false,
                    nosBloqueado = nos and nos.bloqueado or false,
                },
            })
            Wait(100)
        end
    end
end)

--- ¿Está el HUD del coche dentro del minimapa? Lo pregunta origen_plates
--- para no pintar el suyo encima.
---
--- Contesta por lo que TOCA, no solo por lo que ya se ha pintado. Con solo
--- `hudCocheVisible` la primera pregunta llegaba antes que el hilo de arriba
--- (que a pie mira cada 300 ms) y antes que Repasar (250 ms): origen_hud se
--- montaba en el coche, oía «no», y su HUD viejo salía un instante abajo en el
--- centro de la pantalla hasta la siguiente vuelta.
exports('HudDelCoche', function()
    if hudCocheVisible then return true end
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh == 0 or not TocaVerse() then return false end
    local clase = GetVehicleClass(veh)
    return clase ~= 15 and clase ~= 16
end)

--[[ ── El rotulo de la calle ─────────────────────────────────────────

     Dos veces por segundo y SOLO cuando cambia. Un nombre de calle no cambia
     treinta veces por segundo, y mandarlo igualmente obligaria al navegador a
     rehacer el texto en cada aviso para escribir lo mismo. ]]
CreateThread(function()
    local calleAnt, cardinalAnt, zonaAnt

    while true do
        if not encendido then
            Wait(500)
        else
            local ped = PlayerPedId()
            local aqui = GetEntityCoords(ped)
            local calle = CalleDe(aqui)
            local zona = ZonaDe(aqui)
            local cardinal = CardinalDe(GetEntityHeading(ped))

            --- El barrio cuenta: se cambia de barrio sin cambiar de calle.
            if calle ~= calleAnt or cardinal ~= cardinalAnt or zona ~= zonaAnt then
                calleAnt, cardinalAnt, zonaAnt = calle, cardinal, zona
                SendNUIMessage({ accion = 'sitio', calle = calle, zona = zona, cardinal = cardinal })
            end

            Wait(500)
        end
    end
end)

--[[ ── Los blips de alrededor ─────────────────────────────────────────

     Va en su propio hilo y a su propio ritmo: los blips no se mueven al ritmo
     al que te mueves tu, asi que recorrerlos 30 veces por segundo seria tirar
     trabajo. Cada 700 ms no se nota y cuesta la decima parte.

     El corte por distancia se hace con la distancia AL CUADRADO: es la misma
     comparacion sin la raiz cuadrada, y aqui se hace una por blip. ]]
--[[ Las categorias que el jugador ha apagado en el mapa grande (29/09): lo que
     escondes alli tampoco sale aqui. Las manda el mapa grande del inventario
     cada vez que cambian y al abrirse; se guardan en el KVP para que sigan
     escondidas al reconectar sin tener que abrir el mapa grande. ]]
local KVP_OCULTAS = 'origen_map:ocultas'
local ocultas = {}
do
    local ok, lista = pcall(json.decode, GetResourceKvpString(KVP_OCULTAS) or '[]')
    if ok and type(lista) == 'table' then
        for _, id in ipairs(lista) do
            if type(id) == 'string' then ocultas[id] = true end
        end
    end
end

AddEventHandler('origen_map:ponerOcultas', function(lista)
    if type(lista) ~= 'table' then return end
    local nuevas, guardar = {}, {}
    for _, id in ipairs(lista) do
        -- Un id de categoria es corto; mas de 60 no hay.
        if type(id) == 'string' and #id <= 40 and not nuevas[id] and #guardar < 60 then
            nuevas[id] = true
            guardar[#guardar + 1] = id
        end
    end
    ocultas = nuevas
    SetResourceKvp(KVP_OCULTAS, json.encode(guardar))
end)

CreateThread(function()
    while true do
        if not encendido then
            Wait(500)
        else
            local yo = GetEntityCoords(PlayerPedId())
            local tope = Config.blipsRadio * Config.blipsRadio

            local lista, vistos = {}, {}

            --[[ ── Lo que hay registrado ─────────────────────────────────

                 Esta es ahora la fuente de verdad: los recursos dicen que
                 quieren marcar (client/registro.lua) y aqui solo se pide lo de
                 alrededor, ya ordenado por cercania y con el tope aplicado.

                 El rastreo de sprites que viene despues es lo que queda de la
                 forma antigua, y solo recoge lo que todavia no ha pasado por
                 el registro. ]]
            for _, par in ipairs(OrigenMapRegistro.Cerca(
                yo.x, yo.y, Config.blipsRadio, Config.blipsTope)) do
                local p, distancia = par[1], par[2]

                vistos[('%d:%d:%s'):format(
                    math.floor(p.x / 5), math.floor(p.y / 5), p.cat)] = true

                --[[ `or false` y no dejarlo a nil: una tabla de Lua con un
                     hueco en medio deja de ser una lista, y al convertirla a
                     JSON sale un objeto con claves numericas en vez de un
                     array. La interfaz, que la desmonta por posiciones, se
                     quedaba sin nada. ]]
                if not ocultas[p.cat] then lista[#lista + 1] = {
                    p.x, p.y, p.cat, p.icono, distancia,
                    p.nombre or false, p.estado or false,
                    p.color or false, p.radio or false,
                    false, false, -- spriteUrl y sprite, que solo lleva policia
                    p.pulso or false,
                } end
            end

            for _, cat in ipairs(CATEGORIAS) do
                -- Apagada en el mapa grande: sin chinchetas y sin rastrear.
                for _, sprite in ipairs(ocultas[cat.id] and {} or cat.sprites) do
                    local blip = GetFirstBlipInfoId(sprite)

                    while DoesBlipExist(blip) and #lista < Config.blipsTope do
                        local p = GetBlipInfoIdCoord(blip)
                        local dx, dy = p.x - yo.x, p.y - yo.y

                        local d2 = dx * dx + dy * dy
                        if d2 <= tope then
                            --[[ El juego apila varios blips en el mismo sitio
                                 —las gasolineras llevan tres—, y en el mapa
                                 serian una marca encima de otra. Se redondea a
                                 5 m y se queda el primero. ]]
                            local clave = ('%d:%d:%s'):format(
                                math.floor(p.x / 5), math.floor(p.y / 5), cat.id)

                            if not vistos[clave] then
                                vistos[clave] = true
                                --[[ Va tambien la distancia, redondeada a
                                     metros: con ella el navegador agranda la
                                     chincheta segun te acercas. Sale gratis
                                     -- la cuenta ya estaba hecha para el
                                     filtro de arriba, solo faltaba la raiz. ]]
                                lista[#lista + 1] = {
                                    math.floor(p.x * 10) / 10,
                                    math.floor(p.y * 10) / 10,
                                    cat.id,
                                    cat.icono,
                                    math.floor(math.sqrt(d2)),
                                }
                            end
                        end

                        blip = GetNextBlipInfoId(sprite)
                    end
                end
            end

            --[[ Y encima de todo, los avisos de policia: sin filtro de distancia y
                 sin contar para el tope, que es justo lo que los distingue de
                 una gasolinera. ]]
            for _, p in ipairs(PuntosDeAvisos() or {}) do
                local dx, dy = p.x - yo.x, p.y - yo.y
                if not ocultas[p.cat] then lista[#lista + 1] = {
                    math.floor(p.x * 10) / 10,
                    math.floor(p.y * 10) / 10,
                    p.cat,
                    p.icono,
                    math.floor(math.sqrt(dx * dx + dy * dy)),
                    p.nombre or false,
                    false, -- estado
                    p.color or false,
                    false, -- radio
                    p.spriteUrl or false,
                    p.sprite or false,
                    false, -- pulso
                } end
            end

            SendNUIMessage({ accion = 'blips', puntos = lista })
            Wait(Config.blipsCadaMs)
        end
    end
end)

--[[ ── Las referencias policiales dinámicas ───────────────────────────

     A diferencia de las tiendas y gasolineras, las unidades de policía se
     mueven en tiempo real y a alta velocidad (persecuciones).

     Para evitar saltos y tirones visuales ("a saltos"), este hilo adapta
     su frecuencia según la proximidad del compañero más cercano:
       · < 50 m:  50 ms (20 Hz, máxima fluidez para patrullas en convoy)
       · < 100 m: 80 ms (12.5 Hz)
       · < 200 m: 150 ms (6.6 Hz)
       · < 350 m: 250 ms (4 Hz)
       · < 500 m: 400 ms (2.5 Hz)
       · Lejos o sin unidades: 650 ms (ahorro de recursos) ]]
CreateThread(function()
    while true do
        if not encendido then
            Wait(500)
        else
            local ped = PlayerPedId()
            local yo = GetEntityCoords(ped)
            local puntos, distMin = ReferenciasDePolicia(yo)

            local espera = 650
            if distMin then
                if distMin < 50.0 then
                    espera = 50
                elseif distMin < 100.0 then
                    espera = 80
                elseif distMin < 200.0 then
                    espera = 150
                elseif distMin < 350.0 then
                    espera = 250
                elseif distMin < 500.0 then
                    espera = 400
                else
                    espera = 650
                end
            end

            if puntos then
                SendNUIMessage({
                    accion = 'referencias',
                    puntos = puntos,
                    ms = espera
                })
            end

            Wait(espera)
        end
    end
end)

--- El fps se mide por fotograma; es una division y un hueco de tabla. Va
--- dentro del vigilante de abajo, que ya corre cada fotograma: un hilo
--- aparte solo para esto era un despertar mas por fotograma.

--[[ ── El vigilante ────────────────────────────────────────────────────

     Dos cosas que hay que reafirmar mientras el mapa esta puesto, porque otro
     recurso las deshace:

     1. EL RADAR ENCENDIDO. origen_hud lo apaga en cuanto te bajas del coche
        (client/vehicle.lua: lib.onCache("vehicle") -> else DisplayRadar(false)),
        y GTA solo calcula la ruta del GPS con el radar encendido. Sin esto, el
        trazado desaparecia del minimapa al poner un pie en la calle -- que es
        justo cuando mas falta hace saber por donde ir.

        Encendido no quiere decir a la vista: sigue empujado fuera de la
        pantalla. Lo unico que se aprovecha de el es la cuenta de la ruta.

     2. SU SITIO. origen_hud recoloca el minimapa al cambiar la resolucion.

     CADA FOTOGRAMA MIENTRAS ESTA PUESTO, Y NO CADA MEDIO SEGUNDO

     Al montarte en un coche se veia el minimapa de GTA en su sitio antes de
     que apareciera el nuestro. No era cosa de un fotograma suelto: era hasta
     medio segundo, y por dos relojes distintos.

     Lo que pasa al entrar en un vehiculo:

       1. origen_hud enciende el radar en el acto -- lib.onCache('vehicle').
       2. GTA cambia el minimapa a su version de coche, que es OTRA
          disposicion: al hacerlo REPONE la posicion de los componentes, y con
          ella el que teniamos empujado fuera de la pantalla vuelve al suyo.
       3. Y este hilo no lo apartaba hasta el siguiente repaso.

     Con medio segundo entre repasos, ese paso 3 llegaba tarde y se veia. No
     hay forma de enterarse de que GTA ha repuesto la posicion --no avisa-- asi
     que la unica manera de que no se vea NI UN fotograma es reafirmarla en
     todos.

     Y APARTADO SIEMPRE, NO SOLO CON EL MAPA PUESTO

     A pie el mapa esta apagado, asi que un reafirmado que solo corriera con el
     puesto llegaba justo cuando ya no servia: el radar lo enciende origen_hud
     al montarte, GTA repone la posicion en ese mismo instante, y nuestro mapa
     todavia no esta encendido. Se aparta en todos los fotogramas, este puesto o
     no; lo unico que se salta es cuando el jugador ha pedido el de GTA a mano
     con /mapavanilla.

     Y el repaso de si toca verse va aqui tambien, y no con su propio reloj de
     250 ms: apartado el de GTA, ese cuarto de segundo se veia igual de mal —sin
     ningun minimapa en vez de con el equivocado—.

     Son cuatro natives por fotograma. Es lo que cuesta que no se vea ni uno. ]]
CreateThread(function()
    while true do
        Wait(0)

        ApuntarFps()
        Repasar()

        if not vanillaVisible then ColocarVanilla(false) end
        if encendido then DisplayRadar(true) end
    end
end)

--- ── Comandos ────────────────────────────────────────────────────────────
RegisterCommand('mapa', function()
    -- A mano manda el jugador: mientras este apagado asi, el repaso no lo
    -- vuelve a poner aunque se monte en un coche.
    apagadoAMano = encendido
    Encender(not encendido, true)
    print(('[origen_map] mapa %s'):format(encendido and 'encendido' or 'apagado a mano'))
end, false)

RegisterCommand('mapavanilla', function()
    vanillaVisible = not vanillaVisible
    ColocarVanilla(vanillaVisible)
    print(('[origen_map] minimapa de GTA %s'):format(vanillaVisible and 'a la vista' or 'fuera'))
end, false)

--- La tira de cifras encima del mapa: fuera salvo que se pida.
local medidaVisible = false

RegisterCommand('mapamedida', function()
    medidaVisible = not medidaVisible
    SendNUIMessage({ accion = 'medida', ver = medidaVisible })
    print(('[origen_map] cifras %s'):format(medidaVisible and 'a la vista' or 'fuera'))
end, false)

--[[ Los estilos de la linea de la ruta, para poder verlos en el juego y
     elegir. Se guarda el elegido para que aguante los reinicios del recurso. ]]
local ESTILOS = { 'neon', 'ribete', 'bloque', 'cable', 'degradado', 'solida', 'nucleo', 'chevrones', 'desvanecida' }

RegisterCommand('mapalinea', function(_, args)
    local n = tonumber(args[1])
    local nombre = n and ESTILOS[n] or args[1]

    local vale = false
    for _, e in ipairs(ESTILOS) do if e == nombre then vale = true end end

    if not vale then
        print('[origen_map] uso: /mapalinea <1-9>')
        for i, e in ipairs(ESTILOS) do print(('  %d  %s'):format(i, e)) end
        return
    end

    SendNUIMessage({ accion = 'estiloRuta', estilo = nombre })
    SetResourceKvp('origen_map:linea', nombre)
    -- Los ajustes se leen de memoria (ver LeerAjuste): sin esto, el siguiente
    -- repaso volvia a poner la linea de antes hasta reiniciar el recurso.
    ajustesLeidos.linea = nombre
    print(('[origen_map] linea: %s'):format(nombre))
end, false)

RegisterCommand('mapahz', function(_, args)
    local n = tonumber(args[1])
    if not n or n < 1 or n > 60 then
        print('[origen_map] uso: /mapahz <1-60>')
        return
    end
    Config.hz = math.floor(n)
    BorrarFps()
    print(('[origen_map] %d posiciones por segundo'):format(Config.hz))
end, false)

--[[ La medida que decide si esto vale la pena. Se usa asi:

       1. quieto en un sitio con el mapa apagado -> /mapafps
       2. /mapa y esperar unos segundos en el MISMO sitio -> /mapafps

     La diferencia entre las dos cifras es lo que cuesta el mapa. Hay que medir
     quieto y en el mismo punto: mirando al mar y mirando al centro hay mas
     diferencia de fps que la que va a meter ningun mapa. ]]
RegisterCommand('mapafps', function()
    print(('[origen_map] %.1f fps de media (%d muestras) - mapa %s - %d Hz')
        :format(MediaFps(), fps.n, encendido and 'ENCENDIDO' or 'apagado', Config.hz))
    BorrarFps()
    print('[origen_map] contador a cero: deja pasar unos segundos y vuelve a pedirlo')
end, false)

--[[ Al parar el recurso hay que devolver el minimapa de GTA a su sitio: si no,
     quitar origen_map dejaria al jugador sin ningun minimapa y sin ninguna
     pista de por que. ]]
AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    -- Parado a mitad de colocar la caja: el raton no puede quedarse puesto.
    if posicionando then
        posicionando = false
        SetNuiFocus(false, false)
    end
    ColocarVanilla(true)
    DisplayRadar(IsPedInAnyVehicle(PlayerPedId(), false))
end)

--[[ ── Ponerlo al entrar ────────────────────────────────────────────────

     Dos disparos y no uno a proposito:

       - al arrancar el recurso, para que un "ensure origen_map" con la partida
         ya empezada lo devuelva sin tener que reconectar;
       - al cargar el personaje, porque origen_hud hace DisplayRadar(false) en
         ese mismo evento y si solo estuviera el primero nos lo apagaria justo
         despues.

     Encender() dos veces no molesta: deja lo mismo que la primera. ]]
local function Arrancar()
    -- Ya no enciende a secas: pregunta si toca. Con el ajuste de fabrica, a pie
    -- no toca, y el mapa aparece solo al montarse.
    apagadoAMano = false
    Repasar()
end

CreateThread(function()
    Wait(2000)
    Arrancar()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(1500)
    Arrancar()
end)
