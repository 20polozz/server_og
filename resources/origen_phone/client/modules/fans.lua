--[[ OGN Fans en el cliente: solo el camino de la foto que se va a pixelar.

     La interfaz pide la foto original, el servidor la descarga
     (server/fans_imagen.js) y aqui se le pasa a la interfaz tal cual. Del
     cliente a la pagina no hay red, asi que el tamaño da igual; el salto con
     tope es servidor -> cliente, y ese va latente. ]]

Nui.On('fansImagen', function(params)
    if type(params.id) ~= 'string' or type(params.url) ~= 'string' then return { ok = false } end

    TriggerServerEvent('origen_phone:sv:fansImagen', params.id, params.url)
    return { ok = true }
end)

RegisterNetEvent('origen_phone:cl:fansImagen', function(peticion, mime, base64, error)
    Nui.Send('fans:imagen', { id = peticion, mime = mime, base64 = base64, error = error })
end)
