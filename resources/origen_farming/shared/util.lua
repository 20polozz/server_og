--[[ Utilidades que usan el cliente y el servidor por igual. ]]

Granja = Granja or {}

function Granja.Traza(...)
    if not Config.Depurar then return end
    local partes = {}
    for i = 1, select('#', ...) do partes[#partes + 1] = tostring(select(i, ...)) end
    print('^2[origen_farming]^7 ' .. table.concat(partes, ' '))
end

--- Migas para el log del cliente o la consola: solo cuando pasa algo.
function Granja.Miga(...)
end

-- ── La velocidad del mundo ────────────────────────────────────────────────

--- Divide todos los tiempos de crecimiento. La convar manda sobre el config
--- para poder probar sin tocar ficheros.
function Granja.Velocidad()
    -- El cliente no ve las convars del servidor: la lee de lo que publica él.
    if not IsDuplicityVersion() then
        return tonumber(GlobalState['origen_farming:velocidad']) or Config.Velocidad or 1.0
    end
    local v = tonumber(GetConvar('origen_farming_velocidad', '')) or Config.Velocidad or 1.0
    return math.max(0.05, math.min(200.0, v))
end

-- ── Parcelas y celdas ─────────────────────────────────────────────────────

--[[ Las parcelas y los acopios salen del campo (Config.Campos): nadie los
     escribe a mano. Una parcela:
       id 'G-B3', nombre 'Parcela B3', campo, franja, acopio
       centro, rumbo, filas, columnas, paso
       ejeCol / ejeFila   hacia dónde avanzan columnas y filas
       tuberias           las dos tuberías del mapa que la bordean (a lo ancho)
     Un acopio: id 'G-B', franja, pos (vec4) y depósito. ]]

Config.Parcelas = {}
Config.Acopios = {}
Granja.ParcelaPorId = {}
Granja.AcopioPorId = {}

local LETRAS = { 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H' }

for _, campo in ipairs(Config.Campos) do
    local h = math.rad(campo.rumbo)
    local ejeCol = vec2(-math.sin(h), math.cos(h))
    local ejeFila = vec2(math.cos(h), math.sin(h))
    campo.ejeCol, campo.ejeFila = ejeCol, ejeFila
    local lado = campo.columnas * campo.paso
    local modulo = lado + campo.hueco
    local punto = function(a, b)
        return vec3(campo.centro.x + ejeCol.x * a + ejeFila.x * b, campo.centro.y + ejeCol.y * a + ejeFila.y * b,
            campo.centro.z)
    end

    for f, franja in ipairs(campo.franjas) do
        local letra = LETRAS[f]
        local acopioId = campo.letra .. '-' .. letra
        local ap = punto(franja.acopio, franja.b)
        local acopio = {
            id = acopioId, campo = campo.id, franja = f, nombre = ('Acopio %s%s'):format(campo.letra, letra),
            pos = vec4(ap.x, ap.y, ap.z, campo.rumbo),
        }
        -- El depósito, a un lado del palé (hacia la derecha del rumbo).
        acopio.deposito = vec3(ap.x + ejeFila.x * 1.8, ap.y + ejeFila.y * 1.8, ap.z)
        Config.Acopios[#Config.Acopios + 1] = acopio
        Granja.AcopioPorId[acopioId] = acopio

        for n, k in ipairs(franja.parcelas) do
            local a = campo.inicio + lado / 2 + k * modulo
            local parcela = {
                id = ('%s-%s%d'):format(campo.letra, letra, n),
                nombre = ('Parcela %s-%s%d'):format(campo.letra, letra, n),
                campo = campo.id, franja = f, acopio = acopioId,
                centro = punto(a, franja.b), rumbo = campo.rumbo,
                filas = franja.filas, columnas = campo.columnas, paso = campo.paso,
                ejeCol = ejeCol, ejeFila = ejeFila, a = a, b = franja.b,
            }
            parcela.celdas = parcela.filas * parcela.columnas
            parcela.radio = math.sqrt((parcela.filas * parcela.paso) ^ 2 + (parcela.columnas * parcela.paso) ^ 2) / 2
            parcela.indice = #Config.Parcelas + 1
            Config.Parcelas[parcela.indice] = parcela
            Granja.ParcelaPorId[parcela.id] = parcela
        end
    end
end

function Granja.Acopio(id)
    return type(id) == 'string' and Granja.AcopioPorId[id] or nil
end

--- Un punto en planta dentro del rectángulo de una parcela (con margen)?
function Granja.DentroDe(p, x, y, margen)
    margen = margen or 0.0
    local dx, dy = x - p.centro.x, y - p.centro.y
    local a = dx * p.ejeCol.x + dy * p.ejeCol.y
    local b = dx * p.ejeFila.x + dy * p.ejeFila.y
    return math.abs(a) <= p.columnas * p.paso / 2 + margen and math.abs(b) <= p.filas * p.paso / 2 + margen
end

--- Dónde poner aspersores propios en una parcela: sobre sus dos bordes largos
--- (donde van las tuberías), a las fracciones de Config.Riego.propios.
function Granja.AspersoresPropios(p)
    local lista = {}
    local largo = p.columnas * p.paso
    local borde = p.filas * p.paso / 2 + 0.9
    for _, lado in ipairs({ -1, 1 }) do
        for _, fr in ipairs(Config.Riego.propios) do
            local a = (fr - 0.5) * largo
            lista[#lista + 1] = vec2(p.centro.x + p.ejeCol.x * a + p.ejeFila.x * borde * lado,
                p.centro.y + p.ejeCol.y * a + p.ejeFila.y * borde * lado)
        end
    end
    return lista
end

function Granja.Parcela(id)
    return type(id) == 'string' and Granja.ParcelaPorId[id] or nil
end

--- Fila y columna (desde 0) de una celda numerada desde 1.
function Granja.FilaColumna(p, idx)
    idx = idx - 1
    return idx // p.columnas, idx % p.columnas
end

--- Centro en PLANTA de una celda.
function Granja.PosCelda(p, idx)
    local fila, col = Granja.FilaColumna(p, idx)
    local a = (col - (p.columnas - 1) / 2) * p.paso
    local b = (fila - (p.filas - 1) / 2) * p.paso
    return vec2(p.centro.x + p.ejeCol.x * a + p.ejeFila.x * b, p.centro.y + p.ejeCol.y * a + p.ejeFila.y * b)
end

function Granja.CeldaValida(p, idx)
    idx = tonumber(idx)
    return p and idx and idx == math.floor(idx) and idx >= 1 and idx <= p.celdas and idx or nil
end

--- La celda de una parcela que cae debajo de un punto (o nil si cae fuera).
function Granja.CeldaEn(p, x, y)
    local dx, dy = x - p.centro.x, y - p.centro.y
    local a = dx * p.ejeCol.x + dy * p.ejeCol.y
    local b = dx * p.ejeFila.x + dy * p.ejeFila.y
    local col = math.floor(a / p.paso + p.columnas / 2)
    local fila = math.floor(b / p.paso + p.filas / 2)
    if col < 0 or col >= p.columnas or fila < 0 or fila >= p.filas then return nil end
    return fila * p.columnas + col + 1
end

--- La parcela que contiene un punto, mirando solo la planta.
function Granja.ParcelaEn(x, y, margen)
    margen = margen or 0.0
    for _, p in ipairs(Config.Parcelas) do
        local dx, dy = x - p.centro.x, y - p.centro.y
        if dx * dx + dy * dy <= (p.radio + margen) ^ 2 then return p end
    end
    return nil
end

function Granja.Plano(a, b)
    return math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2)
end

-- ── Cultivos ──────────────────────────────────────────────────────────────

Granja.CultivoPorItem = {}
Granja.CultivoPorSemilla = {}
for id, c in pairs(Config.Cultivos) do
    c.id = id
    Granja.CultivoPorItem[c.item] = c
    Granja.CultivoPorSemilla[c.semilla] = c
end

function Granja.Cultivo(id)
    return type(id) == 'string' and Config.Cultivos[id] or nil
end

--- Tiempo de crecimiento de verdad, con la velocidad del mundo aplicada.
function Granja.Tiempo(c) return c.tiempo / Granja.Velocidad() end
function Granja.Rebrote(c) return (c.rebrote or c.tiempo) / Granja.Velocidad() end

function Granja.Sed(c)
    local s = c.sed or 1.0
    if s < 0.85 then return 'baja' end
    if s > 1.15 then return 'alta' end
    return 'media'
end

-- ── Niveles ───────────────────────────────────────────────────────────────

--- Nivel, datos del nivel y datos del siguiente (o nil).
function Granja.Nivel(xp)
    xp = tonumber(xp) or 0
    local nivel = 1
    for i, datos in ipairs(Config.Niveles) do
        if xp >= datos.xp then nivel = i end
    end
    return nivel, Config.Niveles[nivel], Config.Niveles[nivel + 1]
end

--- Las parcelas que puede llevar a la vez alguien con ese nivel AHORA: lo de
--- su nivel, recortado si hay tantos granjeros de jornada que no llega para
--- todos. Lo publica el servidor en GlobalState para que el cliente cuente igual.
function Granja.Tope(nivel)
    local datos = Config.Niveles[tonumber(nivel) or 1] or Config.Niveles[1]
    local n = math.max(1, tonumber(GlobalState['origen_farming:granjeros']) or 1)
    local reparto = math.floor(#Config.Parcelas / n)
    return math.max(Config.Tierras.minimo or 1, math.min(datos.parcelas, reparto))
end

-- ── Textos ────────────────────────────────────────────────────────────────

function Granja.Cortar(s, n)
    if type(s) ~= 'string' then return '' end
    local largo = utf8.len(s)
    if not largo then return '' end
    if largo <= n then return s end
    return s:sub(1, utf8.offset(s, n + 1) - 1)
end

function Granja.Estrellas(n)
    n = math.max(1, math.min(5, tonumber(n) or 1))
    return string.rep('★', n) .. string.rep('☆', 5 - n)
end

function Granja.Dinero(n)
    local s = tostring(math.floor(tonumber(n) or 0))
    local r = s:reverse():gsub('(%d%d%d)', '%1.'):reverse()
    return '$' .. r:gsub('^%.', '')
end

function Granja.Duracion(seg)
    seg = math.max(0, math.floor(tonumber(seg) or 0))
    if seg >= 86400 then return ('%dd %dh'):format(seg // 86400, (seg % 86400) // 3600) end
    if seg >= 3600 then return ('%dh %dm'):format(seg // 3600, (seg % 3600) // 60) end
    if seg >= 60 and seg % 60 == 0 then return ('%d min'):format(seg // 60) end
    if seg >= 60 then return ('%dm %ds'):format(seg // 60, seg % 60) end
    return ('%ds'):format(seg)
end
