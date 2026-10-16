-- Handle kick user from public radio
RegisterNUICallback("KickPublicRadioUser", function(data, cb)
    TriggerServerEvent('origen_radio:server:KickPublicRadioUser', data.radioId, data.citizenid)
    cb({})
end)

-- Handle being kicked from public radio
RegisterNetEvent('origen_radio:client:KickedFromPublicRadio', function(radioName)
    -- Disconnect from radio
    exports["pma-voice"]:removePlayerFromRadio()
    
    -- Reset state
    currentPublicRadio = nil
    isPublicRadioOwner = false
    
    -- Reset widget
    SendNUIMessage({
        action = 'resetRadioWidget'
    })
    
    -- Remove from list
    SendNUIMessage({
        action = 'DisconnectAllFreqs'
    })
    
    -- Notify
    FW_Notify("Te han expulsado de la radio: " .. radioName, "error")
end)

