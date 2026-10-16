--[[ ══════════════════════════════════════════════════════════════════════════
     LA BARAJA

     Una carta es `{ v = 2..14, p = 'p'|'c'|'d'|'t' }`: valor y palo (picas,
     corazones, diamantes, tréboles). El 11, 12, 13 y 14 son J, Q, K y A.

     Este fichero es COMPARTIDO porque la pantalla necesita saber pintar una
     carta y decir cómo se llama una mano. Lo que no está compartido, y no
     puede estarlo, es de dónde salen las cartas: eso pasa entero en el
     servidor. El cliente recibe las cartas ya repartidas y nunca el mazo.
   ══════════════════════════════════════════════════════════════════════════ ]]

Baraja = {}

Baraja.PALOS = { 'p', 'c', 'd', 't' }
Baraja.NOMBRE_PALO = { p = 'Picas', c = 'Corazones', d = 'Diamantes', t = 'Tréboles' }
Baraja.ROJO = { c = true, d = true }

local FIGURAS = { [11] = 'J', [12] = 'Q', [13] = 'K', [14] = 'A' }

--- «A de picas», para el registro y para los avisos.
function Baraja.Nombre(carta)
    if not carta then return '?' end
    return (FIGURAS[carta.v] or tostring(carta.v)) .. ' de ' .. (Baraja.NOMBRE_PALO[carta.p] or '?'):lower()
end

function Baraja.Corta(carta)
    if not carta then return '??' end
    return (FIGURAS[carta.v] or tostring(carta.v)) .. carta.p
end

-- ── El mazo ───────────────────────────────────────────────────────────────

--- Un mazo de `n` barajas, ya revuelto.
function Baraja.Nueva(n)
    local mazo = {}
    for _ = 1, (n or 1) do
        for _, p in ipairs(Baraja.PALOS) do
            for v = 2, 14 do
                mazo[#mazo + 1] = { v = v, p = p }
            end
        end
    end
    return Casino.Barajar(mazo)
end

--[[ Saca una carta del mazo. El mazo se consume por el final, que es O(1):
     sacarla por el principio con `table.remove(mazo, 1)` mueve las otras 311
     cartas en cada reparto. ]]
function Baraja.Sacar(mazo)
    local carta = mazo[#mazo]
    mazo[#mazo] = nil
    return carta
end

-- ── Blackjack ─────────────────────────────────────────────────────────────

--[[ Lo que suma una mano y si es BLANDA (tiene un as contando por 11, o sea
     que todavía se puede pedir sin pasarse por culpa del as).

     Devuelve total, blanda. ]]
function Baraja.Puntos(cartas)
    local total, ases = 0, 0
    for _, c in ipairs(cartas) do
        if c.v == 14 then
            ases = ases + 1
            total = total + 11
        elseif c.v >= 10 then
            total = total + 10
        else
            total = total + c.v
        end
    end
    -- Cada as que se pasa baja de 11 a 1.
    while total > 21 and ases > 0 do
        total = total - 10
        ases = ases - 1
    end
    return total, ases > 0
end

function Baraja.EsBlackjack(cartas)
    if #cartas ~= 2 then return false end
    return Baraja.Puntos(cartas) == 21
end

-- ── Manos de póker ────────────────────────────────────────────────────────

--[[ El nombre de cada categoría, de menos a más. El número es lo que se
     compara: una mano se puntúa como categoría + los valores que la desempatan,
     empaquetados en base 15 para que quepan todos en un número y se puedan
     comparar con un `>` sin desempates a mano. ]]
Baraja.MANOS = {
    [0] = 'Carta alta',
    [1] = 'Pareja',
    [2] = 'Doble pareja',
    [3] = 'Trío',
    [4] = 'Escalera',
    [5] = 'Color',
    [6] = 'Full',
    [7] = 'Póker',
    [8] = 'Escalera de color',
    [9] = 'Escalera real',
}

local function Fuerza(categoria, valores)
    local n = categoria
    for i = 1, 5 do
        n = n * 15 + (valores[i] or 0)
    end
    return n
end

--- Cuenta cuántas hay de cada valor, y devuelve los grupos ordenados.
local function Grupos(cartas)
    local cuenta = {}
    for _, c in ipairs(cartas) do cuenta[c.v] = (cuenta[c.v] or 0) + 1 end
    local grupos = {}
    for v, n in pairs(cuenta) do grupos[#grupos + 1] = { v = v, n = n } end
    -- Primero por cuántas hay, y a igualdad por el valor: así el full de reyes
    -- con treses sale antes que el de treses con reyes.
    table.sort(grupos, function(a, b)
        if a.n ~= b.n then return a.n > b.n end
        return a.v > b.v
    end)
    return grupos
end

--[[ La escalera más alta que hay en una lista de valores. Devuelve el valor de
     la carta más alta, o nil.

     El as vale por 1 en la escalera pequeña (A-2-3-4-5), que es la única vez
     que un as no es la carta más alta de la mesa. ]]
local function Escalera(valores)
    local hay = {}
    for _, v in ipairs(valores) do hay[v] = true end
    if hay[14] then hay[1] = true end
    for alto = 14, 5, -1 do
        local completa = true
        for i = 0, 4 do
            if not hay[alto - i] then completa = false break end
        end
        if completa then return alto end
    end
    return nil
end

--- Puntúa EXACTAMENTE cinco cartas.
local function Cinco(cartas)
    local valores = {}
    local palos = {}
    for _, c in ipairs(cartas) do
        valores[#valores + 1] = c.v
        palos[c.p] = (palos[c.p] or 0) + 1
    end
    table.sort(valores, function(a, b) return a > b end)

    local color = false
    for _, n in pairs(palos) do if n == 5 then color = true end end
    local escalera = Escalera(valores)

    if color and escalera then
        local cat = escalera == 14 and 9 or 8
        return Fuerza(cat, { escalera }), cat
    end

    local grupos = Grupos(cartas)
    local orden = {}
    for _, g in ipairs(grupos) do
        for _ = 1, g.n do orden[#orden + 1] = g.v end
    end

    if grupos[1].n == 4 then return Fuerza(7, { grupos[1].v, grupos[2].v }), 7 end
    if grupos[1].n == 3 and grupos[2] and grupos[2].n == 2 then
        return Fuerza(6, { grupos[1].v, grupos[2].v }), 6
    end
    if color then return Fuerza(5, valores), 5 end
    if escalera then return Fuerza(4, { escalera }), 4 end
    if grupos[1].n == 3 then
        return Fuerza(3, { grupos[1].v, grupos[2].v, grupos[3] and grupos[3].v or 0 }), 3
    end
    if grupos[1].n == 2 and grupos[2] and grupos[2].n == 2 then
        return Fuerza(2, { grupos[1].v, grupos[2].v, grupos[3] and grupos[3].v or 0 }), 2
    end
    if grupos[1].n == 2 then
        local pateadores = {}
        for _, g in ipairs(grupos) do
            if g.n == 1 then pateadores[#pateadores + 1] = g.v end
        end
        return Fuerza(1, { grupos[1].v, pateadores[1] or 0, pateadores[2] or 0, pateadores[3] or 0 }), 1
    end
    return Fuerza(0, valores), 0
end

--[[ La mejor mano de cinco que se puede sacar de las que haya (dos y cinco en
     Hold em, o cinco a secas). Con siete cartas son 21 combinaciones: se
     prueban todas, que a este volumen sale más barato que ser listo.

     Devuelve { fuerza, categoria, nombre, cartas }. ]]
function Baraja.Mejor(cartas)
    local n = #cartas
    if n < 5 then
        local f, cat = 0, 0
        if n > 0 then
            local valores = {}
            for _, c in ipairs(cartas) do valores[#valores + 1] = c.v end
            table.sort(valores, function(a, b) return a > b end)
            f = Fuerza(0, valores)
        end
        return { fuerza = f, categoria = cat, nombre = Baraja.MANOS[cat], cartas = cartas }
    end

    local mejorF, mejorCat, mejores = -1, 0, nil
    local idx = { 1, 2, 3, 4, 5 }
    local function probar()
        local mano = {}
        for i = 1, 5 do mano[i] = cartas[idx[i]] end
        local f, cat = Cinco(mano)
        if f > mejorF then
            mejorF, mejorCat, mejores = f, cat, mano
        end
    end

    -- Todas las combinaciones de 5 entre n, sin recursión.
    local function avanzar(pos)
        if pos > 5 then probar() return end
        local desde = pos == 1 and 1 or idx[pos - 1] + 1
        for i = desde, n - (5 - pos) do
            idx[pos] = i
            avanzar(pos + 1)
        end
    end
    avanzar(1)

    return {
        fuerza = mejorF,
        categoria = mejorCat,
        nombre = Baraja.MANOS[mejorCat],
        cartas = mejores,
    }
end

-- ── Póker de tres cartas ──────────────────────────────────────────────────

--[[ Con tres cartas el orden cambia: la escalera es MÁS DIFÍCIL que el color,
     así que paga más. Es el error que comete todo el que copia la tabla del
     póker de cinco.

     Devuelve { categoria, clave, nombre, fuerza, alta }. ]]
Baraja.TRES = {
    [0] = { clave = 'cartaAlta', nombre = 'Carta alta' },
    [1] = { clave = 'pareja', nombre = 'Pareja' },
    [2] = { clave = 'color', nombre = 'Color' },
    [3] = { clave = 'escalera', nombre = 'Escalera' },
    [4] = { clave = 'trio', nombre = 'Trío' },
    [5] = { clave = 'escaleraColor', nombre = 'Escalera de color' },
}

function Baraja.ManoTres(cartas)
    local valores = {}
    local palos = {}
    for _, c in ipairs(cartas) do
        valores[#valores + 1] = c.v
        palos[c.p] = (palos[c.p] or 0) + 1
    end
    table.sort(valores, function(a, b) return a > b end)

    local color = false
    for _, n in pairs(palos) do if n == 3 then color = true end end

    -- Escalera de tres. El as por abajo (A-2-3) también cuenta.
    local escalera = false
    local alto = valores[1]
    if valores[1] - valores[2] == 1 and valores[2] - valores[3] == 1 then
        escalera = true
    elseif valores[1] == 14 and valores[2] == 3 and valores[3] == 2 then
        escalera = true
        alto = 3
    end

    local cat
    if escalera and color then cat = 5
    elseif valores[1] == valores[2] and valores[2] == valores[3] then cat = 4
    elseif escalera then cat = 3
    elseif color then cat = 2
    elseif valores[1] == valores[2] or valores[2] == valores[3] then cat = 1
    else cat = 0 end

    -- El desempate: en la pareja manda el valor repetido; en lo demás, el orden.
    local orden = valores
    if cat == 1 then
        local par = (valores[1] == valores[2]) and valores[1] or valores[2]
        local suelta = (valores[1] == valores[2]) and valores[3] or valores[1]
        orden = { par, par, suelta }
    elseif cat == 3 or cat == 5 then
        orden = { alto, alto - 1, alto - 2 }
    end

    local datos = Baraja.TRES[cat]
    return {
        categoria = cat,
        clave = datos.clave,
        nombre = datos.nombre,
        alta = valores[1],
        fuerza = Fuerza(cat, orden),
    }
end
