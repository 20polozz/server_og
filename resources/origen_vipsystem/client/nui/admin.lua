--* NUI CALLBACKS — PANEL ADMIN

-- Carga inicial al abrir el panel
RegisterNUICallback('admin:init', function(_, cb)
    local data = lib.callback.await('origen_vipsystem:server:adminInit', false)
    cb(data or { error = true })
end)

RegisterNUICallback('admin:getBusinesses', function(_, cb)
    local res = lib.callback.await('origen_vipsystem:server:adminGetBusinesses', false)
    cb(res or { success = false, businesses = {}, requests = {} })
end)

RegisterNUICallback('admin:uploadBusinessImage', function(data, cb)
    if GetResourceState('origen_uploader') ~= 'started' then
        cb({ success = false, msg = 'El sistema de subida de imágenes no está activo.' })
        return
    end
    if type(data and data.businessId) ~= 'string' or type(data and data.image) ~= 'string'
        or type(data and data.name) ~= 'string' then
        cb({ success = false, msg = 'Selecciona una imagen válida.' })
        return
    end
    if #data.image > 9500000 or #data.name > 160 then
        cb({ success = false, msg = 'La imagen supera el límite permitido.' })
        return
    end

    local preparedOk, ticket, reason = pcall(function()
        return exports['origen_uploader']:PrepararSubida(data.name, data.image)
    end)
    if not preparedOk or type(ticket) ~= 'string' or ticket == '' then
        cb({ success = false, msg = reason or 'No se pudo preparar la imagen.' })
        return
    end

    local res = lib.callback.await('origen_vipsystem:server:adminUploadBusinessImage', 60000, {
        businessId = data.businessId,
        ticket = ticket,
    })
    cb(res or { success = false, msg = 'FiveManage no respondió a tiempo.' })
end)

RegisterNUICallback('admin:setBusinessListing', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:adminSetBusinessListing', false, data)
    cb(res or { success = false })
end)

RegisterNUICallback('admin:decideBusinessRequest', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:adminDecideBusinessRequest', false, data)
    cb(res or { success = false })
end)

-- Agregar VIP
RegisterNUICallback('admin:addVip', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:adminAddVip', false, data)
    cb(res or { success = false })
end)

-- Eliminar VIP
RegisterNUICallback('admin:deleteVip', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:adminDeleteVip', false, data)
    cb(res or { success = false })
end)

-- Editar VIP
RegisterNUICallback('admin:editVip', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:adminEditVip', false, data)
    cb(res or { success = false })
end)

-- Generar código
RegisterNUICallback('admin:generateCode', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:adminGenerateCode', false, data)
    cb(res or { success = false })
end)

-- Eliminar código
RegisterNUICallback('admin:deleteCode', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:adminDeleteCode', false, data)
    cb(res or { success = false })
end)

-- Agregar tipo de VIP
RegisterNUICallback('admin:addVipType', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:adminAddVipType', false, data)
    cb(res or { success = false })
end)

-- Editar tipo de VIP
RegisterNUICallback('admin:editVipType', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:adminEditVipType', false, data)
    cb(res or { success = false })
end)

-- Eliminar tipo de VIP
RegisterNUICallback('admin:deleteVipType', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:adminDeleteVipType', false, data)
    cb(res or { success = false })
end)

-- Guardar configuración
RegisterNUICallback('admin:saveSettings', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:adminSaveSettings', false, data)
    cb(res or { success = false })
end)

-- Refrescar jugadores online
RegisterNUICallback('admin:getOnlinePlayers', function(_, cb)
    local res = lib.callback.await('origen_vipsystem:server:adminGetOnlinePlayers', false)
    cb(res or {})
end)

-- Historial de usos de un código
RegisterNUICallback('admin:getCodeHistory', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:adminGetCodeHistory', false, data)
    cb(res or { success = false, history = {} })
end)

-- Categorias de la tienda
RegisterNUICallback('admin:getStoreCategories', function(_, cb)
    local res = lib.callback.await('origen_vipsystem:server:adminGetStoreCategories', false)
    cb(res or { success = false, storeCategories = {} })
end)

RegisterNUICallback('admin:addStoreCategory', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:adminAddStoreCategory', false, data)
    cb(res or { success = false })
end)

RegisterNUICallback('admin:editStoreCategory', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:adminEditStoreCategory', false, data)
    cb(res or { success = false })
end)

RegisterNUICallback('admin:deleteStoreCategory', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:adminDeleteStoreCategory', false, data)
    cb(res or { success = false })
end)

-- Obtener productos de la tienda (refresh al abrir el tab)
RegisterNUICallback('admin:getStoreItems', function(_, cb)
    local res = lib.callback.await('origen_vipsystem:server:adminGetStoreItems', false)
    cb(res or { success = false, storeItems = {} })
end)

-- Garajes donde se puede depositar un vehiculo entregado
RegisterNUICallback('admin:getVehicleGarages', function(_, cb)
    local res = lib.callback.await('origen_vipsystem:server:adminGetVehicleGarages', false)
    cb(res or { success = false, garages = {} })
end)

-- Agregar producto a la tienda
RegisterNUICallback('admin:addStoreItem', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:adminAddStoreItem', false, data)
    cb(res or { success = false })
end)

-- Editar producto de la tienda
RegisterNUICallback('admin:editStoreItem', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:adminEditStoreItem', false, data)
    cb(res or { success = false })
end)

-- Eliminar producto de la tienda
RegisterNUICallback('admin:deleteStoreItem', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:adminDeleteStoreItem', false, data)
    cb(res or { success = false })
end)

RegisterNUICallback('admin:getCoins', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:adminGetCoins', false, data)
    cb(res or { success = false, wallets = {} })
end)

RegisterNUICallback('admin:getCoinHistory', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:adminGetCoinHistory', false, data)
    cb(res or { success = false, transactions = {}, total = 0, page = 1, pageCount = 1, reasons = {} })
end)

RegisterNUICallback('admin:addCoins', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:adminAddCoins', false, data)
    cb(res or { success = false })
end)

RegisterNUICallback('admin:removeCoins', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:adminRemoveCoins', false, data)
    cb(res or { success = false })
end)

RegisterNUICallback('admin:setCoins', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:adminSetCoins', false, data)
    cb(res or { success = false })
end)

-- ─── Sorteos ──────────────────────────────────────────────────────────────────

RegisterNUICallback('admin:getRaffles', function(_, cb)
    local res = lib.callback.await('origen_vipsystem:server:adminGetRaffles', false)
    cb(res or { success = false })
end)

RegisterNUICallback('admin:createRaffle', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:adminCreateRaffle', false, data)
    cb(res or { success = false })
end)

RegisterNUICallback('admin:editRaffle', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:adminEditRaffle', false, data)
    cb(res or { success = false })
end)

RegisterNUICallback('admin:cancelRaffle', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:adminCancelRaffle', false, data)
    cb(res or { success = false })
end)

RegisterNUICallback('admin:drawRaffle', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:adminDrawRaffle', false, data)
    cb(res or { success = false })
end)

RegisterNUICallback('admin:getRaffleEntries', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:adminGetRaffleEntries', false, data)
    cb(res or { success = false })
end)

-- ─── Suscripciones ────────────────────────────────────────────────────────────

RegisterNUICallback('admin:getSubscriptions', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:adminGetSubscriptions', false, data)
    cb(res or { success = false, subscriptions = {} })
end)

RegisterNUICallback('admin:getSubscriptionCharges', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:adminGetSubscriptionCharges', false, data)
    cb(res or { success = false, charges = {} })
end)

RegisterNUICallback('admin:cancelSubscription', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:adminCancelSubscription', false, data)
    cb(res or { success = false })
end)

RegisterNUICallback('admin:resumeSubscription', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:adminResumeSubscription', false, data)
    cb(res or { success = false })
end)

RegisterNUICallback('admin:forceChargeSubscription', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:adminForceChargeSubscription', false, data)
    cb(res or { success = false })
end)

RegisterNUICallback('admin:extendSubscriptionGrace', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:adminExtendSubscriptionGrace', false, data)
    cb(res or { success = false })
end)

-- El alta de un producto «Mascota»: ¿ese codigo de spawn existe en este servidor
-- y es un animal o un ped? Lo sabe el juego, no el servidor.
RegisterNUICallback('admin:modeloMascota', function(data, cb)
    local modelo = type(data) == 'table' and tostring(data.modelo or '') or ''
    if modelo == '' then return cb({ ok = false }) end
    local hash = joaat(modelo)
    -- Los natives contestan 1, no true: se pasa a booleano o la interfaz, que
    -- espera true, daba por inexistente un modelo que si esta.
    cb({ ok = (IsModelInCdimage(hash) and IsModelAPed(hash)) and true or false, visto = true })
end)
