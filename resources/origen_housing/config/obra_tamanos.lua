-- Tamaños de las casas de modalidad «libre» (ver config/obra.lua), sus topes
-- y lo que cuesta la obra. Se carga después de config/obra.lua (orden
-- alfabético). Aquí solo hay datos y cuentas, sin nada del juego: lo usa el
-- servidor (custom/server/packs.lua) para aceptar o rechazar cada cambio y el
-- cliente (custom/client/packs.lua) para el contador de la cinta.
--
-- ── De dónde salen los números ──────────────────────────────────────────
-- El juego admite unos 2.300 objetos a la vez por jugador y, si se pasa, se
-- cae. El tope de seguridad es Config.Obra.maxObjetos (2.000), y de ahí se
-- dejan 300 (`margen`) para lo que no es de la casa (objetos de otros
-- recursos, lo que lleve la gente encima…): a la casa le quedan 1.700.
--
-- Peor caso de una casa, sin contar con que los paños juntan piezas:
--   · cada celda abierta, 6 objetos (suelo, techo y cuatro paredes): es lo que
--     sale si se excava «a cuadros», sin dos celdas juntas, o si cada cara se
--     pinta de un material distinto y ningún paño se puede juntar;
--   · cada pieza puesta a mano, 1;
--   · cada mueble, 1,5 de media (los que se abren llevan puertas y cajones
--     aparte; una lámpara propia, su modelo apagado);
--   · cada ascensor o montacoches, 12 (cabina, hojas y barreras de cada planta).
--
-- (Esa era la cuenta de partida, con 6 objetos por celda. Desde el ajuste del
-- coordinador de más abajo la celda pesa 0,6 y el margen es 250: a la casa le
-- quedan 1.750. Con los topes de hoy:)
--   Premium:  1.200 × 0,6 + 600 + 250 × 1,5 + 4 × 11 = 1.739  (≤ 1.750)
--   Grande:     500 × 0,6 + 300 + 200 × 1,5 + 2 × 11 =   922
--   Media:      220 × 0,6 + 150 + 130 × 1,5 + 1 × 11 =   488
--   Pequeña:     80 × 0,6 +  60 +  70 × 1,5 + 1 × 11 =   224
-- (el ascensor ya cuenta 1 como pieza: por eso aquí suma 11)
--
-- Una casa real carga mucho menos (una de 749 celdas muy trabajada se quedó en
-- unos 500 objetos gracias a los paños), pero el tope tiene que aguantar a
-- quien construya a mala idea. Además de estos topes, el servidor hace la
-- cuenta exacta de cada casa (Config.Obra.Carga, con el peso real de cada
-- mueble) y no deja pasar de los 1.700 aunque los topes sueltos se cumplan.
-- Si se tocan los números, al arrancar se avisa en la consola del tamaño que
-- no cumpla.
local O = Config.Obra

-- AJUSTE DEL COORDINADOR (noche del 12/10): el peso de 6 objetos por celda era el
-- peor caso teórico y dejaba el Premium en 175 celdas, muy por debajo de lo que
-- el dueño ya tiene construido y funcionando (1.171 celdas y 596 piezas, medido
-- en partida: 560 objetos de obra gracias a paños y cubos, es decir, 0,5 por
-- celda contando sus piezas). Se usa 0,6 por celda. Quien construya a mala idea
-- (cada cara de un material distinto) se topa antes con el tope de objetos del
-- cliente (Config.Obra.maxObjetos = 2.000), que es el que de verdad impide que
-- el juego se caiga: con él alcanzado no se puede poner nada más.
-- (13/10) La pieza pesaba 1 y el Premium se quedaba en 600 piezas: la casa del
-- dueño, que es la referencia de «a tope», ya tiene 645 y 1.166 celdas, y todo
-- junto son 581 objetos de obra medidos en partida (0,32 por celda o pieza). Con
-- 0,75 por pieza el Premium admite 800 y el peor caso sigue dentro del tope.
O.peso = { celda = 0.6, pieza = 0.75, mueble = 1.5, ascensor = 12, margen = 250 }

-- radio: celdas que puede alejarse la obra de la entrada, a cada lado y hacia
-- el fondo. plantasArriba / sotanos: cuántas plantas por encima y por debajo
-- de la baja. Ninguno puede pasar de los de config/obra.lua (radio, plantaMax,
-- plantaMin), que son los de la rejilla.
-- DECISIÓN DEL DUEÑO (14/10/2026): la Pequeña era muy grande. Se bajan Pequeña, Media
-- y Grande; el Premium se queda al máximo. Las casas que ya pasaban del tope nuevo
-- conservan lo construido: solo no pueden ampliar hasta quedar por debajo.
-- (la sala de partida son 25 celdas y llega 4 celdas al fondo: ningún radio baja de 4)
O.tamanos = {
    pequena = { nombre = 'Pequeña', descripcion = 'Un estudio: hasta 35 celdas de 2 × 2 m en una planta, con un sótano',
        celdas = 35, piezas = 30, muebles = 40, plantasArriba = 0, sotanos = 1, radio = 4, imagenes = 4, ascensores = 1 },
    media = { nombre = 'Media', descripcion = 'Una casa de familia: hasta 110 celdas, una planta más y un sótano',
        celdas = 110, piezas = 80, muebles = 90, plantasArriba = 1, sotanos = 1, radio = 7, imagenes = 10, ascensores = 1 },
    grande = { nombre = 'Grande', descripcion = 'Un chalé o una guarida: hasta 260 celdas, dos plantas más y dos sótanos',
        celdas = 260, piezas = 170, muebles = 150, plantasArriba = 2, sotanos = 2, radio = 11, imagenes = 20, ascensores = 2 },
    premium = { nombre = 'Premium', descripcion = 'Una mansión sin compromisos: hasta 1.200 celdas, cuatro plantas más y seis sótanos',
        celdas = 1200, piezas = 800, muebles = 250, plantasArriba = 4, sotanos = 6, radio = 24, imagenes = 40, ascensores = 4 },
}
O.tamanosOrden = { 'pequena', 'media', 'grande', 'premium' }
-- DECISIÓN DEL DUEÑO (14/10/2026): el número de muebles ya no tiene tope por tamaño
-- (quien decora cada rincón se quedaba con la casa a medias). Lo único que para es
-- lo que de verdad aguanta la casa: la cuenta exacta de objetos (Config.Obra.Carga
-- con las celdas, piezas y muebles REALES) contra Config.Obra.CargaMaxima(). Los
-- `muebles` de cada tamaño quedan solo como referencia del peor caso de arriba.
O.mueblesSinTope = true
-- Las casas que ya existían sin tamaño apuntado (las de pruebas)
O.tamanoPorDefecto = 'premium'
-- El que sale elegido al crear una casa, y el de una casa nueva que llegue sin él
O.tamanoNueva = 'pequena'
-- true: quien administra las viviendas (permiso «edit») construye sin topes de
-- tamaño. El tope de objetos del cliente (maxObjetos) le sigue parando.
O.adminSinTopes = false    -- (13/10) listo para abrir: la casa de pruebas del dueño ya cabe en Premium. true solo para probar sin topes

for id, t in pairs(O.tamanos) do t.id = id end

--- Un tamaño por su id; el de por defecto si no existe.
function Config.Obra.Tamano(id)
    return O.tamanos[id] or O.tamanos[O.tamanoPorDefecto]
end

--- Objetos que carga una casa en el peor caso. pesoMuebles: la suma de lo que
--- pesa cada mueble (Config.Obra.PesoMueble), o su número por el peso medio.
function Config.Obra.Carga(celdas, piezas, ascensores, pesoMuebles)
    local p = O.peso
    return celdas * p.celda + piezas * p.pieza + ascensores * (p.ascensor - p.pieza) + pesoMuebles
end

--- Lo más que puede cargar una casa (los 2.000 menos el margen)
function Config.Obra.CargaMaxima()
    return (O.maxObjetos or 2000) - O.peso.margen
end

--- Peor caso de un tamaño lleno hasta sus topes
function Config.Obra.PeorCaso(t)
    return Config.Obra.Carga(t.celdas, t.piezas, t.ascensores, t.muebles * O.peso.mueble)
end

--- Objetos que pone en el cliente un mueble: él y sus partes que se mueven, o
--- su modelo apagado si es una lámpara de las nuestras.
function Config.Obra.PesoMueble(modelo)
    local n = 1
    local def = Config.Almacenajes and Config.Almacenajes.Def and Config.Almacenajes.Def(modelo)
    if def then n = n + #def.partes end
    if Config.Luces and Config.Luces.Lampara and Config.Luces.Lampara(modelo) then n = n + 1 end
    return n
end

--- ¿Cabe la celda (i, j, k) en una casa de ese tamaño?
function Config.Obra.EnTamano(t, i, j, k)
    if k > t.plantasArriba then return false, 'arriba' end
    if k < -t.sotanos then return false, 'abajo' end
    if math.abs(i) > t.radio or j > t.radio then return false, 'lejos' end
    return true
end

-- ── Qué herramienta y qué estilo es una pieza ───────────────────────────
--- De una pieza de obra (su clave y su valor: ver custom/server/obra.lua), la
--- herramienta de la cinta con la que se pone y, si lo tiene, su estilo
--- ('barandillas:forja', 'secretos:libreria', 'trampillas:madera'): es lo que
--- se mira en los packs (Config.Packs.Tiene). nil si no es de ninguna.
function Config.Obra.QueEs(clave, valor)
    local t = tostring(clave):sub(1, 1)
    if t == 'x' or t == 'y' then
        if valor == 'p' then return 'pared' end
        if valor == 'u' then return 'puerta' end
        if valor == 'g' then return 'garaje' end
        if valor == 'd' then return 'puerta2' end
        if type(valor) ~= 'string' then return nil end
        local b = valor:match('^b:([%w_]+)$')
        if b then return 'barandilla', 'barandillas:' .. b end
        local s = valor:match('^o:([%w_]+)')
        if s then return 'secreto', 'secretos:' .. s end
        return nil
    elseif t == 'l' then
        local s = type(valor) == 'string' and valor:match('^o:([%w_]+)') or nil
        if s then return 'trampilla', 'trampillas:' .. s end
        return 'suelo'
    elseif t == 'e' then
        local forma = math.floor((tonumber(valor) or 0) / 4)
        if forma == 0 then return 'sube' end
        if forma == 1 or forma == 2 then return 'subeL' end
        if forma == 3 then return 'escala' end
        return 'caracol'
    elseif t == 'a' then
        return math.floor((tonumber(valor) or 0) / 100) > 0 and 'ascensor2' or 'ascensor'
    elseif t == 'c' then
        return 'montacoches'
    elseif t == 'r' or t == 'v' then
        return 'esquina'        -- esquina redondeada o canto (config/obra_esquinas.lua)
    end
    return nil
end

--- ¿Tiene la casa lo que hace falta para poner esa pieza? `acceso`: lo que
--- tiene desbloqueado, { packs = { [id] = true }, sueltas = { ['estilo:secretos:libreria'] = true } }
--- (Config.Packs.Permite). Si no, devuelve false y el id del pack que le falta.
--- Quien tiene un estilo comprado suelto puede ponerlo aunque no tenga el
--- pack de su herramienta.
function Config.Obra.PiezaPermitida(acceso, clave, valor)
    local herramienta, estilo = Config.Obra.QueEs(clave, valor)
    if estilo and Config.Packs.Suelta(acceso, 'estilo', estilo) then return true end
    if herramienta and not Config.Packs.Permite(acceso, 'herramienta', herramienta) then
        return false, Config.Packs.PackDe('herramienta', herramienta)
    end
    if estilo and not Config.Packs.Permite(acceso, 'estilo', estilo) then
        return false, Config.Packs.PackDe('estilo', estilo)
    end
    return true
end

-- ── Lo que cambia un cambio ─────────────────────────────────────────────
-- Un cambio de obra (`cam`, de custom/server/obra.lua) lleva en cam.celdas las
-- celdas que acaba de abrir (true) o cerrar (false) y en cam.antes lo que
-- había en cada pieza y cada pintura que toca ({ valor } por clave). Con eso y
-- con cómo ha quedado la obra se saca qué ha cambiado.

local function EsHueco(clave)
    local t = tostring(clave):sub(1, 1)
    return t == 'a' or t == 'c'
end

--- { abre, cierra, pone, quita, ascMas, ascMenos, nuevas = { { i, j, k } } }
function Config.Obra.Cuenta(cam, piezas)
    local r = { abre = 0, cierra = 0, pone = 0, quita = 0, ascMas = 0, ascMenos = 0, nuevas = {} }
    for celda, abierta in pairs(cam.celdas or {}) do
        if abierta then
            r.abre = r.abre + 1
            local i, j, k = tostring(celda):match('^(-?%d+):(-?%d+):(-?%d+)$')
            if i then r.nuevas[#r.nuevas + 1] = { tonumber(i), tonumber(j), tonumber(k) } end
        else
            r.cierra = r.cierra + 1
        end
    end
    for clave, a in pairs(cam.antes and cam.antes.piezas or {}) do
        local antes, ahora = a[1], piezas[clave]
        if antes == nil and ahora ~= nil then
            r.pone = r.pone + 1
            if EsHueco(clave) then r.ascMas = r.ascMas + 1 end
        elseif antes ~= nil and ahora == nil then
            r.quita = r.quita + 1
            if EsHueco(clave) then r.ascMenos = r.ascMenos + 1 end
        end
    end
    return r
end

--- ¿Se pasa la casa de su tamaño con ese cambio? `ahora`: { n, np, asc }, lo
--- que tiene ya con el cambio hecho. Devuelve el aviso para el jugador, o nil.
--- Solo se rechaza lo que hace crecer: una casa que ya esté por encima de su
--- tope (porque se le ha bajado el tamaño) puede quitar y cambiar, no añadir.
function Config.Obra.Excede(t, ahora, r)
    local nombre = t.nombre
    for _, c in ipairs(r.nuevas) do
        local cabe, por = Config.Obra.EnTamano(t, c[1], c[2], c[3])
        if not cabe then
            if por == 'arriba' then
                return ('Esta casa (%s) no admite más plantas hacia arriba: %d sobre la baja'):format(nombre, t.plantasArriba)
            elseif por == 'abajo' then
                return ('Esta casa (%s) no admite más sótanos: %d'):format(nombre, t.sotanos)
            end
            return ('Esta casa (%s) no puede alejarse más de la entrada: %d celdas'):format(nombre, t.radio)
        end
    end
    if r.abre > r.cierra and ahora.n > t.celdas then
        return ('Esta casa (%s) ya tiene su máximo de espacio excavado: %d celdas'):format(nombre, t.celdas)
    end
    if r.ascMas > r.ascMenos and ahora.asc > t.ascensores then
        return ('Esta casa (%s) ya tiene su máximo de ascensores y montacoches: %d'):format(nombre, t.ascensores)
    end
    if r.pone > r.quita and ahora.np > t.piezas then
        return ('Esta casa (%s) ya tiene su máximo de piezas (paredes, suelos, escaleras…): %d'):format(nombre, t.piezas)
    end
    return nil
end

-- ── Lo que cuesta ───────────────────────────────────────────────────────
-- Las cifras son de config/zz_economia.lua (Config.Economia), que se carga el
-- último: se leen al hacer la cuenta, no al cargar. Sin él, gratis.
-- El detalle lo dan sus funciones: Config.Economia.Pieza('e', forma) (la
-- escalera según su forma), Pieza('a', plantas, cabina) (el ascensor por
-- planta y por tamaño de cabina), Pieza('c', plantas) (el montacoches por
-- planta) y Config.Economia.Pintar(material). Si no estuvieran, se leen los
-- números sueltos de Config.Economia.obra:
--   { celda = N, pieza = { p, u, g, d, l, e, a, c, baranda, secreto, trampilla }, pintar = N, imagen = N, devolucion = 0.5 }
local function Precios()
    local e = Config.Economia and Config.Economia.obra
    return type(e) == 'table' and e or nil
end

local function Cifra(v)
    v = tonumber(v)
    return v and v > 0 and math.floor(v) or 0
end

local CABINA = { [0] = '1x1', [1] = '2x1', [2] = '2x1', [3] = '2x2' }

-- Precio de una pieza por su letra y su detalle, con la función de economía si la hay
local function DeEconomia(letra, dato, cabina)
    local E = Config.Economia
    if type(E.Pieza) == 'function' then
        local ok, n = pcall(E.Pieza, letra, dato, cabina)
        if ok and tonumber(n) then return Cifra(n) end
    end
    -- reserva: el número suelto (por planta en ascensores y montacoches)
    local p = E.obra.pieza
    local n = type(p) == 'table' and tonumber(p[letra]) or 0
    if letra == 'a' or letra == 'c' then n = n * math.max(1, math.floor(tonumber(dato) or 1)) end
    return Cifra(n)
end

--- Precio de una pieza por su clave y su valor (ver custom/server/obra.lua)
function Config.Obra.PrecioPieza(clave, valor)
    if not Precios() then return 0 end
    local t = tostring(clave):sub(1, 1)
    if t == 'x' or t == 'y' then
        if valor == 'G' then return 0 end       -- la otra mitad de un hueco doble: ya se cobró con la primera
        if valor == 'p' or valor == 'u' or valor == 'g' or valor == 'd' then return DeEconomia(valor) end
        if type(valor) == 'string' and valor:sub(1, 2) == 'b:' then return DeEconomia('baranda') end
        return DeEconomia('secreto')
    elseif t == 'l' then
        if type(valor) == 'string' then return DeEconomia('trampilla') end
        return DeEconomia('l')
    elseif t == 'e' then
        return DeEconomia('e', math.floor((tonumber(valor) or 0) / 4))      -- la forma: 0 recta, 1 y 2 en L, 3 de mano, 4 y 5 de caracol
    elseif t == 'a' then
        local v = tonumber(valor) or 0
        return DeEconomia('a', v % 10, CABINA[math.floor(v / 10) % 10])     -- plantas y huella de la cabina
    elseif t == 'c' then
        return DeEconomia('c', math.floor((tonumber(valor) or 0) / 10))     -- plantas
    elseif t == 'r' then
        return DeEconomia('esquina')        -- esquina redondeada, del radio que sea (config/obra_esquinas.lua)
    elseif t == 'v' then
        return DeEconomia('canto')          -- canto redondo de un saliente
    end
    return 0
end

--- Precio de algo suelto: 'celda', 'imagen'
function Config.Obra.Precio(que)
    local e = Precios()
    return e and Cifra(e[que]) or 0
end

--- Precio de pintar una cara con ese material
function Config.Obra.PrecioPintar(material)
    local e = Precios()
    if not e then return 0 end
    if type(Config.Economia.Pintar) == 'function' then
        local ok, n = pcall(Config.Economia.Pintar, material)
        if ok and tonumber(n) then return Cifra(n) end
    end
    return Cifra(e.pintar)
end

--- Fracción que se devuelve al quitar o rellenar (0…1)
function Config.Obra.Devolucion()
    local e = Precios()
    local d = e and tonumber(e.devolucion) or 0
    return math.max(0, math.min(1, d))
end

--- Lo que hay que cobrar y lo que hay que devolver por un cambio ya hecho.
--- Se cobra todo lo que aparece (también las paredes y los suelos que salen
--- solos al excavar junto a otro espacio) y se devuelve la fracción de todo lo
--- que desaparece: así no hay forma de sacar dinero poniendo y quitando.
--- Pintar solo se cobra cuando el cambio es de pintar (cam.pintar), por cara y
--- según el material: la pintura que hereda una celda nueva de la de al lado
--- va en el precio de la celda. Pintar no devuelve nada.
function Config.Obra.Coste(cam, piezas, pinturas)
    if not Precios() then return 0, 0 end
    local dev = Config.Obra.Devolucion()
    local celda = Config.Obra.Precio('celda')
    local cobrar, devolver = 0, 0
    for _, abierta in pairs(cam.celdas or {}) do
        if abierta then cobrar = cobrar + celda else devolver = devolver + celda * dev end
    end
    for clave, a in pairs(cam.antes and cam.antes.piezas or {}) do
        local antes, ahora = a[1], piezas[clave]
        if antes ~= ahora then
            if ahora ~= nil then cobrar = cobrar + Config.Obra.PrecioPieza(clave, ahora) end
            if antes ~= nil then devolver = devolver + Config.Obra.PrecioPieza(clave, antes) * dev end
        end
    end
    if cam.pintar then
        for clave, a in pairs(cam.antes and cam.antes.pinturas or {}) do
            local material = pinturas[clave]
            if material ~= nil and material ~= a[1] then cobrar = cobrar + Config.Obra.PrecioPintar(material) end
        end
    end
    return cobrar, math.floor(devolver)
end

--- Deja la obra como estaba antes de ese cambio (cuando no pasa los topes o
--- no se puede pagar). Toca solo las tablas que se le dan.
function Config.Obra.Revertir(cam, celdas, piezas, pinturas)
    for celda, abierta in pairs(cam.celdas or {}) do
        if abierta then celdas[celda] = nil else celdas[celda] = 1 end
    end
    for clave, a in pairs(cam.antes and cam.antes.piezas or {}) do piezas[clave] = a[1] end
    for clave, a in pairs(cam.antes and cam.antes.pinturas or {}) do pinturas[clave] = a[1] end
end

-- Aviso en la consola si algún tamaño, lleno, se pasa de lo que aguanta el juego
for _, id in ipairs(O.tamanosOrden) do
    local t = O.tamanos[id]
    local peor = Config.Obra.PeorCaso(t)
    if peor > Config.Obra.CargaMaxima() then
        print(('^1[origen_housing] El tamaño «%s» lleno cargaría %d objetos y el máximo es %d: baja sus topes (config/obra_tamanos.lua)^7'):format(
            t.nombre, math.floor(peor), Config.Obra.CargaMaxima()))
    end
    if t.radio > O.radio or t.plantasArriba > O.plantaMax or -t.sotanos < O.plantaMin then
        print(('^3[origen_housing] El tamaño «%s» pide más radio o más plantas de las que da la rejilla (config/obra.lua)^7'):format(t.nombre))
    end
end
