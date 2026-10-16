-- ========================================
-- CLIENTE: MAIN - ORIGEN RACING
-- ========================================


local circuits = {}
local activeRaces = {} -- { [circuitId] = { raceCount = number } }
local currentRace = nil
local isInRace = false           -- true desde que te unes al lobby
local isActivelyRacing = false   -- true solo cuando la carrera ya empezó
local playerStats = nil
local startPointMarkers = {} -- { [circuitId] = markerId } - Markers de carreras disponibles
local raceStartMarker = nil -- Marker de "¡SALIDA!" cuando el jugador está en carrera
local currentRaceCircuitId = nil -- Para saber qué circuito limpiar al finalizar
local isRacingHubOpen = false
-- Los puntos de los circuitos en el mapa. Aqui arriba: el onResourceStop de
-- abajo los quita, y declarados mas abajo ese handler veia una global vacia.
local circuitBlips = {}

--[[ Preguntar al servidor desde una llamada de la interfaz y contestarle
     SIEMPRE. Con lib.callback a secas, si el callback del servidor fallaba (o
     no existia) la interfaz se quedaba esperando para siempre: botones que
     no hacian nada y pantallas cargando. Lo usan nui_callbacks.lua y
     admin.lua. ]]
local SIN_RESPUESTA = { success = false, message = 'Sin respuesta del servidor' }

function ContestarDesdeServidor(cb, nombre, ...)
    local ok, r = pcall(lib.callback.await, nombre, false, ...)
    if not ok then
        print(('^1[Racing]^7 %s: %s'):format(nombre, tostring(r)))
    end
    if ok and r ~= nil then cb(r) else cb(SIN_RESPUESTA) end
end

-- Función para limpiar TODOS los markers de carreras
local function ClearAllRaceMarkers()
    if raceStartMarker then
        exports.origen_markers:Remove(raceStartMarker)
        raceStartMarker = nil
    end
    if currentRaceCircuitId and startPointMarkers[currentRaceCircuitId] then
        exports.origen_markers:Remove(startPointMarkers[currentRaceCircuitId])
        startPointMarkers[currentRaceCircuitId] = nil
    end
    currentRaceCircuitId = nil
end

-- Evento local para que racing.lua y nui_callbacks.lua puedan limpiar los markers
-- sin acceder directamente a las variables privadas de main.lua
AddEventHandler('racing:cleanupStartMarkers', function()
    ClearAllRaceMarkers()
end)

-- Estado local del hub para evitar trabajo innecesario de state bags globales
AddEventHandler('racing:hub:uiState', function(isOpen)
    isRacingHubOpen = isOpen == true
end)

--[[ Soltar el foco de la NUI sin dejar el panel de crew pintado y sin raton.

     El foco es de TODO el recurso: el hub, los resultados y el panel de crew
     lo comparten. Los cierres del hub y de las carreras soltaban el foco a
     secas, y con el panel de crew abierto este se quedaba en pantalla sin
     raton (y con `panelAbierto` en true, sin volver a abrir).

     - cerrarCrew = false: si el panel de crew sigue abierto, el foco es suyo
       y se deja como esta.
     - cerrarCrew = true (la carrera empieza): se cierra tambien el panel. ]]
function SoltarFocoCarreras(cerrarCrew)
    -- Las teclas antes que el foco (ver foco.lua): el hub recogido las deja
    -- pasar al juego, y el panel de crew tampoco las quiere abiertas.
    SetNuiFocusKeepInput(false)
    if PanelCrewAbierto and PanelCrewAbierto() then
        if cerrarCrew then CerrarPanelCrew(true) end
        return
    end
    SetNuiFocus(false, false)
end

-- Limpiar todos los markers al parar el recurso (reinicio/stop)
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    -- Limpiar marker de espera/salida
    if raceStartMarker then
        exports.origen_markers:Remove(raceStartMarker)
        raceStartMarker = nil
    end

    -- Limpiar todos los markers de punto de partida
    for circuitId, markerId in pairs(startPointMarkers) do
        exports.origen_markers:Remove(markerId)
        startPointMarkers[circuitId] = nil
    end

    -- Limpiar blips del mapa
    for _, blip in pairs(circuitBlips) do
        OrigenMapa.Quitar(blip)
    end
    circuitBlips = {}

    -- Ocultar TextUI si estaba visible
    lib.hideTextUI()

    -- Restaurar HUD y chat por si se estaba corriendo
    TriggerEvent('origen_hud:setRacingMode', false)
    TriggerEvent('origen_chat:setRacingMode', false)
end)

-- ========================================
-- INICIALIZACIÓN
-- ========================================

CreateThread(function()
    Wait(2000)
    -- Jitter por ID de servidor para distribuir la carga al reiniciar el script
    -- Evita que 30+ jugadores hagan queries simultáneas al servidor
    local jitter = (GetPlayerServerId(PlayerId()) % 20) * 200 -- 0-3800ms de jitter
    Wait(jitter)

    -- Cargar circuitos
    LoadCircuits()

    -- Cargar estadísticas del jugador
    LoadPlayerStats()
end)

-- ========================================
-- FUNCIONES CORE
-- ========================================

--- Los circuitos que conoce el cliente (los usa el lobby, client/modos.lua).
function CircuitosCliente() return circuits end

function LoadCircuits()
    lib.callback('racing:getCircuits', false, function(data)
        if data then
            circuits = data
            CreateCircuitBlips()
        end
    end)
end

function LoadPlayerStats()
    lib.callback('racing:getPlayerStats', false, function(stats)
        playerStats = stats
        -- Si el jugador está registrado y los circuitos ya cargaron, crear blips ahora
        -- (pueden haberse saltado si stats llegaron después que los circuitos)
        if stats and stats.username and stats.username ~= '' and #circuits > 0 then
            CreateCircuitBlips()
        end
    end)
end

-- Evento local para refrescar stats tras registrarse en el hub (nui_callbacks.lua lo dispara)
AddEventHandler('racing:reloadPlayerStats', function()
    LoadPlayerStats()
end)

function GetCircuit(circuitId)
    for i = 1, #circuits do
        if circuits[i].id == circuitId then
            return circuits[i]
        end
    end
    return nil
end

-- ========================================
-- BLIPS EN MAPA
-- ========================================

--[[ La tablet de carreras, en el inventario.

     Es lo unico que decide si este jugador ve carreras en el mapa. Se mira la
     cache local del inventario (`hasItem` en minuscula) y no `HasItem`: la de
     mayuscula pregunta al servidor y espera la respuesta, y esto se consulta
     cada pocos segundos.

     Va con pcall porque un export de otro recurso falla en seco si ese recurso
     esta parado, y quedarse sin mapa de carreras es mejor que tirar el hilo. ]]
local function TieneTabletRacing()
    local ok, tiene = pcall(function()
        return exports.origen_inventory:hasItem('tablet_racing')
            or exports.origen_inventory:hasItem('tablet_racingfull')
    end)
    return ok and tiene == true
end

function CreateCircuitBlips()
    -- Limpiar blips existentes
    for _, blip in pairs(circuitBlips) do
        OrigenMapa.Quitar(blip)
    end
    circuitBlips = {}

    --[[ Sin la tablet encima no se ve ninguna carrera en el mapa. Ni los
         circuitos de siempre —esos ya no se marcan nunca— ni las carreras
         puestas: quien no lleva la tablet no se entera de que hay una.

         La limpieza de arriba va ANTES de este corte a proposito: si alguien
         guarda la tablet con carreras en marcha, los puntos que ya tenia se
         van con el mismo recorrido. ]]
    if not TieneTabletRacing() then
        --[[ Y con ellos los carteles del suelo. Esta limpieza es la misma que
             corre mas abajo en cada vuelta; si el corte se llevara tambien la
             limpieza, el cartel de una carrera ya terminada se quedaria
             clavado en el sitio para siempre.

             El del circuito donde se esta corriendo AHORA no se toca: eso es
             una carrera en marcha, no un anuncio. ]]
        for circuitId, markerId in pairs(startPointMarkers) do
            if circuitId ~= currentRaceCircuitId then
                exports.origen_markers:Remove(markerId)
                startPointMarkers[circuitId] = nil
            end
        end

        return
    end

    -- Limpiar markers de punto de partida:
    -- Eliminar todos EXCEPTO el del circuito donde el jugador está corriendo
    -- Y además eliminar el del circuito actual si ya no tiene carreras activas
    local markersRemoved = 0
    for circuitId, markerId in pairs(startPointMarkers) do
        local isCurrentCircuit = (circuitId == currentRaceCircuitId)
        local rData = activeRaces[circuitId]
        local hasActiveRace = rData and rData.raceCount and rData.raceCount > 0
        local timeOk = rData and rData.minTimeRemaining and rData.minTimeRemaining > 0
        local isConquestOnly = rData and rData.conquestOnly

        if not isCurrentCircuit or not hasActiveRace or not timeOk or isConquestOnly then
            exports.origen_markers:Remove(markerId)
            startPointMarkers[circuitId] = nil
            markersRemoved = markersRemoved + 1
        end
    end

    -- Crear blips y markers SOLO para circuitos con carreras activas
    for i = 1, #circuits do
        local circuit = circuits[i]
        local raceData = activeRaces[circuit.id]

        -- Solo crear blip si hay carreras activas en este circuito
        -- Si TODAS son de conquista, no mostramos marker (el blackmarket ya pone el suyo)
        if circuit.blip and circuit.blip.x and raceData and raceData.raceCount > 0 and not raceData.conquestOnly then
            --[[ El circuito, en el mapa. Un punto de origen_map, no un blip
                 del juego. El nombre lleva cuantas carreras hay puestas, que
                 es lo que antes se escribia en el rotulo y los mapas de
                 Leaflet no podian leer. ]]
            local blip = 'circuito_' .. tostring(circuit.id)
            OrigenMapa.Poner(blip, {
                x = circuit.blip.x, y = circuit.blip.y, z = circuit.blip.z,
                cat = 'racing',
                icono = 'bandera',
                nombre = circuit.name .. ' (' .. raceData.raceCount .. ')',
                --[[ Late en los dos mapas. Una carrera puesta dura unos
                     minutos y hay que verla ahora; entre doscientas chinchetas
                     quietas, lo unico que se ve es lo que se mueve. ]]
                pulso = true,
            })

            circuitBlips[circuit.id] = blip

            if circuit.id ~= currentRaceCircuitId then
                local timeRemaining = raceData.minTimeRemaining or 0
                if timeRemaining > 0 then
                    local minutes = math.floor(timeRemaining / 60)
                    local seconds = timeRemaining % 60
                    local timeText = string.format("%02d:%02d", minutes, seconds)

                    local markerId = exports.origen_markers:Create({
                        coords = vector3(circuit.blip.x, circuit.blip.y, circuit.blip.z),
                        type = 'checkpoint',
                        label = circuit.name .. '\n' .. raceData.raceCount .. ' carrera(s) disponible(s)\nTiempo: ' .. timeText,
                        size = 2.0,
                        drawDistance = 100.0,
                        removeDistance = nil
                    })

                    startPointMarkers[circuit.id] = markerId
                end
            end
        end
    end

end

--[[ La tablet entra y sale del inventario sin avisar: se guarda en un cofre,
     se vende, se recupera. Nadie manda un evento por eso, asi que se mira cada
     cinco segundos y solo se vuelve a pintar cuando la respuesta CAMBIA —no en
     cada vuelta—, que es lo que lo hace barato. ]]
CreateThread(function()
    local antes = nil

    while true do
        Wait(5000)

        local ahora = TieneTabletRacing()
        if ahora ~= antes then
            antes = ahora
            CreateCircuitBlips()
        end
    end
end)

function CountTable(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- ========================================
-- THREAD PARA ACTUALIZAR TIEMPO EN MARKERS
-- ========================================

CreateThread(function()
    while true do
        Wait(1000) -- Actualizar cada segundo

        if activeRaces and CountTable(activeRaces) > 0 then

            for circuitId, raceInfo in pairs(activeRaces) do
                -- Actualizar markers de carreras disponibles (cuando NO estás en carrera en ese circuito)
                if startPointMarkers[circuitId] and circuitId ~= currentRaceCircuitId and raceInfo.raceCount and raceInfo.raceCount > 0 and not raceInfo.conquestOnly then
                    if raceInfo.minTimeRemaining and raceInfo.minTimeRemaining > 0 then
                        raceInfo.minTimeRemaining = raceInfo.minTimeRemaining - 1

                        local minutes = math.floor(raceInfo.minTimeRemaining / 60)
                        local seconds = raceInfo.minTimeRemaining % 60
                        local timeText = string.format("%02d:%02d", minutes, seconds)

                        local circuit = nil
                        for i = 1, #circuits do
                            if circuits[i].id == circuitId then
                                circuit = circuits[i]
                                break
                            end
                        end

                        if circuit then
                            exports.origen_markers:Update(startPointMarkers[circuitId], {
                                label = circuit.name .. '\n' .. raceInfo.raceCount .. ' carrera(s) disponible(s)\nTiempo: ' .. timeText
                            })
                        end
                    elseif raceInfo.minTimeRemaining and raceInfo.minTimeRemaining <= 0 then
                        -- Tiempo expirado: eliminar el marker, el servidor limpiará la carrera
                        exports.origen_markers:Remove(startPointMarkers[circuitId])
                        startPointMarkers[circuitId] = nil
                        activeRaces[circuitId] = nil
                    end
                end

                -- Actualizar marker de espera (cuando estás en el lobby esperando)
                -- Solo ANTES de la salida: con la carrera ya en marcha este
                -- cartel no existe (ver racing:convertStartMarkerToFinish).
                if raceStartMarker and currentRaceCircuitId and circuitId == currentRaceCircuitId and isInRace and not isActivelyRacing then
                    if raceInfo.minTimeRemaining and raceInfo.minTimeRemaining > 0 then
                        raceInfo.minTimeRemaining = raceInfo.minTimeRemaining - 1

                        local minutes = math.floor(raceInfo.minTimeRemaining / 60)
                        local seconds = raceInfo.minTimeRemaining % 60
                        local timeText = string.format("%02d:%02d", minutes, seconds)

                        exports.origen_markers:Update(raceStartMarker, {
                            label = 'LA CARRERA COMIENZA EN\n' .. timeText
                        })
                    end
                end
            end
        end
    end
end)

-- ========================================
-- INTERACCIÓN CON CIRCUITOS
-- ========================================

-- Thread para detectar cercanía a circuitos (para abrir Racing Hub)
CreateThread(function()
    local hubUiShown = false
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        if not isActivelyRacing then
            local nearAny = false

            for i = 1, #circuits do
                local circuit = circuits[i]

                if circuit.blip and circuit.blip.x and activeRaces[circuit.id] and activeRaces[circuit.id].raceCount > 0 then
                    local circuitCoords = vector3(circuit.blip.x, circuit.blip.y, circuit.blip.z)
                    local distance = #(playerCoords - circuitCoords)

                    if distance < 15.0 then
                        sleep = 0
                        nearAny = true

                        -- Solo llamar showTextUI cuando el estado cambia (no cada frame)
                        if not hubUiShown then
                            lib.showTextUI('[E] Abrir Hub · ' .. activeRaces[circuit.id].raceCount .. ' carrera' .. (activeRaces[circuit.id].raceCount == 1 and '' or 's') .. ' disponible' .. (activeRaces[circuit.id].raceCount == 1 and '' or 's'))
                            hubUiShown = true
                        end

                        if IsControlJustReleased(0, 38) then -- E
                            lib.hideTextUI()
                            hubUiShown = false
                            OpenRacingHub(circuit.id)
                        end
                    end
                end
            end

            -- Si el jugador no está cerca de ningún circuito activo, ocultar el TextUI
            if not nearAny and hubUiShown then
                lib.hideTextUI()
                hubUiShown = false
            end
        elseif hubUiShown then
            lib.hideTextUI()
            hubUiShown = false
        end

        Wait(sleep)
    end
end)

-- ========================================
-- COMANDOS
-- ========================================

-- Sin comando: el hub se abre con los items tablet_racing / tablet_racingfull.

-- ========================================
-- EVENTOS DEL SERVIDOR
-- ========================================

RegisterNetEvent('racing:updateCircuits', function(newCircuits)
    circuits = newCircuits
    CreateCircuitBlips()
    -- Y el hub, si esta abierto: su lista de circuitos se pide al abrirlo y
    -- un circuito recien creado no salia en «Crear carrera» hasta reabrir.
    SendNUIMessage({ action = 'hub:reloadCircuits' })
end)

RegisterNetEvent('racing:joinedRace', function(raceData)
    currentRace = raceData
    isInRace = true

    -- El evento ya viene desde el servidor, no necesitamos llamarlo aquí
    -- ya que el servidor lo dispara directamente

    lib.notify({
        title = '✅ Unido a Carrera',
        description = 'Te has unido a ' .. (raceData.race_name or 'Carrera'),
        type = 'success'
    })

end)

RegisterNetEvent('racing:leftRace', function()
    local circuitId = currentRace and currentRace.circuit_id or nil

    currentRace = nil
    isInRace = false
    isActivelyRacing = false

    -- Restaurar HUD y chat
    TriggerEvent('origen_hud:setRacingMode', false)
    TriggerEvent('origen_chat:setRacingMode', false)

    -- Limpiar TODOS los markers
    ClearAllRaceMarkers()

    -- Recrear markers normales
    Wait(500)
    CreateCircuitBlips()

    lib.notify({
        title = 'Carrera',
        description = 'Has salido de la carrera',
        type = 'info'
    })
end)

-- 'racing:raceStarted' lo emitia solo server/racing.lua (retirado 18/09/2026).

-- racing:raceFinished manejado más abajo (línea ~652) por el sistema del Racing Hub

-- Evento local cuando termina la carrera (desde racing.lua)
-- AddEventHandler para eventos locales (TriggerEvent); RegisterNetEvent para ambos
AddEventHandler('racing:localRaceFinished', function()
    isInRace = false
    isActivelyRacing = false
    currentRace = nil

    -- Notificar a la NUI que limpie la carrera activa (por si el hub está abierto)
    SendNUIMessage({ action = 'hub:raceFinishedLocally' })

    -- Ocultar TextUI de proximidad inmediatamente para que no reaparezca
    lib.hideTextUI()

    -- Limpiar activeRaces del circuito actual de forma optimista para que la
    -- notificación de proximidad no reaparezca mientras el servidor actualiza
    if currentRaceCircuitId then
        activeRaces[currentRaceCircuitId] = nil
    end
    currentRaceCircuitId = nil

    -- Restaurar HUD y chat
    TriggerEvent('origen_hud:setRacingMode', false)
    TriggerEvent('origen_chat:setRacingMode', false)

    -- Limpiar TODOS los markers de carrera
    ClearAllRaceMarkers()

    -- Esperar a que el servidor actualice las carreras activas
    Wait(1000)
    CreateCircuitBlips()
end)

-- Evento para cambiar marker a "La carrera comienza en..." cuando el jugador se une
RegisterNetEvent('racing:changeMarkerToWaiting', function(circuitId)
    isInRace = true

    if startPointMarkers[circuitId] then
        exports.origen_markers:Remove(startPointMarkers[circuitId])
        startPointMarkers[circuitId] = nil
    end
    if raceStartMarker then
        exports.origen_markers:Remove(raceStartMarker)
        raceStartMarker = nil
    end

    local circuit = nil
    for i = 1, #circuits do
        if circuits[i].id == circuitId then circuit = circuits[i]; break end
    end
    if not circuit or not circuit.blip then return end

    local raceInfo = activeRaces[circuitId]
    local timeRemaining = raceInfo and tonumber(raceInfo.minTimeRemaining) or 0
    if timeRemaining < 0 then timeRemaining = 0 end

    local minutes = math.floor(timeRemaining / 60)
    local seconds = timeRemaining % 60
    local timeText = string.format("%02d:%02d", minutes, seconds)

    -- PASO 5: Crear nuevo marker de espera
    raceStartMarker = exports.origen_markers:Create({
        coords = vector3(circuit.blip.x, circuit.blip.y, circuit.blip.z),
        type = 'checkpoint',
        label = 'LA CARRERA COMIENZA EN\n' .. timeText,
        size = 2.5,
        drawDistance = 150.0,
        removeDistance = nil -- No auto-eliminar
    })

    currentRaceCircuitId = circuitId
end)

--[[ La carrera ARRANCA (lo lanza racing.lua al acabar la cuenta atras).

     El cartel de «La carrera comienza en…» se quita y no se pone nada en su
     sitio. Antes se cambiaba por otro de «¡Salida!» en la linea de salida, y
     pasaban dos cosas:

     - el hilo que cada segundo refresca la cuenta atras seguia vivo, veia
       que habia un cartel y le volvia a escribir «La carrera comienza en
       00:54» encima, con la carrera ya empezada —sobre todo cuando el
       anfitrion la lanzaba antes de que acabase la espera—;
     - ese cartel caia justo donde esta el primer checkpoint y se montaba
       con el suyo.

     La salida ya la dice la cuenta atras, en grande y en el centro de la
     pantalla. Y aqui es donde se apunta que se esta corriendo de verdad:
     `isActivelyRacing` solo se ponia a false, nunca a true, asi que lo que
     dependia de ella —no abrir la tablet en carrera— no se cumplia. ]]
RegisterNetEvent('racing:convertStartMarkerToFinish', function(circuitId)
    isActivelyRacing = true

    if raceStartMarker then
        exports.origen_markers:Remove(raceStartMarker)
        raceStartMarker = nil
    end
    if startPointMarkers[circuitId] then
        exports.origen_markers:Remove(startPointMarkers[circuitId])
        startPointMarkers[circuitId] = nil
    end

    currentRaceCircuitId = circuitId
end)

-- ========================================
-- FUNCIONES DE UI (placeholder)
-- ========================================

-- ── Tablet animation ──────────────────────────────────────────────
local tabletProp      = nil
local TABLET_ANIM_DICT  = 'amb@code_human_in_bus_passenger_idles@female@tablet@idle_a'
local TABLET_ANIM_NAME  = 'idle_a'
local TABLET_PROP_MODEL = 'prop_cs_tablet'

--- Que el hub sigue pedido. La tablet se pone en un hilo que puede esperar
--- hasta 3 s al diccionario: si el hub se cierra antes, la tablet no se pone.
local hubPedido = false

function CloseTabletAnimation()
    hubPedido = false
    if tabletProp ~= nil then
        ClearPedSecondaryTask(PlayerPedId())
        DetachEntity(tabletProp, false, false)
        DeleteEntity(tabletProp)
        tabletProp = nil
    end
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if tabletProp ~= nil then
        DeleteEntity(tabletProp)
        tabletProp = nil
    end
    -- Parar el recurso con el hub (o cualquier pantalla suya) delante dejaba
    -- el raton preso. Las teclas antes que el foco (ver foco.lua).
    SetNuiFocusKeepInput(false)
    SetNuiFocus(false, false)
end)

--[[ El hub es un panel del riel, como el de crew: lleva la misma barra del
     canto, que se la pide al inventario, y desde ella se salta a los demas
     paneles. Ver la skill origen-riel. ]]
local function RielDelHub()
    if GetResourceState('origen_inventory') ~= 'started' then return nil end
    local ok, riel = pcall(function()
        return exports['origen_inventory']:GetRiel('racing')
    end)
    if not ok then return nil end
    return riel
end

--[[ Con el hub RECOGIDO se puede seguir andando y conduciendo, como con el
     inventario: el juego sigue recibiendo teclas (SetNuiFocusKeepInput) y aqui
     se apaga a mano lo que no toca —la camara, que se iria con el raton, los
     golpes y disparos, que saltarian con cada clic, y el menu de pausa, que
     se abriria con el Escape que cierra el hub—.

     Lo decide la interfaz, que es quien sabe si el panel esta en grande o si
     se esta escribiendo en un campo: en esos dos casos las teclas son suyas. ]]
local hubConTeclas = false

local APAGADAS_CON_HUB = {
    1, 2, 106,                          -- camara con el raton
    24, 25, 257, 68, 69, 70, 91, 92,    -- disparar y apuntar, a pie y en coche
    140, 141, 142, 143, 263, 264,       -- cuerpo a cuerpo
    199, 200,                           -- pausa
}

local function TeclasDelHub(alJuego)
    alJuego = alJuego == true and hubPedido
    SetNuiFocusKeepInput(alJuego)

    if hubConTeclas == alJuego then return end
    hubConTeclas = alJuego
    if not alJuego then return end

    CreateThread(function()
        while hubConTeclas and hubPedido do
            DisablePlayerFiring(PlayerId(), true)
            for i = 1, #APAGADAS_CON_HUB do
                DisableControlAction(0, APAGADAS_CON_HUB[i], true)
            end
            Wait(0)
        end
        hubConTeclas = false
    end)
end

RegisterNUICallback('hub:teclas', function(data, cb)
    cb('ok')
    if not hubPedido then return end
    TeclasDelHub(data and data.juego == true)
end)

local function MostrarHub(fullAccess, circuitId)
    SetNuiFocus(true, true)
    -- Cerradas hasta que la interfaz diga que el panel esta recogido.
    hubConTeclas = false
    SetNuiFocusKeepInput(false)
    SendNUIMessage({
        action = 'openRacingHub',
        data = {
            hasFullAccess = fullAccess,
            circuits = circuits,
            selectedCircuit = circuitId,
            playerStats = playerStats,
            riel = RielDelHub(),
        }
    })
end

--[[ Saltar a otro panel desde el riel del hub. El foco se suelta antes que
     nada y el destino se abre a los 200 ms, con la columna de aqui a medio
     recoger; el `true` es el aviso de relevo (la barra no se mueve). ]]
RegisterNUICallback('hub:irDelRiel', function(data, cb)
    cb('ok')

    CloseTabletAnimation()
    SetNuiFocusKeepInput(false)
    SetNuiFocus(false, false)

    if GetResourceState('origen_inventory') ~= 'started' then return end

    local destino = data and data.id
    if not destino then return end

    CreateThread(function()
        Wait(200)
        if data.tipo == 'acceso' then
            exports['origen_inventory']:AbrirAcceso(destino, true)
        else
            exports['origen_inventory']:AbrirEnPestana(destino, true)
        end
    end)
end)

-- fullAccess: true = puede crear carreras, false = solo participar
-- Si no se pasa fullAccess, se consulta al servidor (compatibilidad hacia atrás)
function OpenRacingHub(circuitId, fullAccess)
    -- Grabando un circuito el recurso no puede tener el raton: el panel
    -- saldria encima de la grabacion y se soltaria al acabarla.
    if GrabandoCircuito and GrabandoCircuito() then
        lib.notify({ title = 'Racing', description = 'Termina o cancela la grabación del circuito primero', type = 'error' })
        return
    end

    hubPedido = true

    -- Lanzar animación + prop de tablet en un hilo separado
    Citizen.CreateThread(function()
        if not IsPedInAnyVehicle(PlayerPedId()) then
            RequestAnimDict(TABLET_ANIM_DICT)
            local t = 0
            while not HasAnimDictLoaded(TABLET_ANIM_DICT) and t < 30 do
                Wait(100)
                t = t + 1
            end
            -- Si el hub se cerro mientras cargaba, ni animacion ni tablet: se
            -- quedaba en la mano sin nada en pantalla.
            if hubPedido and HasAnimDictLoaded(TABLET_ANIM_DICT) then
                TaskPlayAnim(PlayerPedId(), TABLET_ANIM_DICT, TABLET_ANIM_NAME, 2.0, 3.0, -1, 51, 0, false, false, false)
                if tabletProp == nil then
                    --[[ Local, no en red: es atrezo de la mano. En red cada
                         apertura creaba un objeto en el servidor, y si el
                         recurso se paraba con la tablet en la mano se quedaba
                         flotando para todos. Los demas ven la animacion. ]]
                    local modelo = GetHashKey(TABLET_PROP_MODEL)
                    lib.requestModel(modelo, 3000)
                    tabletProp = CreateObject(modelo, 0.0, 0.0, 0.0, false, true, false)
                    SetModelAsNoLongerNeeded(modelo)
                    AttachEntityToEntity(tabletProp, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 28422), -0.05, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, 0, true, true, true)
                end
            end
        end
    end)

    if fullAccess ~= nil then
        -- Acceso ya conocido (viene del item), abrir directamente
        MostrarHub(fullAccess, circuitId)
    else
        -- Sin item: consultar al servidor. Si no contesta, fuera la tablet:
        -- se quedaba en la mano sin nada en pantalla.
        CreateThread(function()
            local ok, response = pcall(lib.callback.await, 'racing:hub:getAccessLevel', false)
            if not ok or not hubPedido then
                CloseTabletAnimation()
                if not ok then
                    lib.notify({ title = 'Racing', description = 'No se ha podido abrir la tablet', type = 'error' })
                end
                return
            end
            MostrarHub(response and response.hasFullAccess or false, circuitId)
        end)
    end
end

-- ========================================
-- EXPORTS
-- ========================================

exports('GetCircuits', function() return circuits end)
exports('GetCurrentRace', function() return currentRace end)
exports('IsInRace', function() return isInRace end)

-- Export para abrir Racing Hub desde item (compatibilidad)
--[[ La tablet se abre tambien corriendo: es donde esta «Abandonar». Antes se
     bloqueaba y quien tenia que dejar la carrera no podia. Con la columna
     recogida se sigue conduciendo (hub:teclas). ]]
exports('OpenRacingHubFromItem', function()
    OpenRacingHub(nil, true)
end)

-- tablet_racing: solo participar (no crear carreras)
exports('UseTabletRacing', function()
    OpenRacingHub(nil, false)
end)

-- tablet_racingfull: participar Y crear carreras
exports('UseTabletRacingFull', function()
    OpenRacingHub(nil, true)
end)

-- Evento del servidor (legado, fullAccess determina el tipo)
RegisterNetEvent('racing:openHub', function(fullAccess)
    OpenRacingHub(nil, fullAccess ~= false)
end)

-- Los comandos /crew y /createcrew están registrados en client/crews.lua

-- ========================================
-- NOTA: Los comandos /racing han sido eliminados
-- Ahora se accede al Racing Hub usando los items:
-- - tablet_racing (acceso lite)
-- - tablet_racingfull (acceso full)
-- ========================================

-- ========================================
-- EVENTOS DE RACING HUB
-- ========================================

--[[ Si el vigilante comun (@origen_map/shared/foco.lua) suelta el raton a la
     fuerza con el hub delante, el hub se va con el: si no, quedaba pintado sin
     raton, con la tablet en la mano. La pagina solo cierra el hub si esta
     abierto, y la tablet solo se quita si estaba puesta. ]]
OrigenFoco.AlSoltar(function()
    isRacingHubOpen = false
    CloseTabletAnimation()
    SendNUIMessage({ action = 'closeRacingHub' })
end)

-- Recibir invitación a carrera
RegisterNetEvent('racing:receiveInvitation', function(data)
    SendNUIMessage({
        action = 'showInvitation',
        data = data
    })
end)

-- Carrera iniciando (countdown)
RegisterNetEvent('racing:raceStarting', function(data)
    CloseTabletAnimation()
    SendNUIMessage({
        action = 'closeRacingHub'
    })
    -- La carrera empieza: fuera tambien el panel de crew, que hay que conducir.
    SoltarFocoCarreras(true)
end)

-- (Aqui habia un 'racing:raceFinished' de cliente que cogia el foco con los
-- resultados; el servidor nunca lo lanza al cliente. Los resultados salen
-- por racing:playerFinished / racing:showResults, sin foco.)

-- Eventos push del servidor para actualizar Racing Hub en tiempo real
RegisterNetEvent('racing:hub:raceCreated', function(data)
    SendNUIMessage({
        action = 'raceCreated',
        data = data
    })
end)

RegisterNetEvent('racing:hub:raceUpdated', function(data)
    SendNUIMessage({
        action = 'raceUpdated',
        data = data
    })
end)

RegisterNetEvent('racing:hub:raceRemoved', function(data)
    SendNUIMessage({
        action = 'raceRemoved',
        data = data
    })
end)

-- Carrera cancelada
RegisterNetEvent('racing:raceCancelled', function(data)

    -- Ocultar el TextUI de "Abrir Carreras" si estaba visible
    lib.hideTextUI()

    -- Limpiar blip de proximidad (GPS morado)
    TriggerEvent('racing:clearProximityMarkers')

    -- Limpiar markers en mundo (marker de countdown y de punto de partida)
    ClearAllRaceMarkers()

    -- Resetear estado del jugador
    isInRace = false
    isActivelyRacing = false
    currentRaceCircuitId = nil

    -- Restaurar HUD y chat
    TriggerEvent('origen_hud:setRacingMode', false)
    TriggerEvent('origen_chat:setRacingMode', false)

    -- Refresca blips/markers según carreras que queden activas
    CreateCircuitBlips()

    -- Notificar con el sistema estándar
    lib.notify({ title = 'Carrera', description = data.reason or 'Carrera cancelada', type = 'error', duration = 5000 })

    -- Notificar al store de Racing Hub para que limpie el estado
    SendNUIMessage({
        action = 'racingHub:raceCancelled',
        data = { raceId = data.raceId }
    })
end)

-- ✨ STATE BAG: Escuchar cambios en GlobalState.activeRaces
AddStateBagChangeHandler('activeRaces', 'global', function(bagName, key, value)
    activeRaces = value or {}
    if CountTable(activeRaces) == 0 and not isInRace then
        ClearAllRaceMarkers()
    end
    CreateCircuitBlips()
end)

-- ✨ STATE BAG: Escuchar cambios en Player state (raceData y isReady)
-- Esto se dispara cuando cualquier jugador cambia su estado
AddStateBagChangeHandler('raceData', nil, function(bagName, key, value)
    if not isRacingHubOpen then return end

    -- bagName = "player:X" donde X es el server ID
    -- Usar paréntesis para capturar solo el primer valor de gsub
    local playerId = tonumber((bagName:gsub('player:', '')))
    if not playerId then return end

    local localState = LocalPlayer.state
    if localState.raceData and value and localState.raceData.raceId == value.raceId then
        SendNUIMessage({
            action = 'racing:hub:lobbyPlayerJoined',
            data = {
                playerId = playerId,
                raceId = value.raceId
            }
        })
    end
end)

AddStateBagChangeHandler('isReady', nil, function(bagName, key, value)
    if not isRacingHubOpen then return end

    local playerId = tonumber((bagName:gsub('player:', '')))
    if not playerId then return end
    SendNUIMessage({
        action = 'racing:hub:lobbyPlayerReady',
        data = { playerId = playerId, isReady = value }
    })
end)

-- Cuando el servidor nos auto-inscribe en una carrera de conquista,
-- decirle al Racing Hub que recargue currentRace (la caché del servidor ya fue limpiada)
RegisterNetEvent('racing:conquest:autoJoined', function(data)
    SendNUIMessage({
        action = 'racing:hub:reloadCurrentRace',
        data   = { raceId = data and data.raceId or nil }
    })
end)
