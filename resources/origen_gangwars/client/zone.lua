Zones = {}

local function OnEnterZone()
    LocalPlayer.state.inWarZone = true
    ClearExtraTimecycleModifier()
    ClearTimecycleModifier()
    SetRainLevel(0.0)
    SetArtificialLightsState(false)
    SetWeatherTypeNowPersist(Storms.weather)
    SetWeatherTypeNow(Storms.weather)
    SetWeatherTypePersist(Storms.weather)
    SetOverrideWeather(Storms.weather)
end

exports('OnEnterZone', OnEnterZone) -- exports['origen_gangwars']:OnEnterZone()

local function OnLeaveZone()
    LocalPlayer.state.inWarZone = false
    SetWeatherTypeNow('THUNDER')
    SetWeatherTypeNowPersist('THUNDER')
    SetOverrideWeather('THUNDER')
    SetWeatherTypePersist('THUNDER')
    SetRainLevel(1.0)
    SetArtificialLightsState(true)
    SetTimecycleModifier('int_extlight_small_fog')
    SetExtraTimecycleModifier('heist_boat_norain')
end

--todo esto tiene que iniciar al terminar la cinematica de la zona
Zones.InitZone = function(stormID)
    local inZone = false

    CreateThread(function()
        while LocalPlayer.state.orgInWar do
            local stormMarker = GlobalState['orgStorms_' .. stormID .. '_marker']
            local stage = stormMarker and stormMarker.stage or nil

            if not LocalPlayer.state.inWarZone and stage then
                local healthReduction = Config.ZoneStageHealth[stage] or 32
                SetEntityHealth(PlayerPed, GetEntityHealth(PlayerPed) - healthReduction)
            end
            Wait(3000)
        end
    end)

    CreateThread(function()
        while LocalPlayer.state.orgInWar do
            local waitTime = 500
            local stormMarker = GlobalState['orgStorms_' .. stormID .. '_marker']
            local point = stormMarker and stormMarker.coords or nil
            local radius = stormMarker and stormMarker.radius or nil

            if point then
                radius = radius + 0.0
                waitTime = 0
                local coords = GetEntityCoords(PlayerPed)
                coords = vector3(coords.x, coords.y, point.z)

                local radiusHalf = radius / 2
                local distance = #(coords - point) - 2.0
                local isInZone = distance <= radiusHalf

                if isInZone ~= inZone then
                    if isInZone then
                        OnEnterZone()
                    else
                        OnLeaveZone()
                    end
                    inZone = isInZone
                end

                DrawMarker( 1, point.x, point.y, point.z - 1000.0, 0, 0, 0, 0, 0, 0, radius, radius, 2000.0, Config.ZoneColor.r, Config.ZoneColor.g, Config.ZoneColor.b, Config.ZoneColor.a, false, false, 2, nil, nil, false)
            end

            Wait(waitTime)
        end
    end)
end