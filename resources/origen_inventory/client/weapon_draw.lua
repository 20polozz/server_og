---@diagnostic disable: cast-local-type
local weaponsList = Config.Weapons.list or {}

if #weaponsList == 0 then
    debugger("[Error] Update config/weaponoptions.lua with the last update.")
end

local holstered = true
local canFire = true

local currWeap = `WEAPON_UNARMED`
local currHolster = -1
local currHolsterTexture = -1
local wearingHolster = nil

local hasWeapon = false

CanShoot = true

local function checkWeapon(newWeap)
    for i = 1, #weaponsList do
        if joaat(weaponsList[i]) == newWeap then
            return true
        end
    end
    return false
end

local function isWeaponHolsterable(weap)
    for i = 1, #Config.Weapons.Draw.weapons do
        if joaat(Config.Weapons.Draw.weapons[i]) == weap then
            return true
        end
    end
    return false
end

local function isWeaponDrawable(weapon)
    for i = 1, #Config.Weapons.Draw.weapons do
        if weapon == GetHashKey(Config.Weapons.Draw.weapons[i]) then
            return true
        end
    end
    return false
end

function ResetHolster()
    local ped = PlayerPedId()
    local currWeapon = GetSelectedPedWeapon(ped)
    if isWeaponDrawable(currWeapon) and currWeapon ~= `WEAPON_UNARMED` then
        local pos = GetEntityCoords(ped, true)
        local rot = GetEntityHeading(ped)

        local isPoliceHolster = GetResourceState('origen_police') == 'started' and exports['origen_police']:IsHolsterAllowed()

        canFire = false
        CeaseFire()
        if isPoliceHolster then
            SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
            Wait(700)
        else
            TaskPlayAnimAdvanced(ped, 'reaction@intimidation@1h', 'outro', pos.x, pos.y, pos.z, 0, 0, rot, 8.0, 3.0, -1, 50, 0, 0, 0)
            Wait(1400)
            SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
            ClearPedTasks(ped)
            SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
        end
    end

    hasWeapon = false
    holstered = true
    canFire = true
    currWeap = `WEAPON_UNARMED`
    currHolster = -1
    currHolsterTexture = -1
    wearingHolster = nil
end

function DrawWeapon()
    if not Config.Weapons.Draw.enabled then return end

    -- Wait(30)

    local sleep
    local weaponCheck = 0
    hasWeapon = true

    while hasWeapon do
        local ped = PlayerPedId()
        sleep = 250
        if DoesEntityExist(ped)
            and not IsEntityDead(ped)
            and not IsPedInParachuteFreeFall(ped)
            and not IsPedFalling(ped)
            and (GetPedParachuteState(ped) == -1
            or GetPedParachuteState(ped) == 0) then

            sleep = 0

            if currWeap ~= GetSelectedPedWeapon(ped) then
                local isPoliceHolster = GetResourceState('origen_police') == 'started' and exports['origen_police']:IsHolsterAllowed()
                if isPoliceHolster then
                    local newWeap = GetSelectedPedWeapon(ped)
                    SetCurrentPedWeapon(ped, newWeap, true)
                    currWeap = newWeap
                    holstered = (currWeap == `WEAPON_UNARMED`)
                    Wait(50)
                else
                    local pos = GetEntityCoords(ped, true)
                    local rot = GetEntityHeading(ped)

                    local newWeap = GetSelectedPedWeapon(ped)
                    SetCurrentPedWeapon(ped, currWeap, true)
                    if not isWeaponDrawable(newWeap) then 
                    canFire = false
                    CeaseFire()
                    SetCurrentPedWeapon(ped, newWeap, true)
                    currWeap = newWeap
                    ClearPedTasks(ped)
                    holstered = false
                    canFire = true
                    return
                end
                loadAnimDict('reaction@intimidation@1h')
                loadAnimDict('reaction@intimidation@cop@unarmed')
                loadAnimDict('rcmjosh4')
                loadAnimDict('weapons@pistol@')

                local holsterVariant = GetPedDrawableVariation(ped, 8)
                wearingHolster = false
                for i = 1, #Config.Weapons.Draw.variants, 1 do
                    if holsterVariant == Config.Weapons.Draw.variants[i] then
                        wearingHolster = true
                    end
                end

                if checkWeapon(newWeap) then
                    if holstered then
                        if wearingHolster then
                            --TaskPlayAnim(ped, 'rcmjosh4', 'josh_leadout_cop2', 8.0, 2.0, -1, 48, 10, 0, 0, 0 )
                            canFire = false
                            CeaseFire()
                            currHolster = GetPedDrawableVariation(ped, 7)
                            currHolsterTexture = GetPedTextureVariation(ped, 7)
                            TaskPlayAnimAdvanced(ped, 'rcmjosh4', 'josh_leadout_cop2', pos.x, pos.y, pos.z, 0, 0, rot, 3.0, 3.0, -1, 50, 0, 0, 0)
                            Wait(300)
                            SetCurrentPedWeapon(ped, newWeap, true)

                            if isWeaponHolsterable(newWeap) then
                                local componentId = currHolster == 8 and 2 or currHolster == 1 and 3 or currHolster == 6 and 5
                                if componentId and componentId >= 0 then
                                    SetPedComponentVariation(ped, 7, componentId, currHolsterTexture, 2)
                                end
                            end
                            currWeap = newWeap
                            Wait(300)
                            ClearPedTasks(ped)
                            holstered = false
                            canFire = true
                        else
                            canFire = false
                            CeaseFire()
                            TaskPlayAnimAdvanced(ped, 'reaction@intimidation@1h', 'intro', pos.x, pos.y, pos.z, 0, 0, rot, 8.0, 3.0, -1, 50, 0, 0, 0)
                            Wait(1000)
                            SetCurrentPedWeapon(ped, newWeap, true)
                            currWeap = newWeap
                            Wait(1400)
                            ClearPedTasks(ped)
                            holstered = false
                            canFire = true
                        end
                    elseif newWeap ~= currWeap and checkWeapon(currWeap) then
                        if wearingHolster then
                            canFire = false
                            CeaseFire()

                            TaskPlayAnimAdvanced(ped, 'reaction@intimidation@cop@unarmed', 'intro', pos.x, pos.y, pos.z, 0, 0, rot, 3.0, 3.0, -1, 50, 0, 0, 0)
                            Wait(500)

                            if isWeaponHolsterable(currWeap) then
                                SetPedComponentVariation(ped, 7, currHolster, currHolsterTexture, 2)
                            end

                            SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
                            currHolster = GetPedDrawableVariation(ped, 7)
                            currHolsterTexture = GetPedTextureVariation(ped, 7)

                            TaskPlayAnimAdvanced(ped, 'rcmjosh4', 'josh_leadout_cop2', pos.x, pos.y, pos.z, 0, 0, rot, 3.0, 3.0, -1, 50, 0, 0, 0)
                            Wait(300)
                            SetCurrentPedWeapon(ped, newWeap, true)

                            if isWeaponHolsterable(newWeap) then
                                local componentId = currHolster == 8 and 2 or currHolster == 1 and 3 or currHolster == 6 and 5
                                if componentId and componentId >= 0 then
                                    SetPedComponentVariation(ped, 7, componentId, currHolsterTexture, 2)
                                end
                            end

                            Wait(500)
                            currWeap = newWeap
                            ClearPedTasks(ped)
                            holstered = false
                            canFire = true
                        else
                            canFire = false
                            CeaseFire()
                            TaskPlayAnimAdvanced(ped, 'reaction@intimidation@1h', 'outro', pos.x, pos.y, pos.z, 0, 0, rot, 8.0, 3.0, -1, 50, 0, 0, 0)
                            Wait(1600)
                            SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
                            TaskPlayAnimAdvanced(ped, 'reaction@intimidation@1h', 'intro', pos.x, pos.y, pos.z, 0, 0, rot, 8.0, 3.0, -1, 50, 0, 0, 0)
                            Wait(1000)
                            SetCurrentPedWeapon(ped, newWeap, true)
                            currWeap = newWeap
                            Wait(1400)
                            ClearPedTasks(ped)
                            holstered = false
                            canFire = true
                        end
                    else
                        if wearingHolster then
                            SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
                            currHolster = GetPedDrawableVariation(ped, 7)
                            currHolsterTexture = GetPedTextureVariation(ped, 7)
                            TaskPlayAnimAdvanced(ped, 'rcmjosh4', 'josh_leadout_cop2', pos.x, pos.y, pos.z, 0, 0, rot, 3.0, 3.0, -1, 50, 0, 0, 0)
                            Wait(300)
                            SetCurrentPedWeapon(ped, newWeap, true)

                            if isWeaponHolsterable(newWeap) then
                                local componentId = currHolster == 8 and 2 or currHolster == 1 and 3 or currHolster == 6 and 5
                                if componentId and componentId >= 0 then
                                    SetPedComponentVariation(ped, 7, componentId, currHolsterTexture, 2)
                                end
                            end

                            currWeap = newWeap
                            Wait(300)
                            ClearPedTasks(ped)
                            holstered = false
                            canFire = true
                        else
                            SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
                            TaskPlayAnimAdvanced(ped, 'reaction@intimidation@1h', 'intro', pos.x, pos.y, pos.z, 0, 0, rot, 8.0, 3.0, -1, 50, 0, 0, 0)
                            Wait(1000)
                            SetCurrentPedWeapon(ped, newWeap, true)
                            currWeap = newWeap
                            Wait(1400)
                            ClearPedTasks(ped)
                            holstered = false
                            canFire = true
                        end
                    end
                else
                    if not holstered and checkWeapon(currWeap) then
                        if wearingHolster then
                            canFire = false
                            CeaseFire()
                            TaskPlayAnimAdvanced(ped, 'reaction@intimidation@cop@unarmed', 'intro', pos.x, pos.y, pos.z, 0, 0, rot, 3.0, 3.0, -1, 50, 0, 0, 0)
                            Wait(500)

                            if isWeaponHolsterable(currWeap) then
                                SetPedComponentVariation(ped, 7, currHolster, currHolsterTexture, 2)
                            end

                            SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
                            ClearPedTasks(ped)
                            SetCurrentPedWeapon(ped, newWeap, true)
                            holstered = true
                            canFire = true
                            currWeap = newWeap
                        else
                            canFire = false
                            CeaseFire()
                            TaskPlayAnimAdvanced(ped, 'reaction@intimidation@1h', 'outro', pos.x, pos.y, pos.z, 0, 0, rot, 8.0, 3.0, -1, 50, 0, 0, 0)
                            Wait(1400)
                            SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
                            ClearPedTasks(ped)
                            SetCurrentPedWeapon(ped, newWeap, true)
                            holstered = true
                            canFire = true
                            currWeap = newWeap
                        end
                    end
                end
                end
            else
                if GetSelectedPedWeapon(ped) ~= `WEAPON_UNARMED` and holstered and not wearingHolster then
                    local pos = GetEntityCoords(ped, true)
                    local rot = GetEntityHeading(ped)


                    canFire = false
                    CeaseFire()
                    TaskPlayAnimAdvanced(ped, 'reaction@intimidation@1h', 'intro', pos.x, pos.y, pos.z, 0, 0, rot, 8.0, 3.0, -1, 50, 0, 0, 0)
                    Wait(1000)
                    SetCurrentPedWeapon(ped, currWeap, true)
                    SetCurrentPedWeapon(ped, currWeap, true)
                    Wait(1400)
                    ClearPedTasks(ped)
                    holstered = false
                    canFire = true
                    break
                end
            end
        end

        Wait(sleep)
        if currWeap == nil or currWeap == `WEAPON_UNARMED` then
            weaponCheck += 1
            if weaponCheck == 2 then
                break
            end
        end
    end
end
RegisterNetEvent('weapons:client:DrawWeapon', DrawWeapon)


function CeaseFire()
    CreateThread(function()
        while not canFire do
            DisableControlAction(0, 25, true)
            DisablePlayerFiring(PlayerId(), true)
            Wait(0)
        end
    end)
end