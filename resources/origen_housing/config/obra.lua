-- Obra: la modalidad «libre» de una casa. En vez de un módulo ya hecho, el
-- interior lo excava y lo reparte el jugador, como en un juego de bloques.
--
-- Para el resto del housing es una casa de módulo más: se entra y se sale por
-- su punto, tiene su dimensión, sus llaves y sus muebles. Lo único distinto es
-- el módulo, que es un ancla sin nada (Config.Obra.ancla): la casa se monta
-- alrededor (custom/client/obra.lua).
--
-- El interior es una rejilla de celdas. Cada celda está maciza o abierta; lo
-- que el jugador hace es abrir celdas (excavar) y volver a rellenarlas. Toda
-- cara de una celda abierta que da a una maciza lleva sola su pared, su suelo
-- o su techo: por eso nunca se ve el mapa ni se puede caer fuera. Entre dos
-- celdas abiertas no hay nada, salvo lo que se ponga: pared, pared con puerta,
-- hueco de puerta, hueco de garaje, suelo entre plantas o escalera. Las puertas
-- que se abren son las del catálogo de muebles de la vivienda, que encajan en
-- esos huecos.
Config.Obra = {
    celda = 2.0,          -- lado de la rejilla (el de los modelos origen_casa_*)
    planta = 3.35,        -- de un suelo al de la planta de encima (3,20 libres + la losa)
    plantaMin = -6,       -- sótanos
    plantaMax = 4,
    ancla = 'origen_casa_ancla',   -- el «módulo» de estas casas: no se ve ni se toca; solo dice dónde va la casa
    partida = 5,          -- lado, en celdas, de la sala con la que arranca una casa
    radio = 24,           -- celdas que se puede alejar la obra de la entrada, a cada lado y hacia el fondo
    -- Cuántas celdas, piezas y muebles admite una casa lo dice su TAMAÑO
    -- (config/obra_tamanos.lua): cada celda abierta son hasta seis objetos en
    -- el cliente, y demasiados objetos tumban el juego. El radio y las plantas
    -- de aquí son los de la rejilla: el tamaño los recorta.
    -- El juego admite unos 2.300 objetos a la vez por jugador y, si se pasa, se cae.
    -- Con esto cargado (piezas, muebles y lo que haya de otros recursos) ya no se
    -- deja construir ni amueblar más. Lo mira el cliente, que es quien los cuenta.
    maxObjetos = 2000,
    -- Losas y paredes seguidas del mismo material se montan como un solo paño de
    -- 2 o de 4 celdas (origen_casa_losa2/4_<mat>, origen_casa_tabique2/4_<mat>):
    -- la misma casa con muchos menos objetos. Se construye igual, celda a celda.
    juntar = true,
    -- Dentro de la casa no manda la hora ni el tiempo del servidor: es otra
    -- dimensión y está siempre igual, a oscuras, hasta que se le ponen luces.
    -- Se para la sincronización de Renewed-Weathersync para ese jugador
    -- (statebag syncWeather) y se le fija esta hora y este clima; al salir
    -- vuelve a los del servidor. `modificador`: un timecycle encima, o false.
    ambiente = { hora = 0, clima = 'CLEAR', modificador = false, fuerza = 1.0 },
    deshacer = 5,         -- cambios de obra que cada uno puede deshacer hacia atrás (tecla Z en la cinta)
    ritmo = 80,           -- ms mínimos entre dos cambios del mismo jugador
    -- Con qué se puede pintar cada pared, suelo y techo. De cada uno hay una
    -- losa, un tabique y un tabique con puerta: origen_casa_<pieza>_<id>
    -- (origen_housing/fuente/obra.py; al añadir uno aquí, añadirlo allí).
    materiales = {
        { id = 'blanco', nombre = 'Blanco' },
        { id = 'crema', nombre = 'Crema' },
        { id = 'gris', nombre = 'Gris' },
        { id = 'azul', nombre = 'Azul' },
        { id = 'verde', nombre = 'Verde' },
        { id = 'hormigon', nombre = 'Hormigón' },
        { id = 'ladrillo', nombre = 'Ladrillo' },
        { id = 'madera', nombre = 'Madera' },
        { id = 'baldosa', nombre = 'Baldosa' },
        { id = 'moqueta', nombre = 'Moqueta' },
        -- Segunda tanda (12/10): gastados y sucios para guaridas, almacenes y pisos
        -- francos, y algunos de lujo. Sus texturas van en origen_casa_tex2.
        { id = 'ladrillo_viejo', nombre = 'Ladrillo viejo' },
        { id = 'ladrillo_cal', nombre = 'Ladrillo encalado' },
        { id = 'bloque', nombre = 'Bloque de hormigón' },
        { id = 'humedad', nombre = 'Yeso con humedad' },
        { id = 'desconchado', nombre = 'Pared desconchada' },
        { id = 'chapa_oxido', nombre = 'Chapa ondulada' },
        { id = 'tablones', nombre = 'Tablones viejos' },
        { id = 'cemento_aceite', nombre = 'Cemento con aceite' },
        { id = 'azulejo', nombre = 'Azulejo sucio' },
        { id = 'linoleo', nombre = 'Linóleo de cuadros' },
        { id = 'moqueta_sucia', nombre = 'Moqueta sucia' },
        { id = 'chapa_lagrimada', nombre = 'Chapa lagrimada' },
        { id = 'marmol', nombre = 'Mármol blanco' },
        { id = 'marmol_negro', nombre = 'Mármol negro' },
        { id = 'parquet_oscuro', nombre = 'Parquet en espiga' },
        { id = 'microcemento', nombre = 'Microcemento' },
        { id = 'papel', nombre = 'Papel pintado' },
        { id = 'pizarra', nombre = 'Pizarra' },
        -- Transparente. `interior`: solo se deja poner entre dos espacios de la casa
        -- (una pared levantada entre dos salas o un suelo entre dos plantas),
        -- nunca en una cara que da hacia fuera: la casa está montada en el aire
        -- y por ese cristal se vería el cielo o la ciudad.
        -- `modelo`: cómo se llaman sus piezas (origen_casa_<pieza>_vidrio).
        { id = 'cristal', nombre = 'Cristal', interior = true, modelo = 'vidrio' },
        { id = 'cristal_ahumado', nombre = 'Cristal ahumado', interior = true, modelo = 'vidrio_ahumado' },
        { id = 'cristal_mate', nombre = 'Cristal mate', interior = true, modelo = 'vidrio_mate' },
        { id = 'cristal_azul', nombre = 'Cristal azul', interior = true, modelo = 'vidrio_azul' },
        { id = 'cristal_bronce', nombre = 'Cristal bronce', interior = true, modelo = 'vidrio_bronce' },
        { id = 'cristal_negro', nombre = 'Cristal negro', interior = true, modelo = 'vidrio_negro' },
        { id = 'cristal_acanalado', nombre = 'Cristal acanalado', interior = true, modelo = 'vidrio_acanalado' },
    },
    porDefecto = { pared = 'blanco', suelo = 'madera', techo = 'blanco' },
    -- Barandillas: van en el borde entre dos celdas abiertas, donde iría una pared
    -- puesta a mano (x:… / y:…), con valor 'b:<id>'. No separan salas ni se
    -- pintan. Modelo origen_casa_baranda_<id>, con el origen y los ejes del
    -- tabique; el estilo cuyo modelo aún no se sirva no se ofrece en la cinta.
    barandillas = {
        { id = 'acero', nombre = 'Acero' },
        { id = 'barrotes', nombre = 'Barrotes' },
        { id = 'cristal', nombre = 'Cristal' },
        { id = 'piedra', nombre = 'Piedra' },
        { id = 'murete', nombre = 'Murete' },
        { id = 'madera', nombre = 'Madera' },
        { id = 'industrial', nombre = 'Industrial' },
        { id = 'forja', nombre = 'Forja' },
    },
    escalera = `origen_casa_peldanos`,
    -- Las escaleras en L (Config.Obra.Escalera): origen en el centro de la celda
    -- de arranque, a ras de su suelo; primer tramo hacia +Y y el segundo hacia +X
    -- (derecha) o -X (izquierda). Si el modelo no está, la herramienta lo avisa.
    escaleraLD = `origen_casa_peldanos_ld`,
    escaleraLI = `origen_casa_peldanos_li`,
    -- Escalera de mano (una celda, pegada a la pared de su +Y) y las de caracol:
    -- la compacta (una celda) y la amplia (2x2 celdas, con el origen en el
    -- vértice común de las cuatro). Las de una celda, con el origen en el centro
    -- de la celda a ras de suelo.
    escala = `origen_casa_escala`,
    caracol = `origen_casa_caracol`,
    caracol2 = `origen_casa_caracol2`,
    -- La escalera de mano se trepa sola si su modelo lleva la escalera del juego.
    -- Si no la lleva, con esto a true el cliente ofrece E abajo («Subir») y arriba
    -- («Bajar») y lleva al jugador de una punta a otra con un fundido corto.
    escalaPorCodigo = false,
    cabina = `origen_casa_ascensor`,           -- la del ascensor que se mueve (custom/*/ascensores.lua)
    cabina2x1 = `origen_casa_ascensor_2x1`,    -- …la de dos celdas
    cabina2x2 = `origen_casa_ascensor_2x2`,    -- …y la de cuatro
    plataforma = `origen_casa_montacoches`,   -- la del montacoches
    -- Puertas de garaje del catálogo (config/furniture.lua, «Puertas»): caben en
    -- el hueco de garaje y se dan de alta como puerta de garaje, que sube sola.
    garajes = { [`prop_gar_door_01`] = true, [`prop_gar_door_02`] = true,
        -- las propias (fuente/portones.py)
        [`origen_casa_porton_galva`] = true, [`origen_casa_porton_blanca`] = true, [`origen_casa_porton_antracita`] = true, [`origen_casa_porton_ventanas`] = true,
        [`origen_casa_porton_madera`] = true, [`origen_casa_porton_roja`] = true, [`origen_casa_porton_banda`] = true, [`origen_casa_porton_verde`] = true, },
    -- Hacia dónde sube una escalera según su giro, en celdas (x, y) de la obra
    giros = { [0] = { 0, 1 }, [1] = { 1, 0 }, [2] = { 0, -1 }, [3] = { -1, 0 } },
}

local NOMBRE_MODELO = {}
for _, m in ipairs(Config.Obra.materiales) do NOMBRE_MODELO[m.id] = m.modelo end

-- Modelo de una pieza ('losa', 'tabique', 'marco' o 'garaje') en un material
function Config.Obra.Modelo(pieza, material)
    return joaat(('origen_casa_%s_%s'):format(pieza, NOMBRE_MODELO[material] or material))
end

local BARANDA = {}
for _, b in ipairs(Config.Obra.barandillas) do BARANDA[b.id] = b end

-- Si el valor de un borde (x:… / y:…) es una barandilla ('b:<id>' con un estilo
-- de Config.Obra.barandillas), su estilo ({ id, nombre }); si no, nil.
function Config.Obra.Baranda(valor)
    if type(valor) ~= 'string' then return nil end
    local id = valor:match('^b:([%w_]+)$')
    return id and BARANDA[id] or nil
end

function Config.Obra.ModeloBaranda(id)
    return joaat('origen_casa_baranda_' .. id)
end

-- Una escalera (pieza e:i:j:k). valor = giro + 4 * forma: giro 0..3 (hacia dónde
-- arranca, Config.Obra.giros) y forma 0 recta, 1 en L a la derecha, 2 en L a la
-- izquierda, 3 de mano, 4 de caracol compacta, 5 de caracol amplia. Devuelve, o
-- nil si el valor no vale:
--   celdas   las que ocupa en la planta k, { i, j }: quedan abiertas en k y en
--            k+1, y en k+1 sin suelo (es el hueco de la escalera)… salvo las que
--            llevan { i, j, true }, que arriba conservan (o reciben) su suelo: el
--            rellano de la de caracol amplia
--   entrada  { i, j }: el rellano de abajo, en la planta k, o nil si no hace falta
--   salida   { i, j }: el rellano de arriba, en la planta k+1, o nil si no hace falta
--   giro, forma
-- En el marco de la escalera, «adelante» es su giro y «a la derecha», un cuarto
-- de vuelta más.
--  · La recta pisa dos celdas seguidas.
--  · La L arranca en A = (i, j), sube media planta hasta el rellano B (la celda
--    siguiente), gira un cuarto y sube la otra media por C, la de al lado de B;
--    se sale por la que sigue a C.
--  · La de mano es una celda, con la escala pegada a su pared de delante: arriba
--    se sale hacia atrás.
--  · La de caracol compacta es una celda: se entra desde la de atrás y, una
--    vuelta entera después, se sale arriba a la de atrás.
--  · La de caracol amplia es un bloque de 2x2: A es el rellano (abajo y arriba,
--    con su suelo) y la escalera sube por la de la derecha, la de delante a la
--    derecha y la de delante (sentido antihorario visto desde arriba).
function Config.Obra.Escalera(i, j, valor)
    valor = tonumber(valor)
    if not valor or valor ~= math.floor(valor) or valor < 0 or valor > 23 then return nil end
    local giro, forma = valor % 4, math.floor(valor / 4)
    local d = Config.Obra.giros[giro]
    if forma == 3 then
        -- La escala se trepa con la animación del juego, que arriba saca al jugador
        -- hacia delante, por entre los largueros: la salida es la celda de detrás
        -- de la pared a la que va pegada, en la planta de arriba.
        return { { i, j } }, nil, { i + d[1], j + d[2] }, giro, forma
    elseif forma == 4 then
        return { { i, j } }, { i - d[1], j - d[2] }, { i - d[1], j - d[2] }, giro, forma
    elseif forma == 5 then
        local rx, ry = d[2], -d[1]
        return { { i, j, true }, { i + rx, j + ry }, { i + rx + d[1], j + ry + d[2] }, { i + d[1], j + d[2] } }, nil, nil, giro, forma
    end
    local bi, bj = i + d[1], j + d[2]
    local celdas, salida = { { i, j }, { bi, bj } }, nil
    if forma == 0 then
        salida = { bi + d[1], bj + d[2] }
    else
        -- la derecha de quien sube: un cuarto de vuelta de d, como giran los giros
        local s = forma == 1 and 1 or -1
        local rx, ry = d[2] * s, -d[1] * s
        celdas[3] = { bi + rx, bj + ry }
        salida = { bi + 2 * rx, bj + 2 * ry }
    end
    return celdas, { i - d[1], j - d[2] }, salida, giro, forma
end

-- Planta en la que está un personaje cuyo centro queda a la altura z (medida
-- desde el suelo de la planta baja)
function Config.Obra.PlantaDe(z)
    local k = math.floor((z + 0.4) / Config.Obra.planta)
    return math.max(Config.Obra.plantaMin, math.min(Config.Obra.plantaMax, k))
end

-- ¿Se puede abrir esa celda? La casa crece a los lados y hacia el fondo desde la entrada.
function Config.Obra.EnLimites(i, j, k)
    local C = Config.Obra
    return k >= C.plantaMin and k <= C.plantaMax and math.abs(i) <= C.radio and j >= 0 and j <= C.radio
end

-- El ancla, como un módulo más: es lo que guarda una casa de modalidad libre
-- en data.model. Su punto de entrada es el centro de la celda (0,0).
table.insert(Config.Interiors.small, 1, { model = Config.Obra.ancla, label = 'Diseño libre', offset = vector3(0.0, 1.0, 1.0) })
