--@param text Text to show
--@param type Notification type
--@param length Duration of the notification
Custom.Notify = function(text, type, length)
    lib.notify({
        description = text,
        type = type,
        duration = length,
    })
end