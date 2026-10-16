vehicleList = {}  -- Make global for admin.lua
function generateVehicleList()  -- Make global for admin.lua

    if next(vehicleList) then
        return vehicleList
    end

    local vehicles = GetAllVehicleModels()

    local count = 0
    for _, vehicle in pairs(vehicles) do
        count = count + 1
        if count % 200 == 0 then Wait(0) end -- Prevent client freeze on large vehicle lists
        
        local model = vehicle
        local label = GetDisplayNameFromVehicleModel(model)
        table.insert(vehicleList, {
            model = model,
            label = label
        })
    end

    return vehicleList
end

RegisterCommand('dealer', function(src,args,raw)
    lib.callback('origen_dealerships:ui:getDealerships', false, function(result)
        if result == false then
            Custom.Notify(locale('notifications.no_admin_permissions'), 'error')
            return
        end
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'openAdmin',
            dealerships = result,
            vehicles = generateVehicleList()
        })
    end)
  
end)

RegisterNUICallback('close', function(data, cb)
    -- El raton se suelta lo primero: si algo de abajo revienta (el fundido
    -- de origen_hud, el callback del servidor) ya no se queda preso.
    SetNuiFocus(false, false)

    -- El fundido de origen_hud, en pcall: con el HUD a medio reiniciar el
    -- export revienta y el cierre se quedaba a la mitad.
    local function HudFadeOut(time)
        local t = tonumber(time) or 320
        if GetResourceState('origen_hud') == 'started' and pcall(function()
            SetNuiZindex(1)
            exports['origen_hud']:DoScreenFadeOut(t)
        end) then
            Wait(t + 20)
        else
            DoScreenFadeOut(t)
            while not IsScreenFadedOut() do Wait(0) end
        end
    end

    local function HudFadeIn(time)
        local t = tonumber(time) or 360
        if not (GetResourceState('origen_hud') == 'started' and pcall(function()
            SetNuiZindex(99999)
            exports['origen_hud']:DoScreenFadeIn(t)
        end)) then
            DoScreenFadeIn(t)
        end
    end

    local silent = data and data.silent
    if not silent then
        HudFadeOut(320)
    end

    cleanupPreviewCamera()
    local routingBucket = lib.callback.await('origen_dealership:routingBucketHandler', false)

    if not silent then
        Wait(80)
        HudFadeIn(380)
    end

    cb(true)
    
    -- Check if opened from hub using global variable
    if _G.DealershipHubIntegration and _G.DealershipHubIntegration.openedFromHub then
        _G.DealershipHubIntegration.openedFromHub = false
        
        if GetResourceState('origen_admin') == 'started' then
            exports['origen_admin']:ReturnToScripts()
        end
    end
end)

RegisterNUICallback('getConfig', function(data, cb)
    cb({
        FinancingConfig = Config.FinancingConfig,
    })
end)

RegisterNUICallback('origen_dealerships:ui:teleport', function(data, cb)
    -- Un concesionario sin ningún punto llega sin z (o sin coords): se miraba
    -- después del fundido, SetEntityCoords petaba y la pantalla se quedaba en negro.
    local c = data and data.coords
    if type(c) ~= 'table' or not tonumber(c.x) or not tonumber(c.y) or not tonumber(c.z) then
        Custom.Notify('Este concesionario todavía no tiene ningún punto al que ir.', 'error')
        return cb(false)
    end

    DoScreenFadeOut(1000)
    while not IsScreenFadedOut() do
        Wait(0)
    end
    SetEntityCoords(cache.ped, data.coords.x, data.coords.y, data.coords.z, false, false, false, true)
    DoScreenFadeIn(2000)
    cb(true)
end)

RegisterNUICallback('origen_dealerships:ui:spawnVehicle', function(data, cb)
    local vehicle = data.vehicle
    local model = GetHashKey(vehicle.model)
    
    if not IsModelValid(model) then
        cb(false)
        return
    end

    RequestModel(model)
    DoScreenFadeOut(1000)

    if IsPedInAnyVehicle(cache.ped, false) then
        local vehicleIn = GetVehiclePedIsIn(cache.ped, false)
        if vehicleIn then
            SetEntityAsMissionEntity(vehicleIn, true, true)
            DeleteVehicle(vehicleIn)
        end
    end

    while not IsModelInCdimage(model) do
        Wait(0)
    end

    while not HasModelLoaded(model) do
        Wait(0)
    end

    while not IsScreenFadedOut() do
        Wait(0)
    end

    DoScreenFadeIn(2000)
    local coords = GetEntityCoords(cache.ped)
    local heading = GetEntityHeading(cache.ped)
    local vehicle = CreateVehicle(model, coords.x, coords.y, coords.z, heading, true, false)
    SetVehicleOnGroundProperly(vehicle)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleNumberPlateText(vehicle, 'DEALERSHIP')
    -- Custom:GiveKeys(vehicle, PlayerPedId(), true)
    TaskWarpPedIntoVehicle(cache.ped, vehicle, -1)

    cb(true)
end)

RegisterNUICallback('origen_dealerships:ui:deleteDealership', function(data, cb)
    lib.callback('origen_dealerships:ui:deleteDealership', false, function(retval)
        if retval then
            return cb(true)
        end
        return cb(false)
    end, data)
end)

-- Se le pasa a la NUI la respuesta entera ({success, saved, errors}). Antes
-- cualquier tabla contaba como éxito: salía «guardado» aunque fallara, y la NUI
-- recibía un true que no sabía leer y nunca enseñaba el error. El aviso lo da
-- la NUI, que ya lo hace según success.
RegisterNUICallback('origen_dealerships:ui:saveAll', function(data, cb)
    lib.callback('origen_dealerships:ui:saveAll', false, function(retval)
        cb(type(retval) == 'table' and retval or { success = false })
    end, data)
end)

RegisterNUICallback('deleteCreatorPoint', function(data, cb)
    if data.type and data.index ~= nil then
        DeleteCreatorPoint(data.type, data.index)
    end
    cb(true)
end)

-- Callback para forzar actualización del cache
RegisterNUICallback('origen_dealerships:ui:forceUpdate', function(data, cb)
    lib.callback('origen_dealerships:ui:forceUpdate', false, function(success)
        if success then
            Custom.Notify(locale('notifications.data_updated'), 'success')
        else
            Custom.Notify(locale('notifications.error_updating_data'), 'error')
        end
        cb(success)
    end)
end)

-- Callback para configuración individual de ubicaciones
RegisterNUICallback('setupIndividualLocation', function(data, cb)
    
    setupIndividualLocation(data.dealershipId, data.locationType, data.currentData, function(result)
        
        if result then
            -- Enviar datos al servidor para guardar
            lib.callback('origen_dealerships:ui:updateIndividualLocation', false, function(success)
                if success then
                    Custom.Notify(locale('notifications.locations_updated'))
                    -- Recargar panel de administración
                    lib.callback('origen_dealerships:ui:getDealerships', false, function(dealerships)
                        SendNUIMessage({
                            action = 'refreshDealerships',
                            dealerships = dealerships
                        })
                    end)
                else
                    Custom.Notify(locale('notifications.error_updating_locations'))
                end
                cb(success)
            end, result)
        else
            cb(false)
        end
    end)
end)

-- La NUI avisa al cambiar de pestaña en el modo de colocar puntos. Nadie lo
-- escuchaba y la petición se quedaba sin respuesta.
RegisterNUICallback('changeCreatorTab', function(_, cb)
    cb(true)
end)

RegisterNUICallback('prepareLocationPlacement', function(_, cb)
    -- Cerrar solo el foco de NUI para poder colocar puntos en mundo
    -- sin pasar por el flujo de cierre global (hub/fades externos).
    SetNuiFocus(false, false)
    cb(true)
end)

RegisterNUICallback('maintainNuiFocus', function(data, cb)
    SetNuiFocus(true, true)
    cb(true)
end)

-- Callback para obtener traducciones desde el frontend
RegisterNUICallback('getTranslations', function(data, cb)
    local translations = lib.callback.await('origen_dealerships:getTranslations', false)
    cb(translations)
end)

exports('GeneratePlate', function()
    return lib.callback.await('origen_dealership:sv:generatePlate', false)
end)

--[[ Los avisos de la NUI (compra, financiación, fotos del admin...) van a
     origen_notify, como los del resto del servidor: la pantalla ya no pinta
     los suyos. Solo texto y un tipo de la lista; lo demás se ignora. Si
     origen_notify no está arrancado, se cae a Custom.Notify. ]]
local TIPOS_AVISO = { success = true, error = true, info = true, warning = true }

RegisterNUICallback('notificar', function(data, cb)
    cb('ok')
    if type(data) ~= 'table' or type(data.description) ~= 'string' or data.description == '' then return end
    local texto = data.description:sub(1, 200)
    local tipo = TIPOS_AVISO[data.type] and data.type or 'info'
    local dura = math.min(tonumber(data.duration) or 5000, 10000)
    if GetResourceState('origen_notify') == 'started' then
        local ok = pcall(function()
            exports.origen_notify:Notify({ title = 'Concesionario', description = texto, type = tipo, duration = dura })
        end)
        if ok then return end
    end
    Custom.Notify(texto, tipo, dura)
end)
