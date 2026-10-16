--[[ ── El depósito de Davis ───────────────────────────────────────────────────

     El encargado y su panel (con él se empieza y se acaba todo: jornada,
     uniforme y camión), los puntos del mapa y el uniforme. ]]

local C = Config.Deposito
local abierto = false

-- ── Mapa ──────────────────────────────────────────────────────────────────

CreateThread(function()
    OrigenMapa.Poner('deposito', {
        x = C.centro.x, y = C.centro.y, z = C.centro.z,
        cat = 'trabajos', icono = 'basura', nombre = C.nombre,
    })
end)

--- De jornada se ven la planta de compactación y el encargado, y tu camión.
local puestos, marcado = false, nil
CreateThread(function()
    while true do
        local jornada = L.Jornada()
        if jornada ~= puestos then
            puestos = jornada
            local sitios = {}
            if jornada then
                local d, e = Config.Planta.prensas[2].coords, C.Peds.Encargado.coords
                sitios = {
                    { id = 'tolva', x = d.x, y = d.y, z = d.z, cat = 'trabajos', icono = 'basura', nombre = 'Planta de compactación: vaciar el camión' },
                    { id = 'encargado', x = e.x, y = e.y, z = e.z, cat = 'trabajos', icono = 'persona', nombre = 'Encargado del depósito' },
                }
            end
            OrigenMapa.PonerVarios('sitio', sitios)
        end
        local mio = Vehiculos.mio
        local veh = mio and Vehiculos.Entidad(mio.vehiculo)
        if veh and marcado ~= veh then
            marcado = veh
            OrigenMapa.Poner('alquiler', {
                entidad = veh, cat = 'trabajos', icono = 'camion', color = '#fc0259', propio = true,
                nombre = (Config.Vehiculos.tipos[mio.tipo] or Config.Vehiculos.tipos.camion).nombre,
            })
        elseif not veh and marcado then
            marcado = nil
            OrigenMapa.Quitar('alquiler')
        end
        Wait(3000)
    end
end)

-- ── El uniforme ───────────────────────────────────────────────────────────

local conUniforme = false

local function PonerUniforme()
    local ped = cache.ped
    local u = Config.Uniforme[GetEntityModel(ped) == `mp_m_freemode_01` and 'male' or 'female']
    if not u then return end
    for comp, v in pairs(u) do
        local prop = comp:match('^p(%d+)$')
        if prop then
            SetPedPropIndex(ped, tonumber(prop), v[1], v[2], true)
        else
            SetPedComponentVariation(ped, tonumber(comp), v[1], v[2], 0)
        end
    end
    conUniforme = true
end

local function QuitarUniforme()
    if not conUniforme then return end
    conUniforme = false
    pcall(function() exports.origen_clothing:ReloadAppearanceData() end)
end

-- Si la jornada se acaba por otro lado (reinicio, se cae), fuera el uniforme.
AddStateBagChangeHandler('basuraJornada', ('player:%s'):format(cache.serverId), function(_, _, valor)
    if not valor then SetTimeout(0, QuitarUniforme) end
end)

-- ── El punto de entrega del camión ────────────────────────────────────────
--[[ 30/09, el usuario: no se sabía dónde dejar el camión. Con camión alquilado
     sale en el mapa, a menos de 60 m se ve el aro en el suelo y dentro, al
     volante, E lo entrega y termina la jornada (sin ir al encargado). ]]
local devolverPuesto = false
CreateThread(function()
    local d = C.devolver
    while true do
        local espera = 1000
        local mio = Vehiculos.mio
        if (mio ~= nil) ~= devolverPuesto then
            devolverPuesto = mio ~= nil
            if devolverPuesto then
                OrigenMapa.Poner('devolver', {
                    x = d.coords.x, y = d.coords.y, z = d.coords.z,
                    cat = 'trabajos', icono = 'camion', nombre = 'Entrega del camión de la basura',
                })
            else
                OrigenMapa.Quitar('devolver')
            end
        end
        local veh = mio and Vehiculos.Entidad(mio.vehiculo)
        local dentro = false
        if veh and #(GetEntityCoords(cache.ped) - d.coords) < 60.0 then
            espera = 0
            -- Pequeño (30/09, el usuario: el aro del tamaño de la zona era feísimo):
            -- un disco de 3 m y el camión encima; la zona que vale sigue siendo d.radio.
            DrawMarker(25, d.coords.x, d.coords.y, d.coords.z - 0.97, 0, 0, 0, 0, 0, 0,
                3.0, 3.0, 1.0, 216, 27, 85, 120, false, false, 2, false)
            DrawMarker(39, d.coords.x, d.coords.y, d.coords.z + 0.6, 0, 0, 0, 0, 0, 0,
                1.0, 1.0, 1.0, 216, 27, 85, 150, true, true, 2, false)
            if cache.vehicle == veh and GetPedInVehicleSeat(veh, -1) == cache.ped
                and #(GetEntityCoords(veh) - d.coords) <= d.radio then
                dentro = true
                L.Ayuda('devolver', 'E', 'Entregar el camión y terminar la jornada')
                if IsControlJustReleased(0, 38) then
                    local r = lib.callback.await('origen_garbage:panel:devolverAqui', false, {})
                    if r and r.mensaje then L.Aviso(r.mensaje, r.ok and 'success' or 'error') end
                    if r and r.ok then
                        Vehiculos.mio = nil
                        if r.uniforme == false then QuitarUniforme() end
                    end
                end
            end
        end
        if not dentro then L.QuitarAyuda('devolver') end
        Wait(espera)
    end
end)

-- ── El encargado ──────────────────────────────────────────────────────────

local encargado = nil

local function CrearNPC(cfg)
    local hash = GetHashKey(cfg.modelo)
    if not Dibujo.Cargar(hash) then return nil end
    local c = cfg.coords
    local z = Dibujo.Suelo(c.x, c.y, c.z) or (c.z - 1.0)
    local ped = Rastro.Marcar(CreatePed(4, hash, c.x, c.y, z, c.w, false, false))
    SetModelAsNoLongerNeeded(hash)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_CLIPBOARD', 0, true)
    return ped
end

CreateThread(function()
    local cfg = C.Peds.Encargado
    local conTexto = false
    while true do
        local espera = 1000
        local c = cfg.coords
        local d = #(GetEntityCoords(cache.ped) - c.xyz)
        if d < 60.0 and not encargado then
            encargado = CrearNPC(cfg)
        elseif d >= 60.0 and encargado then
            Dibujo.Borrar(encargado)
            encargado = nil
        end
        if d < 3.0 then espera = 0 elseif d < 12.0 then espera = 250 end
        local cerca = d <= 2.3 and not abierto and not cache.vehicle and not L.ocupado
        if cerca and not conTexto then
            conTexto = true
            L.Ayuda('npc', 'E', L.Jornada() and 'Hablar con el encargado' or 'Empezar la jornada con el encargado')
        elseif not cerca and conTexto then
            conTexto = false
            L.QuitarAyuda('npc')
        end
        if cerca and IsControlJustReleased(0, 38) then
            conTexto = false
            L.QuitarAyuda('npc')
            AbrirPanel('jornada')
        end
        Wait(espera)
    end
end)

-- ── El panel ──────────────────────────────────────────────────────────────

--[[ Los jugadores que tengo al lado, para que el servidor no recorra a los
     300 conectados al montar el panel (equipo: a quien se puede invitar). El
     juego solo da por aqui a los de mi zona (GetActivePlayers); el servidor
     comprueba la distancia de verdad de cada uno. ]]
local function ConCercanos(d)
    d = type(d) == 'table' and d or {}
    local yo, mio, t = GetEntityCoords(PlayerPedId()), PlayerId(), {}
    for _, id in ipairs(GetActivePlayers()) do
        if id ~= mio then
            local ped = GetPlayerPed(id)
            if ped ~= 0 and #(GetEntityCoords(ped) - yo) < 60.0 then t[#t + 1] = GetPlayerServerId(id) end
        end
    end
    d.cercanos = t
    return d
end

function AbrirPanel(seccion)
    if abierto then return end
    abierto = true
    local r = lib.callback.await('origen_garbage:panel:abrir', false, ConCercanos({}))
    if not r or not r.datos then
        abierto = false
        L.Nui('cerrar')
        L.Aviso((r and r.mensaje) or 'El depósito no puede atenderte ahora.', 'error')
        return
    end
    r.datos.seccion = seccion or 'jornada'
    L.panelAbierto = true
    L.EsconderTarjetas()
    SetNuiFocus(true, true)
    L.Nui('abrir', r.datos)
end

function CerrarPanel()
    if not abierto then return end
    abierto = false
    L.panelAbierto = false
    SetNuiFocus(false, false)
    SetTimeout(280, function() if not abierto then L.Nui('cerrar') end end)
    CreateThread(L.PedirYo)
end

OrigenFoco.AlSoltar(function() CerrarPanel() end)

CreateThread(function()
    while true do
        Wait(1000)
        if abierto and #(GetEntityCoords(cache.ped) - C.centro) > C.radio + 10.0 then CerrarPanel() end
    end
end)

RegisterNUICallback('cerrar', function(_, cb)
    CerrarPanel()
    cb({ ok = true })
end)

for _, nombre in ipairs({ 'refrescar', 'empezar', 'terminar', 'marcarTolva', 'equipoInvitar', 'equipoSalir', 'equipoExpulsar' }) do
    RegisterNUICallback(nombre, function(d, cb)
        local r = lib.callback.await('origen_garbage:panel:' .. nombre, false, ConCercanos(d))
        cb(r or { ok = false, mensaje = 'El depósito no contesta.' })
        if not r or not r.ok then return end
        if r.punto then SetNewWaypoint(r.punto.x + 0.0, r.punto.y + 0.0) end
        if r.uniforme == true then PonerUniforme() elseif r.uniforme == false then QuitarUniforme() end
        if nombre == 'empezar' then
            CreateThread(function()
                Wait(600)
                Vehiculos.mio = lib.callback.await('origen_garbage:miVehiculo', false)
                L.PedirYo()
            end)
        end
        if nombre == 'terminar' then Vehiculos.mio = nil end
    end)
end

RegisterNUICallback('marcarVehiculo', function(_, cb)
    local mio = Vehiculos.mio
    local ent = mio and Vehiculos.Entidad(mio.vehiculo)
    if ent then
        local c = GetEntityCoords(ent)
        SetNewWaypoint(c.x, c.y)
        L.Aviso('Ruta marcada a tu camión.', 'success')
        return cb({ ok = true })
    end
    cb({ ok = false, mensaje = 'No veo tu camión desde aquí.' })
end)

-- Al conectar con un camión que ya era tuyo (tras desconectarse).
CreateThread(function()
    Wait(3000)
    L.PedirYo()
    Vehiculos.mio = lib.callback.await('origen_garbage:miVehiculo', false)
end)

AddEventHandler('onResourceStop', function(r)
    if r ~= GetCurrentResourceName() then return end
    if abierto then SetNuiFocus(false, false) end
    if encargado then Dibujo.Borrar(encargado) end
    QuitarUniforme()
end)
