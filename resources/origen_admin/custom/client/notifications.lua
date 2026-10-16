function ShowNotification(text, notifType, duration)
    exports['origen_notify']:Notify({
        description = text,
        type = notifType or 'info',
        duration = duration or 5000
    })
end