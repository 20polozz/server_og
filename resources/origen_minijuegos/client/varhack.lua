-- =====================================================
-- VAR HACK MINIGAME - CLIENT
-- =====================================================

local isVarHack = false
local varHackCallback = nil

function StartVarHack(difficulty, callback)
    
    
    if isVarHack then
        -- Quien esperaba el resultado anterior tiene que recibir uno. Si su
        -- callback se descarta sin llamarlo, su bandera de "minijuego en curso"
        -- no se libera nunca y no vuelve a poder jugar hasta reiniciar.
        local anterior = varHackCallback
        isVarHack = false
        varHackCallback = nil
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'closeVarHack' })
        if anterior then pcall(anterior, false) end
    end
    
    difficulty = difficulty or 'medium'
    
    if not Config.VarHack or not Config.VarHack.Difficulty[difficulty] then
        
        return false
    end
    
    isVarHack = true
    varHackCallback = callback
    
    local ped = PlayerPedId()
    RequestAnimDict('anim@heists@prison_heiststation@cop_reactions')
    while not HasAnimDictLoaded('anim@heists@prison_heiststation@cop_reactions') do
        Wait(10)
    end
    TaskPlayAnim(ped, 'anim@heists@prison_heiststation@cop_reactions', 'cop_b_idle', 8.0, -8.0, -1, 49, 0, false, false, false)
    
    local config = Config.VarHack.Difficulty[difficulty]
    
    SendNUIMessage({
        action = 'startVarHack',
        config = {
            lines = config.lines,
            symbols = config.symbols,
            timeLimit = config.timeLimit
        }
    })
    
    SetNuiFocus(true, true)
    
    return true
end

RegisterNUICallback('varHackResult', function(data, cb)
    -- Un resultado de una partida que ya no esta en curso (cerrada desde
    -- Lua, o ya contestada) no suelta nada: el raton y el callback serian
    -- los de la partida de ahora.
    if not isVarHack then cb('ok') return end
    SetNuiFocus(false, false)
    cb('ok')

    isVarHack = false
    ClearPedTasks(PlayerPedId())

    if varHackCallback then
        varHackCallback(data.success)
        varHackCallback = nil
    end

    TriggerEvent('origen_minijuegos:result', 'varhack', data.success)
end)

RegisterNUICallback('closeVarHack', function(data, cb)
    -- Un resultado de una partida que ya no esta en curso (cerrada desde
    -- Lua, o ya contestada) no suelta nada: el raton y el callback serian
    -- los de la partida de ahora.
    if not isVarHack then cb('ok') return end
    SetNuiFocus(false, false)
    cb('ok')

    isVarHack = false
    ClearPedTasks(PlayerPedId())

    if varHackCallback then
        varHackCallback(false)
        varHackCallback = nil
    end

    TriggerEvent('origen_minijuegos:result', 'varhack', false)
end)

-- Si el vigilante suelta el raton a la fuerza (`soltarraton`, o la pagina
-- sin nada delante) con la partida en marcha: se da por perdida y se deja
-- todo como al cerrar con Escape. Sin coger el foco aqui dentro.
OrigenFoco.AlSoltar(function()
    if not isVarHack then return end
    local anterior = varHackCallback
    isVarHack = false
    varHackCallback = nil
    SendNUIMessage({ action = 'closeVarHack' })
    ClearPedTasks(PlayerPedId())
    if anterior then pcall(anterior, false) end
    TriggerEvent('origen_minijuegos:result', 'varhack', false)
end)

exports('StartVarHack', StartVarHack)

