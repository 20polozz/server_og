local function impoundVehicle(plate)
    return lib.callback.await('origen_garages:cb:impoundVehicle', false, plate)
end

exports('impoundVehicle', impoundVehicle)