--[[ ── Pantallas en vivo: el cliente ───────────────────────────────────

     Solo hace de cartero entre la interfaz y el servidor. Todo lo de verdad
     —capturar la imagen, el WebRTC, pintar el video— ocurre en la interfaz
     (ui/src/pantallas/).

     Cualquier jugador puede ser el mirado: la interfaz del admin esta
     cargada en todos los clientes aunque nunca abran el panel, y es la que
     emite cuando el servidor se lo pide. ]]

local function Interfaz(accion, datos)
    SendNUIMessage({ action = accion, data = datos or {} })
end

-- ── Interfaz → servidor ──────────────────────────────────────────────

RegisterNUICallback('PantallaPedir', function(data, cb)
    local r = lib.callback.await('origen_admin:server:pantallaPedir', false, tonumber(data and data.targetId))
    cb(r or { success = false, message = 'Sin respuesta del servidor' })
end)

RegisterNUICallback('PantallaParar', function(data, cb)
    local r = lib.callback.await('origen_admin:server:pantallaParar', false, data and data.sessionId)
    cb(r or { success = false })
end)

RegisterNUICallback('PantallaPararTodas', function(_, cb)
    local r = lib.callback.await('origen_admin:server:pantallaPararTodas', false)
    cb(r or { success = false })
end)

RegisterNUICallback('PantallaMax', function(_, cb)
    cb({ max = lib.callback.await('origen_admin:server:pantallaMax', false) or 0 })
end)

RegisterNUICallback('PantallaOferta', function(data, cb)
    cb('ok')
    TriggerServerEvent('origen_admin:server:pantallaOferta', data)
end)

RegisterNUICallback('PantallaRespuesta', function(data, cb)
    cb('ok')
    TriggerServerEvent('origen_admin:server:pantallaRespuesta', data)
end)

RegisterNUICallback('PantallaIce', function(data, cb)
    cb('ok')
    TriggerServerEvent('origen_admin:server:pantallaIce', data)
end)

RegisterNUICallback('PantallaCerrada', function(data, cb)
    cb('ok')
    TriggerServerEvent('origen_admin:server:pantallaCerrada', data)
end)

-- ── Servidor → interfaz ──────────────────────────────────────────────

RegisterNetEvent('origen_admin:client:pantallaEmitir', function(datos)
    if datos and datos.avisar then
        ShowNotification(('%s esta viendo tu pantalla'):format(datos.staffName or 'Un staff'))
    end
    Interfaz('pantalla:emitir', datos)
end)

RegisterNetEvent('origen_admin:client:pantallaOferta', function(datos)
    Interfaz('pantalla:oferta', datos)
end)

RegisterNetEvent('origen_admin:client:pantallaRespuesta', function(datos)
    Interfaz('pantalla:respuesta', datos)
end)

RegisterNetEvent('origen_admin:client:pantallaIce', function(datos)
    Interfaz('pantalla:ice', datos)
end)

RegisterNetEvent('origen_admin:client:pantallaFin', function(datos)
    Interfaz('pantalla:fin', datos)
end)

-- La ficha rápida que sale al pinchar en una pantalla.
RegisterNUICallback('EspectarFicha', function(data, cb)
    local r = lib.callback.await('origen_admin:server:espectarFicha', false, tonumber(data and data.targetId))
    cb(r or { success = false, message = 'Sin respuesta del servidor' })
end)
