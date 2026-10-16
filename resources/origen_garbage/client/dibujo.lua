--[[ ── Utilidades del mundo ───────────────────────────────────────────────────

     Cargar modelos, el suelo y lo que se pinta en él (el cuadro de la tolva
     y el aro del cubo que tienes delante). Sacado del aserradero. ]]

Dibujo = {}

function Dibujo.Cargar(hash)
    hash = type(hash) == 'number' and hash or GetHashKey(hash)
    if not IsModelInCdimage(hash) then return false end
    if HasModelLoaded(hash) then return true end
    RequestModel(hash)
    local fin = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < fin do Wait(0) end
    return HasModelLoaded(hash)
end

function Dibujo.Anim(dict)
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local fin = GetGameTimer() + 3000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < fin do Wait(0) end
    return HasAnimDictLoaded(dict)
end

function Dibujo.Borrar(ent)
    if ent and DoesEntityExist(ent) then DeleteEntity(ent) end
end

--- El suelo en un punto, SIN contar objetos (los cubos y los coches).
local suelos = {}
function Dibujo.Suelo(x, y, zRef)
    local clave = math.floor(x * 4 + 0.5) * 100000 + math.floor(y * 4 + 0.5)
    local z = suelos[clave]
    if z then return z end
    for _, alto in ipairs({ 3.0, 30.0 }) do
        local ok, zz = GetGroundZExcludingObjectsFor_3dCoord(x + 0.0, y + 0.0, zRef + alto, false, false)
        if ok and math.abs(zz - zRef) < 30.0 then
            suelos[clave] = zz
            return zz
        end
    end
    RequestCollisionAtCoord(x + 0.0, y + 0.0, zRef + 0.0)
    return nil
end

-- ── Dibujos en el suelo ───────────────────────────────────────────────────

local function Luz()
    local h = GetClockHours() + GetClockMinutes() / 60
    if h >= 7 and h <= 19 then return 1.0 end
    if h > 19 and h < 21 then return 1.0 - (h - 19) / 2 * 0.65 end
    if h >= 5 and h < 7 then return 0.35 + (h - 5) / 2 * 0.65 end
    return 0.35
end

local function Tono(col)
    local luz = Luz()
    return { math.floor(col[1] * luz), math.floor(col[2] * luz), math.floor(col[3] * luz), col[4] or 150 }
end

local function Quad(a, b, c, d, col)
    DrawPoly(a.x, a.y, a.z, b.x, b.y, b.z, c.x, c.y, c.z, col[1], col[2], col[3], col[4])
    DrawPoly(a.x, a.y, a.z, c.x, c.y, c.z, d.x, d.y, d.z, col[1], col[2], col[3], col[4])
end

--- Un aro pegado al suelo, troceado para seguir el terreno.
function Dibujo.Aro(centro, radio, grosor, col)
    local c = Tono(col)
    local n = math.max(16, math.floor(radio * 10))
    local prevA, prevB
    for i = 0, n do
        local a = i / n * math.pi * 2
        local ca, sa = math.cos(a), math.sin(a)
        local xa, ya = centro.x + ca * radio, centro.y + sa * radio
        local xb, yb = centro.x + ca * (radio - grosor), centro.y + sa * (radio - grosor)
        local za = Dibujo.Suelo(xa, ya, centro.z)
        local zb = Dibujo.Suelo(xb, yb, centro.z)
        -- Pegado a una pared o a un muro, el «suelo» de ese trozo es lo alto
        -- del muro: ese trozo no se pinta (antes el aro se subía por la pared).
        if za and zb and math.abs(za - centro.z) < 0.35 and math.abs(zb - centro.z) < 0.35 then
            local pa, pb = vec3(xa, ya, za + 0.05), vec3(xb, yb, zb + 0.05)
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

--[[ Un rectángulo pintado en el suelo (dónde dejar el camión para
     descargar). Cada lado se trocea y cada trozo coge la altura del suelo en
     sus esquinas. `rumbo` en grados de GTA (el largo va hacia él). ]]
function Dibujo.Cuadro(centro, rumbo, largo, ancho, borde, col)
    local h = math.rad(rumbo or 0.0)
    local dx, dy = -math.sin(h), math.cos(h)
    local px, py = -dy, dx
    local c = Tono(col)
    local zRef = Dibujo.Suelo(centro.x, centro.y, centro.z) or centro.z

    local function P(a, b)
        local x = centro.x + dx * a + px * b
        local y = centro.y + dy * a + py * b
        return vec3(x, y, (Dibujo.Suelo(x, y, zRef) or zRef) + 0.05)
    end

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
    Banda(la, an, la, -an, -borde, 0)
    Banda(-la + borde, an, -la + borde, -an, -borde, 0)
    Banda(la - borde, an, -la + borde, an, 0, -borde)
    Banda(la - borde, -an + borde, -la + borde, -an + borde, 0, -borde)
end
