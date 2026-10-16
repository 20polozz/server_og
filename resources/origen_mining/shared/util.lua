--[[ Utilidades que usan el cliente y el servidor por igual. ]]

Mina = Mina or {}

function Mina.Miga(...)
end

--- Divide los tiempos de reposición. La convar manda sobre el config para
--- poder probar sin tocar ficheros; el cliente la lee de lo que publica el
--- servidor.
function Mina.Velocidad()
    if not IsDuplicityVersion() then
        return tonumber(GlobalState['origen_mining:velocidad']) or Config.Velocidad or 1.0
    end
    local v = tonumber(GetConvar('origen_mining_velocidad', '')) or Config.Velocidad or 1.0
    return math.max(0.05, math.min(200.0, v))
end

-- ── Las rocas y los bloques ───────────────────────────────────────────────

--[[ Cada roca sale de los frentes: id 'A-03', frente, pos. Nadie las escribe
     a mano. ]]
Config.Rocas = {}
Mina.RocaPorId = {}
Mina.FrentePorId = {}
Mina.BloquePorId = {}

for _, frente in ipairs(Config.Frentes) do
    Mina.FrentePorId[frente.id] = frente
    for i, pos in ipairs(frente.rocas) do
        local roca = { id = ('%s-%02d'):format(frente.id, i), frente = frente.id, pos = pos }
        Config.Rocas[#Config.Rocas + 1] = roca
        Mina.RocaPorId[roca.id] = roca
    end
end
for _, b in ipairs(Config.Bloques) do Mina.BloquePorId[b.id] = b end

function Mina.Roca(id) return type(id) == 'string' and Mina.RocaPorId[id] or nil end
function Mina.Frente(id) return type(id) == 'string' and Mina.FrentePorId[id] or nil end
function Mina.Bloque(id) return type(id) == 'string' and Mina.BloquePorId[id] or nil end
function Mina.Material(id) return type(id) == 'string' and Config.Materiales[id] or nil end

--- Dónde van las cargas de una voladura: repartidas alrededor del bloque.
function Mina.PuntosCarga(bloque)
    local lista = {}
    local n = Config.Voladura.cargas
    local d = Config.Voladura.distancia
    local p = bloque.pos
    for i = 1, n do
        local a = math.rad((p.w or 0.0) + (i - 1) * 360.0 / n + 45.0)
        lista[i] = vec3(p.x + math.cos(a) * d, p.y + math.sin(a) * d, p.z)
    end
    return lista
end

-- ── La planta ────────────────────────────────────────────────────────────

--- Un punto del marco de la planta (x derecha, y hacia el contenedor) al mundo.
function Mina.EnPlanta(v)
    local a = Config.Planta.ancla
    local w = math.rad(a.w)
    local c, s = math.cos(w), math.sin(w)
    return vec3(a.x + v.x * c - v.y * s, a.y + v.x * s + v.y * c, a.z + v.z)
end

--- Recoloca la boca, el cuadro de descarga y el borde a partir del ancla.
function Mina.PuntosPlanta()
    local P = Config.Planta
    P.boca = Mina.EnPlanta(P.local_boca)
    local d = Mina.EnPlanta(P.local_descarga)
    -- El vehículo mira hacia fuera de la tolva: le da la espalda.
    P.descarga.pos = vec4(d.x, d.y, d.z, (P.ancla.w + 180.0) % 360.0)
    P.borde.pos = Mina.EnPlanta(P.local_borde)
end
Mina.PuntosPlanta()

--- La compuerta del contenedor, donde cada uno recoge lo suyo.
function Mina.Recoger()
    return Mina.EnPlanta(Config.Planta.local_recoger), Config.Planta.recoger_radio
end

--- El horno de la fundición (el centro de su plataforma).
function Mina.Horno()
    local f = Config.Planta.fundicion
    return vec3(f.x, f.y, f.z), Config.Planta.horno_radio
end

--[[ Los metales salen de la planta triturados: un pedrusco más, que se
     lleva en brazos o en la carretilla hasta el horno. Son materiales con su
     propia clave (`hierro_t`...), fuera de Config.OrdenMateriales (no salen
     en las rocas ni en los precios): así todo lo de los pedruscos (brazos,
     carretilla, suelo, tarjetas) sirve tal cual. `triturado` apunta a la
     veta y `modelo` es el prop de origen_planta. ]]
for id, prod in pairs(Config.Productos) do
    local m = Config.Materiales[id]
    if prod.funde and m then
        Config.Materiales[id .. '_t'] = {
            nombre = m.nombre .. ' triturado', nivel = 1, peso = 0, pago = 0, xp = 0,
            color = m.color, triturado = id, modelo = 'origen_planta_piedra_' .. id,
        }
    end
end

--- ¿Es material triturado (va al horno, no a la tolva ni a la caja)?
function Mina.Triturado(veta)
    local m = Config.Materiales[veta]
    return m and m.triturado or nil
end

--- El cuadro donde se aparca para descargar: centro, radio y rumbo.
function Mina.Descarga()
    local d = Config.Planta.descarga
    return d.pos.xyz, d.radio, d.pos.w or 0.0
end

--- El borde del foso, donde se descarga a pie.
function Mina.Borde()
    local b = Config.Planta.borde
    return b.pos, b.radio
end

-- ── Geometría ─────────────────────────────────────────────────────────────

function Mina.Plano(a, b)
    local dx, dy = a.x - b.x, a.y - b.y
    return math.sqrt(dx * dx + dy * dy)
end

--- El vector del suelo hacia el que apunta un rumbo de GTA (0 = norte, 90 = oeste).
function Mina.Direccion(rumbo)
    local h = math.rad(rumbo or 0.0)
    return -math.sin(h), math.cos(h)
end

-- ── Niveles y textos ──────────────────────────────────────────────────────

function Mina.Nivel(xp)
    xp = tonumber(xp) or 0
    local nivel = 1
    for i, datos in ipairs(Config.Niveles) do
        if xp >= datos.xp then nivel = i end
    end
    return nivel, Config.Niveles[nivel], Config.Niveles[nivel + 1]
end

--- Lo que se abre en un nivel, en frases cortas.
function Mina.QueAbre(nivel)
    local lista = {}
    for _, id in ipairs(Config.OrdenMateriales) do
        local m = Config.Materiales[id]
        if m.nivel == nivel and m.peso > 0 then
            lista[#lista + 1] = ('vetas de %s (%s el pedrusco)'):format(m.nombre:lower(), Mina.Dinero(m.pago))
        end
    end
    for _, id in ipairs(Config.Vehiculos.orden) do
        local v = Config.Vehiculos.tipos[id]
        if v.nivel == nivel and nivel > 1 then lista[#lista + 1] = ('%s (%d pedruscos)'):format(v.nombre:lower(), #Mina.Huecos(id)) end
    end
    for _, id in ipairs(Config.OrdenHerramientas) do
        local h = Config.Herramientas[id]
        if h.nivel == nivel and nivel > 1 then lista[#lista + 1] = h.nombre:lower() end
    end
    if Config.Carretilla.nivel == nivel then lista[#lista + 1] = 'la carretilla' end
    if Config.Explosivos.nivel == nivel then lista[#lista + 1] = 'cargas explosivas' end
    if Config.Voladura.nivel == nivel then lista[#lista + 1] = 'voladuras de bloque (y oro)' end
    return lista
end

--- Una veta al azar entre las abiertas a ese nivel, por su peso. `frente`
--- (opcional) limita a las vetas de ese frente.
function Mina.VetaAlAzar(nivel, frente)
    local f = frente and Mina.Frente(frente)
    local vale = {}
    for _, id in ipairs(f and f.vetas or Config.OrdenMateriales) do vale[id] = true end
    local total = 0
    for _, id in ipairs(Config.OrdenMateriales) do
        local m = Config.Materiales[id]
        if vale[id] and m.nivel <= nivel and m.peso > 0 then total = total + m.peso end
    end
    local r = math.random() * total
    for _, id in ipairs(Config.OrdenMateriales) do
        local m = Config.Materiales[id]
        if vale[id] and m.nivel <= nivel and m.peso > 0 then
            r = r - m.peso
            if r <= 0 then return id end
        end
    end
    return 'piedra'
end

function Mina.Cortar(s, n)
    if type(s) ~= 'string' then return '' end
    local largo = utf8.len(s)
    if not largo then return '' end
    if largo <= n then return s end
    return s:sub(1, utf8.offset(s, n + 1) - 1)
end

function Mina.Dinero(n)
    local s = tostring(math.floor(tonumber(n) or 0))
    local r = s:reverse():gsub('(%d%d%d)', '%1.'):reverse()
    return '$' .. r:gsub('^%.', '')
end

--- Segundos de una tanda de golpes con la herramienta que lleva.
function Mina.TiempoGolpe(herramienta)
    local h = Config.Herramientas[herramienta or 'pico'] or Config.Herramientas.pico
    return math.max(1.0, Config.Roca.segundos * h.factor)
end

-- ── Los huecos de la caja ─────────────────────────────────────────────────

--- Dónde va cada pedrusco en la caja, en coordenadas del vehículo. Lo usan
--- el cliente para pintarlos y el servidor para repartirlos: tiene que ser
--- la MISMA lista.
function Mina.Huecos(tipo)
    local c = Config.Vehiculos.tipos[tipo or 'camioneta'].carga
    local lista = {}
    for piso = 0, c.pisos - 1 do
        for _, fila in ipairs(c.filas) do
            for _, col in ipairs(c.columnas) do
                lista[#lista + 1] = { x = col, y = fila, z = c.suelo + piso * (c.alto or 0.4), piso = piso }
            end
        end
    end
    return lista
end
