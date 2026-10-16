-- =====================================================
-- MINESWEEPER MINIGAME - CLIENT
-- =====================================================

local isMinesweeper = false
local minesweeperCallback = nil

-- =====================================================
-- FUNCIÓN PRINCIPAL - INICIAR MINESWEEPER
-- =====================================================

---@param difficulty string Dificultad: 'easy', 'medium', 'hard', 'extreme'
---@param callback function Función que se ejecuta al terminar (success: bool)
---@return boolean success Si se pudo iniciar el minijuego
function StartMinesweeper(difficulty, callback)
    
    
    if isMinesweeper then
        -- Quien esperaba el resultado anterior tiene que recibir uno. Si su
        -- callback se descarta sin llamarlo, su bandera de "minijuego en curso"
        -- no se libera nunca y no vuelve a poder jugar hasta reiniciar.
        local anterior = minesweeperCallback
        isMinesweeper = false
        minesweeperCallback = nil
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'closeMinesweeper' })
        if anterior then pcall(anterior, false) end
    end
    
    difficulty = difficulty or 'medium'
    
    -- Verificar si existe la dificultad
    if not Config.Minesweeper or not Config.Minesweeper.Difficulty[difficulty] then
        
        return false
    end
    
    isMinesweeper = true
    minesweeperCallback = callback
    
    
    -- Iniciar animación
    startMinesweeperAnimation()
    
    -- Obtener configuración de dificultad
    local config = Config.Minesweeper.Difficulty[difficulty]
    
    
    -- Enviar datos al NUI
    SendNUIMessage({
        action = 'startMinesweeper',
        config = {
            gridSize = config.gridSize,
            mines = config.mines,
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

function startMinesweeperAnimation()
    local ped = PlayerPedId()
    
    -- Cargar animación
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

function stopMinesweeperAnimation()
    local ped = PlayerPedId()
    ClearPedTasks(ped)
end

-- =====================================================
-- CALLBACKS DEL NUI
-- =====================================================

-- Resultado
RegisterNUICallback('minesweeperResult', function(data, cb)
    -- Un resultado de una partida que ya no esta en curso (cerrada desde
    -- Lua, o ya contestada) no suelta nada: el raton y el callback serian
    -- los de la partida de ahora.
    if not isMinesweeper then cb('ok') return end
    
    
    local success = data.success
    
    SetNuiFocus(false, false)
    
    cb('ok')
    
    -- Procesar resultado
    isMinesweeper = false
    stopMinesweeperAnimation()
    
    -- Ejecutar callback
    if minesweeperCallback then
        minesweeperCallback(success)
        minesweeperCallback = nil
    end

    TriggerEvent('origen_minijuegos:result', 'minesweeper', success)
end)

RegisterNUICallback('closeMinesweeper', function(data, cb)
    -- Un resultado de una partida que ya no esta en curso (cerrada desde
    -- Lua, o ya contestada) no suelta nada: el raton y el callback serian
    -- los de la partida de ahora.
    if not isMinesweeper then cb('ok') return end
    SetNuiFocus(false, false)
    cb('ok')

    isMinesweeper = false
    stopMinesweeperAnimation()

    if minesweeperCallback then
        minesweeperCallback(false)
        minesweeperCallback = nil
    end

    TriggerEvent('origen_minijuegos:result', 'minesweeper', false)
end)

-- Si el vigilante suelta el raton a la fuerza (`soltarraton`, o la pagina
-- sin nada delante) con la partida en marcha: se da por perdida y se deja
-- todo como al cerrar con Escape. Sin coger el foco aqui dentro.
OrigenFoco.AlSoltar(function()
    if not isMinesweeper then return end
    local anterior = minesweeperCallback
    isMinesweeper = false
    minesweeperCallback = nil
    SendNUIMessage({ action = 'closeMinesweeper' })
    stopMinesweeperAnimation()
    if anterior then pcall(anterior, false) end
    TriggerEvent('origen_minijuegos:result', 'minesweeper', false)
end)

-- =====================================================
-- EXPORT
-- =====================================================

exports('StartMinesweeper', StartMinesweeper)

-- =====================================================
-- COMANDO DE PRUEBA
-- =====================================================

