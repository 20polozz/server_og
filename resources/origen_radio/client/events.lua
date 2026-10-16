local showing = false
wasOpened = false
radioHandProp = 0

TalkingOnRadio = {}

function ClearAllTalkingPlayers()
    for target, _ in pairs(TalkingOnRadio) do
        ToggleVoice(target, false, 'radio')
        SendNUIMessage({
            radio = "Talking",
            target = target,
            value = false
        })
    end
    TalkingOnRadio = {}
end

RegisterNetEvent("origen_radio:client:talking", function(target, value)
    if value then
        if not Radio.Enabled or Radio.Muted then return end
        if Radio.MultiFrec == "none" and Radio.Frec == 0 then return end
        TalkingOnRadio[target] = true
        ToggleVoice(target, true, 'radio')
    else
        TalkingOnRadio[target] = nil
        ToggleVoice(target, false, 'radio')
    end
    SendNUIMessage({
        radio = "Talking",
        target = target,
        value = value
    })
end)

RegisterNetEvent(Config.Framework == "qbcore" and "QBCore:Client:OnPlayerLoaded" or "esx:onPlayerSpawn", function()
    LoadPlayer()
end)

-- Harmonize with pma-voice keybinds
Citizen.CreateThread(function()
    local serverId = GetPlayerServerId(PlayerId())
    AddStateBagChangeHandler('radioPressed', 'player:' .. serverId, function(bagName, key, value, _unused, replicated)
        if value then
            StartTalkRadio()
        else
            StopTalkRadio()
        end
    end)
end)

RegisterNetEvent(Config.Framework == "qbcore" and "QBCore:Client:OnPlayerUnload" or "esx:onPlayerLogout", function()
    UnLoadPlayer()
end)

AddEventHandler('qb-ambulancejob:onplayerdeath', function(bool)
	Toggle(false)
end)

AddEventHandler('esx:onPlayerDeath', function(data)
    Toggle(false)
end)

RegisterNetEvent('esx_ambulancejob:revive', function()
    Toggle(true)
end)

RegisterNetEvent('brutal_ambulancejob:revive', function()
    Toggle(true)
end)

RegisterNetEvent('ak47_ambulancejob:revive', function()
    Toggle(true)
end)

RegisterNetEvent("wasabi_bridge:onPlayerSpawn", function()
    Toggle(true)
end)

RegisterNetEvent("origen_radio:client:TakeDropRadio", function(state)
    Toggle(state)
    if not state then 
        SendNUIMessage({
            action = "DisconnectAllFreqs"
        })
    end
end)

-- Send player citizenid to NUI
RegisterNetEvent(Config.Framework == "qbcore" and "QBCore:Client:OnPlayerLoaded" or "esx:playerLoaded", function()
    Wait(1000)
    local Player = QBCore.Functions.GetPlayerData()
    if Player and Player.citizenid then
        SendNUIMessage({
            action = "setPlayerData",
            citizenid = Player.citizenid
        })
    end
end)

RegisterNUICallback("LoadRadio", function(data, cb)
    exports["origen_radio"]:Toggle(true)
    cb({
        freclist = RadioConfig.Multifrec,
        myfrec = exports["origen_radio"]:GetMultiFrec() or "none",
        anonfrec = Radio.Frec or 0
    })
end)

RegisterNUICallback("TriggerCallback", function(data, cb)
    FW_TriggerCallback(data.name, function(retval)
        cb(retval)
    end, data)
end)

--- La interfaz avisa de que su columna esta en el DOM. Sin esto, el cliente no
--- tiene forma de saber si lo que mando llego a pintarse. Ver OpenRadio.
RegisterNUICallback("pintado", function(_, cb)
    if cb then cb({}) end
    RadioPintada = true
end)

RegisterNUICallback("focus", function(_, cb)
    --[[ Contestar aunque no haya nada que devolver: sin el `cb` la peticion de
         la NUI se queda abierta para siempre y el `await` del otro lado no
         resuelve nunca. ]]
    if cb then cb({}) end

    RadioAbierta = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    StopAnimTask(PlayerPedId(), "cellphone@", "cellphone_text_read_base", 2.0)
	ClearPedTasks(PlayerPedId())
	if radioHandProp ~= 0 then
		DeleteObject(radioHandProp)
		radioHandProp = 0
	end
end)

function separarPorGuion(cadena)
    local partes = {}
    
    for parte in string.gmatch(cadena, "[^%-]+") do
      table.insert(partes, parte)
    end
    
    return partes
  end

RegisterNetEvent("origen_radio:client:AddPlayerMultiFrec", function(id, frec, data, hasAccess, category)
    local playerData = FW_GetPlayerData()
    local citizenID = playerData.citizenid
    local identificador = separarPorGuion(category)
    local categoria = identificador[2]
    if not Config.BindFreqs[categoria] then
        Config.BindFreqs[categoria] = {}
    end

    Config.BindFreqs[id] = categoria
    Config.BindFreqs[id] = {
        categoria = categoria,
        owner = citizenID == categoria and true or false
    }
    SendNUIMessage({
        radio = "AddPlayerMultiFrec",
        id = id,
        frec = frec,
        data = data,
        i = id == GetPlayerServerId(PlayerId()),
        hasAccess = hasAccess,
        category = category
    })
end)

RegisterNetEvent("origen_radio:client:Disconnected", function()
    SendNUIMessage({
        radio = "Disconnected"
    })
    ClearAllTalkingPlayers()
end)

RegisterNetEvent("origen_radio:client:RemovePlayerMultiFrec", function(id, frec)
    Config.BindFreqs[id] = nil
    SendNUIMessage({
        radio = "RemovePlayerMultiFrec",
        id = id,
        frec = frec,
        i = id == GetPlayerServerId(PlayerId()),
    })
end)

RegisterNetEvent("origen_radio:client:SetMuted", function(id, value)
    SendNUIMessage({
        radio = "SetMuted",
        id = id,
        value = value
    })
end)

RegisterNetEvent("origen_radio:client:SetReady", function(id, value, isOwner)
    if isOwner then
        isReady = value
    end
    SendNUIMessage({
        radio = "SetReady",
        id = id,
        value = value
    })
end)

RegisterNUICallback("quickaction", function(data, cb)
    if data.action == "ToggleReady" then
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)

        if vehicle == 0 or (GetPedInVehicleSeat(vehicle, -1) ~= ped and GetPedInVehicleSeat(vehicle, 0) ~= ped) then
            TriggerServerEvent("origen_radio:server:Ready", "testCategory", data.state)
        else
            local players = {}
            for i = -1, 0 do
                local p = GetPedInVehicleSeat(vehicle, i)
                if p ~= 0 then
                    table.insert(players, GetPlayerServerId(NetworkGetPlayerIndexFromPed(p)))
                end
            end
            TriggerServerEvent("origen_radio:server:Ready", "testCategory", data.state, players)
        end
    elseif data.command then
        if type(data.command) == "table" then 
            for frm, command in pairs(data.command) do
                if frm == Config.Framework then
                    ExecuteCommand(command)
                end
            end
        else
            ExecuteCommand(data.command)
        end
    elseif data.event then
        TriggerEvent(data.event)
    elseif data.serverevent then
        TriggerServerEvent(data.serverevent)
    end
    cb(true)
end)

-- RegisterNetEvent("origen_radio:client:RecibeCategoriesData", function(data, ownerCategory, users)
--     for category, frecs in pairs(data) do
--         for frec, address in pairs(frecs) do
--             if not RadioConfig.Multifrec[category] then
--                 RadioConfig.Multifrec[category] = {}
--             end
--             RadioConfig.Multifrec[category][frec] = address
--         end
--     end
--     if ownerCategory then
--         RadioConfig.Multifrec[ownerCategory].owner = true
--     end
--     usersInCategory = users
-- end)

RegisterNUICallback("GetClosestPlayers", function(data, cb)
    local players = FW_GetPlayersFromCoords(GetEntityCoords(PlayerPedId()), 10)
    for i = 1, #players do
        players[i] = GetPlayerServerId(players[i])
    end
    FW_TriggerCallback("origen_radio:server:GetClosestPlayers", function(result)
        cb(result)
    end, players)
end)

RegisterNetEvent("origen_radio:client:KickFromMultiFrec", function(category)
    exports["origen_radio"]:SetMultiFrec(category, "none")
    SendNUIMessage({
        action = "DisconnectAllFreqs",
    })
end)

RegisterNetEvent('key-6', function()
    TriggerEvent('origen_radio:client:KickFromMultiFrec', 'none')
end)

RegisterNetEvent("origen_radio:client:AddMemberRequest", function()
    if not wasOpened then 
        TriggerEvent('key-5')
        Wait(1000)
    end
    wasOpened = true
    SendNUIMessage({
        action = "AddMemberRequest",
        IsAlreadyFocused = IsNuiFocused()
    })
    --[[ Aqui habia un SetNuiFocus(true, true). Nadie dispara este evento, y si
         llegara con la radio cerrada cogia el raton sin pantalla delante. Si
         hace falta abrirla ya lo hace 'key-5' de arriba, que coge el foco. ]]
end)

-- Old private groups events removed

RegisterNetEvent("origen_radio:client:KickedFromCategory", function(category)
    FW_Notify(Lang.notify.kicked_from_group)
    SendNUIMessage({
        action = "KickedFromCategory",
        category = category
    })
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        if radioHandProp ~= 0 then
            DeleteObject(radioHandProp)
        end
    end
end)

-- Old frequency reset event removed

RegisterNUICallback("SetVolume", function(volume)
    if type(volume) ~= "number" then return end
    if volume < 0 then volume = 0 end
    if volume > 100 then volume = 100 end
    exports["pma-voice"]:setRadioVolume(volume)
end)

RegisterNUICallback("MuteFrequency", function(data, cb)
    if data.muted then
        Radio.Muted = true
        exports["pma-voice"]:setRadioVolume(0)
    else
        Radio.Muted = false
        local volume = PlayerMetadata["radio_volume"] or 50
        exports["pma-voice"]:setRadioVolume(volume)
    end
    
    -- Notify NUI of mute status change
    SendNUIMessage({
        action = "muteStatusChanged",
        muted = data.muted
    })
    
    cb("ok")
end)

RegisterNUICallback("ConnectAnonymousRadio", function(data, cb)
    local frequency = data.frequency
    if frequency and type(frequency) == "number" then
        ClearAllTalkingPlayers()
        local radioChannel = math.floor(frequency)
        exports["pma-voice"]:setRadioChannel(radioChannel)
        Radio.Enabled = true
        Radio.Frec = radioChannel
        Radio.MultiFrec = "none"
        Radio.MultiGroup = "none"
        Radio.Targets = {}
        Radio.Clicks = true
        if not Radio.Anim then Radio.Anim = 1 end
        if RadioConfig and RadioConfig.Anims and RadioConfig.Anims[Radio.Anim] then
            RequestAnimDict(RadioConfig.Anims[Radio.Anim].Dict)
        end
        TriggerServerEvent("origen_radio:server:SetFreq", Radio.Frec)
    end
    cb({})
end)

RegisterNUICallback("DisconnectAnonymousRadio", function(data, cb)
    exports["pma-voice"]:setRadioChannel(0)
    Radio.Enabled = false
    Radio.Frec = 0
    Radio.Targets = {}
    TriggerServerEvent("origen_radio:server:SetFreq", 0)
    ClearAllTalkingPlayers()
    cb({})
end)

RegisterNUICallback("CheckCustomFrequencyExists", function(data, cb)
    FW_TriggerCallback("origen_radio:CheckCustomFrequencyExists", function(result)
        cb(result)
    end, data.frequency)
end)

-- Old category name update event removed

exports("IsPlayerTalking", function(source)
    local result = nil
    FW_TriggerCallback("origen_radio:client:IsPlayerTalking", function(ret)
        result = ret
    end, source)
    while result == nil do
        Wait(0)
    end
    return result
end)

exports("GetPlayersInFrec", function(frec)
    local result = nil
    FW_TriggerCallback("origen_radio:client:GetPlayersInFrec", function(ret)
        result = ret
    end, frec)
    while result == nil do
        Wait(0)
    end
    return result
end)