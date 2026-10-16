-- ─── DISABLE COVER MECHANIC (Q) & VEHICLE RADIO WHEEL (Q) ──────────────────────────────
--[[ Antes: dos DisableControlAction en CADA fotograma, para todos los
     jugadores y durante toda la partida (lo que mas pesaba del admin en el
     resmon, 16/09).

     Ahora:
       - La cobertura se quita con SetPlayerCanUseCover, que es un ajuste del
         jugador y no hay que repetirlo cada fotograma (se reafirma cada medio
         segundo por si algo lo vuelve a encender).
       - La rueda de la radio solo existe dentro de un vehiculo: solo ahi se
         bloquea la tecla fotograma a fotograma. A pie, el hilo duerme. ]]
Citizen.CreateThread(function()
    SetUserRadioControlEnabled(false)
    while true do
        SetPlayerCanUseCover(PlayerId(), false)

        if IsPedInAnyVehicle(PlayerPedId(), false) then
            local hasta = GetGameTimer() + 500
            repeat
                DisableControlAction(0, 44, true)
                DisableControlAction(0, 85, true)
                Wait(0)
            until GetGameTimer() >= hasta
        else
            -- A pie la Q ya no hace nada del juego: sin cobertura no hay
            -- que apagar la tecla.
            Wait(500)
        end
    end
end)
