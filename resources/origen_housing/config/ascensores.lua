-- Ascensores y elevadores de coche de las viviendas (custom/client/ascensores.lua
-- y custom/server/ascensores.lua).
--
-- Son muebles del catálogo (config/furniture.lua, categoría «Ascensores»): se
-- compran y se colocan como cualquier otro, con la cinta o con el menú Decorar.
-- No se guarda nada aparte: las piezas enlazadas son todas las de su clase
-- que haya en la misma casa y en la misma zona (interior o exterior).
--   · type = 'elevator'  cabina para personas. A pie, junto a ella, E.
--   · type = 'carlift'   plataforma para coches. Al volante, encima de ella, E.
-- Con dos piezas se va derecho a la otra; con tres o más se elige planta en el
-- menú «Ascensor» del housing (las plantas van numeradas de abajo arriba).
--
-- Este fichero se carga antes que config/furniture.lua (orden alfabético): por
-- eso los modelos se dan de alta allí y aquí solo va cómo se comportan.
Config.Ascensores = {
    -- qué clase de pieza es cada tipo de mueble del catálogo
    tipos = { elevator = 'persona', carlift = 'coche' },

    ritmo = 3000,       -- ms mínimos entre dos viajes del mismo jugador (lo mira el servidor)
    -- Ir de una plataforma a otra apareciendo allí. Quitado: para cambiar de
    -- planta están el ascensor y el montacoches de obra, que se mueven de verdad.
    llevar = false,

    -- Por clase:
    --   radio  a qué distancia del centro de la pieza sale la E (en horizontal)
    --   tope   lo más lejos de la pieza de salida que el servidor da por bueno.
    --          Va holgado: el servidor mide hasta el origen del modelo, no hasta
    --          su centro, y en las casas de módulo sin saber hacia dónde mira.
    persona = { radio = 1.8, tope = 6.0 },
    coche = { radio = 3.5, tope = 12.0 },

    -- Ajustes de cada modelo, todos opcionales:
    --   radio  en vez del de su clase
    --   suelo  altura del piso sobre el origen del modelo. Sin él se busca el
    --          piso con un rayo hacia abajo desde dentro de la pieza.
    --   centro { x, y } dónde se deja a la persona o al coche, en el modelo.
    --          Sin él, el centro de su caja.
    -- Ninguno está medido en partida: si alguien aparece hundido o fuera de la
    -- cabina, se corrige aquí.
    --
    -- Y los de los elevadores de taller con movimiento (más abajo, `taller`).
    -- El mueble es lo fijo; lo que sube es otro modelo, que pone cada cliente:
    --   brazos   el modelo que sube y baja. Su origen (z = 0) es la cara donde
    --            apoya el coche: los tacos, o la chapa que se pisa
    --   alto     metros que sube
    --   reposo   altura de esa cara sobre el suelo con el elevador abajo
    --   apoyo    'bajos': levanta el coche por debajo (los brazos suben primero
    --            hasta tocarlo, y abajo no tienen colisión para poder pasar por
    --            encima); 'ruedas': el coche se sube rodando a la bandeja o a
    --            las pistas, que son macizas siempre
    --   tacos    (solo 'bajos') dónde están los tacos, { x, y } en el modelo:
    --            desde ahí se mide a qué altura quedan los bajos del coche
    --   contacto (solo 'bajos') esa altura si no se puede medir
    --   mandos   { x, y } en el modelo: a pie junto a ese punto, la E sube y
    --            baja el elevador aunque no tenga coche
    --   piezas   más piezas sueltas que se colocan según la altura h de la cara
    --            de apoyo. Por ahora una clase, la tijera: una barra con el
    --            origen en su centro y tendida a lo largo de Y, en { x, y } del
    --            modelo; `largo` es lo que mide entre ejes y `eje`, la altura
    --            del eje de abajo sobre el suelo y lo que queda el de arriba
    --            bajo la cara de apoyo. Su centro va a h / 2 y se inclina
    --            asin((h - 2 * eje) / largo), hacia el lado que diga `giro`.
    -- Las medidas son las de fuente/obra.py: si se cambia el modelo, aquí también.
    modelos = {
        -- dos columnas rojas y cuatro brazos con tacos
        ['origen_casa_elevador'] = {
            brazos = 'origen_casa_elevador_brazos', alto = 1.8, reposo = 0.12, centro = { 0.0, 0.0 },
            apoyo = 'bajos', contacto = 0.20,
            tacos = { { 0.70, 0.95 }, { -0.70, 0.95 }, { 0.70, -0.95 }, { -0.70, -0.95 } },
            mandos = { 1.48, -0.45 },
        },
        -- pórtico a un lado y bandeja entera: un coche arriba y otro debajo
        ['origen_casa_elevador_bandeja'] = {
            brazos = 'origen_casa_elevador_bandeja_brazos', alto = 1.9, reposo = 0.14, centro = { 0.0, 0.0 },
            apoyo = 'ruedas', mandos = { 1.33, -1.35 },
        },
        -- un solo poste rojo a un lado (x = 1,42; y = 0,45) y la bandeja en voladizo, como el
        -- de aparcamiento del juego: un coche arriba y otro debajo. Medidas de fuente/elevador_poste.py.
        -- Arriba la bandeja queda a 1,94 m (1,82 libres debajo); el poste mide 3,06.
        ['origen_casa_elevador_poste'] = {
            brazos = 'origen_casa_elevador_poste_brazos', alto = 1.8, reposo = 0.14, centro = { 0.0, 0.0 },
            apoyo = 'ruedas', mandos = { 1.47, -0.35 },
        },
        -- el mismo con dos postes, uno a cada lado de la bandeja (x = ±1,42; y = 0,45; 2,60 m libres
        -- entre ellos), como el del juego. Central y mandos, en el de +X. Mismas alturas.
        ['origen_casa_elevador_2postes'] = {
            brazos = 'origen_casa_elevador_2postes_brazos', alto = 1.8, reposo = 0.14, centro = { 0.0, 0.0 },
            apoyo = 'ruedas', mandos = { 1.47, -0.35 },
        },
        -- base plana y dos pistas sobre tijeras
        ['origen_casa_elevador_tijera'] = {
            brazos = 'origen_casa_elevador_tijera_brazos', alto = 1.6, reposo = 0.11, centro = { 0.0, 0.0 },
            apoyo = 'ruedas', mandos = { 1.60, -1.65 },
            piezas = {
                { modelo = 'origen_casa_elevador_tijera_barra', x = 0.76, y = 1.0, largo = 1.90, eje = 0.055, giro = -1 },
                { modelo = 'origen_casa_elevador_tijera_barra', x = 0.82, y = 1.0, largo = 1.90, eje = 0.055, giro = 1 },
                { modelo = 'origen_casa_elevador_tijera_barra', x = 0.76, y = -1.0, largo = 1.90, eje = 0.055, giro = -1 },
                { modelo = 'origen_casa_elevador_tijera_barra', x = 0.82, y = -1.0, largo = 1.90, eje = 0.055, giro = 1 },
                { modelo = 'origen_casa_elevador_tijera_barra', x = -0.82, y = 1.0, largo = 1.90, eje = 0.055, giro = -1 },
                { modelo = 'origen_casa_elevador_tijera_barra', x = -0.76, y = 1.0, largo = 1.90, eje = 0.055, giro = 1 },
                { modelo = 'origen_casa_elevador_tijera_barra', x = -0.82, y = -1.0, largo = 1.90, eje = 0.055, giro = -1 },
                { modelo = 'origen_casa_elevador_tijera_barra', x = -0.76, y = -1.0, largo = 1.90, eje = 0.055, giro = 1 },
            },
        },
        -- cuatro columnas azules y dos pistas largas
        ['origen_casa_elevador_4col'] = {
            brazos = 'origen_casa_elevador_4col_brazos', alto = 1.9, reposo = 0.18, centro = { 0.0, 0.0 },
            apoyo = 'ruedas', mandos = { 1.50, -2.55 },
        },
    },

    -- El ascensor que se mueve de verdad, solo en las casas de modalidad libre
    -- (config/obra.lua). No es un mueble: es la pieza de obra «hueco del
    -- ascensor» (a:i:j:k, de n plantas), y por cada hueco hay una cabina que
    -- sube y baja por él. En qué planta está cada una lo lleva el servidor, en
    -- memoria: tras un reinicio vuelven todas a la planta de abajo.
    --
    -- Hay dos huecos, los dos piezas de obra:
    --   a:i:j:k = n + 10 * f + 100 * e
    --                          ascensor de personas, de la planta k a la k+n-1.
    --                          f es la huella: 0 la celda (i, j); 1 dos celdas en X
    --                          (i, i+1); 2 dos en Y (j, j+1); 3 las cuatro.
    --                          e es el estilo: 0 el abierto de siempre; 1…4 la
    --                          cabina cerrada (`cerrada`, abajo) con el frente
    --                          hacia el giro e-1 de Config.Obra.giros (0 fondo
    --                          +Y, 1 +X, 2 -Y, 3 -X). La cerrada solo con f 0…2,
    --                          y la de dos celdas con el frente en un lado largo
    --                          (f = 1: giros 0 y 2; f = 2: giros 1 y 3)
    --   c:i:j:k = n * 10 + g   montacoches: g = 0 ocupa 2 celdas en X por 3 en Y
    --                          (i…i+1, j…j+2); g = 1, 3 en X por 2 en Y
    cabina = {
        -- Modelos y giro de la cabina según la huella (f) del ascensor y la
        -- orientación (g) del montacoches. Todos con el origen en su centro,
        -- que va en el centro de la huella, a ras de la losa. De cada lista se
        -- usa el primer modelo que el cliente tenga: el de delante es el
        -- preferido y los demás, de reserva. Si el preferido aparece más tarde
        -- (se carga sin reiniciar el recurso), la cabina se rehace con él.
        modelos = {
            a = {
                [0] = { { 'origen_casa_ascensor', 'origen_casa_cabina' }, 0.0 },            -- 1,80 x 1,80
                [1] = { { 'origen_casa_ascensor_2x1', 'origen_casa_cabina_2x1' }, 0.0 },    -- 3,80 en X x 1,80 en Y
                [2] = { { 'origen_casa_ascensor_2x1', 'origen_casa_cabina_2x1' }, 90.0 },   -- el mismo, girado
                [3] = { { 'origen_casa_ascensor_2x2', 'origen_casa_cabina_2x2' }, 0.0 },    -- 3,80 x 3,80
            },
            c = {
                [0] = { { 'origen_casa_montacoches', 'origen_casa_plataforma' }, 0.0 },     -- 3,80 en X x 5,80 en Y
                [1] = { { 'origen_casa_montacoches', 'origen_casa_plataforma' }, 90.0 },
            },
        },
        -- La cabina cerrada («Ascensor de cabina», e > 0): tres lados ciegos
        -- y un frente con dos hojas correderas. Los modelos tienen el origen en
        -- el centro, a ras de suelo, y el frente en su -Y; cada cliente los
        -- gira hacia donde diga la pieza. Las hojas son objetos sueltos, sin
        -- colisión, con el origen en el centro de su base: van una a cada lado
        -- del centro del frente (x = -cerrada y +cerrada con las puertas
        -- cerradas, -abierta y +abierta con ellas abiertas), a `y` del centro
        -- de la cabina. En reposo están abiertas; al pedir un viaje se cierran
        -- (`apertura` ms, que el viaje espera en todos los clientes y en el
        -- servidor) y al llegar se abren.
        -- Si al cliente le falta el modelo de la cabina, pone la abierta de
        -- siempre (la de `modelos.a`), sin puertas; si le faltan las hojas, la
        -- cabina sin ellas.
        cerrada = {
            apertura = 900,     -- ms que tardan las puertas en cerrarse, y en abrirse
            huellas = {
                [0] = { modelo = 'origen_casa_ascensor2', hoja = 'origen_casa_ascensor2_hoja', y = -0.86, cerrada = 0.225, abierta = 0.67 },          -- 1,80 x 1,80; hojas de 0,45 (abren 0,445: 5 mm menos, que su canto no caiga en la cara de fuera de la cabina y parpadee)
                [1] = { modelo = 'origen_casa_ascensor2_2x1', hoja = 'origen_casa_ascensor2_hoja_g', y = -0.86, cerrada = 0.40, abierta = 1.20 },   -- 3,80 x 1,80; hojas de 0,80
                [2] = { modelo = 'origen_casa_ascensor2_2x1', hoja = 'origen_casa_ascensor2_hoja_g', y = -0.86, cerrada = 0.40, abierta = 1.20 },   -- la misma, girada
            },
            -- Lo que cierra el frente mientras dura el viaje (desde que las
            -- puertas empiezan a cerrarse hasta que la cabina llega), para que
            -- nadie entre ni salga a medias: un objeto que no se ve, con
            -- colisión, tendido a lo largo de X y con el origen en el centro
            -- de su base. Vale un tabique de la obra (2 m): se ponen los que
            -- hagan falta para tapar `ancho` metros. Con modelo = false, nada.
            barrera = { modelo = 'origen_casa_tabique_blanco', largo = 2.0, y = -0.86, ancho = { [0] = 1.8, [1] = 3.8, [2] = 3.8 } },
        },
        velocidad = 1.5,    -- m/s a media marcha
        rampa = 0.9,      -- segundos que tarda en coger esa velocidad, y en frenar
        ritmo = 1500,       -- ms mínimos entre dos órdenes del mismo jugador
        margen = 400,       -- ms que el servidor espera de más antes de dar el viaje por acabado
        -- Cada cliente pega a SU cabina a todos los que viajan, también a los
        -- demás jugadores: así suben a la par en todas las pantallas en vez de
        -- ir a saltos con la posición de red. A los demás se les suelta un
        -- poco después de llegar, cuando su posición de red ya está arriba.
        soltar = 300,       -- ms
        -- Lo mismo con los coches del montacoches que mueve otro cliente. Si
        -- se ve peor que dejarlos a la red, ponerlo a false.
        cochesAjenos = true,
        -- La luz de dentro (el panel del techo brilla pero no alumbra): una por
        -- celda del ascensor de personas, bajo el techo, que sube y baja con él.
        -- El color, en ENTEROS: con decimales la pantalla se queda en blanco.
        luz = {
            alto = 2.15,                -- sobre el suelo de la cabina
            color = { 255, 222, 186 },  -- blanca cálida
            alcance = 3.4,
            intensidad = 1.4,
            distancia = 25.0,           -- solo las cabinas a menos de esto del jugador
        },
        -- Los cilindros hidráulicos del montacoches: cuatro, uno bajo cada plato
        -- de anclaje de la plataforma, telescópicos. Un hueco de n plantas sube
        -- como mucho n-1: lleva n-1 tramos por cilindro, del 1 (el más grueso,
        -- el de la base) hacia arriba, cada uno más fino que el de debajo; el
        -- último es el que toca la plataforma. Cada tramo es un tubo de 3,45 m
        -- con el origen en su extremo de arriba. Con la plataforma a una altura
        -- h sobre la planta de abajo, el extremo del tramo s va a h * s / tramos:
        -- se estiran al subir y se meten unos en otros (y bajo el suelo) al bajar.
        pistones = {
            modelos = { 'origen_casa_piston_1', 'origen_casa_piston_2', 'origen_casa_piston_3', 'origen_casa_piston_4' },
            platos = { { 1.40, 2.30 }, { -1.40, 2.30 }, { 1.40, -2.30 }, { -1.40, -2.30 } },   -- desde el centro de la plataforma, sin girar
            bajo = 0.0,     -- metros que queda el extremo de cada tramo por debajo de su altura (por si asoma por la chapa)
        },
    },

    -- El elevador de taller: cualquier plataforma del catálogo ('carlift') sube
    -- y baja en el sitio el coche que tenga encima. Los del catálogo son los
    -- cuatro propios (`modelos`, arriba, los que llevan `brazos`): el mueble
    -- son las columnas o la base, y los brazos, la bandeja o las pistas suben
    -- de verdad con el coche. Cada cliente los pone y los mueve en su pantalla
    -- a partir del aviso del servidor; el coche lo mueve su dueño de red. En
    -- qué estado está cada uno lo lleva el servidor, en memoria: tras un
    -- reinicio vuelven todos abajo.
    -- (Un 'carlift' sin `brazos` sigue valiendo, de reserva: sube solo el
    -- coche, `alto` metros, con el mueble quieto. En el catálogo no hay ninguno.)
    taller = {
        alto = 1.7,         -- metros que sube el coche, si el modelo no dice otra cosa
        velocidad = 0.5,    -- m/s
        ritmo = 1500,       -- ms mínimos entre dos órdenes del mismo jugador
        arrimo = 600,       -- ms que tardan los brazos en subir del reposo a los bajos del coche (y en volver)
        radioMandos = 1.8,  -- a qué distancia del punto de mandos sale la E a pie, sin coche
        alcance = 80.0,     -- en la calle (elevadores de parcela), a quién avisa el servidor: a los que estén a menos de esto
        -- El coche que mueve otro cliente: aquí, pegado a los brazos mientras
        -- suben o bajan, para no verlo ir a saltos por la red (como en el
        -- montacoches). Se suelta `soltar` ms después de llegar. Si se ve
        -- peor que dejarlo a la red, a false.
        cochesAjenos = true,
        soltar = 400,
    },
}

--- Lee una pieza de obra como hueco de ascensor ('a') o de montacoches ('c'):
--- { clave, tipo, i0, i1, j0, j1 (las celdas que ocupa), k (planta de abajo),
--- n (plantas), g (huella u orientación), modelos, giro }. nil si la pieza no
--- es un hueco. El ascensor trae además e (estilo: 0 abierto, 1…4 cabina
--- cerrada) y, si es de cabina cerrada, frente (giro 0…3 hacia el que mira)
--- y cerrada (sus ajustes, de `cabina.cerrada.huellas`).
function Config.Ascensores.Hueco(clave, valor)
    if type(clave) ~= 'string' then return nil end
    local t, i, j, k = clave:match('^([ac]):(-?%d+):(-?%d+):(-?%d+)$')
    valor = tonumber(valor)
    if not t or not valor or valor ~= math.floor(valor) or valor < 0 then return nil end
    valor = math.floor(valor)
    i, j, k = tonumber(i), tonumber(j), tonumber(k)
    local n, g, i1, j1 = 0, 0, i, j
    local e, frente, cerrada = 0, nil, nil
    if t == 'c' then
        n, g = valor // 10, valor % 10
        if g == 0 then i1, j1 = i + 1, j + 2 elseif g == 1 then i1, j1 = i + 2, j + 1 else return nil end
    else
        -- las piezas de antes de las huellas valen 2…5: f = 0, una celda
        -- …y las de antes de la cabina cerrada, menos de 100: e = 0, la abierta
        n, g, e = valor % 10, (valor // 10) % 10, valor // 100
        if g == 1 or g == 3 then i1 = i + 1 end
        if g == 2 or g == 3 then j1 = j + 1 end
        if not Config.Ascensores.EstiloVale(g, e) then return nil end
    end
    local cabina = Config.Ascensores.cabina.modelos[t][g]
    if not cabina or n < 2 or n > 5 then return nil end
    local modelos, giro = cabina[1], cabina[2]
    if e > 0 then
        -- la cerrada delante y las abiertas de reserva. El frente del modelo es
        -- su -Y: sin girar mira al giro 2, y cada giro es un cuarto de vuelta.
        -- (las abiertas son iguales por los cuatro lados: les vale el mismo giro)
        frente, cerrada = e - 1, Config.Ascensores.cabina.cerrada.huellas[g]
        modelos = { cerrada.modelo }
        for _, nombre in ipairs(cabina[1]) do modelos[#modelos + 1] = nombre end
        giro = ((2 - frente) * 90.0) % 360.0
    end
    return { clave = clave, tipo = t, i0 = i, i1 = i1, j0 = j, j1 = j1, k = k, n = n, g = g, modelos = modelos, giro = giro,
        e = e, frente = frente, cerrada = cerrada }
end

--- ¿Casan la huella f y el estilo e de un ascensor? e = 0 (abierto) vale con
--- todas; la cabina cerrada (e = 1…4, frente hacia el giro e-1) solo con las
--- huellas que tienen modelo y, en las de dos celdas, con el frente en un lado largo.
function Config.Ascensores.EstiloVale(f, e)
    if e == 0 then return true end
    if e ~= math.floor(e) or e < 1 or e > 4 then return false end
    if not Config.Ascensores.cabina.cerrada.huellas[f] then return false end
    if f == 1 then return (e - 1) % 2 == 0 end      -- larga en X: el frente, hacia +Y o -Y
    if f == 2 then return (e - 1) % 2 == 1 end      -- larga en Y: hacia +X o -X
    return true
end

--- Milisegundos que el viaje de ese hueco espera parado antes de moverse: lo
--- que tardan en cerrarse las puertas de la cabina cerrada. Lo cuentan igual
--- el servidor y todos los clientes (tengan o no los modelos de las puertas).
function Config.Ascensores.Espera(h)
    if h.tipo ~= 'a' or (h.e or 0) == 0 then return 0 end
    return math.max(0, math.floor(Config.Ascensores.cabina.cerrada.apertura))
end

--- ¿Es la celda (i, j) una de las del hueco?
function Config.Ascensores.EnHuella(h, i, j)
    return i >= h.i0 and i <= h.i1 and j >= h.j0 and j <= h.j1
end

--- ¿Es la celda (i, j) vecina del hueco (pegada a uno de sus lados)?
function Config.Ascensores.JuntoAHuella(h, i, j)
    local di = math.max(h.i0 - i, 0, i - h.i1)
    local dj = math.max(h.j0 - j, 0, j - h.j1)
    return di + dj == 1
end

--- Segundos que tarda la cabina en recorrer esas plantas.
function Config.Ascensores.Duracion(plantas)
    local K = Config.Ascensores.cabina
    return plantas * Config.Obra.planta / K.velocidad + K.rampa
end

--- Metros recorridos a los t segundos de un viaje de d metros: arranca
--- acelerando, va a velocidad fija y frena igual que arrancó. Lo usan igual
--- todos los clientes, así la cabina va a la par en todas las pantallas.
function Config.Ascensores.Recorrido(d, t)
    local K = Config.Ascensores.cabina
    local v, r = K.velocidad, K.rampa
    local total = d / v + r
    if t <= 0 then return 0.0 end
    if t >= total then return d end
    if t < r then return 0.5 * v / r * t * t end
    if t <= total - r then return v * (t - r / 2) end
    local q = total - t
    return d - 0.5 * v / r * q * q
end

--- Nombre de una planta, como en la cinta de obra.
function Config.Ascensores.NombrePlanta(k)
    if k == 0 then return 'Planta baja' end
    if k > 0 then return 'Planta ' .. k end
    return 'Sótano ' .. -k
end

--- Clase de pieza de un modelo del catálogo: 'persona', 'coche' o nil si ese
--- mueble no es ni ascensor ni elevador.
function Config.Ascensores.Clase(modelo)
    local item = modelo and __indexFurniture[modelo]
    if item and item.type and Config.Ascensores.tipos[item.type] then return Config.Ascensores.tipos[item.type] end
    -- Un elevador con brazos que ya no se vende (la bandeja de pórtico, fuera
    -- del catálogo desde que está el de un poste): los colocados siguen valiendo.
    local a = modelo and not item and Config.Ascensores.modelos[modelo]
    return a and a.brazos and 'coche' or nil
end
