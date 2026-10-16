-- ========================================
-- CLIENTE: STREAMING / ESPECTADOR DE CARRERAS
-- Patrón idéntico al bodycam de origen_police:
--   1. SetFocusPosAndVel con coords del servidor
--   2. Crear cámara en esa posición
--   3. Wait(1000) para que el ped cargue
--   4. AttachCamToPedBone / órbita manual
-- El ped del espectador NO se mueve ni se oculta.
-- ========================================

local isStreaming        = false
local currentTargetServerId = nil
local currentCameraMode = 'third'
local streamCam         = nil

local streamParticipants    = {}
local streamParticipantIndex = 1

-- Coords del corredor activo (pasadas desde el servidor al arrancar)
local targetServerCoords = nil

-- Órbita (modos third/cinematic)
local camYaw   = 180.0
local camPitch = 20.0
local camDist  = 7.0

-- Rate-limit para GetGroundZFor_3dCoord (nativa costosa: raycast vertical)
local groundCheckFrame = 0
local cachedGroundZ    = nil

-- ========================================
-- UTILIDADES
-- ========================================

local function GetTargetPlayerPed()
    if not currentTargetServerId then return nil end
    local localId = GetPlayerFromServerId(currentTargetServerId)
    if localId == -1 then return nil end
    local ped = GetPlayerPed(localId)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return nil end
    return ped
end

local function DestroyStreamCam()
    if streamCam then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(streamCam, false)
        streamCam = nil
    end
end

local function SendStreamingStateToNUI()
    SendNUIMessage({
        action = 'streaming:stateUpdate',
        data = {
            currentPlayerIndex = streamParticipantIndex - 1,
            cameraMode         = currentCameraMode,
            participants       = streamParticipants
        }
    })
end

-- ========================================
-- INICIO DE CÁMARA (en thread aparte para no bloquear)
-- ========================================

local function StartCameraOnTarget(coordsFromServer)
    Citizen.CreateThread(function()

        DestroyStreamCam()

        -- ─── 1. SetFocusPosAndVel con las coords conocidas (del servidor o del ped local)
        -- Exactamente igual que origen_police bodycam
        local focusCoords = coordsFromServer or targetServerCoords
        if not focusCoords then
            -- Último recurso: intentar obtener coords del ped si está en rango
            local ped = GetTargetPlayerPed()
            if ped then
                local c = GetEntityCoords(ped)
                focusCoords = { x = c.x, y = c.y, z = c.z }
            end
        end

        if not focusCoords then
            print('^1[Streaming]^7 ERROR: no hay coords para SetFocusPosAndVel')
            return
        end

        SetFocusPosAndVel(focusCoords.x, focusCoords.y, focusCoords.z, 0.0, 0.0, 0.0)

        -- ─── 2. Crear cámara en la posición del corredor
        DoScreenFadeOut(200)
        streamCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        SetCamCoord(streamCam, focusCoords.x, focusCoords.y, focusCoords.z + camDist)
        SetCamRot(streamCam, 0.0, 0.0, 0.0, 2)
        SetCamFov(streamCam, 65.0)
        SetCamActive(streamCam, true)
        RenderScriptCams(true, false, 0, true, true)
        DoScreenFadeIn(300)


        -- ─── 3. Esperar 1 segundo para que el ped esté totalmente cargado
        --        (igual que origen_police)
        Citizen.Wait(1000)

        if not isStreaming then return end  -- salieron mientras esperábamos

        -- ─── 4. Verificar ped y actualizar coords conocidas
        local targetPed = GetTargetPlayerPed()
        if targetPed then
            local c = GetEntityCoords(targetPed)
            targetServerCoords = { x = c.x, y = c.y, z = c.z }
            SetFocusPosAndVel(c.x, c.y, c.z, 0.0, 0.0, 0.0)
        end

        -- ─── 5. En modo primera persona: adjuntar al hueso de cabeza
        if currentCameraMode == 'first' and targetPed then
            local headBone = GetPedBoneIndex(targetPed, 31086)
            AttachCamToPedBone(streamCam, targetPed, headBone, 0.0, 0.0, -0.05, true)
        end
        -- En modo third/cinematic: UpdateStreamCamera se encarga cada frame

        SendStreamingStateToNUI()
    end)
end

-- ========================================
-- ACTUALIZACIÓN FRAME A FRAME
-- ========================================

local function UpdateStreamCamera()
    if not isStreaming or not streamCam then return end

    local targetPed = GetTargetPlayerPed()
    if not targetPed then
        -- Ped no disponible: mantener focus en última posición conocida
        if targetServerCoords then
            SetFocusPosAndVel(targetServerCoords.x, targetServerCoords.y, targetServerCoords.z, 0.0, 0.0, 0.0)
        end
        return
    end

    local vehicle = GetVehiclePedIsIn(targetPed, false)
    local entity  = vehicle ~= 0 and vehicle or targetPed
    local coords  = GetEntityCoords(entity)

    -- Asegurar alpha 255 en la entidad objetivo (evita aspecto semi-transparente)
    if GetEntityAlpha(entity) < 255 then
        ResetEntityAlpha(entity)
    end
    if GetEntityAlpha(targetPed) < 255 then
        ResetEntityAlpha(targetPed)
    end

    -- Actualizar focus y posición conocida
    SetFocusPosAndVel(coords.x, coords.y, coords.z, 0.0, 0.0, 0.0)
    targetServerCoords = { x = coords.x, y = coords.y, z = coords.z }

    if currentCameraMode == 'first' then
        -- La cámara adjunta al hueso se mueve automáticamente;
        -- solo sincronizamos rotación con el vehículo/ped
        if vehicle ~= 0 then
            local rot = GetEntityRotation(vehicle, 2)
            SetCamRot(streamCam, rot.x, rot.y, rot.z, 2)
        else
            SetCamRot(streamCam, 0.0, 0.0, GetEntityHeading(targetPed), 2)
        end

    else
        -- Modo orbital / cinemático
        DisableControlAction(0, 1, true)
        DisableControlAction(0, 2, true)
        DisableControlAction(0, 142, true)

        local sens = 25.0
        camYaw   = camYaw   + GetDisabledControlNormal(0, 1) * sens
        camPitch = math.max(-15.0, math.min(70.0, camPitch - GetDisabledControlNormal(0, 2) * sens))

        -- Zoom con rueda
        local wd = GetDisabledControlNormal(0, 14)
        local wu = GetDisabledControlNormal(0, 15)
        if wd ~= 0 then camDist = math.max(2.0, math.min(25.0, camDist + wd * 3.0)) end
        if wu ~= 0 then camDist = math.max(2.0, math.min(25.0, camDist - wu * 3.0)) end

        local radYaw   = math.rad(camYaw)
        local radPitch = math.rad(camPitch)
        local cx = coords.x + camDist * math.cos(radPitch) * math.sin(radYaw)
        local cy = coords.y + camDist * math.cos(radPitch) * math.cos(radYaw)
        local cz = coords.z + camDist * math.sin(radPitch) + 0.5

        -- Evitar que la cámara traverse el suelo (rate-limited: 1 raycast cada 10 frames)
        groundCheckFrame = groundCheckFrame + 1
        if groundCheckFrame >= 10 then
            groundCheckFrame = 0
            local groundFound, groundZ = GetGroundZFor_3dCoord(cx, cy, cz + 2.0, false)
            if groundFound then cachedGroundZ = groundZ end
        end
        if cachedGroundZ and cz < cachedGroundZ + 0.4 then
            cz = cachedGroundZ + 0.4
        end

        SetCamCoord(streamCam, cx, cy, cz)
        PointCamAtEntity(streamCam, entity, 0.0, 0.0, 0.5, true)

        if currentCameraMode == 'cinematic' and vehicle ~= 0 then
            local speed = GetEntitySpeed(vehicle)
            SetCamFov(streamCam, math.min(55.0 + speed * 0.1, 82.0))
        end
    end
end

-- ========================================
-- NAVEGACIÓN (SOLO manual con flechas)
-- ========================================

local function SwitchToParticipant(index, newCoords)
    if #streamParticipants == 0 then return end
    if index < 1 then index = #streamParticipants end
    if index > #streamParticipants then index = 1 end

    streamParticipantIndex = index
    currentTargetServerId  = streamParticipants[index].serverId
    targetServerCoords     = newCoords
    camYaw   = 180.0
    camPitch = 20.0

    -- Actualizar el NUI inmediatamente para que las stats cambien al instante
    SendStreamingStateToNUI()

    StartCameraOnTarget(newCoords)
end

local function StreamNextPlayer()  SwitchToParticipant(streamParticipantIndex + 1, nil) end
local function StreamPrevPlayer()  SwitchToParticipant(streamParticipantIndex - 1, nil) end

local function CycleCameraMode()
    local modes = { 'third', 'first', 'cinematic' }
    local idx = 1
    for i, m in ipairs(modes) do if m == currentCameraMode then idx = i; break end end
    currentCameraMode = modes[(idx % #modes) + 1]
    camYaw = 180.0
    StartCameraOnTarget(targetServerCoords)
    SendStreamingStateToNUI()
end

local function StopStreaming()
    isStreaming            = false
    currentTargetServerId  = nil
    streamParticipants     = {}
    streamParticipantIndex = 1
    targetServerCoords     = nil
    camYaw   = 180.0
    camPitch = 20.0
    camDist  = 7.0

    DestroyStreamCam()
    ClearFocus()  -- Restaurar streaming normal de GTA

    -- Limpiar cualquier HUD de carrera que pudiera quedar visible
    SendNUIMessage({ action = 'streaming:stopped' })
    SendNUIMessage({ action = 'closeRaceHUD' })
    SoltarFocoCarreras(false)
end

-- ========================================
-- EVENTOS DE RED
-- ========================================

RegisterNetEvent('racing:streaming:start', function(targetServerId, participants, serverCoords)

    isStreaming            = true
    currentTargetServerId  = targetServerId
    currentCameraMode      = 'third'
    camYaw   = 180.0
    camPitch = 20.0
    camDist  = 7.0
    targetServerCoords     = serverCoords

    streamParticipants     = participants or {}
    streamParticipantIndex = 1
    for i, p in ipairs(streamParticipants) do
        if p.serverId == targetServerId then
            streamParticipantIndex = i
            break
        end
    end

    StartCameraOnTarget(serverCoords)
end)

RegisterNetEvent('racing:streaming:stopCamera', function()
    StopStreaming()
end)

-- La carrera terminó mientras estábamos especteando:
-- parar la cámara y mostrar el panel de resultados
RegisterNetEvent('racing:streaming:raceFinished', function(data)
    if not isStreaming then return end

    StopStreaming()

    -- Pequeña espera para que la UI de streaming cierre antes de abrir resultados
    Citizen.Wait(600)

    -- El panel de resultados de siempre, con su unico hilo de Retroceso
    -- (AbrirResultados, client/racing.lua).
    AbrirResultados({
        raceId      = data.raceId,
        isTerritory = data.isTerritory or false
    })
end)

RegisterNetEvent('racing:streaming:switchToPlayer', function(targetServerId)
    if not isStreaming then return end
    currentTargetServerId = targetServerId
    for i, p in ipairs(streamParticipants) do
        if p.serverId == targetServerId then streamParticipantIndex = i; break end
    end
    camYaw = 180.0
    -- Intentar obtener coords actuales del ped
    local coords = nil
    local ped = GetTargetPlayerPed()
    if ped then
        local c = GetEntityCoords(ped)
        coords = { x = c.x, y = c.y, z = c.z }
    end
    SwitchToParticipant(streamParticipantIndex, coords)
end)

RegisterNetEvent('racing:streaming:changeCameraMode', function(mode)
    if not isStreaming then return end
    currentCameraMode = mode
    camYaw = 180.0
    StartCameraOnTarget(targetServerCoords)
    SendStreamingStateToNUI()
end)

RegisterNetEvent('racing:streaming:setParticipants', function(participants)
    if not isStreaming then return end
    streamParticipants = participants or {}

    -- Mantener el corredor actual por serverId (el array llega reordenado por posición)
    local newIndex = streamParticipantIndex
    for i, p in ipairs(streamParticipants) do
        if p.serverId == currentTargetServerId then
            newIndex = i
            break
        end
    end
    if newIndex > #streamParticipants then newIndex = 1 end
    streamParticipantIndex = newIndex

    SendStreamingStateToNUI()
end)

-- ========================================
-- NUI CALLBACKS
-- ========================================

RegisterNUICallback('streaming:exitFromNUI', function(data, cb)
    TriggerServerEvent('racing:streaming:unregisterSpectator')
    StopStreaming()
    cb('ok')
end)

-- ========================================
-- THREAD PRINCIPAL
-- ========================================

Citizen.CreateThread(function()
    while true do
        if isStreaming then
            UpdateStreamCamera()

            -- Flechas ← → : cambiar corredor (solo manual)
            if IsDisabledControlJustPressed(0, 174) or IsDisabledControlJustPressed(0, 172) then
                StreamPrevPlayer()
            end
            if IsDisabledControlJustPressed(0, 175) or IsDisabledControlJustPressed(0, 173) then
                StreamNextPlayer()
            end
            --[[ V: ciclar modo cámara. La V es el control 0 (cambiar de
                 camara); antes se leia el 199, que es la P de la PAUSA: la
                 camara cambiaba y de paso se abria el menu del juego. Se
                 anulan cada fotograma la V (que no cambie tambien la camara
                 del propio jugador) y las dos teclas de pausa. ]]
            DisableControlAction(0, 0, true)
            DisableControlAction(0, 199, true)
            DisableControlAction(0, 200, true)
            if IsDisabledControlJustPressed(0, 0) then
                CycleCameraMode()
            end
            -- BACKSPACE: salir (también desregistrar del servidor)
            if IsDisabledControlJustPressed(0, 194) then
                TriggerServerEvent('racing:streaming:unregisterSpectator')
                StopStreaming()
            end

            Citizen.Wait(0)
        else
            Citizen.Wait(500)
        end
    end
end)

