-- Entradas: dónde aparece quien entra en una casa y por dónde se sale, elegido
-- por el dueño desde dentro (custom/client/entradas.lua, custom/server/entradas.lua).
--
--  · Entrada a pie (todas las casas de módulo, también las de modalidad libre):
--    el sitio de dentro en el que aparece quien entra por la puerta, y hacia
--    dónde mira. Ese mismo sitio es el punto de salir. Sin elegir, es el de
--    siempre (el del módulo; en las libres, la celda 0,0 de la planta baja).
--  · Entrada de garaje (solo casas de modalidad libre con «Acceso con
--    vehículos», data.allowVehicles, que marca el admin al crear o editar la
--    casa): dos puntos. Uno DENTRO, donde aparece el coche (un hueco de 2 por
--    3 celdas con suelo), y otro FUERA, en la calle, desde el que se entra al
--    volante y al que se sale.
--
-- Se guarda en entradas.json, por id de casa:
--   pie   = { x, y, z, h, i, j, k }   desde el origen del módulo (i, j, k solo en las libres)
--   coche = { i, j, k, g, q }         la esquina de la huella, su planta, g = 0 (2 celdas en X
--                                     por 3 en Y) o 1 (3 por 2), y q = hacia dónde mira el
--                                     coche: 0 al fondo (+Y), 1 a -X, 2 a -Y, 3 a +X
--   calle = { x, y, z, h }            en el mapa
Config.Entradas = {
    -- Hasta dónde se puede poner el punto de la calle, medido desde la puerta de la casa
    radioCalle = 25.0,
    -- A qué distancia de cada punto se ofrece la E al conductor (cliente)…
    usoCalle = 4.0,
    usoDentro = 3.5,
    -- …y cuánto se lo cree el servidor (el coche se mide donde lo ve el servidor, que va algo por detrás)
    margen = 8.0,
    -- Vehículos que caben dentro de una casa, según su tamaño (config/obra_tamanos.lua).
    -- Si un tamaño lleva allí su propio `coches`, manda ese; sin tamaño, maxCoches.
    cochesPorTamano = { pequena = 1, media = 2, grande = 3, premium = 4 },
    maxCoches = 2,
    -- Solo entran coches con dueño, y que sean de quien conduce o de alguien con
    -- llave de la casa: uno robado o de otro no se puede esconder dentro.
    soloPropios = true,
    ritmo = 1500,           -- ms entre dos cambios de puntos del mismo jugador
    ritmoCoche = 2500,      -- ms entre dos entradas o salidas con coche del mismo jugador
    -- Los coches no se quedan en una casa vacía: cuando sale (o se desconecta) el
    -- último que estaba dentro, los que haya se sacan al punto de la calle, uno
    -- detrás de otro cada tantos metros hacia delante. Ver custom/server/entradas.lua.
    fila = 6.5,
    repaso = 60000,         -- ms entre dos repasos de casas vacías con coches dentro
    -- El felpudo de la entrada a pie: ancho y largo, en metros
    felpudo = { 1.1, 0.7 },
}

local E = Config.Entradas

-- Las dos herramientas de la cinta («Entrada» y «Entrada de garaje»): su
-- subgrupo y su ayuda (config/cinta.lua, que se carga antes que este fichero).
if Config.Cinta then
    if type(Config.Cinta.herramientas) == 'table' then
        Config.Cinta.herramientas.entrada = 'Estructura'
        Config.Cinta.herramientas.cochera = 'Ascensores y coches'
    end
    if type(Config.Cinta.ayuda) == 'table' then
        Config.Cinta.ayuda['h:entrada'] = { 'Elige dónde aparece quien entra en la casa; por ahí mismo se sale.',
            'Ve andando al sitio, mira hacia donde quieres que mire quien entra y haz clic.',
            'Se cambia poniéndola en otro sitio; en el menú de la casa (Entradas) vuelve a la puerta de siempre.' }
        Config.Cinta.ayuda['h:cochera'] = { 'Elige dónde aparece el coche al entrar por la entrada de garaje: un hueco de 2 por 3 celdas con suelo.',
            'Ponte en el centro del hueco, mirando hacia donde mirará el coche, y haz clic.',
            'El punto de la calle se pone desde fuera: menú de la casa (Entradas) o /entradas.' }
    end
end

local function Partes(clave)
    local t, i, j, k = tostring(clave):match('^(%a):(-?%d+):(-?%d+):(-?%d+)$')
    if not t then return nil end
    return t, tonumber(i), tonumber(j), tonumber(k)
end
E.Partes = Partes

function E.Abierta(o, i, j, k)
    return o.celdas[i .. ':' .. j .. ':' .. k] ~= nil
end

--- Celda (i, j) de un punto, en las medidas de la obra (x a lo ancho, y hacia el fondo).
function E.Celda(x, y)
    local c = Config.Obra.celda
    return math.floor(x / c + 0.5), math.floor(y / c)
end

--- ¿Pasa un hueco de ascensor o de montacoches por la celda (i, j, k)?
function E.HuecoEn(o, i, j, k)
    for clave, valor in pairs(o.piezas) do
        local t, hi, hj, hk = Partes(clave)
        valor = tonumber(valor)
        if valor and t == 'a' then
            local f = math.floor(valor / 10) % 10
            if k >= hk and k < hk + valor % 10 and i >= hi and i <= hi + ((f == 1 or f == 3) and 1 or 0)
                and j >= hj and j <= hj + ((f == 2 or f == 3) and 1 or 0) then
                return clave
            end
        elseif valor and t == 'c' then
            local n, g = math.floor(valor / 10), valor % 10
            if k >= hk and k < hk + n and i >= hi and i <= hi + (g == 1 and 2 or 1) and j >= hj and j <= hj + (g == 1 and 1 or 2) then
                return clave
            end
        end
    end
    return nil
end

--- ¿Pisa la celda (i, j) una escalera que arranca en la planta k? Con `hueco`,
--- solo si es de las celdas que arriba se quedan sin suelo.
function E.EscaleraEn(o, i, j, k, hueco)
    for clave, valor in pairs(o.piezas) do
        local t, ei, ej, ek = Partes(clave)
        if t == 'e' and ek == k then
            for _, c in ipairs(Config.Obra.Escalera(ei, ej, valor) or {}) do
                if c[1] == i and c[2] == j and (not hueco or c[3] ~= true) then return true end
            end
        end
    end
    return false
end

--- ¿Tiene suelo esa celda? El suyo (debajo está macizo) o uno entre plantas
--- (una trampilla no cuenta: se abre).
function E.ConSuelo(o, i, j, k)
    if not E.Abierta(o, i, j, k) then return false end
    return not E.Abierta(o, i, j, k - 1) or o.piezas[('l:%d:%d:%d'):format(i, j, k)] == 1
end

--- ¿Vale esa celda para aparecer en ella? Abierta, con suelo, y sin ascensor ni
--- escalera. Devuelve true, o false y el motivo.
function E.CeldaVale(o, i, j, k)
    if not E.Abierta(o, i, j, k) then return false, 'Ahí no hay sitio abierto' end
    if E.HuecoEn(o, i, j, k) then return false, 'Ahí pasa un ascensor' end
    if E.EscaleraEn(o, i, j, k) or E.EscaleraEn(o, i, j, k - 1, true) then return false, 'Ahí hay una escalera' end
    if not E.ConSuelo(o, i, j, k) then return false, 'Ahí no hay suelo' end
    return true
end

--- La huella del coche (2 por 3 celdas) alrededor de un punto, mirando hacia el
--- rumbo h (el del juego: 0 es el fondo de la casa). Se cuadra con la rejilla:
--- centrada en la raya entre dos celdas a lo ancho y en una celda a lo largo.
function E.Huella(x, y, h, k)
    local c = Config.Obra.celda
    local q = math.floor((((tonumber(h) or 0.0) % 360.0) + 45.0) / 90.0) % 4
    local g = q % 2
    local i, j
    if g == 0 then
        i, j = math.floor((x - c / 2) / c + 0.5), math.floor(y / c) - 1
    else
        i, j = math.floor(x / c + 0.5) - 1, math.floor(y / c + 0.5) - 1
    end
    return { i = i, j = j, k = k, g = g, q = q }
end

--- ¿Es una huella bien formada? (lo que llega del fichero o de fuera)
function E.HuellaBien(hu)
    if type(hu) ~= 'table' then return false end
    for _, n in ipairs({ 'i', 'j', 'k', 'g', 'q' }) do
        local v = hu[n]
        if type(v) ~= 'number' or v ~= math.floor(v) or math.abs(v) > 1000 then return false end
    end
    return (hu.g == 0 or hu.g == 1) and hu.q >= 0 and hu.q <= 3 and hu.q % 2 == hu.g
end

--- Las seis celdas de una huella: { { i, j }, … }
function E.CeldasDeHuella(hu)
    local r = {}
    for a = 0, (hu.g == 1 and 2 or 1) do
        for b = 0, (hu.g == 1 and 1 or 2) do r[#r + 1] = { hu.i + a, hu.j + b } end
    end
    return r
end

function E.EnHuella(hu, i, j, k)
    if not hu or k ~= hu.k then return false end
    return i >= hu.i and i <= hu.i + (hu.g == 1 and 2 or 1) and j >= hu.j and j <= hu.j + (hu.g == 1 and 1 or 2)
end

--- Centro de la huella a ras de su suelo (x, y, z en las medidas de la obra) y el rumbo del coche.
function E.CentroDeHuella(hu)
    local c = Config.Obra.celda
    local x = hu.g == 1 and c * (hu.i + 1) or (c * hu.i + c / 2)
    local y = hu.g == 1 and c * (hu.j + 1) or (c * (hu.j + 1) + c / 2)
    return x, y, hu.k * Config.Obra.planta, hu.q * 90.0
end

--- ¿Cabe ahí el coche? Las seis celdas abiertas, con suelo, sin ascensor ni
--- escalera, y sin nada puesto entre ellas. Devuelve true, o false y el motivo.
function E.HuellaVale(o, hu)
    local dentro = {}
    for _, c in ipairs(E.CeldasDeHuella(hu)) do
        if not Config.Obra.EnLimites(c[1], c[2], hu.k) or not E.Abierta(o, c[1], c[2], hu.k) then
            return false, 'El coche necesita un hueco abierto de 2 por 3 celdas'
        end
        local vale, motivo = E.CeldaVale(o, c[1], c[2], hu.k)
        if not vale then return false, motivo .. ': el coche necesita 2 por 3 celdas con suelo' end
        dentro[c[1] .. ':' .. c[2]] = true
    end
    for _, c in ipairs(E.CeldasDeHuella(hu)) do
        if (dentro[(c[1] + 1) .. ':' .. c[2]] and o.piezas[('x:%d:%d:%d'):format(c[1], c[2], hu.k)] ~= nil)
            or (dentro[c[1] .. ':' .. (c[2] + 1)] and o.piezas[('y:%d:%d:%d'):format(c[1], c[2], hu.k)] ~= nil) then
            return false, 'Hay una pared o una barandilla en medio del hueco del coche'
        end
    end
    return true
end

--- Cuántos vehículos caben dentro de una casa de ese tamaño (id de
--- Config.Obra.tamanos). Si el tamaño trae su propio `coches`, manda ese.
function E.Tope(tamano)
    local t = tamano and Config.Obra and Config.Obra.tamanos and Config.Obra.tamanos[tamano]
    local n = type(t) == 'table' and tonumber(t.coches) or E.cochesPorTamano[tamano or '']
    return math.max(0, math.floor(tonumber(n) or E.maxCoches))
end

--- Nombre de una planta, para los textos
function E.NombrePlanta(k)
    if k == 0 then return 'Planta baja' end
    return k > 0 and ('Planta ' .. k) or ('Sótano ' .. -k)
end
