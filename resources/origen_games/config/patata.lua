--[[ ── Patata caliente · que no te explote en las manos ────────────────────── ]]

local P = {}

P.id = 'patata'
P.nombre = 'Patata caliente'
P.lema = 'Que no te explote en las manos'
P.icono = 'patata'
--- El dibujo de su chincheta en los dos mapas (origen_map e inventario).
P.iconoMapa = 'patata'

P.jugadoresMin = 3
P.jugadoresMax = 16
P.rondas = { 1, 3, 5 }
P.rondasDefecto = 3

P.modos = {
    { id = 'clasica', nombre = 'Clásica', texto = 'Una sola patata. Quien la lleve cuando explote, queda fuera.' },
    { id = 'doble', nombre = 'Doble', texto = 'Con seis o más jugadores hay dos patatas a la vez. Caos asegurado.' },
}

P.punto = { x = 201.6, y = -926.9, z = 30.69 }
P.zonaSemilla = { nombre = 'Plaza de la Legión', x = 195.17, y = -933.77, z = 29.7, radio = 40.0 }

P.campos = {
    { id = 'mechaMin', nombre = 'Mecha más corta', tipo = 'rango', min = 10, max = 60, paso = 5, defecto = 20, formato = 'segundos' },
    { id = 'mechaMax', nombre = 'Mecha más larga', tipo = 'rango', min = 15, max = 90, paso = 5, defecto = 35, formato = 'segundos' },
}

P.destacado = 'pases'

P.Juego = {
    alcancePase = 1.8,          -- metros para pasarla al tocar a alguien
    sinDevolucion = 2.5,        -- segundos en los que no se la puedes devolver a quien te la pasó
    alcanceLanzar = 9.0,        -- metros para lanzarla con la tecla
    enfriamientoLanzar = 12,    -- segundos entre lanzamientos
    velocidadPortador = 1.15,   -- quien la lleva corre un poco más
    avisoFinal = 5,             -- segundos finales en los que pita más rápido
    tiempoSeguridad = 900,      -- segundos: si nadie cae antes, ganan los que queden en pie
    pausaSalto = 3,             -- segundos entre una explosión y que la patata salte a otro
    alcanceMecha = 45.0,        -- metros a los que se oye el pitido de la mecha
    dobleDesde = 6,             -- vivos necesarios para que haya dos patatas en el modo doble
    retenerMinimo = 600,        -- ms que hay que llevarla antes de poder pasarla (evita rebotes por lag)
}

P.Puntos = {
    sobrevivirExplosion = 2,    -- a cada superviviente cuando explota una
    ganarRonda = 15,            -- el último en pie
    segundo = 6,                -- el penúltimo
    pase = 1,                   -- por pasarla (no cuenta devolverla)
    maxPasesRonda = 5,          -- tope de pases que puntúan por jugador y ronda
    parejaCada = 20,            -- segundos: entre la misma pareja (en cualquier sentido) solo puntúa un pase cada tanto
}

P.Teclas = {
    lanzar = { control = 38, texto = 'E' },
}

P.ayuda = {
    {
        titulo = 'Cómo va',
        texto = 'Alguien empieza con la patata. Tócale a otro para pasársela: basta con acercarte. La mecha es secreta y pita cada vez más rápido. Quien la lleve cuando explote queda fuera y la patata salta a otro. Gana el último en pie.',
    },
    {
        titulo = 'Teclas',
        teclas = {
            { tecla = 'E', texto = 'Lanzarla al jugador al que apuntes, a unos metros. Si falla, la sigues llevando.' },
        },
        nota = 'Quien la lleva corre un poco más. No se la puedes devolver a quien te la acaba de pasar.',
    },
    {
        titulo = 'Puntos',
        datos = { { k = 'Sobrevivir', v = '+2' }, { k = 'Ganar', v = '+15' }, { k = 'Pasarla', v = '+1' } },
    },
}

Config.Juegos.patata = P
