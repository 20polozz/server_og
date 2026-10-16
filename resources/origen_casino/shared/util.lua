--[[ Utilidades que usan el cliente y el servidor por igual. ]]

Casino = Casino or {}

local ESTE = GetCurrentResourceName()

function Casino.Traza(...)
    if not Config.Depurar then return end
    local partes = {}
    for i = 1, select('#', ...) do partes[#partes + 1] = tostring(select(i, ...)) end
    print('^5[' .. ESTE .. ']^7 ' .. table.concat(partes, ' '))
end

function Casino.Aviso(...)
    local partes = {}
    for i = 1, select('#', ...) do partes[#partes + 1] = tostring(select(i, ...)) end
    print('^3[' .. ESTE .. ']^7 ' .. table.concat(partes, ' '))
end

-- ── Texto ─────────────────────────────────────────────────────────────────

--[[ Recorta a `n` LETRAS sin partir una tilde: `s:sub(1, n)` cuenta bytes y
     deja media «í» colgando, un texto roto que luego revienta al pasarlo a
     JSON. Un texto que no es UTF-8 válido se descarta entero. ]]
function Casino.Cortar(s, n)
    if type(s) ~= 'string' then return '' end
    local largo = utf8.len(s)
    if not largo then return '' end
    if largo <= n then return s end
    return s:sub(1, utf8.offset(s, n + 1) - 1)
end

--- Quita los caracteres de control y los < > (nada de HTML en los nombres).
function Casino.Limpiar(s, n)
    if type(s) ~= 'string' then return '' end
    s = s:gsub('[%z\1-\31\127<>]', ''):gsub('^%s+', ''):gsub('%s+$', '')
    return Casino.Cortar(s, n or 60)
end

--- Un identificador de los nuestros: minúsculas, números y guión bajo.
function Casino.Clave(v, largo)
    if type(v) ~= 'string' then return nil end
    v = v:lower()
    if not v:match('^[a-z][a-z0-9_]*$') or #v > (largo or 32) then return nil end
    return v
end

-- ── Números ───────────────────────────────────────────────────────────────

function Casino.Num(v, min, max, porDefecto)
    v = tonumber(v)
    if not v or v ~= v then return porDefecto end
    if min and v < min then v = min end
    if max and v > max then v = max end
    return v
end

function Casino.Ent(v, min, max, porDefecto)
    local n = Casino.Num(v, min, max, porDefecto)
    return n and math.floor(n + 0.5) or n
end

function Casino.Bool(v, porDefecto)
    if v == nil then return porDefecto end
    return v == true or v == 1
end

--- 1234567 → «1.234.567». Los puntos de millar, a la española.
function Casino.Miles(n)
    local s = tostring(math.floor(tonumber(n) or 0))
    local signo = ''
    if s:sub(1, 1) == '-' then signo, s = '-', s:sub(2) end
    local salida = s:reverse():gsub('(%d%d%d)', '%1.'):reverse()
    salida = salida:gsub('^%.', '')
    return signo .. salida
end

-- ── Azar ──────────────────────────────────────────────────────────────────

--[[ Elegir de una lista con pesos. Devuelve el elemento y su posición.

     La lista puede traer los pesos en `peso` o ser una tabla de números. Un
     peso que no sea un número positivo cuenta como cero: así se puede apagar
     un premio poniéndole 0 sin tener que sacarlo de la lista. ]]
function Casino.Sorteo(lista, campo)
    campo = campo or 'peso'
    local total = 0
    for _, e in ipairs(lista) do
        local p = tonumber(type(e) == 'table' and e[campo] or e) or 0
        if p > 0 then total = total + p end
    end
    if total <= 0 then return lista[1], 1 end

    local tirada = math.random() * total
    local suma = 0
    for i, e in ipairs(lista) do
        local p = tonumber(type(e) == 'table' and e[campo] or e) or 0
        if p > 0 then
            suma = suma + p
            if tirada <= suma then return e, i end
        end
    end
    return lista[#lista], #lista
end

--- Baraja una tabla en el sitio (Fisher-Yates).
function Casino.Barajar(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

-- ── Ritmo ─────────────────────────────────────────────────────────────────

--[[ Un freno por jugador y por acción. Que una pantalla mande algo no lo hace
     legítimo: los callbacks los puede llamar cualquiera desde la consola, tan
     deprisa como quiera. ]]
local ultimos = {}

function Casino.Ritmo(quien, accion, ms)
    local clave = tostring(quien) .. ':' .. accion
    local ahora = GetGameTimer()
    local antes = ultimos[clave]
    if antes and ahora - antes < (ms or 500) then return false end
    ultimos[clave] = ahora
    return true
end

function Casino.OlvidarRitmo(quien)
    local prefijo = tostring(quien) .. ':'
    for clave in pairs(ultimos) do
        if clave:sub(1, #prefijo) == prefijo then ultimos[clave] = nil end
    end
end

-- ── Sitios ────────────────────────────────────────────────────────────────

--- ¿Está este punto dentro del recinto del casino? Solo en planta.
function Casino.EnElCasino(x, y)
    local z = Config.General.zona
    if not z or not z.radio or z.radio <= 0 then return true end
    local dx, dy = x - z.x, y - z.y
    return dx * dx + dy * dy <= z.radio * z.radio
end

--[[ Dónde se sienta alguien en la plaza `i` de un punto colocado.

     El punto tiene rumbo, y los asientos del catálogo están medidos respecto a
     él: hay que girar el desplazamiento antes de sumarlo. Sin esto, girar una
     mesa dejaría los asientos en su sitio de antes, que es el fallo que hace
     que la gente se siente en el aire. ]]
function Casino.Asiento(punto, tipo, i)
    local a = tipo.asientos and tipo.asientos[i]
    if not a then return nil end
    local rad = math.rad(punto.h or 0.0)
    local cos, sin = math.cos(rad), math.sin(rad)
    -- En GTA el rumbo 0 mira a +Y, y crece hacia la izquierda (antihorario).
    local dx = a.dx * cos - a.dy * sin
    local dy = a.dx * sin + a.dy * cos
    return {
        x = punto.x + dx,
        y = punto.y + dy,
        z = punto.z + (a.dz or 0.0),
        h = ((punto.h or 0.0) + (a.dh or 0.0)) % 360.0,
    }
end

-- ── El reloj ──────────────────────────────────────────────────────────────

--- El día natural de hoy, como texto 'AAAA-MM-DD'. Es la clave de los topes.
function Casino.Hoy(momento)
    return os.date('%Y-%m-%d', momento or os.time())
end

--- Segundos que quedan hasta la medianoche del servidor.
function Casino.HastaMedianoche()
    local t = os.date('*t')
    return (23 - t.hour) * 3600 + (59 - t.min) * 60 + (60 - t.sec)
end
