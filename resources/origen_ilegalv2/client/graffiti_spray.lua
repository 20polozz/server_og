-- ── Guard: si el sistema interno de graffiti está desactivado, no registrar nada ──
if not Config.Graffiti or not Config.Graffiti.Enable then return end

local isPlacingGraffiti  = false
local isSprayingGraffiti = false
local previewDui         = nil
local previewCoords      = nil
local scale              = 1.0
local rotation           = 0.0
local transparencia      = 255
local ground             = false
local currentImageUrl    = nil
local duiCounter         = 0
local duiSessionId       = tostring(GetGameTimer())  -- unique per resource start, avoids TXD name collision
local placementGen       = 0    -- increments each StartPlacementMode; prevents stale DUI callbacks
local sprayCanProp       = nil
local sprayProgress      = 0.0  -- 0.0→1.0 durante los 60s

local dbg = Debug:new({ enabled = Config.Debug })

-- ── Animaciones ────────────────────────────────────────────────────────────

local MALE_DICT   = 'anim@scripted@freemode@postertag@graffiti_spray@male@'
local FEMALE_DICT = 'anim@scripted@freemode@postertag@graffiti_spray@heeled@'

local PREVIEW_ANIM_M = 'shake_can_male'
local PREVIEW_ANIM_F = 'shake_can_female'

-- Secuencia durante los 60s (30s cada anim, sin shake_can)
local SPRAY_SEQ_M = { 'spray_can_var_01_male',   'spray_can_var_02_male'   }
local SPRAY_SEQ_F = { 'spray_can_var_01_female', 'spray_can_var_02_female' }

local SPRAY_DURATION = Config.Graffiti.SprayDuration
local ANIM_SWITCH_MS = math.floor(SPRAY_DURATION / 2)  -- 2 anims × mitad cada una

-- ── Helpers ────────────────────────────────────────────────────────────────

local function RotationToDirection(rot)
    local rx = math.rad(rot.x)
    local rz = math.rad(rot.z)
    return vector3(
        -math.sin(rz) * math.abs(math.cos(rx)),
         math.cos(rz) * math.abs(math.cos(rx)),
         math.sin(rx)
    )
end

local function GetSurfaceHeading(normal)
    if normal.z > 0.7 then
        return GetGameplayCamRot(2).z
    else
        return math.deg(math.atan2(normal.x, -normal.y))
    end
end

-- Devuelve true si el ped usa un modelo masculino.
local function IsMalePed(ped)
    return GetEntityModel(ped) ~= GetHashKey('mp_f_freemode_01')
end

local function LoadAnimDict(dict)
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        local t = 0
        while not HasAnimDictLoaded(dict) and t < 30 do
            Wait(100)
            t = t + 1
        end
    end
end

-- canMove=true  → flag 49: upper body + loop, piernas libres (preview)
-- canMove=false → flag  1: cuerpo completo, loop (spray)
local function PlayAnim(ped, dict, anim, canMove)
    LoadAnimDict(dict)
    local flags = canMove and 49 or 1
    -- blendIn 8.0 para sobreescribir cualquier animación en curso sin glitch
    TaskPlayAnim(ped, dict, anim, 8.0, -1.0, -1, flags, 0.0, false, false, false)
end

-- ── Prop spray can ─────────────────────────────────────────────────────────

local function AttachSprayCan(ped)
    local model = GetHashKey('prop_cs_spray_can')
    RequestModel(model)
    local t = 0
    while not HasModelLoaded(model) and t < 30 do Wait(100); t = t + 1 end

    local prop      = CreateObject(model, 0.0, 0.0, 0.0, true, true, false)
    local boneIndex = GetPedBoneIndex(ped, 28422)
    AttachEntityToEntity(prop, ped, boneIndex,
        0.0, 0.0, 0.07, 0.001736, 0.0, 0.0,
        true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(model)
    return prop
end

local function DetachSprayCan()
    if sprayCanProp and DoesEntityExist(sprayCanProp) then
        DeleteObject(sprayCanProp)
        sprayCanProp = nil
    end
end

-- ── Raycast ────────────────────────────────────────────────────────────────

local lastCamCoord = nil
local lastCamDir   = nil
local lastHitCoord = nil
local lastHitNorm  = nil
local lastError    = nil

local function Raycast(ped)
    local camRot   = GetGameplayCamRot(2)
    local camCoord = GetGameplayCamCoord()
    local dir      = RotationToDirection(camRot)

    if lastCamCoord == camCoord and lastCamDir == dir then
        return lastHitCoord, lastHitNorm
    end
    lastCamCoord = camCoord
    lastCamDir   = dir

    local dest = camCoord + dir * 100.0
    local ray   = StartShapeTestRay(
        camCoord.x, camCoord.y, camCoord.z,
        dest.x, dest.y, dest.z,
        1 | 16 | 256, ped
    )
    local _, hit, hitCoord, hitNorm = GetShapeTestResult(ray)

    if hit == 1 then
        local pedCoord = GetEntityCoords(ped)
        if #(pedCoord - hitCoord) <= 10.0 then
            ground       = hitNorm.z > 0.7
            lastHitCoord = hitCoord
            lastHitNorm  = hitNorm
            lastError    = nil
            return hitCoord, hitNorm
        else
            lastError = 'Demasiado lejos'
        end
    else
        lastError = 'Apunta a una superficie'
    end
    lastHitCoord = nil
    lastHitNorm  = nil
    return nil, nil
end

-- ── DUI (asíncrona) ────────────────────────────────────────────────────────

local function CreateGraffitiDui(url, onReady)
    duiCounter = duiCounter + 1
    -- Include session ID in names to avoid collisions with TXDs from previous resource runs
    local txd = 'graffiti_preview_txd_' .. duiSessionId .. '_' .. duiCounter
    local txn = 'graffiti_preview_tex_' .. duiSessionId .. '_' .. duiCounter

    CreateThread(function()
        local resourceName = GetCurrentResourceName()
        local dui = CreateDui(('nui://%s/ui/graffiti_viewer.html'):format(resourceName), 512, 512)

        -- Esperar a que el WebKit process esté disponible ANTES de obtener el handle
        local timeout = 0
        while not IsDuiAvailable(dui) and timeout < 50 do
            Wait(100); timeout = timeout + 1
        end

        -- Crear la textura runtime DESPUÉS de que el DUI esté disponible
        local txdHandle = CreateRuntimeTxd(txd)
        local duiHandle = GetDuiHandle(dui)
        CreateRuntimeTextureFromDuiHandle(txdHandle, txn, duiHandle)

        -- Breve espera para que el DOM esté listo antes de enviar mensajes
        Wait(300)

        -- Enviar loadImage con reintentos
        local msg = json.encode({ action = 'loadImage', url = url })
        SendDuiMessage(dui, msg)
        Wait(300)
        SendDuiMessage(dui, msg)  -- retry 1
        Wait(300)
        SendDuiMessage(dui, msg)  -- retry 2
        Wait(100)

        if onReady then onReady({ dui = dui, txd = txd, txn = txn }) end
    end)
end

-- ── Draw ───────────────────────────────────────────────────────────────────

local function DrawGraffitiMarker(duiData, coords, cfg)
    local g       = cfg.ground ~= nil and cfg.ground or ground
    local heading = coords.w or 0.0
    local rotX    = (cfg.rotation or 0.0) - heading
    local rotY    = g and 270.0 or 90.0
    local rotZ    = g and 90.0  or  0.0
    local s       = cfg.scale or 1.0
    local alpha   = cfg.transparencia or 255

    DrawMarker(
        3,
        coords.x, coords.y, coords.z,
        0.0, 0.0, 0.0,
        rotX, rotY, rotZ,
        s, s, s,
        255, 255, 255, alpha,
        false, false, 2, false,
        duiData.txd, duiData.txn, false
    )
end

-- ── Partículas ─────────────────────────────────────────────────────────────

local function SprayEffect()
    local dict = 'scr_recartheft'
    local name = 'scr_wheel_burnout'
    local ped  = PlayerPedId()
    local fwd  = GetEntityForwardVector(ped)
    local pos  = GetEntityCoords(ped) + fwd * 0.5
    local hdg  = GetEntityHeading(ped)

    RequestNamedPtfxAsset(dict)
    while not HasNamedPtfxAssetLoaded(dict) do Wait(0) end

    UseParticleFxAssetNextCall(dict)
    SetParticleFxNonLoopedColour(1.0, 0.0, 0.0)
    SetParticleFxNonLoopedAlpha(1.0)
    StartParticleFxNonLoopedAtCoord(
        name, pos.x, pos.y, pos.z + 1.0,
        0.0, 0.0, hdg, 0.5, false, false, false
    )
    RemoveNamedPtfxAsset(dict)
end

-- ── Fase de spray: 60s ─────────────────────────────────────────────────────

local function StartSprayPhase(ped, isMale, savedCoords, savedDui, savedImageUrl, cfg)
    isSprayingGraffiti = true
    sprayProgress      = 0.0

    local dict = isMale and MALE_DICT or FEMALE_DICT
    local seq  = isMale and SPRAY_SEQ_M or SPRAY_SEQ_F

    FreezeEntityPosition(ped, true)
    PlayAnim(ped, dict, seq[1], false)

    -- Notificar al servidor para la posible alerta policial (un testigo podría llamar a la policía)
    TriggerServerEvent('origen_gang:server:graffitiSprayAlert', {
        coords = vector3(savedCoords.x, savedCoords.y, savedCoords.z)
    })

    MostrarTeclas({ { key = 'BACKSPACE', text = locale:t('ui.cancel') } })

    -- Thread progressbar: corre en su propio thread para no bloquear el timer
    CreateThread(function()
        ProgressBar.Open({ duration = SPRAY_DURATION, label = locale:t('notify.graffiti_spraying_progress'), canCancel = false })
    end)

    -- Thread A: temporizador + rotación de animaciones + lógica de fin
    CreateThread(function()
        local elapsed   = 0
        local animTimer = 0
        local animIdx   = 1
        local cancelled = false

        while elapsed < SPRAY_DURATION and isSprayingGraffiti do
            Wait(500)
            elapsed   = elapsed   + 500
            animTimer = animTimer + 500
            sprayProgress = elapsed / SPRAY_DURATION

            -- Cambio de animación cada ANIM_SWITCH_MS
            if animTimer >= ANIM_SWITCH_MS then
                animTimer = 0
                animIdx = (animIdx % #seq) + 1
                PlayAnim(ped, dict, seq[animIdx], false)
            end

            if IsEntityDead(ped) then
                isSprayingGraffiti = false
                cancelled = true
            end
        end

        if not cancelled and not isSprayingGraffiti then
            cancelled = true
        end
        isSprayingGraffiti = false

        -- Limpiar
        StopAnimTask(ped, dict, seq[animIdx], 2.0)
        ClearPedTasksImmediately(ped)
        FreezeEntityPosition(ped, false)
        DetachSprayCan()
        QuitarTeclas()

        if not cancelled then
            local territory   = exports[GetCurrentResourceName()]:GetCurrentTerritory()
            local territoryId = territory and territory.id or nil
            TriggerServerEvent('origen_gang:server:placeGraffiti', {
                coords      = savedCoords,
                imageUrl    = savedImageUrl,
                config      = cfg,
                territoryId = territoryId,
            })
            SprayEffect()
            -- Breve espera para que el manager cargue su propio DUI antes de destruir el nuestro
            Wait(2000)
        else
            Notify.SendNotification(locale:t('notify.cancelled_title'), locale:t('notify.graffiti_place_cancelled'), 'error')
        end

        -- Destruir DUI del preview
        if savedDui then DestroyDui(savedDui.dui) end
    end)

    -- Thread B: partículas continuas durante todo el spray
    CreateThread(function()
        local ptfxDict = 'scr_recartheft'
        local ptfxName = 'scr_wheel_burnout'

        RequestNamedPtfxAsset(ptfxDict)
        local t = 0
        while not HasNamedPtfxAssetLoaded(ptfxDict) and t < 20 do
            Wait(100); t = t + 1
        end

        while isSprayingGraffiti do
            if sprayCanProp and DoesEntityExist(sprayCanProp) then
                local pos = GetEntityCoords(sprayCanProp)
                local hdg = GetEntityHeading(PlayerPedId())

                UseParticleFxAssetNextCall(ptfxDict)
                SetParticleFxNonLoopedColour(0.85, 0.1, 0.1)
                SetParticleFxNonLoopedAlpha(0.9)
                StartParticleFxNonLoopedAtCoord(
                    ptfxName,
                    pos.x, pos.y, pos.z,
                    0.0, 0.0, hdg,
                    0.2, false, false, false
                )
            end
            Wait(150)
        end

        RemoveNamedPtfxAsset(ptfxDict)
    end)

    -- Thread C: dibujar el graffiti apareciendo gradualmente (opacidad 0 → target)
    CreateThread(function()
        while isSprayingGraffiti do
            if savedDui and savedCoords then
                local currentAlpha = math.max(5, math.floor(sprayProgress * cfg.transparencia))
                DrawGraffitiMarker(savedDui, savedCoords, {
                    scale         = cfg.scale,
                    rotation      = cfg.rotation,
                    transparencia = currentAlpha,
                    ground        = cfg.ground,
                })
            end
            Wait(0)
        end
    end)

    -- Thread D: ESC o BACKSPACE durante el spray
    CreateThread(function()
        while isSprayingGraffiti do
            DisableControlAction(0, 322, true)  -- ESC
            DisableControlAction(0, 200, true)  -- pausa
            DisableControlAction(0, 177, true)  -- retroceder / BACKSPACE

            if IsDisabledControlJustPressed(0, 322) or IsDisabledControlJustPressed(0, 177) then
                isSprayingGraffiti = false
            end
            Wait(0)
        end
    end)
end

-- ── Confirmar (ENTER) ──────────────────────────────────────────────────────

local function ConfirmPlacement()
    if not previewCoords then return end

    local savedCoords   = previewCoords
    local savedImageUrl = currentImageUrl
    local savedDui      = previewDui   -- traspasamos ownership al spray phase
    local cfg = {
        scale         = scale,
        rotation      = rotation,
        transparencia = transparencia,
        ground        = ground,
    }

    -- Salir del modo preview sin destruir la DUI (la hereda el spray phase)
    previewDui        = nil
    isPlacingGraffiti = false
    currentImageUrl   = nil
    HelpText.HideHelpText()
    SendNUIMessage({ action = 'hideControls' })

    local ped    = PlayerPedId()
    local isMale = IsMalePed(ped)

    -- Limpiar la animación de preview ANTES de empezar el spray
    ClearPedTasksImmediately(ped)

    StartSprayPhase(ped, isMale, savedCoords, savedDui, savedImageUrl, cfg)
end

-- ── Cancelar (ESC) preview ─────────────────────────────────────────────────

local function CancelPlacement()
    if previewDui then
        DestroyDui(previewDui.dui)
        previewDui = nil
    end
    isPlacingGraffiti = false
    currentImageUrl   = nil

    local ped = PlayerPedId()
    ClearPedTasksImmediately(ped)
    DetachSprayCan()

    HelpText.HideHelpText()
    SendNUIMessage({ action = 'hideControls' })
    Notify.SendNotification(locale:t('notify.cancelled_title'), locale:t('notify.graffiti_place_cancelled'), 'error')
end

-- ── Placement Mode (preview) ───────────────────────────────────────────────

local function StartPlacementMode(imageUrl)
    if isPlacingGraffiti or isSprayingGraffiti then return end

    placementGen      = placementGen + 1   -- invalidate any pending DUI callbacks from previous sessions
    local myGen       = placementGen

    isPlacingGraffiti = true
    currentImageUrl   = imageUrl
    scale             = 1.0
    rotation          = 0.0
    transparencia     = 255
    ground            = false
    previewDui        = nil
    previewCoords     = nil
    lastCamCoord      = nil
    lastCamDir        = nil
    lastHitCoord      = nil
    lastHitNorm       = nil
    lastError         = nil

    local ped    = PlayerPedId()
    local isMale = IsMalePed(ped)
    local dict   = isMale and MALE_DICT   or FEMALE_DICT
    local anim   = isMale and PREVIEW_ANIM_M or PREVIEW_ANIM_F

    -- Prop + animación de preview (upper body, movimiento libre)
    sprayCanProp = AttachSprayCan(ped)
    PlayAnim(ped, dict, anim, true)

    -- Las teclas ya salen en la barra de abajo (GraffitiControls.vue)
    Notify.SendNotification('Colocar grafiti', 'Apunta a una superficie', 'info', 3000)

    SendNUIMessage({ action = 'showControls' })
    SendNUIMessage({ action = 'updateValues', scale = scale, rotation = rotation, transparencia = transparencia })

    -- Thread 1: raycast + DUI
    CreateThread(function()
        local lastErrorShown = nil
        local duiCreating    = false

        while isPlacingGraffiti do
            local hitCoord, hitNorm = Raycast(ped)

            if hitCoord and hitNorm then
                local heading = GetSurfaceHeading(hitNorm)
                local offset  = 0.04
                previewCoords = vector4(
                    hitCoord.x + hitNorm.x * offset,
                    hitCoord.y + hitNorm.y * offset,
                    hitCoord.z + hitNorm.z * offset,
                    heading
                )

                if not previewDui and not duiCreating then
                    duiCreating = true
                    CreateGraffitiDui(currentImageUrl, function(duiData)
                        -- Only assign if still in the SAME placement session (prevents stale callbacks
                        -- from a previous session leaking into the current one)
                        if isPlacingGraffiti and placementGen == myGen then
                            previewDui = duiData
                        else
                            DestroyDui(duiData.dui)
                        end
                    end)
                end

                if lastErrorShown then
                    HelpText.HideHelpText()
                    lastErrorShown = nil
                end
            else
                previewCoords = nil
                if lastError and lastError ~= lastErrorShown then
                    HelpText.ShowHelpText(lastError, 'top-center')
                    lastErrorShown = lastError
                end
            end

            Wait(0)
        end

        HelpText.HideHelpText()
        SendNUIMessage({ action = 'hideControls' })
    end)

    -- Thread 2: dibujo del preview
    CreateThread(function()
        while isPlacingGraffiti do
            if previewDui and previewCoords then
                DrawGraffitiMarker(previewDui, previewCoords, {
                    scale         = scale,
                    rotation      = rotation,
                    transparencia = transparencia,
                    ground        = ground,
                })
            end
            Wait(0)
        end
    end)

    -- Thread 3: controles
    CreateThread(function()
        while isPlacingGraffiti do
            DisableControlAction(0, 241, true)
            DisableControlAction(0, 242, true)
            DisableControlAction(0, 322, true)
            DisableControlAction(0, 200, true)

            local ctrl  = IsDisabledControlPressed(0, 36)
            local shift = IsDisabledControlPressed(0, 21)

            if IsDisabledControlJustPressed(0, 241) then
                if ctrl and not shift then
                    transparencia = math.min(transparencia + 15, 255)
                elseif shift and not ctrl then
                    rotation = rotation + 5.0
                else
                    scale = math.min(scale + 0.1, 10.0)
                end
                SendNUIMessage({ action = 'updateValues', scale = scale, rotation = rotation, transparencia = transparencia })
            end

            if IsDisabledControlJustPressed(0, 242) then
                if ctrl and not shift then
                    transparencia = math.max(transparencia - 15, 100)
                elseif shift and not ctrl then
                    rotation = rotation - 5.0
                else
                    scale = math.max(scale - 0.1, 0.5)
                end
                SendNUIMessage({ action = 'updateValues', scale = scale, rotation = rotation, transparencia = transparencia })
            end

            if IsControlJustPressed(0, 191) then
                ConfirmPlacement()
            end

            if IsDisabledControlJustPressed(0, 322) then
                CancelPlacement()
            end

            Wait(0)
        end
    end)
end

-- ── Evento ────────────────────────────────────────────────────────────────

RegisterNetEvent('origen_gang:client:startGraffitiPlacement', function(imageUrl)
    if not imageUrl then return end
    StartPlacementMode(imageUrl)
end)
