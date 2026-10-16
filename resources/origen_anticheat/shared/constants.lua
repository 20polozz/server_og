-- =============================================
-- origen_anticheat — Constantes compartidas
-- =============================================

AC = AC or {}

-- Módulos disponibles
AC.Modules = {
    GodMode      = 'GodMode',
    NoClip       = 'NoClip',
    Spectate     = 'Spectate',
    Weapons      = 'Weapons',
    VehicleSpeed = 'VehicleSpeed',
    Explosion    = 'Explosion',
    VehicleSpawn = 'VehicleSpawn',
    ObjectSpawn  = 'ObjectSpawn',
}

-- Acciones disponibles
AC.Actions = {
    Warn   = 'warn',
    Kick   = 'kick',
    Ban    = 'ban',
}

-- Severidades para Discord embed
AC.Severity = {
    Low    = { label = '🟡 BAJA',   color = 0xEAB308 },
    Medium = { label = '🟠 MEDIA',  color = 0xF97316 },
    High   = { label = '🔴 ALTA',   color = 0xEF4444 },
    Info   = { label = '🔵 INFO',   color = 0x3B82F6 },
}

-- Mapa módulo → severidad
AC.ModuleSeverity = {
    [AC.Modules.GodMode]      = AC.Severity.High,
    [AC.Modules.NoClip]       = AC.Severity.High,
    [AC.Modules.Spectate]     = AC.Severity.Medium,
    [AC.Modules.Weapons]      = AC.Severity.High,
    [AC.Modules.VehicleSpeed] = AC.Severity.Low,
    [AC.Modules.Explosion]    = AC.Severity.High,
    [AC.Modules.VehicleSpawn] = AC.Severity.High,
    [AC.Modules.ObjectSpawn]  = AC.Severity.High,
}
