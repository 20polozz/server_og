-- =============================================================================
-- Quests V2 — Rastreo cliente
--
-- Detecta los hechos del jugador (muertes, entrar en zonas, reunir items),
-- los reporta al servidor (que valida y capa), dibuja blip/waypoint al objetivo
-- activo y alimenta el HUD tracker + diario de la NUI.
-- =============================================================================

-- mission_id -> payload { mission_id, name, description, started_at, objectives }
local activeMissions = {}
-- mission_id fijado (blip + primero en el HUD). nil = automatico
local focusedMission = nil

-- Misiones que el jugador ha plegado del HUD (boton por mision en el diario).
-- Mapa [tostring(mission_id)] = true, persistido en KVP como JSON.
local hudHidden = json.decode(GetResourceKvpString('qv2_hud_hidden') or '{}') or {}

--[[ Misiones de OTROS recursos (04/10/2026): los encargos del Notario de
     origen_mision. No son de este sistema —no tienen fila en la base ni las
     valida este servidor— pero se ven en el MISMO sitio: el rastreador del HUD
     y la pestaña Misiones del inventario. Asi no hay dos cajas en pantalla.

     [id texto] = { datos = payload como el de las nuestras, recurso = quien la puso }
     El payload lleva `externa = true`: su punto del mapa lo pone su recurso, y
     abandonarla se le pide a el por el evento local 'origen_quests:externa:abandonar'. ]]
local externas = {}
-- Anti doble-conteo de kills (id de entidad ya contada)
local countedVictims = {}
-- Throttle de reportes de survive: "mission:idx" -> GetGameTimer() del ultimo envio
local lastSurviveReport = {}
local dentroDeZona = {}       -- "mision:objetivo" -> estaba dentro en el ultimo aviso

-- Blip del objetivo activo
local questBlip = nil
local questBlipRadius = nil

-- ---------------------------------------------------------------------------
-- Utilidades
-- ---------------------------------------------------------------------------

local function toVec(c)
    return vector3(c.x + 0.0, c.y + 0.0, c.z + 0.0)
end

local function countActive()
    local n = 0
    for _ in pairs(activeMissions) do n = n + 1 end
    return n
end

---Primer objetivo con posicion en el mundo de una mision (para blip/waypoint).
local function firstWorldObjective(m)
    for _, obj in ipairs(m.objectives) do
        if not obj.complete then
            if (obj.type == 'goto' or obj.type == 'survive' or obj.type == 'kidnap') and obj.coords then
                return obj
            elseif obj.type == 'kill' and obj.zone then
                return { type = 'kill', coords = obj.zone, radius = obj.zone.radius or 80.0 }
            end
        end
    end
    return nil
end

---Elige la mision "activa" para el HUD/blip: la fijada, o la primera.
local function resolveFocus()
    if focusedMission and activeMissions[focusedMission] then
        return focusedMission, activeMissions[focusedMission]
    end
    if focusedMission and externas[focusedMission] then
        return focusedMission, externas[focusedMission].datos
    end
    for id, m in pairs(activeMissions) do
        return id, m
    end
    return nil, nil
end

-- ---------------------------------------------------------------------------
-- Blip / waypoint
-- ---------------------------------------------------------------------------

local function clearBlip()
    if questBlip then
        OrigenMapa.Quitar(questBlip)
        questBlip = nil
    end
end

--[[ Donde esta quien encargo una mision.

     `Locations` es el catalogo que el cliente pide al arrancar
     (client/main.lua) y es global: cada entrada trae `location` como vector4. ]]
local function sitioDelEncargo(m)
    local id = tonumber(m and m.location_id)
    if not id or id == 0 or type(Locations) ~= 'table' then return nil end

    for i = 1, #Locations do
        local loc = Locations[i]
        if loc and tonumber(loc.id) == id and loc.location then
            return loc.location, loc.name
        end
    end
    return nil
end

local function refreshBlip()
    clearBlip()
    local _, m = resolveFocus()
    if not m then return end
    -- La de otro recurso marca su sitio ella sola.
    if m.externa then return end

    local obj = firstWorldObjective(m)
    local c, nombre, radio

    if obj and obj.coords then
        c = toVec(obj.coords)
        nombre = m.name or 'Mision'
        radio = (obj.radius or 25.0) + 0.0
    else
        --[[ Un objetivo de `collect` no tiene sitio: se reune donde se pueda.

             Antes eso significaba no marcar nada, y como casi todos los
             encargos empiezan reuniendo, aceptar una mision no ponia nada en
             el minimapa. En el mapa grande del menu de pausa si se veia —el
             NPC esta en el registro y alli no hay corte por distancia— y esa
             diferencia entre las dos pantallas era justo lo que chirriaba.

             Asi que se marca a quien lo encarga, que ademas es lo util: de un
             encargo de reunir cosas, lo unico que hay que saber es a quien
             hay que volver. ]]
        local sitio, quien = sitioDelEncargo(m)
        if not sitio then return end
        c = vector3(sitio.x + 0.0, sitio.y + 0.0, sitio.z + 0.0)
        nombre = quien or m.name or 'Mision'
    end

    --[[ El objetivo en curso, en el mapa.

         Ya no son blips del juego: es UN punto de origen_map. Antes hacian
         falta dos —uno para la marca y otro de radio para el circulo de la
         zona— porque un blip no sabe ser las dos cosas; aqui es el mismo punto
         con `radio`.

         Amarillo y con prioridad alta: es lo que hay que hacer ahora, asi que
         ni se confunde con los sitios conocidos —que van blancos— ni puede
         quedarse fuera por el corte de distancia ni por el tope del minimapa
         (ver Cerca() en origen_map/client/registro.lua). ]]
    questBlip = 'objetivo'
    questBlipRadius = nil

    OrigenMapa.Poner(questBlip, {
        x = c.x, y = c.y, z = c.z,
        cat = 'misiones',
        icono = 'exclamacion',
        nombre = nombre,
        color = '#f0c33c',
        radio = radio,
        prioridad = 10,
    })
end

--- El circulo de la zona ya no es un blip aparte: va dentro del mismo punto,
--- asi que quitarlo es quitar el punto. Se deja la funcion porque la llaman
--- desde varios sitios.
local function clearBlipRadius()
    questBlipRadius = nil
end

-- ---------------------------------------------------------------------------
-- NUI: refresco del HUD
-- ---------------------------------------------------------------------------

--- Las misiones activas en una lista, que es como las quiere quien las pinta.
local function listaMisiones()
    local list = {}
    for _, m in pairs(activeMissions) do
        list[#list + 1] = m
    end
    for _, e in pairs(externas) do
        list[#list + 1] = e.datos
    end
    return list
end

--- El rastreador plegado a una línea (tecla J). Se recuerda entre sesiones.
local trackerPlegado = GetResourceKvpInt('qv2_tracker_plegado') == 1

local function nuiState()
    return {
        action = 'qv2:sync',
        missions = listaMisiones(),
        focused = (resolveFocus()),
        plegado = trackerPlegado,
        hudHidden = hudHidden,
        serverTime = GetCloudTimeAsInt(),
    }
end

local function RefreshNUI()
    SendNUIMessage(nuiState())
    clearBlipRadius()
    refreshBlip()

    --[[ Y se avisa a quien tenga la lista delante.

         La lista de misiones ya no es un panel de este recurso: es una pestaña
         del inventario, que se puede tener abierta mientras cambia un
         contador. Sin este aviso habria que salir y volver a entrar en la
         pestaña para ver que un objetivo se ha cumplido. ]]
    TriggerEvent('origen_quests:misiones')
end

-- ---------------------------------------------------------------------------
-- Clasificacion de muertes
-- ---------------------------------------------------------------------------

local function killMatches(victim, obj, mission_id)
    if obj.type ~= 'kill' or obj.complete then return false end
    -- Los que ha puesto la propia mision (QV2Campamento): solo cuentan ellos.
    if obj.target == 'emboscada' then
        return QV2EsDeCampamento(mission_id, obj.idx, victim)
    end
    -- Por defecto, NPC hostil. En Invasion Z era 'zombie', que aqui no existe:
    -- una mision antigua sin target explicito contaria muertes que nunca
    -- llegan, y el jugador se quedaria mirando un contador clavado en cero.
    local t = obj.target or 'evil'

    if t == 'zombie' then
        -- Misiones heredadas. No hay nada que cuente como zombi, asi que se
        -- tratan como NPC hostil en vez de no contar nada.
        return IsEntityAPed(victim) and not IsPedAPlayer(victim)
    elseif t == 'model' then
        local m = GetEntityModel(victim)
        for _, name in ipairs(obj.models or {}) do
            if GetHashKey(name) == m then return true end
        end
        return false
    elseif t == 'evil' or t == 'ped' then
        return IsEntityAPed(victim) and not IsPedAPlayer(victim)
    end
    return false
end

local function inZone(coords, zone)
    if not zone then return true end
    return #(coords - toVec(zone)) <= (zone.radius or 80.0)
end

local function handleKill(victim)
    if countedVictims[victim] then return end
    local vcoords = GetEntityCoords(victim)
    local counted = false

    for mission_id, m in pairs(activeMissions) do
        for _, obj in ipairs(m.objectives) do
            -- A los del campamento no se les mira la zona: te persiguen, y el
            -- que cae dos calles mas alla tambien era de los que habia que tumbar.
            if killMatches(victim, obj, mission_id) and (obj.target == 'emboscada' or inZone(vcoords, obj.zone)) then
                TriggerServerEvent('origen_quests:server:qv2Kill', mission_id, obj.idx)
                counted = true
                if obj.target == 'emboscada' then QV2Contado(mission_id, obj.idx, victim) end
            end
        end
    end

    if counted then countedVictims[victim] = true end
end

AddEventHandler('gameEventTriggered', function(name, args)
    if name ~= 'CEventNetworkEntityDamage' then return end
    local victim = args[1]
    local attacker = args[2]
    if attacker ~= PlayerPedId() then return end
    if not victim or victim == 0 or victim == PlayerPedId() then return end
    if not DoesEntityExist(victim) then return end

    -- El flag de muerte del evento varia entre builds: confirmamos el estado
    -- real del ped en los siguientes ticks para no perder ni duplicar kills.
    CreateThread(function()
        if countedVictims[victim] then return end
        local tries = 0
        while tries < 12 do
            if not DoesEntityExist(victim) then return end
            if IsEntityDead(victim) or IsPedDeadOrDying(victim, true) then
                handleKill(victim)
                return
            end
            tries = tries + 1
            Wait(120)
        end
    end)
end)

-- Limpieza periodica del set de victimas contadas (los ids de entidad se reciclan)
CreateThread(function()
    while true do
        Wait(60 * 1000)
        countedVictims = {}
    end
end)

-- ---------------------------------------------------------------------------
-- Bucle de zonas (goto / survive) + collect
-- ---------------------------------------------------------------------------

CreateThread(function()
    while true do
        local sleep = 1000
        if countActive() > 0 then
            local pcoords = GetEntityCoords(PlayerPedId())

            for mission_id, m in pairs(activeMissions) do
                for _, obj in ipairs(m.objectives) do
                    if not obj.complete then
                        if obj.type == 'goto' and obj.coords then
                            sleep = 400
                            if #(pcoords - toVec(obj.coords)) <= (obj.radius or 25.0) then
                                obj.complete = true -- optimista; el servidor confirma
                                TriggerServerEvent('origen_quests:server:qv2Reach', mission_id, obj.idx)
                            end
                        elseif obj.type == 'kill' and obj.enemigos and obj.zone then
                            sleep = 400
                            if #(pcoords - toVec(obj.zone)) <= (obj.zone.radius or 80.0) then
                                QV2Campamento(mission_id, obj)
                            end
                        elseif obj.type == 'survive' and obj.coords then
                            sleep = 400
                            local inside = #(pcoords - toVec(obj.coords)) <= (obj.radius or 40.0)
                            if inside and obj.enemigos then QV2Emboscada(mission_id, obj) end
                            -- El servidor suma solo el tiempo que pasas dentro y es el
                            -- que confirma. Se le avisa al entrar, cada 4 s mientras
                            -- sigues dentro (si deja de oirte, cierra el tramo) y al salir.
                            local key = mission_id .. ':' .. obj.idx
                            local t = GetGameTimer()
                            local cambia = inside ~= (dentroDeZona[key] or false)
                            local toca = inside and (not lastSurviveReport[key] or (t - lastSurviveReport[key]) > 4000)
                            if cambia or toca then
                                dentroDeZona[key] = inside
                                lastSurviveReport[key] = t
                                TriggerServerEvent('origen_quests:server:qv2Survive', mission_id, obj.idx, inside)
                            end
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

--[[ Secuestros.

     origen_hostage ya lleva la cuenta de quien va contigo (su export
     Seguidores); aqui solo se mira si llevas a alguien y estas en el punto de
     entrega. La captura en si no se programa: ese recurso hace todo el trabajo
     —el NPC se rinde apuntandole, te sigue y se mete solo en tu coche—.

     Cada NPC cuenta UNA vez: sin la tabla de entregados bastaria con dar vueltas dentro
     del radio con el mismo tio detras para llenar el contador. ]]
--- Si la mision pide modelos concretos, solo cuentan esos; si no pide
--- ninguno, vale cualquiera.
local function ModeloVale(ped, obj)
    local modelos = obj.models or {}
    if #modelos == 0 then return true end

    local m = GetEntityModel(ped)
    for _, nombre in ipairs(modelos) do
        if GetHashKey(nombre) == m then return true end
    end
    return false
end

--[[ Quien ya se ha entregado, para que el mismo NPC no cuente dos veces.

     No se vacia por tiempo a proposito: si se limpiara cada minuto bastaria
     con quedarse quieto en el punto con el mismo tio detras para ir sumando.
     Lo que si se sueltan son las entradas de misiones que ya no estan activas,
     que es cuando dejan de significar nada. ]]
local entregados = {}

CreateThread(function()
    while true do
        local sleep = 1500
        local hayObjetivo = false

        for mission_id, m in pairs(activeMissions) do
            for _, obj in ipairs(m.objectives) do
                if obj.type == 'kidnap' and not obj.complete then
                    hayObjetivo = true
                end
            end
        end

        -- Las entregas de misiones que ya no estan en curso no pintan nada.
        for clave in pairs(entregados) do
            local mid = tonumber(clave:match('^(%d+):'))
            if not mid or not activeMissions[mid] then entregados[clave] = nil end
        end

        if hayObjetivo and GetResourceState('origen_hostage') == 'started' then
            sleep = 700

            local ok, seguidores = pcall(function()
                return exports['origen_hostage']:Seguidores()
            end)

            if ok and type(seguidores) == 'table' and #seguidores > 0 then
                local pcoords = GetEntityCoords(PlayerPedId())

                for mission_id, m in pairs(activeMissions) do
                    for _, obj in ipairs(m.objectives) do
                        if obj.type == 'kidnap' and not obj.complete then
                            -- Sin punto marcado, el objetivo es la captura; con
                            -- punto, hay que estar dentro del radio.
                            local enSitio = true
                            if obj.coords then
                                enSitio = #(pcoords - toVec(obj.coords)) <= (obj.radius or 25.0)
                            end

                            if enSitio then
                                for _, ped in ipairs(seguidores) do
                                    local clave = mission_id .. ':' .. obj.idx .. ':' .. ped
                                    if not entregados[clave] and ModeloVale(ped, obj) then
                                        entregados[clave] = true
                                        TriggerServerEvent('origen_quests:server:qv2Kidnap', mission_id, obj.idx)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

-- collect: pide comprobacion server-side periodica mientras haya objetivos collect
-- Intervalo subido de 3-5s a 8-10s: el servidor ya evita trabajo extra si el
-- conteo no cambio (ver CheckCollectObjective), pero seguir pidiendolo cada
-- 3s era mas frecuente de lo necesario para un progreso que no es time-critical.
CreateThread(function()
    while true do
        local hasCollect = false
        for mission_id, m in pairs(activeMissions) do
            for _, obj in ipairs(m.objectives) do
                if obj.type == 'collect' and not obj.complete then
                    hasCollect = true
                    TriggerServerEvent('origen_quests:server:qv2Collect', mission_id, obj.idx)
                end
            end
        end
        Wait(hasCollect and 8000 or 10000)
    end
end)

-- ---------------------------------------------------------------------------
-- Eventos del servidor
-- ---------------------------------------------------------------------------

RegisterNetEvent('origen_quests:client:qv2Sync', function(list)
    activeMissions = {}
    for _, m in ipairs(list or {}) do
        activeMissions[m.mission_id] = m
    end
    RefreshNUI()
end)

RegisterNetEvent('origen_quests:client:qv2Start', function(payload)
    activeMissions[payload.mission_id] = payload
    focusedMission = payload.mission_id
    RefreshNUI()
end)

RegisterNetEvent('origen_quests:client:qv2Update', function(payload)
    activeMissions[payload.mission_id] = payload
    RefreshNUI()
end)

RegisterNetEvent('origen_quests:client:qv2Remove', function(mission_id)
    activeMissions[mission_id] = nil
    if focusedMission == mission_id then focusedMission = nil end
    RefreshNUI()
end)

RegisterNetEvent('origen_quests:client:qv2Complete', function(mission_id, name, summary)
    activeMissions[mission_id] = nil
    if focusedMission == mission_id then focusedMission = nil end
    SendNUIMessage({
        action = 'qv2:complete',
        name = name,
        summary = summary or {},
    })

    --[[ Y se avisa fuera, para la lista de completadas de la pestaña del
         inventario: ese historial es de la sesion y no se guarda en ninguna
         parte, asi que si nadie lo apunta al pasar, se pierde. ]]
    TriggerEvent('origen_quests:completada', name, summary or {})

    RefreshNUI()
end)

-- ---------------------------------------------------------------------------
-- La lista de misiones
-- ---------------------------------------------------------------------------

--[[ Ya no es un panel de este recurso.

     Era un diario propio que se abria con F5 encima del juego. Ahora es una
     pestaña del inventario, como Ciudad o Personaje: el jugador la consulta
     cuando quiere sin salir del panel en el que ya esta, y no hay dos
     columnas iguales abriendose por separado en el mismo canto de la
     pantalla.

     Aqui queda lo que este recurso sabe y los demas no: cuales son las
     misiones, cual esta fijada y que se puede hacer con ellas. Quien las
     pinta es el inventario, a traves de estos exports.

     Se devuelve una copia de `hudHidden` y no la tabla viva: quien la reciba
     esta en otro recurso y no tiene por que poder tocar nuestro estado. ]]
exports('MisionesDatos', function()
    local plegadas = {}
    for k, v in pairs(hudHidden) do plegadas[k] = v end

    return {
        missions = listaMisiones(),
        focused = (resolveFocus()),
        hudHidden = plegadas,
        serverTime = GetCloudTimeAsInt(),
    }
end)

--- Fijar una: es la que sale entera en el HUD y la que marca el mapa.
local function fijarMision(id)
    if type(id) == 'string' and externas[id] then
        focusedMission = id
        RefreshNUI()
        return true
    end
    id = tonumber(id)
    if not id or not activeMissions[id] then return false end

    focusedMission = id
    RefreshNUI()

    SetNewWaypoint(0.0, 0.0) -- limpia el waypoint anterior
    local obj = firstWorldObjective(activeMissions[id])
    if obj and obj.coords then
        local c = toVec(obj.coords)
        SetNewWaypoint(c.x, c.y)
    end
    return true
end

--- Plegar o desplegar una del HUD. Se recuerda entre sesiones.
local function plegarMision(id)
    id = tostring(id or '')
    if id == '' then return false end

    if hudHidden[id] then hudHidden[id] = nil else hudHidden[id] = true end
    SetResourceKvp('qv2_hud_hidden', json.encode(hudHidden))
    RefreshNUI()
    return true
end

--- Abandonarla. Lo confirma el servidor, que es quien la borra.
local function abandonarMision(id)
    if type(id) == 'string' and externas[id] then
        TriggerEvent('origen_quests:externa:abandonar', id)
        return true
    end
    id = tonumber(id)
    if not id then return false end
    TriggerServerEvent('origen_quests:server:qv2Abandon', id)
    return true
end

--[[ Poner, cambiar o quitar (datos = nil) una mision de otro recurso.

     datos = { name, location_name?, objectives = { { idx, type, label, amount?,
               done?, complete?, donde? } } }
     `type` como las nuestras: 'goto' sale con un punto, el resto con contador.
     La primera vez se fija: el jugador la acaba de coger y es la que quiere ver.
     Al terminarla, cada recurso avisa por sus notificaciones y la quita (nil). ]]
exports('MisionExterna', function(id, datos)
    id = tostring(id or '')
    if id == '' then return false end
    if datos == nil then
        externas[id] = nil
        if focusedMission == id then focusedMission = nil end
        RefreshNUI()
        return true
    end
    if type(datos) ~= 'table' then return false end
    local nueva = externas[id] == nil
    datos.mission_id = id
    datos.externa = true
    datos.objectives = datos.objectives or {}
    externas[id] = { datos = datos, recurso = GetInvokingResource() }
    if nueva then focusedMission = id end
    RefreshNUI()
    return true
end)

--- Si el recurso que las puso se para, se van con el.
AddEventHandler('onResourceStop', function(recurso)
    local cambia = false
    for id, e in pairs(externas) do
        if e.recurso == recurso then
            externas[id] = nil
            if focusedMission == id then focusedMission = nil end
            cambia = true
        end
    end
    if cambia then RefreshNUI() end
end)

exports('MisionFijar', fijarMision)
exports('MisionPlegar', plegarMision)
exports('MisionAbandonar', abandonarMision)

--[[ Las dos teclas del rastreador del HUD (diseño «HUD tracker quests»):
     J pliega la misión fijada a una línea y K pasa a la siguiente.

     Las lee el juego y no la interfaz: el rastreador se ve mientras juegas,
     sin foco de teclado, así que una tecla escuchada desde la NUI no llegaría
     nunca. Son RegisterKeyMapping, así que cada jugador puede cambiarlas en
     Ajustes > Teclas > FiveM (y el default solo se aplica la primera vez que
     su perfil ve el comando).

     No hacen nada sin misiones, con un panel delante o con el HUD apartado. ]]
local function puedeTocarRastreador()
    return (next(activeMissions) ~= nil or next(externas) ~= nil) and not IsNuiFocused() and not IsPauseMenuActive() and GetPauseMenuState() == 0
end

RegisterCommand('questplegar', function()
    if not puedeTocarRastreador() then return end
    trackerPlegado = not trackerPlegado
    SetResourceKvpInt('qv2_tracker_plegado', trackerPlegado and 1 or 0)
    SendNUIMessage({ action = 'qv2:plegado', plegado = trackerPlegado })
end, false)

--- La siguiente misión a la vista, en orden de id, y se fija: es la misma
--- fijada de la pestaña de Misiones del inventario, con su punto en el mapa.
RegisterCommand('questsiguiente', function()
    if not puedeTocarRastreador() then return end

    local ids = {}
    for id in pairs(activeMissions) do
        if not hudHidden[tostring(id)] then ids[#ids + 1] = id end
    end
    for id in pairs(externas) do
        if not hudHidden[id] then ids[#ids + 1] = id end
    end
    if #ids < 2 then return end
    -- Las nuestras por id y las de fuera detras: numeros y textos no se comparan.
    table.sort(ids, function(a, b)
        if type(a) ~= type(b) then return type(a) == 'number' end
        return a < b
    end)

    local actual = (resolveFocus())
    local siguiente = ids[1]
    for i = 1, #ids do
        if ids[i] == actual then
            siguiente = ids[i % #ids + 1]
            break
        end
    end

    -- Al cambiar de misión se despliega: lo que se quiere es ver la nueva.
    if trackerPlegado then
        trackerPlegado = false
        SetResourceKvpInt('qv2_tracker_plegado', 0)
    end
    fijarMision(siguiente)
end, false)

RegisterKeyMapping('questplegar', 'Misiones: plegar el seguimiento', 'keyboard', 'J')
RegisterKeyMapping('questsiguiente', 'Misiones: pasar a la siguiente', 'keyboard', 'K')

--[[ Las misiones se abren desde el riel del inventario y de ninguna otra
     forma. Si el inventario no esta en marcha no pasa nada: no hay adonde ir,
     y quedarse sin hacer nada es mejor que abrir medio panel.

     Sin tecla. El F5 estuvo aqui y se ha quitado: es la misma decision que ya
     se tomo con la banda, el negocio y la policia —una sola puerta, el riel, y
     ninguna tecla ocupada de por vida—. Los comandos se quedan por si alguien
     los tiene a mano.

     Ojo si algun dia se le vuelve a poner tecla: el default de un
     RegisterKeyMapping solo se aplica la primera vez que el perfil del jugador
     ve ese comando, asi que a quien ya lo tenga no le cambiara nada. ]]
local function abrirMisiones()
    if GetResourceState('origen_inventory') ~= 'started' then return end
    pcall(function()
        exports.origen_inventory:AbrirEnPestana('quests')
    end)
end

RegisterCommand('questjournal', abrirMisiones, false)
RegisterCommand('questdiario', abrirMisiones, false)

-- Otro recurso abre un panel en la zona derecha de la pantalla (el menú F1 de
-- habilidades de origen_zombies) y pide ocultar el tracker mientras dure.
-- Evento LOCAL cross-recurso: origen_zombies hace TriggerEvent('qv2:suppressHud', bool).
--[[ El rastreador se aparta por dos caminos, y se pinta oculto si lo pide
     cualquiera de los dos:

     - porAviso: lo ultimo que dijeron 'qv2:suppressHud' o el inventario. Es
       una sola bandera a proposito, como antes: el radial pide ocultar y, si
       se elige una opcion del inventario, quien lo devuelve es el inventario
       al cerrarse. Con una bandera por cada uno se quedaba oculto para siempre.
     - porFoco: cualquier interfaz con el foco del raton (garajes, gasolina,
       ropa, negocio...). Asi ningun menu tiene que acordarse de avisar: los
       paneles caen en el canto derecho y el rastreador se veia a traves del
       cristal.
     - porPesca: el HUD de la pesca, que ocupa ese mismo canto. Este SI lleva
       bandera propia: la pesca dura un rato largo y, con la de porAviso, bastaba
       con abrir y cerrar el inventario en mitad de la partida para que el
       rastreador volviera encima de la tarjeta de pesca. ]]
local porAviso, porFoco, porPesca = false, false, false

--[[ - porAjustes (07/10): el menu de Ajustes (origen_ajustes) avisa con
       TriggerEvent('origen:ajustes', bool); con el abierto solo se ve el menu. ]]
local porAjustes = false

--[[ - porCreador (14/10): grabando un circuito (origen_racing avisa con
       'origen_racing:enCreador'): el rastreador tapaba el panel de la grabacion. ]]
local porCreador = false

local function enviarApartado()
    SendNUIMessage({ action = 'qv2:suppressHud', suppress = porAviso or porFoco or porPesca or porAjustes or porCreador })
end

AddEventHandler('origen:ajustes', function(abierto)
    porAjustes = abierto == true
    enviarApartado()
end)

AddEventHandler('origen_racing:enCreador', function(si)
    porCreador = si == true
    enviarApartado()
end)

AddEventHandler('qv2:suppressHud', function(suppress)
    porAviso = suppress == true
    enviarApartado()
end)

--[[ Y el inventario, que ahora es donde vive la lista de misiones.

     Su columna ocupa el mismo canto derecho que el rastreador, asi que sin
     esto el HUD se pintaria encima de la pestaña que enseña exactamente lo
     mismo. ]]
AddEventHandler('origen_inventory:abierto', function(abierto)
    porAviso = abierto == true
    enviarApartado()
end)

--[[ Y la pesca: mientras la tarjeta de «Pesca activa» esta a la vista, el
     rastreador se aparta y vuelve solo cuando ella se va (al salir de la zona,
     al parar la partida o si el recurso se reinicia).

     Evento LOCAL cross-recurso: origen_fishing hace
     TriggerEvent('origen_fishing:pescando', bool) en su toggleFishing. ]]
AddEventHandler('origen_fishing:pescando', function(pescando)
    porPesca = pescando == true
    enviarApartado()
end)

--[[ El foco de la NUI es POR RECURSO, y IsNuiFocused() no siempre ve el de
     los demas: el rastreador se quedaba pintado encima de los paneles a
     pantalla completa de otros recursos (el admin del carboosting). Por eso
     se mira tambien la red de @origen_map/shared/foco.lua, que cada recurso
     con interfaz carga y que avisa de quien coge y suelta el foco.
     El foco de ESTE recurso no cuenta: sus paneles ya esconden el rastreador
     en la propia NUI (dialogo abierto, admin abierto). ]]
local function otroConFoco()
    if OrigenFoco then
        if OrigenFoco.OtroConFoco() then return true end
        return IsNuiFocused() == true and not OrigenFoco.Tiene()
    end
    return IsNuiFocused() == true
end

CreateThread(function()
    while true do
        local foco = otroConFoco()
        if foco ~= porFoco then
            porFoco = foco
            enviarApartado()
        end
        Wait(250)
    end
end)

-- Salvaguarda: si origen_zombies, origen_clothing, origen_fuel o el propio
-- inventario se paran/reinician con su menu abierto, nadie mandaria el
-- suppress=false y el tracker quedaria oculto para siempre.
AddEventHandler('onClientResourceStop', function(res)
    if res == 'origen_zombies' or res == 'origen_clothing' or res == 'origen_fuel'
        or res == 'origen_inventory' or res == 'origen_hud' or res == 'origen_anims' then
        porAviso = false
        enviarApartado()
    end

    if res == 'origen_fishing' then
        porPesca = false
        enviarApartado()
    end
end)

-- ---------------------------------------------------------------------------
-- Pedir estado al entrar / al arrancar el recurso
-- ---------------------------------------------------------------------------

local function requestActive()
    TriggerServerEvent('origen_quests:server:qv2RequestActive')
end

AddEventHandler('QBCore:Client:OnPlayerLoaded', requestActive)
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', requestActive)

-- Red de seguridad para "origen_quests se reinicia con el jugador ya en el
-- mundo" (los dos hooks de OnPlayerLoaded de arriba no se vuelven a disparar
-- entonces). Mismo bug que main.lua's CreateThread ya documenta: sin el
-- guard de isLoggedIn, este Wait(3000) puede disparar mientras el jugador
-- SIGUE en el bucket temporal de creacion de origen_creationv2 (personaje
-- NUEVO, formulario + mapa de base). LoadCitizen (server/quests2.lua) filtra
-- por instance_id y cachea el resultado PARA SIEMPRE (incluso vacio), asi
-- que una llamada aqui en mal momento deja al jugador sin quests el resto de
-- la sesion.
CreateThread(function()
    Wait(3000)
    if not LocalPlayer.state.isLoggedIn then return end
    requestActive()
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    clearBlip()
    clearBlipRadius()
end)


--[[ ═══════════════════════════════════════════════════════════════════════
     Emboscadas

     Un objetivo de aguantar puede traer `enemigos`: gente que aparece cuando
     entras en la zona y viene a por ti. Sin esto, "aguantar" era quedarse
     quieto mirando un reloj, y en un seguimiento de policia o en un sitio de
     banda eso no tiene sentido ninguno.

     Solo armas de mano, a proposito: el servidor abre ahora y la gente no
     tiene con que defenderse de un arma de fuego. Se pide asi en el contenido
     y aqui se vuelve a filtrar, por si alguien escribe otra cosa en el panel.

     Va en una funcion GLOBAL y al final del fichero: el bucle de zonas se
     define mucho mas arriba, y una funcion `local` declarada aqui abajo no la
     veria. Las globales se buscan cuando se llaman, no cuando se escriben.
   ═══════════════════════════════════════════════════════════════════════ ]]

local Emboscadas = {}   -- "mision:objetivo" -> { mission_id, idx, peds = {} }

local ARMAS_DE_MANO = {
    weapon_bat = true, weapon_knife = true, weapon_knuckle = true,
    weapon_bottle = true, weapon_crowbar = true, weapon_hammer = true,
    weapon_switchblade = true, weapon_wrench = true, weapon_golfclub = true,
}

-- Si un modelo del contenido no existe en el juego, se usa este, que esta
-- probado: sale ya en los NPC de encargos.
local MODELO_DE_RESERVA = 'a_m_m_hillbilly_01'

local function puntoAlrededor(jugador, cerca, lejos)
    for _ = 1, 12 do
        local ang = math.random() * math.pi * 2
        local d = cerca + math.random() * (lejos - cerca)
        local x = jugador.x + math.cos(ang) * d
        local y = jugador.y + math.sin(ang) * d
        local hay, z = GetGroundZFor_3dCoord(x, y, jugador.z + 30.0, false)
        -- Que no salgan en el tejado de al lado ni en un sotano.
        if hay and math.abs(z - jugador.z) < 6.0 then
            return vector3(x, y, z)
        end
    end
    return vector3(jugador.x + cerca, jugador.y, jugador.z)
end

-- El pool de peds de GTA es de 256 y se comparte con TODO: trafico, peatones,
-- los NPC de cada recurso. Por encima de esto no se suelta a nadie: mejor un
-- enemigo menos que un crash por "Pool Full, Size == 256".
local TOPE_PEDS = 190

local function soltarEnemigo(e, jugadorPed, centro, cerca, lejos)
    if #GetGamePool('CPed') >= TOPE_PEDS then return nil end
    local modelos = type(e.modelos) == 'table' and e.modelos or {}
    local nombre = modelos[math.random(1, math.max(1, #modelos))] or MODELO_DE_RESERVA
    local hash = GetHashKey(nombre)
    if not IsModelInCdimage(hash) then hash = GetHashKey(MODELO_DE_RESERVA) end

    RequestModel(hash)
    local t = 0
    while not HasModelLoaded(hash) and t < 200 do Wait(10); t = t + 1 end
    if not HasModelLoaded(hash) then return nil end

    local jc = GetEntityCoords(jugadorPed)
    local p = puntoAlrededor(centro or jc, cerca or 16.0, lejos or 26.0)
    local rumbo = (math.deg(math.atan(jc.y - p.y, jc.x - p.x)) - 90.0) % 360.0

    local ped = CreatePed(4, hash, p.x, p.y, p.z, rumbo, true, true)
    SetModelAsNoLongerNeeded(hash)
    if not ped or ped == 0 then return nil end

    local armas = type(e.armas) == 'table' and e.armas or {}
    local arma = armas[math.random(1, math.max(1, #armas))]
    if arma and ARMAS_DE_MANO[arma] then
        GiveWeaponToPed(ped, GetHashKey(arma), 1, false, true)
        SetCurrentPedWeapon(ped, GetHashKey(arma), true)
    end

    SetPedRelationshipGroupHash(ped, GetHashKey('HATES_PLAYER'))
    SetPedAsEnemy(ped, true)
    SetPedDropsWeaponsWhenDead(ped, false)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 46, true)   -- pelea siempre, no se rinde
    SetPedCombatAttributes(ped, 5, true)    -- puede luchar cuerpo a cuerpo
    TaskCombatPed(ped, jugadorPed, 0, 16)

    -- En rojo en el mapa: con cinco repartidos por una nave, sin esto se
    -- pasaba mas rato buscando al ultimo que peleando.
    local blip = AddBlipForEntity(ped)
    SetBlipColour(blip, 1)
    SetBlipScale(blip, 0.75)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Hostil')
    EndTextCommandSetBlipName(blip)

    return ped
end

--- Se llama desde el bucle de zonas cada vez que estas dentro. Solo actua la
--- primera: despues ya hay una emboscada apuntada para ese objetivo.
function QV2Emboscada(mission_id, obj)
    local e = obj.enemigos
    if type(e) ~= 'table' then return end

    local clave = mission_id .. ':' .. tostring(obj.idx)
    if Emboscadas[clave] then return end
    Emboscadas[clave] = { mission_id = mission_id, idx = obj.idx, peds = {} }

    CreateThread(function()
        -- Un respiro: que te de tiempo a ver donde estas antes de que vengan.
        Wait((tonumber(e.retraso) or 6) * 1000)

        local cuantos = math.max(1, math.min(tonumber(e.n) or 2, 5))
        local yo = PlayerPedId()
        for _ = 1, cuantos do
            local reg = Emboscadas[clave]
            if not reg then return end   -- el objetivo ya acabo
            local ped = soltarEnemigo(e, yo)
            if ped then reg.peds[#reg.peds + 1] = ped end
            Wait(1200)
        end

        if e.aviso then
            exports.origen_notify:Notify({
                title = 'Te han visto', description = e.aviso, type = 'error', duration = 5000,
            })
        end
    end)
end

--- Al acabar el objetivo, los que sigan en pie salen corriendo y el juego
--- los quita cuando ya no se ven: borrarlos de golpe en mitad de la pelea
--- queda fatal. Solo se borran en seco al parar el recurso (`deGolpe`).
local function quitarEmboscada(clave, deGolpe)
    local reg = Emboscadas[clave]
    Emboscadas[clave] = nil
    if not reg then return end
    for _, ped in ipairs(reg.peds) do
        if DoesEntityExist(ped) then
            if deGolpe or IsPedDeadOrDying(ped, true) then
                DeleteEntity(ped)
            else
                ClearPedTasks(ped)
                SetPedRelationshipGroupHash(ped, GetHashKey('CIVMALE'))
                TaskSmartFleePed(ped, PlayerPedId(), 150.0, -1, false, false)
                SetPedKeepTask(ped, true)
                SetEntityAsNoLongerNeeded(ped)
            end
        end
    end
end

--[[ El vigilante de las emboscadas.

     Mira cada dos segundos si el objetivo de cada una sigue abierto. En
     cuanto se completa, se abandona o se entrega la mision, se quitan los que
     queden. Asi no hay que tocar ninguno de los eventos de arriba, que ya
     hacen bastantes cosas cada uno. ]]
CreateThread(function()
    while true do
        Wait(2000)
        for clave, reg in pairs(Emboscadas) do
            --[[ Los que caen: fuera el blip al momento y el cuerpo a los 10 s.
                 Antes los cuerpos se quedaban hasta que acababa el objetivo, y
                 en un campamento que vuelve a soltar gente eso es ir llenando
                 el pool de peds.
                 Y si uno de los del campamento muere sin que lo tumbaras tu
                 (le atropella alguien, se cae, lo remata otro), cuenta igual:
                 era de los que habia que quitar de en medio. ]]
            reg.muertos = reg.muertos or {}
            reg.contado = reg.contado or {}
            local ahora = GetGameTimer()
            local quedan = {}
            for _, ped in ipairs(reg.peds) do
                if DoesEntityExist(ped) then
                    if IsPedDeadOrDying(ped, true) then
                        local b = GetBlipFromEntity(ped)
                        if b and b ~= 0 then RemoveBlip(b) end
                        reg.muertos[ped] = reg.muertos[ped] or ahora
                        local lleva = ahora - reg.muertos[ped]
                        if reg.campamento and lleva > 3000 and not reg.contado[ped] then
                            reg.contado[ped] = true
                            countedVictims[ped] = true
                            TriggerServerEvent('origen_quests:server:qv2Kill', reg.mission_id, reg.idx)
                        end
                        if lleva > 10000 then
                            DeleteEntity(ped)
                            reg.muertos[ped] = nil
                        else
                            quedan[#quedan + 1] = ped
                        end
                    else
                        quedan[#quedan + 1] = ped
                    end
                end
            end
            reg.peds = quedan
            local m = activeMissions[reg.mission_id]
            local abierto = false
            if m then
                for _, o in ipairs(m.objectives or {}) do
                    if o.idx == reg.idx and not o.complete then abierto = true break end
                end
            end
            if not abierto then quitarEmboscada(clave) end
        end
    end
end)

AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    for clave in pairs(Emboscadas) do quitarEmboscada(clave, true) end
end)



--[[ ═══════════════════════════════════════════════════════════════════════
     Campamentos

     Un objetivo de ELIMINAR con `enemigos` trae a su gente: cuando entras en
     la zona aparecen alrededor de su centro los que faltan por tumbar, van a
     por ti, y solo cuentan ELLOS (killMatches, target 'emboscada'). Sin esto
     "elimina a cuatro" contaba a cualquiera que cayera en la zona, y eso son
     civiles.

     Si el juego los quita (te alejas mucho, se caen por un terraplen) y aun
     faltan, vuelven a salir la proxima vez que entres: el contador nunca se
     queda clavado. Comparten el registro y el vigilante con las emboscadas,
     asi que se van igual que ellas cuando el objetivo acaba.
   ═══════════════════════════════════════════════════════════════════════ ]]

function QV2EsDeCampamento(mission_id, idx, ped)
    local reg = Emboscadas[tostring(mission_id) .. ':' .. tostring(idx)]
    if not reg then return false end
    for _, p in ipairs(reg.peds) do
        if p == ped then return true end
    end
    return false
end

function QV2Campamento(mission_id, obj)
    local e = obj.enemigos
    if type(e) ~= 'table' or not obj.zone then return end

    local clave = tostring(mission_id) .. ':' .. tostring(obj.idx)
    local faltan = math.max(0, (tonumber(obj.amount) or 1) - (tonumber(obj.done) or 0))
    if faltan == 0 then return end

    local reg = Emboscadas[clave]
    if reg then
        if reg.soltando or (GetGameTimer() - (reg.desde or 0)) < 15000 then return end
        for _, p in ipairs(reg.peds) do
            if DoesEntityExist(p) and not IsPedDeadOrDying(p, true) then return end
        end
        -- Ni uno en pie y aun faltan: el juego se los ha llevado. Otra tanda,
        -- pero no infinitas: un campamento no es una fabrica de peds.
        reg.tandas = (reg.tandas or 1) + 1
        if reg.tandas > 4 then return end
    else
        reg = { mission_id = mission_id, idx = obj.idx, peds = {}, campamento = true, tandas = 1 }
        Emboscadas[clave] = reg
    end
    reg.soltando = true
    reg.desde = GetGameTimer()

    CreateThread(function()
        local yo = PlayerPedId()
        local centro = toVec(obj.zone)
        for _ = 1, math.min(faltan, 8) do
            if Emboscadas[clave] ~= reg then return end   -- el objetivo ya acabo
            local ped = soltarEnemigo(e, yo, centro, 4.0, 14.0)
            if ped then reg.peds[#reg.peds + 1] = ped end
            Wait(350)
        end
        reg.soltando = false
        if e.aviso then
            exports.origen_notify:Notify({
                title = 'Te han visto', description = e.aviso, type = 'error', duration = 5000,
            })
        end
    end)
end


--- handleKill lo llama al contar a uno del campamento, para que el vigilante
--- no lo vuelva a contar cuando lo vea muerto.
function QV2Contado(mission_id, idx, ped)
    local reg = Emboscadas[tostring(mission_id) .. ':' .. tostring(idx)]
    if reg then
        reg.contado = reg.contado or {}
        reg.contado[ped] = true
    end
end

--[[ /pedsquest — quien llena el pool de peds.

     GTA tiene sitio para 256 y el crash "Pool Full, Size == 256" es ese pool
     lleno. Esto cuenta los que hay ahora, cuantos son de este recurso (los NPC
     de los puntos y los enemigos) y los modelos que mas se repiten, para
     saber si el que los deja tirados es este recurso u otro. ]]
RegisterCommand('pedsquest', function(_, args)
    local todos = GetGamePool('CPed')
    local yo = PlayerPedId()
    local aqui = GetEntityCoords(yo)

    -- Nombres que se conocen desde aqui: los NPC de los puntos y los enemigos.
    -- El resto sale como hash; GTA no guarda el nombre del modelo.
    local nombres = {}
    for _, q in pairs(Quests and Quests.Table or {}) do
        if q.data and q.data.model then nombres[GetHashKey(q.data.model)] = q.data.model end
    end
    for _, t in ipairs({ 'g_m_y_ballasout_01', 'g_m_y_ballaeast_01', 'g_m_y_famca_01', 'g_m_y_mexgoon_01',
        'g_m_y_mexgoon_02', 'g_m_y_mexgoon_03', 'g_m_m_mexboss_01', 'g_m_y_lost_01', 'g_m_y_lost_02', 'g_m_y_lost_03',
        'g_m_m_chigoon_01', 'g_m_m_chigoon_02', 's_m_m_bouncer_01', 'a_m_y_methhead_01', 'a_m_m_hillbilly_01',
        'a_m_m_hillbilly_02', 'a_m_m_salton_01', 'g_m_m_armgoon_01', 'g_m_y_armgoon_02', 'g_m_m_armlieut_01',
        'g_m_y_korean_01', 'g_m_y_korean_02', 'g_m_y_korlieut_01', 'mp_m_shopkeep_01', 'a_m_y_skater_01',
        's_m_m_dockwork_01', 'u_f_y_danceburl_01', 'a_m_y_hipster_02', 's_f_y_airhostess_01', 'a_m_m_business_01',
        'g_m_m_chicold_01', 'ig_djsolmike', 's_m_y_ammucity_01' }) do
        nombres[GetHashKey(t)] = t
    end
    local function nombre(m) return nombres[m] or tostring(m) end

    --[[ De quien es cada uno.

         GetEntityScript devuelve el recurso que creo la entidad (en FiveM, el
         nombre del recurso). Los que no son de ningun script son la
         poblacion del propio juego: peatones y conductores, que se crean y se
         borran solos. Los que hay que mirar son los otros. ]]
    local porRecurso = {}
    local muertos = 0
    for _, ped in ipairs(todos) do
        if ped ~= yo and not IsPedAPlayer(ped) then
            local r = GetEntityScript(ped)
            if not r or r == '' then
                r = IsEntityAMissionEntity(ped) and '(script sin nombre)' or '(poblacion del juego)'
            end
            local g = porRecurso[r]
            if not g then
                g = { n = 0, modelos = {}, lejos = 0, muertos = 0 }
                porRecurso[r] = g
            end
            g.n = g.n + 1
            local m = GetEntityModel(ped)
            g.modelos[m] = (g.modelos[m] or 0) + 1
            if #(GetEntityCoords(ped) - aqui) > 150.0 then g.lejos = g.lejos + 1 end
            if IsPedDeadOrDying(ped, true) then g.muertos = g.muertos + 1; muertos = muertos + 1 end
        end
    end

    local lista = {}
    for r, g in pairs(porRecurso) do lista[#lista + 1] = { r = r, g = g } end
    table.sort(lista, function(a, b) return a.g.n > b.g.n end)

    print(('[pedsquest] peds: %d/256   muertos: %d   (sin contar jugadores)'):format(#todos, muertos))
    print('[pedsquest] por recurso ("lejos" = a mas de 150 m de ti: esos no deberian seguir ahi):')
    for _, e in ipairs(lista) do
        local mods = {}
        for m, n in pairs(e.g.modelos) do mods[#mods + 1] = { m = m, n = n } end
        table.sort(mods, function(a, b) return a.n > b.n end)
        local txt = {}
        for i = 1, math.min(4, #mods) do txt[#txt + 1] = mods[i].n .. 'x ' .. nombre(mods[i].m) end
        print(('[pedsquest]   %3d  %-28s lejos %-3d muertos %-3d  %s'):format(
            e.g.n, e.r, e.g.lejos, e.g.muertos, table.concat(txt, ', ')))
    end

    -- /pedsquest <recurso> : donde esta cada uno de ese recurso.
    if args[1] then
        for _, ped in ipairs(todos) do
            if GetEntityScript(ped) == args[1] then
                local c = GetEntityCoords(ped)
                print(('[pedsquest]     %s  %.1f, %.1f, %.1f  (a %.0f m)'):format(
                    nombre(GetEntityModel(ped)), c.x, c.y, c.z, #(c - aqui)))
            end
        end
    end

    local top = lista[1] and (lista[1].r .. ' ' .. lista[1].g.n) or '-'
    exports.origen_notify:Notify({
        title = 'Peds', type = 'info', duration = 8000,
        description = ('%d/256 - el que mas: %s (detalle en F8)'):format(#todos, top),
    })
end, false)
