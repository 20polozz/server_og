--* NUI CALLBACKS - la tienda de fichero «Apoya al proyecto» (server/tienda/tienda.lua)
-- El cliente solo hace de cartero: qué se vende, a cuánto y a quién lo decide el servidor.

RegisterNUICallback('tienda:catalogo', function(_, cb)
    local res = lib.callback.await('origen_vipsystem:server:tienda:catalogo', 8000)
    cb(res or { ok = false })
end)

RegisterNUICallback('tienda:casas', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:tienda:casas', 5000, data)
    cb(res or { ok = false, casas = {} })
end)

-- Los muebles de un pack, uno a uno (la rejilla de su ficha)
RegisterNUICallback('tienda:muebles', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:tienda:muebles', 6000, data)
    cb(res or { ok = false })
end)

-- Una compra cobra, entrega y apunta: con menos margen podría dar por fallida una que el servidor sí ha hecho.
RegisterNUICallback('tienda:comprar', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:tienda:comprar', 15000, data)
    cb(res or { ok = false, msg = 'El servidor no ha contestado a tiempo. Abre la tienda otra vez y mira si se ha hecho el canje antes de repetirlo.' })
end)

-- Staff
RegisterNUICallback('tienda:staff', function(_, cb)
    local res = lib.callback.await('origen_vipsystem:server:tienda:staff', 5000)
    cb(res or { ok = false })
end)

RegisterNUICallback('tienda:regalar', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:tienda:regalar', 15000, data)
    cb(res or { ok = false, msg = 'El servidor no ha contestado a tiempo.' })
end)

RegisterNUICallback('tienda:retirar', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:tienda:retirar', 15000, data)
    cb(res or { ok = false, msg = 'El servidor no ha contestado a tiempo.' })
end)

-- ── Ver en 3D y probar (client/escaparate.lua, client/testdrive.lua) ────────
-- Qué modelo es lo dice el servidor a partir del id del producto, nunca la interfaz.
RegisterNUICallback('tienda:escaparate:abrir', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:tienda:escaparate', 5000, data)
    if res and res.espera then
        Wait(450)
        res = lib.callback.await('origen_vipsystem:server:tienda:escaparate', 5000, data)
    end
    if not res or not res.ok then
        return cb({ ok = false, msg = res and res.msg or 'El servidor no ha contestado.' })
    end
    local bien, motivo = Escaparate.Abrir(res.tipo, res.modelo, res.tatuaje)
    -- (un tatuaje entra mirando a su sitio: la barra tiene que saber desde dónde se parte)
    cb({ ok = bien == true, msg = motivo, tipo = res.tipo, vista = res.tatuaje and res.tatuaje.vista or nil })
end)

-- Tatuajes de la tienda: ponérselo, quitárselo o cambiar el acabado. Lo decide el servidor.
RegisterNUICallback('tienda:tatuaje', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:tienda:tatuaje', 8000, data)
    cb(res or { ok = false, msg = 'El servidor no ha contestado a tiempo.' })
end)

-- El panel de admin: encender y apagar pestañas de la tienda (pestaña «Categorías» del panel VIP)
RegisterNUICallback('tienda:categorias', function(_, cb)
    local res = lib.callback.await('origen_vipsystem:server:tienda:categorias', 8000)
    if res and res.espera then
        Wait(450)
        res = lib.callback.await('origen_vipsystem:server:tienda:categorias', 8000)
    end
    cb(res or { ok = false, msg = 'El servidor no ha contestado a tiempo.' })
end)

RegisterNUICallback('tienda:categoria', function(data, cb)
    cb(lib.callback.await('origen_vipsystem:server:tienda:categoria', 8000, data) or { ok = false, msg = 'El servidor no ha contestado a tiempo.' })
end)

-- Un admin ha encendido o apagado una pestaña: la tienda, si está abierta, se vuelve a pedir
RegisterNetEvent('origen_vipsystem:client:tienda:recargar', function()
    SendNUIMessage({ action = 'tienda:recargar' })
end)

-- El panel de admin de tatuajes (pestaña «Tatuajes» del panel VIP): el permiso lo comprueba el servidor en cada llamada
RegisterNUICallback('tatuajes:admin', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:tatuajes:admin', 8000, data)
    if res and res.espera then
        Wait(450)
        res = lib.callback.await('origen_vipsystem:server:tatuajes:admin', 8000, data)
    end
    cb(res or { ok = false, msg = 'El servidor no ha contestado a tiempo.' })
end)

RegisterNUICallback('tatuajes:admin:dar', function(data, cb)
    cb(lib.callback.await('origen_vipsystem:server:tatuajes:admin:dar', 10000, data) or { ok = false, msg = 'El servidor no ha contestado a tiempo.' })
end)

RegisterNUICallback('tatuajes:admin:quitar', function(data, cb)
    cb(lib.callback.await('origen_vipsystem:server:tatuajes:admin:quitar', 10000, data) or { ok = false, msg = 'El servidor no ha contestado a tiempo.' })
end)

-- La ropa: se le pone la prenda a un doble del personaje, en el mismo estudio
RegisterNUICallback('tienda:ropa:ver', function(data, cb)
    local res = lib.callback.await('origen_vipsystem:server:tienda:ropa', 5000, data)
    if res and res.espera then
        Wait(450)
        res = lib.callback.await('origen_vipsystem:server:tienda:ropa', 5000, data)
    end
    if not res or not res.ok then
        return cb({ ok = false, msg = res and res.msg or 'El servidor no ha contestado.' })
    end
    local bien, motivo = Escaparate.Abrir('ropa', res.hash)
    cb({ ok = bien == true, msg = motivo })
end)

RegisterNUICallback('tienda:escaparate:mover', function(data, cb)
    Escaparate.Mover(data)
    cb({})
end)

RegisterNUICallback('tienda:escaparate:cerrar', function(_, cb)
    Escaparate.Cerrar()
    cb({})
end)

RegisterNUICallback('tienda:probar', function(data, cb)
    if TestDrive.IsActive() then return cb({ ok = false, msg = 'Ya estás probando un vehículo.' }) end
    if cache.vehicle then return cb({ ok = false, msg = 'Bájate del vehículo antes de probar otro.' }) end
    if IsEntityDead(cache.ped) or IsPedFalling(cache.ped) or IsPedSwimming(cache.ped) then
        return cb({ ok = false, msg = 'Ahora mismo no puedes probar un vehículo.' })
    end

    local res = lib.callback.await('origen_vipsystem:server:tienda:probar', 5000, data)
    if not res or not res.ok then
        return cb({ ok = false, msg = res and res.msg or 'El servidor no ha contestado.' })
    end

    -- Antes de cerrar nada: si el modelo no está en este servidor, se dice en la ficha
    local hash = joaat(res.modelo)
    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then
        return cb({ ok = false, msg = 'Este vehículo no está cargado en este servidor: no se puede probar.' })
    end

    cb({ ok = true })
    -- Con la tienda puesta no llegaría ninguna tecla: se cierra (y con ella el escaparate) y se sale a probar
    TriggerEvent('origen_vipsystem:client:cerrarPanel')
    Wait(150)
    TestDrive.Start(res.modelo, res.nombre, res.minutos)
end)
