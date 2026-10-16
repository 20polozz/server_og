-- Handle disconnect from public radio via NUI callback
RegisterNUICallback("DisconnectFromPublicRadio", function(data, cb)
    if data.radioId then
        -- Disconnect from pma-voice
        exports["pma-voice"]:removePlayerFromRadio()
        
        -- Notify server to decrement user count
        TriggerServerEvent('origen_radio:server:UpdatePublicRadioUsers', data.radioId, false)
        
        -- Reset state
        currentPublicRadio = nil
        isPublicRadioOwner = false
        
        -- Reset widget
        SendNUIMessage({
            action = 'resetRadioWidget'
        })
    end
    
    cb({})
end)

-- Receive updated users list from server
RegisterNetEvent('origen_radio:client:UpdatePublicRadioUsersList', function(radioId, usersList)
    SendNUIMessage({
        action = 'UpdatePublicRadioUsersList',
        radioId = radioId,
        users = usersList
    })
end)


