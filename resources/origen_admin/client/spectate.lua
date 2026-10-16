local spectatorReturnCoords
local isSpectateEnabled = false
local isInTransitionState = false
local storedTargetPed
local storedTargetPlayerId
local storedTargetServerId

local function calculateSpectatorCoords(coords)
    return vec3(coords.x, coords.y, coords.z - 15.0)
end

local function prepareSpectatorPed(enabled)
    local playerPed = PlayerPedId()
    FreezeEntityPosition(playerPed, enabled)
    SetEntityVisible(playerPed, not enabled, 0)

    if enabled then
        TaskLeaveAnyVehicle(playerPed, 0, 16)
    end
end

local function collisionTpCoordTransition(coords)
    if not IsScreenFadedOut() then DoScreenFadeOut(500) end
    while not IsScreenFadedOut() do Wait(5) end

    local playerPed = PlayerPedId()
    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    SetEntityCoords(playerPed, coords.x, coords.y, coords.z)
    local attempts = 0
    while not HasCollisionLoadedAroundEntity(playerPed) do
        Wait(5)
        attempts = attempts + 1
        if attempts > 1000 then
            error()
        end
    end
end

local function stopSpectating()
    isSpectateEnabled = false
    isInTransitionState = true

    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(5) end

    NetworkSetInSpectatorMode(false, nil)
    SetMinimapInSpectatorMode(false, nil)
    if spectatorReturnCoords then
        if not pcall(collisionTpCoordTransition, spectatorReturnCoords) then

        end
    end
    prepareSpectatorPed(false)
    storedTargetPed = nil
    storedTargetPlayerId = nil
    storedTargetServerId = nil
    spectatorReturnCoords = nil
    DoScreenFadeIn(500)
    while IsScreenFadingIn() do Wait(5) end
    isInTransitionState = false
    TriggerServerEvent('origen_admin:server:EndSpectate')
    ToggleControls(false)
end

local function createSpectatorTeleportThread()
    CreateThread(function()
        local initialTargetServerid = storedTargetServerId
        while isSpectateEnabled and storedTargetServerId == initialTargetServerid do
            if not DoesEntityExist(storedTargetPed) then
                local newPed = GetPlayerPed(storedTargetPlayerId)
                if newPed > 0 then
                    storedTargetPed = newPed
                else
                    stopSpectating()
                    break
                end
            end
            local newSpectateCoords = calculateSpectatorCoords(GetEntityCoords(storedTargetPed))
            SetEntityCoords(PlayerPedId(), newSpectateCoords.x, newSpectateCoords.y, newSpectateCoords.z, 0, 0, 0, false)

            Wait(500)
        end
    end)
end

function openInventory()
    local id = storedTargetServerId
    if not id then return end
    TriggerServerEvent("inventory:server:OpenInventory", "otherplayer", tonumber(id))
end

function ToggleControls(show)
    CreateThread(function()
        while isSpectateEnabled do
            if IsControlJustPressed(0, 194) then
                stopSpectating()
            end
            if IsControlJustPressed(0, 104) then
                openInventory()
            end
            Wait(5)
        end
    end)
end

RegisterNetEvent('origen_admin:client:StartSpectate', function(targetServerId, targetCoords)
    if isInTransitionState then
        stopSpectating()
        error('Spectate request received while in transition state')
    end

    if targetServerId == GetPlayerServerId(PlayerId()) then
        return ShowNotification('No puedes espectearte a ti mismo')
    end

    isInTransitionState = true

    storedTargetPed = nil
    storedTargetPlayerId = nil
    storedTargetServerId = nil

    if spectatorReturnCoords == nil then
        local spectatorPed = PlayerPedId()
        spectatorReturnCoords = GetEntityCoords(spectatorPed)
    end
    prepareSpectatorPed(true)

    local coordsUnderTarget = calculateSpectatorCoords(targetCoords)
    if not pcall(collisionTpCoordTransition, coordsUnderTarget) then
        stopSpectating()
        return
    end

    local targetResolveAttempts = 0
    local resolvedPlayerId = -1
    local resolvedPed = 0
    while (resolvedPlayerId <= 0 or resolvedPed <= 0) and targetResolveAttempts < 300 do
        targetResolveAttempts = targetResolveAttempts + 1
        resolvedPlayerId = GetPlayerFromServerId(targetServerId)
        resolvedPed = GetPlayerPed(resolvedPlayerId)
        Wait(50)
    end

    if (resolvedPlayerId <= 0 or resolvedPed <= 0) then
        prepareSpectatorPed(false)
        DoScreenFadeIn(500)
        while IsScreenFadedOut() do Wait(5) end
        isInTransitionState = false
        spectatorReturnCoords = nil
        return
    end
    storedTargetPed = resolvedPed
    storedTargetPlayerId = resolvedPlayerId
    storedTargetServerId = targetServerId

    NetworkSetInSpectatorMode(true, resolvedPed)
    SetMinimapInSpectatorMode(true, resolvedPed)
    isSpectateEnabled = true
    isInTransitionState = false
    createSpectatorTeleportThread()
    ToggleControls(true)

    DoScreenFadeIn(500)
    while IsScreenFadedOut() do Wait(5) end
end) 

exports('isSpectateEnabled', isSpectateEnabled)