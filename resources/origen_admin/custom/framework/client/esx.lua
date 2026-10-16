if Config.Framework ~= "esx" then return end
if GetResourceState("es_extended") ~= "started" then
    while true do 
        print("^0[^5Origen Admin^0] es_extended is not started, please make sure to start origen_admin after es_extended^0")
        Wait(2000)
    end
end

Framework = exports['es_extended']:getSharedObject()
Framework.Shared = {}

Citizen.CreateThread(function()
    Framework.TriggerServerCallback("origen_admin:server:GetJobs", function(jobs)
        Framework.Shared.Jobs = jobs
    end)
    Framework.TriggerServerCallback("origen_admin:server:GetItems", function(items)
        Framework.Shared.Items = items
    end)
end)

function FW_TriggerCallback(...)
    Framework.TriggerServerCallback(...)
end

function FW_GetPlayerData()
    local Player = Framework.GetPlayerData()
    return {
        citizenid = Player.identifier,
        metadata = Player.metadata or {},
    }
end

RegisterNetEvent("esx:onPlayerSpawn", function()
    TriggerEvent("origen_admin:client:OnPlayerLoaded")
end)

Citizen.CreateThread(function()
    local Player = FW_GetPlayerData()
    if Player and Player.job and Player.job.name then 
        TriggerEvent("origen_admin:client:OnPlayerLoaded")
    end
end)