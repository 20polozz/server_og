-- ============================================================
-- ORIGEN AMBULANCEJOB — LIVE CONFIGURATION MANAGER (HOT-RELOAD)
-- ============================================================

LiveEMSConfig = {}

local staticConfig = lib.load("config") or {}
for k, v in pairs(staticConfig) do
    LiveEMSConfig[k] = v
end

function GetEMSConfigVal(key, default)
    if LiveEMSConfig[key] ~= nil then
        return LiveEMSConfig[key]
    end
    if staticConfig[key] ~= nil then
        return staticConfig[key]
    end
    return default
end

function UpdateLiveEMSConfig(newConfig)
    if not newConfig or type(newConfig) ~= "table" then return end
    for k, v in pairs(newConfig) do
        -- Si es un número en string, convertir a número para comparaciones lógicas seguras
        if type(v) == "string" and tonumber(v) ~= nil and (k == "respawnTime" or k == "waitTimeForNewCall" or k == "reviveReward" or k == "baseInjuryReward" or k == "paramedicTreatmentPrice" or k == "ambulanceStretchers" or k == "consumeItemPerUse" or k == "timeToWaitForCommand") then
            LiveEMSConfig[k] = tonumber(v)
        else
            LiveEMSConfig[k] = v
        end
    end
end

exports('GetLiveConfig', function()
    return LiveEMSConfig
end)

exports('GetConfigVal', function(key, default)
    return GetEMSConfigVal(key, default)
end)

-- Sincronización en Cliente
if not IsDuplicityVersion() then
    RegisterNetEvent("origen_ambulancejob:client:syncLiveConfig", function(newConfig)
        UpdateLiveEMSConfig(newConfig)
    end)

    RegisterNetEvent("origen_police:client:syncEmsConfig", function(newConfig)
        UpdateLiveEMSConfig(newConfig)
    end)

    local function RequestLiveConfig()
        TriggerServerEvent("origen_ambulancejob:server:requestLiveConfig")
    end

    CreateThread(function()
        Wait(500)
        RequestLiveConfig()
    end)

    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        Wait(500)
        RequestLiveConfig()
    end)

    RegisterNetEvent('esx:playerLoaded', function()
        Wait(500)
        RequestLiveConfig()
    end)
else
    -- Sincronización en Servidor
    local function FetchLatestFromPolice()
        if GetResourceState('origen_police') == 'started' then
            local ok, emsCfg = pcall(function() return exports['origen_police']:GetEmsConfig() end)
            if ok and emsCfg and type(emsCfg) == "table" and next(emsCfg) then
                UpdateLiveEMSConfig(emsCfg)
                return true
            end
        end
        return false
    end

    RegisterNetEvent("origen_ambulancejob:server:onEmsConfigUpdated", function(newConfig)
        UpdateLiveEMSConfig(newConfig)
        TriggerClientEvent("origen_ambulancejob:client:syncLiveConfig", -1, LiveEMSConfig)
    end)

    RegisterNetEvent("origen_ambulancejob:server:requestLiveConfig", function()
        local src = source
        FetchLatestFromPolice()
        TriggerClientEvent("origen_ambulancejob:client:syncLiveConfig", src, LiveEMSConfig)
    end)

    CreateThread(function()
        Wait(200)
        FetchLatestFromPolice()
    end)

    AddEventHandler('onResourceStart', function(resourceName)
        if resourceName == 'origen_police' or resourceName == GetCurrentResourceName() then
            Wait(500)
            FetchLatestFromPolice()
        end
    end)
end
