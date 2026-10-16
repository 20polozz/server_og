--[[ Utilidades que usan el cliente y el servidor por igual. ]]

Caza = Caza or {}

function Caza.Miga(...)
end

function Caza.Traza(...)
    if not Config.Depurar then return end
    local partes = {}
    for i = 1, select('#', ...) do partes[#partes + 1] = tostring(select(i, ...)) end
    print('^3[origen_hunting]^7 ' .. table.concat(partes, ' '))
end

--- Un hash a sus dos formas. El cliente los da con signo y los eventos del
--- servidor sin él; comparar uno con otro sin convertir nunca coincide.
function Caza.Hashes(valor)
    local n = tonumber(valor)
    if not n then return nil, nil end
    n = math.floor(n)
    if n < 0 then return n, n + 0x100000000 end
    if n > 0x7FFFFFFF then return n - 0x100000000, n end
    return n, n
end

--- Una tabla indexada por los hashes de unos nombres, con signo Y sin él.
function Caza.TablaDeHashes(nombres, valor)
    local t = {}
    for nombre, dato in pairs(nombres) do
        local con, sin = Caza.Hashes(GetHashKey(nombre))
        local v = valor ~= nil and valor or dato
        t[con] = v
        t[sin] = v
    end
    return t
end

Caza.ArmaPorHash = Caza.TablaDeHashes(Config.Armas)

function Caza.Arma(hash)
    local con = Caza.Hashes(hash)
    return con and Caza.ArmaPorHash[con] or nil
end

--- La zona que contiene un punto, mirando solo la planta.
function Caza.ZonaEn(x, y)
    for _, zona in ipairs(Config.Zonas) do
        local dx, dy = x - zona.centro.x, y - zona.centro.y
        if dx * dx + dy * dy <= zona.radio * zona.radio then
            return zona
        end
    end
    return nil
end

function Caza.ZonaPorId(id)
    for _, zona in ipairs(Config.Zonas) do
        if zona.id == id then return zona end
    end
    return nil
end

--- Nivel, datos del nivel y experiencia que pide el siguiente.
function Caza.Nivel(xp)
    xp = tonumber(xp) or 0
    local nivel = 1
    for i, datos in ipairs(Config.Niveles) do
        if xp >= datos.xp then nivel = i end
    end
    local actual = Config.Niveles[nivel]
    local siguiente = Config.Niveles[nivel + 1]
    return nivel, actual, siguiente
end

--- La franja del día (1 amanecer, 2 día, 3 atardecer, 4 noche).
function Caza.Franja(hora)
    hora = tonumber(hora) or 12
    for i, f in ipairs(Config.Franjas) do
        if hora >= f.desde and hora <= f.hasta then return i end
    end
    return 4
end

--- Recorta a `n` LETRAS sin partir una tilde: `s:sub(1, n)` cuenta bytes y
--- deja media «í» colgando, un texto roto que luego revienta al pasarlo a
--- JSON. Un texto que no es UTF-8 válido se descarta.
function Caza.Cortar(s, n)
    if type(s) ~= 'string' then return '' end
    local largo = utf8.len(s)
    if not largo then return '' end
    if largo <= n then return s end
    return s:sub(1, utf8.offset(s, n + 1) - 1)
end

--- Quita los caracteres de control ASCII y los < > (nada de HTML en los
--- nombres). Solo ASCII: `%c` depende del locale y en algunos se lleva bytes
--- de las letras con tilde.
function Caza.Limpiar(s, n)
    if type(s) ~= 'string' then return '' end
    s = s:gsub('[%z\1-\31\127<>]', ''):gsub('^%s+', ''):gsub('%s+$', '')
    return Caza.Cortar(s, n or 60)
end

--- Cifra con punto de miles (1.240, no 1240) para los textos que se ven.
function Caza.Miles(n)
    local v = math.floor((tonumber(n) or 0) + 0.5)
    local s = tostring(math.abs(v))
    local fuera = s:reverse():gsub('(%d%d%d)', '%1.'):reverse():gsub('^%.', '')
    return (v < 0 and '-' or '') .. fuera
end

function Caza.Estrellas(n)
    n = math.max(1, math.min(3, tonumber(n) or 1))
    return string.rep('★', n) .. string.rep('☆', 3 - n)
end
