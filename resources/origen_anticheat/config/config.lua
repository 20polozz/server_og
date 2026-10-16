-- =============================================
-- origen_anticheat — Configuración principal
-- =============================================

Config = Config or {}

-- -----------------------------------------------
-- DEBUG: en true loguea en consola sin tomar acción
-- -----------------------------------------------
Config.Debug = false

-- -----------------------------------------------
-- Notificaciones en juego para administradores (origen_notify)
-- false: desactiva los avisos flotantes de anticheat en pantalla
-- true: muestra las notificaciones a los administradores online
-- -----------------------------------------------
Config.NotifyAdmins = false

-- -----------------------------------------------
-- Módulos activos y su acción por defecto
-- Acción: 'warn' → solo alerta Discord + log
-- -----------------------------------------------
Config.Modules = {
    GodMode      = { enabled = true,  action = 'warn' },
    NoClip       = { enabled = true,  action = 'warn' },
    Spectate     = { enabled = true,  action = 'warn' },
    Weapons      = { enabled = true,  action = 'warn' },
    VehicleSpeed = { enabled = true,  action = 'warn' },
    Explosion    = { enabled = true,  action = 'warn' },
    VehicleSpawn = { enabled = true,  action = 'warn' },
    -- Objetos creados en rafaga (los pilones gigantes del 13/10). Se cortan
    -- siempre; `action` solo dice si ademas se expulsa: 'warn' o 'kick'.
    ObjectSpawn  = { enabled = true,  action = 'warn' },
}

-- -----------------------------------------------
-- Los admins con este permiso están exentos de todos los checks
-- -----------------------------------------------
Config.AdminExemptPermission = 'Anticheat:Exempt'

-- -----------------------------------------------
-- Intervalos de check (milisegundos)
-- -----------------------------------------------
Config.CheckIntervalMs       = 3000  -- Loop client-side
Config.ServerCheckIntervalMs = 6000  -- Loop server-side (velocidad/posición)

-- -----------------------------------------------
-- Umbrales de detección
-- -----------------------------------------------
Config.Thresholds = {
    -- Velocidad máxima del ped en noclip (m/s, ~72 km/h)
    NoclipVerticalSpeed   = 8.0,
    NoclipMinGroundHeight = 3.5,   -- Altura mínima sobre el suelo para detectar

    -- Velocidad máxima de vehículo (m/s). 100 m/s ≈ 360 km/h
    VehicleMaxSpeed       = 100.0,

    -- Explosiones máximas por jugador por minuto (sin job autorizado)
    ExplosionMaxPerMin    = 1,

    -- Vehículos máximos spawneados por un jugador en 1 minuto
    VehicleSpawnsMaxPerMin = 30,

    --[[ Rafagas: cuantas cosas puede crear UN jugador en `RafagaVentanaMs`.
         Al pasarse se le cancela todo lo que intente crear durante
         `RafagaBloqueoMs` y se borra lo que acabara de poner. Un jugador
         normal crea de una en una (sacar el coche, colocar un mueble). ]]
    RafagaVentanaMs   = 10000,
    RafagaBloqueoMs   = 120000,
    RafagaVehiculos   = 8,
    RafagaObjetos     = 20,

    -- Distancia máxima entre ticks de servidor (metros) para detección de teleport
    TeleportMaxDelta      = 300.0,

    -- Tiempo de gracia tras spawn/cambio de dimensión para ignorar teleport (ms)
    TeleportGraceMs       = 8000,
}

-- -----------------------------------------------
-- Lista blanca de objetos (server/listablanca.lua)
-- -----------------------------------------------
Config.ListaBlanca = {
    -- Modo al arrancar por primera vez: 'aprender', 'cortar' o 'apagado'.
    -- Despues manda lo ultimo que se puso con `aclista modo ...`.
    Modo = 'aprender',
    -- Aprendiendo, cuantos jugadores distintos tienen que haber creado un
    -- modelo para darlo por bueno sin que lo apruebe nadie.
    JugadoresParaFiar = 5,
    GuardarCadaMs = 60000,
}

-- -----------------------------------------------
-- Armas que NO deberían estar en un servidor RP normal
-- -----------------------------------------------
Config.WeaponBlacklist = {
    'WEAPON_MINIGUN',
    'WEAPON_RPG',
    'WEAPON_RAILGUN',
    'WEAPON_FIREWORK',
    'WEAPON_EMPLAUNCHER',
    'WEAPON_BZGAS',
    'WEAPON_RAYPISTOL',
    'WEAPON_RAYCARBINE',
    'WEAPON_RAYMINIGUN',
}

-- -----------------------------------------------
-- Jobs que tienen permiso de usar ciertas armas
-- (exención de blacklist de armas)
-- -----------------------------------------------
Config.WeaponWhitelistJobs = {
    -- 'police', 'army',  -- añade aquí los jobs que pueden tener armas especiales
}

-- -----------------------------------------------
-- Webhook de Discord para el anticheat
-- Añade tu URL aquí — se gestiona desde origen_admin
-- -----------------------------------------------
Config.DiscordWebhookKey = 'AnticheatAlert'   -- Clave en Config.Logs de origen_admin
