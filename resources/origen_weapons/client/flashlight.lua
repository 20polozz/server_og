local isFlashlightActive = false
local lastWeapon = nil
local currentHasFlashlight = false

-- Hashes de accesorios de linterna para armas en GTA V
local FLASHLIGHT_COMPONENTS = {
    [`COMPONENT_AT_PI_FLSH`] = true,
    [`COMPONENT_AT_PI_FLSH_02`] = true,
    [`COMPONENT_AT_PI_FLSH_03`] = true,
    [`COMPONENT_AT_AR_FLSH`] = true,
    [`COMPONENT_AT_SG_FLSH`] = true,
}

---Comprueba si el arma equipada tiene un accesorio de linterna acoplado
---@param ped number
---@param weaponHash number
---@return boolean
local function HasFlashlightAttachment(ped, weaponHash)
    if not weaponHash or weaponHash == `WEAPON_UNARMED` then return false end
    if weaponHash == `WEAPON_FLASHLIGHT` then return true end

    for compHash in pairs(FLASHLIGHT_COMPONENTS) do
        if HasPedGotWeaponComponent(ped, weaponHash, compHash) then
            return true
        end
    end

    if IsFlashLightOn(ped) == 1 or IsFlashLightOn(ped) == true then
        return true
    end

    return false
end

-- Hilo principal: mantiene la linterna encendida al bajar el arma
CreateThread(function()
    SetFlashLightKeepOnWhileMoving(true)
    SetFlashLightFadeDistance(100.0)

    while true do
        local sleep = 350
        local ped = PlayerPedId()

        if DoesEntityExist(ped) and not IsEntityDead(ped) and (IsPedArmed(ped, 4) or GetSelectedPedWeapon(ped) == `WEAPON_FLASHLIGHT`) then
            local currentWeapon = GetSelectedPedWeapon(ped)

            -- Detección de cambio o enfundado de arma
            if currentWeapon ~= lastWeapon then
                if lastWeapon and isFlashlightActive then
                    SetFlashLightEnabled(ped, false)
                    isFlashlightActive = false
                    LocalPlayer.state:set('weaponFlashlight', false, true)
                end
                lastWeapon = currentWeapon
                currentHasFlashlight = HasFlashlightAttachment(ped, currentWeapon)
            end

            -- Si no se había detectado (ej: accesorio equipado tras desenfundar), revalidar
            if not currentHasFlashlight then
                currentHasFlashlight = HasFlashlightAttachment(ped, currentWeapon)
            end

            if currentHasFlashlight then
                sleep = 0
                SetFlashLightKeepOnWhileMoving(true)

                local inVehicle = IsPedInAnyVehicle(ped, false)
                local isAiming = IsPlayerFreeAiming(PlayerId()) or IsAimCamActive() or IsControlPressed(0, 25)
                local gtaLightOn = (IsFlashLightOn(ped) == 1 or IsFlashLightOn(ped) == true)

                -- Mientras se apunta: el estado lo decide el jugador con el control nativo de GTA (tecla E / DPad)
                if isAiming then
                    -- Evitar falsos apagados durante animaciones de recarga o golpe cuerpo a cuerpo
                    if not IsPedReloading(ped) and not IsPedPerformingMeleeAction(ped) then
                        if gtaLightOn ~= isFlashlightActive then
                            isFlashlightActive = gtaLightOn
                            LocalPlayer.state:set('weaponFlashlight', isFlashlightActive, true)
                        end
                    end
                else
                    -- Al bajar el arma:
                    if inVehicle then
                        -- En vehículos sin apuntar, apagar para que no atraviese el salpicadero
                        if gtaLightOn then
                            SetFlashLightEnabled(ped, false)
                        end
                    else
                        -- Mantener el estado exacto: si la tenía encendida sigue encendida; si la apagó apuntando sigue apagada
                        if isFlashlightActive then
                            if not IsFlashLightOn(ped) then
                                SetFlashLightEnabled(ped, true)
                            end
                        else
                            if IsFlashLightOn(ped) then
                                SetFlashLightEnabled(ped, false)
                            end
                        end
                    end
                end
            end
        else
            if isFlashlightActive then
                if DoesEntityExist(ped) then
                    SetFlashLightEnabled(ped, false)
                end
                isFlashlightActive = false
                LocalPlayer.state:set('weaponFlashlight', false, true)
            end
            lastWeapon = nil
            currentHasFlashlight = false
        end

        Wait(sleep)
    end
end)

-- Sincronización en red para que otros jugadores vean la linterna encendida al bajar el arma
AddStateBagChangeHandler('weaponFlashlight', nil, function(bagName, key, value)
    local ply = GetPlayerFromStateBagName(bagName)
    if ply == 0 then return end
    local otherPed = GetPlayerPed(ply)
    if not DoesEntityExist(otherPed) or otherPed == PlayerPedId() then return end
    SetFlashLightEnabled(otherPed, value == true)
end)

-- Sincronización periódica para peds que entren en streaming
CreateThread(function()
    while true do
        Wait(1500)
        local myPed = PlayerPedId()
        for _, player in ipairs(GetActivePlayers()) do
            local otherPed = GetPlayerPed(player)
            if otherPed ~= myPed and DoesEntityExist(otherPed) and not IsEntityDead(otherPed) then
                if IsPedArmed(otherPed, 4) or GetSelectedPedWeapon(otherPed) == `WEAPON_FLASHLIGHT` then
                    local sId = GetPlayerServerId(player)
                    local state = Player(sId).state.weaponFlashlight
                    if state ~= nil then
                        SetFlashLightEnabled(otherPed, state == true)
                    end
                end
            end
        end
    end
end)

-- Limpieza al reiniciar o detener el recurso
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    local ped = PlayerPedId()
    if DoesEntityExist(ped) then
        SetFlashLightEnabled(ped, false)
    end
    LocalPlayer.state:set('weaponFlashlight', false, true)
end)
