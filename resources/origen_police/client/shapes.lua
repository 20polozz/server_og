RegisterNetEvent('origen_police:client:ReloadShapes', function()
    SendNUIMessage({
        action = "UpdateShapes",
    })
end)