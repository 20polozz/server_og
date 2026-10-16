if OrigenMarca ~= 'nacion' then return end

local PROPS = 'origen_props'
local PEDS = 'origen_peds'
local PETS = 'origen_pets'
local PATENTES = 'origen_patentevip'

local panel = PanelLateral('miscosas')

local function EnMarcha(recurso)
    return GetResourceState(recurso) == 'started'
end

function AbrirMisCosas()
    if not EnMarcha(PROPS) and not EnMarcha(PEDS) and not EnMarcha(PETS) and not EnMarcha(PATENTES) then return end
    if not panel.Empezar() then return end

    local datos = lib.callback.await('origen_hud:miscosas', 5000)
    if not datos then return panel.Fallar('No se pudieron cargar tus cosas. Intentalo en un momento.') end

    panel.Mostrar(datos)
end

--[[ Colocar usa los controles del juego y el cursor del gizmo: con el panel
     puesto no llegaria ninguna tecla. Se cierra primero y se coloca despues. ]]
RegisterNUICallback('miscosas:colocar', function(data, cb)
    cb({})
    panel.Cerrar()

    local id = tonumber(data and data.id)
    if not id or not EnMarcha(PROPS) then return end

    SetTimeout(300, function()
        local ok, err = pcall(function() exports[PROPS]:PlaceOwnedProp(id) end)
        if not ok then print(('^1[origen_hud]^0 No se pudo colocar el objeto %s: %s'):format(id, err)) end
    end)
end)

RegisterNUICallback('miscosas:recoger', function(data, cb)
    local id = tonumber(data and data.id)
    if not id or not EnMarcha(PROPS) then return cb({ ok = false, msg = 'El sistema de objetos no está disponible.' }) end

    local ok, recogido, msg = pcall(function() return exports[PROPS]:PickupOwnedProp(id) end)
    if not ok then return cb({ ok = false, msg = 'No se pudo recoger el objeto.' }) end

    cb({ ok = recogido == true, msg = msg })
end)

--- Con `id` se viste ese ped; sin el, se vuelve a la ropa de siempre. Se cierra para verse puesto.
RegisterNUICallback('miscosas:ped', function(data, cb)
    cb({})
    panel.Cerrar()

    local id = data and tonumber(data.id)
    CreateThread(function()
        local res = lib.callback.await('origen_hud:miscosas:ped', 10000, id)
        local ok = res and res.ok
        local texto = (res and res.msg) or (id and 'No se pudo equipar el ped.' or 'No se pudo quitar el ped.')
        lib.notify({ description = texto, type = ok and 'success' or 'error' })
    end)
end)

local function Avisar(res, fallo)
    local ok = res and res.ok
    lib.notify({ description = (res and res.msg) or fallo, type = ok and 'success' or 'error' })
end

--- Invocar o guardar. Se cierra para ver llegar a la mascota.
RegisterNUICallback('miscosas:mascota', function(data, cb)
    cb({})
    panel.Cerrar()

    local hash = data and data.hash
    CreateThread(function()
        Avisar(lib.callback.await('origen_hud:miscosas:mascota', 10000, hash), 'No se pudo llamar a tu mascota.')
    end)
end)

RegisterNUICallback('miscosas:mascota:configurar', function(data, cb)
    cb({})
    panel.Cerrar()

    CreateThread(function()
        Avisar(lib.callback.await('origen_hud:miscosas:mascota:configurar', 10000, data), 'No se pudo guardar tu mascota.')
    end)
end)

RegisterNUICallback('miscosas:mascota:borrar', function(data, cb)
    cb(lib.callback.await('origen_hud:miscosas:mascota:borrar', 10000, data and data.hash)
        or { ok = false, msg = 'No se pudo liberar a tu mascota.' })
end)

local SIN_PATENTES = { ok = false, msg = 'El sistema de patentes no está disponible.' }

RegisterNUICallback('miscosas:patente:preparar', function(data, cb)
    if not EnMarcha(PATENTES) then return cb(SIN_PATENTES) end
    cb(lib.callback.await('origen_patentevip:preparar', false, data and data.id) or SIN_PATENTES)
end)

RegisterNUICallback('miscosas:patente:comprobar', function(data, cb)
    if not EnMarcha(PATENTES) then return cb(SIN_PATENTES) end
    cb(lib.callback.await('origen_patentevip:comprobar', false, data and data.patente) or SIN_PATENTES)
end)

RegisterNUICallback('miscosas:patente:usar', function(data, cb)
    if not EnMarcha(PATENTES) then return cb(SIN_PATENTES) end

    local res = lib.callback.await('origen_patentevip:usar', false, data and data.id, data and data.patente)
        or { ok = false, msg = 'No se pudo cambiar la patente.' }
    cb(res)
    if not res.ok then return end

    local vehiculo = GetVehiclePedIsIn(cache.ped, false)
    if vehiculo ~= 0 then SetVehicleNumberPlateText(vehiculo, res.patente) end

    panel.Cerrar()
    lib.notify({ description = res.msg, type = 'success' })
end)

exports('AbrirMisCosas', function() AbrirMisCosas() end)
exports('MisCosasAbierta', function() return panel.abierto end)
