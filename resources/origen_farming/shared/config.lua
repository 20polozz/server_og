--[[ ORIGEN · Granja

     Todo lo que se puede ajustar sin tocar código. El servidor decide con
     estos valores: precios, tiempos, rindes, calidades y topes se leen AQUÍ y
     nunca de lo que diga un cliente.

     Los tiempos van en SEGUNDOS REALES. `Config.Velocidad` los divide todos a
     la vez (2 = todo el doble de rápido); para probar se puede pisar con la
     convar `origen_farming_velocidad`. ]]

Config = {}

Config.Depurar = false
Config.Velocidad = 1.0

local MIN = 60
local HORA = 3600

-- ── La cooperativa ────────────────────────────────────────────────────────
--[[ Tres NPC abren el mismo panel, cada uno por su sección. Todo lo que se
     hace en el panel exige estar a `radio` del centro, medido por el servidor.
     La báscula es donde se entregan las cajas (a mano o con el remolque). ]]
Config.Cooperativa = {
    nombre = 'Cooperativa de Grapeseed',
    -- El granero junto a la finca de tierra arada, al este del pueblo.
    centro = vec3(2234.0, 5170.0, 57.5),
    radio = 45.0,
    blip = { sprite = 85, color = 25, escala = 0.8 },

    Peds = {
        Encargado = { modelo = 'a_m_m_farmer_01',    coords = vec4(2238.5, 5168.0, 58.2, 60.0), texto = 'Hablar con el encargado', seccion = 'parcelas', icono = 'seedling' },
        Almacen   = { modelo = 'a_m_m_hillbilly_01', coords = vec4(2236.5, 5161.5, 57.2, 60.0), texto = 'Almacén y pedidos',       seccion = 'almacen',  icono = 'warehouse' },
        Mecanico  = { modelo = 's_m_m_gardener_01',  coords = vec4(2228.0, 5182.0, 59.5, 200.0), texto = 'Alquilar maquinaria',    seccion = 'vehiculos', icono = 'tractor' },
    },

    -- Donde se entregan las cajas. A pie: acércate con la caja en las manos.
    -- Con el remolque: aparca el carro dentro del círculo.
    -- 28/09: la báscula de verdad (plataforma y caseta, Config.Planta) va en el
    -- patio de hormigón del almacén de los silos de la granja Cousins, al sur:
    -- en la cooperativa todo era cuesta y quedaba pegado a la carretera.
    bascula = { coords = vec3(2345.70, 4901.24, 40.95), radio = 7.0 },

    --[[ Donde sale la maquinaria alquilada: huecos sobre el camino de tierra,
         mirando hacia donde se va (el remolque queda detrás, hacia la
         cooperativa). Se usa el primero que esté libre de vehículos y de
         gente; por eso van primero los de más adelante, para que el que sale
         no tenga a nadie delante. Medidos sobre la foto cenital del granero:
           1-2  el camino que baja recto al campo este (rumbo 225)
           3    el camino que sale hacia el oeste (rumbo 143)
         La altura es aproximada: el cliente del conductor asienta el vehículo
         y el remolque en el suelo al recibirlos. ]]
    salidas = {
        vec4(2258.0, 5123.0, 55.0, 225.0),
        vec4(2244.0, 5137.0, 56.0, 225.0),
        vec4(2207.0, 5150.0, 57.0, 143.0),
    },
    devolver = { coords = vec3(2210.0, 5172.0, 56.7), radio = 14.0 },

    -- Grifos para llenar la regadera.
    grifos = {
        vec3(2243.0, 5155.0, 56.0),
        vec3(2262.0, 5147.0, 54.9),
    },
}

-- ── El campo y sus parcelas ───────────────────────────────────────────────
--[[ Los dos campos de tierra arada junto a la cooperativa, enteros, divididos
     en parcelas cuadradas de 4 × 4 celdas. Medidos en el juego: el borde con
     el material del suelo (rayos contra el terreno cada 1,5 m) y las tuberías
     con los aspersores del mapa. Lo genera prueba/campos.lua; no se toca a mano
     sin volver a medir.

       centro, rumbo    el campo; las columnas de celdas avanzan hacia el rumbo
       paso             lado de una celda (m); la parcela mide 4 × paso
       hueco            pasillo entre dos parcelas de la misma franja
       inicio           dónde empieza la retícula a lo largo (m desde el centro):
                        la parcela k de cualquier franja cae en la misma
                        columna, así todo el campo queda en líneas rectas
       franjas          las bandas ENTRE las tuberías: `b` su centro a lo ancho,
                        `filas`, qué columnas de la retícula tienen parcela
                        (las que caben enteras en tierra) y `acopio`, dónde está
                        su palé a lo largo (en la punta que da a la cooperativa)

     Nadie alquila nada: quien está de jornada trabaja una parcela libre y es
     suya mientras tenga algo en la tierra. Lo que está listo lo puede cosechar
     cualquiera que esté de jornada (robar), y al dueño le llega el aviso. ]]
Config.Campos = {
    {
        id = 'este', nombre = 'Campo del Este', letra = 'E',
        centro = vec3(2308.6, 5124.0, 50.0), rumbo = 225.5,
        paso = 2.4, columnas = 4, hueco = 1.2,
        -- Dónde empieza la retícula a lo largo (metros desde el centro).
        inicio = -60.00,
        -- Tuberías del mapa a lo ancho (metros desde el centro), por si hacen falta.
        tuberias = { -18.3, -6.3, 5.7, 16.4 },
        franjas = {
            { b = -22.25, filas = 3, parcelas = { 2, 3, 4, 5, 6, 7, 8 }, acopio = -41.4 },
            { b = -12.30, filas = 4, parcelas = { 2, 3, 4, 5, 6, 7, 8 }, acopio = -41.4 },
            { b = -0.30, filas = 4, parcelas = { 2, 3, 4, 5, 6, 7, 8 }, acopio = -41.4 },
            { b = 11.05, filas = 4, parcelas = { 2, 3, 4, 5, 6, 7, 8 }, acopio = -41.4 },
            { b = 21.05, filas = 3, parcelas = { 2, 3, 4, 5, 6, 7, 8 }, acopio = -41.4 },
        },
    },
    {
        id = 'oeste', nombre = 'Campo del Oeste', letra = 'O',
        centro = vec3(2136.2, 5164.2, 50.0), rumbo = 223.0,
        paso = 2.1, columnas = 4, hueco = 1.2,
        -- Dónde empieza la retícula a lo largo (metros desde el centro).
        inicio = -60.00,
        -- Tuberías del mapa a lo ancho (metros desde el centro), por si hacen falta.
        tuberias = { -26.5, -17.0, -6.4, 3.4, 12.9, 22.4 },
        franjas = {
            { b = -32.35, filas = 4, parcelas = { 3, 4 }, acopio = -10.2 },
            { b = -21.75, filas = 4, parcelas = { 2, 3, 4, 5, 6, 7, 8, 9, 10 }, acopio = 47.4 },
            { b = -11.70, filas = 4, parcelas = { 2, 3, 4, 5, 6, 7, 8, 9, 10 }, acopio = 47.4 },
            { b = -1.50, filas = 4, parcelas = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }, acopio = 47.4 },
            { b = 8.15, filas = 4, parcelas = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }, acopio = 47.4 },
            -- Su punta sureste la ocupa un montón de pacas del mapa (el depósito
            -- salía encima): su acopio va en la otra punta.
            { b = 17.65, filas = 4, parcelas = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }, acopio = -53.4 },
            { b = 26.55, filas = 3, parcelas = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }, acopio = 47.4 },
        },
    },
}

Config.Tierras = {
    -- Lo plantado de una parcela sin tocar: pasado esto sin que su dueño haga
    -- nada, la parcela queda libre (lo que haya lo puede cosechar cualquiera).
    abandono = 3 * HORA,
    -- Con el dueño desconectado se libera antes: la tierra no se queda
    -- guardada para quien no está.
    desconectado = 45 * MIN,
    --[[ El reparto con mucha gente: nadie lleva más de (parcelas del campo ÷
         granjeros de jornada), y nunca menos de `minimo`. Con 95 parcelas,
         hasta 47 granjeros a la vez llevan 2 cada uno; con 20, lo que diga su
         nivel. ]]
    minimo = 1,
    -- Aviso al dueño cuando le cosechan algo ajeno, y cada cuánto como mucho.
    avisoRobo = 60,
}

-- ── El riego ──────────────────────────────────────────────────────────────
--[[ Los aspersores de serie del campo (los del mapa, sobre las tuberías) y los
     que se añaden en las tuberías junto a cada parcela, con el chorro en arco
     de GTA. Se encienden por parcela desde el depósito del acopio o el panel.

     Es una PASADA, no un riego fijo: los aspersores echan agua `duracion`
     segundos (reales, no los acelera `Config.Velocidad`), dejan la tierra
     empapada y se apagan. Desde ahí el agua baja como con la regadera (dura
     `Config.Crecer.aguaDura`, ~35 min con sed normal), así que hay que volver
     a la válvula cuando se seque. Mientras echan agua no se puede volver a
     encender. ]]
Config.Riego = {
    precio = 10, duracion = 120,
    modelo = 'prop_sprink_park_01',
    efecto = { nombre = 'ent_amb_sprinkler_golf', rot = vec3(0.0, 0.0, 0.0), escala = 1.0 },
    -- Un aspersor del mapa cuenta para una parcela si está a menos de esto de
    -- su rectángulo (los de las tuberías de los dos lados).
    margen = 2.5,
    -- Si una parcela no tiene ninguno del mapa, se le ponen en sus tuberías, a
    -- estas fracciones de su largo.
    propios = { 0.25, 0.75 },
}

-- ── Los cultivos ──────────────────────────────────────────────────────────
--[[ tiempo      segundos de crecimiento con agua (sin agua no crece)
     sed         multiplica lo que bebe (1 = normal)
     rinde       unidades por celda con calidad normal
     cosechas    >1: la planta rebrota tras `rebrote` segundos
     precio      precio base por unidad en la cooperativa
     semilla     objeto de la semilla y su precio en la tienda
     item        el objeto que sale (los de los restaurantes cuando existen)
     carga       'caja' o 'saco': cómo se lleva
     volumen     cuánto ocupa cada unidad en la caja
     modelos     prop por fase: brote (0–35 %), crece (35–100 %), lista. GTA no
                 escala props: `hundir` mete la planta en la tierra esa fracción
                 de su altura, y así «crece» al ir saliendo fase a fase
     contenido   lo que se ve dentro de la caja al llevarla (sin él, caja vacía) ]]
Config.Cultivos = {
    lechuga = {
        nombre = 'Lechuga', plural = 'lechugas', item = 'lechuga', nivel = 1, xp = 6,
        semilla = 'semilla_lechuga', precioSemilla = 2,
        tiempo = 18 * MIN, sed = 1.0, rinde = { 3, 5 }, cosechas = 1,
        precio = 11.6, carga = 'caja', volumen = 1,
        modelos = { brote = { 'prop_veg_grass_01_a', hundir = 0.55 }, crece = { 'prop_veg_crop_03_cab', hundir = 0.35 }, lista = { 'prop_veg_crop_03_cab', hundir = 0.0 } },
        contenido = { modelo = 'prop_veg_crop_03_cab' },
        escala = { brote = 0.5, crece = 0.75, lista = 1.0 },
    },
    zanahoria = {
        nombre = 'Zanahoria', plural = 'zanahorias', item = 'zanahoria', nivel = 1, xp = 7,
        semilla = 'semilla_zanahoria', precioSemilla = 3,
        tiempo = 25 * MIN, sed = 0.9, rinde = { 4, 6 }, cosechas = 1,
        precio = 11.6, carga = 'caja', volumen = 1,
        modelos = { brote = { 'prop_veg_grass_01_a', hundir = 0.6 }, crece = { 'prop_veg_grass_01_a', hundir = 0.3 }, lista = { 'prop_veg_crop_04_leaf', hundir = 0.62 } },
        contenido = { modelo = 'ng_proc_food_ornge1a' },
    },
    patata = {
        nombre = 'Patata', plural = 'patatas', item = 'patata', nivel = 2, xp = 9,
        semilla = 'semilla_patata', precioSemilla = 3,
        tiempo = 32 * MIN, sed = 0.8, rinde = { 5, 8 }, cosechas = 1,
        precio = 10.8, carga = 'saco', volumen = 1,
        modelos = { brote = { 'prop_veg_grass_01_a', hundir = 0.5 }, crece = { 'prop_veg_crop_04_leaf', hundir = 0.6 }, lista = { 'prop_veg_crop_04_leaf', hundir = 0.42 } },
    },
    tomate = {
        nombre = 'Tomate', plural = 'tomates', item = 'tomate', nivel = 2, xp = 8,
        semilla = 'semilla_tomate', precioSemilla = 6,
        tiempo = 35 * MIN, sed = 1.2, rinde = { 3, 5 }, cosechas = 3, rebrote = 14 * MIN,
        precio = 10.8, carga = 'caja', volumen = 1,
        modelos = { brote = { 'prop_veg_crop_04_leaf', hundir = 0.75 }, crece = { 'prop_veg_crop_04_leaf', hundir = 0.4 }, lista = { 'prop_veg_crop_04_leaf', hundir = 0.05 } },
        contenido = { modelo = 'ng_proc_food_aple1a' },
    },
    trigo = {
        nombre = 'Trigo', plural = 'trigo', item = 'trigo', nivel = 3, xp = 11,
        semilla = 'semilla_trigo', precioSemilla = 4,
        tiempo = 40 * MIN, sed = 0.6, rinde = { 6, 9 }, cosechas = 1,
        precio = 11.6, carga = 'saco', volumen = 1,
        modelos = { brote = { 'prop_veg_grass_01_a', hundir = 0.5 }, crece = { 'prop_veg_grass_01_b', hundir = 0.45 }, lista = { 'prop_veg_grass_02_a', hundir = 0.0 } },
    },
    fresa = {
        nombre = 'Fresa', plural = 'fresas', item = 'fresa', nivel = 3, xp = 10,
        semilla = 'semilla_fresa', precioSemilla = 8,
        tiempo = 45 * MIN, sed = 1.3, rinde = { 4, 6 }, cosechas = 3, rebrote = 18 * MIN,
        precio = 10.8, carga = 'caja', volumen = 1,
        modelos = { brote = { 'prop_veg_grass_01_a', hundir = 0.6 }, crece = { 'prop_plant_01b', hundir = 0.45 }, lista = { 'prop_plant_01b', hundir = 0.0 } },
        contenido = { modelo = 'ng_proc_food_aple1a' },
    },
    maiz = {
        nombre = 'Maíz', plural = 'mazorcas', item = 'maiz', nivel = 4, xp = 13,
        semilla = 'semilla_maiz', precioSemilla = 5,
        tiempo = 55 * MIN, sed = 1.1, rinde = { 4, 6 }, cosechas = 1,
        precio = 23.2, carga = 'saco', volumen = 1,
        modelos = { brote = { 'prop_veg_grass_01_a', hundir = 0.5 }, crece = { 'prop_plant_01a', hundir = 0.55 }, lista = { 'prop_plant_01a', hundir = 0.0 } },
        escala = { brote = 0.8, crece = 0.6, lista = 1.0 },
    },
    calabaza = {
        nombre = 'Calabaza', plural = 'calabazas', item = 'calabaza', nivel = 5, xp = 20,
        semilla = 'semilla_calabaza', precioSemilla = 8,
        tiempo = 80 * MIN, sed = 1.2, rinde = { 1, 2 }, cosechas = 1,
        precio = 110, carga = 'caja', volumen = 6,
        modelos = { brote = { 'prop_veg_grass_01_a', hundir = 0.6 }, crece = { 'prop_veg_crop_04_leaf', hundir = 0.65 }, lista = { 'prop_veg_crop_03_pump', hundir = 0.08 } },
        contenido = { modelo = 'prop_veg_crop_03_pump' },
        escala = { brote = 0.6, crece = 0.6, lista = 1.0 },
    },
    cafe = {
        nombre = 'Café', plural = 'granos de café', item = 'granos_de_cafe', nivel = 6, xp = 18,
        semilla = 'semilla_cafe', precioSemilla = 14,
        tiempo = 100 * MIN, sed = 1.0, rinde = { 3, 5 }, cosechas = 2, rebrote = 40 * MIN,
        precio = 36.4, carga = 'saco', volumen = 1,
        modelos = { brote = { 'prop_veg_grass_01_a', hundir = 0.6 }, crece = { 'prop_skunk_bush_01', hundir = 0.72 }, lista = { 'prop_skunk_bush_01', hundir = 0.5 } },
    },
}

-- El orden en que salen en las listas.
Config.OrdenCultivos = { 'lechuga', 'zanahoria', 'patata', 'tomate', 'trigo', 'fresa', 'maiz', 'calabaza', 'cafe' }

-- ── El crecimiento ────────────────────────────────────────────────────────
Config.Crecer = {
    -- Una celda llena de agua se queda seca en este tiempo (con sed = 1).
    aguaDura = 35 * MIN,
    -- Sin agua, aguanta esto antes de marchitarse.
    aguante = 30 * MIN,
    -- Lista y sin cosechar, se pudre pasado esto.
    pudre = 3 * HORA,
    -- Con heno o arada y sin sembrar, la tierra vuelve a estar dura pasado esto.
    tierraVuelve = 2 * HORA,
    -- El abono dura esto y acelera el crecimiento.
    abonoDura = 40 * MIN,
    abonoVelocidad = 0.35,
    -- Plagas: cada `plagaCada` segundos, probabilidad por celda creciendo.
    plagaCada = 10 * MIN,
    plagaProb = 0.05,
    plagaProbAbonada = 0.025,
    plagaVelocidad = 0.5,      -- con plaga crece a la mitad
    plagaRinde = 0.7,          -- y rinde un 30 % menos
    -- Lluvia: estos climas riegan todo lo plantado.
    lluvia = { RAIN = true, THUNDER = true, CLEARING = true },
}

-- Estrellas: 1 de base, +2 si nunca le faltó agua (+1 si casi nunca), +1 si
-- estuvo abonada al menos la mitad, +1 si la celda no repite cultivo, −1 con
-- plaga. Precio por estrella. Estrecho a propósito: el 84 % de lo que se
-- vende es de 5★ (medido el 21/09), así que las 5★ son lo NORMAL y no un
-- premio; con 1,45 todo el servidor cobraba casi vez y media.
Config.Calidad = {
    precio = { 0.8, 0.9, 1.0, 1.08, 1.15 },
    humedoPerfecto = 0.97,
    humedoBueno = 0.85,
    abonoMinimo = 0.5,
}

-- ── Herramientas y objetos ────────────────────────────────────────────────
Config.Objetos = {
    azada = 'granja_azada',
    regadera = 'granja_regadera',
    abono = 'granja_abono',
    insecticida = 'granja_insecticida',
}

Config.Regadera = { carga = 8 }

Config.Tienda = {
    { item = 'granja_azada',       precio = 45,  nivel = 1, grupo = 'herramientas', detalle = 'Para arar la tierra a mano.' },
    { item = 'granja_regadera',    precio = 35,  nivel = 1, grupo = 'herramientas', detalle = '8 riegos por carga. Se llena en los grifos.' },
    { item = 'granja_abono',       precio = 6,   nivel = 1, grupo = 'herramientas', detalle = 'Crece un 35 % más rápido y mejora la calidad.' },
    { item = 'granja_insecticida', precio = 14,  nivel = 2, grupo = 'herramientas', detalle = 'Acaba con una plaga.' },
    -- Las semillas se añaden solas desde Config.Cultivos.
}

-- ── La carga: cajas y sacos ───────────────────────────────────────────────
Config.Carga = {
    -- Posiciones medidas en el juego con la animación de cargar (mano derecha).
    caja = { nombre = 'Caja', modelo = 'prop_crate_11d', capacidad = 24,
             hueso = 28422, pos = vec3(0.0, -0.03, -0.35), rot = vec3(5.0, 0.0, 0.0),
             anim = { dict = 'anim@heists@box_carry@', clip = 'idle' } },
    saco = { nombre = 'Saco', modelo = 'prop_feed_sack_01', capacidad = 30,
             hueso = 28422, pos = vec3(0.0, -0.03, -0.3), rot = vec3(95.0, 0.0, 0.0),
             anim = { dict = 'anim@heists@box_carry@', clip = 'idle' } },
    -- La paca de heno para trabajar a mano: se compra en cualquier acopio, se
    -- lleva en brazos y cada una da para `usos` celdas.
    paca = { nombre = 'Paca de heno', modelo = 'prop_haybale_01', usos = 4, precio = 6,
             hueso = 28422, pos = vec3(0.0, -0.03, -0.3), rot = vec3(5.0, 0.0, 90.0),
             anim = { dict = 'anim@heists@box_carry@', clip = 'idle' } },
    -- Cajas que caben apiladas en el palé de un acopio.
    paleMax = 12,
    paleModelo = 'prop_pallet_02a',
    -- Metros a los que se puede dejar/coger del palé, del remolque o de la báscula.
    distancia = 3.0,
}

-- ── Maquinaria ────────────────────────────────────────────────────────────
Config.Vehiculos = {
    tractor = 'tractor2',
    -- Un alquiler abandonado (jugador fuera) se retira pasado esto.
    abandono = 10 * MIN,
    -- Trabajar con el tractor la tierra de OTRO (heno o rastrillo en su
    -- parcela) lo paga la cooperativa por celda: el tractorista de servicio.
    servicio = { heno = 2, rastrillo = 2 },

    --[[ Lo que alquila la cooperativa, en el orden del trabajo:
         heno        tractor + carro de pacas: esparce heno sobre la tierra sin
                     trabajar. `heno` = celdas que da una carga; se recarga en
                     la cooperativa por `recarga`.
         rastrillo   tractor + rastrillo: ara la tierra que ya tiene heno.
         camioneta   pickup: lleva cajas y sacos al punto de venta. ]]
    tipos = {
        heno = {
            nombre = 'Tractor con heno', remolque = 'baletrailer', alquiler = 40, fianza = 300, flota = 3,
            heno = 80, recarga = 40,
            detalle = 'Lo primero: esparce heno sobre tus celdas al pasar por encima.',
            -- Dónde cae el heno, desde el centro del remolque.
            trabajo = { atras = -2.0, ancho = 2.2 },
        },
        rastrillo = {
            nombre = 'Tractor con rastrillo', remolque = 'raketrailer', alquiler = 40, fianza = 300, flota = 3,
            detalle = 'Ara la tierra que ya tiene heno al pasar por encima.',
            trabajo = { atras = -1.2, ancho = 1.8 },
        },
        camioneta = {
            nombre = 'Camioneta de carga', modelo = 'sadler', alquiler = 40, fianza = 300, flota = 6,
            detalle = 'Carga las cajas y los sacos y llévalos al punto de venta.',
            -- La caja de la pickup: 2 de ancho × 2 de largo × 2 pisos. Desde el
            -- origen del vehículo; la altura de cada piso sale del modelo.
            carga = { suelo = 0.12, columnas = { -0.34, 0.34 }, filas = { -2.55, -1.8 }, pisos = 2 },
        },
    },
    orden = { 'heno', 'rastrillo', 'camioneta' },
}

-- ── El mercado ────────────────────────────────────────────────────────────
--[[ Lo que se vende en el servidor satura el precio: cada `saturacion`
     unidades vendidas de un producto POR GRANJERO DE JORNADA lo bajan a la
     mitad del camino hacia el mínimo, y se recupera con una vida media de
     `vidaMedia`. Al ir por granjero, con 5 o con 50 el precio se mueve igual
     para cada uno. En la práctica casi no se nota: medido, el mercado se
     queda en ~0,97. Un producto al día se paga con `demanda` de extra.

     28/09: los cuatro trabajos pagan lo mismo, como mucho 3.000 $ cada
     30 min a nivel máximo (Config.Tope lo corta ahí). Los precios base
     subieron ×1,55: el veterano que no para pasa de ~3.500 a ~5.900 $/h
     netos (≈ 3.000 $/30 min); el de nivel 1, a ~1.500 $/30 min. Las cuentas
     de abajo son las de antes, con los precios viejos.

     LAS CUENTAS. Objetivo pactado (21/09): la granja paga ~2.500 $ NETOS POR
     HORA de media. Se ajustó con lo cobrado de verdad por el banco del 17 al
     21/09 (3.500 ventas, 80 granjeros con más de 2 h): pagaba 4.500 $/h de
     media y 7.000 a los veteranos, porque las cuentas de antes suponían 3★ y
     sin bonus y la realidad es 5★ (×1,45) y bonus máximo (+10 %) casi siempre.
     Recorte aplicado sobre lo bruto, ×0,63:
       calidad 5★ 1,45 → 1,15   ×0,81     bonus de nivel 10 → 5 %   ×0,96
       demanda 1,3 → 1,15       ×0,98     precios base              ×0,83
     Los gastos (abono, semillas, alquileres, riego: ~900 $/h) no bajan, así
     que 5.400 brutos × 0,63 − 900 ≈ 2.500 $/h.

     Cómo queda por granjero (5★, mercado 0,97):
       nivel 1, 2 parcelas = 32 celdas de lechuga, con tractor y abono:
         128 lechugas × 7,5 × 0,97 × 1,15                          ≈ 1.070 $
         heno 40 + rastrillo 40 + camioneta 40 + semillas 64
         + riego 20 + abono 192                              = 396 → ~675 $ la
         vuelta de ~25 min, unos 1.600–1.800 $/h
       granjero medio                                          ~2.500 $/h
       veterano con 3 parcelas que no para                     ~3.500 $/h
     El resto de cultivos da lo mismo por celda y hora; los largos (calabaza,
     maíz, café) piden menos trabajo y por eso son los que más se plantan.
     (El riego son 10 $ por parcela cada pasada de 2 min; el agua dura ~35
     min, así que la lechuga pide una pasada al sembrar: 2 parcelas, 20 $.)
     Si se toca algo de esto, volver a medir con los movimientos `farming-*`
     de origen_banking_transactions y rehacer estas cuentas. ]]
Config.Mercado = {
    saturacion = 1500,
    minimo = 0.6,
    vidaMedia = 90 * MIN,
    demanda = 1.15,
}

-- ── Pedidos del día ───────────────────────────────────────────────────────
Config.Pedidos = {
    cuantos = 4,
    cantidad = { 20, 60 },
    calidadMin = { 1, 4 },
    pago = 1.3,        -- sobre el precio base
    xp = 4,            -- por cada 10 unidades
}

-- ── Niveles ───────────────────────────────────────────────────────────────
Config.Niveles = {
    -- Más parcelas SÍ multiplica lo que se gana (medido el 21/09: el techo lo
    -- pone lo que tarda en crecer, no el trabajo a mano, y con 48 celdas se
    -- saca vez y media que con 32). Un veterano con 3 saca ~3.500 $/h; más de
    -- 3 rompería la economía. El bonus es corto porque a Terrateniente se
    -- llega en tres o cuatro días y el 64 % del dinero lo cobra ese rango.
    { xp = 0,     rango = 'Aprendiz',      parcelas = 2, bonus = 0 },
    { xp = 250,   rango = 'Jornalero',     parcelas = 2, bonus = 1 },
    { xp = 800,   rango = 'Hortelano',     parcelas = 2, bonus = 2 },
    { xp = 2000,  rango = 'Agricultor',    parcelas = 3, bonus = 3 },
    { xp = 4200,  rango = 'Capataz',       parcelas = 3, bonus = 4 },
    { xp = 8000,  rango = 'Terrateniente', parcelas = 3, bonus = 5 },
}

Config.XP = {
    arar = 1,
    entregaPorCaja = 3,
}

-- ── Animaciones y tiempos de cada acción (ms) ────────────────────────────
Config.Acciones = {
    arar = { duracion = 3500, anim = { dict = 'anim@amb@drug_field_workers@rake@male_a@base', clip = 'base' },
             prop = { model = 'prop_tool_rake', bone = 28422, pos = vec3(-0.03, 0.0, -0.0), rot = vec3(0.0, 0.0, 0.0) } },
    sembrar = { duracion = 2500, anim = { dict = 'amb@world_human_gardener_plant@male@base', clip = 'base' } },
    regar = { duracion = 3000, anim = { dict = 'weapon@w_sp_jerrycan', clip = 'fire' },
              prop = { model = 'prop_wateringcan', bone = 28422, pos = vec3(0.4, 0.1, 0.0), rot = vec3(90.0, 180.0, 0.0) } },
    abonar = { duracion = 2500, anim = { dict = 'amb@world_human_gardener_plant@male@base', clip = 'base' } },
    fumigar = { duracion = 3000, anim = { dict = 'amb@world_human_gardener_plant@male@base', clip = 'base' } },
    cosechar = { duracion = 3000, anim = { dict = 'amb@world_human_gardener_plant@male@base', clip = 'base' } },
    limpiar = { duracion = 2500, anim = { dict = 'amb@world_human_gardener_plant@male@base', clip = 'base' } },
    esparcir = { duracion = 3000, anim = { dict = 'amb@world_human_gardener_plant@male@base', clip = 'base' } },
    llenar = { duracion = 2500, anim = { dict = 'amb@world_human_gardener_plant@male@base', clip = 'base' } },
    descargar = { duracion = 5000 },
}

-- Distancia (plano) a la que el servidor deja tocar una celda.
Config.DistanciaCelda = 2.6
-- A esta distancia de una parcela se cargan sus plantas.
Config.DistanciaVer = 90.0

-- ── El equipo de trabajo ──────────────────────────────────────────────────
--[[ Se forma desde el menú de la cooperativa invitando a quien tienes al lado
     (acepta con Y). Dentro del equipo las parcelas son de todos: cualquiera
     del equipo puede arar, sembrar, regar, cosechar y encender el riego, y
     coger las cajas de los palés. Lo que se vende (o un pedido) se reparte a
     partes iguales entre los del equipo que estén de jornada. La cosecha de
     quien no va en tu equipo NO se puede tocar: aquí no se roba. ]]
Config.Equipo = {
    max = 4,                    -- personas, contando al jefe
    distancia = 5.0,            -- metros para poder invitar
    invitacion = 30,            -- segundos para aceptar
    jornada = 'granjaJornada',  -- la state bag de la jornada
    nombre = 'granja',
    bag = 'granjaEquipo',
}

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

-- ── Las máquinas de la cooperativa (28/09) ────────────────────────────────
--[[ Lo que se ve de lo entregado en la báscula (server/procesado.lua,
     client/procesado.lua): la verdura pasa por la línea de lavado y sale en
     cajas al palé; el grano (trigo, maíz, café) sube al silo. Es solo lo que
     se ve: el cobro sigue siendo al vender en el almacén.
     El patio se deja limpio con ymaps (stream/, fuente/patio_ymaps.ps1 y
     patio_ybn.ps1: palés, cajas, volquete y bombonas enterrados 200 m y su
     choque quitado), como el depósito de la basura: sin coste en el juego.
     Colocado en el complejo de silos del juego de la granja Cousins (al sur
     de la cooperativa): patio de hormigón del almacén, llano (0,2 m), con
     palés alrededor, y los silos rojos y blancos al lado. El usuario
     descartó el cruce de la cooperativa (cuesta, pegado a la carretera) y
     el rancho del molino (sueltas, sin integrar).
       maquinas   dónde va cada una (origen en el suelo) y su rumbo
       lavar      segundos de la línea de lavado por entrega
       ensilar    segundos del silo por entrega
       cajas      cajas a la vista en el palé; retira: cada cuánto se lleva
                  una la cooperativa (segundos)
       decorado   rótulo y señales ]]
Config.Planta = {
    centro = vec3(2345.0, 4895.0, 40.9),
    -- Colocadas por el usuario con el editor en el juego (28/09).
    maquinas = {
        lavadora = vec4(2336.41, 4883.04, 40.81, 225.1),
        -- Sobre el hormigón, paralela a la línea (en la tierra la hierba del
        -- terreno atravesaba la plataforma); la caseta hacia la línea.
        bascula = vec4(2345.70, 4901.24, 40.95, 226.9),
        -- Junto a los silos rojos y blancos del juego: el grano va al complejo.
        silo = vec4(2328.82, 4896.08, 40.90, 134.9),
    },
    lavar = 20,
    ensilar = 18,
    cajas = 8,
    retira = 180,
    decorado = {
        { 'origen_gr_rotulo', vec4(2331.03, 4925.11, 40.77, 310.9) },
    },
}
