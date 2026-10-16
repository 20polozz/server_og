--[[ ═══════════════════════════════════════════════════════════════════════
     ESCUELA DE VUELO DE SANDY SHORES · la licencia de piloto

     Se habla con el instructor del aeródromo de Sandy y se va subiendo de
     nivel. Cada nivel es un examen teórico (en la pantalla) y uno o dos
     prácticos (en el aire, con un examinador sentado al lado que va dando
     órdenes: rodar, despegar, aros marcados en el cielo, mantener rumbo,
     pasada baja, tomas y aterrizaje).

         BÁSICA  avionetas ligeras          teórico + práctico en avioneta
         MEDIA   + aviones medios y helis   teórico + práctico en avión
                                            + práctico en helicóptero
         ALTA    cualquier aeronave         teórico + práctico en reactor

     La licencia es un OBJETO del inventario (`licencia_piloto`). Se usa
     para enseñarla a quien tengas delante (la policía, un compañero) y dice
     si es válida. Si se pierde, el mismo instructor hace un duplicado
     pagando, y la de antes queda ANULADA: quien la encuentre no puede
     hacerla pasar por suya.

     Todo cobro, nota y aprobado lo decide el servidor. El cliente solo
     vuela y avisa; cada paso del práctico se comprueba con la posición que
     tiene el servidor del avión.
   ═══════════════════════════════════════════════════════════════════════ ]]

Config = {}

Config.Nombre = 'Escuela de Vuelo de Sandy Shores'
Config.Corto = 'Escuela de vuelo'

--- El objeto de la licencia (definido en origen_inventory/config/items.lua).
Config.Item = 'licencia_piloto'

-- ── El aeródromo ──────────────────────────────────────────────────────────
--[[ La pista se midió el 19/09 en el juego, con rayos contra el asfalto
     (prueba/estado.lua): el asfalto va de la cabecera este (d = 0) a ~670 m,
     unos 32 m de ancho, a 39,5 m de altura. Hay una calle paralela al sur
     (a ~55 m) y la plataforma del avión cae justo en la cabecera este.
     TODAS las rutas de los exámenes se calculan desde estos dos puntos
     (shared/examenes.lua): si se corrigen aquí, se corrige cada circuito. ]]

Config.Pista = {
    -- Cabecera ESTE, la de los hangares. Desde aquí se despega hacia el oeste.
    este = vec3(1717.2, 3256.6, 39.5),
    -- Cabecera OESTE.
    oeste = vec3(1051.8, 3069.9, 39.5),
    -- Ancho útil a cada lado del eje (la pista mide ~30 m; se deja margen).
    semiancho = 18.0,
}

Config.Escuela = {
    -- El instructor: examina, cobra, hace duplicados.
    npc = {
        modelo = 's_m_m_pilot_01',
        coords = vec4(1759.44, 3298.89, 41.96, 149.27),
        escenario = 'WORLD_HUMAN_CLIPBOARD',
        nombre = 'Instructora Vega',
    },
    --[[ Dónde sale el aparato del práctico y dónde se deja al acabar. Son
         VARIAS plazas a propósito: con dos alumnos a la vez, una sola acaba
         con un avión encima de otro. El servidor coge la primera libre. ]]
    salidasAvion = {
        vec4(1731.5, 3266.5, 41.1, 105.0),
        vec4(1746.0, 3271.5, 41.1, 105.0),
        vec4(1760.5, 3276.5, 41.1, 105.0),
    },
    salidasHeli = {
        vec4(1766.0, 3241.0, 41.1, 105.0),
        vec4(1777.0, 3245.0, 41.1, 105.0),
    },
    -- Radio en el que se busca hueco antes de sacar el aparato.
    hueco = 9.0,
    -- Lejos de este punto (en metros, en el plano) el examen se da por
    -- abandonado. Cubre Grapeseed y el Chiliad.
    centro = vec3(1500.0, 3800.0, 0.0),
    radioExamen = 4200.0,
}

--- Quién examina. Se sienta en el asiento de al lado.
Config.Examinador = {
    modelo = 's_m_m_pilot_02',
    nombres = { 'Examinador Ruiz', 'Examinadora Salas', 'Examinador Ortega', 'Examinadora Lorca' },
}

-- ── Los niveles ───────────────────────────────────────────────────────────
--[[ `modelos`: lo que habilita cada nivel ADEMÁS de lo del nivel anterior.
     `todo = true` en la alta: cualquier avión o helicóptero.
     `practicos`: los exámenes de shared/examenes.lua que hay que aprobar
     (todos) para sacar el nivel. `duplicado`: lo que cuesta rehacer la
     tarjeta de ese nivel si se pierde. ]]

Config.Niveles = {
    {
        id = 'basica',
        nombre = 'Básica',
        clase = 'Clase C',
        resumen = 'Avionetas ligeras de una hélice',
        precioTeorico = 6000,
        practicos = { 'basica' },
        duplicado = 3500,
        modelos = {
            'duster', 'cuban800', 'mammatus', 'velum', 'velum2', 'dodo', 'microlight', 'stunt',
        },
    },
    {
        id = 'media',
        nombre = 'Media',
        clase = 'Clase B',
        resumen = 'Aviones medios, reactores ligeros y helicópteros civiles',
        precioTeorico = 15000,
        practicos = { 'media_avion', 'media_heli' },
        duplicado = 7500,
        modelos = {
            'vestra', 'nimbus', 'seabreeze', 'howard', 'alphaz1', 'mogul',
            'maverick', 'frogger', 'frogger2', 'swift', 'swift2', 'supervolito', 'supervolito2',
            'volatus', 'seasparrow', 'seasparrow2', 'seasparrow3', 'conada', 'havok', 'buzzard2', 'polmav',
        },
    },
    {
        id = 'alta',
        nombre = 'Alta',
        clase = 'Clase A',
        resumen = 'Cualquier aeronave: reactores, carga y helicópteros pesados',
        precioTeorico = 30000,
        practicos = { 'alta' },
        duplicado = 15000,
        todo = true,
        modelos = {},
    },
}

-- ── El examen teórico ─────────────────────────────────────────────────────

Config.Teorico = {
    preguntas = { basica = 12, media = 12, alta = 15 },   -- cuántas salen de la bolsa
    aprobado = 0.8,                                       -- fracción de aciertos
    tiempo = 600,                                         -- segundos para contestar
    esperaSuspenso = 300,                                 -- segundos hasta poder repetir
}

-- ── El práctico ───────────────────────────────────────────────────────────

Config.Practico = {
    -- Se empieza con 100 y cada fallo resta (ver cada etapa en examenes.lua).
    aprobado = 70,
    esperaSuspenso = 600,
    -- Daño en la carrocería (sobre 1000) que da el examen por suspendido.
    chapaMinima = 550,
    -- Cada golpe que quite más de esto a la chapa resta puntos.
    golpe = 25.0,
    puntosGolpe = 8,
    -- Segundos fuera de la zona del examen antes de darlo por abandonado.
    fueraMax = 25,
    -- Velocidad máxima rodando por tierra (km/h) y lo que resta pasarse.
    rodajeMax = 45.0,
    puntosRodaje = 5,
}

-- ── Pilotar sin licencia ──────────────────────────────────────────────────
--[[ Al sentarse a los mandos de un avión o un helicóptero se mira si lleva
     encima una licencia válida que cubra ESE aparato. Por defecto solo avisa
     (la policía decide); con `bloquear = true` además no deja arrancar. ]]

Config.Control = {
    activo = true,
    bloquear = false,
    -- Trabajos que vuelan por su cuenta (sus helicópteros son de servicio).
    exentos = { police = true, ambulance = true, sheriff = true },
}

-- ── La policía ────────────────────────────────────────────────────────────
--[[ Con `mdt = true` la licencia aparece en la ficha del ciudadano de la
     MDT de origen_police (tabla police_licenses, tipo 'piloto'). Si la
     policía se la retira desde la MDT, la tarjeta sale RETIRADA al
     enseñarla y hay que volver a examinarse desde la básica. ]]

Config.Policia = {
    mdt = true,
    tipo = 'piloto',
    caduca = 1893456000,   -- el mismo «sin caducidad» que usa origen_police
}

-- ── Mapa ──────────────────────────────────────────────────────────────────

Config.Mapa = {
    nombre = 'Escuela de vuelo',
    categoria = 'public',
    icono = 'avion',
}
