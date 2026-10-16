-- ── Client Dispatch Bridge ────────────────────────────────────────────────────
-- Handler del evento server->client para alertas de dispatch disparadas desde
-- server scripts. Usa Dispatch.SendAlert disponible via bridge/dispatch/**

RegisterNetEvent('origen_ilegalv2:client:dispatch', function(data)
    if not Dispatch or not Dispatch.SendAlert then return end
    Dispatch.SendAlert(data)
end)
