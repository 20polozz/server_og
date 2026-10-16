local openedFromHub = false

exports('IsOpenedFromHub', function() return openedFromHub end)
exports('ResetHubFlag', function() openedFromHub = false end)

exports('openManagement', function()
    openedFromHub = true
    
    CreateThread(function()
        -- Verificar permisos de admin
        local isAdmin = lib.callback.await('origen_fuel:cb:isAdmin', false)
        
        if not isAdmin then
            lib.notify({
                title = 'Gasolinera',
                description = 'No tienes permisos de administrador',
                type = 'error'
            })
            openedFromHub = false
            exports['origen_admin']:ReturnToScripts()
            return
        end
        
        -- Obtener datos de las estaciones
        local response = lib.callback.await('origen_fuel:cb:getStations', false)
        
        if not response or not response.success then
            lib.notify({
                title = 'Gasolinera',
                description = response and response.message or 'Error al obtener estaciones',
                type = 'error'
            })
            openedFromHub = false
            exports['origen_admin']:ReturnToScripts()
            return
        end
        
        -- Enviar datos al NUI
        SendNUIMessage({
            action = 'openAdminFuel',
            data = {
                stations = response.stations,
                fuelTypes = Config.Fuels
            }
        })

        --[[ El foco, YA. Se esperaban 2,8 s y en ese rato el panel estaba
             pintado sin raton y sin Escape. No hacia falta para el relevo:
             origen_admin suelta su foco antes de llamar a openManagement, y la
             pagina no tiene nada que esperar al abrir. ]]
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(false)
        ApartarHud(true)
    end)
end)

RegisterNUICallback('closeAdminFuel', function(data, cb)
    SetNuiFocus(false, false)
    ApartarHud(false)
    cb('ok')
    
    if openedFromHub then
        openedFromHub = false
        exports['origen_admin']:ReturnToScripts()
    end
end)

RegisterNUICallback('addFuelToStation', function(data, cb)
    lib.callback('origen_fuel:cb:addFuelAdmin', false, function(response)
        cb(response)
    end, data.stationId, data.fuelType, data.amount)
end)

RegisterNUICallback('removeFuelFromStation', function(data, cb)
    lib.callback('origen_fuel:cb:removeFuelAdmin', false, function(response)
        cb(response)
    end, data.stationId, data.fuelType, data.amount)
end)

RegisterNUICallback('refreshStations', function(data, cb)
    lib.callback('origen_fuel:cb:getStations', false, function(response)
        cb(response)
    end)
end)

RegisterNUICallback('createStation', function(data, cb)
    lib.callback('origen_fuel:cb:createStation', false, function(response)
        cb(response)
    end, data)
end)

RegisterNUICallback('updateStation', function(data, cb)
    lib.callback('origen_fuel:cb:updateStation', false, function(response)
        cb(response)
    end, data.stationId, data.data)
end)

RegisterNUICallback('deleteStation', function(data, cb)
    lib.callback('origen_fuel:cb:deleteStation', false, function(response)
        cb(response)
    end, data.stationId)
end)

RegisterNUICallback('setStationPrice', function(data, cb)
    lib.callback('origen_fuel:cb:setStationPrice', false, function(response)
        cb(response)
    end, data.stationId, data.fuelType, data.price)
end)

RegisterNUICallback('toggleStationActive', function(data, cb)
    lib.callback('origen_fuel:cb:toggleStationActive', false, function(response)
        cb(response)
    end, data.stationId, data.active)
end)

RegisterNUICallback('refillAllStations', function(data, cb)
    lib.callback('origen_fuel:cb:refillAllStations', false, function(response)
        cb(response)
    end)
end)

RegisterNUICallback('getCurrentCoords', function(data, cb)
    local coords = GetEntityCoords(PlayerPedId())
    cb({
        x = coords.x,
        y = coords.y,
        z = coords.z
    })
end)

RegisterNUICallback('getConfig', function(data, cb)
    cb({
        fuelTypes = Config.Fuels
    })
end)

RegisterNUICallback('startZoneCreation', function(data, cb)
    
    cb({ success = true, message = 'Marcado de zona empezado' })
    
    -- Esperar un momento antes de cerrar el NUI
    Wait(100)
    
    -- Cerrar el NUI temporalmente
    SetNuiFocus(false, false)
    -- Se marca la zona andando por la calle: el HUD vuelve mientras tanto.
    ApartarHud(false)
    
    -- Iniciar creación de zona
    -- Vuelve SIEMPRE, tambien al cancelar (points = nil): el panel sigue
    -- pintado y sin el raton no habia forma de salir de el.
    exports['origen_fuel']:StartZoneCreation(function(points)

        -- Reabrir el NUI
        SetNuiFocus(true, true)
        if ApartarHud then ApartarHud(true) end

        if not points or #points == 0 then return end

        -- Esperar un momento para que el NUI se reactive
        Wait(100)

        -- Enviar puntos al NUI
        SendNUIMessage({
            action = 'zoneCreated',
            points = points
        })
    end)
end)

