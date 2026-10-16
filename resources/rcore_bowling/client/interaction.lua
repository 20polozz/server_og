local showingHelpText = false

-- Elimina códigos de formato nativos de GTA (~INPUT_X~, ~y~, ~n~, etc.)
local function StripGTACodes(text)
    return (text:gsub('~[^~]+~', '')):match('^%s*(.-)%s*$')
end

local function ShowHelpText(controls)
    if not showingHelpText then
        showingHelpText = true
        exports['origen_hud']:setupControls(controls)
    end
end

local function HideHelpText()
    if showingHelpText then
        showingHelpText = false
        exports['origen_hud']:hideControls()
    end
end

Citizen.CreateThread(function()
    while true do
        Wait(0)

        local ped = PlayerPedId()
        local pedCoords = GetEntityCoords(ped)

        local currentLane = GetLanePlayerIsIn()
        local playerId = PlayerId()
        local serverId = GetPlayerServerId(playerId)
        local isCloseToLane = false
        local showingThisFrame = false

        if currentLane then
            isCloseToLane = true
            local lane = Lanes[currentLane]

            if Lanes[currentLane].gameState == 'registration' then
                RenderInteractionMarker(lane.InteractionPos, 2.0)

                if #(pedCoords - lane.InteractionPos) < 1.4 then
                    showingThisFrame = true
                    ShowHelpText({{
                        key  = 'E',
                        text = StripGTACodes(Config.Text.OPEN),
                    }})

                    local isShift = IsControlPressed(0, 21) or IsDisabledControlPressed(0, 21)
                    local isE = IsControlJustPressed(0, 38) or IsDisabledControlJustPressed(0, 38)

                    if isE then
                        HideHelpText()
                        if lane.ownerServerId == serverId then
                            NuiOpenSetupPlayers(currentLane, lane.type == 'teams')
                        else
                            NuiOpenJoin(currentLane, lane.type == 'teams')
                        end
                    end
                end
            elseif Lanes[currentLane].gameState == 'playing' then
                local showing = HandleGameInteraction(pedCoords, serverId, currentLane)
                if showing then showingThisFrame = true end
            end
        else
            for laneName, lane in pairs(Lanes) do
                if lane.IsNear then
                    isCloseToLane = true
                    if not lane.gameState or lane.gameState == 'registration' then
                        RenderInteractionMarker(lane.InteractionPos, 2.0)

                        if #(pedCoords - lane.InteractionPos) < 1.4 then
                            showingThisFrame = true

                            if Lanes[laneName].state then
                                -- Hay partida en curso: unirse
                                if LaneJob and LaneJob[Lanes[laneName].Place] then
                                    ShowHelpText({{
                                        key  = 'E',
                                        text = StripGTACodes(string.format(Config.Text.JOIN_LANE, '$' .. LaneJob[Lanes[laneName].Place].price .. ' ')),
                                    }})
                                else
                                    ShowHelpText({{
                                        key  = 'E',
                                        text = StripGTACodes(string.format(Config.Text.JOIN_LANE, '')),
                                    }})
                                end
                            else
                                -- No hay partida: crear
                                if LaneJob and LaneJob[Lanes[laneName].Place] then
                                    ShowHelpText({
                                        {
                                            key  = 'E',
                                            text = StripGTACodes(string.format(Config.Text.REGISTER_LANE, '$' .. LaneJob[Lanes[laneName].Place].price .. ' ', '$' .. LaneJob[Lanes[laneName].Place].price .. ' ')),
                                        },
                                    })
                                else
                                    ShowHelpText({
                                        {
                                            key  = 'E',
                                            text = 'Crear nueva partida',
                                        },
                                        {
                                            key  = 'SHIFT',
                                            text = '+',
                                        },
                                        {
                                            key  = 'E',
                                            text = 'Crear partida por equipos',
                                        },
                                    })
                                end
                            end

                            local isShift = IsControlPressed(0, 21) or IsDisabledControlPressed(0, 21)
                            local isE = IsControlJustPressed(0, 38) or IsDisabledControlJustPressed(0, 38)

                            if isE then
                                HideHelpText()
                                if Lanes[laneName].state then
                                    NuiOpenJoin(laneName, lane.type == 'teams')
                                else
                                    TriggerServerEvent('rcore_bowling:requestCreateGame', laneName, isShift)
                                end
                            end
                        end
                    end
                end
            end
        end

        if not showingThisFrame then
            HideHelpText()
        end

        if not isCloseToLane then
            Wait(1000)
        end
    end
end)

function HandleGameInteraction(pedCoords, serverId, currentLane)
    local lane = Lanes[currentLane]
    local showing = false

    if lane.ballState == 'racked' and IsPlayersTurn(currentLane, serverId) then
        local rackBallPointsData = lane.SourcePoints[lane.SourceSide]
        local rackLastPos = rackBallPointsData[#rackBallPointsData][1]

        local offsetVector = lane.StartRightPoint - lane.StartLeftPoint

        if lane.SourceSide == 'LEFT' then
            offsetVector = lane.StartLeftPoint - lane.StartRightPoint
        end

        offsetVector = offsetVector / #offsetVector

        local finalPos = lane.SourceRoot + vector3(rackLastPos.x, rackLastPos.y, 0.0) + offsetVector * lane.BallPickupOffsetMultiplier + vector3(0.0, 0.0, lane.BallPickupZOffset)

        RenderInteractionMarker(finalPos)

        if #(pedCoords - finalPos) < 1.3 then
            showing = true
            ShowHelpText({
                {
                    key  = 'E',
                    text = StripGTACodes(Config.Text.TAKE_BALL),
                },
                {
                    key  = 'G',
                    text = 'Abandonar la partida',
                }
            })

            if IsControlJustPressed(0, 38) then
                HideHelpText()
                TriggerServerEvent('rcore_bowling:takeBall', currentLane, GetTargetPlayers())
            elseif IsControlJustPressed(0, 47) then
                HideHelpText()
                TriggerServerEvent('rcore_bowling:leaveLane')
            end
        end
    elseif lane.ballState == 'in-hand' and lane.ballServerId == serverId then
        RenderInteractionMarker(lane.InteractionPos)

        if #(pedCoords - lane.InteractionPos) < 1.3 then
            showing = true
            ShowHelpText({
                {
                    key  = 'E',
                    text = StripGTACodes(Config.Text.PLAY),
                },
                {
                    key  = 'G',
                    text = 'Abandonar la partida',
                }
            })

            if IsControlJustPressed(0, 38) then
                HideHelpText()
                local startPos, angle, rotation, power = HandleBowlingInput(currentLane)
                ThrowBowlingBall(lane, startPos, angle, power, rotation * 2, Lanes[currentLane].pinStatus)
            elseif IsControlJustPressed(0, 47) then
                HideHelpText()
                TriggerServerEvent('rcore_bowling:leaveLane')
            end
        end
    end

    return showing
end

function RenderInteractionMarker(pos, size)
    if not size then
        size = 1.0
    end

    DrawMarker(
        22, 
        pos.x, pos.y, pos.z + 1.0,
        0.0, 0.0, 0.0, 
        0.0, 0.0, 0.0, 
        0.2, 0.2, 0.2, 
        0, 0, 0, 125, 
        false, true, false, false, nil, nil, false
    )
end