--[[ ══════════════════════════════════════════════════════════════════════════
     LA CAJA

     La ventana de comprar y cambiar fichas, y la de sacarse la tarjeta de
     socio. Es la misma pantalla con dos pestañas, y se abre por la que toca:
     desde la caja, por fichas; desde el mostrador de socios, por la tarjeta; y
     cuando la caja rechaza a alguien por no tener la tarjeta, por la tarjeta
     también.

     Esa última es la que salva el sistema: el que se entera de que hace falta
     una tarjeta es el que ha venido a por fichas, y se entera ahí mismo sin
     tener que saberse de memoria que existe un mostrador en la calle.
   ══════════════════════════════════════════════════════════════════════════ ]]

local abierta = false

function AbrirCaja(punto, pestana)
    if abierta or C.pantalla then return end

    local datos = lib.callback.await('origen_casino:caja:datos', false)
    if not datos or not datos.ok then
        C.Aviso(Config.General.nombre, (datos and datos.mensaje) or 'La caja está cerrada.', 'error')
        return
    end

    abierta = true
    C.pantalla = 'caja'
    C.Foco(true)
    C.Enviar('abrirCaja', {
        datos = datos,
        pestana = pestana or (punto and punto.juego == 'membresia' and 'membresia') or 'fichas',
    })
end

function CerrarCaja()
    if not abierta then return end
    abierta = false
    C.pantalla = nil
    C.Foco(false)
    C.Enviar('cerrarCaja')
end

if OrigenFoco then
    OrigenFoco.AlSoltar(function()
        if not abierta then return end
        abierta = false
        C.Enviar('cerrarCaja')
    end)
end

RegisterNUICallback('cajaCerrar', function(_, cb)
    cb({})
    CerrarCaja()
end)

RegisterNUICallback('cajaComprar', function(datos, cb)
    cb(lib.callback.await('origen_casino:caja:comprar', false, datos or {}) or { ok = false })
end)

RegisterNUICallback('cajaVender', function(datos, cb)
    cb(lib.callback.await('origen_casino:caja:vender', false, datos or {}) or { ok = false })
end)

RegisterNUICallback('cajaMembresia', function(datos, cb)
    cb(lib.callback.await('origen_casino:caja:membresia', false, datos or {}) or { ok = false })
end)

RegisterNUICallback('cajaRefrescar', function(_, cb)
    cb(lib.callback.await('origen_casino:caja:datos', false) or { ok = false })
end)

AddEventHandler('onResourceStop', function(recurso)
    if recurso == GetCurrentResourceName() and abierta then C.Foco(false) end
end)
