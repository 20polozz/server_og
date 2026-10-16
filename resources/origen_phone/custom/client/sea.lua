-- ============================================================
-- ORIGEN PHONE — ALERTA S.E.A. (CLIENTE)
-- ============================================================

RegisterNetEvent('origen_phone:client:seaAlert', function(data)
    if not data then return end

    -- Reproducir sonido de alerta
    if Calls and Calls.PlayAlert then
        Calls.PlayAlert()
    end

    -- Si el teléfono está cerrado, asoma por abajo con el aviso de emergencia
    if not Phone.open then
        Nui.Send('backgroundNotification', {
            app = 'sea',
            title = data.title,
            content = data.content,
            data = {
                level = data.level,
                isBroadcast = data.isBroadcast
            },
            createdAt = GetGameTimer()
        })
    end

    -- Empujar evento hacia la interfaz para refrescar la app si está abierta
    SendNUIMessage({
        action = 'sea:alert',
        data = data
    })
    Nui.Send('push', {
        event = 'sea:alert',
        payload = data
    })
end)

RegisterNetEvent('origen_phone:client:seaHistoryUpdated', function(id)
    -- Refrescar la app SEA en el teléfono móvil si está abierta
    SendNUIMessage({
        action = 'sea:alert',
        data = { deletedId = id }
    })
    Nui.Send('push', {
        event = 'sea:alert',
        payload = { deletedId = id }
    })
end)

