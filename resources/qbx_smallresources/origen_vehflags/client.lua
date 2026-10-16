lib.onCache('vehicle', function(value, oldValue)
    if not value then return end
    SetVehicleRadioEnabled(value, false)
end)