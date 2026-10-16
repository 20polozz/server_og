--@param title Title of the notification
--@param description Description text
--@param type Notification type
--@param source Source player (server only)

Custom.Notify = function(data)
    if isServer then
        TriggerClientEvent('ox_lib:notify', data.source or -1, data)
    else
        lib.notify(data)
    end
end