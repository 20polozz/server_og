if not Config.Debug then return end

--? STORMS DEBUG
RegisterCommand('leaveStorm', function()
    if not Storms.id then return debugger('leaveStorm: Storm not found') end
    local response = lib.callback.await('origen_gangwars:server:leaveStorm', false, Storms.id)
end)

RegisterCommand('joinStorm', function(source, args, raw)
    local id = tonumber(args[1])
    if not id then return debugger('joinStorm: Storm not found') end
    local response = lib.callback.await('origen_gangwars:server:joinStorm', false, id)
    if not response then return end
    debugger('joinStorm: Player joined the Storm')
end)

RegisterCommand('spectateStorm', function()
    local players = nil

    local players = lib.callback.await('origen_gangwars:server:debugSpectate', false)

    if not players or not next(players) then return end

    Spectate.UpdatePlayerList(players)
    Spectate.Start()
end)

--? Probar cinematicas desde la cordenada del ped
RegisterCommand('cinematic', function()
    Cinematic.Start()
end)

RegisterNetEvent('origen_gangwars:client:UseItem', function()

    --

    Nui.ToggleMenu(true)
end)