-- ─── DESACTIVAR RADIO POR DEFECTO DE GTA Y DIAL DE EMISORAS ──────────────────
CreateThread(function()
    SetAudioFlag('DisableFlightMusic', true)
    SetAudioFlag('WantedMusicDisabled', true)
    SetUserRadioControlEnabled(false)

    while true do
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)
            if veh ~= 0 then
                -- Desactivar el dial de la radio (tecla Q / rueda de emisoras) y cambio de estación
                DisableControlAction(0, 81, true) -- INPUT_VEH_NEXT_RADIO
                DisableControlAction(0, 82, true) -- INPUT_VEH_PREV_RADIO
                DisableControlAction(0, 83, true) -- INPUT_VEH_NEXT_RADIO_TRACK
                DisableControlAction(0, 84, true) -- INPUT_VEH_PREV_RADIO_TRACK
                DisableControlAction(0, 85, true) -- INPUT_VEH_RADIO_WHEEL (Q)

                if GetPlayerRadioStationName() ~= nil then
                    SetVehRadioStation(veh, "OFF")
                    SetVehicleRadioEnabled(veh, false)
                    SetRadioToStationName("OFF")
                end
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)
