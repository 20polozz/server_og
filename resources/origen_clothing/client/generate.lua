local defaultCollectionName = 'none'

local hashBlacklist = {
    ['none--1--0--0'] = true,
    ['none--5--0--0'] = true,
    ['none--9--0--0'] = true,
    ['none--1000---1--0'] = true,
    ['none--1001---1--0'] = true,
    ['none--1002---1--0'] = true,
    ['none--1006---1--0'] = true,
    ['none--1007---1--0'] = true
}

local function isBlacklisted(hash)
    return hashBlacklist[hash] == true
end

local legacyCollections = {
    [`mp_m_freemode_01`] = {
        ['Male_freemode_beach'] = 1604,
        ['Male_xmas'] = 1604,
        ['Male_freemode_valentines'] = 1604,
        ['Male_freemode_business'] = 1604,
        ['Male_freemode_business2'] = 1604,
        ['Male_freemode_hipster'] = 1604,
        ['Male_freemode_independence'] = 1604,
        ['Male_freemode_Pilot'] = 1604,
        ['Male_freemode_mpLTS'] = 1604,
        ['Male_xmas2'] = 1604,
        ['Male_Heist'] = 1604,
        ['mp_m_luxe_01'] = 1604,
        ['mp_m_luxe_02'] = 1604,
        ['mp_m_htb_01'] = 1604,
        ['mp_m_lowrider_01'] = 1604,
        ['Male_freemode_Halloween'] = 1604,
        ['Male_Apt01'] = 1604,
        ['mp_m_xmas_03'] = 1604,
        ['mp_m_january2016'] = 1604,
        ['mp_m_valentines_02'] = 1604,
        ['mp_m_lowrider_02'] = 1604,
        ['mp_m_executive_01'] = 1604,
        ['mp_m_stunt_01'] = 1604,
        ['mp_m_bikerdlc_01'] = 1604,
        ['mp_m_importexport_01'] = 1604,
        ['mp_m_gunrunning_hair_01'] = 1604,
        ['mp_m_gunrunning_01'] = 1604,
        ['mp_m_airraces_01'] = 1604,
        ['mp_m_smuggler_01'] = 1604,
        ['mp_m_christmas2017'] = 1604,
        ['mp_m_assault'] = 1604,
        ['mp_m_battle'] = 1604,
        ['mp_m_christmas2018'] = 1604,
        ['mp_m_vinewood'] = 2060,
        ['mp_m_heist3'] = 2060,
        ['mp_m_sum'] = 2060,
        ['mp_m_heist4'] = 2189,
        ['mp_m_tuner'] = 2372,
        ['mp_m_security'] = 2545,
        ['mp_m_sum2'] = 2699,
        ['mp_m_christmas3'] = 2802,
        ['mp_m_2023_01'] = 2944,
        ['mp_m_2023_02'] = 3095,
        ['mp_m_2024_01'] = 3258,
        ['mp_m_2024_02'] = 3407,
        ['mp_m_2025_01'] = 3570
    },
    [`mp_f_freemode_01`] = {
        ['Female_freemode_beach'] = 1604,
        ['Female_xmas'] = 1604,
        ['Female_freemode_valentines'] = 1604,
        ['Female_freemode_business'] = 1604,
        ['Female_freemode_business2'] = 1604,
        ['Female_freemode_hipster'] = 1604,
        ['Female_freemode_independence'] = 1604,
        ['Female_freemode_Pilot'] = 1604,
        ['Female_freemode_mpLTS'] = 1604,
        ['Female_xmas2'] = 1604,
        ['Female_Heist'] = 1604,
        ['mp_f_luxe_01'] = 1604,
        ['mp_f_luxe_02'] = 1604,
        ['mp_f_htb_01'] = 1604,
        ['mp_f_lowrider_01'] = 1604,
        ['Female_freemode_Halloween'] = 1604,
        ['Female_Apt01'] = 1604,
        ['mp_f_xmas_03'] = 1604,
        ['mp_f_january2016'] = 1604,
        ['mp_f_valentines_02'] = 1604,
        ['mp_f_lowrider_02'] = 1604,
        ['mp_f_executive_01'] = 1604,
        ['mp_f_stunt_01'] = 1604,
        ['mp_f_bikerdlc_01'] = 1604,
        ['mp_f_importexport_01'] = 1604,
        ['mp_f_gunrunning_hair_01'] = 1604,
        ['mp_f_gunrunning_01'] = 1604,
        ['mp_f_airraces_01'] = 1604,
        ['mp_f_smuggler_01'] = 1604,
        ['mp_f_christmas2017'] = 1604,
        ['mp_f_assault'] = 1604,
        ['mp_f_battle'] = 1604,
        ['mp_f_christmas2018'] = 1604,
        ['mp_f_vinewood'] = 2060,
        ['mp_f_heist3'] = 2060,
        ['mp_f_sum'] = 2060,
        ['mp_f_heist4'] = 2189,
        ['mp_f_tuner'] = 2372,
        ['mp_f_security'] = 2545,
        ['mp_f_sum2'] = 2699,
        ['mp_f_christmas3'] = 2802,
        ['mp_f_2023_01'] = 2944,
        ['mp_f_2023_02'] = 3095,
        ['mp_f_2024_01'] = 3258,
        ['mp_f_2024_02'] = 3407,
        ['mp_f_2025_01'] = 3570
    }
}


local initialPeds = {
    `mp_m_freemode_01`,
    `mp_f_freemode_01`,
}

local PEDS_NAMES = {
    [`mp_m_freemode_01`] = 'mp_m_freemode_01',
    [`mp_f_freemode_01`] = 'mp_f_freemode_01'
}

local COMPONENTS = {
    [1] = 'masks',
    [3] = 'torsos',
    [4] = 'legs',
    [5] = 'bags',
    [6] = 'shoes',
    [7] = 'neck',
    [8] = 'shirts',
    [9] = 'vest',
    [10] = 'decals',
    [11] = 'jackets'
}

local PROPS_COMPONENTS = {
    [0] = 'hats',
    [1] = 'glasses',
    [2] = 'earrings',
    [6] = 'watches',
    [7] = 'bracelets'
}

local REAL_COMPONENTS_NAMES = {
    ['mask'] = 'berd',
    ['torso'] = 'uppr',
    ['leg'] = 'lowr',
    ['parachute'] = 'hand',
    ['shoes'] = 'feet',
    ['accessory'] = 'teef',
    ['undershirt'] = 'accs',
    ['kevlar'] = 'task',
    ['badge'] = 'decl',
    ['torso2'] = 'jbib'
}

local REAL_COMPONENTS_PROPS_NAMES = {
    ['hats'] = 'head',
    ['glasses'] = 'eyes',
    ['earrings'] = 'earrings',
    ['watches'] = 'watches',
    ['bracelets'] = 'bracelets'
}

local lastPed = nil

local function formatResult(data)
    local isProp = data.isProp
    local collection = legacyCollections[data.model]
    local isValidCollection = collection and collection[data.collection]

    local modelName = PEDS_NAMES[data.model] or Config.Peds[data.model] or data.model
    
    local componentRealName = isProp and REAL_COMPONENTS_PROPS_NAMES[data.component_name] or REAL_COMPONENTS_NAMES[data.component_name]
    local drawableFormatted = string.format('%03d', data.drawableid)
    local textureChar = string.char(97 + data.texture_id)

    local hasCollection = data.collection and data.collection ~= ''
    local collectionPart = hasCollection and ('_%s'):format(data.collection) or ''

    local formatYdd, formatYtd
    local category_name = nil

    if isProp then
        formatYdd = ('%s_p%s^p_%s_%s'):format(modelName, collectionPart, componentRealName, drawableFormatted)
        formatYtd = ('%s_p%s^p_%s_diff_%s_%s'):format(modelName, collectionPart, componentRealName, drawableFormatted, textureChar)

        category_name = PROPS_COMPONENTS[data.componentid]

        data.componentid = 1000 + data.componentid
    else
        formatYdd = ('%s%s^%s_%s'):format(modelName, collectionPart, componentRealName, drawableFormatted)
        formatYtd = ('%s%s^%s_diff_%s_%s'):format(modelName, collectionPart, componentRealName, drawableFormatted, textureChar)

        category_name = COMPONENTS[data.componentid]
    end

    if not data.collection or data.collection == '' then 
        data.collection = defaultCollectionName
    end

    local isAddon = (collection and collection[data.collection]) or data.collection == 'none'

    local hashName = ('%s--%s--%s--%s'):format(data.collection, data.componentid, data.drawableid, data.texture_id)

    return {
        model = data.model,
        game_build = isValidCollection or 1604,
        hash = hashName,
        collection = data.collection,
        component_id = data.componentid,
        texture_id = data.texture_id,
        category_name = category_name,
        global_drawable_id = data.global_drawable_id,
        image_url = '',
        ydd_name = formatYdd,
        ytd_name = formatYtd,
        addon = isAddon and 0 or 1,
        is_valid = 0
    }
end

local function addItemToDatabase(item)
    if isBlacklisted(item.hash) then return false end

    local response = lib.callback.await('origen_clothing:server:GenerateItems', false, item)

    return response
end

local function addItemsBatchToDatabase(items)
    if not items or #items == 0 then return false end

    local response = lib.callback.await('origen_clothing:server:GenerateItemsBatch', false, items)

    return response
end

local function applyPed(model)
    if IsModelInCdimage(model) and IsModelValid(model) then
        RequestModel(model)
        while not HasModelLoaded(model) do
            Wait(0)
        end
        SetPlayerModel(PlayerId(), model)
        SetModelAsNoLongerNeeded(model)

        SetPedComponentVariation(PlayerPedId(), 0, 0, 0, 0)
    end
end

local function restoreSkin()
    -- TODO: Restore skin
    ExecuteCommand('reloadskin')
end

RegisterCommand('generate', function()
    if not isAdmin() then return end
    local initialPed = PlayerPedId()
    local currentPed = GetEntityModel(initialPed)
    local list = {}
    local itemList = {}
    
    lastPed = currentPed

    for _, model in pairs(initialPeds) do
        applyPed(model)

        local ped = PlayerPedId()

        local count = GetPedCollectionsCount(ped)
        local collections = {}
        
        for i = 0, count - 1 do
            local collectionName = GetPedCollectionName(ped, i)

            for componentId, componentName in pairs(COMPONENTS) do
                local drawableVariationsCount = GetNumberOfPedCollectionDrawableVariations(ped, componentId, collectionName)

                for drawableId = 0, drawableVariationsCount - 1 do
                    local globalDrawableIndex = GetPedDrawableGlobalIndexFromCollection(ped, componentId, collectionName, drawableId)

                    local textureVariationsCount = GetNumberOfPedCollectionTextureVariations(ped, componentId, collectionName, drawableId)

                    for textureId = 0, textureVariationsCount - 1 do

                        local result = formatResult({
                            model = model,
                            collection = collectionName,
                            componentid = componentId,
                            drawableid = drawableId,
                            global_drawable_id = globalDrawableIndex,
                            texture_id = textureId,
                            component_name = componentName
                        })
                        
                        itemList[#itemList + 1] = result
                        addItemToDatabase(result)

                        Wait(0)
                    end

                    Wait(0)
                end
            end

            for componentId, componentName in pairs(PROPS_COMPONENTS) do
                local drawablePropVariationsCount = GetNumberOfPedCollectionPropDrawableVariations(ped, componentId, collectionName)
                
                for drawablePropId = 0, drawablePropVariationsCount - 1 do
                    local globalPropIndex = GetPedPropGlobalIndexFromCollection(ped, componentId, collectionName, drawablePropId)

                    local texturePropVariationsCount = GetNumberOfPedCollectionPropTextureVariations(ped, componentId, collectionName, drawablePropId)

                    for texturePropId = 0, texturePropVariationsCount - 1 do
                                                
                        local result = formatResult({
                            model = model,
                            collection = collectionName,
                            componentid = componentId,
                            drawableid = drawablePropId,
                            global_drawable_id = globalPropIndex,
                            texture_id = texturePropId,
                            component_name = componentName,
                            isProp = true
                        })

                        itemList[#itemList + 1] = result
                        addItemToDatabase(result)

                        Wait(0)
                    end

                    Wait(0)
                end

            end
        end

        Wait(500)
    end

    restoreSkin()
    lastPed = nil
end, false)

local function generateItemsForPed(model, collectionFilter, componentFilter, isPropFilter)
    local itemList = {}
    
    applyPed(model)
    local ped = PlayerPedId()
    local count = GetPedCollectionsCount(ped)
    
    for i = 0, count - 1 do
        local collectionName = GetPedCollectionName(ped, i)
        
        if not collectionFilter or collectionName == collectionFilter then
            if not isPropFilter or isPropFilter == false then
                for componentId, componentName in pairs(COMPONENTS) do
                    if not componentFilter or componentName == componentFilter then
                        local drawableVariationsCount = GetNumberOfPedCollectionDrawableVariations(ped, componentId, collectionName)
                        
                        for drawableId = 0, drawableVariationsCount - 1 do
                            local globalDrawableIndex = GetPedDrawableGlobalIndexFromCollection(ped, componentId, collectionName, drawableId)
                            local textureVariationsCount = GetNumberOfPedCollectionTextureVariations(ped, componentId, collectionName, drawableId)
                            
                            for textureId = 0, textureVariationsCount - 1 do
                                local result = formatResult({
                                    model = model,
                                    collection = collectionName,
                                    componentid = componentId,
                                    drawableid = drawableId,
                                    global_drawable_id = globalDrawableIndex,
                                    texture_id = textureId,
                                    component_name = componentName
                                })
                                
                                itemList[#itemList + 1] = result
                                addItemToDatabase(result)
                                Wait(0)
                            end
                            Wait(0)
                        end
                    end
                end
            end
            
            if not isPropFilter or isPropFilter == true then
                for componentId, componentName in pairs(PROPS_COMPONENTS) do
                    if not componentFilter or componentName == componentFilter then
                        local drawablePropVariationsCount = GetNumberOfPedCollectionPropDrawableVariations(ped, componentId, collectionName)
                        
                        for drawablePropId = 0, drawablePropVariationsCount - 1 do
                            local globalPropIndex = GetPedPropGlobalIndexFromCollection(ped, componentId, collectionName, drawablePropId)
                            local texturePropVariationsCount = GetNumberOfPedCollectionPropTextureVariations(ped, componentId, collectionName, drawablePropId)
                            
                            for texturePropId = 0, texturePropVariationsCount - 1 do
                                local result = formatResult({
                                    model = model,
                                    collection = collectionName,
                                    componentid = componentId,
                                    drawableid = drawablePropId,
                                    global_drawable_id = globalPropIndex,
                                    texture_id = texturePropId,
                                    component_name = componentName,
                                    isProp = true
                                })
                                
                                itemList[#itemList + 1] = result
                                addItemToDatabase(result)
                                Wait(0)
                            end
                            Wait(0)
                        end
                    end
                end
            end
        end
    end
    
    return itemList
end

RegisterCommand('generatecollection', function(source, args)
    if not isAdmin() then return end
    if #args < 1 then return end
    
    local collectionName = args[1]
    local pedModel = args[2]
    local itemList = {}
    
    lastPed = GetEntityModel(PlayerPedId())
    
    if pedModel then
        local modelHash = GetHashKey(pedModel)
        if not IsModelValid(modelHash) or not IsModelAPed(modelHash) then
            restoreSkin()
            return
        end
        
        generateItemsForPed(modelHash, collectionName, nil, nil)
    else
        for _, model in pairs(initialPeds) do
            generateItemsForPed(model, collectionName, nil, nil)
            Wait(500)
        end
    end
    
    restoreSkin()
    lastPed = nil
end, false)

RegisterCommand('generatecomponent', function(source, args)
    if not isAdmin() then return end
    if #args < 1 then return end
    
    local componentName = args[1]
    local pedModel = args[2]
    
    local isValidComponent = false
    for _, name in pairs(COMPONENTS) do
        if name == componentName then
            isValidComponent = true
            break
        end
    end
    
    if not isValidComponent then
        for _, name in pairs(PROPS_COMPONENTS) do
            if name == componentName then
                isValidComponent = true
                break
            end
        end
    end
    
    if not isValidComponent then return end
    
    lastPed = GetEntityModel(PlayerPedId())
    
    if pedModel then
        local modelHash = GetHashKey(pedModel)
        if not IsModelValid(modelHash) or not IsModelAPed(modelHash) then
            restoreSkin()
            return
        end
        
        generateItemsForPed(modelHash, nil, componentName, nil)
    else
        for _, model in pairs(initialPeds) do
            generateItemsForPed(model, nil, componentName, nil)
            Wait(500)
        end
    end
    
    restoreSkin()
    lastPed = nil
end, false)

RegisterCommand('generateped', function(source, args)
    if not isAdmin() then return end
    if #args < 1 then return end
    
    local pedModel = args[1]
    local modelHash = GetHashKey(pedModel)
    
    if not IsModelValid(modelHash) or not IsModelAPed(modelHash) then return end
    
    lastPed = GetEntityModel(PlayerPedId())
    
    generateItemsForPed(modelHash, nil, nil, nil)
    
    restoreSkin()
    lastPed = nil
end, false)

local importCancelled = false

function CancelImport()
    importCancelled = true
end

local function updateImportProgress(current, total, status, completed, cancelled)
    SendNUIMessage({
        action = 'updateImportProgress',
        current = current,
        total = total,
        status = status or 'processing',
        completed = completed or false,
        cancelled = cancelled or false
    })
end

local function countTotalItems(models, collectionFilter, componentFilter)
    local total = 0
    
    for _, model in pairs(models) do
        applyPed(model)
        local ped = PlayerPedId()
        local count = GetPedCollectionsCount(ped)
        
        for i = 0, count - 1 do
            local collectionName = GetPedCollectionName(ped, i)
            
            if not collectionFilter or collectionName == collectionFilter then
                for componentId, componentName in pairs(COMPONENTS) do
                    if not componentFilter or componentName == componentFilter then
                        local drawableVariationsCount = GetNumberOfPedCollectionDrawableVariations(ped, componentId, collectionName)
                        for drawableId = 0, drawableVariationsCount - 1 do
                            local textureVariationsCount = GetNumberOfPedCollectionTextureVariations(ped, componentId, collectionName, drawableId)
                            total = total + textureVariationsCount
                        end
                    end
                end
                
                for componentId, componentName in pairs(PROPS_COMPONENTS) do
                    if not componentFilter or componentName == componentFilter then
                        local drawablePropVariationsCount = GetNumberOfPedCollectionPropDrawableVariations(ped, componentId, collectionName)
                        for drawablePropId = 0, drawablePropVariationsCount - 1 do
                            local texturePropVariationsCount = GetNumberOfPedCollectionPropTextureVariations(ped, componentId, collectionName, drawablePropId)
                            total = total + texturePropVariationsCount
                        end
                    end
                end
            end
        end
        Wait(0)
    end
    
    return total
end

local function generateItemsWithProgress(models, collectionFilter, componentFilter)
    local current = 0
    local total = 0
    local batchSize = 500
    local itemsBatch = {}
    
    updateImportProgress(0, 0, 'calculating', false, false)
    Wait(500)
    
    total = countTotalItems(models, collectionFilter, componentFilter)
    updateImportProgress(0, total, 'starting', false, false)
    Wait(500)
    
    local function flushBatch()
        if #itemsBatch > 0 then
            addItemsBatchToDatabase(itemsBatch)
            current = current + #itemsBatch
            updateImportProgress(current, total, 'processing', false, false)
            itemsBatch = {}
        end
    end
    
    for _, model in pairs(models) do
        if importCancelled then break end
        
        applyPed(model)
        local ped = PlayerPedId()
        local count = GetPedCollectionsCount(ped)
        
        for i = 0, count - 1 do
            if importCancelled then break end
            
            local collectionName = GetPedCollectionName(ped, i)
            
            if not collectionFilter or collectionName == collectionFilter then
                for componentId, componentName in pairs(COMPONENTS) do
                    if importCancelled then break end
                    
                    if not componentFilter or componentName == componentFilter then
                        local drawableVariationsCount = GetNumberOfPedCollectionDrawableVariations(ped, componentId, collectionName)
                        
                        for drawableId = 0, drawableVariationsCount - 1 do
                            if importCancelled then break end
                            
                            local globalDrawableIndex = GetPedDrawableGlobalIndexFromCollection(ped, componentId, collectionName, drawableId)
                            local textureVariationsCount = GetNumberOfPedCollectionTextureVariations(ped, componentId, collectionName, drawableId)
                            
                            for textureId = 0, textureVariationsCount - 1 do
                                if importCancelled then break end
                                
                                local result = formatResult({
                                    model = model,
                                    collection = collectionName,
                                    componentid = componentId,
                                    drawableid = drawableId,
                                    global_drawable_id = globalDrawableIndex,
                                    texture_id = textureId,
                                    component_name = componentName
                                })
                                
                                if not isBlacklisted(result.hash) then
                                    table.insert(itemsBatch, result)
                                    
                                    if #itemsBatch >= batchSize then
                                        flushBatch()
                                    end
                                end
                                
                                Wait(0)
                            end
                        end
                    end
                end
                
                for componentId, componentName in pairs(PROPS_COMPONENTS) do
                    if importCancelled then break end
                    
                    if not componentFilter or componentName == componentFilter then
                        local drawablePropVariationsCount = GetNumberOfPedCollectionPropDrawableVariations(ped, componentId, collectionName)
                        
                        for drawablePropId = 0, drawablePropVariationsCount - 1 do
                            if importCancelled then break end
                            
                            local globalPropIndex = GetPedPropGlobalIndexFromCollection(ped, componentId, collectionName, drawablePropId)
                            local texturePropVariationsCount = GetNumberOfPedCollectionPropTextureVariations(ped, componentId, collectionName, drawablePropId)
                            
                            for texturePropId = 0, texturePropVariationsCount - 1 do
                                if importCancelled then break end
                                
                                local result = formatResult({
                                    model = model,
                                    collection = collectionName,
                                    componentid = componentId,
                                    drawableid = drawablePropId,
                                    global_drawable_id = globalPropIndex,
                                    texture_id = texturePropId,
                                    component_name = componentName,
                                    isProp = true
                                })
                                
                                if not isBlacklisted(result.hash) then
                                    table.insert(itemsBatch, result)
                                    
                                    if #itemsBatch >= batchSize then
                                        flushBatch()
                                    end
                                end
                                
                                Wait(0)
                            end
                        end
                    end
                end
            end
        end
        
        flushBatch()
        Wait(50)
    end
    
    flushBatch()
    
    if importCancelled then
        updateImportProgress(current, total, 'cancelled', false, true)
    else
        updateImportProgress(current, total, 'completed', true, false)
    end
    
    return current
end

function StartImportClothing(data)
    CreateThread(function()
        importCancelled = false
        lastPed = GetEntityModel(PlayerPedId())
        
        local mode = data.mode or 'all'
        local models = {}
        local collectionFilter = nil
        local componentFilter = nil
        
        if mode == 'all' then
            models = initialPeds
        elseif mode == 'ped' then
            if data.ped and data.ped ~= '' then
                local modelHash = GetHashKey(data.ped)
                if IsModelValid(modelHash) and IsModelAPed(modelHash) then
                    models = {modelHash}
                else
                    restoreSkin()
                    lastPed = nil
                    updateImportProgress(0, 0, 'error', false, true)
                    return
                end
            else
                models = initialPeds
            end
        elseif mode == 'collection' then
            models = initialPeds
            collectionFilter = data.collection == 'none' and '' or data.collection
        elseif mode == 'component' then
            models = initialPeds
            if data.component and data.component ~= '' then
                componentFilter = data.component
            end
        end
        
        if #models == 0 then
            restoreSkin()
            lastPed = nil
            updateImportProgress(0, 0, 'error', false, true)
            return
        end
        
        generateItemsWithProgress(models, collectionFilter, componentFilter)
        
        Wait(500)
        restoreSkin()
        lastPed = nil
    end)
end

local migrationCancelled = false

function CancelMigration()
    migrationCancelled = true
end

local function updateMigrationProgress(current, total, status, completed, cancelled)
    SendNUIMessage({
        action = 'updateImportProgress',
        current = current,
        total = total,
        status = status or 'processing',
        completed = completed or false,
        cancelled = cancelled or false
    })
end

function StartMigrateSkins(data)
    CreateThread(function()
        migrationCancelled = false
        
        local system = data.system
        if not system or system == '' then
            updateMigrationProgress(0, 0, 'error', false, true)
            return
        end
        
        local callbackName = ''
        local countCallbackName = ''
        
        if system == 'qbcore' then
            callbackName = 'origen_clothing:server:MigrateQBBatch'
            countCallbackName = 'origen_clothing:server:GetQBSkinsCount'
        elseif system == 'esx' then
            callbackName = 'origen_clothing:server:MigrateESXBatch'
            countCallbackName = 'origen_clothing:server:GetESXSkinsCount'
        elseif system == 'illenium' then
            callbackName = 'origen_clothing:server:MigrateIlleniumBatch'
            countCallbackName = 'origen_clothing:server:GetIlleniumSkinsCount'
        else
            updateMigrationProgress(0, 0, 'error', false, true)
            return
        end
        
        updateMigrationProgress(0, 0, 'calculating', false, false)
        Wait(500)
        
        local total = lib.callback.await(countCallbackName, false)
        
        if not total or total == 0 then
            updateMigrationProgress(0, 0, 'completed', true, false)
            return
        end
        
        updateMigrationProgress(0, total, 'starting', false, false)
        Wait(500)
        
        local batchSize = 50
        local processed = 0
        
        while processed < total and not migrationCancelled do
            local migrated = lib.callback.await(callbackName, false, processed, batchSize)
            
            if not migrated then
                updateMigrationProgress(processed, total, 'error', false, true)
                return
            end
            
            processed = processed + migrated
            updateMigrationProgress(processed, total, 'processing', false, false)
            Wait(100)
        end
        
        if migrationCancelled then
            updateMigrationProgress(processed, total, 'cancelled', false, true)
        else
            updateMigrationProgress(processed, total, 'completed', true, false)
        end
    end)
end