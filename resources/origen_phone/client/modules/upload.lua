--[[ Subir cosas grandes.

     Una foto cabe en una peticion normal. Un video no: treinta segundos son
     varios megas, y en base64 un tercio mas. Mandarlo de una pieza rompia el
     camino por los dos sitios a la vez:

       - de la interfaz al cliente, la peticion moria con "Failed to fetch"
       - del cliente al servidor, la red contestaba "Serialization of the packet
         failed", que es como FiveM dice que un evento no cabe

     Asi que se manda en trozos. La interfaz va soltando pedazos, el cliente los
     va juntando, y cuando estan todos lo envia al servidor con un evento
     latente: ese es el que existe justo para esto, porque reparte el envio en
     el tiempo en vez de intentar meterlo entero en un paquete.

     El resultado vuelve por un evento aparte, no como respuesta del envio: un
     latente no contesta. Por eso cada subida lleva un numero de ticket, y quien
     espera lo hace por ese numero.
]]

Upload = {}

--[[ Ritmo del envio al servidor, en bytes por segundo.

     ESTABA EN 2 MB/s Y ECHABA AL JUGADOR (29/09). Es la misma conexion que usa
     el juego: a ese ritmo un video se comia toda la subida de casa del jugador,
     el servidor dejaba de oirle y le echaba por timeout; al volver se quedaba en
     «Connecting to server» mientras el servidor aun le daba por dentro. Lo
     mismo que paso con la videollamada el 15/09 (ver RITMO_VIDEO en calls.lua,
     que va a 256 KB/s). Aqui va por debajo: un video tarda mas en subir, pero
     nadie se queda sin conexion. ]]
local RITMO = 160 * 1024

--[[ Lo mas grande que se deja salir, ya en base64. Un video de la camara
     (15 s a 900 kb/s) son unos 2,3 MB; esto deja margen sin permitir envios que
     tarden un minuto ocupando la conexion. ]]
local TOPE_ENVIO = 4 * 1024 * 1024

--- Solo una subida a la vez: dos a la vez son el doble de ritmo.
local subiendo = false

--- Lo que se esta juntando ahora mismo, por identificador.
local montones = {}

--- Lo que espera respuesta del servidor, por ticket.
local esperando = {}

local siguienteTicket = 0

-- ---------------------------------------------------------------------------
--  De la interfaz al cliente, en tandas
-- ---------------------------------------------------------------------------

Nui.On('uploadBegin', function(params)
    local id = ('u%d'):format(GetGameTimer())

    montones[id] = {
        trozos = {},
        isVideo = params.isVideo == true,
        width = tonumber(params.width),
        height = tonumber(params.height),
    }

    return { id = id }
end)

Nui.On('uploadChunk', function(params)
    local monton = montones[params.id]
    if not monton then return { ok = false, error = 'err_upload_lost' } end

    -- El indice llega explicito y no se da por hecho el orden: las peticiones
    -- de la interfaz no tienen por que resolverse en el orden en que salieron.
    local i = tonumber(params.index)
    if not i or type(params.data) ~= 'string' then
        return { ok = false, error = 'err_bad_request' }
    end

    monton.trozos[i + 1] = params.data
    return { ok = true }
end)

Nui.On('uploadFinish', function(params)
    local monton = montones[params.id]
    if not monton then return { ok = false, error = 'err_upload_lost' } end

    montones[params.id] = nil

    local total = tonumber(params.count) or #monton.trozos
    for i = 1, total do
        if monton.trozos[i] == nil then
            return { ok = false, error = 'err_upload_incomplete' }
        end
    end

    local datos = table.concat(monton.trozos, '', 1, total)
    if datos == '' then return { ok = false, error = 'err_no_image' } end
    if #datos > TOPE_ENVIO then return { ok = false, error = 'err_file_too_big' } end
    if subiendo then return { ok = false, error = 'err_upload_busy' } end
    subiendo = true

    siguienteTicket = siguienteTicket + 1
    local ticket = siguienteTicket

    local respuesta = promise.new()
    esperando[ticket] = respuesta

    TriggerLatentServerEvent('origen_phone:sv:upload', RITMO, ticket, {
        isVideo = monton.isVideo,
        width = monton.width,
        height = monton.height,
    }, datos)

    --[[ Si el servidor no contesta, no se puede dejar a la interfaz esperando
         para siempre con el boton bloqueado. Lo que tarda el envio a este ritmo
         mas medio minuto para la subida a internet. ]]
    SetTimeout(30000 + math.ceil(#datos * 1000 / RITMO), function()
        if esperando[ticket] then
            esperando[ticket] = nil
            respuesta:resolve({ ok = false, error = 'err_upload_timeout' })
        end
    end)

    local resultado = Citizen.Await(respuesta)
    subiendo = false
    return resultado
end)

RegisterNetEvent('origen_phone:cl:uploadDone', function(ticket, result)
    local respuesta = esperando[ticket]
    if not respuesta then return end

    esperando[ticket] = nil
    respuesta:resolve(result or { ok = false, error = 'err_something_failed' })
end)
