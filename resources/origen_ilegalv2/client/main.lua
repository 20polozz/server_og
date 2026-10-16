playerGang = nil
local isCreationOpen = false
local dbg = Debug:new({ enabled = Config.Debug })

-- ── StartLocationPlacement ────────────────────────────────────────────────────
-- Delega en Placement.Start (f_placement.lua), enriqueciendo los opts según el
-- tipo de ubicación (soporte de preview de vehículo para 'garage').
-- callback(result) → result = { x, y, z, w } donde w = heading | nil si cancelado.

-- Global y no local: la pestaña de Ubicaciones del cuadro de mando la
-- necesita, y duplicar el modo de colocacion en dos sitios acabaria con dos
-- formas distintas de poner el mismo alijo.
function StartLocationPlacement(locationType, callback)
    local typeConfig = Config.Locations.Types[locationType] or {}

    -- Resolver marker del config o fallback
    local markerOpts = nil
    if typeConfig.marker then
        markerOpts = typeConfig.marker
    else
        local fb = (Config.Markers and Config.Markers.LocationPlacementFallback) or {}
        markerOpts = {
            type         = fb.type         or 2,
            offset       = fb.offset       or { x = 0.0, y = 0.0, z = 1.0 },
            scale        = fb.scale        or { x = 0.3, y = 0.3, z = 0.3 },
            color        = fb.color        or { r = 255, g = 255, b = 255, a = 200 },
            bobUpAndDown = fb.bobUpAndDown == true,
            faceCamera   = fb.faceCamera ~= false,
            rotationOrder = fb.rotationOrder or 2,
            rotate       = fb.rotate == true,
        }
    end

    -- Preview de vehículo (solo para tipos que lo configuren, ej: garage)
    local vehicleModel = nil
    local vehicleAlpha = 150
    if typeConfig.placement_preview then
        vehicleModel = typeConfig.placement_preview.vehicle_model
        vehicleAlpha = typeConfig.placement_preview.vehicle_alpha or 150
    end

    Placement.Start({
        marker        = vehicleModel and nil or markerOpts, -- el vehículo reemplaza al marker
        vehicle_model = vehicleModel,
        vehicle_alpha = vehicleAlpha,
    }, function(result)
        if result then
            -- Normalizar: Placement devuelve { x, y, z, h }; el caller antiguo espera w=heading
            callback({ x = result.x, y = result.y, z = result.z, w = result.h })
        else
            callback(nil)
        end
    end)
end

local function InitializeGangSystem()
    dbg:info('Requesting gang data from server...')
    TriggerServerEvent('origen_gang:server:getGangData')
end

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    -- Always request gang data on resource restart.
    -- On some frameworks Bridge.IsPlayerLoaded() may be false after ensure/restart.
    Wait(2000)
    InitializeGangSystem()
end)

AddEventHandler('origen:Client:OnPlayerLoaded', function()
    dbg:info('Player loaded, initializing gang system in 2 seconds...')
    Wait(2000)
    InitializeGangSystem()
end)

AddEventHandler('origen:Client:OnPlayerUnload', function()
    dbg:info('Player unloaded, clearing gang data...')
    playerGang = nil
end)

function OpenGangCreation()
    if isCreationOpen then return end

    isCreationOpen = true
    SendTranslationsToNUI()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openCreation'
    })
end

function CloseGangCreation()
    isCreationOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'closeCreation'
    })
end

-- Si el raton se suelta a la fuerza (comando `raton`, ver
-- origen_map/shared/foco.lua), la marca se quedaria a true y la creacion no
-- volveria a abrirse hasta reconectar.
if OrigenFoco then
    OrigenFoco.AlSoltar(function()
        if isCreationOpen then CloseGangCreation() end
    end)
end

-- NUI Callbacks
RegisterNUICallback('closeCreation', function(data, cb)
    CloseGangCreation()
    cb('ok')
end)

RegisterNUICallback('createGang', function(data, cb)
    CloseGangCreation()
    TriggerServerEvent('origen_gang:server:createGangWizard', data)
    cb('ok')
end)

-- Events
RegisterNetEvent('origen_gang:client:updateGangData', function(gangData)
    dbg:info('Received gang data update from server')
    dbg:debug('gangData exists:', gangData and 'yes' or 'no')

    playerGang = gangData

    if gangData then
        dbg:success('Gang name:', gangData.name)
        dbg:debug('Gang ID:', gangData.id)
        dbg:debug('Has locations:', gangData.locations and 'yes' or 'no')

        TriggerEvent('origen_gang:client:playerGangLoaded', gangData)
    else
        dbg:warning('No gang data received (player not in gang)')
    end
end)

RegisterNetEvent('origen_gang:client:receiveSanctions', function(sanctions)
    SendNUIMessage({
        action = 'updateSanctions',
        data = sanctions
    })
end)

RegisterNetEvent('origen_gang:client:receiveAnnouncements', function(announcements)
    SendNUIMessage({
        action = 'updateAnnouncements',
        data = announcements
    })
end)

--[[ Ya no hay cuadro de invitacion en pantalla.

     La invitacion se contesta en el movil y solo ahi. El cuadro robaba el
     raton en medio de lo que estuvieras haciendo, se perdia si te pillaba
     conduciendo, y al que si llevaba telefono le preguntaba dos veces lo
     mismo. ]]

RegisterNetEvent('origen_gang:client:leftGang', function()
    playerGang = nil
end)

RegisterNetEvent('origen_gang:client:openCreation', function(desdeMovil)
    -- Desde el boton del movil, el movil sigue abierto y con el raton: se
    -- cierra antes, o las dos pantallas se pelean por el foco.
    if desdeMovil and GetResourceState('origen_phone') == 'started' then
        pcall(function() exports.origen_phone:Close() end)
    end
    OpenGangCreation()
end)

RegisterNetEvent('origen_gang:client:setWaypoint', function(x, y)
    SetNewWaypoint(x, y)
end)

RegisterNUICallback('updateRank', function(data, cb)
    TriggerServerEvent('origen_gang:server:updateRank', data)
    cb('ok')
end)

RegisterNUICallback('requestSanctions', function(data, cb)
    TriggerServerEvent('origen_gang:server:requestSanctions')
    cb('ok')
end)

RegisterNUICallback('requestAnnouncements', function(data, cb)
    TriggerServerEvent('origen_gang:server:getAnnouncements')
    cb('ok')
end)

RegisterNUICallback('markAnnouncementRead', function(data, cb)
    TriggerServerEvent('origen_gang:server:markAnnouncementRead', data.announcementId)
    cb('ok')
end)

RegisterNUICallback('gang:getLocationTypes', function(data, cb)
    local locationTypes = {}
    for typeKey, typeData in pairs(Config.Locations.Types) do
        table.insert(locationTypes, {
            value = typeKey,
            label = locale:t(typeData.label)
        })
    end
    cb(locationTypes)
end)

RegisterNUICallback('getGangVehicles', function(data, cb)
    lib.callback('origen_gangs:server:getGangVehicles', false, function(result)
        cb(result)
    end, data.gangId)
end)

RegisterNUICallback('getVehicleCatalog', function(data, cb)
    lib.callback('origen_gangs:server:getVehicleCatalog', false, function(result)
        cb(result)
    end, data.gangId)
end)

-- ─── Robberies ────────────────────────────────────────────────────────────────
RegisterNUICallback('gang_getRobberies', function(_, cb)
    lib.callback('origen_gang:server:getRobberies', false, function(result)
        cb(result or {})
    end)
end)

RegisterNUICallback('gang_requestRobbery', function(data, cb)
    TriggerServerEvent('origen_gang:server:requestRobbery', data.robberyId)
    cb({ ok = true })
end)

RegisterNetEvent('origen_gang:client:robberyRequestUpdate')
AddEventHandler('origen_gang:client:robberyRequestUpdate', function(data)
    if data.gangId and (not playerGang or tostring(playerGang.id) ~= tostring(data.gangId)) then
        return
    end
    SendNUIMessage({ action = 'gang_robberyUpdate', data = data })
end)

RegisterNetEvent('origen_gang:client:robberyListChanged')
AddEventHandler('origen_gang:client:robberyListChanged', function()
    SendNUIMessage({ action = 'gang_refreshRobberies' })
end)

-- ─── Exports & event bridge para recursos externos ───────────────────────────
-- GetPlayerGang se define aquí (no en graffiti.lua) para que esté disponible
-- independientemente de si Config.Graffiti.Enable está activo o no.
exports('GetPlayerGang', function()
    return playerGang
end)

--[[ ── El botón «Banda» del riel del inventario ────────────────────────────

     Sale teniendo banda o pudiendo crearla. Lo segundo lo sabe el servidor
     (origen_gang:puedeCrearBanda); aquí se guarda y se refresca cada 5 min
     mientras no tengas banda, porque el inventario lo pregunta al abrirse y
     no puede quedarse esperando al servidor. ]]
local puedeCrear = false

local function RefrescarPuedeCrear()
    if playerGang then puedeCrear = false return end
    local ok, r = pcall(function() return lib.callback.await('origen_gang:puedeCrearBanda', false) end)
    puedeCrear = ok and r == true
end

--[[ Cada 5 min (antes 30 s): con cientos de jugadores sin banda eran muchas
     consultas a la BD para algo que casi nunca cambia. Lo que tiene que
     notarse pronto se refresca aparte: al darte o quitarte el permiso un
     admin, al salir de la banda y al cargar personaje. Y al pulsar el botón
     AbrirCreacionDeBanda lo vuelve a comprobar todo en el servidor. ]]
CreateThread(function()
    Wait(5000)
    while true do
        RefrescarPuedeCrear()
        Wait(300000)
    end
end)

RegisterNetEvent('origen_gang:client:refrescarPuedeCrear', function()
    -- Con margen: el servidor escribe el permiso sin esperar a la BD.
    SetTimeout(1500, RefrescarPuedeCrear)
end)

AddEventHandler('origen_gang:client:leftGang', function()
    SetTimeout(1500, RefrescarPuedeCrear)
end)

AddEventHandler('origen:Client:OnPlayerLoaded', function()
    SetTimeout(5000, RefrescarPuedeCrear)
end)

exports('PuedeCrearBanda', function() return puedeCrear end)

--[[ Lo que hace el botón: con banda, el panel de banda (el del menú rápido,
     PanelBanda, que es el que lleva el riel, la radio y la caja); sin ella, el
     creador (el servidor decide si de verdad puedes, igual que desde el móvil). ]]
exports('AbrirDelRiel', function(relevo)
    if playerGang then
        if relevo then exports['origen_ilegalv2']:MarcarRelevo() end
        OpenQuickMenu()
    else
        TriggerServerEvent('origen_gang:server:abrirCreacionDesdeRiel')
        -- Por si el permiso se acaba de quitar o ya tiene banda: que el botón
        -- se entere pronto.
        SetTimeout(1500, RefrescarPuedeCrear)
    end
end)

-- Export para abrir el wizard de creación de banda desde otro recurso cliente.
-- Uso: exports['origen_ilegalv2']:OpenGangCreation()
exports('OpenGangCreation', function()
    OpenGangCreation()
end)
