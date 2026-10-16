--[[ Utilidades que usan el cliente y el servidor por igual. ]]

Vuelo = Vuelo or {}

-- ── Niveles ───────────────────────────────────────────────────────────────

Vuelo.NivelPorId = {}
for i, n in ipairs(Config.Niveles) do
    n.orden = i
    Vuelo.NivelPorId[n.id] = n
end

--- El nivel por su número (1 básica … 3 alta), o nil.
function Vuelo.Nivel(orden)
    return Config.Niveles[tonumber(orden) or 0]
end

--- Qué modelos cubre un nivel (acumulando los de abajo). Hash → true.
local cubre = {}
for i, n in ipairs(Config.Niveles) do
    local t = {}
    if i > 1 then for h in pairs(cubre[i - 1]) do t[h] = true end end
    for _, m in ipairs(n.modelos or {}) do t[GetHashKey(m)] = true end
    cubre[i] = t
end

--- ¿La licencia de nivel `orden` deja pilotar este modelo (hash)?
function Vuelo.Cubre(orden, modelo)
    orden = tonumber(orden) or 0
    local n = Vuelo.Nivel(orden)
    if not n then return false end
    if n.todo then return true end
    return cubre[orden][modelo] == true
end

--- El nivel más bajo que cubre ese modelo.
function Vuelo.NivelQuePide(modelo)
    for i = 1, #Config.Niveles do
        if Vuelo.Cubre(i, modelo) then return i end
    end
    return #Config.Niveles
end

-- ── La pista ──────────────────────────────────────────────────────────────
--[[ Todo el circuito se mide en ejes de la pista:
       d  metros a lo largo del eje, desde la cabecera ESTE hacia la OESTE
          (0 = cabecera este, L = cabecera oeste, más de L = más allá)
       l  metros a un lado: positivo a la DERECHA mirando hacia el oeste
          (o sea, hacia el norte, donde están los hangares)
     Así, si se mide de nuevo la pista, todas las rutas se mueven con ella. ]]

function Vuelo.EjesPista()
    local a, b = Config.Pista.este, Config.Pista.oeste
    local dx, dy = b.x - a.x, b.y - a.y
    local L = math.sqrt(dx * dx + dy * dy)
    local ux, uy = dx / L, dy / L
    -- rumbo de GTA: 0 norte, crece hacia el oeste (antihorario)
    local rumbo = (math.deg(math.atan(-ux, uy)) + 360.0) % 360.0
    return {
        a = a, b = b, L = L, ux = ux, uy = uy,
        -- derecha del eje (girar el vector 90° en sentido horario)
        nx = uy, ny = -ux,
        rumbo = rumbo,
        z = (a.z + b.z) / 2,
    }
end

Vuelo.P = Vuelo.EjesPista()

--- Un punto en ejes de pista → mundo. `z` absoluta; si no, la de la pista.
function Vuelo.EnPista(d, l, z)
    local P = Vuelo.P
    local ez = P.a.z + (P.b.z - P.a.z) * math.max(0.0, math.min(1.0, d / P.L))
    return vec3(P.a.x + P.ux * d + P.nx * (l or 0.0), P.a.y + P.uy * d + P.ny * (l or 0.0), z or ez)
end

--- Mundo → ejes de pista (d, l).
function Vuelo.AEjes(pos)
    local P = Vuelo.P
    local rx, ry = pos.x - P.a.x, pos.y - P.a.y
    return rx * P.ux + ry * P.uy, rx * P.nx + ry * P.ny
end

--- ¿Está sobre la pista (en el plano)? `d0..d1` recorta el tramo.
function Vuelo.SobrePista(pos, d0, d1, margen)
    local d, l = Vuelo.AEjes(pos)
    d0, d1 = d0 or -15.0, d1 or (Vuelo.P.L + 15.0)
    return d >= d0 and d <= d1 and math.abs(l) <= Config.Pista.semiancho + (margen or 0.0), d, l
end

-- ── Geometría y formato ───────────────────────────────────────────────────

function Vuelo.Plano(a, b)
    local dx, dy = a.x - b.x, a.y - b.y
    return math.sqrt(dx * dx + dy * dy)
end

--- Diferencia de rumbos, de -180 a 180.
function Vuelo.DifRumbo(a, b)
    return ((a - b + 540.0) % 360.0) - 180.0
end

function Vuelo.Dinero(n)
    local s = tostring(math.floor(tonumber(n) or 0))
    local r = s:reverse():gsub('(%d%d%d)', '%1.'):reverse()
    return '$' .. r:gsub('^%.', '')
end

function Vuelo.Duracion(seg)
    seg = math.max(0, math.floor(tonumber(seg) or 0))
    if seg >= 60 then return ('%d min %02d s'):format(seg // 60, seg % 60) end
    return ('%d s'):format(seg)
end

function Vuelo.Cortar(txt, n)
    txt = tostring(txt or '')
    if #txt <= n then return txt end
    return txt:sub(1, n)
end
