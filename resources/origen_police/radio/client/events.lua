TalkingOnRadio = {}

function ClearAllTalkingPlayers()
    for target, _ in pairs(TalkingOnRadio) do
        ToggleVoice(target, false, 'radio')
        SendNUIMessage({
            radio = "Talking",
            target = target,
            value = false
        })
        SendNUIMessage({
            radioMenu = "Talking",
            target = target,
            value = false
        })
    end
    TalkingOnRadio = {}
end

RegisterNetEvent("origen_police:client:talking", function(target, value)
    if value then
        if (not Radio.Enabled and Radio.MultiFrec == "none") or Radio.Muted then return end
        TalkingOnRadio[target] = true
        ToggleVoice(target, true, 'radio')
    else
        TalkingOnRadio[target] = nil
        ToggleVoice(target, false, 'radio')
    end
end)

RegisterNetEvent("origen_police:client:OnPlayerLoaded", function()
    LoadPlayer()
end)

RegisterNetEvent('origen_police:client:OnPlayerUnload', function()
    UnLoadPlayer()
end)

RegisterNetEvent('qb-ambulancejob:onplayerdeath', function(bool)
	Toggle(false)
end)

RegisterNetEvent('esx:onPlayerDeath', function(data)
    Toggle(false)
end)

RegisterNetEvent('esx_ambulancejob:revive', function()
    Toggle(true)
end)

RegisterNetEvent("origen_police:client:TakeDropRadio", function(state)
    if not state then
        Toggle(false)
        SendNUIMessage({
            action = "DisconnectAllFreqs"
        })
        if ClearAllTalkingPlayers then ClearAllTalkingPlayers() end
    end
end)

RegisterNetEvent("origen_police:client:Disconnected", function()
    if ClearAllTalkingPlayers then ClearAllTalkingPlayers() end
end)
