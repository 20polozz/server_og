-- Imágenes en las caras de una casa de modalidad libre (ver config/imagenes.lua
-- y custom/server/imagenes.lua). Con la herramienta «Imagen» de la cinta se
-- mira una pared, un suelo o un techo, se da el enlace de Fivemanage y la
-- imagen queda pegada en esa cara, para todos los que entren.
--
-- Cada imagen es un navegador (DUI) con la forma de su cara, pintado sobre dos
-- triángulos a un centímetro y medio de la superficie. Solo viven los de las
-- imágenes cercanas de la casa en la que se está.
--
-- Aquí no se decide nada: se pide al servidor y se dibuja lo que él reparte.
-- De custom/client/obra.lua solo se usa lo público (Obra.Actual y sus eventos)
-- y la cinta llama a Imagenes.EnMano, Imagenes.Poner e Imagenes.Quitar.
local C = Config.Imagenes
local PAGINA = ('nui://%s/ui/imagen.html'):format(GetCurrentResourceName())

Imagenes = {}

local casa = nil        -- id de la casa de obra en la que se está
local lista = {}        -- lo que hay puesto en ella: { [cara] = { url, tam, giro } }
local geo = {}          -- de las que se pueden dibujar: { [cara] = { centro, tl, tr, bl, br, R, T, hw, hh, W, H, url, firma } }
local duis = {}         -- navegadores vivos: { [cara] = { dui, txd, firma, listo, muerto } }
local numTxd = 0
local pidiendo = false  -- con el diálogo del enlace abierto

local TAMANOS = {
    pared = { [0] = '1 celda', '2 celdas de ancho' },
    plano = { [0] = '1 celda', '2 celdas a lo ancho', '2 celdas hacia el fondo', '2 × 2 celdas' },
}

local function Aviso(texto, tipo)
    exports.origen_notify:Notify({ title = 'Imagen', description = texto, type = tipo or 'info', duration = 3500 })
end

local function Separar(cara)
    local clave, lado = tostring(cara):match('^(%a:%-?%d+:%-?%d+:%-?%d+):([ab])$')
    return clave, lado
end

-- ── Dónde va cada imagen ────────────────────────────────────────────────
-- El rectángulo de una imagen en el mundo. R es hacia la derecha de quien la
-- mira y T hacia arriba de la imagen; R × T sale siempre de la superficie
-- hacia quien mira, que es lo que hace que no quede espejada.
--   · Pared: T es el cielo y R = arriba × normal (la normal sale de la pared
--     hacia la celda desde la que se ve).
--   · Suelo: T es hacia donde miraba quien la puso (se lee derecha desde donde
--     estaba) y R su derecha.
--   · Techo: la misma derecha, y T al revés: al levantar la vista, lo de
--     arriba de lo que se ve es lo que queda a la espalda.
local function Geometria(o, clave, lado, tam, giro)
    local t, i, j, k = C.Partes(clave)
    if not t then return nil end
    local CO = Config.Obra
    local celda, m = CO.celda, CO.celda / 2
    local lx, ly, z, rx, ry, tx, ty, hw, hh
    local pared = t == 'x' or t == 'y'
    if pared then
        local n = lado == 'a' and -1.0 or 1.0         -- hacia qué lado sale la cara
        local fuera = n * (C.pared / 2 + C.separacion)
        hw, hh = (tam == 1) and celda or m, C.alto / 2
        z = k * CO.planta + hh
        if t == 'x' then
            lx, ly = i * celda + m + fuera, j * celda + m + (tam == 1 and m or 0.0)
            rx, ry = 0.0, n
        else
            lx, ly = i * celda + (tam == 1 and m or 0.0), j * celda + celda + fuera
            rx, ry = -n, 0.0
        end
    else
        local suelo = t == 's' or (t == 'l' and lado == 'a')
        local ex = (tam == 1 or tam == 3) and celda * 2 or celda
        local ey = (tam == 2 or tam == 3) and celda * 2 or celda
        lx, ly = i * celda + (ex - celda) / 2, j * celda + m + (ey - celda) / 2
        local d = CO.giros[giro] or CO.giros[0]        -- hacia dónde miraba quien la puso
        if d[1] ~= 0 then hw, hh = ey / 2, ex / 2 else hw, hh = ex / 2, ey / 2 end
        rx, ry = d[2] + 0.0, -d[1] + 0.0
        if suelo then
            z = k * CO.planta + C.separacion
            tx, ty = d[1] + 0.0, d[2] + 0.0
        else
            -- t: por debajo de la losa de la planta de encima; l por abajo: por debajo de la suya
            z = (t == 't' and k + 1 or k) * CO.planta - C.losa - C.separacion
            tx, ty = -d[1] + 0.0, -d[2] + 0.0
        end
    end
    local centro = o.o + o.X * lx + o.Y * ly + vector3(0.0, 0.0, z)
    local R = o.X * rx + o.Y * ry
    local T = pared and vector3(0.0, 0.0, 1.0) or (o.X * tx + o.Y * ty)
    local g = { centro = centro, R = R, T = T, hw = hw, hh = hh }
    local der, arr = R * hw, T * hh
    if C.espejoU then der = der * -1.0 end
    if C.espejoV then arr = arr * -1.0 end
    g.tl, g.tr, g.bl, g.br = centro - der + arr, centro + der + arr, centro - der - arr, centro + der - arr
    -- el navegador, con la forma de la cara: así la imagen entra sin deformarse
    g.W = math.floor(C.lado * math.min(1.0, hw / hh) + 0.5)
    g.H = math.floor(C.lado * math.min(1.0, hh / hw) + 0.5)
    return g
end

-- ── Los navegadores ─────────────────────────────────────────────────────
-- Un runtime txd no se puede borrar: cada navegador nuevo deja su textura en
-- memoria para siempre. Andando por una casa con imágenes se creaban y se
-- destruían navegadores sin parar (entran y salen de la distancia), así que
-- los que se sueltan se guardan, en blanco, y se vuelven a usar con otra
-- imagen de la misma forma: como mucho se crean los que llegan a estar a la vez.
local reserva = {}      -- 'ancho x alto' → { { dui, txd }, … }
local enReserva = 0
local MAX_RESERVA = 8

local function Soltar(cara)
    local d = duis[cara]
    if not d then return end
    duis[cara] = nil
    d.muerto = true
    -- (uno que aún se está creando lo recoge su propio hilo)
    if not d.listo or not d.dui then return end
    if d.txd and d.forma and enReserva < MAX_RESERVA then
        SetDuiUrl(d.dui, 'about:blank')
        reserva[d.forma] = reserva[d.forma] or {}
        table.insert(reserva[d.forma], { dui = d.dui, txd = d.txd })
        enReserva = enReserva + 1
    else
        DestroyDui(d.dui)
    end
    d.dui = nil
end

local function SoltarTodos()
    for cara in pairs(duis) do Soltar(cara) end
end

-- Al salir de la casa (o parar el recurso): fuera también los guardados
local function VaciarReserva()
    for _, lista in pairs(reserva) do
        for _, r in ipairs(lista) do DestroyDui(r.dui) end
    end
    reserva, enReserva = {}, 0
end

local function Crear(cara, g)
    -- el enlace solo llega al navegador si pasa el patrón, y va escapado en el #
    if not C.Valida(g.url) then return end
    local d = { firma = g.firma, listo = false, forma = g.W .. 'x' .. g.H }
    duis[cara] = d
    CreateThread(function()
        -- (soltado antes de empezar: no se crea nada)
        if d.muerto then return end
        local escapado = g.url:gsub('[^%w%-%._~]', function(c) return ('%%%02X'):format(c:byte()) end)
        local guardado = reserva[d.forma] and table.remove(reserva[d.forma]) or nil
        if guardado then
            enReserva = enReserva - 1
            d.dui, d.txd = guardado.dui, guardado.txd
            SetDuiUrl(d.dui, PAGINA .. '#' .. escapado)
        else
            d.dui = CreateDui(PAGINA .. '#' .. escapado, g.W, g.H)
            local hasta = GetGameTimer() + 5000
            while not d.muerto and not IsDuiAvailable(d.dui) and GetGameTimer() < hasta do Wait(20) end
            -- soltado mientras se creaba: el navegador se destruye aquí (antes se quedaba vivo para siempre)
            if d.muerto then
                DestroyDui(d.dui)
                d.dui = nil
                return
            end
            numTxd = numTxd + 1
            d.txd = 'origen_housing_imagen_' .. numTxd
            CreateRuntimeTextureFromDuiHandle(CreateRuntimeTxd(d.txd), 'imagen', GetDuiHandle(d.dui))
        end
        Wait(300)
        if not d.muerto then
            -- por si el # no hubiera llegado a la página
            SendDuiMessage(d.dui, json.encode({ action = 'imagen', url = g.url }))
            Wait(guardado and 250 or 0)     -- (el guardado, que no enseñe un instante lo que tenía)
        end
        if d.muerto then
            -- soltado en la espera: ya tiene su textura, así que vale para otra
            d.listo = true
            duis['\0' .. d.txd] = d
            Soltar('\0' .. d.txd)
            return
        end
        d.listo = true
    end)
end

-- Qué se puede dibujar de lo que hay puesto: la cara tiene que seguir en pie
local function Recalcular()
    geo = {}
    local o = Obra.Actual()
    if o and casa and o.id == casa then
        for cara, im in pairs(lista) do
            local clave, lado = Separar(cara)
            if clave and type(im) == 'table' and C.Valida(im.url) and C.Cara(o, clave, lado, im.tam) then
                local g = Geometria(o, clave, lado, im.tam, im.giro)
                if g then
                    g.url = im.url
                    g.firma = ('%s|%dx%d'):format(im.url, g.W, g.H)
                    geo[cara] = g
                end
            end
        end
    end
    for cara, d in pairs(duis) do
        if not geo[cara] or geo[cara].firma ~= d.firma then Soltar(cara) end
    end
end

-- Cada poco: navegador para las más cercanas, y fuera el de las que quedan lejos
local function Repasar()
    local yo = GetEntityCoords(PlayerPedId())
    local cerca = {}
    for cara, g in pairs(geo) do
        local dist = #(yo - g.centro)
        -- las que ya tienen navegador aguantan un poco más: así no se crean y se destruyen en el borde
        if dist < C.distancia or (duis[cara] and dist < C.distancia + 4.0) then
            cerca[#cerca + 1] = { cara = cara, dist = dist }
        end
    end
    table.sort(cerca, function(a, b) return a.dist < b.dist end)
    local quiero = {}
    for q = 1, math.min(#cerca, C.maxDui) do quiero[cerca[q].cara] = true end
    for cara in pairs(duis) do
        if not quiero[cara] then Soltar(cara) end
    end
    for cara in pairs(quiero) do
        if not duis[cara] then Crear(cara, geo[cara]) end
    end
end

-- Los dos triángulos, por las dos caras (por detrás la tapa la propia pared).
-- Las esquinas y sus coordenadas de textura, como en las pantallas del casino
-- y del bingo, que están comprobadas en partida.
local function Dibujar(g, txd)
    local a, b, c, d, n = g.tr, g.tl, g.br, g.bl, 'imagen'
    DrawTexturedPoly(a.x, a.y, a.z, b.x, b.y, b.z, d.x, d.y, d.z, 255, 255, 255, 255, txd, n, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0)
    DrawTexturedPoly(a.x, a.y, a.z, d.x, d.y, d.z, c.x, c.y, c.z, 255, 255, 255, 255, txd, n, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0)
    DrawTexturedPoly(d.x, d.y, d.z, b.x, b.y, b.z, a.x, a.y, a.z, 255, 255, 255, 255, txd, n, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0)
    DrawTexturedPoly(c.x, c.y, c.z, d.x, d.y, d.z, a.x, a.y, a.z, 255, 255, 255, 255, txd, n, 1.0, 1.0, 0.0, 0.0, 1.0, 0.0, 1.0, 0.0, 0.0)
end

CreateThread(function()
    local repaso = 0
    while true do
        if not casa or not next(geo) then
            Wait(500)
        else
            local ahora = GetGameTimer()
            if ahora - repaso > 400 then
                repaso = ahora
                Repasar()
            end
            for cara, d in pairs(duis) do
                local g = geo[cara]
                if d.listo and g then Dibujar(g, d.txd) end
            end
            Wait(0)
        end
    end
end)

-- ── Entrar, salir y lo que cambia ───────────────────────────────────────
-- La obra avisa cada vez que se monta: la primera vez en una casa se pide lo
-- que hay puesto; las demás (alguien ha cambiado una pared) se repasa qué
-- caras siguen en pie.
AddEventHandler('origen_housing:obra:montada', function(id)
    id = tostring(id)
    if casa == id then return Recalcular() end
    SoltarTodos()
    casa, lista, geo = id, {}, {}
    CreateThread(function()
        local r = lib.callback.await('origen_housing:imagenes:estado', false, id)
        if casa ~= id then return end
        lista = type(r) == 'table' and r or {}
        Recalcular()
    end)
end)

AddEventHandler('origen_housing:obra:desmontada', function()
    SoltarTodos()
    VaciarReserva()
    casa, lista, geo = nil, {}, {}
end)

RegisterNetEvent('origen_housing:imagenes:cambio', function(id, cara, im)
    if not casa or casa ~= tostring(id) or type(cara) ~= 'string' then return end
    lista[cara] = type(im) == 'table' and im or nil
    Recalcular()
end)

AddEventHandler('onResourceStop', function(r)
    if r == GetCurrentResourceName() then
        SoltarTodos()
        VaciarReserva()
    end
end)

-- ── La herramienta «Imagen» de la cinta ─────────────────────────────────
-- `m` es la mirada de la cinta (custom/client/obra.lua): la pieza que se
-- mira, la celda desde la que se ve (m.a) y hacia dónde se mira.
local function Objetivo(m, vuelta)
    if not m or not m.pieza or not m.a then return nil end
    local t, i, j, k = C.Partes(m.pieza)
    if not t then return nil end
    local ob = { clave = m.pieza, lado = 'a', tam = 0, giro = 0 }
    if t == 'x' or t == 'y' then
        -- la cara del lado desde el que se mira
        ob.lado = ((t == 'x' and m.a[1] or m.a[2]) == (t == 'x' and i or j)) and 'a' or 'b'
        ob.tam = vuelta % 2
        ob.pared = true
    else
        if t == 't' then ob.lado = 'b' elseif t == 'l' then ob.lado = (m.a[3] == k) and 'a' or 'b' end
        ob.tam = vuelta % 4
        -- derecha para quien la pone: lo de arriba de la imagen, hacia donde mira
        local dx, dy = m.dx or 0.0, m.dy or 1.0
        if math.abs(dx) > math.abs(dy) then ob.giro = dx > 0 and 1 or 3 else ob.giro = dy > 0 and 0 or 2 end
    end
    return ob
end

-- La imagen puesta que tiene debajo el punto que se mira. El margen es menor
-- que el grueso de una pared: no se coge la que hay pegada por el otro lado.
local function Mirada(m)
    if not m or not m.pos then return nil end
    for cara, g in pairs(geo) do
        local d = m.pos - g.centro
        local r, t = d.x * g.R.x + d.y * g.R.y + d.z * g.R.z, d.x * g.T.x + d.y * g.T.y + d.z * g.T.z
        if math.abs(r) <= g.hw and math.abs(t) <= g.hh and #(d - g.R * r - g.T * t) < 0.06 then return cara end
    end
end

local function Linea(a, b, r, g, bl)
    DrawLine(a.x, a.y, a.z, b.x, b.y, b.z, r, g, bl, 255)
end

local vistaVuelta = nil

--- Cada fotograma con la herramienta en la mano: el recuadro de dónde iría la
--- imagen (en el color de la marca si cabe, gris si no) y, al cambiar de
--- tamaño con la R, cuál es.
function Imagenes.EnMano(o, m, vuelta)
    if not o or pidiendo then return end
    local ob = Objetivo(m, vuelta)
    if not ob then return end
    local g = Geometria(o, ob.clave, ob.lado, ob.tam, ob.giro)
    if not g then return end
    local r, v, a = 150, 150, 150
    if C.Cara(o, ob.clave, ob.lado, ob.tam) then
        r, v, a = 216, 27, 85
        if OrigenMarcaColor then r, v, a = OrigenMarcaColor(r, v, a) end
    end
    Linea(g.tl, g.tr, r, v, a)
    Linea(g.tr, g.br, r, v, a)
    Linea(g.br, g.bl, r, v, a)
    Linea(g.bl, g.tl, r, v, a)
    -- una raya corta que señala lo de arriba de la imagen (en suelo y techo no es evidente)
    if not ob.pared then
        local alto = g.T * (g.hh * 0.85)
        Linea(g.centro, g.centro + alto, r, v, a)
    end
    if vistaVuelta ~= vuelta then
        if vistaVuelta ~= nil then
            Aviso('Tamaño: ' .. (ob.pared and TAMANOS.pared or TAMANOS.plano)[ob.tam])
        end
        vistaVuelta = vuelta
    end
end

local function Pedir()
    local dato
    if GetResourceState('org-input') == 'started' then
        local r = exports['org-input']:ShowInput({
            header = 'Imagen',
            submitText = 'Poner',
            icon = 'fa-solid fa-image',
            inputs = {
                { type = 'text', name = 'url', text = 'Enlace de Fivemanage (https://r2.fivemanage.com/….png)', isRequired = true },
            },
        })
        dato = r and r.url
    else
        local r = lib.inputDialog('Imagen', { { type = 'input', label = 'Enlace de Fivemanage', required = true } })
        dato = r and r[1]
    end
    if type(dato) ~= 'string' then return nil end
    dato = dato:gsub('^%s+', ''):gsub('%s+$', '')
    return dato
end

--- Clic con la herramienta: pide el enlace y manda poner la imagen en la cara que se mira.
function Imagenes.Poner(o, m, vuelta)
    if not o or pidiendo then return end
    local ob = Objetivo(m, vuelta)
    if not ob then return Aviso('Mira una pared, un suelo o un techo para poner la imagen') end
    if not C.Cara(o, ob.clave, ob.lado, ob.tam) then
        return Aviso(ob.tam == 0 and 'Ahí no se puede poner una imagen: tiene que ser una pared entera, un suelo o un techo'
            or 'Con ese tamaño no cabe ahí: cambia el tamaño con la R o mira la celda de al lado', 'error')
    end
    local id = o.id
    pidiendo = true
    CreateThread(function()
        local url = Pedir()
        -- el clic o el Intro que cierra el diálogo no vuelve a abrirlo
        SetTimeout(300, function() pidiendo = false end)
        if not url or url == '' then return end
        if not C.Valida(url) then
            return Aviso('Ese enlace no vale: tiene que ser de Fivemanage (https://r2.fivemanage.com/…) y acabar en .png, .jpg o .webp', 'error')
        end
        if casa ~= id then return end
        TriggerServerEvent('origen_housing:imagenes:poner', id, ob.clave, ob.lado, ob.tam, ob.giro, url)
    end)
end

--- Clic derecho con la herramienta: quita la imagen que se mira.
function Imagenes.Quitar(o, m)
    if not o or pidiendo then return end
    local cara = Mirada(m)
    if not cara then return Aviso('Mira la imagen que quieres quitar') end
    TriggerServerEvent('origen_housing:imagenes:quitar', o.id, cara)
end
