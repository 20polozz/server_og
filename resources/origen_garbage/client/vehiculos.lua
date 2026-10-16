--[[ ── El camión (cliente) ────────────────────────────────────────────────────

     Cuál es tu camión (y los de tu equipo), dónde está su trasera, la tarjeta
     con lo que lleva, y la planta de compactación: al llegar con carga se
     pintan los huecos de las prensas y, a pie en la trasera, E vacía. ]]

Vehiculos = { mio = nil }

local V = Config.Vehiculos
local TECLA_E = 38

function Vehiculos.Entidad(net)
    if not net or not NetworkDoesNetworkIdExist(net) then return nil end
    local ent = NetToVeh(net)
    return ent ~= 0 and DoesEntityExist(ent) and ent or nil
end

--- Los camiones de tu equipo que están cerca (su state bag lo dice).
local delEquipo = {}
CreateThread(function()
    while true do
        local lista = {}
        if L.Jornada() then
            local pos = GetEntityCoords(cache.ped)
            for _, veh in ipairs(GetGamePool('CVehicle')) do
                local st = Entity(veh).state.basuraVehiculo
                if st and Equipo.Mismo(st.cid, L.cid) and #(GetEntityCoords(veh) - pos) < 120.0 then
                    lista[#lista + 1] = veh
                end
            end
        end
        delEquipo = lista
        Wait(1000)
    end
end)

function Vehiculos.Trasera(veh)
    local st = Entity(veh).state.basuraVehiculo
    local o = V.tipos[st and st.tipo or 'camion'].trasera
    return GetOffsetFromEntityInWorldCoords(veh, o.x, o.y, o.z)
end

--- La trasera más cercana de un camión del equipo, a pie.
function Vehiculos.TraseraCerca(metros)
    if cache.vehicle then return nil end
    local pos = GetEntityCoords(cache.ped)
    local mejor, dMejor, vMejor
    for _, veh in ipairs(delEquipo) do
        if DoesEntityExist(veh) then
            local t = Vehiculos.Trasera(veh)
            local d = #(t.xy - pos.xy)
            if d <= metros and (not dMejor or d < dMejor) then mejor, dMejor, vMejor = t, d, veh end
        end
    end
    return mejor, vMejor
end

local function Carga(veh)
    return Entity(veh).state.basuraCarga or { n = 0, max = 0 }
end

-- ── La tarjeta y la planta ────────────────────────────────────────────────

local P = Config.Planta

--- La prensa en la que está aparcado el camión (como lo mira el servidor:
--- la trasera en el tope y derecho). Devuelve k o nil.
local function EnPrensa(veh)
    local detras = Vehiculos.Trasera(veh)
    local rumbo = GetEntityHeading(veh)
    for k, def in ipairs(P.prensas) do
        local tope = Basura.Offset(def.coords.xyz, def.coords.w, P.tope)
        if Basura.Plano(detras, tope) <= P.aparcar.metros then
            local giro = math.abs(((rumbo - def.coords.w) + 180.0) % 360.0 - 180.0)
            if giro <= P.aparcar.grados then return k end
        end
    end
    return nil
end

CreateThread(function()
    local conAyuda = false
    while true do
        local espera = 600
        local tarjeta, ayuda = nil, nil
        if L.Jornada() and not L.panelAbierto then
            local veh = cache.vehicle
            local propio = veh and Entity(veh).state.basuraVehiculo
            local trasera, vt = nil, nil
            if not veh and not L.ConBolsa() and not Trabajo.HayObjetivo() then trasera, vt = Vehiculos.TraseraCerca(3.5) end
            local cam = (propio and veh) or vt
            if cam then
                espera = 0
                local c = Carga(cam)
                local nombre = V.tipos[(Entity(cam).state.basuraVehiculo or {}).tipo or 'camion'].nombre
                local pago = L.yo and L.yo.pago or Config.Descarga.pago
                local valor = math.floor(c.n * pago * ((c.n >= c.max and c.max > 0) and (1 + Config.Descarga.lleno) or 1))
                local k = EnPrensa(cam)
                local acciones = {}
                local linea
                if k and not Planta.Libre(k) then
                    linea = ('La prensa %d está trabajando: espera a que caiga la bala o usa otra.'):format(k)
                elseif vt and k and c.n > 0 then
                    acciones[#acciones + 1] = { tecla = 'E', texto = ('Vaciar en la prensa %d'):format(k) }
                    ayuda = { 'E', ('Vaciar %d bolsas en la prensa %d'):format(c.n, k) }
                    if IsControlJustReleased(0, TECLA_E) then
                        L.QuitarAyuda('camion')
                        local id = Planta.Prensa(k)
                        local boca = id and PL:Punto(id, 'boca') or P.prensas[k].coords.xyz
                        CreateThread(function()
                            Trabajo.Ejecutar('descargar', {}, boca, {
                                anim = { dict = 'amb@prop_human_parking_meter@male@base', clip = 'base', flag = 1 },
                            })
                        end)
                    end
                    linea = 'Se vacía en la tolva, prensa sola y cobras al caer la bala.'
                elseif k and c.n > 0 then
                    linea = ('En la prensa %d: bájate y ve a la trasera para vaciarlo.'):format(k)
                elseif c.n >= c.max and c.max > 0 then
                    linea = 'Lleno: a la planta de compactación del depósito, marcha atrás hasta el tope.'
                elseif c.n > 0 then
                    linea = 'Sigue recogiendo, o vacíalo en la planta de compactación del depósito.'
                else
                    linea = 'Vacío: recoge cubos, bolsas y contenedores de la calle.'
                end
                tarjeta = { nombre = nombre, carga = c.n, max = c.max, valor = valor, acciones = acciones, ayuda = linea }
            end
            -- Los huecos de las prensas, al llegar con carga: verde donde está
            -- tu camión, rojo si la prensa trabaja, rosa si está libre.
            local mio = Vehiculos.mio and Vehiculos.Entidad(Vehiculos.mio.vehiculo)
            local algun = cam or mio
            if algun and Carga(algun).n > 0 and #(GetEntityCoords(cache.ped).xy - P.centro.xy) < 60.0 then
                espera = 0
                local def = V.tipos[(Entity(algun).state.basuraVehiculo or {}).tipo or 'camion']
                local dentro = EnPrensa(algun)
                for k, pr in ipairs(P.prensas) do
                    local centro = Basura.Offset(pr.coords.xyz, pr.coords.w, vec3(0.0, P.tope.y + def.cuadro.largo / 2, 0.0))
                    local col = dentro == k and { 60, 200, 110, 190 } or (not Planta.Libre(k) and { 220, 60, 50, 150 })
                        or { 216, 27, 85, 170 }
                    Dibujo.Cuadro(centro, pr.coords.w, def.cuadro.largo, def.cuadro.ancho, 0.3, col)
                end
            end
        end
        if tarjeta then L.Tarjeta('camion', tarjeta) else L.SinTarjeta('camion') end
        if ayuda then
            conAyuda = true
            L.Ayuda('camion', ayuda[1], ayuda[2])
        elseif conAyuda then
            conAyuda = false
            L.QuitarAyuda('camion')
        end
        Wait(espera)
    end
end)
