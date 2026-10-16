--[[ Utilidades que usan el cliente y el servidor por igual. ]]

Lumber = Lumber or {}

function Lumber.Miga(...)
end

--- Divide los tiempos de rebrote. La convar manda sobre el config para poder
--- probar sin tocar ficheros; el cliente la lee de lo que publica el servidor.
function Lumber.Velocidad()
    if not IsDuplicityVersion() then
        return tonumber(GlobalState['origen_lumber:velocidad']) or Config.Velocidad or 1.0
    end
    local v = tonumber(GetConvar('origen_lumber_velocidad', '')) or Config.Velocidad or 1.0
    return math.max(0.05, math.min(200.0, v))
end

-- ── Los árboles ───────────────────────────────────────────────────────────

--[[ Cada árbol sale de los cuarteles: id 'A-07', cuartel, especie, pos (vec3
     del pie del tronco). Nadie los escribe a mano. ]]
Config.Arboles = {}
Lumber.ArbolPorId = {}
Lumber.CuartelPorId = {}

for _, cuartel in ipairs(Config.Cuarteles) do
    Lumber.CuartelPorId[cuartel.id] = cuartel
    for i, pos in ipairs(cuartel.arboles) do
        local arbol = {
            id = ('%s-%02d'):format(cuartel.id, i),
            cuartel = cuartel.id,
            especie = cuartel.especie,
            pos = pos,
            indice = #Config.Arboles + 1,
        }
        Config.Arboles[#Config.Arboles + 1] = arbol
        Lumber.ArbolPorId[arbol.id] = arbol
    end
end

function Lumber.Arbol(id)
    return type(id) == 'string' and Lumber.ArbolPorId[id] or nil
end

function Lumber.Cuartel(id)
    return type(id) == 'string' and Lumber.CuartelPorId[id] or nil
end

function Lumber.Especie(id)
    return type(id) == 'string' and Config.Especies[id] or nil
end

-- ── Geometría ─────────────────────────────────────────────────────────────

--- Distancia en el plano (sin altura).
function Lumber.Plano(a, b)
    local dx, dy = a.x - b.x, a.y - b.y
    return math.sqrt(dx * dx + dy * dy)
end

--- El vector del suelo hacia el que apunta un rumbo de GTA (0 = norte, 90 = oeste).
function Lumber.Direccion(rumbo)
    local h = math.rad(rumbo or 0.0)
    return -math.sin(h), math.cos(h)
end

--- Rumbo normalizado a 0..360 y redondeado al paso de la muesca.
function Lumber.RumboPaso(rumbo)
    local paso = Config.Arbol.paso
    rumbo = ((tonumber(rumbo) or 0) % 360 + 360) % 360
    return (math.floor(rumbo / paso + 0.5) * paso) % 360
end

--- ¿Está (x, y) dentro de la franja de caída de un árbol que cae hacia `rumbo`?
--- Una franja de `largo` × `ancho` desde el pie.
function Lumber.EnFranja(pie, rumbo, largo, ancho, x, y)
    local dx, dy = Lumber.Direccion(rumbo)
    local rx, ry = x - pie.x, y - pie.y
    local a = rx * dx + ry * dy
    local b = rx * -dy + ry * dx
    return a >= -1.0 and a <= largo and math.abs(b) <= ancho / 2
end

--[[ Los puntos de trabajo de un árbol caído, desde el pie hacia la copa:
       ramas   donde se desrama (uno por tronco, más la copa)
       cortes  entre tronco y tronco
       troncos el centro de cada tronco que saldrá
     El tronco limpio empieza a 1 m del pie (lo que queda con el tocón). ]]
function Lumber.Puntos(arbol, rumbo)
    local esp = Lumber.Especie(arbol.especie)
    local dx, dy = Lumber.Direccion(rumbo)
    local L = Config.Tronco.largo
    local base = 1.0
    local function En(d) return vec3(arbol.pos.x + dx * d, arbol.pos.y + dy * d, arbol.pos.z) end
    local p = { ramas = {}, cortes = {}, troncos = {} }
    for i = 1, esp.troncos do
        p.troncos[i] = En(base + (i - 0.5) * L)
        p.ramas[i] = En(base + (i - 0.5) * L)
        if i < esp.troncos then p.cortes[i] = En(base + i * L) end
    end
    p.ramas[#p.ramas + 1] = En(base + esp.troncos * L + 1.5)
    return p
end

-- ── Niveles y textos ──────────────────────────────────────────────────────

function Lumber.Nivel(xp)
    xp = tonumber(xp) or 0
    local nivel = 1
    for i, datos in ipairs(Config.Niveles) do
        if xp >= datos.xp then nivel = i end
    end
    return nivel, Config.Niveles[nivel], Config.Niveles[nivel + 1]
end

--- Lo que se abre en un nivel, en frases cortas.
function Lumber.QueAbre(nivel)
    local lista = {}
    for _, id in ipairs(Config.OrdenEspecies) do
        local e = Config.Especies[id]
        if e.nivel == nivel then lista[#lista + 1] = ('talar %s (%s el tronco)'):format(e.nombre:lower(), Lumber.Dinero(e.pago)) end
    end
    for _, id in ipairs(Config.Vehiculos.orden) do
        local v = Config.Vehiculos.tipos[id]
        if v.nivel == nivel then lista[#lista + 1] = ('%s (%d troncos)'):format(v.nombre:lower(), #Lumber.Huecos(id)) end
    end
    for _, id in ipairs(Config.OrdenHerramientas) do
        local h = Config.Herramientas[id]
        if h.nivel == nivel then lista[#lista + 1] = h.nombre:lower() end
    end
    return lista
end


function Lumber.Cortar(s, n)
    if type(s) ~= 'string' then return '' end
    local largo = utf8.len(s)
    if not largo then return '' end
    if largo <= n then return s end
    return s:sub(1, utf8.offset(s, n + 1) - 1)
end

function Lumber.Estrellas(n)
    n = math.max(1, math.min(5, tonumber(n) or 1))
    return string.rep('★', n) .. string.rep('☆', 5 - n)
end

function Lumber.Dinero(n)
    local s = tostring(math.floor(tonumber(n) or 0))
    local r = s:reverse():gsub('(%d%d%d)', '%1.'):reverse()
    return '$' .. r:gsub('^%.', '')
end

function Lumber.Duracion(seg)
    seg = math.max(0, math.floor(tonumber(seg) or 0))
    if seg >= 3600 then return ('%dh %dm'):format(seg // 3600, (seg % 3600) // 60) end
    if seg >= 60 and seg % 60 == 0 then return ('%d min'):format(seg // 60) end
    if seg >= 60 then return ('%dm %ds'):format(seg // 60, seg % 60) end
    return ('%ds'):format(seg)
end

--- Segundos de un paso de tala con la herramienta que lleva.
function Lumber.TiempoPaso(especie, paso, herramienta)
    local esp = Lumber.Especie(especie)
    local h = Config.Herramientas[herramienta or 'hacha'] or Config.Herramientas.hacha
    return math.max(1.0, ((esp and esp.tiempos[paso]) or 4) * h.factor)
end

-- ── Los huecos de la carga del camión ─────────────────────────────────────

--- Dónde va cada tronco en el remolque, en coordenadas del remolque. El piso
--- de abajo lleva los troncos pegados; el de arriba, encajado en los huecos
--- que dejan (uno menos por hilera). Lo usan el cliente para pintarlos y el
--- servidor para repartirlos: tiene que ser la MISMA lista.
function Lumber.Huecos(tipo)
    local c = Config.Vehiculos.tipos[tipo or 'camion'].carga
    local d = c.diametro or 0.58
    local lista = {}
    for piso = 0, c.pisos - 1 do
        local cols = {}
        if piso == 0 then
            for _, x in ipairs(c.columnas) do cols[#cols + 1] = x end
        else
            for i = 1, #c.columnas - 1 do cols[#cols + 1] = (c.columnas[i] + c.columnas[i + 1]) / 2 end
        end
        for _, fila in ipairs(c.filas) do
            for _, col in ipairs(cols) do
                lista[#lista + 1] = { x = col, y = fila, z = c.suelo + d / 2 + piso * d * 0.87, piso = piso }
            end
        end
    end
    return lista
end
