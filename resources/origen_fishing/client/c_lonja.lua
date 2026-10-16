--[[ La lonja de Florindo.

     Vive aparte de `c_main.lua` porque no tiene nada que ver con el ciclo de
     pesca: es una pantalla que se abre, cobra y se va. ]]

local abierto = false

--- Suelta el foco YA y retrasa el desmontaje lo que dura la animación de salida.
--- El reparto no es intercambiable: si el aviso se retrasara hasta el final y
--- la NUI fallara por el camino, el ratón se quedaría preso sin pantalla delante.
function CerrarLonja()
    if not abierto then return end
    abierto = false

    SetNuiFocus(false, false)

    -- Sin pisar una lonja que se haya vuelto a abrir en esos 280 ms.
    SetTimeout(280, function()
        if not abierto then SendNUIMessage({ accion = 'cerrar' }) end
    end)
end

--[[ Raton soltado a la fuerza (vigilante de origen_map/shared/foco.lua o
     `soltarraton`): sin esto `abierto` se quedaba en true y Florindo no
     volvia a abrir la lonja. ]]
if OrigenFoco then
    OrigenFoco.AlSoltar(function()
        if not abierto then return end
        abierto = false
        SendNUIMessage({ accion = 'cerrar' })
    end)
end

function AbrirLonja()
    if abierto then return end

    local datos = lib.callback.await('origen_fishing:AbrirLonja', false)

    if not datos then
        lib.notify({
            title = 'Lonja',
            description = 'Florindo no puede atenderte ahora.',
            type = 'error'
        })
        return
    end

    abierto = true

    SetNuiFocus(true, true)
    SendNUIMessage({ accion = 'abrir', datos = datos })
end

function LonjaAbierta()
    return abierto
end

exports('EstaAbierto', LonjaAbierta)

RegisterNUICallback('cerrar', function(_, cb)
    CerrarLonja()
    cb({ ok = true })
end)

RegisterNUICallback('vender', function(datos, cb)
    cb(lib.callback.await('origen_fishing:VenderPiezas', false, datos and datos.slots or {}))
end)

RegisterNUICallback('comprar', function(datos, cb)
    cb(lib.callback.await('origen_fishing:ComprarArticulo', false,
        datos and datos.item, datos and datos.cantidad))
end)

--[[ Un reinicio del recurso con la pantalla abierta dejaría el ratón preso y
     sin nada delante: solo se sale reconectando. ]]
AddEventHandler('onResourceStop', function(recurso)
    if recurso == GetCurrentResourceName() and abierto then
        SetNuiFocus(false, false)
    end
end)
