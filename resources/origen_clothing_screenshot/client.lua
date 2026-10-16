local takingScreenshot = false
local screenshotCamera = nil
local forceStop = false
-- El muñeco de las fotos con maniquí (fotografiarLista). Con él puesto, quien posa es él y no
-- el admin: su personaje ni cambia de modelo ni va a la pantalla verde.
local maniqui = nil
local startCoords = vector(0.0, 0.0, 0.0)
local originalAppearance = nil
local originalModel = nil

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

local function buildIndexArray(requested, mapping)
    local result = {}

    if requested ~= "all" then
        for index, name in pairs(mapping) do
            if name == requested then
                result[#result + 1] = index
                return result
            end
        end
        return result
    end

    for index in pairs(mapping) do
        result[#result + 1] = index
    end
    table.sort(result)
    return result
end

local function buildStringArray(requested, fetchAllFn)
    local result = {}

    if requested ~= "all" then
        result[1] = requested
        return result
    end

    for _, coll in ipairs(fetchAllFn()) do
        result[#result + 1] = coll
    end

    return result
end

local function getAllCollections(ped)
    local t = {}
    local count = GetPedCollectionsCount(ped)
    for i = 0, count - 1 do
        t[#t + 1] = GetPedCollectionName(ped, i)
    end
    return t
end

local function getComponentVariations(ped, isProp, componentIdx, collection)
    if isProp then
        return GetNumberOfPedCollectionPropDrawableVariations(ped, componentIdx, collection)
    else
        return GetNumberOfPedCollectionDrawableVariations(ped, componentIdx, collection)
    end
end

local function getGlobalVariationIndex(ped, isProp, componentIdx, collection, drawableId)
    if isProp then
        return GetPedPropGlobalIndexFromCollection(ped, componentIdx, collection, drawableId)
    else
        return GetPedDrawableGlobalIndexFromCollection(ped, componentIdx, collection, drawableId)
    end
end

local function getComponentTextures(ped, isProp, componentIdx, collection, drawableId)
    if isProp then
        return GetNumberOfPedCollectionPropTextureVariations(ped, componentIdx, collection, drawableId)
    else
        return GetNumberOfPedCollectionTextureVariations(ped, componentIdx, collection, drawableId)
    end
end

local function removePedClothes(ped)
    SetPedComponentVariation(ped, 0, -1, 0, 0)  -- Head
	SetPedComponentVariation(ped, 1, 0, 0, 0)   -- Mask
	SetPedComponentVariation(ped, 2, -1, 0, 0)  -- Hair
	SetPedComponentVariation(ped, 7, 0, 0, 0)   -- Accessories
	SetPedComponentVariation(ped, 5, 0, 0, 0)   -- Bags
	SetPedComponentVariation(ped, 6, -1, 0, 0)  -- Shoes
	SetPedComponentVariation(ped, 9, 0, 0, 0)   -- Armor
	SetPedComponentVariation(ped, 3, -1, 0, 0)  -- Torso
	SetPedComponentVariation(ped, 8, -1, 0, 0)  -- Undershirt
	SetPedComponentVariation(ped, 4, -1, 0, 0)  -- Legs
	SetPedComponentVariation(ped, 11, -1, 0, 0) -- Top

	SetPedHairColor(ped, 45, 15)
    ClearAllPedProps(ped)
end

local function startScreenshotCamera(_, camData)
    if screenshotCamera then
        DestroyCam(screenshotCamera, true)
    end
    DestroyAllCams(true)

    local ped = maniqui or PlayerPedId()

    local targetCoords = GetPedBoneCoords(ped, camData.boneId, camData.targetOffset.x, camData.camOffset.y, camData.camOffset.z).xyz

    local newcam = CreateCamWithParams(
		'DEFAULT_SCRIPTED_CAMERA',
		targetCoords,
		0.0,
		0.0,
		0.0,
		camData.fov,
		false,
		0
	)
    PointCamAtCoord(newcam, GetPedBoneCoords(ped, camData.boneId, camData.targetOffset.x, camData.targetOffset.y, camData.targetOffset.z).xyz)
    SetCamUseShallowDofMode(newcam, true)
    SetCamNearDof(newcam, 0.2)
    SetCamFarDof(newcam, 1.0)
    SetCamDofStrength(newcam, 1.0)

    SetCamActiveWithInterp(newcam, currentCamera, 700, 1, 1)

    RenderScriptCams(true, false, 0, true, true)

    screenshotCamera = cam
end

--- `lista` (opcional): las prendas exactas que hay que fotografiar, cada una
--- { collection, component, drawable, texture, isProp }. Con ella no se recorren
--- colecciones ni componentes: se hacen esas y nada más (fotografiarLista, abajo).
local function screenshotClothes(collections, isProp, components, variation, skipExisting, textureFilter, lista)
    local ped = maniqui or PlayerPedId()
    local pedHash = GetEntityModel(ped)

    FreezeEntityPosition(ped, true)
    SetEntityCoordsNoOffset(ped, Config.GreenScreenPos.x, Config.GreenScreenPos.y, Config.GreenScreenPos.z, false, false, false)
    SetEntityHeading(ped, Config.GreenScreenPos.w)

    local esperaSuelo = GetGameTimer()
    while not HasCollisionLoadedAroundEntity(ped) and (not maniqui or GetGameTimer() - esperaSuelo < 8000) do
        if maniqui then RequestCollisionAtCoord(Config.GreenScreenPos.x, Config.GreenScreenPos.y, Config.GreenScreenPos.z) end
		Wait(200)
	end

    TriggerServerEvent('origen_clothing_screenshot:setRoutingBucket', true)
    
    local allHashes = {}

    for _, it in ipairs(lista or {}) do
        local collection = it.collection == 'none' and '' or (it.collection or '')
        local esProp = it.isProp == true
        local camaras = Config.ScreenshotCameras[esProp and 'props' or 'clothes']
        -- Sin cámara configurada para ese hueco (pelo, etc.) no hay foto que hacer
        if camaras[it.component] and it.drawable < getComponentVariations(ped, esProp, it.component, collection) then
            local globalVariationIdx = getGlobalVariationIndex(ped, esProp, it.component, collection, it.drawable)
            local hash = ('%s--%s--%s--%s'):format(collection == '' and 'none' or collection,
                it.component + (esProp and 1000 or 0), it.drawable, it.texture)
            if not isBlacklisted(hash) then
                table.insert(allHashes, {
                    hash = hash, model = pedHash, collection = collection, isProp = esProp,
                    component = it.component, componentIdx = it.component,
                    globalVariationIdx = globalVariationIdx, drawableId = it.drawable, textureId = it.texture,
                    variation = globalVariationIdx + (esProp and 1000 or 0)
                })
            end
        end
    end
    
    for i = 1, #collections do
        local collection = collections[i] == "none" and "" or collections[i]
        for j = 1, #components do
            local componentIdx = components[j]
            local drawableCount = getComponentVariations(ped, isProp, componentIdx, collection)
            for drawableId = 0, drawableCount - 1 do
                if variation and variation >= 0 and drawableId ~= variation then
                    goto continue_drawable
                end
                local globalVariationIdx = getGlobalVariationIndex(ped, isProp, componentIdx, collection, drawableId)
                local textureCount = getComponentTextures(ped, isProp, componentIdx, collection, drawableId)
                for textureId = 0, textureCount - 1 do
                    if textureFilter and textureFilter >= 0 and textureId ~= textureFilter then
                        goto continue_texture
                    end
                    local hash = ('%s--%s--%s--%s'):format(
                        collection == "" and "none" or collection,
                        componentIdx + (isProp and 1000 or 0),
                        drawableId,
                        textureId
                    )
                    
                    if not isBlacklisted(hash) then
                        table.insert(allHashes, {
                            hash = hash,
                            model = pedHash,
                            collection = collection,
                            component = componentIdx,
                            componentIdx = componentIdx,
                            globalVariationIdx = globalVariationIdx,
                            drawableId = drawableId,
                            textureId = textureId,
                            variation = globalVariationIdx + (isProp and 1000 or 0)
                        })
                    end
                    ::continue_texture::
                end
                ::continue_drawable::
            end
        end
    end
    
    local photosToTake = allHashes
    
    if skipExisting then
        if not lista then TriggerEvent('origen_clothing:updateVerificationProgress', {
            progress = '0 / ' .. #allHashes .. ' items'
        }) end
        
        local CHUNK_SIZE = 500
        local existingSet = {}
        
        for i = 1, #allHashes, CHUNK_SIZE do
            local chunk = {}
            for j = i, math.min(i + CHUNK_SIZE - 1, #allHashes) do
                table.insert(chunk, allHashes[j].hash)
            end
            
            local existingChunk = lib.callback.await('origen_clothing_screenshot:getExistingPhotos', false, chunk)
            
            if existingChunk then
                for k = 1, #existingChunk do
                    existingSet[existingChunk[k]] = true
                end
            end
            
            local checked = math.min(i + CHUNK_SIZE - 1, #allHashes)
            
            if not lista then TriggerEvent('origen_clothing:updateVerificationProgress', {
                progress = checked .. ' / ' .. #allHashes .. ' items'
            }) end
            
            Wait(50)
        end
        
        photosToTake = {}
        for i = 1, #allHashes do
            if not existingSet[allHashes[i].hash] then
                table.insert(photosToTake, allHashes[i])
            end
        end
        
        if not lista then TriggerEvent('origen_clothing:hideVerificationLoading') end
    end
    
    local totalPhotos = #photosToTake

    TriggerEvent('origen_clothing_screenshot:progressStart', {
        total = totalPhotos,
        current = 0
    })
    
    exports["origen_clothing"]:ShowControls({
        { key = "E", text = "Parar las fotos"}
    }, "Fotos de ropa")

    local controlsActive = true
    local colgado, colgadoVisto = {}, 0
    CreateThread(function()
        while controlsActive do
            ForcePedMotionState(ped, `MotionState_None`, false, 1, true)
            ClearPedTasksImmediately(ped)
            DisableAllControlActions(0)
            -- Sin HUD mientras dura
            HideHudAndRadarThisFrame()
            HideHudComponentThisFrame(14)
            -- Cualquier objeto junto a quien posa sale en la foto: el arma enfundada del admin (que se
            -- le vuelve a colgar al cambiar de modelo) y, sobre todo, las copias que ese cambio deja
            -- sueltas flotando en el estudio. El estudio es mapa, no objetos: lo que haya a menos de
            -- 3 m no se pinta mientras dura. La lista se rehace dos veces por segundo; esconderlo hay
            -- que pedirlo cada fotograma.
            if GetGameTimer() - colgadoVisto > 500 then
                colgadoVisto = GetGameTimer()
                colgado = {}
                local centro = GetEntityCoords(ped)
                for _, objeto in ipairs(GetGamePool('CObject')) do
                    if #(GetEntityCoords(objeto) - centro) < 3.0 then
                        colgado[#colgado + 1] = objeto
                    end
                end
            end
            for i = 1, #colgado do
                if DoesEntityExist(colgado[i]) then SetEntityLocallyInvisible(colgado[i]) end
            end
            EnableControlAction(0, 38, true)
            if IsControlJustPressed(0, 38) then
                forceStop = true
                controlsActive = false
                TriggerEvent('origen_clothing_screenshot:progressEnd', { cancelled = true })
            end
            Wait(0)
        end
    end)
    
    local currentPhoto = 0
    local lastComponentIdx = nil

    for idx = 1, #photosToTake do
        local item = photosToTake[idx]
        
        -- (en una lista hay ropa y accesorios mezclados: cada prenda dice lo que es)
        local esProp = isProp
        if item.isProp ~= nil then esProp = item.isProp end
        local hueco = (esProp and 'p' or 'c') .. item.componentIdx
        if lastComponentIdx ~= hueco then
            startScreenshotCamera(ped, Config.ScreenshotCameras[esProp and 'props' or 'clothes'][item.componentIdx])
            lastComponentIdx = hueco
        end
        
        removePedClothes(ped)
        -- removePedClothes deja varios huecos en 0, y en un muñeco eso pinta una pieza de serie a la
        -- altura del pecho (un cuadrado oscuro en mitad de la foto): aquí se vacían del todo
        if lista then
            SetPedComponentVariation(ped, 10, -1, 0, 0)
            SetPedComponentVariation(ped, 9, -1, 0, 0)
            SetPedComponentVariation(ped, 5, -1, 0, 0)
            SetPedComponentVariation(ped, 7, -1, 0, 0)
            SetPedComponentVariation(ped, 1, -1, 0, 0)
        end

        if esProp then
            SetPedPropIndex(ped, item.componentIdx, item.globalVariationIdx, item.textureId, true)
        else
            SetPedComponentVariation(ped, item.componentIdx, item.globalVariationIdx, item.textureId, 0)
        end

        takingScreenshot = true

        currentPhoto = currentPhoto + 1
        TriggerEvent('origen_clothing_screenshot:progressUpdate', {
            total = totalPhotos,
            current = currentPhoto,
            collection = item.collection == "" and "none" or item.collection,
            component = item.componentIdx
        })

        TriggerServerEvent(
            "origen_clothing:server:takeClothingScreenshot",
            pedHash,
            item.collection,
            item.componentIdx,
            item.variation,
            item.textureId,
            item.hash
        )

        repeat
            Wait(0)
        until not takingScreenshot

        if forceStop then
            TriggerServerEvent('origen_clothing_screenshot:setRoutingBucket', false)
            
            FreezeEntityPosition(ped, false)
            ClearPedTasksImmediately(ped)
            controlsActive = false
            RenderScriptCams(false, false, 0, true, true)
            if screenshotCamera then
                DestroyCam(screenshotCamera, true)
            end
            DestroyAllCams(true)
            exports["origen_clothing"]:HideControls()
            
            if maniqui then
                -- Fotos con maniquí: el personaje no se ha movido ni ha cambiado; solo se quita el muñeco
                if DoesEntityExist(maniqui) then DeleteEntity(maniqui) end
                maniqui = nil
                ClearFocus()
                FreezeEntityPosition(PlayerPedId(), false)
            elseif originalModel and originalAppearance then
                if GetEntityModel(PlayerPedId()) ~= originalModel then
                    local modelName = originalAppearance.model
                    if type(modelName) == 'number' then
                        for pedName, pedHash in pairs(PEDS_NAMES) do
                            if pedHash == modelName then
                                modelName = pedName
                                break
                            end
                        end
                    end
                    
                    while not HasModelLoaded(originalModel) do
                        RequestModel(originalModel)
                        Wait(0)
                    end
                    
                    SetPlayerModel(PlayerId(), originalModel)
                    Wait(200)
                    SetModelAsNoLongerNeeded(originalModel)
                end
                
                SetEntityCoords(PlayerPedId(), startCoords.x, startCoords.y, startCoords.z)
                exports['origen_clothing']:SetAppearance(PlayerPedId(), originalAppearance)
            else
                SetEntityCoords(ped, startCoords.x, startCoords.y, startCoords.z)
            end
            
            originalAppearance = nil
            originalModel = nil
            return
        end
    end
    
    controlsActive = false
    TriggerEvent('origen_clothing_screenshot:progressEnd', { cancelled = false })
    
    TriggerServerEvent('origen_clothing_screenshot:setRoutingBucket', false)
    
    FreezeEntityPosition(ped, false)
    ClearPedTasksImmediately(ped)
    RenderScriptCams(false, false, 0, true, true)
    if screenshotCamera then
        DestroyCam(screenshotCamera, true)
    end
    DestroyAllCams(true)
    exports["origen_clothing"]:HideControls()
    
    if maniqui then
        -- Fotos con maniquí: el personaje no se ha movido ni ha cambiado; solo se quita el muñeco
        if DoesEntityExist(maniqui) then DeleteEntity(maniqui) end
        maniqui = nil
        ClearFocus()
        FreezeEntityPosition(PlayerPedId(), false)
    elseif originalModel and originalAppearance then
        if GetEntityModel(PlayerPedId()) ~= originalModel then
            while not HasModelLoaded(originalModel) do
                RequestModel(originalModel)
                Wait(0)
            end
            
            SetPlayerModel(PlayerId(), originalModel)
            Wait(200)
            SetModelAsNoLongerNeeded(originalModel)
        end
        
        SetEntityCoords(PlayerPedId(), startCoords.x, startCoords.y, startCoords.z)
        exports['origen_clothing']:SetAppearance(PlayerPedId(), originalAppearance)
    else
        SetEntityCoords(ped, startCoords.x, startCoords.y, startCoords.z)
    end
    
    originalAppearance = nil
    originalModel = nil
end

RegisterNetEvent("origen_clothing:client:screenshotDone", function()
    takingScreenshot = false
end)

function prepareScreenshot(data)
    startCoords = GetEntityCoords(PlayerPedId())
    originalModel = GetEntityModel(PlayerPedId())
    originalAppearance = exports['origen_clothing']:GetAppearanceData(PlayerPedId())
    
    local pedHash = GetHashKey(data.ped)
    
    data.collection = data.collection == 'none' and '' or data.collection

    if not IsModelValid(pedHash) then
        print('Invalid ped model.')
        if data.skipExisting then
            TriggerEvent('origen_clothing:hideVerificationLoading')
        end
        return
    end

    while not HasModelLoaded(pedHash) do
        RequestModel(pedHash)
        Citizen.Wait(0)
    end

    SetPlayerModel(PlayerId(), pedHash)
    Wait(200)
    SetModelAsNoLongerNeeded(pedHash)
    SetPedDefaultComponentVariation(PlayerPedId())

    local desiredCollections = buildStringArray(data.collection or "all", function()
        local ped = PlayerPedId()
        return getAllCollections(ped)
    end)

    local desiredComponents = buildIndexArray(data.component or "all", data.isProp and PROPS_COMPONENTS or COMPONENTS)

    local skipExisting = data.skipExisting
    if skipExisting == nil then
        skipExisting = false
    end
    
    screenshotClothes(
        desiredCollections,
        data.isProp,
        desiredComponents,
        tonumber(data.variation) or -1,
        skipExisting,
        tonumber(data.texture) or -1
    )
    forceStop = false
end

exports('prepareScreenshot', prepareScreenshot)

--[[ Fotos de una lista exacta de prendas, en una sola sesión (un cambio de modelo, un
     viaje a la pantalla verde y vuelta). Lo usa origen_clothing para los cosméticos:
     al marcar una prenda como cosmético se le hace la foto sola, igual que las demás.
       data = { ped = 'mp_m_freemode_01', items = { { collection, component, drawable, texture, isProp }, … } }
     Las que ya tienen foto se saltan. ]]
function fotografiarLista(data)
    if type(data) ~= 'table' or type(data.items) ~= 'table' or #data.items == 0 then return false end
    if maniqui then return false end
    local pedHash = GetHashKey(data.ped)
    if not IsModelValid(pedHash) then return false end

    --[[ Con `data.maniqui = true` (lo que usa origen_clothing para los cosméticos) posa un
         muñeco local y el admin no se toca. Sin él posa el propio admin, como en las fotos
         de /screenshot: cambia de modelo, va a la pantalla verde y vuelve como estaba. ]]
    if not data.maniqui then
        startCoords = GetEntityCoords(PlayerPedId())
        originalModel = GetEntityModel(PlayerPedId())
        originalAppearance = exports['origen_clothing']:GetAppearanceData(PlayerPedId())

        while not HasModelLoaded(pedHash) do
            RequestModel(pedHash)
            Citizen.Wait(0)
        end
        SetPlayerModel(PlayerId(), pedHash)
        Wait(200)
        SetModelAsNoLongerNeeded(pedHash)
        SetPedDefaultComponentVariation(PlayerPedId())

        screenshotClothes({}, false, {}, -1, true, -1, data.items)
        forceStop = false
        return true
    end

    local g = Config.GreenScreenPos
    local desde = GetGameTimer()
    while not HasModelLoaded(pedHash) and GetGameTimer() - desde < 15000 do
        RequestModel(pedHash)
        Citizen.Wait(0)
    end
    if not HasModelLoaded(pedHash) then return false end

    -- El estudio está lejos del admin: se trae a memoria antes de poner el maniquí
    SetFocusPosAndVel(g.x, g.y, g.z, 0.0, 0.0, 0.0)
    RequestCollisionAtCoord(g.x, g.y, g.z)
    Wait(500)

    -- Un muñeco LOCAL (solo lo ve quien hace las fotos), no el personaje del admin
    local ped = CreatePed(4, pedHash, g.x, g.y, g.z, g.w, false, false)
    SetModelAsNoLongerNeeded(pedHash)
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        ClearFocus()
        return false
    end
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetEntityInvincible(ped, true)
    SetPedDefaultComponentVariation(ped)
    -- Un muñeco de estos modelos sin mezcla de cara sale con la piel oscura y verdosa
    SetPedHeadBlendData(ped, 0, 0, 0, 0, 0, 0, 0.0, 0.0, 0.0, false)
    local mezcla = GetGameTimer()
    while not HasPedHeadBlendFinished(ped) and GetGameTimer() - mezcla < 4000 do Wait(50) end

    maniqui = ped
    startCoords = GetEntityCoords(PlayerPedId())
    originalModel = nil
    originalAppearance = nil
    FreezeEntityPosition(PlayerPedId(), true)

    screenshotClothes({}, false, {}, -1, true, -1, data.items)
    forceStop = false
    return true
end

exports('fotografiarLista', fotografiarLista)

--[[ /screenshot y /stopscreenshot son herramientas de administracion (cambian
     el modelo del jugador y lo llevan al estudio de fotos). Antes las tenia
     cualquiera; ahora lo decide el servidor con el permiso Comando:screenshot
     de origen_admin. ]]
local function PuedeHacerFotos()
    if lib.callback.await('origen_clothing_screenshot:puede', false) then return true end
    lib.notify({ title = 'Fotos de ropa', description = 'No tienes acceso a este comando.', type = 'error' })
    return false
end

-- /screenshot ped collection isProp component variation
RegisterCommand('screenshot', function(source, args, raw)
    if not PuedeHacerFotos() then return end

    local pedHash = GetHashKey(args[1])
    if not IsModelValid(pedHash) then
        print('Invalid ped model.')
        return
    end
    while not HasModelLoaded(pedHash) do
        RequestModel(pedHash)
        Citizen.Wait(0)
    end

    startCoords = GetEntityCoords(PlayerPedId())

    SetPlayerModel(PlayerId(), pedHash)
    Wait(200)
    SetModelAsNoLongerNeeded(pedHash)
    SetPedDefaultComponentVariation(PlayerPedId())


    local collectionArg = tostring(args[2] or "all")
    local isProp = tonumber(args[3] or 0) == 1
    local componentArg  = tostring(args[4] or "all")
    local variation = tonumber(args[5] or -1)

    local desiredCollections = buildStringArray(collectionArg, function()
        local ped = PlayerPedId()
        return getAllCollections(ped)
    end)

    local desiredComponents = buildIndexArray(componentArg, isProp and PROPS_COMPONENTS or COMPONENTS)

    screenshotClothes(desiredCollections, isProp, desiredComponents, variation, false, -1)

    forceStop = false
end)

RegisterCommand("stopscreenshot", function()
    if not PuedeHacerFotos() then return end
    forceStop = true
    TriggerEvent('origen_clothing_screenshot:progressEnd', { cancelled = true })
end)