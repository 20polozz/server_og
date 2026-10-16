-- =============================================
-- origen_anticheat — Client: Helper de reporte
-- =============================================

-- Rate-limit client-side: no reportar el mismo módulo más de 1 vez cada N ms
local clientRateLimit = {}
local CLIENT_RATE_MS = 8000

local function IsClientRateLimited(module)
    local now = GetGameTimer()
    if clientRateLimit[module] and (now - clientRateLimit[module]) < CLIENT_RATE_MS then
        return true
    end
    clientRateLimit[module] = now
    return false
end

---Reporta una violación al servidor
---@param module string
---@param description string
function ReportViolation(module, description)
    -- Verificar módulo habilitado en config
    local moduleConfig = Config.Modules[module]
    if not moduleConfig or not moduleConfig.enabled then return end

    -- Si la exención de admins está activa y el jugador tiene el permiso,
    -- el servidor decidirá ignorar el reporte. No bloqueamos aquí en cliente
    -- para no depender de datos del cliente (el servidor es quien valida).

    -- Rate limit client (reduce tráfico de red)
    if IsClientRateLimited(module) then return end

    if Config.Debug then
        print(string.format('^3[AC CLIENT DEBUG]^0 Módulo: %s | %s', module, description))
    end

    TriggerServerEvent('ac:server:reportViolation', module, description)
end

-- Recibir alerta de admin (para mostrar notificación al staff online)
RegisterNetEvent('ac:client:adminAlert', function(data)
    if not Config.NotifyAdmins then return end
    if not data then return end
    -- Usar origen_notify si está disponible
    local ok = pcall(function()
        TriggerEvent('origen_notify:client:Notify', 'warning', '⚠️ Anticheat',
            string.format('[%s] %s — %s', data.module or '?', data.victimName or '?', data.description or '?'))
    end)
    if not ok then
        -- Fallback: print en consola F8
        print(string.format('^1[ANTICHEAT ALERT]^0 %s (ID:%s) | %s: %s',
            data.victimName, data.victimId, data.module, data.description))
    end
end)
