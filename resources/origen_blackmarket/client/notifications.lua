-- ========================================
-- SISTEMA DE NOTIFICACIONES DEL CLIENTE
-- ========================================

-- Función helper para notificar usando origen_notify
function Notify(message, type, duration)
    exports['origen_notify']:Notify({
        description = message,
        type = type or 'info',
        duration = duration or 5000
    })
end

-- Notificación con sonido
function NotifyWithSound(message, type, duration, sound)
    Notify(message, type, duration)
    
    if sound then
        PlaySoundFrontend(-1, sound.name or "CHECKPOINT_PERFECT", sound.set or "HUD_MINI_GAME_SOUNDSET", true)
    end
end

-- ========================================
-- EXPORTS
-- ========================================

exports('Notify', Notify)
exports('NotifyWithSound', NotifyWithSound)
