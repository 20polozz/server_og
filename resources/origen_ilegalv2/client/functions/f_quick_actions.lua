QuickActionsClient = {}

local isHandcuffed = false

RegisterNetEvent('origen_gang:client:openPlayerInventory', function(targetId)
    ExecuteCommand("searchPlayer")
end)

-- Handcuff logic moved to client/functions/f_handcuff.lua
-- RegisterNetEvent('origen_gang:client:toggleHandcuff', function(executorId)
--     local playerPed = PlayerPedId()
--     isHandcuffed = not isHandcuffed
    
--     if isHandcuffed then
--         lib.requestAnimDict('mp_arresting')
--         TaskPlayAnim(playerPed, 'mp_arresting', 'idle', 8.0, -8.0, -1, 49, 0, false, false, false)
--         SetEnableHandcuffs(playerPed, true)
--         DisablePlayerFiring(playerPed, true)
--         SetCurrentPedWeapon(playerPed, `WEAPON_UNARMED`, true)
--         Bridge.Notify('Has sido esposado', 'error')
--     else
--         ClearPedTasks(playerPed)
--         SetEnableHandcuffs(playerPed, false)
--         Bridge.Notify('Has sido liberado', 'success')
--     end
-- end)

RegisterNetEvent('origen_gang:client:putInVehicle', function(executorId)
    local playerPed = PlayerPedId()
    local executor = GetPlayerPed(GetPlayerFromServerId(executorId))
    local vehicle = GetVehiclePedIsIn(executor, false)
    
    if vehicle and vehicle ~= 0 then
        local maxSeats = GetVehicleMaxNumberOfPassengers(vehicle)
        
        for i = maxSeats - 1, 0, -1 do
            if IsVehicleSeatFree(vehicle, i) then
                TaskWarpPedIntoVehicle(playerPed, vehicle, i)
                return
            end
        end
    end
end)

RegisterNetEvent('origen_gang:client:takeOutVehicle', function(executorId)
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    if vehicle and vehicle ~= 0 then
        local coords = GetEntityCoords(playerPed)
        TaskLeaveVehicle(playerPed, vehicle, 16)
    end
end)
