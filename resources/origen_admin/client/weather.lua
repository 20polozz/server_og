local weathers = {
    "CLEAR",
    "EXTRASUNNY",
    "CLOUDS",
    "OVERCAST",
    "RAIN",
    "CLEARING",
    "THUNDER",
    "SMOG",
    "FOGGY",
    "XMAS",
    "SNOWLIGHT",
    "BLIZZARD",
    "HALLOWEEN",
    "NEUTRAL"
}

function GetWeatherFromHash(hash)
    for i, weather in ipairs(weathers) do
        if hash == GetHashKey(weather) then
            return weather
        end
    end
    return "CLEAR"
end

RegisterNUICallback("GetWeatherData", function(data, cb)
    local currentWeather = weathers[1]
    local renewedWeatherSync = GetResourceState('Renewed-Weathersync') ~= 'missing'
    
    if renewedWeatherSync and GlobalState.weather then
        currentWeather = GlobalState.weather.weather or weathers[1]
    else
        local weatherHash = GetPrevWeatherTypeHashName()
        for i, weather in ipairs(weathers) do
            if weatherHash == GetHashKey(weather) then
                currentWeather = weather
                break
            end
        end
    end
    
    local currentTime = {hour = GetClockHours(), minute = GetClockMinutes()}
    if renewedWeatherSync and GlobalState.currentTime then
        currentTime = GlobalState.currentTime
    end
    
    local timeFreezed = false
    local weatherFreezed = false
    local blackoutState = false
    local syncState = true
    
    if renewedWeatherSync then
        timeFreezed = GlobalState.freezeTime or false
        weatherFreezed = GlobalState.weatherFrozen or false
        blackoutState = GlobalState.blackOut or false
        syncState = LocalPlayer.state.syncWeather or true
    else
        if TimeFreezed.enabled then
            timeFreezed = true
        end
        if WeatherFreezed.enabled then
            weatherFreezed = true
        end
    end
    
    cb({
        weather = currentWeather,
        hour = currentTime.hour,
        minute = currentTime.minute,
        timeFreezed = timeFreezed,
        weatherFreezed = weatherFreezed,
        blackout = blackoutState,
        syncWeather = syncState
    })
end)

RegisterNUICallback("SetWeatherTime", function(data, cb)
    local hour = 0
    local minute = 0
    if data.time then
        hour = math.floor(data.time / 60)
        minute = data.time % 60
    end
    SetWeatherTime(hour, minute)
    cb(true)
end)

RegisterNUICallback("SetWeather", function(data, cb)
    SetWeather(data.weather, data.isSynced)
    cb(true)
end)

RegisterNUICallback("SetWeatherSync", function(data, cb)
    SetWeatherSync(data.state)
    cb(true)
end)

RegisterNUICallback("ToggleBlackout", function(data, cb)
    ToggleBlackout(data.state)
    cb(true)
end)

RegisterNUICallback("SetFreezeTime", function(data, cb)
    TriggerServerEvent("origen_admin:server:SetTimeFreezed", data.state)
    cb(true)
end)

RegisterNUICallback("SetFreezeWeather", function(data, cb)
    TriggerServerEvent("origen_admin:server:SetWeatherFreezed", data.state)
    cb(true)
end)

RegisterNUICallback("GetWeatherConfig", function(data, cb)
    FW_TriggerCallback("origen_admin:server:GetWeatherConfig", function(config)
        cb(config)
    end)
end)

RegisterNUICallback("SetWeatherConfig", function(data, cb)
    FW_TriggerCallback("origen_admin:server:SetWeatherConfig", function(success)
        cb(success)
    end, data)
end)