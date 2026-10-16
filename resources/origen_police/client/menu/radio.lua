RegisterNetEvent("origen_police:client:AddPlayerMultiFrec", function(id, frec, data)
    SendNUIMessage({
        radioMenu = "AddPlayerMultiFrec",
        id = id,
        frec = frec,
        data = data,
        i = id == GetPlayerServerId(PlayerId())
    })
end)

RegisterNetEvent("origen_police:client:Disconnected", function()
    SendNUIMessage({
        radioMenu = "Disconnected"
    })
end)

RegisterNetEvent("origen_police:client:talking", function(target, value)
    SendNUIMessage({
        radioMenu = "Talking",
        target = target,
        value = value
    })
end)

RegisterNetEvent("origen_police:client:RemovePlayerMultiFrec", function(id, frec)
    SendNUIMessage({
        radioMenu = "RemovePlayerMultiFrec",
        id = id,
        frec = frec
    })
end)

RegisterNetEvent("origen_police:client:SetMuted", function(id, value)
    SendNUIMessage({
        radioMenu = "SetMuted",
        id = id,
        value = value
    })
end)

RegisterNetEvent("origen_police:client:SetReady", function(id, value)
    SendNUIMessage({
        radioMenu = "SetReady",
        id = id,
        value = value
    })
end)

local function RebuildClientBindFreqs()
    Config.BindFreqs = {}
    if not Config.BindFreqsOrdered then return end

    for _, bind in ipairs(Config.BindFreqsOrdered) do
        local sanitized = {}
        for _, f in ipairs(bind.freqs or {}) do
            if type(f) == "string" then
                table.insert(sanitized, f)
            end
        end
        bind.freqs = sanitized

        local expanded = {}
        for _, freq in ipairs(sanitized) do
            if Config.Multifrec and Config.Multifrec[freq] then
                for _, freq2 in ipairs(Config.Multifrec[freq]) do
                    table.insert(expanded, freq2)
                end
            else
                table.insert(expanded, freq)
            end
        end
        Config.BindFreqs[bind.label] = expanded
    end
end

RegisterNetEvent("origen_police:admin:radioBindsUpdated", function(bindsOrdered)
    if bindsOrdered then
        Config.BindFreqsOrdered = bindsOrdered
    end
    RebuildClientBindFreqs()
    SendNUIMessage({
        action = "adminRadioBindsUpdated",
        binds = Config.BindFreqsOrdered
    })
    SendNUIMessage({
        action = "radioBindsUpdated",
        binds = Config.BindFreqsOrdered
    })
end)

RegisterNetEvent("origen_police:client:OnPlayerLoaded", function()
    TriggerServerEvent("origen_police:admin:requestRadioBindsSync")
end)

CreateThread(function()
    Wait(2000)
    RebuildClientBindFreqs()
    TriggerServerEvent("origen_police:admin:requestRadioBindsSync")
end)

RegisterNUICallback("LoadFrecList", function(data, cb)
    cb({freq = exports["origen_police"]:GetPoliceRadioChannels(), buttons = exports["origen_police"]:GetPoliceRadioButtons()})
end)

RegisterNUICallback("LoadRadioBinds", function(data, cb)
    cb({binds = exports["origen_police"]:GetPoliceRadioBinds()})
end)