--[[ ── La cooperativa y su panel ──────────────────────────────────────────────

     Tres NPC abren el MISMO panel, cada uno por su sección. El panel es un
     menú lateral de la casa (skill `origen-riel`): el foco se suelta al
     instante al cerrar y el desmontaje espera a que acabe la animación. ]]

local C = Config.Cooperativa
local abierto = false

-- ── En el mapa ────────────────────────────────────────────────────────────
--[[ Los dos mapas de la casa (el grande y el minimapa) leen el registro de
     origen_map: la cooperativa con el tractor, en Trabajos, y tus parcelas con
     el brote en el rosa de «lo tuyo», como las casas propias. ]]

local COLOR_MIO = '#fc0259'

CreateThread(function()
    OrigenMapa.Poner('cooperativa', {
        x = C.centro.x, y = C.centro.y, z = C.centro.z,
        cat = 'trabajos',
        icono = 'tractor',
        nombre = C.nombre,
    })
end)

--[[ Tus parcelas. G.parcelas se vacía al alejarse de la finca (no hace falta
     tenerlas en memoria), pero las tuyas se tienen que seguir viendo desde la
     ciudad: con la lista vacía se deja lo que ya estaba puesto. ]]
local marcadas = ''
local function MarcarParcelas()
    if not next(G.parcelas) then return end
    local ids = {}
    for id, v in pairs(G.parcelas) do
        if G.EsMia(v) then ids[#ids + 1] = id end
    end
    table.sort(ids)
    local huella = table.concat(ids, ',')
    if huella == marcadas then return end
    marcadas = huella
    local puntos = {}
    for _, id in ipairs(ids) do
        local cfg = Granja.Parcela(id)
        puntos[#puntos + 1] = {
            id = id,
            x = cfg.centro.x, y = cfg.centro.y, z = cfg.centro.z,
            cat = 'trabajos',
            icono = 'brote',
            color = COLOR_MIO,
            propio = true,
            nombre = cfg.nombre,
        }
    end
    OrigenMapa.PonerVarios('parcela', puntos)
end
AddEventHandler('origen_farming:c:parcela', MarcarParcelas)

--[[ La báscula siempre está en el mapa (29/09, el usuario: no se veía), y
     mientras llevas cosecha (en las manos o en la camioneta alquilada) late,
     porque es a donde hay que ir ahora. La primera caja de la partida, además,
     lo explica y marca la ruta si no llevas ya un destino. Los silos y el
     lavadero, también en el mapa. ]]
local basculaPuesta, explicado = nil, false

local function PonerBascula(late)
    local b = C.bascula.coords
    OrigenMapa.Poner('bascula', {
        x = b.x, y = b.y, z = b.z,
        cat = 'trabajos',
        icono = 'caja',
        nombre = late and 'Báscula: entrega la cosecha' or 'Báscula de la cooperativa',
        pulso = late or nil,
    })
end

CreateThread(function()
    local P = Config.Planta and Config.Planta.maquinas
    if not P then return end
    if P.silo then
        OrigenMapa.Poner('silos', {
            x = P.silo.x, y = P.silo.y, z = P.silo.z, cat = 'trabajos', icono = 'brote',
            nombre = 'Silos de grano de la cooperativa',
        })
    end
    if P.lavadora then
        OrigenMapa.Poner('lavadero', {
            x = P.lavadora.x, y = P.lavadora.y, z = P.lavadora.z, cat = 'trabajos', icono = 'caja',
            nombre = 'Lavadero y envasado de verdura',
        })
    end
end)

local function LlevoCosecha()
    local c = G.carga
    if c and c.tipo ~= 'paca' then return true end
    local mio = Tractor.mio
    if mio and mio.tipo == 'camioneta' then
        local ent = Tractor.Entidad(mio.vehiculo)
        -- Fuera de alcance no se sabe qué lleva: se deja como estaba.
        if not ent then return basculaPuesta end
        local cajas = Entity(ent).state.granjaCajas
        return cajas ~= nil and #cajas > 0
    end
    return false
end

CreateThread(function()
    local b = C.bascula.coords
    while true do
        local llevo = LlevoCosecha()
        if llevo ~= basculaPuesta then
            basculaPuesta = llevo
            PonerBascula(llevo)
        end
        if llevo and not explicado then
            explicado = true
            local lejos = Granja.Plano(GetEntityCoords(cache.ped), b) > 60.0
            if lejos and not DoesBlipExist(GetFirstBlipInfoId(8)) then
                SetNewWaypoint(b.x + 0.0, b.y + 0.0)
            end
            G.Aviso('Lleva la cosecha a la báscula de la cooperativa (el aro rosa junto al granero, marcado en el mapa). '
                .. 'Después véndela hablando con el del almacén.', 'inform', 9000)
        end
        Wait(1000)
    end
end)

-- ── Los NPC, solo cuando hay alguien cerca ────────────────────────────────

local npcs = {}

local function CrearNPC(cfg)
    local hash = GetHashKey(cfg.modelo)
    if not pcall(lib.requestModel, hash, 8000) then return nil end
    local c = cfg.coords
    -- A la altura del punto tal cual: con el «- 1.0» de otros recursos se
    -- quedaban medio enterrados (lo vio el usuario en el juego).
    local ped = Rastro.Marcar(CreatePed(4, hash, c.x, c.y, c.z, c.w, false, false))
    SetModelAsNoLongerNeeded(hash)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_CLIPBOARD', 0, true)
    return ped
end

for clave, cfg in pairs(C.Peds) do
    local punto = lib.points.new({ coords = cfg.coords.xyz, distance = 80.0 })
    local conTexto = false

    function punto:onEnter()
        if npcs[clave] then return end
        npcs[clave] = CrearNPC(cfg)
    end

    function punto:onExit()
        if npcs[clave] and DoesEntityExist(npcs[clave]) then DeleteEntity(npcs[clave]) end
        npcs[clave] = nil
        if conTexto then G.QuitarAyuda('npc:' .. clave) conTexto = false end
    end

    function punto:nearby()
        local cerca = self.currentDistance <= 2.3 and not abierto and not G.carga and not cache.vehicle
        if cerca and not conTexto then
            conTexto = true
            G.Ayuda('npc:' .. clave, 'E', cfg.texto)
        elseif not cerca and conTexto then
            conTexto = false
            G.QuitarAyuda('npc:' .. clave)
        end
        if cerca and IsControlJustReleased(0, 38) then
            conTexto = false
            G.QuitarAyuda('npc:' .. clave)
            AbrirPanel(cfg.seccion)
        end
    end
end

-- ── Abrir y cerrar ────────────────────────────────────────────────────────

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

function AbrirPanel(seccion, relevo)
    if abierto then return end
    abierto = true
    local r = lib.callback.await('origen_farming:panel:abrir', false, ConCercanos({}))
    if not r or not r.datos then
        abierto = false
        -- Reabierto justo al cerrar: el 'cerrar' tardio se lo salto al verlo
        -- abierto, asi que el panel viejo sigue pintado. Fuera.
        G.Nui('cerrar')
        G.Aviso((r and r.mensaje) or 'La cooperativa no puede atenderte ahora.', 'error')
        return
    end
    r.datos.seccion = seccion or 'parcelas'
    r.datos.relevo = relevo == true
    G.panelAbierto = true
    G.Nui('celda', { visible = false })
    SetNuiFocus(true, true)
    G.Nui('abrir', r.datos)
end

function CerrarPanel()
    if not abierto then return end
    abierto = false
    G.panelAbierto = false
    SetNuiFocus(false, false)
    -- Si en estos 280 ms se ha vuelto a abrir, el 'cerrar' tardio no puede
    -- esconder el panel nuevo (que se quedaria con el raton y sin pantalla).
    SetTimeout(280, function() if not abierto then G.Nui('cerrar') end end)
    CreateThread(G.Refrescar)
end

-- Raton soltado a la fuerza (soltarraton, pantalla colgada): el panel se da
-- por cerrado y se esconde, o no volveria a abrirse.
OrigenFoco.AlSoltar(function() CerrarPanel() end)

exports('EstaAbierto', function() return abierto end)

CreateThread(function()
    while true do
        Wait(1000)
        if abierto and #(GetEntityCoords(cache.ped) - C.centro) > C.radio then CerrarPanel() end
    end
end)

-- ── Lo que pide la pantalla ───────────────────────────────────────────────

RegisterNUICallback('cerrar', function(_, cb)
    CerrarPanel()
    cb({ ok = true })
end)

--- Las que van tal cual al servidor.
for _, nombre in ipairs({
    'refrescar', 'jornada', 'dejar', 'riego', 'marcarCampo', 'comprar',
    'venderAlmacen', 'venderTodo', 'retirar', 'venderInventario', 'entregarPedido', 'alquilarVehiculo',
    'devolverVehiculo', 'equipoInvitar', 'equipoSalir', 'equipoExpulsar',
}) do
    RegisterNUICallback(nombre, function(d, cb)
        local r = lib.callback.await('origen_farming:panel:' .. nombre, false, ConCercanos(d))
        cb(r or { ok = false, mensaje = 'La cooperativa no contesta.' })
        if r and r.ok and nombre == 'dejar' then
            CreateThread(G.Refrescar)
        end
        if r and r.ok and r.punto then
            SetNewWaypoint(r.punto.x + 0.0, r.punto.y + 0.0)
        end
        if r and r.ok and nombre == 'alquilarVehiculo' then
            -- El tractor espera fuera: el panel se cierra desde la pantalla.
            CreateThread(function()
                Wait(600)
                Tractor.mio = lib.callback.await('origen_farming:miVehiculo', false)
            end)
        end
    end)
end

RegisterNUICallback('marcar', function(d, cb)
    local cfg = Granja.Parcela(d and d.parcela)
    if cfg then
        SetNewWaypoint(cfg.centro.x + 0.0, cfg.centro.y + 0.0)
        G.Aviso('Ruta marcada a ' .. cfg.nombre .. '.', 'success')
    end
    cb({ ok = cfg ~= nil })
end)

RegisterNUICallback('marcarVehiculo', function(_, cb)
    local mio = Tractor.mio
    local ent = mio and Tractor.Entidad(mio.vehiculo)
    if ent then
        local c = GetEntityCoords(ent)
        SetNewWaypoint(c.x, c.y)
        G.Aviso('Ruta marcada a lo que tienes alquilado.', 'success')
        return cb({ ok = true })
    end
    cb({ ok = false, mensaje = 'No veo tu vehículo desde aquí.' })
end)

--- Los jugadores que tienes cerca, para invitar sin preguntar ids.
RegisterNUICallback('cercanos', function(_, cb)
    local lista = {}
    local yo = GetEntityCoords(cache.ped)
    for _, id in ipairs(GetActivePlayers()) do
        if id ~= cache.playerId then
            local d = #(GetEntityCoords(GetPlayerPed(id)) - yo)
            if d <= 10.0 then lista[#lista + 1] = { id = GetPlayerServerId(id), metros = math.floor(d) } end
        end
    end
    table.sort(lista, function(a, b) return a.metros < b.metros end)
    cb({ ok = true, cerca = lista })
end)

AddEventHandler('onResourceStop', function(r)
    if r ~= GetCurrentResourceName() then return end
    if abierto then SetNuiFocus(false, false) end
    for _, ped in pairs(npcs) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
end)
