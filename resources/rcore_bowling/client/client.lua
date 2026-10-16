function GetTargetPlayers()
	local serverIds = {}
	local ped = PlayerPedId()
	local coords = GetEntityCoords(ped)
	
	for _, playerId in pairs(GetActivePlayers()) do
		local targetPed = GetPlayerPed(playerId)
		local targetCoords = GetEntityCoords(targetPed)

		if #(targetCoords - coords) < 120.0 then
			table.insert(serverIds, GetPlayerServerId(playerId))
		end
	end

	return serverIds
end

local _lastSubtitleText = nil

function SubtitleText(text)
	-- Elimina códigos nativos de GTA (~y~, ~s~, ~INPUT_X~, etc.)
	local clean = (text:gsub('~[^~]+~', '')):match('^%s*(.-)%s*$')

	if clean ~= _lastSubtitleText then
		_lastSubtitleText = clean
		exports['origen_hud']:setupControls({
			{ key = 'LCLICK', text = clean },
		})
	end
end