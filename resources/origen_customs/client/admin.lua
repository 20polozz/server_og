--[[ El panel de administración del taller.

     A pantalla completa, con el lenguaje de la tablet. Lo abre origen_admin
     desde su lista de scripts con `openManagement()`, como el resto. Todo lo
     que hace se vuelve a comprobar en el servidor. ]]

local abierto = false

--- Abre el panel. `seccion` es el apartado con el que se abre (por defecto,
--- Actividad); `callado` no avisa de la falta de permiso, para quien tiene
--- otro camino si el panel no se abre (/admincustoms). Devuelve si se ha
--- encargado él (abierto, o avisado de que hay que cerrar el taller).
local function Abrir(seccion, callado)
    if abierto then return true end
    if TallerAbierto and TallerAbierto() then
        lib.notify({ title = 'Taller', description = 'Cierra el taller antes de abrir el panel.', type = 'error' })
        return true
    end
    local datos = lib.callback.await('origen_customs:admin:datos', false)
    if not datos or not datos.permiso then
        if not callado then
            lib.notify({ title = 'Taller', description = 'No tienes permiso para esto.', type = 'error' })
        end
        return false
    end
    abierto = true
    datos.seccion = type(seccion) == 'string' and seccion or nil
    SetNuiFocus(true, true)
    SendNUIMessage({ accion = 'admin', datos = datos })
    return true
end

-- Envuelto: origen_admin lo llama sin argumentos y no debe colarse ninguno.
exports('openManagement', function() Abrir() end)

--- /admincustoms abre este mismo panel en «Precios del tuneo» (client/precios.lua).
function AbrirPreciosEnPanel()
    return Abrir('precios', true)
end

local function Cerrar()
    if not abierto then return end
    abierto = false
    SetNuiFocus(false, false)
    SendNUIMessage({ accion = 'cerrarAdmin' })
end

-- Raton soltado a la fuerza (vigilante del foco o `soltarraton`): el panel se
-- cierra y se puede volver a abrir.
if OrigenFoco then
    OrigenFoco.AlSoltar(function() if abierto then Cerrar() end end)
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
    cb(lib.callback.await('origen_customs:admin:guardar', false, d and d.seccion, d and d.valor) or { ok = false })
end)

RegisterNUICallback('adminRestablecer', function(d, cb)
    cb(lib.callback.await('origen_customs:admin:restablecer', false, d and d.seccion) or { ok = false })
end)

RegisterNUICallback('adminRegistro', function(d, cb)
    cb(lib.callback.await('origen_customs:admin:registro', false, d or {}) or { ok = false })
end)

--- El modelo del coche en el que va el admin, para bloquearle piezas sin
--- tener que saberse el nombre.
RegisterNUICallback('adminModelo', function(_, cb)
    local veh = GetVehiclePedIsIn(cache.ped, false)
    if veh == 0 then veh = lib.getClosestVehicle(GetEntityCoords(cache.ped), 6.0, false) or 0 end
    if veh == 0 then return cb({ ok = false }) end
    local nombre = GetDisplayNameFromVehicleModel(GetEntityModel(veh)) or ''
    -- El nombre visible no siempre es el del modelo: se comprueba con el hash.
    local modelo = GetEntityModel(veh)
    local candidato = nombre:lower()
    cb({ ok = true, modelo = joaat(candidato) == modelo and candidato or nil, visible = nombre })
end)

AddEventHandler('onResourceStop', function(r)
    if r == GetCurrentResourceName() and abierto then SetNuiFocus(false, false) end
end)
