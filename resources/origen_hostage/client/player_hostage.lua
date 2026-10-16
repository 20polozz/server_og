local holdingHostageInProgress = false
local holdingHostage = false
local beingHeldHostage = false
local hostagePed = nil
local hostageTarget = nil
local hostageDict = "anim@gangops@hostage@"

local function GetClosestPlayer(radius)
    local players = GetActivePlayers()
    local closestDistance = -1
    local closestPlayer = -1
    local ply = PlayerPedId()
    local plyCoords = GetEntityCoords(ply, 0)

    for index, value in ipairs(players) do
        local target = GetPlayerPed(value)
        if target ~= ply and GetEntityHealth(target) > 0 then
            local targetCoords = GetEntityCoords(target, 0)
            local distance = #(targetCoords - plyCoords)
            if closestDistance == -1 or closestDistance > distance then
                closestPlayer = value
                closestDistance = distance
            end
        end
    end
    
    if closestDistance ~= -1 and closestDistance <= radius then
        return closestPlayer, closestDistance
    else
        return nil, nil
    end
end

local function LoadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(0)
    end
end

RegisterCommand("th", function()
    local playerPed = PlayerPedId()
    local weapon = GetSelectedPedWeapon(playerPed)

    if weapon == `WEAPON_UNARMED` then
        exports['origen_notify']:Notify({ title = 'Rehén', description = "Necesitas un arma válida para tomar un rehén.", type = 'error', duration = 3000 })
        return
    end

    if holdingHostageInProgress or holdingHostage or beingHeldHostage then
        return
    end

    local closestPlayer, closestDistance = GetClosestPlayer(2.5)

    if closestPlayer ~= nil and closestDistance <= 2.5 then
        local targetSrc = GetPlayerServerId(closestPlayer)
        if targetSrc ~= -1 then
            holdingHostageInProgress = true
            TriggerServerEvent("origen_hostage:server:takeHostage", targetSrc)
        end
    else
        exports['origen_notify']:Notify({ title = 'Rehén', description = "No hay nadie cerca.", type = 'error', duration = 3000 })
    end
end)

RegisterNetEvent("origen_hostage:client:startHostage", function(targetSrc)
    local playerPed = PlayerPedId()
    hostageTarget = targetSrc
    holdingHostage = true
    holdingHostageInProgress = false
    
    LoadAnimDict(hostageDict)
    TaskPlayAnim(playerPed, hostageDict, "perp_idle", 8.0, -8.0, -1, 49, 0, false, false, false)

    CreateThread(function()
        exports['origen_notify']:DrawText('G', 'Soltar', { 'E', 'Matar' })
        while holdingHostage do
            Wait(0)
            DisableControlAction(0, 24, true) -- disable attack
            DisableControlAction(0, 25, true) -- disable aim
            DisableControlAction(0, 47, true) -- disable weapon (G)
            DisableControlAction(0, 58, true) -- disable weapon
            DisablePlayerFiring(PlayerId(), true)
            
            if not IsEntityPlayingAnim(playerPed, hostageDict, "perp_idle", 3) then
                TaskPlayAnim(playerPed, hostageDict, "perp_idle", 8.0, -8.0, -1, 49, 0, false, false, false)
            end
            
            if IsDisabledControlJustPressed(0, 47) then -- G to release
                holdingHostage = false
                TriggerServerEvent("origen_hostage:server:releaseHostage", hostageTarget)
                exports['origen_notify']:HideText()
                TaskPlayAnim(playerPed, hostageDict, "release", 8.0, -8.0, -1, 48, 0, false, false, false)
                Wait(2000)
                ClearPedTasks(playerPed)
            elseif IsControlJustPressed(0, 38) then -- E to kill
                holdingHostage = false
                TriggerServerEvent("origen_hostage:server:killHostage", hostageTarget)
                exports['origen_notify']:HideText()
                TaskPlayAnim(playerPed, hostageDict, "perp_fail", 8.0, -8.0, -1, 168, 0, false, false, false)
                Wait(2000)
                ClearPedTasks(playerPed)
            end
        end
    end)
end)

RegisterNetEvent("origen_hostage:client:beHostage", function(perpSrc)
    local playerPed = PlayerPedId()
    beingHeldHostage = true
    
    local perpPlayer = GetPlayerFromServerId(perpSrc)
    if perpPlayer ~= -1 then
        local perpPed = GetPlayerPed(perpPlayer)
        
        LoadAnimDict(hostageDict)
        AttachEntityToEntity(playerPed, perpPed, 0, -0.24, 0.11, 0.0, 0.5, 0.5, 0.0, false, false, false, false, 2, false)
        TaskPlayAnim(playerPed, hostageDict, "victim_idle", 8.0, -8.0, -1, 49, 0, false, false, false)

        CreateThread(function()
            while beingHeldHostage do
                Wait(0)
                DisableControlAction(0, 21, true) -- sprint
                DisableControlAction(0, 24, true) -- attack
                DisableControlAction(0, 25, true) -- aim
                DisableControlAction(0, 47, true) -- weapon
                DisableControlAction(0, 58, true) -- weapon
                DisableControlAction(0, 263, true) -- melee
                DisableControlAction(0, 264, true) -- melee
                DisableControlAction(0, 257, true) -- attack 2
                DisableControlAction(0, 140, true) -- melee
                DisableControlAction(0, 141, true) -- melee
                DisableControlAction(0, 142, true) -- melee
                DisableControlAction(0, 143, true) -- melee
                DisableControlAction(0, 75, true) -- exit vehicle
                DisableControlAction(27, 75, true) -- exit vehicle
                DisableControlAction(0, 22, true) -- jump
                DisableControlAction(0, 32, true) -- move
                DisableControlAction(0, 268, true)
                DisableControlAction(0, 33, true)
                DisableControlAction(0, 269, true)
                DisableControlAction(0, 34, true)
                DisableControlAction(0, 270, true)
                DisableControlAction(0, 35, true)
                DisableControlAction(0, 271, true)
                DisablePlayerFiring(PlayerId(), true)
                
                if not IsEntityPlayingAnim(playerPed, hostageDict, "victim_idle", 3) then
                    TaskPlayAnim(playerPed, hostageDict, "victim_idle", 8.0, -8.0, -1, 49, 0, false, false, false)
                end
            end
        end)
    end
end)

RegisterNetEvent("origen_hostage:client:releaseHostage", function()
    beingHeldHostage = false
    local playerPed = PlayerPedId()
    DetachEntity(playerPed, true, false)
    TaskPlayAnim(playerPed, hostageDict, "shove_victim_dir", 8.0, -8.0, -1, 0, 0, false, false, false)
    Wait(2000)
    ClearPedTasks(playerPed)
end)

RegisterNetEvent("origen_hostage:client:killHostage", function()
    beingHeldHostage = false
    local playerPed = PlayerPedId()
    DetachEntity(playerPed, true, false)
    TaskPlayAnim(playerPed, hostageDict, "victim_fail", 8.0, -8.0, -1, 0, 0, false, false, false)
    Wait(1500)
    SetEntityHealth(playerPed, 0)
end)
