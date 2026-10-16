-- =====================================================
-- TIMING CIRCLES MINIGAME - CLIENT
-- =====================================================

local isTimingCircles = false
local timingCirclesCallback = nil

-- =====================================================
-- FUNCIÓN PRINCIPAL - INICIAR TIMING CIRCLES
-- =====================================================

---@param difficulty string Dificultad: 'easy', 'medium', 'hard', 'extreme'
---@param callback function Función que se ejecuta al terminar (success: bool)
---@return boolean success Si se pudo iniciar el minijuego
function StartTimingCircles(difficulty, callback)
    
    
    if isTimingCircles then
        -- Quien esperaba el resultado anterior tiene que recibir uno. Si su
        -- callback se descarta sin llamarlo, su bandera de "minijuego en curso"
        -- no se libera nunca y no vuelve a poder jugar hasta reiniciar.
        local anterior = timingCirclesCallback
        isTimingCircles = false
        timingCirclesCallback = nil
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'closeTimingCircles' })
        if anterior then pcall(anterior, false) end
    end
    
    difficulty = difficulty or 'medium'
    
    -- Verificar si existe la dificultad
    if not Config.TimingCircles or not Config.TimingCircles.Difficulty[difficulty] then
        
        return false
    end
    
    isTimingCircles = true
    timingCirclesCallback = callback
    
    
    -- Iniciar animación
    startTimingCirclesAnimation()
    
    -- Obtener configuración de dificultad
    local config = Config.TimingCircles.Difficulty[difficulty]
    
    
    -- Enviar datos al NUI
    SendNUIMessage({
        action = 'startTimingCircles',
        config = {
            rounds = config.rounds,
            speed = config.speed,
            perfectZone = config.perfectZone
        }
    })
    
    
    -- Abrir NUI
    SetNuiFocus(true, true)
    
    
    
    return true
end

-- =====================================================
-- ANIMACIÓN
-- =====================================================

function startTimingCirclesAnimation()
    local ped = PlayerPedId()
    
    RequestAnimDict('anim@heists@prison_heiststation@cop_reactions')
    while not HasAnimDictLoaded('anim@heists@prison_heiststation@cop_reactions') do
        Wait(10)
    end
    
    TaskPlayAnim(
        ped,
        'anim@heists@prison_heiststation@cop_reactions',
        'cop_b_idle',
        8.0, -8.0, -1,
        49,
        0, false, false, false
    )
end

function stopTimingCirclesAnimation()
    local ped = PlayerPedId()
    ClearPedTasks(ped)
end

-- =====================================================
-- CALLBACKS DEL NUI
-- =====================================================

RegisterNUICallback('timingCirclesResult', function(data, cb)
    -- Un resultado de una partida que ya no esta en curso (cerrada desde
    -- Lua, o ya contestada) no suelta nada: el raton y el callback serian
    -- los de la partida de ahora.
    if not isTimingCircles then cb('ok') return end
    
    
    local success = data.success
    
    SetNuiFocus(false, false)
    
    cb('ok')
    
    isTimingCircles = false
    stopTimingCirclesAnimation()
    
    if timingCirclesCallback then
        timingCirclesCallback(success)
        timingCirclesCallback = nil
    end

    TriggerEvent('origen_minijuegos:result', 'timingcircles', success)
end)

RegisterNUICallback('closeTimingCircles', function(data, cb)
    -- Un resultado de una partida que ya no esta en curso (cerrada desde
    -- Lua, o ya contestada) no suelta nada: el raton y el callback serian
    -- los de la partida de ahora.
    if not isTimingCircles then cb('ok') return end
    SetNuiFocus(false, false)
    cb('ok')

    isTimingCircles = false
    stopTimingCirclesAnimation()

    if timingCirclesCallback then
        timingCirclesCallback(false)
        timingCirclesCallback = nil
    end

    TriggerEvent('origen_minijuegos:result', 'timingcircles', false)
end)

-- Si el vigilante suelta el raton a la fuerza (`soltarraton`, o la pagina
-- sin nada delante) con la partida en marcha: se da por perdida y se deja
-- todo como al cerrar con Escape. Sin coger el foco aqui dentro.
OrigenFoco.AlSoltar(function()
    if not isTimingCircles then return end
    local anterior = timingCirclesCallback
    isTimingCircles = false
    timingCirclesCallback = nil
    SendNUIMessage({ action = 'closeTimingCircles' })
    stopTimingCirclesAnimation()
    if anterior then pcall(anterior, false) end
    TriggerEvent('origen_minijuegos:result', 'timingcircles', false)
end)

-- =====================================================
-- EXPORT
-- =====================================================

exports('StartTimingCircles', StartTimingCircles)

-- =====================================================
-- COMANDO DE PRUEBA
-- =====================================================

