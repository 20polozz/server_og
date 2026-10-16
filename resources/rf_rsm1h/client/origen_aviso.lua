--[[ ORIGEN: el aviso de tecla del mapeado («E  Abrir» en puertas y ascensores)
     sale por el de la casa, exports.origen_notify:DrawText, y no por el suyo.

     El Lua del autor va cifrado y manda el aviso a su NUI (lift.html). Allí
     origen.js lo esconde y nos lo reenvía por este callback con el texto ya
     traducido. Si origen_notify no está, el aviso no sale: no rompe nada. ]]

local puesto = nil

local function Quitar()
    if not puesto then return end
    puesto = nil
    pcall(function() exports.origen_notify:HideText() end)
end

RegisterNUICallback('origenAviso', function(datos, cb)
    cb('ok')

    if type(datos) ~= 'table' or not datos.mostrar then
        return Quitar()
    end

    local tecla = tostring(datos.tecla or 'E'):sub(1, 12)
    local texto = tostring(datos.texto or ''):sub(1, 60)
    if texto == '' then return Quitar() end

    -- Llega repetido mientras sigues al lado; solo se repinta si cambia
    local clave = tecla .. '|' .. texto
    if puesto == clave then return end
    puesto = clave

    pcall(function() exports.origen_notify:DrawText(tecla, texto) end)
end)

AddEventHandler('onResourceStop', function(recurso)
    if recurso == GetCurrentResourceName() then Quitar() end
end)

