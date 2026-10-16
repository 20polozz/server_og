--[[ ── Origen Games · la configuración común ────────────────────────────────

     Lo que comparten todos los juegos. Cada juego tiene además su fichero
     (config/<juego>.lua) que se engancha a Config.Juegos.

     Las zonas donde se juega y el punto del mapa de cada juego NO están aquí:
     los pone el staff desde el menú y viven en la base de datos. Lo que hay
     aquí de puntos y zonas es solo lo de partida. ]]

Config = {}

--- El permiso de origen_admin que deja gestionar zonas y puntos.
Config.Permiso = 'origen_games'

--- El orden en el que salen los juegos donde se listan todos.
Config.Orden = { 'escondite', 'patata', 'colina', 'derbi', 'impostor', 'paintball', 'karts' }

--- Cada config/<juego>.lua añade aquí su entrada.
Config.Juegos = {}

--[[ El punto de cada juego puede ser de tres tipos, y lo elige el staff desde
     la gestión:

       marcador    el aro rosa en el suelo con su flecha
       npc         un personaje quieto con el modelo y la animación que se
                   elijan
       recreativa  una máquina recreativa. El staff se pone donde va a estar
                   el jugador, mirando hacia donde irá la máquina. Al empezar
                   la partida, quien estaba en ella se «mete» dentro.

     Todos se ven en los dos mapas con el dibujo de su juego (`iconoMapa`). ]]
Config.Punto = {
    color = '#d81b55',
    npc = {
        modeloDefecto = 'a_m_y_business_03',
        -- Sugerencias en la gestión; se puede escribir cualquier otro.
        modelos = {
            { id = 'a_m_y_business_03', nombre = 'Ejecutivo' },
            { id = 'a_f_y_business_02', nombre = 'Ejecutiva' },
            { id = 'a_m_y_hipster_01', nombre = 'Hipster' },
            { id = 'a_f_y_hipster_02', nombre = 'Hipster (ella)' },
            { id = 'a_m_y_skater_01', nombre = 'Skater' },
            { id = 's_m_y_clown_01', nombre = 'Payaso' },
            { id = 'u_m_y_imporage', nombre = 'Friki' },
            { id = 's_m_m_bouncer_01', nombre = 'Portero' },
        },
        escenarios = {
            { id = 'quieto', nombre = 'De pie' },
            { id = 'WORLD_HUMAN_CLIPBOARD', nombre = 'Con carpeta' },
            { id = 'WORLD_HUMAN_STAND_MOBILE', nombre = 'Con el móvil' },
            { id = 'WORLD_HUMAN_SMOKING', nombre = 'Fumando' },
            { id = 'WORLD_HUMAN_AA_COFFEE', nombre = 'Con café' },
            { id = 'WORLD_HUMAN_GUARD_STAND', nombre = 'Vigilando' },
            { id = 'WORLD_HUMAN_CHEERING', nombre = 'Animando' },
        },
    },
    recreativa = {
        modeloDefecto = 'ch_prop_arcade_invade_01a',
        modelos = {
            { id = 'ch_prop_arcade_invade_01a', nombre = 'Invade and Persuade' },
            { id = 'ch_prop_arcade_space_01a', nombre = 'Space Monkey' },
            { id = 'ch_prop_arcade_wizard_01a', nombre = 'Wizard' },
            { id = 'ch_prop_arcade_street_01a', nombre = 'Street Crimes' },
            { id = 'ch_prop_arcade_degenatron_01a', nombre = 'Degenatron' },
            { id = 'ch_prop_arcade_race_01a', nombre = 'Carreras' },
            { id = 'prop_arcade_01', nombre = 'Clásica' },
        },
        -- La máquina queda a esta distancia delante de donde se puso el staff.
        distancia = 1.0,
    },
}

--- A cuánto se puede estar del punto de un juego para crear o unirse a una
--- sala. Lo comprueba el servidor.
Config.AlcancePunto = 8.0

Config.Sala = {
    nombreMin = 3,
    nombreMax = 24,
}

--- Las apuestas. Cada jugador paga la entrada del banco al unirse; si la sala
--- se deshace antes de empezar, se devuelve. El bote se lo lleva quien más
--- puntos haga al final (si empatan, se reparte).
Config.Apuesta = {
    cuenta = 'bank',
    maxima = 50000,
    rapidas = { 0, 500, 2500, 10000 },
    -- Lo que se queda la casa del bote, en tanto por ciento. 0 = nada.
    comision = 0,
}

--- Tiempos comunes a todos los juegos.
Config.Tiempos = {
    preparacion = 8,      -- de la carga de la ronda a que empiece de verdad (con la entrada en la recreativa)
    finRonda = 9,         -- el marcador entre rondas
    final = 12,           -- el marcador final antes de volver
}

--- Salirse de la zona: aviso y cuenta atrás. Lo que pasa al acabar lo decide
--- cada juego (eliminar o devolver al centro).
Config.Zona = { aviso = 5, margen = 1.5 }

--- Teclas comunes. Son controles de GTA, no teclas del teclado.
Config.Teclas = {
    abandonar = { control = 23, texto = 'F' },   -- mantener
    anterior = { control = 174, texto = '←' },   -- mirando: cambiar a quién
    siguiente = { control = 175, texto = '→' },
}

Config.MantenerParaSalir = 3000

--- Los límites de lo que el staff puede poner en cualquier zona. Cada juego
--- añade los suyos propios (config/<juego>.lua, campo `campos`).
Config.ZonaLimites = { radioMin = 15, radioMax = 250, radioDefecto = 60 }
