ClothingController = {}
ClothingController.isReady = false

ClothingController.isCAIEnabled = function()
    if not Config.Player.ClothesAsItem.Enable then
        Config.Player.ClothesAsItem.Enable = false
        return false
    end

    local isResourceActive = GetResourceState('origen_clothing') == 'started' or
        GetResourceState('origen_clothing') == 'starting'
    if not isResourceActive then return false end


    return true
end

local function loadCLothes()
    if not ClothingController.isCAIEnabled() then return end

    local ped = PlayerPedId()
    local skin = exports.origen_clothing:GetAppearanceData(ped)
    while not Player.equipedClothes do
        Wait(500)
    end

    if skin then
        local drawables = skin.drawables
        local props = skin.props
        local toApplyDrawables = Player.equipedClothes.drawables
        local toApplyProps = Player.equipedClothes.props

        for clothingType, _ in pairs(drawables) do
            if toApplyDrawables[clothingType] then
                local hash = toApplyDrawables[clothingType]
                exports.origen_clothing:SetPedDrawableByHash(ped, hash, true)
            else
                exports.origen_clothing:RemoveClothing(ped, clothingType, true)
            end
        end

        for clothingType, _ in pairs(props) do
            if toApplyProps[clothingType] then
                local hash = toApplyProps[clothingType]
                exports.origen_clothing:SetPedPropByHash(ped, hash, true)
            else
                exports.origen_clothing:RemoveClothing(ped, clothingType, true)
            end
        end
    end

    ClothingController.isReady = true
end

RegisterNetEvent('origen_clothing:loadClothes', function()
    loadCLothes()
end)

RegisterNetEvent('origen_clothing:saveAppearance', function(data)
    if not ClothingController.isReady then return end

    ClothingController.isReady = false

    local drawables = data.drawables
    local props = data.props

    local updatedClothes = {
        drawables = {
            masks = true,
            neck = true,
            jackets = true,
            vest = true,
            shirts = true,
            bags = true,
            torsos = true,
            legs = true,
            shoes = true,
        },
        props = {
            hats = true,
            glasses = true,
            watches = true,
        }
    }

    local model = GetEntityModel(PlayerPedId())

    for clothingType, hash in pairs(drawables) do
        local isIgnoredDrawable = exports.origen_clothing:GetRemoveHash(model, clothingType)

        if hash and updatedClothes.drawables[clothingType] and isIgnoredDrawable ~= hash then
            updatedClothes.drawables[clothingType] = hash
        else
            updatedClothes.drawables[clothingType] = nil
        end
    end

    for clothingType, hash in pairs(props) do
        local isIgnoredProp = exports.origen_clothing:GetRemoveHash(model, clothingType)

        if hash and updatedClothes.props[clothingType] and isIgnoredProp ~= hash then
            updatedClothes.props[clothingType] = hash
        else
            updatedClothes.props[clothingType] = nil
        end
    end

    TriggerServerEvent('origen_inventory:updateEquippedClothes', updatedClothes)

    ClothingController.isReady = true
end)

ClothingController.getClothingImages = function()
    local ped = PlayerPedId()
    local model = GetEntityModel(ped)

    if not Player.equipedClothes then return {} end

    local hashes = {}

    if Player.equipedClothes.drawables then
        for _, hash in pairs(Player.equipedClothes.drawables) do
            if hash and hash ~= nil then
                hashes[#hashes + 1] = hash
            end
        end
    end

    if Player.equipedClothes.props then
        for _, hash in pairs(Player.equipedClothes.props) do
            if hash and hash ~= nil then
                hashes[#hashes + 1] = hash
            end
        end
    end

    if #hashes == 0 then return {} end

    local p = promise.new()

    Bridge.TriggerCallback('origen_inventory:getClothingImages', function(images)
        p:resolve(images or {})
    end, model, hashes)

    return Citizen.Await(p)
end
