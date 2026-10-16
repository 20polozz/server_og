--[[ Puente de avisos. `origen_notify` es el recurso real del servidor; si no
     esta arrancado se cae a ox_lib para no dejar al jugador sin respuesta. ]]
Custom.Notify = function(data)
    if type(data) ~= 'table' then return end

    if IsServer then
        local target = data.source or -1
        data.source = nil

        if GetResourceState('origen_notify') == 'started' then
            local ok = pcall(TriggerClientEvent, 'origen_notify:SendNotification', target, data)
            if ok then return end
        end

        TriggerClientEvent('ox_lib:notify', target, data)
        return
    end

    if GetResourceState('origen_notify') == 'started' then
        local ok = pcall(function()
            exports['origen_notify']:Notify(data)
        end)
        if ok then return end
    end

    lib.notify(data)
end
