-- =====================================================
-- HACKING MINIGAME - CLIENT
-- =====================================================

local isHacking = false
local hackingCallback = nil

-- =====================================================
-- FUNCIÓN PRINCIPAL - INICIAR HACKING
-- =====================================================

---@param difficulty string Dificultad: 'easy', 'medium', 'hard', 'extreme'
---@param callback function Función que se ejecuta al terminar (success: bool)
---@return boolean success Si se pudo iniciar el minijuego
function StartHacking(difficulty, callback)
    
    
    if isHacking then
        -- Quien esperaba el resultado anterior tiene que recibir uno. Si su
        -- callback se descarta sin llamarlo, su bandera de "minijuego en curso"
        -- no se libera nunca y no vuelve a poder jugar hasta reiniciar.
        local anterior = hackingCallback
        isHacking = false
        hackingCallback = nil
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'closeHacking' })
        if anterior then pcall(anterior, false) end
    end
    
    difficulty = difficulty or 'medium'
    
    -- Verificar si existe la dificultad
    if not Config.Hacking or not Config.Hacking.Difficulty[difficulty] then
        
        return false
    end
    
    isHacking = true
    hackingCallback = callback
    
    
    -- Iniciar animación
    startHackingAnimation()
    
    -- Obtener configuración de dificultad
    local config = Config.Hacking.Difficulty[difficulty]
    
    
    -- Enviar datos al NUI
    SendNUIMessage({
        action = 'startHacking',
        config = {
            levels = config.levels,
            timePerLevel = config.timePerLevel,
            sequenceLength = config.sequenceLength
        }
    })
    
    
    -- Abrir NUI
    SetNuiFocus(true, true)
    
    
    
    return true
end

-- =====================================================
-- ANIMACIÓN DE HACKING
-- =====================================================

function startHackingAnimation()
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

function stopHackingAnimation()
    local ped = PlayerPedId()
    ClearPedTasks(ped)
end

-- =====================================================
-- CALLBACKS DEL NUI
-- =====================================================

-- Resultado del hacking
RegisterNUICallback('hackingResult', function(data, cb)
    -- Un resultado de una partida que ya no esta en curso (cerrada desde
    -- Lua, o ya contestada) no suelta nada: el raton y el callback serian
    -- los de la partida de ahora.
    if not isHacking then cb('ok') return end
    
    
    local success = data.success
    
    
    SetNuiFocus(false, false)
    
    
    
    cb('ok')
    
    
    
    -- Procesar resultado
    isHacking = false
    stopHackingAnimation()
    
    
    
    if hackingCallback then
        hackingCallback(success)
        hackingCallback = nil
    end

    TriggerEvent('origen_minijuegos:result', 'hacking', success)
end)

RegisterNUICallback('closeHacking', function(data, cb)
    -- Un resultado de una partida que ya no esta en curso (cerrada desde
    -- Lua, o ya contestada) no suelta nada: el raton y el callback serian
    -- los de la partida de ahora.
    if not isHacking then cb('ok') return end
    SetNuiFocus(false, false)
    cb('ok')

    isHacking = false
    stopHackingAnimation()

    if hackingCallback then
        hackingCallback(false)
        hackingCallback = nil
    end

    TriggerEvent('origen_minijuegos:result', 'hacking', false)
end)

-- Si el vigilante suelta el raton a la fuerza (`soltarraton`, o la pagina
-- sin nada delante) con la partida en marcha: se da por perdida y se deja
-- todo como al cerrar con Escape. Sin coger el foco aqui dentro.
OrigenFoco.AlSoltar(function()
    if not isHacking then return end
    local anterior = hackingCallback
    isHacking = false
    hackingCallback = nil
    SendNUIMessage({ action = 'closeHacking' })
    stopHackingAnimation()
    if anterior then pcall(anterior, false) end
    TriggerEvent('origen_minijuegos:result', 'hacking', false)
end)

-- =====================================================
-- EXPORT
-- =====================================================

exports('StartHacking', StartHacking)

-- =====================================================
-- COMANDO DE PRUEBA
-- =====================================================

