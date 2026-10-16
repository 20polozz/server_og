local businessPanelAnim = {
    active = false,
    prop = nil
}

local TABLET_ANIM_DICT = 'amb@world_human_seat_wall_tablet@female@base'
local TABLET_ANIM_NAME = 'base'
local TABLET_PROP = `prop_cs_tablet`

function StartBusinessPanelTabletAnim()
    local ped = PlayerPedId()
    if not ped or ped == 0 then return end
    if IsPedInAnyVehicle(ped, false) then return end

    if not HasAnimDictLoaded(TABLET_ANIM_DICT) then
        RequestAnimDict(TABLET_ANIM_DICT)
        local timeout = GetGameTimer() + 3000
        while not HasAnimDictLoaded(TABLET_ANIM_DICT) and GetGameTimer() < timeout do
            Wait(0)
        end
    end

    if not businessPanelAnim.prop or not DoesEntityExist(businessPanelAnim.prop) then
        local pedCoords = GetEntityCoords(ped)
        local prop = CreateObject(TABLET_PROP, pedCoords.x, pedCoords.y, pedCoords.z + 0.2, true, true, false)
        if prop and prop ~= 0 then
            AttachEntityToEntity(
                prop,
                ped,
                GetPedBoneIndex(ped, 60309),
                0.03, 0.002, 0.0,
                10.0, 160.0, 0.0,
                true, true, false, true, 1, true
            )
            businessPanelAnim.prop = prop
        end
    end

    TaskPlayAnim(ped, TABLET_ANIM_DICT, TABLET_ANIM_NAME, 3.0, 3.0, -1, 49, 0.0, false, false, false)
    businessPanelAnim.active = true
end

function StopBusinessPanelTabletAnim()
    local ped = PlayerPedId()
    if ped and ped ~= 0 then
        StopAnimTask(ped, TABLET_ANIM_DICT, TABLET_ANIM_NAME, 1.0)
        ClearPedSecondaryTask(ped)
    end

    if businessPanelAnim.prop and DoesEntityExist(businessPanelAnim.prop) then
        DeleteEntity(businessPanelAnim.prop)
    end

    businessPanelAnim.prop = nil
    businessPanelAnim.active = false
end

--[[ Los modos de colocar (zona, entidad) sueltan el foco y se cancelan con
     ESC o se usan con el. Sin foco, ese ESC le llegaba tambien al radial de
     origen_hud, que se abria; y al acabar el modo este recurso volvia a
     coger el foco: dos recursos con el raton a la vez. El radial respeta
     `mirandoCamara` (como en las camaras y la previa de carteles). Se quita
     un poco despues para que el mismo toque no lo abra al soltar. ]]
local function AvisoSinRadial(activo)
    if activo then
        LocalPlayer.state:set('mirandoCamara', true, false)
    else
        SetTimeout(400, function() LocalPlayer.state:set('mirandoCamara', false, false) end)
    end
end

RegisterNUICallback('closePanel', function(data, cb)
    StopBusinessPanelTabletAnim()
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('deleteInvoice', function(data, cb)
    lib.callback('origen_businesses:cb:deleteInvoice', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('notify', function(data, cb)
    Custom.Notify({
        title = data.title or 'Negocios',
        description = data.description or data.message or '',
        type = data.type or 'inform'
    })
    cb('ok')
end)

RegisterNUICallback('toggleDuty', function(id, cb)
    lib.callback('origen_businesses:cb:toggleDuty', false, function(result)
        cb(result)
    end, id)
end)

RegisterNUICallback('toggleBusinessState', function(id, cb)
    lib.callback('origen_businesses:cb:toggleBusinessState', false, function(result)
        cb(result)
    end, id)
end)

RegisterNUICallback('createBusiness', function(data, cb)
    lib.callback('origen_businesses:cb:createBusiness', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('getOrders', function(data, cb)
    lib.callback('origen_businesses:cb:getOrders', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('tallerOverview', function(data, cb)
    lib.callback('origen_businesses:cb:taller:overview', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('tallerSetLabor', function(data, cb)
    lib.callback('origen_businesses:cb:taller:setLabor', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('tallerBuyParts', function(data, cb)
    lib.callback('origen_businesses:cb:taller:buyParts', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('tallerTakePart', function(data, cb)
    lib.callback('origen_businesses:cb:taller:takePart', false, function(result)
        cb(result)
    end, data)
end)

--[[ Las órdenes de trabajo son de `origen_mechanic`: este panel solo las pinta
     y pide el cambio de estado. El guard evita que el panel reviente si el
     recurso del taller no está arrancado. ]]
RegisterNUICallback('tallerOrderAction', function(data, cb)
    if GetResourceState('origen_mechanic') ~= 'started' then
        return cb({ success = false, message = 'El sistema de mecánica no está disponible.' })
    end

    local acciones = {
        finish = 'origen_mechanic:cb:finishWorkOrder',
        bill = 'origen_mechanic:cb:billWorkOrder',
        cancel = 'origen_mechanic:cb:cancelWorkOrder'
    }

    local callback = acciones[type(data) == 'table' and data.action or '']
    if not callback then
        return cb({ success = false, message = 'Acción no válida.' })
    end

    lib.callback(callback, false, function(result)
        cb(type(result) == 'table' and result or { success = false, message = 'Sin respuesta del servidor.' })
    end, { orderId = tonumber(data.orderId) })
end)

RegisterNUICallback('getInventory', function(data, cb)
    lib.callback('origen_businesses:cb:getInventory', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('getInvoices', function(data, cb)
    lib.callback('origen_businesses:cb:getInvoices', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('resendOpenMessage', function(data, cb)
    lib.callback('origen_businesses:cb:resendOpenMessage', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('createInvoice', function(data, cb)
    lib.callback('origen_businesses:cb:createInvoice', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('getBusinessAnalytics', function(data, cb)
    lib.callback('origen_businesses:cb:getBusinessAnalytics', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('getEmployeeInsights', function(data, cb)
    lib.callback('origen_businesses:cb:getEmployeeInsights', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('resetRanking', function(data, cb)
    lib.callback('origen_businesses:cb:resetRanking', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('getBusinessVehicles', function(data, cb)
    lib.callback('origen_businesses:cb:getBusinessVehicles', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('buyBusinessVehicle', function(data, cb)
    lib.callback('origen_businesses:cb:buyBusinessVehicle', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('spawnBusinessVehicle', function(data, cb)
    lib.callback('origen_businesses:cb:spawnBusinessVehicle', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('deleteBusinessVehicle', function(data, cb)
    lib.callback('origen_businesses:cb:deleteBusinessVehicle', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('storeCurrentBusinessVehicle', function(data, cb)
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 then
        cb({ success = false, message = 'Debes estar dentro del vehículo para guardarlo.' })
        return
    end

    if GetPedInVehicleSeat(vehicle, -1) ~= ped then
        cb({ success = false, message = 'Debes ser el conductor para guardar el vehículo.' })
        return
    end

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    if not netId or netId == 0 then
        cb({ success = false, message = 'No se pudo identificar el vehículo.' })
        return
    end

    data.netId = netId
    lib.callback('origen_businesses:cb:storeBusinessVehicle', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('updatePrice', function(data, cb)
    lib.callback('origen_businesses:cb:updatePrice', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('withdrawInventoryUnits', function(data, cb)
    lib.callback('origen_businesses:cb:withdrawInventoryUnits', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('getLogs', function(data, cb)
    lib.callback('origen_businesses:cb:getLogs', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('depositMoney', function(data, cb)
    lib.callback('origen_businesses:cb:deposit', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('withdrawMoney', function(data, cb)
    lib.callback('origen_businesses:cb:withdraw', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('updateGrade', function(data, cb)
    lib.callback('origen_businesses:cb:updateGrade', false, function(result)
        cb(result)
    end, data)
end)


RegisterNUICallback('adminGetBusinesses', function(data, cb)
    lib.callback('origen_businesses:cb:adminGetBusinesses', false, function(result)
        cb(result)
    end)
end)

RegisterNUICallback('getCurrentCoords', function(data, cb)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    
    cb({
        coords = {
            x = math.floor(coords.x * 100) / 100,
            y = math.floor(coords.y * 100) / 100,
            z = math.floor(coords.z * 100) / 100,
            w = math.floor(heading * 100) / 100
        }
    })
end)

RegisterNUICallback('teleportToCoords', function(data, cb)
    if not data or not data.x or not data.y or not data.z then
        cb('ok')
        return
    end
    
    local ped = PlayerPedId()
    SetEntityCoords(ped, data.x, data.y, data.z, false, false, false, true)
    if data.w then
        SetEntityHeading(ped, data.w)
    end
    
    Custom.Notify({
        title = 'Teletransporte',
        description = 'Te has teletransportado al punto.',
        type = 'success'
    })
    
    cb('ok')
end)

RegisterNUICallback('unfocus', function(data, cb)
    local eraAdmin = AdminNegociosAbierto
    AdminNegociosAbierto = false
    StopBusinessPanelTabletAnim()
    SetNuiFocus(false, false)
    cb('ok')

    -- ESC en el panel de admin: si se abrió desde la pestaña Scripts del
    -- admin, se vuelve a ella. origen_admin solo vuelve si este panel salió
    -- de su lista; los demás paneles que cierran por aquí no vuelven.
    if eraAdmin and GetResourceState('origen_admin') == 'started' then
        SetTimeout(80, function()
            pcall(function() exports['origen_admin']:ReturnToScripts() end)
        end)
    end
end)

RegisterNUICallback('adminUpdateBusiness', function(data, cb)
    lib.callback('origen_businesses:cb:adminUpdateBusiness', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('useRaycast', function(data, cb)
    SetNuiFocus(false, false)
    local model = data.model or data.type == 'vehicle' and 'sultan' or 'player_one'
    local tipo = data.type

    --[[ El punto de carga del móvil se coloca viendo su poste (04/10): el
         mismo fantasma que el mueble de la cocina (rueda gira, Mayús fino,
         clic confirma, clic derecho cancela). Los paneles mandan en `punto`
         qué punto se coloca; el modelo lo decide config/carga.lua, no la
         página. Si el recurso del prop no está, se queda el muñeco de antes. ]]
    local esCarga = data.punto == 'carga'
    if esCarga then
        local poste = Carga.ModeloPrevia()
        if poste then
            tipo, model = 'prop', poste
            -- Si se está moviendo uno que ya existe, su poste fuera mientras
            -- tanto: el rayo chocaba con él
            Carga.Apartar(data.coords)
        end
    end

    -- Con pcall: un modelo que no existe o origen_hud parado daban error aqui,
    -- y sin cb ni foco la NUI se quedaba apartada (invisible) esperando.
    -- Sin foco, un ESC le llegaba al radial del HUD, y al volver se cogia el
    -- foco otra vez: dos recursos a la vez con el raton. Ver AvisoSinRadial.
    AvisoSinRadial(true)
    local ok, coords = pcall(Utils.EntityPositioning, tipo, model, data.coords)
    AvisoSinRadial(false)
    if esCarga then Carga.Apartar(nil) end
    if not ok then
        print(('^1[origen_businesses] useRaycast: %s^0'):format(coords))
        coords = nil
    end

    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    if coords then
        local coordsTable = {
            x = math.floor(coords.x * 100) / 100,
            y = math.floor(coords.y * 100) / 100,
            z = math.floor(coords.z * 100) / 100,
            -- Dentro de la vuelta: la previsualización devuelve el rumbo + 0,1
            -- y un 360,05 no pasa la validación del servidor
            w = math.floor((coords.w % 360.0) * 100) / 100
        }
        cb(coordsTable)
    else
        cb(nil)
    end
end)

RegisterNUICallback('getNearPlayers', function(data, cb)
    local coords = GetEntityCoords(PlayerPedId())
    local players = lib.getNearbyPlayers(coords, 10, true)
    local playerIds = {}

    for i, player in ipairs(players) do
        local serverID = GetPlayerServerId(player.id)
        playerIds[i] = serverID
    end

    lib.callback('origen_businesses:cb:getPlayersData', false, function(result)
        cb(result)
    end, playerIds)
end)

RegisterNUICallback('changeEmployeeGrade', function(data, cb)
    lib.callback('origen_businesses:cb:changeEmployeeGrade', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('forceSetDuty', function(data, cb)
    lib.callback('origen_businesses:cb:forceSetDuty', false, function(result)
        cb(result)
    end, data)
end)


-- NO TOCAR

RegisterNUICallback('hireEmployee', function(data, cb)
    lib.callback('origen_businesses:cb:hireEmployee', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('fireEmployee', function(data, cb)
    lib.callback('origen_businesses:cb:fireEmployee', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('saveGrade', function(data, cb)
    lib.callback('origen_businesses:cb:saveGrade', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('removeGrade', function(data, cb)
    lib.callback('origen_businesses:cb:removeGrade', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('migrateGradeEmployees', function(data, cb)
    lib.callback('origen_businesses:cb:migrateGradeEmployees', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('savePoint', function(data, cb)
    lib.callback('origen_businesses:cb:savePoint', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('saveOpenMessage', function(data, cb)
    lib.callback('origen_businesses:cb:saveOpenMessage', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('saveLogo', function(data, cb)
    lib.callback('origen_businesses:cb:saveLogo', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('removePoint', function(data, cb)
    lib.callback('origen_businesses:cb:removePoint', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('deleteBusiness', function(data, cb)
    lib.callback('origen_businesses:cb:deleteBusiness', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('placeOrder', function(data, cb)
    lib.callback('origen_businesses:cb:placeOrder', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('saveCatalogItem', function(data, cb)
    lib.callback('origen_businesses:cb:saveCatalogItem', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('removeCatalogItem', function(data, cb)
    lib.callback('origen_businesses:cb:removeCatalogItem', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('addCatalogVehicle', function(data, cb)
    local model = GetDisplayNameFromVehicleModel(data.model)
    local name = GetLabelText(model)
    local brand = GetLabelText(GetMakeNameFromVehicleModel(model))

    data.label = brand..' '..name

    lib.callback('origen_businesses:cb:addCatalogVehicle', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('editCatalogVehicle', function(data, cb)
    local model = GetDisplayNameFromVehicleModel(data.model)
    local name = GetLabelText(model)
    local brand = GetLabelText(GetMakeNameFromVehicleModel(model))

    data.label = brand..' '..name

    lib.callback('origen_businesses:cb:editCatalogVehicle', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('removeCatalogVehicle', function(data, cb)
    lib.callback('origen_businesses:cb:removeCatalogVehicle', false, function(result)
        cb(result)
    end, data)
end)

RegisterNetEvent('origen_businesses:client:businessRealtimeUpdate', function(businessId)
    local payload = lib.callback.await('origen_businesses:cb:getManagementData', false, businessId)
    if payload and payload.business then
        SendNUIMessage({
            action = 'updateBusiness',
            data = payload.business
        })
    end
end)

RegisterNUICallback('dj_trackEnded', function(data, cb)
    TriggerServerEvent('origen_businesses:dj:trackEnded', {
        zoneId = tostring(data.zoneId or '')
    })
    cb('ok')
end)

RegisterNUICallback('startPolyzoneCreation', function(data, cb)
    SetNuiFocus(false, false)
    
    Citizen.CreateThread(function()
        -- Con pcall por lo mismo que useRaycast: si falla, la NUI no se
        -- queda apartada esperando un cb que no llega.
        -- ESC cancela la zona, y sin foco ese ESC abria tambien el radial.
        AvisoSinRadial(true)
        local ok, result = pcall(Creation.CreateZone, Creation)
        AvisoSinRadial(false)
        if not ok then
            print(('^1[origen_businesses] startPolyzoneCreation: %s^0'):format(result))
            result = nil
            Creation.active = false
            if Freecam and Freecam.active then
                pcall(Freecam.DestroyCam, Freecam)
            end
        end

        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(false)
        if result then
            -- Convertimos los vectores a tablas para el JSON de la NUI
            local points = {}
            for i=1, #result.points do
                points[i] = { x = result.points[i].x, y = result.points[i].y, z = result.points[i].z }
            end
            
            SendNUIMessage({
                action = 'setPolyzonePoints', -- Necesitaremos manejar esto en el JS o simplemente responder al CB
                points = points,
                thickness = result.thickness
            })
            cb({
                points = points,
                thickness = result.thickness
            }) -- El CB de la NUI recibirá los puntos y el grosor
        else
            cb(false)
        end
    end)
end)

RegisterNUICallback('adminAddXP', function(data, cb)
    lib.callback('origen_businesses:cb:adminAddXP', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('getXPRewards', function(data, cb)
    lib.callback('origen_businesses:cb:getXPRewards', false, function(result)
        cb(result)
    end)
end)

RegisterNUICallback('updateXPRewards', function(data, cb)
    lib.callback('origen_businesses:cb:updateXPRewards', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('getLevelUnlocks', function(data, cb)
    lib.callback('origen_businesses:cb:getLevelUnlocks', false, function(result)
        cb(result)
    end)
end)

RegisterNUICallback('updateLevelUnlocks', function(data, cb)
    lib.callback('origen_businesses:cb:updateLevelUnlocks', false, function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('getAllCrafts', function(data, cb)
    lib.callback('origen_businesses:server:getAllCrafts', false, function(result)
        cb(result)
    end)
end)

RegisterNUICallback('saveCraft', function(data, cb)
    TriggerServerEvent('origen_businesses:server:saveCraft', data)
    cb('ok')
end)

RegisterNUICallback('deleteCraft', function(id, cb)
    TriggerServerEvent('origen_businesses:server:deleteCraft', id)
    cb('ok')
end)

RegisterNUICallback('adminGiveIngredients', function(data, cb)
    TriggerServerEvent('origen_businesses:server:adminGiveIngredients', data)
    cb('ok')
end)

RegisterNUICallback('getInventoryItems', function(data, cb)
    lib.callback('origen_businesses:cb:getInventoryItems', false, function(result)
        cb(result)
    end)
end)

RegisterNUICallback('closeCraftingPanel', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('startCraft', function(craft, cb)
    SetNuiFocus(false, false)
    cb('ok')
    local quantity = math.max(1, math.floor(tonumber(craft.quantity) or 1))

    -- Comprobar materiales antes de empezar la barra de progreso
    if craft.ingredients and type(craft.ingredients) == 'table' then
        for _, ing in ipairs(craft.ingredients) do
            local itemName = tostring(ing.item or ''):gsub('^%s*(.-)%s*$', '%1'):lower()
            local needed = math.max(1, math.floor(tonumber(ing.amount or 1) or 1)) * quantity 
            if not exports.origen_inventory:hasItem(itemName, needed) then
                 Custom.Notify({
                    title = 'Crafteos',
                    description = ('No tienes suficientes materiales: %s (necesitas %dx)'):format(ing.label or ing.item, needed),
                    type = 'error'
                })
                return
            end
        end
    end

    local totalTime = craft.time * quantity
    local label = ('Preparando %s (x%d)'):format(craft.label, quantity)

    if lib.progressBar({
        duration = totalTime,
        label = label,
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true
        },
        anim = {
            dict = 'mini@repair',
            clip = 'fixing_a_ped'
        },
    }) then
        local success, message = lib.callback.await('origen_businesses:server:startCrafting', false, craft.id, quantity)
        if success then
            Custom.Notify({
                title = 'Crafteos',
                description = ('Has terminado de preparar %s (x%d)'):format(craft.label, quantity),
                type = 'success'
            })
        else
            Custom.Notify({
                title = 'Crafteos',
                description = message or 'No has podido terminar el crafteo.',
                type = 'error'
            })
        end
    end
end)

-- INTEGRACIÓN COMPRAVENTA
-- Cada uno cierra el panel en la NUI: soltando solo el foco, se quedaba
-- puesto y congelado detras del menu de compraventa.
RegisterNUICallback('compraventa_buy', function(data, cb)
    StopBusinessPanelTabletAnim()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeBusinessPanel' })
    cb('ok')
    CreateThread(function()
        Wait(150)
        Compraventa.AbrirCompra({ businessId = data.businessId })
    end)
end)

RegisterNUICallback('compraventa_stock', function(data, cb)
    StopBusinessPanelTabletAnim()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeBusinessPanel' })
    cb('ok')
    CreateThread(function()
        Wait(150)
        Compraventa.AbrirGaraje({ businessId = data.businessId })
    end)
end)

RegisterNUICallback('compraventa_manage', function(data, cb)
    StopBusinessPanelTabletAnim()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeBusinessPanel' })
    cb('ok')
    CreateThread(function()
        Wait(150)
        Compraventa.GestionarVehiculoActual({ businessId = data.businessId })
    end)
end)

RegisterNUICallback('compraventa_transfer', function(data, cb)
    StopBusinessPanelTabletAnim()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeBusinessPanel' })
    cb('ok')
    CreateThread(function()
        Wait(150)
        Compraventa.AbrirTraspaso({ businessId = data.businessId })
    end)
end)

RegisterNUICallback('openAdminProfile', function(data, cb)
    cb('ok')
    local hasPermission = false
    if GetResourceState('origen_admin') == 'started' then
        hasPermission = exports['origen_admin']:HasPermission('AdminMenu')
    end
    
    if hasPermission then
        --[[ Con el id de servidor, si está conectado.

             De un empleado solo se guarda el citizenid, y la ficha del panel
             de admin lo necesita para enseñar su ID y para traerlo o ir a él:
             sin esto salía la ficha sin ID y esos botones no hacían nada, así
             que había que salir a buscarlo a la lista de usuarios. ]]
        local cid = data.cid or ''
        local idEnLaCiudad = cid ~= ''
            and lib.callback.await('origen_businesses:cb:idDeCiudadano', false, cid)
            or nil

        local target = {
            id = idEnLaCiudad,
            name = data.name or 'Unknown',
            citizenid = cid
        }
        exports['origen_admin']:openManagement(target, true)
    else
        exports['origen_notify']:Notify({
            description = 'No tienes permisos de administrador para realizar esta acción.',
            type = 'error',
            duration = 6000
        })
    end
end)

RegisterNUICallback('openBusinessAsAdmin', function(data, cb)
    cb('ok')
    AdminNegociosAbierto = false
    StopBusinessPanelTabletAnim()
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'closeAdminPanel'
    })
    
    CreateThread(function()
        Wait(300)
        local businessId = data and data.businessId
        if not businessId then return end

        local idNum = tonumber(businessId)
        local idStr = tostring(businessId)
        local business = Business.Instances[idNum] or Business.Instances[idStr]
        if business then
            business:OpenManagement(true)
        end
    end)
end)

RegisterNetEvent('origen_businesses:client:restoreFocus', function()
    -- Solo si el panel de admin sigue delante: si no, el raton se quedaba
    -- preso sin nada en pantalla.
    if not AdminNegociosAbierto then return end
    SetNuiFocus(true, true)
end)

--[[ Si el vigilante comun (@origen_map/shared/foco.lua) suelta el raton a la
     fuerza, se recogen las pantallas de siempre que no llevan su propia
     cuenta: el cuadro de mando, el admin de negocios y el menu de crafteo.
     Si no, quedaban pintadas sin raton, con la tablet en la mano y, el admin,
     con AdminNegociosAbierto en true (restoreFocus le volveria a dar el
     raton a una pantalla que ya no deberia estar).

     La pagina solo cierra lo que tenga abierto (cada mensaje mira lo suyo),
     y la animacion solo se para si estaba puesta: ClearPedSecondaryTask se
     llevaria la de cualquier otro recurso. ]]
OrigenFoco.AlSoltar(function()
    AdminNegociosAbierto = false
    if businessPanelAnim.active then StopBusinessPanelTabletAnim() end
    SendNUIMessage({ action = 'closeBusinessPanel' })
    SendNUIMessage({ action = 'closeAdminPanel' })
    SendNUIMessage({ action = 'closeCraftingPanel' })
end)
