local isServer = IsDuplicityVersion()
HairSlot = {}
HairSlot.__index = HairSlot
HairSlot.Table = {}
HairSlot.fetched = false

function HairSlot.new(data)
    local self = setmetatable({}, HairSlot)
    debugger("Create hair slot: ", json.encode(data, {indent = true}))
    self.index = data.index
    self.drawable = data.drawable or 0
    self.texture = data.texture or 0
    self.color = data.color or 0
    self.highlightColor = data.highlightColor or 0
    self.active = data.active or self:IsEquiped()
    self.modified = false
    HairSlot.Table[self.index] = self
    return self
end

function HairSlot:GetData(extraFields)
    local data = {
        drawable = self.drawable,
        texture = self.texture,
        color = self.color,
        highlightColor = self.highlightColor,
    }
    for _, field in pairs(extraFields or {}) do
        data[field] = self[field]
    end
    return data
end

function HairSlot.Fetch(data)
    -- If the script has been restarted the hair slots is not assigned by the ReloadAppearance function, so we need to manually fetch the data
    -- The data arg is optional and can be provided to bypass the callback fetch
    if HairSlot.fetched then return end
    HairSlot.fetched = true
    if not data then
        data = lib.callback.await('origen_clothing:getHairSlots', false)
    end
    HairSlot.Clear()

    if not data or #data == 0 then
        -- Initialize default slots
        data = {
            [1] = {
                drawable = GetPedDrawableVariation(cache.ped, 2),
                texture = GetPedTextureVariation(cache.ped, 2),
                color = GetPedHairColor(cache.ped),
                highlightColor = GetPedHairHighlightColor(cache.ped),
                active = true
            },
            [2] = {},
            [3] = {}
        }
    end

    local nuiRetval = {}
    for index, slotData in pairs(data) do
        local slot = HairSlot.new({
            index = index,
            drawable = slotData.drawable,
            texture = slotData.texture,
            color = slotData.color,
            highlightColor = slotData.highlightColor,
            active = slotData.active or false
        })
        nuiRetval[index] = slot:GetData({"active"})
    end

    SendNUIMessage({
        action = 'updateHairSlots',
        hairSlots = nuiRetval
    })
end

function HairSlot.Update(index, data)
    local slot = HairSlot.Table[index]
    if not slot then
        slot = HairSlot.new({index = index})
    end
    debugger("Update hair slot: ", json.encode(data, {indent = true}))
    slot.drawable = data.drawable or slot.drawable
    slot.texture = data.texture or slot.texture
    slot.color = data.color or slot.color
    slot.highlightColor = data.highlightColor or slot.highlightColor
    slot.active = slot:IsEquiped()
    slot.modified = true
end

function HairSlot:Use()
    SetPedComponentVariation(cache.ped, 2, self.drawable, self.texture, 0)
    SetPedHairColor(cache.ped, self.color, self.highlightColor)

    for index, _ in pairs(HairSlot.Table) do
        HairSlot.Table[index].active = false
    end
    self.active = true
end

function HairSlot:IsEquiped()
    return  self.drawable == GetPedDrawableVariation(cache.ped, 2) and
            self.texture == GetPedTextureVariation(cache.ped, 2) and
            self.color == GetPedHairColor(cache.ped) and
            self.highlightColor == GetPedHairHighlightColor(cache.ped)
end

function HairSlot.Clear()
    HairSlot.Table = {}
end

function HairSlot.Get(index)
    return HairSlot.Table[index]
end

function HairSlot.GetEquipped()
    for _, slot in pairs(HairSlot.Table) do
        if slot:IsEquiped() then
            return slot
        end
    end
    return nil
end

if isServer then
    function HairSlot.GetAll(identifier)
        local data = MySQL.query.await([[
            SELECT hairslots FROM origen_clothing_skins WHERE citizenid = ? AND active = 1
        ]], {identifier})
        if data and data[1] and data[1].hairslots then
           return json.decode(data[1].hairslots)
        end
        return nil
    end
end

function HairSlot.Save(identifier, saveData)
    if isServer then
        MySQL.update.await([[
            UPDATE origen_clothing_skins SET hairslots = ? WHERE citizenid = ? AND active = 1
        ]], {json.encode(saveData), identifier})
        return true
    else
        local slotModified = false
        local retval = {}
        for index, slot in pairs(HairSlot.Table) do
            retval[index] = slot:GetData()
            if slot.modified then
                slotModified = true
                slot.modified = false -- Reset modified flag
            end
        end
        if not slotModified then
            retval = nil
            return
        end
        lib.callback.await('origen_clothing:saveHairSlots', false, retval)
    end
end


if not isServer then
    CreateThread(function()
        RegisterCloseMenuCallback(function()
            HairSlot.Save(nil, nil)
        end)
    end)

    RegisterNetEvent("origen_clothing:client:selectHairSlot", function(index)
        HairSlot.Fetch()
        if not index then
            local slot = HairSlot.GetEquipped()
            if not slot then
                for _, s in pairs(HairSlot.Table) do
                    if s.active then slot = s; break end
                end
            end
            if not slot then
                slot = HairSlot.Get(1)
            end
            if not slot then
                Custom.Notify(locale('no_hair_slot'), "error")
                return
            end
            index = slot.index + 1
            debugger("Target index: ", index)
            if index > 3 then
                index = 1
            end
        end
        local slot = HairSlot.Get(index)
        if not slot then
            debugger("Hair slot not found:", index)
            return
        end
        slot:Use()
        Custom.Notify(locale('hair_slot_equipped', index), "success")
    end)

    --TODO: Migrar o ver que hacer con este menu
    -- RegisterCommand("pelos", function()
    --     HairSlot.Fetch()
    --     local menu = {
    --         {
    --             header = "Slots de pelo",
    --             isMenuHeader = true,
    --         }
    --     }

    --     for k, v in pairs(HairSlot.Table) do
    --         table.insert(menu, {
    --             header = "Slot " .. k,
    --             description = "Aplicar modificación de pelo " .. k,
    --             icon = "fa-solid fa-check-to-slot",
    --             params = {
    --                 event = "origen_clothing:client:selectHairSlot",
    --                 args = k
    --             }
    --         })
    --     end

    --     exports["org-menu"]:openMenu(menu)
    -- end)
end