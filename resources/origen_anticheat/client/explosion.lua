-- =============================================
-- origen_anticheat — Client: Detección de Explosiones
-- =============================================

-- Contador de explosiones por ventana de tiempo
local explosionCount = 0
local windowStart = GetGameTimer()
local WINDOW_MS = 60000  -- ventana de 1 minuto

-- Enganchar el evento de explosión nativo
AddEventHandler('gameEventTriggered', function(eventName, args)
    if eventName ~= 'CEventExplosion' then return end

    -- Actualizar ventana de tiempo
    local now = GetGameTimer()
    if now - windowStart > WINDOW_MS then
        explosionCount = 0
        windowStart    = now
    end

    explosionCount = explosionCount + 1

    if Config.Modules.Explosion.enabled and explosionCount > Config.Thresholds.ExplosionMaxPerMin then
        ReportViolation(
            AC.Modules.Explosion,
            string.format('Explosiones excesivas: %d en el último minuto', explosionCount)
        )
        -- Resetear para no spamear después del reporte
        explosionCount = 0
        windowStart    = now
    end
end)

-- Stub vacío requerido por main loop
function CheckExplosion()
    -- La detección se hace via AddEventHandler arriba
end
