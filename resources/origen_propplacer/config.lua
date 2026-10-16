Config = {}

-- 'es' | 'en'
Config.Locale = 'es'

-- ESX admin groups
Config.AdminGroups = { "admin", "superadmin" }

-- QBCore / QBX admin groups (PlayerData.group)
Config.QBAdminGroups = { "god", "admin" }

Config.DeleteRadius            = 5.0
Config.DefaultStep             = 0.05
Config.SnapAngle               = 45.0
Config.PlacementDefaultDist    = 15.0
Config.PlacementMinDistance    = 2.0
Config.PlacementMaxDistance    = 100.0
Config.PlacementScrollStep     = 1.0

Config.StreamRange    = 120.0
Config.StreamInterval = 750
Config.StreamLogs     = false

Config.PlaceCooldownMs  = 500
Config.BatchCooldownMs  = 2000
Config.MaxImportBatch   = 500

Config.MaxPropsPerCategory = 0

Config.BackupInterval = 0
Config.MaxBackups     = 5

Config.Props = {}

-- La misma paleta que el panel (AdminPanel.vue): rosa de la casa y tonos
-- apagados que se distinguen sobre el gris, sin neones.
Config.CategoryColorPalette = {
    "#d81b55", "#e0782b", "#d9a521", "#2f9a63", "#1f8a8a",
    "#2f6fd0", "#6b55c9", "#a8379a", "#7a5a3c", "#5a5d63",
}
