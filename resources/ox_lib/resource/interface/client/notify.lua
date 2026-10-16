--[[
    https://github.com/overextended/ox_lib

    This file is licensed under LGPL-3.0 or higher <https://www.gnu.org/licenses/lgpl-3.0.en.html>

    Copyright © 2025 Linden <https://github.com/thelindat>
]]

---@alias NotificationPosition 'top' | 'top-right' | 'top-left' | 'bottom' | 'bottom-right' | 'bottom-left' | 'center-right' | 'center-left'
---@alias NotificationType 'info' | 'warning' | 'success' | 'error'
---@alias IconAnimationType 'spin' | 'spinPulse' | 'spinReverse' | 'pulse' | 'beat' | 'fade' | 'beatFade' | 'bounce' | 'shake'

---@class NotifyProps
---@field id? string
---@field title? string
---@field description? string
---@field duration? number
---@field showDuration? boolean
---@field position? NotificationPosition
---@field type? NotificationType
---@field style? { [string]: any }
---@field icon? string | { [1]: IconProp, [2]: string }
---@field iconAnimation? IconAnimationType
---@field iconColor? string
---@field alignIcon? 'top' | 'center'
---@field sound? { bank?: string, set: string, name: string }

local settings = require 'resource.settings'

---`client`
---@param data NotifyProps
---@diagnostic disable-next-line: duplicate-set-field
function lib.notify(data)
    exports['origen_notify']:Notify({
        title = data.title,
        description = data.description,
        type = data.type or 'info',
        duration = data.duration or 5000,
        --- Lo que traiga puesto quien lo manda, para no perderlo por el camino.
        remitente = data.remitente,
        recurso = data.recurso,
    })
end

---@class DefaultNotifyProps
---@field title? string
---@field description? string
---@field duration? number
---@field position? NotificationPosition
---@field status? 'info' | 'warning' | 'success' | 'error'
---@field id? number

---@param data DefaultNotifyProps
function lib.defaultNotify(data)
    -- Backwards compat for v3
    data.type = data.status
    if data.type == 'inform' then data.type = 'info' end
    return lib.notify(data --[[@as NotifyProps]])
end

--[[ ── Los avisos que llegan del SERVIDOR ───────────────────────────────────

     Y por que no van directos a `lib.notify`.

     Cuando otro recurso llama a `lib.notify` en el cliente, ox_lib corre dentro
     de SU runtime --se carga con @ox_lib/init.lua en cada recurso--, asi que el
     `GetInvokingResource()` de origen_notify devuelve el recurso de verdad y el
     aviso sale firmado por quien es.

     Estos dos eventos son otra cosa: los registra ox_lib en su propio recurso,
     asi que todo lo que llega por aqui --que es TODO el
     `TriggerClientEvent('ox_lib:notify', ...)` del servidor: la nomina de
     qbx_core, los garajes, los negocios, el banco-- se veia como mandado por
     ox_lib. Y ox_lib esta en la lista de los que NO van al telefono, porque su
     creador de zonas habla con un admin mientras coloca cosas a mano.

     Resultado: cada aviso del lado del servidor se quedaba arriba en el medio
     en vez de llegar al movil.

     Con `recurso = 'servidor'` deja de contar como ox_lib. Quien lo mando de
     verdad no se puede saber desde aqui --el servidor dispara un evento pelado,
     ox_lib no esta en medio--, asi que lo firman las reglas de texto y, si
     ninguna encaja, la ciudad. Un recurso que quiera firmar el suyo puede
     mandar `remitente` en los datos y eso manda sobre todo lo demas. ]]
RegisterNetEvent('ox_lib:notify', function(data)
    if type(data) == 'table' then data.recurso = data.recurso or 'servidor' end
    lib.notify(data)
end)

RegisterNetEvent('ox_lib:defaultNotify', function(data)
    if type(data) == 'table' then data.recurso = data.recurso or 'servidor' end
    lib.defaultNotify(data)
end)
