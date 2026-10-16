--[[
    Habilidades del personaje.

    Existian en la pantalla de estadisticas pero nadie las medía: seis de las
    diez estaban fijadas a cero en el codigo, y el jugador veia seis barras
    vacias como si fuera culpa suya. Esto lleva la cuenta de verdad.

    Cada habilidad es un CONTADOR de algo que pasa en el mundo, y el porcentaje
    sale de compararlo con un techo. El techo es lo que se considera dominar
    esa habilidad; subirlo hace que cueste mas llegar al 100 %.
]]

Config = {}

--- Cada cuanto se guarda en la base lo acumulado. Guardar en cada evento
--- seria una escritura por cada ganzua; con esto son unas pocas por sesion.
Config.GuardarCada = 60000   -- ms

Config.Habilidades = {
    conduccion = {
        etiqueta = 'Conducción',
        de = 'Al volante',
        -- Se mide en kilometros conducidos, no en tiempo: quedarse parado con
        -- el motor encendido no enseña a conducir.
        unidad = 'km',
        techo = 500,
        xp = 1,      -- por unidad
    },
    pilotaje = {
        etiqueta = 'Pilotaje',
        de = 'En vuelo',
        unidad = 'km',
        techo = 150,
        xp = 3,
    },
    mecanica = {
        etiqueta = 'Mecánica',
        de = 'Reparaciones',
        unidad = 'reparaciones',
        techo = 200,
        xp = 10,
    },
    hackeo = {
        etiqueta = 'Hackeo',
        de = 'Minijuegos',
        unidad = 'hackeos',
        techo = 120,
        xp = 15,
    },
    ganzua = {
        etiqueta = 'Ganzúa',
        de = 'Cerraduras',
        unidad = 'cerraduras',
        techo = 200,
        xp = 8,
    },
    robo = {
        etiqueta = 'Robo',
        de = 'Golpes',
        unidad = 'golpes',
        techo = 80,
        xp = 25,
    },

    --[[ Las misiones de origen_quests. A diferencia del resto no cuenta
         acciones sino la experiencia que da cada mision: una mision larga
         enseña mas que cinco recados, y contarlas por unidades las igualaria.
         Por eso el techo va en experiencia y no en numero de misiones. ]]
    misiones = {
        etiqueta = 'Misiones',
        de = 'Encargos',
        unidad = 'exp',
        techo = 2000,
        xp = 1,
    },
}

--[[ Que minijuego cuenta como que.

     Todos los minijuegos del servidor pasan por origen_minijuegos, que avisa
     del resultado con el nombre del juego. Enganchar ahi cubre de una vez
     todos los recursos que los usen, en vez de perseguirlos uno a uno. ]]
Config.Minijuegos = {
    lockpick      = 'ganzua',
    hacking       = 'hackeo',
    codebreaker   = 'hackeo',
    wirepuzzle    = 'hackeo',
    varhack       = 'hackeo',
    powergrid     = 'hackeo',
    minesweeper   = 'hackeo',
    timingcircles = 'hackeo',
    -- Los ocho nuevos (config_nuevos.lua de origen_minijuegos): lo de manos
    -- enseña ganzua; lo de pantallas, hackeo.
    ganzua        = 'ganzua',
    pines         = 'ganzua',
    dial          = 'ganzua',
    taladro       = 'ganzua',
    corte         = 'ganzua',
    huella        = 'hackeo',
    clave         = 'hackeo',
    senal         = 'hackeo',
    boveda        = 'ganzua',
    termita       = 'ganzua',
    soplete       = 'ganzua',
    laser         = 'hackeo',
    tunel         = 'hackeo',
    circuito      = 'hackeo',
    ritmo         = 'hackeo',
    inyeccion     = 'hackeo',
}

--[[ Niveles.

     Cada nivel cuesta un escalon mas que el anterior: el 2 pide 300, el 3
     otros 600, el 4 otros 900. Asi los primeros llegan rapido —que es cuando
     hace falta ver que avanzas— y los altos se notan. ]]
Config.XpPorNivel = 300
Config.NivelMaximo = 60
