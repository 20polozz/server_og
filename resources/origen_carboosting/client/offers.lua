RegisterNetEvent('origen_boosting:cl:CancelTempOffer', function(uniqueID, refused)
    Internal.Notify(refused and locale('in_game.notifications.contract_offer_refused') or locale('in_game.notifications.contract_offer_expired'), 'error', 5000)
    SendNUIMessage({
        action = "offerExpired",
        uniqueID = uniqueID,
        notify = refused and locale('in_game.notifications.contract_offer_refused') or locale('in_game.notifications.contract_offer_expired'),
    })
end)

RegisterNetEvent('origen_boosting:cl:SendTempOffer', function(data)
    Internal.Notify(locale('in_game.notifications.contract_offer_received'), 'info', 5000)
    SendNUIMessage({
        action = "receiverTempOffer",
        data = data
    })
end)

RegisterNetEvent('origen_boosting:cl:RemoveContract', function(uniqueID, price)
    Internal.Notify(locale('in_game.notifications.contract_sold'), 'info', 5000)
    SendNUIMessage({
        action = "removeContract",
        uniqueID = uniqueID,
        price = price,
        notify = locale('in_game.notifications.contract_sold')
    })
end)