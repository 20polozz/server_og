--[[ ORIGEN · Caza

     Todo lo que se puede ajustar sin tocar código. El servidor es quien decide
     con estos valores: precios, calidades, experiencia y topes se leen AQUÍ y
     nunca de lo que diga un cliente. ]]

Config = {}

-- Trazas en la consola del cliente (F8) y del servidor.
Config.Depurar = false

--[[ ── El campamento ────────────────────────────────────────────────────────
     Los tres NPC están a pocos metros. Todo lo que se hace en el panel
     (comprar, vender, la licencia, cobrar encargos) exige estar dentro de
     `radio` del centro, y eso lo comprueba el servidor con tu posición real. ]]
Config.Campamento = {
    centro = vec3(-684.0, 5815.0, 17.0),
    radio = 45.0,

    Peds = {
        Experto   = { modelo = 'MP_M_ExArmy_01', coords = vec4(-695.89, 5802.41, 17.33, 65.86),  texto = 'Hablar con el experto', seccion = 'jornada' },
        Tienda    = { modelo = 'ig_hunter',      coords = vec4(-679.52, 5834.08, 17.33, 130.03), texto = 'Tienda de caza',        seccion = 'tienda' },
        Comprador = { modelo = 'cs_old_man2',    coords = vec4(-667.82, 5813.23, 17.52, 350.99), texto = 'Vender la caza',        seccion = 'vender' },
    },
}

--[[ ── Las zonas ────────────────────────────────────────────────────────────
     Círculos en PLANTA: la altura no cuenta. Una esfera dejaba fuera a quien
     estuviera en una ladera más alta o más baja que el centro. Los animales
     aparecen alrededor del cazador, no en puntos fijos: así siempre hay suelo
     cargado debajo y no caen bajo el mapa. ]]
Config.Zonas = {
    { id = 'paleto', nombre = 'Bosque de Paleto', centro = vec2(-662.5, 5256.67),  radio = 350.0 },
    { id = 'josiah', nombre = 'Monte Josiah',     centro = vec2(-1189.74, 3857.12), radio = 600.0 },
}

--[[ ── Las especies ─────────────────────────────────────────────────────────
     nivel         nivel mínimo para que te aparezca y para despellejarla
     peso          probabilidad relativa de aparecer
     horas         multiplicador del peso por franja: amanecer, dia, atardecer, noche
     conducta      'huye' · 'embiste' (ataca si te acercas mucho) · 'ataca' (te busca)
     deteccion     metros a los que te nota de pie y sin viento
     vida          multiplicador de la vida del animal
     piel          precio base de su piel (se multiplica por la calidad)
     carne         objeto y cuántas piezas da con calidad normal
     legendaria    rara: piel propia, mucha experiencia y marca dorada ]]
Config.Especies = {
    conejo = {
        nombre = 'Conejo', modelo = 'a_c_rabbit_01', nivel = 1, xp = 15, peso = 26,
        horas = { 1.2, 1.0, 1.2, 0.6 },
        conducta = 'huye', deteccion = 14.0, vida = 1.0,
        piel = 6, carne = { item = 'rabbit_meat', min = 1, max = 2 },
    },
    liebre = {
        nombre = 'Liebre', modelo = 'a_c_rabbit_02', nivel = 1, xp = 18, peso = 14,
        horas = { 1.3, 0.9, 1.3, 0.6 },
        conducta = 'huye', deteccion = 18.0, vida = 1.0,
        piel = 8, carne = { item = 'rabbit_meat', min = 1, max = 2 },
    },
    ciervo = {
        nombre = 'Ciervo', modelo = 'a_c_deer', nivel = 1, xp = 30, peso = 30,
        horas = { 1.6, 0.8, 1.6, 0.7 },
        conducta = 'huye', deteccion = 30.0, vida = 1.0,
        piel = 16, carne = { item = 'deer_meat', min = 2, max = 4 },
    },
    coyote = {
        nombre = 'Coyote', modelo = 'a_c_coyote', nivel = 2, xp = 35, peso = 16,
        horas = { 1.0, 0.7, 1.2, 1.8 },
        conducta = 'huye', deteccion = 24.0, vida = 1.0,
        piel = 13, carne = { item = 'coyote_meat', min = 1, max = 2 },
    },
    jabali = {
        nombre = 'Jabalí', modelo = 'a_c_boar', nivel = 2, xp = 45, peso = 14,
        horas = { 1.4, 0.8, 1.4, 1.0 },
        conducta = 'embiste', deteccion = 16.0, vida = 1.3,
        piel = 20, carne = { item = 'boar_meat', min = 2, max = 3 },
    },
    puma = {
        nombre = 'Puma', modelo = 'a_c_mtlion', nivel = 4, xp = 80, peso = 6,
        horas = { 1.0, 0.5, 1.2, 2.0 },
        conducta = 'ataca', deteccion = 32.0, vida = 1.5,
        -- Protegida: abatirla sin licencia en vigor siempre llega a la policía.
        protegida = true,
        piel = 40, carne = { item = 'mtlion_meat', min = 1, max = 2 },
    },

    -- Las legendarias. Mismo modelo que su especie; se distinguen por la marca
    -- dorada del mapa, por el aviso y porque aguantan mucho más.
    ciervo_albino = {
        nombre = 'Ciervo Albino', modelo = 'a_c_deer', nivel = 3, xp = 250, peso = 0.6,
        horas = { 2.0, 0.5, 2.0, 0.5 },
        conducta = 'huye', deteccion = 45.0, vida = 2.2,
        legendaria = true, pielItem = 'animal_pelt_legendary',
        piel = 320, carne = { item = 'deer_meat', min = 4, max = 6 },
    },
    puma_sombra = {
        nombre = 'Puma Sombra', modelo = 'a_c_mtlion', nivel = 5, xp = 400, peso = 0.35,
        horas = { 0.5, 0.2, 1.0, 3.0 },
        conducta = 'ataca', deteccion = 40.0, vida = 3.0,
        legendaria = true, protegida = true, pielItem = 'animal_pelt_legendary',
        piel = 650, carne = { item = 'mtlion_meat', min = 3, max = 4 },
    },
}

-- Franjas del reloj del juego, para `horas` de cada especie.
Config.Franjas = {
    { desde = 5,  hasta = 8 },   -- amanecer
    { desde = 9,  hasta = 17 },  -- día
    { desde = 18, hasta = 21 },  -- atardecer
    -- el resto es noche
}

--[[ ── Las armas y la calidad ───────────────────────────────────────────────
     La calidad de la pieza (1 a 3 estrellas) la pone el servidor mirando CON
     QUÉ murió el animal. La escopeta destroza la piel: nunca pasa de dos.
     Cualquier otra muerte —un arma que no es de caza, un atropello, una
     caída— deja una piel de una estrella y cuenta como caza furtiva. ]]
Config.Armas = {
    WEAPON_MUSKET    = { nombre = 'Rifle de caza', calidad = 3 },
    WEAPON_DBSHOTGUN = { nombre = 'Escopeta de caza', calidad = 2 },
}

Config.Calidad = {
    pieles = { 'animal_pelt_poor', 'animal_pelt_good', 'animal_pelt_perfect' },
    nombres = { 'Estropeada', 'Buena', 'Perfecta' },
    -- Multiplicador del precio de la piel por estrellas.
    precio = { 0.5, 1.0, 1.9 },
    -- Tres disparos o más estropean la pieza una estrella.
    disparosQueEstropean = 3,
}

-- Precio por pieza de carne, antes del bonus de nivel.
Config.Carnes = {
    rabbit_meat = { nombre = 'Carne de conejo', precio = 9 },
    deer_meat   = { nombre = 'Carne de ciervo', precio = 15 },
    coyote_meat = { nombre = 'Carne de coyote', precio = 11 },
    boar_meat   = { nombre = 'Carne de jabalí', precio = 17 },
    mtlion_meat = { nombre = 'Carne de puma',   precio = 26 },
}

-- Pieles que no traen la ficha de la especie (las de antes de este cambio).
Config.PielSinFicha = {
    animal_pelt_poor = 5,
    animal_pelt_good = 12,
    animal_pelt_perfect = 25,
    animal_pelt_legendary = 320,
}

-- Entregar el animal entero paga la piel y la carne media, más esto.
Config.PremioEntero = 1.35

--[[ ── Niveles ──────────────────────────────────────────────────────────────
     bonus    % extra en todo lo que vendes
     presas   cuántos animales pueden estar vivos a la vez para ti ]]
Config.Niveles = {
    { nombre = 'Novato',          xp = 0,    bonus = 0,  presas = 1 },
    { nombre = 'Aprendiz',        xp = 600,  bonus = 5,  presas = 1 },
    { nombre = 'Rastreador',      xp = 1800, bonus = 10, presas = 2 },
    { nombre = 'Cazador',         xp = 4000, bonus = 15, presas = 2 },
    { nombre = 'Maestro cazador', xp = 8000, bonus = 25, presas = 3 },
}

--[[ ── Licencia ─────────────────────────────────────────────────────────────
     Se puede cazar sin ella, pero es caza furtiva: el comprador paga menos y
     cada pieza puede acabar en un aviso a la policía. ]]
Config.Licencia = {
    precio = 1500,
    dias = 7,
    pagoSinLicencia = 0.5,
    avisoFurtivo = 0.35,       -- probabilidad por pieza sin licencia
    avisoArmaIlegal = 0.6,     -- por pieza abatida con un arma que no es de caza
    trabajosPolicia = { 'police' },
}

--[[ ── La tienda ────────────────────────────────────────────────────────────
     Se paga desde el banco; si el jugador tiene varias cuentas, elige con
     cuál (origen_banking). ]]
Config.Tienda = {
    { item = 'weapon_musket',    precio = 6500, nivel = 3, grupo = 'armas',  detalle = 'Tres estrellas si aciertas limpio' },
    { item = 'weapon_dbshotgun', precio = 3000, nivel = 1, grupo = 'armas',  detalle = 'Hasta dos estrellas: los perdigones rompen la piel' },
    { item = 'hunting_ammo',     precio = 60,   nivel = 1, grupo = 'equipo', detalle = 'Munición para las dos armas de caza' },
    { item = 'hunting_knife',    precio = 200,  nivel = 1, grupo = 'equipo', detalle = 'Sin él no se despelleja' },
    { item = 'hunting_bait',     precio = 45,   nivel = 1, grupo = 'equipo', detalle = 'Atrae a la presa hasta donde lo dejes' },
    { item = 'hunting_call',     precio = 350,  nivel = 2, grupo = 'equipo', detalle = 'Hace que la presa venga hacia ti' },
}

Config.Objetos = {
    cuchillo = 'hunting_knife',
    cebo = 'hunting_bait',
    reclamo = 'hunting_call',
}

--[[ ── Las presas ───────────────────────────────────────────────────────────
     Los tiempos protegen al servidor: aunque un cliente pida presas sin
     parar, no recibe más de lo que dicen estos números. ]]
Config.Presas = {
    distanciaMin = 70.0,        -- metros del cazador a los que aparece
    distanciaMax = 130.0,
    esperaEntre = 12,           -- s mínimos entre dos presas
    esperaTrasAbatir = 20,      -- s tras resolver una presa
    vidaMaxima = 15 * 60,       -- s que una presa viva puede durar
    cadaverDura = 6 * 60,       -- s que un cadáver sigue en el suelo
    lejosDelCazador = 350.0,    -- a más de esto, la presa se retira
    exclusivaDelCazador = 60,   -- s en los que solo quien la abatió puede tocarla
}

--[[ ── Rastreo ──────────────────────────────────────────────────────────────
     El mapa no dice dónde está la presa: marca una zona aproximada que se
     mueve con ella. De cerca hay que seguir las huellas (y la sangre, si
     está herida). ]]
Config.Rastreo = {
    zonaRadio = 90.0,           -- radio de la zona del mapa
    zonaCada = 15,              -- s entre actualizaciones de la zona
    sinZonaA = 60.0,            -- más cerca que esto, la zona desaparece
    huellaCada = 2.0,           -- metros entre huellas
    huellasMax = 40,
    huellasSeVenA = 40.0,
    -- Multiplicadores de la distancia a la que te detecta un animal.
    agachado = 0.55,
    corriendo = 1.5,
    vientoEnContra = 1.6,       -- el viento lleva tu olor hacia el animal
}

Config.Cebo = {
    dura = 120,                 -- s que el cebo atrae
    alcance = 140.0,
    duracionColocar = 5000,
}

Config.Reclamo = {
    espera = 45,                -- s entre dos usos
    alcance = 170.0,
}

-- Llevar un animal a hombros y cargarlo en un vehículo.
Config.Carga = {
    -- Clases de vehículo con caja o maletero grande: todoterrenos,
    -- industriales, utilitarios, furgonetas y comerciales.
    clases = { [9] = true, [10] = true, [11] = true, [12] = true, [20] = true },
    -- Las especies pequeñas no se cargan: se despellejan en el sitio.
    noSeCargan = { conejo = true, liebre = true },
}

--[[ ── Encargos diarios ─────────────────────────────────────────────────────
     Cada día el experto propone `porDia` encargos a cada cazador, sacados de
     la lista según su nivel. ]]
Config.Encargos = {
    porDia = 3,
    lista = {
        { id = 'ciervos',  tipo = 'abatir', especie = 'ciervo', n = { 2, 4 },  nivel = 1, pago = 450,  xp = 80,  texto = 'Abate %d ciervos' },
        { id = 'conejos',  tipo = 'abatir', especie = 'conejo', n = { 3, 5 },  nivel = 1, pago = 260,  xp = 50,  texto = 'Abate %d conejos' },
        { id = 'coyotes',  tipo = 'abatir', especie = 'coyote', n = { 2, 3 },  nivel = 2, pago = 420,  xp = 80,  texto = 'Abate %d coyotes' },
        { id = 'jabalies', tipo = 'abatir', especie = 'jabali', n = { 1, 3 },  nivel = 2, pago = 650,  xp = 110, texto = 'Abate %d jabalíes' },
        { id = 'pumas',    tipo = 'abatir', especie = 'puma',   n = { 1, 1 },  nivel = 4, pago = 1200, xp = 220, texto = 'Abate %d puma con licencia' },
        { id = 'perfecta', tipo = 'calidad', calidad = 3,       n = { 1, 3 },  nivel = 2, pago = 700,  xp = 130, texto = 'Consigue %d pieles perfectas' },
        { id = 'enteros',  tipo = 'entregar',                   n = { 1, 2 },  nivel = 1, pago = 520,  xp = 90,  texto = 'Entrega %d animales enteros' },
        { id = 'carne',    tipo = 'carne',                      n = { 8, 16 }, nivel = 1, pago = 300,  xp = 60,  texto = 'Vende %d piezas de carne' },
    },
}

-- La clasificación semanal: cuántos puestos se enseñan.
Config.Clasificacion = { puestos = 10 }

--[[ ── Torneos ──────────────────────────────────────────────────────────────
     Cada `cadaHoras` arranca un torneo con una modalidad sorteada. Todo el
     servidor recibe los avisos: los minutos antes, el arranque, el último
     tramo y el podio. Participa cualquiera que tenga la jornada de caza en
     marcha mientras dure; solo puntúan las piezas legales (arma de caza y,
     si la especie es protegida, con licencia).

     Si el ganador no está conectado al terminar, el premio le espera en el
     campamento (pestaña Torneo). ]]
Config.Torneo = {
    activo = true,
    cadaHoras = 4,
    duracion = 30 * 60,
    avisosAntes = { 10, 5, 1 },         -- minutos
    avisoFinal = 5,                      -- minutos antes del final
    minimoParaPremiar = 1,               -- piezas que hay que llevar para entrar en el podio

    modos = {
        { id = 'puntos',  nombre = 'Puntuación',      unidad = 'pts',    detalle = 'Cada pieza suma según la especie y su calidad' },
        { id = 'piezas',  nombre = 'Más piezas',      unidad = 'piezas', detalle = 'Gana quien despelleje más animales' },
        { id = 'calidad', nombre = 'Piel perfecta',   unidad = 'pieles', detalle = 'Solo cuentan las pieles de tres estrellas' },
        { id = 'especie', nombre = 'Especie objetivo', unidad = 'piezas', detalle = 'Solo cuenta la especie sorteada' },
    },

    -- Especies que pueden salir de objetivo (tienen que poder salirle a un novato
    -- o el torneo se queda sin gente).
    objetivos = { 'ciervo', 'conejo', 'liebre' },

    -- Puntos por especie en la modalidad «Puntuación», antes de la calidad.
    puntos = { conejo = 10, liebre = 12, ciervo = 25, coyote = 30, jabali = 40, puma = 70, ciervo_albino = 200, puma_sombra = 300 },
    -- Multiplicador por estrellas.
    puntosCalidad = { 0.5, 1.0, 1.5 },

    premios = {
        { dinero = 6000, xp = 500 },
        { dinero = 3000, xp = 250 },
        { dinero = 1500, xp = 120 },
    },

    --[[ Inscripción. Con precio > 0 solo compite quien paga, y lo pagado va
         al bote: el premio de cada puesto es su base + su parte del bote. La
         inscripción abre `abreAntes` minutos antes y sigue abierta durante el
         torneo. Si al empezar hay menos de `minimoInscritos`, se cancela y se
         devuelve todo. ]]
    inscripcion = 500,
    abreAntes = 30,
    minimoInscritos = 2,
    reparto = { 0.5, 0.3, 0.2 },
    comision = 0.0,          -- parte del bote que se queda la casa (0 a 0.5)

    --[[ La Gran Cacería: una vez por semana, más larga y con más premio. Se
         anuncia a todo el servidor con días de antelación. Los torneos
         normales que caerían encima se saltan. ]]
    semanal = {
        activo = true,
        nombre = 'Gran Cacería',
        dia = 7,               -- 1 domingo, 2 lunes … 7 sábado
        hora = 21,
        minuto = 0,
        duracion = 60 * 60,
        modo = 'puntos',
        inscripcion = 2500,
        avisosAntes = { 1440, 180, 60, 10, 5, 1 },   -- minutos
        premios = {
            { dinero = 30000, xp = 2000 },
            { dinero = 15000, xp = 1000 },
            { dinero = 7500, xp = 500 },
        },
    },
}

--[[ ── Partidas de caza en grupo ────────────────────────────────────────────
     Se invita por id. Lo que un miembro vende en el campamento se reparte a
     partes iguales entre los que tienen la jornada en marcha, y las piezas de
     cualquiera del grupo las pueden tocar todos desde el primer momento.

     Los encargos de grupo son los mismos para todo el servidor cada día; los
     cumple el grupo entre todos y se cobran una vez por personaje y día. ]]
Config.Grupos = {
    maximo = 4,
    invitacionDura = 30,     -- s para aceptar
    encargosPorDia = 2,
    lista = {
        { id = 'g_ciervos',  tipo = 'abatir', especie = 'ciervo', n = 6,  pago = 1400, xp = 220, texto = 'El grupo abate %d ciervos' },
        { id = 'g_jabalies', tipo = 'abatir', especie = 'jabali', n = 4,  pago = 1800, xp = 280, texto = 'El grupo abate %d jabalíes' },
        { id = 'g_piezas',   tipo = 'piezas',                     n = 12, pago = 1600, xp = 250, texto = 'El grupo consigue %d piezas' },
        { id = 'g_perfecta', tipo = 'calidad', calidad = 3,       n = 5,  pago = 2000, xp = 320, texto = 'El grupo consigue %d pieles perfectas' },
        { id = 'g_enteros',  tipo = 'entregar',                   n = 4,  pago = 1900, xp = 300, texto = 'El grupo entrega %d animales enteros' },
    },
}

--[[ ── Vigilancia para el staff ─────────────────────────────────────────────
     Todo movimiento de dinero y cada pieza quedan apuntados. Quien pase de
     estos umbrales en una hora sale marcado en el panel de admin y se avisa
     al staff conectado (una vez por hora por jugador). ]]
Config.Vigilancia = {
    piezasPorHora = 30,
    dineroPorHora = 25000,
    diasRegistro = 30,
    permiso = 'origen_hunting',    -- el de origen_admin
}
