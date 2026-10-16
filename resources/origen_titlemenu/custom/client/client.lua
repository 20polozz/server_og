Custom = Custom or {}
function ShowNotification(msg)
    if Config.Framework == "qbcore" then
        TriggerEvent('QBCore:Notify', msg)
    elseif Config.Framework == "esx" then
        ESX.ShowNotification(msg)
    end
end

function CreatePlayer()
    if Config.ClothSystem == 'origen_clothing' then
        TriggerServerEvent("qbx_afk:server:SetAFKPaused", true)

        --[[ Se arma ANTES de abrir la ropa porque openCreation bloquea: no
             vuelve hasta que la creacion ha terminado del todo. La bandera es
             lo que distingue este caso de un /skin, que dispara los mismos
             avisos y no debe lanzar ninguna intro. ]]
        if GetResourceState('origen_intro') == 'started' then
            pcall(function() exports.origen_intro:armar() end)
        end

        exports.origen_clothing:openCreation(nil, true)  -- true = first time creation, enable teleport
    elseif Config.Framework == "qbcore" then
        TriggerEvent("qb-clothing:client:openMenu")
    elseif Config.Framework == "esx" then
        -- only version ESX 1.10.4 and 1.10.5 temporal fix
      --  TriggerServerEvent('esx:onPlayerSpawn')
       -- TriggerEvent('esx:onPlayerSpawn')
     TriggerEvent('esx_skin:openSaveableMenu')

        --rcore clothing
        --TriggerEvent('rcore_clothing:openCharCreator')
    
    end
end

function SetSkin(ped, skin)
    if Config.ClothSystem == 'skinchanger' then
		ApplySkinSkinChanger(ped, skin)
	elseif Config.ClothSystem == 'fivem-appearance' then
        if not  HasModelLoaded(skin.model) then RequestModel(skin.model) end
        while not HasModelLoaded(skin.model) do
            Citizen.Wait(0)
        end
		exports['fivem-appearance']:setPedAppearance(ped, skin)
	elseif Config.ClothSystem == 'illenium-appearance' then
        if not  HasModelLoaded(skin.model) then RequestModel(skin.model) end
        while not HasModelLoaded(skin.model) do
            Citizen.Wait(0)
        end
        SetPlayerModel(PlayerId(), skin.model)
        exports['illenium-appearance']:setPedAppearance(ped, skin)
	elseif Config.ClothSystem == 'qb-clothing' then
        if not Config.Framework == "qbcore" then
        end
		TriggerEvent('qb-clothing:client:loadPlayerClothing', skin, ped)
    elseif Config.ClothSystem == 'origen_clothing' then
        exports.origen_clothing:SetAppearance(ped, skin)
    elseif Config.ClothSystem == 'codem-appearance' then
        if Config.Framework == "qbcore" then
            if skin.model and not  HasModelLoaded(skin.model) then 
                RequestModel(skin.model) 
                while not HasModelLoaded(skin.model) do
                    Citizen.Wait(0)
                end
            end
            SetPlayerModel(PlayerId(), skin.model)
            TriggerEvent('qb-clothing:client:loadPlayerClothing', skin, ped)
    elseif Config.Framework == "esx" and not Config.ClothSystem == 'rcore_clothing' then
        exports.rcore_clothing:setPedSkin(ped, skin)
        debug("Setskin executed with rcore_clothing")
        end
	end
end

function ApplySkinSkinChanger(ped, skin)
    local Character = {}
    for k, v in pairs(skin) do
        Character[k] = v
    end

    local face_weight = (Character['face_md_weight'] / 100) + 0.0
    local skin_weight = (Character['skin_md_weight'] / 100) + 0.0
    SetPedHeadBlendData(ped, Character['mom'], Character['dad'], 0, Character['mom'], Character['dad'], 0,
        face_weight, skin_weight, 0.0, false)

    SetPedFaceFeature(ped, 0, (Character['nose_1'] / 10) + 0.0)                                  -- Nose Width
    SetPedFaceFeature(ped, 1, (Character['nose_2'] / 10) + 0.0)                                  -- Nose Peak Height
    SetPedFaceFeature(ped, 2, (Character['nose_3'] / 10) + 0.0)                                  -- Nose Peak Length
    SetPedFaceFeature(ped, 3, (Character['nose_4'] / 10) + 0.0)                                  -- Nose Bone Height
    SetPedFaceFeature(ped, 4, (Character['nose_5'] / 10) + 0.0)                                  -- Nose Peak Lowering
    SetPedFaceFeature(ped, 5, (Character['nose_6'] / 10) + 0.0)                                  -- Nose Bone Twist
    SetPedFaceFeature(ped, 6, (Character['eyebrows_5'] / 10) + 0.0)                              -- Eyebrow height
    SetPedFaceFeature(ped, 7, (Character['eyebrows_6'] / 10) + 0.0)                              -- Eyebrow depth
    SetPedFaceFeature(ped, 8, (Character['cheeks_1'] / 10) + 0.0)                                -- Cheekbones Height
    SetPedFaceFeature(ped, 9, (Character['cheeks_2'] / 10) + 0.0)                                -- Cheekbones Width
    SetPedFaceFeature(ped, 10, (Character['cheeks_3'] / 10) + 0.0)                               -- Cheeks Width
    SetPedFaceFeature(ped, 11, (Character['eye_squint'] / 10) + 0.0)                             -- Eyes squint
    SetPedFaceFeature(ped, 12, (Character['lip_thickness'] / 10) + 0.0)                          -- Lip Fullness
    SetPedFaceFeature(ped, 13, (Character['jaw_1'] / 10) + 0.0)                                  -- Jaw Bone Width
    SetPedFaceFeature(ped, 14, (Character['jaw_2'] / 10) + 0.0)                                  -- Jaw Bone Length
    SetPedFaceFeature(ped, 15, (Character['chin_1'] / 10) + 0.0)                                 -- Chin Height
    SetPedFaceFeature(ped, 16, (Character['chin_2'] / 10) + 0.0)                                 -- Chin Length
    SetPedFaceFeature(ped, 17, (Character['chin_3'] / 10) + 0.0)                                 -- Chin Width
    SetPedFaceFeature(ped, 18, (Character['chin_4'] / 10) + 0.0)                                 -- Chin Hole Size
    SetPedFaceFeature(ped, 19, (Character['neck_thickness'] / 10) + 0.0)                         -- Neck Thickness

    SetPedHairColor(ped, Character['hair_color_1'], Character['hair_color_2'])                   -- Hair Color
    SetPedHeadOverlay(ped, 3, Character['age_1'], (Character['age_2'] / 10) + 0.0)               -- Age + opacity
    SetPedHeadOverlay(ped, 0, Character['blemishes_1'], (Character['blemishes_2'] / 10) + 0.0)   -- Blemishes + opacity
    SetPedHeadOverlay(ped, 1, Character['beard_1'], (Character['beard_2'] / 10) + 0.0)           -- Beard + opacity
    SetPedEyeColor(ped, Character['eye_color'])                                                  -- Eyes color
    SetPedHeadOverlay(ped, 2, Character['eyebrows_1'], (Character['eyebrows_2'] / 10) + 0.0)     -- Eyebrows + opacity
    SetPedHeadOverlay(ped, 4, Character['makeup_1'], (Character['makeup_2'] / 10) + 0.0)         -- Makeup + opacity
    SetPedHeadOverlay(ped, 8, Character['lipstick_1'], (Character['lipstick_2'] / 10) + 0.0)     -- Lipstick + opacity
    SetPedComponentVariation(ped, 2, Character['hair_1'], Character['hair_2'], 2)                -- Hair
    SetPedHeadOverlayColor(ped, 1, 1, Character['beard_3'], Character['beard_4'])                -- Beard Color
    SetPedHeadOverlayColor(ped, 2, 1, Character['eyebrows_3'], Character['eyebrows_4'])          -- Eyebrows Color
    SetPedHeadOverlayColor(ped, 4, 2, Character['makeup_3'], Character['makeup_4'])              -- Makeup Color
    SetPedHeadOverlayColor(ped, 8, 1, Character['lipstick_3'], Character['lipstick_4'])          -- Lipstick Color
    SetPedHeadOverlay(ped, 5, Character['blush_1'], (Character['blush_2'] / 10) + 0.0)           -- Blush + opacity
    SetPedHeadOverlayColor(ped, 5, 2, Character['blush_3'])                                      -- Blush Color
    SetPedHeadOverlay(ped, 6, Character['complexion_1'], (Character['complexion_2'] / 10) + 0.0) -- Complexion + opacity
    SetPedHeadOverlay(ped, 7, Character['sun_1'], (Character['sun_2'] / 10) + 0.0)               -- Sun Damage + opacity
    SetPedHeadOverlay(ped, 9, Character['moles_1'], (Character['moles_2'] / 10) + 0.0)           -- Moles/Freckles + opacity
    SetPedHeadOverlay(ped, 10, Character['chest_1'], (Character['chest_2'] / 10) + 0.0)          -- Chest Hair + opacity
    SetPedHeadOverlayColor(ped, 10, 1, Character['chest_3'])                                     -- Torso Color

    if Character['bodyb_1'] == -1 then
        SetPedHeadOverlay(ped, 11, 255, (Character['bodyb_2'] / 10) + 0.0) -- Body Blemishes + opacity
    else
        SetPedHeadOverlay(ped, 11, Character['bodyb_1'], (Character['bodyb_2'] / 10) + 0.0)
    end

    if Character['bodyb_3'] == -1 then
        SetPedHeadOverlay(ped, 12, 255, (Character['bodyb_4'] / 10) + 0.0)
    else
        SetPedHeadOverlay(ped, 12, Character['bodyb_3'], (Character['bodyb_4'] / 10) + 0.0) -- Blemishes 'added body effect' + opacity
    end

    if Character['ears_1'] == -1 then
        ClearPedProp(ped, 2)
    else
        SetPedPropIndex(ped, 2, Character['ears_1'], Character['ears_2'], 2) -- Ears Accessories
    end

    SetPedComponentVariation(ped, 8, Character['tshirt_1'], Character['tshirt_2'], 2)  -- Tshirt
    SetPedComponentVariation(ped, 11, Character['torso_1'], Character['torso_2'], 2)   -- torso parts
    SetPedComponentVariation(ped, 3, Character['arms'], Character['arms_2'], 2)        -- Arms
    SetPedComponentVariation(ped, 10, Character['decals_1'], Character['decals_2'], 2) -- decals
    SetPedComponentVariation(ped, 4, Character['pants_1'], Character['pants_2'], 2)    -- pants
    SetPedComponentVariation(ped, 6, Character['shoes_1'], Character['shoes_2'], 2)    -- shoes
    SetPedComponentVariation(ped, 1, Character['mask_1'], Character['mask_2'], 2)      -- mask
    SetPedComponentVariation(ped, 9, Character['bproof_1'], Character['bproof_2'], 2)  -- bulletproof
    SetPedComponentVariation(ped, 7, Character['chain_1'], Character['chain_2'], 2)    -- chain
    SetPedComponentVariation(ped, 5, Character['bags_1'], Character['bags_2'], 2)      -- Bag

    if Character['helmet_1'] == -1 then
        ClearPedProp(ped, 0)
    else
        SetPedPropIndex(ped, 0, Character['helmet_1'], Character['helmet_2'], 2) -- Helmet
    end

    if Character['glasses_1'] == -1 then
        ClearPedProp(ped, 1)
    else
        SetPedPropIndex(ped, 1, Character['glasses_1'], Character['glasses_2'], 2) -- Glasses
    end

    if Character['watches_1'] == -1 then
        ClearPedProp(ped, 6)
    else
        SetPedPropIndex(ped, 6, Character['watches_1'], Character['watches_2'], 2) -- Watches
    end

    if Character['bracelets_1'] == -1 then
        ClearPedProp(ped, 7)
    else
        SetPedPropIndex(ped, 7, Character['bracelets_1'], Character['bracelets_2'], 2) -- Bracelets
    end
end

function ShutDownLoadingScreenCustom()
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
end

--[[ Corre justo despues de que openCreation devuelva, o sea cuando la creacion
     ha terminado de verdad y origen_clothing ya resolvio su promesa. Es el
     momento de lanzar la intro; hacerlo antes seria pelearse con ella.

     Solo hace algo si hay una intro armada. ]]
function PostSpawnPlayer()
    if GetResourceState('origen_intro') == 'started' then
        pcall(function() exports.origen_intro:lanzar() end)
    end
end
