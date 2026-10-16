--[[ Puente con la interfaz.

     Dos caminos y nada mas:

       - `rpc`  : la UI pide algo al servidor. El cliente no lo interpreta, solo
                  lo reenvia. Asi no hay logica de juego duplicada en dos sitios.
       - `local`: acciones que son cosa del cliente (cerrar el telefono, sacar
                  una foto, poner un waypoint). Estas si se resuelven aqui.
]]

Nui = {}

local localHandlers = {}

--- Cuales de ellas contestan desde su propio hilo. Ver Nui.OnAsync.
local asincronas = {}

--- Registra una accion local.
---@param name string
---@param fn fun(data: table): any
function Nui.On(name, fn)
    localHandlers[name] = fn
end

--[[ Una accion que tiene que esperar al juego.

     Casi todas contestan al momento y les vale `Nui.On`. Las que no —leer la
     ruta del GPS hay que trazarla primero, y eso son fotogramas— se registran
     aqui: el cuerpo corre en su propio hilo, donde `Wait` es legal, y llama a
     `listo(loQueSea)` cuando lo tenga.

     Sin esto habria que meter el Wait dentro del pcall de la accion normal, que
     es justo donde no se debe ceder. ]]
---@param name string
---@param fn fun(params: table, listo: fun(resultado: any))
function Nui.OnAsync(name, fn)
    localHandlers[name] = fn
    asincronas[name] = true
end

--- Manda un evento a la interfaz.
---@param action string
---@param data any
function Nui.Send(action, data)
    SendNUIMessage({ action = action, data = data })
end

-- Reenvio al servidor. Devuelve tal cual { ok, data } o { ok = false, error }.
RegisterNUICallback('rpc', function(payload, cb)
    local method = payload and payload.method
    if type(method) ~= 'string' then
        cb({ ok = false, error = 'err_bad_request' })
        return
    end

    lib.callback('origen_phone:rpc', false, function(result)
        cb(result or { ok = false, error = 'err_no_response' })
    end, method, payload.params or {})
end)

-- Acciones del cliente.
RegisterNUICallback('local', function(payload, cb)
    local action = payload and payload.action
    local handler = localHandlers[action]

    if not handler then
        if Config.Debug then
            print(('^1[origen_phone] Accion local desconocida: %s^7'):format(tostring(action)))
        end
        cb({ ok = false, error = 'err_unknown_action' })
        return
    end

    --- Las que esperan al juego contestan desde su propio hilo.
    if asincronas[action] then
        CreateThread(function()
            local bien, fallo = pcall(handler, payload.params or {}, function(resultado)
                cb({ ok = true, data = resultado })
            end)

            if not bien then
                print(('^1[origen_phone] Error en la accion local "%s": %s^7'):format(action, fallo))
                cb({ ok = false, error = 'err_something_failed' })
            end
        end)
        return
    end

    local ok, result = pcall(handler, payload.params or {})
    if not ok then
        print(('^1[origen_phone] Error en la accion local "%s": %s^7'):format(action, result))
        cb({ ok = false, error = 'err_something_failed' })
        return
    end

    cb({ ok = true, data = result })
end)

-- Lo que el servidor empuja hacia la interfaz.
RegisterNetEvent('origen_phone:cl:push', function(event, data)
    -- Las llamadas y las notificaciones tienen que llegar aunque el telefono
    -- este cerrado: una suena y la otra despierta la pantalla.
    if event == 'call:incoming' then
        Calls.OnIncoming(data)
    elseif event == 'call:accepted' then
        Calls.OnAccepted(data)
    elseif event == 'call:ended' or event == 'call:taken' then
        Calls.OnEnded(data)
    elseif event == 'notification' then
        Phone.OnNotification(data)
    end

    Nui.Send('push', { event = event, payload = data })
end)
