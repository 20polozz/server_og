--[[ ── La maquinaria en el cliente ────────────────────────────────────────────

     Lo que se ve lo pinta cada cliente desde la state bag del vehículo:
       `minaCarga` { tipo, huecos = { ['k'] = veta }, n, max }: los pedruscos
       en sus huecos de la caja.
     Y la descarga que avisa el servidor: la piedra sale volando de la caja a
     la boca de la tolva, uno tras otro, y la planta la tritura.

     Dos tipos (Config.Vehiculos.tipos): la camioneta (con el portón siempre
     abierto) y el volquete. ]]

Vehiculos = { mio = nil }

local V = Config.Vehiculos
local CHICO = 'prop_rock_5_smash2'
local TECLA_E = 38

local function Tipo(veh)
    local bag = veh and Entity(veh).state.minaCarga
    local id = bag and bag.tipo or (Vehiculos.mio and Vehiculos.mio.tipo) or 'camioneta'
    return V.tipos[id] or V.tipos.camioneta, id
end

local function Entidad(netId, espera)
    local fin = GetGameTimer() + (espera or 0)
    repeat
        if netId and NetworkDoesNetworkIdExist(netId) then
            local ent = NetworkGetEntityFromNetworkId(netId)
            if ent and ent ~= 0 and DoesEntityExist(ent) then return ent end
        end
        if espera then Wait(100) end
    until GetGameTimer() >= fin
    return nil
end
Vehiculos.Entidad = Entidad

local function Controlar(ent)
    local fin = GetGameTimer() + 2000
    while not NetworkHasControlOfEntity(ent) and GetGameTimer() < fin do
        NetworkRequestControlOfEntity(ent)
        Wait(50)
    end
end

local HUECOS = {}
for id in pairs(V.tipos) do HUECOS[id] = Mina.Huecos(id) end

local function Huecos(veh)
    local _, id = Tipo(veh)
    return HUECOS[id] or HUECOS.camioneta
end

--- La trasera del vehículo en el mundo (donde se echa la piedra).
local function Trasera(veh)
    local o = Tipo(veh).trasera
    return GetOffsetFromEntityInWorldCoords(veh, o.x, o.y, o.z)
end
Vehiculos.Trasera = Trasera

-- ── Salir con el vehículo ─────────────────────────────────────────────────

local function AlSuelo(ent)
    local c = GetEntityCoords(ent)
    RequestCollisionAtCoord(c.x, c.y, c.z)
    local fin = GetGameTimer() + 1500
    local ok, z
    repeat
        ok, z = GetGroundZFor_3dCoord(c.x, c.y, c.z + 10.0, false)
        if not ok then Wait(50) end
    until ok or GetGameTimer() > fin
    if ok then SetEntityCoordsNoOffset(ent, c.x, c.y, z + 0.8, false, false, false) end
    SetVehicleOnGroundProperly(ent)
end

RegisterNetEvent('origen_mining:vehiculoListo', function(net, tipo)
    Vehiculos.mio = { vehiculo = net, tipo = tipo }
    if L.panelAbierto and CerrarPanel then CerrarPanel() end
    local veh = Entidad(net, 6000)
    if not veh then return L.Aviso('No encuentro el vehículo.', 'error') end
    Controlar(veh)
    AlSuelo(veh)
    -- La caja vacía: la camioneta trae de fábrica cajas de herramientas
    -- (extras) donde van los pedruscos.
    for i = 1, 14 do
        if DoesExtraExist(veh, i) then SetVehicleExtra(veh, i, true) end
    end
    pcall(function() exports.origen_fuel:SetFuel(veh, 100.0) end)
    SetVehicleEngineOn(veh, true, true, false)
    TaskWarpPedIntoVehicle(cache.ped, veh, -1)
end)

CreateThread(function()
    Wait(3000)
    Vehiculos.mio = lib.callback.await('origen_mining:miVehiculo', false)
end)

--[[ Los vehículos del equipo a la vista (el tuyo incluido): cada segundo se
     mira el pool y se apuntan los de alguien de tu equipo. ]]
local delEquipo = {}
CreateThread(function()
    while true do
        local lista = {}
        if L.Jornada() then
            local pos = GetEntityCoords(cache.ped)
            for _, ent in ipairs(GetGamePool('CVehicle')) do
                local bag = Entity(ent).state.minaVehiculo
                if bag and Equipo.Mismo(bag.cid, L.cid) and #(GetEntityCoords(ent) - pos) < 200.0 then
                    lista[#lista + 1] = ent
                end
            end
        end
        delEquipo = lista
        Wait(1000)
    end
end)

--- La trasera de un vehículo del equipo a menos de `metros`, a pie.
function Vehiculos.TraseraCerca(metros)
    if cache.vehicle then return nil end
    local pos = GetEntityCoords(cache.ped)
    local mejor, dMejor, vMejor
    for _, veh in ipairs(delEquipo) do
        if DoesEntityExist(veh) then
            local t = Trasera(veh)
            local d = #(t.xy - pos.xy)
            if d <= metros and (not dMejor or d < dMejor) then mejor, dMejor, vMejor = t, d, veh end
        end
    end
    return mejor, vMejor
end

-- ── Lo que se ve en las cajas ─────────────────────────────────────────────

local pintados = {}     -- [veh] = { claves = {[k] = veta}, props = {[k] = ent} }
local escondidos = {}   -- ['net:k'] = true mientras vuela a la tolva

local function Limpiar(veh)
    local p = pintados[veh]
    if not p then return end
    for _, e in pairs(p.props) do Cantera.Borrar(e) end
    pintados[veh] = nil
end

local function Pintar(veh, bag)
    local p = pintados[veh]
    if not p then
        p = { claves = {}, props = {} }
        pintados[veh] = p
    end
    local net = NetworkGetNetworkIdFromEntity(veh)
    local huecos = Huecos(veh)
    for k = 1, #huecos do
        local veta = bag.huecos and bag.huecos[tostring(k)]
        local quiere = veta and not escondidos[net .. ':' .. k] and veta or nil
        if p.claves[k] ~= quiere then
            Cantera.Borrar(p.props[k])
            p.props[k], p.claves[k] = nil, quiere
            if quiere then
                local c = GetEntityCoords(veh)
                local e = Cantera.Objeto(CHICO, c.x, c.y, c.z + 3.0, false)
                if e then
                    FreezeEntityPosition(e, false)
                    local o = huecos[k]
                    AttachEntityToEntity(e, veh, 0, o.x, o.y, o.z, 0.0, 0.0, k * 57.0, false, false, false, false, 2, true)
                    p.props[k] = e
                end
            end
        end
    end
end

CreateThread(function()
    while true do
        local pos = GetEntityCoords(cache.ped)
        local vistos = {}
        if L.cerca or Vehiculos.mio then
            for _, veh in ipairs(GetGamePool('CVehicle')) do
                if #(GetEntityCoords(veh) - pos) < 160.0 then
                    local bag = Entity(veh).state.minaCarga
                    if bag then
                        vistos[veh] = true
                        Pintar(veh, bag)
                    end
                end
            end
        end
        for veh in pairs(pintados) do
            if not vistos[veh] or not DoesEntityExist(veh) then Limpiar(veh) end
        end
        Wait(400)
    end
end)

-- ── La descarga en la tolva ───────────────────────────────────────────────

--- Un pedrusco vuela de su hueco a la boca de la tolva.
local function Volar(veh, net, k, ms)
    local o = Huecos(veh)[k]
    if not o then return end
    local clave = net .. ':' .. k
    escondidos[clave] = true
    local desde = GetOffsetFromEntityInWorldCoords(veh, o.x, o.y, o.z)
    local boca = Config.Planta.boca
    local e = Cantera.Objeto(CHICO, desde.x, desde.y, desde.z, false)
    if not e then escondidos[clave] = nil return end
    local t0 = GetGameTimer()
    while true do
        local t = (GetGameTimer() - t0) / ms
        if t >= 1.0 then break end
        local x = desde.x + (boca.x - desde.x) * t
        local y = desde.y + (boca.y - desde.y) * t
        local z = desde.z + (boca.z - desde.z) * t + math.sin(t * math.pi) * 1.4
        SetEntityCoordsNoOffset(e, x, y, z, false, false, false)
        SetEntityRotation(e, t * 400.0, t * 250.0, 0.0, 2, true)
        Wait(0)
    end
    Cantera.Efecto('core', 'ent_amb_stoner_rubble_drop', boca.x, boca.y, boca.z, 1.0)
    Cantera.Borrar(e)
    SetTimeout(3000, function() escondidos[clave] = nil end)
end

RegisterNetEvent('origen_mining:descarga', function(net, ks, vetas, ms)
    local veh = Entidad(net, 1000)
    if not veh or type(ks) ~= 'table' or #ks == 0 then return end
    local paso = math.floor(ms * 0.55 / #ks)
    local dura = math.max(800, math.floor(ms * 0.25))
    local boca = Config.Planta.boca
    Cantera.Polvo(boca.x, boca.y, boca.z + 0.5, 2.0)
    for i, k in ipairs(ks) do
        SetTimeout((i - 1) * paso, function() Volar(veh, net, k, dura) end)
    end
    -- La planta la tritura mientras va cayendo.
    if Planta and Planta.Triturar then
        SetTimeout(math.floor(dura * 0.8), function() Planta.Triturar(vetas, ms) end)
    end
end)

--[[ A pie, desde el borde: la piedra sale de las manos (o de la carretilla)
     y cae a la tolva, una tras otra. ]]
RegisterNetEvent('origen_mining:tolvaPie', function(src, vetas, ms)
    if type(vetas) ~= 'table' then return end
    local ped = Cantera.PedDe(src)
    if not ped then return end
    local boca = Config.Planta.boca
    local paso = math.floor(ms * 0.5 / math.max(1, #vetas))
    for i = 1, #vetas do
        SetTimeout(math.floor(ms * 0.35) + (i - 1) * paso, function()
            local desde = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.8, 0.1)
            local e = Cantera.Objeto(CHICO, desde.x, desde.y, desde.z, false)
            if not e then return end
            local t0, dura = GetGameTimer(), 700
            while true do
                local t = (GetGameTimer() - t0) / dura
                if t >= 1.0 then break end
                SetEntityCoordsNoOffset(e, desde.x + (boca.x - desde.x) * t, desde.y + (boca.y - desde.y) * t,
                    desde.z + (boca.z - desde.z) * t * t + math.sin(t * math.pi) * 0.5, false, false, false)
                SetEntityRotation(e, t * 300.0, t * 200.0, 0.0, 2, true)
                Wait(0)
            end
            Cantera.Efecto('core', 'ent_amb_stoner_rubble_drop', boca.x, boca.y, boca.z, 1.0)
            Cantera.Borrar(e)
        end)
    end
    if Planta and Planta.Triturar then SetTimeout(math.floor(ms * 0.6), function() Planta.Triturar(vetas, ms) end) end
end)

--[[ Detrás del tope de la tolva: con piedra encima (en brazos o en la carretilla) y
     cerca de la tolva, un aro en el suelo donde ponerse. ]]
CreateThread(function()
    while true do
        local espera = 500
        if L.Jornada() and not L.panelAbierto and not cache.vehicle and (L.Mano() or L.Empuja()) then
            local b, r = Mina.Borde()
            local pos = GetEntityCoords(cache.ped)
            if #(pos.xy - b.xy) < 60.0 then
                espera = 0
                local dentro = #(pos.xy - b.xy) <= r
                Cantera.Aro(b, r, 0.3, dentro and { 60, 200, 110, 160 } or { 240, 150, 40, 150 })
            end
        end
        Wait(espera)
    end
end)

-- ── Junto a tu vehículo ───────────────────────────────────────────────────

local function EnDescarga(veh)
    local centro, radio = Mina.Descarga()
    return #(GetEntityCoords(veh).xy - centro.xy) <= radio + 3.0
end

local function Resumen(bag)
    local cuenta, valor = {}, 0
    for _, veta in pairs(bag.huecos or {}) do cuenta[veta] = (cuenta[veta] or 0) + 1 end
    local vetas = {}
    for _, id in ipairs(Config.OrdenMateriales) do
        local n = cuenta[id]
        if n then
            vetas[#vetas + 1] = { nombre = Config.Materiales[id].nombre, n = n }
            valor = valor + (Config.Productos[id] and Config.Productos[id].precio or 0) * n
        end
    end
    if (bag.n or 0) >= (bag.max or 99) then valor = valor * (1 + Config.Descarga.lleno) end
    return vetas, math.floor(valor)
end

--[[ El cuadro de la tolva: mientras llevas el vehículo con carga cerca de la
     planta, se pinta en el suelo dónde aparcar marcha atrás. Verde dentro. ]]
CreateThread(function()
    while true do
        local espera = 500
        local mio = Vehiculos.mio
        local veh = cache.vehicle or (mio and Entidad(mio.vehiculo))
        if veh and not L.panelAbierto then
            local bag = Entity(veh).state.minaCarga
            local centro = Mina.Descarga()
            if bag and (bag.n or 0) > 0 and #(GetEntityCoords(cache.ped).xy - centro.xy) < 80.0 then
                espera = 0
                local cuadro = Tipo(veh).cuadro
                local _, _, rumbo = Mina.Descarga()
                Cantera.Cuadro(centro, rumbo, cuadro.largo, cuadro.ancho, 0.35,
                    EnDescarga(veh) and { 60, 200, 110, 150 } or { 240, 150, 40, 140 })
            end
        end
        Wait(espera)
    end
end)

CreateThread(function()
    while true do
        local espera = 500
        local ped = cache.ped
        local enJornada = L.Jornada() and not L.panelAbierto
        if enJornada and cache.vehicle and GetPedInVehicleSeat(cache.vehicle, -1) == ped then
            local bag = Entity(cache.vehicle).state.minaCarga
            if bag then
                local vetas, valor = Resumen(bag)
                local acciones = {}
                local ayuda = (bag.n or 0) >= (bag.max or 99) and 'Llena: a la tolva de la planta, marcha atrás en el cuadro.'
                    or 'Aparca junto a la roca y echa la piedra por detrás.'
                -- En el cuadro de la tolva se descarga sin bajarse: la caja se
                -- vacía sola en la tolva.
                if (bag.n or 0) > 0 and EnDescarga(cache.vehicle) and not L.ocupado then
                    espera = 0
                    acciones[1] = { tecla = 'E', texto = ('Descargar %d en la tolva'):format(bag.n) }
                    ayuda = 'Va a tu nombre: sale en el contenedor de la planta.'
                    L.Ayuda('camion', 'E', ('Descargar en la tolva (%d)'):format(bag.n))
                    if IsControlJustReleased(0, TECLA_E) then
                        L.QuitarAyuda('camion')
                        CreateThread(function() Trabajo.Ejecutar('descargar', {}, nil, {}) end)
                    end
                else
                    L.QuitarAyuda('camion')
                end
                L.Tarjeta('camion', {
                    nombre = Tipo(cache.vehicle).nombre, carga = bag.n or 0, max = bag.max or 0, vetas = vetas, valor = valor,
                    acciones = acciones, ayuda = ayuda,
                })
            else
                L.SinTarjeta('camion')
            end
        elseif enJornada and not cache.vehicle and not L.ocupado and not L.Mano() and not L.Empuja() then
            local punto, veh = Vehiculos.TraseraCerca(3.0)
            local bag = veh and Entity(veh).state.minaCarga
            if bag then
                espera = 0
                local vetas, valor = Resumen(bag)
                local acciones, ayuda = {}, nil
                if EnDescarga(veh) and (bag.n or 0) > 0 then
                    acciones[#acciones + 1] = { tecla = 'E', texto = ('Descargar %d en la tolva'):format(bag.n) }
                    ayuda = 'Va a tu nombre: sale en el contenedor de la planta.'
                    L.Ayuda('camion', 'E', ('Descargar en la tolva (%d)'):format(bag.n))
                    if IsControlJustReleased(0, TECLA_E) then
                        L.QuitarAyuda('camion')
                        CreateThread(function()
                            Trabajo.Ejecutar('descargar', {}, nil, {})
                        end)
                    end
                else
                    L.QuitarAyuda('camion')
                    ayuda = (bag.n or 0) > 0 and 'Lleva la carga a la tolva de la planta.' or 'Coge pedruscos y échalos aquí.'
                end
                L.Tarjeta('camion', { nombre = Tipo(veh).nombre, carga = bag.n or 0, max = bag.max or 0, vetas = vetas,
                    valor = valor, acciones = acciones, ayuda = ayuda })
            else
                L.SinTarjeta('camion')
                L.QuitarAyuda('camion')
            end
        else
            L.SinTarjeta('camion')
            L.QuitarAyuda('camion')
        end
        Wait(espera)
    end
end)

--[[ El portón de la camioneta va siempre abierto: se echa la piedra por
     detrás. Lo abre quien la tiene (su cliente la controla). ]]
CreateThread(function()
    while true do
        local espera = 2000
        local mio = Vehiculos.mio
        if mio and V.tipos[mio.tipo] and V.tipos[mio.tipo].porton then
            local veh = Entidad(mio.vehiculo)
            if veh and NetworkHasControlOfEntity(veh) and GetVehicleDoorAngleRatio(veh, 5) < 0.9 then
                SetVehicleDoorOpen(veh, 5, false, true)
            end
            espera = 1000
        end
        Wait(espera)
    end
end)

AddEventHandler('onResourceStop', function(r)
    if r ~= GetCurrentResourceName() then return end
    for veh in pairs(pintados) do Limpiar(veh) end
end)
