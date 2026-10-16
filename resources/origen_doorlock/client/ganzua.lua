--[[ Ganzuar puertas: el lado del cliente solo juega.

     El servidor (server/ganzua.lua) decide la puerta y si abre. Aqui se lanza
     el minijuego de origen_minijuegos y se devuelve el resultado tal cual. ]]

--[[ Un booleano suelto aqui se queda pegado en true si el resultado nunca
     vuelve, y entonces no se puede ganzuar nada hasta reiniciar el recurso. Se
     guarda hasta cuando vale: pasado el turno que da el servidor ya no hay
     nada que esperar. ]]
local VENCIMIENTO = ((Config.Ganzua and Config.Ganzua.tiempoMaximo) or 60) * 1000

local ganzuandoHasta = 0
local turno = 0

local function noSePuede(idPuerta)
    ganzuandoHasta = 0
    TriggerServerEvent('origen_doorlock:server:cancelarGanzua', idPuerta)
    Custom.Notify(Translations.ganzua and Translations.ganzua.sinMinijuego or 'No lockpick minigame', 'error')
end

RegisterNetEvent('origen_doorlock:client:ganzuar', function(idPuerta, dificultad)
    if GetGameTimer() < ganzuandoHasta then return end

    --[[ Si sigue habiendo una interfaz con el raton no se pisa. Al usar la
         ganzua desde el inventario este se esta cerrando (se le da un momento),
         pero si es otro minijuego —la ganzua del coche que qbx_vehiclekeys
         lanzo con la misma pulsacion— StartLockpick lo cerraria y su resultado
         se perderia. ]]
    local limite = GetGameTimer() + 600
    while IsNuiFocused() and GetGameTimer() < limite do Wait(50) end
    if IsNuiFocused() then
        TriggerServerEvent('origen_doorlock:server:cancelarGanzua', idPuerta)
        return
    end

    if GetResourceState('origen_minijuegos') ~= 'started' then
        return noSePuede(idPuerta)
    end

    turno = turno + 1
    local miTurno = turno
    ganzuandoHasta = GetGameTimer() + VENCIMIENTO

    local ok, lanzado = pcall(function()
        return exports.origen_minijuegos:StartLockpick(dificultad, function(exito)
            -- El resultado de un turno ya reemplazado gastaria el turno vivo.
            if miTurno ~= turno then return end
            ganzuandoHasta = 0
            TriggerServerEvent('origen_doorlock:server:resultadoGanzua', idPuerta, exito == true)
        end)
    end)

    if (not ok or not lanzado) and miTurno == turno then
        noSePuede(idPuerta)
    end
end)

RegisterNetEvent('origen_doorlock:client:avisoGanzua', function(clave, tipo)
    local texto = Translations.ganzua and Translations.ganzua[clave]
    if texto then Custom.Notify(texto, tipo) end
end)
