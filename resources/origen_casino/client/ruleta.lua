--[[ ══════════════════════════════════════════════════════════════════════════
     LA RULETA EN EL MUNDO

     Como en GTA Online: el crupier lanza la bola, el bombo gira de verdad y
     la bola corre por la pista y cae en el número que ha sacado el servidor.
     Lo ve todo el que esté cerca.

     ── Cómo se hace ────────────────────────────────────────────────────────

     · El bombo: las animaciones de la propia mesa (`intro_wheel` y luego
       `loop_wheel` en bucle, que es como se queda dando vueltas).
     · El crupier: una escena en el origen de la mesa, igual que en las de
       cartas; `spin_wheel` dura lo mismo que el arranque del bombo.
     · La bola: sale del hueso `Roulette_Wheel` con el rumbo de la mesa y hace
       el lanzamiento de GTA (`intro_ball`). Después NO se usan los 38 finales
       de GTA —no hay forma fiable de saber en qué número acaba cada uno—: se
       la lleva a mano, frenando, hasta la casilla del número, y ahí se queda
       dando vueltas con el bombo.

     ── Lo medido en el juego (24/09) ───────────────────────────────────────

     · El giro del hueso del bombo se puede leer en cada fotograma, y la
       casilla del 0 está siempre a 144° de él. Las demás van detrás, en el
       orden del bombo americano, cada 360/38 grados, en el sentido de las
       agujas del reloj visto desde arriba. Se afinó con la bola ENGANCHADA al
       hueso y el bombo parado, mirando la casilla verde. Moverla a mano en el
       mundo la dejaba medio número corrida: iba un fotograma por detrás del
       bombo. Por eso, desde que deja la pista, la bola va enganchada a él.
     · La bola trae una estela en el modelo que solo se recoge con una
       animación puesta: se le deja el último fotograma de `exit_1_ball`
       parado y se ve redonda.
     · La pista de la bola va a 0,32 m del centro y 8 mm por debajo del hueso;
       las casillas, a 0,173 m y 69 mm por debajo (a 0,194 quedaba encima de
       los números).
     · Al TERMINAR una animación de la mesa, el bombo vuelve de golpe a su
       posición de reposo: por eso se deja en `loop_wheel` y no se para nunca.
   ══════════════════════════════════════════════════════════════════════════ ]]

RuletaMundo = {}

local mesas = {}        -- [puntoId] = { punto, tipo, conf, mesa, hueso, centro, crupier, bola, ... }

local DICT = 'anim_casino_b@amb@casino@games@roulette@table'
local BOLA = 'vw_prop_roulette_ball'

-- El bombo americano, en el sentido de las agujas del reloj desde el 0.
-- El 00 va como 37, igual que en el servidor.
local ORDEN = { 0, 28, 9, 26, 30, 11, 7, 20, 32, 17, 5, 22, 34, 15, 3, 24, 36, 13, 1, 37,
                27, 10, 25, 29, 12, 8, 19, 31, 18, 6, 21, 33, 16, 4, 23, 35, 14, 2 }
local INDICE = {}
for i, n in ipairs(ORDEN) do INDICE[n] = i - 1 end

local DEL_CERO = 144.0                  -- grados de la casilla del 0 respecto al hueso
local CASILLA = 360.0 / 38
local PISTA = { r = 0.32, z = -0.008 }
local HUECO = { r = 0.173, z = -0.069 }

local function Rad(g) return math.rad(g) end

--- La bola, enganchada al bombo: `rel` grados respecto a su hueso.
local function PonerBola(m, rel, r, z)
    AttachEntityToEntity(m.bola, m.mesa, m.hueso, math.cos(Rad(rel)) * r, math.sin(Rad(rel)) * r, z,
        0.0, 0.0, 0.0, false, false, false, false, 2, true)
end

--- Redonda: el último fotograma de un final, parado (ver arriba).
local function Redonda(m)
    PlayEntityAnim(m.bola, 'exit_1_ball', DICT, 1000.0, false, true, true, 0.99, 136704)
    SetEntityAnimCurrentTime(m.bola, DICT, 'exit_1_ball', 0.99)
    SetEntityAnimSpeed(m.bola, DICT, 'exit_1_ball', 0.0)
end

local function QuitarBola(m)
    m.tirada = nil
    if m.bola and DoesEntityExist(m.bola) then
        DetachEntity(m.bola, false, false)
        DeleteEntity(m.bola)
    end
    m.bola = nil
end

-- ── El crupier ────────────────────────────────────────────────────────────

local function EscenaCrupier(m, anim, bucle)
    if not m.crupier or not DoesEntityExist(m.crupier) then return end
    local dict = m.mujer and m.conf.dictMujer or m.conf.dict
    local nombre = anim
    if m.mujer and GetAnimDuration(dict, 'female_' .. anim) > 0.0 then nombre = 'female_' .. anim end
    if GetAnimDuration(dict, nombre) <= 0.0 then dict, nombre = m.conf.dict, anim end
    if GetAnimDuration(dict, nombre) <= 0.0 then return end
    local o, r = m.origen, m.giro
    local esc = CreateSynchronizedScene(o.x, o.y, o.z, r.x, r.y, r.z, 2)
    SetSynchronizedSceneLooped(esc, bucle == true)
    TaskSynchronizedScene(m.crupier, esc, dict, nombre, 1000.0, -8.0, 4, 0, 1148846080, 0)
    m.escena = esc
    if not bucle then
        SetTimeout(math.floor(GetAnimDuration(dict, nombre) * 1000), function()
            if mesas[m.punto.id] == m and m.escena == esc then EscenaCrupier(m, m.conf.quieto, true) end
        end)
    end
end

local function PonerCrupier(m)
    local modelos = m.conf.modelos
    local hash = joaat(modelos[(m.punto.id % #modelos) + 1])
    pcall(lib.requestModel, hash, 5000)
    pcall(lib.requestAnimDict, m.conf.dict, 5000)
    if m.conf.dictMujer then pcall(lib.requestAnimDict, m.conf.dictMujer, 5000) end
    local p = CreatePed(4, hash, m.origen.x, m.origen.y, m.origen.z, m.punto.h, false, false)
    SetPedDefaultComponentVariation(p)
    SetEntityInvincible(p, true)
    SetBlockingOfNonTemporaryEvents(p, true)
    SetPedCanRagdoll(p, false)
    SetEntityCollision(p, false, false)
    m.crupier = p
    m.mujer = not IsPedMale(p)
    EscenaCrupier(m, m.conf.quieto, true)
    SetModelAsNoLongerNeeded(hash)
end

-- ── La tirada ─────────────────────────────────────────────────────────────

--[[ El bombo, dando vueltas en bucle (nunca se para: si terminara, volvería
     de golpe a su posición de reposo).

     `loop_wheel` da una vuelta cada 2 s (180°/s, a derechas) y su giro va
     con la fase: fase 0 = hueso a 219,1°, y baja 360° por vuelta (medido).
     Se arranca en la fase que corresponde al ángulo en que estaba y a la
     velocidad a la que iba, y va frenando hasta un giro lento de reposo. Con
     la velocidad normal de la animación, al acabar el lanzamiento el bombo se
     aceleraba de golpe y la bola, enganchada a él, salía disparada. ]]
local VUELTA = 180.0        -- grados por segundo de `loop_wheel` a velocidad 1
local REPOSO = 0.12         -- la velocidad a la que se queda dando vueltas

local function BomboEnBucle(m, velocidad, desdeGiro)
    local fase = desdeGiro and ((219.1 - desdeGiro) / 360.0) % 1.0 or 0.0
    -- La fase va al arrancar Y un fotograma después: puesta en el mismo
    -- fotograma que el Play, el juego no la aplica y el bombo saltaba ~80°.
    PlayEntityAnim(m.mesa, 'loop_wheel', DICT, 1000.0, true, true, true, fase, 136704)
    local v0 = velocidad or REPOSO
    SetEntityAnimSpeed(m.mesa, DICT, 'loop_wheel', v0)
    if desdeGiro then
        SetEntityAnimCurrentTime(m.mesa, DICT, 'loop_wheel', fase)
        Wait(0)
        SetEntityAnimCurrentTime(m.mesa, DICT, 'loop_wheel', fase + (v0 * VUELTA * GetFrameTime()) / 360.0)
        SetEntityAnimSpeed(m.mesa, DICT, 'loop_wheel', v0)
    end

    -- Frena poco a poco hasta el reposo.
    local freno = {}
    m.freno = freno
    if v0 <= REPOSO then return end
    CreateThread(function()
        local t0 = GetGameTimer()
        while m.freno == freno and mesas[m.punto.id] == m do
            local t = (GetGameTimer() - t0) / 1000.0
            local v = math.max(REPOSO, v0 * math.exp(-t / 3.5))
            SetEntityAnimSpeed(m.mesa, DICT, 'loop_wheel', v)
            if v <= REPOSO then break end
            Wait(100)
        end
    end)
end

local function Angulo(d) return ((d + 540.0) % 360.0) - 180.0 end

--[[ Lanza la bola y la deja en la casilla de `numero`. Con `deGolpe` (quien
     llega con la bola ya caída) se pone directamente en su casilla. ]]
local function Tirar(m, numero, deGolpe)
    QuitarBola(m)
    local tirada = {}
    m.tirada = tirada

    local hash = joaat(BOLA)
    pcall(lib.requestModel, hash, 5000)
    local c = m.centro
    m.bola = CreateObjectNoOffset(hash, c.x, c.y, c.z, false, false, false)
    SetEntityCollision(m.bola, false, false)
    FreezeEntityPosition(m.bola, true)
    SetEntityRotation(m.bola, 0.0, 0.0, m.giro.z, 2, true)

    CreateThread(function()
        if not deGolpe then
            -- El lanzamiento: el crupier, el bombo y la bola a la vez.
            EscenaCrupier(m, m.conf.lanzar, false)
            PlayEntityAnim(m.mesa, 'intro_wheel', DICT, 1000.0, false, true, true, 0, 136704)
            PlayEntityAnim(m.bola, 'intro_ball', DICT, 1000.0, false, true, true, 0, 136704)
            local dura = math.floor(GetAnimDuration(DICT, 'intro_ball') * 1000)
            local t0 = GetGameTimer()
            -- Se apunta cómo van la bola y el bombo en el último tramo, para
            -- seguir desde ahí a la misma velocidad.
            local muestras = {}
            while GetGameTimer() - t0 < dura - 40 do
                if m.tirada ~= tirada then return end
                local p = GetEntityCoords(m.bola) - c
                muestras[#muestras + 1] = { t = GetGameTimer(), a = math.deg(math.atan(p.y, p.x)),
                                            g = GetEntityBoneRotation(m.mesa, m.hueso).z }
                if #muestras > 12 then table.remove(muestras, 1) end
                Wait(0)
            end
            local primera, ultima = muestras[1], muestras[#muestras]
            local dt = (ultima and primera and ultima.t > primera.t) and (ultima.t - primera.t) / 1000.0 or 0.0
            local vBola, vBombo = 0.0, -VUELTA * REPOSO
            if dt > 0 then
                -- Sumando las diferencias de fotograma a fotograma, que un
                -- ángulo que da la vuelta no se cuente como -350°.
                local sa, sg = 0.0, 0.0
                for i = 2, #muestras do
                    sa = sa + Angulo(muestras[i].a - muestras[i - 1].a)
                    sg = sg + Angulo(muestras[i].g - muestras[i - 1].g)
                end
                vBola, vBombo = sa / dt, sg / dt
            end
            local giro1 = ultima and ultima.g or GetEntityBoneRotation(m.mesa, m.hueso).z
            BomboEnBucle(m, math.max(REPOSO, math.min(3.0, math.abs(vBombo) / VUELTA)), giro1)

            --[[ Desde donde iba, frenando con deceleración constante, hasta la
                 casilla. Se cuenta todo RESPECTO AL BOMBO, que sigue girando:
                 así la bola acaba quieta dentro de su casilla y no a su lado. ]]
            local rel0 = (ultima and ultima.a or 0.0) - giro1
            local vRel = vBola - vBombo
            if math.abs(vRel) < 90.0 then vRel = (vRel >= 0 and 1 or -1) * 90.0 end

            -- A partir de aquí, enganchada al bombo y redonda.
            StopEntityAnim(m.bola, 'intro_ball', DICT, 1.0)
            Redonda(m)
            PonerBola(m, rel0, PISTA.r, PISTA.z)

            local destino = DEL_CERO - (INDICE[numero] or 0) * CASILLA
            --[[ Frenando parejo desde vRel, en T segundos recorre vRel·T/2. Se
                 elige la vuelta más corta que deje al menos 2,4 s de frenada:
                 así la bola SOLO frena, nunca acelera. ]]
            local sentido = vRel >= 0 and 1 or -1
            local delta = (destino - rel0) * sentido % 360.0
            local minimo = math.abs(vRel) * 1.2
            while delta < minimo do delta = delta + 360.0 end
            local T = math.min(6.0, 2.0 * delta / math.abs(vRel))
            delta = delta * sentido

            local t0b = GetGameTimer()
            while true do
                if m.tirada ~= tirada then return end
                local s = math.min(1.0, (GetGameTimer() - t0b) / (T * 1000.0))
                local rel = rel0 + delta * (2.0 * s - s * s)
                -- Baja de la pista a la casilla en el último tramo, con un rebote.
                local caer = math.max(0.0, math.min(1.0, (s - 0.55) / 0.35))
                local rebote = (caer > 0.0 and caer < 1.0) and math.sin(caer * math.pi * 3.0) * 0.012 * (1.0 - caer) or 0.0
                local r = PISTA.r + (HUECO.r - PISTA.r) * caer + rebote
                local z = PISTA.z + (HUECO.z - PISTA.z) * caer + math.abs(rebote) * 0.5
                PonerBola(m, rel, r, z)
                if s >= 1.0 then break end
                Wait(0)
            end
        else
            BomboEnBucle(m)
            Redonda(m)
        end

        -- Ya en su casilla, enganchada: da vueltas con el bombo sola.
        if m.tirada == tirada then
            PonerBola(m, DEL_CERO - (INDICE[numero] or 0) * CASILLA, HUECO.r, HUECO.z)
        end
    end)
end

--[[ ══ EL PAÑO ══════════════════════════════════════════════════════════════

     Dónde está cada casilla, en metros respecto al punto de la mesa (dx a su
     derecha, dy hacia el crupier). Medido en el juego el 24/09 con fichas en
     cinco puntos conocidos y una foto cenital (580 px por metro):

       · La rejilla de números: 12 columnas cada 7,9 cm desde dx -0,043 (la
         del 1, 2, 3) y 3 filas cada 15,5 cm: la del 1 en dy -0,172, la del 3
         en dy 0,138. Bordes: dx -0,083 a 0,865 y dy -0,25 a 0,216.
       · El 0 y el 00, a la izquierda: dx -0,20 a -0,083; el 0 abajo.
       · Las columnas («2 to 1»), a la derecha: dx 0,865 a 0,955.
       · Las docenas debajo (dy -0,25 a -0,336) y las sencillas debajo de
         ellas (dy -0,336 a -0,41), cada una del ancho de dos columnas.
   ══════════════════════════════════════════════════════════════════════════ ]]

local X0, W = -0.0433, 0.079         -- centro de la primera columna, y el paso
local Y1, H = -0.172, 0.155          -- centro de la fila de abajo (1, 4, 7…), y el paso
local XI, XD = X0 - W / 2, X0 + 11.5 * W
local YB, YA = Y1 - H / 2, Y1 + 2.5 * H
local BORDE = 0.22                   -- lo que cuenta como «en la raya» (fracción de casilla)
local ALTURA = 0.95                  -- el paño, sobre el suelo

local SENCILLAS = { 'falta', 'par', 'rojo', 'negro', 'impar', 'pasa' }
local NOMBRE_SENCILLA = { falta = '1 a 18', par = 'Par', rojo = 'Rojo', negro = 'Negro', impar = 'Impar', pasa = '19 a 36' }

local function Xc(col) return X0 + col * W end
local function Yf(fila) return Y1 + (fila - 1) * H end
local function ColFila(n) return (n - 1) // 3, (n - 1) % 3 + 1 end

--- El centro de una casilla (donde se ponen sus fichas).
local function Centro(id)
    local tipo, a, b = id:match('^(%a+):?(%d*):?(%d*)$')
    a, b = tonumber(a), tonumber(b)
    if tipo == 'p' then
        if a == 0 then return -0.143, -0.135 end
        if a == 37 then return -0.143, 0.10 end
        local c, f = ColFila(a)
        return Xc(c), Yf(f)
    elseif tipo == 'c' then
        if a == 0 then local _, f = ColFila(b) return XI, Yf(f) end
        local c, f = ColFila(a)
        if b == a + 1 then return Xc(c), (Yf(f) + Yf(f + 1)) / 2 end
        return (Xc(c) + Xc(c + 1)) / 2, Yf(f)
    elseif tipo == 't' then
        local c = ColFila(a)
        return Xc(c), YB
    elseif tipo == 'l' then
        local c = ColFila(a)
        return XI + (c + 1) * W, YB
    elseif tipo == 'q' then
        local c, f = ColFila(a)
        return (Xc(c) + Xc(c + 1)) / 2, (Yf(f) + Yf(f + 1)) / 2
    elseif tipo == 'd' then
        return XI + (4 * a - 2) * W, -0.294
    elseif tipo == 'col' then
        return 0.911, Yf(a)
    end
    for i, nombre in ipairs(SENCILLAS) do
        if id == nombre then return XI + (2 * i - 1) * W, -0.372 end
    end
    return nil
end

--- El nombre que se enseña y el tipo (para el pago), de una casilla.
local function Rotulo(id)
    local tipo, a, b = id:match('^(%a+):?(%d*):?(%d*)$')
    a, b = tonumber(a), tonumber(b)
    if tipo == 'p' then return 'Pleno ' .. (a == 37 and '00' or a), 'pleno' end
    if tipo == 'c' then return ('Caballo %d-%d'):format(a, b), 'caballo' end
    if tipo == 't' then return ('Transversal %d-%d'):format(a, a + 2), 'transversal' end
    if tipo == 'q' then return ('Cuadro %d-%d-%d-%d'):format(a, a + 1, a + 3, a + 4), 'cuadro' end
    if tipo == 'l' then return ('Línea %d a %d'):format(a, a + 5), 'linea' end
    if tipo == 'd' then return ({ '1ª docena', '2ª docena', '3ª docena' })[a], 'docena' end
    if tipo == 'col' then return 'Columna ' .. a, 'columna' end
    local t = (id == 'rojo' or id == 'negro') and 'color' or ((id == 'par' or id == 'impar') and 'paridad' or 'mitad')
    return NOMBRE_SENCILLA[id] or id, t
end

--[[ De un punto del paño a la casilla que hay ahí. Dentro de la rejilla, cerca
     de una raya es la apuesta de la raya (caballo, cuadro, transversal,
     línea), igual que al poner una ficha a caballo entre dos números. ]]
local function CasillaEn(dx, dy)
    if dx >= XI and dx <= XD and dy >= YB and dy <= YA then
        local u, v = (dx - XI) / W, (dy - YB) / H
        local col, fila = math.min(11, math.floor(u)), math.min(2, math.floor(v)) + 1
        local fu, fv = u - math.floor(u), v - math.floor(v)
        local n = col * 3 + fila
        local lado = (fu > 1 - BORDE and col < 11) and 1 or ((fu < BORDE) and -1 or 0)
        local alto = (fv > 1 - BORDE and fila < 3) and 1 or ((fv < BORDE) and -1 or 0)

        if alto == -1 and fila == 1 then
            -- La raya de abajo: transversal, o línea si además está entre dos.
            if lado == 1 then return ('l:%d'):format(col * 3 + 1) end
            if lado == -1 and col > 0 then return ('l:%d'):format((col - 1) * 3 + 1) end
            return ('t:%d'):format(col * 3 + 1)
        end
        if lado ~= 0 and alto ~= 0 then
            local c = lado == 1 and col or col - 1
            local f = alto == 1 and fila or fila - 1
            if c >= 0 then return ('q:%d'):format(c * 3 + f) end
        end
        if lado == -1 and col == 0 then return ('c:0:%d'):format(n) end
        if lado == 1 then return ('c:%d:%d'):format(n, n + 3) end
        if lado == -1 then return ('c:%d:%d'):format(n - 3, n) end
        if alto == 1 then return ('c:%d:%d'):format(n, n + 1) end
        if alto == -1 then return ('c:%d:%d'):format(n - 1, n) end
        return 'p:' .. n
    end
    if dx >= -0.20 and dx < XI and dy >= YB and dy <= YA then
        return dy < -0.017 and 'p:0' or 'p:37'
    end
    if dx > XD and dx <= 0.955 and dy >= YB and dy <= YA then
        return 'col:' .. (math.min(2, math.floor((dy - YB) / H)) + 1)
    end
    if dx >= XI and dx <= XD and dy < YB and dy >= -0.336 then
        return 'd:' .. (math.min(2, math.floor((dx - XI) / (4 * W))) + 1)
    end
    if dx >= XI and dx <= XD and dy < -0.336 and dy >= -0.41 then
        return SENCILLAS[math.min(6, math.floor((dx - XI) / (2 * W)) + 1)]
    end
    return nil
end

local function AlMundo(m, dx, dy, dz)
    local rad = math.rad(m.punto.h)
    local cos, sin = math.cos(rad), math.sin(rad)
    return m.punto.x + dx * cos - dy * sin, m.punto.y + dx * sin + dy * cos, m.punto.z + (dz or ALTURA)
end

local function AlPano(m, x, y)
    local rad = math.rad(m.punto.h)
    local cos, sin = math.cos(rad), math.sin(rad)
    local wx, wy = x - m.punto.x, y - m.punto.y
    return wx * cos + wy * sin, -wx * sin + wy * cos
end

-- ══ LAS FICHAS EN EL PAÑO ═════════════════════════════════════════════════

--[[ Cada apuesta es una pila de fichas de GTA, de las gordas a las pequeñas, y
     como mucho diez de alto. Cada plaza corre su pila un poco para que dos
     jugadores en la misma casilla no queden una ficha dentro de otra. ]]
local VALORES = {
    { 10000, 'vw_prop_chip_10kdollar_x1' }, { 5000, 'vw_prop_chip_5kdollar_x1' },
    { 1000, 'vw_prop_chip_1kdollar_x1' }, { 500, 'vw_prop_chip_500dollar_x1' },
    { 100, 'vw_prop_chip_100dollar_x1' }, { 50, 'vw_prop_chip_50dollar_x1' },
    { 10, 'vw_prop_chip_10dollar_x1' },
}
local GROSOR = 0.0055
local CORRER = { [1] = { -0.011, -0.009 }, [2] = { 0.011, -0.009 }, [3] = { -0.011, 0.009 }, [4] = { 0.011, 0.009 } }

local function Desglose(cuanto)
    local lista = {}
    for _, v in ipairs(VALORES) do
        while cuanto >= v[1] and #lista < 10 do
            lista[#lista + 1] = v[2]
            cuanto = cuanto - v[1]
        end
    end
    if #lista == 0 then lista[1] = VALORES[#VALORES][2] end
    return lista
end

local function BorrarPila(pila)
    for _, e in ipairs(pila.ents) do if DoesEntityExist(e) then DeleteEntity(e) end end
end

local function PonerFichas(m, fichas)
    m.fichas = m.fichas or {}
    local siguen = {}
    for _, f in ipairs(fichas or {}) do
        local clave = ('%s|%s'):format(f.p or 0, f.c)
        siguen[clave] = true
        local pila = m.fichas[clave]
        if not pila or pila.n ~= f.n then
            if pila then BorrarPila(pila) end
            local dx, dy = Centro(f.c)
            if dx then
                local corre = CORRER[tonumber(f.p) or 0] or { 0, 0 }
                local x, y, z = AlMundo(m, dx + corre[1], dy + corre[2])
                pila = { n = f.n, ents = {} }
                for i, modelo in ipairs(Desglose(tonumber(f.n) or 0)) do
                    local hash = joaat(modelo)
                    if not HasModelLoaded(hash) then pcall(lib.requestModel, hash, 3000) end
                    local e = CreateObjectNoOffset(hash, x, y, z + (i - 1) * GROSOR, false, false, false)
                    SetEntityHeading(e, m.punto.h + math.random(0, 359))
                    SetEntityCollision(e, false, false)
                    FreezeEntityPosition(e, true)
                    pila.ents[#pila.ents + 1] = e
                end
                m.fichas[clave] = pila
            end
        end
    end
    for clave, pila in pairs(m.fichas) do
        if not siguen[clave] then BorrarPila(pila) m.fichas[clave] = nil end
    end
end

-- ══ APOSTAR CON EL CURSOR ═════════════════════════════════════════════════

local apostando = nil       -- { m, cam, casilla }

--- Del cursor de la pantalla a un rayo del mundo, con la cámara que se ve.
local function RayoCursor(cam)
    local cx, cy = GetNuiCursorPosition()
    local ancho, alto = GetActiveScreenResolution()
    if not cx or ancho == 0 then return nil end
    local sx, sy = (cx / ancho) * 2.0 - 1.0, (cy / alto) * 2.0 - 1.0
    local pos = GetCamCoord(cam)
    local rot = GetCamRot(cam, 2)
    local p, yaw = math.rad(rot.x), math.rad(rot.z)
    local fwd = vector3(-math.sin(yaw) * math.cos(p), math.cos(yaw) * math.cos(p), math.sin(p))
    local der = vector3(math.cos(yaw), math.sin(yaw), 0.0)
    local arriba = vector3(der.y * fwd.z - der.z * fwd.y, der.z * fwd.x - der.x * fwd.z, der.x * fwd.y - der.y * fwd.x)
    local t = math.tan(math.rad(GetCamFov(cam)) / 2.0)
    local dir = fwd + der * (sx * t * GetAspectRatio(false)) + arriba * (-sy * t)
    return pos, dir
end

local function CasillaBajoCursor(a)
    local pos, dir = RayoCursor(a.pano)
    if not pos or math.abs(dir.z) < 0.0001 then return nil end
    local z = a.m.punto.z + ALTURA
    local k = (z - pos.z) / dir.z
    if k <= 0 then return nil end
    local q = pos + dir * k
    local dx, dy = AlPano(a.m, q.x, q.y)
    return CasillaEn(dx, dy)
end

local function CamaraApuestas(m)
    -- Encima del paño, mirando hacia abajo, con la mesa derecha en pantalla.
    local x, y = AlMundo(m, 0.38, -0.10)
    return CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', x, y, m.punto.z + ALTURA + 1.0,
        -89.5, 0.0, m.punto.h, 55.0, false, 0)
end

local function CamaraBombo(m)
    -- Desde el lado de los jugadores, en alto, mirando al centro del bombo.
    local rad = math.rad(m.giro.z)
    local c = m.centro
    local cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', c.x + math.sin(rad) * 0.55,
        c.y - math.cos(rad) * 0.55, c.z + 0.85, 0.0, 0.0, 0.0, 50.0, false, 0)
    PointCamAtCoord(cam, c.x, c.y, c.z - 0.05)
    return cam
end

--- Pasa a la cámara que toca (paño o bombo), con un fundido corto.
local function Mirar(a, bombo)
    local destino = bombo and a.bombo or a.pano
    if a.activa == destino then return end
    if a.activa then
        SetCamActiveWithInterp(destino, a.activa, 650, 1, 1)
    else
        SetCamActive(destino, true)
        RenderScriptCams(true, true, 500, true, false)
    end
    a.activa = destino
    C.Enviar('ruletaVista', { bombo = bombo })
end

local function DejarDeApostar()
    if not apostando then return end
    for _, cam in ipairs({ apostando.pano, apostando.bombo }) do
        if cam then
            SetCamActive(cam, false)
            DestroyCam(cam, false)
        end
    end
    apostando = nil
    C.Enviar('ruletaCursor', nil)
end

--[[ Sentado en una ruleta hay dos cámaras: el PAÑO, desde arriba, para
     apostar con el cursor, y el BOMBO, para ver girar la bola. Al lanzar se
     pasa sola al bombo y en la ronda siguiente vuelve sola al paño; entre
     medias, la C (o el botón de la pantalla) cambia de una a otra cuando se
     quiera, como en GTA Online. ]]
CreateThread(function()
    while true do
        local espera = 500
        local ses = C.sesion
        local m = ses and mesas[ses.punto]
        if m and C.pantalla == 'juego' then
            espera = 0
            if not apostando or apostando.m ~= m then
                DejarDeApostar()
                apostando = { m = m, pano = CamaraApuestas(m), bombo = CamaraBombo(m),
                              verBombo = m.fase == 'girando' }
            end
            Mirar(apostando, apostando.verBombo)

            local id = (m.fase == 'apuestas' and not apostando.verBombo) and CasillaBajoCursor(apostando) or nil
            if id ~= apostando.casilla then
                apostando.casilla = id
                if id then
                    local texto, tipo = Rotulo(id)
                    C.Enviar('ruletaCursor', { id = id, texto = texto, tipo = tipo })
                else
                    C.Enviar('ruletaCursor', nil)
                end
            end
            if id then
                local dx, dy = Centro(id)
                local x, y, z = AlMundo(m, dx, dy, ALTURA + 0.002)
                DrawMarker(25, x, y, z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.055, 0.055, 0.055,
                    255, 255, 255, 150, false, false, 2, false, nil, nil, false)
            end
        elseif apostando then
            DejarDeApostar()
        end
        Wait(espera)
    end
end)

--- Al cambiar de fase: al lanzar, al bombo; al abrir apuestas, al paño.
local function AlCambiarFase(m, fase)
    if not apostando or apostando.m ~= m then return end
    if fase == 'girando' then apostando.verBombo = true end
    if fase == 'apuestas' then apostando.verBombo = false end
end

RegisterNUICallback('ruletaCamara', function(_, cb)
    if apostando then apostando.verBombo = not apostando.verBombo end
    cb({ bombo = apostando and apostando.verBombo or false })
end)

RegisterNUICallback('ruletaCasilla', function(_, cb)
    cb({ casilla = apostando and apostando.casilla or nil })
end)

--- Para las pruebas: la casilla de un punto del paño y el centro de una casilla.
RuletaMundo.CasillaEn = CasillaEn
RuletaMundo.Centro = Centro

-- ── Aplicar la vista ──────────────────────────────────────────────────────

local function Aplicar(m, vista, animar)
    if not vista then
        -- La mesa se ha cerrado: se retiran la bola y las fichas.
        QuitarBola(m)
        PonerFichas(m, {})
        m.ronda, m.fase = nil, nil
        return
    end
    if m.fase ~= vista.fase then AlCambiarFase(m, vista.fase) end
    m.fase = vista.fase
    PonerFichas(m, vista.fichas)
    -- Mientras se apuesta, la bola se queda en el número que salió, como en
    -- la sala: la siguiente tirada ya la quita.
    if vista.numero == nil then return end
    if m.ronda == vista.ronda then return end
    m.ronda = vista.ronda
    Tirar(m, tonumber(vista.numero), not (animar and vista.fase == 'girando'))
end

-- ── Poner y quitar ────────────────────────────────────────────────────────

function RuletaMundo.Poner(punto, tipo, ent)
    RuletaMundo.Quitar(punto.id)
    if not tipo or not tipo.ruletaMundo or not ent or not DoesEntityExist(ent) then return end
    pcall(lib.requestAnimDict, DICT, 5000)
    local hueso = GetEntityBoneIndexByName(ent, 'Roulette_Wheel')
    if hueso == -1 then return end
    local m = {
        punto = punto, tipo = tipo, conf = tipo.ruletaMundo, mesa = ent, hueso = hueso,
        centro = GetWorldPositionOfEntityBone(ent, hueso),
        origen = GetEntityCoords(ent), giro = GetEntityRotation(ent, 2),
    }
    mesas[punto.id] = m
    PonerCrupier(m)
    -- El bombo ya gira despacio al llegar, como en la sala.
    BomboEnBucle(m)

    CreateThread(function()
        local vista = lib.callback.await('origen_casino:vista', false, punto.id)
        if mesas[punto.id] == m and vista then Aplicar(m, vista, false) end
    end)
end

function RuletaMundo.Quitar(id)
    local m = mesas[id]
    if not m then return end
    mesas[id] = nil
    QuitarBola(m)
    PonerFichas(m, {})
    if apostando and apostando.m == m then DejarDeApostar() end
    if m.crupier and DoesEntityExist(m.crupier) then DeletePed(m.crupier) end
end

RegisterNetEvent('origen_casino:vista', function(id, vista)
    local m = mesas[tonumber(id)]
    if not m then return end
    Aplicar(m, vista or nil, true)
end)

AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    for id in pairs(mesas) do RuletaMundo.Quitar(id) end
end)
