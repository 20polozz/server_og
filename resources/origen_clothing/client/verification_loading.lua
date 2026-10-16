RegisterNetEvent('origen_clothing:showVerificationLoading', function(data)
    SendNUIMessage({
        action = 'showVerificationLoading',
        message = data.message,
        progress = data.progress
    })
end)

RegisterNetEvent('origen_clothing:updateVerificationProgress', function(data)
    SendNUIMessage({
        action = 'updateVerificationProgress',
        progress = data.progress
    })
end)

RegisterNetEvent('origen_clothing:hideVerificationLoading', function()
    SendNUIMessage({
        action = 'hideVerificationLoading'
    })
end)

