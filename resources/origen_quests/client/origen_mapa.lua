--[[
    Los sitios de misión en el mapa.

    Cada localización elige en el panel de administración si sale y cuándo
    (`extra.mapa`, ver Config.MapModes):

      · siempre    — marcada desde que entras, hayas pasado por allí o no.
      · descubrir  — no sale hasta que interactúas con ella; a partir de ahí
                     se te queda para siempre. Es lo de siempre, y lo que se
                     supone cuando una localización no dice nada.
      · nunca      — no sale. Hay que saberse el sitio.

    Los de descubrir los guarda el servidor (server/map_marks.lua), que es
    quien decide qué se descubre; los de siempre salen del propio catálogo de
    localizaciones y no hace falta guardarlos en ninguna parte.

    Vale para los tres mapas del servidor: el del juego —minimapa y mapa
    grande— con el blip de aquí, y los dos de Leaflet —el del menú de pausa y
    el de la pestaña de Ciudad del inventario— por el export del final, que es
    lo que consultan los dos. En esos dos la chincheta es dibujo nuestro, no
    un icono del juego.

    Los blips son de sitio conocido, no de misión activa: van pequeños y en
    blanco para no competir con el amarillo del objetivo en curso
    (client/quests2.lua), que es lo que hay que seguir ahora.
]]

--[[ Una personita, en el mapa del juego.

     Esto vale SÓLO para el minimapa y el mapa grande de GTA, que no admiten
     un dibujo nuestro: hay que elegir uno de los suyos, y el que más se
     parece a «alguien con quien hablar» es este.

     En el mapa del menú de pausa no pinta nada: allí la chincheta la
     dibujamos nosotros en SVG (origen_pausemenu/html/src/App.vue, DIBUJOS.
     persona) y los puntos llegan por el export del final de este fichero, no
     rastreando blips. Cambiar este número no cambia aquello.

     Si en el minimapa no acaba de verse como toca, es este número y sólo
     este. ]]
local SPRITE_PERSONA = 280

local Puntos = {}     -- [poi] = { poi, name, x, y, z }
local Blips = {}      -- [poi] = handle del blip
local Pedidos = false

--[[ Un sitio de mision, en el mapa.

     Ya no es un blip del juego: es un punto de origen_map, y de ahi lo leen
     los tres mapas del servidor. Antes habia que elegir un dibujo de los del
     juego —el 280, «alguien con quien hablar»— porque no se podia dibujar el
     nuestro; ahora la personita la dibujamos nosotros y ese apaño sobra.

     Blanco a proposito: es un sitio conocido, no el objetivo en curso. El de
     la mision activa va amarillo y lo pone quests2.lua. ]]
local function PintarBlip(p)
    if Blips[p.poi] then return end

    local clave = 'sitio_' .. tostring(p.poi)

    OrigenMapa.Poner(clave, {
        x = p.x, y = p.y, z = p.z,
        cat = 'misiones',
        icono = 'exclamacion',
        nombre = p.name or 'Punto de misión',
        -- Descubierto por ESTE jugador: los mapas de Leaflet lo marcan como
        -- suyo, igual que sus marcadores.
        propio = true,
    })

    Blips[p.poi] = clave
end

local function Olvidar()
    for _, clave in pairs(Blips) do
        OrigenMapa.Quitar(clave)
    end
    Blips, Puntos = {}, {}
end

--[[ Los que salen siempre.

     Salen del catálogo que ya tiene el cliente, no de la base: no son un
     descubrimiento de nadie, son sitios que el mapa enseña de serie, y
     guardar una fila por jugador para algo que es igual para todos sería
     apuntar lo mismo mil veces.

     El catálogo llega después de arrancar (client/main.lua lo pide al
     servidor), así que esto se llama desde ahí y también al descubrir algo,
     por si acaso. Repintar es gratis: PintarBlip no repite. ]]
function PintarSitiosDeSiempre(locations)
    if type(locations) ~= 'table' then return end

    for _, loc in pairs(locations) do
        local data = loc.Data or loc
        local extra = data.extra or {}

        if extra.mapa == 'siempre' and type(data.coords) == 'table' then
            for k, c in pairs(data.coords) do
                local x, y, z = tonumber(c and c.x), tonumber(c and c.y), tonumber(c and c.z)
                if x and y then
                    -- Una localización puede tener varios sitios y rotar entre
                    -- ellos: se marcan todos, que el jugador no sabe cuál toca.
                    local p = {
                        poi = ('quest:%s:%s'):format(tostring(data.id), tostring(k)),
                        name = data.name or 'Punto de misión',
                        x = x, y = y, z = z or 0.0,
                    }
                    Puntos[p.poi] = p
                    PintarBlip(p)
                end
            end
        end
    end
end

local function Pedir()
    if Pedidos then return end
    Pedidos = true

    local lista = lib.callback.await('origen_quests:server:MisPuntos', false)
    if type(lista) ~= 'table' then
        -- Que no conteste no puede dejar el mapa mudo para siempre: se suelta
        -- el pestillo para que el siguiente aviso vuelva a intentarlo.
        Pedidos = false
        return
    end

    for _, p in ipairs(lista) do
        Puntos[p.poi] = p
        PintarBlip(p)
    end
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Olvidar()
    Pedidos = false
    Pedir()
end)

-- El recurso puede reiniciarse con el jugador ya dentro, y entonces el evento
-- de arriba no vuelve a dispararse.
CreateThread(function()
    if not LocalPlayer.state.isLoggedIn then return end
    Pedir()
end)

RegisterNetEvent('origen_quests:client:PuntoDescubierto', function(p)
    if type(p) ~= 'table' or not p.poi then return end

    Puntos[p.poi] = p
    PintarBlip(p)
end)

-- Cambiar de personaje sin salir del servidor tiene que llevarse los puntos
-- del anterior: son suyos, no de la cuenta.
RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    Olvidar()
    Pedidos = false
end)

AddEventHandler('onResourceStop', function(recurso)
    if recurso == GetCurrentResourceName() then Olvidar() end
end)

--[[ Lo que consume el mapa de la pestaña de Ciudad (origen_inventory,
     client/functions/f_origen_mapa.lua). Se devuelve una copia plana: quien
     lo pida no tiene por que poder tocar la tabla de aqui. ]]
exports('PuntosDescubiertos', function()
    local lista = {}
    for _, p in pairs(Puntos) do
        lista[#lista + 1] = { poi = p.poi, name = p.name, x = p.x, y = p.y, z = p.z }
    end
    return lista
end)
