local buildNumber = GetGameBuildNumber()
local closeMenuCallbacks = {}
local creationManuallyTriggered = false
MenuType = nil
local menuOpenClothesHashes = nil
local screenshotBatchState = {
    started = false,
    running = false
}

-- Reverse index lookups: component/prop index → category name.
-- Used to capture the old ped state BEFORE a preview modifies it,
-- preventing the new item hash from being stored as "old clothes" and
-- ending up in the inventory after purchase.
local drawableIndexToCategory = {}
local propIndexToCategory = {}
for cat, v in pairs(AppearanceData.drawables) do
    drawableIndexToCategory[v.index] = cat
end
for cat, v in pairs(AppearanceData.props) do
    propIndexToCategory[v.index] = cat
end


function RegisterCloseMenuCallback(callback)
    if type(callback) == "function" then
        table.insert(closeMenuCallbacks, callback)
    end
end

function OpenClothing(menu, options)
    MenuType = menu
    if options and options.creationTriggered then
        creationManuallyTriggered = true
    end
    if not IsAdmin.fetched then
        IsAdmin.fetched = true
        IsAdmin.value = lib.callback.await("origen_clothing:isAdmin", false)
    end

    local ped = GetPedCamera()
    UpdateTotals(ped)

    if menu == 'clothes' or menu == 'stock' or menu == 'outfitCreator' then
        local fromOptions = options and options.actualClothes
        menuOpenClothesHashes = fromOptions or GetPedAllHashes(ped, true)
    else
        menuOpenClothesHashes = nil
    end
    
    HairSlot.Fetch()
    local data = {
        action = 'openMenu',
        type = menu,
        admin = IsAdmin.value,
        gender = GetPedGender(ped),
        serverId = GetPlayerServerId(PlayerId()),
        model = GetEntityModelName(GetEntityModel(ped)),
    }
    for k, v in pairs(options or {}) do
        data[k] = v
    end

    SendNUIMessage(data)

    --[[ Fuera el rastreador de misiones y el logo de origen_notify mientras
         te vistes: la columna les cae encima. Es el mismo evento que usan el
         radial de origen_hud y el menu de animaciones; los dos escuchan la
         misma señal, asi que con avisar una vez valen ambos. ]]
    TriggerEvent('qv2:suppressHud', true)
    -- Y el minimapa: en la tienda y en la creacion del personaje sobra, y con el
    -- ajuste «siempre» se quedaba en la esquina encima del probador.
    if GetResourceState('origen_map') == 'started' then exports.origen_map:Apartar(true) end

    -- Solo activar focus si no se especifica delayFocus.
    -- Va DETRAS del mensaje que abre la pantalla: HairSlot.Fetch() puede
    -- esperar al servidor, y con el foco puesto antes el jugador se quedaba
    -- ese rato con el cursor sobre una pantalla que aun no existia.
    if not (options and options.delayFocus) then
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(false)
    end

    local staticPedMenus = {
        ['clothes'] = true, 
        ['stock'] = true, 
        ['barber'] = true,
        ['outfitCreator'] = true,
    }

    
    if staticPedMenus[menu] then
        CreationPed = ped
        CreateThread(function()
            StartCreationThread()
        end)
    end
end

function RestoreMenuOpenClothesHashes()
    if not menuOpenClothesHashes then return end
    local ped = GetPedCamera()
    if not ped or ped == 0 then return end

    for category, hash in pairs(menuOpenClothesHashes) do
        if type(hash) == "string" and hash ~= "" then
            if IsProp(category) then
                SetPedPropByHash(ped, hash)
            else
                SetPedDrawableByHash(ped, hash)
            end
        end
    end
end

RegisterNUICallback("closeMenu", function(data, cb)
    -- Lo primero: la pantalla ya se ha cerrado. En la peluqueria
    -- SaveAppearance() espera al servidor, y mientras tanto el raton se quedaba
    -- preso sin nada delante.
    SetNuiFocus(false, false)
    -- Y vuelven al cerrar.
    TriggerEvent('qv2:suppressHud', false)
    if GetResourceState('origen_map') == 'started' then exports.origen_map:Apartar(false) end
    ClearPedTasks(cache.ped)
    if data.gestion then
        TriggerServerEvent('origen_clothing:gestion:salir')
        data.buyStock = nil -- en gestion no se compra: vuelve la ropa de antes
    end
    if data.menuType == "barber" then
        SaveAppearance()
    end
    if data.creation and not creationManuallyTriggered then
        EndPedCreation()
    else
        -- Si es un menú de creación pero fue cancelado manualmente, ejecutar callback de cancelación
        if data.creation and creationManuallyTriggered and GetMulticharacterCallbacks then
            local multicharacterCallbacks = GetMulticharacterCallbacks()
            if multicharacterCallbacks and multicharacterCallbacks.cancel then
                multicharacterCallbacks.cancel()
                ClearMulticharacterCallbacks()
            end
        end
        StopCamera()
        ForceCleanupCameraSystem()
        InSelection = false
    end
    for _, callback in pairs(closeMenuCallbacks) do
        if type(callback) == "function" then
            callback(data)
        end
    end

    local isClothesLikeMenu = (data.menuType == "stock" or data.menuType == "clothes" or data.menuType == "outfitCreator")
    local isHangerBuy = data.buyStock and data.buyMode == "hanger"
    local shouldRestoreAfterHangerBuy = isHangerBuy

    if (not data.buyStock and isClothesLikeMenu) or shouldRestoreAfterHangerBuy then
        RestoreMenuOpenClothesHashes()
    end

    if shouldRestoreAfterHangerBuy then
        SaveAppearance()
    end

    menuOpenClothesHashes = nil

    --[[ Al final, no al principio: la compra de arriba (closeMenuCallbacks →
         Cart.BuyItems) la valida el servidor mirando que sigues DENTRO de la
         tienda VIP o exclusiva. Salir antes hacia que toda compra ahi fallara. ]]
    SalirDeTiendaEspecial()

    RestorePreviousData()
    InStore = false
    cb(true)
end)

--[[ Si el recurso se para con la pantalla abierta, nadie manda el `false` y
     el rastreador y el logo se quedan escondidos para siempre. ]]
AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    TriggerEvent('qv2:suppressHud', false)
end)

RegisterNUICallback("HandsUp", function(data, cb)
    HandsUp()
    cb(true)
end)
RegisterNUICallback("closeAdminMenu", function(data, cb)
    SetNuiFocus(false, false)
    -- El panel de admin se abre con OpenClothing, que aparta HUD y minimapa.
    TriggerEvent('qv2:suppressHud', false)
    if GetResourceState('origen_map') == 'started' then exports.origen_map:Apartar(false) end
    cb(true)
    
    -- Si fue abierto desde el hub, volver al hub con pantalla de carga
    if exports['origen_clothing']:IsOpenedFromHub() then
        exports['origen_clothing']:ResetHubFlag()
        exports['origen_admin']:ReturnToScripts()
    end
end)

RegisterNUICallback("clothingMenuReady", function(data, cb)
    -- Notify titlemenu that clothing creator is fully loaded and visible
    TriggerEvent('origen_clothing:client:menuReady')
    cb(true)
end)

RegisterNUICallback("SetCameraPosition", function(zone, cb)
    if not zone then return cb(false) end
    MoveCamera("ZONE_"..zone:upper())
    cb(true)
end)

-- PENDIENTE: Tiene que ejecutarse al menos una vez el SetPedHeadBlendData para que el SetPedFaceFeature y SetPedHeadOverlay funcionen

RegisterNUICallback("SetHeadBlend", function(data, cb)
    SetPedHeadBlendData(GetPedCamera(), data.shapeFirst, data.shapeSecond, data.shapeThird, data.skinFirst, data.skinSecond, data.skinThird, data.shapeMix + 0.0, data.skinMix + 0.0, data.thirdMix + 0.0, data.hasParent)
    cb(true)
end)

RegisterNUICallback("setHeadStructure", function(data, cb)
    if data.index == 11 then -- 11 = Eye Opening
        data.value = data.value * -1.0 -- Invert the value so -1 represent the eyes a bit closed and 1 the eyes more open
    end
    SetPedFaceFeature(GetPedCamera(), data.index, data.value + 0.0)
    cb(true)
end)

RegisterNUICallback("setHeadOverlay", function(data, cb)
    if data.index == 10 then -- 10 = Chest hair
        SetPreviousData("ZONE_CHEST", {
            { index = 8, value = 15, texture = 0 }, -- shirt
            { index = 11, value = 15, texture = 0 }, -- jacket
            { index = 3, value = 15, texture = 0 }, -- torso
        })
    else
        RestorePreviousData()
    end

    if data.index == 10 or data.index == 11 then -- BodyBlemishes
        MoveCamera("ZONE_SHIRTS", true)
    else
        MoveCamera("ZONE_HEAD", true)
    end

    SetPedHeadOverlay(GetPedCamera(), data.index, data.value, data.overlayOpacity + 0.0)
    SetPedHeadOverlayColor(GetPedCamera(), data.index, data.colourType, data.firstColor, data.secondColor)
    cb(true)
end)

RegisterNUICallback("setHairTint", function(data, cb)
    SetPedHairTint(GetPedCamera(), data.isHighlight and GetPedHairColor(GetPedCamera()) or data.colorIndex, data.isHighlight and data.colorIndex or GetPedHairHighlightColor(GetPedCamera()))
    cb(true)
end)

RegisterNUICallback("setEyeColor", function(color, cb)
    SetPedEyeColor(GetPedCamera(), color)
    cb(true)
end)

RegisterNUICallback("setDrawable", function(data, cb)
    local ped = GetPedCamera()
    -- In a store (stock mode) capture the original clothing BEFORE the preview
    -- modifies the ped. Without this, Cart.ApplyClothes would read the already-
    -- previewed (new) hash as "old clothes" and the server would return the new
    -- item to the inventory, causing a duplication.
    if MenuType == 'stock' then
        local catIndex = data.index
        if data.hash then
            local parsed = parseItemHash(data.hash)
            if parsed then catIndex = parsed.component_id end
        end
        local cat = catIndex and drawableIndexToCategory[catIndex]
        if cat and not Cart.oldClothes[cat] then
            Cart.oldClothes[cat] = GetPedDrawableHash(ped, cat)
        end
    end
    if data.hash then
        SetPedDrawableByHash(ped, data.hash)
    else
        SetPedComponentVariation(ped, data.index, data.value, data.texture)
    end
    -- Use the actual global drawable id after applying to get correct texture count
    local globalDrawableId = GetPedDrawableVariation(ped, data.index)
    cb(GetNumberOfPedTextureVariations(ped, data.index, globalDrawableId) - 1)
end)

RegisterNUICallback("setProp", function(data, cb)
    local ped = GetPedCamera()
    -- Same pre-capture logic as setDrawable: save the original prop BEFORE the
    -- preview changes it so Cart.oldClothes holds the true pre-store state.
    if MenuType == 'stock' then
        local propIndex = data.index
        if data.hash then
            local parsed = parseItemHash(data.hash)
            if parsed and parsed.anchor then propIndex = parsed.anchor end
        end
        local cat = propIndex and propIndexToCategory[propIndex]
        if cat and not Cart.oldClothes[cat] then
            Cart.oldClothes[cat] = GetPedPropHash(ped, cat, true)
        end
    end
    if data.hash then
        SetPedPropByHash(ped, data.hash)
    else
        if data.value == -1 then
            ClearPedProp(ped, data.index)
        else
            SetPedPropIndex(ped, data.index, data.value, data.texture)
        end
    end
    -- Use the actual global prop drawable id after applying to get correct texture count
    local globalPropId = GetPedPropIndex(ped, data.index)
    cb(GetNumberOfPedPropTextureVariations(ped, data.index, globalPropId) - 1)
end)

RegisterNUICallback("startLooking", function(data, cb)
    FollowMouse = true
    cb(true)
end)

RegisterNUICallback("stopLooking", function(data, cb)
    FollowMouse = false
    cb(true)
end)

RegisterNUICallback("GetConfig", function(_, cb)
    local ped = GetPedCamera()
    local model = GetEntityModel(ped)
    local isMp = IsMpPedModel(model)

    local config = {
        stockEnabled = Config.StockEnabled,
        defaultPrice = Config.DefaultPrice,
        defaultPriceByCategory = Config.DefaultPriceByCategory,
        -- Force useOnlyInputs for addon peds as they don't have items in DB for the grid icons
        useOnlyInputs = Config.UseOnlyInputs or not isMp,
    }
    cb(config)
end)

RegisterNUICallback("GetLocales", function(_, cb)
    cb(getTranslations())
end)

RegisterNUICallback("zoom", function(direction, cb)
    ZoomCamera(direction)
    cb(true)
end)

RegisterNUICallback("rotateCam", function(rotation, cb)
    SetEntityHeading(GetPedCamera(), GetEntityHeading(GetPedCamera()) + rotation.x)
    AddCameraHeight(rotation.y / 50)
    cb(true)
end)

RegisterNUICallback("resetCamera", function(rotation, cb)
    MoveCamera(CurrentCameraZone)
    cb(true)
end)

RegisterNUICallback("usePed", function(model, cb)
    lib.callback.await('origen_clothing:SetSkinAsActive', false, model)
    ReloadAppearanceData(model)
    cb(true)
end)

RegisterNUICallback("givePed", function(data, cb)
    if not IsModelValid(data.model) then
        debugger("Invalid model:", data.model)
        return cb(false)
    end
    cb(lib.callback.await("origen_clothing:givePed", false, data.id, data.model))
end)

RegisterNUICallback("deletePed", function(model, cb)
    cb(lib.callback.await("origen_clothing:deletePed", false, model))
end)

RegisterNUICallback("updateHairSlots", function(data, cb)
    for k, v in pairs(data) do
        HairSlot.Update(k, v)
    end
    cb(true)
end)

RegisterNUICallback("selectHairSlot", function(slot, cb)
    local hairSlot = HairSlot.Get(slot + 1)
    if hairSlot then
        hairSlot:Use()
    end
    cb(true)
end)

RegisterNUICallback("getClothingItems", function(data, cb)
    local category = data.category
    local offset = data.offset or 0
    local limit = data.limit or 50
    local model = GetEntityModel(GetPedCamera())
    
    local items = lib.callback.await("origen_clothing:getClothingItems", false, category, offset, limit, buildNumber, model)
    cb(items)
end)

RegisterNUICallback("getTotalDrawables", function(data, cb)
    local category = data.category
    local ped = GetPedCamera()
    local model = GetEntityModel(ped)
    
    -- In stock mode, we always use the database
    if MenuType == 'stock' then
        local total = lib.callback.await("origen_clothing:getTotalDrawables", false, category, model)
        cb(total)
        return
    end

    -- For standard mode, if it's an addon ped or if the server might not have it,
    -- use natives to get the real count of variations the model has.
    local v = AppearanceData.drawables[category]
    local total = 0
    if v then
        total = GetNumberOfPedDrawableVariations(ped, v.index)
        if total > 0 then total = total - 1 end -- Convert count to max index
    else
        v = AppearanceData.props[category]
        if v then
            total = GetNumberOfPedPropDrawableVariations(ped, v.index)
            if total > 0 then total = total - 1 end -- Convert count to max index
        end
    end

    -- If native count is 0, try the database as a fallback
    if total <= 0 then
        total = lib.callback.await("origen_clothing:getTotalDrawables", false, category, model)
    end
    
    cb(total)
end)

RegisterNUICallback("getStoreStockItems", function(data, cb)
    local storeId = data.storeId
    local category = data.category
    local offset = data.offset or 0
    local limit = data.limit or 50

    local model = GetEntityModel(GetPedCamera())
    
    local items = lib.callback.await("origen_clothing:getStoreStockItems", false, storeId, category, offset, limit, buildNumber, model)
    cb(items)
end)

local genders = {
    [0] = `mp_m_freemode_01`,
    [1] = `mp_f_freemode_01`
}

RegisterNUICallback("getStoreItems", function(data, cb)
    local storeId = data.storeId
    local category = data.category
    local gender = genders[data.gender] or (data.customModel and GetHashKey(data.customModel)) or false
    local page = data.page or 1
    local limit = data.limit or 36
    local statusFilter = data.statusFilter or 'all'
    
    local response = lib.callback.await("origen_clothing:getStoreItems", false, storeId, category, gender, page, limit, statusFilter)
    cb(response)
end)

RegisterNUICallback("updateStoreItem", function(data, cb)
    local storeId = data.storeId
    local itemId = data.itemId
    local price = data.price
    local stock = data.stock
    
    local success = lib.callback.await("origen_clothing:updateStoreItem", false, storeId, itemId, price, stock)
    cb(success)
end)

RegisterNUICallback("removeStoreItem", function(data, cb)
    local storeId = data.storeId
    local itemId = data.itemId
    
    local success = lib.callback.await("origen_clothing:removeStoreItem", false, storeId, itemId)
    cb(success)
end)

RegisterNUICallback("toggleAllStoreItems", function(data, cb)
    local storeId = data.storeId
    local category = data.category
    local gender = genders[data.gender] or false
    local action = data.action
    local defaultPrice = data.defaultPrice or 100
    local defaultStock = data.defaultStock or 0
    
    local success = lib.callback.await("origen_clothing:toggleAllStoreItems", false, storeId, category, gender, action, defaultPrice, defaultStock)
    cb(success)
end)

RegisterNUICallback("addMultipleStoreItems", function(data, cb)
    local storeId = data.storeId
    local itemIds = data.itemIds or {}
    local defaultPrice = data.defaultPrice or 100
    local defaultStock = data.defaultStock or 0

    local success = lib.callback.await("origen_clothing:addMultipleStoreItems", false, storeId, itemIds, defaultPrice, defaultStock)
    cb(success)
end)

RegisterNUICallback('copyCoords', function(data, cb)
    local playerCoords = GetEntityCoords(PlayerPedId())
    cb({
        x = playerCoords.x,
        y = playerCoords.y,
        z = playerCoords.z,
        w = GetEntityHeading(PlayerPedId())
    })
end)

RegisterNUICallback("createStore", function(data, cb)
    cb(lib.callback.await("origen_clothing:createStore", false, data))
end)

RegisterNUICallback("updateStore", function(data, cb)
    cb(lib.callback.await("origen_clothing:updateStore", false, data))
end)

RegisterNUICallback("deleteStore", function(data, cb)
    cb(lib.callback.await("origen_clothing:deleteStore", false, data.id))
end)

RegisterNUICallback("getAllItems", function(data, cb)
    local category = data.category
    local model = data.model
    local page = data.page or 1
    local limit = data.limit or 36
    local permissionsFilter = data.permissionsFilter or 'all'

    local response = lib.callback.await("origen_clothing:getAllItems", false, category, model, page, limit, permissionsFilter)
    
    cb(response)
end)

RegisterNUICallback("getItemPermissions", function(data, cb)
    local itemId = data.itemId
    local response = lib.callback.await("origen_clothing:getItemPermissions", false, itemId)
    cb(response)
end)

RegisterNUICallback("updateItemPermissions", function(data, cb)
    local itemId = data.itemId
    local identifiers = data.identifiers
    local groups = data.groups
    local only_stock = data.only_stock
    
    local response = lib.callback.await("origen_clothing:updateItemPermissions", false, itemId, identifiers, groups, only_stock)
    cb(response)
end)

RegisterNUICallback("createPolyzone", function(data, cb)
    local newData = Creation:CreateExteriorZone(nil)

    if not newData or not next(newData) then
        cb(false)
        return
    end

    cb({
        points = newData.points,
        thickness = newData.thickness
    })
end)

RegisterNUICallback("setFocus", function(data, cb)
    SetNuiFocus(data, data)
    cb(true)
end)

RegisterNUICallback("getPedHash", function(data, cb)
    SendNUIMessage({
        action = "updatePedHash",
        hash = GetEntityModel(GetPedCamera()),
    })

    cb('ok')
end)

RegisterNUICallback("takePhotos", function(data, cb)
    cb('ok')
    SetNuiFocus(false, false)
    
    data.isProp = IsProp(data.component)
    
    if data.skipExisting == nil then
        data.skipExisting = true
    end
    
    if data.skipExisting then
        TriggerEvent('origen_clothing:showVerificationLoading', {
            message = 'Preparando el sistema de fotos...',
            progress = 'Espera un momento...'
        })
        Wait(50)
    end
    
    exports['origen_clothing_screenshot']:prepareScreenshot(data)
end)

RegisterNetEvent('origen_clothing_screenshot:progressStart', function()
    screenshotBatchState.started = true
    screenshotBatchState.running = true
end)

RegisterNetEvent('origen_clothing_screenshot:progressEnd', function()
    screenshotBatchState.running = false
end)

RegisterNUICallback("takeMultipleSelectedPhotos", function(data, cb)
    cb('ok')
    SetNuiFocus(false, false)

    if type(data) ~= 'table' or type(data.items) ~= 'table' or #data.items == 0 then
        return
    end

    local ped = data.ped
    local component = data.component
    if not ped or not component then
        return
    end

    local isProp = IsProp(component)
    local skipExisting = data.skipExisting
    if skipExisting == nil then
        skipExisting = true
    end

    CreateThread(function()
        for _, item in ipairs(data.items) do
            screenshotBatchState.started = false
            screenshotBatchState.running = false

            exports['origen_clothing_screenshot']:prepareScreenshot({
                ped = ped,
                collection = item.collection,
                component = component,
                variation = tonumber(item.drawable_id) or -1,
                texture = tonumber(item.texture_id) or -1,
                skipExisting = skipExisting,
                isProp = isProp
            })

            local startedWaitAt = GetGameTimer()
            while not screenshotBatchState.started and (GetGameTimer() - startedWaitAt) < 4000 do
                Wait(50)
            end

            if screenshotBatchState.started then
                local runningWaitAt = GetGameTimer()
                while screenshotBatchState.running and (GetGameTimer() - runningWaitAt) < 120000 do
                    Wait(100)
                end
            else
                Wait(350)
            end
        end
    end)
end)

RegisterNUICallback("startImportClothing", function(data, cb)
    cb('ok')
    SetNuiFocus(true, true)
    StartImportClothing(data)
end)

RegisterNUICallback("cancelImport", function(data, cb)
    cb('ok')
    CancelImport()
end)

RegisterNUICallback("closeImportProgress", function(data, cb)
    cb('ok')
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'closeImportProgress'
    })
end)

RegisterNUICallback("startMigrateSkins", function(data, cb)
    cb('ok')
    SetNuiFocus(true, true)
    StartMigrateSkins(data)
end)

RegisterNUICallback("cancelMigration", function(data, cb)
    cb('ok')
    CancelMigration()
end)

RegisterNUICallback("closeMigrationProgress", function(data, cb)
    cb('ok')
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'closeMigrationProgress'
    })
end)

-- NEW OUTFIT SYSTEM
--[[ Ponerse o quitarse un atuendo con el menu de ropa abierto cambia la ropa
     "de entrada". Al cerrar, el menu vuelve a poner la ropa con la que se
     abrio (RestoreMenuOpenClothesHashes, tambien al pulsar ENTER con el
     carrito vacio) y se comia el atuendo; en la base si estaba (Equip lo
     guarda), por eso /fixpj lo arreglaba. Lo que se habia probado antes ya
     no esta puesto: Cart.Cancel no tiene nada que devolver. ]]
local function FijarRopaDeEntrada()
    if not menuOpenClothesHashes then return end
    menuOpenClothesHashes = GetPedAllHashes(cache.ped, true)
    Cart.oldClothes = {}
end

RegisterNUICallback("equipOutfit", function(id, cb)
    local outfit = Outfit.Get(id)
    if not outfit then return cb(false) end
    outfit:Equip()
    FijarRopaDeEntrada()
    cb(true)
end)

RegisterNUICallback("unnequipOutfit", function(outfitName, cb)
    local outfit = Outfit.GetEquipped(true)
    if outfit then
        outfit:Unequip()
        FijarRopaDeEntrada()
    end
    cb(true)
end)

RegisterNUICallback("saveOutfit", function(data, cb)
    local data = {
        identifier = data.isJobOutfit and Custom.GetJob().name or Custom.GetPlayerIdentifier(),
        model = Config.Peds[GetEntityModel(CreationPed)],
        label = data.outfitName,
        drawables = GetPedDrawablesHash(CreationPed, {
            ['hair'] = true
        }),
        props = GetPedPropsHash(CreationPed),
        jobOutfit = data.isJobOutfit
    }

    TriggerServerEvent('origen_clothing:server:CreateOutfit', data)

    cb(true)
end)

-- Guarda como atuendo lo que el personaje lleva puesto AHORA, sin abrir la
-- tienda. Lo usa el boton «Guardar atuendo» de la pestaña Personaje de
-- origen_inventory. Es el mismo guardado que el de arriba, pero sobre el ped
-- del jugador en vez del de la tienda (CreationPed solo existe con ella abierta).
exports('GuardarAtuendoPuesto', function(nombre)
    nombre = tostring(nombre or ''):gsub('^%s+', ''):gsub('%s+$', ''):sub(1, 40)
    if nombre == '' then return false end

    local ped = PlayerPedId()
    local modelo = Config.Peds[GetEntityModel(ped)]
    local identificador = Custom.GetPlayerIdentifier()
    if not modelo or not identificador then return false end

    TriggerServerEvent('origen_clothing:server:CreateOutfit', {
        identifier = identificador,
        model = modelo,
        label = nombre,
        drawables = GetPedDrawablesHash(ped, { ['hair'] = true }),
        props = GetPedPropsHash(ped),
        jobOutfit = false,
    })

    return true
end)

RegisterNUICallback("deleteOutfit", function(outfitId, cb)
    local outfit = Outfit.Get(outfitId)
    if outfit then
        local result = outfit:Remove()
        cb(result)
        return
    end
    cb(false)
end)

RegisterNUICallback("startJobOutfitCreation", function(data, cb)
    local coords = GetEntityCoords(PlayerPedId())
    local outfit = data.outfit and Outfit.Get(data.outfit)
    local modelHash = GetHashKey(outfit?.model or data.model)
    
    lib.requestModel(modelHash)
    outfitPed = CreatePed(0, modelHash, coords.x + 1.0, coords.y + 1.0, coords.z - 1.0, 0.0, false, false)
    SetEntityHeading(outfitPed, GetEntityHeading(PlayerPedId()))
    FreezeEntityPosition(outfitPed, true)

    if outfit then
        outfit:TempEquip(outfitPed)
    end

    StartCamera(true, outfitPed)
    OpenClothing('outfitCreator', {
        stock = {},
        storeId = -1,
        drawables = GetPedDrawables(outfitPed),
        props = GetPedProps(outfitPed),
        isEditing = data.outfit or false,
    })
    cb(true)
end)

RegisterNUICallback("endJobOutfitCreation", function(data, cb)
    if outfitPed and DoesEntityExist(outfitPed) then
        DeletePed(outfitPed)
        outfitPed = nil
    end
    SetNuiFocus(false, false)
    StopCamera()
    ForceCleanupCameraSystem()
    InSelection = false
    cb(true)
end)

RegisterNUICallback("updateOutfit", function(outfitId, cb)
    local outfit = Outfit.Get(outfitId)
    if outfit then
        outfit:UpdateClothes(CreationPed)
        cb(true)
    else
        cb(false)
    end
end)

RegisterNUICallback("getItemData", function(data, cb)
    local ped = GetPedCamera()
    local pedHash = GetEntityModel(ped)
    -- dir y modo: por donde seguir si la prenda esta retirada de las tiendas.
    -- hash: la prenda que ese numero es en este cliente, por si el numero
    -- global guardado en la base no coincide (ver HashDeNumeroGlobal).
    local hash = HashDeNumeroGlobal(ped, data.category, data.global_drawable_id, data.texture)
    local item = lib.callback.await("origen_clothing:getItemData", false, data.category, data.global_drawable_id, data.texture, pedHash, data.dir, data.modo, hash)
    
    -- If the item was not found in the DB (common for addon peds or non-imported items),
    -- return synthetic data so the UI allows applying the drawable/texture via natives.
    if not item and not IsMpPedModel(pedHash) and MenuType ~= 'stock' then
        cb({
            id = -1,
            hash = nil,
            drawableid = data.global_drawable_id,
            global_drawable_id = data.global_drawable_id,
            texture_id = data.texture,
            owned = true -- Addon peds are considered to "own" their built-in clothes
        })
        return
    end

    cb(item)
end)

--- Retirar o devolver a las tiendas la prenda que se ve (modo gestion).
RegisterNUICallback("gestionRetirar", function(data, cb)
    local r = lib.callback.await('origen_clothing:gestion:retirar', false, {
        model = GetEntityModel(GetPedCamera()),
        category = data.category,
        global_drawable_id = data.global_drawable_id,
        texture = data.texture,
        entera = data.entera == true,
        ocultar = data.ocultar == true,
    })
    cb(r or { ok = false })
end)

--- Meter en la tienda VIP o sacar de ella la prenda que se ve (modo gestion).
RegisterNUICallback("gestionVip", function(data, cb)
    local r = lib.callback.await('origen_clothing:gestion:vip', false, {
        model = GetEntityModel(GetPedCamera()),
        category = data.category,
        global_drawable_id = data.global_drawable_id,
        texture = data.texture,
        entera = data.entera == true,
        meter = data.meter == true,
    })
    cb(r or { ok = false })
end)

--- Meter en la tienda exclusiva (con precio en XP y stock) o sacar la prenda
--- que se ve (modo gestion).
RegisterNUICallback("gestionExclusiva", function(data, cb)
    local r = lib.callback.await('origen_clothing:gestion:exclusiva', false, {
        model = GetEntityModel(GetPedCamera()),
        category = data.category,
        global_drawable_id = data.global_drawable_id,
        texture = data.texture,
        entera = data.entera == true,
        accion = data.accion,
        xp = data.xp,
        stock = data.stock,
    })
    cb(r or { ok = false })
end)

--- El XP que le queda al jugador, para el carrito de la tienda exclusiva.
RegisterNUICallback("getPlayerXP", function(_, cb)
    cb(lib.callback.await('origen_clothing:exclusiva:miXP', false) or 0)
end)

RegisterNUICallback("getCurrentGlobalDrawable", function(data, cb)
    local ped = GetPedCamera()
    local category = data.category
    local isProp = data.isProp or false
    local hash

    if isProp then
        hash = GetPedPropHash(ped, category, true)
    else
        hash = GetPedDrawableHash(ped, category)
    end

    if not hash then
        cb({ global_drawable_id = 0, texture = 0 })
        return
    end

    local model = ped and GetEntityModel(ped) or GetEntityModel(cache.ped)
    local removeData = model and Config.RemoveItem[model] or nil
    local removeHash = removeData and removeData[category] or nil

    local parsedCurrent = parseItemHash(hash)
    if parsedCurrent then
        -- Props "none" state
        if isProp and tonumber(parsedCurrent.drawable_id) == -1 then
            cb({ global_drawable_id = 0, texture = 0 })
            return
        end

        -- Exact remove hash
        if removeHash and hash == removeHash then
            cb({ global_drawable_id = 0, texture = 0 })
            return
        end

        -- Robust remove detection even if hash formatting/texture differs
        -- collection must also match to avoid false positives with addon items at drawable_id=0
        if removeHash then
            local parsedRemove = parseItemHash(removeHash)
            if parsedRemove
                and parsedCurrent.collection == parsedRemove.collection
                and tonumber(parsedCurrent.component_id) == tonumber(parsedRemove.component_id)
                and tonumber(parsedCurrent.drawable_id) == tonumber(parsedRemove.drawable_id)
            then
                cb({ global_drawable_id = 0, texture = 0 })
                return
            end
        end
    end

    local result = lib.callback.await("origen_clothing:getGlobalDrawableByHash", false, hash)

    if result then
        cb({ global_drawable_id = result.global_drawable_id, texture = result.texture_id })
    else
        cb({ global_drawable_id = 0, texture = 0 })
    end
end)

RegisterNUICallback("getCurrentEquippedHashes", function(data, cb)
    local ped = GetPedCamera()
    if not ped or ped == 0 then
        cb({ hashes = {}, model = nil })
        return
    end
    
    local hashes = GetPedAllHashes(ped, true)
    local pedModel = GetEntityModel(ped)
    cb({ hashes = hashes or {}, model = pedModel })
end)

RegisterNUICallback("checkEquippedItemsOwned", function(data, cb)
    local result = lib.callback.await("origen_clothing:checkEquippedItemsOwned", false, data)
    cb(result or { allOwned = true, unownedHashes = {} })
end)

RegisterNUICallback("getRemoveHash", function(data, cb)
    local category = data and data.category
    if not category then
        cb(false)
        return
    end

    local ped = GetPedCamera()
    local model = ped and GetEntityModel(ped) or GetEntityModel(cache.ped)
    local removeData = model and Config.RemoveItem[model] or nil
    local removeHash = removeData and removeData[category] or nil

    cb(removeHash or false)
end)

RegisterNUICallback("getPlayerCash", function(data, cb)
    local cash = lib.callback.await("origen_clothing:getPlayerCash", false)
    cb(cash or 0)
end)

RegisterNUICallback("giveHanger", function(data, cb)
    local outfit = data
    if not outfit then
        cb(false)
        return
    end
    
    local result = lib.callback.await("origen_clothing:server:giveHanger", false, outfit)
    cb(result or false)
end)

RegisterNUICallback("showNotification", function(data, cb)
    if data and data.text and data.type then
        Custom.Notify(data.text, data.type, data.duration or 5000)
    end
    cb('ok')
end)

local function ShowControls(controls, title)
    SendNUIMessage({
        action = "showControls",
        controls = controls,
        title = title
    })
end

exports('ShowControls', ShowControls)

local function HideControls()
    SendNUIMessage({
        action = "hideControls"
    })
end

exports('HideControls', HideControls)

RegisterNetEvent('origen_clothing:client:useOutfitItem', function(outfit, slot)
    if lib.progressBar({
        duration = math.random(500, 1000),
        label = 'Cambiando ropa...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
        },
        anim = {
            dict = 'missmic4',
            clip = 'michael_tux_fidget'
        }
    }) then 
        local ped = cache.ped

        local oldDrawables = GetPedDrawablesHash(ped, nil, true)
        local oldProps = GetPedPropsHash(ped, nil, true)

        TriggerServerEvent('origen_clothing:server:updateHangerData', slot, oldDrawables, oldProps)

        Wait(200)

        SetPedDrawablesByHash(ped, outfit.drawables)
        SetPedPropsByHash(ped, outfit.props)
        SaveAppearance()
    end
end)
