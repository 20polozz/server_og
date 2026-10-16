-- Client-side handler for public radios
local currentPublicRadio = nil
local isPublicRadioOwner = false

-- Register NUI callbacks
RegisterNUICallback("CreatePublicRadio", function(data, cb)
    TriggerServerEvent('origen_radio:server:CreatePublicRadio', data)
    cb({})
end)

RegisterNUICallback("ConnectToPublicRadio", function(data, cb)
    local Radio = exports['origen_radio']:GetRadio()
    if Radio and Radio.MultiGroup and Radio.MultiGroup ~= "none" then
        exports['origen_radio']:SetMultiFrec("none", "none")
    end
    
    currentPublicRadio = {
        id = data.radioId,
        frequency = data.frequency
    }
    isPublicRadioOwner = false
    
    exports["pma-voice"]:setRadioChannel(tonumber(data.frequency))
    TriggerServerEvent('origen_radio:server:UpdatePublicRadioUsers', data.radioId, true)
    
    SendNUIMessage({
        action = 'updateRadioWidget',
        radioType = 'public'
    })
    
    cb({})
end)

RegisterNUICallback("DeletePublicRadio", function(data, cb)
    TriggerServerEvent('origen_radio:server:DeletePublicRadio', data.radioId)
    
    -- If we're connected to this radio, disconnect
    if currentPublicRadio == data.radioId then
        exports["pma-voice"]:removePlayerFromRadio()
        currentPublicRadio = nil
        isPublicRadioOwner = false
        
        SendNUIMessage({
            action = 'resetRadioWidget'
        })
    end
    
    cb({})
end)

-- Disconnect from public radio
RegisterNetEvent('origen_radio:client:DisconnectFromPublicRadio', function(radioId)
    if currentPublicRadio == radioId then
        exports["pma-voice"]:removePlayerFromRadio()
        currentPublicRadio = nil
        isPublicRadioOwner = false
        
        SendNUIMessage({
            action = 'resetRadioWidget'
        })
    end
end)

-- Refresh public radios list
RegisterNetEvent('origen_radio:client:RefreshPublicRadios', function()
    SendNUIMessage({
        action = 'RefreshPublicRadios'
    })
end)

-- Update user count
RegisterNetEvent('origen_radio:client:UpdatePublicRadioCount', function(radioId, count)
    SendNUIMessage({
        action = 'UpdatePublicRadioCount',
        radioId = radioId,
        count = count
    })
end)

RegisterNetEvent('origen_radio:client:UpdatePublicRadioUsersList', function(radioId, users)
    SendNUIMessage({
        action = 'UpdatePublicRadioUsers',
        radioId = radioId,
        users = users
    })
end)

-- Handle user talking status
RegisterNetEvent('origen_radio:client:PublicRadioUserTalking', function(data)
    SendNUIMessage({
        action = 'PublicRadioUserTalking',
        citizenid = data.citizenid,
        talking = data.talking
    })
end)

-- Notify function
RegisterNetEvent('origen_radio:client:Notify', function(message, type)
    FW_Notify(message, type)
end)

-- Clean up on resource stop
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() and currentPublicRadio then
        TriggerServerEvent('origen_radio:server:UpdatePublicRadioUsers', currentPublicRadio, false)
    end
end)

-- Clean up on player drop
AddEventHandler('playerDropped', function()
    if currentPublicRadio then
        TriggerServerEvent('origen_radio:server:UpdatePublicRadioUsers', currentPublicRadio, false)
    end
end)

-- Handle talking events for public radio
RegisterNetEvent('origen_radio:client:localPlayerTalking', function(isTalking)
    if currentPublicRadio then
        TriggerServerEvent('origen_radio:server:PublicRadioTalking', isTalking)
    end
end)

RegisterNetEvent('origen_radio:client:ConnectingToPrivate', function()
    if currentPublicRadio then
        TriggerServerEvent('origen_radio:server:UpdatePublicRadioUsers', currentPublicRadio.id, false)
        
        local radioIdToRemove = currentPublicRadio.id
        currentPublicRadio = nil
        isPublicRadioOwner = false
        
        SendNUIMessage({
            action = 'RemovePublicRadioFromList',
            radioId = radioIdToRemove
        })
        
        SendNUIMessage({
            action = 'RefreshPublicRadios'
        })
    end
end)

--- Sin radio encima: el servidor ya te ha sacado de la publica (server/sin_radio.lua).
RegisterNetEvent('origen_radio:client:SinRadio', function()
    currentPublicRadio = nil
    isPublicRadioOwner = false
end)

-- This event is no longer needed since we handle it directly in ConnectToPublicRadio

-- Export
exports('GetCurrentPublicRadio', function()
    return currentPublicRadio
end)

exports('IsPublicRadioOwner', function()
    return isPublicRadioOwner
end)

