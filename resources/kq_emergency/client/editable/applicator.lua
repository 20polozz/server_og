Applicator = {}

-- Constants
Applicator.CHECK_INTERVAL = 60000 -- 60 seconds
Applicator.RENDER_DISTANCE = 25.0

-- State
Applicator.state = {
    hasPermission = false,
    lastCheckTime = 0,
    checksCount = 0,

    nearestZone = nil,
    nearestDistance = nil,
    nearestZoneKey = nil
}

function Applicator.CheckPlayerPermissions(force)
    if Applicator.state.nearestZone == nil then
        return
    end

    local currentTime = GetGameTimer()

    local checkInterval = Applicator.CHECK_INTERVAL
    if Applicator.hasPermission then
        checkInterval = checkInterval * 5
    end

    if Applicator.state.checksCount <= 4 then
        checkInterval = checkInterval / 2
    end

    if not force and (currentTime - Applicator.state.lastCheckTime < checkInterval) then
        return
    end

    local policies = exports.kq_link:TriggerServerCallback('kq_emergency:callback:getPlayerPolicies')
    Applicator.state.checksCount = Applicator.state.checksCount + 1

    if policies and policies.apply ~= nil then
        Applicator.state.hasPermission = policies.apply
        Applicator.state.lastCheckTime = currentTime
    else
        -- If callback fails, treat as no permission
        Applicator.state.hasPermission = false
    end
end

-- Function to calculate alpha based on distance
function Applicator.GetMarkerAlpha(distance, maxDistance, baseAlpha)
    if distance >= maxDistance then
        return 0
    end

    local fadeRange = maxDistance * 0.4
    local fadeStart = maxDistance - fadeRange

    if distance <= fadeStart then
        return baseAlpha
    else
        local fadeProgress = (maxDistance - distance) / fadeRange
        return math.floor(baseAlpha * fadeProgress)
    end
end

-- Function to find nearest zone
function Applicator.FindNearestZone(playerCoords)
    if not Config.applicationZones.enabled then
        return nil, nil, nil
    end

    local closestZone = nil
    local closestDist = Applicator.RENDER_DISTANCE + 30.0
    local closestKey = nil

    for key, zone in pairs(Config.applicationZones.zones) do
        local distance = #(playerCoords - zone.coords)

        if distance < closestDist then
            closestZone = zone
            closestDist = distance
            closestKey = key
        end
    end

    return closestZone, closestDist, closestKey
end

-- Render markers for zones
function Applicator.RenderZone()
    -- Si en esta pasada se esta encima del punto. Lo lee el hilo de Init para
    -- poner o quitar el aviso de la tecla.
    Applicator.state.enPunto = false

    local inVehicle = Data.vehicle() ~= 0

    if not inVehicle then
        Applicator.state.nearestZone = nil
        Applicator.state.nearestDistance = nil
        Applicator.state.nearestZoneKey = nil
        return 4000
    end

    local playerCoords = Data.coords()

    -- Find nearest zone
    local zone, distance, zoneKey = Applicator.FindNearestZone(playerCoords)
    Applicator.state.nearestZone = zone
    Applicator.state.nearestDistance = distance
    Applicator.state.nearestZoneKey = zoneKey

    if zone and distance <= (Applicator.RENDER_DISTANCE + 30.0) then
        if Applicator.state.hasPermission then
            local marker = zone.marker
            local alpha = Applicator.GetMarkerAlpha(distance, Applicator.RENDER_DISTANCE, marker.color.a)

            if distance <= Applicator.state.nearestZone.radius + 1.0 then
                -- El aviso ya no es el texto de ayuda de GTA (la caja negra de
                -- arriba a la izquierda): es la pastilla de tecla del servidor,
                -- la de origen_notify. La pone el hilo de Init.
                Applicator.state.enPunto = true

                if IsControlJustReleased(0, 38) then -- E key
                    TriggerServerEvent('kq_emergency:server:openQuickApplyMenu', true)
                    Applicator.CheckPlayerPermissions(true)
                end
            end

            if alpha > 0 then
                DrawMarker(
                    marker.variant,
                    zone.coords.x, zone.coords.y, zone.coords.z,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    marker.scale or (zone.radius * 2), marker.scale or (zone.radius * 2), marker.scale or 1.0,
                    marker.color.r, marker.color.g, marker.color.b, alpha,
                    false, false, 2, false, nil, nil, false
                )
                return 1
            end
        end

        return 20
    end

    return 2000
end

-- Initialize threads
function Applicator.Init()
    -- Main rendering thread
    CreateThread(function()
        while true do
            local sleep = Applicator.RenderZone()

            -- La pastilla de tecla: se pide una vez al entrar y se quita al
            -- salir (no cada fotograma).
            if Applicator.state.enPunto ~= (Applicator.state.avisoPuesto or false) then
                Applicator.state.avisoPuesto = Applicator.state.enPunto
                if Applicator.state.enPunto then
                    exports.origen_notify:DrawText('E', L('applicator.hint_short'))
                else
                    exports.origen_notify:HideText()
                end
            end

            Citizen.Wait(sleep)
        end
    end)

    -- Permissions check thread
    CreateThread(function()
        Citizen.Wait(2000)
        while true do
            Applicator.CheckPlayerPermissions()
            Citizen.Wait(5000)
        end
    end)

end

if Config.applicationZones.enabled then
    -- Initialize on load
    Applicator.Init()
end

