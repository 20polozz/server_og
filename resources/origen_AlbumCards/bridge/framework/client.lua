Bridge = Bridge or {}
Bridge.Framework = Bridge.Framework or {}

local function GetFrameworkType()
    if GetResourceState('qbx_core') ~= 'missing' then return 'qbx' end
    if GetResourceState('qb-core') ~= 'missing' then return 'qb' end
    if GetResourceState('es_extended') ~= 'missing' then return 'esx' end
    return 'qb'
end

local frameworkType = GetFrameworkType()

-- ============================================================
-- GLOBAL FRAMEWORK BRIDGE FUNCTIONS (CLIENT)
-- ============================================================

function origenalbumcards_NotifyClient(msg, type)
    if frameworkType == 'qbx' then
        exports.qbx_core:Notify(msg, type)
    elseif frameworkType == 'qb' then
        exports['qb-core']:GetCoreObject().Functions.Notify(msg, type)
    elseif frameworkType == 'esx' then
        exports['es_extended']:getSharedObject().ShowNotification(msg)
    end
end

local CallbackRequests = {}
local CurrentRequestId = 0

RegisterNetEvent('origen_AlbumCards:ServerCallback', function(id, ...)
    if CallbackRequests[id] then
        CallbackRequests[id](...)
        CallbackRequests[id] = nil
    end
end)

function origenalbumcards_TriggerCallback(name, cb, ...)
    CurrentRequestId = CurrentRequestId + 1
    CallbackRequests[CurrentRequestId] = cb
    TriggerServerEvent('origen_AlbumCards:TriggerCallback', name, CurrentRequestId, ...)
end

function origenalbumcards_ShowHelpText(msg, position)
    if GetResourceState('ox_lib') == 'started' then
        -- Limpiar códigos de colores de GTA para que no se vean mal en ox_lib
        local cleanMsg = msg:gsub('~%a~', '')
        exports.ox_lib:showTextUI(cleanMsg, { position = position or 'right-center' })
        return
    end

    if frameworkType == 'qb' or frameworkType == 'qbx' then
        exports['qb-core']:DrawText(msg, position or 'left')
        return
    elseif frameworkType == 'esx' then
        -- ESX doesn't have a default DrawText/TextUI, typically relies on external ones.
        -- We fallback to native for ESX if no ox_lib.
    end

    -- Fallback to Native
    AddTextEntry('origen_AlbumCards_Help', msg)
    BeginTextCommandDisplayHelp('origen_AlbumCards_Help')
    EndTextCommandDisplayHelp(0, false, true, -1)
end

function origenalbumcards_HideHelpText()
    if GetResourceState('ox_lib') == 'started' then
        exports.ox_lib:hideTextUI()
        return
    end

    if frameworkType == 'qb' or frameworkType == 'qbx' then
        exports['qb-core']:HideText()
        return
    end

    ClearAllHelpMessages()
end

-- Map internal Bridge to Global functions
Bridge.Framework.Notify = origenalbumcards_NotifyClient
Bridge.Framework.TriggerCallback = origenalbumcards_TriggerCallback
Bridge.HelpText = {
    Show = origenalbumcards_ShowHelpText,
    Hide = origenalbumcards_HideHelpText
}
