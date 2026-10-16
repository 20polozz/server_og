--[[ ═══════════════════════════════════════════════════════════════════════
     El registro de puntos del mapa

     Aqui es donde ahora vive TODO lo que sale marcado en el mapa del servidor.
     Antes cada recurso llamaba a AddBlipForCoord y los tres mapas de Leaflet
     —este minimapa, el del menu de pausa y la pestaña de Ciudad del
     inventario— recorrian los blips del juego por numero de sprite para
     enterarse de que habia.

     Eso tenia tres agujeros que no se podian tapar desde el que rastreaba:

       1. DEL SPRITE NO SE SABE EL NOMBRE. No hay ningun native que devuelva
          como se llama un blip, asi que el nombre habia que inventarselo de
          una tabla de numeros: todos los garajes del mapa se llamaban
          «Garaje», y un sitio con nombre propio —«El chatarrero del puerto»—
          era imposible.

       2. UNA CATEGORIA NUEVA HABIA QUE APUNTARLA EN CUATRO SITIOS. La lista de
          sprites estaba copiada en cada mapa, y las copias se fueron por su
          lado.

       3. EL SPRITE SE ELIGE EN UN PANEL. En cuanto un recurso dejaba cambiar
          el dibujo de su blip desde su administracion, el punto desaparecia de
          los mapas sin que nada lo explicara, porque el numero que buscaban ya
          no era ese. (origen_phone tuvo que sacar un export solo para esto.)

     Ahora es al reves: el recurso DICE lo que quiere marcar —donde, de que
     categoria, como se llama— y los mapas leen de aqui. El blip del juego ya
     no se crea.

     ── Como se usa ────────────────────────────────────────────────────────

         exports.origen_map:Poner('garaje_pillbox', {
             x = 215.0, y = -810.0, z = 30.0,
             cat = 'garages',
             nombre = 'Garaje Pillbox Hill',
         })

         exports.origen_map:Quitar('garaje_pillbox')

     Y para una tanda entera de golpe, que es lo normal al arrancar:

         exports.origen_map:PonerVarios('garaje', lista)   -- lista de puntos

     La clave se guarda con el nombre del recurso delante, asi que dos recursos
     pueden usar la misma sin pisarse. Y al parar un recurso se van solos todos
     sus puntos: no hay que acordarse de limpiarlos.

     Quien no quiera depender de este recurso puede mandar un evento en vez de
     llamar al export:

         TriggerEvent('origen_map:poner', 'mirecurso:algo', punto)
         TriggerEvent('origen_map:quitar', 'mirecurso:algo')

     Que es justo lo que hace shared/marcar.lua, el ayudante que cargan los
     demas recursos y que ademas les pone solo el nombre delante de la clave.

     ── Que lleva un punto ─────────────────────────────────────────────────

       x, y, z     donde esta. Obligatorio salvo que siga a una entidad.
       cat         la categoria (ver shared/categorias.lua). Si no se dice,
                   cae en 'public', que es el cajon de sastre.
       nombre      como se llama. Es lo que se lee en la lista del mapa grande.
       icono       el dibujo de la chincheta. Por defecto el de su categoria.
       estado      'abierto' | 'cerrado' | nil. Lo usan los locales.
       entidad     un handle: el punto va detras de esa entidad y se borra solo
                   cuando deja de existir. Para coches, mascotas, unidades.
       jugador     un server id: como `entidad`, pero resolviendo el ped desde
                   el id, que es lo que se tiene cuando el otro esta lejos.
       radio       si lleva, se pinta un circulo y no una chincheta (zonas).
       color       '#rrggbb' para pintarlo de otro color que el de su categoria.
       ruta        true si este punto tiene que marcar el camino del GPS.
                   Ver mas abajo: es lo unico que sigue creando un blip.
       minimapa    false para que NO salga en el minimapa (solo en el grande).
       mapa        false para que NO salga en el mapa grande (solo en el mini).
       prioridad   los de numero mas alto no se quedan fuera cuando se llena el
                   tope del minimapa. De fabrica 0; los avisos van a 10.
       pulso       true para que la chincheta lata en los dos mapas. Solo para
                   lo que dura poco y hay que ver ahora: si late todo, no late
                   nada.

     ── Lo unico que sigue siendo un blip de verdad ────────────────────────

     La ruta del GPS. GTA no sabe trazar un camino por carretera hasta unas
     coordenadas: sabe trazarlo hasta un BLIP que tenga la ruta puesta, y ese
     trazado es justo lo que el mapa dibuja (GetPosAlongGpsTypeRoute).

     Asi que un punto con `ruta = true` crea por debajo un blip con alpha 0:
     invisible en el mapa del juego, pero suficiente para que el juego calcule
     el camino. No es una excepcion a lo de arriba —no marca nada— es la
     manivela del GPS.
   ═══════════════════════════════════════════════════════════════════════ ]]

--- Los puntos, por clave. La clave ya viene con el recurso delante.
local Puntos = {}

--- De que recurso es cada clave, para poder barrerlos todos cuando pare.
local Duenno = {}

--[[ Las claves de los puntos que siguen a una entidad o a un jugador.

     Para que el hilo de los puntos que se mueven no recorra toda la lista cada
     500 ms. Si una clave se queda aqui de mas, el propio hilo la suelta al ver
     que el punto ya no existe o ya no sigue a nada. ]]
local Moviles = {}

local function MarcarMovil(k, punto)
    Moviles[k] = (punto and (punto.entidad or punto.jugador)) and true or nil
end

--- Los blips invisibles de las rutas, por clave.
local BlipsDeRuta = {}

--- Las claves con ruta, en el orden en que se pusieron.
local OrdenDeRutas = {}

--- El icono y la etiqueta de cada categoria, sacados del catalogo compartido.
local PorCategoria = {}
for _, c in ipairs(OrigenMapCategorias or {}) do PorCategoria[c.id] = c end

--- Cuantos cambios lleva el registro. Los mapas lo miran para no rehacer la
--- lista entera cuando no ha pasado nada.
local version = 0

--[[ El barrio, que es lo que de verdad situa a un punto en la lista.

     "Rockford Hills" te coloca; "Garaje" repetido cuarenta veces no. Se calcula
     aqui y no en cada recurso para que todos los puntos lo lleven igual. ]]
local function BarrioDe(x, y, z)
    local zona = GetNameOfZone(x + 0.0, y + 0.0, (z or 0.0) + 0.0)
    if not zona then return nil end
    local nombre = GetLabelText(zona)
    if not nombre or nombre == '' or nombre == 'NULL' then return nil end
    return nombre
end

--[[ El blip invisible de la ruta.

     alpha 0 y no SetBlipDisplay(0): con display 0 el juego deja de tener en
     cuenta el blip para el GPS y la ruta no se calcula. Con alpha 0 el blip
     sigue contando para todo menos para verse, que es exactamente lo que hace
     falta. ]]
local function PonerRuta(clave, p)
    local b = BlipsDeRuta[clave]

    if b and DoesBlipExist(b) then
        --[[ Mismo sitio: nada que hacer. Sitio NUEVO: el blip se tira y se
             hace otro (20/09). Moverlo con SetBlipCoords no vale: el juego
             calcula el camino al poner la ruta y no lo rehace porque el blip
             cambie de coordenadas, asi que la chincheta saltaba al punto
             siguiente y la linea seguia llevando al ANTERIOR. Se vio en el
             examen de conducir, que es el primero que encadena puntos con la
             misma clave: la raya tiraba para atras con el punto delante. ]]
        local c = GetBlipCoords(b)
        if math.abs(c.x - p.x) < 0.5 and math.abs(c.y - p.y) < 0.5 then return end
        RemoveBlip(b)
        BlipsDeRuta[clave] = nil
        for i = #OrdenDeRutas, 1, -1 do
            if OrdenDeRutas[i] == clave then table.remove(OrdenDeRutas, i) end
        end
    end

    b = AddBlipForCoord(p.x + 0.0, p.y + 0.0, (p.z or 0.0) + 0.0)
    SetBlipSprite(b, 1)
    SetBlipAlpha(b, 0)
    SetBlipRoute(b, true)
    SetBlipRouteColour(b, 5)
    BlipsDeRuta[clave] = b
    OrdenDeRutas[#OrdenDeRutas + 1] = clave
end

local function QuitarRuta(clave)
    local b = BlipsDeRuta[clave]
    if not b then return end
    if DoesBlipExist(b) then RemoveBlip(b) end
    BlipsDeRuta[clave] = nil

    for i = #OrdenDeRutas, 1, -1 do
        if OrdenDeRutas[i] == clave then table.remove(OrdenDeRutas, i) end
    end
end

--[[ La ruta que se esta siguiendo, si la ha puesto un punto de aqui.

     La ultima puesta es la que manda en el GPS. La lee el mapa del menu de
     pausa: sin esto una ruta de un trabajo existia en el juego y en el
     minimapa, pero el mapa grande no se enteraba y salia vacio. ]]
local function RutaPuesta()
    local clave = OrdenDeRutas[#OrdenDeRutas]
    if not clave then return nil end

    local b = BlipsDeRuta[clave]
    if not b or not DoesBlipExist(b) then return nil end

    local c = GetBlipCoords(b)
    local p = Puntos[clave] or {}

    return { x = c.x, y = c.y, nombre = p.nombre }
end

--[[ Normaliza lo que manda el recurso.

     Se hace al guardar y no al leer: un punto se guarda una vez y se lee
     muchas veces entre los tres mapas. ]]
local function Preparar(clave, p, recurso)
    if type(p) ~= 'table' then return nil end

    local cat = p.cat or p.categoria or 'public'
    local meta = PorCategoria[cat] or PorCategoria['public']

    local x = tonumber(p.x)
    local y = tonumber(p.y)

    --[[ Sin coordenadas solo vale si va detras de algo: entonces las pone el
         hilo que sigue a las entidades, en cuanto ese algo exista. ]]
    if (not x or not y) and not (p.entidad or p.jugador) then return nil end

    local punto = {
        clave     = clave,
        recurso   = recurso,
        x         = x and (math.floor(x * 10) / 10) or nil,
        y         = y and (math.floor(y * 10) / 10) or nil,
        z         = tonumber(p.z) and (math.floor(tonumber(p.z) * 10) / 10) or 0.0,
        cat       = cat,
        catLabel  = p.catLabel or (meta and meta.label) or 'Servicios',
        icono     = p.icono or (meta and meta.icono) or 'edificio',
        estado    = p.estado,
        entidad   = p.entidad,
        jugador   = p.jugador,
        radio     = tonumber(p.radio),
        color     = p.color,
        ruta      = p.ruta and true or false,
        minimapa  = p.minimapa ~= false,
        mapa      = p.mapa ~= false,
        prioridad = tonumber(p.prioridad) or 0,

        --[[ Late en los dos mapas. Para lo que dura poco y hay que ver ahora:
             una carrera que acaban de lanzar, algo que se cierra en dos
             minutos. Un punto de siempre NO lleva pulso —si late todo, no
             late nada— y por eso no se hereda de la categoria: lo pide el
             recurso punto por punto. ]]
        pulso     = p.pulso and true or false,

        --[[ De ESTE jugador y no del mundo: un sitio de mision que ha
             descubierto el, un marcador que ha puesto el. Los mapas de Leaflet
             lo pintan distinto (`pm-pin es-mio`).

             Va aqui y no lo decide cada mapa por su cuenta porque quien sabe
             si algo es personal es el recurso que lo pone, no el que lo
             dibuja. ]]
        propio    = p.propio and true or false,
    }

    --[[ El barrio y el nombre.

         El barrio se pega al nombre solo cuando el recurso NO ha dado uno: si
         el sitio se llama «El chatarrero del puerto», ese es su nombre y
         añadirle el barrio detras lo estropea. Cuando no hay nombre, lo unico
         que distingue un punto de otro de su categoria es donde esta. ]]
    if punto.x and punto.y then
        punto.barrio = p.barrio or BarrioDe(punto.x, punto.y, punto.z)
    end

    punto.nombre = p.nombre or p.label
    if not punto.nombre then
        local base = OrigenMapSingular[cat] or punto.catLabel
        punto.nombre = base .. (punto.barrio and (' ' .. punto.barrio) or '')
    end

    return punto
end

--- Con el nombre del recurso delante, para que dos recursos no se pisen.
local function ClaveDe(recurso, clave)
    clave = tostring(clave or '')
    if clave:find(':', 1, true) then return clave end
    return recurso .. ':' .. clave
end

--[[ ══ La puerta de entrada ═══════════════════════════════════════════════ ]]

--- Da de alta un punto, o actualiza el que ya hubiera con esa clave.
local function Poner(clave, p, recurso)
    recurso = recurso or GetInvokingResource() or GetCurrentResourceName()
    local k = ClaveDe(recurso, clave)

    local punto = Preparar(k, p, recurso)
    if not punto then return false end

    Puntos[k] = punto
    Duenno[k] = recurso
    MarcarMovil(k, punto)
    version = version + 1

    if punto.ruta and punto.x then PonerRuta(k, punto) else QuitarRuta(k) end
    return true
end

--[[ Cambia SOLO el color de un punto que ya esta puesto.

     Existe porque hay sitios que no marcan una cosa distinta, sino la MISMA
     cosa en otro estado: un arbol que acabas de talar, una roca en espera. Con
     blips eso era un SetBlipColour suelto, y obligar a esos sitios a volver a
     mandar el punto entero —coordenadas incluidas, que muchas veces ya no
     tienen a mano— seria pedirles que se guarden datos que no son suyos. ]]
local function Tintar(clave, color, recurso)
    recurso = recurso or GetInvokingResource() or GetCurrentResourceName()
    local p = Puntos[ClaveDe(recurso, clave)]
    if not p then return false end

    p.color = color
    version = version + 1
    return true
end

--- Quita un punto.
local function Quitar(clave, recurso)
    recurso = recurso or GetInvokingResource() or GetCurrentResourceName()
    local k = ClaveDe(recurso, clave)

    if not Puntos[k] then return false end
    Puntos[k] = nil
    Duenno[k] = nil
    Moviles[k] = nil
    QuitarRuta(k)
    version = version + 1
    return true
end

--[[ Una tanda entera de golpe, que es lo normal: un recurso arranca y pone sus
     cuarenta gasolineras.

     Y REEMPLAZA la tanda anterior con ese prefijo, en vez de sumarse a ella.
     Es lo que se espera al recargar una lista desde el panel de
     administracion: los que ya no esten tienen que irse solos, y obligar a
     cada recurso a acordarse de barrer antes era pedir que alguien se
     olvidara. ]]
local function PonerVarios(prefijo, lista, recurso)
    recurso = recurso or GetInvokingResource() or GetCurrentResourceName()
    if type(lista) ~= 'table' then return 0 end

    local raiz = ClaveDe(recurso, prefijo) .. '#'

    for k in pairs(Puntos) do
        if k:sub(1, #raiz) == raiz then
            Puntos[k] = nil
            Duenno[k] = nil
            Moviles[k] = nil
            QuitarRuta(k)
        end
    end

    local n = 0
    for i, p in ipairs(lista) do
        --[[ La clave la elige el recurso si el punto trae `id`; si no, el
             numero de orden. Con `id` un punto conserva su clave aunque la
             lista se reordene, que importa cuando algo lo esta apuntando. ]]
        local k = raiz .. tostring(p.id or i)
        local punto = Preparar(k, p, recurso)
        if punto then
            Puntos[k] = punto
            Duenno[k] = recurso
            MarcarMovil(k, punto)
            if punto.ruta and punto.x then PonerRuta(k, punto) end
            n = n + 1
        end
    end

    version = version + 1
    return n
end

--- Barre todos los puntos de un recurso.
local function QuitarTodos(recurso)
    recurso = recurso or GetInvokingResource() or GetCurrentResourceName()
    local hubo = false

    for k, r in pairs(Duenno) do
        if r == recurso then
            Puntos[k] = nil
            Duenno[k] = nil
            Moviles[k] = nil
            QuitarRuta(k)
            hubo = true
        end
    end

    if hubo then version = version + 1 end
    return hubo
end

--[[ ══ Lo que leen los mapas ══════════════════════════════════════════════ ]]

--- Todos los puntos que tocan al mapa grande.
local function TodosLosPuntos()
    local lista = {}
    for _, p in pairs(Puntos) do
        if p.mapa and p.x and p.y then lista[#lista + 1] = p end
    end
    return lista
end

--[[ Los de alrededor, para el minimapa.

     El corte se hace con la distancia AL CUADRADO —la misma comparacion sin la
     raiz— porque aqui se hace una por punto y esto corre cada 700 ms.

     Los de prioridad alta —un aviso de policia— no cuentan para el tope ni
     para el radio: un aviso al otro lado de la ciudad importa mas que la
     tienda de la esquina. ]]
local function Cerca(x, y, radio, tope)
    radio = tonumber(radio) or 420.0
    tope = tonumber(tope) or 70

    local limite = radio * radio
    local dentro, sinFiltro = {}, {}

    for _, p in pairs(Puntos) do
        if p.minimapa and p.x and p.y then
            local dx, dy = p.x - x, p.y - y
            local d2 = dx * dx + dy * dy

            if p.prioridad > 0 then
                sinFiltro[#sinFiltro + 1] = { p, d2 }
            elseif d2 <= limite then
                dentro[#dentro + 1] = { p, d2 }
            end
        end
    end

    --- Los mas cercanos primero: si hay que recortar, que se quede lo de al lado.
    table.sort(dentro, function(a, b) return a[2] < b[2] end)

    local salida = {}
    for i = 1, math.min(#dentro, tope) do
        salida[#salida + 1] = { dentro[i][1], math.floor(math.sqrt(dentro[i][2])) }
    end

    --- Y los de prioridad encima, sin contar para el tope.
    for _, par in ipairs(sinFiltro) do
        salida[#salida + 1] = { par[1], math.floor(math.sqrt(par[2])) }
    end

    return salida
end

--[[ ══ Los puntos que se mueven ═══════════════════════════════════════════

     Un punto puede ir detras de una entidad —una unidad de policia, un coche
     robado, una mascota— y entonces sus coordenadas no son un dato, son una
     pregunta que hay que repetir.

     Cada 500 ms y no por fotograma: en el mapa un punto que se mueve medio
     segundo tarde no se nota, y esto recorre la lista entera. Los puntos
     quietos —que son casi todos— no pasan por aqui. ]]
CreateThread(function()
    while true do
        Wait(500)

        local cambio = false

        -- Solo los que siguen a algo (Moviles), no la lista entera.
        for k in pairs(Moviles) do
            local p = Puntos[k]
            if not p or not (p.entidad or p.jugador) then
                Moviles[k] = nil
            else
                local ent = p.entidad

                if p.jugador then
                    local idx = GetPlayerFromServerId(p.jugador)
                    ent = (idx ~= -1) and GetPlayerPed(idx) or nil
                end

                --[[ La entidad ha dejado de existir: el coche se ha destruido,
                     el jugador se ha ido. El punto se va con ella; un punto
                     clavado donde estaba algo que ya no esta miente. ]]
                if not ent or ent == 0 or not DoesEntityExist(ent) then
                    Puntos[k] = nil
                    Duenno[k] = nil
                    Moviles[k] = nil
                    QuitarRuta(k)
                    cambio = true
                else
                    local c = GetEntityCoords(ent)
                    p.x = math.floor(c.x * 10) / 10
                    p.y = math.floor(c.y * 10) / 10
                    p.z = math.floor(c.z * 10) / 10
                    p.rumbo = math.floor(GetEntityHeading(ent))
                    if p.ruta then PonerRuta(k, p) end
                    cambio = true
                end
            end
        end

        if cambio then version = version + 1 end
    end
end)

--[[ ── Cuando un recurso para ────────────────────────────────────────────

     Sin esto, reiniciar un recurso dejaba sus puntos en el mapa para siempre y
     al volver a arrancar los ponia otra vez: cada restart duplicaba la ciudad.

     Va por onClientResourceStop y no por el `onResourceStop` de cada uno: asi
     no hay que acordarse de escribirlo en cuarenta recursos. ]]
AddEventHandler('onClientResourceStop', function(recurso)
    QuitarTodos(recurso)
end)

--[[ ── Los eventos, para quien no quiera llamar al export ────────────────

     Un export falla en seco si el recurso no esta arrancado; un evento se cae
     al vacio sin ruido. Para un recurso que solo quiere marcar un sitio eso es
     lo que se quiere: que la falta del mapa no se lleve por delante lo demas.

     Aqui no hay GetInvokingResource —los eventos no lo tienen— asi que la
     clave tiene que traer el recurso delante ella misma. ]]
AddEventHandler('origen_map:poner', function(clave, punto)
    local recurso = tostring(clave or ''):match('^([^:]+):') or 'desconocido'
    Poner(clave, punto, recurso)
end)

AddEventHandler('origen_map:tintar', function(clave, color)
    local recurso = tostring(clave or ''):match('^([^:]+):') or 'desconocido'
    Tintar(clave, color, recurso)
end)

AddEventHandler('origen_map:quitar', function(clave)
    local recurso = tostring(clave or ''):match('^([^:]+):') or 'desconocido'
    Quitar(clave, recurso)
end)

AddEventHandler('origen_map:ponerVarios', function(prefijo, lista)
    local recurso = tostring(prefijo or ''):match('^([^:]+):') or 'desconocido'
    PonerVarios(prefijo, lista, recurso)
end)

--[[ Para el resto de ficheros de ESTE recurso.

     main.lua pinta el minimapa cada 700 ms y podria preguntarlo por el export,
     pero un export es una llamada entre recursos aunque el recurso sea el
     mismo. Aqui se pasa la funcion tal cual. ]]
OrigenMapRegistro = {
    Cerca = Cerca,
    Puntos = TodosLosPuntos,
}

--[[ ══ Los exports ════════════════════════════════════════════════════════ ]]

exports('Poner', function(clave, punto) return Poner(clave, punto) end)
exports('Quitar', function(clave) return Quitar(clave) end)
exports('Tintar', function(clave, color) return Tintar(clave, color) end)
exports('PonerVarios', function(prefijo, lista) return PonerVarios(prefijo, lista) end)
exports('QuitarTodos', function() return QuitarTodos() end)

--- Para el mapa grande y la pestaña de Ciudad: todo, ya con nombre y barrio.
exports('Puntos', TodosLosPuntos)

--- Para el minimapa: solo lo de alrededor, ya ordenado y con la distancia.
exports('PuntosCerca', function(x, y, radio, tope) return Cerca(x, y, radio, tope) end)

--- El catalogo de categorias, para que los mapas pinten la leyenda sin volver
--- a copiarse la lista.
exports('Categorias', function()
    local copia = {}
    for i, c in ipairs(OrigenMapCategorias or {}) do
        copia[i] = { id = c.id, label = c.label, icono = c.icono }
    end
    return copia
end)

--- Un numero que sube con cada cambio. Un mapa que ya tenga la lista puede
--- preguntar esto y ahorrarse rehacerla si no ha subido.
exports('VersionDelMapa', function() return version end)

--[[ Obliga al juego a calcular otra vez la ruta que manda.

     Quitar y poner la ruta del mismo blip: el juego la traza de nuevo desde
     donde estes. Lo pide main.lua cuando ve que la linea se ha quedado en el
     camino viejo (te has saltado un giro y el juego no la ha rehecho). ]]
function RegistroRehacerRuta()
    local clave = OrdenDeRutas[#OrdenDeRutas]
    local b = clave and BlipsDeRuta[clave]
    if not b or not DoesBlipExist(b) then return false end

    SetBlipRoute(b, false)
    SetBlipRoute(b, true)
    SetBlipRouteColour(b, 5)
    return true
end

--- La ruta que pone un punto de este registro, para el mapa grande.
exports('RutaPuesta', function() return RutaPuesta() end)
--- Y para main.lua, que la necesita para poner el destino en el minimapa.
RegistroRutaPuesta = RutaPuesta

--[[ ── Avisar de que ya estamos ─────────────────────────────────────────

     Los demas recursos ponen sus puntos al arrancar, una vez. Si este llega
     despues —o si alguien lo reinicia a mano— ese aviso ya paso y el mapa se
     quedaria vacio para siempre sin que nada lo explicara.

     Con este evento cada recurso vuelve a contar lo que tenia puesto: la copia
     la guarda su propio ayudante (shared/marcar.lua), asi que aqui basta con
     decir que estamos.

     Va detras de un Wait porque en el fotograma en el que arranca un recurso
     los demas todavia pueden no tener sus manejadores puestos. ]]
CreateThread(function()
    Wait(1000)
    TriggerEvent('origen_map:listo')
end)

--- Para mirar por consola que hay puesto y de quien es.
RegisterCommand('mapapuntos', function(_, args)
    local filtro = args[1]
    local n, porRecurso = 0, {}

    for _, p in pairs(Puntos) do
        if not filtro or p.recurso == filtro or p.cat == filtro then
            n = n + 1
            porRecurso[p.recurso] = (porRecurso[p.recurso] or 0) + 1
        end
    end

    print(('[origen_map] %d puntos%s'):format(n, filtro and (' (' .. filtro .. ')') or ''))
    for r, c in pairs(porRecurso) do print(('   %-28s %d'):format(r, c)) end
end, false)
