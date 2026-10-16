-- ══════════════════════════════════════════════════════════════
-- ORIGEN POLICE — Cliente: Robos Pendientes
-- Recibe solicitudes de robos desde el servidor y las muestra en el tablet.
-- ══════════════════════════════════════════════════════════════

-- ─── Recibir broadcast del servidor ──────────────────────────
RegisterNetEvent('origen_police:client:robberyBroadcast')
AddEventHandler('origen_police:client:robberyBroadcast', function(action, data)
    local isDuty = onduty
    if isDuty == nil then
        local pd = (FW_GetPlayerData and FW_GetPlayerData(false)) or PlayerData
        isDuty = pd and pd.job and (pd.job.onduty == true or pd.job.onduty == 1)
    end

    if action == 'add' then
        SendNUIMessage({
            action    = 'addRobbery',
            id        = data.id,
            type      = data.type,
            location  = data.location,
            playerId  = data.playerId,
            expiresAt = data.expiresAt,
            isNew     = data.isNew,
        })
        if isDuty and data.isNew then
            TriggerEvent('origen_police:ShowNotification', 'Nueva solicitud de atraco recibida', 'info')
        end
    elseif action == 'approve' then
        -- Solicitud aceptada: mostrar con estado approved y cuenta atrás 10 min
        SendNUIMessage({
            action    = 'approveRobbery',
            id        = data.id,
            type      = data.type,
            location  = data.location,
            playerId  = data.playerId,
            expiresAt = data.expiresAt,
            isNew     = data.isNew,
        })
    elseif action == 'remove' then
        SendNUIMessage({
            action = 'removeRobbery',
            id     = data.id,
        })
    end
end)

-- pollActiveRobberies, confirmRobbery, denyRobbery, robberyTabletOpened
-- están registrados en client/menu/main.lua (junto con otros NUI callbacks del tablet)
