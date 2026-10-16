local function sanitizeHudPayload(data)
    if not data then return nil end
    return {
        territoryId = tostring(data.territoryId or ''),
        territoryName = tostring(data.territoryName or 'Territorio'),
        attackerGangId = tostring(data.attackerGangId or ''),
        attackerGangLabel = tostring(data.attackerGangLabel or 'Atacante'),
        defenderGangId = tostring(data.defenderGangId or ''),
        defenderGangLabel = tostring(data.defenderGangLabel or 'Defensor'),
        killsAttacker = tonumber(data.killsAttacker) or 0,
        killsDefender = tonumber(data.killsDefender) or 0,
        presenceAttacker = tonumber(data.presenceAttacker) or 0,
        presenceDefender = tonumber(data.presenceDefender) or 0,
        endTs = tonumber(data.endTs) or 0,
        remainingSeconds = tonumber(data.remainingSeconds) or 0,
    }
end

RegisterNetEvent('origen_gang:client:territoryWar:showHud', function(data)
    local payload = sanitizeHudPayload(data)
    if not payload then return end
    SendNUIMessage({
        action = 'war:show',
        data = payload
    })
end)

RegisterNetEvent('origen_gang:client:territoryWar:updateHud', function(data)
    local payload = sanitizeHudPayload(data)
    if not payload then return end
    SendNUIMessage({
        action = 'war:update',
        data = payload
    })
end)

RegisterNetEvent('origen_gang:client:territoryWar:hideHud', function()
    SendNUIMessage({ action = 'war:hide' })
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    SendNUIMessage({ action = 'war:hide' })
end)

