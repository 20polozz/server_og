-- ========================================
-- CLIENTE: NUI CALLBACKS
-- ========================================

-- Callback para cerrar NUI general
RegisterNUICallback('closeUI', function(data, cb)
    CloseTabletAnimation()
    -- Sin llevarse el foco del panel de crew si sigue abierto (main.lua).
    SoltarFocoCarreras(false)
    cb('ok')
end)

--[[ Aqui habia ocho envoltorios del sistema de carreras anterior al hub
     (getActiveRaces, createRace, joinRace, leaveRace, startRace, getRankings,
     getPlayerStats, getCircuitDetails). La interfaz no llamaba a ninguno.
     Retirados el 18/09/2026 junto con server/racing.lua. ]]

--[[ Los avisos de la interfaz. Ninguna pantalla de este recurso pinta ya su
     propia tarjeta: todo sale por origen_notify, arriba en el medio, como en
     el resto del servidor (ui-vue/src/utils/avisar.ts). ]]
local TIPOS_DE_AVISO = { success = true, error = true, info = true, warning = true }

RegisterNUICallback('racing:avisar', function(data, cb)
    cb('ok')
    if type(data) ~= 'table' then return end

    local titulo = type(data.titulo) == 'string' and data.titulo or 'Racing'
    local texto = type(data.descripcion) == 'string' and data.descripcion or ''

    lib.notify({
        title = titulo,
        -- Con una sola frase, la frase es el cuerpo: un aviso sin cuerpo no sale.
        description = texto ~= '' and texto or titulo,
        type = TIPOS_DE_AVISO[data.tipo] and data.tipo or 'info',
        duration = tonumber(data.duracion) or 5000,
    })
end)

-- ========================================
-- CREW CALLBACKS
-- ========================================

--- Cerrar desde la propia interfaz (ESC o el aspa). Pasa por CerrarPanelCrew
--- —definida en client/crews.lua— porque ahi es donde se lleva la cuenta de si
--- el panel esta abierto; soltando el foco a secas, esa cuenta se quedaba en
--- "abierto" y el boton del riel dejaba de responder a partir de la segunda vez.
RegisterNUICallback('closeCrewPanel', function(data, cb)
    if CerrarPanelCrew then
        CerrarPanelCrew(false)
    else
        SetNuiFocus(false, false)
    end
    cb('ok')
end)

RegisterNUICallback('racing:crews:checkMyPermission', function(data, cb)
    local success, response = pcall(function()
        return lib.callback.await('racing:crews:checkMyPermission', false)
    end)
    if not success then
        cb({ hasPermission = false })
    else
        cb(response or { hasPermission = false })
    end
end)

RegisterNUICallback('racing:crews:getMyCrew', function(data, cb)
    local success, response = pcall(function()
        return lib.callback.await('racing:crews:getMyCrew', false)
    end)

    if not success then
        cb({ success = false, message = 'Error al obtener crew' })
        return
    end

    cb(response or { success = false, message = 'No se pudo obtener crew' })
end)

RegisterNUICallback('racing:crews:getAll', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:crews:getAll')
end)

-- Guerra de territorios y circuito de casa (server/guerras.lua)
RegisterNUICallback('racing:guerra:estado', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:guerra:estado', data)
end)
RegisterNUICallback('racing:proponer:panel', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:proponer:panel', data)
end)
RegisterNUICallback('racing:logros:lista', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:logros:lista', data)
end)

-- La guía «Cómo se juega» (server/logros.lua).
RegisterNUICallback('racing:guia', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:guia', data)
end)
RegisterNUICallback('racing:piloto:extra', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:piloto:extra', data)
end)
RegisterNUICallback('racing:crews:pase', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:crews:pase', data)
end)
RegisterNUICallback('racing:crews:pase:reclamar', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:crews:pase:reclamar', data)
end)
RegisterNUICallback('racing:crews:elegirCasa', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:crews:elegirCasa', data)
end)

RegisterNUICallback('racing:crews:invite', function(data, cb)

    local success, response = pcall(function()
        return lib.callback.await('racing:crews:invite', false, data)
    end)

    if not success then
        print('^1[Crews Client]^7 ERROR al invitar:', response)
        lib.notify({ title = 'Crew', description = 'Error de conexión al invitar', type = 'error', duration = 5000 })
        cb({ success = false, message = 'Error al invitar' })
        return
    end


    if response and response.success then
        lib.notify({
            title = 'Crew',
            description = 'Invitación enviada correctamente',
            type = 'success',
            duration = 4000,
            icon = 'lucide:user-plus'
        })
    else
        lib.notify({
            title = 'Crew',
            description = (response and response.message) or 'No se pudo enviar la invitación',
            type = 'error',
            duration = 5000
        })
    end

    cb(response or { success = false, message = 'Error al invitar' })
end)

RegisterNUICallback('racing:crews:kick', function(data, cb)

    local success, response = pcall(function()
        return lib.callback.await('racing:crews:kick', false, data)
    end)

    if not success then
        print('^1[Crews Client]^7 ERROR al expulsar:', response)
        cb({ success = false, message = 'Error al expulsar' })
        return
    end

    cb(response or { success = false, message = 'Error al expulsar' })
end)

RegisterNUICallback('racing:crews:changeRank', function(data, cb)

    local success, response = pcall(function()
        return lib.callback.await('racing:crews:changeRank', false, data)
    end)

    if not success then
        print('^1[Crews Client]^7 ERROR al cambiar rango:', response)
        cb({ success = false, message = 'Error de conexión' })
        return
    end

    cb(response or { success = false, message = 'Error al cambiar rango' })
end)


RegisterNUICallback('racing:crews:leave', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:crews:leave')
end)

RegisterNUICallback('racing:crews:update', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:crews:update', data)
end)

--[[ El escudo de la crew.

     La interfaz manda la imagen ya leida en base64 —en Lua no hay acceso al
     disco del jugador— y de la NUI hasta aqui no hay red, asi que da igual lo
     que pese. La pared esta en el salto siguiente: una imagen entera no cabe
     en un evento de red y no falla, se pierde. Por eso los bytes van por
     origen_uploader, que los manda en un envio latente y los deja esperando en
     el servidor; lo que viaja en la llamada es solo el resguardo. ]]
RegisterNUICallback('racing:crews:uploadLogo', function(data, cb)
    if GetResourceState('origen_uploader') ~= 'started' then
        cb({ success = false, message = 'El servicio de imágenes no está disponible.' })
        return
    end

    local resguardo, motivo = exports['origen_uploader']:PrepararSubida(
        data and data.nombre, data and data.base64)

    if not resguardo then
        cb({ success = false, message = motivo or 'No se pudo enviar la imagen.' })
        return
    end

    ContestarDesdeServidor(cb, 'racing:crews:uploadLogo', { ticket = resguardo, nombre = data and data.nombre })
end)

RegisterNUICallback('racing:crews:disband', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:crews:disband')
end)

RegisterNUICallback('racing:crews:acceptInvite', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:crews:acceptInvite', data and data.inviteId)
end)

RegisterNUICallback('racing:crews:rejectInvite', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:crews:rejectInvite', data and data.inviteId)
end)

-- ========================================
-- TERRITORY CALLBACKS
-- ========================================

RegisterNUICallback('racing:territories:getAll', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:territories:getAll', data or {})
end)

--[[ El catalogo de circuitos con su territorio y su record.

     Faltaba el puente: el callback de servidor existe desde siempre en
     server/territories.lua, pero sin este RegisterNUICallback la interfaz
     llamaba a `racing:circuits:getAll` y no contestaba nadie, asi que la
     pestaña de circuitos salia vacia y sin dar error. ]]
RegisterNUICallback('racing:circuits:getAll', function(data, cb)
    local ok, response = pcall(lib.callback.await, 'racing:circuits:getAll', false)
    cb(ok and response or { success = false, circuits = {} })
end)

RegisterNUICallback('racing:territories:get', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:territories:get', data and data.territoryId)
end)

RegisterNUICallback('racing:territories:startContest', function(data, cb)
    local success, response = pcall(function()
        return lib.callback.await('racing:territories:startContest', false, data)
    end)
    if not success then
        cb({ success = false, message = 'Error al iniciar disputa' })
        return
    end
    cb(response or { success = false, message = 'Sin respuesta del servidor' })
end)

RegisterNUICallback('racing:territories:release', function(data, cb)
    local success, response = pcall(function()
        return lib.callback.await('racing:territories:release', false, data)
    end)
    if not success then
        lib.notify({ title = 'Territorio', description = 'Error al liberar el territorio', type = 'error', duration = 4000 })
        cb({ success = false, message = 'Error de conexión' })
        return
    end
    if response and response.success then
        lib.notify({ title = 'Territorio', description = 'Territorio liberado correctamente', type = 'success', duration = 4000 })
    else
        lib.notify({ title = 'Territorio', description = (response and response.message) or 'No se pudo liberar', type = 'error', duration = 4000 })
    end
    cb(response or { success = false })
end)

RegisterNUICallback('racing:territories:create', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:territories:create', data)
end)

RegisterNUICallback('racing:territories:update', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:territories:update', data)
end)

RegisterNUICallback('racing:admin:deleteTerritory', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:admin:deleteTerritory', data)
end)

-- ========================================
-- ADMIN CREW CALLBACKS
-- ========================================

RegisterNUICallback('racing:admin:getAllCrews', function(data, cb)

    local success, response = pcall(function()
        return lib.callback.await('racing:admin:getAllCrews', false)
    end)

    if not success then
        print('^1[Crews Client]^7 ERROR en callback del cliente:', response)
        cb({ success = true, crews = {} })
        return
    end

    cb(response or { success = true, crews = {} })
end)

-- Los puntos de un circuito, para dibujarlo en el «Mapa de circuitos» del
-- panel de admin. La NUI lo pedia y aqui no habia quien contestara: al elegir
-- un circuito el mapa se quedaba vacio. El permiso lo mira el servidor.
RegisterNUICallback('racing:admin:getCircuitCheckpoints', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:admin:getCircuitCheckpoints', data)
end)

RegisterNUICallback('racing:admin:deleteCrew', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:admin:deleteCrew', data)
end)

-- El territorio de una crew (solo para su casa): server/crew_territorio.lua.
-- El permiso lo mira el servidor.
RegisterNUICallback('racing:admin:crewTerritorio:get', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:admin:crewTerritorio:get', data)
end)

RegisterNUICallback('racing:admin:crewTerritorio:guardar', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:admin:crewTerritorio:guardar', data)
end)

RegisterNUICallback('racing:admin:crewTerritorio:borrar', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:admin:crewTerritorio:borrar', data)
end)

RegisterNUICallback('racing:admin:grantCrewPermission', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:admin:grantCrewPermission', data)
end)

RegisterNUICallback('racing:admin:getCrewPermissions', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:admin:getCrewPermissions')
end)

RegisterNUICallback('racing:admin:revokeCrewPermission', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:admin:revokeCrewPermission', data)
end)

RegisterNUICallback('racing:admin:launchTerritoryContest', function(data, cb)
    local success, response = pcall(function()
        return lib.callback.await('racing:admin:launchTerritoryContest', false, data)
    end)

    if not success then
        cb({ success = false, message = 'Error al lanzar la disputa' })
        return
    end

    cb(response or { success = false, message = 'Sin respuesta del servidor' })
end)

RegisterNUICallback('racing:crews:createWithPermission', function(data, cb)

    local success, response = pcall(function()
        return lib.callback.await('racing:crews:createWithPermission', false, data)
    end)

    if not success then
        print('^1[Crews Client]^7 ERROR al crear crew:', response)
        cb({ success = false, message = 'Error al crear crew' })
        return
    end

    cb(response or { success = false, message = 'Error al crear crew' })
end)

RegisterNUICallback('racing:crews:getNearbyPlayers', function(data, cb)

    local success, response = pcall(function()
        return lib.callback.await('racing:crews:getNearbyPlayers', false)
    end)

    if not success then
        print('^1[Crews Client]^7 ERROR:', response)
        cb({ success = true, players = {} })
        return
    end

    cb(response or { success = true, players = {} })
end)

-- ======================
-- CALLBACKS DE DISPUTAS
-- ======================

RegisterNUICallback('racing:crews:getAvailableCrews', function(data, cb)

    local success, response = pcall(function()
        return lib.callback.await('racing:crews:getAvailableCrews', false)
    end)

    if not success then
        print('^1[Crews Client]^7 ERROR:', response)
        cb({ success = false, crews = {} })
        return
    end

    cb(response or { success = false, crews = {} })
end)

RegisterNUICallback('racing:disputes:getAll', function(data, cb)

    local success, response = pcall(function()
        return lib.callback.await('racing:disputes:getAll', false)
    end)

    if not success then
        print('^1[Disputes Client]^7 ERROR:', response)
        cb({ success = false, disputes = {} })
        return
    end

    cb(response or { success = false, disputes = {} })
end)

RegisterNUICallback('racing:disputes:create', function(data, cb)

    local success, response = pcall(function()
        return lib.callback.await('racing:disputes:create', false, data)
    end)

    if not success then
        print('^1[Disputes Client]^7 ERROR:', response)
        cb({ success = false, message = 'Error al crear disputa' })
        return
    end

    cb(response or { success = false })
end)

RegisterNUICallback('racing:disputes:accept', function(data, cb)

    local success, response = pcall(function()
        return lib.callback.await('racing:disputes:accept', false, data)
    end)

    if not success then
        print('^1[Disputes Client]^7 ERROR:', response)
        cb({ success = false })
        return
    end

    cb(response or { success = false })
end)

RegisterNUICallback('racing:disputes:reject', function(data, cb)

    local success, response = pcall(function()
        return lib.callback.await('racing:disputes:reject', false, data)
    end)

    if not success then
        print('^1[Disputes Client]^7 ERROR:', response)
        cb({ success = false })
        return
    end

    cb(response or { success = false })
end)

RegisterNUICallback('racing:disputes:cancel', function(data, cb)

    local success, response = pcall(function()
        return lib.callback.await('racing:disputes:cancel', false, data)
    end)

    if not success then
        print('^1[Disputes Client]^7 ERROR:', response)
        cb({ success = false })
        return
    end

    cb(response or { success = false })
end)

RegisterNUICallback('racing:disputes:join', function(data, cb)

    local success, response = pcall(function()
        return lib.callback.await('racing:disputes:join', false, data)
    end)

    if not success then
        print('^1[Disputes Client]^7 ERROR:', response)
        cb({ success = false })
        return
    end

    cb(response or { success = false })
end)

-- ========================================
-- STREAMING CALLBACKS
-- ========================================

RegisterNUICallback('racing:streaming:getActiveRaces', function(data, cb)

    local success, response = pcall(function()
        return lib.callback.await('racing:streaming:getActiveRaces', false, data)
    end)

    if not success then
        print('^1[Streaming Client]^7 ERROR:', response)
        cb({ success = false, races = {} })
        return
    end

    cb(response or { success = false, races = {} })
end)

RegisterNUICallback('racing:streaming:startStream', function(data, cb)

    local success, response = pcall(function()
        return lib.callback.await('racing:streaming:startStream', false, data)
    end)

    if not success then
        print('^1[Streaming Client]^7 ERROR:', response)
        cb({ success = false })
        return
    end

    -- Pasar la lista de participantes al sistema de streaming de Lua
    -- para que pueda navegar entre corredores con el teclado
    if response and response.success and response.race and response.race.participants then
        TriggerEvent('racing:streaming:setParticipants', response.race.participants)
    end

    cb(response or { success = false })
end)

RegisterNUICallback('racing:streaming:stopStream', function(data, cb)
    TriggerEvent('racing:streaming:stopCamera')
    cb({ success = true })
end)

RegisterNUICallback('racing:streaming:switchCamera', function(data, cb)
    TriggerEvent('racing:streaming:switchToPlayer', data.targetServerId)
    cb({ success = true })
end)

RegisterNUICallback('racing:streaming:changeCameraMode', function(data, cb)
    TriggerEvent('racing:streaming:changeCameraMode', data.mode)
    cb({ success = true })
end)

-- ========================================
-- STATS CALLBACKS
-- ========================================

--[[ Los puentes que faltaban. La interfaz pedia estas cuatro cosas y el
     servidor sabia contestarlas, pero no habia nadie en medio: las pestañas
     «Por circuito», «Por categoria» e «Historial» de las estadisticas salian
     siempre vacias, y editar un territorio en el admin cargaba datos a
     medias. ]]
for _, nombre in ipairs({
    'racing:stats:getMyCircuitStats',
    'racing:stats:getMyCategoryStats',
    'racing:stats:getMyHistory',
    'racing:stats:getCircuitTimes',
    'racing:territories:getOneFull',
}) do
    RegisterNUICallback(nombre, function(data, cb)
        local ok, respuesta = pcall(function()
            return lib.callback.await(nombre, false, data)
        end)
        cb(ok and respuesta or { success = false })
    end)
end

RegisterNUICallback('racing:stats:getPlayerStats', function(data, cb)
    local success, response = pcall(function()
        return lib.callback.await('racing:stats:getPlayerStats', false, data)
    end)

    if not success then
        print('^1[Stats Client]^7 ERROR:', response)
        cb({ success = false })
        return
    end

    cb(response or { success = false })
end)

RegisterNUICallback('racing:stats:getCrewStats', function(data, cb)
    local success, response = pcall(function()
        return lib.callback.await('racing:stats:getCrewStats', false, data)
    end)

    if not success then
        print('^1[Stats Client]^7 ERROR:', response)
        cb({ success = false })
        return
    end

    cb(response or { success = false })
end)

RegisterNUICallback('racing:stats:getCrewRankings', function(data, cb)
    local success, response = pcall(function()
        return lib.callback.await('racing:stats:getCrewRankings', false, data)
    end)

    if not success then
        print('^1[Stats Client]^7 ERROR:', response)
        cb({ success = false, rankings = {} })
        return
    end

    cb(response or { success = false, rankings = {} })
end)

RegisterNUICallback('racing:stats:getRacerRankings', function(data, cb)
    local success, response = pcall(function()
        return lib.callback.await('racing:stats:getRacerRankings', false, data)
    end)

    if not success then
        print('^1[Stats Client]^7 ERROR:', response)
        cb({ success = false, rankings = {} })
        return
    end

    cb(response or { success = false, rankings = {} })
end)

RegisterNUICallback('racing:stats:getVehicleRankings', function(data, cb)
    local success, response = pcall(function()
        return lib.callback.await('racing:stats:getVehicleRankings', false, data)
    end)

    if not success then
        print('^1[Stats Client]^7 ERROR:', response)
        cb({ success = false, rankings = {} })
        return
    end

    cb(response or { success = false, rankings = {} })
end)

RegisterNUICallback('racing:stats:getCircuitRankings', function(data, cb)
    local success, response = pcall(function()
        return lib.callback.await('racing:stats:getCircuitRankings', false, data)
    end)

    if not success then
        print('^1[Stats Client]^7 ERROR:', response)
        cb({ success = false, rankings = {} })
        return
    end

    cb(response or { success = false, rankings = {} })
end)

RegisterNUICallback('racing:stats:getHallOfFame', function(data, cb)
    local success, response = pcall(function()
        return lib.callback.await('racing:stats:getHallOfFame', false, data)
    end)

    if not success then
        print('^1[Stats Client]^7 ERROR:', response)
        cb({ success = false })
        return
    end

    cb(response or { success = false })
end)

-- ========================================
-- RACING HUB CALLBACKS
-- ========================================

-- Notificar al servidor que el jugador abrió el hub
RegisterNUICallback('racing:hub:opened', function(data, cb)
    TriggerEvent('racing:hub:uiState', true)
    TriggerServerEvent('racing:hub:playerOpened')
    cb({ success = true })
end)

-- Notificar al servidor que el jugador cerró el hub
RegisterNUICallback('racing:hub:closed', function(data, cb)
    TriggerEvent('racing:hub:uiState', false)
    TriggerServerEvent('racing:hub:playerClosed')
    cb({ success = true })
end)

RegisterNUICallback('racing:hub:getRaces', function(data, cb)
    -- Versión async para evitar que el NUI quede colgado si el servidor tarda
    local responded = false
    local function safeCb(result)
        if not responded then
            responded = true
            cb(result)
        end
    end

    -- Timeout de seguridad: 8 segundos máximo
    SetTimeout(8000, function()
        safeCb({ success = false, races = {} })
    end)

    lib.callback('racing:hub:getRaces', false, function(response)
        safeCb(response or { success = false, races = {} })
    end, data)
end)

RegisterNUICallback('racing:hub:getCircuits', function(data, cb)
    local responded = false
    local function safeCb(result)
        if not responded then responded = true cb(result) end
    end
    SetTimeout(8000, function() safeCb({ success = false, circuits = {} }) end)
    lib.callback('racing:hub:getCircuits', false, function(response)
        safeCb(response or { success = false, circuits = {} })
    end, data)
end)

RegisterNUICallback('racing:hub:getCurrentRace', function(data, cb)
    local responded = false
    local function safeCb(result)
        if not responded then responded = true cb(result) end
    end
    SetTimeout(8000, function() safeCb({ success = false, race = nil }) end)
    lib.callback('racing:hub:getCurrentRace', false, function(response)
        safeCb(response or { success = false, race = nil })
    end, data)
end)

RegisterNUICallback('racing:hub:getPlayerIdentifier', function(data, cb)
    local success, response = pcall(function()
        return lib.callback.await('racing:hub:getPlayerIdentifier', false, {})
    end)

    if success and response then
        cb({
            identifier  = response.identifier,
            playerName  = response.playerName,
            username    = response.username,
            isRegistered = response.isRegistered,
            ognBalance  = response.ognBalance or 0
        })
    else
        cb({ identifier = nil, playerName = nil, username = nil, isRegistered = false, ognBalance = 0 })
    end
end)

RegisterNUICallback('racing:hub:register', function(data, cb)
    local success, response = pcall(function()
        return lib.callback.await('racing:hub:register', false, data)
    end)

    if success and response then
        -- Si el registro fue exitoso, recargar stats en Lua para que aparezcan los blips de circuito
        if response.success then
            TriggerEvent('racing:reloadPlayerStats')
        end
        cb(response)
    else
        cb({ success = false, message = 'Error de conexión con el servidor' })
    end
end)

RegisterNUICallback('racing:hub:getCircuitCheckpoints', function(data, cb)
    local success, response = pcall(function()
        return lib.callback.await('racing:hub:getCircuitCheckpoints', false, data)
    end)

    if not success then
        print('^1[RacingHub Client]^7 ERROR al obtener checkpoints:', response)
        cb({ success = false, checkpoints = {} })
        return
    end

    cb(response or { success = false, checkpoints = {} })
end)

RegisterNUICallback('racing:hub:createRace', function(data, cb)
    -- Quien la crea entra en su sala: el nombre del coche, como al unirse.
    if type(data) == 'table' then
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        if vehicle ~= 0 then
            local displayName = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
            if displayName and displayName ~= 'CARNOTFOUND' and displayName ~= '' then
                data.vehicleName = displayName
            end
        end
    end

    local success, response = pcall(function()
        return lib.callback.await('racing:hub:createRace', false, data)
    end)

    if not success then
        print('^1[RacingHub Client]^7 ERROR:', response)
        cb({ success = false, message = 'Error al crear la carrera' })
        return
    end

    cb(response or { success = false })
end)

RegisterNUICallback('racing:hub:joinRace', function(data, cb)

    -- Obtener nombre legible del vehículo en cliente (nativa solo disponible aquí)
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    if vehicle ~= 0 then
        local model = GetEntityModel(vehicle)
        local displayName = GetDisplayNameFromVehicleModel(model)
        if displayName and displayName ~= 'CARNOTFOUND' and displayName ~= '' then
            data.vehicleName = displayName
        end
    end

    local success, response = pcall(function()
        return lib.callback.await('racing:hub:joinRace', false, data)
    end)

    if not success then
        print('^1[RacingHub Client]^7 ERROR:', response)
        cb({ success = false, message = 'Error al unirse a la carrera' })
        return
    end

    cb(response or { success = false })
end)

RegisterNUICallback('racing:hub:leaveRace', function(data, cb)

    local success, response = pcall(function()
        return lib.callback.await('racing:hub:leaveRace', false, data)
    end)

    if not success then
        print('^1[RacingHub Client]^7 ERROR:', response)
        cb({ success = false })
        return
    end

    -- Limpiar estados del cliente al salir
    if response and response.success then
        -- Disparar el evento local que resetea isInRace, isActivelyRacing y currentRace en main.lua.
        -- No asignar isInRace/currentRaceCircuitId directamente aquí: son locals de main.lua
        -- y una asignación directa crearía globals inútiles sin efecto sobre el local.
        TriggerEvent('racing:localRaceFinished')

        TriggerEvent('racing:cleanupStartMarkers')

        -- Si la carrera ya estaba en curso (racing/countdown), el hub debe cerrarse.
        -- El evento racing:playerDnf con voluntary=true ya se encargará de esto cuando
        -- llegue del servidor, pero cerramos el hub preventivamente también aquí.
        if response.wasRacing then
            CloseTabletAnimation()
            SoltarFocoCarreras(false)
            SendNUIMessage({ action = 'closeRacingHub' })
        end

    end

    cb(response or { success = false })
end)

RegisterNUICallback('racing:hub:cancelRace', function(data, cb)

    local success, response = pcall(function()
        return lib.callback.await('racing:hub:cancelRace', false, data)
    end)

    if not success then
        print('^1[RacingHub Client]^7 ERROR:', response)
        cb({ success = false, message = 'Error al cancelar la carrera' })
        return
    end

    cb(response or { success = false })
end)

RegisterNUICallback('racing:hub:toggleReady', function(data, cb)

    local success, response = pcall(function()
        return lib.callback.await('racing:hub:toggleReady', false, data)
    end)

    if not success then
        print('^1[RacingHub Client]^7 ERROR:', response)
        cb({ success = false })
        return
    end

    cb(response or { success = false })
end)

RegisterNUICallback('racing:hub:startRace', function(data, cb)

    local success, response = pcall(function()
        return lib.callback.await('racing:hub:startRace', false, data)
    end)

    if not success then
        print('^1[RacingHub Client]^7 ERROR:', response)
        cb({ success = false, message = 'Error al iniciar la carrera' })
        return
    end

    cb(response or { success = false })
end)

-- Racing Hub: Obtener resultados de carrera
RegisterNUICallback('racing:hub:getRaceResults', function(data, cb)
    local success, response = pcall(function()
        return lib.callback.await('racing:hub:getRaceResults', false, data)
    end)

    if not success then
        cb({ success = false })
        return
    end

    cb(response or { success = false })
end)

-- Racing Hub: Guardar configuración
RegisterNUICallback('racing:hub:saveConfig', function(data, cb)
    local success, response = pcall(function()
        return lib.callback.await('racing:hub:saveConfig', false, data)
    end)

    cb(response or { success = false })
end)

-- Racing Hub: Obtener configuraciones guardadas
RegisterNUICallback('racing:hub:getSavedConfigs', function(data, cb)
    local success, response = pcall(function()
        return lib.callback.await('racing:hub:getSavedConfigs', false, data)
    end)

    cb(response or { success = false })
end)

-- Racing Hub: Eliminar configuración
RegisterNUICallback('racing:hub:deleteConfig', function(data, cb)
    local success, response = pcall(function()
        return lib.callback.await('racing:hub:deleteConfig', false, data)
    end)

    cb(response or { success = false })
end)

-- Racing Hub: Obtener jugadores online
RegisterNUICallback('racing:hub:getOnlinePlayers', function(data, cb)
    local success, response = pcall(function()
        return lib.callback.await('racing:hub:getOnlinePlayers', false, data)
    end)

    cb(response or { success = false })
end)

-- Racing Hub: los avisos guardados en el servidor (invitaciones a carrera y
-- a crew), que el hub pide al abrirse.
RegisterNUICallback('racing:hub:getInvitations', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:hub:getInvitations')
end)

-- Racing Hub: Invitar jugador
RegisterNUICallback('racing:hub:invitePlayer', function(data, cb)
    local success, response = pcall(function()
        return lib.callback.await('racing:hub:invitePlayer', false, data)
    end)

    cb(response or { success = false })
end)

-- Racing Hub: Aceptar invitación
RegisterNUICallback('racing:hub:acceptInvitation', function(data, cb)
    local success, response = pcall(function()
        return lib.callback.await('racing:hub:acceptInvitation', false, data)
    end)

    -- Aceptar no te apunta a distancia: te marca la ruta hasta la salida.
    if success and type(response) == 'table' and response.irALaSalida then
        local circuito = GetCircuit(tonumber(response.circuitId) or response.circuitId)
        local punto = circuito and circuito.blip
        if punto and punto.x and punto.y then
            TriggerEvent('racing:clearProximityMarkers')
            OrigenMapa.Poner('salida', {
                x = punto.x, y = punto.y, z = punto.z or 0.0,
                cat = 'racing', icono = 'bandera',
                nombre = circuito.name or 'Carrera',
                ruta = true,
            })
            TriggerEvent('racing:storeProximityBlip', 'salida')
        end
        lib.notify({
            title = 'Invitación aceptada',
            description = 'Ve a la salida con tu coche y únete desde el hub',
            type = 'success', duration = 7000,
        })
    elseif type(response) == 'table' and response.message then
        lib.notify({ title = 'Invitación', description = response.message, type = 'error' })
    end

    cb(response or { success = false })
end)

-- Racing Hub: Rechazar invitación
RegisterNUICallback('racing:hub:rejectInvitation', function(data, cb)
    local success, response = pcall(function()
        return lib.callback.await('racing:hub:rejectInvitation', false, data)
    end)

    cb(response or { success = false })
end)

-- Racing Hub: Cerrar resultados
RegisterNUICallback('racing:hub:closeResults', function(data, cb)

    -- Enviar acción a la UI para cerrar el panel
    SendNUIMessage({
        action = 'closeRaceResults'
    })
    -- Y el hilo de Retroceso de los resultados, que se queda sin nada que cerrar.
    CerrarResultados()

    -- Liberar foco NUI (el del panel de crew, si sigue abierto, no)
    SoltarFocoCarreras(false)

    cb({ success = true })
end)

-- Racing Hub: Mostrar punto de partida (blip + GPS)
RegisterNUICallback('racing:hub:showStartPoint', function(data, cb)
    if data.coords then
        -- Limpiar marcadores anteriores si existen
        TriggerEvent('racing:clearProximityMarkers')

        -- Crear nuevo blip
        local coords = data.coords
        local blip = 'salida'
        OrigenMapa.Poner(blip, {
            x = coords.x, y = coords.y, z = coords.z,
            cat = 'racing',
            icono = 'bandera',
            nombre = "Punto de Partida - Carrera",
            ruta = true,
        })

        -- Guardar el blip para limpiar después
        TriggerEvent('racing:storeProximityBlip', blip)
    end
    cb({ success = true })
end)

--[[ Racing Hub: la ruta hasta una carrera, desde el boton de GPS de su ficha.

     El destino es el punto del circuito —el mismo que sale en los mapas—, que
     el cliente ya tiene: no hace falta estar apuntado ni preguntar al
     servidor. Se pone como 'salida', igual que el punto de partida de arriba,
     asi que una ruta sustituye a la otra y las dos se limpian por el mismo
     sitio (racing:clearProximityMarkers). ]]
RegisterNUICallback('racing:hub:gps', function(data, cb)
    cb({ success = true })

    local circuito = data and GetCircuit(tonumber(data.circuitId) or data.circuitId)
    local punto = circuito and circuito.blip

    if not punto or not punto.x or not punto.y then
        lib.notify({ title = 'Racing', description = 'Ese circuito no tiene punto en el mapa', type = 'error' })
        return
    end

    TriggerEvent('racing:clearProximityMarkers')

    OrigenMapa.Poner('salida', {
        x = punto.x, y = punto.y, z = punto.z or 0.0,
        cat = 'racing',
        icono = 'bandera',
        nombre = circuito.name or 'Carrera',
        ruta = true,
    })
    TriggerEvent('racing:storeProximityBlip', 'salida')

    lib.notify({ title = 'Racing', description = 'Ruta marcada hasta ' .. (circuito.name or 'la carrera'), type = 'success' })
end)

-- Racing Hub: Limpiar marcadores de proximidad
RegisterNUICallback('racing:hub:clearStartPoint', function(data, cb)
    TriggerEvent('racing:clearProximityMarkers')
    cb({ success = true })
end)

-- ========================================
-- VEHICLE CLASSES CALLBACKS
-- ========================================

-- Obtener todas las clases
RegisterNUICallback('racing:classes:getAll', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:classes:getAll')
end)

-- Obtener vehículos de una clase
RegisterNUICallback('racing:classes:getVehicles', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:classes:getVehicles', data)
end)

-- Crear clase
RegisterNUICallback('racing:classes:create', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:classes:create', data)
end)

-- Actualizar clase
RegisterNUICallback('racing:classes:update', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:classes:update', data)
end)

-- Eliminar clase
RegisterNUICallback('racing:classes:delete', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:classes:delete', data)
end)

-- Añadir vehículo a clase
RegisterNUICallback('racing:classes:addVehicle', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:classes:addVehicle', data)
end)

-- Eliminar vehículo de clase
RegisterNUICallback('racing:classes:removeVehicle', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:classes:removeVehicle', data)
end)

-- ========================================
-- SISTEMA DE APUESTAS
-- ========================================

-- Colocar apuesta
RegisterNUICallback('racing:bets:placeBet', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:bets:placeBet', data)
end)

-- Obtener resumen de apuestas de una carrera
RegisterNUICallback('racing:bets:getRaceBets', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:bets:getRaceBets', data and data.raceId)
end)

-- Recibir resolución de apuesta desde el servidor
RegisterNetEvent('racing:bets:resolved', function(data)
    SendNUIMessage({ action = 'bets:resolved', data = data })
end)

-- Recibir actualización del resumen de apuestas en tiempo real
RegisterNetEvent('racing:bets:summaryUpdate', function(data)
    SendNUIMessage({ action = 'bets:summaryUpdate', data = data })
end)

-- Economía de crew
RegisterNUICallback('racing:economy:getBalance', function(data, cb)
    local success, response = pcall(function()
        return lib.callback.await('racing:economy:getBalance', false, data or {})
    end)
    if not success then
        cb({ success = false, message = 'Error al obtener el balance' })
        return
    end
    cb(response or { success = false, message = 'Sin respuesta del servidor' })
end)

RegisterNUICallback('racing:economy:getLogs', function(data, cb)
    local success, response = pcall(function()
        return lib.callback.await('racing:economy:getLogs', false, data or {})
    end)
    if not success then
        cb({ success = false, logs = {} })
        return
    end
    cb(response or { success = false, logs = {} })
end)

RegisterNUICallback('racing:economy:deposit', function(data, cb)
    local success, response = pcall(function()
        return lib.callback.await('racing:economy:deposit', false, data or {})
    end)
    if not success then
        cb({ success = false, message = 'Error al depositar' })
        return
    end
    cb(response or { success = false, message = 'Sin respuesta del servidor' })
end)

RegisterNUICallback('racing:economy:withdraw', function(data, cb)
    local success, response = pcall(function()
        return lib.callback.await('racing:economy:withdraw', false, data or {})
    end)
    if not success then
        cb({ success = false, message = 'Error al retirar' })
        return
    end
    cb(response or { success = false, message = 'Sin respuesta del servidor' })
end)

RegisterNUICallback('racing:economy:sendCrypto', function(data, cb)
    local success, response = pcall(function()
        return lib.callback.await('racing:economy:sendCrypto', false, data or {})
    end)
    if not success then
        cb({ success = false, message = 'Error al enviar crypto' })
        return
    end
    cb(response or { success = false, message = 'Sin respuesta del servidor' })
end)

-- Mandar OGN del saldo personal a otro jugador (boton «Enviar» de la cabecera
-- del hub). Todo lo decide el servidor.
RegisterNUICallback('racing:hub:sendOgn', function(data, cb)
    local success, response = pcall(function()
        return lib.callback.await('racing:hub:sendOgn', false, data or {})
    end)
    if not success then
        cb({ success = false, message = 'Error al enviar OGN' })
        return
    end
    cb(response or { success = false, message = 'Sin respuesta del servidor' })
end)

-- (La base de la crew —la pestaña Base del panel— va en client/base.lua.)

-- Historial de territorio
RegisterNUICallback('racing:territories:getHistory', function(data, cb)
    local success, response = pcall(function()
        return lib.callback.await('racing:territories:getHistory', false, data)
    end)
    if not success then cb({ success = false, history = {} }) return end
    cb(response or { success = false, history = {} })
end)

-- ========================================
-- DEALERSHIP CALLBACKS (TriggerServerEvent pattern)
-- ========================================

-- Tabla de callbacks pendientes por reqId
local _dpCallbacks = {}
local _dpReqId     = 0

-- Receptor único de todas las respuestas del servidor
RegisterNetEvent('racing:dealership:client:result')
AddEventHandler('racing:dealership:client:result', function(reqId, result)
    local cb = _dpCallbacks[reqId]
    if cb then
        _dpCallbacks[reqId] = nil
        cb(result)
    end
end)

-- Helper: envía evento al servidor y espera respuesta con timeout
local function dpFetch(action, data, nuiCb, timeout)
    _dpReqId = _dpReqId + 1
    local reqId = _dpReqId
    _dpCallbacks[reqId] = nuiCb
    TriggerServerEvent('racing:dealership:server:' .. action, reqId, data)
    SetTimeout(timeout or 10000, function()
        if _dpCallbacks[reqId] then
            _dpCallbacks[reqId] = nil
            nuiCb({ success = false, message = 'Timeout' })
        end
    end)
end

RegisterNUICallback('racing:dealership:getCatalog', function(data, cb)
    dpFetch('getCatalog', data, cb)
end)

RegisterNUICallback('racing:dealership:buyForCrew', function(data, cb)
    dpFetch('buyForCrew', data, cb)
end)

RegisterNUICallback('racing:dealership:getGarage', function(data, cb)
    dpFetch('getGarage', data, cb)
end)

RegisterNUICallback('racing:dealership:takeVehicle', function(data, cb)
    dpFetch('takeVehicle', data, cb)
end)

RegisterNUICallback('racing:dealership:storeVehicle', function(data, cb)
    dpFetch('storeVehicle', data, cb)
end)


-- Circuitos propuestos por jugadores (server/admin.lua)
RegisterNUICallback('racing:proponer:guardar', function(data, cb)
    local ok, r = pcall(lib.callback.await, 'racing:proponer:guardar', false, data)
    r = ok and r or { success = false, message = 'Error al guardar el circuito' }
    lib.notify({
        title = r.success and 'Circuito enviado' or 'Racing',
        description = r.success and 'Queda en revisión. Te avisaremos cuando un admin lo apruebe.' or (r.message or 'No se ha podido guardar'),
        type = r.success and 'success' or 'error', duration = 7000,
    })
    cb(r)
end)

RegisterNUICallback('admin:revisarCircuito', function(data, cb)
    local ok, r = pcall(lib.callback.await, 'racing:admin:revisarCircuito', false, data)
    cb(ok and r or { success = false })
end)

-- La foto de perfil del hub: se guarda también en el servidor para que la
-- vean los demás (podio de pilotos). Ver RankingHub en server/main.lua.
RegisterNUICallback('racing:perfil:foto', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:perfil:foto', data)
end)

-- El banner del perfil, guardado en el servidor como la foto.
RegisterNUICallback('racing:perfil:banner', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:perfil:banner', data)
end)

-- ========================================
-- LA SALA: ELEGIR COCHE Y CHAT (server/sala.lua)
-- ========================================

-- Nombre y cifras de un modelo, sacados del juego (sin sacar el coche). Las
-- cifras van de 0 a 100 para las barras; 0 si el juego no las da.
local function FichaDeModelo(modelo)
    local h = GetHashKey(modelo)
    if not IsModelInCdimage(h) or not IsModelAVehicle(h) then return nil end
    local display = GetDisplayNameFromVehicleModel(h)
    local nombre = display and GetLabelText(display) or 'NULL'
    if not nombre or nombre == 'NULL' or nombre == '' then nombre = display or modelo end
    local function pct(v, tope) return math.max(0, math.min(100, math.floor((tonumber(v) or 0) / tope * 100 + 0.5))) end
    return {
        nombre = nombre,
        clase = GetLabelText('VEH_CLASS_' .. GetVehicleClassFromName(h)),
        stats = {
            velocidad   = pct(GetVehicleModelEstimatedMaxSpeed(h), 60.0),
            aceleracion = pct(GetVehicleModelAcceleration(h), 0.5),
            frenada     = pct(GetVehicleModelMaxBraking(h), 1.6),
            agarre      = pct(GetVehicleModelMaxTraction(h), 3.2),
        },
    }
end

RegisterNUICallback('racing:sala:coches', function(data, cb)
    local ok, r = pcall(lib.callback.await, 'racing:sala:coches', false)
    if not ok or type(r) ~= 'table' then cb({ success = false }) return end
    for _, c in ipairs(r.coches or {}) do
        local f = FichaDeModelo(c.model)
        if f then
            c.nombre, c.claseJuego, c.stats = f.nombre, f.clase, f.stats
        else
            c.nombre = tostring(c.model):upper()
        end
    end
    cb(r)
end)

RegisterNUICallback('racing:sala:elegirCoche', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:sala:elegirCoche', { plate = type(data) == 'table' and data.plate or nil })
end)

RegisterNUICallback('racing:sala:getChat', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:sala:getChat')
end)

RegisterNUICallback('racing:sala:chat', function(data, cb)
    data = type(data) == 'table' and data or {}
    ContestarDesdeServidor(cb, 'racing:sala:chat', { texto = data.texto, rapido = data.rapido })
end)

RegisterNetEvent('racing:sala:mensaje', function(msg)
    SendNUIMessage({ action = 'salaChat', data = msg })
end)

-- ========================================
-- EN DIRECTO DENTRO DEL HUB (server/directo.lua)
-- ========================================

RegisterNUICallback('racing:directo:ver', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:directo:ver', { raceId = type(data) == 'table' and tonumber(data.raceId) or nil })
end)

RegisterNUICallback('racing:directo:dejar', function(data, cb)
    TriggerServerEvent('racing:directo:dejar')
    cb({ success = true })
end)

RegisterNetEvent('racing:directo:datos', function(foto)
    SendNUIMessage({ action = 'directoDatos', data = foto })
end)

RegisterNetEvent('racing:directo:fin', function(d)
    SendNUIMessage({ action = 'directoFin', data = d })
end)
