-- ECONOMÍA de las viviendas. Se carga el ÚLTIMO de config/ (por eso el «zz_»):
-- cuando llega aquí ya están el catálogo (config/furniture.lua), los packs
-- (config/packs.lua + config/zpack_*.lua) y la obra (config/obra.lua).
--
-- Qué hace este fichero:
--   1. Config.Economia.obra     → lo que cuesta construir (lo cobra Config.Obra.Coste, config/obra_tamanos.lua)
--   2. Config.Economia.muebles  → REGLAS de precio del catálogo; al cargar recorre
--                                 Config.Furniture y pone el `price` de cada mueble
--   3. Config.Economia.tamanos  → cuánto pedir por una casa según su tamaño
--   4. Config.Economia.packs    → precio en XP de cada pack (y su equivalente en dinero)
--   5. Config.Economia.mejoras  → sube las mejoras de la casa (alarma, cámaras…)
--
-- De dónde salen las cifras: fuente/economia.md (base real, 12/10/2026). En corto:
--   · un jugador MEDIO ingresa ~1.400 $ por hora jugada; uno bueno, 2.000–2.700 $;
--     el 5 % más rico, ~3.000–3.500 $ (el tope teórico de un trabajo son 6.000 $/h)
--   · una sesión de 3 h deja ~4.000 $ al medio y ~9.000 $ al rico
--   · patrimonio: mediana 20.000 $, uno de cada diez pasa de 100.000 $, el 1 % de 350.000 $
--   · un coche: mediana 12.000 $, uno bueno 45.000–80.000 $, los caros 150.000–270.000 $
--
-- CÓMO RETOCAR: casi todo se mueve con los multiplicadores de aquí arriba.
-- PARA DESACTIVAR los precios por reglas y volver a los que trae cada fichero:
-- `aplicar = false` en Config.Economia.muebles.
Config.Economia = {
    -- Sube o baja TODO lo que se paga en dinero (obra, muebles, mejoras, tamaños). 1.2 = un 20 % más caro.
    global = 1.0,

    ---------------------------------------------------------------------------
    -- 1. OBRA: construir el interior de una casa de modalidad «Libre»
    ---------------------------------------------------------------------------
    obra = {
        -- DECISIÓN DEL DUEÑO (13/10/2026): construir la casa NO cuesta dinero. Lo que se paga es
        -- amueblarla. Con `estructuraGratis` todo lo que es bloque sale a 0 $: abrir celdas,
        -- paredes, suelos, huecos de puerta y de garaje, escaleras, barandillas, esquinas,
        -- cantos y pintar. Siguen costando los mecanismos (ascensor, montacoches, paso secreto,
        -- trampilla) y poner una imagen propia. Los números de abajo se conservan por si se
        -- vuelve a cobrar: basta con poner esto en false.
        estructuraGratis = true,
        -- Abrir (excavar) una celda de 2x2 m. La sala de partida (5x5) va con la casa.
        celda = 300,
        -- Piezas puestas a mano, por la letra con la que se guardan en la obra
        pieza = {
            p = 150,      -- pared entre dos salas
            u = 300,      -- hueco de puerta (la puerta, aparte: es un mueble del catálogo)
            g = 2000,     -- hueco de garaje (el portón, aparte)
            d = 500,      -- hueco de puerta doble
            l = 200,      -- suelo entre plantas (por celda)
            e = 3000,     -- escalera (la recta; el precio de cada forma, abajo en `escalera`)
            a = 1000,     -- ascensor, POR PLANTA que recorre (uno de 4 plantas: 4.000 $)
            c = 1500,     -- montacoches, POR PLANTA
            baranda = 250,
            secreto = 1000,    -- puerta oculta (librería, armario, pared falsa, espejo espía…)
            trampilla = 500,
            esquina = 500,     -- esquina redondeada en un rincón (cualquiera de los radios)
            canto = 300,       -- canto redondo en un saliente o en el final de un tabique
        },
        -- Escalera por forma (el número es la forma de Config.Obra.Escalera): Config.Economia.Pieza('e', forma)
        escalera = { recta = 3000, l = 4000, mano = 1000, caracol = 5000, caracol2 = 9000,
                     [0] = 3000, [1] = 4000, [2] = 4000, [3] = 1000, [4] = 5000, [5] = 9000 },
        -- La cabina grande del ascensor multiplica el precio por planta
        cabina = { ['1x1'] = 1.0, ['2x1'] = 1.5, ['2x2'] = 2.0 },
        -- Pintar UNA cara (pared, suelo o techo), sin mirar el material: es lo que se
        -- cobra mientras quien cobra no pregunte por material.
        pintar = 40,
        -- Pintar una cara según el material: Config.Economia.Pintar(material)
        pintarMaterial = {
            -- lisos: baratos
            blanco = 25, crema = 25, gris = 25, azul = 25, verde = 25,
            -- gastados y de guarida: baratos
            ladrillo_viejo = 25, ladrillo_cal = 25, bloque = 25, humedad = 20, desconchado = 20,
            chapa_oxido = 25, tablones = 25, cemento_aceite = 20, azulejo = 25, linoleo = 25,
            moqueta_sucia = 20, chapa_lagrimada = 30,
            -- normales
            hormigon = 40, ladrillo = 45, madera = 50, baldosa = 45, moqueta = 45,
            -- de lujo
            marmol = 100, marmol_negro = 110, parquet_oscuro = 90, microcemento = 80, papel = 70, pizarra = 80,
            -- cristal (solo entre dos espacios de la casa)
            cristal = 150, cristal_ahumado = 160, cristal_mate = 160, cristal_azul = 180,
            cristal_bronce = 180, cristal_negro = 180, cristal_acanalado = 190,
        },
        imagen = 1000,      -- poner una imagen propia en una cara
        -- Lo que vuelve al rellenar una celda o quitar una pieza (0.5 = la mitad de lo que costó).
        -- Pintar y las imágenes no devuelven nada.
        devolucion = 0.5,
    },

    ---------------------------------------------------------------------------
    -- 2. MUEBLES: reglas de precio de TODO el catálogo
    ---------------------------------------------------------------------------
    -- Para cada mueble, en este orden:
    --   a) si está en `excepciones` (por modelo) o encaja en `prefijos` → ese precio, tal cual
    --   b) si el fichero que lo da de alta le puso un precio pensado (distinto de `plano`,
    --      los 100 $ de relleno del catálogo viejo) → ese precio × `mult` de su categoría
    --   c) si no → `base` de su categoría × la primera `palabra` que salga en el nombre del
    --      modelo × `propio` si el modelo es nuestro (origen_*)
    --   d) según su tipo (`tipos`): los almacenajes valen como mínimo lo que marca su
    --      capacidad; roperos, teles, cámaras, puertas… tienen un suelo
    --   e) × `global`, suelo `minimo` y redondeo bonito
    -- Lo que viene en un pack de pago ya se pagó en XP: en dólares vale algo simbólico
    -- (`enPack` del precio que saldría, con el tope `enPackTope`). Solo conserva su mínimo
    -- lo que da algo más que aspecto: el almacenaje (por su capacidad) y las cámaras.
    muebles = {
        aplicar = true,     -- false: no se toca ningún precio (quedan los de cada fichero)
        plano = 100,        -- el precio «de relleno»: quien lo lleva no tiene precio pensado
        minimo = 50,        -- nada vale menos (comida y bebidas de adorno)
        propio = 1.6,       -- lo nuestro (origen_*) frente a un prop del juego de su categoría
        -- DECISIÓN DEL DUEÑO (14/10/2026): amueblar era caro en general. `rebaja` multiplica el
        -- precio que sale de las reglas (b) y (c) de TODO el catálogo; 1.0 = los precios de antes.
        rebaja = 0.40,
        enPack = 0.25,      -- lo que viene en un pack de pago: este trozo de su precio ya rebajado…
        enPackTope = 1500,  -- …y nunca más de esto
        -- Lo que vuelve al quitar un mueble, sobre lo que se PAGÓ por él (no sobre el precio
        -- de hoy: los muebles de antes costaron 100 $ y devolver el 45 % del precio nuevo
        -- sería fabricar dinero). Hoy el housing no devuelve nada: ver fuente/economia.md.
        reembolso = 0.45,
        reembolsoSinRegistro = 0,   -- muebles comprados antes de guardar lo pagado: no devuelven

        -- Categoría del catálogo → { base = precio de una pieza normal, mult = por cuánto se
        -- multiplica el precio provisional de quien la dio de alta }
        categorias = {
            ['Sillones']                     = { base = 900, mult = 2.5 },
            ['Sillas']                       = { base = 350,  mult = 2.5 },
            ['Mesas']                        = { base = 700,  mult = 2.5 },
            ['Camas']                        = { base = 2000, mult = 2.5 },
            ['Escritorios']                  = { base = 1400, mult = 2.5 },
            ['Muebles']                      = { base = 1100, mult = 2.5 },
            ['Arte']                         = { base = 600,  mult = 3.0 },
            ['Cuadros personalizados']       = { base = 1200, mult = 3.0 },
            ['Decoración']                   = { base = 180,  mult = 2.5 },
            ['Esculturas y premios']         = { base = 1200, mult = 3.0 },
            ['Trofeos']                      = { base = 900, mult = 3.0 },
            ['Joyas']                        = { base = 2000, mult = 3.0 },
            ['Paredes']                      = { base = 300,  mult = 2.5 },
            ['Alfombras']                    = { base = 600,  mult = 2.5 },
            ['Plantas']                      = { base = 220,  mult = 2.2 },
            ['Luces']                        = { base = 250,  mult = 3.0 },
            ['Puntos de luz']                = { base = 500,  mult = 2.5 },
            ['Carteles de neón']             = { base = 1400, mult = 3.0 },
            ['Electrodomésticos']            = { base = 1200, mult = 3.0 },
            ['Neveras']                      = { base = 1600, mult = 3.0 },
            ['Cocina']                       = { base = 300,  mult = 3.0 },
            ['Comida']                       = { base = 60,   mult = 1.5 },
            ['Bebidas']                      = { base = 80,  mult = 1.5 },
            ['Baño']                         = { base = 500,  mult = 3.0 },
            ['Lavandería y limpieza']        = { base = 250,  mult = 3.0 },
            ['Tecnología']                   = { base = 600,  mult = 3.0 },
            ['Televisores con mueble']       = { base = 4000, mult = 3.0 },
            ['Música / DJ']                  = { base = 1200, mult = 8.0 },
            ['Instrumentos']                 = { base = 1000, mult = 3.0 },
            ['Juegos y juguetes']            = { base = 300,  mult = 3.0 },
            ['Gimnasio']                     = { base = 600,  mult = 4.0 },
            ['Jardín y patio']               = { base = 300,  mult = 2.5 },
            ['Mascotas']                     = { base = 250,  mult = 2.5 },
            ['Libros y velas']               = { base = 100,  mult = 2.0 },
            ['Varios']                       = { base = 220,  mult = 2.5 },
            ['Sótano']                       = { base = 300,  mult = 3.0 },
            ['Sótano: celda y herramientas'] = { base = 400,  mult = 3.0 },
            ['Puertas']                      = { base = 700,  mult = 2.5 },
            ['Cámaras de seguridad']         = { base = 6000, mult = 1.2 },
            ['Armarios']                     = { base = 2500, mult = 1.3 },
            ['Almacenaje']                   = { base = 1500, mult = 1.3 },
            ['Armeros']                      = { base = 5000, mult = 1.3 },
            ['Secretos']                     = { base = 3000, mult = 2.0 },
            ['Taller y exposición']          = { base = 15000, mult = 3.0 },
        },
        -- Categorías que aparezcan después (packs nuevos) y no estén arriba
        categoriaPorDefecto = { base = 700, mult = 2.5 },

        -- Solo para la regla (c): trozos del nombre del modelo, en minúsculas. Manda el
        -- PRIMERO que salga, así que lo concreto va antes que lo general.
        palabras = {
            { 'vault_painting', 8.0 }, { 'artwalll', 1.8 }, { 'artwallm', 1.3 }, { 'artwalls', 0.9 },
            { 'sofacorn', 3.0 }, { 'sofa3seat', 2.4 }, { 'sofa2seat', 1.8 }, { 'sofabed', 2.0 }, { 'daybed', 1.8 },
            { 'yacht_sofa', 2.6 }, { 'sofa', 2.0 }, { 'lounger', 1.3 }, { 'foot_stool', 0.5 }, { 'chairstool', 0.6 }, { 'pouf', 0.5 },
            { 'piano', 6.0 }, { 'jacuzzi', 8.0 }, { 'hottub', 8.0 }, { 'hot_tub', 8.0 }, { 'pooltable', 5.0 }, { 'pool_table', 5.0 },
            { 'arcade', 4.0 }, { 'gold', 4.0 }, { 'diamond', 5.0 }, { 'doorsafe', 4.0 }, { 'statue', 2.0 }, { 'chandelier', 3.0 },
            { 'server', 3.0 }, { 'laptop', 1.5 }, { 'monitor', 1.2 }, { 'console', 1.5 },
            { 'photoframe', 0.4 }, { 'picture_frame', 0.4 }, { 'pictureframe', 0.4 }, { '_photo', 0.4 },
            { 'bottle', 0.4 }, { 'ashtray', 0.3 }, { 'lipstick', 0.3 }, { 'pill', 0.3 }, { 'trinket', 0.5 },
            { 'candle', 0.5 }, { 'bowl', 0.5 }, { 'vase', 0.8 },
        },

        -- Por tipo de mueble
        tipos = {
            -- Almacenaje: mínimo = fijo + porKilo × kilos del baúl (Config.StashesTypes)
            --   small 5 kg → 525 · normal 20 kg → 1.200 · medium 25 kg → 1.425
            --   big 50 kg → 2.550 · extrabig 100 kg → 4.800
            stash = { fijo = 300, porKilo = 45 },
            wardrobe = { suelo = 800 },
            tv = { suelo = 1200 },
            camera = { suelo = 2500 },
            door = { suelo = 300 },
            light = { suelo = 200 },
            board = { suelo = 800 },
            carlift = { suelo = 5000 },
        },

        -- Modelos que empiezan por… → precio fijo (gana a las reglas, pierde con `excepciones`)
        prefijos = {
            { 'origen_casa_porton_', 1500 },     -- portones de garaje propios
            { 'prop_gar_door_', 1000 },          -- portones del juego
            { 'origen_casa_luz_neon_', 500 },   -- neones propios
        },

        -- Modelo → precio fijo. Aquí se retoca a mano lo que las reglas no clavan.
        excepciones = {
            -- lo básico, para que quien empieza pueda instalarse
            ['origen_casa_luz_bombilla'] = 150,
            ['origen_casa_luz_interruptor'] = 200,
            ['origen_casa_alm_cajas'] = 400,          -- cajas de mudanza: el primer baúl
            ['origen_casa_rop_viejo'] = 800,         -- el primer armario
            ['origen_casa_rop_burro'] = 1000,
            -- lo más caro del catálogo
            ['origen_casa_rop_lujo'] = 12000,
            ['origen_casa_luz_arana'] = 1800,
            ['origen_casa_alm_caja_fuerte'] = 6000,
            ['origen_casa_alm_armero'] = 5500,
            ['origen_casa_alm_armero_tactico'] = 8500,
            ['origen_casa_alm_armero_seguridad'] = 12000,
            ['origen_casa_caja_cuadro'] = 5000,      -- caja fuerte escondida tras un cuadro
            -- REVISIÓN FINAL (13/10). «Música / DJ» multiplica por 8 (pensado para los props del juego,
            -- que traían precios de relleno) y a los ocho muebles del pack «Estudio de música», que ya
            -- traían un precio pensado, los dejaba fuera de escala: un micrófono de pie a 12.000 $, una
            -- banqueta a 14.500 $, la mesa de DJ a 96.000 $ (más que el jacuzzi). Se fijan a mano, en
            -- línea con el resto de packs (precio del fichero × 3):
            ['origen_casa_ofi_micro_pie'] = 1800,
            ['origen_casa_ofi_banqueta_piano'] = 2200,
            ['origen_casa_ofi_altavoz_estudio'] = 2900,
            ['origen_casa_ofi_ampli'] = 3100,
            ['origen_casa_ofi_tocadiscos'] = 3400,
            ['origen_casa_ofi_teclado_sinte'] = 5000,
            ['origen_casa_ofi_piano'] = 11000,
            ['origen_casa_ofi_mesa_dj'] = 14000,
        },
    },

    ---------------------------------------------------------------------------
    -- 3. TAMAÑOS: cuánto pedir por una casa al crearla o venderla (orientativo
    --    para el admin; el precio de cada casa lo sigue poniendo él en el panel)
    ---------------------------------------------------------------------------
    -- `dinero` y `xp` son alternativas (o lo uno o lo otro). Los ids son los de
    -- Config.Obra.tamanos (config/obra_tamanos.lua), que es donde están los topes de
    -- celdas, piezas y muebles de cada tamaño.
    -- PRECIOS DEL DUEÑO (13/10/2026): Pequeña 500 · Media 800 · Grande 1.200 · Premium 2.000 XP
    tamanos = {
        -- (los topes son los de config/obra_tamanos.lua: si se cambian allí, este comentario se queda viejo;
        -- la tienda los lee de allí con exports.origen_housing:Tamanos())
        pequena = { nombre = 'Pequeña', dinero = 35000,  xp = 500 },    -- 35 celdas, 40 muebles
        media   = { nombre = 'Media',   dinero = 90000,  xp = 800 },    -- 110 celdas, 90 muebles
        grande  = { nombre = 'Grande',  dinero = 220000, xp = 1200 },    -- 260 celdas, 150 muebles
        premium = { nombre = 'Premium', dinero = 500000, xp = 2000 },   -- 1.200 celdas, 250 muebles
    },
    -- Pasar una casa a un tamaño mayor: la diferencia entre los dos + este recargo
    mejoraTamano = 0.10,

    ---------------------------------------------------------------------------
    -- 4. PACKS de contenido, en XP (la moneda de donación)
    ---------------------------------------------------------------------------
    -- Referencias de lo que ya se vende por XP en el servidor: casa pequeña 150–300,
    -- media 500, grande 800; coche o moto VIP 500; mascota VIP 150–500; prenda
    -- cosmética 50–590. Tebex vende la XP en lotes de 300, 500, 800 y 2.000.
    -- A quién se le da un pack lo decide quien lo vende: la tienda «Apoya al proyecto»
    -- (origen_vipsystem/catalogo/ajustes.lua, packPor = 'cuenta') lo da a la CUENTA del
    -- dueño y vale en todas sus casas; el panel /casacosmeticos puede darlo a una casa sola.
    -- REVISIÓN FINAL (13/10): con los 28 packs de muebles de la noche hay 40 packs y
    -- todos juntos suman 9.650 XP (antes 13 packs y 3.900 XP: la cuenta de «cabe en el
    -- lote de 2.000 XP de Tebex» ya no vale). Los lotes que se venden son los de la
    -- tienda (origen_vipsystem/catalogo/productos.lua, Catalogo.Lotes), no los de aquí.
    -- Todos los precios van escritos abajo para que no cambien solos al añadir un
    -- mueble a un pack (la cuenta de `packPorDefecto` solo vale para un pack nuevo).
    -- REGLA DEL DUEÑO (13/10/2026): nada en la tienda baja de 300 XP, y un pack no puede
    -- costar lo mismo que una pieza exclusiva suelta (300–400 XP): un pack vale SIEMPRE
    -- más, y más cuanto más trae. El precio sale solo de `packPorDefecto` (abajo) para
    -- todos los packs, los de hoy y los que lleguen; aquí solo van las EXCEPCIONES que
    -- se quieran fijar a mano (id = XP). Con la regla de hoy: 6 muebles 500 · 13 muebles
    -- 550 · 25 muebles 800 · 44 muebles 1.200 · 9 materiales 550 · 12 materiales 600.
    packs = {
    },
    -- Packs sin precio arriba: el `xp` que traiga el propio pack si es mayor que 0 y,
    -- si no, esta cuenta por lo que trae.
    packPorDefecto = {
        -- ECONOMÍA DE LA TIENDA (dueño, 12/10 noche): la XP es cara (el paquete pequeño de la
        -- web son 300 XP) y con packs de 500 a 1.500 nadie compraba. Ahora un pack va de 350
        -- a 600 según lo que trae: 6 muebles 350 · 13 muebles 400 · 25 muebles 450 · 44
        -- muebles 550 · un pack de obra con dos herramientas 450. Sigue valiendo SIEMPRE más
        -- que una pieza suelta (300, el mínimo de la tienda).
        -- BAJADA DEL DUEÑO (13/10 tarde): «el mínimo que sea 150» para que haya volumen. Todo a la mitad:
        -- una pieza suelta 150 y un pack de 150 a 300 según lo que trae: «los packs que sean muchos props, 300».
        -- Con esta cuenta: hasta 6 muebles 150 · 7–18 muebles 200 · 19–31 muebles 250 · 32 o más 300.
        fijo = 150,
        porModelo = 4,          -- cada mueble
        porHerramienta = 30,    -- cada herramienta de obra (ascensor, montacoches…)
        porMaterial = 4,        -- cada material de pintar
        porEstilo = 4,          -- cada estilo (barandilla, paso secreto, trampilla)
        minimo = 150, maximo = 300,
        redondeo = 50,
    },
    -- Lotes con descuento. `packs`: lista de ids, o un criterio:
    --   'todos' · 'obra' (los que traen herramientas, materiales o estilos) · 'muebles' (los que solo traen muebles)
    -- El precio del lote es la suma de sus packs con el descuento (se calcula solo: Config.Economia.Lote).
    lotes = {
        construccion = { nombre = 'Todo construcción', packs = 'obra', descuento = 0.35 },
        mobiliario = { nombre = 'Todo mobiliario', packs = 'muebles', descuento = 0.30 },
        lujo = { nombre = 'Todo lujo', packs = { 'materiales_lujo', 'cristales', 'ascensores', 'secretos', 'vestidor', 'armeria' }, descuento = 0.25 },
        todo = { nombre = 'Colección completa', packs = 'todos', descuento = 0.50 },
    },
    -- Comprar un pack con DINERO del juego en vez de XP: caro, pero posible («todo se
    -- puede conseguir jugando»). Un pack de 300 XP sale por 150.000 $. Los lotes, solo por XP.
    -- DECISIÓN DEL DUEÑO (12/10/2026): los cosméticos (packs, piezas sueltas, tamaños)
    -- se consiguen SOLO por XP en la tienda «Apoya al proyecto». Con dinero del juego
    -- no se venden: si se dan, los da un admin desde su panel. No activar.
    packsDinero = {
        activo = false,
        porXP = 500,            -- $ por cada XP del precio del pack
        soloMuebles = false,    -- true: los packs con herramientas de obra, solo por XP
    },

    ---------------------------------------------------------------------------
    -- 5. MEJORAS de la casa (config/upgrades.lua) y huecos de baúl/ropero de los MLO
    ---------------------------------------------------------------------------
    mejoras = {
        aplicar = true,
        mult = 2.0,             -- alarma 20.000 · cámaras 24.000 · puertas 30.000 · resto 20.000
        hueco = 10000,          -- Config.MloPoints.slotPrice (antes 5.000)
    },
}

-------------------------------------------------------------------------------
-- A partir de aquí, el código que aplica lo de arriba. No hace falta tocarlo.
-------------------------------------------------------------------------------
local E = Config.Economia

--- Redondeo bonito: de 10 en 10 hasta 500, de 50 hasta 2.000, de 100 hasta
--- 10.000, de 500 hasta 50.000 y de 1.000 en adelante.
function Config.Economia.Redondear(n)
    n = tonumber(n) or 0
    local paso = n < 500 and 10 or n < 2000 and 50 or n < 10000 and 100 or n < 50000 and 500 or 1000
    return math.floor(n / paso + 0.5) * paso
end

local GLOBAL = tonumber(E.global) or 1

local function Dinero(n)
    return E.Redondear((tonumber(n) or 0) * GLOBAL)
end

-- El multiplicador global se aplica aquí, una vez, a los números de la obra: así
-- vale lo mismo para quien los lee sueltos (config/obra_tamanos.lua) que para las
-- funciones de abajo.
do
    local o = E.obra
    local function Escalar(t)
        for k, v in pairs(t) do
            if type(v) == 'number' then t[k] = math.max(0, math.floor(v * GLOBAL + 0.5)) end
        end
    end
    o.celda = math.floor(o.celda * GLOBAL + 0.5)
    o.pintar = math.floor(o.pintar * GLOBAL + 0.5)
    o.imagen = math.floor(o.imagen * GLOBAL + 0.5)
    Escalar(o.pieza) Escalar(o.escalera) Escalar(o.pintarMaterial)

    -- Construir no se cobra: los bloques, a cero (los mecanismos y la imagen se quedan)
    if o.estructuraGratis then
        o.celda, o.pintar = 0, 0
        for _, letra in ipairs({ 'p', 'u', 'g', 'd', 'l', 'e', 'baranda', 'esquina', 'canto' }) do o.pieza[letra] = 0 end
        for k in pairs(o.escalera) do o.escalera[k] = 0 end
        for k in pairs(o.pintarMaterial) do o.pintarMaterial[k] = 0 end
    end
end

-- ── Obra ─────────────────────────────────────────────────────────────────────

--- Precio de abrir una celda.
function Config.Economia.Celda()
    return E.obra.celda
end

--- Precio de una pieza de obra. `letra`: 'p', 'u', 'g', 'd', 'l', 'e', 'a', 'c',
--- 'baranda', 'secreto', 'trampilla', 'esquina' o 'canto'. `dato`: en 'e', la forma (0..5 o su nombre);
--- en 'a' y 'c', las plantas que recorre; `cabina` ('1x1', '2x1', '2x2') en 'a'.
function Config.Economia.Pieza(letra, dato, cabina)
    local o = E.obra
    local p = tonumber(o.pieza[letra]) or 0
    if letra == 'e' then
        p = o.escalera[dato] or o.escalera[tonumber(dato) or -1] or p
    elseif letra == 'a' or letra == 'c' then
        p = p * math.max(1, math.floor(tonumber(dato) or 1))
        if letra == 'a' and cabina then p = p * (o.cabina[cabina] or 1) end
    end
    return math.floor(p)
end

--- Precio de pintar una cara con ese material.
function Config.Economia.Pintar(material)
    local t = E.obra.pintarMaterial
    return math.floor(tonumber(material and t[material]) or E.obra.pintar)
end

--- Precio de poner una imagen en una cara.
function Config.Economia.Imagen()
    return E.obra.imagen
end

--- Lo que se devuelve de algo de obra que costó `pagado`.
function Config.Economia.DevolucionObra(pagado)
    return math.floor((tonumber(pagado) or 0) * (tonumber(E.obra.devolucion) or 0))
end

-- ── Muebles ──────────────────────────────────────────────────────────────────

local M = E.muebles
local provisional = {}   -- modelo → precio que traía antes de pasar por aquí
local puesto = {}        -- modelo → precio que le hemos puesto

local function Kilos(item)
    local s = item.stash
    if type(s) == 'string' then s = Config.StashesTypes and Config.StashesTypes[s] end
    return type(s) == 'table' and tonumber(s.weight) or nil
end

local function Calcular(item, etiqueta)
    local modelo = item.model
    local fijo = M.excepciones[modelo]
    if not fijo then
        for _, p in ipairs(M.prefijos) do
            if modelo:sub(1, #p[1]) == p[1] then fijo = p[2] break end
        end
    end
    -- ¿es de un pack de pago? (o de los que un pack regala a todas las casas)
    local P = Config.Packs
    local dePack = P ~= nil and ((item.pack ~= nil and item.pack ~= P.base)
        or (P.deModelo[modelo] ~= nil and P.deModelo[modelo] ~= P.base)
        or (P.basicos ~= nil and P.basicos[modelo] == true))
    local function Simbolico(precio)
        return math.min(precio * (M.enPack or 1), M.enPackTope or precio)
    end
    if fijo then return math.max(M.minimo, Dinero(dePack and Simbolico(fijo) or fijo)) end

    local cat = M.categorias[etiqueta] or M.categoriaPorDefecto
    local trae = tonumber(provisional[modelo])
    local precio
    if trae and trae > 0 and trae ~= M.plano then
        precio = trae * cat.mult
    else
        precio = cat.base
        local nombre = modelo:lower()
        for _, p in ipairs(M.palabras) do
            if nombre:find(p[1], 1, true) then precio = precio * p[2] break end
        end
        if nombre:sub(1, 7) == 'origen_' then precio = precio * M.propio end
    end
    precio = precio * (M.rebaja or 1)

    if dePack then precio = Simbolico(precio) end

    local clase = item.type or 'object'
    local tipo = M.tipos[clase]
    if tipo then
        if tipo.porKilo then
            local kg = Kilos(item)
            if kg then precio = math.max(precio, (tipo.fijo or 0) + tipo.porKilo * kg) end
        end
        if tipo.suelo and (not dePack or clase == 'camera') then precio = math.max(precio, tipo.suelo) end
    end

    return math.max(M.minimo, Dinero(precio))
end

--- Pone precio a todo el catálogo. Se puede llamar más de una vez: lo que ya
--- tiene precio puesto por aquí no se vuelve a multiplicar.
function Config.Economia.AplicarMuebles()
    if not M.aplicar or type(Config.Furniture) ~= 'table' then return 0 end
    local n = 0
    for _, cat in ipairs(Config.Furniture) do
        for _, item in ipairs(cat.items or {}) do
            if type(item) == 'table' and type(item.model) == 'string' then
                if puesto[item.model] == nil then
                    provisional[item.model] = item.price
                    item.price = Calcular(item, cat.label)
                    puesto[item.model] = item.price
                    n = n + 1
                elseif item.price ~= puesto[item.model] then
                    -- el mismo modelo dado de alta dos veces: un solo precio
                    item.price = puesto[item.model]
                end
            end
        end
    end
    -- Los almacenajes y roperos retirados del catálogo (siguen colocados en casas)
    for _, item in ipairs(Config.Almacenajes and Config.Almacenajes.antiguos or {}) do
        if type(item) == 'table' and type(item.model) == 'string' and puesto[item.model] == nil then
            provisional[item.model] = item.price
            item.price = Calcular(item, item.type == 'wardrobe' and 'Armarios' or 'Almacenaje')
            puesto[item.model] = item.price
            n = n + 1
        end
    end
    return n
end

--- Precio de hoy de un modelo del catálogo (nil si no está) y el que traía antes de las reglas.
function Config.Economia.PrecioDe(modelo)
    return puesto[modelo], provisional[modelo]
end

--- Lo que se devuelve al quitar un mueble por el que se pagó `pagado`
--- (nil = no consta lo pagado: mueble de antes de guardarlo).
function Config.Economia.Reembolso(pagado)
    if pagado == nil then return math.floor(tonumber(M.reembolsoSinRegistro) or 0) end
    return math.floor((tonumber(pagado) or 0) * (tonumber(M.reembolso) or 0))
end

-- ── Packs ────────────────────────────────────────────────────────────────────

local function Contar(tabla, id)
    local n = 0
    for _, pack in pairs(tabla or {}) do if pack == id then n = n + 1 end end
    return n
end

--- ¿Trae ese pack algo de obra (herramientas, materiales o estilos)?
function Config.Economia.PackEsDeObra(id)
    local P = Config.Packs
    return Contar(P.deHerramienta, id) + Contar(P.deMaterial, id) + Contar(P.deEstilo, id) > 0
end

local function XpPorDefecto(pack)
    local P, d = Config.Packs, E.packPorDefecto
    local xp = d.fijo + d.porModelo * #(pack.modelos or {}) + d.porHerramienta * Contar(P.deHerramienta, pack.id)
        + d.porMaterial * Contar(P.deMaterial, pack.id) + d.porEstilo * Contar(P.deEstilo, pack.id)
    xp = math.floor(xp / d.redondeo + 0.5) * d.redondeo
    return math.max(d.minimo, math.min(d.maximo, xp))
end

--- Pone `xp` y `dinero` a cada pack registrado. El `base` es gratis siempre.
function Config.Economia.AplicarPacks()
    local P = Config.Packs
    if type(P) ~= 'table' then return end
    for _, id in ipairs(P.orden) do
        local pack = P.lista[id]
        if id == P.base then
            pack.xp, pack.dinero = 0, nil
        else
            -- la excepción escrita arriba o, si no, lo que salga de lo que trae. El `xp` que
            -- propone cada pack al registrarse ya no cuenta (12/10): estaban puestos con la
            -- escala vieja, de 300 a 1.500, y todos tienen que salir de la misma regla
            pack.xp = tonumber(E.packs[id]) or XpPorDefecto(pack)
            local d = E.packsDinero
            if d and d.activo and not (d.soloMuebles and E.PackEsDeObra(id)) then
                pack.dinero = E.Redondear(pack.xp * d.porXP * GLOBAL)
            else
                pack.dinero = nil
            end
        end
    end
end

--- Un lote: { nombre, packs = { ids… }, suma = XP sin descuento, xp = XP con descuento }
--- o nil si no existe o no junta al menos dos packs. `tiene`: packs que la casa ya
--- tiene ({ [id] = true }); esos no se cobran.
function Config.Economia.Lote(id, tiene)
    local lote, P = E.lotes[id], Config.Packs
    if not lote or type(P) ~= 'table' then return nil end
    local ids, suma = {}, 0
    local function Vale(pid)
        local pack = P.lista[pid]
        if not pack or pid == P.base or (tiene and tiene[pid]) then return end
        ids[#ids + 1] = pid
        suma = suma + (tonumber(pack.xp) or 0)
    end
    if type(lote.packs) == 'table' then
        for _, pid in ipairs(lote.packs) do Vale(pid) end
    else
        for _, pid in ipairs(P.orden) do
            local obra = E.PackEsDeObra(pid)
            if lote.packs == 'todos' or (lote.packs == 'obra' and obra) or (lote.packs == 'muebles' and not obra) then Vale(pid) end
        end
    end
    if #ids < 2 then return nil end
    local xp = math.floor(suma * (1 - (tonumber(lote.descuento) or 0)) / 50 + 0.5) * 50
    return { id = id, nombre = lote.nombre, packs = ids, suma = suma, xp = xp }
end

-- ── Tamaños ──────────────────────────────────────────────────────────────────

--- Lo que cuesta pasar una casa del tamaño `de` al tamaño `a` ('pequena', 'media',
--- 'grande', 'premium'): { dinero, xp } o nil si no es una subida.
function Config.Economia.MejoraTamano(de, a)
    local t1, t2 = E.tamanos[de], E.tamanos[a]
    if not t1 or not t2 or t2.dinero <= t1.dinero then return nil end
    local r = 1 + (tonumber(E.mejoraTamano) or 0)
    return {
        dinero = Dinero((t2.dinero - t1.dinero) * r),
        xp = math.floor((t2.xp - t1.xp) * r / 50 + 0.5) * 50,
    }
end

-- ── Mejoras ──────────────────────────────────────────────────────────────────

local mejorasHechas = false
local function AplicarMejoras()
    local m = E.mejoras
    if mejorasHechas or not m or not m.aplicar then return end
    mejorasHechas = true
    for _, mejora in pairs(Config.Upgrades or {}) do
        if type(mejora) == 'table' and tonumber(mejora.price) then mejora.price = Dinero(mejora.price * (m.mult or 1)) end
    end
    if Config.MloPoints and m.hueco then Config.MloPoints.slotPrice = Dinero(m.hueco) end
end

-- ── Al cargar ────────────────────────────────────────────────────────────────

Config.Economia.AplicarMuebles()
Config.Economia.AplicarPacks()
AplicarMejoras()

-- Por si algún fichero registrara contenido después de este (no debería: este es
-- el último de config/), una segunda pasada cuando ya ha cargado todo el recurso.
-- Solo toca lo que aún no tiene precio puesto por aquí.
if CreateThread then
    CreateThread(function()
        Config.Economia.AplicarMuebles()
        Config.Economia.AplicarPacks()
    end)
end
