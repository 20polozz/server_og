RegisterNetEvent('origen_boosting:cl:AddActiveOffer', function(data)
    if InTablet then
        SendNUIMessage({
            action = 'addActiveOffer',
            data = data
        })
    end
end)

RegisterNetEvent('origen_boosting:cl:RemoveActiveOffer', function(data)
    local source = GetPlayerServerId(PlayerId())
    if InTablet then
        if data.seller == source then
            Internal.Notify('success', locale('in_game.notifications.market_contract_bought'))
        end
        SendNUIMessage({
            action = 'removeActiveOffer',
            id = data.id,
            isSeller = data.seller and data.seller == source,
            isBuyer = data.buyer and data.buyer == source,
        })
    end
end)