-- origen_admin | Client side devoluciones system

--[[ Si el aviso (o el de /reclamar) esta en pantalla. Global a proposito: los
     cierres del admin (client/main.lua) lo miran para no soltar el raton con
     el aviso aun delante, que se quedaba pintado sin poder pulsar nada. ]]
devolucionAbierta = false

RegisterNetEvent('origen_admin:client:showDevolucionAlert', function()
    SendNUIMessage({
        action = 'showDevolucionAlert'
    })
    devolucionAbierta = true
    SetNuiFocus(true, true)
end)

RegisterNUICallback('closeDevolucionAlert', function(data, cb)
    devolucionAbierta = false
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Raton soltado a la fuerza (@origen_map/shared/foco.lua): el aviso fuera.
if OrigenFoco then
    OrigenFoco.AlSoltar(function()
        if not devolucionAbierta then return end
        devolucionAbierta = false
        SendNUIMessage({ action = 'hideDevolucionAlert' })
    end)
end

RegisterNUICallback('getDevoluciones', function(data, cb)
    FW_TriggerCallback('origen_admin:server:getDevoluciones', function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('createDevolucion', function(data, cb)
    FW_TriggerCallback('origen_admin:server:createDevolucion', function(success)
        cb(success)
    end, data)
end)

RegisterNUICallback('deleteDevolucion', function(data, cb)
    FW_TriggerCallback('origen_admin:server:deleteDevolucion', function(success)
        cb(success)
    end, data)
end)

RegisterNUICallback('checkCitizenId', function(data, cb)
    FW_TriggerCallback('origen_admin:server:checkCitizenId', function(result)
        cb(result)
    end, data)
end)

-- Reclaim system commands and callbacks
RegisterCommand('reclamar', function(source, args, rawCommand)
    FW_TriggerCallback('origen_admin:server:getPendingDevolucionesForPlayer', function(items)
        if not items or #items == 0 then
            exports.origen_notify:Notify({
                title = 'Devoluciones',
                description = 'No tienes devoluciones pendientes.',
                type = 'error',
                duration = 5000
            })
            return
        end
        
        SendNUIMessage({
            action = 'showDevolucionClaim',
            items = items
        })
        devolucionAbierta = true
        SetNuiFocus(true, true)
    end)
end, false)

RegisterNUICallback('claimPendingDevoluciones', function(data, cb)
    FW_TriggerCallback('origen_admin:server:claimPendingDevoluciones', function(result)
        if result and result.success then
            devolucionAbierta = false
            SetNuiFocus(false, false)
            cb({ success = true })
        else
            local errMsg = result and result.message or "Error desconocido"
            exports.origen_notify:Notify({
                title = 'Devoluciones',
                description = errMsg,
                type = 'error',
                duration = 5000
            })
            cb({ success = false, message = errMsg })
        end
    end, data)
end)
