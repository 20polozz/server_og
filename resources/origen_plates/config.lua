Config = {}

-- ── Items ──────────────────────────────────────────────────────────────────────
-- Registra estos items en tu inventario (ox_inventory/data/items.lua):
--
-- ['matricula_personalizada'] = { label = 'Matrícula Personalizada', weight = 50, stack = true, close = true }
-- ['matricula_falsa']         = { label = 'Matrícula Falsa',         weight = 50, stack = true, close = true }

Config.Items = {
    custom = 'matricula_personalizada',
    fake   = 'matricula_falsa',
}

-- ── Matrícula personalizada ───────────────────────────────────────────────────
Config.Plate = {
    MinLength = 1,
    MaxLength = 8,
    -- Caracteres permitidos: letras A-Z, dígitos 0-9, espacio, guion
    AllowedPattern = '^[A-Z0-9 %-]+$',
}

-- ── Matrícula falsa ───────────────────────────────────────────────────────────
Config.FakePlate = {
    -- Formato generado: 3 letras + 4 dígitos, ej: KTZ4829
    Letters = 'ABCDEFGHJKLMNPRSTUVWXYZ',
    Digits  = '0123456789',
}

-- ── Base de datos ─────────────────────────────────────────────────────────────
-- Si true, al aplicar matrícula PERSONALIZADA se actualiza también player_vehicles.plate
-- (permite que el cambio persista en el garage de QBCore/QBX)
Config.UpdateVehicleRecord = true
Config.VehicleTable         = 'player_vehicles'   -- nombre de la tabla del garage
Config.VehiclePlateCol      = 'plate'              -- columna de la matrícula
Config.VehicleOwnerCol      = 'citizenid'          -- columna del propietario

-- ── Óxido Nitroso ─────────────────────────────────────────────────────────────
-- Teclas configurables en Ajustes → Controles → Asignaciones de teclas → ORIGEN Plates
Config.NOS = {
    -- ─ Carga y boost ─────────────────────────────────────────────────────────
    MaxCharge            = 100.0,  -- carga de una botella completa (%)
    DrainPerTick         = 0.5,    -- % NOS drenado por tick activo   (100ms → 5%/seg → botella ~20 seg)
    BoostMultBase        = 1.50,   -- potencia mínima del boost
    BoostMultCap         = 1.65,   -- potencia máxima del boost

    -- ─ Purga / Sobrecalentamiento ─────────────────────────────────────────────
    HeatPerTick          = 1.0,    -- % purga que sube por tick activo    (→ bloqueo en ~10 seg continuos)
    PurgeDrainPerTick    = 1.25,   -- % purga drenada al mantener tecla   (→ vacía en ~8 seg)
    PurgeNosdrainPerTick = 0.5,    -- % NOS extra quemado si purgamos con medidor ya en 0
    MaxTemp              = 100.0,  -- umbral de sobrecalentamiento / bloqueo NOS

    -- ─ Efectos de pantalla ───────────────────────────────────────────────────
    ScreenFxSpeedMph     = 60.0,   -- velocidad (mph) a partir de la cual activan blur + shake

    -- ─ Teclas por defecto (el jugador puede cambiarlas en Ajustes) ────────────
    DefaultKey           = 'LSHIFT',   -- Boost
    DefaultPurgeKey      = 'LMENU',    -- Purga manual (ventear vapor)
}

-- ── Antilag ──────────────────────────────────────────────────────────────────
Config.Antilag = {
    PlaySound = true,       -- ¿Reproducir sonido de petardeo en el escape? (true/false)
    ExplosionType = 61,     -- Tipo de explosión de GTA V. 61 es el estándar (Bike Poof)
    Volume = 0.1,           -- Volumen del sonido de petardeo (0.1 = mínimo, 1.0 = máximo).
}

-- ── Inventario ───────────────────────────────────────────────────────────────
-- Funciones de inventario usadas por el servidor (origen_inventory).

Config.Inventory = {
    HasItem = function(source, item)
        if GetResourceState('origen_inventory') == 'started' then
            local ok, result = pcall(function()
                local count = exports['origen_inventory']:getItem(source, item, nil, true)
                return type(count) == 'number' and count >= 1
            end)
            if ok then return result end
        end
        return false
    end,

    RemoveItem = function(source, item, count)
        count = count or 1
        if GetResourceState('origen_inventory') == 'started' then
            pcall(function()
                exports['origen_inventory']:removeItem(source, item, count)
            end)
            return true
        end
        return false
    end,
}
