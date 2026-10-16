local positionConfig = require 'config.shared'.notifyPosition

---Text box popup for player which dissappears after a set time.
---@param text table|string text of the notification
---@param notifyType? NotificationType informs default styling. Defaults to 'inform'
---@param duration? integer milliseconds notification will remain on screen. Defaults to 5000
---@param subTitle? string extra text under the title
---@param notifyPosition? NotificationPosition
---@param notifyStyle? table Custom styling. Please refer too https://overextended.dev/ox_lib/Modules/Interface/Client/notify#libnotify
---@param notifyIcon? string Font Awesome 6 icon name
---@param notifyIconColor? string Custom color for the icon chosen before
function Notify(text, notifyType, duration, subTitle, notifyPosition, notifyStyle, notifyIcon, notifyIconColor)
    local title, description
    if type(text) == 'table' then
        title = text.text or 'Placeholder'
        description = text.caption or nil
    elseif subTitle then
        title = text
        description = subTitle
    else
        description = text
    end

    --[[ Y de parte de QUIEN, que si no se pierde por el camino.

         `origen_notify` firma cada aviso mirando quien lo manda: la pulsera, el
         banco, la central de tu trabajo. Para saberlo usa `GetInvokingResource`,
         que dice quien ha llamado al export... y quien llama a `origen_notify`
         desde aqui es qbx_core, no el recurso de verdad.

         Son ciento catorce avisos —los negocios, las llaves, el taller, el
         cinturon— que se quedaban sin remitente y salian todos firmados por la
         ciudad. Se lee aqui, donde `GetInvokingResource` todavia dice la
         verdad, y se pasa puesto. ]]
    exports.origen_notify:Notify({
        title = title,
        description = description,
        type = notifyType,
        duration = duration,
        recurso = GetInvokingResource(),
    })
end

exports('Notify', Notify)

---@return PlayerData? playerData
function GetPlayerData()
    return QBX.PlayerData
end

exports('GetPlayerData', GetPlayerData)

---@param filter string | string[] | table<string, number>
---@return boolean
function HasPrimaryGroup(filter)
    return HasPlayerGotGroup(filter, QBX.PlayerData, true)
end

exports('HasPrimaryGroup', HasPrimaryGroup)

---@param filter string | string[] | table<string, number>
---@return boolean
function HasGroup(filter)
    return HasPlayerGotGroup(filter, QBX.PlayerData)
end

exports('HasGroup', HasGroup)

---@return table<string, integer>
function GetGroups()
    local playerData = QBX.PlayerData
    return GetPlayerGroups(playerData)
end

exports('GetGroups', GetGroups)