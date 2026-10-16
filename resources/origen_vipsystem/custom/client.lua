Custom = Custom or {}

--@param vehicle Handle of the test drive vehicle
--@param plate Plate the test drive vehicle was given
Custom.GiveVehicleKeys = function(vehicle, plate)
    if not DoesEntityExist(vehicle) then return end

    CreateThread(function()
        local netId = NetworkGetNetworkIdFromEntity(vehicle)
        local attempts = 0

        while (not netId or netId == 0) and attempts < 20 do
            Wait(50)
            attempts = attempts + 1
            if not DoesEntityExist(vehicle) then return end
            netId = NetworkGetNetworkIdFromEntity(vehicle)
        end

        if not netId or netId == 0 then
            TriggerEvent('vehiclekeys:client:SetOwner', plate)
            return
        end

        TriggerServerEvent('origen_vipsystem:server:testDriveKeys', netId)
    end)
end

-- Ejecuta un export de cliente que pidio el servidor al entregar una accion
-- custom. Solo el servidor dispara este evento, no hay superficie nueva.
local function runClientAction(payload)
    if type(payload) ~= 'table' then return false end
    if type(payload.resource) ~= 'string' or payload.resource == '' then return false end
    if type(payload.name) ~= 'string' or payload.name == '' then return false end
    if GetResourceState(payload.resource) ~= 'started' then return false end

    local args = type(payload.args) == 'table' and payload.args or {}
    local count = math.floor(tonumber(payload.count) or #args)

    -- El runtime se come el primer argumento como `self`: hay que mandar el proxy
    -- adelante o el export recibe la lista corrida un lugar.
    local ok, result = pcall(function()
        local handle = exports[payload.resource]
        if payload.self then
            return handle[payload.name](handle, handle, table.unpack(args, 1, count))
        end
        return handle[payload.name](handle, table.unpack(args, 1, count))
    end)

    if not ok then return false end

    return result == nil or (result and true or false)
end

RegisterNetEvent('origen_vipsystem:client:runAction', runClientAction)
lib.callback.register('origen_vipsystem:client:runAction', runClientAction)
