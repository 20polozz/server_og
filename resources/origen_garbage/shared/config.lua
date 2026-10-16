--[[ ORIGEN · Recogida de Basuras de Davis

     El trabajo, de principio a fin (hecho el 27/09, sobre el basurero del
     origen_newjobs de antes):
       1. El encargado del depósito de Davis: empiezas la jornada, te pones el
          uniforme y sale tu camión de la basura (solo una fianza).
       2. Por la ciudad: vale CUALQUIER cubo, bolsa o contenedor del mapa
          (el usuario, 27/09). Se recoge a pie y la bolsa se echa por la
          trasera del camión.
       3. Lo recogido se vacía para todos: nadie más puede sacar de ahí hasta
          que se vuelve a llenar solo (Config.Recogida.repone).
       4. Con el camión cargado, a la planta de compactación del depósito:
          marcha atrás a una prensa libre, se vacía, prensa sola y se cobra
          por bolsa al caer la bala, al banco, con el extra de tu nivel.
     En equipo (hasta 4) uno conduce y los demás recogen: el camión es de
     todos y lo que se cobra se reparte.

     Todo lo que se puede ajustar sin tocar código. El servidor decide con
     estos valores: precios, tiempos y topes se leen AQUÍ y nunca de lo que
     diga un cliente. ]]

Config = {}

local MIN = 60

-- ── El depósito ───────────────────────────────────────────────────────────
--[[ Peds       el encargado: jornada y camión, todo con él
     salidas    huecos donde sale el camión (el primero libre)
     devolver   dónde se deja el camión al terminar la jornada
     (la descarga es en la planta de compactación: Config.Planta) ]]
Config.Deposito = {
    nombre = 'Recogida de Basuras de Davis',
    centro = vec3(-326.0, -1524.0, 26.6),
    radio = 60.0,

    -- Medido el 27/09 con una foto cenital del depósito con rejilla: el
    -- encargado en el patio, mirando a los camiones.
    Peds = {
        Encargado = { modelo = 's_m_y_garbage', coords = vec4(-357.89, -1545.92, 27.72, 0.33) },   -- puesto por el usuario (29/09)
    },

    -- Al este del patio, de cara a la salida.
    salidas = {
        vec4(-316.0, -1520.0, 26.54, 270.52),
        vec4(-316.0, -1514.0, 26.54, 270.52),
    },
    -- 30/09, puesto por el usuario: donde se entrega el camión (con E, sin bajarse).
    devolver = { coords = vec3(-344.96, -1521.33, 27.73), radio = 5.0 },
}

-- ── La planta de compactación ─────────────────────────────────────────────
--[[ Rehecha el 28/09 (el usuario: «tres prensas, una para cada camión, que
     tiren el prensado hacia abajo, abajo contenedores, y en cuanto se prense
     me paguen»). En la nave del sur del depósito: el muelle (suelo a 26,72)
     cae 2,5 m al patio de abajo (24,22) en y = -1550,08. Todo medido con
     rayos sobre la colisión del juego.

     Cada prensa va en un hueco entre pilares, con la tolva mirando al norte:
     el camión entra marcha atrás hasta el tope de goma, E vacía el camión en
     la tolva, la prensa arranca SOLA, la bala sale por los rodillos, cae por
     la rampa al contenedor de abajo y al salir se cobra (al equipo, repartido).

       prensas     coords: centro de la cámara en el suelo del muelle y su
                   rumbo (0: tolva al norte). contenedor: el suyo, abajo.
       tope        dónde para la trasera del camión (en el marco de la prensa)
       aparcar     lo lejos que puede quedar la trasera del tope, y lo torcido
                   que puede estar el camión (grados)
       prensar     segundos del ciclo (de que arranca a que cae la bala)
       balas       las que caben a la vista en cada contenedor, y cada cuánto se
                   lleva una el depósito
       numero      el cartel con el número, encima del pórtico (en su marco)
       lampara     la campana colgada del tejado (en su marco; z del tejado)
       decorado    lo demás de la planta: modelos propios (origen_pm_*) y del
                   juego. Se crean al acercarse y se quedan quietos. ]]
Config.Planta = {
    nombre = 'Planta de compactación',
    centro = vec3(-349.0, -1546.0, 26.72),
    prensas = {
        -- Numeradas como las ve el camionero al entrar (de izquierda a derecha).
        { coords = vec4(-341.39, -1546.98, 26.72, 0.0), contenedor = vec4(-341.39, -1553.05, 24.23, 0.0) },
        { coords = vec4(-347.00, -1546.98, 26.72, 0.0), contenedor = vec4(-347.00, -1553.05, 24.23, 0.0) },
        { coords = vec4(-352.44, -1546.98, 26.72, 0.0), contenedor = vec4(-352.44, -1553.05, 24.22, 0.0) },
    },
    tope = vec3(0.0, 2.32, 0.0),
    aparcar = { metros = 2.6, grados = 30.0 },
    prensar = 16,
    balas = { max = 8, retira = 4 * MIN },
    numero = vec3(0.0, -0.1, 4.75),
    lampara = { punto = vec2(0.0, -1.0), techo = 34.77 },
    decorado = {
        -- Arriba, en el muelle
        { 'origen_pm_cabina', vec4(-358.17, -1547.9, 26.72, 0.0) },
        { 'origen_pm_rotulo', vec4(-349.78, -1549.76, 31.12, 0.0) },
        { 'origen_pm_senal_caida', vec4(-350.92, -1549.9, 27.07, 180.0) },
        { 'origen_pm_senal_caida', vec4(-342.91, -1549.9, 27.07, 180.0) },
        { 'origen_pm_senal_epi', vec4(-355.1, -1548.6, 28.2, 180.0) },
        { 'origen_pm_senal_prensa', vec4(-349.78, -1548.6, 28.2, 180.0) },
        { 'origen_pm_senal_peatones', vec4(-344.22, -1548.6, 28.2, 180.0) },
        { 'origen_pm_normas', vec4(-360.86, -1541.6, 28.2, 90.0) },
        { 'origen_pm_carga', vec4(-360.86, -1537.6, 28.6, 90.0) },
        { 'prop_bollard_04', vec4(-355.1, -1548.15, 26.72, 0.0) },
        { 'prop_bollard_04', vec4(-349.78, -1548.15, 26.72, 0.0) },
        { 'prop_bollard_04', vec4(-344.22, -1548.15, 26.72, 0.0) },
        { 'prop_fire_exting_1a', vec4(-354.62, -1548.3, 26.72, 180.0) },
        { 'prop_fire_exting_1a', vec4(-349.3, -1548.3, 26.72, 180.0) },
        { 'prop_fire_exting_1a', vec4(-339.2, -1541.5, 26.72, 270.0) },
        { 'prop_pallet_pile_01', vec4(-359.8, -1545.2, 26.72, 90.0) },
        { 'prop_barrel_02a', vec4(-360.35, -1543.4, 26.72, 0.0) },
        { 'prop_barrel_02a', vec4(-360.35, -1542.75, 26.72, 40.0) },
        { 'prop_barrel_02b', vec4(-359.75, -1543.1, 26.72, 0.0) },
        { 'prop_toolchest_05', vec4(-359.55, -1540.3, 26.72, 90.0) },
        { 'prop_rub_cage01a', vec4(-359.2, -1538.2, 26.72, 15.0) },
        { 'prop_elecbox_08', vec4(-339.1, -1538.0, 26.72, 270.0) },
        -- Abajo, en el patio de los contenedores
        { 'origen_pm_contenedor', vec4(-358.3, -1553.05, 24.26, 0.0) },
        { 'origen_pm_zona', vec4(-349.7, -1560.5, 24.23, 0.0) },
        { 'prop_bollard_04', vec4(-355.1, -1550.55, 24.22, 0.0) },
        { 'prop_bollard_04', vec4(-349.78, -1550.55, 24.22, 0.0) },
        { 'prop_bollard_04', vec4(-344.22, -1550.55, 24.22, 0.0) },
        { 'prop_worklight_04b', vec4(-360.3, -1559.0, 24.23, 45.0) },
        { 'prop_mp_cone_02', vec4(-351.8, -1560.3, 24.23, 0.0) },
        { 'prop_mp_cone_02', vec4(-347.6, -1560.3, 24.23, 0.0) },
        { 'prop_rub_binbag_sd_01', vec4(-350.0, -1556.8, 24.23, 30.0) },
        { 'prop_rub_binbag_01', vec4(-344.0, -1557.3, 24.23, 200.0) },
        { 'prop_pallet_02a', vec4(-337.8, -1558.5, 24.23, 10.0) },
    },
}

-- ── Lo que se recoge ──────────────────────────────────────────────────────
--[[ Cualquier objeto del mapa de estos modelos. Cada tipo:
       bolsas    cuántas bolsas saca (un contenedor grande da varias, una
                 por viaje al camión)
       segundos  lo que se tarda en sacar cada bolsa
       esconder  la bolsa suelta del suelo desaparece al cogerla (para todos
                 los que estén cerca) hasta que se repone; los cubos y
                 contenedores se quedan, vacíos ]]
Config.Tipos = {
    bolsa = { nombre = 'Bolsa de basura', bolsas = 1, segundos = 1.8, esconder = true },
    cubo = { nombre = 'Cubo de basura', bolsas = 1, segundos = 2.4 },
    contenedor = { nombre = 'Contenedor', bolsas = 3, segundos = 3.0 },
}

Config.Modelos = {
    -- Bolsas sueltas
    prop_cs_street_binbag_01 = 'bolsa', prop_rub_binbag_01 = 'bolsa', prop_rub_binbag_03 = 'bolsa',
    prop_rub_binbag_03b = 'bolsa', prop_rub_binbag_04 = 'bolsa', prop_rub_binbag_05 = 'bolsa',
    prop_rub_binbag_06 = 'bolsa', prop_rub_binbag_08 = 'bolsa', prop_rub_binbag_sd_01 = 'bolsa',
    prop_rub_binbag_sd_02 = 'bolsa', prop_ld_binbag_01 = 'bolsa', p_binbag_01_s = 'bolsa',
    ng_proc_binbag_01a = 'bolsa', ng_proc_binbag_02a = 'bolsa', hei_prop_heist_binbag = 'bolsa',
    -- Cubos
    prop_bin_01a = 'cubo', prop_bin_02a = 'cubo', prop_bin_03a = 'cubo', prop_bin_04a = 'cubo',
    prop_bin_05a = 'cubo', prop_bin_06a = 'cubo', prop_bin_07a = 'cubo', prop_bin_07b = 'cubo',
    prop_bin_07c = 'cubo', prop_bin_07d = 'cubo', prop_bin_08a = 'cubo', prop_bin_08open = 'cubo',
    prop_bin_09a = 'cubo', prop_bin_10a = 'cubo', prop_bin_10b = 'cubo', prop_bin_11a = 'cubo',
    prop_bin_11b = 'cubo', prop_bin_12a = 'cubo', prop_bin_13a = 'cubo', prop_bin_14a = 'cubo',
    prop_bin_14b = 'cubo', prop_bin_beach_01a = 'cubo', prop_bin_beach_01d = 'cubo',
    prop_recyclebin_01a = 'cubo', prop_recyclebin_02a = 'cubo', prop_recyclebin_02b = 'cubo',
    prop_recyclebin_02_c = 'cubo', prop_recyclebin_02_d = 'cubo', prop_recyclebin_03_a = 'cubo',
    prop_recyclebin_04_a = 'cubo', prop_recyclebin_04_b = 'cubo', prop_recyclebin_05_a = 'cubo',
    zprop_bin_01a_old = 'cubo', prop_cs_bin_01 = 'cubo', prop_cs_bin_02 = 'cubo', prop_cs_bin_03 = 'cubo',
    -- Contenedores grandes
    prop_dumpster_01a = 'contenedor', prop_dumpster_02a = 'contenedor', prop_dumpster_02b = 'contenedor',
    prop_dumpster_3a = 'contenedor', prop_dumpster_4a = 'contenedor', prop_dumpster_4b = 'contenedor',
    prop_cs_dumpster_01a = 'contenedor', p_dumpster_t = 'contenedor',
}

Config.Recogida = {
    -- Lo vaciado vuelve a llenarse solo a los 20 minutos (para todos).
    repone = 20 * MIN,
    -- A cuánto hay que estar del cubo para recogerlo (m).
    distancia = 2.2,
    -- El camión (tuyo o de tu equipo) tiene que estar cerca para recoger:
    -- nada de acumular bolsas en la mano lejos de él.
    camionCerca = 60.0,
}

-- ── La bolsa en la mano ───────────────────────────────────────────────────
--[[ Lo del basurero de antes: la bolsa en la mano derecha y el andar de
     llevarla; con ella no se corre, no se salta ni se pega. ]]
Config.Bolsa = {
    modelo = 'prop_cs_street_binbag_01',
    -- El ajuste del basurero de antes (el usuario: «antes estaba bien»).
    mano = { hueso = 28422, pos = vec3(0.0, 0.04, -0.02), rot = vec3(0.0, 0.0, 0.0) },
    llevar = { dict = 'missfbi4prepp1', clip = '_idle_garbage_man', flag = 49 },
    coger = { dict = 'anim@heists@narcotics@trash', clip = 'pickup', flag = 48 },
    cubo = { dict = 'mini@repair', clip = 'fixing_a_ped', flag = 1 },
    tirar = { dict = 'anim@heists@narcotics@trash', clip = 'throw_b', flag = 48, ms = 1200 },
}

-- ── Los camiones ──────────────────────────────────────────────────────────
Config.Vehiculos = {
    abandono = 10 * MIN,
    tipos = {
        camion = {
            nombre = 'Camión de la basura', nivel = 1, modelo = 'trash',
            -- Sin alquiler: solo una fianza que se devuelve al terminar la
            -- jornada con el camión de vuelta (la mitad si viene destrozado).
            fianza = 250, flota = 10, capacidad = 25,
            -- Dónde se echa la bolsa, desde el centro del camión.
            trasera = vec3(0.0, -6.3, 0.0),     -- el camión acaba a -5,64 (medido)
            cuadro = { largo = 10.5, ancho = 3.4 },
            detalle = 'El de siempre: siempre hay alguno libre.',
        },
        grande = {
            nombre = 'Compactador grande', nivel = 3, modelo = 'trash2',
            fianza = 400, flota = 5, capacidad = 40,
            trasera = vec3(0.0, -6.3, 0.0),     -- el camión acaba a -5,64 (medido)
            cuadro = { largo = 10.5, ancho = 3.4 },
            detalle = 'Lleva muchas más bolsas por viaje, pero hay pocos.',
        },
    },
    orden = { 'grande', 'camion' },
}

-- ── La descarga ───────────────────────────────────────────────────────────
--[[ Se cobra al caer la bala de la prensa: por bolsa (`pago`) más el extra de tu nivel, y un
     `lleno` más si el camión llega lleno. Se paga al banco y, en equipo, se
     reparte a partes iguales entre los que estén de jornada.

     LAS CUENTAS. Desde el 28/09 los cuatro trabajos pagan lo mismo: como
     mucho 3.000 $ cada 30 min a nivel máximo (Config.Tope lo corta ahí).
     TEÓRICAS, hay que medirlas jugando:
       una bolsa: buscar el cubo, sacarla (~2 s), llevarla al camión y
         echarla: ~15 s de media en calles con cubos
       un viaje a la planta y vaciado: ~3 min
       nivel 1  camión (25): ~25 × 15 + 180 ≈ 9,3 min por viaje
                → ~80 bolsas/30 min × 23 $ ≈ 1.850 $/30 min
       nivel 5  compactador (40) + 30 %: ~40 × 15 + 180 = 13 min
                → ~92 bolsas/30 min × 23 $ × 1,30 × 1,10 ≈ 3.000 $/30 min
       En equipo se recoge más deprisa, pero se reparte. ]]
Config.Descarga = {
    pago = 23,          -- por bolsa, antes del extra de nivel
    lleno = 0.10,       -- extra sobre el total si el camión llega lleno
    duracion = 7,       -- segundos de la descarga en la tolva
}

-- ── El equipo de trabajo ──────────────────────────────────────────────────
--[[ Se forma desde el menú del encargado invitando a quien tienes al lado
     (acepta con Y). Dentro del equipo es todo de todos: el camión y lo que
     se cobra en la tolva, a partes iguales entre los que estén de jornada. ]]
Config.Equipo = {
    max = 4,
    distancia = 5.0,
    invitacion = 30,
    jornada = 'basuraJornada',
    nombre = 'basuras',
    bag = 'basuraEquipo',
}

-- ── Niveles ───────────────────────────────────────────────────────────────
--[[ `extra`: lo que se cobra de más por bolsa en ese nivel. La experiencia:
     una por bolsa echada al camión y otra por bolsa descargada en la tolva.
     Con ~300 xp por hora, el compactador llega hacia las 1,5 h y el último
     rango hacia las 6 h. ]]
Config.Niveles = {
    { xp = 0,    rango = 'Peón', extra = 0.00 },
    { xp = 150,  rango = 'Recogedor', extra = 0.05 },
    { xp = 450,  rango = 'Conductor', extra = 0.10 },
    { xp = 1000, rango = 'Veterano', extra = 0.20 },
    { xp = 1800, rango = 'Jefe de ruta', extra = 0.30 },
}

Config.XP = { echar = 1, descargar = 1 }

-- ── El uniforme (el del basurero de antes) ────────────────────────────────
--[[ El uniforme (30/09, números del usuario). Componentes: 1 máscara, 3 brazos,
     4 pantalón, 6 zapatos, 8 camiseta, 11 chaqueta. Las claves con «p» son
     accesorios (p0 = sombrero). { dibujo, color/talla } ]]
Config.Uniforme = {
    male = {
        ['1'] = { 122, 6 }, ['3'] = { 264, 0 }, ['4'] = { 680, 5 }, ['6'] = { 349, 0 }, ['8'] = { 138, 0 },
        ['11'] = { 1595, 0 },
    },
    female = {
        ['3'] = { 222, 0 }, ['4'] = { 248, 1 }, ['6'] = { 266, 0 }, ['8'] = { 14, 0 }, ['11'] = { 0, 0 },
        ['p0'] = { 191, 0 },
    },
}

-- Quienes no pueden hacer este trabajo mientras están de servicio.
Config.Prohibidos = { police = true, sheriff = true, ambulance = true, sapd = true }

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
