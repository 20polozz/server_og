local Binds = {}

RegisterNetEvent('origen_admin:client:OnPlayerLoaded', function()
    local Player = FW_GetPlayerData()
    while not Player.citizenid do
        Citizen.Wait(1000)
        Player = FW_GetPlayerData()
    end
    TriggerServerEvent('origen_admin:server:staffHoursLoaded')
    TriggerServerEvent('origen_admin:server:syncChatSuggestion')
    Binds = Player.metadata.custom_keybind_admin or {}
end)

RegisterCommand("custom_keybind_admin", function(_, args)
    if args[1] and Binds[args[1]] then
        if not HasPermission(FastActions[Binds[args[1]]][2]) then
            return
        end
        FastActions[Binds[args[1]]][1](nil, function() end)
    end
end)

function AddKeyBind(key, action)
    RegisterKeyMapping("custom_keybind_admin " .. key, "", "keyboard", key)

    for k, v in pairs(Binds) do
        if action == v then
            Binds[k] = nil
            break
        end
    end
    Binds[key] = action

    SetPlayerConfig("custom_keybind_admin", Binds)
end

function RemoveKeyBind(act)
    for _, action in pairs(Binds) do 
        if action == act then
            Binds[_] = nil
            break
        end
    end

    SetPlayerConfig("custom_keybind_admin", Binds)
end

function SetPlayerConfig(key, value)
    TriggerServerEvent("origen_admin:server:SetMetaData", key, value)
end

function GetKeyBinds()
    return Binds
end

function SetDefaultBind(key, action)
    for k, v in pairs(Binds) do
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
