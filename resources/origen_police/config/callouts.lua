-- ============================================================
-- ORIGEN POLICE — CONFIGURACIÓN DE CALLOUTS ALEATORIOS CON NPC
-- ============================================================

Config.Callouts = {}

-- Estado global del sistema de callouts aleatorios (se puede cambiar dinámicamente desde el panel admin)
Config.Callouts.Enabled = true

-- Número mínimo de policías de servicio requeridos para que se activen los avisos aleatorios
Config.Callouts.MinPolice = 1

-- Intervalo de tiempo aleatorio entre callouts (en segundos)
Config.Callouts.IntervalMin = 300 -- 5 minutos
Config.Callouts.IntervalMax = 600 -- 10 minutos

-- Tiempo máximo que dura una llamada sin atender antes de expirar (en segundos: 2400 = 40 minutos)
Config.Callouts.CalloutTimeout = 2400 -- 40 minutos

-- Distancia máxima a la que los policías se pueden alejar del evento antes de limpiar los NPCs (en metros)
Config.Callouts.AutoDespawnDistance = 350.0

-- Recompensa opcional para el oficial al resolver el callout
Config.Callouts.Reward = {
    enabled = true,
    cashMin = 300,
    cashMax = 800,
    xp = 50
}

-- ─── ESCENARIOS DE CALLOUTS ───────────────────────────────────
Config.Callouts.Scenarios = {
    FleeingSuspect = {
        name = "FleeingSuspect",
        title = "Sujeto a la fuga",
        code = "10-80",
        type = "Persecución",
        message = "Un vehículo sospechoso se niega a detenerse y huye a gran velocidad.",
        pedModels = {"a_m_m_skater_01", "g_m_y_ballaeast_01", "a_m_y_runner_01", "g_m_y_famca_01"},
        vehicles = {"sultan", "blista", "oracle", "felon", "dominator", "futo"},
        isVehicle = true,
        pedCount = 1,
        behavior = "flee_vehicle"
    },
    KnifeThreat = {
        name = "KnifeThreat",
        title = "Persona armada con cuchillo",
        code = "10-14",
        type = "Asalto",
        message = "Individuo alterado empuñando un arma blanca y amenazando a los transeúntes.",
        pedModels = {"a_m_m_hillbilly_01", "g_m_y_lost_01", "a_m_y_beach_01", "g_m_y_mexgoon_01"},
        weapon = "WEAPON_KNIFE",
        isVehicle = false,
        pedCount = 1,
        behavior = "hostile_melee"
    },
    ArmedShooter = {
        name = "ArmedShooter",
        title = "Sospechoso armado",
        code = "10-99",
        type = "Tiroteo",
        message = "Sujeto armado reportado haciendo disparos en la vía pública.",
        pedModels = {"g_m_y_mexgoon_01", "g_m_y_strpunk_01", "g_m_y_salva_01", "g_m_y_korean_01"},
        weapon = "WEAPON_PISTOL",
        isVehicle = false,
        pedCount = 1,
        behavior = "hostile_firearm"
    },
    StreetFight = {
        name = "StreetFight",
        title = "Pelea en la vía pública",
        code = "10-15",
        type = "Asalto",
        message = "Dos individuos implicados en una violenta riña callejera.",
        pedModels = {"a_m_m_tramp_01", "a_m_y_downtown_01", "g_m_y_purotango_01", "a_m_m_soucent_01"},
        isVehicle = false,
        isFight = true,
        pedCount = 2,
        behavior = "brawl"
    },
    DrunkDriver = {
        name = "DrunkDriver",
        title = "Conductor errático / ebrio",
        code = "10-55",
        type = "Accidente",
        message = "Vehículo realizando maniobras temerarias e invadiendo el carril contrario.",
        pedModels = {"a_m_m_farmer_01", "a_m_y_latino_01", "a_m_m_malibu_01"},
        vehicles = {"blista", "voodoo", "emperor", "ingot", "tornado"},
        isVehicle = true,
        isDrunk = true,
        pedCount = 1,
        behavior = "drunk_driver"
    },
    GangShootout = {
        name = "GangShootout",
        title = "Tiroteo entre bandas",
        code = "10-71",
        type = "Tiroteo",
        message = "Disparos continuos reportados entre dos grupos fuertemente armados.",
        pedModels = {"g_m_y_ballaeast_01", "g_m_y_famca_01", "g_m_y_ballaorig_01", "g_m_y_famdnf_01"},
        weapon = "WEAPON_MICROSMG",
        isVehicle = false,
        pedCount = 4,
        behavior = "gang_war"
    },
    ArmedRobbery = {
        name = "ArmedRobbery",
        title = "Atraco a mano armada",
        code = "10-90",
        type = "Robo",
        message = "Sujetos armados reportados asaltando a transeúntes y vehículos en la zona.",
        pedModels = {"g_m_m_chicold_01", "g_m_y_salvagoon_01"},
        vehicles = {"felon", "oracle"},
        weapon = "WEAPON_PISTOL",
        isVehicle = true,
        pedCount = 2,
        behavior = "hostile_firearm"
    }
}

-- ─── UBICACIONES PREDEFINIDAS DE CALLOUTS ────────────────────
Config.Callouts.Locations = {
    {
        coords = vector3(215.12, -810.45, 30.73),
        heading = 160.0,
        street = "Legion Square, Alta St",
        zone = "Los Santos"
    },
    {
        coords = vector3(-342.15, -135.80, 39.01),
        heading = 240.0,
        street = "Eclipse Blvd, Rockford Hills",
        zone = "Los Santos"
    },
    {
        coords = vector3(425.10, -979.55, 30.71),
        heading = 90.0,
        street = "Atlee St, Mission Row",
        zone = "Los Santos"
    },
    {
        coords = vector3(116.20, -1300.80, 29.15),
        heading = 205.0,
        street = "Carson Ave, Strawberry",
        zone = "Los Santos"
    },
    {
        coords = vector3(-1182.40, -884.20, 13.80),
        heading = 330.0,
        street = "Vespucci Blvd, Vespucci",
        zone = "Los Santos"
    },
    {
        coords = vector3(310.80, 180.50, 103.50),
        heading = 110.0,
        street = "Meteor St, Downtown Vinewood",
        zone = "Los Santos"
    },
    {
        coords = vector3(1974.15, 3816.90, 32.40),
        heading = 210.0,
        street = "Alhambra Drive, Sandy Shores",
        zone = "Blaine County"
    },
    {
        coords = vector3(-110.50, 6462.10, 31.60),
        heading = 45.0,
        street = "Paleto Blvd, Paleto Bay",
        zone = "Blaine County"
    },
    {
        coords = vector3(1190.20, 2710.60, 38.10),
        heading = 180.0,
        street = "Route 68, Harmony",
        zone = "Blaine County"
    },
    {
        coords = vector3(-218.40, -1360.10, 31.25),
        heading = 90.0,
        street = "MacFarlane St, Davis",
        zone = "Los Santos"
    }
}
