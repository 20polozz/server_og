Internal.GiveVehicleKeys = function(vehicle, plate, interior)
    if interior and not Config.GiveKeys.interior then return end
    if not interior and not Config.GiveKeys.exterior then return end
    if Config.KeySystem == 'qb-vehiclekeys' then
        TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', plate)
    elseif Config.KeySystem == 'qs-vehiclekeys' then
        vehicle = NetToVeh(vehicle)
        local model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
        exports['qs-vehiclekeys']:GiveKeys(plate, model, true)
    elseif Config.KeySystem == 'esx_vehiclelock' then
        TriggerServerEvent('esx_vehiclelock:givekey', plate)
    elseif Config.KeySystem == 'wasabi_carlock' then
        exports.wasabi_carlock:GiveKey(plate)
    elseif Config.KeySystem == 'qbx_vehiclekeys' then
        TriggerServerEvent('qbx_vehiclekeys:server:tookKeys', vehicle)
    else
        Custom.GiveVehicleKeys(vehicle, plate)
    end
end