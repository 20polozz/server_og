local Binds = {}

RegisterNetEvent("origen_police:client:OnPlayerLoaded", function()
    local PlayerData = FW_GetPlayerData(true)
    while not PlayerData.citizenid do
        Wait(1000)
        PlayerData = FW_GetPlayerData(true)
    end
    Binds = PlayerData.metadata.custom_police_keybind or {}
    LoadBinds()
end)

CreateThread(function()
    local PlayerData = FW_GetPlayerData(true)
    if PlayerData and PlayerData.citizenid then
        Binds = PlayerData.metadata.custom_police_keybind or {}
        LoadBinds()
    end
end)

function LoadBinds()
    for k, v in pairs(Binds) do
        AddKeyBind(k, v)
    end
end

RegisterCommand("custom_police_keybind", function(_, args)
    if args[1] and Binds[args[1]] then
        TriggerEvent(Binds[args[1]])
    end
end)

function AddKeyBind(key, action)
    RegisterKeyMapping("custom_police_keybind " .. key, "Policía: atajo " .. key, "keyboard", key)
    if type(Binds) ~= "table" then return end
    for k, v in pairs(Binds) do
        if action == v then
            Binds[k] = nil
            break
        end
    end
    Binds[key] = action

    SetPlayerConfig("custom_police_keybind", Binds)
end

function RemoveKeyBind(key)
    Binds[key] = nil

    SetPlayerConfig("custom_police_keybind", Binds)
end

function GetKeyBinds()
    return Binds
end

function SetDefaultBind(key, action)
    if type(Binds) ~= "table" then return end
    for _, v in pairs(Binds) do
        if action == v then
            return
        end
    end
    AddKeyBind(key, action)
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