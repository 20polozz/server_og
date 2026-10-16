-- Pasos secretos de las casas de modalidad libre (custom/client/secretos.lua y
-- custom/server/secretos.lua): puertas ocultas y trampillas. Son piezas de obra
-- (config/obra.lua, custom/*/obra.lua) que cerradas parecen pared, mueble o
-- suelo, y que con la E se abren moviéndose de verdad.
--
--   · En un borde entre dos celdas abiertas (x:… / y:…), valor 'o:<id>' con un
--     estilo de `estilos.borde`. Los que tienen frente (librería, armario…)
--     pueden ir vueltos: 'o:<id>:v' (la cinta los pone de cara a quien coloca).
--   · En el suelo entre dos plantas (l:…), valor 'o:<id>' con un estilo de
--     `estilos.suelo`, en vez del 1 del suelo normal.
--
-- Cerrado cuenta como pared o suelo a todos los efectos. Abierto o cerrado no
-- se guarda: lo lleva el servidor en memoria y al reiniciar está todo cerrado.
--
-- Este fichero se carga después de config/obra.lua (orden alfabético), pero
-- lee sus medidas cuando se le llama, no al cargar.
Config.Secretos = {
    apertura = 1200,      -- ms que tarda en abrirse o cerrarse
    radio = 1.6,          -- metros a los que hay que estar de la pieza para accionarla
    cierre = 0,           -- segundos abierta antes de cerrarse sola; 0 = no se cierra sola
    ritmo = 600,          -- ms mínimos entre dos órdenes del mismo jugador (lo mira el servidor)
    -- Quién ve el cartel «Abrir» / «Cerrar» al arrimarse:
    --   'llave'  solo quien tiene llave de la casa o permiso para construir en ella
    --   'todos'  cualquiera          'nadie'  nadie (la E funciona igual, sin cartel)
    cartel = 'llave',
    -- Quién puede accionarla: 'todos' (quien conozca el sitio) o 'llave'
    quien = 'todos',
    -- Si las trampillas que giran se inclinaran hacia abajo en vez de levantarse, poner -1
    giroSuelo = 1,
    -- Sonido al abrir y al cerrar, de los del juego. De serie ninguno. Para
    -- poner uno: sonido = { abrir = { 'NOMBRE', 'CONJUNTO' }, cerrar = { 'NOMBRE', 'CONJUNTO' }, alcance = 12 }
    sonido = false,
    asa = 'origen_casa_secreto_asa',   -- el asa de detrás de los muebles que la llevan (`asa = true` en su estilo)

    -- Lo que el dueño (quien tiene llave) puede ponerle a cada paso desde su menú
    -- (tecla G junto al paso). Se guarda en secretos.json, no en la base de datos.
    pin = { min = 4, max = 6, fallos = 3, bloqueo = 60 },   -- cifras del código; fallos seguidos y segundos de castigo
    cierres = { 0, 5, 10, 20 },   -- cierres automáticos que se pueden elegir, en segundos (0 = no)
    alarmaCada = 60,              -- segundos mínimos entre dos avisos de alarma del mismo paso
    cerrojoRepaso = 5,            -- cada cuántos segundos se mira si la sala atrancada se ha quedado vacía

    -- Disparadores a distancia: muebles del catálogo (config/furniture.lua, «Secretos»)
    -- que accionan un paso desde otra parte de la casa. Con la E se usan; el dueño
    -- elige con la G a qué paso va cada uno (sin elegir, al más cercano).
    --   radio   metros a los que hay que estar del mueble
    --   gesto   lo que hace el mueble al usarlo: { eje = 'x' | 'y' | 'z', grados, ms }
    gatillos = {
        ['origen_casa_gatillo_libro'] = { nombre = 'Libro', radio = 1.4, gesto = { eje = 'x', grados = 22.0, ms = 700 } },
        ['origen_casa_gatillo_interruptor'] = { nombre = 'Interruptor', radio = 1.4 },
        ['origen_casa_gatillo_palanca'] = { nombre = 'Palanca', radio = 1.5, gesto = { eje = 'x', grados = 40.0, ms = 800 } },
        ['origen_casa_gatillo_candelabro'] = { nombre = 'Candelabro', radio = 1.5, gesto = { eje = 'y', grados = 25.0, ms = 800 } },
        ['origen_casa_gatillo_cuadro'] = { nombre = 'Cuadro', radio = 1.5, gesto = { eje = 'y', grados = 8.0, ms = 700 } },
    },

    -- Por estilo:
    --   id, nombre
    --   modelo     el suyo (origen_casa_paso_<id> / origen_casa_trampilla_<id>). Sin modelo es
    --              el tabique o la losa del material con que esté pintada esa cara. Un estilo
    --              cuyo modelo aún no se sirva no se ofrece en la cinta.
    --              EN UN BORDE el paso son dos cosas: la PARED, que es el tabique del material de
    --              esa cara (se pinta como cualquier pared), y el MUEBLE, un objeto aparte pegado
    --              delante: origen_casa_secreto_<id> (o el que diga `mueble`), sin pared, con el
    --              origen y los ejes del tabique. Mientras ese no se sirva se usa `modelo`, el
    --              antiguo, que lleva su propia pared blanca y no se camufla.
    --   asa        true: lleva además el asa de detrás (Config.Secretos.asa), si se sirve
    --   porMaterial  true (el espejo espía): `modelo` lleva su paño y hay uno por material de
    --              pared, <modelo>_<material>; si el de ese material no se sirve, el `modelo` a secas
    --   modo       'corre' (se desliza de lado tras la pared o bajo el suelo vecino) o 'gira'
    --   recorrido  metros que se corre                     (modo corre; de serie 1.9)
    --   separa     metros que se despega del vecino para no parpadear con él: en un borde, hacia
    --              su frente; en el suelo, hacia abajo      (modo corre; de serie 0.02)
    --   lado       hacia dónde corre: 'auto' (donde haya pared o suelo vecino; si no lo hay en
    --              ningún lado, gira) o fijo. En un borde, 1 o -1 a lo largo de la pared (hacia
    --              el fondo o hacia la derecha de la casa, o al revés); en el suelo, 0…3 como
    --              Config.Obra.giros (0 fondo, 1 derecha, 2 entrada, 3 izquierda)
    --   angulo     grados que gira                          (de serie 90 en un borde, 85 en el suelo)
    --   bisagra    en qué extremo gira: 'auto' o fijo, con los mismos valores que `lado`.
    --              'auto' en un borde: el extremo que tenga pared al lado; en el suelo: el lado
    --              contrario a quien la acciona
    --   apertura   ms que tarda este estilo, si no son los de arriba
    --   fijo       true: no se abre (el espejo espía); solo se coloca, con su cara hacia donde se quiera
    --   abre       (borde, gira) hacia dónde abre: 'auto' (al lado contrario de quien la
    --              acciona), 'frente' (hacia su frente) o 'detras'
    estilos = {
        borde = {
            { id = 'pared', nombre = 'Pared falsa', modo = 'corre', lado = 'auto', recorrido = 1.9, separa = 0.02 },
            { id = 'libreria', nombre = 'Librería', modelo = 'origen_casa_paso_libreria', modo = 'gira', bisagra = 'auto', abre = 'auto', angulo = 90.0, asa = true },
            { id = 'armario', nombre = 'Armario', modelo = 'origen_casa_paso_armario', modo = 'gira', bisagra = 'auto', abre = 'auto', angulo = 90.0, asa = true },
            { id = 'taquillas', nombre = 'Taquillas', modelo = 'origen_casa_paso_taquillas', modo = 'gira', bisagra = 'auto', abre = 'auto', angulo = 90.0, asa = true },
            -- (los que corren y tienen fondo pasan por delante de la pared vecina: se despegan el grueso del tabique)
            { id = 'estanteria', nombre = 'Estantería metálica', modelo = 'origen_casa_paso_estanteria', modo = 'corre', lado = 'auto', recorrido = 1.9, separa = 0.12 },
            { id = 'panel', nombre = 'Panelado de madera', modelo = 'origen_casa_paso_panel', modo = 'corre', lado = 'auto', recorrido = 1.9, separa = 0.12 },
            { id = 'espejo', nombre = 'Espejo', modelo = 'origen_casa_paso_espejo', modo = 'gira', bisagra = 'auto', abre = 'auto', angulo = 90.0, asa = true },
            { id = 'chimenea', nombre = 'Chimenea', modelo = 'origen_casa_paso_chimenea', modo = 'corre', lado = 'auto', recorrido = 1.9, separa = 0.12 },
            { id = 'nevera', nombre = 'Frigorífico empotrado', modelo = 'origen_casa_paso_nevera', modo = 'gira', bisagra = 'auto', abre = 'frente', angulo = 95.0, asa = true },
            -- puerta acorazada a la vista, para la sala del pánico: pesada, abre despacio
            { id = 'blindada', nombre = 'Puerta acorazada', modelo = 'origen_casa_paso_blindada', modo = 'gira', bisagra = 'auto', abre = 'frente', angulo = 95.0, apertura = 3200, asa = true },
            -- espejo espía: no se abre. Por su frente es un espejo y desde detrás se ve a través.
            -- Lleva su paño (necesita el agujero): uno por material, y se pinta como una pared.
            { id = 'espia', nombre = 'Espejo espía', modelo = 'origen_casa_paso_espia', fijo = true, porMaterial = true },
        },
        suelo = {
            { id = 'suelo', nombre = 'Suelo falso', modo = 'corre', lado = 'auto', recorrido = 1.9, separa = 0.02 },
            { id = 'madera', nombre = 'Trampilla de madera', modelo = 'origen_casa_trampilla_madera', modo = 'gira', bisagra = 'auto', angulo = 85.0 },
            { id = 'metal', nombre = 'Escotilla de chapa', modelo = 'origen_casa_trampilla_metal', modo = 'gira', bisagra = 'auto', angulo = 85.0 },
            -- (la alfombra sobresale por arriba: baja algo más para caber bajo el suelo vecino)
            { id = 'alfombra', nombre = 'Alfombra', modelo = 'origen_casa_trampilla_alfombra', modo = 'corre', lado = 'auto', recorrido = 1.9, separa = 0.06 },
            { id = 'rejilla', nombre = 'Rejilla', modelo = 'origen_casa_trampilla_rejilla', modo = 'gira', bisagra = 'auto', angulo = 85.0 },
        },
    },
}

local S = Config.Secretos
local ESTILO = { borde = {}, suelo = {} }
for tipo, lista in pairs(S.estilos) do
    for _, e in ipairs(lista) do ESTILO[tipo][e.id] = e end
end

local function Partes(clave)
    local t, i, j, k = tostring(clave):match('^([xyl]):(-?%d+):(-?%d+):(-?%d+)$')
    if not t then return end
    return t, tonumber(i), tonumber(j), tonumber(k)
end

local function Abierta(o, i, j, k) return o.celdas[i .. ':' .. j .. ':' .. k] ~= nil end

--- ¿Es el valor de un paso secreto? (sin mirar si su estilo existe)
function Config.Secretos.Es(valor)
    return type(valor) == 'string' and valor:sub(1, 2) == 'o:'
end

--- De qué clase es la pieza de esa clave: 'borde' (x, y), 'suelo' (l) o nil.
function Config.Secretos.Tipo(clave)
    local t = tostring(clave):sub(1, 1)
    return (t == 'x' or t == 'y') and 'borde' or t == 'l' and 'suelo' or nil
end

--- El estilo del paso que hay en esa clave con ese valor, si lo es:
--- estilo, vuelto (true si va con el frente al otro lado), tipo. Si no, nil.
function Config.Secretos.Estilo(clave, valor)
    if type(valor) ~= 'string' then return nil end
    local tipo = S.Tipo(clave)
    if not tipo then return nil end
    local vuelto = false
    local id = valor:match('^o:([%w_]+)$')
    if not id then
        id = valor:match('^o:([%w_]+):v$')
        vuelto = true
    end
    local e = id and ESTILO[tipo][id] or nil
    if not e or (vuelto and tipo ~= 'borde') then return nil end
    return e, vuelto, tipo
end

--- ¿Es un paso que no se pinta? Solo las trampillas con modelo propio: en un
--- borde la pared es siempre el tabique de su material (el mueble va aparte)
--- y se pinta como cualquier otra.
function Config.Secretos.ConModelo(clave, valor)
    local e, _, tipo = S.Estilo(clave, valor)
    return e ~= nil and e.modelo ~= nil and tipo == 'suelo'
end

-- (cliente) El modelo del mueble sin pared de un estilo de borde, si ya se sirve
local function MuebleDe(e)
    if not e or not e.modelo or e.fijo or e.porMaterial then return nil end
    local modelo = joaat(e.mueble or ('origen_casa_secreto_' .. e.id))
    return IsModelInCdimage(modelo) and modelo or nil
end

--- (cliente) ¿Se puede poner ese estilo? Los de modelo propio, solo si ya se sirve
--- (el mueble sin pared o, mientras no esté, el antiguo con pared).
function Config.Secretos.Disponible(e)
    return e.modelo == nil or MuebleDe(e) ~= nil or IsModelInCdimage(joaat(e.modelo))
end

--- (cliente) El mueble que va delante de la pared de ese paso (modelo sin
--- pared) y, si lo lleva y se sirve, su asa. nil si ese paso no lleva mueble
--- aparte (pared falsa, espejo espía, trampillas, o su modelo nuevo no se sirve).
function Config.Secretos.Mueble(clave, valor)
    local e, _, tipo = S.Estilo(clave, valor)
    if tipo ~= 'borde' then return nil end
    local mueble = MuebleDe(e)
    if not mueble then return nil end
    local asa = e.asa and S.asa and joaat(S.asa) or nil
    return mueble, asa and IsModelInCdimage(asa) and asa or nil
end

--- (cliente) El modelo de la PIEZA de ese paso (lo que monta la obra), o nil si
--- es el tabique o la losa de su material: la pared falsa, y todo paso de borde
--- cuyo mueble va aparte. `material`: con el que está pintada la cara.
function Config.Secretos.Modelo(clave, valor, material)
    local e, _, tipo = S.Estilo(clave, valor)
    if not e or not e.modelo then return nil end
    if tipo == 'borde' then
        if e.porMaterial and material then
            -- uno por material de pared (origen_casa_paso_espia_<material>); si no está, el de siempre
            local suyo = Config.Obra.Modelo((e.modelo:gsub('^origen_casa_', '')), material)
            if IsModelInCdimage(suyo) then return suyo end
        elseif MuebleDe(e) then
            return nil
        end
    end
    local modelo = joaat(e.modelo)
    return IsModelInCdimage(modelo) and modelo or nil
end

--- (cliente) El estilo que toca con esa vuelta de la R, de los que se pueden poner.
function Config.Secretos.Toca(tipo, vuelta)
    local hay = {}
    for _, e in ipairs(S.estilos[tipo] or {}) do
        if S.Disponible(e) then hay[#hay + 1] = e end
    end
    return hay[vuelta % math.max(#hay, 1) + 1]
end

-- ── Dónde está cada cosa ────────────────────────────────────────────────
-- Todo en las medidas de la obra: x a lo ancho, y hacia el fondo y z desde el
-- suelo de la planta baja, con el origen en el ancla (lo mismo que usan
-- custom/client/obra.lua y custom/server/obra.lua para sacar la celda).

-- De un punto respecto a un paso. En un borde: `a` a lo largo de la pared
-- desde su centro y `p` a través (positivo hacia la celda siguiente, la i+1 o
-- la j+1). En el suelo: `a` y `p` son x e y desde el centro de la celda.
-- Devuelve t, i, j, k, a, p.
local function Respecto(clave, x, y)
    local t, i, j, k = Partes(clave)
    if not t then return end
    local c = Config.Obra.celda
    if t == 'x' then return t, i, j, k, y - (j * c + c / 2), x - (i * c + c / 2) end
    if t == 'y' then return t, i, j, k, x - i * c, y - (j * c + c) end
    return t, i, j, k, x - i * c, y - (j * c + c / 2)
end

--- ¿Está ese punto lo bastante cerca del paso para accionarlo? En un borde:
--- en su planta, frente a la pared y a menos de `radio`. En el suelo: en la
--- planta de encima o en la de debajo y a menos de `radio` del centro.
function Config.Secretos.Cerca(clave, x, y, z, radio)
    local t, _, _, k, a, p = Respecto(clave, x, y)
    if not t then return false end
    local O = Config.Obra
    local planta = O.PlantaDe(z)
    if t == 'l' then
        return (planta == k or planta == k - 1) and a * a + p * p <= radio * radio
    end
    return planta == k and math.abs(a) <= O.celda / 2 + 0.3 and math.abs(p) <= radio
end

--- ¿Está ese punto (el centro de un personaje) en medio del paso? Con alguien
--- ahí no se cierra: en un borde, quien está en el vano; en el suelo, quien
--- está metido en el hueco (el que pisa el borde de al lado no estorba).
function Config.Secretos.EnMedio(clave, x, y, z)
    local t, _, _, k, a, p = Respecto(clave, x, y)
    if not t then return false end
    local O = Config.Obra
    if t == 'l' then
        local dz = z - k * O.planta
        return math.abs(a) < 0.95 and math.abs(p) < 0.95 and dz > -0.9 and dz < 0.9
    end
    return O.PlantaDe(z) == k and math.abs(a) < O.celda / 2 + 0.05 and math.abs(p) < 0.45
end

--- ¿Está ese punto de pie encima de la trampilla? (una que gira no se levanta con alguien encima)
function Config.Secretos.Encima(clave, x, y, z)
    local t, _, _, k, a, p = Respecto(clave, x, y)
    if t ~= 'l' then return false end
    local dz = z - k * Config.Obra.planta
    return math.abs(a) < 1.0 and math.abs(p) < 1.0 and dz >= 0.9 and dz < 1.7
end

--- Ms que tarda en moverse un estilo
function Config.Secretos.Apertura(estilo)
    return math.max(100, tonumber(estilo and estilo.apertura) or tonumber(S.apertura) or 1200)
end

--- A qué lado del paso queda ese punto: en un borde, 1 la celda siguiente (i+1
--- o j+1) y -1 la otra; en el suelo, 1 encima y -1 debajo.
function Config.Secretos.Lado(clave, x, y, z)
    local t, _, _, k, _, p = Respecto(clave, x, y)
    if not t then return nil end
    if t == 'l' then return (z - k * Config.Obra.planta >= 0.0) and 1 or -1 end
    return p >= 0 and 1 or -1
end

--- Qué lado de un paso es «dentro» (el que puede atrancarlo y sale sin código):
--- el que haya marcado el dueño (`marcado`, 1 o -1) o, si no, la espalda del
--- modelo en un borde (la pared lisa) y la planta de abajo en el suelo.
function Config.Secretos.Dentro(clave, valor, marcado)
    if marcado == 1 or marcado == -1 then return marcado end
    local _, vuelto, tipo = S.Estilo(clave, valor)
    if tipo ~= 'borde' then return -1 end
    local frente = (tostring(clave):sub(1, 1) == 'x') and -1 or 1
    if vuelto then frente = -frente end
    return -frente
end

--- La celda (i, j, k) que queda a ese lado del paso
function Config.Secretos.CeldaDe(clave, lado)
    local t, i, j, k = Partes(clave)
    if not t then return nil end
    if t == 'x' then return i + (lado == 1 and 1 or 0), j, k end
    if t == 'y' then return i, j + (lado == 1 and 1 or 0), k end
    return i, j, k - (lado == 1 and 0 or 1)
end

--- Centro de un paso en las medidas de la obra (x, y, z; en un borde, a media altura)
function Config.Secretos.Centro(clave)
    local t, i, j, k = Partes(clave)
    if not t then return nil end
    local c, O = Config.Obra.celda, Config.Obra
    if t == 'x' then return i * c + c / 2, j * c + c / 2, k * O.planta + 1.2 end
    if t == 'y' then return i * c, j * c + c, k * O.planta + 1.2 end
    return i * c, j * c + c / 2, k * O.planta
end

--- Si ese modelo de mueble (nombre o hash) es un disparador, su nombre de modelo y sus ajustes
function Config.Secretos.Gatillo(modelo)
    if type(modelo) == 'number' then
        for nombre, g in pairs(S.gatillos) do
            if joaat(nombre) == modelo then return nombre, g end
        end
        return nil
    end
    if type(modelo) == 'string' and S.gatillos[modelo] then return modelo, S.gatillos[modelo] end
    return nil
end

--- ¿Vale ese código? (solo cifras, del largo que diga la config)
function Config.Secretos.PinVale(pin)
    return type(pin) == 'string' and #pin >= S.pin.min and #pin <= S.pin.max and pin:match('^%d+$') ~= nil
end

-- ¿Hay pared en ese borde? (una entera: da a macizo o está levantada)
local function Tapado(o, t, i, j, k)
    local u, v = Abierta(o, i, j, k), Abierta(o, i + (t == 'x' and 1 or 0), j + (t == 'y' and 1 or 0), k)
    if u and v then return o.piezas[('%s:%d:%d:%d'):format(t, i, j, k)] == 'p' end
    return true
end

-- ¿Hay suelo a la altura de la planta k en esa celda? (o macizo, que lo tapa igual)
local function Pisable(o, i, j, k)
    if Abierta(o, i, j, k) and Abierta(o, i, j, k - 1) then return o.piezas[('l:%d:%d:%d'):format(i, j, k)] == 1 end
    return true
end

--- Cómo se abre ese paso, visto lo que tiene alrededor y dónde está quien lo
--- acciona (x, y en las medidas de la obra). Lo decide el servidor al abrir y
--- se lo manda a todos, para que lo vean igual. Devuelve { modo, lado, sentido }:
---   borde  corre: lado = 1 / -1, hacia dónde se desliza a lo largo de la pared
---          gira:  lado = extremo de la bisagra (1 / -1) y sentido = 1 si abre
---                 hacia la celda siguiente (i+1 o j+1), -1 hacia la otra
---   suelo  corre: lado = 0…3 (Config.Obra.giros), hacia dónde se desliza
---          gira:  lado = 0…3, el lado de la bisagra
function Config.Secretos.Plan(o, clave, valor, x, y)
    local e, vuelto, tipo = S.Estilo(clave, valor)
    if not e then return nil end
    local t, i, j, k, a, p = Respecto(clave, x or 0.0, y or 0.0)
    local modo, lado = e.modo, nil
    if tipo == 'borde' then
        local function vecino(paso)
            if t == 'x' then return Tapado(o, t, i, j + paso, k) end
            return Tapado(o, t, i + paso, j, k)
        end
        if modo == 'corre' then
            lado = (e.lado == 1 or e.lado == -1) and e.lado or (vecino(1) and 1) or (vecino(-1) and -1) or nil
            if lado then return { modo = 'corre', lado = lado, sentido = 1 } end
        end
        lado = (e.bisagra == 1 or e.bisagra == -1) and e.bisagra or (vecino(1) and 1) or (vecino(-1) and -1) or 1
        -- hacia dónde mira su frente: el tabique mira a la celda (i,j) en un borde x y a la (i,j+1) en uno y
        local frente = (t == 'x') and -1 or 1
        if vuelto then frente = -frente end
        local sentido
        if e.abre == 'frente' then sentido = frente
        elseif e.abre == 'detras' then sentido = -frente
        else sentido = (p > 0) and -1 or 1 end      -- al lado contrario de quien la acciona
        return { modo = 'gira', lado = lado, sentido = sentido }
    end
    local giros = Config.Obra.giros
    local function fijo(v) return type(v) == 'number' and giros[v] and v or nil end
    if modo == 'corre' then
        lado = fijo(e.lado)
        if not lado then
            for g = 0, 3 do
                if Pisable(o, i + giros[g][1], j + giros[g][2], k) then lado = g break end
            end
        end
        if lado then return { modo = 'corre', lado = lado, sentido = 1 } end
    end
    lado = fijo(e.bisagra)
    if not lado then
        -- la bisagra, en el lado contrario a quien la acciona: se levanta alejándose de él
        if math.abs(a) > math.abs(p) then lado = a > 0 and 3 or 1 else lado = p > 0 and 2 or 0 end
    end
    return { modo = 'gira', lado = lado, sentido = 1 }
end
