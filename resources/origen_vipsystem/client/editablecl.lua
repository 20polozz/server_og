function notify(msg, type)
    -- type = 'inform' or 'error' or 'success'
    if Notify and Notify.SendNotification then
        Notify.SendNotification(T('general.title'), msg, type, 7000)
    end
end
