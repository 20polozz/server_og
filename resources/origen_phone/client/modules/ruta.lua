--[[ LA RUTA POR CARRETERA

     El mapa de las aplicaciones de viajes y de reparto dibujaba una linea recta
     de un punto a otro: por encima de los edificios, cruzando el agua y sin
     parecerse en nada al camino real. Un pasajero mirandola no sabe si su
     carrera son dos calles o media ciudad.

     GTA sabe el camino de verdad, el mismo que pinta en el minimapa, y se le
     puede preguntar punto por punto.

     LO QUE HAY QUE SABER ANTES DE TOCAR ESTO

     La ruta del GPS es una cosa DEL MINIMAPA, no del mundo: con el radar
     apagado el juego no la calcula, y los natives contestan que no hay ruta sin
     dar ningun error. Como muchos servidores apagan el radar a pie, aqui se
     enciende un momento para poder leerla y se deja como estaba.

     Y el largo tampoco se puede preguntar: GetGpsBlipRouteLength devuelve cero
     para la ruta de un waypoint. El final se encuentra andando la ruta hasta
     que el juego deja de avanzar. ]]

Ruta = {}

--- Cada cuantos metros se pregunta. Mas fino no se nota en un mapa de telefono
--- y son llamadas de mas: a 25 m una carrera de 5 km son 200 puntos.
local PASO = 25.0
local TOPE_PUNTOS = 900

--- Por si el juego no dijera donde acaba: de punta a punta del mapa hay unos
--- 15 km, asi que con esto no se recorre para siempre.
local MAX_METROS = 24000.0

--- 0 waypoint, 1 blip del radar, 2 la discreta.
local SLOTS = { 0, 1, 2 }

--[[ Como se le pregunta al juego por un punto de la ruta.

     El native es 0xD0EF8A959B8A4CB9. Se llamaba GET_GPS_WAYPOINT_ROUTE_END y
     ahora se llama GET_POS_ALONG_GPS_TYPE_ROUTE, asi que el nombre del
     envoltorio depende de la version del cliente. Se prueban los dos y, si no
     esta ninguno, se llama al hash a pelo.

     Firma: BOOL(Vector3* salida, BOOL desdeElJugador, float metros, int slot).
     En Lua el puntero de salida vuelve como segundo valor. ]]
local FORMAS = {
    function(desdeJugador, metros, slot)
        if type(GetPosAlongGpsTypeRoute) ~= 'function' then return nil end
        local _, pos = GetPosAlongGpsTypeRoute(desdeJugador, metros, slot)
        return pos
    end,
    function(desdeJugador, metros, slot)
        if type(GetGpsWaypointRouteEnd) ~= 'function' then return nil end
        local _, pos = GetGpsWaypointRouteEnd(desdeJugador, metros, slot)
        return pos
    end,
    function(desdeJugador, metros, slot)
        local _, pos = Citizen.InvokeNative(
            0xD0EF8A959B8A4CB9, Citizen.PointerValueVector(), desdeJugador,
            metros + 0.0, slot, Citizen.ResultAsInteger())
        return pos
    end,
}

--- Un punto en el cero absoluto es "no hay nada", no un sitio del mapa.
local function Vale(pos)
    return pos ~= nil and not (math.abs(pos.x) < 0.01 and math.abs(pos.y) < 0.01)
end

local function Pedir(desdeJugador, metros, slot)
    for i = 1, #FORMAS do
        local ok, pos = pcall(FORMAS[i], desdeJugador, metros, slot)
        if ok and Vale(pos) then return pos end
    end
    return nil
end

--- Cual de los tres slots tiene ruta ahora mismo.
local function SlotActivo()
    for _, slot in ipairs(SLOTS) do
        --[[ Se pregunta por el metro 20 y no por el cero: desde el jugador, el
             metro cero es el jugador mismo y contesta aunque no haya ruta. A
             veinte metros ya hace falta camino que recorrer. ]]
        if Pedir(true, 20.0, slot) then return slot end
    end
    return nil
end

--[[ El radar, encendido lo justo para que el juego calcule la ruta.

     Se devuelve como estaba. Y no se toca si ya estaba encendido: en un coche
     lo esta, y apagarselo al jugador al terminar seria peor que no leer la
     ruta. ]]
local function ConElRadar(hacer)
    local estaba = IsRadarHidden()

    if estaba then DisplayRadar(true) end

    --- Un fotograma para que el juego trace la ruta con el radar ya visible.
    Wait(0)

    local ok, resultado = pcall(hacer)

    if estaba then DisplayRadar(false) end

    if not ok then return nil end
    return resultado
end

local function Andarla()
    local slot = SlotActivo()
    if not slot then return nil end

    local puntos = {}
    local ultimo, quietos = nil, 0
    local d = 0.0

    while d <= MAX_METROS and #puntos < TOPE_PUNTOS do
        local pos = Pedir(true, d, slot)
        if not pos then break end

        if ultimo then
            local avance = math.sqrt((pos.x - ultimo.x) ^ 2 + (pos.y - ultimo.y) ^ 2)

            --[[ Pasado el final el juego se queda clavado en el ultimo punto y
                 repite la misma respuesta: eso es el final.

                 Tres preguntas seguidas y no una, con poco margen: con el
                 margen ancho, un tramo lento —una curva cerrada, un nudo— se
                 tomaba por el final y cortaba la ruta a la mitad. ]]
            if avance < 0.1 then
                quietos = quietos + 1
                if quietos >= 3 then break end
            else
                quietos = 0
                puntos[#puntos + 1] = {
                    x = math.floor(pos.x * 10) / 10,
                    y = math.floor(pos.y * 10) / 10,
                }
            end
        else
            puntos[#puntos + 1] = {
                x = math.floor(pos.x * 10) / 10,
                y = math.floor(pos.y * 10) / 10,
            }
        end

        ultimo = pos
        d = d + PASO
    end

    if #puntos < 2 then return nil end

    return puntos
end

--[[ El trazado de la ruta que hay puesta ahora mismo.

     Devuelve nil si no hay ninguna, y entonces el mapa dibuja la recta de
     siempre: una recta dice menos que el camino, pero mas que nada. ]]
---@return table[]|nil
function Ruta.Trazado()
    return ConElRadar(Andarla)
end

-- ---------------------------------------------------------------------------
--  Un trabajo con dos paradas
-- ---------------------------------------------------------------------------

--[[ Una carrera y un envio son lo mismo visto desde el mapa: se va a por algo
     y luego se lleva a otro sitio. Marcar las dos paradas, poner la ruta en la
     que toca ahora y leer por donde va estaba escrito para el reparto; los
     viajes lo necesitaban igual, asi que vive aqui y lo usan los dos.

     La ruta se pone con SetBlipRoute y NO con SetNewWaypoint a proposito: el
     waypoint es del jugador, y quitarselo cada vez que cambia de tramo le borra
     el sitio al que iba el. Un blip con ruta hace lo mismo sin pisarle nada. ]]

local marcas = {}

--- Quita las marcas de un trabajo.
---@param cual string
function Ruta.Limpiar(cual)
    local suyas = marcas[cual]
    if not suyas then return end

    for i = 1, #suyas do OrigenMapa.Quitar(suyas[i]) end
    marcas[cual] = nil
end

--[[ Pone una marca con su nombre y, si le toca, su ruta.

     Ya no es un blip del juego: es un punto de origen_map. Devuelve su CLAVE,
     que es lo que hay que guardar para poder quitarla luego.

     `conRuta` decide quien lleva la ruta del GPS, y no las dos: con las dos
     puestas el juego dibuja dos lineas a la vez y no se entiende cual es cual.
     Es lo unico para lo que se sigue creando un blip por debajo —invisible—,
     porque GTA solo sabe trazar el camino por carretera hasta un blip. ]]
---@param cual string
---@param n number
---@param coords table
---@param color string
---@param nombre string
---@param conRuta boolean
---@return string
local function Marcar(cual, n, coords, color, nombre, conRuta)
    local clave = ('parada_%s_%d'):format(cual, n)

    OrigenMapa.Poner(clave, {
        x = coords.x, y = coords.y, z = coords.z or 0.0,
        cat = 'trabajos',
        nombre = nombre,
        color = color,
        ruta = conRuta,
        prioridad = 10,
    })

    return clave
end

--[[ Marca las dos paradas de un trabajo y devuelve por donde se va.

     `ida` dice si todavia hay que ir a por ello (a la primera parada) o si ya
     se lleva encima (a la segunda). Devuelve el trazado para que el mapa de la
     aplicacion pinte el camino de verdad en vez de una recta. ]]
---@param cual string
---@param origen table|nil
---@param destino table|nil
---@param ida boolean
---@param nombreOrigen string
---@param nombreDestino string
---@return table|nil
function Ruta.DosParadas(cual, origen, destino, ida, nombreOrigen, nombreDestino)
    Ruta.Limpiar(cual)

    local suyas = {}

    if origen and origen.x then
        suyas[#suyas + 1] = Marcar(cual, 1, origen, '#f0c33c', nombreOrigen, ida)
    end

    if destino and destino.x then
        suyas[#suyas + 1] = Marcar(cual, 2, destino, '#ff3355', nombreDestino, not ida)
    end

    marcas[cual] = suyas

    --[[ Se espera a que el juego la trace, hasta tres segundos.

         La marca la pone origen_map y el GPS la calcula despues, a su ritmo:
         con una espera fija y corta se leia antes de que existiera, y el mapa
         de la aplicacion se quedaba sin camino. ]]
    local hasta = GetGameTimer() + 3000
    local puntos

    repeat
        Wait(150)
        puntos = Ruta.Trazado()
    until puntos or GetGameTimer() >= hasta

    return puntos
end
