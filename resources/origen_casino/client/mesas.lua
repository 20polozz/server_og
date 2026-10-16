--[[ ══════════════════════════════════════════════════════════════════════════
     LAS MESAS DE CARTAS EN EL MUNDO

     Como en el casino de GTA Online: cada mesa tiene su crupier de pie detrás,
     y las cartas se reparten de verdad sobre el tapete —props de carta, una a
     una, con la animación del crupier—. Lo ve todo el que esté cerca, juegue
     o no.

     Lo que hay encima de la mesa lo manda el servidor como una VISTA pública
     (Juego.EmpujarVista): aquí no se decide nada, solo se pinta. Las cartas
     tapadas llegan tapadas, sin valor.

     ── Lo que se midió en el juego (24/09) ─────────────────────────────────

     · El crupier: sus animaciones van colocadas respecto al ORIGEN DE LA MESA.
       Con una escena en el origen y el giro de la mesa, cae solo detrás de la
       bandeja de fichas, con las manos en el canto. No hay que medirlo.
     · El tapete está a 0,95 m del suelo. El rayo da 1,20 en toda la mesa,
       pero eso es la caja de colisión, no el paño.
     · Las cartas (`vw_prop_cas_card_<palo>_<valor>`) tienen una caja de 2 m:
       con `CreateObject` salían un metro por encima. Van con
       `CreateObjectNoOffset`.
     · Las de cada jugador, a 0,44 m de su silla hacia la mesa: caen justo en
       el recuadro pintado. Las del crupier, delante de la bandeja.
   ══════════════════════════════════════════════════════════════════════════ ]]

Mesas = {}

local mesas = {}     -- [puntoId] = { punto, tipo, conf, origen, crupier, cartas = { [clave] = carta } }

local PALO = { p = 'spd', c = 'hrt', d = 'dia', t = 'club' }
local VALOR = { [11] = 'jack', [12] = 'queen', [13] = 'king', [14] = 'ace' }

local function ModeloCarta(c)
    if not c or c.t or not c.v then return 'vw_prop_cas_card_spd_ace' end
    local v = VALOR[c.v] or ('%02d'):format(c.v)
    return ('vw_prop_cas_card_%s_%s'):format(PALO[c.p] or 'spd', v)
end

local function Cargar(modelo)
    local hash = joaat(modelo)
    if not HasModelLoaded(hash) then pcall(lib.requestModel, hash, 5000) end
    return hash
end

-- ── Posiciones ────────────────────────────────────────────────────────────

--- De coordenadas de la mesa (dx a la derecha, dy hacia el crupier) al mundo.
local function Mundo(m, dx, dy, dz)
    local rad = math.rad(m.punto.h)
    local cos, sin = math.cos(rad), math.sin(rad)
    return m.punto.x + dx * cos - dy * sin, m.punto.y + dx * sin + dy * cos, m.punto.z + (dz or 0.0)
end

--[[ Dónde va cada carta. Las de un jugador se montan en escalera sobre su
     recuadro, cada una un poco a la derecha y hacia la mesa, como las deja un
     crupier; con la mano separada, la segunda mano va al lado. ]]
local function Sitio(m, info)
    local c = m.conf
    -- Cada carta un pelo más alta que la anterior, y la tapada más: volteada
    -- se hunde lo que mide de grueso y la de debajo la tapaba entera.
    local alto = c.altura + (info.i or 1) * 0.0009 + ((info.carta and info.carta.t) and 0.004 or 0.0)
    if info.quien == 'crupier' then
        -- Con huecos pintados en el paño (el póker), cada carta al suyo.
        local hueco = c.crupier.huecos and c.crupier.huecos[info.i or 1]
        if hueco then
            local x, y, z = Mundo(m, hueco.dx, hueco.dy, alto)
            return x, y, z, m.punto.h + 180.0 + (hueco.giro or 0.0)
        end
        local dx = c.crupier.dx + ((info.i or 1) - 1) * (c.pasoCrupier or 0.07)
        local x, y, z = Mundo(m, dx, c.crupier.dy, alto)
        return x, y, z, m.punto.h + 180.0
    end
    local s = m.tipo.asientos[info.plaza]
    if not s then return nil end
    local f = math.rad(s.dh)
    local fx, fy = -math.sin(f), math.cos(f)       -- hacia la mesa
    local rx, ry = math.cos(f), math.sin(f)        -- a su derecha
    local desplazar = ((info.mano or 1) - 1) * 0.13 - ((info.manos or 1) - 1) * 0.065
    local k = (info.i or 1) - 1
    -- En fila (el póker: las tres una al lado de otra, centradas) o en
    -- escalera (el blackjack: cada una encima de la anterior, corrida).
    local lado, fondo = desplazar + k * c.paso, k * 0.012
    if c.fila then lado, fondo = (k - ((c.fila - 1) / 2)) * c.paso, 0.0 end
    local dx = s.dx + fx * c.jugador + rx * lado + fx * fondo
    local dy = s.dy + fy * c.jugador + ry * lado + fy * fondo
    local x, y, z = Mundo(m, dx, dy, alto)
    return x, y, z, m.punto.h + s.dh
end

-- ── Una carta ─────────────────────────────────────────────────────────────

local function Orientar(ent, rumbo, tapada)
    -- Tapada = volteada 180° sobre su eje largo: se ve el dorso.
    SetEntityRotation(ent, 0.0, tapada and 180.0 or 0.0, rumbo, 2, true)
end

local function CrearCarta(m, carta, x, y, z, rumbo)
    local hash = Cargar(ModeloCarta(carta))
    local e = CreateObjectNoOffset(hash, x, y, z, false, false, false)
    SetEntityCollision(e, false, false)
    FreezeEntityPosition(e, true)
    Orientar(e, rumbo, carta.t == true)
    return e
end

--- La lleva de donde está a donde va, con un pequeño arco, en `ms`.
local function Volar(e, desde, hasta, ms, rumbo, tapada)
    local t0 = GetGameTimer()
    while DoesEntityExist(e) do
        local t = math.min(1.0, (GetGameTimer() - t0) / ms)
        local s = 1 - (1 - t) * (1 - t)
        local x = desde.x + (hasta.x - desde.x) * s
        local y = desde.y + (hasta.y - desde.y) * s
        local z = desde.z + (hasta.z - desde.z) * s + math.sin(t * math.pi) * 0.06
        SetEntityCoordsNoOffset(e, x, y, z, false, false, false)
        Orientar(e, rumbo, tapada)
        if t >= 1.0 then break end
        Wait(0)
    end
end

-- ── El crupier ────────────────────────────────────────────────────────────

--[[ Una animación del crupier puede venir como nombre (del diccionario de la
     mesa) o como { diccionario, nombre } (la de reposo del póker sale del de
     todos los crupieres). Si el crupier es mujer y hay versión `female_`, se
     usa esa: las manos y los hombros van distinto. ]]
local function Anim(m, anim)
    if not anim then return nil end
    local dict, nombre = m.conf.dict, anim
    if type(anim) == 'table' then dict, nombre = anim[1], anim[2] end
    if not HasAnimDictLoaded(dict) then pcall(lib.requestAnimDict, dict, 3000) end
    if m.mujer and GetAnimDuration(dict, 'female_' .. nombre) > 0.0 then nombre = 'female_' .. nombre end
    if GetAnimDuration(dict, nombre) <= 0.0 then return nil end
    return dict, nombre
end

local function EscenaCrupier(m, anim, bucle)
    if not m.crupier or not DoesEntityExist(m.crupier) then return end
    local dict, nombre = Anim(m, anim)
    if not dict then return end
    local o, r = m.origen, m.giro
    local esc = CreateSynchronizedScene(o.x, o.y, o.z, r.x, r.y, r.z, 2)
    SetSynchronizedSceneLooped(esc, bucle == true)
    TaskSynchronizedScene(m.crupier, esc, dict, nombre, 1000.0, -8.0, 4, 0, 1148846080, 0)
    m.escena = esc
    return esc, GetAnimDuration(dict, nombre)
end

--- Una animación suelta del crupier y, al acabar, otra vez quieto.
local function Gesto(m, anim)
    local esc, dura = EscenaCrupier(m, anim, false)
    if not esc then return 0 end
    dura = math.floor(dura * 1000)
    SetTimeout(dura, function()
        if mesas[m.punto.id] == m and m.escena == esc then EscenaCrupier(m, m.conf.quieto, true) end
    end)
    return dura
end

local function PonerCrupier(m)
    local modelos = m.conf.modelos
    -- Siempre el mismo crupier en la misma mesa, para todos los jugadores.
    local modelo = modelos[(m.punto.id % #modelos) + 1]
    local hash = Cargar(modelo)
    pcall(lib.requestAnimDict, m.conf.dict, 5000)
    if type(m.conf.quieto) == 'table' then pcall(lib.requestAnimDict, m.conf.quieto[1], 5000) end
    local p = CreatePed(4, hash, m.origen.x, m.origen.y, m.origen.z, m.punto.h + 180.0, false, false)
    SetPedDefaultComponentVariation(p)
    m.mujer = not IsPedMale(p)
    SetEntityInvincible(p, true)
    SetBlockingOfNonTemporaryEvents(p, true)
    SetPedCanRagdoll(p, false)
    SetEntityCollision(p, false, false)
    m.crupier = p
    EscenaCrupier(m, m.conf.quieto, true)
    SetModelAsNoLongerNeeded(hash)
end

-- ── Aplicar una vista ─────────────────────────────────────────────────────

--[[ De la vista a la lista de cartas que tiene que haber en la mesa, con una
     clave estable cada una: así se sabe cuáles son nuevas, cuáles siguen y
     cuáles se han ido. El orden de la lista es el orden del reparto. ]]
local function Deseadas(m, vista)
    local lista = {}
    if not vista then return lista end

    --[[ Tus cartas, boca arriba SOLO para ti: la vista las trae tapadas para
         todos (en el póker nadie ve las del de al lado) y tu propio estado,
         que solo te llega a ti, trae sus valores. ]]
    local ses, est = C.sesion, C.estado
    if ses and ses.punto == m.punto.id and est and vista.plazas then
        -- El póker las trae sueltas; el Hold em, en tu fila de jugadores.
        local mias = type(est.cartas) == 'table' and est.cartas or nil
        if not mias and type(est.jugadores) == 'table' then
            for _, j in ipairs(est.jugadores) do
                if j.yo and type(j.cartas) == 'table' then mias = j.cartas end
            end
        end
        local mia = vista.plazas[tostring(ses.plaza)]
        if mias and mia and mia[1] then
            local mano = {}
            for i, c in ipairs(mia[1]) do
                local buena = mias[i]
                mano[i] = (buena and buena.v) and { v = buena.v, p = buena.p } or c
            end
            mia[1] = mano
        end
    end

    -- La mano va en la clave: una carta de la mano siguiente es otra carta
    -- aunque caiga en el mismo sitio.
    local ronda = tostring(vista.ronda or 0)

    local plazas = {}
    for clave in pairs(vista.plazas or {}) do plazas[#plazas + 1] = tonumber(clave) end
    table.sort(plazas)

    -- En el orden en que las da el crupier: una vuelta a todos y a él, y otra.
    local maxI = 0
    for _, plaza in ipairs(plazas) do
        for _, mano in ipairs(vista.plazas[tostring(plaza)]) do maxI = math.max(maxI, #mano) end
    end
    maxI = math.max(maxI, #(vista.crupier or {}))

    for i = 1, maxI do
        for _, plaza in ipairs(plazas) do
            local manos = vista.plazas[tostring(plaza)]
            for mi, mano in ipairs(manos) do
                if mano[i] then
                    lista[#lista + 1] = {
                        clave = ('%s|%d:%d:%d'):format(ronda, plaza, mi, i), carta = mano[i],
                        quien = 'jugador', plaza = plaza, mano = mi, manos = #manos, i = i,
                    }
                end
            end
        end
        local c = vista.crupier and vista.crupier[i]
        if c then
            lista[#lista + 1] = { clave = ronda .. '|c:' .. i, carta = c, quien = 'crupier', i = i }
        end
    end
    return lista
end

local function AnimDe(m, info, primeraVuelta)
    local a = m.conf.anims
    if info.quien == 'crupier' then
        return info.i == 1 and a.propia or (info.i == 2 and a.propiaSegunda or a.propiaMas)
    end
    local n = ('%02d'):format(info.plaza)
    return (primeraVuelta and a.dar or a.pedir):format(n)
end

local function Aplicar(m, vista, animar)
    m.cola = m.cola or {}
    local deseadas = Deseadas(m, vista)
    local siguen = {}
    local girar = {}      -- las que se descubren: todas de una vez, con un solo gesto

    for _, info in ipairs(deseadas) do
        siguen[info.clave] = true
        local ya = m.cartas[info.clave]
        if not ya then
            m.cartas[info.clave] = { info = info, pendiente = true }
            if animar then
                m.cola[#m.cola + 1] = info
            else
                local x, y, z, rumbo = Sitio(m, info)
                if x then
                    m.cartas[info.clave] = { info = info, ent = CrearCarta(m, info.carta, x, y, z, rumbo) }
                end
            end
        else
            -- La misma carta que estaba tapada y ahora no: se le da la vuelta.
            local antes = ya.info.carta
            ya.info = info
            if ya.ent and antes.t and not info.carta.t then
                girar[#girar + 1] = info.clave
            elseif ya.ent and (info.manos ~= (ya.manos or info.manos)) then
                local x, y, z, rumbo = Sitio(m, info)
                if x then SetEntityCoordsNoOffset(ya.ent, x, y, z, false, false, false) Orientar(ya.ent, rumbo, info.carta.t) end
            end
            ya.manos = info.manos
        end
    end

    if #girar > 0 then m.cola[#m.cola + 1] = { girar = girar } end

    -- Las que ya no están: el crupier las recoge.
    local fuera = {}
    for clave, c in pairs(m.cartas) do
        if not siguen[clave] then fuera[#fuera + 1] = c m.cartas[clave] = nil end
    end
    if #fuera > 0 then
        if animar then
            m.cola[#m.cola + 1] = { recoger = fuera }
        else
            for _, c in ipairs(fuera) do if c.ent and DoesEntityExist(c.ent) then DeleteEntity(c.ent) end end
        end
    end

    if animar and not m.trabajando and #m.cola > 0 then
        m.trabajando = true
        CreateThread(function()
            while mesas[m.punto.id] == m and #m.cola > 0 do
                local paso = table.remove(m.cola, 1)
                if paso.recoger then
                    Gesto(m, m.conf.anims.recoger)
                    Wait(900)
                    local x, y, z = Mundo(m, m.conf.zapato.dx * 0.2, m.conf.crupier.dy + 0.2, m.conf.altura)
                    for _, c in ipairs(paso.recoger) do
                        if c.ent and DoesEntityExist(c.ent) then
                            CreateThread(function()
                                local desde = GetEntityCoords(c.ent)
                                Volar(c.ent, desde, vector3(x, y, z), 450, GetEntityHeading(c.ent), c.info.carta.t)
                                DeleteEntity(c.ent)
                            end)
                        end
                    end
                    Wait(600)
                elseif paso.girar then
                    -- El crupier hace el gesto y se les da la vuelta a todas.
                    Gesto(m, m.conf.anims.girar)
                    Wait(1200)
                    for _, clave in ipairs(paso.girar) do
                        local c = m.cartas[clave]
                        if c and c.ent and DoesEntityExist(c.ent) then
                            local x, y, z, rumbo = Sitio(m, c.info)
                            DeleteEntity(c.ent)
                            if x then c.ent = CrearCarta(m, c.info.carta, x, y, z, rumbo) end
                        end
                    end
                    Wait(400)
                else
                    local c = m.cartas[paso.clave]
                    if c and c.pendiente then
                        local x, y, z, rumbo = Sitio(m, paso)
                        if x then
                            Gesto(m, AnimDe(m, paso, paso.i <= 2))
                            Wait(m.conf.retardo)
                            local zx, zy, zz = Mundo(m, m.conf.zapato.dx, m.conf.zapato.dy, m.conf.altura + 0.06)
                            local e = CrearCarta(m, paso.carta, zx, zy, zz, rumbo)
                            c.ent, c.pendiente = e, nil
                            Volar(e, vector3(zx, zy, zz), vector3(x, y, z), 420, rumbo, paso.carta.t == true)
                            Wait(m.conf.entreCartas)
                        end
                    end
                end
            end
            m.trabajando = false
        end)
    end
end

-- ── Poner y quitar una mesa ───────────────────────────────────────────────

function Mesas.Poner(punto, tipo, ent)
    Mesas.Quitar(punto.id)
    if not tipo or not tipo.mesaCartas then return end
    local origen, giro
    if ent and DoesEntityExist(ent) then
        origen, giro = GetEntityCoords(ent), GetEntityRotation(ent, 2)
    else
        origen, giro = vector3(punto.x, punto.y, punto.z), vector3(0.0, 0.0, punto.h)
    end
    local m = { punto = punto, tipo = tipo, conf = tipo.mesaCartas, origen = origen, giro = giro, cartas = {} }
    mesas[punto.id] = m
    PonerCrupier(m)

    -- Lo que ya hay encima, sin animar: el que llega tarde ve la mesa como está.
    CreateThread(function()
        local vista = lib.callback.await('origen_casino:vista', false, punto.id)
        if mesas[punto.id] == m and vista then Aplicar(m, vista, false) end
    end)
end

function Mesas.Quitar(id)
    local m = mesas[id]
    if not m then return end
    mesas[id] = nil
    for _, c in pairs(m.cartas) do
        if c.ent and DoesEntityExist(c.ent) then DeleteEntity(c.ent) end
    end
    if m.crupier and DoesEntityExist(m.crupier) then DeletePed(m.crupier) end
end

RegisterNetEvent('origen_casino:vista', function(id, vista)
    local m = mesas[tonumber(id)]
    if not m then return end
    Aplicar(m, vista or nil, true)
end)

AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    for id in pairs(mesas) do Mesas.Quitar(id) end
end)
