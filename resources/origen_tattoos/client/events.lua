RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    TattooLists = GetTattoosList()
    AppliedTattoos = GetPlayerTattoos()
    ApplyPlayerTattos()
end)

RegisterNetEvent('qbx_core:client:playerLoaded', function()
    TattooLists = GetTattoosList()
    AppliedTattoos = GetPlayerTattoos()
    ApplyPlayerTattos()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    currentTattoos = {}
end)

RegisterNetEvent('qbx_core:client:playerLoggedOut', function()
    currentTattoos = {}
end)

RegisterNetEvent('origen_tattoos:client:updateTattoos', function()
    AppliedTattoos = GetPlayerTattoos()
    ApplyPlayerTattos()
end)

RegisterNetEvent('origen_tattoos:client:SyncNpc', function(store, travel)
    StartNPCSequence(store, travel)
end)