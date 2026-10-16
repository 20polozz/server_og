--@param text Text to show (already translated)
--@param type Notification type
--@param length Duration of the notification
Custom.Notify = function(text, type, length)
    lib.notify({
        title = 'Concesionario',
        description = text,
        type = type,
        duration = length
    })
end

--@param text Text to show (already translated)
--@param key Key to show (already translated)
local notify = nil
Custom.DrawText = function(text, key)
    lib.showTextUI('[' .. key .. '] - ' .. text)
end

Custom.HideText = function()
    lib.hideTextUI()
end