RegisterNUICallback("getStores", function(data, cb)
    cb(Store.GetHeaders())
end)

RegisterNUICallback("getStoreStock", function(data, cb)
    local store = Store.Get(tonumber(string.match(data.storeId, "%d+$")))
    if not store then
        cb({})
        return
    end
    local stocks = store:GetStock(data.category)
    for k, v in pairs(stocks) do
        stocks[k].gender = stocks[k].gender == false and "male" or "female"
    end
    cb(stocks)
end)

RegisterNUICallback("getAllStock", function(data, cb)
    local skipClothes = {}
    local stock = lib.callback.await('origen_clothing:getAllStock', false, data.storeId, data.category)
    
    for k, v in pairs(stock) do
        skipClothes[v.drawable_id] = true
    end

    -- Adding the game clothes
    local category = AppearanceData.drawables[data.category] or AppearanceData.props[data.category]
    for i = 0, GetNumberOfPedDrawableVariations(cache.ped, category.index) do
        if skipClothes[i] then
            goto skip
        end

        -- Also if there're a lot of clothes we can skip some data like category
        stock[#stock + 1] = {
            drawable_id = i,
            textures = GetNumberOfPedTextureVariations(cache.ped, category.index, i),
            category = data.category,
            gender = GetPedGender(cache.ped),
            item_id = nil,
            -- price = Config.DefaultPrice, -- Not needed here cause we already have the default price in the NUI
        }

        ::skip::
    end

    cb(stock)
end)

RegisterNUICallback("updateStockItem", function(data, cb)
    data.item.stockModified = nil
    data.item.fetchingModification = nil
    local result = lib.callback.await('origen_clothing:updateStockItem', false, data.item, data.storeId)
    cb(result)
end)