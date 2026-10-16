-- ============================================================
-- ORIGEN POLICE — CLIENTE DISCORD SYNC & AGENT DATA UPDATED
-- ============================================================

RegisterNetEvent("origen_police:client:agentDataUpdated", function(data)
    if not data then return end
    SendNUIMessage({
        action = "agentDataUpdated",
        data = data
    })
end)
