local TimeFreezed = {
    enabled = false,
    hour = 0,
    minute = 0
}
local WeatherFreezed = {
    enabled = false,
    weather = "EXTRASUNNY"
}
local qbWeatherSync = GetResourceState('qb-weathersync') ~= 'missing'
local renewedWeatherSync = GetResourceState('Renewed-Weathersync') ~= 'missing'

function SetWeatherTime(hour, minute)
    if renewedWeatherSync then
        TriggerServerEvent("origen_admin:server:SetTime", hour, minute)
        return
    end
    NetworkOverrideClockTime(hour, minute, 0)
end

function SetWeather(weather, isSynced)
    if renewedWeatherSync then
        if isSynced then
            TriggerServerEvent("origen_admin:server:SetWeather", weather)
        else
            LocalPlayer.state.playerWeather = weather
        end
        return
    end

    if qbWeatherSync and isSynced then 
        TriggerServerEvent("origen_admin:server:SetWeather", weather)
        return
    end
    ClearOverrideWeather()
    ClearWeatherTypePersist()
    SetWeatherTypePersist(weather)
    SetWeatherTypeNow(weather)
    SetWeatherTypeNowPersist(weather)
end

function IsTimeFreezed()
    if TimeFreezed.enabled then
        return true
    end
    local attempts = 0
    local result = nil

    if qbWeatherSync or renewedWeatherSync then 
        FW_TriggerCallback("origen_admin:server:IsTimeFreezed", function(state)
            result = state
        end)
    end

    while result == nil and attempts < 1000 do
        Citizen.Wait(0)
        attempts = attempts + 1
    end
    return result
end

function IsWeatherFreezed()
    if WeatherFreezed.enabled then
        return true
    end
    local attempts = 0
    local result = nil

    if qbWeatherSync or renewedWeatherSync then 
        FW_TriggerCallback("origen_admin:server:IsWeatherFreezed", function(state)
            result = state
        end)
    end

    while result == nil and attempts < 1000 do
        Citizen.Wait(0)
        attempts = attempts + 1
    end
    return result
end

function SetWeatherSync(state)
    if renewedWeatherSync then
        LocalPlayer.state.syncWeather = state
        return
    end
    if qbWeatherSync then
        return TriggerEvent(state and "qb-weathersync:client:EnableSync" or "qb-weathersync:client:DisableSync")
    end
end

RegisterNetEvent("origen_admin:client:SetFreezeTime", function(state)
    TimeFreezed = {
        enabled = state,
        hour = GetClockHours(),
        minute = GetClockMinutes()
    }
    if not state then return end
    while TimeFreezed.enabled do
        Citizen.Wait(1000)
        NetworkOverrideClockTime(TimeFreezed.hour, TimeFreezed.minute, 0)
    end
end)

RegisterNetEvent("origen_admin:client:SetFreezeWeather", function(state)
    WeatherFreezed = {
        enabled = state,
        weather = GetWeatherFromHash(GetPrevWeatherTypeHashName())
    }
    if not state then return end
    while WeatherFreezed.enabled do
        Citizen.Wait(500)
        SetWeather(WeatherFreezed.weather)
    end
end)

function ToggleBlackout(state)
    TriggerServerEvent("origen_admin:server:SetBlackout", state)
end

function IsBlackout()
    local attempts = 0
    local result = nil
    FW_TriggerCallback("origen_admin:server:IsBlackout", function(state)
        result = state
    end)
    while result == nil and attempts < 1000 do
        Citizen.Wait(0)
        attempts = attempts + 1
    end
    return result
end