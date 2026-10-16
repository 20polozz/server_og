SwingDisplayFlags = {
    All = -1,
    None = 0,
    Grass = 1,
    Wind = 2,
    Club = 4,
    Power = 8,
    Spin = 16,
    ShotNum = 32
}

LiesIn = {
    None = 0,
    Path = 1,
    Bunker = 2,
    Green = 3,
    Fairway = 4,
    Rough = 6,
    Tee = 7,
}

ClubType = {
    None = 0,
    D = 1,
    _3W = 3,
    _5W = 5,
    _3L = 7,
    _4L = 8,
    _5L = 9,
    _6L = 10,
    _7L = 11,
    _8L = 12,
    _9L = 13,
    PW = 14,
    SW = 16,
    LW = 17,
    P = 19,
}

SwingType = {
    Normal = 0,
    Power = 1,
    Punch = 2,
    Approach = 3,
    ShortPutt = 4,
    Putt = 5,
    LongPutt = 6,
    ScriptControlled = 7,
}

HoleResult = {
    InOne = 0,
    IsPar = 1,
    UnderPar = 2,
    OverPar = 3
}

StateFlag = {
    None = 0,
    Highlight = 1,
    IsMultiplayer = 2,
    HasCrewTag = 4,
    IsReady = 8,
    HideBall = 16,
    ---Gets the bits that should be added onto the StateFlag enum
    ---@param hole1 integer A single value from the HoleResult enum for the first hole
    ---@param hole2 integer A single value from the HoleResult enum for the second hole
    ---@param hole3 integer A single value from the HoleResult enum for the third hole
    ---@param hole4 integer A single value from the HoleResult enum for the fourth hole
    ---@param hole5 integer A single value from the HoleResult enum for the fifth hole
    ---@param hole6 integer A single value from the HoleResult enum for the sixth hole
    ---@param hole7 integer A single value from the HoleResult enum for the seventh hole
    ---@param hole8 integer A single value from the HoleResult enum for the eighth hole
    ---@param hole9 integer A single value from the HoleResult enum for the ninth hole
    ---@return integer
    GetScoreShapeBits = function(hole1, hole2, hole3, hole4, hole5, hole6, hole7, hole8, hole9)
        local shift = 4
        local function GetBits(value)
            shift = shift + 2
            if value == HoleResult.InOne then
                return 1 << shift
            elseif value == HoleResult.UnderPar then
                return 2 << shift
            elseif value == HoleResult.OverPar then
                return 3 << shift
            end
            return 0 << shift
        end
        return GetBits(hole1) | GetBits(hole2) | GetBits(hole3) | GetBits(hole4) | GetBits(hole5) | GetBits(hole6) | GetBits(hole7) | GetBits(hole8) | GetBits(hole9)
    end
}

DisplayFlag = {
    All = -1,
    None = 0,
    Minimap = 1,
    SwingDisplay = 2,
    Scoreboard = 16
}

ButtonFlag = {
    All = -1,
    None = 0,
    Reset = 1,
    Club = 2,
    Quit = 4,
    Aim = 8,
    Swing = 16,
    Shot = 32,
    Scoreboard = 64,
    PreviewHole = 128,
    PreviewShot = 256,
}

PickerResult = {
    Pending = 0,
    Finished = 1,
    Exited = 2
}

MaterialType = {
    Invalid = -1,
    Sand = 0,
    Concrete = 1,
    Fairway = 2,
    Green = 3,
    Rough = 4,
    Tee = 5,
    Water = 7,
    Hole = 8,
    Bushes = 9
}

SimulationResult = {
    Invalid = -1,
    Pending = 0,
    Ended = 1,
    InHole = 2,
    Killed = 3
}

ReplayPacketType = {
    Initialise = 0,
    Position = 1,
    TrailEnd = 2,
    Finish = 3,
    Sound = 4,
    Particle = 5
}

function RequestModelAsync(modelHash)
    while not HasModelLoaded(modelHash) do
        RequestModel(modelHash)
        Wait(0)
    end
end

function RequestAnimDictAsync(animDict)
    while not HasAnimDictLoaded(animDict) do
        RequestAnimDict(animDict)
        Wait(0)
    end
end

function RequestParticleFxAsync(ptfxDict)
    local startTime = GetGameTimer()
    while not HasNamedPtfxAssetLoaded(ptfxDict) do
        RequestNamedPtfxAsset(ptfxDict)
        if GetGameTimer() - startTime > 500 then
            print("[Golf Warning] Timed out whilst requesting particle " .. tostring(ptfxDict))
            break
        end
        Wait(0)
    end
end

---@param holeIndex integer
---@param coords vector3
---@param locationConfig LocationConfig
---@return boolean
function IsCoordsInBounds(holeIndex, coords, locationConfig)
    local bounds = locationConfig.MainBounds
    if holeIndex ~= 0 then
        bounds = locationConfig.HolesConfig[holeIndex].bounds
    end

    for _, boundData in pairs(bounds) do
        if #(coords - boundData[1]) < boundData[2] then
            return true
        end
    end
    return false
end

local lastSubtitle = nil
local lastSubtitleTime = 0
function ShowSubtitle(message)
    if GetRenderingCam() == -1 then
        local cleanMessage = message:gsub("~.-~", "")
        local currentTime = GetGameTimer()
        
        -- Only show if message changed OR if 15 seconds have passed since the last same notification
        if lastSubtitle ~= cleanMessage or (currentTime - lastSubtitleTime) > 15000 then
            exports['origen_notify']:showNotification({
                title = 'LS GOLF CLUB',
                description = cleanMessage,
                type = 'primary',
                duration = 10000
            })
            lastSubtitle = cleanMessage
            lastSubtitleTime = currentTime
        end
    end
end

function ConvertMetersToYards(meters)
    return meters * 1.0936132983
end

function ConvertMetersToFeet(meters)
    return meters * 3.28084
end

function DisplayBigMessage(title, message, duration, offset)
    Citizen.CreateThreadNow(function()
        local scaleform = RequestScaleformMovie("mp_big_message_freemode")
        while not HasScaleformMovieLoaded(scaleform) do
            Wait(0)
        end

        local startTime = GetGameTimer()
        while GetGameTimer() - startTime < duration do
            BeginScaleformMovieMethod(scaleform, "SHOW_SHARD_WASTED_MP_MESSAGE")
            ScaleformMovieMethodAddParamTextureNameString(title)
            ScaleformMovieMethodAddParamTextureNameString(message)
            EndScaleformMovieMethod()
            if not offset then
                DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255, 0)
            else
                DrawScaleformMovie(scaleform, offset.x, offset.y, 0.8, 0.8, 255, 255, 255, 255, 0)
            end
            Wait(0)
        end
    end)
end

function GetBallModelPrefix(playerNum)
    if playerNum >= 2 and playerNum <= 4 then
        return "_p" .. tostring(playerNum)
    else
        return ""
    end
end

function table.count(self)
    local count = 0
    for _ in pairs(self) do
        count = count + 1
    end
    return count
end

function table.copy(obj, seen)
    if type(obj) ~= "table" then return obj end
    if seen and seen[obj] then return seen[obj] end
    local s = seen or {}
    local res = setmetatable({}, getmetatable(obj))
    s[obj] = res
    for k, v in pairs(obj) do res[table.copy(k, s)] = table.copy(v, s) end
    return res
end

---@param locationConfig LocationConfig
---@param lobbyData GameData
local function SetScoreboardFromMinigameData(locationConfig, lobbyData)
    local scoreboardData = {
        rows = {}
    }

    if lobbyData.selectedMinigame == "score" then
        scoreboardData.name = string.format("Score (X/%s)", Config.MinigameScore.scoreToReach)

        for _, playerData in pairs(lobbyData.players) do
            local numShots, score = GetPlayerMinigameScoreCount(playerData)
            table.insert(scoreboardData.rows, {
                name = playerData.name,
                numShots = numShots,
                value = tostring(score),
            })
        end
    elseif lobbyData.selectedMinigame == "pressure" then
        local holeData = locationConfig.MinigamesHoles[lobbyData.minigameHoleIndex]
        local totalNumSegments = holeData.segments[lobbyData.minigameRadiusIndex].numSegments

        scoreboardData.name = string.format("Holes Completed (X/%s)", totalNumSegments)

        for _, playerData in pairs(lobbyData.players) do
            local numShots, segmentsDone = GetPlayerMinigamePressureResult(playerData, lobbyData)
            table.insert(scoreboardData.rows, {
                name = playerData.name,
                numShots = numShots,
                value = tostring(segmentsDone),
            })
        end
    end

    SendReactMessage("setScoreboardData", scoreboardData)
end

---@param passedLobbyData any
---@param locationConfig LocationConfig
function SetScoreboardFromLobbyData(passedLobbyData, locationConfig)
    local LobbyData = LobbyData or passedLobbyData
    if LobbyData.selectedMinigame then
        SetScoreboardFromMinigameData(locationConfig, LobbyData)
        return
    end

    local activePlayerSrc = LobbyData.activePlayerIndex ~= 0 and LobbyData.startPlayerOrders[LobbyData.activePlayerIndex] or nil

    local scoreboardIndex = 0
    for playerSrc, playerInfo in pairs(LobbyData.players) do
        local flags = StateFlag.None
        if playerSrc == activePlayerSrc then
            flags = flags | StateFlag.Highlight
        end

        local holeResults = {}
        local holeAmounts = {}
        local totalScore = 0

        for holeIndex, holeInfo in pairs(playerInfo.holes) do
            local holePar = locationConfig.HolesConfig[holeIndex].par

            local holeResult = HoleResult.IsPar
            if holeInfo.hasFinished then
                if holeInfo.numShots == 1 then
                    holeResult = HoleResult.InOne
                elseif holeInfo.numShots > holePar then
                    holeResult = HoleResult.OverPar
                elseif holeInfo.numShots < holePar then
                    holeResult = HoleResult.UnderPar
                end

                table.insert(holeAmounts, tostring(holeInfo.numShots))
                totalScore = totalScore + holeInfo.numShots
            else
                table.insert(holeAmounts, "")
            end

            table.insert(holeResults, holeResult)
        end

        flags = flags | StateFlag.GetScoreShapeBits(table.unpack(holeResults))
        UI.SetScoreboardSlot(scoreboardIndex, flags, playerInfo.name, "crew", "PLAYER_READY", 28 + scoreboardIndex, totalScore, 0, table.unpack(holeAmounts))

        scoreboardIndex = scoreboardIndex + 1
    end
end

function tprint (tbl, indent)
    if not indent then indent = 0 end
    if type(tbl) == 'table' then
       for k, v in pairs(tbl) do
          formatting = string.rep("  ", indent) .. k .. ": "
          if type(v) == "table" then
             print(formatting)
             tprint(v, indent+1)
          elseif type(v) == 'boolean' then
             print(formatting .. tostring(v))
          else
             print(formatting .. v)
          end
       end
    else
       print(tbl)
    end
end

function DeleteCamWithEase(cameraIndex, easeMilliseconds)
    Citizen.CreateThread(function()
        Citizen.Wait(easeMilliseconds)
        SetCamActive(cameraIndex, false)
        DestroyCam(cameraIndex, false)
    end)
end

function GetBallBlipColour(playerNum)
    if playerNum == 2 then
        return 5
    elseif playerNum == 3 then
        return 17
    elseif playerNum == 4 then
        return 8
    end
    return 0
end

function IsPlayerAWinner(gameWinners)
    for _, src in pairs(gameWinners) do
        if src == LocalPlayerSrc then
            return true
        end
    end
    return false
end

local lastHelpMsg = nil
local lastFrameHelp = 0

local function GetTextFromKey(key)
    local text = key
    if key == "RGOLF_LOBBY" then
        text = Texts.openLobby:format("[" .. Config.Keys.openLobbyKey .. "]"):gsub("~INPUT_%w+~", "")
    elseif key == "RGOLF_SHOW_SCORECARD" then
        local keyStr = "F10" -- Standard mapping for 311 if not otherwise specified
        text = Texts.openScorecard:gsub("~INPUT_%w+~", "["..keyStr.."]")
    elseif key == "RGOLF_RETURN_BOUNDS" then
        text = Texts.returnToBounds:gsub("~INPUT_%w+~", "")
    elseif key == "RGOLF_START_SHOT" then
        text = Texts.startShot:gsub("~INPUT_%w+~", "[E]")
    elseif key == "RGOLF_CADDY_SPAWNED" then
        text = Texts.caddySpawned
    elseif key == "RGOLF_PURCHASE_MEMBERSHIP" then
        text = Texts.purchaseMembership:format("[" .. Config.Keys.openLobbyKey .. "]", Texts.currency..tostring(Config.MembershipPrice)):gsub("~INPUT_%w+~", "")
    end
    return text:gsub("~.-~", "")
end

function ShowTimedHelpText(message, duration)
    local text = GetTextFromKey(message)
    local key = "E"
    if message:find("SCORECARD") then key = "F10" end
    
    exports['origen_notify']:DrawText(key, text:gsub("%["..key.."%]", ""):gsub("Pulsa ", ""))
    Citizen.SetTimeout(duration or 5000, function()
        if lastHelpMsg == text then
            exports['origen_notify']:HideText()
            lastHelpMsg = nil
        end
    end)
    lastHelpMsg = text
end

local bIsHidingThreadRunning = false
function ShowHelpTextThisFrame(message, curved)
    local text = GetTextFromKey(message)
    local currentTime = GetGameTimer()
    
    if lastHelpMsg ~= text then
        local key = "E"
        if message:find("SCORECARD") then key = "F10" end
        if message:find("LOBBY") then key = Config.Keys.openLobbyKey end
        
        exports['origen_notify']:DrawText(key, text:gsub("%["..key.."%]", ""):gsub("Pulsa ", ""))
        lastHelpMsg = text
    end
    lastFrameHelp = currentTime
    
    if not bIsHidingThreadRunning then
        bIsHidingThreadRunning = true
        Citizen.CreateThread(function()
            while true do
                Wait(500)
                if GetGameTimer() - lastFrameHelp > 750 and lastHelpMsg then
                    exports['origen_notify']:HideText()
                    lastHelpMsg = nil
                    bIsHidingThreadRunning = false
                    break
                end
            end
        end)
    end
end

function GetActionAnimName(clubType)
    local animName = UI.GetClubTypeMaterial(clubType) .. "_"
    if clubType == ClubType.P then
        animName = animName .. "action_"
    else
        animName = animName .. "swing_action_"
    end
    return animName .. "high"
end

---@param playerData PlayerData
---@return integer numShots
---@return integer score
function GetPlayerMinigameScoreCount(playerData)
    local numShots = 0
    local score = 0

    for _, result in pairs(playerData.minigame.shotResults) do
        numShots = numShots + 1
        if result.score then
            score = score + result.score
        end
    end

    return numShots, score
end

---@param playerData PlayerData
---@param lobbyData GameData?
---@return integer numShots
---@return integer segmentsDone
function GetPlayerMinigamePressureResult(playerData, lobbyData)
    local numShots = 0
    local segmentsDone = {}

    for _, result in pairs(playerData.minigame.shotResults) do
        numShots = numShots + 1
        if result.segmentIndex and lobbyData and result.radiusIndex == lobbyData.minigameRadiusIndex and result.holeIndex == lobbyData.minigameHoleIndex then
            segmentsDone[result.segmentIndex] = true
        end
    end

    return numShots, table.count(segmentsDone)
end

---@param message string
function DebugLog(message)
    if Config.Debug then
        print(string.format("[RCore Golf Debug] %s", message))
    end
end

if IsDuplicityVersion() then
    ---@param locationData LocationSpecificData
    ---@return GameData?
    function GetPendingLobbyData(locationData)
        for _, lobbyData in pairs(locationData.gameData) do
            if not lobbyData.hasStarted then
                return lobbyData
            end
        end
        return nil
    end

    ---@param source Source
    ---@param locationData LocationSpecificData
    ---@return Source?
    function GetLobbySrcPlayerIsIn(source, locationData)
        for leaderSrc, lobbyData in pairs(locationData.gameData) do
            if leaderSrc == source then return leaderSrc end

            if lobbyData.players[source] then return leaderSrc end
        end
        return nil
    end

    ---@param locationData LocationSpecificData
    function SendGameDataToSubscribed(locationData)
        local pendingLobbyData = GetPendingLobbyData(locationData)
        for playerSrc in pairs(locationData.uiSubscribedPlayers) do
            TriggerClientEvent("rcore_golf:sendPendingLobbyData", playerSrc, pendingLobbyData)
        end
    end

    ---@param lobbyData GameData
    ---@param eventName string
    ---@param ... any
    function SendEventToLobby(lobbyData, eventName, ...)
        for playerSrc in pairs(lobbyData.players) do
            TriggerClientEvent(eventName, playerSrc, ...)
        end
    end

    ---@param lobbyData GameData
    ---@param string string
    function SendNotificationToLobby(lobbyData, string)
        for playerSrc in pairs(lobbyData.players) do
            ShowNotification(playerSrc, string)
        end
    end

    ---@param eventName string
    ---@param bucketId integer?
    ---@param locationData LocationSpecificData
    ---@param ... any
    function SendEventToCourseSubscribers(eventName, bucketId, locationData, ...)
        for playerSrc in pairs(locationData.courseSubscribedPlayers) do
            if not bucketId or (bucketId and tonumber(GetPlayerRoutingBucket(playerSrc)) == tonumber(bucketId)) then
                TriggerClientEvent(eventName, playerSrc, ...)
            end
        end
    end

    ---@param lobbyData GameData
    ---@return Source[]
    function GetGameWinner(lobbyData)
        local winningPlayers = {}
        local lowestShotCount = nil
        local currentShotCount = 0
        for playerSrc, playerData in pairs(lobbyData.players) do
            currentShotCount = 0
            for _, holeData in pairs(playerData.holes) do
                currentShotCount = currentShotCount + holeData.numShots
            end

            if not lowestShotCount then
                lowestShotCount = currentShotCount
                table.insert(winningPlayers, playerSrc)
            elseif lowestShotCount == currentShotCount then
                table.insert(winningPlayers, playerSrc)
            elseif lowestShotCount > currentShotCount then
                winningPlayers = {}
                table.insert(winningPlayers, playerSrc)
            end
        end
        return winningPlayers
    end

    ---@param inputTable table
    function RandomSortTable(inputTable)
        for index = 1, #inputTable do
            local swapIndex = math.random(1, #inputTable)
            local valueCopy = inputTable[index]
            inputTable[index] = inputTable[swapIndex]
            inputTable[swapIndex] = valueCopy
        end
    end

    ---@param players table<Source, any>
    ---@return Source[]
    function StructureLobbyPlayers(players)
        local structuredTable = {}
        for playerSrc in pairs(players) do
            table.insert(structuredTable, playerSrc)
        end
        return structuredTable
    end

    ---@param lobbyData GameData
    ---@param locationData LocationSpecificData
    ---@return vector3[]
    function SplitCaddySpawnLocations(lobbyData, locationData)
        local locationConfig = LocationsConfig[locationData.name]

        local spawnsPerPlayer = math.floor(#locationConfig.CaddySpawns / table.count(lobbyData.players))
        local strucutedPlayers = StructureLobbyPlayers(lobbyData.players)
        local spawnsForPlayers = {}
        local playerIndex = 1
        for index, spawnCoords in pairs(locationConfig.CaddySpawns) do
            if not spawnsForPlayers[strucutedPlayers[playerIndex]] then spawnsForPlayers[strucutedPlayers[playerIndex]] = {} end
            table.insert(spawnsForPlayers[strucutedPlayers[playerIndex]], spawnCoords)
            if (index % spawnsPerPlayer == 0.0) and strucutedPlayers[playerIndex+1] then
                playerIndex = playerIndex + 1
            end
        end
        return spawnsForPlayers
    end

    ---@param playersWhoCantAfford Source[]
    ---@return string
    function FormulateCannotAffordString(playersWhoCantAfford)
        local cannotAffordString = ""
        for index, playerSrc in pairs(playersWhoCantAfford) do
            if #playersWhoCantAfford == 1 then
                cannotAffordString = (GetCharacterName(playerSrc) or "placeholder")  .. " can not afford this wager!"
            elseif #playersWhoCantAfford == index then
                cannotAffordString = cannotAffordString .. " and " .. (GetCharacterName(playerSrc) or "placeholder")  .. " can not afford this wager!"
            else
                cannotAffordString = cannotAffordString .. (GetCharacterName(playerSrc) or "placeholder") .. (#playersWhoCantAfford - index >= 2 and ", " or "")
            end
        end
        return cannotAffordString
    end

    ---@param winners Source[]
    ---@return string
    function FormulateWinnerString(winners)
        local winnerString = ""
        for index, source in pairs(winners) do
            if #winners == 1 then
                winnerString = (GetCharacterName(source) or "placeholder")  .. " has won the game!"
            elseif #winners == index then
                winnerString = winnerString .. " and " .. (GetCharacterName(source) or "placeholder")  .. " has won the game!"
            else
                winnerString = winnerString .. (GetCharacterName(source) or "placeholder") .. (#winners - index >= 2 and ", " or "")
            end
        end
        return winnerString
    end

    ---@param lobbyData GameData
    ---@param locationData LocationSpecificData
    ---@return integer
    function GetNextSuitablePlayerIndex(lobbyData, locationData)
        assert(lobbyData.activePlayerIndex ~= 0)

        local currentIndex = lobbyData.activePlayerIndex
        local workingIndex = currentIndex

        if ShouldActivePlayerShootNext(lobbyData, locationData) then
            return currentIndex
        end

        local furthestPlayerIndex = GetFurthestSuitablePlayer(lobbyData, locationData)
        if furthestPlayerIndex ~= -1 then
            return furthestPlayerIndex
        end

        repeat
            workingIndex = workingIndex + 1
            if workingIndex > table.count(lobbyData.players) then
                workingIndex = 1
            end

            local workingPlayerSrc = lobbyData.startPlayerOrders[workingIndex]
            local workingPlayerInfo = lobbyData.players[workingPlayerSrc]
            local workingPlayerHoleInfo = workingPlayerInfo.holes[lobbyData.activeHoleIndex]

            if not workingPlayerHoleInfo.hasFinished then
                return workingIndex
            end
        until currentIndex == workingIndex

        return -1
    end

    ---@param lobbyData GameData
    ---@param locationData LocationSpecificData
    ---@return integer
    function GetFurthestSuitablePlayer(lobbyData, locationData)
        -- We are not interested in picking based on furthest.
        if not Config.FurthestShootsFirst then
            return -1
        end

        local locationConfig = LocationsConfig[locationData.name]

        local holeCoords = locationConfig.HolesConfig[lobbyData.activeHoleIndex].holeCoords

        local furthestDistance = 0.0
        local furthestPlayerSrc = nil

        for playerSrc, playerInfo in pairs(lobbyData.players) do
            local playerHoleInfo = playerInfo.holes[lobbyData.activeHoleIndex]

            -- Do not pick next player based on furthest until all players have taken at least one shot.
            if playerHoleInfo.numShots == 0 then
                return -1
            end

            if not playerHoleInfo.hasFinished then
                local ballData = locationData.ballsData[playerSrc]
                if ballData then
                    local distanceToHole = #(ballData[2] - holeCoords)
                    if distanceToHole > furthestDistance then
                        furthestDistance = distanceToHole
                        furthestPlayerSrc = playerSrc
                    end
                end
            end
        end

        if furthestPlayerSrc then
            for playerIndex, playerSrc in pairs(lobbyData.startPlayerOrders) do
                if playerSrc == furthestPlayerSrc then
                    return playerIndex
                end
            end
        end

        return -1
    end

    ---@param lobbyData GameData
    ---@param locationData LocationSpecificData
    ---@return boolean
    function ShouldActivePlayerShootNext(lobbyData, locationData)
        assert(lobbyData.activePlayerIndex ~= 0)

        if not Config.NextToHoleShootsNext then
            return false
        end

        local playerSrc = lobbyData.startPlayerOrders[lobbyData.activePlayerIndex]
        if not playerSrc then
            return false
        end

        local playerInfo = lobbyData.players[playerSrc]
        local playerHoleInfo = playerInfo.holes[lobbyData.activeHoleIndex]
        if playerHoleInfo.hasFinished then
            return false
        end

        local ballData = locationData.ballsData[playerSrc]
        if not ballData then
            return false
        end

        local locationConfig = LocationsConfig[locationData.name]

        local holeCoords = locationConfig.HolesConfig[lobbyData.activeHoleIndex].holeCoords
        local distanceToHole =  #(ballData[2] - holeCoords)

        return distanceToHole < Config.NextToHoleDistance
    end
else
    ---@param holeData MinigamesConfigHole
    ---@param radiusIndex integer
    ---@param red integer
    ---@param green integer
    ---@param blue integer
    function DrawMinigameHoleRing(holeData, radiusIndex, red, green, blue)
        local scale = holeData.segments[radiusIndex].radius * 2.0
        DrawMarker(1, holeData.position.x, holeData.position.y, holeData.position.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, scale, scale, 0.4, red, green, blue, 255, false, false, 2, false, nil, nil, false)
    end

    ---@param title string
    ---@param text string
    ---@param barIndex integer
    ---@param textScale number
    function DrawTimerBar(title, text, barIndex, textScale)
        local width = 0.17
        local hTextMargin = -0.01
        local rectHeight = 0.038
        local textMargin = 0.008
        local rectMargin = 0.005
        local heightMargin = -0.04
        local widthMargin = 0.014
        local safeZoneSize = GetSafeZoneSize()

        local rectX = widthMargin + safeZoneSize - width + width / 2
        local rectY = heightMargin + safeZoneSize - rectHeight + rectHeight / 2 - (barIndex - 1) * (rectHeight + rectMargin)

        DrawSprite("timerbars", "all_black_bg", rectX + 0.02, rectY, width - 0.035, 0.038, 0, 0, 0, 0, 128)

        DrawText(title, safeZoneSize - width + 0.06, rectY - textMargin, 0.32)
        DrawText(string.upper(text), safeZoneSize - hTextMargin + 0, rectY - 0.0175, textScale, true, width / 2)
    end

    ---@param text string
    ---@param x number
    ---@param y number
    ---@param scale number
    ---@param right boolean
    ---@param width number
    function DrawText(text, x, y, scale, right, width)
        SetTextFont(0)
        SetTextScale(scale, scale)
        SetTextColour(254, 254, 254, 255)

        if right then
            SetTextWrap(x - width, x)
            SetTextRightJustify(true)
        end

        BeginTextCommandDisplayText("STRING")
        AddTextComponentSubstringPlayerName(text)
        EndTextCommandDisplayText(x, y)
    end

    ---@param coords vector3
    ---@param text string
    ---@param scale number
    function DrawText3D(coords, text, scale)
        local onScreen, x, y = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z, 0.0, 0.0)
        if not onScreen then
            return
        end

        SetTextScale(scale, scale)
        SetTextFont(0)
        SetTextColour(255, 255, 255, 255)
        SetTextCentre(true)
        SetTextDropshadow(0, 0, 0, 0, 55)
        SetTextDropShadow()
        SetTextOutline()

        BeginTextCommandDisplayText("STRING")
        AddTextComponentSubstringPlayerName(text)
        EndTextCommandDisplayText(x, y)
    end
end