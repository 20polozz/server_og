ButtonNotificationInternal = function(msg, beep) -- Skip the multigsub function for faster execution
    AddTextEntry('ButtonNotificationInternal', msg)
    BeginTextCommandDisplayHelp('ButtonNotificationInternal')
    EndTextCommandDisplayHelp(0, true, beep, -1)
end

CreateBlip = function(name, coords, sprite, colour, scale)
    --[[ NOTA DE ORIGEN: esto ya no crea un blip del juego.

         Registra un punto en origen_map —de donde leen los tres mapas del
         servidor— y devuelve su CLAVE, no un handle. `colour` y `scale` se
         siguen admitiendo para no romper a quien llame, pero no se usan: alli
         la chincheta es dibujo nuestro. El `sprite` si: pasa por
         OrigenMapa.Icono, y el que no conozca deja el dibujo de la categoria. ]]
    ultimaMarca = (ultimaMarca or 0) + 1
    local clave = 'marca_' .. ultimaMarca

    OrigenMapa.Poner(clave, {
        x = coords.x, y = coords.y, z = coords.z,
        cat = 'public',
        icono = OrigenMapa.Icono(sprite),
        nombre = name,
    })

    return clave
end

StartCacheUpdateLoop = function()
    Citizen.CreateThread(function()
        while true do
            currentSlice = GetSelfSlice()
            player = PlayerPedId()
            Citizen.Wait(Config.UpdateCooldown)
        end
    end)
end

Emit = function(type, manual, ...)
    TriggerEvent("Utility:On:".. (manual and "!" or "") ..type, ...)
end

EmitInteraction = function()
    for k,v in pairs(Utility.Cache.Marker) do
        if v.candraw ~= false then
            local distance = #(GetEntityCoords(PlayerPedId()) - v.coords)

            if distance < v.interaction_distance then
                Emit("marker", false, k)
                v.near = false
            end
        end
    end

    for k,v in pairs(Utility.Cache.Object) do
        if v.candraw ~= false then
            local distance = #(GetEntityCoords(PlayerPedId()) - v.coords)	
            
            if distance < v.interaction_distance then
                Emit("object", false, k)
                v.near = false
            end
        end
    end
end

-- It is not directly in the fxmanifest because many do not know that the utility lib can run without the utility framework
-- and keep reporting the error "Failed to load script @utility_framework/client/api.lua". 
LoadUtilityFrameworkIfFound = function()
    if GetResourceState("utility_framework") ~= "missing" then
        local init = LoadResourceFile("utility_framework", "client/api.lua")
    
        if init then
            load(init, "@utility_framework/client/api.lua")()
        end
    end
end