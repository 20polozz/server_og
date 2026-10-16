AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if activeMission.vsZone then
            activeMission.vsZone:remove()
        end
        if activeMission.vsPed then
            DeleteEntity(activeMission.vsPed)
        end
    end
end)

RegisterNetEvent('origen_boosting:cl:generateVinScratchZone', function(data)
    --- El sitio donde se raya el VIN. Con ruta, que es a donde hay que ir.
    activeMission.vsBlip = 'vin'
    activeMission.vehicle = data.vehicle

    OrigenMapa.Poner(activeMission.vsBlip, {
        x = data.coords.x, y = data.coords.y, z = data.coords.z,
        cat = 'illegal',
        icono = 'paquete',
        nombre = locale('in_game.blip.delivery_point'),
        color = '#2ee6a8',
        ruta = true,
        prioridad = 10,
    })

    activeMission.vsPed = NetworkGetEntityFromNetworkId(data.ped)
    SetBlockingOfNonTemporaryEvents(activeMission.vsPed, true)
    FreezeEntityPosition(activeMission.vsPed, true)
    SetEntityInvincible(activeMission.vsPed, true)

    activeMission.vsZone = lib.points.new({
        coords = data.coords,
        distance = 6,
    })

    function activeMission.vsZone:onEnter()
        Custom.DrawText('E', locale('in_game.notifications.interact_mechanic'))
    end

    function activeMission.vsZone:onExit()
        Custom.HideText()
    end

    function activeMission.vsZone:nearby()
        DrawMarker(21, data.coords.xyz, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.5, 0.5, 0.5, 0, 0, 0, 100, false, true, 2, true, false, false, false)

        if self.currentDistance < 2 and IsControlJustReleased(0, 38) then
            local veh = lib.getClosestVehicle(data.coords.xyz, 5, false)
            if veh == activeMission.vehId then
                Custom.HideText()
                OrigenMapa.Quitar(activeMission.vsBlip)
                activeMission.vsZone:remove()
                SetVehicleDoorsLockedForAllPlayers(veh, true)
                if Custom.Progress(20000, locale('in_game.notifications.checking_vehicle')) then
                    SetVehicleDoorsLockedForAllPlayers(veh, false)
                    local vehProps = lib.getVehicleProperties(veh)
                    lib.callback.await('origen_boosting:sv:saveVinVehicle', false, vehProps, activeMission.vehicle)
                    Custom.GiveKeys(veh)
                    TriggerServerEvent('origen_boosting:sv:vinFinished', activeMission.id)
                end
            end
        end
    end
end)