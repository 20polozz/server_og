--[[ ── El panel de administración ─────────────────────────────────────────────

     A pantalla completa, con el lenguaje de la tablet. Lo abre origen_admin
     desde su lista de scripts con `openManagement()`, como el resto. Todo lo
     que hace se vuelve a comprobar en el servidor. ]]

local abierto = false

local function Abrir()
    if abierto then return end
    local datos = lib.callback.await('origen_hunting:admin:datos', false)
    if not datos or not datos.permiso then
        C.Aviso('Caza', 'No tienes permiso para esto.', 'error')
        return
    end
    abierto = true
    C.adminAbierto = true
    SetNuiFocus(true, true)
    SendNUIMessage({ accion = 'admin', datos = datos })
end

exports('openManagement', Abrir)

local function Cerrar()
    if not abierto then return end
    abierto = false
    C.adminAbierto = false
    SetNuiFocus(false, false)
    SendNUIMessage({ accion = 'cerrarAdmin' })
end

-- Raton soltado a la fuerza: el panel se cierra y se puede volver a abrir.
if OrigenFoco then
    OrigenFoco.AlSoltar(function()
        if not abierto then return end
        abierto = false
        C.adminAbierto = false
        SendNUIMessage({ accion = 'cerrarAdmin' })
    end)
end

--- Cerrar y, si el panel se abrió desde la pestaña Scripts del admin, volver
--- a ella. Ya no hay botón: es lo que hace ESC. origen_admin decide si vuelve
--- (solo si este panel salió de su lista); si no, ESC cierra y nada más.
local function CerrarYVolver()
    Cerrar()
    if GetResourceState('origen_admin') ~= 'started' then return end
    SetTimeout(80, function()
        pcall(function() exports['origen_admin']:ReturnToScripts() end)
    end)
end

RegisterNUICallback('adminCerrar', function(_, cb)
    cb({})
    CerrarYVolver()
end)

RegisterNUICallback('adminVolver', function(_, cb)
    cb({})
    CerrarYVolver()
end)

RegisterNUICallback('adminGuardar', function(d, cb)
    cb(lib.callback.await('origen_hunting:admin:guardar', false, d and d.seccion, d and d.valor) or { ok = false })
end)

RegisterNUICallback('adminRestablecer', function(d, cb)
    cb(lib.callback.await('origen_hunting:admin:restablecer', false, d and d.seccion) or { ok = false })
end)

RegisterNUICallback('adminRegistro', function(d, cb)
    cb(lib.callback.await('origen_hunting:admin:registro', false, d or {}) or { ok = false })
end)

RegisterNUICallback('adminTorneo', function(d, cb)
    cb(lib.callback.await('origen_hunting:admin:torneo', false, d and d.accion, d and d.extra) or { ok = false })
end)

--- Coordenadas de donde está el admin, para crear una zona sin copiar números.
RegisterNUICallback('adminAqui', function(_, cb)
    local p = GetEntityCoords(cache.ped)
    cb({ x = math.floor(p.x * 100) / 100, y = math.floor(p.y * 100) / 100 })
end)

RegisterNUICallback('adminRuta', function(d, cb)
    local x, y = tonumber(d and d.x), tonumber(d and d.y)
    if x and y then SetNewWaypoint(x, y) end
    cb({ ok = x ~= nil })
end)

AddEventHandler('onResourceStop', function(r)
    if r == GetCurrentResourceName() and abierto then SetNuiFocus(false, false) end
end)
