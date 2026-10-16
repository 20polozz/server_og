CurrentFrec = nil

-- Funciones
function Toggle(value)
    if value ~= nil then
        Radio.Enabled = value
    else
        Radio.Enabled = not Radio.Enabled
    end
    if not Radio.Enabled then
        TriggerEvent("origen_police:client:CloseRadioTab")
    end
    SendNUIMessage({
        action = "status",
        status = Radio.Enabled
    })
end

function SetFreq(value)
    if ClearAllTalkingPlayers then ClearAllTalkingPlayers() end
    Radio.Frec = value or 0
    TriggerServerEvent("origen_police:server:SetFreq", Radio.Frec)
    SendNUIMessage({
        action = "set_freq",
        new_freq = Radio.Frec
    })
end

function SetTargets(value)
    Radio.Targets = value or {}
end

function AddPlayerTarget(id)
    Radio.Targets[id] = true
end

function RemovePlayerTarget(id)
    Radio.Targets[id] = nil
end

function SetMultiFrec(group, value)
    if ClearAllTalkingPlayers then ClearAllTalkingPlayers() end
    if not group or group == "none" then group = Config.PoliceJobName or "police" end
    Radio.MultiGroup = group or "none"
    Radio.MultiFrec = value or "none"
    CurrentFrec = value
    Radio.Enabled = (value and value ~= "none")

    local Player = FW_GetPlayerData(true)
    local divisions = {}
    if Player and Player.metadata and Player.metadata.divisions then
        local rawDivs = Player.metadata.divisions
        if type(rawDivs) == "table" then
            for k, v in pairs(rawDivs) do
                local divId = nil
                if type(v) == "table" and (v.id or v.name) then
                    divId = tostring(v.id or v.name)
                elseif type(k) == "number" and (type(v) == "string" or type(v) == "number") then
                    divId = tostring(v)
                elseif v == true or v == 1 or v == "1" then
                    divId = tostring(k)
                end
                if divId and divId ~= "" then
                    divisions[#divisions+1] = divId
                end
            end
        end
    end
    
    TriggerServerEvent("origen_police:server:SetMultiFrec", Radio.MultiGroup, Radio.MultiFrec, {
        divisions = divisions,
    })

    if Radio.MultiFrec and Radio.MultiFrec ~= "none" then
        SendNUIMessage({
            radio = "AddPlayerMultiFrec",
            id = GetPlayerServerId(PlayerId()),
            frec = Radio.MultiFrec,
            i = true
        })
        SendNUIMessage({
            radioMenu = "AddPlayerMultiFrec",
            id = GetPlayerServerId(PlayerId()),
            frec = Radio.MultiFrec,
            i = true
        })
    else
        local myId = GetPlayerServerId(PlayerId())
        RemovePlayerMultiFrec(myId)
        SendNUIMessage({ radio = "Disconnected", id = myId })
        SendNUIMessage({ radioMenu = "Disconnected", id = myId })
    end
end

function SetMultiFrecTargets(value)
    Radio.MultiFrecTargets = value or {}
end

function AddPlayerMultiFrec(id, frec, data)
    local numId = tonumber(id)
    for _, v in pairs(Radio.MultiFrecTargets) do
        if numId and v[numId] then v[numId] = nil end
        if v[id] then v[id] = nil end
    end
    if not Radio.MultiFrecTargets[frec] then
        Radio.MultiFrecTargets[frec] = {}
    end
    Radio.MultiFrecTargets[frec][numId or id] = data or true

    local myId = GetPlayerServerId(PlayerId())
    SendNUIMessage({
        radio = "AddPlayerMultiFrec",
        id = id,
        frec = frec,
        data = data,
        i = (numId == myId)
    })
    SendNUIMessage({
        radioMenu = "AddPlayerMultiFrec",
        id = id,
        frec = frec,
        data = data,
        i = (numId == myId)
    })
end

function RemovePlayerMultiFrec(id, frec)
    local numId = tonumber(id)
    if frec and Radio.MultiFrecTargets[frec] then
        if numId then Radio.MultiFrecTargets[frec][numId] = nil end
        Radio.MultiFrecTargets[frec][id] = nil
    else
        for _, v in pairs(Radio.MultiFrecTargets) do
            if numId and v[numId] then v[numId] = nil end
            if v[id] then v[id] = nil end
        end
    end

    local myId = GetPlayerServerId(PlayerId())
    SendNUIMessage({
        radio = "RemovePlayerMultiFrec",
        id = id,
        frec = frec,
        i = (numId == myId)
    })
    SendNUIMessage({
        radioMenu = "RemovePlayerMultiFrec",
        id = id,
        frec = frec,
        i = (numId == myId)
    })
end

function MovePlayerMultiFrec(id, group, frec)
    if not id or id == "me" then
        id = GetPlayerServerId(PlayerId())
    else
        id = tonumber(id) or id
    end
    group = group or Config.PoliceJobName or "police"
    RemovePlayerMultiFrec(id)
    AddPlayerMultiFrec(id, frec)
    TriggerServerEvent("origen_police:server:moveplayer", id, group, frec)
end

function MoveMultiplePlayers(ids, group, frec)
    if type(ids) ~= "table" or #ids == 0 then return end
    group = group or Config.PoliceJobName or "police"
    local myId = GetPlayerServerId(PlayerId())
    for _, id in ipairs(ids) do
        local targetId = (id == "me") and myId or (tonumber(id) or id)
        RemovePlayerMultiFrec(targetId)
        AddPlayerMultiFrec(targetId, frec)
    end
    TriggerServerEvent("origen_police:server:movemultipleplayers", ids, group, frec)
end

function ToggleMute(value)
    if value ~= nil then
        Radio.Muted = value
    else
        Radio.Muted = not Radio.Muted
    end
    -- El mini despacho ensena un icono mientras la radio este silenciada.
    SendNUIMessage({ action = "RadioSilenciada", muted = Radio.Muted == true })
end

function SetMuted(id, value)
    for _, v in pairs(Radio.MultiFrecTargets) do
        if v[id] then
            v[id].muted = value
            break
        end
    end
end

function SetAnim(value)
    Radio.Anim = value or 1

    RequestAnimDict(RadioConfig.Anims[Radio.Anim].Dict)

    SetPlayerConfig("radio_police.anim", Radio.Anim)
end

local animradio = 1
RegisterCommand(Config.Commands.ChangeRadioAnim.cmd, function()
    animradio = animradio + 1
    if animradio > GetTableLength(RadioConfig.Anims) then
        animradio = 1
    end
    SetAnim(animradio)
end)

RegisterNUICallback("SetRadioAnim", function(data, cb)
    if not RadioConfig.Anims[data.anim] then print("INVALID RADIO ANIM, CHECK THE AMOUNT OF ANIMS IN RADIO CONFIG") return end
    SetAnim(data.anim)
    cb(true)
end)

function ToggleClicks(value)
    Radio.Clicks = value

    SetPlayerConfig("radio_police.clicks", Radio.Clicks)
end

function RadioAddKeyBind(bindType, key, action)
    if not key or not action then return end
    bindType = bindType or "keyboard"
    key = tostring(key):upper()
    action = tostring(action)

    RegisterKeyMapping("+r_police_keybind " .. key, "Radio policial: " .. action, bindType, key)

    for k, v in pairs(Radio.Binds) do
        if action == v or tostring(k):upper() == key then
            Radio.Binds[k] = nil
        end
    end
    Radio.Binds[key] = action

    SetPlayerConfig("radio_police.binds", Radio.Binds)
end

function RadioRemoveKeyBind(key)
    if not key then return end
    key = tostring(key):upper()
    Radio.Binds[key] = nil

    SetPlayerConfig("radio_police.binds", Radio.Binds)
end

-- Eventos
RegisterNetEvent("origen_police:client:Toggle", Toggle)
RegisterNetEvent("origen_police:client:SetFreq", SetFreq)
RegisterNetEvent("origen_police:client:SetTargets", SetTargets)
RegisterNetEvent("origen_police:client:AddPlayerTarget", AddPlayerTarget)
RegisterNetEvent("origen_police:client:RemovePlayerTarget", RemovePlayerTarget)
RegisterNetEvent("origen_police:client:SetMultiFrec", SetMultiFrec)
RegisterNetEvent("origen_police:client:SetMultiFrecTargets", SetMultiFrecTargets)
RegisterNetEvent("origen_police:client:AddPlayerMultiFrec", AddPlayerMultiFrec)
RegisterNetEvent("origen_police:client:RemovePlayerMultiFrec", RemovePlayerMultiFrec)
RegisterNetEvent("origen_police:client:MovePlayerMultiFrec", MovePlayerMultiFrec)
RegisterNetEvent("origen_police:client:MoveMultiplePlayers", MoveMultiplePlayers)
RegisterNetEvent("origen_police:client:SetMuted", SetMuted)
RegisterNetEvent("origen_police:client:SetAnim", SetAnim)
RegisterNetEvent("origen_police:client:ToggleClicks", ToggleClicks)
RegisterNetEvent("origen_police:client:RadioAddKeyBind", RadioAddKeyBind)
RegisterNetEvent("origen_police:client:RadioRemoveKeyBind", RadioRemoveKeyBind)

-- Exports
exports("Toggle", Toggle)
exports("SetFreq", SetFreq)
exports("SetTargets", SetTargets)
exports("AddPlayerTarget", AddPlayerTarget)
exports("RemovePlayerTarget", RemovePlayerTarget)
exports("SetMultiFrec", SetMultiFrec)
exports("SetMultiFrecTargets", SetMultiFrecTargets)
exports("AddPlayerMultiFrec", AddPlayerMultiFrec)
exports("RemovePlayerMultiFrec", RemovePlayerMultiFrec)
exports("MovePlayerMultiFrec", MovePlayerMultiFrec)
exports("MoveMultiplePlayers", MoveMultiplePlayers)
exports("SetMuted", SetMuted)
exports("SetAnim", SetAnim)
exports("ToggleClicks", ToggleClicks)
exports("RadioAddKeyBind", RadioAddKeyBind)
exports("RadioRemoveKeyBind", RadioRemoveKeyBind)
exports("GetCurrentFrequencyName", function()
    return CurrentFrec or "none"
end)

-- NUI
RegisterNUICallback("Toggle", function(data, cb)
    Toggle(table.unpack(data))
    cb(true)
end)

RegisterNUICallback("SetFreq", function(data, cb)
    SetFreq(table.unpack(data))
    cb(true)
end)

RegisterNUICallback("SetTargets", function(data, cb)
    SetTargets(table.unpack(data))
    cb(true)
end)

RegisterNUICallback("AddPlayerTarget", function(data, cb)
    AddPlayerTarget(table.unpack(data))
    cb(true)
end)

RegisterNUICallback("RemovePlayerTarget", function(data, cb)
    RemovePlayerTarget(table.unpack(data))
    cb(true)
end)

RegisterNUICallback("SetMultiFrec", function(data, cb)
    local group = (type(data) == "table" and data[1]) or nil
    local value = (type(data) == "table" and data[2]) or nil
    if not value and type(data) == "table" and data[1] then
        value = data[1]
        group = nil
    end
    SetMultiFrec(group, value)
    cb(true)
end)

RegisterNUICallback("SetMultiFrecTargets", function(data, cb)
    SetMultiFrecTargets(table.unpack(data))
    cb(true)
end)

RegisterNUICallback("AddPlayerMultiFrec", function(data, cb)
    AddPlayerMultiFrec(table.unpack(data))
    cb(true)
end)

RegisterNUICallback("RemovePlayerMultiFrec", function(data, cb)
    RemovePlayerMultiFrec(table.unpack(data))
    cb(true)
end)

RegisterNUICallback("MovePlayerMultiFrec", function(data, cb)
    local id = type(data) == "table" and (data.id or data[1]) or nil
    local group = type(data) == "table" and (data.group or data[2]) or Config.PoliceJobName or "police"
    local frec = type(data) == "table" and (data.frec or data.multifrec or data[3]) or nil
    if id and frec then
        MovePlayerMultiFrec(id, group, frec)
    end
    cb(true)
end)

RegisterNUICallback("MoveMultiplePlayers", function(data, cb)
    local ids = type(data) == "table" and (data.ids or data[1]) or nil
    local group = type(data) == "table" and (data.group or data[2]) or Config.PoliceJobName or "police"
    local frec = type(data) == "table" and (data.frec or data.multifrec or data[3]) or nil
    if ids and type(ids) == "table" and #ids > 0 and frec then
        MoveMultiplePlayers(ids, group, frec)
    end
    cb(true)
end)

RegisterNUICallback("SetMuted", function(data, cb)
    SetMuted(table.unpack(data))
    cb(true)
end)

RegisterNUICallback("SetAnim", function(data, cb)
    SetAnim(table.unpack(data))
    cb(true)
end)

RegisterNUICallback("ToggleClicks", function(data, cb)
    ToggleClicks(table.unpack(data))
    cb(true)
end)

RegisterNUICallback("RadioAddKeyBind", function(data, cb)
    local bindType = "keyboard"
    local key = nil
    local action = nil

    if type(data) == "table" then
        bindType = data.type or data[1] or "keyboard"
        key = data.key or data[2]
        action = data.action or data[3]
    end

    if key and action then
        RadioAddKeyBind(bindType, key, action)
    end
    cb(true)
end)

RegisterNUICallback("RadioRemoveKeyBind", function(data, cb)
    local key = nil
    if type(data) == "table" then
        key = data.key or data[1]
    elseif type(data) == "string" then
        key = data
    end

    if key then
        RadioRemoveKeyBind(key)
    end
    cb(true)
end)

-- Gets
exports("GetMultiFrec", function()
    return (Radio.MultiFrec and Radio.MultiFrec ~= "none" and Radio.MultiFrec) or (CurrentFrec and CurrentFrec ~= "none" and CurrentFrec) or "none"
end)

RegisterNUICallback("GetBinds", function(data, cb)
    cb(Radio.Binds or {})
end)

function DisconnectAllRadio()
    -- 1. Detener habla y animaciones/props si estaba hablando
    if StopTalkRadio then
        StopTalkRadio()
    end

    -- 2. Salir de multifrecuencia
    if SetMultiFrec then
        SetMultiFrec(nil, "none")
    end

    -- 3. Salir de frecuencia anónima / general
    if SetFreq then
        SetFreq(0)
    end

    -- 4. Notificar servidor de radio
    TriggerServerEvent("origen_police:server:SetMultiFrec", "none", "none")
    TriggerServerEvent("origen_police:server:SetFreq", 0)

    -- 5. Desconectar pma-voice si existe
    if GetResourceState("pma-voice") == "started" then
        pcall(function() exports['pma-voice']:setRadioChannel(0) end)
        pcall(function() exports['pma-voice']:removePlayerFromRadio() end)
    end

    -- 6. Desconectar saltychat si existe
    if GetResourceState("saltychat") == "started" then
        pcall(function() exports['saltychat']:SetRadioChanel('', true) end)
    end

    -- 7. Resetear state bag de radio
    if LocalPlayer and LocalPlayer.state then
        LocalPlayer.state:set('radioChannel', 0, true)
    end

    -- 8. Actualizar NUI y estado local
    Radio.Enabled = false
    Radio.MultiFrec = "none"
    Radio.MultiGroup = "none"
    Radio.Frec = 0
    CurrentFrec = nil
    local myId = GetPlayerServerId(PlayerId())
    RemovePlayerMultiFrec(myId)

    SendNUIMessage({ action = "DisconnectAllFreqs" })
    SendNUIMessage({ action = "Disconnected" })
    SendNUIMessage({ radio = "Disconnected", id = myId })
    SendNUIMessage({ radioMenu = "Disconnected", id = myId })
    SendNUIMessage({ action = "set_freq", new_freq = 0 })
    SendNUIMessage({ action = "status", status = false })

    TriggerEvent("origen_police:client:Disconnected")
    TriggerEvent("origen_police:client:TakeDropRadio", false)
    TriggerEvent("origen_police:client:CloseRadioTab")
end
exports("DisconnectAllRadio", DisconnectAllRadio)
RegisterNetEvent("origen_police:client:forceDisconnectRadio", DisconnectAllRadio)