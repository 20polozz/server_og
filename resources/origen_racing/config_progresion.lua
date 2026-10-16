--[[ PROGRESIÓN DEL PILOTO (server/progresion.lua, client/temporada.lua y la
     pestaña «Temporada» del hub).

     Cinco piezas:
       · Divisiones: un rating tipo ELO por piloto (empieza en 1000) que sube y
         baja con cada carrera que cuenta, y la división que le toca.
       · Temporadas: numeradas, con inicio y fin; puntos por carrera (la tabla
         de puntos de las sesiones), clasificación y premios al cerrar.
       · Retos diarios y semanales, con recompensa que se reclama a mano.
       · Títulos: se ganan con retos, divisiones y temporadas; uno se lleva puesto.
       · Pase de temporada: niveles con los mismos puntos y una recompensa
         por nivel que se reclama a mano.

     Todo lo calcula el servidor. Los importes son MODERADOS a propósito: el
     servidor tiene un tope de economía de unos 3.000 $ cada 30 min en los
     trabajos, y esto no puede ser una fuente de dinero mejor que trabajar. ]]
Config.Progresion = {
    Enabled = true,

    -- Moneda de los premios y recompensas (la del resto del recurso).
    Moneda = 'ogn',

    -- ── Rating (ELO multijugador) ───────────────────────────────────────────
    RatingInicial = 1000,
    RatingMinimo  = 100,
    --[[ K: cuánto se mueve el rating en una carrera. Con varios corredores se
         reparte entre los emparejamientos (K / (n - 1) por rival), así que una
         carrera de 8 mueve lo mismo, como mucho, que un mano a mano. ]]
    K = 32,
    -- Los primeros N partidos de un piloto se mueven más, para que llegue
    -- antes a su sitio.
    KNovato        = 48,
    CarrerasNovato = 10,

    --[[ Qué carreras cuentan para rating, puntos de temporada y retos:
         ni casuales, ni de un solo corredor, y solo de estos tipos. El drift
         NO cuenta para rating ni temporada: los puntos los da el cliente. ]]
    TiposQueCuentan = { circuit = true, sprint = true, eliminacion = true, arcade = true, territory = true },
    MinCorredores   = 2,

    -- ── Divisiones (desde = rating mínimo) ───────────────────────────────────
    -- El color lo pone la interfaz (paleta común, utils/paleta.ts).
    Divisiones = {
        { id = 'bronce',   label = 'Bronce',   desde = 0 },
        { id = 'plata',    label = 'Plata',    desde = 1100 },
        { id = 'oro',      label = 'Oro',      desde = 1250 },
        { id = 'platino',  label = 'Platino',  desde = 1400 },
        { id = 'diamante', label = 'Diamante', desde = 1600 },
        { id = 'leyenda',  label = 'Leyenda',  desde = 1850 },
    },
    -- Llegar por primera vez a una división da su título (id de Titulos).
    TituloPorDivision = { diamante = 'diamante', leyenda = 'leyenda' },

    -- «Solo mi división» al crear: entra quien esté a ± este número de divisiones.
    MargenDivisiones = 1,

    -- ── Temporadas ──────────────────────────────────────────────────────────
    Temporada = {
        --[[ 15/10: seis semanas con fecha fija. Cada una acaba un domingo a
             las 23:59 (hora de Madrid) y la siguiente empieza en ese momento.
             La primera que se abra a mitad de semana cuenta esa semana como
             la primera de las seis. ]]
        Semanas = 6,
        Dias = 42,                 -- respaldo (no se usa con Semanas)
        -- La última semana: respeto de territorio ×1,5 y protección de 24 h como mucho.
        SemanaFinalRespeto = 1.5,
        SemanaFinalProteccionMin = 24 * 60,
        -- Reinicio suave al cerrar: el rating se acerca a 1000 este tanto por
        -- uno (0.5 = se queda a medio camino; 0 = no se toca; 1 = todos a 1000).
        Reinicio = 0.5,
        -- Puntos de cada carrera: los de Config.Sesiones.Puntos (25, 18, 15…).
        -- Con estos de respaldo si no estuvieran.
        Puntos = { 25, 18, 15, 12, 10, 8, 6, 4, 2, 1 },
        PuntosPorAcabar = 1,       -- a quien acaba fuera de la tabla de puntos
        -- Carreras al día que suman puntos de temporada por piloto (el rating
        -- sigue moviéndose). Que dos amigos no se pasen la tarde regalándose puntos.
        TopeCarrerasDia = 15,
        -- Premios al cerrar, por puesto. `titulo` admite %d (el número de la temporada).
        Premios = {
            { dinero = 5000, titulo = 'Campeón T%d' },
            { dinero = 3000, titulo = 'Subcampeón T%d' },
            { dinero = 2000, titulo = 'Podio T%d' },
            { dinero = 1000 },
            { dinero = 1000 },
            { dinero = 500 },
            { dinero = 500 },
            { dinero = 500 },
            { dinero = 500 },
            { dinero = 500 },
        },
        -- Mínimo de carreras en la temporada para tener premio.
        MinCarrerasPremio = 10,
        Top = 25,                  -- filas de la clasificación en el hub
    },

    -- ── Retos ───────────────────────────────────────────────────────────────
    --[[ tipo:
           terminar   acabar carreras (modo = solo de ese tipo)
           ganar      ganar carreras  (modo = solo de ese tipo)
           podio      acabar entre los tres primeros
           circuitos  correr en circuitos DISTINTOS
           vueltas    vueltas completadas (en carreras de vueltas)
           drift      puntos de drift (del cliente: con tope por carrera)
           division   subir de división
         Recompensa: dinero (OGN), puntos (de temporada) y/o titulo (id). ]]
    Retos = {
        Diarios = 4,             -- 15/10: 4 al día y 4 a la semana (antes 3 y 2)
        Semanales = 4,
        -- Los puntos de drift los cuenta el cliente: en una carrera no suman
        -- más de esto para un reto.
        TopeDriftPorCarrera = 8000,

        -- 15/10: los retos eran casi todo el OGN del servidor (unos 15.000 al
        -- día). Bajan a la escala de la economía nueva, y «puntos» es respeto.
        CatalogoDiario = {
            { id = 'd_terminar3',  texto = 'Termina 3 carreras',            tipo = 'terminar',  objetivo = 3,     dinero = 40, puntos = 40 },
            { id = 'd_podio',      texto = 'Sube al podio',                 tipo = 'podio',     objetivo = 1,     dinero = 60, puntos = 40 },
            { id = 'd_ganar',      texto = 'Gana una carrera',              tipo = 'ganar',     objetivo = 1,     dinero = 80, puntos = 60 },
            { id = 'd_sprint',     texto = 'Gana un sprint',                tipo = 'ganar',     modo = 'sprint', objetivo = 1, dinero = 80, puntos = 60 },
            { id = 'd_circuitos2', texto = 'Corre en 2 circuitos distintos', tipo = 'circuitos', objetivo = 2,     dinero = 40, puntos = 40 },
            { id = 'd_vueltas10',  texto = 'Completa 10 vueltas',           tipo = 'vueltas',   objetivo = 10,    dinero = 40, puntos = 40 },
            { id = 'd_drift15k',   texto = 'Haz 15.000 puntos de drift',    tipo = 'drift',     objetivo = 15000, dinero = 40, puntos = 40 },
            { id = 'd_elim',       texto = 'Termina una eliminación',       tipo = 'terminar',  modo = 'eliminacion', objetivo = 1, dinero = 40, puntos = 40 },
        },
        CatalogoSemanal = {
            { id = 's_terminar15', texto = 'Termina 15 carreras',           tipo = 'terminar',  objetivo = 15,    dinero = 300, puntos = 200 },
            { id = 's_ganar5',     texto = 'Gana 5 carreras',               tipo = 'ganar',     objetivo = 5,     dinero = 400, puntos = 250, titulo = 'imparable' },
            { id = 's_podio8',     texto = 'Sube al podio 8 veces',         tipo = 'podio',     objetivo = 8,     dinero = 300, puntos = 200 },
            { id = 's_circuitos5', texto = 'Corre en 5 circuitos distintos', tipo = 'circuitos', objetivo = 5,     dinero = 250, puntos = 150, titulo = 'trotamundos' },
            { id = 's_drift100k',  texto = 'Haz 100.000 puntos de drift',   tipo = 'drift',     objetivo = 100000, dinero = 250, puntos = 150, titulo = 'rey_drift' },
            { id = 's_division',   texto = 'Sube de división',              tipo = 'division',  objetivo = 1,     dinero = 300, puntos = 200, titulo = 'escalador' },
        },
    },

    -- ── Pase de temporada ───────────────────────────────────────────────────
    --[[ Gratis y para todos. Los niveles se suben con los MISMOS puntos de
         temporada de la clasificación (carreras + retos): no hay otra cosa
         que ganar ni que comprar. Cada nivel tiene su recompensa, que se
         reclama a mano una sola vez por piloto y temporada
         (racing_pase_reclamos). Al cerrar la temporada los puntos vuelven a
         cero y el pase con ellos: lo que no se reclame antes, se pierde.

         La curva: el nivel n cuesta PuntosBase + PuntosSubida·(n − 1), así
         que el 1 sale con 2 carreras y los últimos piden algo más.
         Con 20 y 0,5 son ~1.000 puntos para los 35 niveles. Medido en la
         temporada 1 (primera semana): una carrera deja ~10,5 puntos de media
         contando los retos, y quien corre a diario (≈ 20 carreras a la
         semana) hace ~210 a la semana → unos 900 en 30 días más los retos
         semanales. Lo completa quien juega casi todos los días; quien corre
         un par de días por semana llega a la mitad (los hitos 10 y 20). ]]
    Pase = {
        Enabled = true,
        --[[ Activo: si el pase ya cuenta. Con false la pestaña enseña la
             pista con «El pase empieza pronto», todo bloqueado, y el
             servidor NO escribe nada en la base (ni líneas base ni
             reclamos): así se puede tener en el local sin tocar la buena.

             Lo de antes no cuenta: los puntos de temporada son un total
             (no hay registro con fecha), así que a cada piloto se le apunta
             una LÍNEA BASE (racing_pase_base) la primera vez que el
             servidor lo ve con el pase activo —al abrir la pestaña, al
             acabar una carrera o al reclamar un reto— y el pase cuenta solo
             lo que gane desde ahí: puntos del pase = puntos − base. ]]
        Activo = true,             -- 15/10: encendido
        Niveles = 40,
        -- En respeto de temporada (15/10): ~8.000 para los 35 niveles, unas 60 carreras.
        PuntosBase = 160,
        PuntosSubida = 4,
        -- OGN de un nivel normal (los de Recompensas mandan sobre esto).
        DineroPorNivel = 0,        -- 15/10: el dinero va nivel a nivel (unos 2.100 OGN en todo el pase)
        -- Niveles grandes en la pista (el último siempre lo es).
        Hitos = { 10, 20, 30, 40 },   -- y todos los que dan título
        --[[ Lo que no es un nivel normal. dinero = OGN; titulo = id de
             Titulos (para siempre); tituloTemporada = título de ESA
             temporada, con %d para su número. Total del pase con estos
             valores: 28 × 100 + 3 × 150 + 500 + 750 + 1.000 + 1.500 =
             7.000 OGN en toda la temporada: más o menos lo que dejan dos
             semanas de retos diarios cumplidos (~500 al día). ]]
        --[[ 15/10: solo recompensas que existen (comprobado en el código):
             títulos, el objeto de matrícula personalizada (origen_plates) y
             el coche de la temporada al garaje personal (qbx_vehicles).
             item = { nombre, cantidad, label }; coche = modelo (lo cambia el
             admin cada temporada en CocheTemporada). ]]
        Recompensas = {
            -- Objetos de origen_inventory (con su imagen en ui/images): todos
            -- de carreras y de taller. dinero va a la cartera del piloto.
            [1]  = { items = { { nombre = 'kit_reparacion', cantidad = 1 } } },
            [2]  = { dinero = 100 },
            [3]  = { items = { { nombre = 'bidon_combustible', cantidad = 1 } } },
            [4]  = { dinero = 100 },
            [5]  = { titulo = 'rodado', dinero = 100 },
            [6]  = { items = { { nombre = 'cleaningkit', cantidad = 1 } } },
            [7]  = { dinero = 100 },
            [8]  = { items = { { nombre = 'bomba_ruedas', cantidad = 1 } } },
            [9]  = { dinero = 100 },
            [10] = { tituloTemporada = 'Habitual T%d', items = { { nombre = 'matricula_personalizada', cantidad = 1 } } },
            [11] = { items = { { nombre = 'tirekit', cantidad = 1 } } },
            [12] = { dinero = 100 },
            [13] = { items = { { nombre = 'kit_reparacion', cantidad = 2 } } },
            [14] = { dinero = 100 },
            [15] = { titulo = 'quemarruedas', items = { { nombre = 'oxido_nitroso', cantidad = 1 } } },
            [16] = { dinero = 100 },
            [17] = { items = { { nombre = 'bidon_combustible', cantidad = 2 } } },
            [18] = { dinero = 100 },
            [19] = { items = { { nombre = 'advancedrepairkit', cantidad = 1 } } },
            [20] = { tituloTemporada = 'Veterano T%d', dinero = 200 },
            [21] = { items = { { nombre = 'cleaningkit', cantidad = 2 } } },
            [22] = { dinero = 100 },
            [23] = { items = { { nombre = 'oxido_nitroso', cantidad = 1 } } },
            [24] = { dinero = 100 },
            [25] = { titulo = 'gasolina', items = { { nombre = 'tirekit', cantidad = 2 } } },
            [26] = { dinero = 100 },
            [27] = { items = { { nombre = 'kit_reparacion', cantidad = 3 } } },
            [28] = { dinero = 100 },
            [29] = { items = { { nombre = 'bomba_ruedas', cantidad = 1 } } },
            [30] = { tituloTemporada = 'Élite T%d', dinero = 200, items = { { nombre = 'matricula_personalizada', cantidad = 1 } } },
            [31] = { items = { { nombre = 'advancedrepairkit', cantidad = 1 } } },
            [32] = { dinero = 100 },
            [33] = { items = { { nombre = 'oxido_nitroso', cantidad = 2 } } },
            [34] = { dinero = 100 },
            [35] = { tituloTemporada = 'Incansable T%d' },
            [36] = { dinero = 100 },
            [37] = { items = { { nombre = 'advancedrepairkit', cantidad = 2 } } },
            [38] = { dinero = 100 },
            [39] = { items = { { nombre = 'oxido_nitroso', cantidad = 3 } } },
            [40] = { tituloTemporada = 'Leyenda de la T%d', coche = true },
        },
        -- Nombre que enseña la pista de cada objeto.
        NombresItems = {
            kit_reparacion = 'Kit de reparación rápida', bidon_combustible = 'Bidón de combustible',
            cleaningkit = 'Kit de limpieza', bomba_ruedas = 'Bomba de ruedas', tirekit = 'Kit de neumáticos',
            oxido_nitroso = 'Óxido nitroso', advancedrepairkit = 'Kit de reparación avanzado',
            matricula_personalizada = 'Matrícula personalizada',
        },
        CocheTemporada = 'sultan2',   -- el coche del nivel 40 (modelo de spawn)
        GarajeCoche    = 'garaje_central',
    },

    -- ── Títulos ─────────────────────────────────────────────────────────────
    -- Los de temporada («Campeón T3», «Veterano T3»…) se crean al ganarlos,
    -- no van aquí.
    Titulos = {
        novato      = 'Novato',            -- todos lo tienen
        leyenda     = 'Leyenda',
        diamante    = 'Diamante',
        rey_drift   = 'Rey del drift',
        imparable   = 'Imparable',
        trotamundos = 'Trotamundos',
        escalador   = 'Escalador',
        -- Del pase de temporada
        rodado       = 'Rodado',
        quemarruedas = 'Quemarruedas',
        gasolina     = 'Gasolina en vena',
    },
}

--[[ RESPETO DEL PILOTO (server/respeto.lua, 15/10). La única medida de
     progreso: el total sube el nivel (1-50) y la licencia; el de temporada es
     el que suma la clasificación y el pase. Una carrera normal (6 pilotos,
     4 minutos, 3.º) da unos 130. ]]
Config.Respeto = {
    Enabled = true,

    -- Por carrera (solo carreras con 3+ en la salida, 2+ que acaban y 90 s)
    Acabar        = 50,
    Puesto        = { 60, 45, 35 },   -- extra del 1.º, 2.º y 3.º
    PuestoHasta6  = 20,               -- extra del 4.º al 6.º
    PuestoResto   = 10,               -- extra del resto que acaba
    PorRival      = 5,                -- por cada piloto que acaba detrás
    RivalMax      = 50,
    PorMinuto     = 8,                -- por minuto de carrera (del ganador)
    MinutoMax     = 80,
    NoAcabar      = 10,
    PrimeraVictoria = 150,            -- la primera victoria del día (Madrid)
    Drift         = 40,               -- fijo por acabar: sus puntos los cuenta el cliente

    -- Multiplicadores
    PorTipo  = { eliminacion = 1.25, territory = 1.5 },
    Semana   = 1.5,                   -- circuito de la semana
    CasaRival = 1.25,                 -- circuito de casa de otra crew (server/guerras.lua)
    Casual   = 0.4,                   -- casual y arcade: solo respeto total, sin bonos
    Novato   = 1.5,                   -- las primeras CarrerasNovato carreras
    CarrerasNovato = 10,

    -- Mismo grupo de rivales en el día: desde la vez GrupoMitad, la mitad;
    -- desde GrupoCero, nada.
    GrupoMitad = 5,
    GrupoCero  = 9,

    -- Niveles: pasar del n al n+1 cuesta NivelBase + NivelPaso·(n−1)
    NivelBase = 400,
    NivelPaso = 80,
    NivelMax  = 50,

    --[[ Licencias. entradaMax = entrada máxima al crear o unirse; clases =
         letras de las clases de coche que deja usar (racing_vehicle_classes,
         «Clase D» → D). Un coche que no está en ninguna clase no se frena. ]]
    Licencias = {
        { id = 'C', label = 'C',       nivel = 1,  entradaMax = 250,   clases = { 'D', 'C' },
          abre = 'Salas sin entrada o hasta 250 OGN. Clases D y C.' },
        { id = 'B', label = 'B',       nivel = 8,  entradaMax = 2500,  clases = { 'D', 'C', 'B' },
          abre = 'Entradas hasta 2.500. Clase B. Fundar una crew y apostar.' },
        { id = 'A', label = 'A',       nivel = 18, entradaMax = 10000, clases = { 'D', 'C', 'B', 'A' },
          abre = 'Entradas hasta 10.000. Clase A. Carreras de papeles.' },
        { id = 'S', label = 'S',       nivel = 30, entradaMax = 50000, clases = { 'D', 'C', 'B', 'A', 'S', 'S+' },
          abre = 'Entradas hasta 50.000. Clase S y superdeportivos.' },
        { id = 'L', label = 'Leyenda', nivel = 50, entradaMax = 50000, clases = { 'D', 'C', 'B', 'A', 'S', 'S+' },
          abre = 'Licencia de leyenda.' },
    },
    --[[ Clases por defecto (15/10). Si un coche no está en ninguna clase del
         admin (racing_vehicle_classes), su letra sale de aquí para el límite
         de la licencia. Un coche que no está ni aquí ni en el admin no se frena.
         Las clases del admin mandan siempre sobre esta lista. ]]
    ClasesPorDefecto = {
        D  = { 'futo', 'blista', 'blista2', 'issi2', 'issi3', 'panto', 'prairie', 'brioso', 'rhapsody', 'dilettante', 'asea', 'premier',
               'emperor', 'warrener', 'club', 'kanjo', 'weevil', 'asbo', 'primo', 'stanier', 'ingot', 'fugitive', 'glendale', 'regina' },
        C  = { 'sultan', 'penumbra', 'penumbra2', 'dominator', 'gauntlet', 'buffalo', 'fusilade', 'schwarzer', 'sentinel3', 'rt3000',
               'tailgater', 'zion3', 'dominator3', 'ellie', 'retinue', 'savestra', 'gt500', 'futo2', 'blista3', 'sentinel', 'zion', 'oracle2',
               'felon', 'jackal', 'cogcabrio', 'chino', 'hotknife', 'blade', 'phoenix', 'vigero', 'ruiner', 'sabregt', 'stalion' },
        B  = { 'kuruma', 'jester', 'comet2', 'comet3', 'banshee', 'carbonizzare', 'coquette', 'elegy2', 'feltzer2', 'furoregt', 'massacro',
               'ninef', 'ninef2', 'rapidgt', 'schafter3', 'seven70', 'buffalo2', 'remus', 'previon', 'dominator7', 'gb200', 'flashgt',
               'jugular', 'paragon', 'drafter', 'komoda', 'imorgon', 'vstr', 'alpha', 'khamelion', 'surano', 'verlierer2', 'lynx', 'raptor' },
        A  = { 'sultanrs', 'zr350', 'jester3', 'comet5', 'comet6', 'comet7', 'jester4', 'italirsx', 'pariah', 'neon', 'schlagen', 'italigto',
               'elegy', 'specter', 'specter2', 'revolter', 'raiden', 'banshee2', 'sugoi', 'sultan2', 'vectre', 'euros', 'growler', 'cypher',
               'tailgater2', 'calico', 'coquette4', 'massacro2', 'jester2', 'locust', 'neo', 'tropos' },
        S  = { 't20', 'italigtb', 'italigtb2', 'osiris', 'reaper', 'tyrus', 'vagner', 'xa21', 'nero', 'nero2', 'cyclone', 'autarch', 'visione',
               'taipan', 'tempesta', 'fmj', 'pfister811', 'prototipo', 'sc1', 'vacca', 'cheetah', 'infernus', 'adder', 'turismor', 'entityxf',
               'zentorno', 'bullet', 'gp1', 'penetrator', 'le7b', 'sheava', 'italirsx2' },
        ['S+'] = { 'krieger', 'emerus', 'tezeract', 'thrax', 'deveste', 'furia', 's80', 'zorrusso', 'ignus', 'entity3', 'torero2', 'entity2' },
    },
    LicenciaPapeles = 'A',
    LicenciaCrew    = 'B',
    LicenciaApostar = 'B',
}

--[[ LOGROS (server/logros.lua, 15/10). Insignias que se coleccionan jugando;
     cada una sale de datos que el servidor ya guarda (`dato`) y da su título.
     rareza: bronce · plata · oro · leyenda (la forma y el color de la insignia).
     icono: de lucide (los que ya usa el hub). ]]
Config.Logros = {
    -- Respeto de piloto que da cada logro la primera vez, según su rareza (15/10).
    -- Una sola vez por piloto: todo junto son unos 19.000 de respeto repartidos en meses.
    Respeto = { bronce = 50, plata = 150, oro = 400, leyenda = 1000 },
    Categorias = {
        { id = 'carrera',  label = 'En pista' },
        { id = 'piloto',   label = 'Licencia y división' },
        { id = 'circuito', label = 'Circuitos y récords' },
        { id = 'crew',     label = 'Crew y territorio' },
        { id = 'temporada', label = 'Temporadas y retos' },
    },
    -- Once por categoría (una fila entera en la colección).
    Lista = {
        -- En pista
        { id = 'primera_carrera', categoria = 'carrera', rareza = 'bronce',  icono = 'lucide:flag',          dato = 'carreras',  objetivo = 1,   nombre = 'Primera salida',   texto = 'Acaba tu primera carrera' },
        { id = 'carreras_25',     categoria = 'carrera', rareza = 'plata',   icono = 'lucide:flag',          dato = 'carreras',  objetivo = 25,  nombre = 'Habitual',         texto = 'Corre 25 carreras' },
        { id = 'carreras_100',    categoria = 'carrera', rareza = 'oro',     icono = 'lucide:flag',          dato = 'carreras',  objetivo = 100, nombre = 'Kilómetros',       texto = 'Corre 100 carreras' },
        { id = 'carreras_500',    categoria = 'carrera', rareza = 'leyenda', icono = 'lucide:flag',          dato = 'carreras',  objetivo = 500, nombre = 'Vive en la pista', texto = 'Corre 500 carreras' },
        { id = 'primera_victoria', categoria = 'carrera', rareza = 'bronce', icono = 'lucide:trophy',        dato = 'victorias', objetivo = 1,   nombre = 'Primera victoria', texto = 'Gana una carrera' },
        { id = 'victorias_10',    categoria = 'carrera', rareza = 'plata',   icono = 'lucide:trophy',        dato = 'victorias', objetivo = 10,  nombre = 'Ganador',          texto = 'Gana 10 carreras' },
        { id = 'victorias_50',    categoria = 'carrera', rareza = 'oro',     icono = 'lucide:trophy',        dato = 'victorias', objetivo = 50,  nombre = 'Depredador',       texto = 'Gana 50 carreras' },
        { id = 'victorias_200',   categoria = 'carrera', rareza = 'leyenda', icono = 'lucide:trophy',        dato = 'victorias', objetivo = 200, nombre = 'Intocable',        texto = 'Gana 200 carreras' },
        { id = 'podios_10',       categoria = 'carrera', rareza = 'plata',   icono = 'lucide:medal',         dato = 'podios',    objetivo = 10,  nombre = 'Podio fijo',       texto = 'Sube al podio 10 veces' },
        { id = 'racha_3',         categoria = 'carrera', rareza = 'plata',   icono = 'lucide:flame',         dato = 'racha',     objetivo = 3,   nombre = 'En racha',         texto = 'Gana 3 carreras seguidas' },
        { id = 'racha_7',         categoria = 'carrera', rareza = 'oro',     icono = 'lucide:flame',         dato = 'racha',     objetivo = 7,   nombre = 'Imparable',        texto = 'Gana 7 carreras seguidas' },
        -- Licencia y división
        { id = 'nivel_5',         categoria = 'piloto', rareza = 'bronce',  icono = 'lucide:chevrons-up',   dato = 'nivel',     objetivo = 5,   nombre = 'Despegue',         texto = 'Llega al nivel 5 de piloto' },
        { id = 'licencia_b',      categoria = 'piloto', rareza = 'bronce',  icono = 'lucide:id-card',       dato = 'licencia',  objetivo = 2,   nombre = 'Licencia B',       texto = 'Llega al nivel 8 de piloto' },
        { id = 'licencia_a',      categoria = 'piloto', rareza = 'plata',   icono = 'lucide:id-card',       dato = 'licencia',  objetivo = 3,   nombre = 'Licencia A',       texto = 'Llega al nivel 18 de piloto' },
        { id = 'nivel_25',        categoria = 'piloto', rareza = 'plata',   icono = 'lucide:chevrons-up',   dato = 'nivel',     objetivo = 25,  nombre = 'Medio camino',     texto = 'Llega al nivel 25 de piloto' },
        { id = 'licencia_s',      categoria = 'piloto', rareza = 'oro',     icono = 'lucide:id-card',       dato = 'licencia',  objetivo = 4,   nombre = 'Licencia S',       texto = 'Llega al nivel 30 de piloto' },
        { id = 'licencia_l',      categoria = 'piloto', rareza = 'leyenda', icono = 'lucide:crown',         dato = 'licencia',  objetivo = 5,   nombre = 'Leyenda',          texto = 'Llega al nivel 50 de piloto' },
        { id = 'division_plata',  categoria = 'piloto', rareza = 'bronce',  icono = 'lucide:shield',        dato = 'division',  objetivo = 2,   nombre = 'División Plata',   texto = 'Sube a la división Plata' },
        { id = 'division_oro',    categoria = 'piloto', rareza = 'plata',   icono = 'lucide:shield',        dato = 'division',  objetivo = 3,   nombre = 'División Oro',     texto = 'Sube a la división Oro' },
        { id = 'division_platino', categoria = 'piloto', rareza = 'oro',    icono = 'lucide:shield-check',  dato = 'division',  objetivo = 4,   nombre = 'División Platino', texto = 'Sube a la división Platino' },
        { id = 'division_diamante', categoria = 'piloto', rareza = 'oro',   icono = 'lucide:gem',           dato = 'division',  objetivo = 5,   nombre = 'Diamante',         texto = 'Sube a la división Diamante' },
        { id = 'division_leyenda', categoria = 'piloto', rareza = 'leyenda', icono = 'lucide:sparkles',     dato = 'division',  objetivo = 6,   nombre = 'Élite',            texto = 'Sube a la división Leyenda' },
        -- Circuitos y récords
        { id = 'circuitos_5',     categoria = 'circuito', rareza = 'bronce',  icono = 'lucide:map',         dato = 'circuitos', objetivo = 5,   nombre = 'Explorador',       texto = 'Marca tiempo en 5 circuitos' },
        { id = 'circuitos_15',    categoria = 'circuito', rareza = 'plata',   icono = 'lucide:map',         dato = 'circuitos', objetivo = 15,  nombre = 'Trotamundos',      texto = 'Marca tiempo en 15 circuitos' },
        { id = 'circuitos_30',    categoria = 'circuito', rareza = 'oro',     icono = 'lucide:map',         dato = 'circuitos', objetivo = 30,  nombre = 'Conoce cada curva', texto = 'Marca tiempo en 30 circuitos' },
        { id = 'circuitos_40',    categoria = 'circuito', rareza = 'leyenda', icono = 'lucide:map-pinned',  dato = 'circuitos', objetivo = 40,  nombre = 'Cartógrafo',       texto = 'Marca tiempo en 40 circuitos' },
        { id = 'vueltas_100',     categoria = 'circuito', rareza = 'bronce',  icono = 'lucide:rotate-cw',   dato = 'vueltas',   objetivo = 100, nombre = 'Cien vueltas',     texto = 'Completa 100 vueltas' },
        { id = 'vueltas_500',     categoria = 'circuito', rareza = 'plata',   icono = 'lucide:rotate-cw',   dato = 'vueltas',   objetivo = 500, nombre = 'Quinientas',       texto = 'Completa 500 vueltas' },
        { id = 'vueltas_1000',    categoria = 'circuito', rareza = 'oro',     icono = 'lucide:infinity',    dato = 'vueltas',   objetivo = 1000, nombre = 'Mil vueltas',     texto = 'Completa 1.000 vueltas' },
        { id = 'record_1',        categoria = 'circuito', rareza = 'plata',   icono = 'lucide:timer',       dato = 'records',   objetivo = 1,   nombre = 'Plusmarquista',    texto = 'Ten un récord de circuito' },
        { id = 'record_3',        categoria = 'circuito', rareza = 'oro',     icono = 'lucide:timer',       dato = 'records',   objetivo = 3,   nombre = 'Cronómetro',       texto = 'Ten 3 récords de circuito' },
        { id = 'record_5',        categoria = 'circuito', rareza = 'leyenda', icono = 'lucide:timer',       dato = 'records',   objetivo = 5,   nombre = 'Dueño del crono',  texto = 'Ten 5 récords de circuito' },
        { id = 'creador',         categoria = 'circuito', rareza = 'oro',     icono = 'lucide:pencil-ruler', dato = 'propuestos', objetivo = 1, nombre = 'Creador',          texto = 'Que publiquen un circuito tuyo' },
        -- Crew y territorio
        { id = 'en_crew',         categoria = 'crew', rareza = 'bronce',  icono = 'lucide:users',           dato = 'crew',      objetivo = 1,   nombre = 'De la familia',    texto = 'Entra en una crew' },
        { id = 'fundador',        categoria = 'crew', rareza = 'plata',   icono = 'lucide:crown',           dato = 'fundador',  objetivo = 1,   nombre = 'Fundador',         texto = 'Lidera una crew' },
        { id = 'crew_casa',       categoria = 'crew', rareza = 'bronce',  icono = 'lucide:house',           dato = 'crewCasa',  objetivo = 1,   nombre = 'En casa',          texto = 'Tu crew tiene circuito de casa' },
        { id = 'crew_nivel_5',    categoria = 'crew', rareza = 'plata',   icono = 'lucide:chevrons-up',     dato = 'crewNivel', objetivo = 5,   nombre = 'Crew en marcha',   texto = 'Tu crew llega al nivel 5' },
        { id = 'crew_nivel_10',   categoria = 'crew', rareza = 'oro',     icono = 'lucide:chevrons-up',     dato = 'crewNivel', objetivo = 10,  nombre = 'Crew seria',       texto = 'Tu crew llega al nivel 10' },
        { id = 'crew_nivel_20',   categoria = 'crew', rareza = 'leyenda', icono = 'lucide:chevrons-up',     dato = 'crewNivel', objetivo = 20,  nombre = 'Dinastía',         texto = 'Tu crew llega al nivel 20' },
        { id = 'crew_territorio', categoria = 'crew', rareza = 'plata',   icono = 'lucide:flag-triangle-right', dato = 'crewTerritorios', objetivo = 1, nombre = 'Bandera puesta', texto = 'Tu crew tiene un territorio' },
        { id = 'crew_territorios_3', categoria = 'crew', rareza = 'oro',  icono = 'lucide:flag-triangle-right', dato = 'crewTerritorios', objetivo = 3, nombre = 'Barrio propio', texto = 'Tu crew tiene 3 territorios' },
        { id = 'crew_imperio',    categoria = 'crew', rareza = 'leyenda', icono = 'lucide:castle',          dato = 'crewTerritorios', objetivo = 5, nombre = 'Imperio',      texto = 'Tu crew tiene 5 territorios' },
        { id = 'crew_conquistas', categoria = 'crew', rareza = 'oro',     icono = 'lucide:swords',          dato = 'conquistas', objetivo = 5,  nombre = 'Conquistador',     texto = 'Tu crew conquista 5 territorios' },
        { id = 'crew_bandera',    categoria = 'crew', rareza = 'oro',     icono = 'lucide:flag',            dato = 'crewBandera', objetivo = 1, nombre = 'Bandera clavada',  texto = 'Tu crew tiene el récord de la casa de otra' },
        -- Temporadas y retos
        { id = 'retos_10',        categoria = 'temporada', rareza = 'bronce',  icono = 'lucide:target',     dato = 'retos',     objetivo = 10,  nombre = 'Cumplidor',        texto = 'Completa 10 retos' },
        { id = 'retos_50',        categoria = 'temporada', rareza = 'plata',   icono = 'lucide:target',     dato = 'retos',     objetivo = 50,  nombre = 'Sin excusas',      texto = 'Completa 50 retos' },
        { id = 'retos_200',       categoria = 'temporada', rareza = 'oro',     icono = 'lucide:target',     dato = 'retos',     objetivo = 200, nombre = 'Obsesivo',         texto = 'Completa 200 retos' },
        { id = 'retos_500',       categoria = 'temporada', rareza = 'leyenda', icono = 'lucide:crosshair',  dato = 'retos',     objetivo = 500, nombre = 'Máquina',          texto = 'Completa 500 retos' },
        { id = 'pase_10',         categoria = 'temporada', rareza = 'bronce',  icono = 'lucide:ticket',     dato = 'paseNiveles', objetivo = 10, nombre = 'Pase en marcha',  texto = 'Reclama 10 niveles del pase' },
        { id = 'pase_25',         categoria = 'temporada', rareza = 'plata',   icono = 'lucide:ticket',     dato = 'paseNiveles', objetivo = 25, nombre = 'Coleccionista',   texto = 'Reclama 25 niveles del pase' },
        { id = 'pase_completo',   categoria = 'temporada', rareza = 'oro',     icono = 'lucide:ticket-check', dato = 'paseCompleto', objetivo = 1, nombre = 'Pase completo', texto = 'Llega al último nivel del pase' },
        { id = 'temporadas_3',    categoria = 'temporada', rareza = 'plata',   icono = 'lucide:calendar',   dato = 'temporadas', objetivo = 3,  nombre = 'Veterano',         texto = 'Corre en 3 temporadas' },
        { id = 'titulos_10',      categoria = 'temporada', rareza = 'oro',     icono = 'lucide:badge',      dato = 'titulos',   objetivo = 10,  nombre = 'Vitrina llena',    texto = 'Gana 10 títulos de temporada, pase o retos' },
        { id = 'podio_temporada', categoria = 'temporada', rareza = 'oro',     icono = 'lucide:award',      dato = 'podioTemporada', objetivo = 1, nombre = 'Podio de temporada', texto = 'Acaba una temporada entre los 3 primeros' },
        { id = 'campeon',         categoria = 'temporada', rareza = 'leyenda', icono = 'lucide:crown',      dato = 'campeon',   objetivo = 1,   nombre = 'Campeón',          texto = 'Gana una temporada' },
    },
}
