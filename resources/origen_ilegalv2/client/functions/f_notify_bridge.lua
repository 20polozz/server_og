-- ── Client Notify Bridge ──────────────────────────────────────────────────────
-- Handler del evento server->client para notificaciones disparadas desde
-- NotifyPlayer() en server/functions/f_bridge_migration.lua.
-- Usa Notify.SendNotify que ya está disponible via bridge/notify/**

RegisterNetEvent('origen_ilegalv2:client:notify', function(message, msgType, time)
    if type(message) == 'table' then
        local payload = message
        local title = payload.title
        local description = payload.description or payload.message or ''
        local nType = payload.type or msgType
        local duration = payload.duration or payload.time or time

        if title then
            Notify.SendNotification(title, description, nType, duration)
        else
            Notify.SendNotify(description, nType, duration)
        end
        return
    end

    Notify.SendNotify(message, msgType, time)
end)
