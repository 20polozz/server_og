--[[ Los minijuegos del gimnasio.

     Cada ejercicio tiene el suyo, y lo bien que salga decide cuanto sube la
     habilidad en esa serie (Config.Minijuego). Son cinco mecanicas, todas de
     teclado y SIN foco de la interfaz: el raton sigue siendo de la camara y la
     pantalla solo pinta lo que esto le va diciendo.

       tempo        una aguja va y viene; ESPACIO cuando pasa por la zona
       aguante      una barra que se vacia; ESPACIO para mantenerla en la franja
       alterno      ← y → alternadas, a un ritmo que hay que sostener
       secuencia    series de flechas en orden
       respiracion  mantener y soltar ESPACIO para seguir a una guia

     La nota va de 0 a 1 y la calcula esto; el servidor la recorta y decide
     cuanto vale. ]]

Juego = {}

local ESPACIO, ARRIBA, ABAJO, IZQUIERDA, DERECHA = 22, 172, 173, 174, 175
local FLECHAS = { ARRIBA, ABAJO, IZQUIERDA, DERECHA }
local NOMBRE = { [ARRIBA] = 'arriba', [ABAJO] = 'abajo', [IZQUIERDA] = 'izquierda', [DERECHA] = 'derecha' }

local function Pulsa(c) return IsDisabledControlJustPressed(0, c) end
local function Entre(v, a, b) return math.max(a, math.min(b, v)) end

local J = nil        -- la partida en curso
local enviado = 0    -- cuando se le mando el ultimo estado a la pantalla

--- Un destello de acierto o de fallo, que la pantalla pinta un momento.
local function Destello(que)
    J.destello, J.destelloHasta = que, GetGameTimer() + 260
end

local MECANICAS = {}

-- ── tempo ───────────────────────────────────────────────────────────────────
MECANICAS.tempo = {
    empezar = function(c)
        J.periodo = c.periodo or 2.2
        J.ancho = c.ancho or 0.2
        J.centro = 0.3 + math.random() * 0.4
        J.objetivo = c.objetivo or 8
        J.aciertos, J.fallos, J.p = 0, 0, 0.0
    end,
    paso = function(_, ahora)
        local fase = ((ahora - J.desde) / 1000 / J.periodo) % 2.0
        J.p = fase <= 1.0 and fase or (2.0 - fase)

        if Pulsa(ESPACIO) then
            if math.abs(J.p - J.centro) <= J.ancho / 2 then
                J.aciertos = J.aciertos + 1
                -- La zona salta de sitio y se estrecha un poco: cada repeticion pide mas.
                J.centro = 0.15 + math.random() * 0.7
                J.ancho = math.max(0.1, J.ancho * 0.93)
                Destello('bien')
            else
                J.fallos = J.fallos + 1
                Destello('mal')
            end
        end
    end,
    nota = function() return Entre((J.aciertos - 0.5 * J.fallos) / J.objetivo, 0, 1) end,
    estado = function()
        return { m = J.p, z0 = J.centro - J.ancho / 2, z1 = J.centro + J.ancho / 2, n = J.aciertos, de = J.objetivo }
    end,
    teclas = { { 'ESPACIO', 'cuando la aguja pase por la zona' } },
}

-- ── aguante ─────────────────────────────────────────────────────────────────
MECANICAS.aguante = {
    empezar = function(c)
        J.cae, J.sube = c.cae or 0.26, c.sube or 0.085
        J.z0, J.z1 = c.desde or 0.55, c.hasta or 0.8
        J.v, J.dentro, J.total = 0.45, 0.0, 0.0
    end,
    paso = function(dt)
        J.v = J.v - J.cae * dt
        if Pulsa(ESPACIO) then J.v = J.v + J.sube end
        J.v = Entre(J.v, 0, 1)
        J.total = J.total + dt
        if J.v >= J.z0 and J.v <= J.z1 then J.dentro = J.dentro + dt end
    end,
    nota = function() return J.total > 0 and Entre(J.dentro / J.total / 0.85, 0, 1) or 0 end,
    estado = function() return { m = J.v, z0 = J.z0, z1 = J.z1, lleno = true } end,
    teclas = { { 'ESPACIO', 'a golpes, para mantenerte en la franja' } },
}

-- ── alterno ─────────────────────────────────────────────────────────────────
MECANICAS.alterno = {
    empezar = function(c)
        J.lento, J.rapido, J.tope = c.desde or 2.0, c.hasta or 3.4, c.tope or 5.0
        J.toca, J.marcas, J.ritmo = IZQUIERDA, {}, 0.0
        J.dentro, J.total = 0.0, 0.0
    end,
    paso = function(dt, ahora)
        for _, tecla in ipairs({ IZQUIERDA, DERECHA }) do
            if Pulsa(tecla) then
                if tecla == J.toca then
                    J.marcas[#J.marcas + 1] = ahora
                    J.toca = tecla == IZQUIERDA and DERECHA or IZQUIERDA
                else
                    -- Dos veces la misma: se pierde el paso.
                    J.marcas = {}
                    Destello('mal')
                end
            end
        end
        -- El ritmo: pulsaciones buenas en el ultimo segundo y medio.
        while J.marcas[1] and ahora - J.marcas[1] > 1500 do table.remove(J.marcas, 1) end
        J.ritmo = #J.marcas / 1.5
        J.total = J.total + dt
        if J.ritmo >= J.lento and J.ritmo <= J.rapido then J.dentro = J.dentro + dt end
    end,
    nota = function() return J.total > 0 and Entre(J.dentro / J.total / 0.85, 0, 1) or 0 end,
    estado = function()
        return { m = Entre(J.ritmo / J.tope, 0, 1), z0 = J.lento / J.tope, z1 = J.rapido / J.tope, lleno = true,
                 teclas = { 'izquierda', 'derecha' }, i = J.toca == IZQUIERDA and 1 or 2 }
    end,
    teclas = { { '← →', 'alternadas, sin pasarte ni quedarte corto' } },
}

-- ── secuencia ───────────────────────────────────────────────────────────────
local function OtraSecuencia()
    J.serie, J.i = {}, 1
    for n = 1, J.largo do J.serie[n] = FLECHAS[math.random(#FLECHAS)] end
end

MECANICAS.secuencia = {
    empezar = function(c)
        J.largo, J.objetivo = c.largo or 4, c.objetivo or 6
        J.hechas, J.fallos = 0, 0
        OtraSecuencia()
    end,
    paso = function()
        for _, tecla in ipairs(FLECHAS) do
            if Pulsa(tecla) then
                if tecla == J.serie[J.i] then
                    J.i = J.i + 1
                    if J.i > J.largo then
                        J.hechas = J.hechas + 1
                        Destello('bien')
                        OtraSecuencia()
                    end
                else
                    J.fallos = J.fallos + 1
                    J.i = 1
                    Destello('mal')
                end
                break
            end
        end
    end,
    nota = function() return Entre((J.hechas - 0.25 * J.fallos) / J.objetivo, 0, 1) end,
    estado = function()
        local t = {}
        for n, tecla in ipairs(J.serie) do t[n] = NOMBRE[tecla] end
        return { teclas = t, i = J.i, n = J.hechas, de = J.objetivo }
    end,
    teclas = { { '↑ ↓ ← →', 'en el orden que salen' } },
}

-- ── respiracion ─────────────────────────────────────────────────────────────
MECANICAS.respiracion = {
    empezar = function(c)
        J.periodo, J.margen, J.paso = c.periodo or 6.0, c.margen or 0.12, c.velocidad or 0.42
        J.v, J.g, J.dentro, J.total = 0.5, 0.5, 0.0, 0.0
    end,
    paso = function(dt, ahora)
        J.g = 0.5 + 0.36 * math.sin((ahora - J.desde) / 1000 / J.periodo * 2 * math.pi)
        J.v = Entre(J.v + (IsDisabledControlPressed(0, ESPACIO) and J.paso or -J.paso) * dt, 0, 1)
        J.total = J.total + dt
        if math.abs(J.v - J.g) <= J.margen then J.dentro = J.dentro + dt end
    end,
    nota = function() return J.total > 0 and Entre(J.dentro / J.total / 0.85, 0, 1) or 0 end,
    estado = function() return { m = J.v, z0 = J.g - J.margen, z1 = J.g + J.margen } end,
    teclas = { { 'ESPACIO', 'mantén para subir, suelta para bajar: sigue la franja' } },
}

-- ---------------------------------------------------------------------------

--- Empieza la serie de un ejercicio. `c` es el `juego` de su tipo en el config.
function Juego.Empezar(c, titulo, serie)
    local m = MECANICAS[c and c.mecanica or '']
    if not m then return false end

    J = { m = m, clase = c.mecanica, desde = GetGameTimer(), antes = GetGameTimer() }
    m.empezar(c)
    enviado = 0
    SendNUIMessage({ a = 'juego', clase = J.clase, titulo = titulo, serie = serie, teclas = m.teclas })
    return true
end

--- Cada fotograma mientras dura la serie.
function Juego.Paso()
    if not J then return end
    local ahora = GetGameTimer()
    local dt = math.min(0.1, (ahora - J.antes) / 1000)
    J.antes = ahora
    J.m.paso(dt, ahora)

    -- A la pantalla, unas treinta veces por segundo: mas no se nota.
    if ahora - enviado >= 33 then
        enviado = ahora
        local e = J.m.estado()
        e.a = 'juego_estado'
        e.destello = ahora < (J.destelloHasta or 0) and J.destello or nil
        SendNUIMessage(e)
    end
end

--- Acaba la serie y dice que tal ha ido, de 0 a 1.
function Juego.Nota()
    if not J then return 0.0 end
    local nota = J.m.nota() + 0.0
    J = nil
    return nota
end

function Juego.Parar()
    J = nil
end

function Juego.EnCurso()
    return J ~= nil
end

--- Como va la serie ahora mismo (lo mismo que se le manda a la pantalla).
function Juego.Estado()
    if not J then return nil end
    local e = J.m.estado()
    e.clase = J.clase
    return e
end
