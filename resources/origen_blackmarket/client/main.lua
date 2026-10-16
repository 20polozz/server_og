-- ========================================
-- CLIENTE PRINCIPAL — multi-mercado
-- ========================================

local QBCore     = nil
local PlayerData = {}

-- Estado global por mercado (compartido con zones.lua)
MarketState = {}
for marketId in pairs(Config.Markets) do
    MarketState[marketId] = {
        active     = false,
        owner      = nil,
        ownerLabel = nil,
        isOwner    = false,
        protected  = false,
    }
end

local MarketInfoOpen = false
local CaptureWindowActive = {}

-- ========================================
-- INICIALIZACIÓN
-- ========================================

CreateThread(function()
    QBCore     = exports['qb-core']:GetCoreObject()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    for marketId in pairs(Config.Markets) do
        TriggerServerEvent('blackmarket:server:getState', marketId)
    end
    -- Pedir mercados dinámicos de nuevo al cargar el personaje, por si el recurso
    -- todavía no los había cargado cuando arrancó el cliente (race condition de inicio).
    TriggerServerEvent('blackmarket:server:requestDynamicMarkets')
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
end)

RegisterNetEvent('QBCore:Client:OnGangUpdate', function(gang)
    PlayerData.gang = gang
    for marketId in pairs(Config.Markets) do
        TriggerServerEvent('blackmarket:server:getState', marketId)
    end
end)

-- ========================================
-- EVENTOS DEL SERVIDOR
-- ========================================

RegisterNetEvent('blackmarket:client:updateState', function(state)
    local marketId = tonumber(state.marketId) or 1
    local wasActive = MarketState[marketId] and MarketState[marketId].active
    MarketState[marketId] = state
    UpdateMarketBlip(marketId)
    Config.DebugPrint(('Market[%d] state updated'):format(marketId))
    -- Si el mercado está activo y el jugador ya estaba en zona, registrar presencia
    if state.active and not wasActive and InZoneMap and InZoneMap[marketId] then
        TriggerServerEvent('blackmarket:server:enterZone', marketId)
    end
end)

RegisterNetEvent('blackmarket:client:marketActivated', function(marketId)
    marketId = tonumber(marketId) or 1
    if MarketState[marketId] then MarketState[marketId].active = true end
    UpdateMarketBlip(marketId)
    -- Si ya estamos dentro de la zona, registrarnos ahora que la captura arrancó
    if InZoneMap and InZoneMap[marketId] then
        TriggerServerEvent('blackmarket:server:enterZone', marketId)
    end
end)

RegisterNetEvent('blackmarket:client:marketDeactivated', function(marketId)
    marketId = tonumber(marketId) or 1
    if MarketState[marketId] then MarketState[marketId].active = false end
    UpdateMarketBlip(marketId)
    -- Salir del registro de zona aunque sigamos físicamente dentro
    if InZoneMap and InZoneMap[marketId] then
        TriggerServerEvent('blackmarket:server:leaveZone', marketId)
    end
end)

RegisterNetEvent('blackmarket:client:updateOwner', function(marketId, gangName, gangLabel)
    marketId = tonumber(marketId) or 1
    if MarketState[marketId] then
        MarketState[marketId].owner      = gangName
        MarketState[marketId].ownerLabel = gangLabel
        MarketState[marketId].isOwner    = PlayerData.gang and PlayerData.gang.name == gangName or false
    end
    UpdateMarketBlip(marketId)
end)

-- Abrir UI mercado
RegisterNetEvent('blackmarket:client:openUI', function(data)
    Config.DebugPrint(('[CLIENT] Opening UI Market[%d]'):format(data.marketId or 1))
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'openMarket', data = data })
end)

-- ========================================
-- TORNEO DE CONQUISTA — estado cliente
-- ========================================

-- TournamentOpen[marketId] = { conquestId, endsAt, mLabel } | nil
TournamentOpen = {}

-- Marker activo del punto de salida de conquista (se borra al iniciar la carrera)
local conquestStartMarkerId = nil

RegisterNetEvent('blackmarket:client:tournamentRegistrationOpen', function(data)
    -- Guardamos el gameTimer en el momento de recepción + secsLeft para calcular
    -- el tiempo restante en cliente sin usar os.time() (no disponible en cliente FiveM)
    TournamentOpen[data.marketId] = {
        conquestId        = data.conquestId,
        endsAt            = data.endsAt,
        secsLeft          = data.secsLeft or 0,
        receivedTimer     = GetGameTimer(),
        circuitName       = data.circuitName,
        mLabel            = data.mLabel,
        registeredCrews   = data.registeredCrews or {},
        isRegistered      = false,
        vehicleClassName  = data.vehicleClassName,
        collisionsEnabled = data.collisionsEnabled or false,
    }
    lib.notify({
        title       = 'Torneo de Conquista',
        description = ('<b>%s</b> ha salido a disputa. Busca la zona del mercado e inscríbete para participar en la carrera.'):format(data.mLabel),
        type        = 'warning',
        duration    = 15000,
    })
end)

RegisterNetEvent('blackmarket:client:tournamentRegistrationClosed', function(marketId)
    TournamentOpen[marketId] = nil
end)

RegisterNetEvent('blackmarket:client:tournamentRaceCreated', function(data)
    local phaseLabel = data.phase == 'final' and 'FINAL' or 'Clasificatoria'
    local secsLeft   = data.secsLeft or 0
    local minsLeft   = math.ceil(secsLeft / 60)

    lib.notify({
        title       = ('Torneo — %s'):format(phaseLabel),
        description = ('<b>%s</b> · Ya estás inscrito. Ve al punto de salida marcado en el mapa <b>en vehículo</b>: tienes %d min.'):format(
            data.mLabel, minsLeft),
        type        = 'success',
        duration    = math.min(secsLeft * 1000, 15000), -- desaparece antes de que empiece la carrera
    })

    -- Marker en el punto de salida — solo para inscritos, se elimina al inicio de carrera
    if data.startPoint then
        -- Limpiar marker anterior si existía
        if conquestStartMarkerId then
            pcall(function() exports.origen_markers:Remove(conquestStartMarkerId) end)
            conquestStartMarkerId = nil
        end

        conquestStartMarkerId = exports.origen_markers:Create({
            coords       = vector3(data.startPoint.x, data.startPoint.y, data.startPoint.z),
            type         = 'checkpoint',
            label        = ('Salida — %s\nVe en vehículo al punto de inicio'):format(phaseLabel),
            size         = 3.0,
            drawDistance = 400.0,
            color        = { r = 216, g = 27, b = 85, a = 180 },
        })

        SetNewWaypoint(data.startPoint.x, data.startPoint.y)

        -- Fallback: eliminar al expirar el tiempo de join + 30s de margen
        local savedId = conquestStartMarkerId
        CreateThread(function()
            Wait((secsLeft + 30) * 1000)
            if conquestStartMarkerId == savedId then
                pcall(function() exports.origen_markers:Remove(conquestStartMarkerId) end)
                conquestStartMarkerId = nil
            end
        end)
    end
end)

RegisterNetEvent('blackmarket:client:tournamentFinished', function(data)
    TournamentOpen[data.marketId] = nil
end)

-- Actualización en tiempo real de crews inscritas → guardar en cache local y reenviar al NUI
RegisterNetEvent('blackmarket:client:tournamentCrewsUpdated', function(marketId, crews)
    -- Actualizar caché local para que al re-abrir el panel tenga las crews actuales
    if TournamentOpen[marketId] then
        TournamentOpen[marketId].registeredCrews = crews
    end
    SendNUIMessage({ action = 'tournamentCrewsUpdated', marketId = marketId, crews = crews })
end)

-- Al iniciar el countdown de la carrera, eliminar el marker de salida y la notificación
RegisterNetEvent('racing:startRaceCountdown', function(data)
    if conquestStartMarkerId then
        pcall(function() exports.origen_markers:Remove(conquestStartMarkerId) end)
        conquestStartMarkerId = nil
    end
    -- Limpiar notificación persistente de inscripción (ox_lib)
    pcall(function() lib.hideTextUI() end)
end)

-- Confirmación de auto-inscripción al crear la carrera de conquista
RegisterNetEvent('racing:conquest:autoJoined', function(data)
    lib.notify({
        title       = 'Inscrito en la carrera',
        description = ('<b>%s</b>: ya estás dentro. Ve al punto de salida en vehículo cuando llegues.'):format(data.raceName or 'Torneo'),
        type        = 'info',
        duration    = 10000,
    })
end)

-- ========================================
-- EVENTOS DE CAPTURA
-- ========================================

RegisterNetEvent('blackmarket:client:captureWindowStart', function(data)
    local marketId = tonumber(data.marketId) or 1
    CaptureWindowActive[marketId] = true
    SendNUIMessage({
        action   = 'captureWindowStart',
        marketId = marketId,
        endTime  = data.endTime,
        duration = data.duration,
        isGrace  = data.isGrace,
        meta     = data.meta,
        you      = data.you,
    })
end)

RegisterNetEvent('blackmarket:client:captureUpdate', function(data)
    SendNUIMessage({
        action    = 'captureUpdate',
        marketId  = data.marketId,
        timeLeft  = data.timeLeft,
        standings = data.standings,
        endTime   = data.endTime,
        duration  = data.duration,
        isGrace   = data.isGrace,
        meta      = data.meta,
        you       = data.you,
    })
end)

RegisterNetEvent('blackmarket:client:captureWindowEnd', function(marketId)
    marketId = tonumber(marketId) or 1
    CaptureWindowActive[marketId] = false
    SendNUIMessage({ action = 'captureWindowEnd', marketId = marketId })
end)

-- ========================================
-- NPC PUERTA — Panel informativo
-- ========================================

AddEventHandler('blackmarket:client:openMarketInfo', function(marketId)
    if MarketInfoOpen then return end
    marketId = tonumber(marketId) or 1
    local info = lib.callback.await('blackmarket:getMarketInfo', false, marketId)
    if not info then return end
    MarketInfoOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'openMarketInfo', data = info })
end)

-- Abrir UI de Admin
-- `AdminPanelOpen`: el panel de admin y el mercado se cierran por el mismo
-- callback (closeUI); con esto se sabe cuál de los dos era.
local AdminPanelOpen = false

RegisterNetEvent('blackmarket:client:openAdminUI', function(data)
    Config.DebugPrint('[CLIENT] Opening Admin UI')
    AdminPanelOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'openAdminPanel', data = data })
end)

-- ========================================
-- NUI CALLBACKS
-- ========================================

RegisterNUICallback('closeUI', function(data, cb)
    SetNuiFocus(false, false); cb('ok')

    -- ESC en el panel de admin: si se abrió desde la pestaña Scripts del
    -- admin, se vuelve a ella. origen_admin solo vuelve si este panel salió
    -- de su lista; el mercado de los jugadores cierra y nada más.
    if AdminPanelOpen then
        AdminPanelOpen = false
        if GetResourceState('origen_admin') == 'started' then
            SetTimeout(80, function()
                pcall(function() exports['origen_admin']:ReturnToScripts() end)
            end)
        end
    end
end)

RegisterNUICallback('closeMarketInfo', function(data, cb)
    MarketInfoOpen = false; SetNuiFocus(false, false); cb('ok')
end)

--[[ Raton soltado a la fuerza (vigilante de origen_map/shared/foco.lua o
     `soltarraton`): se cierra lo que hubiera abierto. Sin esto MarketInfoOpen
     se quedaba en true y el NPC de la puerta no volvia a abrir su panel. ]]
if OrigenFoco then
    OrigenFoco.AlSoltar(function()
        MarketInfoOpen = false
        -- Antes del aviso: la pagina contesta con closeUI y no debe volver al admin.
        AdminPanelOpen = false
        SendNUIMessage({ action = 'closeMarketInfo' })
        SendNUIMessage({ action = 'closeTournamentPanel' })
        SendNUIMessage({ action = 'closeMarket' })
        SendNUIMessage({ action = 'closeAdminPanel' })
    end)
end

RegisterNUICallback('closeTournamentPanel', function(data, cb)
    SetNuiFocus(false, false); cb('ok')
end)

RegisterNUICallback('registerForConquest', function(data, cb)
    local result = lib.callback.await('blackmarket:registerForConquest', false, data.marketId)
    if result and result.success then
        -- Marcar como inscrito en la caché local
        local mid = tonumber(data.marketId) or 1
        if TournamentOpen[mid] then TournamentOpen[mid].isRegistered = true end
        lib.notify({
            title       = 'Inscrito',
            description = 'Ve al Racing Hub cuando se anuncie la carrera.',
            type        = 'success',
            duration    = 6000,
        })
    elseif result and result.alreadyRegistered then
        -- Sincronizar estado: ya inscrito pero el panel no lo sabía
        local mid = tonumber(data.marketId) or 1
        if TournamentOpen[mid] then TournamentOpen[mid].isRegistered = true end
    elseif result and result.err then
        lib.notify({
            title       = 'No se pudo inscribir',
            description = result.err,
            type        = 'error',
            duration    = 5000,
        })
    else
        lib.notify({
            title       = 'No se pudo inscribir',
            description = 'No fue posible completar la inscripción, intenta de nuevo.',
            type        = 'error',
            duration    = 5000,
        })
    end
    cb(result or { success = false })
end)

RegisterNUICallback('getProducts', function(data, cb)
    local products = lib.callback.await('blackmarket:getProducts', false, data.marketId)
    cb(products)
end)

RegisterNUICallback('getPlayerInfo', function(data, cb)
    local info = lib.callback.await('blackmarket:getPlayerInfo', false, data.marketId)
    cb(info)
end)

RegisterNUICallback('addProduct', function(data, cb)
    local result = lib.callback.await('blackmarket:addProduct', false, data)
    cb(result)
end)

RegisterNUICallback('removeProduct', function(data, cb)
    local result = lib.callback.await('blackmarket:removeProduct', false, data.productId)
    cb(result)
end)

RegisterNUICallback('buyProduct', function(data, cb)
    local result = lib.callback.await('blackmarket:buyProduct', false, data.productId, data.quantity)
    cb(result)
end)

RegisterNUICallback('updateStock', function(data, cb)
    local result = lib.callback.await('blackmarket:updateProductStock', false, data.productId, data.newStock)
    cb(result)
end)

RegisterNUICallback('getAvailableItems', function(data, cb)
    local items = lib.callback.await('blackmarket:getAvailableItems', false, data and data.marketId)
    cb(items)
end)

RegisterNUICallback('getMarketState', function(data, cb)
    local state = lib.callback.await('blackmarket:getMarketState', false, data.marketId)
    cb(state)
end)

RegisterNUICallback('getMarketConfig', function(data, cb)
    local config = lib.callback.await('blackmarket:getMarketConfig', false, data.marketId)
    cb(config)
end)

RegisterNUICallback('saveMarketConfig', function(data, cb)
    local result = lib.callback.await('blackmarket:saveMarketConfig', false, data)
    cb(result)
end)

RegisterNUICallback('releaseMarket', function(data, cb)
    local result = lib.callback.await('blackmarket:releaseMarket', false, data.marketId)
    cb(result)
end)

RegisterNUICallback('toggleMarketActive', function(data, cb)
    local result = lib.callback.await('blackmarket:toggleMarketActive', false, data.marketId)
    cb(result)
end)

RegisterNUICallback('forceActivation', function(data, cb)
    local result = lib.callback.await('blackmarket:forceActivation', false, data.marketId)
    cb(result)
end)

RegisterNUICallback('getCaptureHistory', function(data, cb)
    local history = lib.callback.await('blackmarket:getCaptureHistory', false, data.marketId)
    cb(history or {})
end)

RegisterNUICallback('setNextActivation', function(data, cb)
    local result = lib.callback.await('blackmarket:setNextActivation', false, data.marketId, data.minutesFromNow)
    cb(result or { success = false })
end)

RegisterNUICallback('adminEditProduct', function(data, cb)
    local result = lib.callback.await('blackmarket:adminEditProduct', false, data)
    cb(result or { success = false })
end)

RegisterNUICallback('getCircuits', function(data, cb)
    local circuits = lib.callback.await('blackmarket:getCircuits', false)
    cb(circuits or {})
end)

RegisterNUICallback('getVehicleClasses', function(data, cb)
    local classes = lib.callback.await('blackmarket:getVehicleClasses', false)
    cb(classes or {})
end)

RegisterNUICallback('getPlayerPosition', function(_, cb)
    local ped    = PlayerPedId()
    local coords = GetEntityCoords(ped)
    cb({ x = coords.x, y = coords.y, z = coords.z })
end)

RegisterNUICallback('createMarket', function(data, cb)
    local result = lib.callback.await('blackmarket:createMarket', false, data)
    cb(result or { success = false })
end)

RegisterNUICallback('deleteMarket', function(data, cb)
    local result = lib.callback.await('blackmarket:deleteMarket', false, tonumber(data.marketId))
    cb(result or { success = false })
end)

RegisterNUICallback('updateMarketWorld', function(data, cb)
    local result = lib.callback.await('blackmarket:updateMarketWorld', false, data)
    cb(result or { success = false })
end)

-- Captura de posición interactiva: libera el foco del NUI, el admin se mueve
-- al punto deseado y pulsa [E] para confirmar (o [BACKSPACE] para cancelar).
RegisterNUICallback('startPositionCapture', function(data, cb)
    SetNuiFocus(false, false)

    exports['origen_hud']:setupControls({
        { key = 'E',         text = 'Confirmar punto' },
    })

    CreateThread(function()
        local deadline = GetGameTimer() + 30000
        while GetGameTimer() < deadline do
            Wait(0)
            if IsControlJustReleased(0, 38) then   -- E
                local ped     = PlayerPedId()
                local coords  = GetEntityCoords(ped)
                local heading = GetEntityHeading(ped)
                exports['origen_hud']:hideControls()
                SetNuiFocus(true, true)
                cb({
                    success = true,
                    x       = math.floor(coords.x * 100) / 100,
                    y       = math.floor(coords.y * 100) / 100,
                    z       = math.floor(coords.z * 100) / 100,
                    heading = math.floor(heading * 10)  / 10,
                })
                return
            end
            if IsControlJustReleased(0, 177) then  -- BACKSPACE
                exports['origen_hud']:hideControls()
                SetNuiFocus(true, true)
                cb({ success = false })
                return
            end
        end
        -- Timeout (30s)
        exports['origen_hud']:hideControls()
        SetNuiFocus(true, true)
        cb({ success = false })
    end)
end)

-- ========================================
-- EXPORTS
-- ========================================

exports('GetMarketState', function(marketId)
    return MarketState[tonumber(marketId) or 1]
end)

exports('IsMarketActive', function(marketId)
    local s = MarketState[tonumber(marketId) or 1]
    return s and s.active or false
end)

exports('IsInActiveCaptureZone', function()
    if not InZoneMap then return false end
    for marketId, inZone in pairs(InZoneMap) do
        if inZone and CaptureWindowActive[marketId] then
            return true, marketId
        end
    end
    return false
end)

exports('OpenMarket', function(marketId)
    TriggerServerEvent('blackmarket:server:openMarket', tonumber(marketId) or 1)
end)

exports('openManagement', function()
    TriggerServerEvent('blackmarket:server:openAdminPanel')
end)
