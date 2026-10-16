local hasTracker = false

RegisterNetEvent("origen_police:client:OnPlayerLoaded", function()
    TriggerServerEvent("origen_police:server:GetAnkleCuff")
end)

RegisterNUICallback("AnckleShock", function(data, cb)
    TriggerServerEvent("origen_police:server:ankleshock", data.id)
    cb(true)
end)

function AddTrackerObj(skipLoop)
    if not hasTracker then return end
    if Config.TrackerCloths and Config.TrackerCloths.enabled then
        SetPedComponentVariation(PlayerPedId(), 7, GetEntityModel(PlayerPedId()) == GetHashKey("mp_m_freemode_01") and Config.TrackerCloths.male or Config.TrackerCloths.female, 0, 0)
    end

    if skipLoop then return end
    while hasTracker do
        AddTrackerObj(true)
        Wait(3000)
    end
end

function RemoveTrackerObj()
    hasTracker = false
    if Config.TrackerCloths and Config.TrackerCloths.enabled then
        SetPedComponentVariation(PlayerPedId(), 7, 0, 0, 0)
    end
end

RegisterNetEvent("origen_police:client:anklecuff", function()
    local player, distance = FW_GetClosestPlayer()
    local ped = PlayerPedId()
    if player ~= -1 and distance <= 3.0 and distance > 0 then
        TriggerServerEvent("origen_police:server:anklecuff", GetPlayerServerId(player))
        RequestAnimSet('move_ped_crouched')
        while not HasAnimSetLoaded('move_ped_crouched') do
            Wait(10)
        end
        SetPedMovementClipset(ped, 'move_ped_crouched', 1.0)
        SetPedStrafeClipset(ped, 'move_ped_crouched_strafing')
        Wait(400)
        RequestAnimDict("mp_arresting")
        while not HasAnimDictLoaded("mp_arresting") do
            Wait(1)
        end
        TaskPlayAnim(PlayerPedId(), 'mp_arresting', 'a_uncuff', 8.0, -8.0,-1, 16, 0, 0, 0, 0)
        Wait(5000)
        ClearPedTasks(ped)
        SetPedStealthMovement(ped, false, 'DEFAULT_ACTION')
        ResetPedMovementClipset(ped, 1.0)
        ResetPedWeaponMovementClipset(ped)
        ResetPedStrafeClipset(ped)
    else
        ShowNotification(Config.Translations.NoPersonNear, "error")
    end
end)

RegisterNetEvent("origen_police:client:SetAnkleCuff", function(state)
    if not state then
        RemoveTrackerObj()
        return
    end
    hasTracker = true
    AddTrackerObj()
end)

RegisterNetEvent("origen_police:client:ankleshock", function()
    local dict = "stungun@standing"
    RequestAnimDict(dict)

    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Wait(0)
    end
    local ped = PlayerPedId()
    TaskPlayAnim(ped, dict, "damage", 8.0, 1.0, 1500, 1, 0, false, false, false)

    
    for _ = 0, 15, 1 do
        SetEntityHealth(ped, GetEntityHealth(ped) - 1)
        Wait(100)
    end

    SetPedToRagdoll(ped, 4000, 4000, 0, 0, 0, 0)
end)