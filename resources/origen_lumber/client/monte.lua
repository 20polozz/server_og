--[[ ── Lo que se ve en el monte ───────────────────────────────────────────────

     Cada cliente pinta, a partir del estado del servidor:
       en pie     el árbol entero (con colisión)
       talando    el árbol con la muesca (serrín al pie)
       caido      el mismo árbol tumbado en el rumbo de la muesca, apoyado en la
                  pendiente; si acaba de caer, la caída entera con su polvo
       limpio     los troncos alineados, separados por cada corte ya hecho, y
                  las ramas cortadas por el suelo
       tocon      el tocón y las ramas
       planton    un arbolito nuevo
     y los troncos sueltos del suelo (con colisión). Solo lo que está cerca. ]]

Monte = {}

local A = Config.Arbol
local T = Config.Tronco

local arboles = {}      -- [id] = { clave, ents = {}, cayendo }
local troncos = {}      -- [id] = { clave, ent }

-- ── Utilidades ────────────────────────────────────────────────────────────

local function Cargar(hash)
    if not IsModelInCdimage(hash) then return false end
    if HasModelLoaded(hash) then return true end
    RequestModel(hash)
    local fin = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < fin do Wait(0) end
    return HasModelLoaded(hash)
end
Monte.Cargar = Cargar

local function Borrar(ent)
    if ent and DoesEntityExist(ent) then DeleteEntity(ent) end
end
Monte.Borrar = Borrar

--- El suelo en un punto, SIN contar objetos: el rayo de antes chocaba con
--- nuestros propios árboles tumbados y troncos, y los troncos nuevos se
--- quedaban flotando encima de ellos en vez de asentarse en la tierra.
--- Si el terreno aún no ha cargado devuelve nil (y no se guarda).
local suelos = {}
local function TierraYa(x, y, zRef)
    -- Primero desde poco más arriba de la referencia: empezando muy alto se
    -- cogen el brazo de la grúa o las cintas del techo como si fueran suelo.
    for _, alto in ipairs({ 3.0, 30.0 }) do
        local ok, z = GetGroundZExcludingObjectsFor_3dCoord(x + 0.0, y + 0.0, zRef + alto, false, false)
        if ok and math.abs(z - zRef) < 30.0 then return z end
    end
    return nil
end

function Monte.Suelo(x, y, zRef)
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

--- Lo mismo sin caché: para las animaciones, que lo piden en cada fotograma.
function Monte.SueloYa(x, y, zRef)
    return TierraYa(x, y, zRef)
end

local function Objeto(modelo, x, y, z, solido)
    local hash = type(modelo) == 'number' and modelo or GetHashKey(modelo)
    if not Cargar(hash) then return nil end
    local ent = Rastro.Marcar(CreateObjectNoOffset(hash, x + 0.0, y + 0.0, z + 0.0, false, false, false))
    FreezeEntityPosition(ent, true)
    SetEntityCollision(ent, solido == true, solido == true)
    SetEntityCanBeDamaged(ent, false)
    SetEntityLodDist(ent, 400)
    return ent
end
Monte.Objeto = Objeto

--- Un tronco tumbado entre dos puntos del suelo: centro, rumbo y cabeceo
--- según la pendiente. `radio` lo levanta para que apoye y no se entierre.
function Monte.Tumbado(ent, cx, cy, zRef, rumbo, largo, radio, rapido)
    local dx, dy = Lumber.Direccion(rumbo)
    local Suelo = rapido and Monte.SueloYa or Monte.Suelo
    local sa = Suelo(cx - dx * largo / 2, cy - dy * largo / 2, zRef)
    local sb = Suelo(cx + dx * largo / 2, cy + dy * largo / 2, zRef)
    local sc = Suelo(cx, cy, zRef)
    local za, zb = sa or zRef, sb or zRef
    local zc = math.max((za + zb) / 2, sc or zRef)
    local cabeceo = math.deg(math.atan(zb - za, largo))
    SetEntityCoordsNoOffset(ent, cx + 0.0, cy + 0.0, zc + radio, false, false, false)
    SetEntityRotation(ent, cabeceo + 0.0, 0.0, rumbo + 0.0, 2, true)
    -- false = el terreno no estaba cargado: hay que volver a asentarlo.
    return sa ~= nil and sb ~= nil and sc ~= nil
end

-- ── El árbol ──────────────────────────────────────────────────────────────

--- Lo que ha crecido un plantón (0..1), con lo que dijo el servidor.
local function Crecido(v)
    local t = (v.t or 0) + (GetGameTimer() - (v.recibida or GetGameTimer())) / 1000
    return math.max(0, math.min(1, t * Lumber.Velocidad() / A.crecePlanton))
end

local function Clave(v, arbol)
    if not v or v.e == 'pie' then return 'pie' end
    local partes = { v.e, tostring(v.r) }
    -- El plantón se repinta cada 10 % que crece (sale un poco más de la tierra).
    if v.e == 'planton' then partes[#partes + 1] = 'g' .. math.floor(Crecido(v) * 10) end
    for k in pairs(v.ramas or {}) do partes[#partes + 1] = 'r' .. k end
    for k in pairs(v.cortes or {}) do partes[#partes + 1] = 'c' .. k end
    table.sort(partes)
    return table.concat(partes, ',')
end

local function Polvo(x, y, z, escala)
    RequestNamedPtfxAsset('core')
    local fin = GetGameTimer() + 1000
    while not HasNamedPtfxAssetLoaded('core') and GetGameTimer() < fin do Wait(0) end
    UseParticleFxAssetNextCall('core')
    StartParticleFxNonLoopedAtCoord('ent_dst_dust', x + 0.0, y + 0.0, z + 0.0, 0.0, 0.0, 0.0, (escala or 2.0) + 0.0, false, false, false)
end
Monte.Polvo = Polvo

function Monte.Astillas(x, y, z)
    RequestNamedPtfxAsset('core')
    local fin = GetGameTimer() + 1000
    while not HasNamedPtfxAssetLoaded('core') and GetGameTimer() < fin do Wait(0) end
    UseParticleFxAssetNextCall('core')
    StartParticleFxNonLoopedAtCoord('ent_dst_wood_splinter', x + 0.0, y + 0.0, z + 0.0, 0.0, 0.0, 0.0, 1.2, false, false, false)
    UseParticleFxAssetNextCall('core')
    StartParticleFxNonLoopedAtCoord('ent_dst_gen_paper', x + 0.0, y + 0.0, z + 0.0, 0.0, 0.0, 0.0, 0.6, false, false, false)
end

--- El árbol tumbado en el rumbo, apoyado en la pendiente. Con `angulo` < 90
--- está a medio caer (el giro es sobre el pie).
local function Inclinar(ent, arbol, rumbo, angulo, alto)
    local esp = Lumber.Especie(arbol.especie)
    local dx, dy = Lumber.Direccion(rumbo)
    local zPie = arbol.pos.z
    local zCopa = Monte.Suelo(arbol.pos.x + dx * esp.altura * 0.7, arbol.pos.y + dy * esp.altura * 0.7, zPie) or zPie
    -- En el suelo la copa queda a la altura del terreno de abajo.
    local pendiente = math.deg(math.atan(zCopa - zPie, esp.altura * 0.7))
    local final = 90.0 - pendiente
    local a = math.min(angulo, final)
    SetEntityCoordsNoOffset(ent, arbol.pos.x, arbol.pos.y, zPie + (alto or 0.0), false, false, false)
    SetEntityRotation(ent, -a + 0.0, 0.0, rumbo + 0.0, 2, true)
    return final
end

local function PintarArbol(id, v)
    local arbol = Lumber.Arbol(id)
    local esp = Lumber.Especie(arbol.especie)
    local p = arboles[id]
    local clave = Clave(v, arbol)
    if p and p.clave == clave and not p.cayendo then return end
    if p and p.cayendo then return end

    -- Lo de antes fuera (excepto si es el mismo árbol en pie o tumbado: se
    -- reutiliza para la caída).
    local reutilizar
    if p then
        for _, e in ipairs(p.ents) do
            if p.arbol == e and v and (v.e == 'caido' or v.e == 'talando') then reutilizar = e else Borrar(e) end
        end
    end
    p = { clave = clave, ents = {} }
    arboles[id] = p
    local estado = v and v.e or 'pie'
    local base = arbol.pos

    if estado == 'pie' or estado == 'talando' then
        local ent = reutilizar or Objeto(esp.modelo, base.x, base.y, base.z - 0.15, true)
        if ent then
            SetEntityRotation(ent, 0.0, 0.0, 0.0, 2, true)
            p.arbol = ent
            p.ents[#p.ents + 1] = ent
        end
    elseif estado == 'caido' then
        local ent = reutilizar or Objeto(esp.modelo, base.x, base.y, base.z - 0.15, false)
        if ent then
            p.arbol = ent
            p.ents[#p.ents + 1] = ent
            SetEntityCollision(ent, false, false)
            local ms = A.caida.ms
            local desde = (v.caida or 99) * 1000
            if desde < ms + 1500 then
                -- Cae ahora: giro acelerado sobre el pie, golpe y polvo.
                p.cayendo = true
                CreateThread(function()
                    local t0 = GetGameTimer() - math.max(0, desde)
                    local final = 90.0
                    while true do
                        local t = (GetGameTimer() - t0) / ms
                        if t >= 1.0 or not DoesEntityExist(ent) then break end
                        final = Inclinar(ent, arbol, v.r, 90.0 * t * t, 0.0)
                        Wait(0)
                    end
                    if DoesEntityExist(ent) then
                        Inclinar(ent, arbol, v.r, 90.0, 0.35)
                        local dx, dy = Lumber.Direccion(v.r)
                        for _, d in ipairs({ 0.35, 0.6, 0.85 }) do
                            local x, y = base.x + dx * esp.altura * d, base.y + dy * esp.altura * d
                            Polvo(x, y, (Monte.Suelo(x, y, base.z) or base.z) + 0.5, 3.0)
                        end
                        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.08)
                    end
                    p.cayendo = false
                    -- Si mientras caía cambió algo (ya lo desramaron), se repinta.
                    PintarArbol(id, L.arboles[id])
                end)
            else
                Inclinar(ent, arbol, v.r, 90.0, 0.35)
            end
        end
        -- Las ramas ya cortadas, por el suelo.
        local puntos = Lumber.Puntos(arbol, v.r)
        for k in pairs(v.ramas or {}) do
            local pto = puntos.ramas[tonumber(k)]
            if pto then
                local z = Monte.Suelo(pto.x + 1.2, pto.y, base.z) or base.z
                p.ents[#p.ents + 1] = Objeto(A.ramas, pto.x + 1.2, pto.y, z, false)
            end
        end
    elseif estado == 'limpio' then
        local puntos = Lumber.Puntos(arbol, v.r)
        local dx, dy = Lumber.Direccion(v.r)
        local separado = 0.0
        for i, c in ipairs(puntos.troncos) do
            if i > 1 and v.cortes and v.cortes[tostring(i - 1)] then separado = separado + 0.35 end
            local ent = Objeto(T.modelo, c.x, c.y, c.z, true)
            if ent then
                Monte.Tumbado(ent, c.x + dx * separado, c.y + dy * separado, base.z, v.r, T.largo, 0.3)
                p.ents[#p.ents + 1] = ent
            end
        end
        for _, pto in ipairs(puntos.ramas) do
            local z = Monte.Suelo(pto.x + 1.4, pto.y + 0.6, base.z) or base.z
            p.ents[#p.ents + 1] = Objeto(A.ramas, pto.x + 1.4, pto.y + 0.6, z, false)
        end
        p.ents[#p.ents + 1] = Objeto(A.tocon, base.x, base.y, (Monte.Suelo(base.x, base.y, base.z) or base.z) - 0.9, true)
    elseif estado == 'tocon' then
        p.ents[#p.ents + 1] = Objeto(A.tocon, base.x, base.y, (Monte.Suelo(base.x, base.y, base.z) or base.z) - 0.9, true)
        if v.r then
            local puntos = Lumber.Puntos(arbol, v.r)
            for i, pto in ipairs(puntos.ramas) do
                if i % 2 == 1 then
                    local z = Monte.Suelo(pto.x + 1.4, pto.y + 0.6, base.z) or base.z
                    p.ents[#p.ents + 1] = Objeto(A.ramas, pto.x + 1.4, pto.y + 0.6, z, false)
                end
            end
        end
    elseif estado == 'planton' then
        -- GTA no deja escalar props: el arbolito va hundido en la tierra y sale
        -- a medida que crece (recién plantado asoma poco más de un metro).
        Cargar(GetHashKey(A.plantonModelo))
        local min, max = GetModelDimensions(GetHashKey(A.plantonModelo))
        local hundir = (max.z - min.z - 1.2) * (1 - Crecido(v))
        p.ents[#p.ents + 1] = Objeto(A.plantonModelo, base.x, base.y, (Monte.Suelo(base.x, base.y, base.z) or base.z) - 0.2 - hundir, false)
        p.ents[#p.ents + 1] = Objeto(A.tocon, base.x + 0.9, base.y, (Monte.Suelo(base.x + 0.9, base.y, base.z) or base.z) - 1.2, false)
    end
end

function Monte.ArbolEnt(id)
    local p = arboles[id]
    return p and p.arbol
end

local function OlvidarArbol(id)
    local p = arboles[id]
    if not p then return end
    for _, e in ipairs(p.ents) do Borrar(e) end
    arboles[id] = nil
end

-- ── Los troncos sueltos ───────────────────────────────────────────────────

local ocultos = {}      -- [troncoId] = true mientras otra animación lo mueve

function Monte.Ocultar(id, si)
    ocultos[id] = si or nil
    local p = troncos[id]
    if p and p.ent and DoesEntityExist(p.ent) then SetEntityVisible(p.ent, not si, false) end
end

local function PintarTronco(id, v)
    local p = troncos[id]
    if not v then
        if p then Borrar(p.ent) troncos[id] = nil end
        return
    end
    local clave = ('%.2f,%.2f,%.1f'):format(v.p.x, v.p.y, v.p.h or 0)
    if p and p.clave == clave and DoesEntityExist(p.ent) then
        if not p.asentado then p.asentado = Monte.Tumbado(p.ent, v.p.x, v.p.y, v.p.z, v.p.h or 0.0, T.largo, 0.3) end
        return
    end
    if p then Borrar(p.ent) end
    local ent = Objeto(T.modelo, v.p.x, v.p.y, v.p.z, true)
    if not ent then troncos[id] = nil return end
    local asentado = Monte.Tumbado(ent, v.p.x, v.p.y, v.p.z, v.p.h or 0.0, T.largo, 0.3)
    if ocultos[id] then SetEntityVisible(ent, false, false) end
    troncos[id] = { clave = clave, ent = ent, asentado = asentado }
end

function Monte.TroncoEnt(id)
    local p = troncos[id]
    return p and p.ent
end

-- ── Repaso: solo lo cercano ───────────────────────────────────────────────

AddEventHandler('origen_lumber:c:arbol', function(id)
    local arbol = Lumber.Arbol(id)
    if arbol and #(GetEntityCoords(cache.ped).xy - arbol.pos.xy) <= Config.DistanciaVer then
        PintarArbol(id, L.arboles[id])
    end
end)

AddEventHandler('origen_lumber:c:tronco', function(id)
    local v = L.troncos[id]
    if not v then
        local p = troncos[id]
        if p then Borrar(p.ent) troncos[id] = nil end
        return
    end
    if #(GetEntityCoords(cache.ped).xy - vec2(v.p.x, v.p.y)) <= 180.0 then PintarTronco(id, v) end
end)

CreateThread(function()
    while true do
        if L.cerca then
            local pos = GetEntityCoords(cache.ped).xy
            -- Solo los más cercanos, con tope: nunca más de LIMITE.ArbolesVisibles
            -- árboles a la vez, y con colisión solo los de alrededor.
            local cerca = {}
            for _, arbol in ipairs(Config.Arboles) do
                local d = #(pos - arbol.pos.xy)
                if d <= Config.DistanciaVer then cerca[#cerca + 1] = { arbol = arbol, d = d } end
            end
            table.sort(cerca, function(a, b) return a.d < b.d end)
            local pintar = {}
            for i = 1, math.min(#cerca, Config.Limites.arboles) do pintar[cerca[i].arbol.id] = cerca[i].d end
            for _, arbol in ipairs(Config.Arboles) do
                local d = pintar[arbol.id]
                if d then
                    PintarArbol(arbol.id, L.arboles[arbol.id])
                    local p = arboles[arbol.id]
                    if p and p.arbol and DoesEntityExist(p.arbol) and not p.cayendo then
                        local v = L.arboles[arbol.id]
                        local enPie = not v or v.e == 'pie' or v.e == 'talando'
                        local solido = enPie and d <= Config.Limites.colision
                        if p.solido ~= solido then
                            SetEntityCollision(p.arbol, solido, solido)
                            p.solido = solido
                        end
                    end
                elseif arboles[arbol.id] then
                    OlvidarArbol(arbol.id)
                end
            end
            Wait(0)
            for id, v in pairs(L.troncos) do
                local d = #(pos - vec2(v.p.x, v.p.y))
                if d <= Config.Limites.troncos then PintarTronco(id, v)
                elseif troncos[id] then Borrar(troncos[id].ent) troncos[id] = nil end
            end
            for id, p in pairs(troncos) do
                if not L.troncos[id] then Borrar(p.ent) troncos[id] = nil end
            end
            Wait(1500)
        else
            if next(arboles) or next(troncos) then
                for id in pairs(arboles) do OlvidarArbol(id) end
                for _, p in pairs(troncos) do Borrar(p.ent) end
                troncos = {}
            end
            Wait(3000)
        end
    end
end)

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

--- Una franja pegada al suelo desde `pie` hacia `rumbo`, troceada cada 0,75 m.
function Monte.Franja(pie, rumbo, desde, hasta, ancho, col)
    local dx, dy = Lumber.Direccion(rumbo)
    local px, py = -dy * ancho / 2, dx * ancho / 2
    local luz = Luz()
    local c = { math.floor(col[1] * luz), math.floor(col[2] * luz), math.floor(col[3] * luz), col[4] }
    local n = math.max(1, math.ceil((hasta - desde) / 0.75))
    local prevI, prevD
    for i = 0, n do
        local d = desde + (hasta - desde) * i / n
        local x, y = pie.x + dx * d, pie.y + dy * d
        local zi = Monte.Suelo(x - px, y - py, pie.z)
        local zd = Monte.Suelo(x + px, y + py, pie.z)
        if zi and zd then
            local izq, der = vec3(x + px, y + py, zd + 0.08), vec3(x - px, y - py, zi + 0.08)
            if prevI then Quad(prevD, der, izq, prevI, c) end
            prevI, prevD = izq, der
        else
            prevI = nil
        end
    end
end

--[[ Un rectángulo pintado en el suelo (dónde dejar el remolque para
     descargar). Cada lado se trocea cada 0,7 m y cada trozo coge la altura
     del suelo en sus esquinas: a una sola altura, en cuanto el patio sube un
     poco, la mitad del cuadro se queda enterrada. ]]
function Monte.Cuadro(centro, rumbo, largo, ancho, borde, col)
    local dx, dy = Lumber.Direccion(rumbo)
    local px, py = -dy, dx
    local luz = Luz()
    local c = { math.floor(col[1] * luz), math.floor(col[2] * luz), math.floor(col[3] * luz), col[4] }
    local zRef = Monte.Suelo(centro.x, centro.y, centro.z) or centro.z

    --- Un punto del rectángulo: `a` a lo largo, `b` a lo ancho, pegado al suelo.
    local function P(a, b)
        local x = centro.x + dx * a + px * b
        local y = centro.y + dy * a + py * b
        return vec3(x, y, (Monte.Suelo(x, y, zRef) or zRef) + 0.05)
    end

    --- Una banda del borde, de (a1,b1) a (a2,b2), troceada para seguir el suelo.
    local function Banda(a1, b1, a2, b2, grosorA, grosorB)
        local pasos = math.max(1, math.ceil(math.max(math.abs(a2 - a1), math.abs(b2 - b1)) / 0.7))
        for i = 0, pasos - 1 do
            local u, v = i / pasos, (i + 1) / pasos
            local aU, bU = a1 + (a2 - a1) * u, b1 + (b2 - b1) * u
            local aV, bV = a1 + (a2 - a1) * v, b1 + (b2 - b1) * v
            local p1, p2 = P(aU, bU), P(aU + grosorA, bU + grosorB)
            local p3, p4 = P(aV + grosorA, bV + grosorB), P(aV, bV)
            Quad(p1, p2, p3, p4, c)
            Quad(p4, p3, p2, p1, c)
        end
    end

    local la, an = largo / 2, ancho / 2
    Banda(la, an, la, -an, -borde, 0)        -- delante
    Banda(-la + borde, an, -la + borde, -an, -borde, 0)  -- detrás
    Banda(la - borde, an, -la + borde, an, 0, -borde)    -- lado izquierdo
    Banda(la - borde, -an + borde, -la + borde, -an + borde, 0, -borde) -- lado derecho
end

--- La flecha de la muesca: una franja estrecha y una punta.
function Monte.Flecha(pie, rumbo, largo, col)
    Monte.Franja(pie, rumbo, 1.2, largo - 1.2, 0.35, col)
    local dx, dy = Lumber.Direccion(rumbo)
    local px, py = -dy, dx
    local tip = vec2(pie.x + dx * largo, pie.y + dy * largo)
    local b1 = vec2(pie.x + dx * (largo - 1.4) + px * 0.8, pie.y + dy * (largo - 1.4) + py * 0.8)
    local b2 = vec2(pie.x + dx * (largo - 1.4) - px * 0.8, pie.y + dy * (largo - 1.4) - py * 0.8)
    local function P(v) return vec3(v.x, v.y, (Monte.Suelo(v.x, v.y, pie.z) or pie.z) + 0.1) end
    local luz = Luz()
    local a, b, c = P(tip), P(b1), P(b2)
    DrawPoly(a.x, a.y, a.z, b.x, b.y, b.z, c.x, c.y, c.z, math.floor(col[1] * luz), math.floor(col[2] * luz), math.floor(col[3] * luz), col[4])
    DrawPoly(a.x, a.y, a.z, c.x, c.y, c.z, b.x, b.y, b.z, math.floor(col[1] * luz), math.floor(col[2] * luz), math.floor(col[3] * luz), col[4])
end

--- Una marca corta atravesada (donde se corta un tronco o se quitan ramas).
function Monte.Marca(punto, rumbo, col, ancho)
    Monte.Franja(vec3(punto.x, punto.y, punto.z), rumbo, -0.12, 0.12, ancho or 1.6, col)
end

-- ── ¡Árbol va! ────────────────────────────────────────────────────────────

local avisos = {}   -- [arbolId] = { rumbo, hasta }

RegisterNetEvent('origen_lumber:aviso', function(id, rumbo, ms)
    local arbol = Lumber.Arbol(id)
    if not arbol then return end
    avisos[id] = { rumbo = rumbo, hasta = GetGameTimer() + (tonumber(ms) or 5000) + A.caida.ms }
    local esp = Lumber.Especie(arbol.especie)
    local pos = GetEntityCoords(cache.ped)
    if #(pos.xy - arbol.pos.xy) < esp.altura + 25.0 then
        L.Aviso('¡Árbol va! Aléjate de la zona roja.', 'warning', 5000)
    end
end)

CreateThread(function()
    while true do
        local espera = 500
        if next(avisos) then
            espera = 0
            local ahora = GetGameTimer()
            for id, a in pairs(avisos) do
                if ahora > a.hasta then
                    avisos[id] = nil
                else
                    local arbol = Lumber.Arbol(id)
                    local esp = Lumber.Especie(arbol.especie)
                    local latido = 110 + math.floor(60 * math.abs(math.sin(ahora / 180)))
                    Monte.Franja(arbol.pos, a.rumbo, 0.5, esp.altura, A.caida.ancho, { 220, 40, 40, latido })
                end
            end
        end
        Wait(espera)
    end
end)

RegisterNetEvent('origen_lumber:golpe', function(dano)
    local ped = cache.ped
    SetPedToRagdoll(ped, 3500, 3500, 0, false, false, false)
    ApplyDamageToPed(ped, math.min(80, tonumber(dano) or 40), false)
    ShakeGameplayCam('MEDIUM_EXPLOSION_SHAKE', 0.35)
end)

AddEventHandler('onResourceStop', function(r)
    if r ~= GetCurrentResourceName() then return end
    for id in pairs(arboles) do OlvidarArbol(id) end
    for _, p in pairs(troncos) do Borrar(p.ent) end
end)
