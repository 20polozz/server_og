RegisterNUICallback('GetAdminLogs', function(data, cb)
    FW_TriggerCallback('origen_admin:server:GetAdminLogs', function(result)
        cb(result)
    end)
end)

local deathLogCooldown = 0

AddEventHandler('gameEventTriggered', function(event, data)
    if event ~= 'CEventNetworkEntityDamage' then return end
    local victim, attacker, victimDied, weapon = data[1], data[2], data[4], data[7]
    
    if not IsEntityAPed(victim) or not victimDied then return end
    
    -- Verify this is referring to the local player being the victim
    if NetworkGetPlayerIndexFromPed(victim) ~= PlayerId() then return end
    
    -- Verify if they actually died, to prevent false positives from fatalDamage trigger
    if not IsEntityDead(victim) then return end
    
    if GetGameTimer() - deathLogCooldown < 5000 then return end
    deathLogCooldown = GetGameTimer()
    
    local isKilledByAnother = false
    local killerId = -1
    local killerVehName = nil

    if attacker and attacker ~= -1 and attacker ~= 0 and attacker ~= victim then
        if IsEntityAPed(attacker) and IsPedAPlayer(attacker) then
            killerId = NetworkGetPlayerIndexFromPed(attacker)
            isKilledByAnother = true
        elseif IsEntityAVehicle(attacker) then
            local driver = GetPedInVehicleSeat(attacker, -1)
            if IsEntityAPed(driver) and IsPedAPlayer(driver) then
                killerId = NetworkGetPlayerIndexFromPed(driver)
                killerVehName = GetDisplayNameFromVehicleModel(GetEntityModel(attacker))
                isKilledByAnother = true
            end
        end
    end

    local victimName = GetPlayerName(PlayerId())
    
    if isKilledByAnother and killerId ~= -1 then
        local serverKillerId = GetPlayerServerId(killerId)
        local killerName = GetPlayerName(killerId) or "Desconocido"
        
        local weaponHashStr = weapon and tostring(weapon) or "Desconocida"
        local weaponName = "Desconocido"
        pcall(function()
            local WEAPONS = exports.qbx_core:GetWeapons()
            if WEAPONS and WEAPONS[weapon] then
                weaponName = WEAPONS[weapon].label .. " (" .. WEAPONS[weapon].name .. ")"
            end
        end)
        
        if weaponName ~= "Desconocido" then
            weaponHashStr = weaponName
        end
        
        local txt = string.format("**%s** fue asesinado por **%s** (ID: %s).", victimName, killerName, tostring(serverKillerId))
        txt = txt .. string.format("\nArma utilizada: **%s**", weaponHashStr)
        
        if killerVehName then
            txt = txt .. string.format("\nEl asesino estaba en un vehículo: **%s**", killerVehName)
        end
        
        TriggerServerEvent('origen_admin:server:logDeath', 'killed', txt, serverKillerId)
    else
        local txt = string.format("**%s** ha muerto.", victimName)
        TriggerServerEvent('origen_admin:server:logDeath', 'died', txt)
    end
end)
