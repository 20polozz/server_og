-- ============================================================
-- ORIGEN PLATES — Sabotaje / Dispositivos Racing (cliente)
-- ============================================================

-- ── Helper: vehículo cercano ajeno al jugador ─────────────────────────────────

local function getNearbyVehicle(maxDist)
    local ped      = PlayerPedId()
    local myVeh    = GetVehiclePedIsIn(ped, false)
    local origin   = GetEntityCoords(ped)
    local nearest  = nil
    local nearestD = maxDist or 5.0

    for _, veh in ipairs(GetGamePool('CVehicle')) do
        if veh ~= myVeh and DoesEntityExist(veh) then
            local netId = NetworkGetNetworkIdFromEntity(veh)
            if netId and netId > 0 then
                local d = #(origin - GetEntityCoords(veh))
                if d < nearestD then
                    nearestD = d
                    nearest  = veh
                end
            end
        end
    end
    return nearest
end

-- ── 1. JAULA DE SEGURIDAD ─────────────────────────────────────────────────────
-- Activa para 10 minutos: aumenta la resistencia de carrocería y motor.
-- Las ruedas no se blindan (se pinchan con normalidad).

local jaulaActive = false

local function applyJaulaModifiers(v, state)
    if not DoesEntityExist(v) then return end
    local mult = state and 0.25 or 1.0
    SetVehicleDamageModifier(v, mult)
    SetVehicleEngineDamageModifier(v, mult)
    SetVehicleDeformationDamageModifier(v, mult)
end

local function useJaulaSeguidad()
    if jaulaActive then
        lib.notify({ title = 'Jaula', description = 'Ya está activa', type = 'warning', duration = 3000 })
        return
    end

    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh == 0 then
        lib.notify({ title = 'Jaula', description = 'Debes estar dentro de un vehículo', type = 'error', duration = 3000 })
        return
    end

    local ok = lib.callback.await('origen_plates:consumeRacingItem', false, 'jaula_seguridad')
    if not ok then
        lib.notify({ title = 'Jaula', description = 'No tienes una jaula de seguridad', type = 'error', duration = 3000 })
        return
    end

    jaulaActive = true
    applyJaulaModifiers(veh, true)

    lib.notify({
        title       = 'Jaula de Seguridad',
        description = 'Activa — mayor resistencia en carrocería y motor (10 min)',
        type        = 'success',
        duration    = 5000,
    })

    CreateThread(function()
        local endTime = GetGameTimer() + 600000
        local tracked = veh

        while GetGameTimer() < endTime and jaulaActive do
            Wait(1000)
            local cur = GetVehiclePedIsIn(PlayerPedId(), false)
            if cur ~= 0 and GetPedInVehicleSeat(cur, -1) == PlayerPedId() then
                if cur ~= tracked then
                    applyJaulaModifiers(tracked, false) -- Restaurar antiguo
                    tracked = cur
                    applyJaulaModifiers(cur, true)     -- Aplicar al nuevo
                end
            end
        end

        applyJaulaModifiers(tracked, false)
        jaulaActive = false
        lib.notify({ title = 'Jaula', description = 'Protección expirada', type = 'inform', duration = 4000 })
    end)
end

exports('UseJaulaSeguidad', useJaulaSeguidad)
RegisterNetEvent('origen_plates:useJaulaSeguidad', useJaulaSeguidad)

-- ── 2. LOCALIZADOR GPS ────────────────────────────────────────────────────────
-- Instala un rastreador en el vehículo más cercano; muestra un blip 10 minutos.

local gpsBlips = {}   -- [netId] = blipHandle

local function useLocalizadorGPS()
    local veh = getNearbyVehicle(6.0)
    if not veh then
        lib.notify({ title = 'Localizador GPS', description = 'No hay vehículo cerca (radio: 6 m)', type = 'error', duration = 3000 })
        return
    end

    local planted = lib.progressBar({
        duration     = 3000,
        label        = 'Instalando localizador GPS...',
        useWhileDead = false,
        canCancel    = true,
        disable      = { car = true, move = true },
        anim         = { dict = 'mini@repair', clip = 'fixing_a_ped' },
    })
    if not planted then return end

    local netId = NetworkGetNetworkIdFromEntity(veh)
    local res   = lib.callback.await('origen_plates:plantGPS', false, netId)

    if not res or not res.success then
        lib.notify({ title = 'Localizador GPS', description = 'No tienes el localizador', type = 'error', duration = 3000 })
        return
    end

    lib.notify({ title = 'Localizador GPS', description = 'Instalado — señal activa 10 min', type = 'success', duration = 4000 })

    --[[ El localizador, en el mapa.

         Ya no es un blip del juego: es un punto de origen_map. Va con
         prioridad alta porque un coche localizado importa este donde este
         —el corte por distancia del minimapa se lo comeria— y con `mapa` y
         `minimapa` puestos, que es lo que hacia SetBlipAsShortRange(false). ]]
    local blip = 'gps_' .. tostring(netId)
    gpsBlips[netId] = blip

    OrigenMapa.Poner(blip, {
        x = GetEntityCoords(veh).x, y = GetEntityCoords(veh).y, z = GetEntityCoords(veh).z,
        cat = 'illegal',
        icono = 'coche',
        nombre = 'Vehículo localizado',
        color = '#ff3355',
        prioridad = 10,
    })

    CreateThread(function()
        local expiry = GetGameTimer() + 600000
        while GetGameTimer() < expiry do
            Wait(10000)
            local poll = lib.callback.await('origen_plates:pollGPS', false, netId)
            if not poll or not poll.found then break end
            --- Volver a ponerlo con la misma clave lo mueve: el registro
            --- actualiza el punto en vez de crear otro.
            OrigenMapa.Poner(blip, {
                x = poll.coords.x, y = poll.coords.y, z = poll.coords.z,
                cat = 'illegal',
                icono = 'coche',
                nombre = 'Vehículo localizado',
                color = '#ff3355',
                prioridad = 10,
            })
        end
        OrigenMapa.Quitar(blip)
        gpsBlips[netId] = nil
        lib.notify({ title = 'Localizador GPS', description = 'Señal perdida', type = 'inform', duration = 4000 })
    end)
end

exports('UseLocalizadorGPS', useLocalizadorGPS)
RegisterNetEvent('origen_plates:useLocalizadorGPS', useLocalizadorGPS)

-- ── 3. INHIBIDOR DE VELOCIDAD ─────────────────────────────────────────────────
-- Limita el vehículo objetivo a ~43 km/h. El efecto persiste hasta reparación.

local function useInhibidorVelocidad()
    local veh = getNearbyVehicle(5.0)
    if not veh then
        lib.notify({ title = 'Inhibidor', description = 'No hay vehículo cerca (radio: 5 m)', type = 'error', duration = 3000 })
        return
    end

    local ok = lib.progressBar({
        duration     = 4000,
        label        = 'Instalando inhibidor de velocidad...',
        useWhileDead = false,
        canCancel    = true,
        disable      = { car = true, move = true },
        anim         = { dict = 'mini@repair', clip = 'fixing_a_ped' },
    })
    if not ok then return end

    local netId = NetworkGetNetworkIdFromEntity(veh)
    local res   = lib.callback.await('origen_plates:plantSpeedInhibitor', false, netId)

    if not res or not res.success then
        lib.notify({ title = 'Inhibidor', description = 'No tienes el inhibidor', type = 'error', duration = 3000 })
        return
    end

    lib.notify({ title = 'Inhibidor de Velocidad', description = 'Instalado — velocidad máxima limitada', type = 'success', duration = 4000 })
end

-- Servidor hace broadcast; cada cliente comprueba si es SU vehículo (actual o futuro)
RegisterNetEvent('origen_plates:applySpeedInhibitor', function(netId)
    netId = tonumber(netId)

    -- Función que aplica el efecto cuando el jugador esté en ese vehículo
    local function applyIfMatch()
        local myVeh = GetVehiclePedIsIn(PlayerPedId(), false)
        if myVeh ~= 0 and NetworkGetNetworkIdFromEntity(myVeh) == netId then
            SetVehicleMaxSpeed(myVeh, 12.0)   -- ~43 km/h
            lib.notify({ title = 'Sabotaje', description = 'Inhibidor de velocidad detectado en tu vehículo', type = 'error', duration = 6000 })
            return true
        end
        return false
    end

    if not applyIfMatch() then
        -- Esperar hasta 60 segundos por si el jugador entra después
        CreateThread(function()
            local deadline = GetGameTimer() + 60000
            while GetGameTimer() < deadline do
                Wait(1000)
                if applyIfMatch() then break end
            end
        end)
    end
end)

exports('UseInhibidorVelocidad', useInhibidorVelocidad)
RegisterNetEvent('origen_plates:useInhibidorVelocidad', useInhibidorVelocidad)

-- ── 4. BOMBA DE RUEDAS ────────────────────────────────────────────────────────
-- Cuenta atrás de 45 seg; revienta las 4 ruedas del vehículo objetivo.

local function useBombaRuedas()
    local veh = getNearbyVehicle(5.0)
    if not veh then
        lib.notify({ title = 'Bomba de Ruedas', description = 'No hay vehículo cerca (radio: 5 m)', type = 'error', duration = 3000 })
        return
    end

    local ok = lib.progressBar({
        duration     = 5000,
        label        = 'Colocando bomba en las ruedas...',
        useWhileDead = false,
        canCancel    = true,
        disable      = { car = true, move = true },
        anim         = { dict = 'mini@repair', clip = 'fixing_a_ped' },
    })
    if not ok then return end

    local netId = NetworkGetNetworkIdFromEntity(veh)
    local res   = lib.callback.await('origen_plates:plantTireBomb', false, netId)

    if not res or not res.success then
        lib.notify({ title = 'Bomba de Ruedas', description = 'No tienes la bomba', type = 'error', duration = 3000 })
        return
    end

    lib.notify({ title = 'Bomba de Ruedas', description = 'Colocada — detona en 45 seg', type = 'success', duration = 4000 })
end

-- Aviso de cuenta atrás al conductor del vehículo objetivo
RegisterNetEvent('origen_plates:tireBombCountdown', function(netId, seconds)
    netId = tonumber(netId)
    local myVeh = GetVehiclePedIsIn(PlayerPedId(), false)
    if myVeh == 0 or NetworkGetNetworkIdFromEntity(myVeh) ~= netId then return end

    lib.notify({ title = 'Bomba Detectada', description = ('Bomba en tus ruedas — detona en %d seg'):format(seconds), type = 'error', duration = 7000 })

    -- Alertas progresivas
    CreateThread(function()
        for _, t in ipairs({ 30, 15, 5, 3, 2, 1 }) do
            if t >= seconds then goto continue end
            Wait((seconds - t) * 1000)
            local cur = GetVehiclePedIsIn(PlayerPedId(), false)
            if cur ~= 0 and NetworkGetNetworkIdFromEntity(cur) == netId then
                lib.notify({ title = 'Bomba', description = ('%d segundo%s'):format(t, t == 1 and '' or 's'), type = 'error', duration = 2000 })
            end
            ::continue::
        end
    end)
end)

-- Detonación
RegisterNetEvent('origen_plates:detonateTireBomb', function(netId)
    netId   = tonumber(netId)
    local myVeh = GetVehiclePedIsIn(PlayerPedId(), false)
    if myVeh == 0 or NetworkGetNetworkIdFromEntity(myVeh) ~= netId then return end

    for i = 0, 5 do
        SetVehicleTyreBurst(myVeh, i, true, 1000.0)
    end
    PlaySoundFrontend(-1, 'Beep_Red', 'DLC_HEIST_HACKING_SNAKE_SOUNDS', true)
    lib.notify({ title = 'Bomba', description = 'Ruedas reventadas', type = 'error', duration = 5000 })
end)

exports('UseBombaRuedas', useBombaRuedas)
RegisterNetEvent('origen_plates:useBombaRuedas', useBombaRuedas)

-- ── 5. SABOTAJE DE MOTOR ──────────────────────────────────────────────────────
-- Se activa al arrancar: falla el motor a los 5 segundos de conducir.

local engineSabotaged = {}   -- [netId] = true

local function useSabotajeMotor()
    local veh = getNearbyVehicle(5.0)
    if not veh then
        lib.notify({ title = 'Sabotaje Motor', description = 'No hay vehículo cerca (radio: 5 m)', type = 'error', duration = 3000 })
        return
    end

    local ok = lib.progressBar({
        duration     = 6000,
        label        = 'Saboteando motor...',
        useWhileDead = false,
        canCancel    = true,
        disable      = { car = true, move = true },
        anim         = { dict = 'mini@repair', clip = 'fixing_a_ped' },
    })
    if not ok then return end

    local netId = NetworkGetNetworkIdFromEntity(veh)
    local res   = lib.callback.await('origen_plates:plantEngineSabotage', false, netId)

    if not res or not res.success then
        lib.notify({ title = 'Sabotaje Motor', description = 'No tienes el kit de sabotaje', type = 'error', duration = 3000 })
        return
    end

    lib.notify({ title = 'Sabotaje de Motor', description = 'Dispositivo instalado — se activa al arrancar', type = 'success', duration = 5000 })
end

RegisterNetEvent('origen_plates:engineSabotageArmed', function(netId)
    engineSabotaged[tonumber(netId)] = true
end)

RegisterNetEvent('origen_plates:engineSabotageDisarmed', function(netId)
    engineSabotaged[tonumber(netId)] = nil
end)

-- Detectar entrada al vehículo saboteado
CreateThread(function()
    local lastVeh = 0
    while true do
        Wait(1000)
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)

        if veh ~= 0 and veh ~= lastVeh then
            lastVeh = veh
            local netId = NetworkGetNetworkIdFromEntity(veh)
            if engineSabotaged[netId] then
                engineSabotaged[netId] = nil
                -- Fallo progresivo: arrancar bien y petarle a los 5 segundos
                CreateThread(function()
                    Wait(5000)
                    if GetVehiclePedIsIn(PlayerPedId(), false) == veh then
                        SetVehicleEngineHealth(veh, 50.0)
                        SetVehicleEngineOn(veh, false, true, false)
                        lib.notify({ title = 'Motor Saboteado', description = 'El motor ha fallado', type = 'error', duration = 6000 })
                    end
                end)
            end
        elseif veh == 0 then
            lastVeh = 0
        end
    end
end)

exports('UseSabotajeMotor', useSabotajeMotor)
RegisterNetEvent('origen_plates:useSabotajeMotor', useSabotajeMotor)

-- ── 6. PINCHOS DE CARRETERA ───────────────────────────────────────────────────
-- Despliega una franja de pinchos que pincha las ruedas delanteras al pasar.
-- 2 usos máx / 45 segundos de vida. Solo el deployer ve el blip en el mapa.

local spikePositions = {}   -- [spikeId] = vector3
local spikeBlips     = {}   -- [spikeId] = blipHandle
local myDeployedSpikes = {} -- [spikeId] = true

local function usePinchosCarretera()
    local coords = GetEntityCoords(PlayerPedId())
    local res    = lib.callback.await('origen_plates:deploySpikes', false, coords.x, coords.y, coords.z)

    if not res or not res.success then
        lib.notify({ title = 'Pinchos', description = 'No tienes pinchos de carretera', type = 'error', duration = 3000 })
        return
    end

    myDeployedSpikes[res.spikeId] = true
    lib.notify({ title = 'Pinchos de Carretera', description = 'Desplegados — activos 45 seg (2 usos)', type = 'success', duration = 4000 })
end

-- Recibir posiciones de pinchos desde servidor
RegisterNetEvent('origen_plates:spikeDeployed', function(spikeId, x, y, z, deployerSrc)
    spikePositions[spikeId] = vector3(x, y, z)

    -- Solo el deployer ve el blip
    if myDeployedSpikes[spikeId] then
        local blip = 'pinchos_' .. tostring(spikeId)
        spikeBlips[spikeId] = blip

        OrigenMapa.Poner(blip, {
            x = x, y = y, z = z,
            cat = 'illegal',
            nombre = 'Pinchos',
            color = '#ff3355',
        })
    end
end)

RegisterNetEvent('origen_plates:spikeRemoved', function(spikeId)
    spikePositions[spikeId]    = nil
    myDeployedSpikes[spikeId]  = nil
    if spikeBlips[spikeId] then
        OrigenMapa.Quitar(spikeBlips[spikeId])
        spikeBlips[spikeId] = nil
    end
end)

-- Thread: detectar si el vehículo del jugador pasa sobre pinchos
CreateThread(function()
    local lastHitTime = 0
    while true do
        Wait(300)
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)

        if veh ~= 0 and GetEntitySpeed(veh) > 2.0 then
            local vehCoords = GetEntityCoords(veh)
            local now       = GetGameTimer()

            for spikeId, pos in pairs(spikePositions) do
                if #(vehCoords - pos) < 3.5 and (now - lastHitTime) > 3000 then
                    lastHitTime = now
                    -- Pinchar ruedas delanteras (0 = frontal izquierda, 1 = frontal derecha)
                    SetVehicleTyreBurst(veh, 0, true, 1000.0)
                    SetVehicleTyreBurst(veh, 1, true, 1000.0)
                    lib.notify({ title = 'Pinchos', description = '¡Has pasado sobre pinchos!', type = 'error', duration = 4000 })
                    TriggerServerEvent('origen_plates:spikeHit', spikeId)
                    break
                end
            end
        end
    end
end)

exports('UsePinchosCarretera', usePinchosCarretera)
RegisterNetEvent('origen_plates:usePinchosCarretera', usePinchosCarretera)

-- ── Cleanup ───────────────────────────────────────────────────────────────────

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    jaulaActive = false
    --- Los puntos del mapa los barre solo el registro de origen_map cuando
    --- este recurso para; aqui basta con soltar las claves.
    gpsBlips = {}
    spikeBlips = {}
end)
