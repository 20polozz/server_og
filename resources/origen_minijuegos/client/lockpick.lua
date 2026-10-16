-- =====================================================
-- LOCKPICK MINIGAME - CLIENT
-- =====================================================

local isLockpicking = false
local lockpickCallback = nil

-- =====================================================
-- FUNCIÓN PRINCIPAL - INICIAR LOCKPICK
-- =====================================================

---@param difficulty string Dificultad: 'easy', 'medium', 'hard', 'extreme'
---@param callback function Función que se ejecuta al terminar (success: bool)
---@return boolean success Si se pudo iniciar el minijuego
function StartLockpick(difficulty, callback)
    if isLockpicking then
        -- Quien esperaba el resultado anterior tiene que recibir uno. Si su
        -- callback se descarta sin llamarlo, su bandera de "minijuego en curso"
        -- no se libera nunca y no vuelve a poder jugar hasta reiniciar.
        local anterior = lockpickCallback
        isLockpicking = false
        lockpickCallback = nil
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'closeLockpick' })
        if anterior then pcall(anterior, false) end
    end
    
    difficulty = difficulty or 'medium'
    
    -- Verificar si existe la dificultad
    if not Config.Lockpick.Difficulty[difficulty] then
        
        return false
    end
    
    isLockpicking = true
    lockpickCallback = callback
    
    
    -- Iniciar animación
    startLockpickAnimation()
    
    -- Obtener configuración de dificultad
    local config = Config.Lockpick.Difficulty[difficulty]
    
    
    -- Enviar datos al NUI
    SendNUIMessage({
        action = 'startLockpick',
        config = {
            pins = config.pins,
            timePerPin = config.timePerPin,
            sweetSpotSize = config.sweetSpotSize,
            moveSpeed = config.moveSpeed
        }
    })
    
    
    -- Abrir NUI
    SetNuiFocus(true, true)
    
    
    
    return true
end

-- =====================================================
-- ANIMACIÓN DE LOCKPICK
-- =====================================================

function startLockpickAnimation()
    local ped = PlayerPedId()
    
    -- Cargar animación
    RequestAnimDict(Config.Lockpick.Animation.dict)
    while not HasAnimDictLoaded(Config.Lockpick.Animation.dict) do
        Wait(10)
    end
    
    -- Reproducir animación
    TaskPlayAnim(
        ped,
        Config.Lockpick.Animation.dict,
        Config.Lockpick.Animation.anim,
        8.0, -8.0, -1,
        Config.Lockpick.Animation.flag,
        0, false, false, false
    )
end

function stopLockpickAnimation()
    local ped = PlayerPedId()
    ClearPedTasks(ped)
end

-- =====================================================
-- CALLBACKS DEL NUI
-- =====================================================

-- Resultado del lockpick
RegisterNUICallback('lockpickResult', function(data, cb)
    -- Un resultado de una partida que ya no esta en curso (cerrada desde
    -- Lua, o ya contestada) no suelta nada: el raton y el callback serian
    -- los de la partida de ahora.
    if not isLockpicking then cb('ok') return end
    
    
    local success = data.success
    
    
    -- IMPORTANTE: Liberar NUI focus ANTES de responder el callback
    SetNuiFocus(false, false)
    
    
    
    -- Responder al NUI
    cb('ok')
    
    
    
    -- Procesar resultado
    isLockpicking = false
    stopLockpickAnimation()
    
    
    
    -- Ejecutar callback (si fue registrado localmente)
    if lockpickCallback then
        lockpickCallback(success)
        lockpickCallback = nil
    end

    -- Evento para recursos externos que esperen el resultado
    TriggerEvent('origen_minijuegos:result', 'lockpick', success)

end)

-- Cerrar NUI (ESC)
RegisterNUICallback('closeLockpick', function(data, cb)
    -- Un resultado de una partida que ya no esta en curso (cerrada desde
    -- Lua, o ya contestada) no suelta nada: el raton y el callback serian
    -- los de la partida de ahora.
    if not isLockpicking then cb('ok') return end
    SetNuiFocus(false, false)
    cb('ok')

    isLockpicking = false
    stopLockpickAnimation()

    if lockpickCallback then
        lockpickCallback(false)
        lockpickCallback = nil
    end

    TriggerEvent('origen_minijuegos:result', 'lockpick', false)
end)

-- Si el vigilante suelta el raton a la fuerza (`soltarraton`, o la pagina
-- sin nada delante) con la partida en marcha: se da por perdida y se deja
-- todo como al cerrar con Escape. Sin coger el foco aqui dentro.
OrigenFoco.AlSoltar(function()
    if not isLockpicking then return end
    local anterior = lockpickCallback
    isLockpicking = false
    lockpickCallback = nil
    SendNUIMessage({ action = 'closeLockpick' })
    stopLockpickAnimation()
    if anterior then pcall(anterior, false) end
    TriggerEvent('origen_minijuegos:result', 'lockpick', false)
end)

-- =====================================================
-- EXPORT
-- =====================================================

exports('StartLockpick', StartLockpick)

-- =====================================================
-- COMANDO DE PRUEBA
-- =====================================================

