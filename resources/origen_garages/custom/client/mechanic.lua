--[[ Puente con origen_mechanic, dueño único del estado de salud por matrícula.
     El garaje borra la entidad, así que el estado se guarda a propósito ANTES
     del borrado en vez de confiar en que el otro recurso reaccione a tiempo a
     su propio `entityRemoved`. ]]
local function saveVehicleHealth(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return false end
    if GetResourceState('origen_mechanic') ~= 'started' then return false end
    if not NetworkGetEntityIsNetworked(vehicle) then return false end

    local ok = pcall(function()
        TriggerServerEvent('origen_mechanic:server:saveVehicle', { netId = VehToNet(vehicle) })
    end)

    return ok
end

Custom.SaveVehicleHealth = saveVehicleHealth
