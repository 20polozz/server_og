-- Register NUI callbacks for custom frequencies
RegisterNUICallback("CreateCustomFrequency", function(data, cb)
    TriggerServerEvent('origen_radio:server:CreateCustomFrequency', data)
    cb({})
end)

RegisterNUICallback("UpdateCustomFrequencyName", function(data, cb)
    TriggerServerEvent('origen_radio:server:UpdateCustomFrequencyName', data)
    cb({})
end)

RegisterNUICallback("DeleteCustomFrequency", function(frequencyId, cb)
    TriggerServerEvent('origen_radio:server:DeleteCustomFrequency', frequencyId)
    cb({})
end)

RegisterNetEvent('origen_radio:client:CustomFrequencyCreated', function(data)
    SendNUIMessage({
        action = 'CustomFrequencyCreated',
        data = data
    })
end)

RegisterNetEvent('origen_radio:client:CustomFrequencyNameUpdated', function(data)
    SendNUIMessage({
        action = 'CustomFrequencyNameUpdated',
        data = data
    })
end)

RegisterNetEvent('origen_radio:client:CustomFrequencyDeleted', function(frequencyId)
    SendNUIMessage({
        action = 'CustomFrequencyDeleted',
        data = frequencyId
    })
end)

RegisterNetEvent('origen_radio:client:MemberRevoked', function(frequencyId, revokedCitizenid)
    local playerData = FW_GetPlayerData()
    local myCitizenid = playerData.citizenid
    
    if myCitizenid == revokedCitizenid then
        SendNUIMessage({
            action = 'CustomFrequencyDeleted',
            data = frequencyId
        })
        FW_Notify("El dueño te ha revocado el acceso a una frecuencia", "error")
    end
end)

RegisterNetEvent('origen_radio:client:MemberLeft', function(frequencyId, ownerCitizenid, memberName)
    local playerData = FW_GetPlayerData()
    local myCitizenid = playerData.citizenid
    
    if myCitizenid == ownerCitizenid then
        FW_Notify(memberName .. " se ha desvinculado de tu frecuencia", "info")
    end
end)

-- Store pending invitations on the client
local PendingInvitations = {}

RegisterNetEvent('origen_radio:client:FrequencyInvitation', function(data)
    table.insert(PendingInvitations, data)
    
    SendNUIMessage({
        action = 'FrequencyInvitation',
        data = data
    })
end)

RegisterNUICallback("GetPendingInvitations", function(data, cb)
    cb(PendingInvitations)
end)

RegisterNUICallback("ClearInvitation", function(data, cb)
    for i = #PendingInvitations, 1, -1 do
        if PendingInvitations[i].frequencyId == data.frequencyId and 
           PendingInvitations[i].inviterCid == data.inviterCid then
            table.remove(PendingInvitations, i)
            break
        end
    end
    cb({})
end)

-- Invite player to frequency
RegisterNUICallback("InviteToFrequency", function(data, cb)
    FW_TriggerCallback("origen_radio:InviteToFrequency", function(result)
        cb({success = result})
    end, data)
end)

-- Accept frequency invitation
RegisterNUICallback("AcceptFrequencyInvitation", function(data, cb)
    FW_TriggerCallback("origen_radio:AcceptFrequencyInvitation", function(result)
        cb({success = result})
    end, data)
end)

-- Get frequency members
RegisterNUICallback("GetFrequencyMembers", function(data, cb)
    FW_TriggerCallback("origen_radio:GetFrequencyMembers", function(members)
        cb(members)
    end, data.frequencyId)
end)

-- Revoke member access
RegisterNUICallback("RevokeMemberAccess", function(data, cb)
    TriggerServerEvent('origen_radio:server:RevokeMemberAccess', data.frequencyId, data.memberCitizenid)
    cb({})
end)

-- Leave shared frequency
RegisterNUICallback("LeaveSharedFrequency", function(data, cb)
    TriggerServerEvent('origen_radio:server:LeaveSharedFrequency', data.frequencyId)
    cb({})
end)

-- Update frequency user count in real-time
RegisterNetEvent('origen_radio:client:UpdateFrequencyUserCount', function(group, multifrec, userCount)
    SendNUIMessage({
        action = 'UpdateFrequencyUserCount',
        group = group,
        frequency = multifrec,
        userCount = userCount
    })
end)

RegisterNetEvent('origen_radio:client:UpdateFrequencyUsersList', function(group, multifrec, usersList)
    SendNUIMessage({
        action = 'UpdateFrequencyUsersList',
        group = group,
        frequency = multifrec,
        users = usersList
    })
end)

