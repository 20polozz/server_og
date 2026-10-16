-- =============================================
-- origen_anticheat — Client: Detección de Godmode
-- =============================================

local lastGodmodeState = false

function CheckGodMode()
    if not Config.Modules.GodMode.enabled then return end

    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then return end

    -- Ignorar si el jugador está muerto o abatido
    if IsEntityDead(ped) or IsPedDeadOrDying(ped, true) or LocalPlayer.state.isDead or LocalPlayer.state.isdead or LocalPlayer.state.inLastStand or LocalPlayer.state.inlaststand then
        return
    end

    -- GetPlayerInvincible es la nativa correcta en FiveM para el jugador local
    local invincible = GetPlayerInvincible(PlayerId())

    -- Sólo reportar cuando cambia de falso → true (evita spam)
    if invincible and not lastGodmodeState then
        ReportViolation(AC.Modules.GodMode, 'Godmode activo detectado en el jugador')
    end

    lastGodmodeState = invincible
end

