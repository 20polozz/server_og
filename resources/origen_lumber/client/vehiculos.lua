--[[ ── La maquinaria en el cliente ────────────────────────────────────────────

     Lo que se ve lo pinta cada cliente desde las state bags de los vehículos:
       remolque   `lumberCarga` { huecos, cinchas, cable }: los troncos en
                  sus huecos, las cinchas por encima y el cable del cabrestante
                  hasta el tronco enganchado
     Y las animaciones que avisa el servidor: un tronco que sube por el cable
     (`subida`) y la carga que rueda al patio al entregarla (`entrega`).

     Quien conduce su camión no puede arrancar con carga sin cinchas.

     Dos tipos (Config.Vehiculos.tipos): el camión con remolque y la
     camioneta, que lleva la carga en su propia caja con el portón abierto.
     Todo lo que depende del tipo (huecos, cabrestante, cinchas) se lee del
     tipo que publica el servidor en la state bag de la carga. ]]

Vehiculos = { mio = nil }

local V = Config.Vehiculos
local T = Config.Tronco

--- El tipo de lo que lleva la carga (lo publica el servidor en la bag).
local function Tipo(rem)
    local bag = rem and Entity(rem).state.lumberCarga
    local id = bag and bag.tipo or (Vehiculos.mio and Vehiculos.mio.tipo) or 'camion'
    return V.tipos[id] or V.tipos.camion, id
end
local TECLA_E, TECLA_G, TECLA_H, TECLA_X = 38, 47, 74, 73

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

-- ── Los huecos del remolque ───────────────────────────────────────────────

local HUECOS = {}
for id in pairs(V.tipos) do HUECOS[id] = Lumber.Huecos(id) end

local function Huecos(rem)
    local _, id = Tipo(rem)
    return HUECOS[id] or HUECOS.camion
end

--- Punto del cabrestante en el mundo (en el camión, el lado derecho del
--- remolque; en la camioneta, junto al portón).
local function PuntoCabrestante(rem)
    local c = Tipo(rem).cabrestante
    return GetOffsetFromEntityInWorldCoords(rem, c.lado, c.adelante, 0.0)
end
Vehiculos.PuntoCabrestante = PuntoCabrestante

-- ── Alquiler: salir con el vehículo ───────────────────────────────────────

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

RegisterNetEvent('origen_lumber:vehiculoListo', function(vehiculoNet, remolqueNet, tipo)
    Vehiculos.mio = { vehiculo = vehiculoNet, remolque = remolqueNet, tipo = tipo }
    if L.panelAbierto and CerrarPanel then CerrarPanel() end
    local vehiculo = Entidad(vehiculoNet, 6000)
    if not vehiculo then return L.Aviso('No encuentro el vehículo.', 'error') end
    Controlar(vehiculo)
    AlSuelo(vehiculo)
    pcall(function() exports.origen_fuel:SetFuel(vehiculo, 100.0) end)
    SetVehicleEngineOn(vehiculo, true, true, false)
    TaskWarpPedIntoVehicle(cache.ped, vehiculo, -1)
    local remolque = remolqueNet and remolqueNet ~= vehiculoNet and Entidad(remolqueNet, 6000)
    if remolque then
        Controlar(remolque)
        AlSuelo(remolque)
        Wait(500)
        AttachVehicleToTrailer(vehiculo, remolque, 1.1)
    end
end)

CreateThread(function()
    Wait(3000)
    Vehiculos.mio = lib.callback.await('origen_lumber:miVehiculo', false)
end)

--- Lo que lleva la carga: el remolque del camión o la propia camioneta.
function Vehiculos.MiRemolque()
    local mio = Vehiculos.mio
    return mio and Entidad(mio.remolque) or nil
end

--[[ Los vehículos del equipo a la vista (el tuyo incluido): cada segundo se
     mira el pool y se apuntan los que llevan carga de alguien de tu equipo.
     { rem, veh } — en la camioneta los dos son el mismo. ]]
local delEquipo = {}
CreateThread(function()
    while true do
        local lista = {}
        if L.Jornada() then
            local pos = GetEntityCoords(cache.ped)
            for _, ent in ipairs(GetGamePool('CVehicle')) do
                local bag = Entity(ent).state.lumberVehiculo
                if bag and Equipo.Mismo(bag.cid, L.cid) and #(GetEntityCoords(ent) - pos) < 200.0 then
                    local rem = bag.remolque and Entidad(bag.remolque) or ent
                    if rem then lista[#lista + 1] = { rem = rem, veh = ent } end
                end
            end
        end
        delEquipo = lista
        Wait(1000)
    end
end)

--- El vehículo del equipo con el que estás: el que conduces, o aquel cuya
--- palanca tienes a menos de `metros`. Devuelve rem, veh.
local function AMano(metros)
    if cache.vehicle then
        for _, v in ipairs(delEquipo) do
            if v.veh == cache.vehicle then return v.rem, v.veh end
        end
        return nil
    end
    local pos = GetEntityCoords(cache.ped)
    local mejor, dMejor
    for _, v in ipairs(delEquipo) do
        if DoesEntityExist(v.rem) then
            local d = #(PuntoCabrestante(v.rem) - pos)
            if d <= metros and (not dMejor or d < dMejor) then mejor, dMejor = v, d end
        end
    end
    if mejor then return mejor.rem, mejor.veh end
    return nil
end

--- Un vehículo del equipo a tiro de cable y sin cinchas (para enganchar).
function Vehiculos.MiCamion()
    local pos = GetEntityCoords(cache.ped)
    for _, v in ipairs(delEquipo) do
        local bag = DoesEntityExist(v.rem) and Entity(v.rem).state.lumberCarga
        if bag and not bag.cinchas and not bag.cable and (bag.n or 0) < (bag.max or 99)
            and #(PuntoCabrestante(v.rem) - pos) <= Tipo(v.rem).cabrestante.alcance + 3.0 then
            return v.rem
        end
    end
    return nil
end

-- ── Lo que se ve en los remolques ─────────────────────────────────────────

local pintados = {}     -- [remolqueEnt] = { claves = {[k] = especie}, props = {[k] = ent}, cinchas = {}, cable }
local escondidos = {}   -- ['remNet:k'] = true mientras baja por la animación

local function Tronco(x, y, z)
    local hash = GetHashKey(T.modelo)
    if not Monte.Cargar(hash) then return nil end
    local ent = Rastro.Marcar(CreateObjectNoOffset(hash, x + 0.0, y + 0.0, z + 0.0, false, false, false))
    SetEntityCollision(ent, false, false)
    return ent
end

--- Un cable entre dos entidades. `tipo` es el de GTA, medido en el juego:
--- 3 cable de acero trenzado (cabrestante), 2 cuerda (cinchas).
local function Cable(desde, hasta, entA, entB, tipo)
    RopeLoadTextures()
    local fin = GetGameTimer() + 1000
    while not RopeAreTexturesLoaded() and GetGameTimer() < fin do Wait(0) end
    local largo = math.max(0.5, #(desde - hasta))
    local cuerda = AddRope(desde.x, desde.y, desde.z, 0.0, 0.0, 0.0, largo, tipo or 3, largo, 0.5, 0.5, false, false, false, 1.0, false, 0)
    if entA and entB then
        AttachEntitiesToRope(cuerda, entA, entB, desde.x, desde.y, desde.z, hasta.x, hasta.y, hasta.z, largo, false, false, 0, 0)
    end
    return Rastro.Cable(cuerda)
end
Vehiculos.Cable = Cable

--[[ De dónde sale el cable del cabrestante: un punto invisible pegado al
     chasis del remolque, en el lateral delantero. Antes era un gancho a 40 cm
     por encima de la plataforma y el cable parecía salir del aire. ]]
local function Ancla(rem)
    local c = GetEntityCoords(rem)
    local a = Rastro.Marcar(CreateObject(GetHashKey('prop_rope_hook_01'), c.x, c.y, c.z + 2, false, false, false))
    SetEntityCollision(a, false, false)
    SetEntityVisible(a, false, false)
    local o = Tipo(rem).cabrestante.ancla or vec3(1.3, 3.9, 0.25)
    AttachEntityToEntity(a, rem, 0, o.x, o.y, o.z, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
    return a
end

local function LimpiarRemolque(rem)
    local p = pintados[rem]
    if not p then return end
    for _, e in pairs(p.props) do Monte.Borrar(e) end
    if p.cable then Rastro.QuitarCable(p.cable.cuerda) Monte.Borrar(p.cable.ancla) end
    pintados[rem] = nil
end

local function PintarRemolque(rem, bag)
    local p = pintados[rem]
    if not p then
        p = { claves = {}, props = {}, cinchasOn = false }
        pintados[rem] = p
    end
    local net = NetworkGetNetworkIdFromEntity(rem)
    local HUECOS = Huecos(rem)
    local cfg = Tipo(rem)
    -- Los troncos, hueco a hueco.
    for k = 1, #HUECOS do
        local h = bag.huecos and bag.huecos[tostring(k)]
        local esconder = escondidos[net .. ':' .. k]
        local quiere = h and not esconder and h.e or nil
        if p.claves[k] ~= quiere then
            Monte.Borrar(p.props[k])
            p.props[k] = nil
            p.claves[k] = quiere
            if quiere then
                local c = GetEntityCoords(rem)
                local e = Tronco(c.x, c.y, c.z + 3.0)
                if e then
                    local o = HUECOS[k]
                    -- Todos paralelos: un ángulo distinto por tronco dejaba la
                    -- carga con pinta de haberse caído sola encima.
                    AttachEntityToEntity(e, rem, 0, o.x, o.y, o.z, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                    p.props[k] = e
                end
            end
        end
    end
    -- Las cinchas se pintan cada fotograma (ver abajo): aquí solo se apunta
    -- qué filas llevan carga y a qué altura.
    local cinchas = bag.cinchas and (bag.n or 0) > 0
    p.cinchasOn = cinchas
    if cinchas then
        local filas, alto = {}, 0
        for k in pairs(bag.huecos or {}) do
            local o = HUECOS[tonumber(k)]
            if o then
                filas[o.y] = true
                alto = math.max(alto, o.z + (cfg.carga.diametro or 0.58) / 2)
            end
        end
        p.filas, p.alto = filas, alto
    end
    -- El cable del cabrestante hasta el tronco enganchado.
    local cable = bag.cable
    local enAnimacion = Vehiculos.subiendo and Vehiculos.subiendo.id == cable
    local troncoEnt = cable and not enAnimacion and Monte.TroncoEnt(cable) or nil
    if p.cable and (p.cable.id ~= cable or not troncoEnt or p.cable.tronco ~= troncoEnt) then
        Rastro.QuitarCable(p.cable.cuerda)
        Monte.Borrar(p.cable.ancla)
        p.cable = nil
    end
    if troncoEnt and not p.cable then
        local c = GetEntityCoords(rem)
        local ancla = Ancla(rem)
        Wait(0)
        p.cable = { id = cable, tronco = troncoEnt, ancla = ancla,
            cuerda = Cable(GetEntityCoords(ancla), GetEntityCoords(troncoEnt), ancla, troncoEnt) }
    end
end

CreateThread(function()
    while true do
        local pos = GetEntityCoords(cache.ped)
        local vistos = {}
        if L.cerca or Vehiculos.mio then
            for _, veh in ipairs(GetGamePool('CVehicle')) do
                if #(GetEntityCoords(veh) - pos) < 160.0 then
                    local st = Entity(veh).state
                    local bag = st.lumberCarga
                    if bag then
                        vistos[veh] = true
                        PintarRemolque(veh, bag)
                    end
                end
            end
        end
        for rem in pairs(pintados) do
            if not vistos[rem] or not DoesEntityExist(rem) then LimpiarRemolque(rem) end
        end
        Wait(400)
    end
end)

--[[ Las cinchas: bandas naranjas de trinquete que salen del canto del
     remolque, suben por encima de los troncos y bajan al otro canto. Van
     pegadas al remolque (se calculan con su posición en cada fotograma), dos
     por cada fila de troncos cargada. Los cables de GTA no se quedan quietos
     encima de la carga; esto sí. ]]
local function Banda(rem, y, puntos, ancho)
    local col = { 235, 120, 20, 255 }
    for i = 1, #puntos - 1 do
        local a, b = puntos[i], puntos[i + 1]
        local a1 = GetOffsetFromEntityInWorldCoords(rem, a.x, y - ancho, a.z)
        local a2 = GetOffsetFromEntityInWorldCoords(rem, a.x, y + ancho, a.z)
        local b1 = GetOffsetFromEntityInWorldCoords(rem, b.x, y - ancho, b.z)
        local b2 = GetOffsetFromEntityInWorldCoords(rem, b.x, y + ancho, b.z)
        DrawPoly(a1.x, a1.y, a1.z, b1.x, b1.y, b1.z, b2.x, b2.y, b2.z, col[1], col[2], col[3], col[4])
        DrawPoly(a1.x, a1.y, a1.z, b2.x, b2.y, b2.z, a2.x, a2.y, a2.z, col[1], col[2], col[3], col[4])
        DrawPoly(a1.x, a1.y, a1.z, b2.x, b2.y, b2.z, b1.x, b1.y, b1.z, col[1], col[2], col[3], col[4])
        DrawPoly(a1.x, a1.y, a1.z, a2.x, a2.y, a2.z, b2.x, b2.y, b2.z, col[1], col[2], col[3], col[4])
    end
end

CreateThread(function()
    while true do
        local hay = false
        local pos = GetEntityCoords(cache.ped)
        for rem, p in pairs(pintados) do
            if p.cinchasOn and p.filas and DoesEntityExist(rem) and #(GetEntityCoords(rem) - pos) < 90.0 then
                hay = true
                local cfg = Tipo(rem)
                local base = cfg.carga.suelo + 0.02
                local top = p.alto + 0.03
                local w = cfg.cinchas.ancho
                local puntos = {
                    vec3(-w, 0, base - 0.25), vec3(-w, 0, base), vec3(-w + 0.31, 0, top - 0.14), vec3(-w * 0.44, 0, top),
                    vec3(w * 0.44, 0, top), vec3(w - 0.31, 0, top - 0.14), vec3(w, 0, base), vec3(w, 0, base - 0.25),
                }
                for fila in pairs(p.filas) do
                    Banda(rem, fila - cfg.cinchas.separacion, puntos, 0.04)
                    Banda(rem, fila + cfg.cinchas.separacion, puntos, 0.04)
                end
            end
        end
        Wait(hay and 0 or 400)
    end
end)

-- ── Las animaciones del cable ─────────────────────────────────────────────

--- Un tronco sube por el cable: se arrastra por el suelo hasta el costado del
--- remolque y de ahí sube a su hueco. Lo ven todos los de alrededor.
RegisterNetEvent('origen_lumber:subida', function(troncoId, remNet, k, ms)
    local rem = Entidad(remNet, 1000)
    local v = L.troncos[troncoId]
    local o = rem and Huecos(rem)[k]
    if not rem or not v or not o then return end
    local lado = Tipo(rem).cabrestante.lado + 0.7
    Vehiculos.subiendo = { id = troncoId }
    Monte.Ocultar(troncoId, true)
    local desde = vec3(v.p.x, v.p.y, v.p.z)
    local e = Tronco(desde.x, desde.y, desde.z)
    if not e then Vehiculos.subiendo = nil Monte.Ocultar(troncoId, false) return end
    local c = GetEntityCoords(rem)
    local ancla = Ancla(rem)
    Monte.Tumbado(e, desde.x, desde.y, desde.z, v.p.h or 0.0, T.largo, 0.3)
    Wait(0)
    local cuerda = Cable(GetEntityCoords(ancla), GetEntityCoords(e), ancla, e)
    local t0 = GetGameTimer()
    local rumboRem = GetEntityHeading(rem)
    local h0 = v.p.h or 0.0
    while true do
        local t = (GetGameTimer() - t0) / ms
        if t >= 1.0 or not DoesEntityExist(rem) then break end
        -- Dónde está el costado del remolque y el hueco ahora (el remolque puede moverse un poco).
        local costado = GetOffsetFromEntityInWorldCoords(rem, lado, o.y, 0.0)
        local hueco = GetOffsetFromEntityInWorldCoords(rem, o.x, o.y, o.z)
        local suelo = Monte.SueloYa(costado.x, costado.y, costado.z) or costado.z
        rumboRem = GetEntityHeading(rem)
        -- Rumbo: gira hasta ir paralelo al remolque.
        local dh = ((rumboRem - h0 + 540) % 360) - 180
        if t < 0.72 then
            local u = t / 0.72
            local x = desde.x + (costado.x - desde.x) * u
            local y = desde.y + (costado.y - desde.y) * u
            Monte.Tumbado(e, x, y, desde.z, h0 + dh * u, T.largo, 0.3, true)
        else
            local u = (t - 0.72) / 0.28
            local x = costado.x + (hueco.x - costado.x) * u
            local y = costado.y + (hueco.y - costado.y) * u
            local z = (suelo + 0.3) + (hueco.z - suelo - 0.3) * math.sin(u * math.pi / 2) + math.sin(u * math.pi) * 0.5
            SetEntityCoordsNoOffset(e, x, y, z, false, false, false)
            SetEntityRotation(e, 0.0, 0.0, rumboRem, 2, true)
        end
        Wait(0)
    end
    Wait(600)
    Rastro.QuitarCable(cuerda)
    Monte.Borrar(ancla)
    Monte.Borrar(e)
    Monte.Ocultar(troncoId, false)
    Vehiculos.subiendo = nil
end)

RegisterNetEvent('origen_lumber:subidaFin', function()
    Vehiculos.subiendo = nil
end)

--- Al entregar, los troncos bajan rodando del remolque al patio uno tras
--- otro, de arriba abajo, y desaparecen con una polvareda.
local function Rodar(rem, remNet, k, ms)
    local o = Huecos(rem)[k]
    if not o then return end
    local clave = remNet .. ':' .. k
    escondidos[clave] = true
    local hueco = GetOffsetFromEntityInWorldCoords(rem, o.x, o.y, o.z)
    local rampa = Config.Aserradero.rampa
    local e = Tronco(hueco.x, hueco.y, hueco.z)
    if not e then escondidos[clave] = nil return end
    local rumbo = GetEntityHeading(rem)
    local t0 = GetGameTimer()
    local suelo = Monte.Suelo(rampa.x, rampa.y, rampa.z) or rampa.z
    while true do
        local t = (GetGameTimer() - t0) / ms
        if t >= 1.0 then break end
        local x = hueco.x + (rampa.x - hueco.x) * t
        local y = hueco.y + (rampa.y - hueco.y) * t
        local z = hueco.z + ((suelo + 0.3) - hueco.z) * t + math.sin(t * math.pi) * 0.4
        SetEntityCoordsNoOffset(e, x, y, z, false, false, false)
        -- Rueda de lado mientras baja.
        SetEntityRotation(e, 0.0, t * 540.0, rumbo, 2, true)
        Wait(0)
    end
    Monte.Polvo(rampa.x, rampa.y, suelo + 0.2, 1.2)
    Monte.Borrar(e)
    SetTimeout(3000, function() escondidos[clave] = nil end)
end

RegisterNetEvent('origen_lumber:entrega', function(remNet, ks, ms)
    local rem = Entidad(remNet, 1000)
    if not rem or type(ks) ~= 'table' or #ks == 0 then return end
    -- Todos caben en la entrega: cada uno sale un poco después del anterior.
    local paso = math.floor(ms * 0.8 / #ks)
    local dura = math.max(900, math.floor(ms * 0.35))
    for i, k in ipairs(ks) do
        SetTimeout((i - 1) * paso, function() Rodar(rem, remNet, k, dura) end)
    end
end)

-- ── A pie junto a tu camión ───────────────────────────────────────────────

local function Pedir(nombre, ...)
    local r = lib.callback.await('origen_lumber:' .. nombre, false, ...)
    if r and r.mensaje then L.Aviso(r.mensaje, r.ok and 'success' or 'error') end
    return r
end

local function EnDescarga(rem)
    local d = Config.Aserradero.descarga
    return #(GetEntityCoords(rem).xy - d.coords.xy) <= d.radio + 4.0
end

--[[ El cuadro de la bahía de descarga: mientras llevas el camión con carga,
     se pinta en el suelo del patio el sitio donde hay que dejar el remolque.
     Verde cuando ya está dentro; naranja mientras no. ]]
CreateThread(function()
    local D = Config.Aserradero.descarga
    while true do
        local espera = 500
        local rem = AMano(12.0) or Vehiculos.MiRemolque()
        if rem and not L.panelAbierto then
            local pos = GetEntityCoords(cache.ped)
            local bag = Entity(rem).state.lumberCarga or {}
            if (bag.n or 0) > 0 and #(pos.xy - D.coords.xy) < 70.0 then
                espera = 0
                local dentro = EnDescarga(rem)
                local cuadro = Tipo(rem).cuadro
                Monte.Cuadro(D.coords, D.coords.w, cuadro.largo, cuadro.ancho, 0.35,
                    dentro and { 60, 200, 110, 150 } or { 240, 150, 40, 140 })
            end
        end
        Wait(espera)
    end
end)

CreateThread(function()
    while true do
        local espera = 600
        local rem, veh = AMano(3.0)
        local ped = cache.ped
        if rem and not L.panelAbierto and not L.ocupado then
            local bag = Entity(rem).state.lumberCarga or {}
            local especies, cuenta = {}, {}
            for _, h in pairs(bag.huecos or {}) do cuenta[h.e] = (cuenta[h.e] or 0) + 1 end
            for e, n in pairs(cuenta) do especies[#especies + 1] = { nombre = Config.Especies[e] and Config.Especies[e].nombre or e, n = n } end
            -- Lo que se cobrará al entregar (lo calcula el servidor igual).
            local valor = 0
            for e, n in pairs(cuenta) do valor = valor + (Config.Especies[e] and Config.Especies[e].pago or 0) * n end
            if (bag.n or 0) >= (bag.max or 99) then valor = valor * (1 + Config.Entrega.lleno) end
            valor = math.floor(valor)

            if cache.vehicle and cache.vehicle == veh and GetPedInVehicleSeat(veh, -1) == ped then
                -- Conduciendo: no arranca con carga sin cinchas.
                espera = 0
                local bloqueo
                if (bag.n or 0) > 0 and not bag.cinchas then bloqueo = 'Pon las cinchas a la carga antes de arrancar.' end
                if bloqueo then
                    DisableControlAction(0, 71, true)
                    DisableControlAction(0, 72, true)
                    L.Ayuda('camion', 'F', bloqueo)
                else
                    L.QuitarAyuda('camion')
                end
                L.Tarjeta('camion', {
                    nombre = Tipo(rem).nombre, carga = bag.n or 0, max = bag.max or #Huecos(rem),
                    cinchas = bag.cinchas == true, cable = bag.cable ~= nil, especies = especies,
                    valor = valor, acciones = {},
                    ayuda = bloqueo or ((bag.n or 0) >= (bag.max or 12) and 'Lleno: a la bahía de entrega del aserradero.'
                        or 'Aparca junto a los troncos y bájate a la palanca del cabrestante.'),
                })
            elseif not cache.vehicle and #(GetEntityCoords(ped) - PuntoCabrestante(rem)) <= 3.0 then
                espera = 0
                local acciones, principal, alt = {}, nil, nil
                local ayuda
                if bag.cable then
                    principal = { 'E', 'Tirar del cable' }
                    acciones[#acciones + 1] = { tecla = 'E', texto = 'Tirar del cable' }
                    acciones[#acciones + 1] = { tecla = 'X', texto = 'Soltar el cable' }
                    ayuda = 'Tira: el tronco sube a su hueco.'
                elseif EnDescarga(rem) and (bag.n or 0) > 0 and not bag.cinchas then
                    principal = { 'E', ('Entregar la carga (%s)'):format(Lumber.Dinero(valor)) }
                    acciones[#acciones + 1] = { tecla = 'E', texto = ('Entregar %d troncos'):format(bag.n or 0) }
                    ayuda = 'Se cobra por tronco, al banco.'
                elseif not bag.cinchas then
                    ayuda = 'Engancha el cable a un tronco (a pie, junto al tronco).'
                end
                if bag.cable then
                    -- nada más: primero hay que terminar con el tronco del cable
                elseif bag.cinchas then
                    principal = principal or { 'H', 'Quitar las cinchas' }
                    acciones[#acciones + 1] = { tecla = 'H', texto = 'Quitar las cinchas' }
                    ayuda = EnDescarga(rem) and 'Quita las cinchas para entregar la carga.' or 'Carga atada: listo para arrancar.'
                elseif (bag.n or 0) > 0 then
                    alt = { 'H', 'Poner las cinchas' }
                    acciones[#acciones + 1] = { tecla = 'H', texto = 'Poner las cinchas' }
                    ayuda = 'Pon las cinchas para llevar la carga.'
                end
                if principal then L.Ayuda('camion', principal[1], principal[2], alt) else L.QuitarAyuda('camion') end
                L.Tarjeta('camion', {
                    nombre = Tipo(rem).nombre, carga = bag.n or 0, max = bag.max or #Huecos(rem),
                    cinchas = bag.cinchas == true, cable = bag.cable ~= nil, especies = especies,
                    valor = valor, acciones = acciones, ayuda = ayuda or '',
                })
                local punto = PuntoCabrestante(rem)
                if IsControlJustReleased(0, TECLA_E) then
                    L.QuitarAyuda('camion')
                    if bag.cable then
                        CreateThread(function()
                            Trabajo.Ejecutar('tirar', {}, punto, { anim = Config.Anims.palanca, texto = 'Tirando del cable' })
                        end)
                    elseif EnDescarga(rem) and (bag.n or 0) > 0 and not bag.cinchas then
                        CreateThread(function()
                            Trabajo.Ejecutar('entregar', {}, punto, { anim = Config.Anims.palanca, texto = 'Entregando la carga' })
                        end)
                    end
                elseif IsControlJustReleased(0, TECLA_H) then
                    CreateThread(function()
                        TaskStartScenarioInPlace(ped, 'PROP_HUMAN_BUM_BIN', 0, true)
                        Wait(1800)
                        ClearPedTasks(ped)
                        Pedir('cinchas')
                    end)
                elseif IsControlJustReleased(0, TECLA_X) and bag.cable then
                    CreateThread(function() Pedir('soltarCable') end)
                end
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

--[[ El portón de atrás de la camioneta va siempre abierto: los troncos
     miden 4 m y asoman por detrás. Lo abre quien la tiene (su cliente la
     controla y el juego lo reparte a los demás). ]]
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
    for rem in pairs(pintados) do LimpiarRemolque(rem) end
    local rem = Vehiculos.MiRemolque()
    if rem then FreezeEntityPosition(rem, false) end
end)
