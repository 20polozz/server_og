-- Esquinas redondeadas (config/obra_esquinas.lua): lo que la cinta necesita de
-- ellas. Las monta, las marca y las pinta custom/client/obra.lua como una pieza
-- más (r:… el rincón de una celda, v:… un vértice); aquí va a qué se apunta con
-- la herramienta «Esquina redondeada», su recuadro y su tira de variantes.
local C = Config.Obra
local E = C.Esquinas

Esquinas = {}

local function Abierta(o, i, j, k) return o.celdas[i .. ':' .. j .. ':' .. k] ~= nil end

local function AMundo(o, x, y, k, z)
    return o.o + o.X * x + o.Y * y + vector3(0.0, 0.0, k * C.planta + (z or 0.0))
end

--- ¿Se sirven ya los modelos? (el de serie de la primera forma: sin él no se ofrece nada)
function Esquinas.Disponible()
    return IsModelInCdimage(C.Modelo('esquina_' .. E.formas[1].id, C.porDefecto.pared))
end

--- Clave y valor de lo que pondría la herramienta donde se mira (`m`, la
--- mirada de la cinta): la esquina del rincón más cercano de la celda desde la
--- que se mira, con el radio que toque (la R los pasa); y si ese rincón no lo
--- es pero el vértice es un saliente, su canto redondo.
function Esquinas.Objetivo(o, m, vuelta)
    if not m.a or not m.x or not Esquinas.Disponible() then return nil end
    local i, j, k = m.a[1], m.a[2], m.a[3]
    if not Abierta(o, i, j, k) then return nil end
    local sx = (m.x - i * C.celda) >= 0 and 1 or -1
    local sy = (m.y - (j * C.celda + C.celda / 2)) >= 0 and 1 or -1
    local forma = E.formas[vuelta % #E.formas + 1]
    local rincon = E.ClaveRincon(i, j, k, sx, sy)
    if E.Vale(o, rincon, forma.id) then return rincon, forma.id end
    local p, q = E.VerticeDe(i, j, sx, sy)
    local vertice = E.ClaveVertice(p, q, k)
    if E.Vale(o, vertice, E.canto.id) and IsModelInCdimage(C.Modelo('esquina_' .. E.canto.id, C.porDefecto.pared)) then
        return vertice, E.canto.id
    end
    return nil
end

--- Por qué el clic no ha puesto nada (texto para el jugador).
function Esquinas.Pista(o, m)
    if not Esquinas.Disponible() then return 'Las esquinas redondeadas aún no están disponibles' end
    if m and m.a and m.x and Abierta(o, m.a[1], m.a[2], m.a[3]) then
        local i, j, k = m.a[1], m.a[2], m.a[3]
        local sx = (m.x - i * C.celda) >= 0 and 1 or -1
        local sy = (m.y - (j * C.celda + C.celda / 2)) >= 0 and 1 or -1
        local rincon = E.ClaveRincon(i, j, k, sx, sy)
        if o.piezas[rincon] ~= nil then return 'Ese rincón ya está redondeado: la R cambia el radio, y el clic derecho lo quita' end
        local _, pega = E.Vale(o, rincon, E.formas[1].id)
        if pega then return pega end
    end
    return 'Mira el rincón donde se juntan dos paredes lisas, o el canto de una pared que hace saliente'
end

--- La celda desde la que se ve una esquina que se está mirando (para pintar su sala, o para volver a apuntar):
--- la suya, o —de un canto— la abierta de las cuatro de su vértice que más cerca queda de (x, y).
function Esquinas.CeldaDe(o, clave, x, y)
    local i, j, k = E.Rincon(clave)
    if i then return { i, j, k } end
    local p, q
    p, q, k = E.Vertice(clave)
    if not p then return nil end
    local mejor, cuanto
    for a = 0, 1 do
        for b = 0, 1 do
            if Abierta(o, p + a, q + b, k) then
                local d = ((p + a) * C.celda - x) ^ 2 + ((q + b) * C.celda + C.celda / 2 - y) ^ 2
                if not cuanto or d < cuanto then mejor, cuanto = { p + a, q + b, k }, d end
            end
        end
    end
    return mejor
end

--- ¿Le falta a esa esquina el modelo de ese material? (el cristal, o un material nuevo cuyas
--- esquinas aún no se sirven): con él no se pinta, que se quedaría con el aspecto de otro.
function Esquinas.SinModelo(o, clave, material)
    local t = clave:sub(1, 1)
    if t ~= 'r' and t ~= 'v' then return false end
    local forma = E.Forma(clave, o.piezas[clave])
    if not forma then return false end
    return not E.MaterialVale(material) or not IsModelInCdimage(C.Modelo('esquina_' .. forma.id, material))
end

--- Lo que pasa la R, para la tira de variantes de la cinta: lista ({ id, nombre, img }), cómo se llama eso y cuál toca.
function Esquinas.Variantes(vuelta)
    local lista = {}
    for _, f in ipairs(E.formas) do
        lista[#lista + 1] = { id = f.id, nombre = f.nombre, img = ('./img/obra/estilos/esquinas_%s.png'):format(f.id) }
    end
    return lista, 'Radio', E.formas[vuelta % #E.formas + 1].id
end

local function Color()
    local r, g, b = 216, 27, 85
    if OrigenMarcaColor then r, g, b = OrigenMarcaColor(r, g, b) end
    return r, g, b
end

--- El recuadro de la esquina que se mira: en un rincón, el paño que va de una
--- pared a la otra por delante de la curva; en un canto, su caja.
function Esquinas.Recuadro(o, clave)
    local forma = E.Forma(clave, o.piezas[clave])
    local x, y, k = E.Sitio(clave)
    if not forma or not x then return end
    local r, g, b = Color()
    local alto = C.planta - 0.15
    local p
    if clave:sub(1, 1) == 'r' then
        local _, _, _, sx, sy = E.Rincon(clave)
        local c, n = E.pared / 2, 0.03
        -- los dos puntos donde la curva toca las paredes, un poco hacia la sala
        local ax, ay = x - sx * (c + n), y - sy * (c + forma.radio)
        local bx, by = x - sx * (c + forma.radio), y - sy * (c + n)
        p = { AMundo(o, ax, ay, k, 0.02), AMundo(o, bx, by, k, 0.02), AMundo(o, bx, by, k, alto), AMundo(o, ax, ay, k, alto) }
        DrawPoly(p[1].x, p[1].y, p[1].z, p[2].x, p[2].y, p[2].z, p[3].x, p[3].y, p[3].z, r, g, b, 70)
        DrawPoly(p[1].x, p[1].y, p[1].z, p[3].x, p[3].y, p[3].z, p[4].x, p[4].y, p[4].z, r, g, b, 70)
        DrawPoly(p[3].x, p[3].y, p[3].z, p[2].x, p[2].y, p[2].z, p[1].x, p[1].y, p[1].z, r, g, b, 70)
        DrawPoly(p[4].x, p[4].y, p[4].z, p[3].x, p[3].y, p[3].z, p[1].x, p[1].y, p[1].z, r, g, b, 70)
        for q = 1, 4 do
            local a, d = p[q], p[q % 4 + 1]
            DrawLine(a.x, a.y, a.z, d.x, d.y, d.z, r, g, b, 255)
        end
        return
    end
    local h = forma.radio + 0.03
    for _, s in ipairs({ { -1, -1, 1, -1 }, { 1, -1, 1, 1 }, { 1, 1, -1, 1 }, { -1, 1, -1, -1 } }) do
        local a0, a1 = AMundo(o, x + s[1] * h, y + s[2] * h, k, 0.02), AMundo(o, x + s[1] * h, y + s[2] * h, k, alto)
        local b0, b1 = AMundo(o, x + s[3] * h, y + s[4] * h, k, 0.02), AMundo(o, x + s[3] * h, y + s[4] * h, k, alto)
        DrawLine(a0.x, a0.y, a0.z, a1.x, a1.y, a1.z, r, g, b, 255)
        DrawLine(a0.x, a0.y, a0.z, b0.x, b0.y, b0.z, r, g, b, 255)
        DrawLine(a1.x, a1.y, a1.z, b1.x, b1.y, b1.z, r, g, b, 255)
    end
end
