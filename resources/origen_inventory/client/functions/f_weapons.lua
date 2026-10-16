local Thread = CreateThread

local WeaponsConfig = Config.Weapons
local Weapons = {}

Weapons.current = {}
Weapons.current.data = nil
Weapons.current.weapon = nil
Weapons.current.serial = nil
Weapons.current.slot = nil
Weapons.current.lastReloadTime = 0
Weapons.current.checkingThrowable = false
Weapons.infiniteAmmoEnabled = false

Weapons.multiplierAmount = 0
Weapons.isReloading = false
Weapons.isMelee = false

local function CheckThrowable(weaponName)
    local localWeaponHash = GetHashKey(weaponName)
    Thread(function()
        while Weapons.current.checkingThrowable do
            local ped = PlayerPedId()
            local weapon = GetSelectedPedWeapon(ped)

            if weapon ~= localWeaponHash then
                break
            end

            if IsControlJustReleased(0, 24) or IsDisabledControlJustReleased(0, 24) then
                Wait(400) -- Increased wait to prevent premature removal of throwables during animation
                TriggerServerEvent('inventory:Server:RemoveItem', weaponName, 1)
                InventoryUI.Notify('remove', weaponName)
                Wait(100)
            end

            if GetAmmoInClip(ped, weapon) == 0 or GetSelectedPedWeapon(ped) ~= weapon then
                break
            end

            Wait(5)
        end

        Wait(1000)
        Weapons.unarmedPed()
        Weapons.current.checkingThrowable = false
    end)
end

Weapons.ammoThread = function()
    Thread(function()
        local shotsFired = 0
        local lastShotTime = 0

        if Weapons.current.data == nil then return end

        while Weapons.current.data do
            local wait = 1000
            local ped = PlayerPedId()
            local isArmed = IsPedArmed(ped, 7)

            if isArmed and not Weapons.current.isMelee then
                wait = 10

                if not Config.Player.CheatProtect.EnableNoItemWeapons then
                    if not Weapons.current.weapon then
                        Weapons.unarmedPed()
                    end
                end

                if not Weapons.current.weapon then
                    wait = 1000
                    goto continue
                end

                if Config.Weapons.InventoryWeaponSystem then
                    if Config.Weapons.Throwables[Weapons.current.weapon] then
                        wait = 1000
                        goto continue
                    end

                    if IsControlJustReleased(0, 24) or IsDisabledControlJustReleased(0, 24) then
                        wait = 0
                        local weapon = GetSelectedPedWeapon(ped)
                        local ammo = GetAmmoInPedWeapon(ped, weapon)

                        if Weapons.current.data and Weapons.current.data.metadata and Weapons.current.data.ammo then
                            Weapons.current.data.metadata.ammo = tonumber(ammo)
                        end

                        if WeaponsConfig.AutoReload?.enabled and tonumber(ammo) == 0 then
                            Thread(Weapons.reloadAmmoFromCommand)
                        end

                        shotsFired = shotsFired + 1
                        Weapons.multiplierAmount = Weapons.multiplierAmount + 1
                        lastShotTime = GetGameTimer()

                        if Weapons.multiplierAmount > 0 and Weapons.current.data then
                            TriggerServerEvent("weapons:server:UpdateWeaponQuality", Weapons.current.data,
                                Weapons.multiplierAmount)
                            Weapons.multiplierAmount = 0
                        end
                    end
                end

                ::continue::
            end

            if isArmed and shotsFired > 0 and (GetGameTimer() - lastShotTime >= 1000) then
                if not Weapons.infiniteAmmoEnabled then
                    local ammo = GetAmmoInPedWeapon(PlayerPedId(), GetSelectedPedWeapon(PlayerPedId()))
                    TriggerServerEvent("weapons:server:UpdateWeaponAmmo", Weapons.current.data, tonumber(ammo), shotsFired,
                        nil)
                end
                shotsFired = 0
            end

            Wait(wait)
        end
    end)
end

Weapons.setCurrent = function(weaponData)
    Weapons.current.data = weaponData

    if Weapons.current.data then
        Weapons.ammoThread()
    end
end
exports('SetCurrentWeapon', Weapons.setCurrent)

Weapons.onUseWeapon = function(weaponData)
    if not weaponData then return false end
    if not weaponData.name then return false end
    local weaponName = weaponData.name:lower()
    local weaponSerial = weaponData.metadata and weaponData.metadata.serie or false
    local weaponSlot = weaponData.slot

    local playerPed = PlayerPedId()

    if Config.Weapons.Draw.enabled then
        ResetHolster()
    end

    if Weapons.current.weapon then
        local function RemoveWeaponFromPlayer()
            if not Weapons.current.weapon then return end

            TriggerEvent('weapons:client:DrawWeapon')
            if Weapons.current.weapon:lower() == 'weapon_petrolcan' or Weapons.current.weapon:lower() == "weapon_fireextinguisher" then
                local ammoInPedWeapon = GetAmmoInPedWeapon(playerPed, GetSelectedPedWeapon(playerPed))
                TriggerServerEvent("weapons:server:UpdateWeaponAmmo", weaponData, tonumber(ammoInPedWeapon) or 0)
            end

            Weapons.setCurrent(nil)
            Weapons.unarmedPed()
            Weapons.current.weapon = nil
            Weapons.current.slot = nil
            Weapons.isMelee = false
        end
        if (Weapons.current.weapon:lower() == weaponName) and (Weapons.current.serial == weaponSerial) and (Weapons.current.slot == weaponSlot) then
            return RemoveWeaponFromPlayer()
        end

        if Weapons.current.slot ~= weaponSlot then
            return RemoveWeaponFromPlayer()
        end
    end

    local ped = PlayerPedId()

    local weaponModel = GetHashKey(weaponName)
    if not IsWeaponValid(weaponModel) then
        debugger(('^1[Error] Failed to load weapon model: %s (%s)^0'):format(weaponName, weaponModel))
        return
    end

    TryCatch
        :try(function()
            if Config.Weapons.Throwables[weaponName] then
                GiveWeaponToPed(ped, GetHashKey(weaponName), weaponData.count, false, true)
                SetPedAmmo(ped, GetHashKey(weaponName), weaponData.count)
                SetCurrentPedWeapon(ped, GetHashKey(weaponName), true)

                Weapons.setCurrent(weaponData)
                Weapons.current.checkingThrowable = true
                CheckThrowable(weaponName)
                Weapons.current.weapon = weaponName
                Weapons.current.serial = weaponSerial
                Weapons.current.slot = weaponData.slot
                return
            elseif Config.Weapons.Melee[weaponName] then
                local weaponHash = GetHashKey(weaponName)
                Weapons.current.weapon = weaponName
                Weapons.current.serial = weaponSerial
                Weapons.current.slot = weaponData.slot
                Weapons.isMelee = true
                Weapons.setCurrent(weaponData)


                RemoveWeaponFromPed(ped, weaponHash)
                GiveWeaponToPed(ped, weaponHash, 1, false, true)
                SetPedAmmo(ped, weaponHash, 1)
                SetCurrentPedWeapon(ped, weaponHash, true)

                TriggerServerEvent('inventory:server:weapons:CurrentWeapon', weaponData)
                return
            elseif weaponName == 'weapon_snowball' then
                TriggerEvent('weapons:client:DrawWeapon')
                GiveWeaponToPed(ped, GetHashKey(weaponName), 1, false, false)
                SetPedAmmo(ped, GetHashKey(weaponName), 10)
                SetCurrentPedWeapon(ped, GetHashKey(weaponName), true)
                Weapons.current.weapon = weaponName
                Weapons.current.serial = weaponSerial
                Weapons.current.slot = weaponData.slot
                Weapons.setCurrent(weaponData)
                return
            else
                if Config.Weapons.InventoryWeaponSystem then
                    TriggerServerEvent('inventory:server:weapons:CurrentWeapon', weaponData)
                    Bridge.TriggerCallback('weapon:server:GetWeaponAmmo', function(result)
                        Weapons.current.weapon = weaponName
                        Weapons.current.serial = weaponSerial
                        Weapons.current.slot = weaponData.slot
                        Weapons.setCurrent(weaponData)

                        TriggerEvent('weapons:client:DrawWeapon')

                        local ammo = tonumber(result)
                        if not ammo then
                            error('GetWeaponAmmo not return')
                            return
                        end
                        RemoveWeaponFromPed(ped, GetHashKey(weaponName))
                        GiveWeaponToPed(ped, GetHashKey(weaponName), ammo, false, true)
                        SetPedAmmo(ped, GetHashKey(weaponName), ammo)
                        SetCurrentPedWeapon(ped, GetHashKey(weaponName), true)

                        WeaponAttachment.updateCurrentWeaponAttachments()
                    end, weaponData)
                else
                    TriggerEvent('weapons:client:DrawWeapon')
                    local ammo = tonumber(weaponData.metadata?.ammo) or 0
                    if weaponName == 'weapon_petrolcan' or weaponName == 'weapon_fireextinguisher' then
                        ammo = 4000
                    end

                    Weapons.current.weapon = weaponName
                    Weapons.current.serial = weaponSerial
                    Weapons.current.slot = weaponData.slot

                    Weapons.setCurrent(weaponData)

                    GiveWeaponToPed(ped, GetHashKey(weaponName), ammo, false, false)
                    SetPedAmmo(ped, GetHashKey(weaponName), ammo)
                    SetCurrentPedWeapon(ped, GetHashKey(weaponName), true)

                    WeaponAttachment.updateCurrentWeaponAttachments()
                end
            end
        end)
        :catch(function(err)
            debugger('^1', err, '^0')
        end)
        :finally(function()

        end)
end
RegisterNetEvent('inventory:client:UseWeapon', Weapons.onUseWeapon)

Weapons.reloadAmmo = function(amount, ammoItem)
    if Weapons.isReloading then return false end
    if Weapons.isMelee then return true end
    if not Weapons.current.weapon then return false end

    local playerPed = PlayerPedId()
    local currentWeapon = GetSelectedPedWeapon(playerPed)
    if not currentWeapon or currentWeapon == `WEAPON_UNARMED` then return false end

    local maxAllowedAmmo = Config.MaximumAmmoValues[Weapons.current.weapon] or 9999
    local currentAmmo = GetAmmoInPedWeapon(playerPed, currentWeapon)
    if currentAmmo >= maxAllowedAmmo then
        Bridge.Notify(locale:t('notify.weapons.maxammo'), 'error')
        return false
    end

    local reloadAmmoTime = Config.Weapons.AmmoReloadTime[ammoItem.name] or 4000

    if Weapons.current.reloadAmmoTime and (GetGameTimer() - Weapons.current.lastReloadTime) < reloadAmmoTime then
        Bridge.Notify(locale:t('notify.weapons.reloading'), 'error')
        return false
    end

    local _, weaponMaxAmmo = GetMaxAmmo(playerPed, currentWeapon)
    if not weaponMaxAmmo or weaponMaxAmmo <= 0 then 
        weaponMaxAmmo = 250 
    end

    if currentAmmo >= maxAllowedAmmo or currentAmmo >= weaponMaxAmmo then
        Bridge.Notify(locale:t('notify.weapons.maxammo'), 'error')
        return false
    end

    local controlConfig = CreateControlConfig(false, false, false, true)

    local function makeReload()
        local newAmmo = math.min(currentAmmo + amount, weaponMaxAmmo)

        ClearPedTasks(playerPed)

        SetAmmoInClip(playerPed, currentWeapon, 0)
        SetPedAmmo(playerPed, currentWeapon, 0)

        if not WeaponsConfig.Draw.weapon_reload_animation.enable then
            TaskReloadWeapon(playerPed, false)
        end

        AddAmmoToPed(playerPed, currentWeapon, newAmmo)

        TriggerServerEvent("inventory:weapons:server:AddWeaponAmmo", Weapons.current.data, newAmmo)
        TriggerServerEvent('inventory:Server:RemoveItem', ammoItem.name, 1, ammoItem.slot)
        InventoryUI.Notify('remove', ammoItem.name)
    end

    Weapons.isReloading = true

    if WeaponsConfig.Draw.weapon_reload_animation.progress then
        Bridge.ProgressBar(
            "reloading_weapon",
            locale:t('notify.load_bullet', ammoItem.label),
            reloadAmmoTime,
            controlConfig,
            nil,
            nil,
            function(result)
                if not result then
                    return Bridge.Notify(locale:t('notify.Cancel'))
                end

                makeReload()
            end
        )
    else
        makeReload()
    end


    Weapons.current.lastReloadTime = GetGameTimer()

    Wait(reloadAmmoTime)

    SetTimeout(1000, function()
        Weapons.isReloading = false
    end)
end
exports('AddAmmo', Weapons.reloadAmmo)
if Config.Weapons.InventoryWeaponSystem then
    RegisterNetEvent('origen_inventory:weapon:client:AddAmmo', function(type, amount, item)
        Weapons.reloadAmmo(amount, item)
    end)
else
    RegisterNetEvent('origen_inventory:weapon:client:AddAmmo', function(type, amount, item)
        -- Relay event
        TriggerEvent(Config.Weapons.Draw.relayEvents.client['AddAmmo'], type, amount, item)
    end)
end

Weapons.unarmedPed = function()
    local ped = PlayerPedId()
    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
    RemoveAllPedWeapons(ped, true)

    Weapons.current.weapon = nil
    Weapons.current.serial = nil
    Weapons.current.slot = nil
end
exports('unarmedPed', Weapons.unarmedPed)
RegisterNetEvent('origen_inventory:Unarmed', Weapons.unarmedPed)

local getOldAmmoType = function(ammoType)
    for itemName, data in pairs(Config.Weapons.AmmoTypes) do
        if data.type == ammoType then
            return itemName
        end
    end
    return nil
end

Weapons.reloadAmmoFromCommand = function()
    if Weapons.isReloading then return false end
    if Weapons.isMelee then return false end
    if not Weapons.current.weapon then return false end
    if not Weapons.current.weapon then return false end

    local weapon = Weapons.current.weapon
    local ammoType = Items()[weapon].ammotype
    local weaponAmmo = getOldAmmoType(ammoType) or ammoType
    local ammoItem = Items()[weaponAmmo]

    if not weaponAmmo or not ammoItem then
        Bridge.Notify(locale:t('notify.weapons.noammo'), 'error')
        return false
    end

    local hasAmmo = Inventory.search('count', ammoItem.name)
    if not hasAmmo or hasAmmo <= 0 then
        Bridge.Notify(locale:t('notify.weapons.noammo'), 'error')
        return false
    end

    local ammoAsType = WeaponsConfig.AmmoTypes[ammoItem.name]
    local newAmmo = 12

    if ammoAsType then
        newAmmo = ammoAsType.amount
    end

    if WeaponsConfig.FastReload.NeedAmmoInHotbar then
        local hotbar = Inventory.getHotbar()
        local hasAmmo = false
        for _, item in pairs(hotbar) do
            if item.name == weaponAmmo.name then
                hasAmmo = true
                break
            end
        end

        if not hasAmmo then
            Bridge.Notify(locale:t('notify.weapons.noammo'), 'error')
            return false
        end
    end

    Weapons.reloadAmmo(newAmmo, ammoItem)
end

if WeaponsConfig.InventoryWeaponSystem and WeaponsConfig.FastReload.enabled then
    RegisterCommand('reloadAmmo', Weapons.reloadAmmoFromCommand, false)
    RegisterKeyMapping('reloadAmmo', 'Armas: recarga rápida', 'keyboard', Config.Weapons.FastReload.key)
end

RegisterNetEvent('origen_inventory:weapon:droped', function(name, serie)
    if not Weapons.current.weapon then return end
    if Weapons.current.weapon:lower() ~= name:lower() then return end
    if serie and Weapons.current.serial and serie ~= Weapons.current.serial then return end
    Weapons.unarmedPed()
end)

Thread(function()
    SetWeaponsNoAutoswap(true)
end)

---Get Current Weapon info
---@return string|nil
---@return number|nil
---@return table|nil
Internal__GetCurrentWeapon = function()
    return Weapons.current.weapon, Weapons.current.serie, Weapons.current.data
end


RegisterNetEvent('origen_inventory:weapons:client:EquipAmor', function(value)
    local ped = PlayerPedId()
    RequestAnimDict('clothingtie')
    while not HasAnimDictLoaded('clothingtie') do
        Wait(0)
    end
    TaskPlayAnim(ped, 'clothingtie', 'try_tie_negative_a', 8.0, 2.0, 1200, 48, 10, false, false, false)
    Wait(200)
    SetPedArmour(ped, value)
end)

RegisterNetEvent('origen_inventory:client:SetMaxAmmoCommand', function()
    local weaponName, weaponSerie, weaponData = Internal__GetCurrentWeapon()
    if not weaponName or not weaponData then
        return Bridge.Notify('No tienes un arma equipada que use munición.', 'error')
    end

    local playerPed = PlayerPedId()
    local currentWeapon = GetSelectedPedWeapon(playerPed)
    
    if currentWeapon == `WEAPON_UNARMED` then
        return Bridge.Notify('Equipa un arma primero.', 'error')
    end

    local _, weaponMaxAmmo = GetMaxAmmo(playerPed, currentWeapon)
    local maxAllowedAmmo = Config.MaximumAmmoValues and Config.MaximumAmmoValues[weaponName] or weaponMaxAmmo

    if not maxAllowedAmmo or maxAllowedAmmo > 2500 then
        maxAllowedAmmo = 2500 -- Safe cap
    end

    SetAmmoInClip(playerPed, currentWeapon, 0)
    SetPedAmmo(playerPed, currentWeapon, 0)
    AddAmmoToPed(playerPed, currentWeapon, maxAllowedAmmo)

    TriggerServerEvent("inventory:weapons:server:AddWeaponAmmo", weaponData, maxAllowedAmmo)
    Bridge.Notify('Has reabastecido tu arma al máximo de munición permitida.', 'success')
end)

RegisterNetEvent('origen_inventory:client:SetInfAmmoCommand', function()
    Weapons.infiniteAmmoEnabled = not Weapons.infiniteAmmoEnabled
    local playerPed = PlayerPedId()

    SetPedInfiniteAmmoClip(playerPed, Weapons.infiniteAmmoEnabled)

    if Weapons.infiniteAmmoEnabled then
        Bridge.Notify('Munición infinita SIN RECARGA Activada.', 'success')
    else
        Bridge.Notify('Munición infinita DESACTIVADA.', 'error')
    end
end)
