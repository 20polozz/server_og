Custom.GiveKeys = function(vehicle, plate)
    if not vehicle and not plate then
        return false
    end
    
    local plateToUse = plate or (DoesEntityExist(vehicle) and GetVehicleNumberPlateText(vehicle) or nil)
    if not plateToUse then
        return false
    end

    TriggerEvent('vehiclekeys:client:SetOwner', plate)
    return true
end