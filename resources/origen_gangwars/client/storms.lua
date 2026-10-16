Storms = {
    id = nil,
    coords = nil,
    radius = nil,
    weather = nil,
    time = nil,
    playerOldCoords = nil,
    bagsHandlers = {},
    marker = {},
}

local timeList = {
    ['day'] = 9,
    ['night'] = 22,
}

local function GetCoordZ(x, y)
	local groundCheckHeights = { 48.0, 49.0, 50.0, 51.0, 52.0, 53.0, 54.0, 55.0, 56.0, 57.0, 58.0 }
	for i, height in ipairs(groundCheckHeights) do
		local foundGround, z = GetGroundZFor_3dCoord(x, y, height)
		if foundGround then
			return z
		end
	end
	return nil
end

local function getSafeSpawnPoint()
    local coords = Storms.coords
    local radius = 100.0
    local maxAttempts = 400
    local attempt = 0
    local spawnPoint, zCoords

    repeat
        spawnPoint = vector3(coords.x + math.random(-radius, radius), coords.y + math.random(-radius, radius), coords.z)
        zCoords = GetCoordZ(spawnPoint.x, spawnPoint.y)
        attempt = attempt + 1
    until zCoords ~= nil or attempt >= maxAttempts

    if zCoords == nil then
        debugger("Error: Could not find a safe spawn point.")
        return coords
    end

    return vector3(spawnPoint.x, spawnPoint.y, zCoords)
end

local function setWeather(weather, time)
    CreateThread(function()
        while Storms and Storms.id do
            SetRainLevel(0.0)
			SetWeatherTypePersist(weather or 'CLEAR')
			SetWeatherTypeNow(weather or 'CLEAR')
			SetWeatherTypeNowPersist(weather or 'CLEAR')

            NetworkOverrideClockTime(timeList[time] or 18, 00, 0)
            Wait(100)
        end
    end)
end

local function autoParachute()
    -- Solo actúa como red de seguridad durante el descenso inicial.
    -- En cuanto el jugador toca suelo tras haber caído/volado, el thread termina
    -- para que durante la partida no se vuelva a dar paracaídas al saltar.
    CreateThread(function()
        local wasFalling = false
        while LocalPlayer.state.orgInWar do
            local falling   = IsPedFalling(PlayerPed)
            local freeFall  = IsPedInParachuteFreeFall(PlayerPed) == 1

            if falling then
                wasFalling = true
                GiveWeaponToPed(PlayerPed, -72657034, 1, 0, 1)
                TaskSkyDive(PlayerPed)
                SetPedParachuteTintIndex(PlayerPed, 6)
            end
            if freeFall then
                wasFalling = true
                ForcePedToOpenParachute(PlayerPed)
            end

            -- Una vez que el jugador estaba en el aire y ha aterrizado → desactivar
            if wasFalling and IsPedOnGround(PlayerPed) then
                break
            end
            Wait(100)
        end
    end)
end

Storms.ParachuteAction = function()
    local pId = PlayerId()
    if not Storms.id then return debugger('ParachuteAction: Storm not found') end
    local spawnPoint = getSafeSpawnPoint()
    SetEntityCoords(ped, spawnPoint.x, spawnPoint.y, Storms.coords.z + Config.HeightToSpawn)
    SetPlayerControl(pId, true)
    SetPlayerParachuteModelOverride(PlayerId(), `p_parachute1_mp_s`)
    SetPedParachuteTintIndex(PlayerPed, 6)
    GiveWeaponToPed(PlayerPed, -72657034, 1, 0, 1)
    TaskSkyDive(PlayerPed)

    while LocalPlayer.state.orgInWar do
        if IsPedInParachuteFreeFall(PlayerPed) == 1 and not parachuteDeployed then
            if GetEntityHeightAboveGround(PlayerPed) < Config.OpenParachuteHeight then
                parachuteDeployed = true
                ForcePedToOpenParachute(PlayerPed)
                break
            end
        end
        Wait(100)
    end
    if Config.AutoParachute then
        autoParachute()
    end
end

local function playerHandler()
    return AddStateBagChangeHandler('orgStorms_' .. Storms.id .. '_players', nil, function(bagName, key, value)
        Spectate.UpdatePlayerList(value)
        SendNUIMessage({
            action = 'updatePlayers',
            data = {
                players = value
            }
        })
    end)
end

local currentStage = 0
local function markersHandler()
    return AddStateBagChangeHandler('orgStorms_' .. Storms.id .. '_marker', nil, function(bagName, key, value)
        if not value then return end
        local stage = value and value.stage or currentStage
        if stage ~= currentStage then
            Nui.UpdateHud('stage', value.stage)
            currentStage = stage
        end

        if value.state == 'break' then
            Nui.UpdateHud('zoneState', 'break')
            Nui.UpdateHud('zoneCountdown', value.breaktime)
        elseif value.state == 'closing' then
            Nui.UpdateHud('zoneState', 'closing')
            Nui.UpdateHud('zoneCountdown', nil)
        end
    end)
end

local function phaseHandler()
    return AddStateBagChangeHandler('orgStorms_' .. Storms.id .. '_phase', nil, function(bagName, key, value)
        if not value then return end
        Nui.UpdateHud('phase', value)
        if value == 'disputa' then
            Nui.UpdateHud('zoneCountdown', nil)
        end
    end)
end

local function lobbyTimeHandler()
    return AddStateBagChangeHandler('orgStorms_' .. Storms.id .. '_lobbyTime', nil, function(bagName, key, value)
        if value == nil then return end
        local phase = GlobalState['orgStorms_' .. Storms.id .. '_phase']
        if phase == 'preparation' then
            Nui.UpdateHud('zoneCountdown', value)
        end
    end)
end

local function startTimeHandler()
    return AddStateBagChangeHandler('orgStorms_' .. Storms.id .. '_startedIn', nil, function(bagName, key, value)
        if value then
            SendNUIMessage({
                action = 'updateStartTime',
                data = {
                    time = value
                }
            })
        end
    end)
end

local function playerCountHandler()
    return AddStateBagChangeHandler('orgStorms_' .. Storms.id .. '_playerCount', nil, function(bagName, key, value)
        Nui.UpdateHud('players', value)
    end)
end

RegisterNetEvent('origen_gangwars:client:joinStorm', function(data)
    if Storms.id then return debugger('joinStorm: Storm already joined') end
    Storms.id = data.id
    Storms.coords = data.coords
    Storms.radius = data.radius
    Storms.bagsHandlers.players = playerHandler()
    Storms.bagsHandlers.playerCount = playerCountHandler()
    Storms.bagsHandlers.startTime = startTimeHandler()
    Storms.bagsHandlers.markers = markersHandler()
    Storms.bagsHandlers.phase = phaseHandler()
    Storms.bagsHandlers.lobbyTime = lobbyTimeHandler()
    Storms.weather = data.weather
    Storms.time = data.time
    debugger('joinStorm id: '..Storms.id)
end)

RegisterNetEvent('origen_gangwars:client:setInvincible', function(state)
    SetEntityInvincible(PlayerPed, state)
end)

local function handleScreenFadeOut(fadeOutTime)
    if IsScreenFadedOut() then return end
    DoScreenFadeOut(fadeOutTime)
    while not IsScreenFadedOut() do Wait(0) end
end

local function handleScreenFadeIn(fadeInTime)
    if IsScreenFadedIn() then return end
    DoScreenFadeIn(fadeInTime)
    while not IsScreenFadedIn() do Wait(0) end
end

local function initiateStorm()
    Custom.DisableWeatherSync()
    setWeather(Storms.weather, Storms.time)
    
    -- Cerrar el menú (la pantalla de carga ya está visible)
    Nui.ToggleMenu(false)
    Storms.playerOldCoords = GetEntityCoords(PlayerPed)
    LocalPlayer.state.playerOldCoords = Storms.playerOldCoords
    deathlogics.RegisterHandler()
    handleScreenFadeOut(1000)
end

local function startLobby()
    -- Ya no usamos el lobby del portaaviones
    -- La pantalla de carga ya está visible desde initiateStorm()
    
    debugger('[startLobby] Starting cinematic, hiding loading screen')
    
    -- Ocultar pantalla de carga justo antes de la cinemática
    SendNUIMessage({
        action = 'toggleLoadingScreen',
        data = {
            state = false
        }
    })
    
    Wait(300)  -- Pequeña pausa para transición suave
    
    -- Iniciar la cinemática de la zona
    Cinematic.Start()
end

local forcedStart = false
RegisterNetEvent('origen_gangwars:client:StartStorm', function()
    if not Storms.id then 
        return debugger('StartStorm: Storm not found') 
    end

    LocalPlayer.state.orgInWar = true

    -- Bloquear el chat del juego mientras dure la partida
    CreateThread(function()
        while LocalPlayer.state.orgInWar do
            DisableControlAction(0, 245, true) -- T = abrir chat
            DisableControlAction(0, 243, true) -- Y = chat de equipo
            Wait(0)
        end
    end)
    
    -- Obtener datos de la batalla actual para la pantalla de carga
    local battleName = GlobalState['orgStorms_' .. Storms.id .. '_name'] or 'Guerra de bandas'
    local battleImage = GlobalState['orgStorms_' .. Storms.id .. '_image'] or ''
    local playerCount = GlobalState['orgStorms_' .. Storms.id .. '_playerCount'] or 0
    local maxPlayers = GlobalState['orgStorms_' .. Storms.id .. '_maxPlayers'] or 100
    
    debugger('[StartStorm] Storm ID: ' .. Storms.id)
    debugger('[StartStorm] Battle Name: ' .. battleName)
    debugger('[StartStorm] Battle Image: ' .. (battleImage or 'none'))
    debugger('[StartStorm] Player Count: ' .. playerCount .. '/' .. maxPlayers)
    debugger('[StartStorm] Showing loading screen NOW')
    
    -- Mostrar pantalla de carga con datos de la batalla
    SendNUIMessage({
        action = 'toggleLoadingScreen',
        data = {
            state = true,
            battleName = battleName,
            battleImage = battleImage,
            mapName = battleName,  -- Usar el nombre de la batalla como nombre del mapa
            players = playerCount,
            maxPlayers = maxPlayers
        }
    })
    
    debugger('[StartStorm] Loading screen message sent, waiting 2 seconds')
    Wait(2000)  -- Mostrar pantalla de carga por 2 segundos

    initiateStorm()

    if not forcedStart then
        startLobby()
    end

    SetEntityHealth(PlayerPed, 200.0)
    CreateThread(Storms.ParachuteAction)
    Wait(1500)
    Zones.InitZone(Storms.id)
    handleScreenFadeIn(2000)

    if not Storms.id then 
        return debugger('StartStorm: Storm not found') 
    end
    
    debugger('StartStorm id: ' .. Storms.id)
    Nui.UpdateHud('players', GlobalState['orgStorms_' .. Storms.id .. '_playerCount'])

    -- Sincronizar fase y cuenta atrás actuales con el NUI (por si el handler no disparó)
    local currentPhase = GlobalState['orgStorms_' .. Storms.id .. '_phase']
    if currentPhase then
        Nui.UpdateHud('phase', currentPhase)
    end
    local currentLobbyTime = GlobalState['orgStorms_' .. Storms.id .. '_lobbyTime']
    if currentLobbyTime and currentPhase == 'preparation' then
        Nui.UpdateHud('zoneCountdown', currentLobbyTime)
    end
end)

local function resetPlayerState()
    LocalPlayer.state.orgInWar = false
    LocalPlayer.state.inWarZone = false
end

local function clearStormHandlers()
    for _, handler in pairs(Storms.bagsHandlers) do
        RemoveStateBagChangeHandler(handler)
    end
end

local function restorePlayerPosition()
    -- Eliminar TODAS las armas del ped antes de teleportar (cliente nunca debe conservar armas de match)
    RemoveAllPedWeapons(PlayerPed, true)
    SetCurrentPedWeapon(PlayerPed, `WEAPON_UNARMED`)

    if LocalPlayer.state.playerOldCoords then
        handleScreenFadeOut(1000)
        SetEntityCoords(PlayerPed, LocalPlayer.state.playerOldCoords.x, LocalPlayer.state.playerOldCoords.y, LocalPlayer.state.playerOldCoords.z)
        Custom.EnableWeatherSync()

        SetEntityHealth(PlayerPed, 200.0)
        LocalPlayer.state.playerOldCoords = nil

        Wait(1000)
        handleScreenFadeIn(1000)
    end
end

local function clearStormData()
    Storms.id = nil
    Storms.coords = nil
    Storms.radius = nil
    Storms.weather = nil
    Storms.time = nil
    Storms.playerOldCoords = nil
    Storms.marker = {}
    Storms.bagsHandlers = {}
    currentStage = 0
    -- Resetear estado de fase en el NUI
    Nui.UpdateHud('phase', 'preparation')
    Nui.UpdateHud('zoneState', nil)
    Nui.UpdateHud('zoneCountdown', nil)
    Nui.UpdateHud('stage', 0)
end

RegisterNetEvent('origen_gangwars:client:leaveStorm', function(scoreBoard, position)
    Spectate.Stop()
    resetPlayerState()
    Nui.ToggleHud(false)
    
    -- Ocultar pantalla de carga por si acaso estaba visible
    SendNUIMessage({
        action = 'toggleLoadingScreen',
        data = {
            state = false
        }
    })
    
    exports['origen_gangwars']:OnEnterZone()
    
    if not Storms.id then 
        return debugger('leaveStorm: Storm not found') 
    end

    clearStormHandlers()
    
    if scoreBoard and scoreBoard[1] then
        EndScene.Start(scoreBoard, position)
    end
    
    deathlogics.UnregisterHandler()
    
    clearStormData()
    restorePlayerPosition()
    Spectate.UpdatePlayerList({})

    -- Seguridad: si la pantalla quedó en negro por cualquier motivo (ej. partida cancelada antes de Start)
    if IsScreenFadedOut() then
        DoScreenFadeIn(500)
    end
end)

local function handleResourceStartDuringWar()
    RemoveAllPedWeapons(PlayerPed, true)
    SetCurrentPedWeapon(PlayerPed, `WEAPON_UNARMED`)
    resetPlayerState()
    exports['origen_gangwars']:OnEnterZone()
    restorePlayerPosition()
    TriggerServerEvent('origen_gangwars:server:resetBucket')
end

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        if LocalPlayer.state.orgInWar then
            handleResourceStartDuringWar()
        end
    end
end)

local function resetStormLobby()
    if not Storms.id then return debugger('resetStormLobby: Storm not found') end

    --Limpiar todo Server Side
    TriggerServerEvent('origen_gangwars:server:leaveStormLobby', Storms.id)

    --Limpiar todo Client Side
    clearStormHandlers()
    clearStormData()
end

RegisterNuiCallback('resetStormLobby', function(data, cb)
    if not Storms.id then return debugger('resetStormLobby: Storm not found') end

    resetStormLobby()
    cb(true)
end)