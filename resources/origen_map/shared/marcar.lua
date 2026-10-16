--[[ ═══════════════════════════════════════════════════════════════════════
     Marcar un sitio en el mapa, desde cualquier recurso

     Este fichero NO se carga en origen_map: se carga EN EL OTRO RECURSO,
     poniendolo el primero de sus client_scripts:

         client_scripts {
             '@origen_map/shared/marcar.lua',
             'client/main.lua',
         }

     Y a partir de ahi:

         OrigenMapa.Poner('gasolinera_1', {
             x = 265.0, y = -1261.0, z = 29.0,
             cat = 'gasolineras',
             nombre = 'Gasolinera Strawberry',
         })

         OrigenMapa.Quitar('gasolinera_1')

         OrigenMapa.PonerVarios('gasolinera', lista)   -- una tanda entera

     El punto entero —todos los campos que admite— esta explicado en
     origen_map/client/registro.lua. Los de siempre son estos cuatro:

         x, y, z    donde
         cat        de que es (garages, banking, shops, trabajos, ...)
         nombre     como se llama; es lo que se lee en la lista del mapa grande
         ruta       true si ademas tiene que marcar el camino del GPS

     ── Por que un evento y no el export ───────────────────────────────────

     Porque un export revienta en seco si origen_map no esta arrancado, y esto
     se llama desde cuarenta recursos: un mapa parado no puede llevarse por
     delante el arranque de un trabajo. Un evento al que no contesta nadie se
     cae al vacio sin ruido, que es exactamente lo que se quiere aqui.

     ── La clave ───────────────────────────────────────────────────────────

     Lleva delante el nombre del recurso, que se pone aqui solo: dos recursos
     pueden usar 'principal' sin pisarse. Y al parar un recurso, sus puntos se
     van con el sin que nadie tenga que acordarse de barrerlos.
   ═══════════════════════════════════════════════════════════════════════ ]]

OrigenMapa = {}

--- El nombre del recurso QUE CARGA este fichero, no el de origen_map: este
--- fichero corre dentro del otro recurso, que es justo lo que hace que la
--- clave salga bien sin que nadie la escriba.
local YO = GetCurrentResourceName()

--[[ Lo que este recurso ha mandado al mapa, para poder repetirlo.

     Hace falta por el orden de arranque. Un recurso pone sus puntos al
     arrancar, una vez; si origen_map todavia no esta vivo en ese momento,
     nadie escucha el evento y esos puntos no existen para nadie. Y lo mismo
     pasa cada vez que alguien reinicia origen_map a mano: el registro se va
     con el y se lleva por delante los puntos de los cuarenta recursos, que ya
     no los van a volver a mandar.

     Asi que se guarda aqui una copia y se vuelve a mandar entera cuando el
     mapa avisa de que esta listo. Es la lista de un recurso —unas decenas de
     puntos— y solo se recorre en ese momento. ]]
local puestos = {}

local function ClaveDe(clave)
    clave = tostring(clave or '')
    if clave:find(':', 1, true) then return clave end
    return YO .. ':' .. clave
end

--[[ El mapa acaba de arrancar y no sabe nada de nosotros.

     Se le vuelve a contar todo lo que este recurso tenia puesto. Los que se
     quitaron por el camino no estan en la copia, asi que no vuelven. ]]
AddEventHandler('origen_map:listo', function()
    for clave, punto in pairs(puestos) do
        if punto.lista then
            TriggerEvent('origen_map:ponerVarios', clave, punto.lista)
        else
            TriggerEvent('origen_map:poner', clave, punto)
        end
    end
end)

--- Da de alta un punto, o mueve/actualiza el que ya hubiera con esa clave.
function OrigenMapa.Poner(clave, punto)
    if type(punto) ~= 'table' then return end
    local k = ClaveDe(clave)
    puestos[k] = punto
    TriggerEvent('origen_map:poner', k, punto)
end

--[[ Cambia solo el color de un punto que ya esta puesto.

     Para cuando lo que cambia no es la cosa sino su estado: un arbol recien
     talado, una roca en espera. Asi no hay que volver a mandar el punto entero
     con unas coordenadas que muchas veces ya no se tienen a mano. ]]
function OrigenMapa.Tintar(clave, color)
    local k = ClaveDe(clave)
    if puestos[k] and not puestos[k].lista then puestos[k].color = color end
    TriggerEvent('origen_map:tintar', k, color)
end

--- Lo quita del mapa.
function OrigenMapa.Quitar(clave)
    local k = ClaveDe(clave)
    puestos[k] = nil
    TriggerEvent('origen_map:quitar', k)
end

--[[ Una tanda entera de golpe, que es lo normal al arrancar: un recurso pone
     sus cuarenta gasolineras.

     REEMPLAZA la tanda anterior con ese mismo prefijo en vez de sumarse a
     ella, que es lo que se espera al recargar una lista desde un panel: los
     que ya no esten se van solos. ]]
function OrigenMapa.PonerVarios(prefijo, lista)
    if type(lista) ~= 'table' then return end
    local k = ClaveDe(prefijo)
    --- `lista` marca la copia como tanda, para repetirla como tanda.
    puestos[k] = { lista = lista }
    TriggerEvent('origen_map:ponerVarios', k, lista)
end

--[[ ═══════════════════════════════════════════════════════════════════════
     Donde tiene el jugador su punto marcado

     Devuelve las coordenadas del waypoint, o nil si no hay ninguno.

     ── Por que no IsWaypointActive() ──────────────────────────────────────

     Porque miente en este servidor. Ese native solo dice que si cuando el
     punto se ha puesto DESDE EL MAPA DEL JUEGO; el que pone SetNewWaypoint
     —que es como lo pone nuestro mapa, y el movil, y el aviso de la policia—
     no cuenta para el. Y como aqui el mapa nativo ya no se abre nunca, la
     respuesta era siempre false: el punto se veia en el mapa, el blip existia,
     el GPS trazaba la ruta, y aun asi /tpm contestaba «no tienes ningun punto
     marcado».

     El blip de sprite 8 es el waypoint del jugador y ese si esta, lo haya
     puesto quien lo haya puesto. Es lo que mira qbx_core desde siempre, que es
     por lo que su /tpm nunca dio problemas.

     Quien necesite esto sin cargar marcar.lua que copie las tres lineas: lo
     que no puede hacer es preguntar por IsWaypointActive().
   ═══════════════════════════════════════════════════════════════════════ ]]
function OrigenMapa.Waypoint()
    local blip = GetFirstBlipInfoId(8)
    if not DoesBlipExist(blip) then return nil end
    return GetBlipInfoIdCoord(blip)
end

--[[ ═══════════════════════════════════════════════════════════════════════
     El color de un blip de GTA, en color de los nuestros

     Los configs del servidor llevan escrito el color como el numero de GTA
     —`color = 3`, `BlipColor = 1`— porque se escribieron cuando los puntos
     eran blips de verdad. Al pasar al registro esos numeros se quedaron sin
     leer: cambiabas el color en el panel de admin y no pasaba nada.

     Esto los traduce, para que lo que ya esta escrito siga mandando.

     ── De donde salen estos hex ───────────────────────────────────────────

     De origen_police, que llevaba años con esta misma tabla dentro para pintar
     las referencias de su MDT (client/references.lua). No estan sacados de una
     lista de internet: son los que ya se ven en las interfaces de ORIGEN, asi
     que un punto del mapa y una referencia de la MDT con el mismo numero salen
     del mismo color, que es lo que se espera.

     GTA tiene 86 colores de blip y no hay native para preguntar por el RGB de
     ninguno, asi que aqui solo estan los 24 que alguien acabo de afinar en su
     dia. Un numero que no este devuelve nil, y entonces manda el color de la
     categoria: un sitio razonable donde caerse.

     Si aparece uno nuevo y se sabe de que color es, se añade aqui y lo cogen
     los cuarenta recursos a la vez.
   ═══════════════════════════════════════════════════════════════════════ ]]
local COLORES = {
    [0]  = '#ffffff', [1]  = '#e03232', [2]  = '#71cb71', [3]  = '#5db6e5',
    --- El 4 no venia en la tabla de origen_police y es el segundo mas usado en
    --- los configs del servidor. Rosa, que es como lo llama quien lo escribio
    --- (origen_gangwars/config/commands.lua:25). Si al verlo no cuadra, se
    --- cambia aqui y cambia en todas partes.
    [4]  = '#fd9bbd',
    [5]  = '#eec64e', [11] = '#8dcea7', [12] = '#70a8ae', [15] = '#6ac4bf',
    [18] = '#97cae9', [24] = '#bbd65b', [25] = '#0c7b56', [26] = '#7ac3fe',
    [28] = '#cda80c', [29] = '#4561ab', [30] = '#29a5b8', [34] = '#ed8ca1',
    [40] = '#4c4c4c', [41] = '#f29d9d', [46] = '#ecf029', [50] = '#896ce2',
    [76] = '#782323', [82] = '#a4ccaa', [83] = '#a854f2', [85] = '#3d3d3d',
}

--[[ Devuelve '#rrggbb', o nil si ese numero no esta en la tabla.

     Un nil no es un fallo: es «no lo pintes de nada en particular». El campo
     `color` del registro admite nil y en ese caso manda la categoria. ]]
function OrigenMapa.Color(indice)
    return COLORES[tonumber(indice) or -1]
end

--[[ ═══════════════════════════════════════════════════════════════════════
     El sprite de un blip de GTA, en dibujo de los nuestros

     Hermana de OrigenMapa.Color, y por lo mismo: muchos sitios del servidor
     vienen de un config o de la base de datos con el dibujo escrito como el
     numero de sprite de GTA —`sprite = 73`, `blipInfo.sprite = 52`—, y al
     pasar al registro ese numero se quedo sin leer. Todas las tiendas del
     inventario, fueran de ropa o armerias, salian con la misma cesta.

     Esto lo traduce a la clave de la chincheta (el campo `icono` del punto),
     para que lo que ya esta escrito en el panel siga diciendo que es cada sitio.

     ── De donde salen estos numeros ───────────────────────────────────────

     De la lista oficial de blips de FiveM, que es la del juego tal cual
     (docs.fivem.net/docs/game-references/blips, generada del build 3258).
     Al lado de cada uno va el nombre interno del sprite que da esa lista,
     para que se pueda comprobar sin fiarse de nadie. No hay ninguno puesto
     «de memoria»: el que no se ha podido cotejar con esa lista, no esta.

     Ojo con los nombres, que engañan: el 52 se llama `radar_crim_holdups`
     porque en la historia es la tienda que se puede atracar, pero es el
     dibujo de tienda que usan todos los configs; y el 50 NO es un parking,
     es `radar_crim_carsteal`.

     Un numero que no este devuelve nil, y entonces manda el dibujo de la
     categoria, igual que con el color. Si aparece uno nuevo, se añade aqui y
     lo cogen los cuarenta recursos a la vez.
   ═══════════════════════════════════════════════════════════════════════ ]]
local ICONOS = {
    --- Tiendas y servicios
    [52]  = 'cesta',        -- radar_crim_holdups (la tienda 24/7)
    [73]  = 'camiseta',     -- radar_clothes_store
    [71]  = 'tijeras',      -- radar_barber
    [75]  = 'tatuaje',      -- radar_tattoo
    [110] = 'pistola',      -- radar_gun_shop
    [313] = 'pistola',      -- radar_shootingrange_gunshop
    [156] = 'pistola',      -- radar_weapon_pistol
    [93]  = 'copa',         -- radar_bar
    [121] = 'copa',         -- radar_strip_club
    [108] = 'dinero',       -- radar_financier_strand (el $ de los bancos)
    [500] = 'dinero',       -- radar_production_money
    [74]  = 'gimnasio',     -- radar_gym
    [311] = 'gimnasio',     -- radar_arm_wrestling (el brazo de los gimnasios)

    --- Vehiculos
    [72]  = 'taller',       -- radar_car_mod_shop
    [446] = 'taller',       -- radar_bennys
    [402] = 'taller',       -- radar_repair
    [357] = 'coche',        -- radar_garage
    [369] = 'coche',        -- radar_garage_for_sale
    [225] = 'coche',        -- radar_gang_vehicle
    [326] = 'coche',        -- radar_getaway_car
    [856] = 'parking',      -- radar_multistorey_garage
    [810] = 'llave',        -- radar_vehicle_for_sale (concesionario)
    [361] = 'gasolina',     -- radar_jerry_can

    --- Emergencias
    [61]  = 'cruz',         -- radar_hospital
    [153] = 'cruz',         -- radar_weapon_health
    [60]  = 'escudo',       -- radar_police_station
    [526] = 'escudo',       -- radar_police_station_dropoff

    --- Ocio
    [109] = 'golf',         -- radar_golf
    [358] = 'golf',         -- radar_golf_flag
    [122] = 'tenis',        -- radar_tennis
    [95]  = 'baloncesto',   -- radar_basketball
    [97]  = 'bolos',        -- radar_bowling
    [141] = 'caza',         -- radar_hunting
    [740] = 'juego',        -- radar_arcade
    [679] = 'casino',       -- radar_casino
    [680] = 'casino',       -- radar_casino_table_games
    [681] = 'casino',       -- radar_casino_wheel
    [683] = 'casino',       -- radar_casino_chips
    [684] = 'casino',       -- radar_casino_horse_racing

    --- Trabajos
    [198] = 'taxi',         -- radar_taxi
    [513] = 'autobus',      -- radar_bus
    [477] = 'camion',       -- radar_truck
    [318] = 'basura',       -- radar_garbage
    [501] = 'paquete',      -- radar_package

    --- Propiedades
    [40]  = 'casa',         -- radar_safehouse
    [374] = 'local',        -- radar_business
    [375] = 'local',        -- radar_business_for_sale

    --- Carreras e ilegal
    [38]  = 'bandera',      -- radar_raceflag
    [309] = 'bandera',      -- radar_race
    [315] = 'bandera',      -- radar_race_land
    [84]  = 'calavera',     -- radar_rampage
    [390] = 'mira',         -- radar_aim
}

--[[ Devuelve la clave del dibujo, o nil si ese numero no esta en la tabla.

     Igual que con el color, un nil es «no lo dibujes de nada en particular»:
     el campo `icono` del registro admite nil y en ese caso manda la categoria.
     Quien sepa mejor que el config lo que es su sitio puede ponerle detras un
     `or 'lo_que_sea'`. ]]
function OrigenMapa.Icono(sprite)
    return ICONOS[tonumber(sprite) or -1]
end
