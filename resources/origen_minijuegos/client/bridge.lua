--[[ La puerta por eventos, para quien no quiere depender de un export:
       TriggerEvent('origen_minijuegos:startGame', juego, dificultad, ajustes)
     y el resultado vuelve por 'origen_minijuegos:gameResult'.
     `ajustes` solo lo entienden los juegos nuevos (config_nuevos.lua). ]]
AddEventHandler('origen_minijuegos:startGame', function(gameName, difficulty, ajustes)

    local minigames = {
        lockpick     = StartLockpick,
        hacking      = StartHacking,
        codebreaker  = StartCodeBreaker,
        wirepuzzle   = StartWirePuzzle,
        minesweeper  = StartMinesweeper,
        timingcircles = StartTimingCircles,
        varhack      = StartVarHack,
        powergrid    = StartPowerGrid,
    }

    if Config.Nuevos[gameName] then
        StartMinijuego(gameName, difficulty, ajustes, function(success)
            TriggerEvent('origen_minijuegos:gameResult', success)
        end)
        return
    end

    local fn = minigames[gameName]
    if fn then
        fn(difficulty, function(success)

            TriggerEvent('origen_minijuegos:gameResult', success)
        end)
    else

        TriggerEvent('origen_minijuegos:gameResult', false)
    end
end)
