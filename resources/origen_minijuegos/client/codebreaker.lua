-- =====================================================
-- CODE BREAKER MINIGAME - CLIENT
-- =====================================================

local isCodeBreaking = false
local codeBreakerCallback = nil

-- =====================================================
-- FUNCIÓN PRINCIPAL - INICIAR CODE BREAKER
-- =====================================================

---@param difficulty string Dificultad: 'easy', 'medium', 'hard', 'extreme'
---@param callback function Función que se ejecuta al terminar (success: bool)
---@return boolean success Si se pudo iniciar el minijuego
function StartCodeBreaker(difficulty, callback)
    
    
    if isCodeBreaking then
        -- Quien esperaba el resultado anterior tiene que recibir uno. Si su
        -- callback se descarta sin llamarlo, su bandera de "minijuego en curso"
        -- no se libera nunca y no vuelve a poder jugar hasta reiniciar.
        local anterior = codeBreakerCallback
        isCodeBreaking = false
        codeBreakerCallback = nil
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'closeCodeBreaker' })
        if anterior then pcall(anterior, false) end
    end
    
    difficulty = difficulty or 'medium'
    
    -- Verificar si existe la dificultad
    if not Config.CodeBreaker or not Config.CodeBreaker.Difficulty[difficulty] then
        
        return false
    end
    
    isCodeBreaking = true
    codeBreakerCallback = callback
    
    
    -- Iniciar animación
    startCodeBreakerAnimation()
    
    -- Obtener configuración de dificultad
    local config = Config.CodeBreaker.Difficulty[difficulty]
    
    
    -- Enviar datos al NUI
    SendNUIMessage({
        action = 'startCodeBreaker',
        config = {
            gridSize = config.gridSize,
            sequenceLength = config.sequenceLength,
            sequences = config.sequences,
            timeLimit = config.timeLimit
        }
    })
    
    
    -- Abrir NUI
    SetNuiFocus(true, true)
    
    
    
    return true
end

-- =====================================================
-- ANIMACIÓN
-- =====================================================

function startCodeBreakerAnimation()
    local ped = PlayerPedId()
    
    -- Cargar animación (usando laptop/tablet)
    RequestAnimDict('anim@heists@prison_heiststation@cop_reactions')
    while not HasAnimDictLoaded('anim@heists@prison_heiststation@cop_reactions') do
        Wait(10)
    end
    
    -- Reproducir animación
    TaskPlayAnim(
        ped,
        'anim@heists@prison_heiststation@cop_reactions',
        'cop_b_idle',
        8.0, -8.0, -1,
        49,
        0, false, false, false
    )
end

function stopCodeBreakerAnimation()
    local ped = PlayerPedId()
    ClearPedTasks(ped)
end

-- =====================================================
-- CALLBACKS DEL NUI
-- =====================================================

-- Resultado
RegisterNUICallback('codeBreakerResult', function(data, cb)
    -- Un resultado de una partida que ya no esta en curso (cerrada desde
    -- Lua, o ya contestada) no suelta nada: el raton y el callback serian
    -- los de la partida de ahora.
    if not isCodeBreaking then cb('ok') return end
    
    
    local success = data.success
    
    SetNuiFocus(false, false)
    
    cb('ok')
    
    -- Procesar resultado
    isCodeBreaking = false
    stopCodeBreakerAnimation()
    
    -- Ejecutar callback
    if codeBreakerCallback then
        codeBreakerCallback(success)
        codeBreakerCallback = nil
    end

    TriggerEvent('origen_minijuegos:result', 'codebreaker', success)
end)

RegisterNUICallback('closeCodeBreaker', function(data, cb)
    -- Un resultado de una partida que ya no esta en curso (cerrada desde
    -- Lua, o ya contestada) no suelta nada: el raton y el callback serian
    -- los de la partida de ahora.
    if not isCodeBreaking then cb('ok') return end
    SetNuiFocus(false, false)
    cb('ok')

    isCodeBreaking = false
    stopCodeBreakerAnimation()

    if codeBreakerCallback then
        codeBreakerCallback(false)
        codeBreakerCallback = nil
    end

    TriggerEvent('origen_minijuegos:result', 'codebreaker', false)
end)

-- Si el vigilante suelta el raton a la fuerza (`soltarraton`, o la pagina
-- sin nada delante) con la partida en marcha: se da por perdida y se deja
-- todo como al cerrar con Escape. Sin coger el foco aqui dentro.
OrigenFoco.AlSoltar(function()
    if not isCodeBreaking then return end
    local anterior = codeBreakerCallback
    isCodeBreaking = false
    codeBreakerCallback = nil
    SendNUIMessage({ action = 'closeCodeBreaker' })
    stopCodeBreakerAnimation()
    if anterior then pcall(anterior, false) end
    TriggerEvent('origen_minijuegos:result', 'codebreaker', false)
end)

-- =====================================================
-- EXPORT
-- =====================================================

exports('StartCodeBreaker', StartCodeBreaker)

-- =====================================================
-- COMANDO DE PRUEBA
-- =====================================================

