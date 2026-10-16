local math_abs = math.abs
local math_cos = math.cos
local math_sin = math.sin
local math_sqrt = math.sqrt
local math_max = math.max
local math_min = math.min
local activeSounds = {}

--[[ ── Radios de coche ───────────────────────────────────────────────────────
     Su id es `vehicle_<matricula sin espacios>` (lo pone el servidor). Aqui la
     matricula viene rellena con espacios, asi que se compara sin ellos. ]]
local function CocheDeLaRadio(speakerId)
    local matricula = speakerId:gsub('^vehicle_', '')
    for _, vehicle in ipairs(GetGamePool('CVehicle')) do
        if (GetVehicleNumberPlateText(vehicle) or ''):gsub('%s+', '') == matricula then
            return vehicle
        end
    end
    return nil
end

--- ¿Tiene que sonarle a este jugador la radio de ese coche ahora mismo?
local function OyeRadioCoche(speaker, vehicle, playerPed, playerCoords)
    if not vehicle then return false end
    -- Un video que YouTube no deja poner no se vuelve a intentar cada medio segundo.
    if speaker.videoFallido and speaker.videoFallido == speaker.videoId then return false end
    -- «Solo dentro»: unicamente quien va sentado en ese coche, sea quien sea.
    if speaker.insideOnly then
        return GetVehiclePedIsIn(playerPed, false) == vehicle
    end
    return #(playerCoords - GetEntityCoords(vehicle)) <= (Config.CarRadioRange or 30.0)
end

--[[ ── Modo streamer (/streamermode, de origen_businesses) ───────────────────
     Con el modo puesto no se crea ningun reproductor: ni altavoces ni radios
     de coche. Al quitarlo, el hilo de abajo los vuelve a crear por donde vaya
     la cancion. La radio de admin se calla en main.lua. ]]
local silencioStreamer = false

function EnModoStreamer() return silencioStreamer end

AddEventHandler('origen:modoStreamer', function(activo)
    silencioStreamer = activo == true
    if not silencioStreamer then return end
    for speakerId in pairs(activeSounds) do
        DestroySound(speakerId)
    end
end)

CreateThread(function()
    if GetResourceState('origen_businesses') ~= 'started' then return end
    local ok, activo = pcall(function() return exports.origen_businesses:EnModoStreamer() end)
    if ok and activo then TriggerEvent('origen:modoStreamer', true) end
end)

function CreateSound(speakerId, videoId, volume, startSeconds)
    if silencioStreamer then return end

    if activeSounds[speakerId] then
        DestroySound(speakerId)
    end
    
    activeSounds[speakerId] = {
        videoId = videoId,
        volume = volume,
        isPlaying = true
    }
    
    SendNUIMessage({
        action = 'createSound',
        data = {
            speakerId = speakerId,
            videoId = videoId,
            volume = volume,
            startSeconds = startSeconds or 0
        }
    })
end

function DestroySound(speakerId)
    if activeSounds[speakerId] then
        activeSounds[speakerId] = nil
        
        SendNUIMessage({
            action = 'destroySound',
            data = {
                speakerId = speakerId
            }
        })
    end
end

function UpdateSoundVolume(speakerId, volume)
    if activeSounds[speakerId] then
        activeSounds[speakerId].volume = volume
        
        SendNUIMessage({
            action = 'updateVolume',
            data = {
                speakerId = speakerId,
                volume = volume
            }
        })
    end
end

function PauseSound(speakerId)
    if activeSounds[speakerId] then
        activeSounds[speakerId].isPlaying = false
        
        SendNUIMessage({
            action = 'pauseSound',
            data = {
                speakerId = speakerId
            }
        })
    end
end

function ResumeSound(speakerId)
    if activeSounds[speakerId] then
        activeSounds[speakerId].isPlaying = true
        
        SendNUIMessage({
            action = 'resumeSound',
            data = {
                speakerId = speakerId
            }
        })
    end
end

-- Received periodically from the server to keep vehicle radio state alive for
-- players who were far away when the radio started. Updates state so the sync
-- thread can create audio when the player gets close enough.
RegisterNetEvent('origen_speaker:client:vehicleRadioKeepAlive', function(speakerId, videoId, volume, elapsed, insideOnly)
    if type(speakerId) ~= 'string' or not speakerId:match("^vehicle_") then return end
    elapsed = tonumber(elapsed) or 0
    local speaker = placedSpeakers[speakerId]
    if not speaker then
        placedSpeakers[speakerId] = {
            isVehicle = true,
            isPlaying = true,
            videoId = videoId,
            volume = volume,
            insideOnly = insideOnly == true,
            gameTimerRef = GetGameTimer() - (elapsed * 1000)
        }
    else
        -- Otra cancion (o la radio estaba parada): se toma el tiempo del
        -- servidor y el reproductor viejo, si lo habia, se quita.
        if speaker.videoId ~= videoId or not speaker.isPlaying then
            speaker.gameTimerRef = GetGameTimer() - (elapsed * 1000)
            speaker.videoFallido = nil
            if speaker.videoId ~= videoId then DestroySound(speakerId) end
        end
        -- Refresh volume; only set gameTimerRef if not already tracking (preserve existing sync)
        speaker.volume = volume
        speaker.isPlaying = true
        speaker.videoId = videoId
        speaker.isVehicle = true
        speaker.insideOnly = insideOnly == true
        if not speaker.gameTimerRef then
            speaker.gameTimerRef = GetGameTimer() - (elapsed * 1000)
        end
    end
end)

--- «Solo dentro» encendido o apagado: el hilo de abajo corta o devuelve el
--- sonido a quien toque en la siguiente vuelta.
RegisterNetEvent('origen_speaker:client:vehicleRadioScope', function(speakerId, insideOnly)
    if type(speakerId) ~= 'string' or not speakerId:match("^vehicle_") then return end
    local speaker = placedSpeakers[speakerId]
    if not speaker then return end
    speaker.insideOnly = insideOnly == true
end)

--[[ El reproductor de YouTube de la NUI no ha podido con el video (insercion
     bloqueada, privado, borrado...). Se quita aqui, se marca para no
     reintentarlo en bucle y se le cuenta al servidor, que avisa a quien lo
     puso. A los demas no se les toca nada. ]]
RegisterNUICallback('soundError', function(data, cb)
    cb('ok')
    if type(data) ~= 'table' or type(data.speakerId) ~= 'string' or type(data.videoId) ~= 'string' then return end

    local speaker = placedSpeakers[data.speakerId]
    if speaker then speaker.videoFallido = data.videoId end
    activeSounds[data.speakerId] = nil

    TriggerServerEvent('origen_speaker:server:videoFallido', data.speakerId, data.videoId, tonumber(data.codigo))
end)

--- Cuanto dura el video de una radio de coche: el servidor lo necesita para
--- pasar a la siguiente cancion de una lista.
RegisterNUICallback('soundDuration', function(data, cb)
    cb('ok')
    if type(data) ~= 'table' or type(data.speakerId) ~= 'string' or type(data.videoId) ~= 'string' then return end
    if not data.speakerId:match("^vehicle_") then return end
    TriggerServerEvent('origen_speaker:server:duracionVideo', data.speakerId, data.videoId, tonumber(data.duracion))
end)

RegisterNetEvent('origen_speaker:client:playMusic', function(speakerId, videoId, volume, insideOnly)
    if type(speakerId) ~= 'string' then return end
    if speakerId:match("^vehicle_") then
        -- Always register the state so the sync thread can manage it for approaching players
        if not placedSpeakers[speakerId] then
            placedSpeakers[speakerId] = {}
        end
        local speaker = placedSpeakers[speakerId]
        speaker.isPlaying = true
        speaker.videoId = videoId
        speaker.volume = volume
        speaker.isVehicle = true
        speaker.insideOnly = insideOnly == true
        -- Poner otra vez la misma direccion es volver a intentarlo.
        speaker.videoFallido = nil
        -- Record client-side game timer when the song starts so approaching players sync correctly
        speaker.gameTimerRef = GetGameTimer()

        -- Create sound immediately only if the vehicle is already in range
        local playerPed = PlayerPedId()
        if OyeRadioCoche(speaker, CocheDeLaRadio(speakerId), playerPed, GetEntityCoords(playerPed)) then
            CreateSound(speakerId, videoId, volume, 0)
        else
            DestroySound(speakerId)
        end
        return
    end

    if placedSpeakers[speakerId] then
        placedSpeakers[speakerId].isPlaying = true
        placedSpeakers[speakerId].videoId = videoId
        placedSpeakers[speakerId].volume = volume
        placedSpeakers[speakerId].gameTimerRef = GetGameTimer()
    end

    local speaker = placedSpeakers[speakerId]
    if not speaker then return end

    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local speakerCoords = vector3(speaker.x, speaker.y, speaker.z)
    local distance = #(playerCoords - speakerCoords)
    local speakerRange = speaker.range or Config.MaxDistance or 50.0

    if distance <= speakerRange then
        CreateSound(speakerId, videoId, volume, 0)
    end
end)

RegisterNetEvent('origen_speaker:client:stopMusic', function(speakerId)
    if placedSpeakers[speakerId] then
        placedSpeakers[speakerId].isPlaying = false
        placedSpeakers[speakerId].videoId = nil
    end
    DestroySound(speakerId)
end)

RegisterNetEvent('origen_speaker:client:volumeChanged', function(speakerId, volume)
    UpdateSoundVolume(speakerId, volume)
    
    if placedSpeakers[speakerId] then
        placedSpeakers[speakerId].volume = volume
    end
end)

RegisterNetEvent('origen_speaker:client:pauseMusic', function(speakerId)
    PauseSound(speakerId)
end)

RegisterNetEvent('origen_speaker:client:resumeMusic', function(speakerId)
    ResumeSound(speakerId)
end)

CreateThread(function()
    while true do
        Wait(Config.SyncInterval)
        
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local soundCount = 0

        for speakerId, speaker in pairs(placedSpeakers) do
            if speaker.isPlaying and speaker.videoId then
                if speakerId:match("^vehicle_") then
                    local vehicle = CocheDeLaRadio(speakerId)
                    if vehicle then
                        local oye = OyeRadioCoche(speaker, vehicle, playerPed, playerCoords)
                        if oye and not activeSounds[speakerId] then
                            local elapsed = speaker.gameTimerRef and math.max(0, (GetGameTimer() - speaker.gameTimerRef) / 1000) or 0
                            CreateSound(speakerId, speaker.videoId, speaker.volume or Config.DefaultVolume, elapsed)
                        elseif not oye and activeSounds[speakerId] then
                            DestroySound(speakerId)
                        end
                    end
                else
                    local speakerCoords = vector3(speaker.x, speaker.y, speaker.z)
                    local distance = #(playerCoords - speakerCoords)
                    local speakerRange = speaker.range or Config.MaxDistance or 50.0
                    if distance <= speakerRange and not activeSounds[speakerId] then
                        local elapsed = speaker.gameTimerRef and math.max(0, (GetGameTimer() - speaker.gameTimerRef) / 1000) or 0
                        CreateSound(speakerId, speaker.videoId, speaker.volume or Config.DefaultVolume, elapsed)
                    elseif distance > speakerRange and activeSounds[speakerId] then
                        DestroySound(speakerId)
                    end
                end
            end
        end
        
        local speakerDistances = {}
        for speakerId, soundData in pairs(activeSounds) do
            soundCount = soundCount + 1
            local speaker = placedSpeakers[speakerId]
            local sourceCoords = nil
            local baseVolume = Config.DefaultVolume / 100.0
            
            if speakerId:match("^vehicle_") then
                local vehicle = CocheDeLaRadio(speakerId)
                if vehicle then
                    sourceCoords = GetEntityCoords(vehicle)
                    baseVolume = (soundData.volume or 50) / 100.0
                end
            elseif speaker then
                sourceCoords = vector3(speaker.x, speaker.y, speaker.z)
                baseVolume = (speaker.volume or 50) / 100.0
            end
            
            if sourceCoords then
                local distance = #(playerCoords - sourceCoords)
                
                local speakerHeading = nil
                if speaker and speaker.heading then
                    speakerHeading = speaker.heading
                end
                
                speakerDistances[#speakerDistances+1] = {
                    speakerId = speakerId,
                    distance = distance,
                    sourceCoords = sourceCoords,
                    baseVolume = baseVolume,
                    heading = speakerHeading
                }
            else
                DestroySound(speakerId)
            end
        end
        
        local closestSpeaker = nil
        local closestDistance = math.huge
        
        for _, speakerData in ipairs(speakerDistances) do
            if speakerData.distance < closestDistance then
                closestDistance = speakerData.distance
                closestSpeaker = speakerData.speakerId
            end
        end
        
        for _, speakerData in ipairs(speakerDistances) do
            local speakerId = speakerData.speakerId
            local distance = speakerData.distance
            local baseVolume = speakerData.baseVolume
            
            local speakerRange = speakerId:match("^vehicle_") and (Config.CarRadioRange or 30.0)
                or (placedSpeakers[speakerId] and placedSpeakers[speakerId].range)
                or Config.MaxDistance or 50.0
            
            if distance > speakerRange then
                DestroySound(speakerId)
            else
                local volumeFactor = 1.0 - (distance / speakerRange)
                volumeFactor = volumeFactor ^ 1.5
                
                if Config.EnableDirectionalAudio and speakerData.heading then
                    local directionFactor = CalculateDirectionalFactor(
                        speakerData.sourceCoords,
                        speakerData.heading,
                        playerCoords
                    )
                    volumeFactor = volumeFactor * directionFactor
                end
                
                local isDominant = (speakerId == closestSpeaker)
                
                if Config.EnableDominantSpeaker and not isDominant and #speakerDistances > 1 then
                    local distanceDiff = distance - closestDistance
                    
                    if distanceDiff < Config.EchoPreventionDistance then
                        local attenuationFactor = distanceDiff / Config.EchoPreventionDistance
                        attenuationFactor = attenuationFactor ^ 2.0
                        volumeFactor = volumeFactor * (0.1 + (attenuationFactor * (Config.NonDominantVolumeMax - 0.1)))
                    end
                end
                
                local adjustedVolume = baseVolume * volumeFactor
                
                SendNUIMessage({
                    action = 'set3DVolume',
                    data = {
                        speakerId = speakerId,
                        volume = adjustedVolume
                    }
                })
            end
        end
    end
end)

local function getCameraDirection()
    local cameraRotation = GetGameplayCamRot(0)

    local radiansZ = (cameraRotation.z * 0.0174532924)
    local radiansX = (cameraRotation.x * 0.0174532924)
    local xCos     = math_abs(math_cos(radiansX))

    return {
        x = (-math_sin(radiansZ) * xCos),
        y = (math_cos(radiansZ) * xCos),
        z = math_sin(radiansX),
    }
end

function CalculateDirectionalFactor(speakerCoords, speakerHeading, playerCoords)

    local cameraDir = getCameraDirection()
    local toSpeaker = speakerCoords - playerCoords
    local distanceToSpeaker = math_sqrt(toSpeaker.x * toSpeaker.x + toSpeaker.y * toSpeaker.y + toSpeaker.z * toSpeaker.z)

    local frontVolume = Config.DirectionalFrontVolume or 1.0
    local sideVolume = Config.DirectionalSideVolume or 0.7
    local backVolume = Config.DirectionalBackVolume or 0.3
    
    local directionFactor = frontVolume
    
    if distanceToSpeaker > 0.01 then
        local toSpeakerNorm = {
            x = toSpeaker.x / distanceToSpeaker,
            y = toSpeaker.y / distanceToSpeaker,
            z = toSpeaker.z / distanceToSpeaker
        }
        
        local dotProduct = cameraDir.x * toSpeakerNorm.x + cameraDir.y * toSpeakerNorm.y + cameraDir.z * toSpeakerNorm.z
        
        local cameraFactor = 0.3 + (dotProduct + 1.0) / 2.0 * 0.7
        
        cameraFactor = math_max(0.3, math_min(1.0, cameraFactor))
        
        directionFactor = directionFactor * cameraFactor
    end
    
    return directionFactor
end

function GetClosestSpeaker()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local closestSpeaker = nil
    local closestDistance = Config.InteractionDistance
    
    for speakerId, speakerData in pairs(placedSpeakers) do
        if not speakerData.isVehicle and speakerData.x and speakerData.y and speakerData.z then
            local speakerCoords = vector3(speakerData.x, speakerData.y, speakerData.z)
            local distance = #(playerCoords - speakerCoords)
            
            if distance < closestDistance then
                closestDistance = distance
                closestSpeaker = speakerId
            end
        end
    end
    
    return closestSpeaker, closestDistance
end

function GetPlayerSpeakers()
    return playerSpeakers
end

function GetAllSpeakers()
    return placedSpeakers
end

exports('CreateSound', CreateSound)
exports('DestroySound', DestroySound)
exports('UpdateSoundVolume', UpdateSoundVolume)
exports('GetClosestSpeaker', GetClosestSpeaker)
exports('GetPlayerSpeakers', GetPlayerSpeakers)
exports('GetAllSpeakers', GetAllSpeakers)