deathlogics = {}

local killedHandle = nil
local diedHandle = nil

deathlogics.RegisterHandler = function()
    killedHandle = AddEventHandler('gameEventTriggered', function(event, data)
        if event == 'CEventNetworkEntityDamage' then
            local victim, attacker, victimDied, weapon = data[1], data[2], data[4], data[7]
    
            if not IsEntityAPed(victim) then return end
            if victimDied and NetworkGetPlayerIndexFromPed(victim) == PlayerId() and IsEntityDead(PlayerPed) then
                TriggerServerEvent('origen_gangwars:server:onPlayerDeath')
                local pos = GetEntityCoords(PlayerPed)
                local heading = GetEntityHeading(PlayerPed)
                NetworkResurrectLocalPlayer(pos.x, pos.y, pos.z + 0.5, heading, true, false)

                local players = GlobalState['orgStorms_' .. Storms.id .. '_players']
                if not players then
                    return
                end

                Spectate.UpdatePlayerList(players)

                local attackerSrc = GetPlayerServerId(NetworkGetEntityOwner(attacker))
                if attackerSrc then
                    Spectate.Start(attackerSrc)
                else
                    if not Storms.id then return debugger('leaveStorm: Storm not found') end
                    local response = lib.callback.await('origen_gangwars:server:leaveStorm', false, Storms.id)
                end
            end
        end
    end)
end

deathlogics.UnregisterHandler = function()
    if killedHandle then
        RemoveEventHandler(killedHandle)
        killedHandle = nil
    end
end