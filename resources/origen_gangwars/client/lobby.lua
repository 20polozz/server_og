Lobby = {}

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
    local coords = Config.LobbyCoords
    local radius = Config.LobbySize
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

DoScreenFadeIn(1000)

Lobby.Start = function()
    DoScreenFadeOut(1000)
    while not IsScreenFadedOut() do Wait(0) end
    local spawnPoint = getSafeSpawnPoint()
    SetEntityCoords(PlayerPed, spawnPoint.x, spawnPoint.y, spawnPoint.z)
    SetEntityInvincible(PlayerPed, true)
    Wait(1500)
    DoScreenFadeIn(3000)

    if not Storms or not Storms.id then
        debugger("Error: Storms.id is not set.")
        return
    end

    Nui.ToggleHud(true)
    Nui.UpdateHud('stage', nil)

    local lobbyTime = GlobalState['orgStorms_' .. Storms.id .. '_lobbyTime']
    if not lobbyTime then
        debugger("Error: GlobalState 'orgStorms_" .. Storms.id .. "_lobbyTime' is not set.")
        return
    end

    while lobbyTime > 0 do
        Nui.UpdateHud('countdown', lobbyTime)
        if not Storms.id then return end
        lobbyTime = GlobalState['orgStorms_' .. Storms.id .. '_lobbyTime']
        Wait(1000)
    end

    Nui.ToggleHud(false)
    Nui.UpdateHud('countdown', nil)

    SetEntityInvincible(PlayerPed, false)
end