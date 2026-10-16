--[[ ── Escondite · ayudantes compartidos ──────────────────────────────────── ]]

Util = {}

function Util.Contar(t)
    local n = 0
    for _ in pairs(t or {}) do n = n + 1 end
    return n
end

function Util.Acotar(v, min, max)
    v = tonumber(v) or min
    if v < min then return min end
    if v > max then return max end
    return v
end

function Util.Entero(v, min, max)
    return math.floor(Util.Acotar(v, min, max))
end

--- Un texto que ha escrito un jugador, limpio para enseñárselo a otros: sin
--- marcas, sin saltos y recortado. Se pinta en una NUI, y un `<img onerror>`
--- en el nombre de una sala se ejecutaría en la pantalla de todo el que abra
--- la lista si algún día alguien usa v-html por descuido.
function Util.Texto(v, max)
    if type(v) ~= 'string' then return '' end
    v = v:gsub('[%c<>`]', ''):gsub('%s+', ' ')
    v = v:match('^%s*(.-)%s*$') or ''
    if #v > max then
        v = v:sub(1, max)
        -- Cortar por bytes puede partir una letra con tilde por la mitad, y
        -- media letra llega a la pantalla como un rombo con interrogación.
        while #v > 0 and not utf8.len(v) do v = v:sub(1, -2) end
    end
    return v
end

function Util.Dist2D(a, b)
    local dx, dy = a.x - b.x, a.y - b.y
    return math.sqrt(dx * dx + dy * dy)
end

function Util.Dist3D(a, b)
    local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function Util.Barajar(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end
