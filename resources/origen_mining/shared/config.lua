--[[ ORIGEN · Cantera Davis Quartz

     El trabajo, de principio a fin:
       1. El capataz de la cantera: empiezas la jornada y te da el casco, el
          pico y la camioneta, en el mismo sitio.
       2. En un frente de roca: picas la roca hasta que se parte en pedruscos.
          Cada roca lleva una veta (piedra, carbón, hierro, cobre o cuarzo) y
          se ve por el brillo de su color.
       3. Coges los pedruscos en brazos (o en la carretilla, desde el nivel 2)
          y los echas uno a uno en la caja del vehículo.
       4. Descargas en la tolva de la planta del mapa (marcha atrás por la
          rampa, o a pie desde el borde con la carretilla o en brazos): la
          piedra cae al foso y sube por la cinta. Se cobra por pedrusco, según
          la veta, y más si el vehículo viene lleno.
       5. Desde el nivel 4, cargas explosivas para partir rocas de golpe; en
          el 5, voladuras de los bloques grandes del frente, que dan mucha
          piedra y a veces oro.

     Todo lo que se puede ajustar sin tocar código. El servidor decide con
     estos valores: precios, tiempos y topes se leen AQUÍ y nunca de lo que
     diga un cliente.

     Todos los props, vehículos, animaciones y partículas de este fichero se
     comprobaron el 27/09 en el cliente (existen y cargan en nuestra build).
     Los volquetes de GTA NO basculan la caja: la descarga se anima aparte. ]]

Config = {}

-- Divide los tiempos de regeneración de las rocas (no los de las acciones);
-- para probar se puede pisar con la convar `origen_mining_velocidad`.
Config.Velocidad = 1.0

local MIN = 60

-- ── La cantera ────────────────────────────────────────────────────────────
--[[ Peds      el capataz: jornada, herramienta, vehículo y explosivos
     salidas   huecos donde sale el vehículo (el primero libre)
     devolver  dónde se deja el vehículo al terminar la jornada
     La descarga es en la tolva DEL MAPA (Config.Planta).
     Todo esto se puede mover dentro del juego con /minaeditor. ]]
Config.Mina = {
    nombre = 'Cantera Davis Quartz',
    centro = vec3(2880.0, 2800.0, 50.0),
    radio = 260.0,

    Peds = {
        Capataz = { modelo = 's_m_y_construct_02', coords = vec4(2832.0, 2798.0, 57.49, 140.0) },
    },

    salidas = {
        vec4(2828.15, 2788.09, 57.67, 268.5),
        vec4(2822.0, 2782.0, 57.67, 268.5),
        vec4(2835.0, 2780.0, 57.67, 268.5),
    },
    devolver = { coords = vec3(2828.15, 2788.09, 57.67), radio = 18.0 },

}

-- ── Las vetas ─────────────────────────────────────────────────────────────
--[[ nivel    desde qué nivel sale esa veta en las rocas que picas
     peso     lo común que es (sobre el total de vetas abiertas a tu nivel)
     pago     lo que se cobra por cada pedrusco descargado en la tolva
     color    el brillo de la veta en la roca (r, g, b)
     xp       experiencia por roca partida ]]
Config.Materiales = {
    piedra = { nombre = 'Piedra',  nivel = 1, peso = 50, pago = 9,  color = { 200, 200, 190 }, xp = 1 },
    carbon = { nombre = 'Carbón',  nivel = 1, peso = 30, pago = 12, color = { 40, 40, 45 },    xp = 2 },
    hierro = { nombre = 'Hierro',  nivel = 2, peso = 25, pago = 15, color = { 200, 80, 40 },   xp = 2 },
    cobre  = { nombre = 'Cobre',   nivel = 3, peso = 20, pago = 18, color = { 60, 200, 150 },  xp = 3 },
    cuarzo = { nombre = 'Cuarzo',  nivel = 4, peso = 12, pago = 22, color = { 230, 220, 255 }, xp = 3 },
    -- El oro no sale picando: solo en las voladuras (Config.Voladura.oro).
    oro    = { nombre = 'Oro',     nivel = 5, peso = 0,  pago = 95, color = { 255, 200, 40 },  xp = 8 },
}
Config.OrdenMateriales = { 'piedra', 'carbon', 'hierro', 'cobre', 'cuarzo', 'oro' }

-- ── Las rocas ─────────────────────────────────────────────────────────────
--[[ Cada roca pasa por fases al picarla: entera → agrietada → partida (en
     pedruscos). `golpes` es cuántas veces hay que picarla y `segundos` lo que
     dura cada tanda de golpes con el pico. Al partirse suelta `pedruscos`
     alrededor y desaparece hasta que la cantera la repone. ]]
Config.Roca = {
    fases = {
        { modelo = 'prop_rock_3_c', hundir = 0.25 },   -- 1,6 × 1,6 × 1,1 m, entera
        { modelo = 'prop_rock_4_e', hundir = 0.30 },   -- 1,5 × 1,3 × 1,1 m, agrietada
    },
    -- Partida, la roca desaparece hasta que se repone (no queda escombro).
    escombro = {},
    golpes = 3,
    segundos = 4.5,
    pedruscos = 2,
    repone = 20 * MIN,
    -- Quien empieza a picar una roca la tiene reservada mientras la trabaje.
    reserva = 5 * MIN,
    -- Dónde hay que ponerse para picar (m del centro de la roca, en el plano).
    distancia = 2.4,
}

-- ── Los pedruscos ─────────────────────────────────────────────────────────
Config.Pedrusco = {
    modelo = 'prop_rock_5_smash3',     -- 0,55 × 0,44 × 0,40 m
    -- En brazos: el ajuste del minero de antes (hueso 60309, la mano
    -- izquierda) con la animación de llevar una caja.
    mano = { hueso = 60309, pos = vec3(0.051, 0.0, 0.225), rot = vec3(65.0, 0.0, 0.0) },
    anim = { dict = 'anim@heists@box_carry@', clip = 'idle', flag = 49 },
    -- Coger del suelo.
    coger = { dict = 'random@domestic', clip = 'pickup_low', flag = 0 },
    -- Como en el aserradero: no se dejan props tirados. Un pedrusco en el
    -- suelo desaparece si su dueño pasa más de `abandono` lejos.
    abandono = 5 * MIN,
    cerca = 60.0,
    distancia = 1.8,
}

-- ── Herramientas ──────────────────────────────────────────────────────────
--[[ No son objetos del inventario ni armas: las presta el capataz con la
     jornada y solo existen mientras dura (un estado del jugador y el prop en
     la mano). Nadie se queda un pico para pegar. `factor` multiplica los
     segundos de cada tanda de golpes. ]]
Config.Herramientas = {
    pico = {
        nombre = 'Pico', nivel = 1, factor = 1.0,
        -- El ajuste de origen_anims para `ground_attack_on_spot`.
        prop = { modelo = 'prop_tool_pickaxe', hueso = 57005, pos = vec3(0.08, -0.4, -0.1), rot = vec3(80.0, -20.0, 175.0) },
        -- Al hombro mientras andas (el mismo ajuste que /axe de origen_anims).
        hombro = { pos = vec3(0.04, -0.255, -0.138), rot = vec3(-109.0, 163.6, 20.6) },
        anim = { dict = 'melee@large_wpn@streamed_core', clip = 'ground_attack_on_spot', flag = 1 },
    },
    -- El del nivel 4: GTA pone el martillo y lo anima solo con su escenario.
    martillo = {
        nombre = 'Martillo neumático', nivel = 4, factor = 0.6,
        prop = nil,
        escenario = 'WORLD_HUMAN_CONST_DRILL',
    },
}
Config.OrdenHerramientas = { 'pico', 'martillo' }

-- ── La carretilla ─────────────────────────────────────────────────────────
--[[ Con lo que se empieza (27/09, el usuario): en el nivel 1 se trabaja
     solo con la carretilla, sin vehículo; en el 2 llega la camioneta y en el
     después ya no hay más vehículos. Se empuja y se deja con H, lleva hasta `capacidad`
     pedruscos y se vuelca entera en la tolva (a pie, desde el borde) o en la
     caja del vehículo. ]]
Config.Carretilla = {
    nivel = 1,
    capacidad = 3,
    modelo = 'prop_wheelbarrow01a',     -- 1,64 × 0,69 × 0,66 m
    --[[ Empujándola NO va pegada al cuerpo (así flotaba: 27/09, foto del
         usuario). Se coloca en cada fotograma, con
         la rueda apoyada en el suelo: cada empuñadura en la palma de su mano
         (`palma`: metros desde el hueso de la mano hacia los dedos, y `dentro`
         hacia el otro puño; ajustado con primeros planos el 27/09).
         Medido en el modelo con marcas (27/09): empuñaduras en x -0,745,
         y ±0,24 (48 cm entre ellas), z 0,57; la rueda está en +x. ]]
    empujar = { asa = vec3(-0.745, 0.24, 0.57), eje = vec3(0.60, 0.0, 0.19), palma = 0.13, dentro = 0.015 },
    --[[ Brazos estirados hacia abajo, una mano a cada lado de la cadera (63
         cm entre manos, medido): como se lleva de verdad. La del carro de la
         compra cruzaba los brazos sobre la barra (se descartó el 27/09). ]]
    anim = { dict = 'rcmepsilonism8', clip = 'bag_handler_idle_a', flag = 49 },
    -- Dónde van los pedruscos dentro (desde el centro de la carretilla).
    -- Hacia la rueda, que es donde la caja es honda: hacia las asas el fondo
    -- sube y la piedra lo atravesaba.
    huecos = { vec3(0.30, 0.0, 0.56), vec3(0.00, 0.0, 0.55), vec3(0.16, 0.0, 0.76) },
    distancia = 2.0,
}

-- ── Explosivos ────────────────────────────────────────────────────────────
--[[ Las cargas NO son objetos del inventario: el capataz las vende a quien
     tiene nivel y se apuntan en el propio jugador (no se pueden sacar de la
     cantera ni dar a nadie). Se pierden al terminar la jornada.
       carga     una roca normal: en vez de picar, una carga y se parte de
                 golpe (nivel 4)
       voladura  los bloques grandes del frente (Config.Bloques): `cargas`
                 cargas alrededor y, al volar, muchos pedruscos (nivel 5)
     La explosión es solo de mentira (luz, humo, sonido y temblor): no hay
     explosión de GTA que rompa coches o mate. Quien se quede dentro del radio
     cae al suelo con un golpe. ]]
Config.Explosivos = {
    nivel = 4,
    -- Cada carga. A 60 $ volar un bloque (4 cargas) dejaba menos que picar
    -- esos 12 pedruscos en el mismo tiempo (171 $ frente a 222): a 35 queda
    -- ~270 $, algo mejor que picar, que es lo que debe premiar el nivel 5.
    precio = 70,          -- ×2 con los precios del 28/09 (sigue la misma cuenta)
    maximo = 6,           -- las que puedes llevar a la vez
    modelo = 'prop_c4_final',
    poner = { dict = 'weapons@projectile@sticky_bomb', clip = 'plant_vertical', flag = 0, ms = 2300 },
    detonar = { dict = 'anim@mp_player_intmenu@key_fob@', clip = 'fob_click', flag = 48 },
    -- Distancia mínima a la carga para poder detonar, y radio del golpe.
    lejos = 12.0,
    radio = 9.0,
    dano = 25,
    -- Una carga puesta y sin detonar se desactiva sola a los 3 minutos.
    caduca = 3 * MIN,
}

Config.Voladura = {
    nivel = 5,
    cargas = 4,
    modelo = 'prop_rock_4_big2',        -- 3,4 × 3,2 × 2,6 m
    pedruscos = 12,
    -- Probabilidad de que cada pedrusco de una voladura salga de oro.
    oro = 0.12,
    radio = 18.0,
    cuenta = 10,          -- segundos de sirena antes de volar
    dano = 40,
    repone = 45 * MIN,
    distancia = 3.2,      -- a cuánto del bloque se ponen las cargas
}

-- ── Los frentes de roca ───────────────────────────────────────────────────
--[[ Rehechos el 27/09 (el usuario: «las piedras se tocan con otras y hay
     espacio de sobra»): los del minero de antes seguían el borde del foso,
     pegados a las rocas del mapa. Ahora van en filas al tresbolillo, a 4,5 m,
     en las explanadas, a 2 m o más del borde y del camión grande del mapa y
     fuera del camino de los vehículos; elegidos sobre fotos cenitales con
     rejilla y con el suelo medido en cada punto. La z es
     la del suelo medido; el cliente la vuelve a asentar con el terreno. ]]
Config.Frentes = {
    --[[ Hubo un frente T para los que empiezan junto a la tolva nueva (27/09),
         pero quedaba en la explanada por donde se va a la fundición y el
         usuario lo quitó: quien empieza pica en el Frente Sur, el más cercano
         a la planta (~30 m), donde a su nivel solo sale piedra y carbón. ]]
    {
        id = 'A', nombre = 'Frente Norte', centro = vec3(2942.0, 2809.3, 40.8), radio = 13,
        rocas = {
            vec3(2936.21, 2811.78, 41.88),
            vec3(2941.14, 2811.07, 41.36),
            vec3(2944.39, 2811.95, 40.99),
            vec3(2949.27, 2811.32, 40.80),
            vec3(2933.94, 2806.56, 41.16),
            vec3(2938.57, 2806.99, 40.90),
            vec3(2941.90, 2807.58, 40.57),
            vec3(2947.10, 2806.41, 40.49),
            vec3(2951.97, 2807.38, 40.66),
        },
    },
    {
        id = 'B', nombre = 'Frente Oeste', centro = vec3(2931.5, 2798.0, 40.0), radio = 9,
        rocas = {
            vec3(2925.84, 2802.22, 40.74),
            vec3(2930.69, 2801.32, 40.50),
            vec3(2935.16, 2802.20, 40.29),
            vec3(2927.65, 2798.16, 40.05),
            vec3(2932.27, 2798.21, 39.96),
            vec3(2937.29, 2798.03, 39.89),
            vec3(2932.44, 2793.85, 39.54),
            vec3(2937.22, 2794.35, 39.52),
        },
    },
    {
        id = 'C', nombre = 'Frente Sur', centro = vec3(2954.0, 2781.4, 39.0), radio = 15,
        rocas = {
            vec3(2946.60, 2777.89, 38.28),
            vec3(2950.54, 2777.04, 38.41),
            vec3(2955.29, 2777.17, 39.04),
            vec3(2960.20, 2777.04, 39.06),
            vec3(2964.66, 2776.82, 38.52),
            vec3(2948.64, 2781.28, 38.68),
            vec3(2952.85, 2781.38, 39.42),
            vec3(2956.98, 2781.41, 39.77),
            vec3(2962.19, 2781.29, 38.98),
            vec3(2966.06, 2781.89, 38.14),
            vec3(2941.05, 2785.10, 38.80),
            vec3(2946.02, 2785.32, 39.02),
            vec3(2950.04, 2785.67, 39.79),
            vec3(2954.98, 2784.73, 40.29),
        },
    },
}

--[[ Los bloques grandes de las voladuras (nivel 5): uno por frente, en el
     borde, lejos de las rocas pequeñas. Se colocan con /minaeditor. ]]
Config.Bloques = {
    { id = 'V1', nombre = 'Bloque del Frente Norte', pos = vec4(2932.0, 2822.0, 44.0, 0.0) },
    { id = 'V2', nombre = 'Bloque del Frente Oeste', pos = vec4(2914.0, 2790.0, 41.0, 0.0) },
    { id = 'V3', nombre = 'Bloque del Frente Sur', pos = vec4(2986.0, 2776.0, 38.5, 0.0) },
}

-- ── La planta de trituración ──────────────────────────────────────────────
--[[ La planta propia (origen_planta, props hechos en Blender el 27/09): tolva
     a ras de suelo → cinta de subida → trituradora → cinta de salida →
     contenedor, y aparte la fundición. Todo es visual y local de cada
     cliente: el servidor solo avisa de cada descarga (como antes) y cada
     cliente hace subir las piedras, triturarlas y llenar el contenedor.

       ancla      donde va la trituradora (x, y, z, rumbo); la tolva, las
                  cintas y el contenedor cuelgan de ella (Planta de
                  origen_planta). Puesto por el usuario el 27/09, girado
                  180° y corrido 3 m hacia la tolva (el contenedor se salía
                  del llano; medido con una foto cenital) a petición suya: la tolva queda del lado del camino
                  (por ahí se entra con la carretilla y el vehículo) y el
                  contenedor del otro, hacia la fundición.
       fundicion  la fundición, en su propio sitio (del usuario, 27/09);
                  el material se recoge del contenedor y se lleva allí

     `boca`, `descarga` y `borde` salen del ancla (Mina.PuntosPlanta, en
     util.lua): la boca es el centro de la tolva, y todo se entrega detrás
     del tope: el vehículo entra marcha atrás al cuadro y a pie se echa desde
     el aro que hay junto al tope. Moviendo el ancla con /minaeditor
     se recolocan solos. ]]
Config.Planta = {
    ancla = vec4(2955.46, 2748.68, 42.47, 101.42),
    fundicion = vec4(2954.45, 2735.81, 43.3, 290.66),
    -- Metros en el marco de la planta (x derecha, y hacia el contenedor).
    local_boca = vec3(0.0, -9.0, 1.1),
    local_descarga = vec3(0.0, -16.2, 0.0),
    -- A pie (en brazos o con la carretilla) se entrega en el mismo sitio que
    -- los vehículos: detrás del tope, mirando a la tolva (el usuario, 27/09).
    local_borde = vec3(0.0, -13.1, 0.0),
    descarga = { radio = 5.0 },
    borde = { radio = 1.2 },
    --[[ Lo que el mapa tiene donde va la planta (casetas, bidones, tubos,
         focos) se esconde mientras está montada: rectángulos en el marco de
         la planta (x0, x1, y0, y1), incluido el sitio donde aparca el
         vehículo; y el de la fundición en el suyo. ]]
    despejar = { { -1.9, 1.9, -21.0, 11.3 }, { -3.2, 3.2, -3.5, 3.0 },
        -- generador, caseta con su escalera y las dos torres de luz (la plancha
        -- y los tubos del mapa no son objetos: no se esconden, se esquivan)
        { 6.6, 8.6, -8.0, -3.6 }, { 2.0, 11.0, -2.2, 6.5 }, { 5.5, 9.5, -15.0, -10.0 }, { -9.5, -5.5, 10.5, 14.5 },
        -- una torre de luz del mapa, entre la tolva y la nuestra
        { 2.4, 4.6, -11.4, -7.0 } },
    -- la fundición, y a su derecha la balsa de temple y el carro de lingotes
    despejar_fundicion = { { -2.6, 2.6, -2.2, 3.2 }, { 2.3, 5.4, -2.0, 2.4 } },
    --[[ El proceso, por jugador (server/planta.lua): lo que cada uno mete en
         la tolva queda a SU nombre y solo él lo saca.
           proceso    segundos desde la descarga hasta que está en el
                      contenedor (lo que tarda en subir, triturarse y bajar)
           fundir     segundos de horno por cada pedrusco triturado
           tope       lo que puede tener cada uno dentro de la planta a la
                      vez (triturándose + en el contenedor + en el horno +
                      lingotes sin recoger): si no cabe, no descarga ]]
    proceso = 40,
    fundir = 15,
    tope = 80,
    -- Dónde se recoge: la compuerta del contenedor (marco de la planta) y el
    -- horno (marco de la fundición: el centro de la plataforma).
    local_recoger = vec3(0.0, 11.6, 0.0),
    recoger_radio = 2.2,
    horno_radio = 2.8,
    -- Cuánto material llena el contenedor a la vista (entre todos).
    lleno_visual = 40,
}

--[[ ── Lo que sale de la planta y lo que se paga ────────────────────────────
     Descargar ya no se cobra (27/09, el usuario): el dinero sale de vender
     al capataz lo que produce la planta.
       item    el objeto del inventario (origen_inventory/config/items.lua)
       precio  lo que paga el capataz por cada uno
       funde   los metales salen triturados del contenedor y se llevan al
               horno (en brazos o en la carretilla); de cada pedrusco sale un
               lingote. Lo demás sale ya triturado, directo al inventario.
     28/09: los cuatro trabajos pagan lo mismo, como mucho 3.000 $ cada
     30 min a nivel máximo (Config.Tope lo corta ahí). Precios ×2: el nivel
     5 pasa de ~3.000 a ~6.000 $/h (≈ 3.000 $/30 min) y el nivel 1 a ~1.250
     $/30 min. Las cuentas de abajo son las de antes, con los precios viejos.
     LAS CUENTAS (27/09, con los tiempos de este config; objetivo: la granja,
     ~1.700 $/h quien empieza, ~2.500 de media, ~3.500 un veterano). Cada
     pedrusco vale ~1,3–1,6 veces lo que se cobraba al descargar, porque la
     planta pide más trabajo (recoger, llevar al horno y vender).
       picar: 3 × 4,5 s → 2 pedruscos (con martillo × 0,6); a la caja ~5 s;
       viaje a la tolva por pedrusco: carretilla desde el Frente Sur ~30 s,
       camioneta ~15 s; cada metal al horno ~10 s más
       nivel 1  carretilla, piedra y carbón (12,5 $ de media): ~100/h
                (el frente T da 18 cada 20 min; el resto, de A/B/C) ≈ 1.250 $/h
       nivel 3  camioneta y carretilla, hasta cobre (17,4 $, 36 % metal):
                ~28 s por pedrusco → ~128/h ≈ 2.200 $/h (sin volquete)
       nivel 5  martillo y cuarzo (18,5 $): ~22 s → ~160/h ≈ 3.000 $/h, y
                cada voladura (12 pedruscos, 12 % de oro) deja ~410 $ menos
                4 cargas: ver Config.Explosivos.precio
     Siguen siendo cuentas: medir con las ventas reales (`Datos.Stat` ganado
     y vendidos) cuando haya gente jugando y ajustar. ]]
Config.Productos = {
    piedra = { item = 'grava', nombre = 'Grava', precio = 22 },
    carbon = { item = 'carbon_mineral', nombre = 'Carbón', precio = 30 },
    hierro = { item = 'lingote_hierro', nombre = 'Lingote de hierro', precio = 48, funde = true },
    cobre  = { item = 'lingote_cobre', nombre = 'Lingote de cobre', precio = 58, funde = true },
    cuarzo = { item = 'cuarzo', nombre = 'Cuarzo triturado', precio = 60 },
    oro    = { item = 'lingote_oro', nombre = 'Lingote de oro', precio = 300, funde = true },
}

-- ── Maquinaria ────────────────────────────────────────────────────────────
Config.Vehiculos = {
    abandono = 10 * MIN,
    tipos = {
        --[[ La camioneta: la carga en la caja, con el portón abierto. ]]
        camioneta = {
            nombre = 'Camioneta', nivel = 2, modelo = 'bison',
            fianza = 150, flota = 12, porton = true,
            -- Huecos de la caja (desde el centro del vehículo): tres filas de
            -- dos a la izquierda; la derecha es para la carretilla (27/09).
            carga = { columnas = { -0.5, -0.14 }, filas = { -1.25, -1.8, -2.35 }, pisos = 1, suelo = 0.44, alto = 0.40 },   -- suelo: caja a 0,267 m + 0,176 del pedrusco (medido)
            -- A pie, dónde se echa la piedra: detrás del portón.
            trasera = vec3(0.0, -3.4, 0.0),
            -- La carretilla viaja tumbada a lo largo de la caja, con la rueda
            -- hacia la cabina (de pie quedaba mal, 27/09). Desde el centro del
            -- vehículo; sale ya aquí al empezar la jornada con la camioneta.
            carretilla = { pos = vec3(0.36, -1.85, 0.30), rot = vec3(0.0, 0.0, 90.0) },   -- a ras: suelo de la caja a 0,267 m, patas a -0,032
            cuadro = { largo = 6.5, ancho = 2.8 },
            detalle = 'Lleva poca piedra, pero siempre hay alguna libre.',
        },
    },
    -- El volquete (tiptruck, nivel 3) se quitó el 27/09 a petición del
    -- usuario: se trabaja solo con la carretilla y la camioneta.
    orden = { 'camioneta' },
}

-- ── La descarga ───────────────────────────────────────────────────────────
--[[ Desde el 27/09 la descarga NO se cobra: lo descargado pasa por la planta
     a tu nombre y se cobra al vender lo que sale (Config.Productos). Lo de
     abajo son las cuentas de cuando se cobraba al descargar (el `pago` de
     cada veta sigue sirviendo de referencia para los precios de venta).
     `lleno` ya no se usa.

     LAS CUENTAS (objetivo: 900–1.200 $ cada 30 min para el nivel alto; quien
     empieza, la mitad). TEÓRICAS: hay que medirlas jugando y rehacerlas.
       picar una roca (3 tandas de 4,5 s + girarse): ~16 s → 2 pedruscos
       llevar un pedrusco a la caja a pie: ~10 s (con carretilla, ~5 s)
       ida y vuelta a la planta y descarga: ~110 s por viaje
       nivel 1  camioneta (6) + pico, piedra y carbón (~10,2 $):
                ~6 × 18 + 110 ≈ 218 s por viaje → ~50 pedruscos ≈ 560 $/30 min
       nivel 3  volquete (12) + carretilla, hasta cobre (~12,6 $):
                ~12 × 13 + 110 ≈ 266 s → ~81 pedruscos ≈ 1.100 $/30 min
       nivel 5  martillo + voladuras (12 de golpe, algo de oro): ~1.200 $
                (las cargas cuestan 60 $ cada una) ]]
Config.Descarga = {
    lleno = 0.10,     -- extra sobre el total si llega lleno
    duracion = 9,     -- segundos de la descarga (la piedra vuela a la tolva)
}

-- ── El equipo de trabajo ──────────────────────────────────────────────────
Config.Equipo = {
    max = 4,
    distancia = 5.0,
    invitacion = 30,
    jornada = 'minaJornada',
    nombre = 'la cantera',
    bag = 'minaEquipo',
}

-- ── Niveles ───────────────────────────────────────────────────────────────
--[[ Lo que abre cada nivel sale de los `nivel` de vetas, herramientas,
     carretilla, explosivos y vehículos. La experiencia: por roca partida (la
     `xp` de su veta), por pedrusco cargado y por pedrusco descargado. ]]
Config.Niveles = {
    { xp = 0,    rango = 'Peón' },
    { xp = 150,  rango = 'Picador' },
    { xp = 400,  rango = 'Barrenero' },
    { xp = 900,  rango = 'Artillero' },
    { xp = 1800, rango = 'Maestro de voladuras' },
}

Config.XP = { cargar = 1, descargar = 1, voladura = 10, fundir = 1 }

Config.Anims = {
    echar = { dict = 'anim@heists@box_carry@', clip = 'idle', flag = 49 },
    palanca = { dict = 'amb@prop_human_parking_meter@male@base', clip = 'base', flag = 1 },
}

Config.DistanciaVer = 160.0
Config.Limites = { colision = 40.0, pedruscos = 140.0 }

-- ── Los topes (28/09, el usuario) ─────────────────────────────────────────
--[[ Los cuatro trabajos (granja, aserradero, mina y basuras) pagan lo mismo:
     como mucho `dinero` cada `ventana` a nivel máximo, y admiten como mucho
     `trabajadores` de jornada a la vez (hasta que sale uno no entra otro).
     Lo decide server/tope.lua, el mismo fichero en los cuatro. ]]
Config.Tope = {
    trabajadores = 10,
    dinero = 3000,
    ventana = 30 * MIN,
}
