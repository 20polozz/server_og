--[[ ── El aserradero ──────────────────────────────────────────────────────────

     El encargado y su panel (con él se empieza y se acaba todo: jornada,
     hacha y camión) y los puntos del mapa. La bahía de entrega la pinta
     client/vehiculos.lua cuando llegas con el camión cargado. ]]

local C = Config.Aserradero
local abierto = false

-- ── Mapa ──────────────────────────────────────────────────────────────────

CreateThread(function()
    OrigenMapa.Poner('aserradero', {
        x = C.centro.x, y = C.centro.y, z = C.centro.z,
        cat = 'trabajos', icono = 'arbol', nombre = C.nombre,
    })
end)

--- De jornada se ven los cuarteles (zonas con su radio), la bahía de
--- entrega y el encargado.
local puestos = false
CreateThread(function()
    while true do
        local jornada = L.Jornada()
        if jornada ~= puestos then
            puestos = jornada
            local puntos = {}
            if jornada then
                for _, c in ipairs(Config.Cuarteles) do
                    local esp = Config.Especies[c.especie]
                    puntos[#puntos + 1] = {
                        id = c.id, x = c.centro.x, y = c.centro.y, z = c.centro.z,
                        cat = 'trabajos', icono = 'arbol', radio = c.radio + 0.0,
                        nombre = ('Cuartel de %s: %s'):format(esp.nombre:lower(), c.nombre),
                    }
                end
            end
            OrigenMapa.PonerVarios('cuartel', puntos)
            local sitios = {}
            if jornada then
                local d, e = C.descarga.coords, C.Peds.Encargado.coords
                sitios = {
                    { id = 'bahia', x = d.x, y = d.y, z = d.z, cat = 'trabajos', icono = 'paquete', nombre = 'Entrega de la madera' },
                    { id = 'encargado', x = e.x, y = e.y, z = e.z, cat = 'trabajos', icono = 'persona', nombre = 'Encargado del aserradero' },
                }
            end
            OrigenMapa.PonerVarios('sitio', sitios)
        end
        -- El camión, detrás de él.
        local mio = Vehiculos.mio
        local veh = mio and Vehiculos.Entidad(mio.vehiculo)
        if veh and not Vehiculos.marcado then
            Vehiculos.marcado = veh
            OrigenMapa.Poner('alquiler', {
                entidad = veh, cat = 'trabajos', icono = 'camion',
                color = '#fc0259', propio = true, nombre = (Config.Vehiculos.tipos[mio.tipo] or Config.Vehiculos.tipos.camion).nombre,
            })
        elseif not veh and Vehiculos.marcado then
            Vehiculos.marcado = nil
            OrigenMapa.Quitar('alquiler')
        elseif veh and Vehiculos.marcado ~= veh then
            Vehiculos.marcado = nil
        end
        Wait(3000)
    end
end)

-- ── El encargado ──────────────────────────────────────────────────────────

local encargado = nil

local function CrearNPC(cfg)
    local hash = GetHashKey(cfg.modelo)
    if not Monte.Cargar(hash) then return nil end
    local c = cfg.coords
    local z = Monte.Suelo(c.x, c.y, c.z) or c.z
    local ped = Rastro.Marcar(CreatePed(4, hash, c.x, c.y, z, c.w, false, false))
    SetModelAsNoLongerNeeded(hash)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_CLIPBOARD', 0, true)
    return ped
end

--[[ Rehacer lo que se ve: lo llama el editor cuando se mueve un sitio (el
     encargado, en este caso), para verlo colocado sin reiniciar nada. ]]
Aserradero = Aserradero or {}
local rehacer = false
function Aserradero.Rehacer() rehacer = true end

CreateThread(function()
    local cfg = C.Peds.Encargado
    local conTexto = false
    while true do
        local espera = 1000
        local c = cfg.coords
        local d = #(GetEntityCoords(cache.ped) - c.xyz)
        if rehacer then
            rehacer = false
            if encargado then Monte.Borrar(encargado) encargado = nil end
        end
        if d < 60.0 and not encargado then
            encargado = CrearNPC(cfg)
        elseif d >= 60.0 and encargado then
            Monte.Borrar(encargado)
            encargado = nil
        end
        if d < 12.0 then espera = 0 end
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
    local r = lib.callback.await('origen_lumber:panel:abrir', false, ConCercanos({}))
    if not r or not r.datos then
        abierto = false
        -- Reabierto justo al cerrar: el 'cerrar' tardio se lo salto al verlo
        -- abierto, asi que el panel viejo sigue pintado. Fuera.
        L.Nui('cerrar')
        L.Aviso((r and r.mensaje) or 'El aserradero no puede atenderte ahora.', 'error')
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
    -- Si en estos 280 ms se ha vuelto a abrir, el 'cerrar' tardio no puede
    -- esconder el panel nuevo (que se quedaria con el raton y sin pantalla).
    SetTimeout(280, function() if not abierto then L.Nui('cerrar') end end)
    CreateThread(L.PedirYo)
end

-- Raton soltado a la fuerza (soltarraton, pantalla colgada): el panel se da
-- por cerrado y se esconde, o no volveria a abrirse.
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

for _, nombre in ipairs({
    'refrescar', 'empezar', 'terminar', 'herramienta', 'marcarCuartel', 'marcarBahia',
    'equipoInvitar', 'equipoSalir', 'equipoExpulsar',
}) do
    RegisterNUICallback(nombre, function(d, cb)
        local r = lib.callback.await('origen_lumber:panel:' .. nombre, false, ConCercanos(d))
        cb(r or { ok = false, mensaje = 'El aserradero no contesta.' })
        if r and r.ok and r.punto then SetNewWaypoint(r.punto.x + 0.0, r.punto.y + 0.0) end
        if r and r.ok and nombre == 'empezar' then
            CreateThread(function()
                Wait(600)
                Vehiculos.mio = lib.callback.await('origen_lumber:miVehiculo', false)
            end)
        end
        if r and r.ok and nombre == 'terminar' then Vehiculos.mio = nil end
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

AddEventHandler('onResourceStop', function(r)
    if r ~= GetCurrentResourceName() then return end
    if abierto then SetNuiFocus(false, false) end
    if encargado then Monte.Borrar(encargado) end
end)
