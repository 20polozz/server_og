--[[ El taller abierto: une la cámara, los puntos, la pantalla y el servidor.

     Mientras está abierto, el mecánico tiene el CONTROL de red del coche:
     lo que prueba se ve en el coche de verdad, así que el cliente que mira a
     su lado lo ve cambiar en directo. Al cerrar, todo lo no pagado vuelve a
     como estaba (`base`). ]]

local abierto = false
local veh = nil
local netId = nil
local base = nil          -- las propiedades de verdad: al abrir, o lo último pagado
local admin = false
local noche = false
local luces = false
local puertas = false

local function Aviso(texto, tipo)
    lib.notify({ title = 'Taller', description = texto, type = tipo or 'inform' })
    -- Los que impiden abrir quedan también en la F8 (y en el CitizenFX_log).
    if tipo == 'error' then print(('[origen_customs] %s'):format(texto)) end
end

--- Pide el control de red del coche: sin él, lo que se prueba no se ve fuera
--- y el dueño de la entidad lo vuelve a pisar.
local function Control(v)
    local hasta = GetGameTimer() + 2000
    NetworkRequestControlOfEntity(v)
    while not NetworkHasControlOfEntity(v) and GetGameTimer() < hasta do
        Wait(50)
        NetworkRequestControlOfEntity(v)
    end
    return NetworkHasControlOfEntity(v)
end

--- El coche que se tunea: el que conduces o, a pie, el más cercano.
local function ElCoche()
    if cache.vehicle then
        if GetPedInVehicleSeat(cache.vehicle, -1) ~= cache.ped then return nil, 'Tienes que ir al volante.' end
        return cache.vehicle
    end
    local v = lib.getClosestVehicle(GetEntityCoords(cache.ped), Config.Acceso.radioCoche, false)
    if not v then return nil, 'No hay ningún coche a tu lado.' end
    -- Con otro jugador al volante el coche es suyo y no se deja tunear.
    local conductor = GetPedInVehicleSeat(v, -1)
    if conductor ~= 0 and IsPedAPlayer(conductor) and conductor ~= cache.ped then
        return nil, 'Que se baje el conductor primero.'
    end
    return v
end

local function EstaticoParaPantalla()
    return {
        zonas = Catalogo.Zonas,
        tintados = Catalogo.Tintados,
        matriculas = Catalogo.Matriculas,
        acabados = Catalogo.Acabados,
        tiposLlanta = Catalogo.TiposLlanta,
    }
end

local function HUD(ver)
    DisplayRadar(ver)
    if GetResourceState('origen_hud') == 'started' then
        pcall(function() exports.origen_hud:toggleHud(ver) end)
    end
    -- El minimapa de origen_map es su propia NUI: sin esto asoma detrás del
    -- chivato de rendimiento. Apartar gana a quien lo pida a la vista y se
    -- limpia solo si este recurso se para.
    if GetResourceState('origen_map') == 'started' then
        pcall(function() exports.origen_map:Apartar(not ver) end)
    end
    -- Con el minimapa apartado, origen_hud cree que el HUD del coche no está
    -- dentro del mapa y saca el suyo viejo abajo en el centro. Se le calla.
    TriggerEvent('origen_hud:client:hideVehicleHud', not ver)
end

local function Noche(encender)
    noche = encender == true
    -- Weathersync congela a las 21:00 al quitarle la sincronía, y la vuelve a
    -- poner al devolvérsela. Solo toca a este jugador.
    LocalPlayer.state:set('syncWeather', not noche, false)
    if noche then
        SetTimeout(150, function() if noche then NetworkOverrideClockTime(23, 30, 0) end end)
    end
end

local function Cerrar()
    if not abierto then return end
    abierto = false

    -- El ratón lo PRIMERO: si algo de abajo fallara, el jugador no se queda preso.
    SetNuiFocus(false, false)
    SetTimeout(280, function()
        if not abierto then SendNUIMessage({ accion = 'cerrar' }) end
    end)

    Camara.Parar()
    Puntos.Parar()
    if noche then Noche(false) end
    HUD(true)

    if veh and DoesEntityExist(veh) then
        -- Lo no pagado se va: el coche vuelve a lo último de verdad.
        if base then Aplicar.Restaurar(veh, base) end
        for i = 0, 5 do SetVehicleDoorShut(veh, i, false) end
        SetVehicleLights(veh, 0)
        FreezeEntityPosition(veh, false)
        if netId then SetNetworkIdCanMigrate(netId, true) end
    end

    TriggerServerEvent('origen_customs:cerrar')
    veh, netId, base = nil, nil, nil
end

--- Abre el taller. `opciones.admin` = modo administración (sin cobrar; lo
--- vuelve a comprobar el servidor).
local function Abrir(opciones)
    if abierto then return end
    opciones = type(opciones) == 'table' and opciones or {}

    local v, motivo = ElCoche()
    if not v then return Aviso(motivo, 'error') end
    if not NetworkGetEntityIsNetworked(v) then return Aviso('Ese coche no se puede tunear.', 'error') end
    if not Control(v) then return Aviso('No se puede trabajar en ese coche ahora mismo.', 'error') end

    local id = VehToNet(v)
    local r = lib.callback.await('origen_customs:abrir', false, id, GetVehicleClass(v), opciones.admin == true)
    if type(r) ~= 'table' or not r.ok then
        return Aviso(type(r) == 'table' and r.mensaje or 'El taller no responde.', 'error')
    end

    veh, netId, admin = v, id, r.admin == true
    SetNetworkIdCanMigrate(netId, false)
    FreezeEntityPosition(veh, true)
    SetVehicleEngineOn(veh, true, true, false)

    local bloqueadas = PiezasBloqueadasDe(GetEntityModel(veh))
    local datos = Aplicar.Leer(veh, bloqueadas)
    base = lib.table.deepclone(datos.props)

    abierto = true
    luces, puertas = false, false
    HUD(false)
    Camara.Empezar(veh)
    Puntos.Empezar(veh)

    SendNUIMessage({
        accion = 'abrir',
        datos = {
            coche = datos, taller = r.taller, admin = admin, registrado = r.registrado,
            precios = r.precios, multiplicador = r.multiplicador, moneda = r.moneda,
            catalogo = EstaticoParaPantalla(),
        },
    })
    SetNuiFocus(true, true)
end

exports('Abrir', Abrir)
-- Lo que llamaban origen_businesses y origen_admin a qbx_customs.
exports('openCustoms', function(_, adminMode) Abrir({ admin = adminMode == true }) end)

RegisterCommand('customs', function() Abrir({}) end, false)

if OrigenFoco then
    OrigenFoco.AlSoltar(function() if abierto then Cerrar() end end)
end

AddEventHandler('onResourceStop', function(nombre)
    if nombre ~= GetCurrentResourceName() or not abierto then return end
    SetNuiFocus(false, false)
    RenderScriptCams(false, false, 0, true, false)
    if noche then LocalPlayer.state:set('syncWeather', true, false) end
    DisplayRadar(true)
    TriggerEvent('origen_hud:client:hideVehicleHud', false)
    if veh and DoesEntityExist(veh) then
        if base then Aplicar.Restaurar(veh, base) end
        FreezeEntityPosition(veh, false)
    end
end)

-- ── La pantalla habla ─────────────────────────────────────────────────────

local function Ok(cb, datos) cb(datos == nil and { ok = true } or datos) end

RegisterNUICallback('cerrar', function(_, cb) Ok(cb) Cerrar() end)

--- Probar un cambio (al pasar el ratón o al montarlo en el presupuesto).
RegisterNUICallback('probar', function(d, cb)
    Ok(cb)
    if not abierto then return end
    local c = Cambios.Normalizar(d and d.cambio)
    if c then Aplicar.Cambio(veh, c) end
end)

--- Varias a la vez: al deshacer o al volver a poner el montaje entero.
RegisterNUICallback('probarVarios', function(d, cb)
    Ok(cb)
    if not abierto or type(d) ~= 'table' or type(d.cambios) ~= 'table' then return end
    for _, bruto in ipairs(d.cambios) do
        local c = Cambios.Normalizar(bruto)
        if c then Aplicar.Cambio(veh, c) end
    end
end)

--- Volver al coche de verdad (sin nada del montaje).
RegisterNUICallback('original', function(_, cb)
    Ok(cb)
    if abierto and base then Aplicar.Restaurar(veh, base) end
end)

RegisterNUICallback('rendimiento', function(_, cb)
    if not abierto then return cb({}) end
    -- Un fotograma para que el juego recalcule con la pieza nueva.
    Wait(0)
    cb(Aplicar.Rendimiento(veh))
end)

RegisterNUICallback('llantas', function(d, cb)
    if not abierto then return cb({}) end
    cb(Aplicar.LlantasDe(veh, tonumber(d and d.tipo) or 0))
end)

RegisterNUICallback('tasar', function(d, cb)
    if not abierto then return cb({ ok = false }) end
    cb(lib.callback.await('origen_customs:tasar', false, d and d.lista or {}) or { ok = false })
end)

RegisterNUICallback('cercanos', function(_, cb)
    if not abierto then return cb({}) end
    cb(lib.callback.await('origen_customs:cercanos', false) or {})
end)

RegisterNUICallback('enviar', function(d, cb)
    if not abierto then return cb({ ok = false }) end
    cb(lib.callback.await('origen_customs:enviar', false, d and d.lista or {}, d and d.cliente, {
        descuento = d and d.descuento, gratis = d and d.gratis,
    }) or { ok = false })
end)

RegisterNUICallback('aplicarAdmin', function(d, cb)
    if not abierto or not admin then return cb({ ok = false }) end
    local r = lib.callback.await('origen_customs:aplicarAdmin', false, d and d.lista or {})
    if type(r) == 'table' and r.ok then
        base = r.props or lib.getVehicleProperties(veh)
        Aplicar.Restaurar(veh, base)
    end
    cb(r or { ok = false })
end)

-- Cámara y escena
RegisterNUICallback('camara', function(d, cb)
    Ok(cb)
    if not abierto or type(d) ~= 'table' then return end
    if d.accion == 'arrastrar' then
        Camara.Arrastrar(d.dx, d.dy)
    elseif d.accion == 'zoom' then
        Camara.Zoom(d.pasos)
    elseif d.accion == 'zona' then
        local zona = d.zona and Catalogo.Zona(d.zona)
        Camara.Zona(zona, zona and Puntos.Local(zona.id))
        -- Las puertas que hay que abrir para ver la zona (capó, maletero…).
        for i = 0, 5 do SetVehicleDoorShut(veh, i, false) end
        for _, puerta in ipairs(zona and zona.abre or {}) do SetVehicleDoorOpen(veh, puerta, false, false) end
    elseif d.accion == 'vista' then
        Camara.Vista(d.vista)
    elseif d.accion == 'exposicion' then
        Camara.Exposicion(d.on)
    end
end)

RegisterNUICallback('escena', function(d, cb)
    Ok(cb)
    if not abierto or type(d) ~= 'table' then return end
    if d.que == 'noche' then
        Noche(d.on)
    elseif d.que == 'luces' then
        luces = d.on == true
        SetVehicleLights(veh, luces and 2 or 0)
    elseif d.que == 'puertas' then
        puertas = d.on == true
        for i = 0, 5 do
            if puertas then SetVehicleDoorOpen(veh, i, false, false) else SetVehicleDoorShut(veh, i, false) end
        end
    elseif d.que == 'claxon' then
        StartVehicleHorn(veh, 1400, `HELDDOWN`, false)
    end
end)

-- ── El servidor contesta al presupuesto ───────────────────────────────────

RegisterNetEvent('origen_customs:respuesta', function(r)
    if not abierto or type(r) ~= 'table' then return end
    if r.ok then
        base = r.props or lib.getVehicleProperties(veh)
        Aplicar.Restaurar(veh, base)
        SendNUIMessage({ accion = 'pagado', datos = { total = r.total, props = base, mensaje = r.mensaje } })
        Aviso(r.mensaje or 'Presupuesto pagado.', 'success')
    else
        SendNUIMessage({ accion = 'rechazado', datos = { mensaje = r.mensaje } })
        Aviso(r.mensaje or 'El presupuesto no salió adelante.', 'error')
    end
end)

RegisterNetEvent('origen_customs:precios', function(precios)
    if abierto then SendNUIMessage({ accion = 'precios', datos = precios }) end
end)

-- Cerrar si el coche desaparece o el mecánico se aleja.
CreateThread(function()
    while true do
        if abierto then
            if not veh or not DoesEntityExist(veh) then
                Cerrar()
            else
                SetEntityLocallyInvisible(cache.ped)
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)

function TallerAbierto() return abierto end

-- Lo manda la orden de consola `customsadmin` (solo el servidor).
RegisterNetEvent('origen_customs:abrirAdmin', function() Abrir({ admin = true }) end)

-- El botón de silencio del riel se quitó el 07/10: solo vive en el inventario.
