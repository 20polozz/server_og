local Thread = CreateThread
local carryConfig = Config.Animations.Carry
local piggybackConfig = Config.Animations.Piggyback

eventPublisher = EventPublisher.new()

local function ensureAnimDict(animDict)
	if not HasAnimDictLoaded(animDict) then
		RequestAnimDict(animDict)
		while not HasAnimDictLoaded(animDict) do
			Wait(0)
		end
	end
end

local function getClosestPlayerId(radius)
	local player, _ = GetClosestPlayer(radius)
	if player and player ~= -1 then
		local serverId = GetPlayerServerId(player)
		if serverId and serverId ~= -1 and IsEntityVisible(GetPlayerPed(player)) then
			return serverId
		end
	end
	return nil
end

local function stopCarry()
	carryConfig.InProgress = false
	ClearPedSecondaryTask(PlayerPedId())
	DetachEntity(PlayerPedId(), true, false)
	TriggerServerEvent("origen_inventory:carry:stop", carryConfig.targetSrc)
	carryConfig.targetSrc = 0
end

local function startCarry(targetSrc)
	if piggybackConfig.InProgress then return end
	carryConfig.InProgress = true
	carryConfig.targetSrc = targetSrc
	TriggerServerEvent("origen_inventory:carry:sync", targetSrc)
	ensureAnimDict(carryConfig.anims.me.dict)
	carryConfig.type = "carrying"
end

eventPublisher:subscribe('origen_inventory:personal:carry', function()
	if not carryConfig.InProgress then
		local targetSrc = getClosestPlayerId(3)
		if targetSrc then
			startCarry(targetSrc)
		else
			Bridge.Notify(locale:t('notify.NoPlayerNear'), 'success')
		end
	else
		stopCarry()
	end
end)

exports('Carry', function()
	eventPublisher:publish('origen_inventory:personal:carry')
end)

local function stopPiggyback()
	piggybackConfig.InProgress = false
	DetachEntity(PlayerPedId(), true, false)
	TriggerServerEvent("Piggyback:stop", piggybackConfig.targetSrc)
	piggybackConfig.targetSrc = 0
end

local function startPiggyback(targetSrc)
	if carryConfig.InProgress then return end
	piggybackConfig.InProgress = true
	ProcessThread()
	piggybackConfig.targetSrc = targetSrc
	TriggerServerEvent("Piggyback:sync", targetSrc)
	ensureAnimDict(piggybackConfig.anims.me.dict)
	piggybackConfig.type = "piggybacking"
end

eventPublisher:subscribe('origen_inventory:personal:horse', function()
	if not piggybackConfig.InProgress then
		local targetSrc = getClosestPlayerId(3)
		if targetSrc then
			startPiggyback(targetSrc)
		else
			Bridge.Notify(locale:t('notify.NoPlayerNear'), 'error')
		end
	else
		stopPiggyback()
	end
end)

exports('Piggyback', function()
	eventPublisher:publish('origen_inventory:personal:horse')
end)

eventPublisher:subscribe('origen_inventory:personal:putInVehicle', function()
	TriggerEvent('origen_police:client:vehicleinof')
end)

RegisterNetEvent("origen_inventory:carry:syncTarget", function(targetSrc)
	local targetPed = GetPlayerPed(GetPlayerFromServerId(targetSrc))
	local attachConfig = carryConfig.anims.target.attach
	carryConfig.InProgress = true
	ensureAnimDict(carryConfig.anims.target.dict)
	-- Lo lee el bucle de muerto de origen_ambulancejob: mientras te llevan a
	-- hombros deja de reponer la animacion de tirado y no se pisan.
	LocalPlayer.state:set('cargadoPor', targetSrc, false)
	AttachEntityToEntity(PlayerPedId(), targetPed, 0, attachConfig.x, attachConfig.y, attachConfig.z, 0.5, 0.5, 180,
		false, false, false, false, 2, false)
	carryConfig.type = "beingcarried"
end)

RegisterNetEvent("Piggyback:syncTarget", function(targetSrc)
	local targetPed = GetPlayerPed(GetPlayerFromServerId(targetSrc))
	local attachConfig = piggybackConfig.anims.target.attach
	piggybackConfig.InProgress = true
	ProcessThread()
	ensureAnimDict(piggybackConfig.anims.target.dict)
	AttachEntityToEntity(PlayerPedId(), targetPed, 0, attachConfig.x, attachConfig.y, attachConfig.z, 0.5, 0.5, 180,
		false, false, false, false, 2, false)
	piggybackConfig.type = "beingPiggybacked"
end)

RegisterNetEvent("Piggyback:cl_stop", function()
	piggybackConfig.InProgress = false
	DetachEntity(PlayerPedId(), true, false)
end)

RegisterNetEvent("origen_inventory:carry:cl_stop", function()
	local ped = PlayerPedId()
	local target = carryConfig.anims.target
	carryConfig.InProgress = false
	ClearPedSecondaryTask(ped)
	-- La de ir a hombros no es secundaria: sin quitarla a mano te quedabas en
	-- esa postura al soltarte. Muerto, el bucle de la ambulancia vuelve a
	-- tumbarte en cuanto deja de sonar.
	if IsEntityPlayingAnim(ped, target.dict, target.clip, 3) then
		StopAnimTask(ped, target.dict, target.clip, 2.0)
	end
	DetachEntity(ped, true, false)
	LocalPlayer.state:set('cargadoPor', nil, false)
end)

AddEventHandler('onResourceStop', function(resource)
	if resource ~= GetCurrentResourceName() then return end
	if LocalPlayer.state.cargadoPor then
		LocalPlayer.state:set('cargadoPor', nil, false)
	end
end)

function ProcessThread()
	local targetAnims = piggybackConfig.anims.target
	local meAnims = piggybackConfig.anims.me

	if carryConfig.InProgress then return end

	Thread(function()
		while piggybackConfig.InProgress do
			Wait(50)
			if piggybackConfig.type == "beingPiggybacked" then
				if not IsEntityPlayingAnim(PlayerPedId(), targetAnims.dict, targetAnims.clip, 3) then
					TaskPlayAnim(PlayerPedId(), targetAnims.dict, targetAnims.clip, 8.0, -8.0, 100000, targetAnims.flag,
						0, false, false, false)
				end
			elseif piggybackConfig.type == "piggybacking" then
				if not IsEntityPlayingAnim(PlayerPedId(), meAnims.dict, meAnims.clip, 3) then
					TaskPlayAnim(PlayerPedId(), meAnims.dict, meAnims.clip, 8.0, -8.0, 100000, meAnims.flag, 0, false,
						false, false)
				end
			end
		end
		ClearPedTasks(PlayerPedId())
	end)
end

Thread(function()
	local targetAnims = carryConfig.anims.target
	local meAnims = carryConfig.anims.me

	while true do
		if piggybackConfig.InProgress then
			goto continue
		end

		if not carryConfig.InProgress then
			goto continue
		end

		if carryConfig.type == "beingcarried" then
			if not IsEntityPlayingAnim(PlayerPedId(), targetAnims.dict, targetAnims.clip, 3) then
				TaskPlayAnim(PlayerPedId(), targetAnims.dict, targetAnims.clip, 8.0, -8.0, 100000, targetAnims.flag, 0,
					false, false, false)
			end
		elseif carryConfig.type == "carrying" then
			if not IsEntityPlayingAnim(PlayerPedId(), meAnims.dict, meAnims.clip, 3) then
				TaskPlayAnim(PlayerPedId(), meAnims.dict, meAnims.clip, 8.0, -8.0, 100000, meAnims.flag, 0, false, false,
					false)
			end
		end

		::continue::

		Wait(500)
	end
end)

exports('isCarryInProgress', function()
	return carryConfig.InProgress or piggybackConfig.InProgress or false
end)
