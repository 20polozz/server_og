--[[ ── La pestaña ESPECTAR ─────────────────────────────────────────────

     Dos cosas en la misma pestaña, las dos con el permiso de observar
     (AdminMenu:Spectate):

       - PANTALLAS: la imagen del juego de un jugador, en vivo. Viaja por
         WebRTC de su interfaz a la tuya; el servidor solo presenta a los
         dos (antes blackvertex_screens).

       - REPETICION: cada cliente guarda los ultimos segundos de lo que pasa
         a su alrededor. Se le pide, llega al staff y se reproduce con
         actores en su propio mundo (antes pr_screens). ]]

Config.Pantallas = {
    -- Pantallas abiertas a la vez por cada staff. Cada una es un video que
    -- tu cliente decodifica: con nueve a 540p un equipo normal va holgado.
    MaxPorStaff = 9,
    -- Staff mirando al mismo jugador a la vez. Cada uno le cuesta a ESE
    -- jugador otra codificacion y otra subida.
    MaxPorJugador = 3,
    -- Poder abrir la tuya. Sirve para probar con el servidor vacio.
    VerseASiMismo = true,
    -- Avisar al jugador de que le estan mirando.
    AvisarAlJugador = false,

    Calidad = {
        fps = 24,
        ancho = 960,
        alto = 540,
        kbps = 900,
    },
}

Config.Repeticion = {
    -- Grabacion en cada cliente
    grabarSiempre = true,
    captureRate = 6,          -- fotos por segundo
    bufferSeconds = 1200,     -- lo que se guarda hacia atras (20 minutos)
    captureRadius = 100.0,    -- jugadores que entran en la foto
    recordNpcs = false,
    npcRadius = 30.0,

    -- Peticiones
    transmitRate = 6,
    segundosPosibles = { 30, 60, 120, 180, 300, 600, 1200 },
    maxSegundos = 1200,
    esperaMs = 120000,        -- lo que se espera a que llegue el clip (2 minutos para clips largos)
    ritmoMs = 3000,           -- entre dos peticiones del mismo staff
    clipsGuardados = 6,       -- los que se quedan listos para ver en tu cliente

    -- Reproduccion
    useBucket = true,
    bucketBase = 9000,

    maxFrames = 0,            -- se calcula abajo
    maxEvents = 2000,

    aimRayLength = 60.0,
    tracerWindow = 220,
    eventFeedSize = 6,
    eventHighlightWindow = 1200,

    playbackSpeeds = { 0.1, 0.25, 0.5, 1.0, 2.0, 4.0 },
    defaultSpeedIndex = 4,

    camera = {
        baseSpeed = 0.35,
        fastMultiplier = 4.0,
        slowMultiplier = 0.25,
        sensitivity = 6.0,
        orbitDistance = 4.5,
    },

    keys = {
        togglePause = 22,     -- espacio
        speedDown = 174,
        speedUp = 175,
        stepBack = 173,
        stepForward = 172,
        -- Retroceso, el mismo que sale del espectar de siempre.
        exit = 194,
        -- Escape tambien sale: mientras dura la repeticion el radial no se abre
        -- (origen_hud mira LocalPlayer.state.enRepeticion).
        exitAlt = 200,
        toggleCamera = 47,    -- G
        cycleTarget = 246,    -- Y
        prevEvent = 20,       -- Z
        nextEvent = 73,       -- X
        toggleTracers = 182,  -- L
        -- G, Y y L y no E, TAB y F: esas tres las tienen otros recursos en
        -- RegisterKeyMapping, que salta aunque los controles esten apagados.
        forward = 32,
        back = 33,
        left = 34,
        right = 35,
        up = 44,
        down = 46,
        fast = 21,
        slow = 36,
    },
}
Config.Repeticion.maxFrames = Config.Repeticion.captureRate * Config.Repeticion.bufferSeconds
