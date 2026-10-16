-- client.lua — origen_status
--
-- Este script se ejecuta en el CLIENTE únicamente cuando las resources
-- han sido descargadas por completo (el hecho de que corra = descarga OK).
--
-- Notifica al servidor que el jugador ya está dentro, para que Node.js
-- pueda moverle de db.windows → db.connected de forma fiable, sin la
-- condición de carrera del antiguo notify('connected') en el gate.

local _sent = false

CreateThread(function()
    -- Esperar a que la sesión de red esté activa (jugador completamente cargado)
    local tries = 0
    while tries < 60 do
        if NetworkIsPlayerActive(PlayerId()) then
            break
        end
        Wait(1000)
        tries = tries + 1
    end

    if not _sent then
        _sent = true
        TriggerServerEvent('origen_status:playerLoaded')
    end
end)
