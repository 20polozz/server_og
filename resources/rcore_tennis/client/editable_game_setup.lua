PlayerSettings = nil

local showingHelp = false

function HandleStartPlayingPoint(ped, coords, courtIdx, positionName, serverPointCoords)
    DrawMarker(
        22, 
        serverPointCoords.x, serverPointCoords.y, serverPointCoords.z + 1.0, 
        0.0, 0.0, 0.0, 
        0.0, 0.0, 0.0, 
        0.2, 0.2, 0.2, 
        0, 0, 0, 150, 
        false, false, false, false, nil, nil, false
    )

    if #(coords - serverPointCoords) < 1.3 then
        if not showingHelp then
            showingHelp = true
            exports.origen_notify:DrawText('E', 'Unirse al Tenis')
        end
        local joinTenisKey = IsControlJustPressed(0, Config.Control.JOIN_TENIS.key)
        local isModifier = IsControlPressed(0, Config.Control.TUTORIAL_MODIFIER.key)

        if isModifier and joinTenisKey then
            DisplayTenisTutorial()
        elseif not isModifier and joinTenisKey then
            exports.origen_notify:HideText()
            showingHelp = false
            TriggerServerEvent('rcore_tennis:requestPosition', courtIdx, positionName)
            Wait(3000)
        end
        return true
    end
    return false
end

Citizen.CreateThread(function()
    local startKey = Config.Control.JOIN_TENIS
    local serveKey = Config.Control.SERVE
    local tutorial = Config.Control.TUTORIAL_MODIFIER

    while true do
        if not PlayerSettings then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)

            local nearCourt = false
            local atPoint = false

            for courtIdx, courtData in pairs(TennisCourts) do
                if #(coords - courtData.courtCenter) < 100.0 then
                    nearCourt = true
                    local aSideServePoint, bSideServePoint = ComputeSideServePoint(courtData)

                    if HandleStartPlayingPoint(ped, coords, courtIdx, CONST_SIDE_A, aSideServePoint) then atPoint = true end
                    if HandleStartPlayingPoint(ped, coords, courtIdx, CONST_SIDE_B, bSideServePoint) then atPoint = true end
                end
            end

            if not atPoint and showingHelp then
                exports.origen_notify:HideText()
                showingHelp = false
            end

            if nearCourt then
                Wait(0)
            else
                Wait(1000)
            end
        else
            if showingHelp then
                exports.origen_notify:HideText()
                showingHelp = false
            end
            Wait(1000)
        end
    end
end)

function ComputeSideServePoint(courtData)
    local courtCenter = courtData.courtCenter
    local courtHeading = courtData.courtHeading
    local serverPointLength = courtData.courtLength + 0.7
    local serverPointWide = courtData.courtWidth/3

    local aSideServePoint = vector3(
        courtCenter.x + math.cos(math.rad(courtHeading + 90.0)) * serverPointLength + math.cos(math.rad(courtHeading + 180.0)) * serverPointWide, 
        courtCenter.y + math.sin(math.rad(courtHeading + 90.0)) * serverPointLength + math.sin(math.rad(courtHeading + 180.0)) * serverPointWide,
        courtCenter.z - 0.1
    )
    
    local aSideOppositeServePoint = vector3(
        courtCenter.x + math.cos(math.rad(courtHeading + 90.0)) * serverPointLength + math.cos(math.rad(courtHeading + 0.0)) * serverPointWide, 
        courtCenter.y + math.sin(math.rad(courtHeading + 90.0)) * serverPointLength + math.sin(math.rad(courtHeading + 0.0)) * serverPointWide,
        courtCenter.z - 0.1
    )
    
    local bSideServePoint = vector3(
        courtCenter.x + math.cos(math.rad(courtHeading - 90.0)) * serverPointLength + math.cos(math.rad(courtHeading + 0.0)) * serverPointWide, 
        courtCenter.y + math.sin(math.rad(courtHeading - 90.0)) * serverPointLength + math.sin(math.rad(courtHeading + 0.0)) * serverPointWide,
        courtCenter.z - 0.1
    )
    
    local bSideOppositeServePoint = vector3(
        courtCenter.x + math.cos(math.rad(courtHeading - 90.0)) * serverPointLength + math.cos(math.rad(courtHeading + 180.0)) * serverPointWide, 
        courtCenter.y + math.sin(math.rad(courtHeading - 90.0)) * serverPointLength + math.sin(math.rad(courtHeading + 180.0)) * serverPointWide,
        courtCenter.z - 0.1
    )

    return aSideServePoint, bSideServePoint, aSideOppositeServePoint, bSideOppositeServePoint
end

RegisterNetEvent('rcore_tennis:setServeSide')
AddEventHandler('rcore_tennis:setServeSide', function(side)
    PlayerSettings.serveSide = side
end)

RegisterNetEvent('rcore_tennis:setServeAllowed')
AddEventHandler('rcore_tennis:setServeAllowed', function(state)
    PlayerSettings.canServe = state
end)

RegisterNetEvent('rcore_tennis:grantPosition')
AddEventHandler('rcore_tennis:grantPosition', function(courtName, positionName, serveSide)
    PlayerSettings = {}
    PlayerSettings.courtName = courtName
    PlayerSettings.side = positionName
    PlayerSettings.canServe = true
    PlayerSettings.isServing = false
    PlayerSettings.serveSide = serveSide

    Citizen.CreateThread(function()
        serveScaleform = setupServeScaleform("TENNIS")

        while PlayerSettings do
            Wait(0)
            
            if not IsHelpMessageBeingDisplayed() then
		        DrawScaleformMovieFullscreen(serveScaleform, 255, 255, 255, 255, 0)
            end
        end

        SetScaleformMovieAsNoLongerNeeded(serveScaleform)
        serveScaleform = nil
    end)

    StartTennisWorker(PlayerPedId(), TennisCourts[courtName], positionName)
end)

Headshots = {}
RegisterNetEvent('rcore_tennis:syncPlayers')
AddEventHandler('rcore_tennis:syncPlayers', function(courtName, playerData)
    if not TennisCourts[courtName].players then
        TennisCourts[courtName].players = {}
    end

    for positionName, serverId in pairs(playerData) do
        TennisCourts[courtName].players[positionName] = serverId
    end

    if PlayerSettings and PlayerSettings.courtName then
        if TennisCourts[PlayerSettings.courtName].players[CONST_SIDE_A] and TennisCourts[PlayerSettings.courtName].players[CONST_SIDE_B] then
        else
            HidePlayerCard()
        end
    end
end)

RegisterNetEvent('rcore_tennis:startCourt')
AddEventHandler('rcore_tennis:startCourt', function(syncData)
    ShowPlayerCard()
            
    local youServerId = GetPlayerServerId(PlayerId())
    local sideAServerId = TennisCourts[PlayerSettings.courtName].players[CONST_SIDE_A]
    local sideBServerId = TennisCourts[PlayerSettings.courtName].players[CONST_SIDE_B]

    -- headshots
    Headshots[sideAServerId] = GetServerIdHeadshot(sideAServerId)
    Headshots[sideBServerId] = GetServerIdHeadshot(sideBServerId)

    SetInitialPlayerCard(
        youServerId == sideAServerId and Config.Translation.YOU or Config.Translation.OPPONENT, 
        youServerId == sideBServerId and Config.Translation.YOU or Config.Translation.OPPONENT
    )
end)

function GetServerIdHeadshot(serverId)
    local player = GetPlayerFromServerId(serverId)
    local ped = GetPlayerPed(player)
    local mugshot = RegisterPedheadshot(ped)

    for i = 1, 30 do
        Wait(0)
        if IsPedheadshotReady(mugshot) then
            break
        end
    end

    if IsPedheadshotReady(mugshot) then
        return GetPedheadshotTxdString(mugshot)
    end

    RequestStreamedTextureDict('char_blank_entry')

    for i = 1, 30 do
        Wait(0)
        if HasStreamedTextureDictLoaded(textureDict) then
            break
        end
    end

    return 'char_blank_entry'
end