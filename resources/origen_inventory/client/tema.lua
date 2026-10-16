--[[ El silencio de la interfaz: el boton del altavoz, al final del riel del
     inventario. Solo mutea los sonidos de ESTE menu (el inventario), no los del servidor ni dispatch. ]]
local KVP_SILENCIO = 'origen_inventory:silencio'
local silencio = GetResourceKvpString(KVP_SILENCIO) == 'si'

RegisterNUICallback('silencio', function(datos, cb)
    local si = datos and datos.silencio
    if type(si) ~= 'boolean' then
        cb({ ok = false })
        return
    end
    silencio = si
    SetResourceKvp(KVP_SILENCIO, si and 'si' or 'no')
    cb({ ok = true, silencio = silencio })
end)

RegisterNUICallback('dameSilencioInventario', function(_, cb)
    cb({ silencio = silencio })
end)
