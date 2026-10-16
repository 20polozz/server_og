-- =============================================
-- origen_anticheat — Client: Main Loop
-- =============================================

-- Esperar a que el jugador esté completamente cargado
CreateThread(function()
    -- Grace period inicial al entrar al servidor
    Wait(15000)

    -- Loop principal
    while true do
        Wait(Config.CheckIntervalMs)

        -- Esperar a que el ped exista
        local ped = PlayerPedId()
        if not ped or ped == 0 then goto continue end
        if not NetworkIsPlayerActive(PlayerId()) then goto continue end

        -- Ejecutar todos los checks
        CheckGodMode()
        CheckNoClip()
        CheckSpectate()
        CheckWeapons()
        CheckVehicleSpeed()
        CheckExplosion()  -- stub, detección real es via eventHandler

        ::continue::
    end
end)
