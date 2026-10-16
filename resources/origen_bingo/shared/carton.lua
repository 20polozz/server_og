--[[ El cartón del bingo español: 3 filas × 9 columnas, 15 números.

     · Cada fila lleva exactamente 5 números (y 4 huecos).
     · Cada columna, de 1 a 3 números, todos de su decena: la primera del 1 al
       9, la segunda del 10 al 19 … y la última del 80 al 90.
     · Dentro de una columna van de menor a mayor, de arriba abajo.

     Un cartón es { filas = { {9 casillas}, {9}, {9} } } con 0 en los huecos.
     Lo genera el servidor; el cliente solo lo pinta.

     Este fichero es Lua puro (sin natives) para poder probarlo fuera del
     juego: pruebas/probar.py. ]]

Carton = {}

local function Rango(col)
    if col == 1 then return 1, 9 end
    if col == 9 then return 80, 90 end
    return (col - 1) * 10, (col - 1) * 10 + 9
end
Carton.Rango = Rango

local function Barajar(t, azar)
    for i = #t, 2, -1 do
        local j = azar(1, i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

--- Un cartón nuevo. `azar(a, b)` es el math.random que toque (el de las pruebas
--- es fijo para poder repetirlas).
function Carton.Nuevo(azar)
    azar = azar or math.random

    -- Cuántos números lleva cada columna: uno cada una y seis más repartidos,
    -- sin pasar de tres.
    local cuenta = { 1, 1, 1, 1, 1, 1, 1, 1, 1 }
    local quedan = 6
    while quedan > 0 do
        local c = azar(1, 9)
        if cuenta[c] < 3 then
            cuenta[c] = cuenta[c] + 1
            quedan = quedan - 1
        end
    end

    --[[ En qué filas va cada columna. Las columnas más llenas primero, y cada
         una a las filas a las que más les falta para llegar a cinco (con
         empates al azar). Así siempre cuadra: las filas acaban con 5 cada una. ]]
    local orden = Barajar({ 1, 2, 3, 4, 5, 6, 7, 8, 9 }, azar)
    table.sort(orden, function(a, b) return cuenta[a] > cuenta[b] end)

    local falta = { 5, 5, 5 }
    local filasDe = {}
    for _, c in ipairs(orden) do
        local filas = Barajar({ 1, 2, 3 }, azar)
        table.sort(filas, function(a, b) return falta[a] > falta[b] end)
        local elegidas = {}
        for k = 1, cuenta[c] do
            elegidas[k] = filas[k]
            falta[filas[k]] = falta[filas[k]] - 1
        end
        table.sort(elegidas)
        filasDe[c] = elegidas
    end

    -- Los números de cada columna, sin repetir y de menor a mayor.
    local filas = { {}, {}, {} }
    for f = 1, 3 do
        for c = 1, 9 do filas[f][c] = 0 end
    end
    for c = 1, 9 do
        local a, b = Rango(c)
        local bolsa = {}
        for n = a, b do bolsa[#bolsa + 1] = n end
        Barajar(bolsa, azar)
        local nums = {}
        for k = 1, cuenta[c] do nums[k] = bolsa[k] end
        table.sort(nums)
        for k, f in ipairs(filasDe[c]) do filas[f][c] = nums[k] end
    end

    return { filas = filas }
end

--- ¿Es un cartón bien hecho? (Para las pruebas, y para no fiarse de nada que
--- venga de la base de datos.)
function Carton.Valido(carton)
    if type(carton) ~= 'table' or type(carton.filas) ~= 'table' or #carton.filas ~= 3 then return false end
    local vistos = {}
    for c = 1, 9 do
        local a, b = Rango(c)
        local antes, hay = 0, 0
        for f = 1, 3 do
            local n = carton.filas[f][c]
            if n ~= 0 then
                if n < a or n > b or n <= antes or vistos[n] then return false end
                vistos[n], antes, hay = true, n, hay + 1
            end
        end
        if hay < 1 or hay > 3 then return false end
    end
    for f = 1, 3 do
        local n = 0
        for c = 1, 9 do
            if carton.filas[f][c] ~= 0 then n = n + 1 end
        end
        if n ~= 5 then return false end
    end
    return true
end

--- Cuántos números le faltan a cada fila con las bolas que han salido.
--- `salidas` es un conjunto: salidas[n] = true.
function Carton.Faltan(carton, salidas)
    local r = { 0, 0, 0 }
    for f = 1, 3 do
        for c = 1, 9 do
            local n = carton.filas[f][c]
            if n ~= 0 and not salidas[n] then r[f] = r[f] + 1 end
        end
    end
    return r
end

--- La bolsa del bombo: los 90 números en un orden al azar.
function Carton.Bombo(azar)
    azar = azar or math.random
    local b = {}
    for n = 1, 90 do b[n] = n end
    return Barajar(b, azar)
end
