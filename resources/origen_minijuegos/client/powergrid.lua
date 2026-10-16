-- =====================================================
-- POWER GRID MINIGAME - CLIENT
-- =====================================================

local isPowerGrid = false
local powerGridCallback = nil

function StartPowerGrid(difficulty, callback)
    
    
    if isPowerGrid then
        -- Quien esperaba el resultado anterior tiene que recibir uno. Si su
        -- callback se descarta sin llamarlo, su bandera de "minijuego en curso"
        -- no se libera nunca y no vuelve a poder jugar hasta reiniciar.
        local anterior = powerGridCallback
        isPowerGrid = false
        powerGridCallback = nil
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'closePowerGrid' })
        if anterior then pcall(anterior, false) end
    end
    
    difficulty = difficulty or 'medium'
    
    if not Config.PowerGrid or not Config.PowerGrid.Difficulty[difficulty] then
        
        return false
    end
    
    isPowerGrid = true
    powerGridCallback = callback
    
    local ped = PlayerPedId()
    RequestAnimDict('anim@heists@prison_heiststation@cop_reactions')
    while not HasAnimDictLoaded('anim@heists@prison_heiststation@cop_reactions') do
        Wait(10)
    end
    TaskPlayAnim(ped, 'anim@heists@prison_heiststation@cop_reactions', 'cop_b_idle', 8.0, -8.0, -1, 49, 0, false, false, false)
    
    local config = Config.PowerGrid.Difficulty[difficulty]
    
    SendNUIMessage({
        action = 'startPowerGrid',
        config = {
            gridSize = config.gridSize,
            pathLength = config.pathLength,
            timeLimit = config.timeLimit
        }
    })
    
    SetNuiFocus(true, true)
    
    return true
end

RegisterNUICallback('powerGridResult', function(data, cb)
    -- Un resultado de una partida que ya no esta en curso (cerrada desde
    -- Lua, o ya contestada) no suelta nada: el raton y el callback serian
    -- los de la partida de ahora.
    if not isPowerGrid then cb('ok') return end
    SetNuiFocus(false, false)
    cb('ok')

    isPowerGrid = false
    ClearPedTasks(PlayerPedId())

    if powerGridCallback then
        powerGridCallback(data.success)
        powerGridCallback = nil
    end

    TriggerEvent('origen_minijuegos:result', 'powergrid', data.success)
end)

RegisterNUICallback('closePowerGrid', function(data, cb)
    -- Un resultado de una partida que ya no esta en curso (cerrada desde
    -- Lua, o ya contestada) no suelta nada: el raton y el callback serian
    -- los de la partida de ahora.
    if not isPowerGrid then cb('ok') return end
    SetNuiFocus(false, false)
    cb('ok')

    isPowerGrid = false
    ClearPedTasks(PlayerPedId())

    if powerGridCallback then
        powerGridCallback(false)
        powerGridCallback = nil
    end

    TriggerEvent('origen_minijuegos:result', 'powergrid', false)
end)

-- Si el vigilante suelta el raton a la fuerza (`soltarraton`, o la pagina
-- sin nada delante) con la partida en marcha: se da por perdida y se deja
-- todo como al cerrar con Escape. Sin coger el foco aqui dentro.
OrigenFoco.AlSoltar(function()
    if not isPowerGrid then return end
    local anterior = powerGridCallback
    isPowerGrid = false
    powerGridCallback = nil
    SendNUIMessage({ action = 'closePowerGrid' })
    ClearPedTasks(PlayerPedId())
    if anterior then pcall(anterior, false) end
    TriggerEvent('origen_minijuegos:result', 'powergrid', false)
end)

exports('StartPowerGrid', StartPowerGrid)

