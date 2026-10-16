local cam
local installedCCTVCameras = {}  -- { [id] = entityHandle }
local cctvCamerasData = {} -- { [id] = serverData }

function GetInstalledCamList()
    local result = {}
    for id, camData in pairs(cctvCamerasData) do
        local camId = tonumber(camData.id) or tonumber(id)
        local obj = installedCCTVCameras[camId] or 0
        local alive = obj ~= 0 and DoesEntityExist(obj) and GetEntityHealth(obj) >= 900
        result[#result + 1] = {
            id = camId,
            label = camData.label or ("Cámara #" .. tostring(camId)),
            placerName = camData.placerName,
            coords = camData.coords,
            obj = obj,
            online = alive,
        }
    end
    table.sort(result, function(a, b) return (a.id or 0) < (b.id or 0) end)
    return result
end

function RefreshInstalledCamsUI()
    SendNUIMessage({ action = "RefreshInstalledCams", cams = GetInstalledCamList() })
end

local currentCamType = nil
local currentCamTarget = nil

local bodycamAudioCam = nil
local currentAudioCamTarget = nil

local function LimpiarFocoEntornoBodycam()
    if bodycamAudioCam then
        if DoesCamExist(bodycamAudioCam) then
            SetCamActive(bodycamAudioCam, false)
            DestroyCam(bodycamAudioCam, false)
        end
        RenderScriptCams(false, false, 0, true, false)
        bodycamAudioCam = nil
        currentAudioCamTarget = nil
    end
    ClearFocus()
end

function StopCurrentCam()
    if cam then
        SetCamActive(cam, false)
        DestroyCam(cam, true)
        RenderScriptCams(false, false, 0, true, false)
        cam = nil
    end
    LimpiarFocoEntornoBodycam()
    ClearTimecycleModifier()
    ClearFocus()
    FreezeEntityPosition(PlayerPedId(), false)
    currentCamType = nil
    currentCamTarget = nil
    SendNUIMessage({
        action = "nosignal",
        toggle = false
    })
end

RegisterNUICallback("StopCam", function(data, cb)
    StopCurrentCam()
    if cb then cb(true) end
end)

RegisterNetEvent("origen_police:client:StopCam", function()
    StopCurrentCam()
end)

AddEventHandler("origen_police:client:tabletClosed", function()
    StopCurrentCam()
    DetenerAudioBodycam(nil)
    FW_TriggerCallback("origen_police:server:bodycamPararTodas", function() end)
    SendNUIMessage({ action = "bodycam:cerrarTodas" })
end)

-- ============================================================
-- GESTOR DE AUDIO Y ENTORNO DE BODYCAMS (MUMBLE + ENTORNO 3D)
-- ============================================================
local activeBodycamAudio = {} -- [sessionId] = { targetId = number, channel = number, muted = boolean, listeners = { [source] = channel } }
local focusedBodycamSession = nil
local lastKnownBodycamCoords = {} -- [targetId] = vector3
local bodycamAudioThreadActive = false

local function ActualizarFocoEntornoBodycam()
    if bodycamAudioThreadActive then return end
    bodycamAudioThreadActive = true

    CreateThread(function()
        while true do
            local hayUnmuted = false
            local targetActivo = nil

            -- Si hay sesión enfocada y no está muteada, esa es la prioritaria
            if focusedBodycamSession and activeBodycamAudio[focusedBodycamSession] and not activeBodycamAudio[focusedBodycamSession].muted then
                targetActivo = activeBodycamAudio[focusedBodycamSession].targetId
                hayUnmuted = true
            else
                -- Si no, buscar la primera activa no muteada
                for _, sData in pairs(activeBodycamAudio) do
                    if not sData.muted and sData.targetId then
                        targetActivo = sData.targetId
                        hayUnmuted = true
                        break
                    end
                end
            end

            if not hayUnmuted or not targetActivo then
                break
            end

            -- Resolver coordenadas y ped del objetivo (ped local si existe en rango, o coords sincronizadas)
            local coords = nil
            local ped = nil
            local targetPlayer = GetPlayerFromServerId(targetActivo)
            if targetPlayer and targetPlayer ~= -1 then
                local p = GetPlayerPed(targetPlayer)
                if p and p > 0 and DoesEntityExist(p) then
                    ped = p
                    coords = GetEntityCoords(ped)
                    lastKnownBodycamCoords[targetActivo] = coords
                end
            end

            if not coords and lastKnownBodycamCoords[targetActivo] then
                coords = lastKnownBodycamCoords[targetActivo]
            end

            if coords then
                -- 1. Crear cámara de audio ambiental en la posición del agente si no existe
                if not bodycamAudioCam or not DoesCamExist(bodycamAudioCam) then
                    bodycamAudioCam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", coords.x, coords.y, coords.z + 0.8, 0.0, 0.0, 0.0, 65.0, false, 2)
                    SetCamActive(bodycamAudioCam, true)
                    RenderScriptCams(true, false, 0, true, false)
                    currentAudioCamTarget = nil
                end

                -- 2. Si el ped está disponible en rango, adjuntar al hueso de la cabeza (31086) y fijar oyente 3D
                if ped and DoesEntityExist(ped) then
                    if currentAudioCamTarget ~= targetActivo then
                        local headBone = GetPedBoneIndex(ped, 31086)
                        AttachCamToPedBone(bodycamAudioCam, ped, (headBone and headBone ~= -1) and headBone or 0, 0.0, 0.18, 0.0, true)
                        currentAudioCamTarget = targetActivo
                    end

                    local rot = GetEntityRotation(ped, 2)
                    SetCamRot(bodycamAudioCam, rot.x, rot.y, rot.z, 2)

                    local veh = GetVehiclePedIsIn(ped, false)
                    if veh and veh ~= 0 and DoesEntityExist(veh) then
                        SetFocusEntity(veh)
                        pcall(SetAudioVehiclePriority, veh)
                    else
                        SetFocusEntity(ped)
                    end
                else
                    if currentAudioCamTarget then
                        DetachCam(bodycamAudioCam)
                        currentAudioCamTarget = nil
                    end
                    SetCamCoord(bodycamAudioCam, coords.x, coords.y, coords.z + 0.8)
                    SetFocusPosAndVel(coords.x, coords.y, coords.z, 0.0, 0.0, 0.0)
                    pcall(SetFocusArea, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0)
                end
            end

            -- Reintentar conectar canales Mumble y mantener volumenes
            for _, sData in pairs(activeBodycamAudio) do
                if not sData.muted and sData.targetId then
                    local ch = sData.channel
                    if not ch or ch <= 0 then
                        ch = (Player(sData.targetId).state and Player(sData.targetId).state.assignedChannel) or MumbleGetVoiceChannelFromServerId(sData.targetId)
                        if ch and ch > 0 then
                            sData.channel = ch
                        end
                    end

                    if sData.channel and sData.channel > 0 then
                        if not sData.listeners then sData.listeners = {} end
                        if sData.listeners[sData.targetId] ~= sData.channel then
                            if sData.listeners[sData.targetId] then
                                MumbleRemoveVoiceChannelListen(sData.listeners[sData.targetId])
                            end
                            MumbleAddVoiceChannelListen(sData.channel)
                            sData.listeners[sData.targetId] = sData.channel
                        end
                        MumbleSetVolumeOverrideByServerId(sData.targetId, 1.0)
                    end

                    if sData.nearbyVolumes then
                        for pSrc, vol in pairs(sData.nearbyVolumes) do
                            MumbleSetVolumeOverrideByServerId(pSrc, vol)
                        end
                    end
                end
            end

            Wait(100)
        end

        bodycamAudioThreadActive = false
        LimpiarFocoEntornoBodycam()
    end)
end

function DetenerAudioBodycam(sessionId)
    if not sessionId then
        -- Limpiar todas las sesiones
        for _, sData in pairs(activeBodycamAudio) do
            if sData.listeners then
                for pSrc, ch in pairs(sData.listeners) do
                    if ch and ch ~= -1 then
                        MumbleRemoveVoiceChannelListen(ch)
                    end
                    MumbleSetVolumeOverrideByServerId(pSrc, -1.0)
                end
            end
            if sData.channel and sData.channel ~= -1 then
                MumbleRemoveVoiceChannelListen(sData.channel)
            end
            if sData.targetId then
                MumbleSetVolumeOverrideByServerId(sData.targetId, -1.0)
            end
        end
        activeBodycamAudio = {}
        focusedBodycamSession = nil
        LimpiarFocoEntornoBodycam()
        return
    end

    local sData = activeBodycamAudio[sessionId]
    if sData then
        if sData.listeners then
            for pSrc, ch in pairs(sData.listeners) do
                if ch and ch ~= -1 then
                    MumbleRemoveVoiceChannelListen(ch)
                end
                MumbleSetVolumeOverrideByServerId(pSrc, -1.0)
            end
        end
        if sData.channel and sData.channel ~= -1 then
            MumbleRemoveVoiceChannelListen(sData.channel)
        end
        if sData.targetId then
            MumbleSetVolumeOverrideByServerId(sData.targetId, -1.0)
        end
        activeBodycamAudio[sessionId] = nil
        if focusedBodycamSession == sessionId then
            focusedBodycamSession = nil
            currentAudioCamTarget = nil
        end
    end

    local quedaAlguna = false
    for _, d in pairs(activeBodycamAudio) do
        if not d.muted then
            quedaAlguna = true
            break
        end
    end
    if not quedaAlguna then
        LimpiarFocoEntornoBodycam()
    end
end

local function ConfigurarAudioBodycam(sessionId, targetId, muted, coords, channel)
    if not sessionId or not targetId then return end
    targetId = tonumber(targetId)
    local ch = tonumber(channel)

    if coords then
        lastKnownBodycamCoords[targetId] = vector3(coords.x, coords.y, coords.z)
    end

    local sData = activeBodycamAudio[sessionId]
    if not sData then
        local tChannel = ch or (Player(targetId).state and Player(targetId).state.assignedChannel) or MumbleGetVoiceChannelFromServerId(targetId)
        sData = {
            targetId = targetId,
            channel = tChannel and tonumber(tChannel) or nil,
            muted = muted == true,
            listeners = {}
        }
        activeBodycamAudio[sessionId] = sData
    else
        sData.muted = muted == true
        if ch and ch > 0 then
            sData.channel = ch
        end
        if not sData.listeners then sData.listeners = {} end
    end

    if sData.muted then
        if sData.listeners then
            for pSrc, lCh in pairs(sData.listeners) do
                if lCh and lCh ~= -1 then
                    MumbleRemoveVoiceChannelListen(lCh)
                end
                MumbleSetVolumeOverrideByServerId(pSrc, -1.0)
            end
            sData.listeners = {}
        end
        if sData.channel and sData.channel ~= -1 then
            MumbleRemoveVoiceChannelListen(sData.channel)
        end
        MumbleSetVolumeOverrideByServerId(targetId, -1.0)
    else
        if not sData.channel or sData.channel <= 0 then
            sData.channel = ch or (Player(targetId).state and Player(targetId).state.assignedChannel) or MumbleGetVoiceChannelFromServerId(targetId)
        end
        if sData.channel and sData.channel > 0 then
            if sData.listeners[targetId] ~= sData.channel then
                if sData.listeners[targetId] then
                    MumbleRemoveVoiceChannelListen(sData.listeners[targetId])
                end
                MumbleAddVoiceChannelListen(sData.channel)
                sData.listeners[targetId] = sData.channel
            end
            MumbleSetVolumeOverrideByServerId(targetId, 1.0)
        end
        ActualizarFocoEntornoBodycam()
    end
end

-- ============================================================
-- WEBRTC BODYCAMS PUENTE NUI <-> SERVIDOR
-- ============================================================
RegisterNUICallback("BodycamPedir", function(data, cb)
    FW_TriggerCallback("origen_police:server:bodycamPedir", function(res)
        cb(res or { success = false, message = "Sin respuesta del servidor" })
    end, tonumber(data and data.targetId))
end)

RegisterNUICallback("BodycamToggleAudio", function(data, cb)
    if data and data.sessionId and data.targetId then
        ConfigurarAudioBodycam(data.sessionId, tonumber(data.targetId), data.muted, data.coords, data.channel)
    end
    if cb then cb("ok") end
end)

RegisterNUICallback("BodycamFocusAudio", function(data, cb)
    if data and data.sessionId then
        focusedBodycamSession = data.sessionId
        if data.targetId and data.coords then
            lastKnownBodycamCoords[tonumber(data.targetId)] = vector3(data.coords.x, data.coords.y, data.coords.z)
        end
        if data.channel and activeBodycamAudio[data.sessionId] then
            local ch = tonumber(data.channel)
            if ch and ch > 0 then
                activeBodycamAudio[data.sessionId].channel = ch
            end
        end
        ActualizarFocoEntornoBodycam()
    end
    if cb then cb("ok") end
end)

RegisterNUICallback("BodycamStopAudio", function(data, cb)
    DetenerAudioBodycam(data and data.sessionId)
    if cb then cb("ok") end
end)

RegisterNUICallback("BodycamParar", function(data, cb)
    if data and data.sessionId then
        DetenerAudioBodycam(data.sessionId)
    end
    FW_TriggerCallback("origen_police:server:bodycamParar", function(res)
        cb(res or { success = false })
    end, data and data.sessionId)
end)

RegisterNUICallback("BodycamPararTodas", function(_, cb)
    DetenerAudioBodycam(nil)
    FW_TriggerCallback("origen_police:server:bodycamPararTodas", function(res)
        cb(res or { success = false })
    end)
end)

RegisterNUICallback("BodycamOferta", function(data, cb)
    cb("ok")
    TriggerServerEvent("origen_police:server:bodycamOferta", data)
end)

RegisterNUICallback("BodycamRespuesta", function(data, cb)
    cb("ok")
    TriggerServerEvent("origen_police:server:bodycamRespuesta", data)
end)

RegisterNUICallback("BodycamIce", function(data, cb)
    cb("ok")
    TriggerServerEvent("origen_police:server:bodycamIce", data)
end)

-- Monitor de voz y sincronización de coordenadas en juego para emisión de bodycams
local sesionesEmisionActivas = {}
local monitorVozActivo = false
local syncCoordsActivo = false

local function TransmitiendoEnJuego()
    local yo = PlayerId()
    if NetworkIsPlayerTalking(yo) then return true end

    local mumble = MumbleIsPlayerTalking(yo)
    if mumble == true or mumble == 1 then return true end

    if LocalPlayer and LocalPlayer.state and LocalPlayer.state.radioActive then
        return true
    end

    if IsControlPressed(0, 249) or IsDisabledControlPressed(0, 249) then
        return true
    end

    return false
end

local function IniciarMonitorVozEmisor()
    if monitorVozActivo then return end
    monitorVozActivo = true

    CreateThread(function()
        local estadoAnterior = false
        local tiempoFinHablar = 0
        local COLA_MS = 350 -- Mantener micro abierto 350ms tras dejar de hablar para no cortar la frase

        while monitorVozActivo do
            local transmitiendo = TransmitiendoEnJuego()
            local ahora = GetGameTimer()

            local hablando = false
            if transmitiendo then
                hablando = true
                tiempoFinHablar = ahora + COLA_MS
            elseif ahora < tiempoFinHablar then
                hablando = true
            end

            if hablando ~= estadoAnterior then
                estadoAnterior = hablando
                TriggerServerEvent("origen_police:server:bodycamHablando", hablando)
                SendNUIMessage({
                    action = "bodycam:vozEstado",
                    data = { hablando = hablando }
                })
            end

            Wait(transmitiendo and 30 or 80)
        end

        TriggerServerEvent("origen_police:server:bodycamHablando", false)
        SendNUIMessage({
            action = "bodycam:vozEstado",
            data = { hablando = false }
        })
    end)
end

local function DetenerMonitorVozSiVacio()
    if next(sesionesEmisionActivas) == nil then
        monitorVozActivo = false
    end
end

local function IniciarSyncCoordsEmisor()
    if syncCoordsActivo then return end
    syncCoordsActivo = true

    CreateThread(function()
        while syncCoordsActivo do
            local ped = PlayerPedId()
            if DoesEntityExist(ped) then
                local c = GetEntityCoords(ped)
                local myChannel = (LocalPlayer and LocalPlayer.state and LocalPlayer.state.assignedChannel) or MumbleGetVoiceChannelFromServerId(PlayerServerId())
                TriggerServerEvent("origen_police:server:bodycamSyncCoords", { x = c.x, y = c.y, z = c.z }, myChannel)
            end
            Wait(700)
        end
    end)
end

local function DetenerSyncCoordsSiVacio()
    if next(sesionesEmisionActivas) == nil then
        syncCoordsActivo = false
    end
end

RegisterNUICallback("BodycamCerrada", function(data, cb)
    cb("ok")
    if data and data.sessionId then
        sesionesEmisionActivas[data.sessionId] = nil
        DetenerMonitorVozSiVacio()
        DetenerSyncCoordsSiVacio()
    end
    TriggerServerEvent("origen_police:server:bodycamCerrada", data)
end)

RegisterNetEvent("origen_police:client:bodycamEmitir", function(datos)
    if datos and datos.sessionId then
        sesionesEmisionActivas[datos.sessionId] = true
        IniciarMonitorVozEmisor()
        IniciarSyncCoordsEmisor()
    end
    SendNUIMessage({ action = "bodycam:emitir", data = datos })
end)

RegisterNetEvent("origen_police:client:bodycamOferta", function(datos)
    SendNUIMessage({ action = "bodycam:oferta", data = datos })
end)

RegisterNetEvent("origen_police:client:bodycamRespuesta", function(datos)
    SendNUIMessage({ action = "bodycam:respuesta", data = datos })
end)

RegisterNetEvent("origen_police:client:bodycamIce", function(datos)
    SendNUIMessage({ action = "bodycam:ice", data = datos })
end)

RegisterNetEvent("origen_police:client:bodycamFin", function(datos)
    if datos and datos.sessionId then
        DetenerAudioBodycam(datos.sessionId)
        sesionesEmisionActivas[datos.sessionId] = nil
        DetenerMonitorVozSiVacio()
        DetenerSyncCoordsSiVacio()
    end
    SendNUIMessage({ action = "bodycam:fin", data = datos })
end)

RegisterNetEvent("origen_police:client:bodycamSyncCoords", function(targetId, coords, channel)
    if not targetId then return end
    targetId = tonumber(targetId)

    if coords then
        lastKnownBodycamCoords[targetId] = vector3(coords.x, coords.y, coords.z)
    end

    local ch = tonumber(channel)
    for sessionId, sData in pairs(activeBodycamAudio) do
        if sData.targetId == targetId then
            if ch and ch > 0 then
                sData.channel = ch
                if not sData.muted then
                    if sData.listeners[targetId] ~= ch then
                        if sData.listeners[targetId] then
                            MumbleRemoveVoiceChannelListen(sData.listeners[targetId])
                        end
                        MumbleAddVoiceChannelListen(ch)
                        sData.listeners[targetId] = ch
                    end
                    MumbleSetVolumeOverrideByServerId(targetId, 1.0)
                end
            end
        end
    end

    ActualizarFocoEntornoBodycam()
end)

RegisterNetEvent("origen_police:client:bodycamAudioSync", function(sessionId, coords, targetId, targetChannel, nearbyPlayers)
    if not sessionId or not targetId then return end
    targetId = tonumber(targetId)
    local tCh = tonumber(targetChannel)

    if coords then
        lastKnownBodycamCoords[targetId] = vector3(coords.x, coords.y, coords.z)
    end

    local sData = activeBodycamAudio[sessionId]
    if not sData then
        sData = {
            targetId = targetId,
            channel = tCh or (Player(targetId).state and Player(targetId).state.assignedChannel) or MumbleGetVoiceChannelFromServerId(targetId),
            muted = false,
            listeners = {}
        }
        activeBodycamAudio[sessionId] = sData
    else
        if tCh and tCh > 0 then
            sData.channel = tCh
        end
    end

    if sData.muted then
        if sData.listeners then
            for pSrc, ch in pairs(sData.listeners) do
                if ch and ch ~= -1 then
                    MumbleRemoveVoiceChannelListen(ch)
                end
                MumbleSetVolumeOverrideByServerId(pSrc, -1.0)
            end
            sData.listeners = {}
        end
        return
    end

    if not sData.listeners then
        sData.listeners = {}
    end

    -- 1. Voz del propio oficial objetivo de la bodycam
    local targetVoiceChannel = sData.channel or tCh or (Player(targetId).state and Player(targetId).state.assignedChannel) or MumbleGetVoiceChannelFromServerId(targetId)
    if targetVoiceChannel and targetVoiceChannel > 0 and targetVoiceChannel ~= -1 then
        sData.channel = targetVoiceChannel
        if sData.listeners[targetId] ~= targetVoiceChannel then
            if sData.listeners[targetId] then
                MumbleRemoveVoiceChannelListen(sData.listeners[targetId])
            end
            MumbleAddVoiceChannelListen(targetVoiceChannel)
            sData.listeners[targetId] = targetVoiceChannel
        end
        MumbleSetVolumeOverrideByServerId(targetId, 1.0)
    end

    -- 2. Voces de los demás usuarios en rango de voz del oficial (hasta 25 metros)
    local currentNearby = {}
    if not sData.nearbyVolumes then sData.nearbyVolumes = {} end
    if nearbyPlayers and type(nearbyPlayers) == 'table' then
        for _, p in ipairs(nearbyPlayers) do
            local pSrc = tonumber(p.source)
            local pCh = tonumber(p.channel) or (Player(pSrc).state and Player(pSrc).state.assignedChannel) or MumbleGetVoiceChannelFromServerId(pSrc)
            local dist = tonumber(p.dist) or 0.0

            if pSrc and pSrc ~= targetId and pCh and pCh > 0 and pCh ~= -1 then
                currentNearby[pSrc] = true
                -- Atenuación progresiva del volumen según distancia al agente (1.0 a 0m -> 0.2 a 25m)
                local vol = math.max(0.2, math.min(1.0, 1.0 - (dist / 25.0) * 0.8))
                sData.nearbyVolumes[pSrc] = vol

                if sData.listeners[pSrc] ~= pCh then
                    if sData.listeners[pSrc] then
                        MumbleRemoveVoiceChannelListen(sData.listeners[pSrc])
                    end
                    MumbleAddVoiceChannelListen(pCh)
                    sData.listeners[pSrc] = pCh
                end
                MumbleSetVolumeOverrideByServerId(pSrc, vol)
            end
        end
    end

    -- 3. Limpiar oyentes que se hayan alejado del rango de voz
    for pSrc, oldCh in pairs(sData.listeners) do
        if pSrc ~= targetId and not currentNearby[pSrc] then
            if oldCh and oldCh ~= -1 then
                MumbleRemoveVoiceChannelListen(oldCh)
            end
            MumbleSetVolumeOverrideByServerId(pSrc, -1.0)
            sData.listeners[pSrc] = nil
            if sData.nearbyVolumes then
                sData.nearbyVolumes[pSrc] = nil
            end
        end
    end

    -- 4. Notificar a NUI por si el feed necesita actualizar coords/canal
    SendNUIMessage({
        action = "bodycam:syncInfo",
        data = {
            sessionId = sessionId,
            targetId = targetId,
            channel = sData.channel,
            coords = coords
        }
    })

    -- 5. Mantener activo el foco de audio y streaming de GTA V para el entorno 3D
    ActualizarFocoEntornoBodycam()
end)

RegisterNetEvent("origen_police:client:bodycamHablando", function(targetId, hablando)
    SendNUIMessage({
        action = "bodycam:hablando",
        data = { targetId = targetId, hablando = hablando }
    })
end)

AddEventHandler("onResourceStop", function(res)
    if res == GetCurrentResourceName() then
        monitorVozActivo = false
        syncCoordsActivo = false
        DetenerAudioBodycam(nil)
    end
end)

-- ============================================================
-- REPETICIONES POLICIALES 3D (ORBITA / LIBRE / TRAZADORAS)
-- ============================================================
RegisterNUICallback("PoliceRepeticionPedir", function(data, cb)
    local targetId = tonumber(data and data.targetId)
    local segundos = tonumber(data and data.segundos) or 60
    -- Opciones permitidas: 1 min (60s), 2 min (120s), 3 min (180s), 5 min (300s), 10 min (600s) y 20 min (1200s)
    local permitidos = { [60] = true, [120] = true, [180] = true, [300] = true, [600] = true, [1200] = true }
    if not permitidos[segundos] then
        segundos = 60
    end
    if not targetId then
        if cb then cb({ success = false, message = "ID de objetivo inválido" }) end
        return
    end

    if GetResourceState('origen_admin') ~= 'started' then
        if cb then cb({ success = false, message = "origen_admin no está iniciado. Ejecuta 'ensure origen_admin'." }) end
        return
    end

    local ok, res = pcall(function()
        return exports['origen_admin']:PedirRepeticion(targetId, segundos)
    end)

    if not ok or not res then
        if cb then cb({ success = false, message = "Export no encontrado en origen_admin. Ejecuta 'ensure origen_admin' en consola." }) end
        return
    end

    if cb then cb(res) end
end)

RegisterNUICallback("PoliceRepeticionLista", function(_, cb)
    local ok, lista = pcall(function()
        return exports['origen_admin']:ObtenerRepeticiones()
    end)
    if cb then cb((ok and lista) or {}) end
end)

RegisterNUICallback("PoliceRepeticionBorrar", function(data, cb)
    local id = tonumber(data and data.id)
    if id then
        pcall(function()
            exports['origen_admin']:BorrarRepeticion(id)
        end)
    end
    if cb then cb("ok") end
end)

RegisterNUICallback("PoliceRepeticionVer", function(data, cb)
    local id = tonumber(data and data.id)
    if not id then
        if cb then cb({ success = false, message = "ID inválido" }) end
        return
    end
    -- Cerrar la tablet de policía para despejar la pantalla y controles. Con
    -- el panel F7 detras se cierra tambien, o le volvia el foco en mitad de la
    -- repeticion. Ver ApartarTablet.
    if ApartarTablet then
        ApartarTablet()
    elseif TogglePause then
        TogglePause(false)
    end
    -- Iniciar la reproducción 3D con callback para reabrir la tablet al salir
    local ok, res = pcall(function()
        return exports['origen_admin']:VerRepeticion(id, function()
            TriggerEvent('origen_police:client:OpenPoliceCad')
        end)
    end)
    if not ok then
        if cb then cb({ success = false, message = "No se pudo iniciar la repetición. Asegúrate de reiniciar origen_admin." }) end
        return
    end
    if cb then cb(res or { success = true }) end
end)

RegisterNetEvent("origen_police:client:repeticionActualizada", function(lista)
    SendNUIMessage({
        action = "police:repeticionLista",
        lista = lista or {}
    })
end)

RegisterNetEvent("origen_police:client:ShowBodycam", function(coords, serverid)
    StopCurrentCam()
    local myServerId = GetPlayerServerId(PlayerId())
    local ped = nil
    if serverid == myServerId then
        ped = PlayerPedId()
    else
        local targetPlayer = GetPlayerFromServerId(serverid)
        if targetPlayer and targetPlayer ~= -1 then
            ped = GetPlayerPed(targetPlayer)
        end
    end

    local pCoords = (ped and DoesEntityExist(ped) and GetEntityCoords(ped)) or coords
    if not pCoords then
        SendNUIMessage({ action = "nosignal", toggle = true })
        return
    end

    cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", pCoords.x, pCoords.y, pCoords.z, 0.0, 0.0, 0.0, GetGameplayCamFov(), false, 2)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, false)
    SetFocusPosAndVel(pCoords.x, pCoords.y, pCoords.z, 0.0, 0.0, 0.0)

    if ped and DoesEntityExist(ped) then
        AttachCamToPedBone(cam, ped, 31086, 0.0, 0.18, 0.0, true)
    end
    ClearTimecycleModifier()

    currentCamType = "bodycam"
    currentCamTarget = ped

    CreateThread(function()
        while cam and currentCamType == "bodycam" do
            Wait(0)
            if ped and DoesEntityExist(ped) then
                SetCamRot(cam, GetEntityRotation(ped))
                local curCoords = GetEntityCoords(ped)
                SetFocusPosAndVel(curCoords.x, curCoords.y, curCoords.z, 0.0, 0.0, 0.0)
            end
        end
    end)
end)

RegisterNetEvent("origen_police:client:ShowCarcam", function(coords, netid)
    StopCurrentCam()
    local veh = NetworkGetEntityFromNetworkId(netid)
    if not veh or veh == 0 or not DoesEntityExist(veh) then
        SendNUIMessage({ action = "nosignal", toggle = true })
        return
    end

    local vCoords = GetEntityCoords(veh)
    cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", vCoords, 0, 0, 0, GetGameplayCamFov(), false, 2)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, false)
    SetFocusPosAndVel(vCoords, 0.0, 0.0, 0.0)

    local specialOffset = Config.DefaultCarCamOffset or vector3(0.0, 0.5, 0.4)
    if type(Config.CustomCarOffsets) == "table" then
        for k, v in pairs(Config.CustomCarOffsets) do
            if GetHashKey(k) == GetEntityModel(veh) then
                specialOffset = v
                break
            end
        end
    end
    AttachCamToEntity(cam, veh, specialOffset.x, specialOffset.y, specialOffset.z, true)
    ClearTimecycleModifier()

    currentCamType = "carcam"
    currentCamTarget = veh

    CreateThread(function()
        while cam and currentCamType == "carcam" do
            Wait(0)
            if DoesEntityExist(veh) then
                SetCamRot(cam, GetEntityRotation(veh))
                SetFocusPosAndVel(GetEntityCoords(veh), 0.0, 0.0, 0.0)
            else
                SendNUIMessage({ action = "nosignal", toggle = true })
                StopCurrentCam()
                break
            end
        end
    end)
end)

RegisterNUICallback("GetCamsInArea", function(data, cb)
    cb(GetCamsInArea())
end)

cameraProps = Config.cameraProps

function GetCamsInArea()
    local retval = {}
    local p = GetEntityCoords(PlayerPedId())
    local objects = FW_GetObjects()
    if type(cameraProps) ~= "table" then cameraProps = {} end
    for _, v in pairs(cameraProps) do
        local model = GetHashKey(v)
    
        for i = 1, #objects do
            local currentObj = objects[i]
            if GetEntityModel(currentObj) == model then
                -- Comprobar si es una cámara instalada manualmente
                local isInstalled = false
                for _, installedCamObj in pairs(installedCCTVCameras) do
                    if installedCamObj == currentObj then
                        isInstalled = true
                        break
                    end
                end

                if not isInstalled then
                    local dist = #(p - GetEntityCoords(currentObj))
        
                    if dist < 50 then
                        table.insert(retval, {
                            obj = currentObj,
                            dist = dist,
                            model = v,
                            online = GetEntityHealth(currentObj) >= 900
                        })
                    end
                end
            end
        end
    end


    table.sort(retval, function(a, b)
        return a.dist < b.dist
    end)

    return retval
end

RegisterNUICallback("ShowCam", function(data, cb)
    cb(true)
    ShowCam(tonumber(data.obj))
end)

RegisterNUICallback("RotateCam", function(data, cb)
    if cam then
        local deltaX = tonumber(data.deltaX) or 0.0
        local deltaY = tonumber(data.deltaY) or 0.0
        local rot = GetCamRot(cam, 2)
        local newX = math.max(-85.0, math.min(45.0, rot.x + deltaY))
        local newZ = rot.z + deltaX
        SetCamRot(cam, newX, rot.y, newZ, 2)
    end
    if cb then cb(true) end
end)

RegisterNUICallback("ZoomCam", function(data, cb)
    if cam then
        local currentFov = GetCamFov(cam)
        local zoomIn = data.zoomIn == true
        if zoomIn then
            currentFov = math.max(15.0, currentFov - 5.0)
        else
            currentFov = math.min(90.0, currentFov + 5.0)
        end
        SetCamFov(cam, currentFov)
    end
    if cb then cb(true) end
end)

function ShowCam(obj)
    StopCurrentCam()
    if not obj or not DoesEntityExist(obj) then
        SendNUIMessage({ action = "nosignal", toggle = true })
        return
    end

    local coords = GetEntityCoords(obj)
    cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", coords, 0, 0, 0, GetGameplayCamFov(), false, 2)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, false)
    SetFocusEntity(obj)

    AttachCamToEntity(cam, obj, 0.0, -0.2, -0.4, true)
    ClearTimecycleModifier()

    local initialRot = GetEntityRotation(obj) - vector3(35, 0, 180)
    local camRot = initialRot
    SetCamRot(cam, camRot.x, camRot.y, camRot.z, 2)

    currentCamType = "cctv"
    currentCamTarget = obj

    CreateThread(function()
        local signal = true
        while cam and currentCamType == "cctv" do
            Wait(0)
            if signal and (not DoesEntityExist(obj) or GetEntityHealth(obj) < 900) then
                signal = false
                SendNUIMessage({
                    action = "nosignal",
                    toggle = true
                })
            end
        end
    end)
end

RegisterNUICallback("SetBodyCamEnabled", function(state, cb)
    state = state.value
    TriggerServerEvent("origen_police:server:DisableBodyCam", state)
    cb(true)
end)

-- ============================================================
-- SISTEMA CÁMARAS CCTV INSTALABLES
-- ============================================================
local cctvPlacementActive = false
local cctvPreviewProp = 0
local CCTV_MODEL = "prop_cctv_cam_06a"   -- Modelo por defecto (ya en cameraProps)

-- Sincronización inicial: cuando el servidor manda todas las cámaras ya instaladas
RegisterNetEvent("origen_police:client:SyncAllCCTV", function(list)
    for id, data in pairs(list) do
        cctvCamerasData[id] = data
        if not installedCCTVCameras[id] then
            SpawnCCTVObject(id, data.coords, data.heading, data.model)
        end
    end
    RefreshInstalledCamsUI()
end)

-- Añadir una cámara nueva sincronizada desde el servidor
RegisterNetEvent("origen_police:client:AddInstalledCCTV", function(id, data)
    cctvCamerasData[id] = data
    SpawnCCTVObject(id, data.coords, data.heading, data.model)
    -- Notificar a la UI si está abierta la sección de cámaras
    RefreshInstalledCamsUI()
end)

-- Eliminar una cámara sincronizada desde el servidor
RegisterNetEvent("origen_police:client:RemoveInstalledCCTV", function(id)
    id = tonumber(id)
    cctvCamerasData[id] = nil
    if installedCCTVCameras[id] and DoesEntityExist(installedCCTVCameras[id]) then
        DeleteEntity(installedCCTVCameras[id])
    end
    installedCCTVCameras[id] = nil
    RefreshInstalledCamsUI()
end)

-- Crear el objeto en el mundo
function SpawnCCTVObject(id, coords, heading, cctvModelProp)
    local actualModel = cctvModelProp or CCTV_MODEL
    local model = GetHashKey(actualModel)
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end
    if not HasModelLoaded(model) then return end

    local obj = CreateObject(model, coords.x, coords.y, coords.z, false, true, false)
    SetEntityCoordsNoOffset(obj, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(obj, heading)
    FreezeEntityPosition(obj, true)
    
    -- Hacer que la cámara pueda detectar daños por disparos o puñetazos
    SetEntityCollision(obj, true, true)
    SetEntityCanBeDamaged(obj, true)
    SetEntityInvincible(obj, false)
    SetEntityMaxHealth(obj, 1000)
    SetEntityHealth(obj, 1000)
    
    installedCCTVCameras[tonumber(id)] = obj
    SetModelAsNoLongerNeeded(model)
end

-- Thread de vigilancia: Detectar si alguna cámara es destruida por disparos
CreateThread(function()
    while true do
        local sleep = 1000
        local hasCams = false
        
        for _, _ in pairs(installedCCTVCameras) do
            hasCams = true
            break
        end
        
        if hasCams then
            sleep = 0
            local ped = PlayerPedId()
            
            -- Si el jugador está disparando un arma
            if IsPedShooting(ped) then
                local hasImpact, impactCoords = GetPedLastWeaponImpactCoord(ped)
                if hasImpact then
                    for id, entity in pairs(installedCCTVCameras) do
                        if DoesEntityExist(entity) then
                            local camCoords = GetEntityCoords(entity)
                            -- Si el tiro pega a menos de 1.2 metros (en la chapa de la cámara o su cuerpo físico)
                            if #(impactCoords - camCoords) < 1.5 then
                                UseParticleFxAssetNextCall("core")
                                StartParticleFxNonLoopedAtCoord("ent_dst_elec_fire_sp", camCoords.x, camCoords.y, camCoords.z, 0.0, 0.0, 0.0, 2.0, false, false, false)
                                
                                TriggerServerEvent("origen_police:server:RemoveCCTVCam", id)
                            end
                        end
                    end
                end
            end
            
            -- Si el jugador pega un golpe cuerpo a cuerpo o batazo cerca
            if IsPedInMeleeCombat(ped) and IsControlJustPressed(0, 24) then
                local pCoords = GetEntityCoords(ped)
                for id, entity in pairs(installedCCTVCameras) do
                    if DoesEntityExist(entity) then
                        local camCoords = GetEntityCoords(entity)
                        if #(pCoords - camCoords) < 1.5 then
                            UseParticleFxAssetNextCall("core")
                            StartParticleFxNonLoopedAtCoord("ent_dst_elec_fire_sp", camCoords.x, camCoords.y, camCoords.z, 0.0, 0.0, 0.0, 2.0, false, false, false)
                            
                            TriggerServerEvent("origen_police:server:RemoveCCTVCam", id)
                        end
                    end
                end
            end
        end
        
        Wait(sleep)
    end
end)

-- Entrar en modo de colocación (disparado por el ítem)
local function RotationToDirection(rotation)
    local adjustedRotation = { x = (math.pi / 180) * rotation.x, y = (math.pi / 180) * rotation.y, z = (math.pi / 180) * rotation.z }
    local direction = {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), 
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), 
        z = math.sin(adjustedRotation.x)
    }
    return direction
end

local function RayCastGamePlayCamera(distance)
    local cameraRotation = GetGameplayCamRot(2)
    local cameraCoord = GetGameplayCamCoord()
    local direction = RotationToDirection(cameraRotation)
    local destination = { x = cameraCoord.x + direction.x * distance, y = cameraCoord.y + direction.y * distance, z = cameraCoord.z + direction.z * distance }
    local a, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0))
    return hit, endCoords, entityHit
end

-- Modelos de cámara disponibles
local availableCCTVModels = {
    "prop_cctv_cam_06a",
    "prop_cctv_cam_01b",
    "prop_cctv_cam_01a",
    "prop_cctv_cam_04b",
    "prop_cctv_cam_04c"
}

-- Entrar en modo de colocación (disparado por el ítem)
RegisterNetEvent("origen_police:client:StartCCTVPlacement", function()
    if cctvPlacementActive then return end
    cctvPlacementActive = true

    local ped = PlayerPedId()
    local currentModelIndex = 1
    local currentModel = GetHashKey(availableCCTVModels[currentModelIndex])

    local function spawnPreviewProp(modelHash)
        if cctvPreviewProp ~= 0 then DeleteEntity(cctvPreviewProp) end
        RequestModel(modelHash)
        while not HasModelLoaded(modelHash) do Wait(10) end
        cctvPreviewProp = CreateObject(modelHash, 0.0, 0.0, 0.0, false, false, false)
        SetEntityCollision(cctvPreviewProp, false, false)
        SetEntityAlpha(cctvPreviewProp, 180, false)
        SetModelAsNoLongerNeeded(modelHash)
    end

    spawnPreviewProp(currentModel)
    local camHeading = GetEntityHeading(ped)
    ShowNotification("Modo Instalación de Cámara\nApunta donde quieras colocarla.")

    CreateThread(function()
        while cctvPlacementActive do
            Wait(0)
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 25, true) -- Aim
            ShowHelpNotification("~INPUT_CONTEXT~ o ~INPUT_ATTACK~ Instalar | ~INPUT_FRONTEND_RRIGHT~ Cancelar\n~INPUT_WEAPON_WHEEL_PREV~ ~INPUT_WEAPON_WHEEL_NEXT~ Rotar | ~INPUT_MOVE_LEFT_ONLY~ ~INPUT_MOVE_RIGHT_ONLY~ Cambiar Modelo")

            -- Cambiar de modelo con Flecha Izquierda
            if IsControlJustPressed(0, 174) then
                currentModelIndex = currentModelIndex - 1
                if currentModelIndex < 1 then currentModelIndex = #availableCCTVModels end
                currentModel = GetHashKey(availableCCTVModels[currentModelIndex])
                spawnPreviewProp(currentModel)
            end

            -- Cambiar de modelo con Flecha Derecha
            if IsControlJustPressed(0, 175) then
                currentModelIndex = currentModelIndex + 1
                if currentModelIndex > #availableCCTVModels then currentModelIndex = 1 end
                currentModel = GetHashKey(availableCCTVModels[currentModelIndex])
                spawnPreviewProp(currentModel)
            end

            local hit, coords, entity = RayCastGamePlayCamera(10.0)
            if hit and hit ~= 0 then
                SetEntityCoordsNoOffset(cctvPreviewProp, coords.x, coords.y, coords.z, false, false, false)
                SetEntityHeading(cctvPreviewProp, camHeading)

                -- Rotación con Rueda del Ratón
                if IsDisabledControlPressed(0, 14) or IsControlPressed(0, 14) then -- Scroll down
                    camHeading = camHeading - 3.0
                elseif IsDisabledControlPressed(0, 15) or IsControlPressed(0, 15) then -- Scroll up
                    camHeading = camHeading + 3.0
                end

                -- Colocar (E o Click Izquierdo)
                if IsDisabledControlJustPressed(0, 24) or IsControlJustPressed(0, 38) then
                    local placeCoords = GetEntityCoords(cctvPreviewProp)
                    local placeHeading = GetEntityHeading(cctvPreviewProp)
                    local finalModelName = availableCCTVModels[currentModelIndex]

                    DeleteEntity(cctvPreviewProp)
                    cctvPreviewProp = 0
                    cctvPlacementActive = false

                    -- Progreso de animación
                    ProgressBar("install_cctv", "Instalando Cámara CCTV...", 5000, false, true, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    }, {
                        animDict = "mini@repair",
                        anim = "fixing_a_ped",
                        flags = 16,
                    }, {}, {}, function() -- onFinish
                        TriggerServerEvent("origen_police:server:RegisterCCTVCam", placeCoords, placeHeading, finalModelName)
                        ShowNotification("~g~Cámara instalada correctamente.")
                    end, function() -- onCancel
                        ShowNotification("~r~Instalación cancelada.")
                    end)
                    break
                end
            else
                -- Ocultar en 0,0,0 si no apunta a nada válido
                SetEntityCoordsNoOffset(cctvPreviewProp, 0.0, 0.0, 0.0, false, false, false)
            end

            -- Cancelar (Backspace)
            if IsControlJustPressed(0, 202) then
                DeleteEntity(cctvPreviewProp)
                cctvPreviewProp = 0
                cctvPlacementActive = false
                ShowNotification("Instalación cancelada.")
                break
            end
        end
    end)
end)

-- Detectar estar cerca de una cámara para quitarla
CreateThread(function()
    while true do
        local sleep = 1000
        -- Sin camaras instaladas no hay nada que quitar: ni se mira el trabajo.
        -- GetPlayerJobCategory() va en cache (main.lua) y solo existe si
        -- CanOpenTablet da true, como la comprobacion de antes
        if next(installedCCTVCameras) and GetPlayerJobCategory() then
            local ped = PlayerPedId()
            local pCoords = GetEntityCoords(ped)
            
            for id, entity in pairs(installedCCTVCameras) do
                if DoesEntityExist(entity) then
                    local camCoords = GetEntityCoords(entity)
                    local dist = #(pCoords - camCoords)
                    if dist < 2.5 then
                        sleep = 0
                        ShowHelpNotification("Presiona ~INPUT_CONTEXT~ para quitar la Cámara CCTV")
                        if IsControlJustPressed(0, 38) then
                            ProgressBar("remove_cctv", "Guardando Cámara CCTV...", 15000, false, true, {
                                disableMovement = true,
                                disableCarMovement = true,
                                disableMouse = false,
                                disableCombat = true,
                            }, {
                                animDict = "mini@repair",
                                anim = "fixing_a_ped",
                                flags = 16,
                            }, {}, {}, function() -- onFinish
                                TriggerServerEvent("origen_police:server:RemoveCCTVCam", id)
                                ShowNotification("~g~Cámara CCTV recogida exitosamente.")
                                Wait(1000)
                            end, function() -- onCancel
                                ShowNotification("~r~Cancelado.")
                            end)
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- Renombrar una cámara sincronizada
RegisterNetEvent("origen_police:client:RenameInstalledCCTV", function(id, newName)
    id = tonumber(id)
    if cctvCamerasData[id] then
        cctvCamerasData[id].label = newName
        RefreshInstalledCamsUI()
    end
end)

-- Callback de la UI para obtener las cámaras instaladas (combina server data + entidad)
RegisterNUICallback("GetInstalledCCTVCams", function(data, cb)
    cb(GetInstalledCamList())
end)

-- Callback para ver una cámara CCTV instalada desde la tablet
RegisterNUICallback("ShowInstalledCCTVCam", function(data, cb)
    cb(true)
    local id = tonumber(data.id)
    local obj = installedCCTVCameras[id]
    if obj and DoesEntityExist(obj) then
        ShowCam(obj)
    else
        SendNUIMessage({ action = "nosignal", toggle = true })
        Citizen.SetTimeout(2000, function()
            SendNUIMessage({ action = "nosignal", toggle = false })
        end)
    end
end)
-- Callback para renombrar una cámara instalada desde la tablet
RegisterNUICallback("RenameInstalledCCTVCam", function(data, cb)
    cb(true)
    local id = tonumber(data.id)
    local newName = data.name
    if newName and newName ~= "" then
        TriggerServerEvent("origen_police:server:RenameCCTVCam", id, newName)
    end
end)

-- Solicitar sincronización al spawnar
CreateThread(function()
    Wait(2000)
    TriggerServerEvent("origen_police:server:RequestCCTVSync")
end)