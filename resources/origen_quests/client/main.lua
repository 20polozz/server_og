local Loaded = false

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    LoadQuests()
end)

-- Red de seguridad para el caso "origen_quests se reinicia con el jugador ya
-- en el mundo" (RegisterNetEvent de arriba no se vuelve a disparar entonces).
-- ANTES comprobaba QBCore.Functions.GetPlayerData().citizenid == nil -- pero
-- el servidor puebla el citizenid en cuanto se crea el personaje
-- (qbx_core/server/player.lua's Login->CreatePlayer->UpdatePlayerData), NO
-- cuando el jugador termina de spawnear. Para un personaje EXISTENTE esa
-- ventana es de ~1s; para uno NUEVO son los segundos/minutos que tarda en
-- rellenar el formulario y elegir base en el mapa de origen_creationv2 --
-- tiempo de sobra para que este hilo corra MIENTRAS el jugador SIGUE en el
-- bucket temporal de creacion (CREATION_BUCKET_OFFSET+source). El servidor
-- respondia entonces con una lista de localizaciones VACIA (filtrada por ese
-- bucket, que nunca tiene ninguna) -- vacia pero valida (`type({}) ==
-- 'table'`), asi que LoadQuests() la aceptaba como exito definitivo y fijaba
-- Loaded=true para siempre, sin reintento, sin NPCs de mision para el resto
-- de la sesion de un personaje NUEVO especificamente (los existentes casi
-- nunca caian en esta ventana de 1s). LocalPlayer.state.isLoggedIn lo pone
-- origen_creationv2 en el MISMO instante que dispara QBCore:Client:
-- OnPlayerLoaded (client/main.lua, playerSpawned()), o sea solo cuando el
-- bucket ya es definitivamente el real.
CreateThread(function()
    AddRelationshipGroup('QuestsNPCs')

    if not LocalPlayer.state.isLoggedIn then return end
    LoadQuests()
end)

-- El servidor devuelve `false` (en vez de la lista) mientras su catalogo
-- todavia esta cargando desde MySQL, o mientras este jugador concreto sigue
-- en el bucket temporal de creacion de personaje (ver server/events.lua,
-- que ahora espera con exports.origen_creationv2:WaitTempBucketResolved
-- antes de rendirse). Antes, `Loaded` se ponia a true ANTES de saber si la
-- respuesta traia algo de verdad, asi que un jugador cuyo OnPlayerLoaded
-- llegaba en esa ventana se quedaba con `Locations` vacio para siempre en
-- esa sesion -- cero NPCs de mision, cero forma de interactuar con quests,
-- sin ningun reintento. Ahora reintenta hasta 60 veces (1s entre intentos --
-- presupuesto ampliado de los 30 originales porque el servidor puede tardar
-- mas de 30s en resolver el bucket bajo carga real) y solo marca `Loaded`
-- cuando de verdad llega una tabla.
function LoadQuests()
    if Loaded then return end

    CreateThread(function()
        for _ = 1, 60 do
            local p = promise.new()
            QBCore.Functions.TriggerCallback("origen_quests:server:GetLocations", function(result)
                p:resolve(result)
            end)
            local locations = Citizen.Await(p)

            if type(locations) == 'table' then
                Loaded = true

                for i = 1, #locations do
                    locations[i].location = vector4(tonumber(locations[i].location.x), tonumber(locations[i].location.y), tonumber(locations[i].location.z), tonumber(locations[i].location.w))
                end

                Locations = locations

                for i = 1, #Locations do
                    Quests.Create(Locations[i])
                end

                -- Los sitios que salen en el mapa desde el principio. Van
                -- aqui y no en origen_mapa.lua porque el catalogo llega por
                -- este camino y no hay otro. Ver Config.MapModes.
                if PintarSitiosDeSiempre then
                    PintarSitiosDeSiempre(Locations)
                end
                return
            end

            Wait(1000)
        end
    end)
end

-- Red de seguridad final (ver server/class.lua): si el arranque del servidor
-- se hincha lo suficiente, los 60 intentos/~60s de arriba pueden agotarse
-- ANTES de que el catalogo este listo -- este evento llega justo cuando de
-- verdad lo esta, asi que basta con volver a intentar. LoadQuests() ya no
-- hace nada si `Loaded` sigue en true (exito por la via normal), y si sigue
-- en false, esta vez el servidor ya tiene datos que devolver.
-- Este evento se emite con TriggerClientEvent(..., -1) a TODOS los
-- conectados, incluidos los que siguen en el bucket temporal de creacion de
-- personaje (nuevo). Sin este gate, LoadQuests() correria ahi mismo, pediria
-- GetLocations con ese bucket temporal y aceptaria la lista vacia resultante
-- como exito definitivo -- el mismo bug que el hilo de seguridad de arriba
-- ya evita. QBCore:Client:OnPlayerLoaded se encarga de llamar a LoadQuests()
-- en cuanto el jugador termine de spawnear de verdad (catalogo ya cargado
-- para entonces), asi que aqui basta con descartar el evento.
RegisterNetEvent('origen_quests:client:catalogReady', function()
    if not LocalPlayer.state.isLoggedIn then return end
    LoadQuests()
end)

RegisterNetEvent("origen_quests:client:UpdateLocation", function(data)
    -- Una localizacion sin coordenadas (borrada o a medio crear) reventaba aqui
    -- con «attempt to index a nil value (field 'location')».  Se descarta.
    if type(data) ~= 'table' or type(data.location) ~= 'table' then return end
    data.location = vector4(tonumber(data.location.x), tonumber(data.location.y), tonumber(data.location.z), tonumber(data.location.w))
    Quests.Create(data)
end)

RegisterNetEvent("origen_quests:client:DeleteLocation", function(id)
    if Quests.Table[id] then
        Quests.Table[id]:Delete()
        Quests.Table[id] = nil
    end
end)