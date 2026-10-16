-- VALES DE CASA: una casa de construcción libre que el jugador consigue en la
-- tienda «Apoya al proyecto» (origen_vipsystem) y coloca él mismo donde quiera.
--
--   · La tienda da el vale (export DarValeCasa). Queda en «Mis cosas» como
--     «por colocar»; no caduca.
--   · Desde «Mis cosas» → «Colocar mi casa» se cierra la tienda y el jugador, a
--     pie, elige el punto de entrada con la barra de abajo (custom/client/vales.lua),
--     y le pone nombre y número.
--   · El servidor (custom/server/vales.lua) lo comprueba TODO otra vez con las
--     coordenadas reales del personaje, da de alta la casa por el mismo camino
--     que el panel de admin (House.new → saveHouse) y marca el vale como usado.
--
-- Se guarda en vales.json (nada de base de datos nueva).
Config.Vales = {
    -- Metros que tiene que haber, como mínimo, desde el punto que se elige hasta la
    -- entrada de CUALQUIER otra casa (de cualquier tipo), su punto de garaje, su punto
    -- de la calle (entrada de garaje de las libres), y la puerta o la recepción de un hotel.
    -- Por qué 10: la zona exterior de una casa colocada así es un cuadrado de
    -- 2 × `exterior.medio` de lado alrededor de la puerta; con 10 m entre puertas dos
    -- de esos cuadrados no llegan a tocarse nunca, las E de «entrar» (1,5–2 m) no se
    -- pisan y en una acera normal siguen cabiendo una casa por portal. Menos de 8 m y
    -- se montan los puntos; más de 15 m y en una calle de adosados no cabe nadie.
    distanciaMinima = 10.0,

    -- La zona exterior de la casa (donde su dueño puede poner muebles de fuera):
    -- un cuadrado de `medio` metros a cada lado de la puerta y `grosor` metros de alto.
    -- Pequeña a propósito: es la calle, no una parcela. 2 × medio × 1,42 tiene que
    -- ser menor que `distanciaMinima`.
    exterior = { medio = 2.5, grosor = 8.0 },

    -- ¿Admite vehículos la casa? (lo que el admin marca como «Acceso con vehículos»
    -- al crearla). true: su dueño puede poner la entrada de garaje y meter los coches
    -- que deje su tamaño (Config.Entradas.cochesPorTamano: 1/2/3/4). Sin esto el pack
    -- «Garaje y taller» no serviría de nada en estas casas.
    vehiculos = true,

    -- Sitios donde NO se puede poner una casa: centro y radio en metros.
    -- Rellénalo con lo que quieras proteger (comisarías, hospitales, concesionarios,
    -- garajes públicos, zonas de evento…). `nombre` es lo que lee el jugador.
    zonasProhibidas = {
        -- { nombre = 'la comisaría de Mission Row', x = 441.0,  y = -982.0,  z = 30.7, radio = 80.0 },
        -- { nombre = 'el hospital Pillbox',         x = 307.0,  y = -592.0,  z = 43.3, radio = 90.0 },
        -- { nombre = 'el concesionario',            x = -45.0,  y = -1098.0, z = 26.4, radio = 60.0 },
    },

    -- Altura (z) entre la que se admite una casa: fuera de aquí es el fondo del mar o el cielo
    zMin = -30.0, zMax = 900.0,

    -- Nombre de la casa: largo y qué letras valen (el servidor quita lo demás)
    nombre = { min = 3, max = 40 },
    -- Número de la casa: entero entre estos dos. No se repite en la misma calle.
    numero = { min = 1, max = 9999 },
    -- Palabras que no se admiten en el nombre (en minúsculas y sin tildes; se busca dentro del nombre)
    palabrasProhibidas = { 'nazi', 'hitler', 'puta', 'puto', 'maricon', 'nigger', 'nigga', 'subnormal' },

    -- Ritmo (ms): entre dos comprobaciones del sitio y entre dos intentos de colocar del mismo jugador
    ritmoComprobar = 350,
    ritmoColocar = 3000,
    -- Lo que dura abierto un configurador sin confirmar (s): pasado ese tiempo hay que abrirlo otra vez
    sesion = 900,
    -- Lo más que puede moverse el personaje (m/s) al confirmar: hay que estar parado
    velocidadMaxima = 1.5,
}

local V = Config.Vales

--- ¿Vale ese texto como nombre de casa? Devuelve el nombre limpio, o nil y el motivo.
--- Lua puro: lo usan el servidor (que manda) y el cliente (para avisar antes).
function Config.Vales.NombreLimpio(texto)
    if type(texto) ~= 'string' then return nil, 'Escribe un nombre para la casa' end
    -- sin saltos de línea ni controles; los espacios seguidos, uno
    texto = texto:gsub('[%c]', ' '):gsub('%s+', ' '):gsub('^%s+', ''):gsub('%s+$', '')
    -- nada que pueda ser HTML ni un formato raro: letras (con tildes), cifras, espacio y . , ' - º ª # ! ? ( )
    if texto:find('[<>&"`\\/{}%[%]|%%$^*=+~;:@]') then
        return nil, 'El nombre solo puede llevar letras, números, espacios y . , \' - # ! ?'
    end
    -- (las letras con tilde ocupan dos bytes: se cuenta por caracteres)
    local largo = 0
    for _ in texto:gmatch('[\1-\127\194-\244][\128-\191]*') do largo = largo + 1 end
    if largo < V.nombre.min then return nil, ('El nombre tiene que tener al menos %d letras'):format(V.nombre.min) end
    if largo > V.nombre.max then return nil, ('El nombre no puede pasar de %d letras'):format(V.nombre.max) end
    if not texto:find('[%a\194-\244]') then return nil, 'El nombre tiene que llevar alguna letra' end
    local llano = texto:lower()
    for con, sin in pairs({ ['á'] = 'a', ['é'] = 'e', ['í'] = 'i', ['ó'] = 'o', ['ú'] = 'u', ['ü'] = 'u',
        ['Á'] = 'a', ['É'] = 'e', ['Í'] = 'i', ['Ó'] = 'o', ['Ú'] = 'u', ['Ü'] = 'u' }) do
        llano = llano:gsub(con, sin)
    end
    for _, palabra in ipairs(V.palabrasProhibidas or {}) do
        if palabra ~= '' and llano:find(palabra, 1, true) then return nil, 'Ese nombre no se admite: elige otro' end
    end
    return texto
end

--- ¿Vale ese número de casa? Devuelve el entero, o nil y el motivo.
function Config.Vales.NumeroLimpio(valor)
    local n = tonumber(valor)
    if not n or n ~= n or n ~= math.floor(n) then return nil, 'El número de la casa tiene que ser un número entero' end
    n = math.floor(n)
    if n < V.numero.min or n > V.numero.max then
        return nil, ('El número de la casa tiene que estar entre %d y %d'):format(V.numero.min, V.numero.max)
    end
    return n
end

--- El nombre de una calle tal como lo da el juego, sin nada raro (lo manda el cliente: es solo un rótulo)
function Config.Vales.CalleLimpia(texto)
    if type(texto) ~= 'string' then return 'Los Santos' end
    texto = texto:gsub('[%c<>&"`\\{}%[%]|]', ' '):gsub('%s+', ' '):gsub('^%s+', ''):gsub('%s+$', '')
    if texto == '' then return 'Los Santos' end
    return texto:sub(1, 60)
end

--- ¿Está el punto (x, y) dentro de ese polígono ({ {x, y}, … })?
function Config.Vales.Dentro(puntos, x, y)
    local n, dentro = #puntos, false
    local j = n
    for i = 1, n do
        local a, b = puntos[i], puntos[j]
        local ax, ay, bx, by = tonumber(a.x), tonumber(a.y), tonumber(b.x), tonumber(b.y)
        if ax and ay and bx and by and ((ay > y) ~= (by > y)) and (x < (bx - ax) * (y - ay) / (by - ay) + ax) then
            dentro = not dentro
        end
        j = i
    end
    return dentro
end
