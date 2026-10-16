Mousetrap = Mousetrap or {}

function Mousetrap.Notify(message, type, duration)
    local notifType = type or 'error'
    local notifDuration = duration or 5000
    
    local system = Config.NotificationSystem
    
    if system == 'esx' then
        local ESX = exports['es_extended']:getSharedObject()
        if ESX then
            ESX.ShowNotification(message)
        end
        
    elseif system == 'qbcore' then
        local QBCore = exports['qb-core']:GetCoreObject()
        if QBCore then
            QBCore.Functions.Notify(message, notifType, notifDuration)
        end
        
    elseif system == 'qbox' then
        exports.qbx_core:Notify(message, notifType, notifDuration)
    end
end
