--@param text Text to show
--@param type Notification type
--@param length Duration of the notification
Custom.Notify = function(text, type, length)
    -- Usar origen_notify para las notificaciones
    exports['origen_notify']:Notify({
        description = text,
        type = type or 'info',
        duration = length or 5000
    })
end

--@param text Text to show
--@param key Key to show
Custom.DrawText = function(text, key)
    -- Usar origen_notify para el DrawText
    exports['origen_notify']:DrawText(key, text)
end

Custom.HideText = function()
    -- Usar origen_notify para ocultar el DrawText
    exports['origen_notify']:HideText()
end