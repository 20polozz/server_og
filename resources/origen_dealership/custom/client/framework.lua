Custom.GetPlayerIdentifier = function()
    local identifier = nil
    if Config.Framework == 'qb-core' then 
        identifier = Framework.Functions.GetPlayerData().citizenid
    elseif Config.Framework == 'esx' then 
        identifier = Framework.GetPlayerData().identifier
    end

    return identifier
end

Custom.GetPlayerJob = function()
    local job = nil
    if Config.Framework == 'qb-core' or Config.Framework == 'qbx' then
        local data = Framework.Functions.GetPlayerData()
        if data and data.job then
            job = data.job.name
        end
    elseif Config.Framework == 'esx' then
        local data = Framework.GetPlayerData()
        if data and data.job then
            job = data.job.name
        end
    end
    return job
end


Custom.HandleInteraction = function(interactionData)
    if interactionData.type == 'npc' then
        -- interactionData.onInteract()
        -- return true
        return false -- Deshabilitado
    end
    return false
end

Custom.GetVehicleProps = function(vehicle)
    if not DoesEntityExist(vehicle) then
        return {}
    end
    
    if Config.VehiclePurchase.useOxLibProps and lib and lib.getVehicleProperties then
        return lib.getVehicleProperties(vehicle)
    else
        -- Fallback básico si ox_lib no está disponible
        return {
            model = GetEntityModel(vehicle),
            plate = GetVehicleNumberPlateText(vehicle),
            bodyHealth = GetVehicleBodyHealth(vehicle),
            engineHealth = GetVehicleEngineHealth(vehicle),
            fuelLevel = GetVehicleFuelLevel(vehicle),
            dirtLevel = GetVehicleDirtLevel(vehicle),
        }
    end
end

-- Función para aplicar propiedades al vehículo usando ox_lib
Custom.SetVehicleProps = function(vehicle, props)
    if not DoesEntityExist(vehicle) or not props then
        return false
    end
    
    if Config.VehiclePurchase.useOxLibProps and lib and lib.setVehicleProperties then
        lib.setVehicleProperties(vehicle, props)
        return true
    else
        -- Fallback básico si ox_lib no está disponible
        if props.plate then
            SetVehicleNumberPlateText(vehicle, props.plate)
        end
        if props.bodyHealth then
            SetVehicleBodyHealth(vehicle, props.bodyHealth + 0.0)
        end
        if props.engineHealth then
            SetVehicleEngineHealth(vehicle, props.engineHealth + 0.0)
        end
        if props.fuelLevel then
            SetVehicleFuelLevel(vehicle, props.fuelLevel + 0.0)
        end
        if props.dirtLevel then
            SetVehicleDirtLevel(vehicle, props.dirtLevel + 0.0)
        end
        return true
    end
end
