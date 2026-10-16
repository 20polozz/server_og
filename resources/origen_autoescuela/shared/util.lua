--[[ Utilidades que usan el cliente y el servidor por igual. ]]

Auto = Auto or {}

-- ── Niveles ───────────────────────────────────────────────────────────────

Auto.NivelPorId = {}
for i, n in ipairs(Config.Niveles) do
    n.orden = i
    Auto.NivelPorId[n.id] = n
end

--- El nivel por su número (1 coche … 3 camión), o nil.
function Auto.Nivel(orden)
    return Config.Niveles[tonumber(orden) or 0]
end

--- Qué clases de vehículo cubre cada nivel, acumulando las de abajo.
local cubre = {}
for i, n in ipairs(Config.Niveles) do
    local t = {}
    if i > 1 then for c in pairs(cubre[i - 1]) do t[c] = true end end
    for _, c in ipairs(n.clases or {}) do t[c] = true end
    cubre[i] = t
end

--- ¿El carné de nivel `orden` deja conducir un vehículo de esa clase?
function Auto.Cubre(orden, clase)
    orden = tonumber(orden) or 0
    clase = tonumber(clase)
    if not clase or not Auto.Nivel(orden) then return false end
    if Config.Control.libres[clase] then return true end
    return cubre[orden][clase] == true
end

--- El nivel más bajo que cubre esa clase de vehículo (nil si no pide carné).
function Auto.NivelQuePide(clase)
    clase = tonumber(clase)
    if not clase or Config.Control.libres[clase] then return nil end
    for i = 1, #Config.Niveles do
        if cubre[i][clase] then return i end
    end
    return nil
end

-- ── Geometría ─────────────────────────────────────────────────────────────

function Auto.Plano(a, b)
    local dx, dy = a.x - b.x, a.y - b.y
    return math.sqrt(dx * dx + dy * dy)
end

--- Diferencia de rumbos, de -180 a 180.
function Auto.DifRumbo(a, b)
    return ((a - b + 540.0) % 360.0) - 180.0
end

--- El rumbo (de GTA) que lleva de `a` a `b`.
function Auto.RumboEntre(a, b)
    local dx, dy = b.x - a.x, b.y - a.y
    return (math.deg(math.atan(-dx, dy)) + 360.0) % 360.0
end

--[[ Hacia dónde se gira al pasar de un tramo al siguiente: 'izq', 'der' o
     'recto'. Se calcula de la propia ruta para no tener que escribirlo a
     mano punto por punto. ]]
function Auto.Giro(antes, aqui, despues)
    if not antes or not despues then return 'recto' end
    local d = Auto.DifRumbo(Auto.RumboEntre(aqui, despues), Auto.RumboEntre(antes, aqui))
    if d > 35.0 then return 'izq' end        -- en GTA el rumbo crece a la izquierda
    if d < -35.0 then return 'der' end
    return 'recto'
end

-- ── Formato ───────────────────────────────────────────────────────────────

function Auto.Dinero(n)
    local s = tostring(math.floor(tonumber(n) or 0))
    local r = s:reverse():gsub('(%d%d%d)', '%1.'):reverse()
    return '$' .. r:gsub('^%.', '')
end

function Auto.Duracion(seg)
    seg = math.max(0, math.floor(tonumber(seg) or 0))
    if seg >= 60 then return ('%d min %02d s'):format(seg // 60, seg % 60) end
    return ('%d s'):format(seg)
end

function Auto.Cortar(txt, n)
    txt = tostring(txt or '')
    if #txt <= n then return txt end
    return txt:sub(1, n)
end
