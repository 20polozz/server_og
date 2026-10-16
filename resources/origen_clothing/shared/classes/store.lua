local isServer = IsDuplicityVersion()
StoreOld = {}
StoreOld.__index = StoreOld
StoreOld.Table = {}

function StoreOld.Get(id)
    return StoreOld.Table[id]
end

function StoreOld.Detele(id)
    local store = StoreOld.Table[id]
    if store then
        store:Delete()
        StoreOld.Table[id] = nil
    end
end

function StoreOld.Clear()
    for id, _ in pairs(StoreOld.Table) do
        StoreOld.Detele(id)
    end
end

function StoreOld.GetHeaders()
    local headers = {}
    for _, store in pairs(StoreOld.Table) do
        local newCoords = ConvertVecToArray(store.coords)
        newCoords = {x = newCoords[1], y = newCoords[2]}
        headers[#headers+1] = {
            id = store.id,
            type = store.type,
            coords = newCoords,
            label = store:GetLabel()
        }
    end
    return headers
end

function StoreOld.new(data)
    local self = setmetatable({}, StoreOld)
    self.id = data.id
    self.type = data.type or "clothes"
    self.coords = ConvertArrayToVec(data.coords)
    self.markers = {}

    self.blip = nil
    if not isServer then
        self.blip = self:CreateBlip()
    end

    self.stock = {}
    self.sameStock = {} -- Indicates if the store has the same stock as the last fetched data for each category
    self.prices = {}
    self.samePrices = {} -- Indicates if the store has the same prices as the last fetched data for each category

    self.interactions = {}

    for k, v in pairs(data.markers or {}) do
        self.markers[k] = ConvertArrayToVec(v)

        if not isServer then
            self:CreateInteraction(k)
        end
    end

    StoreOld.Table[self.id] = self

    return self
end

function StoreOld:__tostring()
    return ("StoreOld(id=%s, type=%s, coords=%s)"):format(self.id, self.type, tostring(self.coords))
end

function StoreOld:Delete()
    if self.blip then
        RemoveBlip(self.blip)
        self.blip = nil
    end

    -- If this method is called due a stop of the resource we don't need to handle this as is already managed by origen_interact
    if TableContains({"stopped", "stopping"}, GetResourceState(ResourceName)) then
        for _, interaction in ipairs(self.interactions) do
            debugger("Removing: ", interaction)
        end
    end
end

function StoreOld:CreateBlip()
    --[[ local storeData = Config.StoreTypes[self.type]
    if not storeData then
        debugger("Invalid store type: " .. self.type)
        return
    end

    local blip = AddBlipForCoord(self.coords.xyz)
    SetBlipSprite(blip, storeData.blip.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipAsShortRange(blip, true)

    return blip ]]
end

function StoreOld:CreateInteraction(markerId)
    local marker = self.markers[markerId]
    if not marker then
        debugger(("Marker with ID %s not found in store %s"):format(markerId, self.id))
        return
    end
    
    --TODO: Hacer luego que se pueda usar Target
    local storeInstance = self

    local point = lib.points.new({
        coords = ConvertVecToArray(marker),
        distance = 5,
        dunak = 'nerd',
    })
     
    function point:onEnter()
        Custom.DrawText(locale('open_store'), 'E')
    end
    
    function point:onExit()
        Custom.HideText()
    end

    function point:nearby()
        if IsControlJustReleased(0, 38) then
            storeInstance:Open(markerId, {})
        end
    end
    
    -- storeInstance:Open(markerId, {})

    -- self.interactions[#self.interactions+1] = exports.origen_interact:addCoords({
    --     id = "origen_clothing_store_"..self.id..":"..markerId,
    --     direction = 'top',
    --     coords = ConvertVec4ToVec3(marker),
    --     options = {
    --         {
    --             label = "Abrir tienda",
    --             icon = "shirt",
    --             onSelect = function(data)
    --                 self:Open(markerId, {})
    --             end,
    --             canInteract = function(entity, distance, coords, id)
    --                 return not InStore
    --             end
    --         }
    --     },
    --     renderDistance = 5.0,
    --     activeDistance = 1.5,
    --     cooldown = 1500,
    -- })
end

function StoreOld:FindNearestMarkerId()
    local playerCoords = GetEntityCoords(cache.ped)
    local closestMarkerId = nil
    local closestDistance = math.huge

    for markerId, marker in pairs(self.markers) do
        local distance = #(playerCoords - marker.xyz)
        if distance < closestDistance then
            closestDistance = distance
            closestMarkerId = markerId
        end
    end

    return closestMarkerId, closestDistance
end

function StoreOld:SameStock(category)
    if Config.StockEnabled then
        return category and self.sameStock[category]
    end
    return category and self.samePrices[category]
end

function StoreOld:NoticeStockChange(category)
    if not category then
        self.sameStock = {}
    end
    self.sameStock[category] = false
    self.samePrices[category] = false
end

function StoreOld:GetStock(category, gender)
    if isServer then
        if not self:SameStock(category) then
            if Config.StockEnabled then
                local stock = GetAvailableStock(self.id, gender, category)
                for k, v in pairs(stock) do
                    v.variations = json.decode(v.variations)
                end
                if category then
                    self.stock[category] = stock
                    self.sameStock[category] = true
                else
                    return stock
                end
            else -- Stock disabled :(
                -- We need to return the price of all the items
                local prices = GetAllPrices(category)
                if category then
                    self.prices[category] = prices
                    self.samePrices[category] = true
                else
                    return prices
                end
            end
        end
        return Config.StockEnabled and self.stock[category] or self.prices[category] or {}
    else
        self.stock = lib.callback.await('origen_clothing:getStoreStock', false, self.id, category)
        return self.stock
    end
end

function StoreOld:GetLabel()
    local storeData = Config.StoreTypes[self.type]
    return storeData and storeData.label or "Tienda de ropa"
end

function StoreOld:OnStockModified(category)
    if not category then
        self.sameStock = {}
    end
    self.sameStock[category] = false
end

function StoreOld:Open(markerId, options)
    -- local distance

    -- options = options or {}
    -- options.onPositionTimeout = options.onPositionTimeout or nop

    -- if not markerId then
    --     markerId, distance = self:FindNearestMarkerId()
    --     if not markerId or (distance > 10 and not options.ignoreDistance) then
    --         debugger(("No valid markers found within range for store: %s"):format(self.id))
    --         return
    --     end
    -- end

    -- InStore = true

    -- local targetCoords = self.markers[markerId]
    -- local timeoutTime = options.positionTimeout or 5000

    -- if not options.disablePositioning then
    --     TaskGoStraightToCoord(cache.ped, targetCoords.xyz, 1.0, timeoutTime, targetCoords.w, 0.5)
    --     local startTime, timeout = GetGameTimer(), false

    --     while true do
    --         if  VectorNearlyEqual(GetEntityCoords(cache.ped), targetCoords, 2.0) and
    --             NearlyEqual(GetEntityHeading(cache.ped), targetCoords.w, 2.0)
    --         then
    --             Wait(500) -- Give time to the ped to end turning in place to reach the target heading so the camera get the right offset
    --             break
    --         end
    --         if GetGameTimer() - startTime > timeoutTime then
    --             timeout = true
    --             options.onPositionTimeout(targetCoords, GetEntityCoords(cache.ped))
    --             break
    --         end
    --         Wait(0)
    --     end

    --     if timeout then
    --         debugger("Timeout while trying reach target coordinates: ", targetCoords)
    --         SetEntityCoords(cache.ped, targetCoords.xyz, false, false, false, false)
    --         SetEntityHeading(cache.ped, targetCoords.w)
    --         Wait(1000) -- Give time to fall to the ground
    --     end
    -- end

    -- local stock = self:GetStock()
    -- debugger(json.encode(stock, {indent = true}))
    StoreOld.OpenMenu(stock, self.id, self.type)
end

function StoreOld.OpenMenu(stock, storeId, type)
    StartCamera(true)
    OpenClothing(type or 'stock', {
        stock = stock == -1 and {} or stock,
        storeId = storeId,
        drawables = GetPedDrawables(cache.ped),
        props = GetPedProps(cache.ped),
        outfits = Outfit.LoadOutfits()
    })
end

function StoreOld.GetGlobalCloths(ped)
    local result = {
        drawables = {},
        props = {},
    }
    for k, v in pairs(AppearanceData.drawables) do
        result.drawables[k] = GetNumberOfPedDrawableVariations(ped, v.index)
    end
    for k, v in pairs(AppearanceData.props) do
        result.props[k] = GetNumberOfPedPropDrawableVariations(ped, v.index)
    end
    return result
end

function StoreOld:AreItemsAvailable(items, gender)
    if not items then
        return false
    end

    for _, item in pairs(items) do
        if not item.hasStock then -- Stock disabled for this item
            goto skip
        end
        local stock = self:GetStock(item.category, gender)
        if not stock or #stock == 0 then
            return false
        end
        local found = false
        for _, stockItem in pairs(stock) do
            if stockItem.drawable_id == item.drawable_id then
                if stockItem.variations[item.selectedTexture + 1] then
                    found = true
                end
                break
            end
        end
        if not found then
            return false
        end
        ::skip::
    end

    return true
end

function StoreOld:RemoveStockItems(items, gender)
    local flag = true
    for _, item in pairs(items) do
        if not item.hasStock then -- Stock disabled for this item
            goto skip
        end
        if not AddStock(self.id, item.category, gender, item.drawable_id, item.selectedTexture + 1, -1) then
            flag = false
        end
        ::skip::
    end
    return flag
end