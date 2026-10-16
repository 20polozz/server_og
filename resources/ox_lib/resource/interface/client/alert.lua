--[[
    https://github.com/overextended/ox_lib

    This file is licensed under LGPL-3.0 or higher <https://www.gnu.org/licenses/lgpl-3.0.en.html>

    Copyright © 2025 Linden <https://github.com/thelindat>
]]

---@type promise?
local alert = nil
local alertId = 0

---@class AlertDialogProps
---@field header string;
---@field content string;
---@field centered? boolean?;
---@field size? 'xs' | 'sm' | 'md' | 'lg' | 'xl';
---@field overflow? boolean?;
---@field cancel? boolean?;
---@field labels? {cancel?: string, confirm?: string}

--[[ ORIGEN (07/10): el aviso con confirmar sale en org-input (el menu
     pequeño de todo el servidor, skill origen-dialogo) y no en la web de
     ox_lib. Devuelve lo mismo que ox: 'confirm' o 'cancel'.
     OJO: si se actualiza ox_lib, esto hay que volver a ponerlo. ]]

---El markdown corto que se usa en los avisos (negrita, cursiva, saltos) a HTML.
local function aHtml(md)
    md = tostring(md or '')
    md = md:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;')
    md = md:gsub('%*%*(.-)%*%*', '<b>%1</b>'):gsub('__(.-)__', '<b>%1</b>')
    md = md:gsub('%*(.-)%*', '<i>%1</i>')
    md = md:gsub('\n#+%s*', '\n'):gsub('^#+%s*', '')
    md = md:gsub('\n', '<br>')
    return md
end

---@param data AlertDialogProps
---@param timeout? number Force the window to timeout after `x` milliseconds.
---@return 'cancel' | 'confirm' | nil
function lib.alertDialog(data, timeout)
    if alert then return end

    local id = alertId + 1
    alertId = id
    alert = true

    if timeout then
        SetTimeout(timeout, function()
            if id == alertId and alert then lib.closeAlertDialog('timeout') end
        end)
    end

    local labels = data.labels or {}
    local res = exports['org-input']:ShowInput({
        header = data.header,
        icon = 'fa-solid fa-circle-exclamation',
        submitText = labels.confirm or 'Confirmar',
        inputs = { { type = 'nota', name = 'aviso', text = aHtml(data.content) } },
    })

    if id ~= alertId or not alert then return end
    alert = nil
    return res and 'confirm' or 'cancel'
end

---@param reason? string An optional reason for the window to be closed.
function lib.closeAlertDialog(reason)
    if not alert then return end
    alert = nil
    exports['org-input']:CloseInput()
end

RegisterNUICallback('closeAlert', function(_, cb) cb(1) end)

RegisterNetEvent('ox_lib:alertDialog', lib.alertDialog)
