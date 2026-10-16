QBCore = exports['qb-core']:GetCoreObject()

Locations = {}
local camera
local active = false
local LocationAnimProps = {}

-- Forward declarations: permiten que los closures creados antes de la
-- definición real (CreateThread, RegisterNetEvent) capturen estas variables
-- como upvalues y las resuelvan en tiempo de ejecución.
local CreateLocationPoint
local DestroyLocationPoint

local function NormalizeLocationVector(location)
    if type(location) ~= "table" then
        return nil
    end

    local x = tonumber(location.x)
    local y = tonumber(location.y)
    local z = tonumber(location.z)
    local w = tonumber(location.w)
    if not x or not y or not z or not w then
        return nil
    end

    return vector4(x, y, z, w)
end

-- CreateThread(function()
--     AddRelationshipGroup('QuestsNPCs')
--     while not QBCore.Functions.GetPlayerData().citizenid do
--         Wait(1000)
--     end

--     QBCore.Functions.TriggerCallback("origen_quests:server:GetLocations", function(locations)
--         for i = 1, #locations do
--             locations[i].location = vector4(tonumber(locations[i].location.x), tonumber(locations[i].location.y),
--                 tonumber(locations[i].location.z), tonumber(locations[i].location.w))
--         end

--         Locations = locations

--         for i = 1, #Locations do
--             CreateLocationPoint(Locations[i])
--         end
--     end)
-- end)

RegisterNetEvent("origen_quests:client:CreateLocation", function(data)
    for i = 1, #Locations do
        if Locations[i].id == data.id then return end
    end

    local parsedLocation = NormalizeLocationVector(data.location)
    if not parsedLocation then
        return
    end
    data.location = parsedLocation

    table.insert(Locations, data)
    CreateLocationPoint(data)
end)

-- RegisterNetEvent("origen_quests:client:UpdateLocation", function(data)
--     for i = 1, #Locations do
--         if Locations[i].id == data.id then
--             data.location = vector4(tonumber(data.location.x), tonumber(data.location.y), tonumber(data.location.z),
--                 tonumber(data.location.w))

--             DestroyLocationPoint(Locations[i])
--             Locations[i] = data
--             CreateLocationPoint(Locations[i])

--             break
--         end
--     end
-- end)

-- RegisterNetEvent("origen_quests:client:DeleteLocation", function(id)
--     for i = 1, #Locations do
--         if Locations[i].id == id then
--             DestroyLocationPoint(Locations[i])
--             table.remove(Locations, i)
--             break
--         end
--     end
-- end)

-- RegisterNetEvent("origen_quests:client:ToggleLocation", function(id, active, extra)
--     for i = 1, #Locations do
--         if Locations[i].id == id then
--             Locations[i].active = active
--             Locations[i].extra = extra

--             if active == 0 then
--                 DestroyLocationPoint(Locations[i])
--             else
--                 CreateLocationPoint(Locations[i])
--             end

--             break
--         end
--     end
-- end)

-- Funciones para manejar las interacciones con Sleepless Interact
function AddInteractionToLocation(location)
    --[[ local interactionId = "quest_location_" .. location.id

    if location.type == "new_npc" or location.type == "new_prop" then
        if not location.entity or not DoesEntityExist(location.entity) then
            return
        end
        interact.addLocalEntity({
            entity = location.entity,
            id = interactionId,
            renderDistance = location.distance or 3.0,
            activeDistance = location.distance or 3.0,
            options = {
                {
                    label = location.name or "Interactuar",
                    action = function()
                        OpenMissionsMenu(location.missions, location.id, location.name, location.dialog, location.audio)
                    end
                }
            }
        })
    elseif location.type == "marker" then
        interact.addCoords({
            coords = location.location.xyz,
            id = interactionId,
            renderDistance  = location.distance or 3.0,
            activeDistance  = location.distance or 3.0,
            options = {
                {
                    label = location.name or "Interactuar",
                    action = function()
                        OpenMissionsMenu(location.missions, location.id, location.name, location.dialog, location.audio)
                    end
                }
            }
        })
    elseif location.type == "model" and location.model then
        -- Para modelos específicos, usamos addModelInteraction
        interact.addLocalEntity({
            model = location.model,
            id = interactionId,
            renderDistance = location.distance or 3.0,
            activeDistance = location.distance or 3.0,
            options = {
                {
                    label = location.name or "Interactuar",
                    action = function()
                        OpenMissionsMenu(location.missions, location.id, location.name, location.dialog, location.audio)
                    end
                }
            }
        })
    end ]]
end

function RemoveInteractionFromLocation(location)
    --[[ local interactionId = "quest_location_" .. location.id
    
    interact.removeById(interactionId) ]]
end

local function GetLocationInteractionDistance(location)
    local distance = tonumber(location and location.distance) or 1.5
    if distance < 0.5 then distance = 0.5 end
    return distance
end

local function ParseHexColor(hex)
    if type(hex) ~= "string" then return nil end
    local clean = hex:gsub("#", "")
    if #clean ~= 6 then return nil end

    local r = tonumber(clean:sub(1, 2), 16)
    local g = tonumber(clean:sub(3, 4), 16)
    local b = tonumber(clean:sub(5, 6), 16)
    if not r or not g or not b then return nil end

    return { r = r, g = g, b = b, a = 255 }
end

function GetLocationIconVisual(location, isHint)
    local defaults = isHint and {
        icon = 9,
        size = 0.20,
        color = { r = 255, g = 255, b = 255, a = 255 }
    } or {
        icon = 20,
        size = 0.30,
        color = { r = 0, g = 0, b = 0, a = 255 }
    }

    local extra = {}
    if location and location.type == "marker" then
        extra = location.extra or {}
    end
    local icon = tonumber(extra.icon) or defaults.icon
    local size = tonumber(extra.iconSize) or defaults.size
    local color = ParseHexColor(extra.iconColor) or defaults.color

    if size < 0.05 then size = 0.05 end

    return icon, size, color
end

-- ============================================================
-- SISTEMA REACTIVO CON OX_LIB POINTS
-- Reemplaza los 5 threads permanentes de polling:
--   · FindClosestLocation (1000ms)
--   · Spawn/Despawn por proximidad (2000ms)
--   · Dibujo de markers (Wait(0))
--   · Interacción tipo marker/npc/prop (Wait(5))
--   · Interacción tipo model (Wait(5))
--
-- Con points, solo se activan callbacks para locations dentro
-- del radio definido. CPU: ~80% menos por jugador.
-- ============================================================

local MARKER_DRAW_DIST = 20.0

-- Limpia la entidad y el point de un location de forma segura
DestroyLocationPoint = function(location)
    -- Invalidar cualquier spawn en progreso
    location.spawning = false
    location.spawnGen = (location.spawnGen or 0) + 1
    if location.point then
        location.point:remove()
        location.point = nil
    end
    if location.entity then
        local ped = location.entity
        if LocationAnimProps[ped] then
            for _, prop in ipairs(LocationAnimProps[ped]) do
                if DoesEntityExist(prop) then DeleteEntity(prop) end
            end
            LocationAnimProps[ped] = nil
        end
        if DoesEntityExist(ped) then DeleteEntity(ped) end
        location.entity = nil
    end
end

-- Crea el point ox_lib para un location activo.
-- onEnter: spawnea NPC/Prop.
-- onExit:  borra NPC/Prop y limpia texto.
-- nearby:  dibuja marker y gestiona interacción con E.
-- Lanza el spawn de un NPC o Prop en su propio thread para NO bloquear
-- el hilo de ox_lib. Usa generación + flag para evitar:
--   · doble-spawn (onEnter + chequeo inicial solapados)
--   · entidad "fantasma" si el jugador sale del radio mientras carga el modelo
local function spawnLocationEntity(location)
    if location.spawning or location.entity then return end
    location.spawning = true
    location.spawnGen = (location.spawnGen or 0) + 1
    local gen = location.spawnGen
    CreateThread(function()
        local entity
        if location.type == 'new_npc' then
            entity = CreateLocationNPC(location)
        elseif location.type == 'new_prop' then
            entity = CreateLocationProp(location)
        end
        location.spawning = false
        -- Sólo guardar la entidad si esta generación sigue siendo válida
        -- (si onExit disparó mientras cargaba, spawnGen habrá incrementado)
        if gen == location.spawnGen and entity and entity ~= false then
            location.entity = entity
        elseif entity and entity ~= false and DoesEntityExist(entity) then
            -- Generación obsoleta: jugador salió durante la carga → limpiar
            DeleteEntity(entity)
        end
    end)
end

CreateLocationPoint = function(location)
    DestroyLocationPoint(location)
    if location.active ~= 1 then return end

    local interactionDist = GetLocationInteractionDistance(location)
    local pointDist = math.max(Config.NPCSpawnRadius, MARKER_DRAW_DIST)
    local isTextShowing = false

    location.point = lib.points.new({
        coords = location.location.xyz,
        distance = pointDist,
    })

    -- onEnter: dispara el spawn en un thread separado para no bloquear ox_lib.
    -- Antes del fix, llamar CreateLocationNPC (que tiene Wait) desde aquí
    -- congelaba el sistema de puntos entero mientras cargaba el modelo,
    -- causando que otras ubicaciones no aparecieran para algunos jugadores.
    function location.point:onEnter()
        if location.type == 'new_npc' or location.type == 'new_prop' then
            spawnLocationEntity(location)
        end
    end

    function location.point:onExit()
        -- Invalidar spawn en progreso: si el thread termina después de onExit
        -- verá que gen != spawnGen y eliminará la entidad en vez de guardarla
        location.spawning = false
        location.spawnGen = (location.spawnGen or 0) + 1
        if location.entity then
            local ped = location.entity
            if LocationAnimProps[ped] then
                for _, prop in ipairs(LocationAnimProps[ped]) do
                    if DoesEntityExist(prop) then DeleteEntity(prop) end
                end
                LocationAnimProps[ped] = nil
            end
            if DoesEntityExist(ped) then DeleteEntity(ped) end
            location.entity = nil
        end
        if isTextShowing then
            isTextShowing = false
            exports.origen_notify:HideText()
        end
    end

    function location.point:nearby()
        local dist = self.currentDistance

        -- === MARKER / HINT (dentro de 20m) ===
        if dist < MARKER_DRAW_DIST then
            if location.type == 'marker' then
                local icon, size, color = GetLocationIconVisual(location, false)
                DrawMarker(icon, location.location.xyz, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, size, size, size, color.r, color.g, color.b, color.a, false, false, 0, true)
            elseif (location.type == 'new_npc' or location.type == 'new_prop')
                and location.entity and location.extra and location.extra.hint then
                local icon, size, color = GetLocationIconVisual(location, true)
                if icon == 9 then
                    DrawMarker(icon, location.location.xyz + vector3(0.0, 0.0, 1.0), 0.0, 0.0, 0.0,
                        90.0, 0.0, 0.0, size, size, size, color.r, color.g, color.b, color.a,
                        true, true, 2, false, "quest", "quest", false)
                else
                    DrawMarker(icon, location.location.xyz + vector3(0.0, 0.0, 1.0), 0.0, 0.0, 0.0,
                        90.0, 0.0, 0.0, size, size, size, color.r, color.g, color.b, color.a,
                        true, true, 2, false)
                end
            end
        end

        -- === INTERACCIÓN (solo si está configurada) ===
        if not (location.extra and location.extra.interaction) then return end

        if location.type == 'model' and location.model then
            -- Tipo modelo: buscar entidad del modelo solo cuando estamos muy cerca
            if dist < interactionDist then
                local pcoords = GetEntityCoords(PlayerPedId())
                local targetEntity = GetClosestObjectOfType(pcoords, interactionDist,
                    GetHashKey(location.model), false, false, false)

                if targetEntity == 0 then
                    local ped, pedDist = QBCore.Functions.GetClosestPed(pcoords, false, true)
                    if ped ~= 0 and DoesEntityExist(ped) and pedDist < interactionDist
                        and GetEntityModel(ped) == GetHashKey(location.model) then
                        targetEntity = ped
                    end
                end

                if targetEntity ~= 0 and DoesEntityExist(targetEntity) then
                    if not isTextShowing then
                        isTextShowing = true
                        exports.origen_notify:DrawText('E', 'Interactuar')
                    end
                    if isQuestInteractPressed() then
                        IntentarAbrirSitio(location)
                    end
                    return
                end
            end

            if isTextShowing then
                isTextShowing = false
                exports.origen_notify:HideText()
            end
        else
            -- Tipos marker, new_npc, new_prop
            if dist < interactionDist then
                if not isTextShowing then
                    isTextShowing = true
                    exports.origen_notify:DrawText('E', 'Interactuar')
                end
                if isQuestInteractPressed() then
                    IntentarAbrirSitio(location)
                end
            elseif isTextShowing then
                isTextShowing = false
                exports.origen_notify:HideText()
            end
        end
    end

    -- Chequeo inicial: si el jugador ya está dentro del radio en el momento
    -- de crear el punto, disparar el spawn de inmediato (usando el mismo
    -- helper no-bloqueante para evitar race condition con onEnter).
    -- Guard: cache.coords puede ser nil/cero durante la pantalla de carga.
    if (location.type == 'new_npc' or location.type == 'new_prop') then
        local coords = cache.coords
        if coords and (math.abs(coords.x) > 1.0 or math.abs(coords.y) > 1.0) then
            if #(coords - location.location.xyz) < pointDist then
                spawnLocationEntity(location)
            end
        end
    end
end

local function GetCurrenLocation(id)
    local idNum = tonumber(id)
    local idStr = tostring(id)
    for i = 1, #Locations do
        local location = Locations[i]
        if location.id == id then
            return location
        end

        local locationIdNum = tonumber(location.id)
        if idNum and locationIdNum and idNum == locationIdNum then
            return location
        end

        if tostring(location.id) == idStr then
            return Locations[i]
        end
    end
end

--[[ Cuanto lleva encima el jugador de cada cosa.

     La ficha del encargo decia lo que hay que poner pero no si lo tienes, que
     es LA pregunta delante del NPC: o vuelves con ello o no vuelves. Se lee
     del inventario del cliente —el mismo sitio de donde lo lee origen_phone
     para saber si llevas el movil— y es SOLO PARA LA PANTALLA: quien decide
     si el trueque vale es el servidor, que revisa el inventario de verdad.

     Devuelve una tabla nombre -> cuantos. Si el inventario no contesta,
     devuelve nil y la pantalla no pinta ningun recuento en vez de pintar un
     cero que seria mentira. ]]
local function ContarLoQueLlevas()
    if GetResourceState('origen_inventory') ~= 'started' then return nil end

    local ok, items = pcall(function()
        return exports.origen_inventory:getInventory()
    end)
    if not ok or type(items) ~= 'table' then return nil end

    local cuenta = {}
    for _, item in pairs(items) do
        if type(item) == 'table' and item.name then
            cuenta[item.name] = (cuenta[item.name] or 0) + (tonumber(item.amount) or tonumber(item.count) or 1)
        end
    end
    return cuenta
end

--[[ ── Sitios cerrados a una faccion ─────────────────────────────────────

     Hay puntos que solo son para quien lleva placa, para quien esta en una
     banda, para quien trabaja en un negocio o para quien va en un crew. Y no
     basta con esconderles los encargos: el que no es de la faccion no tiene
     que poder ni hablar con el NPC, ni enterarse de que ese sitio existe.

     Por eso la puerta esta AQUI y no dentro del menu. OpenMissionsMenu, nada
     mas entrar, apunta el sitio como descubierto —a proposito: has estado ahi
     y has hablado con quien fuera—. Si dejaramos pasar al que no toca, se le
     quedaria el punto marcado en el mapa para siempre aunque no pudiera hacer
     nada en el. El que no es de la faccion se lleva una mala contestacion y
     ya esta: para el, ahi no hay nada.

     `extra.faccion` tiene la misma forma que el `rest` de un encargo, asi que
     se resuelve con la misma funcion y no hay dos maneras distintas de decir
     lo mismo.

     Lo decide el SERVIDOR (PuedoAbrirSitio en server/events.lua, con
     OGNPasaLaPuerta de server/origen_bridge.lua): es el que sabe de verdad en
     que banda, negocio o crew estas. Antes se decidia aqui con las facciones
     que mandaba GetPlayerFactions, y ese callback se pedia otra vez, con el
     mismo nombre, desde dentro de su propia respuesta (la puerta y luego el
     menu). El puente qb de qbx_core apunta la respuesta por NOMBRE y la borra
     despues de llamarla, asi que la segunda se quedaba sin nadie que la
     escuchara: pasabas la puerta y el menu no se abria nunca. ]]
local RECHAZO_POR_DEFECTO = 'No tengo nada para ti. Vete de aqui.'

function IntentarAbrirSitio(location)
    local puerta = location.extra and location.extra.faccion

    if type(puerta) ~= 'table' or #puerta == 0 then
        OpenMissionsMenu(location.missions, location.id, location.name,
            location.dialog, location.audio)
        return
    end

    QBCore.Functions.TriggerCallback("origen_quests:server:PuedoAbrirSitio", function(puede, rechazo)
        if puede then
            OpenMissionsMenu(location.missions, location.id, location.name,
                location.dialog, location.audio)
            return
        end

        exports.origen_notify:Notify({
            title = location.name or 'No es tu sitio',
            description = rechazo or (location.extra and location.extra.rechazo) or RECHAZO_POR_DEFECTO,
            type = 'error',
            duration = 4000,
        })
    end, location.id)
end

--[[ Los botones COMUNES del riel del encargo: los mismos que llevan todos
     los paneles (inventario, banda, negocio, mascotas...). La lista NO se
     escribe aqui: la da origen_inventory, que es quien sabe que accesos le
     tocan a este jugador. Sin el inventario en marcha, riel vacio. ]]
local function RielComun()
    if GetResourceState('origen_inventory') ~= 'started' then return {} end
    local ok, riel = pcall(function()
        return exports.origen_inventory:GetRiel('misiones')
    end)
    return (ok and type(riel) == 'table') and riel or {}
end

function OpenMissionsMenu(missions, location_id, name, dialog, audio)
    -- Deja el sitio marcado para siempre en el mapa personal del jugador (item
    -- "mapa" de origen_zombies). Va ANTES de resolver misiones a propósito: has
    -- estado aquí y has hablado con quien fuera; que luego no tengas acceso a
    -- ninguna misión no borra el hecho. El servidor valida que estés de verdad
    -- delante del sitio y es idempotente, así que reinteractuar no duplica nada
    -- ni vuelve a notificar (ver server/map_marks.lua).
    TriggerServerEvent('origen_quests:server:MarkLocationOnMap', location_id)

    -- El servidor ya devuelve solo los encargos de tu faccion (GetMissionsByIds).
    QBCore.Functions.TriggerCallback("origen_quests:server:GetMissionsByIds", function(result, nombresCadena)
        result = result or {}
        nombresCadena = nombresCadena or {}
        local missions_to_send = {}
        -- Una sola lectura del inventario para todas las misiones del sitio.
        local llevas = ContarLoQueLlevas()
        local location = GetCurrenLocation(location_id)
        local isAutoLocation = tonumber(location and location.auto) == 1
        local resolvedLocationId = (location and location.id) or location_id

        for _, mission in ipairs(result) do
            do
                if isAutoLocation and (next(result) and #result == 1) then
                    AcceptMission({
                        id = mission.id,
                        location_id = resolvedLocationId
                    })
                    return
                end

                for _, event in ipairs(mission.events or {}) do
                    if event.type == "ItemTrade" or event.type == "EventAndTrade" then
                        local function processEventItems(items, isGive)
                            for k, v in pairs(items) do
                                local iteminfo = exports.origen_inventory:GetItems(k)

                                --[[ Lo que DA la mision llega de dos formas y hay
                                     que aceptar las dos. El panel de admin lo guarda
                                     como {min, max}; el contenido de rol
                                     (sql/origen-rp/generador) lo escribe como un
                                     numero suelto: `da = { image_printed = 2 }`. El
                                     servidor ya paga las dos (AddItems, en
                                     server/events.lua); aqui se daba por hecha la
                                     tabla, y con un numero `v.min` reventaba, el
                                     callback se cortaba y el dialogo del NPC no
                                     llegaba a abrirse. ]]
                                local amount = v
                                if isGive then
                                    if type(v) == 'table' then
                                        local minV, maxV = tonumber(v.min) or 1, tonumber(v.max) or 1
                                        amount = minV == maxV and ('x' .. minV) or '?'
                                    else
                                        amount = 'x' .. (tonumber(v) or 1)
                                    end
                                end

                                --- Un objeto que el inventario no conoce (renombrado,
                                --- borrado) no puede tumbar el dialogo entero: se
                                --- enseña con su nombre interno, como ya hacen las
                                --- recompensas V2 de mas abajo.
                                local nombre = (iteminfo and iteminfo.name) or k

                                items[k] = {
                                    name = nombre,
                                    label = (iteminfo and iteminfo.label) or k,
                                    image = iteminfo and iteminfo.image or nil,
                                    description = iteminfo and iteminfo.description or nil,
                                    amount = amount,
                                    -- Solo en lo que TE PIDEN: cuanto llevas de eso
                                    -- encima ahora mismo. nil si no hay inventario.
                                    tienes = (not isGive) and llevas and (llevas[nombre] or 0) or nil,
                                }
                            end
                        end

                        processEventItems(event.requested or {})
                        processEventItems(event.give or {}, true)
                    elseif event.type == "rewards2" and event.items then
                        -- Recompensas V2: mismo enriquecido que los trueques, si no
                        -- la NUI solo tiene el nombre interno (sin label ni la
                        -- imagen override de origen_item_images).
                        for k, v in pairs(event.items) do
                            local iteminfo = exports.origen_inventory:GetItems(k)
                            local amount
                            if type(v) == 'table' then
                                local minV, maxV = tonumber(v.min) or 1, tonumber(v.max) or 1
                                amount = minV == maxV and ('x' .. minV) or (minV .. '-' .. maxV)
                            else
                                amount = 'x' .. tostring(v)
                            end
                            event.items[k] = {
                                name = (iteminfo and iteminfo.name) or k,
                                label = (iteminfo and iteminfo.label) or k,
                                image = iteminfo and iteminfo.image or nil,
                                amount = amount,
                            }
                        end
                    end
                end

                table.insert(missions_to_send, mission)
            end
        end

        -- Donde estas ahora mismo, que es donde hay que volver a cerrar el
        -- trato. Se coge del jugador y no del sitio a proposito: estas
        -- hablando con quien encarga, asi que sus pies SON el sitio, y asi
        -- vale igual para los NPC que andan y para los marcadores fijos.
        --[[ Sin nada que ofrecer, no se abre nada.

             Un panel negro con solo el nombre del NPC queda fatal y no dice
             por que. Pasa cuando todo lo de ese sitio esta hecho por hoy,
             cuando lo que queda pide terminar antes otra cosa, o cuando los
             encargos son de un grupo al que no perteneces. En los tres casos
             se dice con una frase, y el jugador sigue a lo suyo. ]]
        if #missions_to_send == 0 then
            exports.origen_notify:Notify({
                title = name or 'Nada por ahora',
                description = 'Ahora mismo no tengo nada para ti. Vuelve mas tarde.',
                type = 'info',
                duration = 4000,
            })
            return
        end

        local px, py, pz = table.unpack(GetEntityCoords(PlayerPedId()))

        SendNUIMessage({
            action = "open",
            missions = missions_to_send,
            chain_names = nombresCadena,
            location_coords = { x = px, y = py, z = pz },
            location_id = location_id,
            location_name = name,
            location_dialog = dialog,
            location_audio = audio,
            location_type = location and location.type or "marker",
            riel = RielComun(),
        })

        if location and location.entity then
            StartCam(location.entity, location.type)
        end

        if location and location.anim4 then
            ApplyPedAnim(PlayerPedId(), location.anim4)
        end

        SetNuiFocus(true, true)

        active = true
    end, missions)
end

function CreateLocationNPC(info)
    if IsModelInCdimage(info.model) then
        RequestModel(info.model)

        while not HasModelLoaded(info.model) do
            Wait(10)
        end

        local npc = CreatePed(4, info.model, info.location.x, info.location.y, info.location.z - 1, info.location.w,
            false, true)
        SetEntityHeading(npc, info.location.w)

        --[[ Sentarlo en el suelo de verdad, antes de congelarlo.

             El `- 1` de arriba es una correccion a bulto: da por hecho que la
             altura guardada esta siempre un metro por encima del suelo. Cuando
             no lo esta —y en muchas filas no lo esta— el NPC queda flotando o
             medio enterrado, y como se congela acto seguido, la gravedad no lo
             arregla nunca. Se veia a simple vista.

             Aqui se pregunta donde esta el suelo de verdad y se le pone ahi. El
             NPC se crea solo cuando el jugador esta a menos de 80 m
             (Config.NPCSpawnRadius), asi que el terreno ya esta cargado y la
             pregunta tiene respuesta.

             El margen de tres metros no es por si acaso: hay NPCs puestos a
             proposito en un piso alto o en una pasarela, y ahi el suelo que se
             encuentra es la calle de abajo. Si lo que sale queda demasiado
             lejos de donde se le puso, se respeta lo que dice la ficha. ]]
        local hay, suelo = GetGroundZFor_3dCoord(
            info.location.x + 0.0, info.location.y + 0.0, info.location.z + 3.0, false)
        if hay and math.abs(suelo - info.location.z) <= 3.0 then
            SetEntityCoordsNoOffset(npc, info.location.x + 0.0, info.location.y + 0.0, suelo + 0.0, false, false, false)
        end

        FreezeEntityPosition(npc, true)
        SetEntityInvincible(npc, true)
        SetBlockingOfNonTemporaryEvents(npc, true)
        SetPedConfigFlag(npc, 79, true)

        SetPedRelationshipGroupHash(npc, GetHashKey("QuestsNPCs"))

        if info.anim1 and info.anim1 ~= "" then
            ApplyPedAnim(npc, info.anim1)
        end

        if info.extra and info.extra.skin then
            SetNPCSkin(npc, info.extra.skin)
        end

        if info.extra and info.extra.weapon then
            GiveNPCVisualWeapon(npc, info.extra.weapon)
        end

        return npc
    else
        -- print("^1Model not found: " .. info.model .. " for location: " .. info.name .. " (" .. info.id .. ")^7")
    end

    return false
end

-- Cache de animaciones: evita leer y parsear anims.json en cada llamada.
-- Con 20 NPCs de quest se cargaba 20 veces en el mismo tick de inicialización.
local _animsCache = nil
local function getAnims()
    if not _animsCache then
        _animsCache = json.decode(LoadResourceFile("origen_anims", "anims.json")) or {}
    end
    return _animsCache
end

function ApplyPedAnim(npc, selected_anim, get)
    local anims = getAnims()

    local function clearPedProps(ped)
        local list = LocationAnimProps[ped]
        if not list then return end
        for _, prop in ipairs(list) do
            if DoesEntityExist(prop) then
                DeleteEntity(prop)
            end
        end
        LocationAnimProps[ped] = nil
    end

    local function attachPropToPed(ped, propName, bone, placement)
        if not propName or propName == "" then return end
        local hash = type(propName) == "number" and propName or GetHashKey(propName)
        if not IsModelInCdimage(hash) then return end

        RequestModel(hash)
        local timeout = 0
        while not HasModelLoaded(hash) and timeout < 100 do
            Wait(10)
            timeout = timeout + 1
        end
        if not HasModelLoaded(hash) then return end

        local pedCoords = GetEntityCoords(ped)
        local object = CreateObject(hash, pedCoords.x, pedCoords.y, pedCoords.z + 0.2, false, false, false)
        if object and object ~= 0 then
            local boneIndex = GetPedBoneIndex(ped, tonumber(bone) or 57005)
            local p = placement or {}
            local x = tonumber(p[1]) or 0.0
            local y = tonumber(p[2]) or 0.0
            local z = tonumber(p[3]) or 0.0
            local rx = tonumber(p[4]) or 0.0
            local ry = tonumber(p[5]) or 0.0
            local rz = tonumber(p[6]) or 0.0

            SetEntityAsMissionEntity(object, true, true)
            SetEntityCollision(object, false, false)
            AttachEntityToEntity(object, ped, boneIndex, x, y, z, rx, ry, rz, true, true, false, true, 1, true)

            if not LocationAnimProps[ped] then
                LocationAnimProps[ped] = {}
            end
            table.insert(LocationAnimProps[ped], object)
        end

        SetModelAsNoLongerNeeded(hash)
    end

    local function applyAnimationProps(ped, props)
        if not props then return end
        if type(props) == "table" and props.prop then
            attachPropToPed(ped, props.prop, props.propBone, props.propPlacement)
            if props.propTwo then
                attachPropToPed(ped, props.propTwo, props.propTwoBone, props.propTwoPlacement)
            end
            return
        end

        if type(props) == "table" then
            for _, propData in pairs(props) do
                if type(propData) == "table" then
                    local propName = propData.prop or propData.Name
                    local propBone = propData.propBone or propData.Bone
                    local propPlacement = propData.propPlacement or propData.Placement
                    if type(propPlacement) == "table" and propPlacement[1] and propPlacement[1].x then
                        propPlacement = {
                            propPlacement[1].x, propPlacement[1].y, propPlacement[1].z,
                            propPlacement[2].x, propPlacement[2].y, propPlacement[2].z
                        }
                    end
                    attachPropToPed(ped, propName, propBone, propPlacement)
                end
            end
        end
    end

    for i = 1, #anims, 1 do
        if anims[i].subtitle:gsub("/", "") == selected_anim:gsub("/", "") then
            local anim = (anims[i].scenarios and anims[i].scenarios.scene) or (anims[i].dances) or false

            if not get then
                clearPedProps(npc)
                if type(anim) == "string" then
                    TaskStartScenarioInPlace(npc, anim, 0, true)
                elseif type(anim) == "table" then
                    RequestAnimDict(anim.dict)

                    while not HasAnimDictLoaded(anim.dict) do
                        Wait(1)
                    end

                    TaskPlayAnim(npc, anim.dict, anim.anim, 8.0, 0.0, -1, 1, 0, 0, 0, 0)
                end

                applyAnimationProps(npc, anims[i].props)
            else
                return anim
            end

            return
        end
    end
end

RegisterNetEvent("origen_quests:client:DoMissionAnimation", function(sender, location_id)
    for i = 1, #Locations do
        if Locations[i].id == location_id then

            if Locations[i].entity and #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(Locations[i].entity)) < 150 then
                ClearPedTasksImmediately(Locations[i].entity)

                ApplyPedAnim(Locations[i].entity, Locations[i].anim2)

                Wait(5000)

                ClearPedTasksImmediately(Locations[i].entity)
                TriggerEvent('anim:cancel')

                ApplyPedAnim(Locations[i].entity, Locations[i].anim1)
            end

            break
        end
    end
end)

function CreateLocationProp(info)
    if IsModelInCdimage(info.model) then
        RequestModel(info.model)

        while not HasModelLoaded(info.model) do
            Wait(10)
        end

        local prop

        if GetMakeNameFromVehicleModel(GetHashKey(info.model)) ~= "CARNOTFOUND" then
            prop = QBCore.Functions.SpawnVehicle(GetHashKey(info.model), false, vector4(info.location.x,
                info.location.y, info.location.z - 1, info.location.w))
            SetVehicleUndriveable(prop, true)
            SetVehicleDoorsLocked(prop, 2)
            SetVehicleCustomPrimaryColour(prop, 255, 255, 255)
        else
            prop = CreateObject(GetHashKey(info.model), info.location.x, info.location.y, info.location.z - 1, false,
                false, false)
        end

        SetEntityHeading(prop, info.location.w)

        --[[ Pegarlo al suelo, si la localizacion lo pide (`extra.alSuelo`).

             El objeto se planta en la z que venga y se congela ahi. Si esa z
             no es exacta, el prop flota o se hunde, y desde el panel no hay
             forma de saberlo sin entrar al juego a mirarlo uno a uno.

             Con esto la z solo tiene que ser aproximada: el juego lo baja
             hasta apoyarlo. Va detras del rumbo porque el sitio depende de
             como este girado, y antes de congelarlo porque un objeto congelado
             ya no se mueve.

             Es opcional a proposito: un prop encima de una mesa o en una
             estanteria NO quiere esto, y las que ya existen no cambian. ]]
        if info.extra and info.extra.alSuelo then
            PlaceObjectOnGroundProperly(prop)
        end

        FreezeEntityPosition(prop, true)
        SetEntityInvincible(prop, true)

        return prop
    else
        -- print("^1Model not found: " .. info.model .. " for location: " .. info.name .. " (" .. info.id .. ")^7")
    end

    return false
end

-- Quien es de que faccion ya no se mira aqui: lo decide el servidor
-- (OGNPasaLaPuerta, server/origen_bridge.lua) en la puerta del sitio y en la
-- lista de encargos. Ver IntentarAbrirSitio.

function ToggleQuest(state)
    SendNUIMessage({
        action = "toggle",
        state = state
    })
    SetNuiFocus(state, state)
    active = state
end

--- Si el encargo del NPC esta abierto ahora. Lo mira helper_events.lua para
--- no reabrirlo tras un minijuego si ya no estaba delante.
function QuestAbierta()
    return active
end

local function isQuestInteractPressed()
    return IsControlJustPressed(0, 38)
        or IsDisabledControlJustPressed(0, 38)
        or IsControlJustPressed(0, 51)
        or IsDisabledControlJustPressed(0, 51)
end

function AcceptMission(data)
    local progressbar = false
    local anim = nil

    QBCore.Functions.TriggerCallback('origen_quests:server:CanAcceptMission', function(canAccept, mission)
        if not canAccept then
            return
        end

        if mission and mission.Data and mission.Data.events then
            for i = 1, #mission.Data.events, 1 do
                local event = mission.Data.events[i]
                if event.type == 'EventAndTrade' and event.trigger == 'org_progressbar' and tonumber(event.progressbar) and
                    tonumber(event.progressbar) > 0 then
                    progressbar = tonumber(event.progressbar)
                    break
                end
            end
        end

        local location = GetCurrenLocation(data.location_id)

        if location and location.anim3 then
            anim = ApplyPedAnim(PlayerPedId(), location.anim3, true)
        end

        if active then
            ToggleQuest(false)
            -- El panel se cierra aqui sin pasar por el callback "close", que
            -- era el unico que quitaba la camara: con un NPC `new_npc` el
            -- jugador se quedaba mirandole desde la camara scriptada.
            EndCam()
        end

        TriggerServerEvent('origen_quests:server:SendDispatchAlert', data.id, data.location_id)

        if progressbar then

            local animation = {}

            if anim then
                if type(anim) == 'string' then
                    animation = {
                        task = anim
                    }
                else
                    animation = {
                        animDict = anim.dict,
                        anim = anim.anim,
                        flags = 1
                    }
                end
            end

            Wait(100)

            QBCore.Functions.Progressbar('accept_mission', 'Realizando misión', progressbar * 1000, false, false, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true
            }, animation, {}, {}, function()
                ClearPedTasksImmediately(PlayerPedId())
                TriggerServerEvent("origen_quests:server:AcceptMission", data.id, data.location_id)
            end)
        else
            TriggerServerEvent("origen_quests:server:AcceptMission", data.id, data.location_id)
        end
    end, data.id, data.location_id)
end

-- Los dos contestan siempre: sin cb la peticion de la NUI se queda colgada.
RegisterNUICallback("accept", function(data, cb)
    cb('ok')
    AcceptMission(data)
end)

RegisterNUICallback("close", function(_, cb)
    cb('ok')
    SetNuiFocus(false, false)
    EndCam()
    TriggerEvent('anim:cancel')
    ClearPedTasksImmediately(PlayerPedId())
    active = false
end)

--[[ Saltar a otro panel desde el riel del encargo. Primero se cierra igual
     que con "close" (foco, camara del NPC, animacion) y a los 200 ms se abre
     el destino, como hacen los demas paneles del riel: las pestañas del
     inventario por AbrirEnPestana, los accesos (admin, banda, negocio...)
     por AbrirAcceso. Sin relevo: el encargo no comparte la barra con nadie
     al cerrarse, asi que el que entra se desliza normal. ]]
RegisterNUICallback("riel", function(data, cb)
    cb('ok')
    local destino = data and data.id
    if type(destino) ~= 'string' or destino == '' then return end

    SetNuiFocus(false, false)
    EndCam()
    TriggerEvent('anim:cancel')
    ClearPedTasksImmediately(PlayerPedId())
    active = false

    if GetResourceState('origen_inventory') ~= 'started' then return end
    local acceso = data.tipo == 'acceso'
    SetTimeout(200, function()
        pcall(function()
            if acceso then
                exports.origen_inventory:AbrirAcceso(destino, false)
            else
                exports.origen_inventory:AbrirEnPestana(destino, false)
            end
        end)
    end)
end)

--[[ Si el vigilante suelta el raton a la fuerza, el encargo y el panel de
     administracion se cierran de verdad: sin esto `active` seguia en true, la
     camara del NPC puesta y el dialogo pintado sin raton. Lo mismo que hace
     el callback "close", sin coger el foco. ]]
OrigenFoco.AlSoltar(function()
    local estabaAbierto = active
    active = false
    SendNUIMessage({ action = "toggle", state = false })
    SendNUIMessage({ menu = 'quests', action = 'close' })
    EndCam()
    if estabaAbierto then
        TriggerEvent('anim:cancel')
        ClearPedTasksImmediately(PlayerPedId())
    end
end)

RegisterNUICallback("ChangeClothes", function(data, cb)
    local entity = 0

    for i = 1, #Locations do
        if Locations[i].id == data.location_id then
            entity = Locations[i].entity
            break
        end
    end

    if entity and DoesEntityExist(entity) and #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(entity)) < 100 then
        cb(true)

        QBCore.Functions.TriggerCallback("origen_quests:GetNPCSkin", function(result)
            exports.origen_clothing:SetAppearance(entity, result)
            local heading = GetEntityHeading(entity)

            local clothing = exports['origen_clothing']:startPedCreation(true, 0, entity, true)

            if clothing then 
                SetEntityHeading(entity, heading)

                if clothing then
                    local safeSkin = {}
                    for key, value in pairs(clothing) do
                        if key ~= "model" and key ~= "modelHash" then
                            safeSkin[key] = value
                        end
                    end

                    TriggerServerEvent("origen_quests:UpdateNPCSkin", data.location_id, safeSkin)
                end
            end
        end, data.location_id)
    else
        cb(false)
    end
end)

function SetNPCSkin(ped, data)
    if data and type(data) == "table" then
        local safeSkin = {}
        for key, value in pairs(data) do
            if key ~= "model" and key ~= "modelHash" then
                safeSkin[key] = value
            end
        end

        exports.origen_clothing:SetAppearance(ped, safeSkin)
    end
end

-- Alias para no tener que escribir el nombre técnico del arma en el panel
local npcWeaponAliases = {
    bate = 'WEAPON_BAT',
    bat = 'WEAPON_BAT',
    knife = 'WEAPON_KNIFE',
    cuchillo = 'WEAPON_KNIFE',
    machete = 'WEAPON_MACHETE',
    hacha = 'WEAPON_HATCHET',
    pistol = 'WEAPON_PISTOL',
    pistola = 'WEAPON_PISTOL',
    escopeta = 'WEAPON_PUMPSHOTGUN',
    combatpistol = 'WEAPON_COMBATPISTOL'
}

-- Arma puramente decorativa: los NPCs de ubicación están congelados,
-- son invencibles y tienen bloqueados los eventos no temporales, así que
-- nunca la usan. Sólo sirve para que se vean más amenazantes.
function GiveNPCVisualWeapon(ped, weaponName)
    if type(weaponName) ~= 'string' then return end

    local trimmed = weaponName:gsub('^%s+', ''):gsub('%s+$', '')
    if trimmed == '' then return end

    local normalized = string.upper(trimmed)
    if not normalized:find('^WEAPON_') then
        normalized = npcWeaponAliases[string.lower(trimmed)] or ('WEAPON_' .. normalized)
    end

    local weaponHash = GetHashKey(normalized)
    if not IsWeaponValid(weaponHash) then return end

    GiveWeaponToPed(ped, weaponHash, 0, false, true)
    SetCurrentPedWeapon(ped, weaponHash, true)
    SetPedCanSwitchWeapon(ped, false)
    SetPedDropsWeaponsWhenDead(ped, false)
end

function StartCam(entity, _type)
    ClearFocus()

    local position = GetEntityCoords(entity)
    local rotation = GetEntityRotation(entity, 2)

    if _type == "new_npc" then
        position = position + vector3(0.0, 0.0, 0.52) + GetEntityForwardVector(entity)
        rotation = rotation + vector3(0.0, 0.0, 181)

        camera = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", position, rotation, GetGameplayCamFov())
        SetCamActive(camera, true)
        RenderScriptCams(true, true, 1000, true, false)
    end
end

function EndCam()
    if camera then
        ClearFocus()

        RenderScriptCams(false, true, 1000, true, false)
        DestroyCam(camera, false)

        camera = nil
    end
end

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        -- Parado con un encargo abierto, se quedaban el raton y la camara
        -- scriptada puestos: ninguno se va solo al parar el recurso.
        SetNuiFocus(false, false)
        EndCam()

        for i = 1, #Locations do
            DestroyLocationPoint(Locations[i])
        end
        -- Limpiar props de animación residuales
        for ped, props in pairs(LocationAnimProps) do
            for _, prop in ipairs(props) do
                if DoesEntityExist(prop) then DeleteEntity(prop) end
            end
            LocationAnimProps[ped] = nil
        end
    end
end)

RegisterNUICallback("TriggerCallback", function(data, cb)
    QBCore.Functions.TriggerCallback(data.name, function(retval)
        cb(retval)
    end, data)
end)

RegisterNUICallback("GetTriggerEvents", function(data, cb)
    cb(Config.TriggerEvents)
end)

--[[ Donde estoy ahora mismo.

     Leia cache.coords de ox_lib, que solo rellenan sus modulos de points y
     zones (imports/points/client.lua, imports/zones/shared.lua). Este recurso
     no los usa, asi que era nil SIEMPRE y caia al 0,0,0 de reserva: el boton
     de "mi posicion" parecia no hacer nada cuando en realidad guardaba el
     centro del mapa.

     Se lee con el native, que es lo que hay que hacer para una posicion que
     se pide en el momento: un cache tiene sentido para algo que se consulta
     cien veces por segundo, no para un clic. ]]
RegisterNUICallback("GetCoords", function(data, cb)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    cb({
        x = coords.x,
        y = coords.y,
        z = coords.z,
        w = GetEntityHeading(ped)
    })
end)

--[[ Marcar el sitio del encargo para poder volver.

     Mientras hablas con quien lo encarga no sirve de nada -- estas ahi. Sirve
     al salir: te vas a por lo que te pide y luego hay que volver, y en un
     mapa de este tamano "el chatarrero del puerto" no es una direccion.

     Pone el punto en origen_map (nuestro mapa, no el de GTA) con ruta, y de
     paso el waypoint del juego para quien vaya mirando el minimapa. ]]
RegisterNUICallback("marcarEncargo", function(data, cb)
    local x, y, z = tonumber(data.x), tonumber(data.y), tonumber(data.z)
    if not x or not y then return cb(false) end

    OrigenMapa.Poner('encargo', {
        x = x, y = y, z = z or 0.0,
        cat = 'trabajos',
        icono = 'exclamacion',
        nombre = data.nombre or 'Encargo',
        ruta = true,
    })
    SetNewWaypoint(x, y)

    cb(true)
end)

local function isAdmin()
    local p = promise:new()
    QBCore.Functions.TriggerCallback('origen_quests:server:isAdmin', function(hasPermission)
        p:resolve(hasPermission)
    end)
    return Citizen.Await(p)
end

--[[ Ir hasta un punto desde el panel de administracion.

     Antes esto solo ponia un waypoint. Para comprobar donde habia quedado un
     NPC habia que cerrar el panel y conducir hasta alli, y con cien puntos
     repartidos por el mapa eso no lo hace nadie. Ahora te lleva.

     Va aqui abajo y no donde estaba el callback viejo porque necesita
     `isAdmin`, y en Lua un `local function` no existe para el codigo escrito
     por encima de su declaracion.

     Tres cosas que no son adorno:

     . Se le vuelve a preguntar al servidor si quien lo pide es admin. El panel
       ya lo comprueba al abrirse, pero un callback de NUI que teletransporta y
       no comprueba nada es una puerta abierta: que alguien ponga un waypoint no
       le importa a nadie, que aparezca donde le de la gana si.
     . Se esconde el panel ANTES de mover a nadie. Con el foco NUI puesto no se
       ve el mundo, y el sentido de esto es justamente mirar. Se manda el
       mensaje de cerrar en vez de llamar a closeMenu, que ese ademas te
       devuelve al hub.
     . Se espera a que cargue el suelo. Sin esa espera, en cuanto el destino
       esta lejos apareces sobre un vacio y te caes hasta morir. ]]
RegisterNUICallback("IrAlPunto", function(data, cb)
    local x, y = tonumber(data.x), tonumber(data.y)
    if not x or not y then return cb(false) end

    local z = tonumber(data.z) or 0.0
    local w = tonumber(data.w)

    -- Se contesta ya: la promesa de la NUI no tiene por que esperar al viaje.
    cb(true)

    CreateThread(function()
        if not isAdmin() then return end

        -- El waypoint se sigue poniendo: al salir de aqui, para volver.
        SetNewWaypoint(x, y)

        SendNUIMessage({ menu = 'quests', action = 'close' })
        SetNuiFocus(false, false)

        local ped = PlayerPedId()
        -- Si vas conduciendo, se mueve el coche contigo. Si no, se queda
        -- tirado en la otra punta del mapa.
        local entidad = GetVehiclePedIsIn(ped, false)
        if entidad == 0 then entidad = ped end

        DoScreenFadeOut(300)
        local espera = 0
        while not IsScreenFadedOut() and espera < 100 do
            Wait(10)
            espera = espera + 1
        end

        FreezeEntityPosition(entidad, true)
        SetEntityCoordsNoOffset(entidad, x, y, z + 1.0, false, false, false)
        if w then SetEntityHeading(entidad, w) end

        local intentos = 0
        while not HasCollisionLoadedAroundEntity(entidad) and intentos < 300 do
            RequestCollisionAtCoord(x, y, z)
            Wait(10)
            intentos = intentos + 1
        end

        --[[ Las filas viejas del panel jQuery guardaban las coordenadas como
             texto y algunas se quedaron sin z: normalizeCoord las deja en 0, y
             el 0 esta bajo el agua o bajo tierra en casi todo el mapa. Con el
             suelo ya cargado si se puede preguntar donde esta. ]]
        if z <= 1.0 then
            local hayS, suelo = GetGroundZFor_3dCoord(x, y, 1000.0, false)
            if hayS then
                SetEntityCoordsNoOffset(entidad, x, y, suelo + 1.0, false, false, false)
            end
        else
            --[[ Y aunque haya z, puede ser mentira.

                 Habia puntos guardados DEBAJO del mapa —NPCs de interiores
                 MLO del servidor antiguo que aqui no estan instalados, a
                 veinte o cuarenta metros bajo la calle—. El viaje te llevaba
                 fiel a esa z, esperaba la colision, te soltaba y caias al
                 vacio. El dato ya esta arreglado, pero el viaje no puede
                 depender de que todos los datos esten bien: esto es lo que
                 usa un admin justo para ir a mirar los que estan mal.

                 Se lanza un rayo hacia abajo desde el sitio. Si pega, hay
                 suelo y te quedas donde toca —tambien en un porche o un
                 primer piso—. Si no pega nada y la superficie del mundo esta
                 claramente por encima, estabas bajo tierra: se te sube a
                 ella. Ojo con el "acerto" del rayo: segun la version llega
                 como booleano o como 0/1, y en Lua el 0 es verdadero. ]]
            local h = StartExpensiveSynchronousShapeTestLosProbe(
                x, y, z + 1.0, x, y, z - 15.0, 1 + 16, entidad, 7)
            local _, pego, pos = GetShapeTestResult(h)
            local haySuelo = (pego == true or pego == 1) and pos
                and not (pos.x == 0.0 and pos.y == 0.0 and pos.z == 0.0)

            if not haySuelo then
                local hayS, superficie = GetGroundZFor_3dCoord(x, y, 1000.0, false)
                if hayS and superficie > z + 2.0 then
                    SetEntityCoordsNoOffset(entidad, x, y, superficie + 1.0, false, false, false)
                end
            end
        end

        FreezeEntityPosition(entidad, false)
        DoScreenFadeIn(400)
    end)
end)

RegisterNetEvent("origen_quests:client:OpenMenu", function()
    if not isAdmin() then return end
    SendNUIMessage({
        menu = 'quests',
        action = 'open',
    })
    SetNuiFocus(true, true)
end)

RegisterCommand('questadmin', function()   
    TriggerEvent('origen_quests:client:OpenMenu')
end, false)

RegisterNetEvent("origen_quests:client:OpenNpcsMenu", function()
    if not isAdmin() then return end
    SendNUIMessage({
        menu = 'evils_npcs',
        action = 'open',
    })
    SetNuiFocus(true, true)
end)

RegisterNUICallback('closeMenu', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')

    -- ESC: si el panel se abrió desde la pestaña Scripts del admin, se vuelve
    -- a ella. origen_admin solo vuelve si este panel salió de su lista; con
    -- /questadmin, ESC cierra y nada más. (origen_hub ya no existe.)
    if GetResourceState('origen_admin') == 'started' then
        SetTimeout(80, function()
            pcall(function() exports['origen_admin']:ReturnToScripts() end)
        end)
    end
end)

local openedFromHub = false

exports('IsOpenedFromHub', function() return openedFromHub end)
exports('ResetHubFlag', function() openedFromHub = false end)

exports('openManagement', function()
    
    openedFromHub = true
    
    CreateThread(function()        
        SendNUIMessage({
            menu = 'quests',
            action = 'open',
        })
        
        SetNuiFocus(true, true)        
    end)
end)