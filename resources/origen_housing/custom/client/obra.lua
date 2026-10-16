-- Obra (ver config/obra.lua y custom/server/obra.lua). Dos cosas:
--  · Las casas de modalidad «libre»: el interior no es un módulo hecho, lo
--    excava y lo reparte el jugador.
--  · La cinta: el modo de decorar de todas las casas de módulo, sin menú,
--    con el que se amuebla y (en las libres) se construye.
-- Sobre las libres: Entrar, salir, la dimensión, las llaves y los muebles son los de
-- cualquier vivienda de módulo; lo único distinto es que el «módulo» es un
-- ancla sin nada y la casa se monta aquí alrededor, con objetos locales.
local C = Config.Obra
local actual = nil      -- la obra en la que está el jugador: { id, o, X, Y, rumbo, celdas, piezas, pinturas, objetos, claves, modelo }
local construyendo = false

Obra = {}               -- lo que llama el resto del housing (client/shell.lua)

-- ── Rejilla ─────────────────────────────────────────────────────────────
-- Ejes de la obra: X a lo ancho, Y hacia el fondo. La celda (0,0) es la de
-- la entrada: en ella aparece quien entra y en ella está el punto de salir.
local function AMundo(o, x, y, k)
    return o.o + o.X * x + o.Y * y + vector3(0.0, 0.0, k * C.planta)
end

local function ALocal(o, p)
    local d = p - o.o
    return d.x * o.X.x + d.y * o.X.y, d.x * o.Y.x + d.y * o.Y.y, d.z
end

local function Celda(x, y)
    return math.floor(x / C.celda + 0.5), math.floor((y - C.celda / 2) / C.celda + 0.5)
end

local function K(i, j, k) return i .. ':' .. j .. ':' .. k end
local function Abierta(o, i, j, k) return o.celdas[K(i, j, k)] ~= nil end

local function Partes(clave)
    local t, i, j, k = clave:match('^(%a):(-?%d+):(-?%d+):(-?%d+)$')
    return t, tonumber(i), tonumber(j), tonumber(k)
end

-- Material con el que está pintada una cara
local function Material(o, clave)
    local t = clave:sub(1, 1)
    return o.pinturas[clave] or (t == 't' and C.porDefecto.techo) or ((t == 's' or t == 'l') and C.porDefecto.suelo) or C.porDefecto.pared
end

-- Modelo, posición y rumbo de una pieza.
--   s, t: suelo y techo de una celda que da a macizo    l: suelo entre plantas
--   x, y: pared en el borde de la celda                 e: escalera
local CORRIDA = 0.003
-- El estilo de un paso secreto (config/secretos.lua) y si va vuelto; nil si esa pieza no lo es.
local function PasoSecreto(clave, valor)
    if not Config.Secretos then return nil end
    return Config.Secretos.Estilo(clave, valor)
end
local function Colocacion(o, clave, valor, material)
    local t, i, j, k = Partes(clave)
    local m, cx, cy = C.celda / 2, i * C.celda, j * C.celda + C.celda / 2
    material = material or Material(o, clave)
    if t == 's' or t == 'l' then
        -- (una trampilla, 'o:<estilo>' de config/secretos.lua, lleva su modelo; el «suelo falso» es la losa de siempre)
        return (t == 'l' and Config.Secretos and Config.Secretos.Modelo(clave, valor)) or C.Modelo('losa', material), AMundo(o, cx, cy, k), o.rumbo
    elseif t == 't' then
        return C.Modelo('losa', material), AMundo(o, cx, cy, k + 1), o.rumbo
    elseif t == 'x' then
        -- Las paredes van corridas 3 mm a lo largo (todas hacia el mismo lado, así
        -- siguen casando entre ellas): su canto ya no cae en el mismo plano que
        -- el canto de las losas, que donde hay un hueco al lado se ven los dos y
        -- parpadeaban.
        -- el hueco de garaje ocupa este borde y el siguiente: va centrado entre los dos
        if valor == 'g' or valor == 'd' then return C.Modelo(valor == 'd' and 'marco2' or 'garaje', material), AMundo(o, cx + m, cy + m + CORRIDA, k), o.rumbo + 90.0 end
        -- la barandilla ('b:<estilo>') va donde el tabique, con su mismo giro
        local baranda = C.Baranda(valor)
        if baranda then return C.ModeloBaranda(baranda.id), AMundo(o, cx + m, cy + CORRIDA, k), o.rumbo + 90.0 end
        -- un paso secreto ('o:<estilo>', config/secretos.lua): su modelo, o el tabique de su material; los que tienen frente pueden ir vueltos
        local paso, vuelto = PasoSecreto(clave, valor)
        if paso then return Config.Secretos.Modelo(clave, valor, material) or C.Modelo('tabique', material), AMundo(o, cx + m, cy + CORRIDA, k), o.rumbo + 90.0 + (vuelto and 180.0 or 0.0) end
        return C.Modelo(valor == 'u' and 'marco' or 'tabique', material), AMundo(o, cx + m, cy + CORRIDA, k), o.rumbo + 90.0
    elseif t == 'y' then
        if valor == 'g' or valor == 'd' then return C.Modelo(valor == 'd' and 'marco2' or 'garaje', material), AMundo(o, cx + m + CORRIDA, cy + m, k), o.rumbo end
        local baranda = C.Baranda(valor)
        if baranda then return C.ModeloBaranda(baranda.id), AMundo(o, cx + CORRIDA, cy + m, k), o.rumbo end
        local paso, vuelto = PasoSecreto(clave, valor)
        if paso then return Config.Secretos.Modelo(clave, valor, material) or C.Modelo('tabique', material), AMundo(o, cx + CORRIDA, cy + m, k), o.rumbo + (vuelto and 180.0 or 0.0) end
        return C.Modelo(valor == 'u' and 'marco' or 'tabique', material), AMundo(o, cx + CORRIDA, cy + m, k), o.rumbo
    end
    if t == 'r' or t == 'v' then
        -- esquina redondeada (el rincón de una celda) o canto (un vértice): config/obra_esquinas.lua.
        -- Su origen es el vértice de la rejilla, sin correr: no tiene ninguna cara en el plano de una pared.
        local modelo, x, y, giro = C.Esquinas.Colocar(o, clave, valor)
        return modelo, AMundo(o, x or cx, y or cy, k), o.rumbo + (giro or 0.0)
    end
    if t == 'a' then
        -- hueco de ascensor: aquí solo sirve para enseñar la cabina al colocarlo
        -- valor = plantas + 10 * huella + 100 * estilo (0 abierto; 1…4 cabina cerrada, frente hacia el giro estilo-1)
        local f, e = math.floor(valor / 10) % 10, math.floor(valor / 100)
        local modelo, pos, rumbo = C.cabina, AMundo(o, cx, cy, k), o.rumbo
        if f == 1 then modelo, pos = C.cabina2x1, AMundo(o, cx + m, cy, k)
        elseif f == 2 then modelo, pos, rumbo = C.cabina2x1, AMundo(o, cx, cy + m, k), o.rumbo + 90.0
        elseif f == 3 then modelo, pos = C.cabina2x2, AMundo(o, cx + m, cy + m, k) end
        local cerrada = e > 0 and Config.Ascensores.cabina.cerrada.huellas[f]
        if cerrada then
            -- el frente del modelo es su -Y: sin girar mira al giro 2. Si el
            -- modelo no está, la abierta de siempre con ese mismo giro.
            local suyo = joaat(cerrada.modelo)
            if IsModelInCdimage(suyo) then modelo = suyo end
            rumbo = o.rumbo + (2 - (e - 1)) * 90.0
        end
        return modelo, pos, rumbo
    elseif t == 'c' then
        local g = valor % 10
        return C.plataforma, AMundo(o, cx + (g == 1 and 2 or 1) * m, cy + (g == 1 and 1 or 2) * m, k), o.rumbo + (g == 1 and 90.0 or 0.0)
    end
    -- escalera: valor = giro + 4 * forma (Config.Obra.Escalera); un valor raro, como recta sin girar
    valor = tonumber(valor) or 0
    local giro, forma = valor % 4, math.floor(valor / 4)
    -- en L: el origen del modelo es el centro de la celda de arranque
    if forma == 1 or forma == 2 then
        return forma == 1 and C.escaleraLD or C.escaleraLI, AMundo(o, cx, cy, k), o.rumbo - giro * 90.0
    end
    local d = C.giros[giro]
    -- de mano y de caracol compacta: una celda, con el origen en su centro
    if forma == 3 or forma == 4 then
        return forma == 3 and C.escala or C.caracol, AMundo(o, cx, cy, k), o.rumbo - giro * 90.0
    elseif forma == 5 then
        -- de caracol amplia: el origen es el vértice común de sus cuatro celdas (delante y a la derecha de la del rellano)
        return C.caracol2, AMundo(o, cx + (d[1] + d[2]) * m, cy + (d[2] - d[1]) * m, k), o.rumbo - giro * 90.0
    end
    -- el modelo sube hacia su +Y: giro 0 mira hacia el fondo, y cada giro es un cuarto de vuelta
    return C.escalera, AMundo(o, cx + d[1] * m, cy + d[2] * m, k), o.rumbo - giro * 90.0
end

local function Cargar(modelo)
    if HasModelLoaded(modelo) then return true end
    RequestModel(modelo)
    local t = GetGameTimer()
    while not HasModelLoaded(modelo) and GetGameTimer() - t < 6000 do Wait(10) end
    return HasModelLoaded(modelo)
end

-- ── Montaje ─────────────────────────────────────────────────────────────
-- Todo lo que tiene que haber: lo puesto a mano y, en cada celda abierta, la
-- pared, el suelo o el techo de cada cara que da a una celda maciza.
local function Deseadas(o)
    local d = {}
    for celda in pairs(o.celdas) do
        local i, j, k = celda:match('^(-?%d+):(-?%d+):(-?%d+)$')
        i, j, k = tonumber(i), tonumber(j), tonumber(k)
        if not Abierta(o, i, j, k - 1) then d[('s:%d:%d:%d'):format(i, j, k)] = 1 end
        if not Abierta(o, i, j, k + 1) then d[('t:%d:%d:%d'):format(i, j, k)] = 1 end
        if not Abierta(o, i + 1, j, k) then d[('x:%d:%d:%d'):format(i, j, k)] = 'p' end
        if not Abierta(o, i - 1, j, k) then d[('x:%d:%d:%d'):format(i - 1, j, k)] = 'p' end
        if not Abierta(o, i, j + 1, k) then d[('y:%d:%d:%d'):format(i, j, k)] = 'p' end
        if not Abierta(o, i, j - 1, k) then d[('y:%d:%d:%d'):format(i, j - 1, k)] = 'p' end
    end
    for clave, valor in pairs(o.piezas) do
        -- 'G' es la otra mitad de un hueco de garaje: la pieza va en su pareja.
        -- Los huecos de ascensor (a) y de montacoches (c) no llevan pieza: su
        -- cabina la pone y la mueve custom/client/ascensores.lua.
        local t = clave:sub(1, 1)
        if valor ~= 'G' and t ~= 'a' and t ~= 'c' then d[clave] = valor end
    end
    return d
end

-- ── Paños ───────────────────────────────────────────────────────────────
-- Lo que se monta no es una pieza por cara, sino «unidades»: una cara suelta
-- o un paño de varias del mismo material (losas de 2x2 y 4x4 celdas, paredes
-- de 2 y 4). Los paños van siempre en casillas fijas de la rejilla (múltiplos
-- de su tamaño): al cambiar una celda solo se rehace el paño que la contiene.
-- No se juntan el cristal (lleva su marco por celda), lo que está apartado
-- (Obra.Ocultar) ni los suelos de un hueco de ascensor, que se apartan solos.
local HuecoEn
local EXISTE, FALTA = {}, {}
-- (lo que hay ya no se pregunta más; lo que falta se vuelve a mirar a los cinco segundos: los modelos van llegando)
local function Existe(modelo)
    if EXISTE[modelo] then return true end
    local ahora = GetGameTimer()
    if FALTA[modelo] and ahora - FALTA[modelo] < 5000 then return false end
    if IsModelInCdimage(modelo) then
        EXISTE[modelo], FALTA[modelo] = true, nil
        return true
    end
    FALTA[modelo] = ahora
    return false
end

local SUELTO = {}       -- materiales que no se juntan
for _, mat in ipairs(C.materiales) do
    if mat.interior or mat.modelo then SUELTO[mat.id] = true end
end

local function Unidades(o, quiero)
    local u, losas, paredes, restos = {}, {}, {}, {}
    local m = C.celda / 2
    -- Las celdas por las que pasa un hueco de ascensor o de montacoches, apuntadas de una vez:
    -- preguntarlo por cada suelo entre plantas (HuecoEn) era recorrer todas las piezas de la
    -- casa dos veces por cada uno, en cada montaje.
    local enHueco = {}
    for clave, valor in pairs(o.piezas) do
        local t = clave:sub(1, 1)
        valor = (t == 'a' or t == 'c') and tonumber(valor) or nil
        if valor then
            local _, hi, hj, hk = Partes(clave)
            local n, ancho, largo
            if t == 'a' then
                local f = math.floor(valor / 10) % 10
                n, ancho, largo = valor % 10, (f == 1 or f == 3) and 1 or 0, (f == 2 or f == 3) and 1 or 0
            else
                local g = valor % 10
                n, ancho, largo = math.floor(valor / 10), g == 1 and 2 or 1, g == 1 and 1 or 2
            end
            if hi then
                for q = 0, math.min(n, 12) - 1 do
                    for a = 0, ancho do
                        for b = 0, largo do enHueco[K(hi + a, hj + b, hk + q)] = true end
                    end
                end
            end
        end
    end
    local function suelta(clave)
        local modelo, pos, rumbo = Colocacion(o, clave, quiero[clave])
        u[clave] = { modelo = modelo, pos = pos, rumbo = rumbo, clave = clave }
    end
    -- una cara que no ha entrado en ningún paño: si es de las que salen solas al
    -- excavar y está sin pintar, se guarda para el cubo de su celda
    local function resto(clave)
        local t, i, j, k = Partes(clave)
        local cara
        if o.pinturas[clave] == nil and o.piezas[clave] == nil and not o.ocultas[clave] and C.juntar then
            if t == 's' then cara = 1
            elseif t == 't' then cara = 2
            elseif t == 'x' then
                if Abierta(o, i, j, k) then cara = 3 else i, cara = i + 1, 4 end
            elseif t == 'y' then
                if Abierta(o, i, j, k) then cara = 5 else j, cara = j + 1, 6 end
            end
        end
        if not cara then return suelta(clave) end
        local celda = K(i, j, k)
        restos[celda] = restos[celda] or { i = i, j = j, k = k, caras = {}, n = 0 }
        restos[celda].caras[cara], restos[celda].n = clave, restos[celda].n + 1
    end
    o.enPlano = {}
    for clave, valor in pairs(quiero) do
        local t, i, j, k = Partes(clave)
        local mat = Material(o, clave)
        local junta = C.juntar and not SUELTO[mat] and not o.ocultas[clave]
        if t == 's' or t == 't' or t == 'l' then
            local L = t == 't' and k + 1 or k       -- la planta a cuya altura queda la cara de arriba de la losa
            o.enPlano[L .. ':' .. i .. ':' .. j] = clave
            -- (una trampilla va siempre suelta: la mueve custom/client/secretos.lua)
            if junta and not PasoSecreto(clave, valor) and not (t == 'l' and (enHueco[K(i, j, k)] or enHueco[K(i, j, k - 1)])) then
                local g = L .. '|' .. mat
                losas[g] = losas[g] or { L = L, mat = mat, c = {} }
                losas[g].c[i .. ':' .. j] = clave
            else
                suelta(clave)
            end
        elseif (t == 'x' or t == 'y') and valor == 'p' and junta then
            local fijo, corre = t == 'x' and i or j, t == 'x' and j or i
            local g = t .. '|' .. fijo .. '|' .. k .. '|' .. mat
            paredes[g] = paredes[g] or { t = t, fijo = fijo, k = k, mat = mat, c = {} }
            paredes[g].c[corre] = clave
        else
            suelta(clave)
        end
    end

    -- Las losas: primero los paños cuadrados y, con lo que sobra (pasillos,
    -- bordes), tiras de una celda de ancho. { celdas en X, celdas en Y }
    local FORMAS = { { 4, 4 }, { 2, 2 }, { 1, 4 }, { 4, 1 }, { 1, 2 }, { 2, 1 } }
    for _, g in pairs(losas) do
        local hecho = {}
        for _, f in ipairs(FORMAS) do
            local ni, nj = f[1], f[2]
            local modelo = joaat(ni == nj and ('origen_casa_losa%d_%s'):format(ni, g.mat) or ('origen_casa_losa%dx%d_%s'):format(ni, nj, g.mat))
            if Existe(modelo) then
                local vistos = {}
                for ij in pairs(g.c) do
                    local i, j = ij:match('^(-?%d+):(-?%d+)$')
                    local i0, j0 = math.floor(tonumber(i) / ni) * ni, math.floor(tonumber(j) / nj) * nj
                    local bloque = i0 .. ':' .. j0
                    if not hecho[ij] and not vistos[bloque] then
                        vistos[bloque] = true
                        local entero = true
                        for a = 0, ni - 1 do
                            for b = 0, nj - 1 do
                                local q = (i0 + a) .. ':' .. (j0 + b)
                                if not g.c[q] or hecho[q] then entero = false end
                            end
                        end
                        if entero then
                            for a = 0, ni - 1 do
                                for b = 0, nj - 1 do hecho[(i0 + a) .. ':' .. (j0 + b)] = true end
                            end
                            u[('L%dx%d:%d:%d:%d:%s'):format(ni, nj, g.L, i0, j0, g.mat)] = {
                                modelo = modelo, rumbo = o.rumbo, grupo = 'losa', L = g.L,
                                pos = AMundo(o, (i0 + (ni - 1) / 2) * C.celda, (j0 + (nj - 1) / 2) * C.celda + m, g.L),
                            }
                        end
                    end
                end
            end
        end
        for ij, clave in pairs(g.c) do
            if not hecho[ij] then resto(clave) end
        end
    end

    for _, g in pairs(paredes) do
        local hecho = {}
        for _, n in ipairs({ 4, 2 }) do
            local modelo = joaat(('origen_casa_tabique%d_%s'):format(n, g.mat))
            if Existe(modelo) then
                local vistos = {}
                for a in pairs(g.c) do
                    local a0 = math.floor(a / n) * n
                    if not hecho[a] and not vistos[a0] then
                        vistos[a0] = true
                        local entero = true
                        for q = a0, a0 + n - 1 do
                            if not g.c[q] or hecho[q] then entero = false end
                        end
                        if entero then
                            for q = a0, a0 + n - 1 do hecho[q] = true end
                            local medio = (a0 + (n - 1) / 2) * C.celda
                            local pos, rumbo
                            if g.t == 'x' then
                                pos, rumbo = AMundo(o, g.fijo * C.celda + m, medio + m + CORRIDA, g.k), o.rumbo + 90.0
                            else
                                pos, rumbo = AMundo(o, medio + CORRIDA, g.fijo * C.celda + C.celda, g.k), o.rumbo
                            end
                            u[('P%d:%s:%d:%d:%d:%s'):format(n, g.t, g.fijo, a0, g.k, g.mat)] = {
                                modelo = modelo, pos = pos, rumbo = rumbo, grupo = g.t, fijo = g.fijo, k = g.k,
                            }
                        end
                    end
                end
            end
        end
        for a, clave in pairs(g.c) do
            if not hecho[a] then resto(clave) end
        end
    end

    -- El cubo: al excavar una celda le salen suelo, techo y paredes, siempre con
    -- los materiales de serie. Las que no han cabido en un paño van juntas en un
    -- solo objeto, origen_casa_cubo_<caras>, con un 1 por cada cara que lleva:
    -- suelo, techo, pared +X, -X, +Y, -Y. En cuanto se pinta una, esa se separa.
    for _, r in pairs(restos) do
        local bits = ''
        for cara = 1, 6 do bits = bits .. (r.caras[cara] and '1' or '0') end
        local modelo = r.n >= 2 and joaat('origen_casa_cubo_' .. bits)
        if modelo and Existe(modelo) then
            u[('C:%d:%d:%d:%s'):format(r.i, r.j, r.k, bits)] = {
                modelo = modelo, rumbo = o.rumbo, grupo = 'cubo', i = r.i, j = r.j, k = r.k, caras = r.caras,
                pos = AMundo(o, r.i * C.celda, r.j * C.celda + m, r.k),
            }
        else
            for _, clave in pairs(r.caras) do suelta(clave) end
        end
    end
    return u
end

local function Borrar(o, e)
    if not e then return end
    o.claves[e] = nil
    if DoesEntityExist(e) then DeleteEntity(e) end
end

local function Quitar(o, clave)
    Borrar(o, o.objetos[clave])
    o.objetos[clave], o.modelo[clave] = nil, nil
end

-- Deja montado justo lo que tiene que haber. Lo nuevo se pone antes de quitar
-- lo viejo (también al repintar): nunca falta el suelo ni un instante.
local function MontarUnaVez(o)
    local quiero = Unidades(o, Deseadas(o))
    for clave, d in pairs(quiero) do
        local modelo, pos, rumbo = d.modelo, d.pos, d.rumbo
        -- (un modelo que aún no se sirve —una escalera en L sin su pieza— no se espera)
        if o.modelo[clave] ~= modelo and Existe(modelo) and Cargar(modelo) then
            -- (mientras cargaba el modelo se ha podido salir de la casa: lo que se creara ahora ya no lo quitaría nadie)
            if o.muerta then return end
            local viejo = o.objetos[clave]
            local e = CreateObjectNoOffset(modelo, pos.x, pos.y, pos.z, false, false, false)
            SetEntityHeading(e, rumbo)
            FreezeEntityPosition(e, true)
            -- de una cara suelta, su clave; de un paño, sus datos (la cara sale de dónde se mira)
            o.objetos[clave], o.claves[e], o.modelo[clave] = e, d.clave or d, modelo
            Borrar(o, viejo)
        end
    end
    for clave in pairs(o.objetos) do
        if quiero[clave] == nil then Quitar(o, clave) end
    end
    -- lo que hay que tener apartado (los suelos de un hueco mientras pasa la cabina)
    for clave in pairs(o.ocultas or {}) do
        local e = o.objetos[clave]
        if e and DoesEntityExist(e) then
            SetEntityVisible(e, false, false)
            SetEntityCollision(e, false, false)
        end
    end
    if o.muerta then return end
    TriggerEvent('origen_housing:obra:montada', o.id)
end

-- De uno en uno. Montar espera a los modelos que aún no están cargados; con dos montajes a la
-- vez (dos cambios seguidos, de otro jugador) el más viejo acababa después y quitaba lo que el
-- nuevo había puesto: faltaba un suelo o una pared hasta el siguiente cambio. El que llega con
-- otro en marcha lo deja pedido, y el que está en marcha da otra vuelta al acabar.
local function Montar(o)
    if o.montando then
        o.otraVez = true
        return
    end
    o.montando = true
    repeat
        o.otraVez = false
        local ok, err = pcall(MontarUnaVez, o)
        if not ok then print(('^1[origen_housing]^7 obra: %s'):format(tostring(err))) end
    until not o.otraVez or o.muerta
    o.montando = false
end

-- ── Lo que llama el housing ─────────────────────────────────────────────
-- La luz de dentro: siempre la misma, sin la hora ni el clima de la calle
local function Ambiente(dentro)
    local a = C.ambiente
    if not a then return end
    local estado = LocalPlayer.state
    if dentro then
        estado:set('playerWeather', a.clima or 'CLEAR', true)
        estado:set('syncWeather', false, true)
        CreateThread(function()
            -- la sincronización tarda un momento en soltar la hora
            for _ = 1, 6 do
                if not actual then return end
                NetworkOverrideClockTime(math.floor(a.hora or 0), 0, 0)
                Wait(500)
            end
        end)
        if a.modificador then
            SetTimecycleModifier(a.modificador)
            SetTimecycleModifierStrength((a.fuerza or 1.0) + 0.0)
        end
    else
        if a.modificador then ClearTimecycleModifier() end
        estado:set('playerWeather', 'EXTRASUNNY', true)
        estado:set('syncWeather', true, true)
    end
end

function Obra.EsLibre(houseData)
    return houseData and houseData.data and houseData.data.type == 'shell' and houseData.data.model == C.ancla
end

--- Monta la casa alrededor del ancla. Lo llama Shell:CreateShell en cuanto
--- crea el «módulo» y antes de llevar al jugador dentro, y no vuelve hasta que
--- el suelo está puesto.
function Obra.Montar(houseData, ancla)
    if not Obra.EsLibre(houseData) then return end
    Obra.Desmontar()
    -- el ancla, derecha: así el punto de entrada del housing y la rejilla casan siempre
    SetEntityRotation(ancla, 0.0, 0.0, 0.0, 2, true)
    -- Sin la obra no hay suelo, y a quien entra se le lleva igual al interior (a dos mil metros
    -- de altura): si el servidor no contesta a la primera —acaba de arrancar— se insiste; y si
    -- no hay manera, se monta al menos la celda de la entrada, de la que se puede salir.
    local estado
    for _ = 1, 4 do
        estado = lib.callback.await('origen_housing:obra:estado', false, houseData.id)
        if estado then break end
        Wait(700)
    end
    if not estado then
        print('^1[origen_housing]^7 obra: el servidor no ha dado la obra de la casa ' .. tostring(houseData.id))
        Custom.Notify('No se ha podido cargar el interior de la casa: sal y vuelve a entrar', 'error', 8000)
        estado = { celdas = { ['0:0:0'] = 1 }, piezas = {}, pinturas = {} }
    end
    actual = { id = tostring(houseData.id), o = GetEntityCoords(ancla), rumbo = 0.0, X = vector3(1.0, 0.0, 0.0), Y = vector3(0.0, 1.0, 0.0),
        celdas = estado.celdas or {}, piezas = estado.piezas or {}, pinturas = estado.pinturas or {}, objetos = {}, claves = {}, modelo = {}, ocultas = {}, enPlano = {} }
    Montar(actual)
    Ambiente(true)
end

--- Al salir de la casa (ver Custom.OnExitHouse, al final).
function Obra.Desmontar()
    local o = actual
    if not o then return end
    actual, construyendo = nil, false
    o.muerta = true      -- (un montaje que siga esperando un modelo no crea ya nada)
    for clave in pairs(o.objetos) do Quitar(o, clave) end
    Ambiente(false)
    TriggerServerEvent('origen_housing:obra:salir', o.id)
    TriggerEvent('origen_housing:obra:desmontada', o.id)
end

--- La obra en la que está el jugador (solo para leer): { id, o, celdas, piezas }, o nil.
function Obra.Actual()
    return actual
end

--- Centro del suelo de una celda (la cara de arriba de su losa), en el mundo.
function Obra.Mundo(i, j, k)
    if not actual then return nil end
    return AMundo(actual, i * C.celda, j * C.celda + C.celda / 2, k)
end

--- Aparta (invisible y sin colisión) o repone una pieza por su clave. Se
--- mantiene aunque la casa se vuelva a montar; lo usa el ascensor con los
--- suelos de su hueco mientras pasa la cabina.
function Obra.Ocultar(clave, si)
    local o = actual
    if not o then return end
    o.ocultas[clave] = si and true or nil
    local e = o.objetos[clave]
    if si and not e then
        -- Un suelo entre plantas que no está puesto (el hueco de un ascensor, abierto) no tiene
        -- nada que apartar: antes se rehacía la casa entera cada vez que la cabina cruzaba una
        -- planta, una vez por cada celda del hueco.
        if clave:sub(1, 1) == 'l' and o.piezas[clave] == nil then return end
        -- va dentro de un paño: se rehace para dejarla suelta (y apartada)
        Montar(o)
        return
    end
    if e and DoesEntityExist(e) then
        SetEntityVisible(e, not si, false)
        SetEntityCollision(e, not si, not si)
    end
end

--- Modelo, posición y rumbo de una pieza en su sitio (custom/client/secretos.lua mueve desde ahí los pasos secretos).
function Obra.Colocacion(clave, valor)
    if not actual then return nil end
    return Colocacion(actual, clave, valor)
end

--- ¿Está el jugador en una casa de obra? (para ofrecer «Construir» en el menú de la casa)
function Obra.Dentro()
    return actual ~= nil
end

RegisterNetEvent('origen_housing:obra:cambio', function(id, cam)
    local o = actual
    if not o or o.id ~= tostring(id) then return end
    for celda, si in pairs(cam.celdas or {}) do o.celdas[celda] = si and 1 or nil end
    for clave, valor in pairs(cam.piezas or {}) do
        if valor == false then o.piezas[clave] = nil else o.piezas[clave] = valor end
    end
    for clave, material in pairs(cam.pinturas or {}) do o.pinturas[clave] = material or nil end
    Montar(o)
end)

RegisterNetEvent('origen_housing:obra:deshecho', function(quedan)
    quedan = tonumber(quedan) or 0
    exports.origen_notify:Notify({ title = 'Deshecho', type = 'info', duration = 2500,
        description = quedan > 0 and ('Puedes deshacer %d más'):format(quedan) or 'No queda nada más que deshacer' })
end)

RegisterNetEvent('origen_housing:obra:aviso', function(texto)
    Custom.Notify(texto, 'error', 4000)
end)

AddEventHandler('onResourceStop', function(r)
    if r == GetCurrentResourceName() then Obra.Desmontar() end
end)

-- ── La cinta: amueblar y construir sin menú ─────────────────────────────
-- Una sola fila abajo (ui/js/obra.js). Q y E cambian de categoría, la rueda
-- pasa cosas y la del centro ya se ve en la casa, donde se mira; clic la pone.
-- Las herramientas de obra y los materiales son dos categorías más, solo en
-- las casas de modalidad libre. Los muebles se compran y se borran con las
-- mismas llamadas al servidor que el menú Decorar de siempre.
local HERRAMIENTAS = {
    cavar = { nombre = 'Excavar', icono = 'fas fa-person-digging', poner = 'Excavar', quitar = 'Rellenar' },
    pared = { nombre = 'Pared', icono = 'fas fa-table-cells-large' },
    -- en el rincón entre dos paredes (o en el canto de un saliente): la R cambia el radio (config/obra_esquinas.lua, custom/client/esquinas.lua)
    esquina = { nombre = 'Esquina redondeada', icono = 'fas fa-bezier-curve', gira = 'Radio' },
    -- en el mismo borde que una pared, sin separar salas: la R pasa de estilo (Config.Obra.barandillas)
    barandilla = { nombre = 'Barandilla', icono = 'fas fa-grip-lines', gira = 'Estilo' },
    puerta = { nombre = 'Hueco de puerta', icono = 'fas fa-door-open' },
    puerta2 = { nombre = 'Hueco de puerta doble', icono = 'fas fa-door-closed' },
    garaje = { nombre = 'Hueco de garaje', icono = 'fas fa-warehouse' },
    -- pasos secretos (config/secretos.lua; los abre custom/client/secretos.lua): la R pasa de estilo
    secreto = { nombre = 'Puerta secreta', icono = 'fas fa-dungeon', gira = 'Estilo', frente = 'Dar la vuelta' },
    trampilla = { nombre = 'Trampilla', icono = 'fas fa-square-caret-down', gira = 'Estilo' },
    suelo = { nombre = 'Suelo entre plantas', icono = 'fas fa-layer-group' },
    baja = { nombre = 'Escalera que baja', icono = 'fas fa-arrow-turn-down', gira = 'Girar' },
    sube = { nombre = 'Escalera que sube', icono = 'fas fa-arrow-turn-up', gira = 'Girar' },
    -- la misma pieza (e:…) en L: la R cambia de mano (derecha, izquierda) y, a la tercera, gira
    bajaL = { nombre = 'Escalera en L que baja', icono = 'fas fa-turn-down', gira = 'Mano y giro' },
    subeL = { nombre = 'Escalera en L que sube', icono = 'fas fa-turn-up', gira = 'Mano y giro' },
    -- más formas de la misma pieza (e:…). Suben desde donde se mira; con Mayús + rueda, bajan a la planta de abajo
    escala = { nombre = 'Escalera de mano', icono = 'fas fa-water-ladder', gira = 'Girar', frente = 'Sube o baja' },
    caracol = { nombre = 'Escalera de caracol', icono = 'fas fa-rotate', gira = 'Compacta o amplia, y giro', frente = 'Sube o baja' },
    ascensor = { nombre = 'Ascensor', icono = 'fas fa-elevator', gira = 'Tamaño y plantas' },
    -- la misma pieza (a:…) con cabina cerrada y puertas: de 1 o 2 celdas, y con frente (Mayús + rueda)
    ascensor2 = { nombre = 'Ascensor de cabina', icono = 'fas fa-square-person-confined', gira = 'Tamaño y plantas', frente = 'Frente' },
    montacoches = { nombre = 'Montacoches', icono = 'fas fa-car-side', gira = 'Plantas y giro' },
    imagen = { nombre = 'Imagen', icono = 'fas fa-image', gira = 'Tamaño' },      -- custom/client/imagenes.lua
    -- los puntos de entrada (custom/client/entradas.lua): se ponen donde se está, mirando hacia donde se mira
    entrada = { nombre = 'Entrada', icono = 'fas fa-right-to-bracket', poner = 'Poner aquí la entrada' },
    cochera = { nombre = 'Entrada de garaje', icono = 'fas fa-car', poner = 'El coche aparece aquí' },
}
local ORDEN = { 'cavar', 'pared', 'esquina', 'barandilla', 'puerta', 'puerta2', 'garaje', 'secreto', 'trampilla', 'suelo', 'baja', 'sube', 'bajaL', 'subeL', 'escala', 'caracol', 'ascensor', 'ascensor2', 'montacoches', 'imagen', 'entrada', 'cochera' }

-- Pista cuando un clic no hace nada, sin repetirla a cada clic. También sale
-- por un evento local, por si alguien quiere apuntar qué se intentó.
local ultimaPista = 0
local function Pista(texto, ...)
    TriggerEvent('origen_housing:obra:nada', texto, ...)
    if GetGameTimer() - ultimaPista < 1500 then return end
    ultimaPista = GetGameTimer()
    Custom.Notify(texto, 'info', 3500)
end

-- ── La mirada ───────────────────────────────────────────────────────────
-- Qué se está mirando.
--   pos, normal: dónde choca la mirada (o unos metros por delante, al aire)
--   mueble, id: el mueble de la casa que se mira y su identificador
--   pieza, entidad: la pieza de la obra que se mira. Su clave dice qué dos
--     celdas separa: a es la celda abierta desde la que se ve; b, la del otro lado
local function Mirada(o, ignorar)
    local ped = PlayerPedId()
    local cam, rot = GetFinalRenderedCamCoord(), GetFinalRenderedCamRot(2)
    local rx, rz = math.rad(rot.x), math.rad(rot.z)
    local dir = vector3(-math.sin(rz) * math.cos(rx), math.cos(rz) * math.cos(rx), math.sin(rx))
    local fin = cam + dir * 16.0
    local rayo = StartExpensiveSynchronousShapeTestLosProbe(cam.x, cam.y, cam.z, fin.x, fin.y, fin.z, 1 + 16, ped, 4)
    local _, toca, pos, normal, ent = GetShapeTestResult(rayo)
    local m = { dir = dir, rumbo = rot.z, cam = cam }
    if toca ~= 1 then
        m.pos, m.normal = cam + dir * 4.0, vector3(0.0, 0.0, 1.0)
        m.aire = true
        return m
    end
    m.pos, m.normal = pos, normal
    if ent and ent ~= 0 and ent ~= ignorar and DoesEntityExist(ent) and GetEntityType(ent) == 3 then
        local id = Entity(ent).state.entityID
        if id then m.mueble, m.id = ent, id end
    end
    if not o then return m end
    local pieza, grupo = o.claves[ent], nil
    if type(pieza) == 'table' then
        -- un paño: la cara es la de la celda en la que cae lo que se mira
        grupo = pieza
        local lx, ly = ALocal(o, pos - normal * 0.03)
        if grupo.grupo == 'cubo' then
            local nx, ny = normal.x * o.X.x + normal.y * o.X.y, normal.x * o.Y.x + normal.y * o.Y.y
            local cara
            if math.abs(normal.z) > 0.7 then
                cara = normal.z > 0 and 1 or 2
            elseif math.abs(nx) > math.abs(ny) then
                cara = lx > grupo.i * C.celda and 3 or 4
            else
                cara = ly > grupo.j * C.celda + C.celda / 2 and 5 or 6
            end
            -- el canto de una losa o de una pared: la cara que más cerca quede de las que tiene
            pieza = grupo.caras[cara] or grupo.caras[1] or grupo.caras[2] or select(2, next(grupo.caras))
        elseif grupo.grupo == 'losa' then
            local ci, cj = Celda(lx, ly)
            pieza = o.enPlano[grupo.L .. ':' .. ci .. ':' .. cj]
        elseif grupo.grupo == 'x' then
            pieza = ('x:%d:%d:%d'):format(grupo.fijo, math.floor(ly / C.celda), grupo.k)
        else
            pieza = ('y:%d:%d:%d'):format(math.floor(lx / C.celda + 0.5), grupo.fijo, grupo.k)
        end
    end
    if not pieza then
        -- no es una pieza de la obra (la cabina de un ascensor, la plataforma del
        -- montacoches, un mueble…): al menos, en qué celda cae lo que se mira
        local lx, ly, lz = ALocal(o, pos)
        local ci, cj = Celda(lx, ly)
        m.celda = { ci, cj, math.floor((lz + 0.02) / C.planta) }
        return m
    end

    m.dx, m.dy, m.dz = dir.x * o.X.x + dir.y * o.X.y, dir.x * o.Y.x + dir.y * o.Y.y, dir.z
    m.pieza, m.entidad = pieza, ent
    -- de un paño no se marca el objeto entero, sino el recuadro de la cara (ver Recuadro)
    -- (y de una suelta también: el contorno del juego no les sale a todos los jugadores)
    m.entidad, m.recuadro = nil, true
    m.x, m.y = ALocal(o, pos)
    local cx, cy, cz = ALocal(o, cam)
    local t, i, j, k = Partes(m.pieza)
    local u, v      -- las dos celdas que separa
    if t == 's' then
        u, v = { i, j, k }, { i, j, k - 1 }
    elseif t == 't' then
        u, v = { i, j, k }, { i, j, k + 1 }
    elseif t == 'l' then
        u, v = { i, j, k }, { i, j, k - 1 }
        if cz < k * C.planta then u, v = v, u end
    elseif t == 'x' then
        u, v = { i, j, k }, { i + 1, j, k }
        if cx > i * C.celda + C.celda / 2 then u, v = v, u end
    elseif t == 'y' then
        u, v = { i, j, k }, { i, j + 1, k }
        if cy > j * C.celda + C.celda then u, v = v, u end
    elseif t == 'r' or t == 'v' then
        -- una esquina redondeada: se ve desde su celda (un canto, desde la abierta más cercana a la cámara)
        m.a = Esquinas.CeldaDe(o, m.pieza, cx, cy)
        return m
    else
        local _, _, z = ALocal(o, pos)
        local ei, ej = Celda(m.x, m.y)
        m.a = { ei, ej, math.floor((z + 0.02) / C.planta) }
        return m
    end
    -- se ve desde la que está abierta; si lo están las dos, desde el lado de la cámara
    if not Abierta(o, u[1], u[2], u[3]) and Abierta(o, v[1], v[2], v[3]) then u, v = v, u end
    m.a, m.b = u, v
    return m
end

-- Para pintar de una vez: todas las caras como la que se mira (paredes,
-- suelo o techo) de la sala en la que está. La sala es lo que se alcanza desde
-- esa celda sin cruzar una pared, en su misma planta.
local function CarasDeLaSala(o, m)
    local t, _, _, pk = Partes(m.pieza)
    if t == 'e' or not m.a then return {} end
    -- (una esquina redondeada cuenta como pared, y las de la sala se pintan con sus paredes)
    local que = (t == 'x' or t == 'y' or t == 'r' or t == 'v') and 'pared' or (t == 's' or (t == 'l' and m.a[3] == pk)) and 'suelo' or 'techo'
    local k = m.a[3]
    local function borde(i, j, oi, oj)
        if i ~= oi then return ('x:%d:%d:%d'):format(math.min(i, oi), j, k) end
        return ('y:%d:%d:%d'):format(i, math.min(j, oj), k)
    end
    local vistas, cola, caras, puestas = { [K(m.a[1], m.a[2], k)] = true }, { { m.a[1], m.a[2] } }, {}, {}
    local function cara(clave)
        if not puestas[clave] then
            puestas[clave] = true
            caras[#caras + 1] = clave
        end
    end
    while #cola > 0 and #caras < 1200 do
        local c = table.remove(cola)
        local i, j = c[1], c[2]
        if que == 'suelo' then
            cara(Abierta(o, i, j, k - 1) and ('l:%d:%d:%d'):format(i, j, k) or ('s:%d:%d:%d'):format(i, j, k))
        elseif que == 'techo' then
            cara(Abierta(o, i, j, k + 1) and ('l:%d:%d:%d'):format(i, j, k + 1) or ('t:%d:%d:%d'):format(i, j, k))
        else
            C.Esquinas.DeCelda(o, i, j, k, cara)
        end
        for _, l in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
            local oi, oj = i + l[1], j + l[2]
            local pared = borde(i, j, oi, oj)
            -- (una barandilla no separa salas: se pasa por encima, y no se pinta)
            if not Abierta(o, oi, oj, k) or (o.piezas[pared] ~= nil and not C.Baranda(o.piezas[pared])) then
                if que == 'pared' then
                    -- medio hueco de garaje: la pieza (y su pintura) es la de su pareja
                    if o.piezas[pared] == 'G' then
                        pared = (pared:sub(1, 1) == 'x') and borde(i, j - 1, oi, oj - 1) or borde(i - 1, j, oi - 1, oj)
                    end
                    cara(pared)
                end
            elseif not vistas[K(oi, oj, k)] then
                vistas[K(oi, oj, k)] = true
                cola[#cola + 1] = { oi, oj }
            end
        end
    end
    return caras
end

-- ¿Pasa un hueco de ascensor o de montacoches por la celda (i,j,k)? Devuelve su clave.
function HuecoEn(o, i, j, k)
    for clave, valor in pairs(o.piezas) do
        local t, hi, hj, hk = Partes(clave)
        if t == 'a' then
            local f = math.floor(valor / 10) % 10      -- las centenas son el estilo (cabina cerrada y su frente)
            if k >= hk and k < hk + valor % 10 and i >= hi and i <= hi + ((f == 1 or f == 3) and 1 or 0)
                and j >= hj and j <= hj + ((f == 2 or f == 3) and 1 or 0) then
                return clave
            end
        elseif t == 'c' then
            local n, g = math.floor(valor / 10), valor % 10
            if k >= hk and k < hk + n and i >= hi and i <= hi + (g == 1 and 2 or 1) and j >= hj and j <= hj + (g == 1 and 1 or 2) then
                return clave
            end
        end
    end
end

local function NombrePlanta(k)
    if k == 0 then return 'planta baja' end
    return k > 0 and ('planta ' .. k) or ('sótano ' .. -k)
end

-- Giro (0..3) más cercano a la dirección en la que se mira
local function GiroMirada(m)
    if math.abs(m.dx) > math.abs(m.dy) then return m.dx > 0 and 1 or 3 end
    return m.dy > 0 and 0 or 2
end

-- Clave y valor de la pieza que pondría la herramienta donde se mira
-- El hueco entre dos plantas por el que pasa la mirada. Un hueco no tiene nada
-- que mirar: la mirada lo atraviesa y acaba en la planta de abajo, en otra
-- celda, o en un mueble. Así que se busca por dónde cruza el plano de cada
-- suelo (mirando hacia abajo) o de cada techo (hacia arriba) antes de chocar
-- con nada: si ahí falta el suelo entre dos plantas abiertas, es ese.
local function HuecoMirado(o, m)
    if not m.cam then return end
    local ax, ay, az = ALocal(o, m.cam)
    local bx, by, bz = ALocal(o, m.cam + m.dir)
    local dx, dy, dz = bx - ax, by - ay, bz - az
    if math.abs(dz) < 0.02 then return end
    local tope = m.aire and 16.0 or (#(m.pos - m.cam) + 0.05)
    local kc = math.floor(az / C.planta)
    for n = 0, 2 do
        local kk = dz < 0 and kc - n or kc + 1 + n
        local t = (kk * C.planta - az) / dz
        if t > 0.0 and t <= tope then
            local ci, cj = Celda(ax + dx * t, ay + dy * t)
            if Abierta(o, ci, cj, kk) and Abierta(o, ci, cj, kk - 1) and o.piezas[('l:%d:%d:%d'):format(ci, cj, kk)] == nil then
                return ci, cj, kk
            end
        end
    end
end

-- El estilo de barandilla que toca con esa vuelta de la R, de los que se pueden
-- poner: los de Config.Obra.barandillas cuyo modelo ya se sirve. nil si no hay ninguno.
local function EstiloBaranda(vuelta)
    local hay = {}
    for _, b in ipairs(C.barandillas) do
        if Existe(C.ModeloBaranda(b.id)) then hay[#hay + 1] = b end
    end
    return hay[vuelta % math.max(#hay, 1) + 1]
end

local function Objetivo(o, id, m, vuelta, frente)
    -- el ascensor de cabina es el ascensor de siempre con estilo: se elige igual
    local cabina = id == 'ascensor2'
    if cabina then id = 'ascensor' end
    if id == 'trampilla' then
        -- en un hueco entre dos plantas, o sobre el suelo entre plantas que se mira (lo sustituye)
        local estilo = Config.Secretos and Config.Secretos.Toca('suelo', vuelta)
        if not estilo then return end
        local hi, hj, hk = HuecoMirado(o, m)
        if hi then return ('l:%d:%d:%d'):format(hi, hj, hk), 'o:' .. estilo.id end
        if m.pieza and m.pieza:sub(1, 1) == 'l' then return m.pieza, 'o:' .. estilo.id end
        if not m.a then return end
        local kk = m.dz < 0 and m.a[3] + 1 or m.a[3]
        if not (Abierta(o, m.a[1], m.a[2], kk) and Abierta(o, m.a[1], m.a[2], kk - 1)) then return end
        return ('l:%d:%d:%d'):format(m.a[1], m.a[2], kk), 'o:' .. estilo.id
    end
    -- la esquina redondeada: el rincón más cercano de la celda que se mira (custom/client/esquinas.lua)
    if id == 'esquina' then return Esquinas.Objetivo(o, m, vuelta) end
    if id == 'suelo' or id == 'ascensor' or id == 'montacoches' then
        local hi, hj, hk = HuecoMirado(o, m)
        if hi and id == 'suelo' then return ('l:%d:%d:%d'):format(hi, hj, hk), 1 end
        -- el ascensor y el montacoches se ponen en la celda del hueco que se mira
        if hi then m.a = { hi, hj, hk } end
    end
    if not m.a then return end
    local i, j, k = m.a[1], m.a[2], m.a[3]
    if id == 'pared' or id == 'puerta' or id == 'puerta2' or id == 'garaje' or id == 'barandilla' or id == 'secreto' then
        local dx, dy = m.x - i * C.celda, m.y - (j * C.celda + C.celda / 2)
        local valor = id == 'puerta' and 'u' or id == 'garaje' and 'g' or id == 'puerta2' and 'd' or 'p'
        local doble = valor == 'g' or valor == 'd'      -- ocupa este borde y el de al lado
        if id == 'barandilla' then
            -- se apunta como la pared; la R pasa de estilo
            local estilo = EstiloBaranda(vuelta)
            if not estilo then return end
            valor = 'b:' .. estilo.id
        end
        -- el paso secreto se apunta igual; los que tienen frente salen de cara a quien los pone (Mayús + rueda: al revés)
        local secreto = id == 'secreto' and Config.Secretos and Config.Secretos.Toca('borde', vuelta) or nil
        if id == 'secreto' and not secreto then return end
        local function ValorSecreto(deCara)
            if not secreto.modelo then return 'o:' .. secreto.id end
            if (frente or 0) % 2 == 1 then deCara = not deCara end
            return 'o:' .. secreto.id .. (deCara and '' or ':v')
        end
        if math.abs(dx) > math.abs(dy) then
            local a, b = math.min(i, dx > 0 and i + 1 or i - 1), j
            if secreto then valor = ValorSecreto(i == a) end      -- sin volver mira a la celda (a, b)
            -- el garaje ocupa este borde y el de al lado: con R, el del otro lado
            if doble and vuelta % 2 == 1 then b = b - 1 end
            if not (Abierta(o, a, b, k) and Abierta(o, a + 1, b, k)) then return end
            if doble and not (Abierta(o, a, b + 1, k) and Abierta(o, a + 1, b + 1, k)) then return end
            return ('x:%d:%d:%d'):format(a, b, k), valor
        end
        local a, b = i, math.min(j, dy > 0 and j + 1 or j - 1)
        if secreto then valor = ValorSecreto(j ~= b) end          -- sin volver mira a la celda (a, b + 1)
        if doble and vuelta % 2 == 1 then a = a - 1 end
        if not (Abierta(o, a, b, k) and Abierta(o, a, b + 1, k)) then return end
        if doble and not (Abierta(o, a + 1, b, k) and Abierta(o, a + 1, b + 1, k)) then return end
        return ('y:%d:%d:%d'):format(a, b, k), valor
    elseif id == 'suelo' then
        -- mirando hacia abajo por un hueco se tapa el hueco; mirando hacia arriba, el de encima
        local kk = m.dz < 0 and k + 1 or k
        if not (Abierta(o, i, j, kk) and Abierta(o, i, j, kk - 1)) then return end
        return ('l:%d:%d:%d'):format(i, j, kk), 1
    elseif id == 'ascensor' or id == 'montacoches' then
        -- Solo se ofrece lo que cabe: tramos de 2 a 5 plantas que pasen por la
        -- celda mirada y tengan su hueco abierto en todas. La R va pasando por
        -- las opciones: el ascensor, de una celda, de dos (a lo ancho y a lo
        -- largo) y de cuatro; el montacoches, derecho y girado; y cada uno de
        -- más plantas a menos.
        local function libre(g, kk)
            local ancho, largo
            if id == 'ascensor' then
                ancho, largo = (g == 1 or g == 3) and 1 or 0, (g == 2 or g == 3) and 1 or 0
            else
                ancho, largo = g == 1 and 2 or 1, g == 1 and 1 or 2
            end
            for a = 0, ancho do
                for b = 0, largo do
                    if not Abierta(o, i + a, j + b, kk) then return false end
                end
            end
            return true
        end
        local opciones = {}
        for g = 0, (id == 'montacoches' and 1 or cabina and 2 or 3) do     -- la cabina cerrada no la hay de cuatro celdas
            if libre(g, k) then
                local abajo, arriba = k, k
                while abajo - 1 >= C.plantaMin and libre(g, abajo - 1) do abajo = abajo - 1 end
                while arriba + 1 <= C.plantaMax and libre(g, arriba + 1) do arriba = arriba + 1 end
                for n = math.min(5, arriba - abajo + 1), 2, -1 do
                    for base = math.max(abajo, k - n + 1), math.min(k, arriba - n + 1) do
                        opciones[#opciones + 1] = { base, n, g }
                    end
                end
            end
        end
        if #opciones == 0 then return end
        local op = opciones[vuelta % #opciones + 1]
        if id == 'ascensor' then
            local estilo = 0
            if cabina then
                -- El frente, hacia quien lo coloca: el lado del hueco que le
                -- queda más cerca (en el de dos celdas, uno de los dos largos).
                -- Mayús + rueda lo pasa al siguiente lado (o al de enfrente).
                local f = op[3]
                local px, py = ALocal(o, GetEntityCoords(PlayerPedId()))
                local dx = px - (i + (f == 1 and 0.5 or 0.0)) * C.celda
                local dy = py - ((j + (f == 2 and 0.5 or 0.0)) * C.celda + C.celda / 2)
                local g
                if f == 1 or (f == 0 and math.abs(dy) >= math.abs(dx)) then
                    g = dy > 0 and 0 or 2
                else
                    g = dx > 0 and 1 or 3
                end
                estilo = (g + (frente or 0) * (f == 0 and 1 or 2)) % 4 + 1
            end
            return ('a:%d:%d:%d'):format(i, j, op[1]), op[2] + 10 * op[3] + 100 * estilo
        end
        return ('c:%d:%d:%d'):format(i, j, op[1]), op[2] * 10 + op[3]
    elseif id == 'sube' or id == 'baja' then
        local giro = (GiroMirada(m) + vuelta) % 4
        if id == 'sube' then return ('e:%d:%d:%d'):format(i, j, k), giro end
        -- La que baja es una escalera de la planta de abajo que sube hacia el
        -- jugador: su último tramo queda bajo la celda mirada.
        local d = C.giros[giro]
        return ('e:%d:%d:%d'):format(i + d[1], j + d[2], k - 1), (giro + 2) % 4
    elseif id == 'subeL' or id == 'bajaL' then
        -- En L (valor = giro + 4 * forma, Config.Obra.Escalera). Se arranca hacia
        -- donde se mira; la R pasa de torcer a la derecha a torcer a la izquierda
        -- y, de dos en dos, da un cuarto de vuelta.
        local giro = (GiroMirada(m) + math.floor(vuelta / 2)) % 4
        local zurda = vuelta % 2 == 1
        if id == 'subeL' then return ('e:%d:%d:%d'):format(i, j, k), giro + 4 * (zurda and 2 or 1) end
        -- La que baja es una de la planta de abajo que llega aquí: se pisa su
        -- segundo tramo en la celda mirada, andando hacia donde se mira, y en el
        -- rellano de después se tuerce (a la derecha o a la izquierda de quien
        -- baja) hasta su arranque. Vista subiendo tuerce a la otra mano.
        local d = C.giros[giro]
        local s = zurda and -1 or 1
        local ai, aj = i + d[1] + s * d[2], j + d[2] - s * d[1]
        return ('e:%d:%d:%d'):format(ai, aj, k - 1), (giro + (zurda and 1 or 3)) % 4 + 4 * (zurda and 1 or 2)
    elseif id == 'escala' then
        -- De mano (forma 3): va en la celda desde la que se mira, pegada a la
        -- pared que se mira; mirando el suelo, a la pared que quede más cerca
        -- del punto mirado. La R la pasa a la pared siguiente. Con Mayús + rueda
        -- es la que baja: la misma, una planta más abajo.
        local t = m.pieza and m.pieza:sub(1, 1)
        local giro
        if (t == 'x' or t == 'y') and m.b then
            giro = (m.b[1] > i and 1) or (m.b[1] < i and 3) or (m.b[2] > j and 0) or 2
        else
            local dx, dy = m.x - i * C.celda, m.y - (j * C.celda + C.celda / 2)
            if math.abs(dx) > math.abs(dy) then giro = dx > 0 and 1 or 3 else giro = dy > 0 and 0 or 2 end
        end
        giro = (giro + vuelta) % 4
        return ('e:%d:%d:%d'):format(i, j, (frente or 0) % 2 == 1 and k - 1 or k), giro + 12
    elseif id == 'caracol' then
        -- De caracol: compacta (forma 4, una celda) o amplia (forma 5, 2x2 con el
        -- rellano en la celda mirada); la R alterna y, de dos en dos, gira. Se
        -- entra andando hacia donde se mira. Con Mayús + rueda, la que baja.
        local giro = (GiroMirada(m) + math.floor(vuelta / 2)) % 4
        return ('e:%d:%d:%d'):format(i, j, (frente or 0) % 2 == 1 and k - 1 or k), giro + 4 * (vuelta % 2 == 1 and 5 or 4)
    end
end

-- ── El catálogo ─────────────────────────────────────────────────────────
-- Una cosa de la cinta es { clave, tipo = 'h' | 'm' | 'f', ... }:
--   h:<id> herramienta de obra · m:<material> pintar con él · f:<modelo> mueble
local PORCLAVE, PORMODELO = {}, {}      -- todas las cosas, por clave y (los muebles) por modelo
local MEMORIA = { recientes = {}, favoritos = {} }
local gastado = 0

local function Cosa(c)
    PORCLAVE[c.clave] = c
    return c
end

-- Los muebles, repartidos por grupo de la cinta (config/cinta.lua), cada uno
-- con su nombre legible, su grupo y su subgrupo. Un modelo que el catálogo
-- trae en dos categorías sale una sola vez, en la primera.
local MUEBLES = {}      -- id de grupo → sus cosas, en el orden del catálogo
local function Catalogar()
    local T = Config.Cinta
    local hechos, lista, usos = {}, {}, {}
    local n = 0
    for _, cat in ipairs(Config.Furniture or {}) do
        for _, it in ipairs(cat.items or {}) do
            local c = PORCLAVE['f:' .. it.model]
            if c and not hechos[c] then
                hechos[c] = true
                local entrada = T.Entrada(it.model)
                local nombre, propio = T.Nombre(it, cat.label, entrada)
                c.nombre, c.generico, c.categoria = nombre, not propio, cat.label
                c.grupo, c.sub = T.Clasificar(cat.label, it.model, entrada, propio and nombre or nil)
                -- sin nombre propio ni entrada en el diccionario: la categoría y un número, siempre
                if not propio and not entrada then usos[nombre] = 2 elseif not propio then usos[nombre] = (usos[nombre] or 0) + 1 end
                lista[#lista + 1] = c
                n = n + 1
                if n % 250 == 0 then Wait(0) end
            end
        end
    end
    -- los nombres genéricos que se repiten, numerados: «Sillón 1», «Sillón 2»…
    local cuenta, porGrupo = {}, {}
    for _, c in ipairs(lista) do
        if c.generico and (usos[c.nombre] or 0) > 1 then
            cuenta[c.nombre] = (cuenta[c.nombre] or 0) + 1
            c.nombre = c.nombre .. ' ' .. cuenta[c.nombre]
        end
        porGrupo[c.grupo] = porGrupo[c.grupo] or {}
        porGrupo[c.grupo][#porGrupo[c.grupo] + 1] = c
    end
    MUEBLES = porGrupo
end

CreateThread(function()
    for _, id in ipairs(ORDEN) do
        local h = HERRAMIENTAS[id]
        Cosa({ clave = 'h:' .. id, tipo = 'h', id = id, nombre = h.nombre, icono = h.icono })
    end
    for n, mat in ipairs(C.materiales) do
        Cosa({ clave = 'm:' .. mat.id, tipo = 'm', n = n, id = mat.id, nombre = 'Pintar · ' .. mat.nombre, img = './img/obra/' .. mat.id .. '.jpg' })
    end
    Wait(500)       -- el catálogo de muebles lo ordena client/furniture.lua al arrancar
    for _, cat in ipairs(Config.Furniture or {}) do
        for _, it in ipairs(cat.items or {}) do
            local precio = tonumber(it.price) or Config.DefaultPrice or 0
            local c = Cosa({ clave = 'f:' .. it.model, tipo = 'f', modelo = it.model, precio = precio, nombre = cat.label, puerta = it.type == 'door',
                img = './img/furniture/' .. it.model .. '.png' })
            PORMODELO[joaat(it.model)] = c
        end
    end
    Catalogar()
    for lista in pairs(MEMORIA) do
        local ok, t = pcall(json.decode, GetResourceKvpString('origen_housing:cinta:' .. lista) or '[]')
        MEMORIA[lista] = ok and type(t) == 'table' and t or {}
    end
end)

local function Recordar(lista)
    SetResourceKvp('origen_housing:cinta:' .. lista, json.encode(MEMORIA[lista]))
end

local function Usada(clave)
    local t = MEMORIA.recientes
    for q = #t, 1, -1 do
        if t[q] == clave then table.remove(t, q) end
    end
    table.insert(t, 1, clave)
    while #t > 14 do t[#t] = nil end
    Recordar('recientes')
end

-- Las cosas de una lista de claves (recientes, favoritos) que valen en esta casa
local function DeLista(lista, libre)
    local r = {}
    for _, clave in ipairs(lista) do
        local c = PORCLAVE[clave]
        if c and (libre or c.tipo == 'f') then r[#r + 1] = c end
    end
    return r
end

-- Subgrupo de una cosa dentro de su grupo (config/cinta.lua)
local function SubDe(c)
    if c.tipo == 'h' then return Config.Cinta.SubHerramienta(c.id) end
    if c.tipo == 'm' then return Config.Cinta.SubMaterial(c.id) end
    return c.sub
end

-- El buscador (Intro): lo que se va escribiendo llega de la página por los
-- dos callbacks de más abajo y lo recoge el bucle de la cinta.
local BUSCA = { activo = false, texto = '', cosas = {}, cambio = false, fin = nil, visto = 0 }
local ULTIMA = {}       -- lo último que se llevó en cada grupo (por su nombre) y, en [0], lo último de todo

-- Los grupos de la cinta en esta casa (config/cinta.lua): Recientes, Favoritos,
-- Construir y Pintar (solo en las de modalidad libre), los de muebles y, al
-- final, Buscar. Cada grupo lleva sus cosas seguidas, ordenadas por subgrupo,
-- y `subs`: { nombre, desde, n } de cada uno.
local function Categorias(libre)
    local T = Config.Cinta
    local cats = {
        { nombre = 'Recientes', icono = 'fas fa-clock-rotate-left', cosas = DeLista(MEMORIA.recientes, libre), viva = 'recientes',
            pista = 'Aquí sale lo último que has usado' },
        { nombre = 'Favoritos', icono = 'fas fa-heart', cosas = DeLista(MEMORIA.favoritos, libre), viva = 'favoritos',
            pista = 'Con la F guardas aquí lo que llevas en la mano' },
    }
    for _, g in ipairs(T.grupos) do
        local cosas = {}
        if g.id == 'construir' then
            if libre then
                for _, id in ipairs(ORDEN) do cosas[#cosas + 1] = PORCLAVE['h:' .. id] end
            end
        elseif g.id == 'pintar' then
            if libre then
                for _, mat in ipairs(C.materiales) do cosas[#cosas + 1] = PORCLAVE['m:' .. mat.id] end
            end
        elseif not g.obra then
            cosas = MUEBLES[g.id] or {}
        end
        -- lo que la casa no tiene (packs: custom/client/packs.lua) va al final de su subgrupo, con candado, o fuera
        if PacksCliente then cosas = PacksCliente.Filtrar(cosas) end
        if #cosas > 0 then
            local seguidas, subs = T.Repartir(g, cosas, SubDe)
            cats[#cats + 1] = { id = g.id, nombre = g.nombre, icono = g.icono, cosas = seguidas, subs = subs }
        end
    end
    cats[#cats + 1] = { nombre = 'Buscar', icono = 'fas fa-magnifying-glass', cosas = BUSCA.cosas, busca = true,
        pista = 'Pulsa Intro y escribe: busca por nombre en todo el catálogo' }
    return cats
end

-- Los resultados de buscar `texto` en todos los grupos: todas las palabras
-- tienen que estar en el nombre, el subgrupo, el grupo o el modelo de la cosa.
local function Buscar(cats, texto)
    local T = Config.Cinta
    local palabras, r, vistas = {}, {}, {}
    for p in T.Llano(texto):gmatch('%S+') do palabras[#palabras + 1] = p end
    if #palabras == 0 or #T.Llano(texto) < 2 then return r end
    for _, cat in ipairs(cats) do
        if cat.id then
            for _, c in ipairs(cat.cosas) do
                if not vistas[c.clave] then
                    c.pajar = c.pajar or T.Llano(('%s %s %s %s'):format(c.nombre or '', SubDe(c) or '', cat.nombre, c.modelo or c.id or ''))
                    if T.Casa(palabras, c.pajar) then
                        vistas[c.clave] = true
                        r[#r + 1] = c
                        if #r >= (T.maxBusqueda or 80) then return r end
                    end
                end
            end
        end
    end
    return r
end

-- Lo que la R va pasando en una herramienta con estilos, para enseñarlo
-- entero encima de la cosa: { { nombre, img, on } }, y cómo se llama eso.
local IMG_ESTILO = {}
local function ImagenEstilo(grupo, id)
    local ruta = ('img/obra/estilos/%s_%s.png'):format(grupo, id)
    if IMG_ESTILO[ruta] == nil then
        IMG_ESTILO[ruta] = LoadResourceFile(GetCurrentResourceName(), 'ui/' .. ruta) ~= nil
    end
    return IMG_ESTILO[ruta] and ('./' .. ruta) or nil
end

local function Variantes(cosa, vuelta)
    if not cosa or cosa.tipo ~= 'h' then return nil end
    local lista, de, elegido = {}, 'Estilo', nil
    if cosa.id == 'barandilla' then
        for _, b in ipairs(C.barandillas) do
            if IsModelInCdimage(C.ModeloBaranda(b.id)) then
                local cerrado = PacksCliente and PacksCliente.EstiloCerrado('barandillas', b.id)
                lista[#lista + 1] = { id = b.id, nombre = cerrado and (b.nombre .. ' · con pack') or b.nombre, img = ImagenEstilo('barandillas', b.id) }
            end
        end
        local e = EstiloBaranda(vuelta)
        elegido = e and e.id
    elseif (cosa.id == 'secreto' or cosa.id == 'trampilla') and Config.Secretos then
        local tipo = cosa.id == 'secreto' and 'borde' or 'suelo'
        for _, e in ipairs(Config.Secretos.estilos[tipo] or {}) do
            if Config.Secretos.Disponible(e) then
                local grupo = cosa.id == 'secreto' and 'secretos' or 'trampillas'
                -- (lo que la casa no tiene sale avisado: el servidor no deja ponerlo)
                local cerrado = PacksCliente and PacksCliente.EstiloCerrado(grupo, e.id)
                lista[#lista + 1] = { id = e.id, nombre = cerrado and (e.nombre .. ' · con pack') or e.nombre, img = ImagenEstilo(grupo, e.id) }
            end
        end
        local e = Config.Secretos.Toca(tipo, vuelta)
        elegido = e and e.id
    elseif cosa.id == 'esquina' then
        lista, de, elegido = Esquinas.Variantes(vuelta)
    elseif cosa.id == 'caracol' then
        lista, de, elegido = { { id = 0, nombre = 'Compacta' }, { id = 1, nombre = 'Amplia' } }, 'Forma', vuelta % 2
    elseif cosa.id == 'subeL' or cosa.id == 'bajaL' then
        lista, de, elegido = { { id = 0, nombre = 'Tuerce a la derecha' }, { id = 1, nombre = 'Tuerce a la izquierda' } }, 'Mano', vuelta % 2
    elseif cosa.id == 'garaje' or cosa.id == 'puerta2' then
        lista, de, elegido = { { id = 0, nombre = 'Hacia este lado' }, { id = 1, nombre = 'Hacia el otro' } }, 'Lado', vuelta % 2
    end
    if #lista < 2 then return nil end
    local r = {}
    for q, v in ipairs(lista) do r[q] = { nombre = v.nombre, img = v.img, on = v.id == elegido } end
    return r, de
end

-- La ficha de ayuda (H) de lo que se lleva
local function Ayuda(cosa)
    local T = Config.Cinta
    local clave = 'nada'
    if cosa then
        clave = cosa.tipo == 'm' and 'm' or cosa.tipo == 'f' and (cosa.puerta and 'f:puerta' or 'f') or ('h:' .. tostring(cosa.id))
    end
    return { titulo = cosa and cosa.nombre or 'La cinta', lineas = T.ayuda[clave] or T.ayuda[cosa and cosa.tipo or 'nada'] or {}, teclas = T.chuleta }
end

RegisterNUICallback('cintaBusca', function(data, cb)
    cb({})
    if not BUSCA.activo then return end
    BUSCA.texto, BUSCA.cambio, BUSCA.visto = tostring(data and data.texto or ''):sub(1, 80), true, GetGameTimer()
end)

RegisterNUICallback('cintaBuscaFin', function(data, cb)
    cb({})
    if BUSCA.activo then BUSCA.fin = (data and data.ok) and 'ok' or 'no' end
end)

-- ── El modo ─────────────────────────────────────────────────────────────
local VENTANA = 7       -- cosas a cada lado de la elegida que se ven en la cinta
local abierta = false
local fantasmaVivo = nil -- lo que se lleva en la mano, en transparente (para quitarlo si se para el recurso)

local function Pintar(cats, nc, ni, cosa, teclas, extra)
    local cat = cats[nc]
    extra = extra or {}
    -- los subgrupos del grupo y en cuál cae la cosa elegida
    local subs, sub = {}, 0
    for q, x in ipairs(cat.subs or {}) do
        subs[q] = { nombre = x.nombre, n = x.n }
        if ni >= x.desde and ni < x.desde + x.n then sub = q end
    end
    local variantes, variantesDe = Variantes(cosa, extra.vuelta or 0)
    -- La cinta da la vuelta: a la izquierda de la primera está la última. Así
    -- la elegida queda siempre en el centro con cosas a los dos lados. Si la
    -- categoría tiene menos de las que caben, sale cada una una sola vez.
    local vista, n = {}, #cat.cosas
    local izq = math.min(VENTANA, math.floor(math.max(0, n - 1) / 2))
    local der = math.min(VENTANA, math.max(0, n - 1) - izq)
    for q = -VENTANA, VENTANA do
        local c = n > 0 and q >= -izq and q <= der and cat.cosas[(ni - 1 + q) % n + 1] or nil
        -- (candado: el nombre del pack que le falta a la casa para poder ponerlo, custom/client/packs.lua)
        vista[#vista + 1] = c and { img = c.img, icono = c.icono, precio = c.precio, nombre = c.nombre, on = q == 0, candado = PacksCliente and PacksCliente.Bloqueada(c) or nil } or { hueco = true }
    end
    local nombres = {}
    for q, x in ipairs(cats) do nombres[q] = { nombre = x.nombre, icono = x.icono } end
    local fav = false
    if cosa then
        for _, clave in ipairs(MEMORIA.favoritos) do
            if clave == cosa.clave then fav = true end
        end
    end
    SendNUIMessage({ action = 'cinta', ver = true, categorias = nombres, categoria = nc, cosas = vista,
        nombre = cosa and cosa.nombre or (cat.viva and 'Aquí saldrá lo que vayas usando' or '—'), precio = cosa and cosa.precio, favorito = fav,
        cuenta = #cat.cosas > 0 and (ni .. ' / ' .. #cat.cosas) or '', teclas = teclas, gastado = gastado,
        subs = subs, sub = sub, pista = cat.pista, variantes = variantes, variantesDe = variantesDe,
        ayuda = extra.ayuda and Ayuda(cosa) or nil,
        -- (13/10) la ficha de la izquierda dice siempre qué hace lo que se lleva: el primer renglón de su ayuda
        desc = cosa and (Ayuda(cosa).lineas or {})[1] or nil,
        busca = cat.busca and { activo = BUSCA.activo, texto = BUSCA.texto, n = #cat.cosas } or nil })
end

-- Solo lo que vale para lo que se lleva en la mano y siempre en el mismo
-- orden: pasar · poner · variantes · quitar · lo que se mira · varios · salir
-- (la chuleta entera está en config/cinta.lua y sale con la H). Q y E, las
-- flechas de subgrupo, Intro y la H ya van dibujadas en la propia cinta; el
-- salto de diez (↑ ↓) y el cuentagotas (clic central) solo salen en la chuleta:
-- valen siempre igual y aquí la fila no daba para todo sin encogerse.
local function Teclas(cosa, total)
    local t = { { key = 'Rueda', text = 'Pasar' } }
    if cosa then
        if cosa.tipo == 'f' then
            t[#t + 1] = { key = 'Clic', text = 'Posicionar' }
            t[#t + 1] = { key = 'Mayús + Clic', text = 'Colocar ya' }
            t[#t + 1] = { key = 'R', text = 'Modo' }
            t[#t + 1] = { key = 'Mayús + Rueda', text = 'Girar' }
            t[#t + 1] = { key = 'Alt', text = 'Sin imán' }
        elseif cosa.tipo == 'm' then
            t[#t + 1] = { key = 'Clic', text = 'Pintar' }
            t[#t + 1] = { key = 'Mayús + Clic', text = 'Toda la sala' }
        else
            local h = HERRAMIENTAS[cosa.id]
            t[#t + 1] = { key = 'Clic', text = h.poner or 'Poner' }
            if h.gira then t[#t + 1] = { key = 'R', text = h.gira } end
            if h.frente then t[#t + 1] = { key = 'Mayús + Rueda', text = h.frente } end
            if cosa.id == 'garaje' or cosa.id == 'puerta2' then t[#t + 1] = { key = 'R', text = 'Al otro lado' } end
        end
    end
    t[#t + 1] = { key = 'Clic dcho', text = (cosa and cosa.id == 'cavar') and 'Rellenar' or 'Quitar' }
    -- mover es cosa de muebles: con una herramienta o un material en la mano no se anuncia (aunque sigue valiendo)
    if not cosa or cosa.tipo == 'f' then t[#t + 1] = { key = 'G', text = 'Mover' } end
    if cosa then t[#t + 1] = { key = 'F', text = 'Favorito' } end
    -- deshacer es solo de la obra: con un mueble en la mano no se anuncia
    if Obra.Dentro() and (not cosa or cosa.tipo ~= 'f') then t[#t + 1] = { key = 'Z', text = 'Deshacer' } end
    t[#t + 1] = { key = 'Retroceso', text = 'Salir' }
    return t
end

-- Dónde y cómo quedaría un mueble según lo que se mira. Con la mira sola no
-- había forma de dejarlo donde uno quería, así que el mueble se ayuda solo:
--   · sale ya cuadrado con las paredes de la casa (y gira de 15 en 15);
--   · mirando a una pared se pega de espaldas a ella, y si es de los que van
--     de pie baja al suelo;
--   · en el suelo, si le queda cerca una pared u otro mueble, se arrima hasta
--     tocarlo (así se ponen dos estanterías lado con lado o un sofá contra
--     la pared sin afinar a mano).
-- Con Alt pulsado va libre, sin nada de eso.
local IMAN = 0.35       -- a menos de esto de algo, se arrima

local function Choque(desde, hasta)
    local h = StartExpensiveSynchronousShapeTestLosProbe(desde.x, desde.y, desde.z, hasta.x, hasta.y, hasta.z, 1 + 16, PlayerPedId(), 4)
    local _, toca, pos = GetShapeTestResult(h)
    if toca == 1 then return pos end
end

-- Una puerta, encajada en el hueco de puerta o de garaje que se mira: centrada
-- en el hueco, a ras de suelo y en el plano de la pared. Un hueco no tiene nada
-- que tocar con la mirada, así que se busca el que la mirada atraviesa (o roza).
-- Cada muesca de Mayús + rueda le da la vuelta (abre hacia el otro lado).
local function Encajar(o, modelo, m, giro)
    if not o or not m.cam then return end
    local mejor, cuanto
    for clave, valor in pairs(o.piezas) do
        if valor == 'u' or valor == 'g' or valor == 'd' then
            local _, centro, rumbo = Colocacion(o, clave, valor)
            local ancho, alto = valor == 'g' and 3.02 or valor == 'd' and 2.62 or 1.32, valor == 'g' and 2.51 or 2.31
            local medio = centro + vector3(0.0, 0.0, alto / 2)
            -- el punto de la mirada más cercano al centro del hueco
            local t = (medio - m.cam).x * m.dir.x + (medio - m.cam).y * m.dir.y + (medio - m.cam).z * m.dir.z
            if t > 0.3 and t < 9.0 then
                local d = #(m.cam + m.dir * t - medio)
                if d < math.max(ancho, alto) / 2 + 0.25 and (not cuanto or d < cuanto) then
                    mejor, cuanto = { centro = centro, rumbo = rumbo, doble = valor == 'd', toca = m.cam + m.dir * t }, d
                end
            end
        end
    end
    if not mejor then return end
    local min, max = GetModelDimensions(modelo)
    local rumbo = mejor.rumbo
    local otraHoja = false
    if mejor.doble then
        -- hueco doble: cada hoja en su mitad (la del lado que se mira), y la una
        -- vuelta respecto a la otra, para que las bisagras queden hacia fuera
        local a = math.rad(rumbo)
        local largo = vector3(math.cos(a), math.sin(a), 0.0)
        local lado = (mejor.toca - mejor.centro).x * largo.x + (mejor.toca - mejor.centro).y * largo.y
        otraHoja = lado < 0
        mejor.centro = mejor.centro + largo * (otraHoja and -0.655 or 0.655)
    end
    -- de cara a quien la pone; cada muesca de giro la voltea
    local r = math.rad(rumbo)
    local frente = vector3(-math.sin(r), math.cos(r), 0.0)
    local haciaMi = (m.cam - mejor.centro).x * frente.x + (m.cam - mejor.centro).y * frente.y
    if haciaMi > 0 then rumbo = rumbo + 180.0 end
    if math.floor(giro / 15.0 + 0.5) % 2 == 1 then rumbo = rumbo + 180.0 end
    if otraHoja then rumbo = rumbo + 180.0 end
    r = math.rad(rumbo)
    local cx, cy = (min.x + max.x) / 2, (min.y + max.y) / 2
    local pos = vector3(mejor.centro.x - (cx * math.cos(r) - cy * math.sin(r)), mejor.centro.y - (cx * math.sin(r) + cy * math.cos(r)),
        mejor.centro.z - min.z + 0.005)
    return pos, rumbo % 360.0
end

local function Posar(modelo, m, giro, eje, libre)
    local min, max = GetModelDimensions(modelo)
    local p, n = m.pos, m.normal
    local dePie = math.abs(min.z) < 0.06        -- tiene el origen en la base: va apoyado en el suelo

    if not m.aire and n.z < -0.6 then
        -- colgado del techo
        return vector3(p.x, p.y, p.z - max.z - 0.005), m.rumbo + 180.0 + giro
    elseif not m.aire and n.z <= 0.6 then
        -- en una pared: la espalda del mueble (su -Y) contra ella, mirando a la sala
        local rumbo = math.deg(math.atan(n.y, n.x)) - 90.0 + giro
        local fuera = math.max(0.01, -min.y) + 0.01
        local pos = vector3(p.x + n.x * fuera, p.y + n.y * fuera, p.z)
        if dePie and not libre then
            local suelo = Choque(pos + vector3(0.0, 0.0, 0.2), pos - vector3(0.0, 0.0, 6.0))
            if suelo then pos = vector3(pos.x, pos.y, suelo.z - min.z + 0.005) end
        end
        return pos, rumbo
    end

    -- en el suelo (o al aire)
    local hacia = m.rumbo + 180.0
    if not libre then hacia = eje + math.floor((hacia - eje) / 90.0 + 0.5) * 90.0 end
    local rumbo = hacia + giro
    local pos = vector3(p.x, p.y, p.z - min.z + 0.005)
    if libre or m.aire then return pos, rumbo end

    -- los imanes: hacia atrás, hacia delante y a los lados
    local r = math.rad(rumbo)
    local X, Y = vector3(math.cos(r), math.sin(r), 0.0), vector3(-math.sin(r), math.cos(r), 0.0)
    local alto = vector3(0.0, 0.0, math.max(0.25, (max.z - min.z) * 0.5))
    for _, lado in ipairs({ { Y * -1.0, -min.y }, { Y, max.y }, { X * -1.0, -min.x }, { X, max.x } }) do
        local dir, medio = lado[1], math.max(0.02, lado[2])
        local centro = pos + alto
        local toca = Choque(centro, centro + dir * (medio + IMAN))
        if toca then
            local hueco = #(toca - centro) - medio
            pos = pos + dir * (hueco - 0.01)
        end
    end
    return pos, rumbo
end

-- Con la cinta abierta solo se ve la cinta: fuera el HUD (comida, agua…), el
-- rastreador de misiones y el minimapa, como hacen los demás menús del servidor.
local function HudFuera(fuera)
    TriggerEvent('qv2:suppressHud', fuera)
    pcall(function() exports.origen_hud:toggleHud(not fuera) end)
    -- El minimapa es de origen_map y es su propia pantalla: toggleHud no lo
    -- alcanza. `Apartar` gana a quien lo pida a la vista y se limpia solo si
    -- este recurso se para.
    if GetResourceState('origen_map') == 'started' then
        pcall(function() exports.origen_map:Apartar(fuera) end)
    end
end

-- El borde de la cara que se mira, cuando forma parte de un paño (de una cara
-- suelta se marca el objeto). Cuatro rayas, despegadas un par de centímetros
-- hacia el lado desde el que se ve.
local function Recuadro(o, m)
    local t, i, j, k = Partes(m.pieza)
    if not t then return end
    if t == 'r' or t == 'v' then return Esquinas.Recuadro(o, m.pieza) end
    local h, n = C.celda / 2, 0.02
    local cx, cy = i * C.celda, j * C.celda + h
    local p
    if t == 'x' or t == 'y' then
        local alto = C.planta - 0.15
        local function P(x, y, z) return AMundo(o, x, y, k) + vector3(0.0, 0.0, z) end
        if t == 'x' then
            local x = cx + h + ((m.a and m.a[1] > i) and 0.05 + n or -0.05 - n)
            p = { P(x, cy - h, 0.02), P(x, cy + h, 0.02), P(x, cy + h, alto), P(x, cy - h, alto) }
        else
            local y = cy + h + ((m.a and m.a[2] > j) and 0.05 + n or -0.05 - n)
            p = { P(cx - h, y, 0.02), P(cx + h, y, 0.02), P(cx + h, y, alto), P(cx - h, y, alto) }
        end
    else
        -- arriba de la losa (un suelo) o por debajo (un techo, o un suelo entre plantas visto desde abajo)
        local L = t == 't' and k + 1 or k
        local debajo = t == 't' or (t == 'l' and m.a and m.a[3] < k)
        local z = debajo and -0.15 - n or n
        local function P(x, y) return AMundo(o, x, y, L) + vector3(0.0, 0.0, z) end
        p = { P(cx - h, cy - h), P(cx + h, cy - h), P(cx + h, cy + h), P(cx - h, cy + h) }
    end
    local r, g, b = 216, 27, 85
    if OrigenMarcaColor then r, g, b = OrigenMarcaColor(r, g, b) end
    -- relleno translúcido (por las dos caras) y borde: se ve aunque la casa esté a oscuras
    DrawPoly(p[1].x, p[1].y, p[1].z, p[2].x, p[2].y, p[2].z, p[3].x, p[3].y, p[3].z, r, g, b, 70)
    DrawPoly(p[1].x, p[1].y, p[1].z, p[3].x, p[3].y, p[3].z, p[4].x, p[4].y, p[4].z, r, g, b, 70)
    DrawPoly(p[3].x, p[3].y, p[3].z, p[2].x, p[2].y, p[2].z, p[1].x, p[1].y, p[1].z, r, g, b, 70)
    DrawPoly(p[4].x, p[4].y, p[4].z, p[3].x, p[3].y, p[3].z, p[1].x, p[1].y, p[1].z, r, g, b, 70)
    for q = 1, 4 do
        local a, c = p[q], p[q % 4 + 1]
        DrawLine(a.x, a.y, a.z, c.x, c.y, c.z, r, g, b, 255)
    end
end

-- La caja de un mueble que se mira, en rayas: el contorno del juego
-- (SetEntityDrawOutline) depende de los ajustes gráficos y a algunos no les sale.
local function CajaDe(ent)
    if not ent or not DoesEntityExist(ent) then return end
    local min, max = GetModelDimensions(GetEntityModel(ent))
    local v = {}
    for n = 0, 7 do
        v[n] = GetOffsetFromEntityInWorldCoords(ent, n % 2 == 0 and min.x or max.x, math.floor(n / 2) % 2 == 0 and min.y or max.y, n < 4 and min.z or max.z)
    end
    local r, g, b = 216, 27, 85
    if OrigenMarcaColor then r, g, b = OrigenMarcaColor(r, g, b) end
    for _, l in ipairs({ { 0, 1 }, { 1, 3 }, { 3, 2 }, { 2, 0 }, { 4, 5 }, { 5, 7 }, { 7, 6 }, { 6, 4 }, { 0, 4 }, { 1, 5 }, { 2, 6 }, { 3, 7 } }) do
        local a, c = v[l[1]], v[l[2]]
        DrawLine(a.x, a.y, a.z, c.x, c.y, c.z, r, g, b, 255)
    end
end

-- ¿Carga ya este jugador el máximo de objetos? (se cuenta como mucho una vez por segundo)
local llenoVisto, llenoEs = 0, false
local function Lleno()
    local ahora = GetGameTimer()
    if ahora - llenoVisto > 1000 then
        llenoVisto = ahora
        llenoEs = #GetGamePool('CObject') >= (C.maxObjetos or 2000)
    end
    return llenoEs
end

local function Cinta(house, o, claveInicial)
    abierta, construyendo = true, true
    HudFuera(true)
    local casa, ancla = house.id, house.houseData.shell.entity
    -- qué tiene esta casa (packs y tamaño): se le pide al servidor antes de montar las categorías
    if PacksCliente then PacksCliente.AlAbrir(casa) end
    local cats = Categorias(o ~= nil)
    local nc, ni = (o and 3 or 1), 1
    if #cats[nc].cosas == 0 then nc = (o and 3 or 3) end
    local vuelta, giro, frente = 0, 0.0, 0
    local fantasma, modeloFantasma, marcada
    local ultimoPintado, ocupado = 0, false
    local anunciado = ''

    -- ir a una cosa concreta (la que se pide al abrir, o la del cuentagotas)
    local function IrA(clave)
        for qc = 3, #cats do
            for qi, c in ipairs(cats[qc].cosas) do
                if c.clave == clave then nc, ni = qc, qi return true end
            end
        end
        return false
    end
    -- sin nada pedido, se vuelve a lo último que se llevó en la mano
    if claveInicial then IrA(claveInicial) elseif ULTIMA[0] then IrA(ULTIMA[0]) end
    local conAyuda = false                  -- la ficha de ayuda (H), desplegada
    local antesNc, antesNi = nc, ni         -- dónde se estaba al empezar a buscar (Esc vuelve ahí)
    local callarHasta = 0                   -- tras buscar, un instante sin leer Intro ni Retroceso (son las teclas con las que se acaba)
    local cuadro = GetGameTimer()           -- cuándo corrió el bucle por última vez

    local function Refrescar()
        local cat = cats[nc]
        if cat.viva then cat.cosas = DeLista(MEMORIA[cat.viva], o ~= nil) end
        ni = math.max(1, math.min(ni, math.max(1, #cat.cosas)))
        local cosa = cat.cosas[ni]
        if cosa and not cat.busca then ULTIMA[cat.nombre], ULTIMA[0] = cosa.clave, cosa.clave end
        Pintar(cats, nc, ni, cosa, Teclas(cosa, #cat.cosas), { vuelta = vuelta, ayuda = conAyuda })
        return cosa
    end

    -- en qué cosa cae uno al entrar en un grupo: la última que se llevó de él
    local function Recordada(cat)
        local clave = ULTIMA[cat.nombre]
        if clave then
            for q, c in ipairs(cat.cosas) do
                if c.clave == clave then return q end
            end
        end
        return 1
    end

    -- la primera cosa del subgrupo siguiente (o del anterior), dando la vuelta
    local function OtroSub(cat, hacia)
        local subs = cat.subs or {}
        if #subs < 2 then return ni end
        local q = 1
        for n, x in ipairs(subs) do
            if ni >= x.desde and ni < x.desde + x.n then q = n end
        end
        return subs[(q - 1 + hacia) % #subs + 1].desde
    end

    local function AcabarBusqueda(aceptar)
        BUSCA.activo, BUSCA.fin, BUSCA.cambio = false, nil, false
        SetNuiFocus(false, false)
        callarHasta = GetGameTimer() + 350
        if not (aceptar and #cats[#cats].cosas > 0) then nc, ni = antesNc, antesNi end
    end
    local cosa = Refrescar()

    local function SoltarFantasma()
        if fantasma and DoesEntityExist(fantasma) then DeleteEntity(fantasma) end
        fantasma, modeloFantasma = nil, nil
    end

    local function Modo(texto)
        exports.origen_notify:Notify({ title = 'Decorar', description = 'Modo: ' .. texto, type = 'info', duration = 2200 })
    end

    -- Mientras se coloca un mueble (desde el primer clic o la primera R hasta
    -- que se pone o se cancela) la cinta está apartada, también en el modo
    -- «con la mira»: solo queda la barra pequeña de teclas.
    local colocando = false
    local function BarraPequena(si)
        if not si then return Nui.ControlsNotify() end
        Nui.ControlsNotify({ title = 'Decorar', keys = {
            { key = 'R', text = 'Modo: mira · mover · girar' },
            { key = 'RUEDA', text = 'Girar' },
            { key = 'ALT', text = 'Sin imán' },
            { key = 'enter', text = 'Colocar' },
            { key = 'ESC', text = 'Cancelar' },
        } })
    end

    -- Durante el ajuste (las flechas de mover y los aros de girar) el ratón es
    -- del ajuste, pero el personaje no se queda clavado: se anda con WASD y,
    -- manteniendo el clic derecho, el ratón mueve la cámara. Así se rodea el
    -- mueble para verlo desde donde haga falta sin salir del modo.
    local function AndarMientras()
        CreateThread(function()
            Wait(200)
            if not Gizmo.enabled then return end
            SetNuiFocusKeepInput(true)
            while Gizmo.enabled do
                local mirando = IsDisabledControlPressed(0, 25)
                for _, c in ipairs({ 14, 15, 16, 17, 23, 24, 25, 37, 44, 45, 47, 73, 140, 141, 142, 199, 200, 257, 263, 264 }) do
                    DisableControlAction(0, c, true)
                end
                if not mirando then
                    DisableControlAction(0, 1, true)
                    DisableControlAction(0, 2, true)
                end
                Wait(0)
            end
            SetNuiFocusKeepInput(false)
        end)
    end

    -- Mueve un mueble que ya está puesto (lo que antes se hacía desde
    -- «Comprados» en el menú de decorar): el mismo ajuste de mover y girar, y
    -- al acabar se guarda su sitio nuevo. Cancelar lo devuelve a donde estaba.
    local function Mover(ent, id)
        if ocupado or not ent or not DoesEntityExist(ent) then return end
        ocupado = true
        SendNUIMessage({ action = 'cinta', ver = false })
        if marcada and DoesEntityExist(marcada) then SetEntityDrawOutline(marcada, false) end
        marcada = nil
        local p0, r0 = GetEntityCoords(ent), GetEntityRotation(ent)
        Modo('mover')
        local cancelar = Furniture.CancelEdit
        Furniture.CancelEdit = function() end
        Gizmo.alCambiarModo = function(modo) Modo(modo == 'rotate' and 'girar' or 'mover') end
        while IsControlPressed(0, 47) or IsDisabledControlPressed(0, 47) do
            DisableControlAction(0, 47, true)
            Wait(0)
        end
        SetTimeout(120, function()
            if Gizmo.enabled and DoesEntityExist(ent) then
                Gizmo.mode = 'translate'
                SendNUIMessage({ action = 'setGizmoEntity', data = { handle = ent, mode = 'translate',
                    position = GetEntityCoords(ent), rotation = GetEntityRotation(ent) } })
                Nui.ControlsNotify({ title = 'Decorar', keys = {
                    { key = 'R', text = 'Modo: mover · girar' },
                    { key = 'WASD', text = 'Andar' },
                    { key = 'CLIC DCHO', text = 'Mirar' },
                    { key = 'ALT', text = 'Al suelo' },
                    { key = 'enter', text = 'Guardar' },
                    { key = 'ESC', text = 'Cancelar' },
                } })
            end
        end)
        AndarMientras()
        local fin = Gizmo:StartGizmo(ent)
        Gizmo.alCambiarModo = nil
        Furniture.CancelEdit = cancelar
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        if DoesEntityExist(ent) then
            local guardado = false
            if fin then
                local p, r = GetEntityCoords(ent), GetEntityRotation(ent)
                guardado = lib.callback.await('origen_housing:server:UpdateFurniture', false, {
                    houseID = casa, zone = 'interior', id = id,
                    objectData = { position = GetOffsetFromEntityGivenWorldCoords(ancla, p.x, p.y, p.z), rotation = r },
                })
            end
            if not guardado and DoesEntityExist(ent) then
                SetEntityCoordsNoOffset(ent, p0.x, p0.y, p0.z, false, false, false)
                SetEntityRotation(ent, r0.x, r0.y, r0.z, 2, true)
            end
        end
        BarraPequena(false)
        if abierta then cosa = Refrescar() end
        SetTimeout(250, function() ocupado = false end)
    end

    -- Compra el mueble que se lleva en la mano. Con `ajustar`, antes pasa por
    -- el posicionamiento del housing (las flechas de mover y girar), con la
    -- cinta apartada. La R va dando la vuelta a los modos: con la mira →
    -- mover → girar → con la mira.
    local function Colocar(ajustar)
        if ocupado or not fantasma or not cosa or cosa.tipo ~= 'f' then return end
        ocupado = true
        local c = cosa
        local p, r = GetEntityCoords(fantasma), GetEntityRotation(fantasma)
        local comprar, aLaMira = true, false
        if ajustar then
            SendNUIMessage({ action = 'cinta', ver = false })
            if marcada and DoesEntityExist(marcada) then SetEntityDrawOutline(marcada, false) end
            marcada = nil
            Modo('mover')
            -- cancelar el ajuste devuelve a la cinta, no al menú Decorar
            local cancelar = Furniture.CancelEdit
            Furniture.CancelEdit = function() end
            Gizmo.alCambiarModo = function(modo)
                if modo == 'rotate' then
                    Modo('girar')
                else
                    -- tercera R: se suelta el ajuste y el mueble vuelve a ir con la mira
                    aLaMira = true
                    Modo('con la mira')
                    Gizmo:DeleteGizmo()
                end
            end
            -- las teclas de este ajuste, en vez de las del menú de siempre
            SetTimeout(150, function()
                if Gizmo.enabled then
                    Nui.ControlsNotify({ title = 'Decorar', keys = {
                        { key = 'R', text = 'Modo: mover · girar · mira' },
                        { key = 'WASD', text = 'Andar' },
                        { key = 'CLIC DCHO', text = 'Mirar' },
                        { key = 'ALT', text = 'Al suelo' },
                        { key = 'enter', text = 'Colocar' },
                        { key = 'ESC', text = 'Cancelar' },
                    } })
                end
            end)
            -- La R que abre el ajuste no puede llegarle a la página (la tomaría
            -- por un cambio de modo y se saltaría «mover»): se espera a soltarla.
            while IsControlPressed(0, 45) or IsDisabledControlPressed(0, 45) do
                DisableControlAction(0, 45, true)
                Wait(0)
            end
            -- …y el ajuste empieza siempre en «mover», acabara como acabara el anterior
            SetTimeout(120, function()
                if Gizmo.enabled and fantasma and DoesEntityExist(fantasma) then
                    Gizmo.mode = 'translate'
                    SendNUIMessage({ action = 'setGizmoEntity', data = { handle = fantasma, mode = 'translate',
                        position = GetEntityCoords(fantasma), rotation = GetEntityRotation(fantasma) } })
                end
            end)
            AndarMientras()
            local fin = Gizmo:StartGizmo(fantasma)
            Gizmo.alCambiarModo = nil
            Furniture.CancelEdit = cancelar
            SetNuiFocus(false, false)
            SetNuiFocusKeepInput(false)
            if fin and not aLaMira and fantasma and DoesEntityExist(fantasma) then
                p, r = GetEntityCoords(fantasma), GetEntityRotation(fantasma)
            else
                comprar = false
            end
        end
        if comprar then
            -- la compra es la de siempre: el servidor cobra, guarda y lo pone para todos
            local ok = lib.callback.await('origen_housing:server:BuyFurniture', false, {
                houseID = casa, zone = 'interior', id = tostring(math.random(100000, 999999) .. casa),
                objectData = { model = c.modelo, position = GetOffsetFromEntityGivenWorldCoords(ancla, p.x, p.y, p.z), rotation = r },
            })
            if ok == true then
                gastado = gastado + c.precio
                Usada(c.clave)
            end
        end
        if not comprar and ajustar and aLaMira then
            -- tercera R: el mueble vuelve a ir con la mira, con la barra pequeña
            colocando = true
            BarraPequena(true)
        else
            -- puesto o cancelado: vuelve la cinta
            colocando = false
            BarraPequena(false)
            if abierta then cosa = Refrescar() end
        end
        SetTimeout(250, function() ocupado = false end)
    end

    while abierta and currentInteriorHouseID == casa do
        Wait(0)
        -- muerto o inconsciente no se decora: la cinta se cierra sola (tenía las teclas cogidas hasta salir de la casa)
        if IsEntityDead(PlayerPedId()) or LocalPlayer.state.isDead == true or LocalPlayer.state.inLastStand == true then break end
        for _, c in ipairs({ 14, 15, 16, 17, 23, 24, 25, 37, 38, 44, 45, 47, 73, 140, 141, 142, 257, 348 }) do DisableControlAction(0, c, true) end

        -- ── moverse por la cinta ──
        local cambia = false
        local total = #cats[nc].cosas
        if colocando then
            -- a medio colocar: la rueda gira (con Mayúsculas, fino) y nada más
            DisableControlAction(0, 200, true)      -- Esc cancela, no abre el menú de pausa
            local paso = IsControlPressed(0, 21) and 5.0 or 15.0
            if IsDisabledControlJustPressed(0, 14) then giro = (giro + paso) % 360.0 end
            if IsDisabledControlJustPressed(0, 15) then giro = (giro - paso) % 360.0 end
        elseif BUSCA.activo then
            -- escribiendo en el buscador: el teclado es de la página (ver más abajo)
        elseif IsDisabledControlJustPressed(0, 38) then
            nc = nc % #cats + 1
            ni, cambia = Recordada(cats[nc]), true
        elseif IsDisabledControlJustPressed(0, 44) then
            nc = (nc - 2) % #cats + 1
            ni, cambia = Recordada(cats[nc]), true
        elseif IsDisabledControlJustPressed(0, 175) then
            -- flechas: al subgrupo siguiente o al anterior
            ni, cambia = OtroSub(cats[nc], 1), true
        elseif IsDisabledControlJustPressed(0, 174) then
            ni, cambia = OtroSub(cats[nc], -1), true
        elseif total > 0 and (IsDisabledControlJustPressed(0, 173) or IsDisabledControlJustPressed(0, 11)) then
            -- abajo o Av Pág: diez más allá (y del final, al principio)
            ni, cambia = ni >= total and 1 or math.min(total, ni + (Config.Cinta.salto or 10)), true
        elseif total > 0 and (IsDisabledControlJustPressed(0, 172) or IsDisabledControlJustPressed(0, 10)) then
            ni, cambia = ni <= 1 and total or math.max(1, ni - (Config.Cinta.salto or 10)), true
        elseif cosa and (cosa.id == 'ascensor2' or cosa.id == 'secreto' or cosa.id == 'escala' or cosa.id == 'caracol') and IsControlPressed(0, 21) then
            -- con Mayúsculas la rueda cambia hacia dónde mira el frente de la cabina
            if IsDisabledControlJustPressed(0, 14) then frente = (frente + 1) % 4 end
            if IsDisabledControlJustPressed(0, 15) then frente = (frente - 1) % 4 end
        elseif cosa and cosa.tipo == 'f' and IsControlPressed(0, 21) then
            -- con Mayúsculas la rueda gira el mueble que se lleva
            if IsDisabledControlJustPressed(0, 14) then giro = (giro + 15.0) % 360.0 end
            if IsDisabledControlJustPressed(0, 15) then giro = (giro - 15.0) % 360.0 end
        elseif total > 0 then
            if IsDisabledControlJustPressed(0, 14) then ni, cambia = ni % total + 1, true end
            if IsDisabledControlJustPressed(0, 15) then ni, cambia = (ni - 2) % total + 1, true end
        end
        if cambia then
            vuelta, giro, frente = 0, 0.0, 0
            cosa = Refrescar()
        end
        local ajustar = false
        if IsDisabledControlJustPressed(0, 45) then
            -- con un mueble, la R cambia de modo (y el primero tras la mira es mover)
            if cosa and cosa.tipo == 'f' then
                ajustar = true
            else
                vuelta = vuelta + 1
                if cosa then Refrescar() end        -- la tira de variantes marca la que toca
            end
        end
        -- flechas, Re Pág / Av Pág y la H son de la cinta mientras está abierta
        for _, c in ipairs({ 10, 11, 74, 172, 173, 174, 175 }) do DisableControlAction(0, c, true) end
        -- H: la ficha de ayuda de lo que se lleva
        if IsDisabledControlJustPressed(0, 74) and not colocando and not BUSCA.activo then
            conAyuda = not conAyuda
            cosa = Refrescar()
        end
        -- ── Intro: buscar por nombre ──
        -- Mientras se escribe, el teclado es de la página (sin ratón) y aquí solo
        -- se recoge lo que manda. Si la página dejara de contestar, a los 40 s se suelta solo.
        -- (lo mismo al volver de cualquier diálogo —el enlace de una imagen, el ajuste
        -- de un mueble—: el Intro o el Retroceso con que se cerró no son para la cinta)
        local ahora = GetGameTimer()
        if (IsNuiFocused() and not BUSCA.activo) or ahora - cuadro > 250 then callarHasta = math.max(callarHasta, ahora + 400) end
        cuadro = ahora
        if GetGameTimer() < callarHasta then
            DisableControlAction(0, 199, true)
            DisableControlAction(0, 200, true)
        elseif not BUSCA.activo and not colocando and not ocupado and (IsControlJustPressed(0, 191) or IsDisabledControlJustPressed(0, 191)) then
            if nc ~= #cats then antesNc, antesNi = nc, ni end      -- (buscando otra vez desde los resultados, Esc sigue volviendo a donde se estaba)
            BUSCA.activo, BUSCA.texto, BUSCA.cambio, BUSCA.fin, BUSCA.visto = true, '', false, nil, GetGameTimer()
            BUSCA.cosas = {}
            cats[#cats].cosas = BUSCA.cosas
            nc, ni = #cats, 1
            vuelta, giro, frente = 0, 0.0, 0
            SetNuiFocus(true, false)
            cosa = Refrescar()
        end
        if BUSCA.activo then
            if BUSCA.cambio then
                BUSCA.cambio = false
                BUSCA.cosas = Buscar(cats, BUSCA.texto)
                cats[#cats].cosas = BUSCA.cosas
                ni = 1
                vuelta, giro, frente = 0, 0.0, 0
                cosa = Refrescar()
            end
            if BUSCA.fin or GetGameTimer() - BUSCA.visto > 40000 then
                AcabarBusqueda(BUSCA.fin == 'ok')
                vuelta, giro, frente = 0, 0.0, 0
                cosa = Refrescar()
            end
        end
        -- F: guardar o quitar de favoritos lo que se lleva en la mano
        if IsDisabledControlJustPressed(0, 23) and cosa and not colocando then
            local t, estaba = MEMORIA.favoritos, false
            for q = #t, 1, -1 do
                if t[q] == cosa.clave then table.remove(t, q) estaba = true end
            end
            if not estaba then table.insert(t, 1, cosa.clave) end
            Recordar('favoritos')
            cosa = Refrescar()
        end

        -- Lo que la casa no tiene (su pack: custom/client/packs.lua) se ve en la
        -- cinta con candado, pero no se lleva en la mano: de aquí al final de la
        -- vuelta es como no llevar nada (se puede seguir quitando y moviendo).
        local cosaConCandado = cosa and PacksCliente and PacksCliente.Bloqueada(cosa) and cosa or nil
        if cosaConCandado then
            if not colocando and IsDisabledControlJustPressed(0, 24) then
                Pista(('Eso es del %s: esta casa no lo tiene'):format(PacksCliente.Bloqueada(cosa)), 'candado', cosa.clave)
            end
            cosa = nil
        end

        local m = Mirada(o, fantasma)
        local puesta = m.pieza and o.piezas[m.pieza] ~= nil      -- la pieza que se mira, ¿la puso el jugador?
        -- la herramienta «Imagen» es de custom/client/imagenes.lua: aquí solo se le pasa la mirada
        local conImagen = cosa and cosa.id == 'imagen' and o and Imagenes
        if conImagen then Imagenes.EnMano(o, m, vuelta) end
        -- lo mismo con «Entrada» y «Entrada de garaje» (custom/client/entradas.lua): van a los pies, no donde se mira
        local conEntrada = cosa and (cosa.id == 'entrada' or cosa.id == 'cochera') and o and Entradas
        if conEntrada then Entradas.EnMano(o, cosa.id) end

        -- ── lo que se pondría, en transparente ──
        local modelo, pos, rumbo, clave, valor
        if cosa and cosa.tipo == 'f' then
            modelo = joaat(cosa.modelo)
            if IsModelInCdimage(modelo) and Cargar(modelo) then
                -- las puertas buscan su hueco (con Alt, libres como cualquier mueble)
                if cosa.puerta and not IsControlPressed(0, 19) then pos, rumbo = Encajar(o, modelo, m, giro) end
                if not pos then pos, rumbo = Posar(modelo, m, giro, GetEntityHeading(ancla), IsControlPressed(0, 19)) end
            else
                modelo = nil
            end
        elseif cosa and cosa.tipo == 'h' and o then
            clave, valor = Objetivo(o, cosa.id, m, vuelta, frente)
            if clave and o.piezas[clave] ~= valor then modelo, pos, rumbo = Colocacion(o, clave, valor) end
            -- de una puerta secreta se enseña su mueble (la pared es la que ya hay, o un tabique más)
            if modelo and cosa.id == 'secreto' and Config.Secretos and Config.Secretos.Mueble then modelo = Config.Secretos.Mueble(clave, valor) or modelo end
            -- una pieza cuyo modelo aún no se sirve (las escaleras en L) ni se enseña ni se pone
            if modelo and clave:sub(1, 1) == 'e' and not IsModelInCdimage(modelo) then modelo, pos, rumbo, clave, valor = nil, nil, nil, nil, nil end
        end
        -- el ascensor que se pondría: cuántas plantas y entre cuáles (cambia con la R)
        if cosa and (cosa.id == 'ascensor' or cosa.id == 'ascensor2' or cosa.id == 'montacoches') then
            -- (sin las centenas: el frente de la cabina cambia al andar alrededor y no se anuncia)
            local firma = clave and (clave .. '=' .. valor % 100) or ''
            if firma ~= anunciado then
                anunciado = firma
                if clave then
                    local _, _, _, base = Partes(clave)
                    local deAscensor = cosa.id ~= 'montacoches'
                    local n = deAscensor and valor % 10 or math.floor(valor / 10)
                    local planta = deAscensor and ({ [0] = '1 celda', '2 celdas', '2 celdas', '4 celdas' })[math.floor(valor / 10) % 10] or '2 por 3 celdas'
                    exports.origen_notify:Notify({ title = HERRAMIENTAS[cosa.id].nombre, type = 'info', duration = 2500,
                        description = ('%s · %d plantas: de %s a %s'):format(planta, n, NombrePlanta(base), NombrePlanta(base + n - 1)) })
                end
            end
        end
        -- la barandilla: qué estilo se lleva (cambia con la R)
        if cosa and cosa.id == 'barandilla' then
            local estilo = EstiloBaranda(vuelta)
            local firma = 'baranda=' .. (estilo and estilo.id or '')
            if firma ~= anunciado then
                anunciado = firma
                if estilo then
                    exports.origen_notify:Notify({ title = HERRAMIENTAS.barandilla.nombre, type = 'info', duration = 2500, description = estilo.nombre })
                end
            end
        end
        -- el paso secreto: qué estilo se lleva (cambia con la R)
        if cosa and (cosa.id == 'secreto' or cosa.id == 'trampilla') and Config.Secretos then
            local estilo = Config.Secretos.Toca(cosa.id == 'secreto' and 'borde' or 'suelo', vuelta)
            local firma = cosa.id .. '=' .. (estilo and estilo.id or '')
            if firma ~= anunciado then
                anunciado = firma
                if estilo then
                    exports.origen_notify:Notify({ title = HERRAMIENTAS[cosa.id].nombre, type = 'info', duration = 2500, description = estilo.nombre })
                end
            end
        end
        if modeloFantasma ~= modelo then
            SoltarFantasma()
            modeloFantasma = modelo
            if modelo and Cargar(modelo) then
                fantasma = CreateObjectNoOffset(modelo, pos.x, pos.y, pos.z, false, false, false)
                fantasmaVivo = fantasma
                SetEntityCollision(fantasma, false, false)
                SetEntityAlpha(fantasma, 170, false)
                FreezeEntityPosition(fantasma, true)
            end
        end
        if fantasma then
            SetEntityCoordsNoOffset(fantasma, pos.x, pos.y, pos.z + (clave and 0.01 or 0.0), false, false, false)
            SetEntityHeading(fantasma, rumbo)
        end

        -- ── lo que se mira, con el borde marcado ──
        -- Con un mueble en la mano solo se marcan (y solo se quitan) muebles.
        -- Las piezas de la casa —también los suelos entre plantas, que cuentan
        -- como puestos a mano— son cosa de Obra y Pintar: marcarlas aquí
        -- hacía creer que el mueble iba a ir a ese cuadro del suelo.
        local deObra = not cosa or cosa.tipo ~= 'f'
        local mirado = m.mueble or (deObra and m.entidad) or nil
        if marcada ~= mirado then
            if marcada and DoesEntityExist(marcada) then SetEntityDrawOutline(marcada, false) end
            marcada = mirado
            if marcada then
                local r, g, b = 216, 27, 85
                if OrigenMarcaColor then r, g, b = OrigenMarcaColor(r, g, b) end
                SetEntityDrawOutlineColor(r, g, b, 255)
                SetEntityDrawOutline(marcada, true)
            end
        end

        if deObra and m.recuadro and m.pieza then Recuadro(o, m) end
        if m.mueble then CajaDe(m.mueble) end
        -- la mira: un punto en el centro de la pantalla, para saber a qué se apunta
        DrawRect(0.5, 0.5, 0.0045, 0.008, 0, 0, 0, 160)
        DrawRect(0.5, 0.5, 0.0027, 0.0048, 255, 255, 255, 235)

        if ajustar then Colocar(true) end

        -- ── clic ──
        local clic = IsDisabledControlJustPressed(0, 24)
        -- con la casa al tope de objetos ya no se pone nada más (pintar y quitar, sí)
        if clic and not colocando and cosa and cosa.tipo ~= 'm' and cosa.id ~= 'imagen' and cosa.id ~= 'entrada' and cosa.id ~= 'cochera' and Lleno() then
            Pista(('La casa ya carga %d objetos, el máximo: quita algo antes de poner más'):format(C.maxObjetos))
            clic = false
        end
        if colocando then
            -- con la barra pequeña: clic o Intro lo pone donde está; Esc lo deja
            if clic or IsControlJustPressed(0, 191) then
                Colocar(false)
            elseif IsControlJustPressed(0, 202) or IsDisabledControlJustPressed(0, 200) then
                colocando = false
                BarraPequena(false)
                cosa = Refrescar()
            end
            clic = false
        end
        if cosa and cosa.tipo == 'm' and o then
            -- se pinta arrastrando: con el clic mantenido, cada cara que se va mirando
            local id = cosa.id
            if m.pieza and C.Baranda(o.piezas[m.pieza]) then
                -- una barandilla no se pinta (ni cuenta como pared de la sala)
                if clic then Pista('Las barandillas no se pintan: su aspecto es su estilo', 'pintar', m.pieza) end
            elseif m.pieza and Config.Secretos and Config.Secretos.ConModelo(m.pieza, o.piezas[m.pieza]) then
                if clic then Pista('Eso no se pinta: su aspecto es su estilo', 'pintar', m.pieza) end
            elseif m.pieza and Esquinas.SinModelo(o, m.pieza, id) then
                -- una esquina redondeada no se hace de cristal, ni de un material cuyas esquinas aún no se sirven
                if clic then Pista('Las esquinas redondeadas no se pueden pintar con ese material', 'pintar', m.pieza) end
            elseif clic and IsControlPressed(0, 21) and m.pieza then
                local caras = {}
                for _, c in ipairs(CarasDeLaSala(o, m)) do
                    if Material(o, c) ~= id and not Esquinas.SinModelo(o, c, id) then caras[#caras + 1] = c end
                end
                if #caras > 0 then TriggerServerEvent('origen_housing:obra:pintar', o.id, caras, id) end
                ultimoPintado = GetGameTimer() + 400
                Usada(cosa.clave)
            elseif IsDisabledControlPressed(0, 24) and not IsControlPressed(0, 21) and m.pieza and m.pieza:sub(1, 1) ~= 'e'
                and Material(o, m.pieza) ~= id and GetGameTimer() - ultimoPintado > 90 then
                ultimoPintado = GetGameTimer()
                TriggerServerEvent('origen_housing:obra:pintar', o.id, m.pieza, id)
                if clic then Usada(cosa.clave) end
            elseif clic and not m.pieza then
                Pista('Mira una pared, un suelo o un techo para pintarlo')
            end
        elseif clic and cosa and cosa.tipo == 'f' then
            if not fantasma then
                Pista('Ese mueble no está disponible ahora mismo')
            elseif not ocupado then
                -- clic: ajustar antes de comprar; con Mayúsculas, tal cual donde se mira
                Colocar(not IsControlPressed(0, 21))
            end
        elseif clic and cosa and cosa.tipo == 'h' and o then
            if cosa.id == 'imagen' then
                if conImagen then Imagenes.Poner(o, m, vuelta) end
            elseif cosa.id == 'entrada' or cosa.id == 'cochera' then
                if conEntrada then Entradas.Poner(o, cosa.id) end
            elseif cosa.id == 'cavar' then
                if not m.pieza then
                    Pista('Mira una pared, un suelo o un techo para excavar', 'cavar')
                elseif puesta and m.pieza:sub(1, 1) == 'l' then
                    -- un suelo entre dos plantas: excavarlo es abrir el hueco
                    TriggerServerEvent('origen_housing:obra:quitar', o.id, m.pieza)
                    Usada(cosa.clave)
                elseif puesta and (m.pieza:sub(1, 1) == 'x' or m.pieza:sub(1, 1) == 'y') then
                    -- una pared entre dos espacios: excavarla es quitarla
                    TriggerServerEvent('origen_housing:obra:quitar', o.id, m.pieza)
                    Usada(cosa.clave)
                elseif puesta then
                    Pista('Eso lo pusiste tú: se quita con clic derecho', 'cavar', m.pieza)
                elseif not m.b or Abierta(o, m.b[1], m.b[2], m.b[3]) then
                    Pista('Detrás de eso ya está abierto', 'cavar', m.pieza)
                else
                    TriggerServerEvent('origen_housing:obra:cavar', o.id, m.b[1], m.b[2], m.b[3], m.a)
                    Usada(cosa.clave)
                end
            elseif clave then
                TriggerServerEvent('origen_housing:obra:poner', o.id, clave, valor)
                Usada(cosa.clave)
            elseif cosa.id == 'ascensor' or cosa.id == 'ascensor2' then
                Pista('El ascensor necesita al menos dos plantas abiertas, una encima de otra, en esa celda', cosa.id, m.pieza)
            elseif cosa.id == 'montacoches' then
                Pista('El montacoches necesita un espacio de 2 por 3 celdas abierto en dos plantas o más', cosa.id, m.pieza)
            elseif cosa.id == 'garaje' or cosa.id == 'puerta2' then
                Pista('Ese hueco ocupa dos celdas de ancho entre dos espacios abiertos: mira el suelo junto a la raya', cosa.id, m.pieza)
            elseif cosa.id == 'pared' or cosa.id == 'puerta' then
                Pista('Las paredes se ponen entre dos espacios abiertos: mira el suelo junto a la raya donde la quieres', cosa.id, m.pieza)
            elseif cosa.id == 'esquina' then
                Pista(Esquinas.Pista(o, m), cosa.id, m.pieza)
            elseif cosa.id == 'barandilla' then
                Pista(EstiloBaranda(0) and 'Las barandillas se ponen entre dos espacios abiertos: mira el suelo junto a la raya donde la quieres'
                    or 'Las barandillas aún no están disponibles', cosa.id, m.pieza)
            elseif cosa.id == 'secreto' then
                Pista('La puerta secreta va entre dos espacios abiertos: mira la pared que quieres cambiar, o el suelo junto a la raya', cosa.id, m.pieza)
            elseif cosa.id == 'trampilla' then
                Pista('La trampilla va en el suelo entre dos plantas: mira ese suelo, o el hueco que quieres tapar', cosa.id, m.pieza)
            elseif cosa.id == 'suelo' then
                Pista('El suelo entre plantas se pone donde hay un hueco entre dos plantas', cosa.id, m.pieza)
            elseif (cosa.id == 'subeL' or cosa.id == 'bajaL') and not (IsModelInCdimage(C.escaleraLD) and IsModelInCdimage(C.escaleraLI)) then
                Pista('La escalera en L aún no está disponible', cosa.id, m.pieza)
            elseif cosa.id == 'escala' then
                Pista(IsModelInCdimage(C.escala) and 'Mira la pared a la que va pegada la escalera de mano, o el suelo junto a ella'
                    or 'La escalera de mano aún no está disponible', cosa.id, m.pieza)
            elseif cosa.id == 'caracol' and not IsModelInCdimage(vuelta % 2 == 1 and C.caracol2 or C.caracol) then
                Pista(vuelta % 2 == 1 and 'La escalera de caracol amplia aún no está disponible: con la R, la compacta'
                    or 'La escalera de caracol compacta aún no está disponible: con la R, la amplia', cosa.id, m.pieza)
            else
                Pista('Mira el suelo donde quieres la escalera', cosa.id, m.pieza)
            end
        elseif clic and not cosa then
            Pista('Elige algo con la rueda, o cambia de categoría con Q y E')
        end

        -- ── clic derecho: quitar lo que se mira ──
        if IsDisabledControlJustPressed(0, 25) and not ocupado and not colocando then
            if m.mueble then
                ocupado = true
                local id = m.id
                CreateThread(function()
                    lib.callback.await('origen_housing:server:DeleteFurniture', false, { houseID = casa, entityID = id, zone = 'interior' })
                    Wait(250)
                    ocupado = false
                end)
            elseif m.celda and HuecoEn(o, m.celda[1], m.celda[2], m.celda[3]) then
                -- mirando la cabina o la plataforma: se quita ese ascensor, con lo que sea en la mano
                TriggerServerEvent('origen_housing:obra:quitar', o.id, HuecoEn(o, m.celda[1], m.celda[2], m.celda[3]))
            elseif cosa and (cosa.id == 'ascensor' or cosa.id == 'ascensor2' or cosa.id == 'montacoches') and m.a and HuecoEn(o, m.a[1], m.a[2], m.a[3]) then
                -- con la herramienta en la mano, el clic derecho quita el ascensor de esa celda
                TriggerServerEvent('origen_housing:obra:quitar', o.id, HuecoEn(o, m.a[1], m.a[2], m.a[3]))
            elseif conImagen then
                -- con la herramienta Imagen en la mano el clic derecho quita la imagen, nunca la pared
                Imagenes.Quitar(o, m)
            elseif puesta and deObra then
                TriggerServerEvent('origen_housing:obra:quitar', o.id, m.pieza)
            elseif cosa and cosa.id == 'cavar' and m.a then
                TriggerServerEvent('origen_housing:obra:rellenar', o.id, m.a[1], m.a[2], m.a[3])
            elseif m.pieza and deObra then
                Pista('Eso es parte de la casa: para abrirlo usa Excavar', 'quitar', m.pieza)
            end
        end

        -- ── G: mover un mueble ya puesto ──
        if not colocando and m.mueble and IsDisabledControlJustPressed(0, 47) then Mover(m.mueble, m.id) end

        -- ── Z: deshacer el último cambio de obra (hasta cinco; los lleva el servidor) ──
        DisableControlAction(0, 20, true)
        if o and not colocando and IsDisabledControlJustPressed(0, 20) then
            TriggerServerEvent('origen_housing:obra:deshacer', o.id)
        end

        -- ── cuentagotas: llevarse en la mano lo que se mira ──
        if not colocando and (IsDisabledControlJustPressed(0, 348) or IsDisabledControlJustPressed(0, 73)) then
            local cogida
            if m.mueble then
                local c = PORMODELO[GetEntityModel(m.mueble)]
                cogida = c and c.clave
            elseif m.pieza and o and C.Baranda(o.piezas[m.pieza]) then
                cogida = 'h:barandilla'      -- de una barandilla, la herramienta (no tiene material)
            elseif m.pieza and o and Config.Secretos and Config.Secretos.ConModelo(m.pieza, o.piezas[m.pieza]) then
                cogida = m.pieza:sub(1, 1) == 'l' and 'h:trampilla' or 'h:secreto'
            elseif m.pieza and o and m.pieza:sub(1, 1) ~= 'e' then
                cogida = 'm:' .. Material(o, m.pieza)
            end
            if cogida and IrA(cogida) then
                vuelta, giro, frente = 0, 0.0, 0
                cosa = Refrescar()
            end
        end

        -- (lo del candado sigue elegido en la cinta para la vuelta siguiente)
        if cosaConCandado and cosa == nil then cosa = cosaConCandado end

        if not colocando and not BUSCA.activo and GetGameTimer() >= callarHasta then
            if IsControlJustPressed(0, 202) then abierta = false end
        end
    end
    BarraPequena(false)
    -- si se cierra a medio buscar (al salir de la casa), el teclado vuelve al juego
    if BUSCA.activo then
        BUSCA.activo, BUSCA.fin = false, nil
        SetNuiFocus(false, false)
    end

    abierta, construyendo = false, false
    if marcada and DoesEntityExist(marcada) then SetEntityDrawOutline(marcada, false) end
    SoltarFantasma()
    SendNUIMessage({ action = 'cinta', ver = false })
    HudFuera(false)
end

-- ── Abrir ───────────────────────────────────────────────────────────────
-- La casa en la que se puede usar la cinta: el interior de una de módulo
-- (también las de modalidad libre) de la que se tiene llave.
local function CasaDeLaCinta()
    if not currentInteriorHouseID then return nil end
    local house = House.get(currentInteriorHouseID)
    if not house or not house.owned or not house.houseData or not house.houseData.data then return nil end
    if house.houseData.data.type ~= 'shell' or not house.houseData.shell or not house.houseData.shell.entity then return nil end
    if not Config.FurnitureEnable.interior or not house:hasKey() then return nil end
    return house
end

--- ¿Está abierta la cinta? (custom/client/luces.lua: decorando, las lámparas apagadas se ven encendidas)
function Obra.CintaAbierta()
    return abierta == true
end

--- Abre (o cierra) la cinta. clave: con qué empezar ('h:cavar', 'm:ladrillo', 'f:<modelo>').
function Obra.Cinta(clave)
    if abierta then
        abierta = false
        return true
    end
    local house = CasaDeLaCinta()
    if not house then return false end
    local o = (actual and actual.id == tostring(house.id)) and actual or nil
    CreateThread(function() Cinta(house, o, clave) end)
    return true
end

RegisterCommand('obra', function()
    if not Obra.Cinta() then Custom.Notify('Se decora desde dentro de tu casa', 'error', 4000) end
end, false)

-- El menú Decorar de siempre (la columna lateral) ya no se abre en estas
-- casas: lo que hacía —comprar, mover, quitar— se hace desde la cinta. Todo
-- lo que lo abría abre la cinta.
CreateThread(function()
    while not Furniture or not Furniture.ToggleMenu do Wait(200) end
    local deSiempre = Furniture.ToggleMenu
    Furniture.ToggleMenu = function(self, state, ...)
        if state and not self.active and CasaDeLaCinta() then
            if not abierta then Obra.Cinta() end
            return
        end
        return deSiempre(self, state, ...)
    end
end)

-- La pestaña Construir del menú Decorar: elegir ahí una herramienta o un
-- material cierra el menú y abre la cinta con eso en la mano.
local alDecorar = Custom.OnStartDecorate
Custom.OnStartDecorate = function(...)
    -- (retirada: se construye solo desde la cinta. El menú de siempre, donde
    -- aún se abre —el exterior de una casa, las que no son de módulo—, no la enseña.)
    SendNUIMessage({ action = 'obraMenu', menu = nil })
    if alDecorar then return alDecorar(...) end
end

RegisterNUICallback('obraHerramienta', function(data, cb)
    cb({})
    if not actual then return end
    Furniture:CloseFurniture()
    local mat = C.materiales[tonumber(data.material) or 0]
    Obra.Cinta(data.herramienta == 'pintar' and mat and ('m:' .. mat.id) or ('h:' .. tostring(data.herramienta)))
end)

-- Al salir de la casa (Shell:Exit llama a Custom.OnExitHouse cuando el jugador
-- ya está en la calle) se cierra la cinta y se desmonta la obra.
local alSalir = Custom.OnExitHouse
Custom.OnExitHouse = function(houseID)
    abierta = false
    Obra.Desmontar()
    if alSalir then return alSalir(houseID) end
end

AddEventHandler('onResourceStop', function(r)
    if r ~= GetCurrentResourceName() then return end
    if abierta then HudFuera(false) end
    -- (los objetos locales no se van solos al parar el recurso)
    if fantasmaVivo and DoesEntityExist(fantasmaVivo) then DeleteEntity(fantasmaVivo) end
end)

-- ── La escalera de mano, por código ─────────────────────────────────────
-- Solo con Config.Obra.escalaPorCodigo: si el modelo no lleva la escalera del
-- juego, la E al pie («Subir») y arriba, junto al hueco («Bajar»), lleva al
-- jugador a la otra punta con un fundido corto. Es su propio personaje dentro
-- de su casa: no se valida más.
if C.escalaPorCodigo then
    CreateThread(function()
        local conTexto = false
        local escalas, de, vistas = {}, nil, 0      -- { pie, alto, abajo }: las de la casa, repasadas cada segundo
        while true do
            local espera = 700
            local o = actual
            local accion, destino
            if o and (de ~= o or GetGameTimer() - vistas > 1000) then
                escalas, de, vistas = {}, o, GetGameTimer()
                for clave, valor in pairs(o.piezas) do
                    if clave:sub(1, 1) == 'e' then
                        local _, i, j, k = Partes(clave)
                        local celdas, _, salida, giro, forma = C.Escalera(i, j, valor)
                        if celdas and forma == 3 then
                            local d = C.giros[giro]
                            -- abajo, su celda (se llega algo apartado de la pared); arriba, la celda de salida
                            local pie = AMundo(o, i * C.celda, j * C.celda + C.celda / 2, k)
                            escalas[#escalas + 1] = { pie = pie, abajo = pie - (o.X * d[1] + o.Y * d[2]) * 0.3,
                                alto = AMundo(o, salida[1] * C.celda, salida[2] * C.celda + C.celda / 2, k + 1) }
                        end
                    end
                end
            end
            if o and not abierta and not IsScreenFadedOut() then
                local p = GetEntityCoords(PlayerPedId()) - vector3(0.0, 0.0, 1.0)
                for _, e in ipairs(escalas) do
                    if #(p - e.pie) < 1.3 then
                        accion, destino = 'Subir', e.alto
                    elseif #(p - e.alto) < 1.4 then
                        accion, destino = 'Bajar', e.abajo
                    end
                    if accion then break end
                end
            end
            if accion then
                espera = 0
                if conTexto ~= accion then
                    Internal.DrawText(accion, 'E')
                    conTexto = accion
                end
                if IsControlJustPressed(0, 38) then
                    DoScreenFadeOut(200)
                    local t = GetGameTimer()
                    while not IsScreenFadedOut() and GetGameTimer() - t < 800 do Wait(0) end
                    SetEntityCoordsNoOffset(PlayerPedId(), destino.x, destino.y, destino.z + 1.0, false, false, false)
                    Wait(150)
                    DoScreenFadeIn(250)
                end
            elseif conTexto then
                Internal.HideText()
                conTexto = false
            end
            Wait(espera)
        end
    end)
end
