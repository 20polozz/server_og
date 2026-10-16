function SetPlayerConfig(key, value)
    TriggerServerEvent("origen_radio:SetMetaData", key, value)
end

RegisterNetEvent(Config.Framework == "qbcore" and "QBCore:Client:OnPlayerLoaded" or "esx:onPlayerSpawn", function()
    local PlayerData = FW_GetPlayerData()
    while not PlayerData.citizenid do
        Citizen.Wait(1000)
        PlayerData = FW_GetPlayerData()
    end
    Radio.Binds = PlayerData.metadata.radio_keybind or {}
end)

Citizen.CreateThread(function()
    local PlayerData = FW_GetPlayerData()
    if PlayerData and PlayerData.citizenid then
        Radio.Binds = PlayerData.metadata.radio_keybind or {}
    end
end)


RegisterCommand("radio_keybind", function(_, args)
    if args[1] and Radio.Binds[args[1]] then
        TriggerEvent(Radio.Binds[args[1]])
    end
end)

function AddKeyBind(key, action, name)
    RegisterKeyMapping("radio_keybind " .. key, "Radio: atajo " .. key, "keyboard", key)
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

function RemoveKeyBind(key)
    Radio.Binds[key] = nil
    PlayerMetadata["radio_keybind"] = Radio.Binds
    SetPlayerConfig("radio_keybind", Radio.Binds)
end

function GetKeyBinds()
    return Radio.Binds
end

function SetDefaultBind(key, action)
    for k, v in pairs(Radio.Binds) do
        if action == v then
            return
        end
    end
    AddKeyBind(key, action, name)
end

exports("AddKeyBind", AddKeyBind)
exports("SetDefaultBind", SetDefaultBind)
exports("RemoveKeyBind", RemoveKeyBind)
exports("GetKeyBinds", GetKeyBinds)

RegisterNetEvent("AddKeyBind", AddKeyBind)
RegisterNetEvent("SetDefaultBind", SetDefaultBind)
RegisterNetEvent("RemoveKeyBind", RemoveKeyBind)
RegisterNetEvent("GetKeyBinds", function(cb)
    cb(GetKeyBinds())
end)

RegisterNUICallback("AddKeyBind", function(data, cb)
    AddKeyBind(table.unpack(data))
    cb(true)
end)

RegisterNUICallback("SetDefaultBind", function(data, cb)
    SetDefaultBind(table.unpack(data))
    cb(true)
end)

RegisterNUICallback("RemoveKeyBind", function(data, cb)
    RemoveKeyBind(table.unpack(data))
    cb(true)
end)

RegisterNUICallback("GetKeyBinds", function(data, cb)
    cb(GetKeyBinds())
end)