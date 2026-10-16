local craftingPointType = Config.WorldPoints.PointTypes.crafting

Sprite = {
    dict = nil,
    txt = nil,
    dui = nil
}

Sprite.loadDict = function()
    if not HasStreamedTextureDictLoaded(Sprite.dict) then
        RequestStreamedTextureDict(Sprite.dict)
        while not HasStreamedTextureDictLoaded(Sprite.dict) do
            Wait(10)
        end
    end
end

Sprite.unload = function()
    SetStreamedTextureDictAsNoLongerNeeded(Sprite.dict)
end

Sprite.update = function(icon)
    SendDuiMessage(Sprite.dui, json.encode(
        {
            action = 'changeSpriteIcon',
            data = {
                icon = icon
            }
        }
    ))
end

Sprite.updateCrafting = function(craftingData)
    if not Sprite.dui then return end
    SendDuiMessage(Sprite.dui, json.encode(
        {
            action = 'onNearbyCrafting',
            data = craftingData
        }
    ))
end

Sprite.emitEvent = function(eventName, data)
    SendDuiMessage(Sprite.dui, json.encode(
        {
            action = eventName,
            data = data
        }
    ))
end

Sprite.updateCraftingSprite = function(craftingId)
    if not craftingPointType.sprite?.enabled or craftingPointType.sprite?.showCraftingPanel == false then
        return
    end
    local response = Callbacks.await('origen_inventory:server:fetchCurrentCraftingStatus', false, craftingId)
    if not response then return end

    local currentCrafting = response.current or 0
    local craftingItems = response.max or 0

    Sprite.updateCrafting({
        name = response.name or 'Fabricación',
        current = currentCrafting,
        max = craftingItems
    })
end

Sprite.draw = function(coords)
    local camCoords = GetGameplayCamCoord()
    local distance = #(coords - camCoords)
    local scale = 1.3
    scale = math.floor(scale * 10000) / 10000
    scale = scale * math.exp(-0.15 * distance)

    local spriteScale = scale > 0.02 and scale or 0.02
    SetScriptGfxAlignParams(0.0, 0.0, 0.0, 0.0)
    SetDrawOrigin(coords.x, coords.y, coords.z)
    DrawInteractiveSprite(Sprite.dict, Sprite.txt, 0.0, 0.0, spriteScale, spriteScale, 0.0, 255, 255, 255, 255)
end

Sprite.normalizeVector = function(vec)
    local length = math.sqrt(vec.x * vec.x + vec.y * vec.y + vec.z * vec.z)
    if length == 0 then
        return vector3(0, 0, 0)
    end
    return vector3(vec.x / length, vec.y / length, vec.z / length)
end

Sprite.drawFloatingLight = function(coords, settings)
    local lightColor = settings.color or vector4(255, 255, 200, 100)
    local lightSize = settings.size or 3.0
    local lightFloatIntensity = settings.floatIntensity or 4.0

    DrawCorona(coords.x, coords.y, coords.z, lightSize, lightColor.x, lightColor.y, lightColor.z, lightColor.w,
    lightFloatIntensity, 0.2, coords.x, coords.y, coords.z, 2.0, 0.0, 90.0, 2)
end

CreateThread(function()
    local txdName = 'orginv_sprite'
    local txtName = 'orginv_sprite_texture'
    local txd = CreateRuntimeTxd(txdName)
    local screenW, screenH = GetActiveScreenResolution()
    local DuiObject = CreateDui('https://cfx-nui-origen_inventory/ui/sprite.html', screenW, screenH)


    CreateRuntimeTextureFromDuiHandle(txd, txtName, GetDuiHandle(DuiObject))

    Sprite.dict = txdName
    Sprite.txt = txtName
    Sprite.dui = DuiObject
end)
