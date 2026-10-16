Config.Debug = false

Config.Mileage = {
    TickMs = 1000,
    SyncThresholdKm = 0.25,
    --[[ Por debajo de un metro por segundo es temblor de fisica parado, no
         conduccion: sumarlo infla el cuentakilometros de un coche quieto. ]]
    MinDistance = 1.0,
    --[[ Mas de 300 m en un tick es un teleport (garaje, admin, respawn), no un
         trayecto. ]]
    MaxDistancePerTick = 300.0,
    MaxKmPerSync = 2.0
}

--- Multiplicador de intervalo de servicio por clase de vehículo.
Config.IntervalMultipliers = {
    [0] = 1.4,
    [1] = 1.2,
    [2] = 1.0,
    [3] = 1.1,
    [4] = 0.8,
    [5] = 0.7,
    [6] = 0.85,
    [7] = 0.75,
    [8] = 1.3,
    [9] = 0.6,
    [10] = 0.5,
    [11] = 0.6,
    [12] = 0.9,
    [17] = 0.6,
    [18] = 0.5,
    [19] = 0.4,
    [20] = 0.5,
    [22] = 0.3
}

Config.MultiplierClamp = { min = 0.1, max = 3.0 }

Config.DefaultVehicleClass = 2

--- 13 Bicicletas, 14 Barcos, 15 Helicópteros, 16 Aviones, 21 Trenes.
Config.UntrackableClasses = {
    [13] = true,
    [14] = true,
    [15] = true,
    [16] = true,
    [21] = true
}

--- Modelos excluidos del sistema, en minúsculas.
Config.BlacklistedModels = {}

Config.RandomState = {
    MileageRange = { 5000, 200000 },
    ServiceUsedRange = { 0.0, 0.9 },
    ComponentHealthRange = { 65, 100 }
}

Config.ComponentThresholds = {
    optimal = 51,
    worn = 21,
    critical = 1
}

Config.ServiceThresholds = {
    okRatio = 0.16
}

Config.Admin = {
    Permission = 'Comando:mecanica'
}

Config.RateLimit = {
    EnsureMs = 250,
    MileageSyncMs = 400,
    SaveMs = 1000,
    AdminMs = 500,
    KitRepairMs = 1000
}

--[[ Red de seguridad: el guardado en apagado depende de que el recurso llegue a
     terminar el handler. Un crash del servidor no da esa oportunidad. ]]
Config.AutosaveMinutes = 5

Config.History = {
    DefaultLimit = 25,
    MaxLimit = 100
}
