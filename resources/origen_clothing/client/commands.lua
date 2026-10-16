local ultimoFix = 0

RegisterCommand(Config.reloadSkinCommand, function()
    -- Recargar cambia el modelo, y un modelo nuevo nace vivo: muerto o caido te levantaria
    local ped = PlayerPedId()
    local st = LocalPlayer.state
    if IsEntityDead(ped) or IsPedFatallyInjured(ped) or st.dead or st.isDead or st.inLastStand then
        Custom.Notify('No puedes recargar el personaje estando herido de muerte', 'error', 4000)
        return
    end
    if RecargaEnCurso() or GetGameTimer() - ultimoFix < 5000 then
        Custom.Notify('Espera un momento antes de volver a usar /' .. Config.reloadSkinCommand, 'error', 3000)
        return
    end
    ultimoFix = GetGameTimer()
    ReloadAppearanceData()
end)

RegisterCommand(Config.openPedsMenuCommand, function()
    TriggerEvent("origen_clothing:openClothingMenu", "ped")
end)

-- Sistema para quitarse y ponerse la chaqueta (Top y Brazos)
local savedJacket = nil

RegisterCommand('chaqueta', function()
    local ped = PlayerPedId()
    local gender = GetEntityModel(ped)
    local mpMale = GetHashKey('mp_m_freemode_01')
    local mpFemale = GetHashKey('mp_f_freemode_01')

    if gender ~= mpMale and gender ~= mpFemale then return end

    if savedJacket == nil then
        savedJacket = {
            top = { drawable = GetPedDrawableVariation(ped, 11), texture = GetPedTextureVariation(ped, 11) },
            torso = { drawable = GetPedDrawableVariation(ped, 3), texture = GetPedTextureVariation(ped, 3) }
        }

        if gender == mpMale then
            SetPedComponentVariation(ped, 11, 15, 0, 2)
            SetPedComponentVariation(ped, 3, 15, 0, 2)
        else
            SetPedComponentVariation(ped, 11, 15, 0, 2)
            SetPedComponentVariation(ped, 3, 15, 0, 2)
        end
    else
        SetPedComponentVariation(ped, 11, savedJacket.top.drawable, savedJacket.top.texture, 2)
        SetPedComponentVariation(ped, 3, savedJacket.torso.drawable, savedJacket.torso.texture, 2)
        savedJacket = nil
    end
end)

-- Sistema para quitarse y ponerse la camiseta interior
local savedShirt = nil

RegisterCommand('camiseta', function()
    local ped = PlayerPedId()
    local gender = GetEntityModel(ped)
    local mpMale = GetHashKey('mp_m_freemode_01')
    local mpFemale = GetHashKey('mp_f_freemode_01')

    if gender ~= mpMale and gender ~= mpFemale then return end

    if savedShirt == nil then
        savedShirt = {
            undershirt = { drawable = GetPedDrawableVariation(ped, 8), texture = GetPedTextureVariation(ped, 8) }
        }

        if gender == mpMale then
            SetPedComponentVariation(ped, 8, 15, 0, 2)
        else
            SetPedComponentVariation(ped, 8, 14, 0, 2)
        end
    else
        SetPedComponentVariation(ped, 8, savedShirt.undershirt.drawable, savedShirt.undershirt.texture, 2)
        savedShirt = nil
    end
end)