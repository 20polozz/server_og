--[[ NOTA DE ORIGEN: este recurso ya no crea blips del juego.

     Los puntos se registran en origen_map, que es de donde los leen los tres
     mapas del servidor (el minimapa, el del menu de pausa y la pestaña de
     Ciudad del inventario). El ayudante que lo hace se carga desde el
     fxmanifest: '@origen_map/shared/marcar.lua'.

     Es un recurso de terceros: si llega una version nueva, este cambio hay que
     volver a hacerlo. ]]

LocalPed = 0
LocalPedCoords = vector3(0.0, 0.0, 0.0)
LocalPlayerSrc = GetPlayerServerId(PlayerId())

ballEntities = {}
isPicking = false
isSimulating = false
lastSentReplayData = 0
pendingReplayData = nil
simulationCamera = 0
selectedClubType = 0
hasCarryDistance = false
bIsHandlingPickerResult = false
vehicleCaddy = 0
vehicleCaddyNetId = 0
caddyBlip = 0
CaddyCreated = false
ShowStartShot = true
LaunchPosition = vector3(0.0, 0.0, 0.0)

local bIsMainThreadRunning = false
local flagBlip = 0
local startBlip = 0
local timeExitedBounds = 0
local bWasInScoreboard = false
local lastSentLeaveEvent = 0
local bShouldCreateSimulationCamera = false
local guideAlphas = {}
local waitingForHole = false

---@param locationConfig LocationConfig
local function UpdateGeneric(locationConfig)
    if not IsInsideGrounds[locationConfig.name] then
        local currentTime = GetGameTimer()
        if timeExitedBounds == 0 then
            timeExitedBounds = currentTime
        elseif currentTime - timeExitedBounds < 5000 then
            ShowHelpTextThisFrame("RGOLF_RETURN_BOUNDS", false)
        elseif currentTime - lastSentLeaveEvent > 1000 then
            if LobbyData.leaderSrc == LocalPlayerSrc then
                TriggerServerEvent("rcore_golf:disbandLobby", locationConfig.name)
            else
                TriggerServerEvent("rcore_golf:leaveLobby", locationConfig.name)
            end
            lastSentLeaveEvent = currentTime
        end
    else
        timeExitedBounds = 0
    end
end

---@param locationConfig LocationConfig
local function UpdateRouteHelper(locationConfig)
    if GetRenderingCam() ~= -1 then return end

    if GetLocalPlayerNumberOfShots() > 0 then return end

    if LobbyData.activeHoleIndex == 0 then return end

    local holeConfig = locationConfig.HolesConfig[LobbyData.activeHoleIndex]
    local distanceToTee = #(LocalPedCoords - holeConfig.teeCoords)
    if distanceToTee < 15.0 then return end

    local currentHolesGuide = locationConfig.HolesGuide[LobbyData.activeHoleIndex]
    local numGuidesForCurrentHole = #currentHolesGuide

    for guideIndex, guideCoord in pairs(currentHolesGuide) do
        if guideIndex ~= numGuidesForCurrentHole and #(LocalPedCoords - guideCoord) < 15.0 then
            local direction = norm(guideCoord - currentHolesGuide[guideIndex + 1])
            local heading = math.deg(math.atan(direction.x, direction.y))
            guideAlphas[guideIndex] = (guideAlphas[guideIndex] and guideAlphas[guideIndex] + 1.0) or 0.0
            guideAlphas[guideIndex] = math.min(guideAlphas[guideIndex], 100)
            DrawMarker(20, guideCoord.x, guideCoord.y, guideCoord.z - 0.5, 0.0, 0.0, 0.0, 90.0, 0.0, heading, 1.0, 1.0, 1.0, 216, 27, 85, math.floor(guideAlphas[guideIndex]), false, false, 3, false, nil, nil, false)
        else
            if guideAlphas[guideIndex] then
                guideAlphas[guideIndex] = nil
            end
        end
    end
end

---@param locationConfig LocationConfig
function HandlePickerFinishedAsync(locationConfig)
    bShouldCreateSimulationCamera = false
    bIsHandlingPickerResult = true

    local position, clubType, swingType, swingPower, windDirection, launchAngle, satMaterialType, wasPerfectPower = Picker.GetResult()
    local ballEntity = Picker.Stop(false)

    UI.SetSwingMeterVisibility(false)
    UI.DisableInstructionalButtons()
    UI.ToggleGolfFlags(false)
    UI.SetSwingHeight(0xFFFFFFFF)
    UI.SetCarryDistance(-1)
    UI.SetSwingDistance(0)
    UI.SetDisplay(DisplayFlag.Minimap | DisplayFlag.SwingDisplay)

    local numShots = 0
    if LobbyData.selectedMinigame then
        numShots = #LobbyData.players[LocalPlayerSrc].minigame.shotResults
    else
        numShots = LobbyData.players[LocalPlayerSrc].holes[LobbyData.activeHoleIndex].numShots
    end
    local relativeWindDirection = launchAngle - math.deg(math.atan(windDirection.x, windDirection.y))

    UI.SetSwingDisplay(SwingDisplayFlags.Wind | SwingDisplayFlags.Spin, LiesIn.None, math.floor(LobbyData.windSpeed), -relativeWindDirection, 0, 0, false, 0, 0.0, numShots + 1)

    LaunchPosition = position
    selectedClubType = clubType
    ballEntities[LocalPlayerSrc] = ballEntity
    hasCarryDistance = false
    local animName = GetActionAnimName(clubType)
    RequestAnimDictAsync("mini@golf")

    TaskPlayAnim(LocalPed, "mini@golf", animName, 2.0, -2.0, -1, 2, 0.0, false, false, false)

    local animDuration = GetAnimDuration("mini@golf", animName)
    RemoveAnimDict("mini@golf")

    local startTime = GetGameTimer()
    while GetGameTimer() - startTime < 400 do
        UI.Update()
        Wait(0)
    end

    if clubType ~= ClubType.P then
        PlaySwingSound()
    end

    PlayLaunchFromMaterialSound(clubType, satMaterialType, ballEntity, wasPerfectPower, swingPower)

    if startBlip ~= 0 then
        OrigenMapa.Quitar(startBlip)
        startBlip = 0
    end

    Simulation.Init(ballEntity, position, windDirection, satMaterialType, locationConfig)

    local launchSuccess = false

    if clubType == ClubType.P then
        local launchVelocity = Simulation.CalculateHorizontalVelocity(swingPower, swingType, clubType, satMaterialType, launchAngle, false)
        launchSuccess = Simulation.HorizontalLaunch(launchVelocity)
    else
        local launchVelocity = Simulation.CalculateSwingVelocity(swingPower, swingType, clubType, satMaterialType, launchAngle, true)
        launchSuccess = Simulation.SwingLaunch(launchVelocity, wasPerfectPower, selectedClubType == ClubType.P)
    end

    if not launchSuccess then
        print("[Golf Warning] Failed to launch ball with parameters " .. json.encode({
            swingPower = swingPower,
            swingType = swingType,
            clubType = clubType,
            satMaterialType = satMaterialType,
            launchAngle = launchAngle,
            wasPerfectPower = wasPerfectPower,
            selectedClubType = selectedClubType
        }))

        TriggerServerEvent("rcore_golf:removeClubForPlayer", locationConfig.name)
        ClearPedTasksImmediately(LocalPed)
        ShowStartShot = true
    else
        isSimulating = true

        lastSentReplayData = GetGameTimer()
        pendingReplayData = {}
        AddReplayPacket(ReplayPacketType.Initialise, position, selectedClubType)

        Wait(math.max(animDuration - 400, 0))

        bShouldCreateSimulationCamera = true
    end

    bIsHandlingPickerResult = false
end

function RemoveSimulationCameraAsync()
    if simulationCamera ~= 0 then
        Wait(1000) -- To view ball once it's landed
        RemoveSimulationCamera()
    end
end

function RemoveSimulationCamera()
    RenderScriptCams(false, true, 500, false, false)
    DeleteCamWithEase(simulationCamera, 500)
    ClearFocus()
    simulationCamera = 0
end

---@param locationConfig LocationConfig
local function HasFinishedShotsForMinigameAndNotify(locationConfig)
    local localPlayerData = LobbyData.players[LocalPlayerSrc]
    if not localPlayerData then
        return
    end

    if LobbyData.selectedMinigame == "score" then
        local numShots, score = GetPlayerMinigameScoreCount(localPlayerData)
        if score >= Config.MinigameScore.scoreToReach then
            ShowSubtitle(Texts.finishedScoreReached)
            return true
        end

        if numShots >= Config.MinigameScore.maxNumShots then
            ShowSubtitle(Texts.finishedReachedMaxShots)
            return true
        end
    elseif LobbyData.selectedMinigame == "pressure" then
        local holeData = locationConfig.MinigamesHoles[LobbyData.minigameHoleIndex]
        local totalNumSegments = holeData.segments[LobbyData.minigameRadiusIndex].numSegments

        local numShots, numSegments = GetPlayerMinigamePressureResult(localPlayerData, LobbyData)
        if numSegments >= totalNumSegments then
            ShowSubtitle(Texts.finishedPressureGame)
            return true
        end

        if numShots >= Config.MinigamePresure.maxNumShots then
            ShowSubtitle(Texts.finishedReachedMaxShots)
            return true
        end
    end

    return false
end

---@param locationConfig LocationConfig
local function UpdatePreparePick(locationConfig)
    if GetRenderingCam() ~= -1 then return end

    local ballEntity = ballEntities[LocalPlayerSrc]

    ---@type vector3[]
    local targetPositions = {}

    if LobbyData.selectedMinigame then
        if HasFinishedShotsForMinigameAndNotify(locationConfig) then
            return
        end
        local startPositions = locationConfig.MinigamesStartPositions
        assert(startPositions, "UpdatePreparePick: In a minigame but start positions are nil")
        targetPositions = startPositions
    else
        targetPositions = {
            locationConfig.HolesConfig[LobbyData.activeHoleIndex].teeCoords
        }
    end

    if not ballEntity then
        ShowSubtitle(string.format(Texts.moveToTeeForShot, ((LobbyData.activeHoleIndex ~= LobbyData.holeOrder[1] and Texts.nextStartingPoint) or Texts.startingPoint)))
    else
        ShowSubtitle(Texts.moveToPositionForShot)
        targetPositions = {
            GetEntityCoords(ballEntity, true)
        }
    end

    local closestPositionIndex = nil
    local closestPositionDistance = 1.5

    local allNearbyPlayerCoords = {}

    -- Hack so we don't have to introduce additional sync. Assume people nearby to a launch position are using it.
    if LobbyData.selectedMinigame then
        local localPlayerPed = PlayerPedId()
        for _, playerIndex in pairs(GetActivePlayers()) do
            local playerPed = GetPlayerPed(playerIndex)
            if playerPed ~= 0 and playerPed ~= localPlayerPed then
                table.insert(allNearbyPlayerCoords, GetEntityCoords(playerPed, true))
            end
        end
    end

    if GetRenderingCam() == -1 then
        local size = Config.CurrentMarkerSize or 0.25
        local colour = Config.CurrentMarkerColour or {255, 255, 0, 125}
        for index, targetPosition in pairs(targetPositions) do
            local shouldShow = true
            if LobbyData.selectedMinigame then
                for _, playerPosition in pairs(allNearbyPlayerCoords) do
                    if #(playerPosition - targetPosition) < 2.0 then
                        shouldShow = false
                        break
                    end
                end
            end

            if shouldShow then
                DrawMarker(0, targetPosition.x, targetPosition.y, targetPosition.z + 0.25, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, size, size, size, colour[1], colour[2], colour[3], colour[4], false, false, 2, false, nil, nil, false)

                local distance = #(LocalPedCoords - targetPosition)
                if distance <= closestPositionDistance then
                    closestPositionIndex = index
                    closestPositionDistance = distance
                end
            end
        end
    end

    local targetPosition = targetPositions[closestPositionIndex]
    if not targetPosition then
        return
    end

    if #(LocalPedCoords - targetPosition) > 1.5 then
        return
    end

    if ShowStartShot and GetVehiclePedIsIn(LocalPed, false) == 0 then
        ShowHelpTextThisFrame("RGOLF_START_SHOT", false)
        if IsControlJustPressed(0, 51) then
            bWasInScoreboard = false
            ShowStartShot = false
            SetCurrentPedWeapon(LocalPed, `WEAPON_UNARMED`, true)
            FreezeEntityPosition(LocalPed, true)
            if ballEntity then
                Picker.StartFromEntity(ballEntity, locationConfig)
            else
                Picker.StartFromTee(targetPosition, locationConfig)
            end
            isPicking = true
        end
    end
end

---@param passedLobbyData table?
---@param locationConfig LocationConfig
function CheckScoreboardDisplay(passedLobbyData, locationConfig)
    if bIsHandlingPickerResult then return end

    if IsControlPressed(0, Config.Keys.scorecard) and passedLobbyData and passedLobbyData.selectedMinigame ~= "training" then
        if not bWasInScoreboard then
            UI.Enable()
            UI.InitScoreboardTitle()
            UI.InitScoreboardPars()
            bWasInScoreboard = true
        end

        UI.SetDisplay(DisplayFlag.Scoreboard)
        SetScoreboardFromLobbyData(passedLobbyData, locationConfig)
        UI.Update()
    else
        UI.SetDisplay(DisplayFlag.None)

        if bWasInScoreboard then
            UI.Disable()
            bWasInScoreboard = false
        end
    end
end

---@param locationConfig LocationConfig
---@return table
local function GetSpotlightCoords(locationConfig)
    local pickerState = GetPickerState()
    local spotlightCoords = {}
    spotlightCoords.ballCoords = {coords = GetEntityCoords(pickerState.ballEntity), radius = 10.0, brightness = 10.0}
    spotlightCoords.holeCoords = {coords = locationConfig.HolesConfig[LobbyData.activeHoleIndex].holeCoords, radius = 250.0, brightness = 100.0}
    if pickerState.selectedClubType == ClubType.P then
        spotlightCoords.playerPos = {coords = GetEntityCoords(LocalPed), radius = 250.0, brightness = 100.0}
    end
    return spotlightCoords
end

---@param locationConfig LocationConfig
local function DrawSpotlightForPlayer(locationConfig)
    if not Config.DrawSpotlights then return end

    if LobbyData.activeHoleIndex == 0 then
        return
    end

    local spotlightCoords = GetSpotlightCoords(locationConfig)

    for _, spotlightData in pairs(spotlightCoords) do
        DrawSpotLight(
            spotlightData.coords.x, spotlightData.coords.y, spotlightData.coords.z + 15.0,
            0.0, 0.0, -1.0,
            255, 255, 255,
            20.0,
            spotlightData.brightness,
            -10.0,
            spotlightData.radius,
            55.0
        )
    end
end

---@param locationConfig LocationConfig
local function UpdateActivePlayer(locationConfig)
    if isSimulating then
        UpdateSimulation(locationConfig)
        if isSimulating and bShouldCreateSimulationCamera then
            UpdateSimulationCamera(locationConfig)
        end
    elseif isPicking then
        UpdateIsPicking(locationConfig)
        DrawSpotlightForPlayer(locationConfig)
    else
        CheckScoreboardDisplay(nil, locationConfig)
        UpdatePreparePick(locationConfig)
    end
end

---@param networkEndTime integer
---@param barIndex integer
---@return integer
local function UpdateEndTimerBar(networkEndTime, barIndex)
    local timeRemainingMsec = networkEndTime - GetNetworkTime()
    if timeRemainingMsec <= 0 then
        return barIndex
    end

    local timeRemainingSecs = math.floor(timeRemainingMsec / 1000)

    local minutesLeft = math.floor(timeRemainingSecs / 60)
    local secondsLeft = timeRemainingSecs % 60

    local function minutesText()
        local text = tostring(minutesLeft)
        if #text == 1 then
            text = "0" .. text
        end
        return text
    end

    local function secondsText()
        local text = tostring(secondsLeft)
        if #text == 1 then
            text = "0" .. text
        end
        return text
    end

    local prefix = (minutesLeft == 0 and secondsLeft < 30) and "~r~" or "~y~"
    DrawTimerBar(prefix .. "TIEMPO", string.format("%s:%s", minutesText(), secondsText()), barIndex, 0.5)

    return barIndex + 1
end

---@param barIndex integer
---@param numShotsLeft integer
---@return integer
local function UpdateShotsLeftTimerbar(barIndex, numShotsLeft)
    local prefix = numShotsLeft < 5 and "~r~" or "~y~"
    DrawTimerBar(prefix .. "GOLPES", tostring(numShotsLeft), barIndex, 0.5)
    return barIndex + 1
end

---@param barIndex integer
---@param locationConfig LocationConfig
---@return integer
local function UpdateMinigameTimerBar(barIndex, locationConfig)
    local localPlayerData = LobbyData.players[LocalPlayerSrc]
    if not localPlayerData then
        return barIndex
    end

    if LobbyData.selectedMinigame == "score" then
        local numShots, score = GetPlayerMinigameScoreCount(localPlayerData)

        local numShotsLeft = Config.MinigameScore.maxNumShots - numShots
        barIndex = UpdateShotsLeftTimerbar(barIndex, numShotsLeft)

        DrawTimerBar("~g~PUNTOS", string.format("%s/%s", score, Config.MinigameScore.scoreToReach), barIndex, 0.5)
        barIndex = barIndex + 1
    elseif LobbyData.selectedMinigame == "pressure" then
        local numShots, numSegments = GetPlayerMinigamePressureResult(localPlayerData, LobbyData)

        local numShotsLeft = Config.MinigamePresure.maxNumShots - numShots
        barIndex = UpdateShotsLeftTimerbar(barIndex, numShotsLeft)

        local holeData = locationConfig.MinigamesHoles[LobbyData.minigameHoleIndex]
        local totalNumSegments = holeData.segments[LobbyData.minigameRadiusIndex].numSegments

        DrawTimerBar("~g~DIANAS", string.format("%s/%s", numSegments, totalNumSegments), barIndex, 0.5)
        barIndex = barIndex + 1
    end

    return barIndex
end

---@param locationConfig LocationConfig
local function UpdateTimerBars(locationConfig)
    local nextBarIndex = 1
    if LobbyData.networkEndTime then
        nextBarIndex = UpdateEndTimerBar(LobbyData.networkEndTime, nextBarIndex)
    end

    UpdateMinigameTimerBar(nextBarIndex, locationConfig)
end

---@param locationConfig LocationConfig
local function UpdateTick(locationConfig)
    UpdateGeneric(locationConfig)

    if Config.NextHoleArrows then
        UpdateRouteHelper(locationConfig)
    end

    UpdateTimerBars(locationConfig)

    local activePlayerSrc = LobbyData.activePlayerIndex ~= 0 and LobbyData.startPlayerOrders[LobbyData.activePlayerIndex] or LocalPlayerSrc
    if LocalPlayerSrc == activePlayerSrc then
        UpdateActivePlayer(locationConfig)
    else
        local activePlayerInfo = LobbyData.players[activePlayerSrc]
        ShowSubtitle(string.format(Texts.waitingForPlayer, activePlayerInfo.name))
        CheckScoreboardDisplay(nil, locationConfig)
    end
end

---@param locationConfig LocationConfig
local function SetupHoleSpecificContent(locationConfig)
    if LobbyData.activeHoleIndex == 0 then
        return
    end

    local holeConfig = locationConfig.HolesConfig[LobbyData.activeHoleIndex]

    flagBlip = 'bandera'
    OrigenMapa.Poner(flagBlip, {
        x = holeConfig.holeCoords.x, y = holeConfig.holeCoords.y, z = holeConfig.holeCoords.z,
        cat = 'activities',
        icono = 'golf',
    })

    local teeBlipData = Config.TeeBlipData or {}
    startBlip = 'salida'
    OrigenMapa.Poner(startBlip, {
        x = holeConfig.teeCoords.x, y = holeConfig.teeCoords.y, z = holeConfig.teeCoords.z,
        cat = 'activities',
        icono = 'golf',
    })
end

local function ResetHoleSpecificContent()
    OrigenMapa.Quitar(flagBlip)
    flagBlip = 0

    OrigenMapa.Quitar(startBlip)
    startBlip = 0
end

local function SafeAudioBankLoad(name)
    local startTime = GetGameTimer()
    while not RequestScriptAudioBank(name, false) do
        if GetGameTimer() - startTime > 2000 then
            print("Failed to load script audio bank " .. name .. " in time")
            break
        end
        Wait(0)
    end
end

local function MainInit()
    TriggerEvent("rcore_golf:setShowRadar", true)
    SafeAudioBankLoad("GOLF_I")
    SafeAudioBankLoad("GOLF_2")
    SafeAudioBankLoad("GOLF_3")
end

local function FinalCleanup()
    if isPicking then
        Picker.Stop(true)
        isPicking = false
        ShowStartShot = true
        ClearPedTasks(LocalPed)
    end

    if isSimulating then
        DeleteEntity(Simulation.GetEntity())
        Simulation.Finish()
        isSimulating = false
        ClearPedTasks(LocalPed)
        RemoveSimulationCamera()
    end
    TriggerEvent("rcore_golf:setShowRadar", false)

    timeExitedBounds = 0
    lastSentReplayData = 0

    ReleaseNamedScriptAudioBank("GOLF_I")
    ReleaseNamedScriptAudioBank("GOLF_2")
    ReleaseNamedScriptAudioBank("GOLF_3")

    ResetHoleSpecificContent()
end

---@param locationConfig LocationConfig
function DisplayHoleBigMessage(locationConfig)
    if not LobbyData.activeHoleIndex or LobbyData.activeHoleIndex == LobbyData.holeOrder[1] then return end
    Citizen.CreateThread(function()

        while GetRenderingCam() ~= -1 do
            Wait(50)
        end

        local title = Texts.hole .. tostring(LobbyData.activeHoleIndex) .. "/" .. tostring(#locationConfig.HolesConfig)
        if LobbyData.selectedMinigame then
            if LobbyData.selectedMinigame == "training" then
                title = Texts.minigameTraining
            elseif LobbyData.selectedMinigame == "score" then
                title = Texts.minigameTopScore
            elseif LobbyData.selectedMinigame == "pressure" then
                title = Texts.minigameTopPressure
            end
        end

        DisplayBigMessage(title, Texts.nextStartingPointBigMessage, 2000)
    end)
end

RegisterNetEvent("rcore_golf:holeHasChanged", function(locationName)
    waitingForHole = false
    ResetHoleSpecificContent()
    local locationConfig = LocationsConfig[locationName]
    SetupHoleSpecificContent(locationConfig)
    DisplayHoleBigMessage(locationConfig)
end)

RegisterNetEvent("rcore_golf:waitForHole", function()

    waitingForHole = true
    while waitingForHole do
        Wait(0)
        ShowSubtitle(Texts.waitingForHole)
    end
end)

function AttachBlipToBall(playerSrc)
    if not LobbyData then
        return
    end

    local playerInfo = LobbyData.players[playerSrc]
    if not playerInfo then
        return
    end

    local ballEntity = ballEntities[playerSrc]
    if not ballEntity then
        return
    end

    if GetBlipFromEntity(ballEntity) == 0 then
        local blip = 'bola'
        OrigenMapa.Poner(blip, {
            entidad = ballEntity,
            cat = 'activities',
            icono = 'golf',
        })
    end
end

function UpdateOrCreateBall(playerSrc, ballData)
    local ballEntity = ballEntities[playerSrc]

    if not ballEntity then
        local ballModel = GetHashKey("prop_golf_ball" .. GetBallModelPrefix(ballData[1]))
        RequestModelAsync(ballModel)
        ballEntity = CreateObjectNoOffset(ballModel, 0.0, 0.0, 0.0, false, false, false)
        SetModelAsNoLongerNeeded(ballModel)

        ballEntities[playerSrc] = ballEntity
    end

    local coords = ballData[2]
    SetEntityCoordsNoOffset(ballEntity, coords.x, coords.y, coords.z, false, false, false)
    FreezeEntityPosition(ballEntity, true)

    AttachBlipToBall(playerSrc)

    return ballEntity
end

function GetLocalPlayerNumberOfShots()
    local playerInfo = LobbyData.players[LocalPlayerSrc]
    if playerInfo then
        local holeInfo = playerInfo.holes[LobbyData.activeHoleIndex]
        if holeInfo then
            return holeInfo.numShots
        end
    end
    return -1
end

RegisterNetEvent("rcore_golf:sendFullBalls", function(data)
    for playerSrc, ballData in pairs(data) do
        UpdateOrCreateBall(playerSrc, ballData)
    end
end)

RegisterNetEvent("rcore_golf:sendSingleBall", function(playerSrc, ballData)
    KillReplayForPlayer(playerSrc)
    UpdateOrCreateBall(playerSrc, ballData)
end)

RegisterNetEvent("rcore_golf:removeBallForPlayer", function(playerSrc)
    KillReplayForPlayer(playerSrc)

    local ballEntity = ballEntities[playerSrc]
    if ballEntity then
        DeleteEntity(ballEntity)
        ballEntities[playerSrc] = nil
    end
end)

function InitMainThread()
    if LobbyData and not bIsMainThreadRunning then
        bIsMainThreadRunning = true
        MainInit()
        while LobbyData do
            DisplayRadar(true)
            if not waitingForHole then
                UpdateTick(LocationsConfig[LobbyData.locationName])
            end
            Wait(0)
        end
        FinalCleanup()
        bIsMainThreadRunning = false
    end
end

---@param winnerString string
---@param isWinner boolean
---@param passedLobbyData GameData
---@param winAmount number
---@param locationConfig LocationConfig
local function ReturnToClubHouseTick(winnerString, isWinner, passedLobbyData, winAmount, locationConfig)
    while true do
        Wait(0)
        if passedLobbyData.selectedMinigame then
            ShowSubtitle(Texts.returnToMinigameLobby)
        else
            ShowSubtitle(Texts.returnToClubhouse)
        end

        if not passedLobbyData.selectedMinigame then
            ShowHelpTextThisFrame("RGOLF_SHOW_SCORECARD", false)
            CheckScoreboardDisplay(passedLobbyData, locationConfig)
        end

        if #(LocalPedCoords - locationConfig.LobbyCoords) <= 5.0 then
            DisplayBigMessage((isWinner and Texts.gameWon or Texts.gameLost), winnerString, 2000)
            DisplayRadar(not Config.DisableRadarAfterGame)
            IncrementGameStats(isWinner, winAmount)
            break
        end
    end
end

RegisterNetEvent("rcore_golf:returnToClubhouse", function(gameWinners, winnerString, winAmount, locationName)
    local isWinner = IsPlayerAWinner(gameWinners)
    local locationConfig = LocationsConfig[locationName]
    ReturnToClubHouseTick(winnerString, isWinner, LobbyData, winAmount, locationConfig)
end)

local function CleanupEntities()
    CleanupBallEntities()
    CleanupClubEntities()
    CleanupTeeAndBallEntities()
end

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if DoesEntityExist(vehicleCaddy) then
            DeleteEntity(vehicleCaddy)
        end

        if DoesBlipExist(caddyBlip) then
            OrigenMapa.Quitar(caddyBlip)
        end

        UI.Disable()
        UI.ToggleGolfFlags(false)
        UI.SetTrailEnabled(false)

        if isPicking then
            Picker.Stop(true)
        end

        if isSimulating then
            Simulation.Finish()
        end

        BlurFadeOut()
        CleanupEntities()
    end
end)

RegisterNetEvent("rcore_golf:killEverythingSynced", function()
    CleanupEntities()
end)

for locationName, locationConfig in pairs(LocationsConfig) do
    locationConfig.name = locationName
end

---@param holeData MinigamesConfigHole
---@param radiusIndex integer
---@param segmentIndex integer
---@param red integer
---@param green integer
---@param blue integer
function DrawMinigameHoleSegment(holeData, radiusIndex, segmentIndex, red, green, blue)
    local previousRadius = radiusIndex == 1 and 0.0 or holeData.segments[radiusIndex - 1].radius

    local segmentData = holeData.segments[radiusIndex]
    local angleBetweenSegements = 360.0 / segmentData.numSegments

    local startAngle = -segmentData.initialHeading + angleBetweenSegements * (segmentIndex - 1)

    local numPolys = 5
    local angleBetweenEdgeVertex = angleBetweenSegements / numPolys

    for polyIndex = 1, numPolys do
        local polyAngle2 = startAngle + angleBetweenEdgeVertex * (polyIndex - 1)
        local polyAngle2Rads = math.rad(polyAngle2)
        local polyDirection2 = vector3(math.sin(polyAngle2Rads), math.cos(polyAngle2Rads), 0.0)

        local polyAngle3 = polyAngle2 + angleBetweenEdgeVertex
        local polyAngle3Rads = math.rad(polyAngle3)
        local polyDirection3 = vector3(math.sin(polyAngle3Rads), math.cos(polyAngle3Rads), 0.0)

        local polyEdge1 = holeData.position + (polyDirection2 * previousRadius)
        local polyEdge2 = holeData.position + (polyDirection2 * segmentData.radius)

        local polyEdge3 = holeData.position + (polyDirection3 * previousRadius)
        local polyEdge4 = holeData.position + (polyDirection3 * segmentData.radius)

        DrawPoly(polyEdge2.x, polyEdge2.y, polyEdge2.z, polyEdge1.x, polyEdge1.y, polyEdge1.z, polyEdge4.x, polyEdge4.y, polyEdge4.z, red, green, blue, 255)
        DrawPoly(polyEdge1.x, polyEdge1.y, polyEdge1.z, polyEdge3.x, polyEdge3.y, polyEdge3.z, polyEdge4.x, polyEdge4.y, polyEdge4.z, red, green, blue, 255)
    end
end

-- Debug code, do not remove!
-- Citizen.CreateThread(function()
--     for _, locationConfig in pairs(LocationsConfig) do
--         for _, boundData in pairs(locationConfig.MainBounds) do
--             local boundPos = boundData[1]
--             local blip = 'golf_4'
--             OrigenMapa.Poner(blip, {
--                 x = boundPos.x, y = boundPos.y, z = boundPos.z,
--                 cat = 'activities',
--                 radio = boundData[2] + 0.0,
--             })
--             SetBlipAlpha(blip, 150)
--         end

--         Citizen.CreateThread(function()
--             while true do
--                 if locationConfig.MinigamesHoles then
--                     for _, holeData in pairs(locationConfig.MinigamesHoles) do
--                         for circleSegmentIndex, segmentData in pairs(holeData.segments) do
--                             local rgb = {255, 0, 0}
--                             if circleSegmentIndex == 2 then
--                                 rgb = {0, 255, 0}
--                             elseif circleSegmentIndex == 3 then
--                                 rgb = {0, 0, 255}
--                             end
--                             DrawMarker(1, holeData.position.x, holeData.position.y, holeData.position.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, segmentData.radius * 2.0, segmentData.radius * 2.0, 0.2, rgb[1], rgb[2], rgb[3], 255, false, false, 2, false, nil, nil, false)
--                             DrawMinigameHoleSegment(holeData, circleSegmentIndex, math.floor(GetGameTimer() / 100) % 8, rgb[1], rgb[2], rgb[3])
--                         end
--                     end
--                 end
--                 Wait(0)
--             end
--         end)
--     end
-- end)