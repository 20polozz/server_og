PlayerMetadata = {}

-- Funciones
function Toggle(value)
    if value ~= nil then
        Radio.Enabled = value
    else
        Radio.Enabled = not Radio.Enabled
    end
    if not Radio.Enabled then
        TriggerEvent("origen_radio_menu:client:CloseRadioTab")
    end
    SendNUIMessage({
        action = "status",
        status = Radio.Enabled
    })
end

function SetFreq(value)
    if ClearAllTalkingPlayers then ClearAllTalkingPlayers() end
    Radio.Frec = value or 0
    TriggerServerEvent("origen_radio:server:SetFreq", Radio.Frec)
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

function SetMultiFrec(group, value, reason)
    if ClearAllTalkingPlayers then ClearAllTalkingPlayers() end
    if group ~= "none" and value ~= "none" then
        TriggerEvent('origen_radio:client:ConnectingToPrivate')
    end
    
    Radio.MultiGroup = group or "none"
    Radio.MultiFrec = value or "none"
    TriggerServerEvent("origen_radio:server:SetMultiFrec", Radio.MultiGroup, Radio.MultiFrec, reason)
end

function SetMultiFrecTargets(value)
    Radio.MultiFrecTargets = value or {}
end

function AddPlayerMultiFrec(id, frec, data)
    for k, v in pairs(Radio.MultiFrecTargets) do
        if v[id] then
            v[id] = nil
            break
        end
    end
    if not Radio.MultiFrecTargets[frec] then
        Radio.MultiFrecTargets[frec] = {}
    end
    Radio.MultiFrecTargets[frec][id] = data or true
end

function RemovePlayerMultiFrec(id, frec)
    if frec and Radio.MultiFrecTargets[frec] then
        Radio.MultiFrecTargets[frec][id] = nil
    else
        for k, v in pairs(Radio.MultiFrecTargets) do
            if v[id] then
                v[id] = nil
                break
            end
        end
    end
end

function MovePlayerMultiFrec(id, group, frec)
    id = tonumber(id)
    RemovePlayerMultiFrec(id)
    AddPlayerMultiFrec(id, frec)
    TriggerServerEvent("origen_radio:server:moveplayer", id, group, frec)
end

function ToggleMute(value)
    Radio.Muted = (value ~= nil) and value or (not Radio.Muted)
end

function SetMuted(id, value)
    for k, v in pairs(Radio.MultiFrecTargets) do
        if v[id] then
            v[id].muted = value
            break
        end
    end
end

RegisterNetEvent("origen_metadata:client:metadataLoaded", function(metadata)
    if not metadata then return end
    LoadAnim(metadata)
    PlayerMetadata = metadata
    
    -- Ensure citizenid is in metadata
    local PlayerData = FW_GetPlayerData()
    if PlayerData and PlayerData.citizenid and not PlayerMetadata.citizenid then
        PlayerMetadata.citizenid = PlayerData.citizenid
    end
end)

RegisterNUICallback("GetPlayerMetadata", function(data, cb)
    -- Ensure citizenid is always included
    if not PlayerMetadata.citizenid then
        local PlayerData = FW_GetPlayerData()
        if PlayerData and PlayerData.citizenid then
            PlayerMetadata.citizenid = PlayerData.citizenid
        end
    end
    local PlayerData = FW_GetPlayerData()
    if PlayerData and PlayerData.metadata then
        if PlayerData.metadata["radio_clicks"] then
            Radio.Clicks = PlayerData.metadata["radio_clicks"]
        end
        if PlayerData.metadata["radio_keybind"] then
            Radio.Binds = PlayerData.metadata["radio_keybind"]
        end
    end
    cb(PlayerMetadata)
end)

function LoadAnim(data)
    if data and data["radio_anim"] then
        SetAnim(data["radio_anim"])
    end
    if animLoaded then return end
    animLoaded = true
end

function SetAnim(value, notify)
    value = tonumber(value)
    Radio.Anim = value or 1
    PlayerMetadata["radio_anim"] = Radio.Anim
    local animData = RadioConfig.Anims[Radio.Anim]
    if not animData then 
        Radio.Anim = 1
        animData = RadioConfig.Anims[Radio.Anim]
    end
    local animDict = animData.Dict
    
    Citizen.CreateThread(function()
        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do
            Citizen.Wait(10)
        end
        
        SetPlayerConfig("radio_anim", Radio.Anim)
        if not notify then return end
        FW_Notify(Lang.notify.anim_changed)
    end)
end

function ToggleClicks(value)
    Radio.Clicks = value
    PlayerMetadata["radio_clicks"] = Radio.Clicks
    SetPlayerConfig("radio_clicks", Radio.Clicks)
end

RegisterNetEvent('key-2', function()
    ToggleMute()
    TriggerServerEvent("origen_radio:server:Mute", Radio.MultiGroup, Radio.Muted)
end)

function RadioAddKeyBind(_type, key, action)
    if not Config.BindSystem then return end
    RegisterKeyMapping("+r_keybind_radio " .. key, "Radio: atajo " .. tostring(key), _type, key)

    for k, v in pairs(Radio.Binds) do
        if action == v then
            Radio.Binds[k] = nil
            break
        end
    end
    Radio.Binds[key] = action
    PlayerMetadata["radio_keybind"] = Radio.Binds
    SetPlayerConfig("radio_keybind", Radio.Binds)
end

function RadioRemoveKeyBind(key)
    Radio.Binds[key] = nil
    PlayerMetadata["radio.binds"] = Radio.Binds
    SetPlayerConfig("radio.binds", Radio.Binds)
end

-- Eventos
RegisterNetEvent("origen_radio:client:Toggle", Toggle)
RegisterNetEvent("origen_radio:client:SetFreq", SetFreq)
RegisterNetEvent("origen_radio:client:SetTargets", SetTargets)
RegisterNetEvent("origen_radio:client:AddPlayerTarget", AddPlayerTarget)
RegisterNetEvent("origen_radio:client:RemovePlayerTarget", RemovePlayerTarget)
RegisterNetEvent("origen_radio:client:SetMultiFrec", SetMultiFrec)
RegisterNetEvent("origen_radio:client:SetMultiFrecTargets", SetMultiFrecTargets)
RegisterNetEvent("origen_radio:client:AddPlayerMultiFrec", AddPlayerMultiFrec)
RegisterNetEvent("origen_radio:client:RemovePlayerMultiFrec", RemovePlayerMultiFrec)
RegisterNetEvent("origen_radio:client:MovePlayerMultiFrec", MovePlayerMultiFrec)
RegisterNetEvent("origen_radio:client:SetMuted", SetMuted)
RegisterNetEvent("origen_radio:client:SetAnim", SetAnim)
RegisterNetEvent("origen_radio:client:ToggleClicks", ToggleClicks)
RegisterNetEvent("origen_radio:client:RadioAddKeyBind", RadioAddKeyBind)
RegisterNetEvent("origen_radio:client:RadioRemoveKeyBind", RadioRemoveKeyBind)

-- Exports
exports("Toggle", Toggle)
exports("SetFreq", SetFreq)
exports("GetRadio", function() return Radio end)
exports("SetTargets", SetTargets)
exports("AddPlayerTarget", AddPlayerTarget)
exports("RemovePlayerTarget", RemovePlayerTarget)
exports("SetMultiFrec", SetMultiFrec)
exports("SetMultiFrecTargets", SetMultiFrecTargets)
exports("AddPlayerMultiFrec", AddPlayerMultiFrec)
exports("RemovePlayerMultiFrec", RemovePlayerMultiFrec)
exports("MovePlayerMultiFrec", MovePlayerMultiFrec)
exports("SetMuted", SetMuted)
exports("SetAnim", SetAnim)
exports("ToggleClicks", ToggleClicks)
exports("RadioAddKeyBind", RadioAddKeyBind)
exports("RadioRemoveKeyBind", RadioRemoveKeyBind)

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
    SetMultiFrec(table.unpack(data))
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
    MovePlayerMultiFrec(table.unpack(data))
    cb(true)
end)

RegisterNUICallback("SetMuted", function(data, cb)
    SetMuted(table.unpack(data))
    cb(true)
end)

RegisterNUICallback("SetAnim", function(data, cb)
    SetAnim(table.unpack(data), true)
    cb(true)
end)

RegisterNUICallback("ToggleClicks", function(data, cb)
    ToggleClicks(table.unpack(data))
    cb(true)
end)

RegisterNUICallback("RadioAddKeyBind", function(data, cb)
    RadioAddKeyBind(table.unpack(data))
    cb(true)
end)

RegisterNUICallback("RadioRemoveKeyBind", function(data, cb)
    RadioRemoveKeyBind(table.unpack(data))
    cb(true)
end)

-- Gets
exports("GetMultiFrec", function()
    return Radio.MultiFrec
end)

RegisterNUICallback("GetBinds", function(data, cb)
    cb(Radio.Binds)
end)