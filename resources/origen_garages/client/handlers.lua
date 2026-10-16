RegisterNetEvent('origen_garages:client:UpdateGarage', function(garageData)
    local garage = cGarage.Get(garageData.id)
    
    if garage then
        garage:update(garageData)
    else
        cGarage.new(garageData)
    end
end)

RegisterNetEvent('origen_garages:client:DeleteGarage', function(garageId)
    local garage = cGarage.Get(garageId)
    if garage then
        garage:delete()
    end
end)