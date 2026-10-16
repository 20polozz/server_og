local isPlacingSpeaker = false
placedSpeakers = {}
currentSpeaker = nil
playerSpeakers = {}
local currentVehicleRadio = nil
local isCarRadioOpen = false

local function HasPermission()
    if not Config.UsePermissions then
        return true
    end
    
    for _, job in pairs(Config.AllowedJobs) do
        local playerJob = Custom.GetJob()
        if playerJob.name == job then
            return true
        end
    end
    
    return false
end

--- Los mismos patrones que en el servidor, que es quien decide: un id de
--- YouTube son siempre 11 caracteres.
local function ExtractVideoId(url)
    if type(url) ~= 'string' then return nil end
    local patterns = {
        '[?&]v=([%w_%-]+)',
        'youtu%.be/([%w_%-]+)',
        '/embed/([%w_%-]+)',
        '/shorts/([%w_%-]+)',
        '/live/([%w_%-]+)',
        'youtube%.com/v/([%w_%-]+)',
    }
    
    for _, pattern in ipairs(patterns) do
        local videoId = string.match(url, pattern)
        if videoId and #videoId == 11 then
            return videoId
        end
    end
    
    return nil
end

local function IsValidURL(url)
    if not url or url == '' then
        return false
    end
    
    if Config.ValidateDomain then
        if not string.match(url, 'youtube%.com') and not string.match(url, 'youtu%.be') then
            return false
        end
    end
    
    local videoId = ExtractVideoId(url)
    return videoId ~= nil
end

local function GetYouTubeTitle(url)
    local videoId = ExtractVideoId(url)
    if not videoId then
        return 'Unknown'
    end
    
    return 'Loading... (' .. videoId .. ')'
end

function PlaceSpeaker(speakerType)
    if isPlacingSpeaker then return end
    
    if not HasPermission() then
        Internal.Notify(_('no_permission'), 'error')
        return
    end
    
    if #playerSpeakers >= Config.MaxSpeakers then
        Internal.Notify(_('max_speakers_reached', #playerSpeakers, Config.MaxSpeakers), 'error')
        return
    end

    local typeData = Config.SpeakerTypes[speakerType]
    local speakerModel = GetHashKey(typeData and typeData.prop or 'prop_speaker_01')
    
    lib.requestModel(speakerModel)
    
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local playerHeading = GetEntityHeading(playerPed)
    local forward = GetEntityForwardVector(playerPed)
    local spawnCoords = playerCoords + forward * 1.5
    
    local ground, groundZ = GetGroundZFor_3dCoord(spawnCoords.x, spawnCoords.y, spawnCoords.z + 10.0, false)
    if ground then
        spawnCoords = vector3(spawnCoords.x, spawnCoords.y, groundZ)
    end

    -- Animación pickup_low
    local animDict = "pickup_object"
    lib.requestAnimDict(animDict)
    TaskPlayAnim(playerPed, animDict, "pickup_low", 8.0, -8.0, -1, 0, 0, false, false, false)
    
    Wait(800) -- Tiempo justo para que la animación parezca que lo deja en el suelo

    TriggerServerEvent('origen_speaker:server:placeSpeaker', {
        x = spawnCoords.x,
        y = spawnCoords.y,
        z = spawnCoords.z,
        heading = playerHeading,
        type = speakerType
    })
    
    Wait(500)
    ClearPedTasks(playerPed)
end

function RemoveSpeaker(speakerId)
    TriggerServerEvent('origen_speaker:server:removeSpeaker', speakerId)
end

function OpenSpeakerUI(speakerId)
    local speaker = placedSpeakers[speakerId]
    if not speaker then 
        return 
    end
    
    currentSpeaker = speakerId
    
    lib.callback('origen_speaker:server:getSyncStatus', false, function(syncStatus)        
        -- El foco con la respuesta: si el servidor tarda o no contesta, el
        -- raton no se queda preso sin panel delante.
        if currentSpeaker ~= speakerId then return end
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'openSpeaker',
            speakerId = speakerId,
            isCarRadio = false,
            syncStatus = syncStatus or {synced = false}
        })        
    end, speakerId)
end

RegisterNUICallback('closeSpeaker', function(data, cb)
    SetNuiFocus(false, false)
    
    if isCarRadioOpen then
        isCarRadioOpen = false
        currentVehicleRadio = nil
    else
        currentSpeaker = nil
    end
    
    cb('ok')
end)

-- Play Music
RegisterNUICallback('playMusic', function(data, cb)
    local speakerId = nil
    
    if isCarRadioOpen and currentVehicleRadio then
        speakerId = 'vehicle_' .. currentVehicleRadio.plate
    elseif currentSpeaker then
        speakerId = currentSpeaker
    else
        cb({success = false, message = 'No hay altavoz ni vehículo elegido'})
        return
    end
    
    local url = data.url
    if not IsValidURL(url) then
        cb({success = false, message = _('invalid_url')})
        Internal.Notify(_('invalid_url'), 'error')
        return
    end
    
    local videoId = ExtractVideoId(url)
    local title = GetYouTubeTitle(url)
    
    TriggerServerEvent('origen_speaker:server:playMusic', speakerId, url, videoId, title)
    
    cb({success = true, title = title})
end)

RegisterNUICallback('stopMusic', function(data, cb)
    local speakerId = nil
    
    if isCarRadioOpen and currentVehicleRadio then
        speakerId = 'vehicle_' .. currentVehicleRadio.plate
    elseif currentSpeaker then
        speakerId = currentSpeaker
    else
        cb({success = false})
        return
    end
    
    TriggerServerEvent('origen_speaker:server:stopMusic', speakerId)
    cb({success = true})
end)

RegisterNUICallback('setVolume', function(data, cb)
    local speakerId = nil
    
    if isCarRadioOpen and currentVehicleRadio then
        speakerId = 'vehicle_' .. currentVehicleRadio.plate
    elseif currentSpeaker then
        speakerId = currentSpeaker
    else
        cb({success = false})
        return
    end
    
    local speaker = placedSpeakers[speakerId]
    local maxVolume = (speaker and speaker.maxVolume) or Config.MaxVolume or 100
    local volume = tonumber(data.volume) or Config.DefaultVolume
    volume = math.max(Config.MinVolume, math.min(maxVolume, volume))
    
    TriggerServerEvent('origen_speaker:server:setVolume', speakerId, volume)
    cb({success = true})
end)

RegisterNUICallback('removeSpeaker', function(data, cb)
    if isCarRadioOpen then
        cb({success = false, message = 'La radio del coche no se puede recoger'})
        return
    end
    
    if not currentSpeaker then
        cb({success = false})
        return
    end
    
    RemoveSpeaker(currentSpeaker)
    SetNuiFocus(false, false)
    currentSpeaker = nil
    cb({success = true})
end)

RegisterNUICallback('Internal.Notify', function(data, cb)
    local type = data.type or 'primary'
    Internal.Notify(data.message, type)
    cb('ok')
end)

RegisterNUICallback('updateSongTitle', function(data, cb)    
    if type(data.speakerId) == 'string' and type(data.title) == 'string' then
        -- El servidor comprueba que es el video que suena y que lo estas oyendo.
        TriggerServerEvent('origen_speaker:server:updateTitle', data.speakerId, data.title, data.videoId)
        
        if currentSpeaker == data.speakerId or (isCarRadioOpen and currentVehicleRadio and ('vehicle_' .. currentVehicleRadio.plate) == data.speakerId) then
            SendNUIMessage({
                action = 'updateNowPlaying',
                title = data.title
            })
        end
    end
    
    cb('ok')
end)

RegisterNUICallback('getPlaylists', function(data, cb)
    lib.callback('origen_speaker:server:getPlaylists', false, function(result)
        if result then
            cb({
                myPlaylists = result.myPlaylists or {},
                sharedPlaylists = result.sharedPlaylists or {}
            })
        else
            cb({
                myPlaylists = {},
                sharedPlaylists = {}
            })
        end
    end)
end)

RegisterNUICallback('createPlaylist', function(data, cb)
    if not data.name or data.name == '' then
        cb({success = false, message = 'Nombre de lista no válido'})
        return
    end
    
    lib.callback('origen_speaker:server:createPlaylist', false, function(success, message)
        if success then
            Internal.Notify(_('playlist_created', data.name), 'success')
            cb({success = true, message = message or 'Lista creada'})
        else
            Internal.Notify(message or _('error_occurred'), 'error')
            cb({success = false, message = message or 'No se pudo crear la lista'})
        end
    end, data.name, data.imageUrl or '')
end)

RegisterNUICallback('renamePlaylist', function(data, cb)
    if not data.playlistId or not data.newName or data.newName == '' then
        cb({success = false, message = 'Datos no válidos'})
        return
    end
    
    lib.callback('origen_speaker:server:renamePlaylist', false, function(success, message)
        if success then
            Internal.Notify(_('playlist_renamed'), 'success')
            cb({success = true, message = message or 'Lista renombrada'})
        else
            Internal.Notify(message or _('error_occurred'), 'error')
            cb({success = false, message = message or 'No se pudo renombrar la lista'})
        end
    end, data.playlistId, data.newName, data.imageUrl or '')
end)

RegisterNUICallback('deletePlaylist', function(data, cb)
    if not data.playlistId then
        cb({success = false, message = 'Lista no válida'})
        return
    end
    
    lib.callback('origen_speaker:server:deletePlaylist', false, function(success, message)
        if success then
            Internal.Notify(_('playlist_deleted'), 'success')
            cb({success = true, message = message or 'Lista eliminada'})
        else
            Internal.Notify(message or _('error_occurred'), 'error')
            cb({success = false, message = message or 'No se pudo eliminar la lista'})
        end
    end, data.playlistId)
end)

RegisterNUICallback('getPlaylistSongs', function(data, cb)
    if not data.playlistId then
        cb({songs = {}})
        return
    end
    
    lib.callback('origen_speaker:server:getPlaylistSongs', false, function(songs)
        cb({songs = songs or {}})
    end, data.playlistId)
end)

RegisterNUICallback('addSongToPlaylist', function(data, cb)
    if not data.playlistId or not data.url then
        cb({success = false, message = 'Datos no válidos'})
        return
    end
    
    local url = data.url
    if not IsValidURL(url) then
        cb({success = false, message = _('invalid_url')})
        Internal.Notify(_('invalid_url'), 'error')
        return
    end
    
    local title = data.title or GetYouTubeTitle(url)
        
    lib.callback('origen_speaker:server:addSongToPlaylist', false, function(success, message)
        if success then
            Internal.Notify(_('song_added'), 'success')
            cb({success = true, message = message or 'Canción añadida'})
        else
            Internal.Notify(message or _('error_occurred'), 'error')
            cb({success = false, message = message or 'No se pudo añadir la canción'})
        end
    end, data.playlistId, url, title)
end)

RegisterNUICallback('removeSongFromPlaylist', function(data, cb)
    if not data.songId then
        cb({success = false, message = 'Canción no válida'})
        return
    end
    
    lib.callback('origen_speaker:server:removeSongFromPlaylist', false, function(success, message)
        if success then
            Internal.Notify(_('song_removed'), 'success')
            cb({success = true, message = message or 'Canción quitada'})
        else
            Internal.Notify(message or _('error_occurred'), 'error')
            cb({success = false, message = message or 'No se pudo quitar la canción'})
        end
    end, data.songId)
end)

RegisterNUICallback('sharePlaylist', function(data, cb)
    if not data.playlistId or not data.targetPlayerId then
        cb({success = false, message = 'Datos no válidos'})
        return
    end
    
    lib.callback('origen_speaker:server:sharePlaylist', false, function(success, message)
        if success then
            Internal.Notify(_('playlist_shared'), 'success')
            cb({success = true, message = message or 'Lista compartida'})
        else
            Internal.Notify(message or _('error_occurred'), 'error')
            cb({success = false, message = message or 'No se pudo compartir la lista'})
        end
    end, data.playlistId, data.targetPlayerId)
end)

RegisterNUICallback('getPublicPlaylists', function(data, cb)    
    lib.callback('origen_speaker:server:getPublicPlaylists', false, function(playlists)
        cb({playlists = playlists})
    end)
end)

RegisterNUICallback('importPlaylist', function(data, cb)    
    if not data.playlistId then
        cb({success = false, message = 'Lista no válida'})
        return
    end
    
    lib.callback('origen_speaker:server:importPlaylist', false, function(success, message)
        if success then
            Internal.Notify(_('playlist_imported'), 'success')
            cb({success = true, message = message or 'Lista importada'})
        else
            Internal.Notify(message or _('error_occurred'), 'error')
            cb({success = false, message = message or 'No se pudo importar la lista'})
        end
    end, data.playlistId)
end)

RegisterNUICallback('likePlaylist', function(data, cb)    
    if not data.playlistId then
        cb({success = false, message = 'Lista no válida'})
        return
    end
    
    lib.callback('origen_speaker:server:likePlaylist', false, function(success, liked, message)
        if success then
            cb({success = true, liked = liked, message = message or 'Me gusta guardado'})
        else
            cb({success = false, message = message or 'No se pudo guardar el me gusta'})
        end
    end, data.playlistId)
end)

RegisterNUICallback('toggleFavorite', function(data, cb)    
    if not data.playlistId then
        cb({success = false, message = 'Lista no válida'})
        return
    end
    
    lib.callback('origen_speaker:server:toggleFavorite', false, function(success, isFavorite, message)
        if success then
            cb({success = true, isFavorite = isFavorite, message = message or 'Favorito actualizado'})
        else
            cb({success = false, message = message or 'No se pudo cambiar el favorito'})
        end
    end, data.playlistId)
end)

RegisterNUICallback('togglePublic', function(data, cb)
    if not data.playlistId then
        cb({success = false, message = 'Lista no válida'})
        return
    end
    
    lib.callback('origen_speaker:server:togglePublic', false, function(result)
        cb(result)
    end, data.playlistId)
end)

RegisterNUICallback('getNearbySpeakers', function(data, cb)
    if not data.speakerId then
        cb({speakers = {}})
        return
    end
    
    lib.callback('origen_speaker:server:getNearbySpeakers', false, function(speakers)
        cb({speakers = speakers or {}})
    end, data.speakerId, Config.SpeakerSync.MaxSyncDistance)
end)

RegisterNUICallback('createSyncGroup', function(data, cb)
    if not data.masterId or not data.slaveIds then
        cb({success = false, message = 'Datos no válidos'})
        return
    end
    
    lib.callback('origen_speaker:server:createSyncGroup', false, function(success, message)
        if success then
            Internal.Notify(_('sync_created'), 'success')
            cb({success = true, message = message})
        else
            Internal.Notify(message or _('error_occurred'), 'error')
            cb({success = false, message = message})
        end
    end, data.masterId, data.slaveIds)
end)

RegisterNUICallback('removeSyncGroup', function(data, cb)
    if not data.masterId then
        cb({success = false, message = 'Datos no válidos'})
        return
    end
    
    lib.callback('origen_speaker:server:removeSyncGroup', false, function(success, message)
        if success then
            Internal.Notify(_('sync_removed'), 'success')
            cb({success = true, message = message})
        else
            Internal.Notify(message or _('error_occurred'), 'error')
            cb({success = false, message = message})
        end
    end, data.masterId)
end)

RegisterNUICallback('getSyncStatus', function(data, cb)
    if not data.speakerId then
        cb({synced = false})
        return
    end
    
    lib.callback('origen_speaker:server:getSyncStatus', false, function(status)
        cb(status or {synced = false})
    end, data.speakerId)
end)

RegisterNetEvent('origen_speaker:client:speakerPlaced', function(speakerId, speakerData)
    placedSpeakers[speakerId] = speakerData
    
    if speakerData.owner == GetPlayerServerId(PlayerId()) then
        playerSpeakers[#playerSpeakers+1] = speakerId
        Internal.Notify(_('speaker_placed'), 'success')
    end
    
    CreateSpeakerObject(speakerId, speakerData)
end)

RegisterNetEvent('origen_speaker:client:speakerRemoved', function(speakerId)
    -- Si estaba sonando, el reproductor se quita tambien (antes se quedaba vivo).
    DestroySound(speakerId)
    if placedSpeakers[speakerId] then
        if placedSpeakers[speakerId].object then
            local obj = placedSpeakers[speakerId].object
            
            if DoesEntityExist(obj) then
                DeleteObject(obj)
                DeleteEntity(obj)
            end
        end
        
        if currentSpeaker == speakerId then
            SetNuiFocus(false, false)
            SendNUIMessage({
                action = 'closeSpeaker'
            })
            currentSpeaker = nil
        end
        
        placedSpeakers[speakerId] = nil
        
        local wasOwner = false
        for i, id in ipairs(playerSpeakers) do
            if id == speakerId then
                table.remove(playerSpeakers, i)
                wasOwner = true
                break
            end
        end
        
        if wasOwner then
            Internal.Notify(_('speaker_removed'), 'success')
        end
    end
end)

RegisterNetEvent('origen_speaker:client:onPLayerLoad', function()
    TriggerServerEvent('origen_speaker:server:requestSpeakers')
end)

RegisterNetEvent('origen_speaker:client:removeAllSpeakers', function()
    if currentSpeaker then
        SetNuiFocus(false, false)
        SendNUIMessage({
            action = 'closeSpeaker'
        })
        currentSpeaker = nil
    end
    
    for speakerId, speakerData in pairs(placedSpeakers) do
        if speakerData.object then
            local obj = speakerData.object
            if DoesEntityExist(obj) then
                DeleteObject(obj)
                DeleteEntity(obj)
            end
        end
    end
    
    placedSpeakers = {}
    playerSpeakers = {}    
end)

RegisterNetEvent('origen_speaker:client:updateSpeaker', function(speakerId, speakerData)
    if placedSpeakers[speakerId] then
        for k, v in pairs(speakerData) do
            placedSpeakers[speakerId][k] = v
        end
    end
end)

RegisterNetEvent('origen_speaker:client:updateTitle', function(speakerId, title, videoId)
    if placedSpeakers[speakerId] then
        placedSpeakers[speakerId].title = title
        if videoId then
            placedSpeakers[speakerId].videoId = videoId
        end
    end
    
    if currentSpeaker == speakerId or (isCarRadioOpen and currentVehicleRadio and ('vehicle_' .. currentVehicleRadio.plate) == speakerId) then
        SendNUIMessage({
            action = 'updateNowPlaying',
            title = title,
            videoId = videoId
        })
    end
end)

RegisterNetEvent('origen_speaker:client:volumeChanged', function(speakerId, volume)
    if placedSpeakers[speakerId] then
        placedSpeakers[speakerId].volume = volume
    end
    
    SendNUIMessage({
        action = 'updateVolume',
        data = {
            speakerId = speakerId,
            volume = volume
        }
    })
end)

RegisterNetEvent('origen_speaker:client:syncSpeakers', function(speakers)
    placedSpeakers = speakers

    -- Convert server-computed elapsedSeconds into a local game timer reference
    -- so the sync thread can calculate elapsed time without os.time() (unavailable on client)
    local now = GetGameTimer()
    for speakerId, speakerData in pairs(placedSpeakers) do
        if speakerData.isPlaying and speakerData.elapsedSeconds then
            placedSpeakers[speakerId].gameTimerRef = now - (speakerData.elapsedSeconds * 1000)
        end
        CreateSpeakerObject(speakerId, speakerData)
    end
end)

function CreateSpeakerObject(speakerId, speakerData)
    if speakerData.isVehicle then return end

    if placedSpeakers[speakerId] and placedSpeakers[speakerId].object then
        return
    end
        
    local speakerModel = GetHashKey(speakerData.prop or 'prop_speaker_01')
    
    RequestModel(speakerModel)
    while not HasModelLoaded(speakerModel) do
        Wait(0)
    end
    
    local coords = vector3(speakerData.x, speakerData.y, speakerData.z)
    local speakerObject = CreateObject(speakerModel, coords.x, coords.y, coords.z, false, false, false)
    
    SetEntityHeading(speakerObject, speakerData.heading)
    PlaceObjectOnGroundProperly(speakerObject)
    SetEntityCollision(speakerObject, true, true)
    FreezeEntityPosition(speakerObject, true)
    
    placedSpeakers[speakerId].object = speakerObject
end

CreateThread(function()
    local currentShownText = false
    local isRemoving = false
    
    while true do
        local sleep = 500
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        local closestSpeakerId, closestDistance = GetClosestSpeaker()
        
        if closestSpeakerId and closestDistance < Config.InteractionDistance then
            sleep = 0
            local speakerData = placedSpeakers[closestSpeakerId]
            local isOwner = speakerData.owner == GetPlayerServerId(PlayerId())
            
            if not currentShownText then
                local controls = {
                    { key = 'E', text = _('press_interact') }
                }
                if isOwner then
                    table.insert(controls, { key = 'BORRAR', text = _('delete') })
                end

                if GetResourceState('origen_hud') == 'started' then
                    exports['origen_hud']:setupControls(controls)
                else
                    local text = "**[E]** " .. _('press_interact')
                    if isOwner then
                        text = text .. "  \n**[BORRAR]** " .. _('delete')
                    end
                    lib.showTextUI(text, {
                        position = "left-center",
                        icon = 'compact-disc'
                    })
                end
                currentShownText = true
            end
            
            if IsControlJustPressed(0, Config.Keys.Interact) then
                OpenSpeakerUI(closestSpeakerId)
            end
            
            if isOwner and IsControlPressed(0, Config.Keys.Cancel) and not isRemoving then
                isRemoving = true
                if lib.progressBar({
                    duration = 2000,
                    label = _('removing_speaker'),
                    useWhileDead = false,
                    canCancel = true,
                    disable = { move = true, car = true, mouse = false, combat = true },
                    anim = {
                        dict = "pickup_object",
                        clip = "pickup_low",
                        flag = 0
                    }
                }) then
                    RemoveSpeaker(closestSpeakerId)
                    if GetResourceState('origen_hud') == 'started' then
                        exports['origen_hud']:hideControls()
                    else
                        lib.hideTextUI()
                    end
                    currentShownText = false
                    Wait(500)
                    ClearPedTasks(playerPed)
                else
                    ClearPedTasks(playerPed)
                end
                isRemoving = false
            end
        else
            if currentShownText then
                if GetResourceState('origen_hud') == 'started' then
                    exports['origen_hud']:hideControls()
                else
                    lib.hideTextUI()
                end
                currentShownText = false
            end
        end
        
        Wait(sleep)
    end
end)

RegisterCommand('placespeaker', function()
    PlaceSpeaker()
end, false)

function OpenCarRadio()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if vehicle == 0 then
        Internal.Notify(_('need_vehicle'), 'error')
        return
    end
    
    local plate = GetVehicleNumberPlateText(vehicle)
    local vehicleNetId = VehToNet(vehicle)
        
    currentVehicleRadio = {
        vehicle = vehicle,
        plate = plate,
        netId = vehicleNetId
    }
    
    isCarRadioOpen = true
    
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openSpeaker',
        isCarRadio = true,
        vehiclePlate = plate
    })
end

local adminRadioOpen = false
local adminRadioActive = false
local radioAdminVolumen = 50

RegisterNetEvent('origen_speaker:client:openAdminRadio', function(data)    
    adminRadioOpen = true
    
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openAdminRadio',
        mode = data.mode or 'zone',
        radius = data.radius or 50,
        volume = data.volume or 50,
        active = data.active or false,
        videoId = data.videoId or nil,
        title = data.title or nil
    })
end)

RegisterNUICallback('closeAdminRadio', function(data, cb)    
    adminRadioOpen = false
    SetNuiFocus(false, false)
    
    TriggerServerEvent('origen_speaker:server:closeAdminRadio')
    cb({success = true})
end)

RegisterNUICallback('adminRadioChangeMode', function(data, cb)    
    TriggerServerEvent('origen_speaker:server:adminRadioChangeMode', data.mode)
    cb({success = true})
end)

RegisterNUICallback('adminRadioChangeRadius', function(data, cb)    
    TriggerServerEvent('origen_speaker:server:adminRadioChangeRadius', data.radius)
    cb({success = true})
end)

RegisterNUICallback('adminRadioPlay', function(data, cb)    
    TriggerServerEvent('origen_speaker:server:adminRadioPlay', data)
    cb({success = true})
end)

RegisterNUICallback('adminRadioPause', function(data, cb)    
    TriggerServerEvent('origen_speaker:server:adminRadioPause')
    cb({success = true})
end)

RegisterNUICallback('adminRadioResume', function(data, cb)    
    TriggerServerEvent('origen_speaker:server:adminRadioResume')
    cb({success = true})
end)

RegisterNUICallback('adminRadioStop', function(data, cb)    
    TriggerServerEvent('origen_speaker:server:adminRadioStop')
    cb({success = true})
end)

RegisterNUICallback('adminRadioSetVolume', function(data, cb)    
    TriggerServerEvent('origen_speaker:server:adminRadioSetVolume', data.volume)
    cb({success = true})
end)

RegisterNUICallback('startVoiceBroadcast', function(data, cb)
    TriggerServerEvent('origen_speaker:server:startVoiceBroadcast', data.mode, data.radius)
    exports['pma-voice']:setRadioChannel(999)
    ExecuteCommand('+radiotalk')
    cb({success = true})
end)

RegisterNUICallback('stopVoiceBroadcast', function(data, cb)
    TriggerServerEvent('origen_speaker:server:stopVoiceBroadcast')
    ExecuteCommand('-radiotalk')
    cb({success = true})
end)

RegisterNetEvent('origen_speaker:client:adminRadioPlay', function(data)    
    adminRadioActive = true
    radioAdminVolumen = data.volume or 50

    SendNUIMessage({
        action = 'playMusicFromAdmin',
        videoId = data.videoId,
        url = data.url,
        title = data.title or 'Admin Radio',
        volume = EnModoStreamer() and 0 or radioAdminVolumen,
        mode = data.mode or 'zone'
    })
end)

RegisterNetEvent('origen_speaker:client:adminRadioPause', function()    
    SendNUIMessage({
        action = 'pauseMusicFromAdmin'
    })
end)

RegisterNetEvent('origen_speaker:client:adminRadioResume', function()    
    SendNUIMessage({
        action = 'resumeMusicFromAdmin'
    })
end)

RegisterNetEvent('origen_speaker:client:adminRadioStop', function()
    
    adminRadioActive = false
    
    SendNUIMessage({
        action = 'stopMusicFromAdmin'
    })
end)

RegisterNetEvent('origen_speaker:client:adminRadioVolumeChange', function(data)
    radioAdminVolumen = tonumber(data.volume) or radioAdminVolumen
    SendNUIMessage({
        action = 'updateVolumeFromAdmin',
        volume = EnModoStreamer() and 0 or radioAdminVolumen
    })
end)

-- Modo streamer: la radio de admin sigue sonando a volumen 0, asi al quitar
-- el modo continua por donde va en vez de empezar de nuevo.
AddEventHandler('origen:modoStreamer', function(activo)
    if not adminRadioActive then return end
    SendNUIMessage({
        action = 'updateVolumeFromAdmin',
        volume = activo == true and 0 or radioAdminVolumen
    })
end)

RegisterNetEvent('origen_speaker:client:updatePlayersListening', function(players)    
    SendNUIMessage({
        action = 'updatePlayersListening',
        players = players
    })
end)

RegisterNetEvent('origen_speaker:client:adminRadioPlayResponse', function(data)    
    SendNUIMessage({
        action = 'adminRadioPlayResponse',
        title = data.title
    })
end)

AddEventHandler('onResourceStop', function(resource)    
    if resource ~= GetCurrentResourceName() then return end
    if not placedSpeakers or not next(placedSpeakers) then return end
    for _, speaker in pairs(placedSpeakers) do
        local object = speaker.object
        if DoesEntityExist(object) then
            DeleteEntity(object)
        end
    end
end)

exports('PlaceSpeakerSmall', function() PlaceSpeaker('speaker_small') end)
exports('PlaceSpeakerMedium', function() PlaceSpeaker('speaker_medium') end)
exports('PlaceSpeakerMedium1', function() PlaceSpeaker('speaker_medium_1') end)
exports('PlaceSpeakerBig', function() PlaceSpeaker('speaker_big') end)

-- Exports

exports('PlaceSpeaker', PlaceSpeaker)
exports('RemoveSpeaker', RemoveSpeaker)
exports('OpenSpeakerUI', OpenSpeakerUI)

--[[ ── La radio del coche desde otra interfaz ────────────────────────────────
     El panel de Vehiculo del inventario la lleva dentro y ya no abre esta
     pantalla, asi que necesita dar las mismas ordenes sin pasar por ella.

     Cada orden es un callback al servidor y lo que se devuelve es lo que el
     SERVIDOR ha decidido: la maneja cualquiera que vaya dentro del coche, y
     eso solo lo puede comprobar el. Si dice que no, el jugador se entera con un
     aviso aqui mismo (el panel no enseña mensajes). El id de la radio lo saca
     el servidor del coche en el que vas; aqui no se manda. ]]
local function CocheDebajo()
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh == 0 then return nil end
    return veh
end

local function PedirRadio(evento, ...)
    local ok, r = pcall(lib.callback.await, evento, false, ...)
    if not ok or type(r) ~= 'table' then
        return { ok = false, mensaje = _('error_occurred') }
    end
    r.ok = r.ok == true
    return r
end

local function AvisarSiFalla(r)
    if not r.ok and r.mensaje then
        Internal.Notify(r.mensaje, 'error')
    end
    return r
end

local function SinCoche()
    return AvisarSiFalla({ ok = false, mensaje = _('car_radio_inside') })
end

exports('CarRadioPlay', function(url)
    if not CocheDebajo() then return SinCoche() end

    if type(url) ~= 'string' or not IsValidURL(url) then
        return AvisarSiFalla({ ok = false, mensaje = _('invalid_url') })
    end

    return AvisarSiFalla(PedirRadio('origen_speaker:server:carRadioPlay', url))
end)

exports('CarRadioStop', function()
    if not CocheDebajo() then return SinCoche() end
    return AvisarSiFalla(PedirRadio('origen_speaker:server:carRadioStop'))
end)

exports('CarRadioSetVolume', function(volume)
    if not CocheDebajo() then return SinCoche() end
    return AvisarSiFalla(PedirRadio('origen_speaker:server:carRadioVolume', tonumber(volume)))
end)

--- Guardar una direccion en una lista. Va aqui y no en quien llama porque el
--- titulo del video se saca del mismo sitio que al reproducir.
exports('CarRadioAddSong', function(playlistId, url)
    if not playlistId or type(url) ~= 'string' or not IsValidURL(url) then
        return AvisarSiFalla({ ok = false, mensaje = _('invalid_url') })
    end

    local title = GetYouTubeTitle(url)
    local ok, bien, mensaje = pcall(lib.callback.await, 'origen_speaker:server:addSongToPlaylist', false, playlistId, url, title)
    if not ok then
        return AvisarSiFalla({ ok = false, mensaje = _('error_occurred') })
    end

    if bien then Internal.Notify(_('song_added'), 'success') end
    return AvisarSiFalla({ ok = bien and true or false, mensaje = mensaje, titulo = title })
end)

--- Crear una lista (con aviso si el servidor dice que no: tope de listas...).
exports('CarRadioCreatePlaylist', function(nombre)
    if type(nombre) ~= 'string' or nombre == '' then
        return { ok = false }
    end

    local ok, bien, mensaje = pcall(lib.callback.await, 'origen_speaker:server:createPlaylist', false, nombre, '')
    if not ok then
        return AvisarSiFalla({ ok = false, mensaje = _('error_occurred') })
    end
    if bien then Internal.Notify(_('playlist_created', nombre), 'success') end
    return AvisarSiFalla({ ok = bien and true or false, mensaje = mensaje })
end)

--[[ Poner una lista en la radio del coche. La cola la lleva el servidor: saca
     las canciones (solo de una lista tuya, compartida contigo o publica) y va
     pasando de una a otra cuando termina cada video. ]]
exports('CarRadioPlayPlaylist', function(playlistId)
    if not CocheDebajo() then return SinCoche() end
    if not playlistId then return { ok = false } end
    return AvisarSiFalla(PedirRadio('origen_speaker:server:carRadioPlayPlaylist', playlistId))
end)

--- `dentro` a true: la radio deja de oirse fuera del coche.
exports('CarRadioInsideOnly', function(dentro)
    if not CocheDebajo() then return SinCoche() end
    return AvisarSiFalla(PedirRadio('origen_speaker:server:carRadioInsideOnly', dentro and true or false))
end)
exports('OpenCarRadio', OpenCarRadio)