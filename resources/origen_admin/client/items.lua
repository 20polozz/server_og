RegisterNetEvent('origen_admin:client:useHarnessItem', function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    
    if veh == 0 then
        ShowNotification("No estás dentro de ningún vehículo", "error")
        return
    end
    
    local currentFlyFlag = GetPedConfigFlag(ped, 32, true)
    
    if currentFlyFlag then -- El jugador volaría (true), así que lo ponemos (false)
        exports['origen_inventory']:progressBar({
            name = "put_harness",
            duration = 15000,
            label = "Colocando arnés de seguridad...",
            useWhileDead = false,
            canCancel = true,
            controlDisables = {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            },
            animation = {
                animDict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@",
                anim = "machinic_loop_meach",
                flags = 49,
            },
        }, function(cancelled)
            if not cancelled then
                SetPedConfigFlag(ped, 32, false)
                -- Guardar estado en el vehículo
                if Entity(veh) then
                    Entity(veh).state:set('harness', true, true)
                end
                ShowNotification("Arnés colocado. Ya no saldrás disparado.", "success")
                TriggerServerEvent('origen_admin:server:consumeHarness')
            else
                ShowNotification("Acción cancelada.", "error")
            end
        end)
    else
        ShowNotification("Ya tienes un arnés puesto.", "error")
    end
end)

-- Hilo para detectar arnés en el vehículo al entrar
CreateThread(function()
    local lastVeh = 0
    while true do
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        
        if veh ~= 0 then
            if veh ~= lastVeh then
                lastVeh = veh
                -- Al entrar en un vehículo nuevo, comprobamos si tiene arnés
                if Entity(veh) and Entity(veh).state.harness then
                    SetPedConfigFlag(ped, 32, false)
                    ShowNotification("Este vehículo tiene arnés instalado. Activado.", "info")
                else
                    SetPedConfigFlag(ped, 32, true)
                end
            end
        elseif lastVeh ~= 0 then
            -- Al bajar o cambiar de asiento a uno fuera del coche, reseteamos el flag para el ped
            SetPedConfigFlag(ped, 32, true)
            lastVeh = 0
        end
        Wait(1500)
    end
end)
