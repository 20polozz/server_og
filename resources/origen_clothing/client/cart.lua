local NOMBRE_XP = GetConvar('origen:marca', 'origen') == 'nacion' and 'Farm XP' or 'XP'

Cart = {
    storeId = -1,
    price = 0,
    items = {},
    oldClothes = {},
    buyMode = 'wear',
    hangerName = nil
}

function Cart.ApplyClothes(item)
    local itemData = parseItemHash(item.hash)
    local isProp = IsProp(item.category)
    
    local componentId = {}

    if isProp then
        componentId = AppearanceData.props[item.category].index
    else
        componentId = AppearanceData.drawables[item.category].index
    end

    
    if not Cart.oldClothes[item.category] then
        if isProp then
            Cart.oldClothes[item.category] = GetPedPropHash(CreationPed, item.category, true)
        else
            Cart.oldClothes[item.category] = GetPedDrawableHash(CreationPed, item.category)
        end
        debugger("Old "..item.category.." -> ", json.encode(Cart.oldClothes[item.category]))
    end
    
    itemData.collection = itemData.collection == "none" and "" or itemData.collection

    -- La vista previa de la tienda tambien: el catalogo puede tener prendas de
    -- un pack que hoy no arranca (ver PrendaExiste en utils.lua).
    if not PrendaExiste(CreationPed, itemData) then return end

    if itemData.anchor then
        if itemData.drawable_id == -1 then
            ClearPedProp(CreationPed, itemData.anchor)
        else
            SetPedCollectionPropIndex(CreationPed, itemData.anchor, itemData.collection, itemData.drawable_id, itemData.texture_id)
        end
    else
        SetPedCollectionComponentVariation(CreationPed, itemData.component_id, itemData.collection, itemData.drawable_id, itemData.texture_id)
    end
end

function Cart.AddItem(item, storeId)
    if not item.owned and not item.remove then
        Cart.price = Cart.price + (item.price or 0)
    end
    Cart.storeId = storeId

    local foundSameCategory = false

    for k, v in pairs(Cart.items) do
        if v.category == item.category then
            Cart.items[k] = item
            foundSameCategory = true
            break
        end
    end

    if not foundSameCategory then
        Cart.items[#Cart.items + 1] = item
    end

    Cart.ApplyClothes(item)
end

function Cart.RestoreOldCloth(category)
    local isProp = IsProp(category)
    if Cart.oldClothes[category] then
        local componentId = {}
        if isProp then
            componentId = AppearanceData.props[category].index
            if Cart.oldClothes[category].drawable_id == -1 then
                ClearPedProp(CreationPed, componentId)
            else
                SetPedPropByHash(CreationPed, Cart.oldClothes[category])
            end
        else
            componentId = AppearanceData.drawables[category].index
            SetPedDrawableByHash(CreationPed, Cart.oldClothes[category])
        end
        local result = {
            isProp = isProp,
            drawable_id = Cart.oldClothes[category].drawable_id,
            texture = Cart.oldClothes[category].texture,
        }
        return result
    else
        debugger("No old clothes found for category: " .. category)
    end
end

function Cart.RestoreValues()
    Cart.price = 0
    Cart.items = {}
    Cart.storeId = -1
    Cart.buyMode = 'wear'
    Cart.hangerName = nil
end

function Cart.Cancel()
    Cart.RestoreValues()

    for category, oldCloth in pairs(Cart.oldClothes) do
        Cart.RestoreOldCloth(category)
    end
    Cart.oldClothes = {}
end

--[[ Lo que llevas puesto al salir de la tienda tras pagar: la ropa con la que
     entraste y, encima, SOLO lo que el servidor ha dado por comprado (o por
     quitado). Antes se quedaba puesto todo lo que habias probado aunque no
     estuviera en el carrito: pagabas una prenda y te llevabas las demas. ]]
local function VestirSoloLoComprado(puestas)
    RestoreMenuOpenClothesHashes()
    local ped = cache.ped
    for categoria, hash in pairs(puestas or {}) do
        if type(hash) == 'string' and hash ~= '' then
            if IsProp(categoria) then
                SetPedPropByHash(ped, hash)
            else
                SetPedDrawableByHash(ped, hash)
            end
        end
    end
end

function Cart.BuyItems()
    if #Cart.items == 0 then
        -- Carrito vacio: no se ha comprado nada, vuelve la ropa de antes.
        Cart.oldClothes = {}
        RestoreMenuOpenClothesHashes()
        return
    end

    if Cart.storeId == -1 then
        local pedModel = GetEntityModel(GetPedCamera())
        local result = lib.callback.await('origen_clothing:buyDirectItems', false, {
            items = Cart.items,
            price = Cart.price,
            model = pedModel
        })

        if not result or not result.status then
            Custom.Notify((result and result.error) or locale('no_money'), "error", 7000)
            Cart.Cancel()
            RestoreMenuOpenClothesHashes()
            return
        end

        local pricePaid = tonumber(result.finalPrice) or 0
        local priceText = pricePaid > 0 and (' -$' .. pricePaid) or ''
        Custom.Notify((locale('bought_clothes') or 'Compra realizada') .. priceText, "success", 5000)
        Cart.RestoreValues()
        Cart.oldClothes = {}
        SaveAppearance()
        return
    end

    Cart.playerModel = GetEntityModel(cache.ped)
    Cart.buyMode = Cart.buyMode == 'hanger' and 'hanger' or 'wear'
    Cart.hangerName = Cart.hangerName or nil

    local result = lib.callback.await('origen_clothing:buyItems', false, Cart)
    local isHangerMode = Cart.buyMode == 'hanger'

    if result.status then
        for i, data in pairs(result.refused or {}) do
            local categoryLabel = locale(data.category) or tostring(data.category or '')
            local msg

            if data.reason == 'out_of_stock' then
                msg = (locale('item_out_of_stock_category') or 'No queda stock de la categoría "%s"'):format(categoryLabel)
            else
                msg = (locale('item_no_longer_available_category') or 'El artículo de la categoría "%s" ya no está disponible'):format(categoryLabel)
            end

            Custom.Notify(msg, "error", 7000)
            Cart.RestoreOldCloth(data.category)
        end

        local hangerCreated = (not isHangerMode) or (result.hangerCreated == true)

        if isHangerMode and hangerCreated then
            for category, _ in pairs(Cart.oldClothes) do
                Cart.RestoreOldCloth(category)
            end
            if result.hangerName and result.hangerName ~= '' then
                Custom.Notify(("Conjunto guardado en percha: %s"):format(result.hangerName), "success", 6000)
            else
                Custom.Notify("Conjunto guardado en percha", "success", 6000)
            end
        elseif isHangerMode and result.hangerError then
            Custom.Notify(result.hangerError, "error", 7000)
        end

        Cart.oldClothes = {}

        local pricePaid = tonumber(result.finalPrice) or 0
        local priceText = pricePaid > 0 and (' -$' .. pricePaid) or ''
        -- Tienda exclusiva: lo que se ha gastado es XP.
        local xpPaid = tonumber(result.xp) or 0
        if xpPaid > 0 then
            priceText = priceText .. (' -%d %s'):format(xpPaid, NOMBRE_XP)
        end

        if #result.refused > 0 then
            local partialPurchaseText = locale('partial_purchase')
            if not partialPurchaseText or partialPurchaseText == 'partial_purchase' then
                partialPurchaseText = "Compra parcial realizada"
            end
            Custom.Notify(partialPurchaseText .. priceText, "info", 7000)
        elseif not isHangerMode then
            Custom.Notify((locale('bought_clothes') or 'Compra realizada') .. priceText, "success", 5000)
        end
        Cart.RestoreValues()
        if not isHangerMode then
            VestirSoloLoComprado(result.puestas)
            SaveAppearance()
        end
    else
        Custom.Notify(result.error, "error", 7000)
        Cart.Cancel()
        RestoreMenuOpenClothesHashes()
    end
end

function Cart.RemoveItem(item)
    for i, v in ipairs(Cart.items) do
        if v.drawable_id == item.drawable_id and v.category == item.category then
            if not v.owned and not v.remove then
                Cart.price = Cart.price - (v.price or 0)
            end
            table.remove(Cart.items, i)
            break
        end
    end
    return Cart.RestoreOldCloth(item.category)
end

CreateThread(function()
    RegisterCloseMenuCallback(function(data)
        if outfitPed then
            DeleteEntity(outfitPed)
            outfitPed = nil
        end
        if (data.menuType == "stock" or data.menuType == "clothes" or data.menuType == "outfitCreator") and not data.buyStock then
            Cart.Cancel()
            debugger("Cart cancelled")
        end
        if data.buyStock then
            Cart.buyMode = data.buyMode == 'hanger' and 'hanger' or 'wear'
            Cart.hangerName = data.hangerName
            Cart.BuyItems()
            debugger("Cart items bought")
        end
    end)
end)

RegisterNUICallback("addToCart", function(data, cb)
    local item = data.item
    local storeId = data.storeId

    if not item or not storeId then
        debugger("Invalid item or storeId")
        return
    end

    Cart.AddItem(item, storeId)

    local globalDrawableId = GetPedDrawableVariation(CreationPed, item.index)
    cb(GetNumberOfPedTextureVariations(CreationPed, item.index, globalDrawableId) - 1)
end)

RegisterNUICallback("removeFromCart", function(data, cb)
    local item = data.item

    if not item then
        debugger("Invalid item")
        return
    end

    cb(Cart.RemoveItem(item))
end)