-- Imágenes en las caras de una casa de modalidad libre (custom/client/imagenes.lua
-- y custom/server/imagenes.lua): el jugador pega una imagen suya, de un enlace
-- de Fivemanage, sobre una pared, un suelo o un techo de su obra.
--
-- Este fichero se carga antes que config/obra.lua (orden alfabético): por eso
-- no cuelga de Config.Obra y lee sus medidas cuando se le llama, no al cargar.
Config.Imagenes = {
    maxPorCasa = 40,      -- imágenes puestas por casa
    ritmo = 1000,         -- ms mínimos entre dos cambios del mismo jugador (lo mira el servidor)
    maxUrl = 300,         -- largo máximo del enlace
    distancia = 25.0,     -- solo se dibujan las que quedan a menos de esto
    maxDui = 12,          -- navegadores vivos a la vez (las más cercanas)
    lado = 512,           -- píxeles del lado largo de cada navegador
    separacion = 0.015,   -- lo que se despega de la superficie, para que no parpadee con ella
    -- Medidas de las piezas (origen_housing/fuente/obra.py)
    alto = 3.20,          -- de suelo a techo
    losa = 0.15,          -- grueso de la losa
    pared = 0.10,         -- grueso del tabique
    -- Si alguna vez sale espejada o cabeza abajo, se corrige aquí sin tocar código
    espejoU = false,
    espejoV = false,
}

local EXTENSIONES = { png = true, jpg = true, jpeg = true, webp = true }

--- ¿Es un enlace que se puede poner? Solo https://r2.fivemanage.com/… acabado
--- en .png, .jpg, .jpeg o .webp, sin nada raro por medio. Lo mira el servidor
--- al guardar y el cliente antes de dárselo al navegador (ui/imagen.html lo
--- vuelve a mirar con el mismo patrón).
function Config.Imagenes.Valida(url)
    if type(url) ~= 'string' or #url > Config.Imagenes.maxUrl then return false end
    -- la lista de letras permitidas deja fuera espacios, comillas, < > ? # y demás
    if not url:match('^https://r2%.fivemanage%.com/[%w%-%._/%%]+$') then return false end
    if url:find('..', 1, true) or url:find('//', 9, true) then return false end
    local ext = url:lower():match('%.(%a+)$')
    return ext ~= nil and EXTENSIONES[ext] == true
end

-- ── Qué cara es cuál ────────────────────────────────────────────────────
-- Una imagen va en una cara: la clave de la pieza (ver custom/server/obra.lua)
-- más el lado, porque una pared y un suelo entre plantas tienen dos.
--   x:i:j:k  lado 'a' = la cara que se ve desde la celda (i,j);  'b' = desde la (i+1,j)
--   y:i:j:k  lado 'a' = desde la (i,j);  'b' = desde la (i,j+1)
--   l:i:j:k  lado 'a' = por arriba (suelo de la planta k);  'b' = por abajo (techo de la k-1)
--   s:i:j:k  siempre 'a' (suelo)        t:i:j:k  siempre 'b' (techo)
-- Tamaño (tam): en pared, 0 una celda de ancho y 1 dos (este borde y el
-- siguiente). En suelo y techo, 0 una celda, 1 dos a lo ancho, 2 dos hacia el
-- fondo y 3 las cuatro. Siempre crece hacia la celda siguiente (i+1, j+1).
local function Abierta(o, i, j, k) return o.celdas[i .. ':' .. j .. ':' .. k] ~= nil end

local function Partes(clave)
    local t, i, j, k = tostring(clave):match('^([stxyl]):(-?%d+):(-?%d+):(-?%d+)$')
    if not t then return end
    i, j, k = tonumber(i), tonumber(j), tonumber(k)
    if math.abs(i) > 999 or math.abs(j) > 999 or math.abs(k) > 999 then return end
    return t, i, j, k
end
Config.Imagenes.Partes = Partes

--- ¿Existe esa cara, entera, en la obra `o` ({ celdas, piezas })? Vale igual
--- en el servidor (antes de guardar) y en el cliente (antes de dibujar).
function Config.Imagenes.Cara(o, clave, lado, tam)
    local t, i, j, k = Partes(clave)
    if not t or (lado ~= 'a' and lado ~= 'b') or type(tam) ~= 'number' then return false end
    if t == 'x' or t == 'y' then
        if tam ~= 0 and tam ~= 1 then return false end
        for q = 0, tam do
            local bi, bj = i + (t == 'y' and q or 0), j + (t == 'x' and q or 0)
            local borde = ('%s:%d:%d:%d'):format(t, bi, bj, k)
            local u, v = Abierta(o, bi, bj, k), Abierta(o, bi + (t == 'x' and 1 or 0), bj + (t == 'y' and 1 or 0), k)
            local valor = o.piezas[borde]
            -- hay pared si da a macizo o si se ha levantado una entera (ni hueco de puerta ni de garaje)
            if not ((u ~= v and valor == nil) or (u and v and valor == 'p')) then return false end
            -- y la cara pedida tiene que dar a una celda abierta
            if lado == 'a' and not u then return false end
            if lado == 'b' and not v then return false end
        end
        if tam == 1 then
            -- entre las dos celdas desde las que se ve no puede haber otra pared
            local ci, cj = i + ((t == 'x' and lado == 'b') and 1 or 0), j + ((t == 'y' and lado == 'b') and 1 or 0)
            if o.piezas[('%s:%d:%d:%d'):format(t == 'x' and 'y' or 'x', ci, cj, k)] ~= nil then return false end
        end
        return true
    end

    if tam ~= 0 and tam ~= 1 and tam ~= 2 and tam ~= 3 then return false end
    local suelo
    if t == 's' then
        if lado ~= 'a' or Abierta(o, i, j, k - 1) then return false end
        suelo = true
    elseif t == 't' then
        if lado ~= 'b' or Abierta(o, i, j, k + 1) then return false end
        suelo = false
    else
        -- (sobre una trampilla, 'o:<estilo>' de config/secretos.lua, no: se mueve)
        if o.piezas[clave] ~= 1 then return false end
        suelo = lado == 'a'
        if not suelo then k = k - 1 end     -- por abajo es el techo de la planta de debajo
    end
    local ancho, largo = (tam == 1 or tam == 3) and 1 or 0, (tam == 2 or tam == 3) and 1 or 0
    for a = 0, ancho do
        for b = 0, largo do
            local ci, cj = i + a, j + b
            if not Abierta(o, ci, cj, k) then return false end
            if suelo then
                if Abierta(o, ci, cj, k - 1) and o.piezas[('l:%d:%d:%d'):format(ci, cj, k)] ~= 1 then return false end
            else
                if Abierta(o, ci, cj, k + 1) and o.piezas[('l:%d:%d:%d'):format(ci, cj, k + 1)] ~= 1 then return false end
            end
            -- sin paredes por medio
            if a < ancho and o.piezas[('x:%d:%d:%d'):format(ci, cj, k)] ~= nil then return false end
            if b < largo and o.piezas[('y:%d:%d:%d'):format(ci, cj, k)] ~= nil then return false end
        end
    end
    return true
end
