-- =============================================
-- origen_anticheat — Client: Detección de Spectate no autorizado
-- =============================================

local wasSpectating = false

function CheckSpectate()
    if not Config.Modules.Spectate.enabled then return end

    local inSpectate = NetworkIsInSpectatorMode()

    -- Reportar sólo al entrar en spectate (cambio de estado)
    if inSpectate and not wasSpectating then
        ReportViolation(
            AC.Modules.Spectate,
            'Jugador entró en modo spectate sin permiso de admin'
        )
    end

    wasSpectating = inSpectate
end
