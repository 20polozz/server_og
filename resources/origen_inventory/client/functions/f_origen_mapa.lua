--[[
    El mapa grande de la ciudad.

    Hasta el 11/09/2026 era el menú de pausa (origen_pausemenu/client/mapa.lua)
    y el inventario tenía otro mapa más pobre en la pestaña de Ciudad. Ahora
    hay uno solo y es este: se abre dentro del inventario —desde Ciudad, desde
    el radial o con la M del pie— y hace todo lo que hacía el del menú de
    pausa: la ruta por carretera, las paradas, el punto libre, las chinchetas y
    las zonas propias, compartir un sitio, los territorios, los avisos de
    policía y tus vehículos.

    La pantalla es components/mapa/MapaGrande.vue. Aquí solo se dan coordenadas
    del juego: la conversión la hace la interfaz.
]]

--[[ Las categorías de puntos, COPIADAS de origen_blipmanager/config.lua.

     Está copiada a propósito y no leída de allí: su Config es un global suyo y
     desde aquí no se ve. Si alguien añade una categoría allí, aquí no aparece
     —queda anotado— pero el mapa sigue funcionando con el resto en vez de
     quedarse en blanco.

     El `icono` es el dibujo que pinta la interfaz en la chincheta; el nombre no
     es de ninguna librería de iconos, es una clave de la tabla DIBUJOS de
     App.vue. ]]
local CATEGORIAS = {
    { id = 'garages',    label = 'Garajes',    icono = 'coche',    sprites = { 357, 524, 400, 350, 624 } },
    { id = 'banking',    label = 'Bancos',     icono = 'dinero',   sprites = { 108, 277, 278, 431, 434 } },
    { id = 'shops',      label = 'Tiendas',    icono = 'cesta',    sprites = { 52, 59, 133, 361, 403, 605 } },
    { id = 'public',     label = 'Servicios',  icono = 'edificio', sprites = { 60, 61, 489, 490, 567, 419, 351 } },
    { id = 'housing',    label = 'Viviendas',  icono = 'casa',     sprites = { 40, 374, 375, 492, 411 } },
    { id = 'illegal',    label = 'Ilegal',     icono = 'calavera', sprites = { 84, 310, 496, 501, 514 } },
    { id = 'racing',     label = 'Carreras',   icono = 'bandera',  sprites = { 315 } },
    { id = 'activities', label = 'Ocio',       icono = 'ocio',     sprites = { 73, 75, 71, 106, 266, 311, 480, 614 } },
    --[[ Las tiendas de mascotas (origen_pets) ponen su blip con el sprite
         442. Va como categoria propia y no dentro de 'shops' para que se
         pueda encender y apagar sola: son cuatro puntos en toda la ciudad y
         mezclados entre cien tiendas no se encuentran. ]]
    { id = 'mascotas',   label = 'Mascotas',   icono = 'huella',   sprites = { 442 } },

}

--[[ Los sitios de mision NO se buscan por sprite.

     Se penso hacerlo asi y esta mal por dos motivos. Uno, ya llegan por su
     propio camino —los pone origen_quests en el registro de origen_map, ver
     PuntosDelRegistro() mas abajo—, asi que saldrian dos veces. Y dos, por
     sprite lo unico que se sabe es el numero: el nombre habria que
     inventarselo del singular de la categoria, y saldria «Encargo Banham
     Canyon» donde el sitio se llama «El chatarrero del puerto».

     Aqui el dibujo de la chincheta es nuestro, no del juego, asi que el
     sprite del blip no pinta nada en esta pantalla. ]]

--[[ El singular de cada categoria, para cuando del sprite no se sabe mas.

     "Tiendas Vespucci" suena a lista; "Tienda Vespucci" suena a sitio. ]]
local SINGULAR = {
    garages = 'Garaje',
    banking = 'Banco',
    shops = 'Tienda',
    public = 'Servicio',
    housing = 'Vivienda',
    illegal = 'Punto ilegal',
    racing = 'Carrera',
    activities = 'Ocio',
    mascotas = 'Tienda de mascotas',
    telefonos = 'Tienda de telefonos',
}

--[[ Como se llama cada sprite.

     El juego NO deja leer el nombre de un blip: no hay ningun native que lo
     devuelva. Asi que el nombre se saca del sprite, y esta tabla es el unico
     sitio donde se dice que es cada numero.

     Los que estan aqui salen de los propios recursos del servidor, que son los
     que crean esos blips —origen_police pone comisarias con el 60,
     origen_banking bancos con el 108, origen_clothing barberias con el 71, y
     asi—. Los que NO estan son blips que pone GTA de serie y que ningun
     recurso crea: para esos se usa el singular de su categoria, que dice
     menos pero no se inventa nada.

     Si alguien identifica uno de los que faltan, se añade aqui y aparece en el
     mapa sin tocar nada mas. ]]
local NOMBRES = {
    [357] = 'Garaje',
    [524] = 'Concesionario',
    [350] = 'Casa en venta',
    [40]  = 'Vivienda',
    [108] = 'Banco',
    [52]  = 'Tienda',
    [60]  = 'Comisaria',
    [61]  = 'Hospital',
    [419] = 'Ayuntamiento',
    [84]  = 'Zona de bandas',
    [315] = 'Carrera',
    [73]  = 'Tienda de ropa',
    [75]  = 'Tatuajes',
    [71]  = 'Barberia',
    [106] = 'Deportes',
    [311] = 'Gimnasio',
}

--[[ Todos los puntos que hay ahora mismo en el mapa del juego.

     Se recorren los sprites de cada categoría porque no hay ningún native que
     devuelva "dame todos los blips": hay que preguntar por sprite.

     Los blips se leen CADA VEZ que se abre el menú y no una vez por sesión: los
     trabajos y los eventos ponen y quitan blips mientras se juega, y una lista
     cacheada acabaría enseñando sitios que ya no están. ]]
--[[ ══ Los puntos que los recursos han REGISTRADO ═════════════════════════

     Esta es ahora la fuente buena. Cada recurso dice lo que quiere marcar
     —donde, de que categoria y COMO SE LLAMA— en el registro de origen_map
     (client/registro.lua), y aqui solo se recoge.

     Lo que gana respecto a rastrear blips: el nombre. Del sprite de un blip no
     se puede sacar —no hay native que lo devuelva— asi que la lista de la
     derecha decia «Garaje» cuarenta veces. Ahora dice como se llama el sitio.

     El rastreo por sprite de mas abajo sigue existiendo para lo que todavia no
     ha pasado por el registro (blips que pone GTA de serie, y recursos de
     terceros que se actualizan desde fuera). Lo registrado gana: un punto del
     registro tapa cualquier blip que caiga a menos de 5 m. ]]
local function PuntosDelRegistro()
    if GetResourceState('origen_map') ~= 'started' then return {} end

    --[[ En pcall porque el recurso puede estar arrancado y todavia no tener el
         export registrado —justo despues de un restart—, y una llamada fallida
         se llevaria por delante el mapa entero. ]]
    local ok, lista = pcall(function()
        return exports['origen_map']:Puntos()
    end)

    if not ok or type(lista) ~= 'table' then return {} end

    local salida = {}
    for _, p in ipairs(lista) do
        salida[#salida + 1] = {
            x = p.x, y = p.y, z = p.z or 0.0,
            cat = p.cat,
            catLabel = p.catLabel,
            icono = p.icono,
            nombre = p.nombre,
            barrio = p.barrio,
            estado = p.estado,
            -- De este jugador y no del mundo: lo dice el recurso que pone el
            -- punto, y la chincheta se pinta distinta.
            propio = p.propio,
            color = p.color,
            radio = p.radio,
            --[[ Faltaban en el menu de pausa, y la pantalla si los lee
                 (`mandan`): sin ellos un aviso y el objetivo de la mision
                 activa se pintaban igual que un cajero. ]]
            prioridad = p.prioridad,
            pulso = p.pulso,
        }
    end

    return salida
end

--- `yaPuestos` son los puntos del registro: un blip que caiga encima de uno de
--- ellos no se añade, porque seria la misma cosa contada dos veces.
local function PuntosDelMundo(yaPuestos)
    local lista, vistos = {}, {}

    --[[ El sitio, sin la categoria: si un recurso ha registrado su garaje, el
         blip que hubiera quedado suelto ahi es ese mismo garaje aunque el
         rastreo lo hubiera metido en otra categoria. ]]
    for _, p in ipairs(yaPuestos or {}) do
        vistos[('%d:%d'):format(math.floor(p.x / 5), math.floor(p.y / 5))] = true
    end

    for _, cat in ipairs(CATEGORIAS) do
        for _, sprite in ipairs(cat.sprites) do
            local blip = GetFirstBlipInfoId(sprite)

            while DoesBlipExist(blip) do
                local coords = GetBlipInfoIdCoord(blip)

                --[[ Dos blips distintos pueden caer en el mismo punto —el juego
                     pone varios encima en las gasolineras— y en el mapa serían
                     una marca sobre otra. Se redondea a 5 m y se queda el
                     primero. ]]
                local sitio = ('%d:%d'):format(
                    math.floor(coords.x / 5), math.floor(coords.y / 5))
                local clave = sitio .. ':' .. sprite

                if not vistos[clave] and not vistos[sitio] then
                    vistos[clave] = true

                    local barrio = BarrioDe(coords.x, coords.y, coords.z)

                    lista[#lista + 1] = {
                        x = math.floor(coords.x * 10) / 10,
                        y = math.floor(coords.y * 10) / 10,
                        z = math.floor((coords.z or 0.0) * 10) / 10,
                        cat = cat.id,
                        catLabel = cat.label,
                        icono = cat.icono,

                        --[[ El barrio es lo que distingue un punto de otro de
                             su misma categoría, así que va pegado al nombre:
                             sin él la lista de la derecha serían cien filas
                             que ponen lo mismo. ]]
                        barrio = barrio,
                        nombre = ((NOMBRES[sprite] or SINGULAR[cat.id] or cat.label)
                            .. (barrio and (' ' .. barrio) or '')),
                    }
                end

                blip = GetNextBlipInfoId(sprite)
            end
        end
    end

    return lista
end

--[[ ══ Las capas que no son blips del mundo ═══════════════════════════════

     Los blips los tiene todo el mundo desde el minuto uno. Lo que sigue es lo
     que es TUYO —lo que has descubierto, lo que has guardado, lo que te han
     pasado— y por eso se pinta con otra forma de chincheta, no solo con otro
     color: a 17 px el color se confunde, la forma no. ]]

--[[ Los sitios de mision NO se recogen aqui.

     Los pone origen_quests en el registro de origen_map
     (origen_quests/client/origen_mapa.lua), asi que llegan ya con todo lo
     demas por PuntosDelRegistro(): con su nombre, su barrio y marcados como
     propios.

     Antes se pedian ademas por el export PuntosDescubiertos, de cuando eran
     blips del juego y no pasaban por el registro. Al migrarlos se quedaron los
     dos caminos abiertos y cada sitio descubierto salia DOS VECES en el mapa,
     una encima de otra. Lo mismo pasaba en la pestaña de Ciudad del
     inventario, que recoge de los mismos dos sitios.

     El export sigue existiendo y no sobra: lo usa quien necesita la lista de
     descubiertos sin pasar por el mapa. Lo que sobraba era pedirlo aqui. ]]

--[[ Los avisos y las unidades de origen_police.

     Antes salian solos: eran blips nativos y el minimapa del juego los pintaba
     sin que nadie hiciera nada. Desde que el minimapa y este mapa los dibuja
     Leaflet, un blip nativo no se ve en ninguno de los dos, y quien esta de
     servicio se quedo sin ver ni los avisos ni a sus companeros.

     No se sacan por sprite como los del mundo: los sprites de las referencias
     los elige cada unidad de una lista larga (COLA, SWAT, K9...), asi que
     perseguirlos por numero seria ir detras de una lista que cambia. Se le
     preguntan a origen_police, que es quien los tiene.

     Solo devuelve algo si estas de servicio: los exports miran sus propias
     tablas, y fuera de servicio estan vacias. ]]
local function PuntosDePolicia()
    if GetResourceState('origen_police') ~= 'started' then return {} end

    local fuentes = {
        { export = 'AvisosParaMapa',      cat = 'avisos',      label = 'Avisos',   icono = 'sirena' },
        { export = 'ReferenciasParaMapa', cat = 'referencias', label = 'Unidades', icono = 'escudo' },
    }

    local lista = {}

    for _, fuente in ipairs(fuentes) do
        local ok, puntos = pcall(function()
            return exports['origen_police'][fuente.export](exports['origen_police'])
        end)

        if ok and type(puntos) == 'table' then
            for _, p in ipairs(puntos) do
                if p.x and p.y then
                    lista[#lista + 1] = {
                        x = p.x, y = p.y,
                        cat = fuente.cat, catLabel = fuente.label, icono = fuente.icono,
                        nombre = p.etiqueta or fuente.label,
                        barrio = BarrioDe(p.x, p.y, 0.0),
                        propio = true,
                    }
                end
            end
        end
    end

    return lista
end

--[[ Los marcadores que te has guardado tu.

     Van en el KVP del cliente y no en la base: son de este ordenador y de este
     jugador, no hacen falta en el servidor para nada, y asi no cuestan ni una
     consulta ni una tabla. ]]
local CLAVE_MARCADORES = 'origen_inventory:mapa:marcadores'

local function MarcadoresGuardados()
    local crudo = GetResourceKvpString(CLAVE_MARCADORES)
    if not crudo or crudo == '' then return {} end

    local ok, lista = pcall(json.decode, crudo)
    return (ok and type(lista) == 'table') and lista or {}
end

local function EscribirMarcadores(lista)
    SetResourceKvp(CLAVE_MARCADORES, json.encode(lista))
end

local function MarcadoresComoPuntos()
    local lista = {}
    for _, m in ipairs(MarcadoresGuardados()) do
        if m.x and m.y then
            lista[#lista + 1] = {
                x = m.x, y = m.y,
                cat = 'marcadores', catLabel = 'Mis marcadores', icono = 'chincheta',
                nombre = m.nombre or 'Marcador',
                barrio = BarrioDe(m.x, m.y, 0.0),
                marcador = m.id,
                propio = true,
            }
        end
    end
    return lista
end

--[[ Las zonas que dibujas tu.

     Un marcador dice "aqui"; una zona dice "todo esto". Son cosas distintas y
     por eso se guardan aparte: un sitio de encuentro es un punto, un area de
     patrulla o el trozo de calle que os repartis no lo es.

     Van al KVP igual que los marcadores: son de este jugador, no hacen falta en
     el servidor y asi no cuestan ni una tabla. ]]
local CLAVE_ZONAS = 'origen_inventory:mapa:zonas'

local function ZonasGuardadas()
    local crudo = GetResourceKvpString(CLAVE_ZONAS)
    if not crudo or crudo == '' then return {} end

    local ok, lista = pcall(json.decode, crudo)
    return (ok and type(lista) == 'table') and lista or {}
end

local function EscribirZonas(lista)
    SetResourceKvp(CLAVE_ZONAS, json.encode(lista))
end

--[[ Lo que te ha pasado alguien. Vive en memoria y se pierde al reconectar: es
     un "mira, aqui" de ahora mismo, no una libreta. Si quieres quedartelo, lo
     guardas como marcador y ya es tuyo. ]]
local compartidos = {}

--- Guardar uno que te acaba de llegar. Se limita la lista para que una broma
--- de spam no te llene el mapa de chinchetas.
local function RecibirCompartido(punto)
    table.insert(compartidos, 1, {
        x = punto.x, y = punto.y,
        nombre = punto.nombre,
        de = punto.de,
    })
    while #compartidos > 20 do table.remove(compartidos) end
end

local function CompartidosComoPuntos()
    local lista = {}
    for _, c in ipairs(compartidos) do
        lista[#lista + 1] = {
            x = c.x, y = c.y,
            cat = 'compartidos', catLabel = 'Compartidos', icono = 'compartido',
            nombre = c.nombre or 'Punto compartido',
            barrio = BarrioDe(c.x, c.y, 0.0),
            de = c.de,
            propio = true,
        }
    end
    return lista
end

--[[ Los territorios de bandas, que son AREAS y no puntos.

     Es lo unico del servidor que solo se puede enseñar en un mapa: una lista no
     puede dibujar donde empieza y acaba un barrio. Los sirve el cliente de
     origen_ilegalv2 con sus vertices y el color de la banda que lo controla, ya
     resuelto; aqui no hay que ir a la base de datos. ]]
local function TerritoriosDeBandas()
    if GetResourceState('origen_ilegalv2') ~= 'started' then return {} end

    local ok, lista = pcall(function()
        return exports['origen_ilegalv2']:GetTerritories()
    end)
    if not ok or type(lista) ~= 'table' then return {} end

    --[[ `pairs` y no `ipairs`: el export devuelve la tabla indexada por el id
         del territorio ('territory_...'), no una lista. Con ipairs no se
         recorria nada y el mapa de la ciudad nunca pintaba un territorio.

         Solo llegan los que la banda del jugador CONOCE: el filtro lo hace el
         servidor de origen_ilegalv2 al mandarlos. ]]
    local salida = {}
    for _, t in pairs(lista) do
        -- Los vertices llegan en zone_data.points o en points, segun por donde
        -- se hayan creado. Vale cualquiera de los dos.
        local puntos = (type(t.zone_data) == 'table' and t.zone_data.points) or t.points

        if type(puntos) == 'table' and #puntos >= 3 then
            local vertices = {}
            for _, v in ipairs(puntos) do
                if v.x and v.y then
                    vertices[#vertices + 1] = { x = v.x + 0.0, y = v.y + 0.0 }
                end
            end

            if #vertices >= 3 then
                salida[#salida + 1] = {
                    id = t.id,
                    nombre = t.name or 'Territorio',
                    banda = t.gang_name or t.gang_id,
                    color = t.gang_color,
                    base = t.is_base and true or false,
                    vertices = vertices,
                }
            end
        end
    end
    return salida
end

--[[ Las categorias que no vienen de origen_blipmanager. Se añaden a las suyas y
     la interfaz no tiene que saber de donde sale cada una: el desplegable, la
     leyenda y el buscador funcionan igual con todas. ]]
--- «Misiones» ya no sale de aqui: viene en el catalogo de origen_map, y la
--- añade sola el bloque de categorias del registro de mas abajo.
local function CategoriasPropias(marcadores, compartidosN, policia)
    local extra = {}

    --[[ Las de policia solo si hay algo que enseñar: un civil no tiene por que
         ver dos categorias vacias en su leyenda. Se miran por separado porque
         se puede estar de servicio sin ningun aviso, o con avisos y sin nadie
         mas conectado. ]]
    local hayAvisos, hayUnidades = false, false
    for _, p in ipairs(policia or {}) do
        if p.cat == 'avisos' then hayAvisos = true end
        if p.cat == 'referencias' then hayUnidades = true end
    end
    if hayAvisos then
        extra[#extra + 1] = { id = 'avisos', label = 'Avisos', icono = 'sirena' }
    end
    if hayUnidades then
        extra[#extra + 1] = { id = 'referencias', label = 'Unidades', icono = 'escudo' }
    end
    -- Los marcadores salen siempre, aunque no tengas ninguno: si no, la
    -- categoria aparece de la nada al guardar el primero y descoloca la lista.
    extra[#extra + 1] = { id = 'marcadores', label = 'Mis marcadores', icono = 'chincheta' }
    if compartidosN > 0 then
        extra[#extra + 1] = { id = 'compartidos', label = 'Compartidos', icono = 'compartido' }
    end
    return extra
end

--- Todo lo que la pantalla necesita para pintarse de cero.
function DatosDelMapa()
    local c = GetEntityCoords(PlayerPedId())

    --[[ Primero lo registrado, que es lo que manda, y con ello en la mano se
         rastrean los blips sueltos que queden: los que caigan encima de un
         punto registrado no se cuentan dos veces. ]]
    local registrados = PuntosDelRegistro()
    local puntos = PuntosDelMundo(registrados)
    for _, q in ipairs(registrados) do puntos[#puntos + 1] = q end

    local marcadores = MarcadoresComoPuntos()
    local recibidos = CompartidosComoPuntos()
    local policia = PuntosDePolicia()

    for _, lista in ipairs({ marcadores, recibidos, policia }) do
        for _, q in ipairs(lista) do puntos[#puntos + 1] = q end
    end

    local categorias = {}
    local yaEsta = {}

    for _, cat in ipairs(CATEGORIAS) do
        categorias[#categorias + 1] = cat
        yaEsta[cat.id] = true
    end
    for _, cat in ipairs(CategoriasPropias(marcadores, #recibidos, policia)) do
        categorias[#categorias + 1] = cat
        yaEsta[cat.id] = true
    end

    --[[ Y las que traiga el registro y aqui no estuvieran.

         Antes las categorias eran las diez de la tabla de sprites de arriba,
         porque era lo unico que se sabia rastrear. Ahora un recurso puede
         registrar sus puntos como «Trabajos» o «Gasolineras» y esta pantalla
         se entera sola: se le pide el catalogo a origen_map y se añaden las que
         TENGAN PUNTOS, para no dejar filtros vacios en la leyenda. ]]
    local usadas = {}
    for _, p in ipairs(registrados) do usadas[p.cat] = true end

    if next(usadas) and GetResourceState('origen_map') == 'started' then
        local ok, catalogo = pcall(function()
            return exports['origen_map']:Categorias()
        end)

        if ok and type(catalogo) == 'table' then
            for _, cat in ipairs(catalogo) do
                if usadas[cat.id] and not yaEsta[cat.id] then
                    categorias[#categorias + 1] = cat
                    yaEsta[cat.id] = true
                end
            end
        end
    end

    return {
        puntos = puntos,
        categorias = categorias,
        territorios = TerritoriosDeBandas(),
        zonas = ZonasGuardadas(),
        ambiente = AmbienteAhora(),
        -- Dónde estás: el mapa abre centrado ahí. Uno que abre en el centro del
        -- mundo obliga a buscarse a uno mismo antes de poder usarlo. `h` es
        -- hacia donde miras: tu marca es una flecha, para no confundirla con
        -- la chincheta del destino (06/10).
        yo = { x = math.floor(c.x * 10) / 10, y = math.floor(c.y * 10) / 10, h = math.floor(GetEntityHeading(PlayerPedId())) },
    }
end

--[[ ══ La ruta del GPS ══════════════════════════════════════════════════════

     El trazado DE VERDAD: el mismo camino por carretera que el juego pinta en
     el radar cuando pones un punto en el mapa.

     Se lee con GetPosAlongGpsTypeRoute, que devuelve la posicion que hay a X
     metros del principio de la ruta activa. Preguntando cada pocos metros
     desde cero hasta lo que mide la ruta sale el camino entero.

     El "slot" dice de que ruta se habla: 0 es el punto que ha marcado el
     jugador, 1 el de un blip del radar y 2 la discreta. Se prueban los tres en
     ese orden porque una ruta puesta por otro recurso puede vivir en otro slot.

     La misma tecnica que usa origen_racing/client/gps3d.lua para dibujar la
     ruta en 3D sobre el asfalto; alli se cortan los primeros metros porque solo
     pinta lo que tienes delante, y aqui hace falta entera. ]]

--[[ ══ El radar ═══════════════════════════════════════════════════════════

     GTA solo calcula la ruta del GPS cuando el radar esta ENCENDIDO: la ruta es
     una cosa del minimapa, no del mundo. Y en este servidor el HUD lo apaga en
     cuanto te bajas del coche (origen_hud/client/vehicle.lua), asi que andando
     no hay ninguna ruta —ni que leer aqui, ni que seguir en el juego—.

     Encendido no quiere decir que lo veas: mientras el mapa esta abierto la
     pantalla lo tapa entera. Se enciende en dos casos:

       · con el mapa abierto, para poder leer el trazado;
       · mientras tengas una ruta puesta desde el mapa, aunque lo cierres, para
         que a pie tengas GPS que seguir igual que en coche.

     Al acabar se deja como estaba. ]]

--[[ Encender el radar mientras haya una ruta puesta, aunque el mapa este
     cerrado. En false a proposito, igual que lo tenia el menu de pausa: a pie
     este servidor no enseña minimapa, y forzarlo solo por tener una ruta
     rompia eso. Con el mapa abierto se enciende siempre, que es cuando hace
     falta para leer el trazado. ]]
local RADAR_CON_RUTA = false

local menuAbierto = false
local rutaActiva = false
local radarAntes = nil
local vigilando = false

--- El waypoint del jugador es el blip de sprite 8. Cuando desaparece —has
--- llegado, o lo has quitado— ya no hay ruta que seguir.
local function HayWaypoint()
    return DoesBlipExist(GetFirstBlipInfoId(8))
end

--- Si el waypoint esta puesto en (x, y), con unos metros de margen.
local function WaypointEn(x, y)
    local wp = GetFirstBlipInfoId(8)
    if not DoesBlipExist(wp) then return false end
    local c = GetBlipInfoIdCoord(wp)
    return math.abs(c.x - x) < 3.0 and math.abs(c.y - y) < 3.0
end

--[[ Poner el waypoint EN ESE SITIO, y comprobar que se ha quedado ahi.

     Un SetNewWaypoint a secas encima de otro waypoint no es de fiar: igual que
     pinchar dos veces en el mapa del juego, puede quitar el que hay en vez de
     moverlo, y el GPS sigue unos fotogramas con la ruta vieja. De ahi que a
     veces el punto no se quedara hasta el segundo o tercer intento, o que el
     GPS siguiera llevando al sitio anterior (17/09).

     Por eso: se quita el que haya, se espera a que se vaya, se pone el nuevo y
     se mira que esta donde tiene que estar. Si no, otra vez. Espera fotogramas,
     asi que se llama desde un hilo. Devuelve si ha quedado puesto. ]]
function MapaPonerWaypoint(x, y)
    x, y = tonumber(x), tonumber(y)
    if not x or not y then return false end
    x, y = x + 0.0, y + 0.0

    for _ = 1, 3 do
        if WaypointEn(x, y) then return true end

        if HayWaypoint() then
            DeleteWaypoint()
            local hasta = GetGameTimer() + 500
            while HayWaypoint() and GetGameTimer() < hasta do Wait(0) end
        end

        SetNewWaypoint(x, y)

        local hasta = GetGameTimer() + 500
        while not WaypointEn(x, y) and GetGameTimer() < hasta do Wait(0) end
    end

    return WaypointEn(x, y)
end

--[[ Quitar el waypoint, y comprobar que se ha ido.

     Lo mismo que al ponerlo: un DeleteWaypoint a secas no siempre cuaja a la
     primera, y el punto se quedaba puesto con el panel diciendo que no habia
     ruta. Se insiste hasta tres veces. Espera fotogramas: desde un hilo. ]]
function MapaQuitarWaypoint()
    for _ = 1, 3 do
        if not HayWaypoint() then return true end

        DeleteWaypoint()
        local hasta = GetGameTimer() + 500
        while HayWaypoint() and GetGameTimer() < hasta do Wait(0) end
    end

    return not HayWaypoint()
end

--[[ El waypoint de ahora, para que el mapa grande se quede con el del juego y
     no con el que recuerda. Si otro recurso lo cambia —el «Marcar» de Ciudad,
     las llaves, la policia, una casa— o lo quita, el mapa grande lo ve en el
     latido siguiente, igual que el minimapa. ]]
local function WaypointAhora()
    local wp = GetFirstBlipInfoId(8)
    if not DoesBlipExist(wp) then return nil end
    local c = GetBlipInfoIdCoord(wp)
    return {
        x = math.floor(c.x * 10) / 10,
        y = math.floor(c.y * 10) / 10,
        barrio = BarrioDe and BarrioDe(c.x, c.y, c.z) or nil,
    }
end

local function AplicarRadar()
    if menuAbierto or rutaActiva then
        if radarAntes == nil then
            -- Como estaba, para devolverlo igual. Si el native no esta, se usa
            -- la misma regla que el HUD: encendido solo en coche.
            local ok, oculto = pcall(IsRadarHidden)
            if ok and type(oculto) == 'boolean' then
                radarAntes = not oculto
            else
                radarAntes = IsPedInAnyVehicle(PlayerPedId(), false)
            end
        end
        DisplayRadar(true)
        return
    end

    if radarAntes ~= nil then
        DisplayRadar(radarAntes)
        radarAntes = nil
    end
end

--[[ El HUD vuelve a apagar el radar cada vez que te bajas de un coche, asi que
     no basta con encenderlo una vez: hay que reponerlo mientras haga falta.
     Medio segundo es de sobra —es un native, no cuesta nada— y el hilo se acaba
     solo en cuanto no queda motivo para tenerlo encendido. ]]
local function Vigilar()
    if vigilando then return end
    vigilando = true

    CreateThread(function()
        while menuAbierto or rutaActiva do
            DisplayRadar(true)
            Wait(500)

            --[[ Si el waypoint ya no esta —has llegado, o lo has quitado— la
                 ruta se ha acabado.

                 Se mira DESPUES de esperar y no antes: SetNewWaypoint tarda un
                 fotograma en crear el blip, y comprobandolo de inmediato la
                 ruta se cancelaba justo al ponerla. ]]
            if rutaActiva and not HayWaypoint() then
                rutaActiva = false
            end
        end

        vigilando = false
        AplicarRadar()
    end)
end

--- Lo llama la pantalla al abrirse y al cerrarse (mapaAbierto, mas abajo).
function RadarParaLaRuta(encender)
    menuAbierto = encender and true or false
    AplicarRadar()
    if menuAbierto then Vigilar() end
end

--- Lo llama trazar y quitar ruta. Es lo que la mantiene encendida a pie.
function SeguirLaRuta(hay)
    if hay and RADAR_CON_RUTA == false then return end

    rutaActiva = hay and true or false
    AplicarRadar()
    if rutaActiva then Vigilar() end
end

local SLOTS = { 0, 1, 2 }

--- Cada cuantos metros se pregunta. En un mapa, mas fino no se nota y son
--- llamadas de mas: a 25 m una ruta de 5 km son 200 puntos.
local PASO = 25.0
local TOPE_PUNTOS = 900

--- Por si el juego no dice cuanto mide la ruta: de punta a punta del mapa hay
--- unos 15 km, asi que con esto sobra y no se recorre para siempre.
local MAX_METROS = 24000.0

--[[ Como se le pregunta al juego por un punto de la ruta.

     El native es 0xD0EF8A959B8A4CB9. Se llamo GET_GPS_WAYPOINT_ROUTE_END y
     AHORA se llama GET_POS_ALONG_GPS_TYPE_ROUTE, asi que el nombre del
     envoltorio de Lua depende de la version del cliente. Se prueban los dos y,
     si no esta ninguno, se llama al hash a pelo.

     Firma: BOOL(Vector3* salida, BOOL desdeElJugador, float metros, int slot).
     El puntero de salida en Lua viene como segundo valor devuelto. ]]
local FORMAS = {
    {
        nombre = 'GetPosAlongGpsTypeRoute',
        pedir = function(desdeJugador, metros, slot)
            if type(GetPosAlongGpsTypeRoute) ~= 'function' then return nil end
            local _, pos = GetPosAlongGpsTypeRoute(desdeJugador, metros, slot)
            return pos
        end,
    },
    {
        nombre = 'GetGpsWaypointRouteEnd',
        pedir = function(desdeJugador, metros, slot)
            if type(GetGpsWaypointRouteEnd) ~= 'function' then return nil end
            local _, pos = GetGpsWaypointRouteEnd(desdeJugador, metros, slot)
            return pos
        end,
    },
    {
        nombre = 'InvokeNative 0xD0EF8A959B8A4CB9',
        pedir = function(desdeJugador, metros, slot)
            local _, pos = Citizen.InvokeNative(0xD0EF8A959B8A4CB9,
                Citizen.PointerValueVector(), desdeJugador, metros, slot,
                Citizen.ResultAsInteger())
            return pos
        end,
    },
}

--[[ La forma que funciona en ESTE cliente, averiguada una vez y recordada.

     Un punto en el (0, 0) no es un punto: es lo que devuelve el native cuando
     no ha escrito nada en la salida. Por eso no vale con mirar si contesta. ]]
local formaBuena = nil

local function ValePunto(pos)
    return pos ~= nil and pos.x ~= nil
        and not (math.abs(pos.x) < 0.01 and math.abs(pos.y) < 0.01)
end

local function Pedir(desdeJugador, metros, slot)
    if formaBuena then
        local ok, pos = pcall(formaBuena.pedir, desdeJugador, metros + 0.0, slot)
        if ok and ValePunto(pos) then return pos end
        -- La forma recordada ha dejado de valer: se vuelven a probar todas en
        -- vez de darse por vencido para siempre.
        formaBuena = nil
    end

    for _, forma in ipairs(FORMAS) do
        local ok, pos = pcall(forma.pedir, desdeJugador, metros + 0.0, slot)
        if ok and ValePunto(pos) then
            formaBuena = forma
            return pos
        end
    end

    return nil
end

--- Si un slot tiene ruta ahora mismo. Preguntar por el metro cero es la unica
--- forma fiable de saberlo: GetGpsBlipRouteFound solo mira la ruta de un BLIP,
--- y la que pone SetNewWaypoint no cuenta como tal.
local function SlotActivo()
    for _, slot in ipairs(SLOTS) do
        --[[ Se pregunta por el metro 20 y no por el cero: desde el jugador, el
             metro cero es el jugador mismo y sale aunque no haya ninguna ruta.
             A veinte metros ya hay que tener camino que recorrer. ]]
        if Pedir(true, 20.0, slot) then return slot end
    end
    return nil
end

function TrazadoDelGps()
    local slot = SlotActivo()
    if not slot then return nil end

    --[[ Cuanto mide, SOLO COMO DATO.

         No se usa de tope: GetGpsBlipRouteLength devuelve 0 para la ruta de un
         waypoint, y cuando devuelve algo se queda corto —era esto lo que dejaba
         el trazado cortado por la mitad a los pocos segundos—. El final de la
         ruta se busca andandola, no preguntando cuanto mide. ]]
    local largo = GetGpsBlipRouteLength() or 0.0

    local puntos, recorrido = {}, 0.0
    local ultimo, quietos = nil, 0
    local d = 0.0

    while d <= MAX_METROS and #puntos < TOPE_PUNTOS do
        local pos = Pedir(true, d, slot)
        if not pos then break end

        if ultimo then
            local avance = math.sqrt((pos.x - ultimo.x) ^ 2 + (pos.y - ultimo.y) ^ 2)

            --[[ Pasado el final, el native se queda clavado en el ultimo punto
                 y sigue contestando lo mismo. Eso es el final de la ruta.

                 Tres preguntas seguidas y medio metro de margen, no una y cinco:
                 con el margen ancho, un tramo lento —una curva cerrada, un
                 nudo— se tomaba por el final y cortaba la ruta a la mitad. ]]
            if avance < 0.1 then
                quietos = quietos + 1
                if quietos >= 3 then break end
            else
                quietos = 0
                recorrido = recorrido + avance
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

    --[[ ¿Llega el trazado hasta donde vas?

         Si el ultimo punto se queda lejos del waypoint es que el muestreo se ha
         cortado, y un trazado a medias es peor que ninguno: sustituye al bueno
         que ya habia y parece que la ruta se acaba en mitad de la nada. Se
         marca como parcial y la interfaz decide. ]]
    local parcial = false
    local wp = GetFirstBlipInfoId(8)

    if DoesBlipExist(wp) then
        local meta = GetBlipInfoIdCoord(wp)
        local fin = puntos[#puntos]
        parcial = math.sqrt((fin.x - meta.x) ^ 2 + (fin.y - meta.y) ^ 2) > 200.0
    end

    return {
        puntos = puntos,
        largo = math.floor(largo > 0 and largo or recorrido),
        slot = slot,
        forma = formaBuena and formaBuena.nombre or '?',
        parcial = parcial,
    }
end

--[[ Esperar al camino del waypoint que se acaba de poner, no a uno cualquiera.

     Antes se esperaba a que "algun slot tuviera ruta", y eso se cumplia en el
     acto con la ruta VIEJA (la del waypoint anterior, que el juego tarda unos
     fotogramas en tirar) o con la de un trabajo: el mapa grande dibujaba el
     camino a otro sitio. Ahora vale solo el trazado que acaba donde esta el
     waypoint (TrazadoDelGps lo marca como parcial si no). Recorrer la ruta
     cuesta, asi que se mira cada 150 ms y no en cada fotograma. Si en tres
     segundos no hay camino —el mar, una isla— se devuelve nil y la interfaz
     pinta la linea recta. ]]
function EsperarTrazado(ms)
    local hasta = GetGameTimer() + (ms or 3000)

    while GetGameTimer() < hasta do
        if SlotActivo() then
            local t = TrazadoDelGps()
            if t and not t.parcial then return t end
        end
        Wait(150)
    end

    return nil
end

--[[ Para cuando la ruta no salga y haya que averiguar por que. Dice que
     nombres existen, que contesta cada forma en cada slot y cuantos puntos
     saca. Sin esto, un trazado que no aparece no deja ni un rastro. ]]
RegisterCommand('mapadiag', function()
    local function di(t) print('[mapa] ' .. t) end

    di('---- diagnostico del trazado v3 ----')

    local function comoEstaElRadar()
        local ok, oculto = pcall(IsRadarHidden)
        if not ok or type(oculto) ~= 'boolean' then return 'no se puede saber' end
        return oculto and 'OCULTO' or 'a la vista'
    end

    di(('nombres: GetPosAlongGpsTypeRoute=%s  GetGpsWaypointRouteEnd=%s')
        :format(type(GetPosAlongGpsTypeRoute), type(GetGpsWaypointRouteEnd)))

    --[[ Lo primero: ¿hay waypoint? Sin el no hay ruta que leer, y todo lo demas
         sale a cero sin que eso quiera decir nada. El blip del waypoint es el
         sprite 8. ]]
    local wp = GetFirstBlipInfoId(8)
    local puesto = false

    if DoesBlipExist(wp) then
        local c = GetBlipInfoIdCoord(wp)
        di(('waypoint: SI, en %.1f, %.1f'):format(c.x, c.y))
    else
        -- Se pone uno de prueba para que el diagnostico no dependa de nada.
        di('waypoint: no habia. Pongo uno de prueba en Mission Row (425, -979)')
        SetNewWaypoint(425.1, -979.5)
        puesto = true

        local hasta = GetGameTimer() + 3000
        while GetGameTimer() < hasta and not GetGpsBlipRouteFound() do Wait(0) end
        Wait(500)
    end

    --[[ La medida que decide: como esta la cosa ANTES de tocar el radar y
         DESPUES de encenderlo. Si al encenderlo aparece la ruta, la causa es el
         radar; si sigue sin haberla, el problema es otro y hay que buscar por
         otro lado. ]]
    di(('ANTES   radar=%s  rutaDeBlip=%s  largo=%s  enVehiculo=%s')
        :format(comoEstaElRadar(), tostring(GetGpsBlipRouteFound()),
            tostring(GetGpsBlipRouteLength()),
            tostring(IsPedInAnyVehicle(PlayerPedId(), false))))

    RadarParaLaRuta(true)
    Wait(1500)

    di(('DESPUES radar=%s  rutaDeBlip=%s  largo=%s')
        :format(comoEstaElRadar(), tostring(GetGpsBlipRouteFound()),
            tostring(GetGpsBlipRouteLength())))

    -- A varias distancias: si solo falla en el metro cero es otra cosa.
    local DISTANCIAS = { 0.0, 10.0, 25.0, 50.0, 100.0, 250.0 }

    for _, forma in ipairs(FORMAS) do
        for _, slot in ipairs(SLOTS) do
            local linea = {}
            for _, d in ipairs(DISTANCIAS) do
                local ok, pos = pcall(forma.pedir, true, d, slot)
                if not ok then
                    linea[#linea + 1] = ('%dm=ERROR'):format(d)
                elseif pos == nil then
                    linea[#linea + 1] = ('%dm=nil'):format(d)
                else
                    linea[#linea + 1] = ('%dm=%.0f,%.0f'):format(d, pos.x or -1, pos.y or -1)
                end
            end
            di(('%-34s slot %d  %s'):format(forma.nombre, slot, table.concat(linea, '  ')))
        end
    end

    --[[ Y lo mismo con el otro sentido del primer argumento: si "desde el
         jugador" no da nada, a lo mejor si lo da "desde el siguiente nodo". ]]
    di('-- con desdeJugador = false --')
    for _, slot in ipairs(SLOTS) do
        local linea = {}
        for _, d in ipairs(DISTANCIAS) do
            local ok, pos = pcall(FORMAS[1].pedir, false, d, slot)
            linea[#linea + 1] = (ok and pos) and ('%dm=%.0f,%.0f'):format(d, pos.x, pos.y)
                or ('%dm=nil'):format(d)
        end
        di(('slot %d  %s'):format(slot, table.concat(linea, '  ')))
    end

    local t = TrazadoDelGps()
    di(('trazado: %s'):format(t
        and ('%d puntos, %d m, slot %d, por %s%s')
            :format(#t.puntos, t.largo, t.slot, t.forma, t.parcial and ' (PARCIAL: no llega al destino)' or '')
        or 'ninguno'))

    if puesto then
        di('quito el waypoint de prueba')
        DeleteWaypoint()
    end

    RadarParaLaRuta(false)

    di('---- fin ----')
end, false)

--[[ El latido: la hora y dónde estás, cada pocos segundos mientras el mapa está
     abierto. Son natives del cliente, sin ida al servidor, así que no cuesta
     nada; y sin esto el reloj se queda parado en la hora de apertura y las
     distancias de la lista mienten en cuanto echas a andar. ]]
--[[ Una ruta que no ha puesto este mapa: la de un trabajo del movil.

     Esas no son un waypoint sino un blip con ruta que pone origen_map, asi que
     el panel no se enteraba: el minimapa la pintaba y el mapa grande no. Solo
     cuando no hay waypoint, que si lo hay es ese el que se sigue. ]]
local function RutaDeFuera()
    if HayWaypoint() then return nil end
    if GetResourceState('origen_map') ~= 'started' then return nil end

    local ok, r = pcall(function() return exports.origen_map:RutaPuesta() end)
    if not ok or type(r) ~= 'table' or not tonumber(r.x) then return nil end

    return { x = r.x, y = r.y, nombre = r.nombre }
end

RegisterNUICallback('mapaAmbiente', function(_, cb)
    local c = GetEntityCoords(PlayerPedId())
    cb({
        fuera = RutaDeFuera(),
        waypoint = WaypointAhora(),
        ambiente = AmbienteAhora(),
        yo = { x = math.floor(c.x * 10) / 10, y = math.floor(c.y * 10) / 10, h = math.floor(GetEntityHeading(PlayerPedId())) },
        -- La ruta viaja con el latido porque su primer punto eres tu: si no se
        -- rehace al moverte, el trazado se queda colgando donde estabas.
        ruta = TrazadoDelGps(),
    })
end)

--- Recargar los puntos sin cerrar el mapa.
RegisterNUICallback('mapaDatos', function(_, cb)
    cb(DatosDelMapa())
end)

--[[ Marcar un punto en el GPS del juego. Es lo que se espera de un mapa: que
     puedas decir "voy ahí" sin tener que buscarlo otra vez en el del juego. ]]
RegisterNUICallback('mapaMarcar', function(datos, cb)
    local x, y = tonumber(datos and datos.x), tonumber(datos and datos.y)
    if not x or not y then return cb(false) end

    --[[ Si vas en coche, la ruta es de todos los que van dentro. Es lo que
         hacia el mapa del GTA de siempre y lo que se espera cuando dos van al
         mismo sitio: el que la marca no tiene que dictarle el camino al que
         conduce.

         Quien va dentro lo decide el servidor y no esto: desde el cliente
         habria que mandarle una lista de a quien avisar, y una lista que llega
         del cliente es una lista en la que se puede meter cualquiera. ]]
    if IsPedInAnyVehicle(PlayerPedId(), false) then
        TriggerServerEvent('origen_inventory:mapa:rutaDelCoche', {
            x = math.floor(x * 10) / 10,
            y = math.floor(y * 10) / 10,
            nombre = tostring(datos and datos.nombre or ''):sub(1, 40),
        })
    end

    -- Que el radar se quede encendido aunque cierres el mapa: sin el, a pie te
    -- quedas sin la ruta en el minimapa en cuanto sales de esta pantalla.
    SeguirLaRuta(true)

    --[[ Poner el punto y comprobar que se ha quedado (MapaPonerWaypoint), y
         contestar con el camino HASTA ESE PUNTO (EsperarTrazado). `puesto`
         dice la verdad: si el juego no lo ha cogido, la interfaz lo sabe. ]]
    CreateThread(function()
        local puesto = MapaPonerWaypoint(x, y)
        cb({ puesto = puesto, ruta = puesto and EsperarTrazado(3000) or nil })
    end)
end)

RegisterNUICallback('mapaQuitarRuta', function(_, cb)
    cb(true)

    --[[ El radar se suelta DESPUES de que el punto se haya ido: apagandolo en
         el mismo fotograma, el juego ya no llegaba a vaciar la ruta y el
         minimapa la seguia pintando. ]]
    CreateThread(function()
        MapaQuitarWaypoint()
        Wait(250)
        if not HayWaypoint() then SeguirLaRuta(false) end
    end)
end)

--[[ Lo que se puede saber de un sitio cualquiera del mapa: en qué barrio cae y
     a cuánto está POR CARRETERA.

     La distancia en línea recta la calcula la interfaz sola —le sobra con las
     coordenadas—, pero la de carretera es un native: es la cifra que enseña el
     mapa del juego, y la que de verdad dice si merece la pena ir.

     Devuelve nil cuando el juego no encuentra camino —un sitio en mitad del
     mar, una isla— en vez de un numero enorme: mejor no decir nada que mentir. ]]
RegisterNUICallback('mapaPunto', function(datos, cb)
    local x, y = tonumber(datos and datos.x), tonumber(datos and datos.y)
    if not x or not y then return cb(nil) end

    local z = tonumber(datos and datos.z) or 0.0
    local yo = GetEntityCoords(PlayerPedId())

    local carretera = CalculateTravelDistanceBetweenPoints(yo.x, yo.y, yo.z, x + 0.0, y + 0.0, z + 0.0)
    if not carretera or carretera <= 0 or carretera > 100000 then carretera = nil end

    cb({
        barrio = BarrioDe(x, y, z),
        carretera = carretera and math.floor(carretera) or nil,
    })
end)


--[[ ══ Marcadores propios ═══════════════════════════════════════════════════

     Guardar un sitio con nombre. Es lo que se le pide a un mapa y lo que no
     tiene ningun otro sitio donde vivir. ]]

RegisterNUICallback('mapaGuardarMarcador', function(datos, cb)
    local x, y = tonumber(datos and datos.x), tonumber(datos and datos.y)
    local nombre = tostring(datos and datos.nombre or ''):sub(1, 40)

    if not x or not y or nombre == '' then return cb(false) end

    local lista = MarcadoresGuardados()
    lista[#lista + 1] = {
        -- El reloj del juego no vale como identificador —dos marcadores en el
        -- mismo segundo tendrian el mismo—, asi que se le pega un contador.
        id = ('m%d_%d'):format(GetGameTimer(), #lista + 1),
        nombre = nombre,
        x = math.floor(x * 10) / 10,
        y = math.floor(y * 10) / 10,
    }

    EscribirMarcadores(lista)
    cb(true)
end)

RegisterNUICallback('mapaBorrarMarcador', function(datos, cb)
    local id = tostring(datos and datos.id or '')
    if id == '' then return cb(false) end

    local lista, quedan = MarcadoresGuardados(), {}
    for _, m in ipairs(lista) do
        if tostring(m.id) ~= id then quedan[#quedan + 1] = m end
    end

    EscribirMarcadores(quedan)
    cb(true)
end)

--[[ ══ Compartir un punto ════════════════════════════════════════════════════

     Mandarle un sitio a quien tengas alrededor. Esto es lo que hace que el mapa
     sea de dos y no de uno: dos jugadores mirando el mismo punto.

     Va a los de cerca y no a una lista de nombres a proposito: no hace falta
     elegir a nadie, no depende de bandas ni de trabajos, y se parece a lo que
     harias de verdad —señalar algo a los que tienes al lado—. ]]

--[[ A UNA persona, la que elijas. En el menu de pausa se mandaba a todo el que
     el servidor creyera a 120 m, sin elegir, y acababa llegando a todo el
     servidor. El destino lo valida el servidor, no esto. ]]
RegisterNUICallback('mapaCompartir', function(datos, cb)
    local x, y = tonumber(datos and datos.x), tonumber(datos and datos.y)
    local destino = tonumber(datos and datos.destino)
    if not x or not y or not destino then return cb(false) end

    TriggerServerEvent('origen_inventory:mapa:compartir', {
        x = math.floor(x * 10) / 10,
        y = math.floor(y * 10) / 10,
        nombre = tostring(datos and datos.nombre or 'Punto'):sub(1, 40),
        destino = math.floor(destino),
    })
    cb(true)
end)

--[[ Los que tienes alrededor, para elegir a quien compartir. Solo es una
     ayuda para no tener que saberse el ID: el servidor no se fia de esta
     lista para nada. ]]
local ALCANCE_CERCANOS = 50.0

RegisterNUICallback('mapaCercanos', function(_, cb)
    local yo = PlayerPedId()
    local desde = GetEntityCoords(yo)
    local lista = {}

    for _, jugador in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(jugador)
        if ped ~= yo then
            local d = #(desde - GetEntityCoords(ped))
            if d <= ALCANCE_CERCANOS then
                lista[#lista + 1] = { playerId = GetPlayerServerId(jugador), distancia = math.floor(d * 10) / 10 }
            end
        end
    end

    table.sort(lista, function(a, b) return a.distancia < b.distancia end)
    cb(lista)
end)

RegisterNetEvent('origen_inventory:mapa:puntoCompartido', function(punto)
    if type(punto) ~= 'table' or not punto.x or not punto.y then return end

    RecibirCompartido(punto)

    exports['origen_notify']:Notify({
        description = ('%s te ha compartido un punto: %s')
            :format(punto.de or 'Alguien', punto.nombre or 'Punto'),
        type = 'info',
        duration = 6000,
    })

    -- Si tienes el mapa abierto, que aparezca sin tener que cerrarlo y volver.
    SendNUIMessage({ action = 'MapaRefrescar' })
end)

--[[ ══ La ruta del que va contigo ═════════════════════════════════════════════

     Alguien de tu coche ha marcado un sitio: te lo pone a ti tambien.

     No se pregunta. Ya estas metido en el mismo coche que quien la marca, y un
     "¿aceptas?" en mitad de la conduccion es peor que la ruta que sustituye.
     Lo que si hay es aviso, que es la diferencia entre que te cambien el GPS y
     que no sepas por que te lo han cambiado. ]]

--[[ Adoptar una ruta que no ha puesto este mapa.

     La pone en el GPS del juego y ademas se la queda el panel: la ensena
     dibujada, con su camino y su distancia, igual que si la hubieras marcado
     tu desde aqui. Sin esto, una ruta puesta desde fuera existe en el juego
     pero el mapa grande no se entera y sale vacio.

     Es lo que hace falta para que marcar desde el movil se note. A pie no hay
     minimapa en este servidor --Config.RadarConRuta = false, a proposito-- asi
     que un SetNewWaypoint a secas no ensena nada por ningun lado: la ruta esta
     puesta y no hay donde verla. Adoptandola, al menos el mapa grande la tiene.

     Devuelve false si el sitio no vale, para que quien llame sepa que no ha
     cogido. ]]
local function AdoptarRuta(x, y, nombre, de)
    x, y = tonumber(x), tonumber(y)
    if not x or not y then return false end

    SeguirLaRuta(true)

    local sitio = nombre
    if sitio == nil or sitio == '' then sitio = BarrioDe(x, y, 0.0) end

    --[[ El punto se pone con comprobacion (MapaPonerWaypoint) y el trazado se
         espera hasta que llegue a ESE punto (EsperarTrazado): el juego tarda
         unos fotogramas en calcular el camino. Si no llega en tres segundos se
         manda igual, sin camino, y el panel enseña la linea recta. ]]
    CreateThread(function()
        if not MapaPonerWaypoint(x, y) then return end

        SendNUIMessage({
            action = 'MapaRutaDeOtro',
            ruta = { x = x, y = y, nombre = sitio, de = de },
            trazado = EsperarTrazado(3000),
        })
    end)

    return true
end

--- Para el movil y para cualquier otro recurso que ponga una ruta: que el mapa
--- grande la ensene en vez de quedarse a oscuras. `de` es opcional.
exports('MarcarRuta', function(x, y, nombre, de)
    return AdoptarRuta(x, y, nombre, de)
end)

RegisterNetEvent('origen_inventory:mapa:rutaDelCoche', function(ruta)
    if type(ruta) ~= 'table' then return end
    if not AdoptarRuta(ruta.x, ruta.y, ruta.nombre, ruta.de or 'Alguien') then return end

    local sitio = ruta.nombre
    if sitio == nil or sitio == '' then sitio = BarrioDe(tonumber(ruta.x), tonumber(ruta.y), 0.0) end

    exports['origen_notify']:Notify({
        description = (sitio and sitio ~= '')
            and ('%s ha marcado una ruta: %s'):format(ruta.de or 'Alguien', sitio)
            or ('%s ha marcado una ruta en el mapa'):format(ruta.de or 'Alguien'),
        type = 'info',
        duration = 6000,
    })
end)

--[[ ══ Ruta con paradas ═══════════════════════════════════════════════════════

     Lo unico que este mapa hace y el del juego no: encadenar varios sitios.

     El waypoint se pone en la PRIMERA parada, que es la que el GPS va a
     calcular por carretera; las demas van en la multi-ruta, que el juego pinta
     en el radar como una cadena. Al llegar a una, el jugador pasa a la
     siguiente desde aqui.

     Si los natives de la multi-ruta no responden, se queda el waypoint de la
     primera parada: se pierde la cadena en el radar, no la ruta. ]]

RegisterNUICallback('mapaParadas', function(datos, cb)
    local paradas = type(datos) == 'table' and datos.paradas or nil
    if type(paradas) ~= 'table' or #paradas == 0 then return cb(false) end

    pcall(ClearGpsMultiRoute)

    -- 8 es el color rosa del HUD; true/true = empezar en el jugador y pintarla
    -- tambien a pie.
    local montada = pcall(function()
        StartGpsMultiRoute(8, true, true)
        for _, q in ipairs(paradas) do
            AddPointToGpsMultiRoute(q.x + 0.0, q.y + 0.0, tonumber(q.z) or 0.0)
        end
        SetGpsMultiRouteRender(true)
    end)

    -- Y el waypoint en la primera, que es de donde sale el trazado por
    -- carretera que se pinta en el panel.
    SeguirLaRuta(true)

    CreateThread(function()
        local puesto = MapaPonerWaypoint(paradas[1].x, paradas[1].y)
        cb({ puesto = puesto, cadena = montada, ruta = puesto and EsperarTrazado(3000) or nil })
    end)
end)

RegisterNUICallback('mapaQuitarParadas', function(_, cb)
    pcall(ClearGpsMultiRoute)
    cb(true)

    CreateThread(function()
        MapaQuitarWaypoint()
        Wait(250)
        if not HayWaypoint() then SeguirLaRuta(false) end
    end)
end)

--- Cuantos han recibido el punto que acabas de compartir. Sin esto no sabes si
--- ha llegado a alguien o has hablado solo.
RegisterNetEvent('origen_inventory:mapa:compartido', function(resultado, destino)
    local textos = {
        ok = { ('Punto compartido con el ID %s'):format(tostring(destino)), 'success' },
        nadie = { 'Ese ID no está conectado', 'error' },
        espera = { 'Espera un momento antes de compartir otro', 'error' },
    }
    local t = textos[resultado] or textos.nadie

    exports['origen_notify']:Notify({ description = t[1], type = t[2], duration = 4000 })
end)


--[[ ══ Zonas dibujadas a mano ═════════════════════════════════════════════

     Se marcan pulsando en el mapa punto a punto y se cierran cuando hay tres o
     mas. Tres es el minimo real: con dos no hay area, hay una raya. ]]

RegisterNUICallback('mapaGuardarZona', function(datos, cb)
    local vertices = type(datos) == 'table' and datos.vertices or nil
    local nombre = tostring(datos and datos.nombre or ''):sub(1, 40)

    if type(vertices) ~= 'table' or #vertices < 3 or nombre == '' then
        return cb(false)
    end

    local limpios = {}
    for _, v in ipairs(vertices) do
        local x, y = tonumber(v.x), tonumber(v.y)
        if x and y then
            limpios[#limpios + 1] = {
                x = math.floor(x * 10) / 10,
                y = math.floor(y * 10) / 10,
            }
        end
    end
    if #limpios < 3 then return cb(false) end

    local lista = ZonasGuardadas()
    lista[#lista + 1] = {
        id = ('z%d_%d'):format(GetGameTimer(), #lista + 1),
        nombre = nombre,
        vertices = limpios,
    }

    EscribirZonas(lista)
    cb(true)
end)

RegisterNUICallback('mapaBorrarZona', function(datos, cb)
    local id = tostring(datos and datos.id or '')
    if id == '' then return cb(false) end

    local quedan = {}
    for _, z in ipairs(ZonasGuardadas()) do
        if tostring(z.id) ~= id then quedan[#quedan + 1] = z end
    end

    EscribirZonas(quedan)
    cb(true)
end)

--[[ ══ Los ajustes del minimapa ═══════════════════════════════════════════

     El minimapa lo dibuja origen_map, que no tiene pantalla propia. Sus
     ajustes se tocan desde aqui, que es el sitio natural: quien quiere cambiar
     como se ve el mapa pequeño ya esta mirando el grande.

     Este fichero solo hace de puente. Los valores validos, el valor de partida
     y donde se guardan viven en origen_map: si estuvieran repetidos aqui,
     añadir una opcion alli seria acordarse de tocar dos recursos. ]]

local function HayMinimapa()
    return GetResourceState('origen_map') == 'started'
end

RegisterNUICallback('mapaAjustesLeer', function(_, cb)
    if not HayMinimapa() then cb(false) return end

    local ok, ajustes = pcall(function()
        return exports.origen_map:Ajustes()
    end)

    cb(ok and ajustes or false)
end)

RegisterNUICallback('mapaAjustesPoner', function(datos, cb)
    if not HayMinimapa() or type(datos) ~= 'table' then cb(false) return end

    -- Sin validar aqui a proposito: origen_map comprueba clave y valor contra
    -- su propia tabla, que es la unica que sabe lo que existe.
    TriggerEvent('origen_map:ponerAjuste', datos.clave, datos.valor)
    cb(true)
end)

--[[ Colocar el minimapa en otro sitio de la pantalla.

     Se arrastra la caja de verdad, encima del juego, y no una maqueta dentro
     del diálogo: donde queda bien solo se sabe viendo lo que tapa. Asi que el
     inventario se QUITA de en medio, origen_map se queda con el raton el rato
     que dure, y al acabar nos devuelve el `volver` que le damos aqui para
     que reabramos el mapa grande con los ajustes abiertos, como estaban.

     Se cierra primero y se avisa despues: el foco es de cada recurso, pero
     con dos pantallas pidiendo el raton a la vez no hay forma de saber cual
     se queda los clics. ]]
RegisterNUICallback('mapaPosicionarMinimapa', function(_, cb)
    if not HayMinimapa() then cb(false) return end
    cb(true)

    if Player and Player.isOpen then
        Player:CloseInventory(false, false)
    end

    TriggerEvent('origen_map:posicionar', { volver = 'ajustesMinimapa' })
end)

--[[ Y la vuelta. Solo si el viaje era nuestro: otro recurso puede mandar a
     colocar el minimapa con su propio `volver` y no le toca al inventario
     abrirse por el.

     Un respiro antes de abrir: se ha confirmado con ENTER o cancelado con
     ESC, y si la tecla sigue abajo cuando el inventario coge el raton, su
     repeticion le llegaria al mapa grande, que con el ESC se cierra. ]]
AddEventHandler('origen_map:posicionarAcabado', function(volver)
    if volver ~= 'ajustesMinimapa' then return end

    SetTimeout(150, function()
        exports[GetCurrentResourceName()]:AbrirEnPestana('city', false, 'ajustesMinimapa')
    end)
end)


--[[ ══ Lo que en el menu de pausa estaba en otro fichero ═══════════════════

     Abrir y cerrar: el menu de pausa encendia el radar en su propio
     openNewPauseMenu. Aqui el mapa es una pieza del inventario que se monta y
     se desmonta, asi que es la pantalla la que avisa. ]]
RegisterNUICallback('mapaAbierto', function(datos, cb)
    RadarParaLaRuta(datos and datos.abierto == true)
    cb(true)
end)

--[[ Los locales y tus vehiculos. Necesitan al servidor, asi que no viajan con
     la apertura: el mapa se abre en el acto y esto llega un momento despues.

     Se sirven como PUNTOS y CATEGORIAS con la misma forma que los blips, para
     que la pantalla no tenga que saber de donde sale cada capa. ]]
RegisterNUICallback('mapaExtras', function(_, cb)
    local puntos, categorias = {}, {}

    --[[ Los locales, los mismos de la pestaña de Ciudad (CiudadLocales, en
         f_origen_ciudad.lua). El color NO es el de una categoria: es su
         estado, abierto o cerrado. ]]
    local abiertos = 0
    for _, n in ipairs(CiudadLocales()) do
        local c = n.coords
        if type(c) == 'table' and c.x and c.y then
            if n.isOpen then abiertos = abiertos + 1 end
            puntos[#puntos + 1] = {
                x = c.x, y = c.y,
                cat = 'locales', catLabel = 'Locales', icono = 'local',
                nombre = n.label or n.name or 'Local',
                barrio = n.barrio,
                abierto = n.isOpen and true or false,
                empleados = tonumber(n.employees) or 0,
                logo = n.logo,
            }
        end
    end

    if #puntos > 0 then
        categorias[#categorias + 1] = { id = 'locales', label = 'Locales', icono = 'local', abiertos = abiertos }
    end

    --[[ Tus vehiculos, solo los que estan FUERA: los guardados estan en un
         garaje, y el garaje ya sale en el mapa. El servidor los busca por
         matricula entre los vehiculos cargados (f_origen_mapa.lua). ]]
    local mios = lib.callback.await('origen_inventory:mapa:misVehiculos', false) or {}
    for _, v in ipairs(mios) do
        if v.x and v.y then
            puntos[#puntos + 1] = {
                x = v.x, y = v.y,
                cat = 'vehiculos', catLabel = 'Mis vehículos', icono = 'coche',
                nombre = v.modelo or 'Vehículo',
                barrio = BarrioDe(v.x, v.y, v.z or 0.0),
                matricula = v.matricula,
                propio = true,
            }
        end
    end

    if #mios > 0 then
        categorias[#categorias + 1] = { id = 'vehiculos', label = 'Mis vehículos', icono = 'coche' }
    end

    cb({ puntos = puntos, categorias = categorias })
end)

--[[ ══ El menu de pausa de GTA, apagado ═══════════════════════════════════

     Lo hacia origen_pausemenu y era lo UNICO del servidor que lo impedia: sin
     esto, ESC y P vuelven a abrir el menu y el mapa del juego. El ESC es del
     radial de origen_hud, y el mapa es este. Va tambien el mapa grande del
     radar: con el minimapa del juego empujado fuera de la pantalla por
     origen_map, su tecla expandia un radar que no se ve.

     Una vez por fotograma, que es lo que hace falta para ganarle al juego. ]]
CreateThread(function()
    while true do
        SetPauseMenuActive(false)
        SetRadarBigmapEnabled(false, false)
        Wait(0)
    end
end)

--[[ ══ La tecla del mapa ══════════════════════════════════════════════════

     Una tecla que abre el mapa grande directamente, sin pasar por el
     inventario ni por Ciudad. La elige cada jugador en «Ajustes del minimapa»
     (MapaGrande.vue) y de serie no hay ninguna: cualquier letra que
     pusieramos aqui ya la tiene alguien para otra cosa.

     Se lee con IsRawKeyPressed y no con RegisterKeyMapping, igual que los
     bindeos de origen_anims: un mapping no se puede cambiar desde codigo --se
     queda con la primera tecla que vio el perfil--, y aqui la tecla la cambia
     el jugador cuando quiera. `vk` es el codigo de tecla virtual de Windows,
     que para letras, cifras y F1-F12 es el mismo keyCode que da el navegador.

     Se guarda con KVP, como los demas ajustes del minimapa: es cosa de tu
     teclado, no de tu personaje. ]]
local KVP_TECLA = 'origen_inventory:mapa_tecla'

--[[ Las que no se pueden coger. Moverse, el chat, los huecos del inventario
     (commands.lua), su tecla de abrir y las que ya usa la NUI para cerrar y
     confirmar. La NUI tiene la misma lista para avisar al momento; esta es la
     que manda. ]]
local TECLAS_COGIDAS = {
    W = true, A = true, S = true, D = true, T = true,
    ['1'] = true, ['2'] = true, ['3'] = true, ['4'] = true, ['5'] = true, ['6'] = true, ['7'] = true,
    TAB = true, ESC = true, ENTER = true, F8 = true,
}
if Config.DefaultOpenKey then TECLAS_COGIDAS[tostring(Config.DefaultOpenKey):upper()] = true end

local function LeerTecla()
    local texto = GetResourceKvpString(KVP_TECLA)
    if not texto or texto == '' then return nil end
    local ok, t = pcall(json.decode, texto)
    if not ok or type(t) ~= 'table' then return nil end
    -- El JSON puede devolver 77.0 y el native quiere un entero.
    local vk = math.tointeger(tonumber(t.vk))
    if not vk or type(t.key) ~= 'string' then return nil end
    return { key = t.key, vk = vk }
end

local teclaMapa = LeerTecla()

RegisterNUICallback('mapaTeclaLeer', function(_, cb)
    cb({
        tecla = teclaMapa or false,
        -- Sin los IsRawKey* no hay forma de leer una tecla cualquiera.
        disponible = IsRawKeyPressed ~= nil,
        cogidas = (function()
            local l = {}
            for k in pairs(TECLAS_COGIDAS) do l[#l + 1] = k end
            return l
        end)(),
    })
end)

--- `{ key, vk }` para ponerla, o `{ quitar = true }` para dejar el mapa sin tecla.
RegisterNUICallback('mapaTeclaPoner', function(datos, cb)
    if type(datos) ~= 'table' then cb(false) return end

    if datos.quitar then
        teclaMapa = nil
        DeleteResourceKvp(KVP_TECLA)
        cb({ tecla = false })
        return
    end

    local key = type(datos.key) == 'string' and datos.key:upper() or nil
    local vk = math.tointeger(tonumber(datos.vk))
    if not key or #key > 6 or not vk or vk < 8 or vk > 254 or TECLAS_COGIDAS[key] then
        cb(false)
        return
    end

    teclaMapa = { key = key, vk = vk }
    SetResourceKvp(KVP_TECLA, json.encode(teclaMapa))
    cb({ tecla = teclaMapa })
end)

--[[ La misma tecla con el mapa abierto lo cierra: la NUI tiene el foco y
     aqui abajo no llega, asi que es ella la que avisa. Se cierra el
     inventario entero, que es lo que abrio la tecla. ]]
RegisterNUICallback('mapaTeclaCerrar', function(_, cb)
    cb(true)
    if Player and Player.isOpen then
        Player:CloseInventory(false, false)
    end
end)

if IsRawKeyPressed then
    CreateThread(function()
        while true do
            --[[ Las teclas «en crudo» llegan aunque haya un chat o un menu con
                 el foco: sin IsNuiFocused, escribir una frase con esa letra
                 abriria el mapa. Mismas guardas que el comando del inventario
                 (commands.lua). ]]
            local libre = teclaMapa ~= nil and not IsNuiFocused() and not IsPauseMenuActive()
                and not Inventory.locked
                and not (Config.Framework == 'qbcore' and not LocalPlayer.state.isLoggedIn)

            if libre and IsRawKeyPressed(teclaMapa.vk) and not (Player and Player.isOpen) then
                exports[GetCurrentResourceName()]:AbrirEnPestana('city', false, 'mapa')
            end

            Wait(libre and 0 or 250)
        end
    end)
end

--[[ Las categorias apagadas en el mapa grande, al minimapa (29/09): lo que
     escondes aqui tampoco sale en la esquina. origen_map las guarda y filtra. ]]
RegisterNUICallback('mapaOcultas', function(datos, cb)
    local lista = type(datos) == 'table' and datos.apagadas
    if type(lista) == 'table' then
        TriggerEvent('origen_map:ponerOcultas', lista)
    end
    cb(true)
end)
