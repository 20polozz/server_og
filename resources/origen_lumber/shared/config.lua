--[[ ORIGEN · Aserradero de Paleto

     El trabajo, de principio a fin (simplificado el 19/09):
       1. El encargado del aserradero: empiezas la jornada y te da el hacha y
          el camión maderero, en el mismo sitio.
       2. En el monte: muesca, corte de caída, desramar y trocear.
       3. Cargar los troncos uno a uno con el cabrestante del camión.
       4. Traer el camión a la bahía del patio y entregar la carga: se cobra
          por tronco, según la especie, y más si el camión viene lleno.
     Se empieza con camioneta, hacha y abeto; subiendo de nivel se abren el
     cedro, el camión, el pino y, al final, la motosierra (ver Config.Niveles).

     Todo lo que se puede ajustar sin tocar código. El servidor decide con
     estos valores: precios, tiempos y topes se leen AQUÍ y nunca de lo que
     diga un cliente.

     Los tiempos van en SEGUNDOS REALES. `Config.Velocidad` divide los de
     rebrote de los árboles (no los de las acciones); para probar se puede pisar
     con la convar `origen_lumber_velocidad`. ]]

Config = {}

Config.Velocidad = 1.0

local MIN = 60

-- ── El aserradero ─────────────────────────────────────────────────────────
--[[ Peds       el encargado: jornada, hacha y camión, todo con él
     salidas    huecos donde sale el camión (el primero libre)
     devolver   dónde se deja el camión al terminar la jornada
     descarga   la bahía del patio donde se entrega la carga
     rampa      hacia dónde ruedan los troncos al entregarlos ]]
Config.Aserradero = {
    nombre = 'Aserradero de Paleto',
    centro = vec3(-585.0, 5275.0, 69.3),
    radio = 70.0,

    Peds = {
        Encargado = { modelo = 's_m_y_construct_01', coords = vec4(-572.6, 5249.5, 69.5, 95.0), texto = 'Hablar con el encargado', seccion = 'jornada' },
    },

    -- Mirando al sur: por delante queda la esquina del patio por donde sale el
    -- camino (medido en la foto cenital del patio sur).
    salidas = {
        vec4(-575.5, 5252.0, 69.5, 180.0),
        vec4(-582.5, 5255.0, 69.5, 180.0),
        vec4(-569.0, 5256.0, 69.5, 180.0),
    },
    devolver = { coords = vec3(-582.0, 5245.0, 69.5), radio = 16.0 },

    descarga = { coords = vec4(-600.9, 5306.0, 69.3, 27.0), radio = 7.0 },
    rampa = vec3(-595.7, 5296.0, 69.2),
}

-- ── Las especies ──────────────────────────────────────────────────────────
--[[ nivel         desde qué nivel se puede talar
     modelo        el árbol en pie (el mismo prop cae y queda en el suelo)
     altura        metros: largo de la zona de caída
     troncos       cuántos troncos de 4 m salen al trocearlo
     tiempos       segundos de cada paso con el hacha
     pago          lo que paga el aserradero por cada tronco entregado: la
                   especie de más nivel paga más
     xp            experiencia por árbol tumbado ]]
Config.Especies = {
    abeto = {
        nombre = 'Abeto', nivel = 1, modelo = 'prop_tree_cedar_s_01', altura = 10.5,
        troncos = 2, tiempos = { muesca = 5, tumbar = 7, rama = 3, corte = 4 },
        pago = 54, xp = 2,
    },
    cedro = {
        nombre = 'Cedro', nivel = 2, modelo = 'prop_tree_pine_01', altura = 27.0,
        troncos = 4, tiempos = { muesca = 7, tumbar = 10, rama = 3, corte = 4 },
        pago = 61, xp = 3,
    },
    pino = {
        nombre = 'Pino', nivel = 4, modelo = 'prop_tree_pine_02', altura = 30.0,
        troncos = 5, tiempos = { muesca = 8, tumbar = 12, rama = 3, corte = 4 },
        pago = 68, xp = 4,
    },
}
Config.OrdenEspecies = { 'abeto', 'cedro', 'pino' }

-- ── Los cuarteles de corta ────────────────────────────────────────────────
--[[ Posiciones medidas en el juego: suelo llano (pendiente < 17°), libre de
     árboles y rocas del mapa y a más de 7,5 m de caminos (rayos contra el
     terreno cada 6 m, agrupados con 8,4 m entre árboles). ]]
Config.Cuarteles = {
    {
        id = 'A', nombre = 'Prado del Lazo', especie = 'abeto',
        centro = vec3(-709.2, 5357.2, 62.1), radio = 66,
        arboles = {
            vec3(-736.0, 5404.0, 48.11),
            vec3(-724.0, 5404.0, 49.92),
            vec3(-712.0, 5398.0, 52.51),
            vec3(-724.0, 5392.0, 53.41),
            vec3(-706.0, 5392.0, 54.04),
            vec3(-712.0, 5386.0, 56.04),
            vec3(-700.0, 5386.0, 55.55),
            vec3(-718.0, 5380.0, 57.26),
            vec3(-706.0, 5380.0, 58.34),
            vec3(-724.0, 5374.0, 58.17),
            vec3(-712.0, 5374.0, 59.39),
            vec3(-694.0, 5374.0, 59.18),
            vec3(-730.0, 5368.0, 58.77),
            vec3(-718.0, 5368.0, 60.12),
            vec3(-700.0, 5368.0, 61.31),
            vec3(-748.0, 5362.0, 58.16),
            vec3(-736.0, 5362.0, 59.66),
            vec3(-724.0, 5362.0, 60.46),
            vec3(-706.0, 5362.0, 63.32),
            vec3(-754.0, 5356.0, 57.44),
            vec3(-742.0, 5356.0, 60.13),
            vec3(-700.0, 5356.0, 64.75),
            vec3(-688.0, 5356.0, 65.73),
            vec3(-748.0, 5350.0, 59.74),
            vec3(-730.0, 5350.0, 62.16),
            vec3(-706.0, 5350.0, 66.26),
            vec3(-694.0, 5350.0, 66.81),
            vec3(-682.0, 5350.0, 65.89),
            vec3(-736.0, 5344.0, 62.19),
            vec3(-712.0, 5344.0, 67.14),
            vec3(-700.0, 5344.0, 67.16),
            vec3(-688.0, 5344.0, 67.15),
            vec3(-676.0, 5344.0, 65.00),
            vec3(-706.0, 5338.0, 68.42),
            vec3(-694.0, 5338.0, 68.05),
            vec3(-682.0, 5338.0, 66.82),
            vec3(-670.0, 5338.0, 63.58),
            vec3(-712.0, 5332.0, 69.51),
            vec3(-700.0, 5332.0, 68.97),
            vec3(-688.0, 5332.0, 67.96),
            vec3(-676.0, 5332.0, 65.56),
            vec3(-718.0, 5326.0, 70.41),
            vec3(-706.0, 5326.0, 69.38),
            vec3(-694.0, 5326.0, 68.70),
            vec3(-682.0, 5326.0, 67.12),
        },
    },
    {
        id = 'B', nombre = 'Loma Norte', especie = 'cedro',
        centro = vec3(-622.2, 5420.4, 51.3), radio = 54,
        arboles = {
            vec3(-652.0, 5440.0, 50.02),
            vec3(-616.0, 5440.0, 53.16),
            vec3(-604.0, 5440.0, 54.84),
            vec3(-592.0, 5440.0, 57.07),
            vec3(-658.0, 5434.0, 48.56),
            vec3(-646.0, 5434.0, 50.11),
            vec3(-634.0, 5434.0, 50.61),
            vec3(-622.0, 5434.0, 51.72),
            vec3(-610.0, 5434.0, 53.16),
            vec3(-598.0, 5434.0, 54.91),
            vec3(-640.0, 5428.0, 49.24),
            vec3(-628.0, 5428.0, 50.31),
            vec3(-604.0, 5428.0, 52.82),
            vec3(-592.0, 5428.0, 55.09),
            vec3(-598.0, 5422.0, 53.19),
            vec3(-640.0, 5416.0, 46.65),
            vec3(-628.0, 5416.0, 47.07),
            vec3(-616.0, 5416.0, 47.97),
            vec3(-604.0, 5416.0, 50.40),
            vec3(-592.0, 5416.0, 53.52),
            vec3(-622.0, 5410.0, 48.45),
            vec3(-640.0, 5404.0, 50.16),
            vec3(-628.0, 5404.0, 49.04),
            vec3(-634.0, 5398.0, 50.72),
            vec3(-640.0, 5392.0, 50.98),
            vec3(-628.0, 5386.0, 53.89),
            vec3(-634.0, 5380.0, 52.37),
        },
    },
    {
        id = 'C', nombre = 'Hondonada del Puente', especie = 'pino',
        centro = vec3(-658.5, 5270.4, 73.6), radio = 32,
        arboles = {
            vec3(-658.0, 5290.0, 69.81),
            vec3(-652.0, 5284.0, 70.27),
            vec3(-670.0, 5278.0, 73.54),
            vec3(-676.0, 5272.0, 74.62),
            vec3(-658.0, 5272.0, 74.00),
            vec3(-664.0, 5266.0, 75.22),
            vec3(-652.0, 5266.0, 74.32),
            vec3(-640.0, 5266.0, 72.41),
            vec3(-670.0, 5260.0, 75.56),
            vec3(-658.0, 5260.0, 75.22),
            vec3(-646.0, 5260.0, 74.22),
        },
    },
}

-- ── El árbol, de principio a fin ──────────────────────────────────────────
Config.Arbol = {
    -- Tocón → árbol de nuevo.
    rebrote = 90 * MIN,
    -- Ya no se replanta, pero los plantones que quedaron de antes siguen
    -- creciendo con esto hasta volver a ser árbol.
    crecePlanton = 25 * MIN,
    plantonModelo = 'prop_tree_cedar_s_02',
    tocon = 'prop_tree_stump_01',
    ramas = 'prop_log_aa',
    -- Quien empieza a talar un árbol lo tiene reservado mientras lo trabaje.
    reserva = 10 * MIN,
    -- Dónde hay que ponerse para cortar (m del tronco, en el plano).
    distancia = 2.8,
    -- La caída: duración de la animación, ancho de la zona que golpea y daño.
    caida = { ms = 3400, ancho = 3.2, dano = 45 },
    -- Direcciones de la muesca, de 45 en 45 grados.
    paso = 45,
}

-- ── Los troncos ───────────────────────────────────────────────────────────
Config.Tronco = {
    modelo = 'prop_log_01', largo = 4.1,
    -- No se dejan troncos por el monte: un tronco en el suelo, o un árbol
    -- tumbado sin trocear, desaparece si su dueño pasa más de `abandono` lejos
    -- (a más de `cerca` metros, o desconectado). Mientras anda cerca no cuenta.
    abandono = 5 * MIN,
    cerca = 60.0,
    -- Distancia a la que se engancha a mano (m).
    distancia = 3.0,
}

-- ── Herramientas ──────────────────────────────────────────────────────────
--[[ El 19/09 se retiraron de la base todas las weapon_hatchet: eran hachas del
     aserradero que la gente se había quedado para pegar (el hacha era un arma
     de GTA). Mientras esto esté en true, el barrido de herramientas también
     se la quita a cualquiera que la lleve encima, por si alguien estaba
     conectado ese día y la volvía a guardar. Si algún día se vende un hacha
     de verdad en una tienda, poner a false. ]]
Config.QuitarHachasViejas = true

--[[ Lo que se daba antes y ya no es de este trabajo: el barrido se lo quita
     a quien lo tenga. ]]
Config.ObjetosRetirados = {}

Config.Herramientas = {
    hacha = {
        nombre = 'Hacha', nivel = 1, factor = 1.0,
        -- Se entrega como objeto del inventario y se ata a la mano. NO es un
        -- arma de GTA (antes era weapon_hatchet y la gente se la quedaba para
        -- pegar): no hace daño, no se puede tirar ni dar, y se retira a quien
        -- no esté de jornada.
        item = 'hacha_lenador',
        prop = { modelo = 'prop_ld_fireaxe', hueso = 57005, pos = vec3(0.1, 0.0, 0.0), rot = vec3(-65.0, -40.0, -115.0) },
        anim = { dict = 'melee@large_wpn@streamed_core', clip = 'car_down_attack', flag = 1 },
        -- Desramar: golpe corto hacia el suelo.
        animRama = { dict = 'melee@large_wpn@streamed_core', clip = 'ground_attack_on_spot', flag = 1 },
    },
    -- La del profesional: todo en algo más de la mitad de tiempo. Igual que
    -- el hacha, es un objeto del trabajo que no sale de él.
    motosierra = {
        nombre = 'Motosierra', nivel = 5, factor = 0.6,
        item = 'motosierra',
        prop = { modelo = 'prop_tool_consaw', hueso = 57005, pos = vec3(0.12, 0.02, -0.02), rot = vec3(-70.0, 0.0, 180.0) },
        anim = { dict = 'anim@heists@fleeca_bank@drilling', clip = 'drill_straight_idle', flag = 1 },
    },
}
Config.OrdenHerramientas = { 'hacha', 'motosierra' }

-- ── Maquinaria ────────────────────────────────────────────────────────────
Config.Vehiculos = {
    abandono = 10 * MIN,
    tipos = {
        camion = {
            nombre = 'Camión maderero', nivel = 3, modelo = 'phantom', remolque = 'trflat',
            -- Sin alquiler: solo una fianza que se devuelve al terminar la
            -- jornada con el camión de vuelta (la mitad si viene destrozado).
            fianza = 300, flota = 6,
            -- La carga (desde el centro del remolque): dos hileras de tres
            -- troncos pegados y, encima, dos
            -- encajados en los huecos (como se apila de verdad). 10 en total.
            carga = { columnas = { -0.6, 0.0, 0.6 }, filas = { -3.2, 1.4 }, pisos = 2, suelo = 0.43, diametro = 0.58 },
            -- El cabrestante: la palanca está en el lado derecho del remolque,
            -- hacia delante, y el cable sale del chasis (`ancla`, medido desde
            -- el centro del remolque): antes salía flotando sobre la plataforma.
            cabrestante = { lado = 1.7, adelante = 3.5, alcance = 30.0, ancla = vec3(1.32, 3.9, 0.22) },
            -- Las cinchas: medio ancho del remolque y a cuánto de cada fila van.
            cinchas = { ancho = 1.36, separacion = 1.2 },
            -- El cuadro de la bahía: largo y ancho del sitio donde se aparca.
            cuadro = { largo = 14.0, ancho = 3.6 },
            detalle = 'Carga muchos troncos, pero hay pocos: el viaje rinde más.',
        },
        --[[ La camioneta (19/09): para que no salgan decenas de camiones. Una
             pickup con el portón de atrás abierto y los troncos asomando por
             detrás. Lleva menos, pero hay muchas más. Se carga igual, con un
             cabrestante pequeño en la trasera.
             OJO: medidas puestas a ojo sobre el modelo, sin ver en el juego. ]]
        camioneta = {
            nombre = 'Camioneta', nivel = 1, modelo = 'sadler',
            fianza = 150, flota = 12,
            -- Dos troncos pegados en la caja y uno encima, a lo largo: con
            -- 4 m de tronco, asoman por el portón abierto.
            carga = { columnas = { -0.3, 0.3 }, filas = { -1.7 }, pisos = 2, suelo = 0.57, diametro = 0.58 },
            cabrestante = { lado = 1.25, adelante = -2.4, alcance = 20.0, ancla = vec3(0.0, -2.75, 0.35) },
            cinchas = { ancho = 0.95, separacion = 0.7 },
            cuadro = { largo = 7.0, ancho = 2.8 },
            porton = true,
            detalle = 'Lleva pocos troncos, pero siempre hay alguna libre.',
        },
    },
    orden = { 'camion', 'camioneta' },
}

-- ── La entrega ────────────────────────────────────────────────────────────
--[[ Se cobra por tronco entregado (`pago` de cada especie) y, si el camión
     viene lleno, un extra sobre el total. Se paga al banco.

     LAS CUENTAS. Desde el 28/09 los cuatro trabajos pagan lo mismo: como
     mucho 3.000 $ cada 30 min a nivel máximo (Config.Tope lo corta ahí);
     los precios subieron ×2,44 para llegar. Con los tiempos medidos:
       talar: ~19 s por tronco de abeto, ~15 de cedro, ~14 de pino (con la
              motosierra, ~9)
       cargar con el cabrestante: ~25 s por tronco
       ida y vuelta al patio, cinchas y entrega: ~100 s por viaje
       nivel 1  camioneta (3) + hacha + abeto: ~4 min por viaje
                → ~23 troncos × 54 $ × 1,10 ≈ 1.370 $/30 min
       nivel 3  camión (10) + hacha + cedro: ~8,3 min por viaje
                → ~36 troncos × 61 $ × 1,10 ≈ 2.420 $/30 min
       nivel 5  camión + motosierra + pino: ~7,4 min por viaje
                → ~40 troncos × 68 $ × 1,10 ≈ 3.000 $/30 min
       Un viaje a medias paga por tronco, pero sin el extra de lleno. ]]
Config.Entrega = {
    lleno = 0.10,     -- extra sobre el total si el camión viene lleno
    duracion = 8,     -- segundos de la entrega (los troncos ruedan al patio)
}

-- ── El equipo de trabajo ──────────────────────────────────────────────────
--[[ Se forma desde el menú del encargado invitando a quien tienes al lado
     (acepta con Y). Dentro del equipo es todo de todos: los árboles, los
     troncos y los vehículos; y lo que se cobra en la bahía se reparte a
     partes iguales entre los del equipo que estén de jornada. ]]
Config.Equipo = {
    max = 4,                    -- personas, contando al jefe
    distancia = 5.0,            -- metros para poder invitar
    invitacion = 30,            -- segundos para aceptar
    jornada = 'lumberJornada',  -- la state bag de la jornada
    nombre = 'aserradero',
    bag = 'lumberEquipo',
}

-- ── Animaciones de a pie ──────────────────────────────────────────────────
-- ── Niveles ───────────────────────────────────────────────────────────────
--[[ Lo que abre cada nivel sale de los `nivel` de especies, herramientas y
     vehículos. La experiencia: por árbol tumbado (la `xp` de la especie), por
     tronco cargado y por tronco entregado. Con ~45 xp cada media hora al
     empezar, el camión llega en unas 2 h y la motosierra hacia las 12 h. ]]
Config.Niveles = {
    { xp = 0,    rango = 'Peón' },
    { xp = 120,  rango = 'Leñador' },
    { xp = 350,  rango = 'Camionero' },
    { xp = 800,  rango = 'Talador' },
    { xp = 1600, rango = 'Profesional' },
}

Config.XP = { cargar = 1, entregar = 1 }

Config.Anims = {
    enganchar = { dict = 'amb@world_human_gardener_plant@male@base', clip = 'base', flag = 1 },
    palanca = { dict = 'amb@prop_human_parking_meter@male@base', clip = 'base', flag = 1 },
}

Config.DistanciaVer = 180.0

--[[ Cuántos props pone cada jugador como mucho (rendimiento): árboles pintados
     a la vez (los más cercanos), a qué distancia tienen colisión, y hasta dónde
     se pintan los troncos sueltos. ]]
Config.Limites = { arboles = 60, colision = 40.0, troncos = 150.0 }

--[[ ── La colocación del patio ────────────────────────────────────────────────
     Hecha a mano con /aserraderoeditor el 18/09 y escrita aquí para que el
     patio salga IGUAL en cualquier servidor, llegue o no el fichero
     shared/puntos.json. Si más adelante se vuelve a guardar con el editor, lo
     del fichero manda sobre esto (se aplica después, en shared/puntos.lua). ]]
do
    local A = Config.Aserradero
    -- 29/09 (el usuario): la línea en U ocupa el patio y el camino de arriba
    -- queda para descargar. El camión entra marcha atrás al camino y deja el
    -- remolque pegado al parque de troncos: ruedan del remolque al parque.
    A.descarga.coords = vec4(-575.00, 5269.00, 69.40, 70.0)
    A.rampa = vec3(-575.59, 5262.94, 69.50)
    -- Los camiones salen de la bahía vieja (zona norte), hacia el puente.
    A.salidas[1] = vec4(-604.00, 5300.00, 69.25, 180.0)
    A.salidas[2] = vec4(-600.50, 5300.00, 69.25, 180.0)
    A.salidas[3] = vec4(-607.50, 5300.00, 69.25, 180.0)
    A.devolver.coords = vec3(-600.00, 5298.00, 69.25)
    A.Peds.Encargado.coords = vec4(-594.50, 5306.50, 69.21, 90.0)
end

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

-- ── La línea de sierra (28/09; en U el 29/09) ─────────────────────────────
--[[ Lo entregado pasa por la línea y se cobra al final (server/linea.lua,
     client/linea.lua): los troncos ruedan del remolque al parque, la grúa los
     lleva a la descortezadora, la sierra los corta en tablas, la apiladora
     hace el paquete y la cinta lo lleva al secadero. Al entrar el paquete en
     el secadero se paga la carga (el tope de server/tope.lua, en ese momento).
     La U (medida con rayos en el juego y en foto cenital, 29/09): baja junto a
     la valla del terraplén, cruza abajo y sube por el lado este al secadero.
       maquinas    dónde va cada una (origen en el suelo) y su rumbo
       tronco      segundos entre tronco y tronco por la línea
       porLote     troncos que se ven pasar por cada carga entregada (como
                   mucho; con cola, uno)
       esperaMax   segundos que una carga puede esperar su turno: pasados, se
                   cobra igual (el dinero no se queda colgado de la cola)
       cinta       segundos de la apiladora al secadero
       decorado    señales y trastos ]]
Config.Linea = {
    centro = vec3(-574.9, 5249.0, 69.5),
    maquinas = {
        grua = vec4(-572.06, 5261.06, 69.59, 152.0),
        parque = vec4(-576.12, 5263.22, 69.47, 332.0),
        descortezadora = vec4(-572.69, 5257.32, 69.49, 152.0),
        sierra = vec4(-577.29, 5248.67, 69.47, 152.0),
        apiladora = vec4(-581.92, 5240.14, 69.47, 332.0),
        cinta = vec4(-575.66, 5236.82, 69.49, 332.0),
        secadero = vec4(-567.64, 5251.92, 69.49, 332.0),
    },
    tronco = 12,
    porLote = 2,
    esperaMax = 180,
    cinta = 14,
    decorado = {
        { 'origen_as_rotulo', vec4(-603.5, 5289.0, 69.4, 315.0) },
        { 'origen_as_senal_suspendidas', vec4(-567.32, 5261.03, 69.52, 152.0) },
        { 'origen_as_senal_sierra', vec4(-569.80, 5244.01, 69.47, 62.0) },
        { 'prop_fire_exting_1a', vec4(-568.39, 5246.66, 69.47, 62.0) },
        { 'prop_toolchest_05', vec4(-571.59, 5240.43, 69.47, 62.0) },
        { 'prop_barrel_02a', vec4(-572.99, 5236.30, 69.49, 0.0) },
        { 'prop_barrel_02a', vec4(-572.80, 5235.18, 69.51, 30.0) },
    },
}
