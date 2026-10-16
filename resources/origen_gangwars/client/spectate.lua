playersList = {}

Spectate =  {
    currentSpectate = nil,
}


local spectatorReturnCoords
local isSpectateEnabled = false
local isInTransitionState = false
local storedTargetPed
local storedTargetPlayerId
local storedTargetServerId

local nextKey
local prevKey
local stopKey

local function prepareSpectatorPed(enabled)
    FreezeEntityPosition(PlayerPed, enabled)
    SetEntityVisible(PlayerPed, not enabled, 0)

    if enabled then
        TaskLeaveAnyVehicle(PlayerPed, 0, 16)
    end
end

DoScreenFadeIn(100)

-- Returns sorted table keys and the 1-based position of currentSpectate in that list
local function getSpectatePosition()
    local keys = {}
    for k in pairs(playersList) do
        table.insert(keys, k)
    end
    table.sort(keys)

    local currentPos = 0
    for i, k in ipairs(keys) do
        if k == Spectate.currentSpectate then
            currentPos = i
            break
        end
    end

    return keys, currentPos, #keys
end

-- Builds and sends the spectator controls NUI message
local function sendSpectatorNui(playerData)
    local _, currentPos, total = getSpectatePosition()
    Nui.ControlsNotify({
        title = playerData and playerData.name or '',
        currentIndex = currentPos,
        totalPlayers = total,
        keys = {
            { key = 'left',   text = 'Anterior' },
            { key = 'right',  text = 'Siguiente' },
            { key = 'delete', text = 'Salir' },
        }
    })
end


local function stopSpectating()
    if not Spectate.currentSpectate then return debugger('Spectate: No current spectate found') end
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(5) end
    Spectate.currentSpectate = nil

    Nui.ControlsNotify()
    isSpectateEnabled = false
    isInTransitionState = true
    NetworkSetInSpectatorMode(false, nil)
    SetMinimapInSpectatorMode(false, nil)
    prepareSpectatorPed(false)
    storedTargetPed = nil
    storedTargetPlayerId = nil
    storedTargetServerId = nil
    spectatorReturnCoords = nil
    isInTransitionState = false

    local oldCoords = Storms.coords
    SetEntityCoords(PlayerPed, oldCoords.x, oldCoords.y, oldCoords.z)

    if not Storms.id then return debugger('leaveStorm: Storm not found') end
    local response = lib.callback.await('origen_gangwars:server:leaveStorm', false, Storms.id)

    ToggleKeyBinds(false)
    Wait(1000)
    DoScreenFadeIn(500)
    while not IsScreenFadedIn() do Wait(5) end
end

NetworkSetInSpectatorMode(false, nil)
SetMinimapInSpectatorMode(false, nil)
prepareSpectatorPed(false)


local function fadeScreenIn()
    DoScreenFadeIn(500)
    while not IsScreenFadedIn() do Wait(5) end
end

local function spectatePlayer(targetServerId)
    targetServerId = tonumber(targetServerId)

    -- Evitar transiciones simultáneas
    if isInTransitionState then return debugger('Spectate: Ya en transición') end

    -- No espectarse a uno mismo: saltar al siguiente
    if targetServerId == GetPlayerServerId(PlayerId()) then
        local keys, currentIndex, total = getSpectatePosition()
        if total == 0 then return end
        local nextIndex = (currentIndex % total) + 1
        Spectate.currentSpectate = keys[nextIndex]
        local pd = playersList[Spectate.currentSpectate]
        if pd then spectatePlayer(pd.src) end
        return
    end

    isInTransitionState = true

    -- Guardar coords de retorno la primera vez
    if not spectatorReturnCoords then
        spectatorReturnCoords = GetEntityCoords(PlayerPed)
    end

    -- Preparar ped local (invisible y congelado)
    prepareSpectatorPed(true)

    -- Resolver PlayerId y Ped del objetivo
    local resolvedPlayerId, resolvedPed = -1, 0
    for attempt = 1, 100 do
        resolvedPlayerId = GetPlayerFromServerId(targetServerId)
        resolvedPed = GetPlayerPed(resolvedPlayerId)
        if resolvedPlayerId > 0 and resolvedPed > 0 then break end
        Wait(50)
    end

    if resolvedPlayerId <= 0 or resolvedPed <= 0 then
        -- No se encontró el objetivo; restaurar estado
        prepareSpectatorPed(false)
        isInTransitionState = false
        debugger('Spectate: No se encontró el ped del objetivo ' .. targetServerId)
        return
    end

    storedTargetPed      = resolvedPed
    storedTargetPlayerId = resolvedPlayerId
    storedTargetServerId = targetServerId

    -- NetworkSetInSpectatorMode controla la cámara directamente sobre el ped objetivo.
    -- SetFocusEntity garantiza que el mundo cargue alrededor del objetivo.
    -- NO se mueve el ped local para evitar que quede bajo el mapa.
    NetworkSetInSpectatorMode(true, resolvedPed)
    SetMinimapInSpectatorMode(true, resolvedPed)
    SetFocusEntity(resolvedPed)

    isSpectateEnabled   = true
    isInTransitionState = false

    fadeScreenIn()
end

local function UpdatePlayerList(newData)
    playersList = newData
end

local function getPLayerFromList(src)
    for tableIndex, playerData in pairs(playersList) do
        if playerData.src == src then
            return playerData, tableIndex
        end
    end
    return nil
end

local function start(src)
    if not Config.Debug and not LocalPlayer.state.orgInWar then return debugger('Spectate: You are not in storm') end
    if not playersList or not next(playersList) then return debugger('Spectate: No players found') end
    local playerData, tableIndex = getPLayerFromList(src)
    if not playerData then
        if not Storms.id then return debugger('leaveStorm: Storm not found') end
        local response = lib.callback.await('origen_gangwars:server:leaveStorm', false, Storms.id)
        return
    end
    Spectate.currentSpectate = tableIndex
    ToggleKeyBinds(true)
    sendSpectatorNui(playerData)
    spectatePlayer(playerData.src)
end

function ToggleKeyBinds(state)
    if nextKey then nextKey:disable(not state) end
    if prevKey then prevKey:disable(not state) end
    if stopKey then stopKey:disable(not state) end
end

local function registerKeyBinds()
    nextKey = lib.addKeybind({
        name = 'spectate_next',
        description = 'Guerra de bandas: espectar al siguiente',
        defaultKey = 'RIGHT',
        onPressed = function(self)
            if not Spectate.currentSpectate then
                return debugger('Spectate: No current spectate found')
            end

            local keys, currentIndex, total = getSpectatePosition()
            if not currentIndex or currentIndex == 0 then
                return debugger('Spectate: Current spectate not found in keys')
            end

            local nextIndex = currentIndex + 1
            if nextIndex > total then nextIndex = 1 end

            Spectate.currentSpectate = keys[nextIndex]
            local playerData = playersList[Spectate.currentSpectate]
            if not playerData then return end

            sendSpectatorNui(playerData)
            spectatePlayer(playerData.src)
        end
    })

    prevKey = lib.addKeybind({
        name = 'spectate_prev',
        description = 'Guerra de bandas: espectar al anterior',
        defaultKey = 'LEFT',
        onPressed = function(self)
            if not Spectate.currentSpectate then
                return debugger('Spectate: No current spectate found')
            end

            local keys, currentIndex, total = getSpectatePosition()
            if not currentIndex or currentIndex == 0 then
                return debugger('Spectate: Current spectate not found in keys')
            end

            local prevIndex = currentIndex - 1
            if prevIndex < 1 then prevIndex = total end

            Spectate.currentSpectate = keys[prevIndex]
            local playerData = playersList[Spectate.currentSpectate]
            if not playerData then return end

            sendSpectatorNui(playerData)
            spectatePlayer(playerData.src)
        end
    })

    stopKey = lib.addKeybind({
        name = 'spectate_stop',
        description = 'Guerra de bandas: dejar de espectar',
        defaultKey = 'BACK',
        onPressed = function(self)
            if not Spectate.currentSpectate then return debugger('Spectate: No current spectate found') end
            stopSpectating()
        end
    })

    nextKey:disable(true)
    prevKey:disable(true)
    stopKey:disable(true)
end

registerKeyBinds()

Spectate.UpdatePlayerList = UpdatePlayerList
Spectate.Start = start
Spectate.Stop = stopSpectating


RegisterCommand('ammo', function()
    local weapon = GetSelectedPedWeapon(cache.ped)

    SetPedAmmo(cache.ped, weapon, 1000)
end)
