--[[ ── Lo que se ve en la cantera ─────────────────────────────────────────────

     Cada cliente pinta, a partir del estado del servidor:
       rocas        entera (sin golpes) o agrietada (con alguno), con el brillo
                    de su veta; partida, el escombro
       bloques      la roca grande de las voladuras (o sus restos)
       pedruscos    los sueltos por el suelo
       carretillas  aparcadas en el suelo o delante de quien las empuja, con
                    los pedruscos que lleven dentro
       personas     el pedrusco en brazos y el pico al hombro (o en las manos
                    mientras pica) de cualquiera que trabaje en la cantera
     Solo lo que está cerca. Todo es local de cada cliente (no son objetos de
     red) y lleva la marca de Rastro. ]]

Cantera = {}

local R = Config.Roca
local P = Config.Pedrusco
local CR = Config.Carretilla

-- El pedrusco de las cajas y la carretilla: uno más pequeño que el de la
-- mano, para que quepan en la caja sin atravesarse.
local CHICO = 'prop_rock_5_smash2'

--- El modelo de un pedrusco de esa veta: el triturado de la planta tiene el
--- suyo (origen_planta); la piedra de las rocas, el de siempre.
local function ModeloDe(veta, porDefecto)
    local m = Config.Materiales[veta]
    return m and m.modelo or porDefecto
end

local rocas = {}        -- [id] = { clave, ent }
local bloques = {}      -- [id] = { clave, ents = {} }
local pedruscos = {}    -- [id] = { clave, ent, asentado }
local carretillas = {}  -- [cid] = { ent, clave, props = {[k] = ent}, pegada }

-- ── Utilidades ────────────────────────────────────────────────────────────

local function Cargar(hash)
    if type(hash) == 'string' then hash = GetHashKey(hash) end
    if not IsModelInCdimage(hash) then return false end
    if HasModelLoaded(hash) then return true end
    RequestModel(hash)
    local fin = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < fin do Wait(0) end
    return HasModelLoaded(hash)
end
Cantera.Cargar = Cargar

local function Borrar(ent)
    if ent and DoesEntityExist(ent) then
        if IsEntityAttached(ent) then DetachEntity(ent, false, false) end
        DeleteEntity(ent)
    end
end
Cantera.Borrar = Borrar

--- El suelo en un punto, SIN contar objetos (nuestras rocas no son suelo).
--- Si el terreno aún no ha cargado devuelve nil (y no se guarda).
local suelos = {}
local function TierraYa(x, y, zRef)
    for _, alto in ipairs({ 3.0, 30.0 }) do
        local ok, z = GetGroundZExcludingObjectsFor_3dCoord(x + 0.0, y + 0.0, zRef + alto, false, false)
        if ok and math.abs(z - zRef) < 30.0 then return z end
    end
    return nil
end

function Cantera.Suelo(x, y, zRef)
    local clave = math.floor(x * 4 + 0.5) * 100000 + math.floor(y * 4 + 0.5)
    local z = suelos[clave]
    if z then return z end
    z = TierraYa(x, y, zRef)
    if z then
        suelos[clave] = z
        return z
    end
    RequestCollisionAtCoord(x + 0.0, y + 0.0, zRef + 0.0)
    return nil
end

function Cantera.SueloYa(x, y, zRef)
    return TierraYa(x, y, zRef)
end

function Cantera.OlvidarSuelos() suelos = {} end

local function Objeto(modelo, x, y, z, solido)
    local hash = type(modelo) == 'number' and modelo or GetHashKey(modelo)
    if not Cargar(hash) then return nil end
    local ent = Rastro.Marcar(CreateObjectNoOffset(hash, x + 0.0, y + 0.0, z + 0.0, false, false, false))
    FreezeEntityPosition(ent, true)
    SetEntityCollision(ent, solido == true, solido == true)
    SetEntityCanBeDamaged(ent, false)
    SetEntityLodDist(ent, 300)
    return ent
end
Cantera.Objeto = Objeto

--- Un número fijo por id (para girar cada roca siempre igual).
local function Semilla(s)
    local n = 0
    for i = 1, #s do n = (n * 31 + s:byte(i)) % 100000 end
    return n
end

-- ── Efectos ───────────────────────────────────────────────────────────────

local function Asset(dict)
    if HasNamedPtfxAssetLoaded(dict) then return true end
    RequestNamedPtfxAsset(dict)
    local fin = GetGameTimer() + 1500
    while not HasNamedPtfxAssetLoaded(dict) and GetGameTimer() < fin do Wait(0) end
    return HasNamedPtfxAssetLoaded(dict)
end

--- Un efecto de una vez en un punto.
function Cantera.Efecto(dict, nombre, x, y, z, escala)
    if not Asset(dict) then return end
    UseParticleFxAssetNextCall(dict)
    StartParticleFxNonLoopedAtCoord(nombre, x + 0.0, y + 0.0, z + 0.0, 0.0, 0.0, 0.0, (escala or 1.0) + 0.0, false, false, false)
end

--- El golpe del pico: chispas, tierra y cascotes.
function Cantera.Golpe(x, y, z)
    Cantera.Efecto('cut_michael1', 'cs_mich1_pick_dirt_impact', x, y, z, 1.4)
    Cantera.Efecto('core', 'ent_dst_rocks', x, y, z, 0.8)
    Cantera.Efecto('core', 'bul_gravel', x, y, z, 1.6)
end

function Cantera.Polvo(x, y, z, escala)
    Cantera.Efecto('core', 'ent_dst_dust', x, y, z, escala or 2.0)
end

--- La roca que se parte: polvareda y cascotes.
function Cantera.Partir(x, y, z)
    Cantera.Efecto('core', 'ent_dst_rocks', x, y, z + 0.5, 2.0)
    Cantera.Efecto('core', 'ent_dst_dust', x, y, z + 0.4, 2.5)
    Cantera.Efecto('core', 'ent_dst_concrete_large', x, y, z + 0.3, 1.0)
end

-- ── Dibujos en el suelo ───────────────────────────────────────────────────

local function Luz()
    local h = GetClockHours() + GetClockMinutes() / 60
    if h >= 7 and h <= 19 then return 1.0 end
    if h > 19 and h < 21 then return 1.0 - (h - 19) / 2 * 0.65 end
    if h >= 5 and h < 7 then return 0.35 + (h - 5) / 2 * 0.65 end
    return 0.35
end

local function Quad(a, b, c, d, col)
    DrawPoly(a.x, a.y, a.z, b.x, b.y, b.z, c.x, c.y, c.z, col[1], col[2], col[3], col[4])
    DrawPoly(a.x, a.y, a.z, c.x, c.y, c.z, d.x, d.y, d.z, col[1], col[2], col[3], col[4])
end

local function Tono(col, alfa)
    local luz = Luz()
    return { math.floor(col[1] * luz), math.floor(col[2] * luz), math.floor(col[3] * luz), alfa or col[4] or 150 }
end

--- Un aro pegado al suelo, troceado para seguir el terreno.
function Cantera.Aro(centro, radio, grosor, col)
    local c = Tono(col)
    local n = math.max(16, math.floor(radio * 10))
    local zRef = centro.z
    local prevA, prevB
    for i = 0, n do
        local a = i / n * math.pi * 2
        local ca, sa = math.cos(a), math.sin(a)
        local xa, ya = centro.x + ca * radio, centro.y + sa * radio
        local xb, yb = centro.x + ca * (radio - grosor), centro.y + sa * (radio - grosor)
        local za = Cantera.Suelo(xa, ya, zRef)
        local zb = Cantera.Suelo(xb, yb, zRef)
        if za and zb then
            local pa, pb = vec3(xa, ya, za + 0.06), vec3(xb, yb, zb + 0.06)
            if prevA then
                Quad(prevA, pa, pb, prevB, c)
                Quad(prevB, pb, pa, prevA, c)
            end
            prevA, prevB = pa, pb
        else
            prevA = nil
        end
    end
end

--- Una franja pegada al suelo desde `pie` hacia `rumbo`.
function Cantera.Franja(pie, rumbo, desde, hasta, ancho, col)
    local dx, dy = Mina.Direccion(rumbo)
    local px, py = -dy * ancho / 2, dx * ancho / 2
    local c = Tono(col)
    local n = math.max(1, math.ceil((hasta - desde) / 0.75))
    local prevI, prevD
    for i = 0, n do
        local d = desde + (hasta - desde) * i / n
        local x, y = pie.x + dx * d, pie.y + dy * d
        local zi = Cantera.Suelo(x - px, y - py, pie.z)
        local zd = Cantera.Suelo(x + px, y + py, pie.z)
        if zi and zd then
            local izq, der = vec3(x + px, y + py, zd + 0.08), vec3(x - px, y - py, zi + 0.08)
            if prevI then Quad(prevD, der, izq, prevI, c) end
            prevI, prevD = izq, der
        else
            prevI = nil
        end
    end
end

--- La flecha del editor: una franja estrecha y una punta.
function Cantera.Flecha(pie, rumbo, largo, col)
    Cantera.Franja(pie, rumbo, 1.2, largo - 1.2, 0.35, col)
    local dx, dy = Mina.Direccion(rumbo)
    local px, py = -dy, dx
    local tip = vec2(pie.x + dx * largo, pie.y + dy * largo)
    local b1 = vec2(pie.x + dx * (largo - 1.4) + px * 0.8, pie.y + dy * (largo - 1.4) + py * 0.8)
    local b2 = vec2(pie.x + dx * (largo - 1.4) - px * 0.8, pie.y + dy * (largo - 1.4) - py * 0.8)
    local function Pt(v) return vec3(v.x, v.y, (Cantera.Suelo(v.x, v.y, pie.z) or pie.z) + 0.1) end
    local c = Tono(col)
    local a, b, d = Pt(tip), Pt(b1), Pt(b2)
    DrawPoly(a.x, a.y, a.z, b.x, b.y, b.z, d.x, d.y, d.z, c[1], c[2], c[3], c[4])
    DrawPoly(a.x, a.y, a.z, d.x, d.y, d.z, b.x, b.y, b.z, c[1], c[2], c[3], c[4])
end

--[[ Un rectángulo pintado en el suelo (dónde aparcar para descargar). Cada
     lado se trocea y coge la altura del suelo en sus esquinas. ]]
function Cantera.Cuadro(centro, rumbo, largo, ancho, borde, col)
    local dx, dy = Mina.Direccion(rumbo)
    local px, py = -dy, dx
    local c = Tono(col)
    local zRef = Cantera.Suelo(centro.x, centro.y, centro.z) or centro.z
    local function Pt(a, b)
        local x = centro.x + dx * a + px * b
        local y = centro.y + dy * a + py * b
        return vec3(x, y, (Cantera.Suelo(x, y, zRef) or zRef) + 0.05)
    end
    local function Banda(a1, b1, a2, b2, grosorA, grosorB)
        local pasos = math.max(1, math.ceil(math.max(math.abs(a2 - a1), math.abs(b2 - b1)) / 0.7))
        for i = 0, pasos - 1 do
            local u, v = i / pasos, (i + 1) / pasos
            local aU, bU = a1 + (a2 - a1) * u, b1 + (b2 - b1) * u
            local aV, bV = a1 + (a2 - a1) * v, b1 + (b2 - b1) * v
            local p1, p2 = Pt(aU, bU), Pt(aU + grosorA, bU + grosorB)
            local p3, p4 = Pt(aV + grosorA, bV + grosorB), Pt(aV, bV)
            Quad(p1, p2, p3, p4, c)
            Quad(p4, p3, p2, p1, c)
        end
    end
    local la, an = largo / 2, ancho / 2
    Banda(la, an, la, -an, -borde, 0)
    Banda(-la + borde, an, -la + borde, -an, -borde, 0)
    Banda(la - borde, an, -la + borde, an, 0, -borde)
    Banda(la - borde, -an + borde, -la + borde, -an + borde, 0, -borde)
end

-- ── Las rocas ─────────────────────────────────────────────────────────────

local function ClaveRoca(v)
    if not v then return 'nada' end
    if v.e == 'escombro' then return 'escombro' end
    return v.g > 0 and 'agrietada' or 'entera'
end

local function PintarRoca(roca, v)
    local p = rocas[roca.id]
    local clave = ClaveRoca(v)
    if p and p.clave == clave and DoesEntityExist(p.ent) then return end
    local antes = p and p.clave
    if p then Borrar(p.ent) end
    local suelo = Cantera.Suelo(roca.pos.x, roca.pos.y, roca.pos.z)
    local z = suelo or roca.pos.z
    local semilla = Semilla(roca.id)
    local ent
    if clave == 'escombro' then
        -- Partida: no queda nada (antes quedaba una lasca grande en medio; el
        -- usuario, 27/09). El servidor la repone para todos a los R.repone.
        -- Recién partida: la polvareda la ve todo el que está cerca.
        if antes == 'agrietada' or antes == 'entera' then Cantera.Partir(roca.pos.x, roca.pos.y, z) end
    elseif clave ~= 'nada' then
        local fase = R.fases[clave == 'agrietada' and 2 or 1]
        ent = Objeto(fase.modelo, roca.pos.x, roca.pos.y, z - fase.hundir, false)
    end
    if ent then SetEntityHeading(ent, (semilla % 360) + 0.0) end
    -- Sin suelo aún (terreno sin cargar): se vuelve a intentar en el repaso.
    rocas[roca.id] = { clave = suelo and clave or 'reintentar', ent = ent }
end

function Cantera.RocaEnt(id)
    local p = rocas[id]
    return p and p.ent
end

-- ── Los bloques de voladura ───────────────────────────────────────────────

local function PintarBloque(bloque, v)
    local p = bloques[bloque.id]
    local clave = v and v.e or 'bloque'
    if clave == 'cargado' or clave == 'volando' then clave = 'bloque' end
    if p and p.clave == clave then return end
    local antes = p and p.clave
    if p then for _, e in ipairs(p.ents) do Borrar(e) end end
    p = { clave = clave, ents = {} }
    local pos = bloque.pos
    local suelo = Cantera.Suelo(pos.x, pos.y, pos.z)
    local z = suelo or pos.z
    if clave == 'volado' then
        local e = Objeto('ch_prop_ch_rubble_pile', pos.x, pos.y, z, false)
        if e then SetEntityHeading(e, (pos.w or 0.0) + 0.0) p.ents[#p.ents + 1] = e end
        for i = 1, 3 do
            local a = math.rad(i * 120.0)
            local s = Objeto('h4_prop_rock_scree_med_01', pos.x + math.cos(a) * 2.2, pos.y + math.sin(a) * 2.2, z, false)
            if s then p.ents[#p.ents + 1] = s end
        end
        if antes == 'bloque' then Cantera.Partir(pos.x, pos.y, z) end
    else
        local e = Objeto(Config.Voladura.modelo, pos.x, pos.y, z - 0.35, true)
        if e then SetEntityHeading(e, (pos.w or 0.0) + 0.0) p.ents[#p.ents + 1] = e end
    end
    if not suelo then p.clave = 'reintentar' end
    bloques[bloque.id] = p
end

-- ── Pedruscos sueltos ─────────────────────────────────────────────────────

local function PintarPedrusco(id, v)
    local p = pedruscos[id]
    if not v or v.s ~= 'suelo' or not v.p then
        if p then Borrar(p.ent) pedruscos[id] = nil end
        return
    end
    local clave = ('%.2f,%.2f'):format(v.p.x, v.p.y)
    if p and p.clave == clave and DoesEntityExist(p.ent) and p.asentado then return end
    if p then Borrar(p.ent) end
    local suelo = Cantera.Suelo(v.p.x, v.p.y, v.p.z)
    local ent = Objeto(ModeloDe(v.m, P.modelo), v.p.x, v.p.y, (suelo or v.p.z) + 0.18, false)
    if ent then SetEntityRotation(ent, 0.0, 0.0, (v.p.h or 0.0) + 0.0, 2, true) end
    pedruscos[id] = { clave = clave, ent = ent, asentado = suelo ~= nil }
end

function Cantera.PedruscoEnt(id)
    local p = pedruscos[id]
    return p and p.ent
end

-- ── Carretillas ───────────────────────────────────────────────────────────

--- El ped de un jugador por su id de servidor (si está a la vista).
local function PedDe(src)
    local jugador = GetPlayerFromServerId(tonumber(src) or -1)
    if jugador == -1 then return nil end
    local ped = GetPlayerPed(jugador)
    return (ped and ped ~= 0 and DoesEntityExist(ped)) and ped or nil
end
Cantera.PedDe = PedDe

local function LimpiarCarretilla(cid)
    local p = carretillas[cid]
    if not p then return end
    for _, e in pairs(p.props) do Borrar(e) end
    Borrar(p.ent)
    carretillas[cid] = nil
end

local function PintarCarretilla(cid, v)
    if not v or v.borrada then return LimpiarCarretilla(cid) end
    local p = carretillas[cid]
    local ped = v.empuja and PedDe(v.empuja)
    -- En la caja de un vehículo: pegada a él (si el vehículo no está aquí, no se ve).
    if v.veh then
        local veh = NetworkDoesNetworkIdExist(v.veh) and NetToVeh(v.veh) or 0
        local clave = 'caja:' .. tostring(v.veh) .. ':' .. tostring(veh)
        if p and p.clave == clave and p.ent and DoesEntityExist(p.ent) then return end
        if p then
            Borrar(p.ent)
            for k, e in pairs(p.props or {}) do Borrar(e) p.props[k] = nil end
        end
        p = { props = {}, claves = {}, clave = clave }
        carretillas[cid] = p
        if veh == 0 or not DoesEntityExist(veh) then return end
        local tipo = Config.Vehiculos.tipos[Vehiculos.TipoDe and Vehiculos.TipoDe(veh) or 'camioneta'] or Config.Vehiculos.tipos.camioneta
        local o = tipo.carretilla or Config.Vehiculos.tipos.camioneta.carretilla
        local c = GetEntityCoords(veh)
        local ent = Objeto(CR.modelo, c.x, c.y, c.z + 2.0, false)
        if ent then
            FreezeEntityPosition(ent, false)
            SetEntityCollision(ent, false, false)
            AttachEntityToEntity(ent, veh, 0, o.pos.x, o.pos.y, o.pos.z, o.rot.x, o.rot.y, o.rot.z, false, false, false, false, 2, true)
        end
        p.ent = ent
        return
    end
    local modo = v.empuja and 'empuja' or 'suelo'
    local clave = modo == 'suelo' and ('%.2f,%.2f,%.0f'):format(v.p.x, v.p.y, v.p.h or 0) or ('empuja:' .. tostring(v.empuja))
    if not p or not DoesEntityExist(p.ent) or p.clave ~= clave or (modo == 'empuja' and p.ped ~= ped) then
        if p then Borrar(p.ent) end
        p = p or { props = {} }
        p.clave, p.ped = clave, ped
        local base = modo == 'suelo' and v.p or GetEntityCoords(ped or cache.ped)
        local ent = Objeto(CR.modelo, base.x, base.y, base.z + (modo == 'suelo' and 0.0 or -0.9), false)
        if ent then
            if modo == 'empuja' and ped then
                -- La coloca el bucle de abajo en cada fotograma.
                SetEntityCollision(ent, false, false)
            elseif modo == 'suelo' then
                local z = Cantera.Suelo(v.p.x, v.p.y, v.p.z + 0.9) or v.p.z
                SetEntityCoordsNoOffset(ent, v.p.x, v.p.y, z, false, false, false)
                SetEntityRotation(ent, 0.0, 0.0, (v.p.h or 0.0) + 90.0, 2, true)
            end
        end
        -- Los pedruscos de dentro van pegados a la carretilla: se rehacen.
        for k, e in pairs(p.props) do Borrar(e) p.props[k] = nil end
        p.claves = {}
        p.ent = ent
        carretillas[cid] = p
    end
    -- La carga, hueco a hueco.
    p.claves = p.claves or {}
    for k = 1, CR.capacidad do
        local quiere = v.carga and v.carga[tostring(k)] or nil
        if p.claves[k] ~= quiere then
            Borrar(p.props[k])
            p.props[k], p.claves[k] = nil, quiere
            if quiere and p.ent and DoesEntityExist(p.ent) then
                local c = GetEntityCoords(p.ent)
                local e = Objeto(ModeloDe(quiere, CHICO), c.x, c.y, c.z + 1.0, false)
                if e then
                    FreezeEntityPosition(e, false)
                    local o = CR.huecos[k]
                    AttachEntityToEntity(e, p.ent, 0, o.x, o.y, o.z, 0.0, 0.0, k * 70.0, false, false, false, false, 2, true)
                    p.props[k] = e
                end
            end
        end
    end
end

--[[ Las carretillas que alguien empuja: cada empuñadura en el puño de su
     mano y la rueda en el suelo. La orientación sale de los dos puños:
       · el ancho del modelo va de un puño al otro (y se ensancha solo al
         dibujarlo hasta medir lo mismo: 48 cm de asas contra unos 63 de
         puños en la animación);
       · el largo, perpendicular a eso, inclinado lo justo para que la rueda
         toque el suelo.
     Se monta la matriz entera a mano (SetEntityMatrix) en cada fotograma.
     Con IK las manos no se movían, y ninguna animación trae los puños a 48
     cm con la vara a lo largo del puño (medido el 27/09). ]]
local function Unir(v) local n = #v return n > 0 and v / n or v end
local function Cruz(a, b) return vec3(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x) end

CreateThread(function()
    local e = CR.empujar
    local asa = vec3(e.asa.x, 0.0, e.asa.z)
    local v = e.eje - asa                          -- de las asas a la rueda, en el modelo
    local largo = #v
    local phi = math.atan(-v.z, v.x)               -- lo que baja el modelo de las asas a la rueda
    local arriba = vec3(0.0, 0.0, 1.0)
    while true do
        local hay = false
        for _, p in pairs(carretillas) do
            local ped = p.ped
            if ped and p.ent and DoesEntityExist(p.ent) and DoesEntityExist(ped) then
                hay = true
                local mi = GetPedBoneCoords(ped, 18905, e.palma, 0.0, 0.0)
                local md = GetPedBoneCoords(ped, 57005, e.palma, 0.0, 0.0)
                local m = (mi + md) / 2
                local w = Unir(mi - md)                              -- +y del modelo: la izquierda
                -- El centro del puño cae un poco hacia dentro del hueso.
                mi, md = mi - w * e.dentro, md + w * e.dentro
                local k = math.max(1.0, math.min(1.45, #(mi - md) / (2 * e.asa.y)))
                local fh = Unir(Cruz(w, arriba))                      -- hacia delante, en llano
                local suelo = Cantera.SueloYa(m.x + fh.x * 1.2, m.y + fh.y * 1.2, m.z) or (m.z - 0.8)
                -- La sonda también choca con props congelados (el horno de la
                -- planta): pegado a uno, la rueda «se apoyaba» arriba y la
                -- carretilla se ponía de pie (27/09). Cerca de los pies o nada.
                local pies = GetEntityCoords(ped).z - 0.98
                if suelo > pies + 0.4 or suelo < pies - 0.8 then suelo = pies end
                local dz = (suelo + e.eje.z) - m.z
                local dh = math.sqrt(math.max(0.01, largo * largo - dz * dz))
                local t = Unir(fh * dh + arriba * dz)                 -- de las asas a la rueda, en el mundo
                local zt = Unir(Cruz(t, w))
                local x = Unir(t * math.cos(phi) + zt * math.sin(phi))
                local z = Unir(Cruz(x, w))
                local pos = m - (x * asa.x + z * asa.z)
                local y = w * k
                SetEntityMatrix(p.ent, y.x, y.y, y.z, x.x, x.y, x.z, z.x, z.y, z.z, pos.x, pos.y, pos.z)
            end
        end
        Wait(hay and 0 or 300)
    end
end)

function Cantera.CarretillaEnt(cid)
    local p = carretillas[cid]
    return p and p.ent
end

-- ── La gente trabajando: pedrusco en brazos y pico ────────────────────────

local adornos = {}      -- [serverId] = { mano = {m, ent}, pico = {pose, ent} }

local function Adornar(src, ped)
    local st = Player(src).state
    local a = adornos[src] or {}
    adornos[src] = a
    -- El pedrusco en brazos.
    local mano = Config.Materiales[st.minaMano] and st.minaMano or nil
    if (a.mano and a.mano.m) ~= mano or (a.mano and not DoesEntityExist(a.mano.ent)) then
        if a.mano then Borrar(a.mano.ent) end
        a.mano = nil
        if mano then
            local c = GetEntityCoords(ped)
            local e = Objeto(ModeloDe(mano, P.modelo), c.x, c.y, c.z + 1.0, false)
            if e then
                FreezeEntityPosition(e, false)
                local o = P.mano
                AttachEntityToEntity(e, ped, GetPedBoneIndex(ped, o.hueso), o.pos.x, o.pos.y, o.pos.z, o.rot.x, o.rot.y, o.rot.z,
                    true, true, false, true, 1, true)
                a.mano = { m = mano, ent = e }
            end
        end
    end
    -- El pico: al hombro, o en las manos mientras pica. Con algo en brazos,
    -- o empujando la carretilla, se guarda (no se ve).
    local h = Config.Herramientas[st.minaHerramienta]
    local pose = nil
    if h and h.prop and not mano and not st.minaEmpuja then pose = st.minaPicando and 'mano' or 'hombro' end
    if (a.pico and a.pico.pose) ~= pose or (a.pico and not DoesEntityExist(a.pico.ent)) then
        if a.pico then Borrar(a.pico.ent) end
        a.pico = nil
        if pose then
            local c = GetEntityCoords(ped)
            local e = Objeto(h.prop.modelo, c.x, c.y, c.z + 1.0, false)
            if e then
                FreezeEntityPosition(e, false)
                local o = pose == 'mano' and h.prop or h.hombro
                AttachEntityToEntity(e, ped, GetPedBoneIndex(ped, h.prop.hueso), o.pos.x, o.pos.y, o.pos.z, o.rot.x, o.rot.y, o.rot.z,
                    true, true, false, true, 1, true)
                a.pico = { pose = pose, ent = e }
            end
        end
    end
end

local function Desadornar(src)
    local a = adornos[src]
    if not a then return end
    if a.mano then Borrar(a.mano.ent) end
    if a.pico then Borrar(a.pico.ent) end
    adornos[src] = nil
end

CreateThread(function()
    while true do
        local vistos = {}
        if L.cerca then
            local pos = GetEntityCoords(cache.ped)
            for _, jugador in ipairs(GetActivePlayers()) do
                local ped = GetPlayerPed(jugador)
                local src = GetPlayerServerId(jugador)
                if ped ~= 0 and #(GetEntityCoords(ped) - pos) < 90.0 then
                    local st = Player(src).state
                    if st.minaJornada then
                        vistos[src] = true
                        Adornar(src, ped)
                    end
                end
            end
        end
        for src in pairs(adornos) do
            if not vistos[src] then Desadornar(src) end
        end
        Wait(250)
    end
end)

--[[ El golpe del pico, a la vez que la animación: la cabeza del pico toca
     la roca al 34 % de cada vuelta de `ground_attack_on_spot` (medido el
     27/09: baja de +0,5 a -0,67 m entre el 30 y el 35 %). Cada cliente mira
     la animación de quien pica y suelta los cascotes en la punta del pico en
     ese instante: uno por golpe, ni antes ni dos veces. ]]
local GOLPE = 0.34
CreateThread(function()
    local anim = Config.Herramientas.pico.anim
    local punta = nil
    local fase = {}         -- [src] = tiempo de la animación en la vuelta anterior
    while true do
        local hay = false
        for src, a in pairs(adornos) do
            local ped = a.pico and a.pico.pose == 'mano' and PedDe(src)
            if ped and IsEntityPlayingAnim(ped, anim.dict, anim.clip, 3) then
                hay = true
                local t = GetEntityAnimCurrentTime(ped, anim.dict, anim.clip)
                local antes = fase[src]
                if antes and antes < GOLPE and t >= GOLPE and DoesEntityExist(a.pico.ent) then
                    if not punta then
                        local _, mx = GetModelDimensions(GetHashKey(Config.Herramientas.pico.prop.modelo))
                        punta = mx.z - 0.1
                    end
                    local c = GetOffsetFromEntityInWorldCoords(a.pico.ent, 0.0, 0.0, punta)
                    Cantera.Golpe(c.x, c.y, c.z + 0.05)
                end
                fase[src] = t
            else
                fase[src] = nil
            end
        end
        Wait(hay and 0 or 250)
    end
end)

-- ── El brillo de las vetas ────────────────────────────────────────────────

--[[ Cada roca enseña su veta con una luz de su color pegada a la piedra y un
     aro tenue en el suelo (solo de cerca y de jornada). El oro de las
     voladuras brilla también en el suelo. ]]
CreateThread(function()
    while true do
        local espera = 500
        if L.cerca and L.Jornada() and not L.panelAbierto then
            local pos = GetEntityCoords(cache.ped)
            local hay = false
            for _, roca in ipairs(Config.Rocas) do
                local d = #(pos.xy - roca.pos.xy)
                if d < 26.0 then
                    local v = L.rocas[roca.id]
                    local m = v and v.e == 'roca' and Config.Materiales[v.v]
                    if m then
                        hay = true
                        local ent = Cantera.RocaEnt(roca.id)
                        local c = ent and DoesEntityExist(ent) and GetEntityCoords(ent) or roca.pos
                        DrawLightWithRange(c.x, c.y, c.z + 1.0, m.color[1], m.color[2], m.color[3], 2.6, 3.0)
                        if d < 12.0 then Cantera.Aro(c, 1.25, 0.14, { m.color[1], m.color[2], m.color[3], 110 }) end
                    end
                end
            end
            for id, t in pairs(L.pedruscos) do
                if t.m == 'oro' and t.s == 'suelo' and t.p and #(pos.xy - vec2(t.p.x, t.p.y)) < 30.0 then
                    hay = true
                    local ent = Cantera.PedruscoEnt(id)
                    local c = ent and DoesEntityExist(ent) and GetEntityCoords(ent) or vec3(t.p.x, t.p.y, t.p.z)
                    DrawLightWithRange(c.x, c.y, c.z + 0.5, 255, 200, 40, 1.8, 4.0)
                end
            end
            if hay then espera = 0 end
        end
        Wait(espera)
    end
end)

-- ── Repaso: solo lo cercano ───────────────────────────────────────────────

AddEventHandler('origen_mining:c:roca', function(id)
    local roca = Mina.Roca(id)
    if roca and #(GetEntityCoords(cache.ped).xy - roca.pos.xy) <= Config.DistanciaVer then
        PintarRoca(roca, L.rocas[id])
    end
end)

AddEventHandler('origen_mining:c:bloque', function(id)
    local b = Mina.Bloque(id)
    if b and #(GetEntityCoords(cache.ped).xy - b.pos.xy) <= Config.DistanciaVer then PintarBloque(b, L.bloques[id]) end
end)

AddEventHandler('origen_mining:c:pedrusco', function(id)
    PintarPedrusco(id, L.pedruscos[id])
end)

AddEventHandler('origen_mining:c:carretilla', function(cid)
    PintarCarretilla(cid, L.carretillas[cid])
end)

--- El editor mueve los bloques: se repintan donde estén ahora.
function Cantera.RehacerBloques()
    for id, p in pairs(bloques) do
        for _, e in ipairs(p.ents) do Borrar(e) end
        bloques[id] = nil
    end
end

CreateThread(function()
    while true do
        if L.cerca then
            local pos = GetEntityCoords(cache.ped).xy
            for _, roca in ipairs(Config.Rocas) do
                local d = #(pos - roca.pos.xy)
                if d <= Config.DistanciaVer then
                    PintarRoca(roca, L.rocas[roca.id])
                    local p = rocas[roca.id]
                    local v = L.rocas[roca.id]
                    if p and p.ent and DoesEntityExist(p.ent) then
                        local solido = v and v.e == 'roca' and d <= Config.Limites.colision
                        if p.solido ~= solido then
                            SetEntityCollision(p.ent, solido, solido)
                            p.solido = solido
                        end
                    end
                elseif rocas[roca.id] then
                    Borrar(rocas[roca.id].ent)
                    rocas[roca.id] = nil
                end
            end
            Wait(0)
            for _, b in ipairs(Config.Bloques) do
                if #(pos - b.pos.xy) <= Config.DistanciaVer then
                    PintarBloque(b, L.bloques[b.id])
                elseif bloques[b.id] then
                    for _, e in ipairs(bloques[b.id].ents) do Borrar(e) end
                    bloques[b.id] = nil
                end
            end
            for id, v in pairs(L.pedruscos) do
                if v.s == 'suelo' and v.p and #(pos - vec2(v.p.x, v.p.y)) <= Config.Limites.pedruscos then
                    PintarPedrusco(id, v)
                elseif pedruscos[id] then
                    Borrar(pedruscos[id].ent)
                    pedruscos[id] = nil
                end
            end
            for id, p in pairs(pedruscos) do
                if not L.pedruscos[id] then Borrar(p.ent) pedruscos[id] = nil end
            end
            for cid, v in pairs(L.carretillas) do PintarCarretilla(cid, v) end
            for cid in pairs(carretillas) do
                if not L.carretillas[cid] then LimpiarCarretilla(cid) end
            end
            Wait(1000)
        else
            if next(rocas) or next(pedruscos) or next(bloques) or next(carretillas) then
                for id, p in pairs(rocas) do Borrar(p.ent) rocas[id] = nil end
                for id, p in pairs(pedruscos) do Borrar(p.ent) pedruscos[id] = nil end
                for id, p in pairs(bloques) do for _, e in ipairs(p.ents) do Borrar(e) end bloques[id] = nil end
                for cid in pairs(carretillas) do LimpiarCarretilla(cid) end
            end
            Wait(3000)
        end
    end
end)

AddEventHandler('onResourceStop', function(r)
    if r ~= GetCurrentResourceName() then return end
    for _, p in pairs(rocas) do Borrar(p.ent) end
    for _, p in pairs(pedruscos) do Borrar(p.ent) end
    for _, p in pairs(bloques) do for _, e in ipairs(p.ents) do Borrar(e) end end
    for cid in pairs(carretillas) do LimpiarCarretilla(cid) end
    for src in pairs(adornos) do Desadornar(src) end
end)
