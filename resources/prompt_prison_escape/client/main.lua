local config = require 'config.config_c'
local ScrewGame = require 'client.minigame.screw_game'
local interaction = require 'client.editable.interaction'
local currentGame = nil

function startGame(entity)
    if currentGame then
        lib.print.warn('[Main] Game already in progress')
        return
    end

    lib.print.debug('[Main] Starting toilet escape interaction')

    local coords = GetEntityCoords(entity)
    local originalHeading = GetEntityHeading(entity)
    local netID = lib.callback.await('prompt_prison_escape:createToiletObject', 500, vec4(coords.x, coords.y, coords.z, originalHeading))
    if not netID then
        lib.print.error('[Main] Failed to create toilet object - server returned nil')
        return
    end

    lib.print.debug('[Main] Waiting for network entity:', netID)
    lib.waitFor(function()
        if NetworkDoesNetworkIdExist(netID) then
            return true
        end
    end)

    Wait(300)
    local entity = NetworkGetEntityFromNetworkId(netID)
    if not DoesEntityExist(entity) then
        lib.print.error('[Main] Entity does not exist after network sync')
        return
    end

    -- Apply correct rotation client-side as fallback (server rotation can be unreliable)
    SetEntityRotation(entity, 0.0, 0.0, originalHeading, 2, true)
    lib.print.debug('[Main] Applied heading:', originalHeading)

    lib.print.debug('[Main] Entity created successfully, starting game')
    currentGame = ScrewGame.new(entity)
    currentGame:start()
    currentGame = nil
    lib.print.debug('[Main] Game ended, cleaned up')
end

lib.zones.poly({
	name = "prison",
	points = {
		vec3(1770.0, 2531.0, 46.0),
		vec3(1795.0, 2487.0, 46.0),
		vec3(1747.0, 2440.0, 46.0),
		vec3(1662.0, 2430.0, 46.0),
		vec3(1589.0, 2458.0, 46.0),
		vec3(1539.0, 2522.0, 46.0),
		vec3(1538.0, 2595.0, 46.0),
		vec3(1770.0, 2573.0, 46.0),
	},
	thickness = 50.0,
    onEnter = function()
        lib.print.debug('[Main] Entered prison zone, enabling interaction')
        interaction.setup(startGame)
    end,
    onExit = function()
        lib.print.debug('[Main] Exited prison zone, disabling interaction')
        interaction.cleanup()
    end
})

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then
        if currentGame then
            lib.print.warn('[Main] Resource stopping with active game, cleaning up')
            currentGame:cleanup()
            currentGame = nil
        end
    end
end)