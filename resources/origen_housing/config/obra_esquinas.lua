-- Esquinas redondeadas de las casas de modalidad «libre» (ver config/obra.lua).
-- Se carga después de config/obra.lua (orden alfabético). Aquí solo hay datos
-- y cuentas, sin nada del juego: lo usan el servidor (custom/server/obra.lua)
-- para validar y el cliente (custom/client/obra.lua y esquinas.lua) para montar.
--
-- Son dos piezas de obra más, cada una con su clave:
--
--   r:I:J:k   el RINCÓN de una celda: I = 2·i + a, J = 2·j + b, con (i, j) la
--             celda y a, b = 0 hacia -X / -Y, 1 hacia +X / +Y. Así cada uno de
--             los cuatro rincones de cada celda tiene su clave (y su pintura).
--             valor = el id de una forma de `formas` ('r50', 'r95'): un cuarto
--             de cilindro cóncavo de ese radio que rellena el rincón, de suelo
--             a techo. Pide que los dos bordes de ese rincón sean pared lisa
--             (la que da a macizo, o una 'p' puesta a mano: sin hueco de
--             puerta, que el arco lo pisaría), y que por la celda no pase una
--             escalera ni un ascensor.
--   v:p:q:k   el VÉRTICE de la rejilla que es la esquina +X +Y de la celda
--             (p, q): el común a (p, q), (p+1, q), (p, q+1) y (p+1, q+1), con la
--             misma cuenta que x:… e y:… valor = 'canto': un canto redondo de
--             suelo a techo para un saliente. Vale donde al vértice llegan dos
--             paredes lisas en ángulo (el canto vivo de un pilar o de un
--             bloque) o una sola (el final de un tabique).
--
-- Se pintan como una pared, con cualquier material que no sea cristal (hay un
-- modelo por forma y material: origen_casa_esquina_<forma>_<material>, de
-- origen_housing/fuente/esquinas.py, que tira de las texturas de las paredes).
-- Al ponerlas salen del material de una de las paredes que unen.
-- La que se queda sin sus paredes (se excava detrás, se quita el tabique, se
-- le pone un hueco de puerta o una escalera) se quita sola, con su devolución.
local C = Config.Obra
local E = {}
C.Esquinas = E

-- Las formas del rincón, en el orden en que las pasa la R. El radio grande es
-- media celda menos media pared: dos en los rincones de una misma pared se
-- tocan en su centro y hacen un medio punto; cuatro, una sala redonda.
E.formas = {
    { id = 'r50', nombre = 'Radio 0,5 m', radio = 0.5 },
    { id = 'r95', nombre = 'Radio 1 m', radio = 0.95 },
}
E.canto = { id = 'canto', nombre = 'Canto exterior', radio = 0.0515 }
E.pared = 0.10          -- grueso de las paredes del kit: su cara queda a la mitad de esto del borde de la celda

local FORMA = {}
for _, f in ipairs(E.formas) do FORMA[f.id] = f end

--- La forma de una pieza (r:… con una de `formas`, v:… con el canto), o nil si ese valor no vale para esa clave.
function E.Forma(clave, valor)
    local t = tostring(clave):sub(1, 1)
    if t == 'r' then return FORMA[valor] end
    if t == 'v' and valor == E.canto.id then return E.canto end
    return nil
end

local function Numeros(clave, letra)
    local t, a, b, k = tostring(clave):match('^(%a):(-?%d+):(-?%d+):(-?%d+)$')
    if t ~= letra then return nil end
    a, b, k = math.tointeger(tonumber(a)), math.tointeger(tonumber(b)), math.tointeger(tonumber(k))
    if not (a and b and k) or math.abs(a) > 4000 or math.abs(b) > 4000 or math.abs(k) > 100 then return nil end
    return a, b, k
end

--- De r:I:J:k → i, j, k (la celda) y sx, sy (hacia dónde cae su rincón: -1 o 1 en cada eje).
function E.Rincon(clave)
    local I, J, k = Numeros(clave, 'r')
    if not I then return nil end
    local i, j = I // 2, J // 2
    return i, j, k, (I - 2 * i == 1) and 1 or -1, (J - 2 * j == 1) and 1 or -1
end

--- De v:p:q:k → p, q, k.
function E.Vertice(clave)
    return Numeros(clave, 'v')
end

function E.ClaveRincon(i, j, k, sx, sy)
    return ('r:%d:%d:%d'):format(2 * i + (sx > 0 and 1 or 0), 2 * j + (sy > 0 and 1 or 0), k)
end

function E.ClaveVertice(p, q, k)
    return ('v:%d:%d:%d'):format(p, q, k)
end

--- El vértice (p, q) al que da el rincón (sx, sy) de la celda (i, j).
function E.VerticeDe(i, j, sx, sy)
    return sx > 0 and i or i - 1, sy > 0 and j or j - 1
end

local function Abierta(o, i, j, k)
    return o.celdas[i .. ':' .. j .. ':' .. k] ~= nil
end

-- ¿Hay pared lisa en ese borde (x:i:j:k entre (i, j) e (i+1, j); y:i:j:k entre
-- (i, j) e (i, j+1))? La que sale sola hacia lo macizo, o una 'p' puesta a mano.
local function Muro(o, t, i, j, k)
    local u, v = Abierta(o, i, j, k), Abierta(o, i + (t == 'x' and 1 or 0), j + (t == 'y' and 1 or 0), k)
    if u ~= v then return true end
    if not u then return false end
    return o.piezas[t .. ':' .. i .. ':' .. j .. ':' .. k] == 'p'
end

-- Los dos bordes de un rincón: el que corta X y el que corta Y
local function BordesRincon(i, j, k, sx, sy)
    return { 'x', sx > 0 and i or i - 1, j, k }, { 'y', i, sy > 0 and j or j - 1, k }
end

-- Los cuatro medios bordes que llegan a un vértice: los dos primeros corren a lo largo de X (y:…), los otros dos a lo largo de Y (x:…)
local function BordesVertice(p, q, k)
    return { { 'y', p, q, k }, { 'y', p + 1, q, k }, { 'x', p, q, k }, { 'x', p, q + 1, k } }
end

local function ClaveBorde(b)
    return b[1] .. ':' .. b[2] .. ':' .. b[3] .. ':' .. b[4]
end

--- Las celdas por las que pasa una escalera o un hueco de ascensor o de montacoches: { ['i:j:k'] = true }.
--- (Para repasar muchas esquinas de una vez sin recorrer las piezas por cada una.)
function E.Ocupadas(o)
    local r = {}
    for clave, valor in pairs(o.piezas) do
        local t = clave:sub(1, 1)
        if t == 'e' or t == 'a' or t == 'c' then
            local _, i, j, k = clave:match('^(%a):(-?%d+):(-?%d+):(-?%d+)$')
            i, j, k, valor = tonumber(i), tonumber(j), tonumber(k), tonumber(valor)
            if i and valor and t == 'e' then
                -- su tramo en su planta y, en la de encima, las celdas que se quedan sin suelo
                for _, c in ipairs(C.Escalera(i, j, valor) or {}) do
                    r[c[1] .. ':' .. c[2] .. ':' .. k] = true
                    if not c[3] then r[c[1] .. ':' .. c[2] .. ':' .. (k + 1)] = true end
                end
            elseif i and valor then
                local n, ancho, largo
                if t == 'a' then
                    local f = math.floor(valor / 10) % 10
                    n, ancho, largo = valor % 10, (f == 1 or f == 3) and 1 or 0, (f == 2 or f == 3) and 1 or 0
                else
                    local g = valor % 10
                    n, ancho, largo = math.floor(valor / 10), g == 1 and 2 or 1, g == 1 and 1 or 2
                end
                for q = 0, math.min(n, 12) - 1 do
                    for a = 0, ancho do
                        for b = 0, largo do r[(i + a) .. ':' .. (j + b) .. ':' .. (k + q)] = true end
                    end
                end
            end
        end
    end
    return r
end

--- ¿Tiene sentido esa pieza ahí, tal como está la obra `o` ({ celdas, piezas })?
--- Devuelve true, o false y el motivo para el jugador (sin motivo si la clave o
--- el valor no valen). `ocupadas`: lo de E.Ocupadas(o), si ya se tiene.
function E.Vale(o, clave, valor, ocupadas)
    if not E.Forma(clave, valor) then return false end
    if tostring(clave):sub(1, 1) == 'r' then
        local i, j, k, sx, sy = E.Rincon(clave)
        if not i then return false end
        if not Abierta(o, i, j, k) then return false, 'La esquina redondeada va en un rincón de un espacio abierto' end
        local bx, by = BordesRincon(i, j, k, sx, sy)
        if not (Muro(o, bx[1], bx[2], bx[3], bx[4]) and Muro(o, by[1], by[2], by[3], by[4])) then
            return false, 'Ahí no hay rincón que redondear: hacen falta dos paredes lisas en ángulo (sin hueco de puerta)'
        end
        ocupadas = ocupadas or E.Ocupadas(o)
        if ocupadas[i .. ':' .. j .. ':' .. k] then return false, 'Por esa celda pasa una escalera o un ascensor: ahí no cabe la esquina' end
        return true
    end
    local p, q, k = E.Vertice(clave)
    if not p then return false end
    local n, aLoLargoX, aLoLargoY = 0, 0, 0
    for q2, b in ipairs(BordesVertice(p, q, k)) do
        if Muro(o, b[1], b[2], b[3], b[4]) then
            n = n + 1
            if q2 <= 2 then aLoLargoX = aLoLargoX + 1 else aLoLargoY = aLoLargoY + 1 end
        end
    end
    -- una pared sola que acaba ahí, o dos en ángulo; dos seguidas, tres o cuatro lo tapan entero
    if n == 1 or (n == 2 and aLoLargoX == 1 and aLoLargoY == 1) then return true end
    return false, 'El canto redondo va donde una pared hace saliente o donde acaba un tabique'
end

local function EsCristal(material)
    for _, m in ipairs(C.materiales) do
        if m.id == material then return m.interior == true end
    end
    return true     -- un material que no existe tampoco se hereda
end

--- El material del que sale una esquina recién puesta: el de una de las paredes
--- que une, si está pintada (el cristal no: la esquina es maciza). nil = el de serie.
function E.Hereda(o, clave)
    local bordes
    if tostring(clave):sub(1, 1) == 'r' then
        local i, j, k, sx, sy = E.Rincon(clave)
        if not i then return nil end
        bordes = { BordesRincon(i, j, k, sx, sy) }
    else
        local p, q, k = E.Vertice(clave)
        if not p then return nil end
        bordes = {}
        for _, b in ipairs(BordesVertice(p, q, k)) do
            if Muro(o, b[1], b[2], b[3], b[4]) then bordes[#bordes + 1] = b end
        end
    end
    for _, b in ipairs(bordes) do
        local material = o.pinturas[ClaveBorde(b)]
        if material and not EsCristal(material) then return material end
    end
    return nil
end

--- ¿Se puede pintar una esquina con ese material? (todos menos los cristales)
function E.MaterialVale(material)
    return not EsCristal(material)
end

--- Las esquinas y los cantos puestos en una celda: llama a f(clave) con cada uno.
function E.DeCelda(o, i, j, k, f)
    for _, s in ipairs({ { 1, 1 }, { -1, 1 }, { -1, -1 }, { 1, -1 } }) do
        local r = E.ClaveRincon(i, j, k, s[1], s[2])
        if o.piezas[r] ~= nil then f(r) end
        local p, q = E.VerticeDe(i, j, s[1], s[2])
        local v = E.ClaveVertice(p, q, k)
        if o.piezas[v] ~= nil then f(v) end
    end
end

-- Giro del modelo (grados, sobre el de la obra) según hacia dónde cae el rincón:
-- el modelo trae la pieza hacia -X -Y de su origen, que es el vértice.
local GIRO = { ['1:1'] = 0.0, ['-1:1'] = 90.0, ['-1:-1'] = 180.0, ['1:-1'] = 270.0 }

--- Dónde va el modelo de una pieza, en las medidas de la obra (x a lo ancho, y
--- hacia el fondo), su planta y su giro: x, y, k, giro. nil si la clave no vale.
function E.Sitio(clave)
    local m = C.celda / 2
    if tostring(clave):sub(1, 1) == 'r' then
        local i, j, k, sx, sy = E.Rincon(clave)
        if not i then return nil end
        return i * C.celda + sx * m, j * C.celda + m + sy * m, k, GIRO[sx .. ':' .. sy]
    end
    local p, q, k = E.Vertice(clave)
    if not p then return nil end
    return p * C.celda + m, q * C.celda + C.celda, k, 0.0
end

--- Modelo de una forma en un material. En el cliente, si el de ese material no
--- se sirve todavía (un material nuevo sin sus esquinas), el del material de serie.
function E.Modelo(forma, material)
    local modelo = C.Modelo('esquina_' .. forma, material or C.porDefecto.pared)
    if IsModelInCdimage and not IsModelInCdimage(modelo) then
        modelo = C.Modelo('esquina_' .. forma, C.porDefecto.pared)
    end
    return modelo
end

--- (cliente) Modelo, x, y y giro de una pieza para montarla: con su pintura, o
--- —si aún no está puesta— con la que heredaría.
function E.Colocar(o, clave, valor)
    local x, y, _, giro = E.Sitio(clave)
    if not x then return nil end
    local forma = E.Forma(clave, valor) or (tostring(clave):sub(1, 1) == 'r' and E.formas[1] or E.canto)
    local material = o.pinturas[clave] or (o.piezas[clave] == nil and E.Hereda(o, clave)) or C.porDefecto.pared
    return E.Modelo(forma.id, material), x, y, giro
end
