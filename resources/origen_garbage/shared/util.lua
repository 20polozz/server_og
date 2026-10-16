--[[ Utilidades que usan el cliente y el servidor por igual. ]]

Basura = Basura or {}

function Basura.Miga(...)
end

-- ── Lo que se recoge ──────────────────────────────────────────────────────

--- Hash del modelo → tipo ('bolsa', 'cubo', 'contenedor').
Basura.TipoDeHash = {}
for nombre, tipo in pairs(Config.Modelos) do
    Basura.TipoDeHash[joaat(nombre) & 0xFFFFFFFF] = tipo
    Basura.TipoDeHash[joaat(nombre)] = tipo
end

function Basura.Tipo(hash)
    hash = tonumber(hash)
    if not hash then return nil end
    local tipo = Basura.TipoDeHash[hash] or Basura.TipoDeHash[hash & 0xFFFFFFFF]
    return tipo, tipo and Config.Tipos[tipo]
end

--[[ La clave de un cubo del mapa: su modelo y su sitio redondeado a medio
     metro. Los objetos del mapa no tienen id que valga entre clientes; su
     modelo y su posición, sí (son los mismos para todos). ]]
function Basura.Clave(hash, x, y)
    return ('%d:%d:%d'):format(math.floor(tonumber(hash) or 0) & 0xFFFFFFFF, math.floor(x * 2 + 0.5), math.floor(y * 2 + 0.5))
end

-- ── Geometría ─────────────────────────────────────────────────────────────

function Basura.Plano(a, b)
    local dx, dy = a.x - b.x, a.y - b.y
    return math.sqrt(dx * dx + dy * dy)
end

--- Un punto en coordenadas de un vehículo con rumbo `h` (grados de GTA).
function Basura.Offset(pos, h, o)
    local r = math.rad(h or 0.0)
    local c, s = math.cos(r), math.sin(r)
    return vec3(pos.x + o.x * c - o.y * s, pos.y + o.x * s + o.y * c, pos.z + (o.z or 0.0))
end

-- ── Niveles y textos ──────────────────────────────────────────────────────

function Basura.Nivel(xp)
    xp = tonumber(xp) or 0
    local nivel = 1
    for i, datos in ipairs(Config.Niveles) do
        if xp >= datos.xp then nivel = i end
    end
    return nivel, Config.Niveles[nivel], Config.Niveles[nivel + 1]
end

--- Lo que se paga por bolsa en ese nivel.
function Basura.PagoBolsa(nivel)
    local n = Config.Niveles[nivel] or Config.Niveles[1]
    return Config.Descarga.pago * (1 + (n.extra or 0))
end

--- Lo que se abre en un nivel, en frases cortas.
function Basura.QueAbre(nivel)
    local lista = {}
    local n = Config.Niveles[nivel]
    if n and (n.extra or 0) > 0 then
        lista[#lista + 1] = ('+%d %% por bolsa (%s)'):format(math.floor(n.extra * 100 + 0.5), Basura.Dinero(Basura.PagoBolsa(nivel), true))
    end
    for _, id in ipairs(Config.Vehiculos.orden) do
        local v = Config.Vehiculos.tipos[id]
        if v.nivel == nivel then lista[#lista + 1] = ('%s (%d bolsas)'):format(v.nombre:lower(), v.capacidad) end
    end
    return lista
end

function Basura.Cortar(s, n)
    if type(s) ~= 'string' then return '' end
    local largo = utf8.len(s)
    if not largo then return '' end
    if largo <= n then return s end
    return s:sub(1, utf8.offset(s, n + 1) - 1)
end

--- «$1.250»; con `decimales`, «$11,55».
function Basura.Dinero(n, decimales)
    n = tonumber(n) or 0
    if decimales and n % 1 ~= 0 then
        return ('$%s'):format(('%.2f'):format(n):gsub('%.', ','))
    end
    local s = tostring(math.floor(n))
    local r = s:reverse():gsub('(%d%d%d)', '%1.'):reverse()
    return '$' .. r:gsub('^%.', '')
end

function Basura.Duracion(seg)
    seg = math.max(0, math.floor(tonumber(seg) or 0))
    if seg >= 3600 then return ('%dh %dm'):format(seg // 3600, (seg % 3600) // 60) end
    if seg >= 60 then return ('%d min'):format(math.ceil(seg / 60)) end
    return ('%ds'):format(seg)
end
