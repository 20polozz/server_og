--[[ Un CAMBIO es una línea del presupuesto: «alerón 3», «pintura primaria
     roja metalizada», «neón en los cuatro lados». Es lo único que viaja
     entre la pantalla, el cliente y el servidor, y significa lo mismo en los
     tres sitios:

       · el cliente lo aplica al coche para enseñarlo (client/aplicar.lua);
       · el servidor lo valida, le pone precio y lo escribe en las
         propiedades que guarda (Cambios.Escribir).

     El servidor NUNCA guarda propiedades que le mande un cliente: parte de
     las que ya había en la base de datos y les aplica los cambios pagados.
     Así, un cliente tocado puede enseñarse lo que quiera en su pantalla, pero
     solo se queda en el coche lo que alguien ha pagado.

     Formas:
       { k = 'mod',         i = 0..49, v = -1..n }        pieza (v = -1: de serie)
       { k = 'interruptor', i = 18|20|22, v = bool }       turbo, humo, xenón
       { k = 'llanta',      tipo = 0..12, v = -1..n }
       { k = 'neumaticos',  v = bool }                     perfil personalizado
       { k = 'pintura',     capa = 'primaria'|'secundaria', color = n | {r,g,b}, acabado = 0..3 }
       { k = 'perla' | 'llantasColor' | 'interior' | 'salpicadero', v = n }
       { k = 'vinilo',      v = -1..n, modo = 'mod'|'livery' }
       { k = 'xenonColor',  v = -1..12 }
       { k = 'neon',        lados = { bool, bool, bool, bool } }
       { k = 'neonColor' | 'humo', c = {r,g,b} }
       { k = 'tintado' | 'matricula', v = n }
       { k = 'extra',       i = 1..15, v = bool }
]]

Cambios = {}

local function Entero(v, min, max)
    v = tonumber(v)
    if not v or v ~= v or v == math.huge or v == -math.huge then return nil end
    v = math.floor(v)
    if v < min or v > max then return nil end
    return v
end

local function RGB(t)
    if type(t) ~= 'table' then return nil end
    local r, g, b = Entero(t[1] or t.r, 0, 255), Entero(t[2] or t.g, 0, 255), Entero(t[3] or t.b, 0, 255)
    if not r or not g or not b then return nil end
    return { r, g, b }
end

local COLORES = { perla = 'pearlescentColor', llantasColor = 'wheelColor', interior = 'interiorColor', salpicadero = 'dashboardColor' }
local CAPAS = { primaria = { 'color1', 'paintType1' }, secundaria = { 'color2', 'paintType2' } }
local CAMALEON_MIN, CAMALEON_MAX, TIPO_CARTA = 161, 242, 7

local function EsCamaleon(n)
    n = tonumber(n)
    return n ~= nil and n >= CAMALEON_MIN and n <= CAMALEON_MAX
end

--- Devuelve el cambio saneado o nil si no es un cambio válido. Todo lo que
--- no esté en la forma de arriba se descarta, campo a campo.
function Cambios.Normalizar(c)
    if type(c) ~= 'table' then return nil end
    local k = c.k

    if k == 'mod' then
        local i = Entero(c.i, 0, 49)
        if not i or not Catalogo.Mods[i] then return nil end
        local v = Entero(c.v, -1, 255)
        return v and { k = k, i = i, v = v } or nil
    elseif k == 'interruptor' then
        local i = Entero(c.i, 18, 22)
        if not i or not Catalogo.Interruptores[i] then return nil end
        return { k = k, i = i, v = c.v == true }
    elseif k == 'llanta' then
        local tipo, v = Entero(c.tipo, 0, 12), Entero(c.v, -1, 255)
        return tipo and v and { k = k, tipo = tipo, v = v } or nil
    elseif k == 'neumaticos' then
        return { k = k, v = c.v == true }
    elseif k == 'pintura' then
        if not CAPAS[c.capa] then return nil end
        local acabado = Entero(c.acabado, 0, 3) or 0
        if type(c.color) == 'table' then
            local rgb = RGB(c.color)
            return rgb and { k = k, capa = c.capa, color = rgb, acabado = acabado } or nil
        end
        local n = Entero(c.color, 0, Catalogo.ColorMax)
        return n and { k = k, capa = c.capa, color = n } or nil
    elseif COLORES[k] then
        local v = Entero(c.v, 0, Catalogo.ColorMax)
        return v and { k = k, v = v } or nil
    elseif k == 'vinilo' then
        local v = Entero(c.v, -1, 64)
        if not v then return nil end
        return { k = k, v = v, modo = c.modo == 'livery' and 'livery' or 'mod' }
    elseif k == 'xenonColor' then
        local v = Entero(c.v, -1, Catalogo.XenonMax)
        return v and { k = k, v = v } or nil
    elseif k == 'neon' then
        if type(c.lados) ~= 'table' then return nil end
        return { k = k, lados = { c.lados[1] == true, c.lados[2] == true, c.lados[3] == true, c.lados[4] == true } }
    elseif k == 'neonColor' or k == 'humo' then
        local rgb = RGB(c.c)
        return rgb and { k = k, c = rgb } or nil
    elseif k == 'tintado' then
        local v = Entero(c.v, 0, 6)
        return v and { k = k, v = v } or nil
    elseif k == 'matricula' then
        local v = Entero(c.v, 0, 5)
        return v and { k = k, v = v } or nil
    elseif k == 'extra' then
        local i = Entero(c.i, 1, 15)
        return i and { k = k, i = i, v = c.v == true } or nil
    end

    return nil
end

--- La clave que identifica QUÉ se cambia: dos cambios con la misma clave se
--- pisan (el segundo alerón sustituye al primero, no se suma).
function Cambios.Clave(c)
    if c.k == 'mod' or c.k == 'interruptor' or c.k == 'extra' then return c.k .. ':' .. c.i end
    if c.k == 'pintura' then return 'pintura:' .. c.capa end
    return c.k
end

local function Iguales(a, b)
    if type(a) ~= 'table' or type(b) ~= 'table' then return a == b end
    for i = 1, math.max(#a, #b) do
        if a[i] ~= b[i] then return false end
    end
    return true
end

local function Extras(props)
    return type(props.extras) == 'table' and props.extras or {}
end

--- Lo que tiene ahora el coche en la parcela que toca el cambio, con la misma
--- forma que el cambio. Sirve para saber si un cambio de verdad cambia algo:
--- volver a poner lo que ya había no se cobra.
function Cambios.Actual(props, c)
    props = props or {}
    local k = c.k

    if k == 'mod' then
        local campo = Catalogo.Mods[c.i].campo
        return tonumber(props[campo]) or -1
    elseif k == 'interruptor' then
        return props[Catalogo.Interruptores[c.i].campo] == true
    elseif k == 'llanta' then
        return { tonumber(props.wheels) or 0, tonumber(props.modFrontWheels) or -1 }
    elseif k == 'neumaticos' then
        return props.modCustomTiresF == true
    elseif k == 'pintura' then
        local campos = CAPAS[c.capa]
        local color = props[campos[1]]
        if type(color) == 'table' then
            return { color[1], color[2], color[3], tonumber(props[campos[2]]) or 0 }
        end
        local n = tonumber(color) or 0
        if tonumber(props[campos[2]]) == 6 then return { n, 6 } end
        if EsCamaleon(n) then return { n, tonumber(props[campos[2]]) or 0 } end
        return n
    elseif COLORES[k] then
        return tonumber(props[COLORES[k]]) or 0
    elseif k == 'vinilo' then
        return tonumber(c.modo == 'livery' and props.livery or props.modLivery) or -1
    elseif k == 'xenonColor' then
        return tonumber(props.xenonColor) or -1
    elseif k == 'neon' then
        local n = type(props.neonEnabled) == 'table' and props.neonEnabled or {}
        return { n[1] == true, n[2] == true, n[3] == true, n[4] == true }
    elseif k == 'neonColor' then
        return type(props.neonColor) == 'table' and props.neonColor or { 255, 0, 255 }
    elseif k == 'humo' then
        return type(props.tyreSmokeColor) == 'table' and props.tyreSmokeColor or { 255, 255, 255 }
    elseif k == 'tintado' then
        return tonumber(props.windowTint) or 0
    elseif k == 'matricula' then
        return tonumber(props.plateIndex) or 0
    elseif k == 'extra' then
        local e = Extras(props)
        local v = e[c.i] or e[tostring(c.i)]
        return v == 0
    end
end

--- El valor del cambio en la misma forma que Cambios.Actual.
function Cambios.Valor(c)
    local k = c.k
    if k == 'llanta' then return { c.tipo, c.v } end
    if k == 'pintura' then
        if type(c.color) == 'table' then return { c.color[1], c.color[2], c.color[3], c.acabado or 0 } end
        if EsCamaleon(c.color) then return { c.color, TIPO_CARTA } end
        return c.color
    end
    if k == 'neon' then return c.lados end
    if k == 'neonColor' or k == 'humo' then return c.c end
    return c.v
end

function Cambios.CambiaAlgo(props, c)
    return not Iguales(Cambios.Actual(props, c), Cambios.Valor(c))
end

--- Escribe el cambio en una tabla de propiedades de ox_lib. `esMoto` pone la
--- llanta también detrás (en un coche la rueda trasera la decide el juego).
function Cambios.Escribir(props, c, esMoto)
    local k = c.k

    if k == 'mod' then
        props[Catalogo.Mods[c.i].campo] = c.v
    elseif k == 'interruptor' then
        props[Catalogo.Interruptores[c.i].campo] = c.v
    elseif k == 'llanta' then
        props.wheels = c.tipo
        props.modFrontWheels = c.v
        if esMoto then props.modBackWheels = c.v end
    elseif k == 'neumaticos' then
        props.modCustomTiresF = c.v
        props.modCustomTiresR = c.v
    elseif k == 'pintura' then
        local campos = CAPAS[c.capa]
        if type(c.color) == 'table' then
            props[campos[1]] = { c.color[1], c.color[2], c.color[3] }
            props[campos[2]] = c.acabado or 0
        else
            props[campos[1]] = c.color
            if EsCamaleon(c.color) then
                props[campos[2]] = TIPO_CARTA
            elseif tonumber(props[campos[2]]) == 6 then
                props[campos[2]] = TIPO_CARTA
            end
        end
    elseif COLORES[k] then
        props[COLORES[k]] = c.v
    elseif k == 'vinilo' then
        if c.modo == 'livery' then props.livery = c.v else props.modLivery = c.v end
    elseif k == 'xenonColor' then
        props.xenonColor = c.v
    elseif k == 'neon' then
        props.neonEnabled = { c.lados[1], c.lados[2], c.lados[3], c.lados[4] }
    elseif k == 'neonColor' then
        props.neonColor = { c.c[1], c.c[2], c.c[3] }
    elseif k == 'humo' then
        props.tyreSmokeColor = { c.c[1], c.c[2], c.c[3] }
    elseif k == 'tintado' then
        props.windowTint = c.v
    elseif k == 'matricula' then
        props.plateIndex = c.v
    elseif k == 'extra' then
        -- La forma de ox_lib: 0 = puesto, 1 = quitado. Clave en texto, que es
        -- como vuelve del JSON de la base de datos: con la numérica al lado
        -- quedarían las dos.
        props.extras = Extras(props)
        props.extras[c.i] = nil
        props.extras[tostring(c.i)] = c.v and 0 or 1
    end

    return props
end

--[[ El precio de un cambio, sin multiplicador de clase. `precios` es la
     tabla viva (la de la base de datos, rellenada con Config.Precios). Un
     cambio que no cambia nada vale 0; quitar una pieza (volver a la de serie)
     también. ]]
function Cambios.Precio(c, precios, props)
    if props and not Cambios.CambiaAlgo(props, c) then return 0 end
    local k = c.k
    local P = precios

    if k == 'mod' then
        local def = Catalogo.Mods[c.i]
        if c.v < 0 then return 0 end
        local p = P[def.precio]
        if type(p) == 'table' then return tonumber(p[c.v + 1]) or tonumber(p[#p]) or 0 end
        return tonumber(p) or 0
    elseif k == 'interruptor' then
        return c.v and (tonumber(P[Catalogo.Interruptores[c.i].precio]) or 0) or 0
    elseif k == 'llanta' then
        return c.v < 0 and 0 or (tonumber(P.llantas) or 0)
    elseif k == 'neumaticos' then
        return c.v and (tonumber(P.neumaticos) or 0) or 0
    elseif k == 'pintura' then
        return tonumber(type(c.color) == 'table' and P.pinturaRGB or P.pinturaGTA) or 0
    elseif k == 'perla' then return tonumber(P.perla) or 0
    elseif k == 'llantasColor' then return tonumber(P.colorLlantas) or 0
    elseif k == 'interior' then return tonumber(P.colorInterior) or 0
    elseif k == 'salpicadero' then return tonumber(P.colorSalpicadero) or 0
    elseif k == 'vinilo' then return c.v < 0 and 0 or (tonumber(P.vinilo) or 0)
    elseif k == 'xenonColor' then return tonumber(P.colorXenon) or 0
    elseif k == 'neon' then
        local n = 0
        for i = 1, 4 do if c.lados[i] then n = n + 1 end end
        return n * (tonumber(P.neon) or 0)
    elseif k == 'neonColor' then return tonumber(P.colorNeon) or 0
    elseif k == 'humo' then return tonumber(P.humo) or 0
    elseif k == 'tintado' then return c.v == 0 and 0 or (tonumber(P.tintado) or 0)
    elseif k == 'matricula' then return tonumber(P.matricula) or 0
    elseif k == 'extra' then return tonumber(P.extra) or 0
    end
    return 0
end

function Cambios.Multiplicador(clase)
    local m = Config.MultiplicadorClase[tonumber(clase) or -1] or 1.0
    local t = Config.MultiplicadorTope
    return math.max(t.min, math.min(t.max, m))
end
