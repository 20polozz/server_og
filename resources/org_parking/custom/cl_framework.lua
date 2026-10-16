-- ═══════════════════════════════════════════════════════════════════════════
--  ORG Parking — Client Framework Bridge
--  ► This file is NOT encrypted. Edit it to match your server setup.
-- ═══════════════════════════════════════════════════════════════════════════

Framework = Framework or {}

-- ─────────────────────────────────────────────────────────────────────────────
--  GetLocalIdentifier()
--  Returns the current player's unique identifier.
-- ─────────────────────────────────────────────────────────────────────────────
function Framework.GetLocalIdentifier()
    if Config.Framework == 'qbx' or Config.Framework == 'qb' then
        local ok, p = pcall(function() return exports.qbx_core:GetPlayerData() end)
        return (ok and p) and p.citizenid or nil

    elseif Config.Framework == 'esx' then
        local ok, p = pcall(function() return exports['es_extended']:GetPlayerData() end)
        return (ok and p) and p.identifier or nil

    elseif Config.Framework == 'custom' then
        -- ► Edit here:
        return nil
    end

    return nil
end

-- ─────────────────────────────────────────────────────────────────────────────
--  OnPlayerLoaded(callback)
--  Registers a callback that fires when the local player is fully loaded.
--  callback() receives no arguments.
-- ─────────────────────────────────────────────────────────────────────────────
-- ─────────────────────────────────────────────────────────────────────────────
--  NotifyClient(message, notifyType)
--  Shows a notification to the local player.
--  notifyType: 'success' | 'error' | 'info' | 'warning'
-- ─────────────────────────────────────────────────────────────────────────────
function Framework.NotifyClient(message, notifyType)
    notifyType = notifyType or 'info'
    if Config.NotifySystem == 'ox_lib' then
        lib.notify({ description = message, type = notifyType })

    elseif Config.NotifySystem == 'qbx' or Config.NotifySystem == 'qb' then
        local ok, core = pcall(function() return exports['qbx_core']:GetCoreObject() end)
        if not ok then ok, core = pcall(function() return exports['qb-core']:GetCoreObject() end) end
        if ok and core then core.Functions.Notify(message, notifyType) end

    elseif Config.NotifySystem == 'esx' then
        local ok, esx = pcall(function() return exports['es_extended']:getSharedObject() end)
        if ok and esx then esx.ShowNotification(message) end

    elseif Config.NotifySystem == 'chat' then
        TriggerEvent('chat:addMessage', { args = { '[Parking]', message } })

    elseif Config.NotifySystem == 'custom' then
        -- ► Edit here:
    end
end

function Framework.OnPlayerLoaded(callback)
    if Config.Framework == 'qbx' or Config.Framework == 'qb' then
        AddEventHandler('QBCore:Client:OnPlayerLoaded', callback)
        -- Also fire immediately if already loaded
        local ok, p = pcall(function() return exports.qbx_core:GetPlayerData() end)
        if ok and p and p.citizenid then
            CreateThread(function() Wait(100); callback() end)
        end

    elseif Config.Framework == 'esx' then
        AddEventHandler('esx:playerLoaded', callback)

    elseif Config.Framework == 'custom' then
        -- ► Edit here:
        -- AddEventHandler('your_framework:playerLoaded', callback)
    end
end
