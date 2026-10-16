local function setFakePlate(vehicle, plate)
    if vehicle then
        if plate then
            if GlobalState.fakePlates[GetVehicleNumberPlateText(vehicle):gsub(" ", "")] then return false, "El vehículo ya tiene una matrícula falsa aplicada" end
            local realplate = GetVehicleNumberPlateText(vehicle)
            TriggerServerEvent('origen_utils:server:platesCache', true, plate, realplate)
            SetVehicleNumberPlateText(vehicle, plate)
            return true
        else
            if not GlobalState.fakePlates[GetVehicleNumberPlateText(vehicle):gsub(" ", "")] then return false, "El vehículo no tiene una matrícula falsa aplicada" end
            local realplate = GlobalState.fakePlates[GetVehicleNumberPlateText(vehicle):gsub(" ", "")]
            TriggerServerEvent('origen_utils:server:platesCache', false, GetVehicleNumberPlateText(vehicle), realplate)
            SetVehicleNumberPlateText(vehicle, realplate)
            return true
        end
    end
end
exports('setFakePlate', setFakePlate)
exports('getVehiclePlate', function(plate)
    local fakePlates = GlobalState.fakePlates
    return fakePlates[plate] or plate
end)