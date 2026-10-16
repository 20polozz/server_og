--[[ ── Mandar la imagen al servidor ─────────────────────────────────────

     Los bytes no caben en un evento normal (ver el comentario largo del
     server.lua). Van por un evento LATENTE, que los manda a un ritmo fijo sin
     bloquear el canal, y el servidor los guarda un minuto con un resguardo.
     Quien quiera subirlos despues solo tiene que enseñar ese resguardo.

     Esta funcion espera a que el servidor confirme que los tiene. Se llama
     desde dentro de un callback de NUI, que ya es una corrutina, asi que
     puede esperar sin bloquear el juego. ]]
local respuestas = {}
local contador = 0

-- 256 KB por segundo: un logo de 1 MB tarda unos cuatro segundos y no se nota
-- en el resto del trafico del jugador.
local RITMO = 256000

RegisterNetEvent('origen_uploader:cl:preparada', function(resguardo, ok, mensaje)
    respuestas[resguardo] = { ok = ok, mensaje = mensaje }
end)

--- Deja la imagen esperando en el servidor.
--- @return string|nil resguardo, string|nil motivo del fallo
local function PrepararSubida(nombre, base64)
    if type(base64) ~= 'string' or #base64 == 0 then
        return nil, 'No llegó la imagen.'
    end

    contador = contador + 1
    local resguardo = ('%d-%d'):format(GetGameTimer(), contador)
    respuestas[resguardo] = nil

    TriggerLatentServerEvent('origen_uploader:sv:preparar', RITMO, resguardo,
        type(nombre) == 'string' and nombre or 'imagen.png', base64)

    --[[ El tope de espera va con el tamaño: al ritmo de arriba, 10 MB son unos
         40 segundos. Se le da margen y un suelo de 15 s para las pequeñas. ]]
    local tope = math.max(15000, math.floor((#base64 / RITMO) * 1000 * 3))
    local esperado = 0

    while respuestas[resguardo] == nil and esperado < tope do
        Wait(50)
        esperado = esperado + 50
    end

    local r = respuestas[resguardo]
    respuestas[resguardo] = nil

    if not r then return nil, 'El servidor no ha contestado a tiempo.' end
    if not r.ok then return nil, r.mensaje or 'No se pudo preparar la imagen.' end

    return resguardo
end

--[[ La puerta para los demas recursos (negocios, bandas, crews): ellos piden
     el resguardo aqui y luego se lo pasan a SU callback de servidor, que es
     quien comprueba el permiso y llama a UploadFileInternal. ]]
exports('PrepararSubida', PrepararSubida)

local function OpenUploader()
    lib.callback('origen_uploader:cb:getHistory', false, function(history)
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'open',
            history = history
        })
    end)
end

exports('openManagement', OpenUploader)

RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    if GetResourceState('origen_admin') == 'started' then
        exports['origen_admin']:ReturnToScripts()
    end
    cb('ok')
end)

RegisterNUICallback('notify', function(data, cb)
    if GetResourceState('origen_notify') == 'started' then
        exports.origen_notify:Notify({
            title = 'Subir imágenes',
            description = data.message,
            type = data.type or 'info'
        })
    end

    --[[ Y ademas a la consola, siempre. Este aviso era la unica señal de que
         una subida habia fallado, y salia solo por origen_notify: con ese
         recurso parado, un error de la API o de permisos se perdia entero y el
         panel se quedaba sin decir nada. Un error que no se ve no existe. ]]
    if (data.type or 'info') == 'error' then
        print(('^1[origen_uploader] %s^0'):format(tostring(data.message)))
    end

    cb('ok')
end)

RegisterNUICallback('upload', function(data, cb)
    local resguardo, motivo = PrepararSubida(data.name, data.image)
    if not resguardo then
        cb({ success = false, message = motivo })
        return
    end

    lib.callback('origen_uploader:cb:upload', false, function(result)
        cb(result)
    end, { ticket = resguardo, name = data.name })
end)

RegisterNUICallback('delete', function(data, cb)
    lib.callback('origen_uploader:cb:delete', false, function(result)
        cb(result)
    end, data.id)
end)

RegisterNUICallback('getHistory', function(_, cb)
    lib.callback('origen_uploader:cb:getHistory', false, function(history)
        cb(history)
    end)
end)
