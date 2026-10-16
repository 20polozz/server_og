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

--@param text Text to show
--@param key Key to show
Custom.DrawText = function(key, text)
    lib.showTextUI('['..key..'] - '..text)
end

Custom.HideText = function()
    lib.hideTextUI()
end

Custom.Progress = function(duration, text)
    return lib.progressCircle({
        canCancel = false,
        disable = {
            car = true,
        },
        duration = duration,
        label = text,
        position = 'bottom',
        useWhileDead = false,
    })
end