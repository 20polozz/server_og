Internal.DisableWeatherSync = function()
    if Config.Weather == 'qb-weathersync' then
        TriggerEvent('qb-weathersync:client:DisableSync')
    elseif Config.Weather == 'cd_easytime' then
        TriggerEvent('cd_easytime:PauseSync', true)
    elseif Config.Weather == 'Renewed-Weathersync' then
        LocalPlayer.state.syncWeather = false
    else
        Custom.DisableWeatherSync()
    end

    if Config.ForceDisableRain and not disabledRain then
        disabledRain = true
        lastRainLevel = GetRainLevel()

        CreateThread(function()
            while disabledRain do
                SetRainLevel(0.0)
                Wait(1000)
            end
        end)
    end
end

Internal.EnableWeatherSync = function()
    if Config.Weather == 'qb-weathersync' then
        TriggerEvent('qb-weathersync:client:EnableSync')
    elseif Config.Weather == 'cd_easytime' then
        TriggerEvent('cd_easytime:PauseSync', false)
    elseif Config.Weather == 'Renewed-Weathersync' then
        LocalPlayer.state.syncWeather = true
    else
        Custom.EnableWeatherSync()
    end

    if Config.ForceDisableRain and disabledRain then
        disabledRain = false
        SetRainLevel(lastRainLevel)
    end
end