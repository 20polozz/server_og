--[[ ═══════════════════════════════════════════════════════════════════════
     El SILENCIO de la interfaz (27/09). Mismo camino que el tema: se guarda
     aqui, en el KVP, y se reparte con un evento global que cada puente
     (@origen_map/shared/tema.lua) pasa a su pantalla. Lo que calla lo decide
     el trozo del <head> de cada pagina: los ruidos de menu, no la musica,
     los videos ni la radio.

         TriggerEvent('origen:silencio:poner', true)   -- desde cualquier recurso
         TriggerEvent('origen:silencio:alternar')
   ═══════════════════════════════════════════════════════════════════════ ]]

local KVP_SILENCIO = 'origen:silencio'
local silencio = GetResourceKvpString(KVP_SILENCIO) == 'si'

exports('SilencioActual', function()
    return silencio
end)

local function ponerSilencio(si)
    si = si == true
    if si == silencio then return end
    silencio = si
    SetResourceKvp(KVP_SILENCIO, si and 'si' or 'no')
    TriggerEvent('origen:silencio:aplicar', silencio)
end

AddEventHandler('origen:silencio:poner', ponerSilencio)
AddEventHandler('origen:silencio:alternar', function() ponerSilencio(not silencio) end)

AddEventHandler('onClientResourceStart', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    TriggerEvent('origen:silencio:aplicar', silencio)
end)

RegisterCommand('silencio', function(_, args)
    local a = args[1]
    if a == 'si' or a == 'on' then ponerSilencio(true)
    elseif a == 'no' or a == 'off' then ponerSilencio(false)
    else ponerSilencio(not silencio) end
    print(('[origen_map] ruidos de interfaz: %s'):format(silencio and 'callados' or 'activos'))
end, false)
