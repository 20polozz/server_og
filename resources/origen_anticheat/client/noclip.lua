-- =============================================
-- origen_anticheat — Client: Detección de NoClip / Vuelo
-- =============================================

local lastCoords = nil
local lastCheckTime = 0

function CheckNoClip()
    if not Config.Modules.NoClip.enabled then return end

    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then return end

    -- Dentro de una partida de Origen Games el recurso mueve al jugador a mano
    -- (a la zona, de vuelta al centro, a su sitio si es un prop quieto) y eso
    -- se lee igual que un noclip.
    if LocalPlayer.state.enJuego then
        lastCoords = nil
        return
    end

    -- A caballo (origen_pets) va enganchado al animal: al galope pasa de
    -- 15 m/s y, como no anda el, el motor dice que esta quieto.
    if LocalPlayer.state.montado and IsEntityAttached(ped) then
        lastCoords = nil
        return
    end

    -- Si está en vehículo, no aplicar
    if IsPedInAnyVehicle(ped, false) then
        lastCoords = nil
        return 
    end

    -- Si está muerto o cayendo legítimamente, ignorar
    if IsEntityDead(ped) or IsPedRagdoll(ped) or IsPedFalling(ped) then 
        lastCoords = nil
        return 
    end

    local pos = GetEntityCoords(ped)
    local now = GetGameTimer()

    if not lastCoords then
        lastCoords = pos
        lastCheckTime = now
        return
    end

    local timeDiff = (now - lastCheckTime) / 1000.0
    if timeDiff <= 0 then timeDiff = 0.1 end

    local dist = #(pos - lastCoords)
    local moveSpeed = dist / timeDiff

    -- Velocidad reportada por el motor de físicas
    local vel  = GetEntityVelocity(ped)
    local engineSpeed = math.sqrt(vel.x * vel.x + vel.y * vel.y + vel.z * vel.z)

    -- Si el jugador se movió físicamente a una velocidad alta (> 15 m/s) 
    -- PERO la velocidad del engine es casi nula (< 2 m/s), significa que 
    -- se está moviendo con SetEntityCoords (típico de NoClip / Freecam de menús)
    if moveSpeed > 15.0 and engineSpeed < 2.0 then
        -- Evitar falsos positivos de teleports descartando distancias masivas (> 100m en 1 check)
        -- Si es un teleport legítimo (admin goto), la distancia será enorme, no un noclip
        if dist > 5.0 and dist < 100.0 then
            ReportViolation(
                AC.Modules.NoClip,
                string.format('NoClip detectado: Movimiento continuo a %.1f m/s (Engine: %.1f m/s)', moveSpeed, engineSpeed)
            )
        end
    end

    -- Detección vertical clásica (velocidad vertical)
    if vel.z > Config.Thresholds.NoclipVerticalSpeed then
        local found, groundZ = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z, false)
        local height = pos.z - (found and groundZ or 0.0)
        
        if height > Config.Thresholds.NoclipMinGroundHeight then
            ReportViolation(
                AC.Modules.NoClip,
                string.format('Velocidad vertical sospechosa: %.1f m/s, altura: %.1fm', vel.z, height)
            )
        end
    end

    lastCoords = pos
    lastCheckTime = now
end

