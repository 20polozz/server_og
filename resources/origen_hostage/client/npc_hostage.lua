local noty = false

Framework = nil
RobedEntities = {}
AggressiveEntities = {}
FleeingEntities = {}

CreateThread(function()
	if Cfg.Framework == 'qbcore' then
		Framework = exports['qb-core']:GetCoreObject()
	elseif Cfg.Framework == 'qbox' then
		Framework = exports.qbx_core
	elseif Cfg.Framework == 'esx' then
		Framework = exports['es_extended']:getSharedObject()
	elseif Cfg.Framework == 'custom' then
		Framework = GetCoreObject()
	end
end)

local targetCoords = nil
local targetPed = nil
CreateThread(function()
	while true do
		local w = 1000
		local ped = PlayerPedId()
		if IsPedArmed(ped, 7) and (IsPedInMeleeCombat(ped) or IsPlayerFreeAiming(PlayerId()) or GetPedConfigFlag(ped, 78)) then
			local founded, pedTarget = GetEntityPlayerIsFreeAimingAt(PlayerId())
			targetCoords = GetEntityCoords(pedTarget)
			targetPed = pedTarget
			if not founded then
				founded, pedTarget = GetPlayerTargetEntity(PlayerId())
			end
			if founded and IsEntityAPed(pedTarget) and GetPedType(pedTarget) ~= 28 and not IsPedAPlayer(pedTarget) and not IsEntityPositionFrozen(pedTarget) and not GetPedConfigFlag(pedTarget, 79) and #(GetEntityCoords(ped) - GetEntityCoords(pedTarget)) < 5 and GetEntityHealth(pedTarget) > 0 and not IsPedInAnyVehicle(pedTarget, false) and not IsPedBlacklisted(pedTarget) then
				w = 5
				if IsControlJustPressed(0, Cfg.KillKey) then
					DoSurrender(pedTarget)
				else
					if not noty then
						exports['origen_notify']:DrawText('E', Cfg.Translations['someter'])
						noty = true
					end
				end
			elseif noty then
				noty = false
				targetCoords = nil
				exports['origen_notify']:HideText()
			end
		elseif noty then
			noty = false
			targetCoords = nil
			exports['origen_notify']:HideText()
		end

		Wait(w)
	end
end)

local surrendered = {}

Citizen.CreateThread(function()
	while true do
		for entity, _ in pairs(RobedEntities) do 
			if not DoesEntityExist(entity) then
				RobedEntities[entity] = nil
			end
		end
		for entity, _ in pairs(AggressiveEntities) do 
			if not DoesEntityExist(entity) then
				AggressiveEntities[entity] = nil
			elseif GetEntityHealth(entity) <= 0 then
				AggressiveEntities[entity] = nil
			else
				local playerPed = PlayerPedId()
				if not IsPedInCombat(entity, playerPed) and GetEntityHealth(entity) > 0 then
					SetPedFleeAttributes(entity, 0, false)
					SetPedCombatAttributes(entity, 46, true)
					SetPedCombatAttributes(entity, 5, true)
					TaskCombatPed(entity, playerPed, 0, 16)
				end
			end
		end
		for entity, fleeTime in pairs(FleeingEntities) do 
			if not DoesEntityExist(entity) then
				FleeingEntities[entity] = nil
			elseif GetEntityHealth(entity) <= 0 then
				FleeingEntities[entity] = nil
			elseif GetGameTimer() - fleeTime > Cfg.FleeingCooldown then
				FleeingEntities[entity] = nil
			end
		end
		for entity, _ in pairs(surrendered) do 
			if not DoesEntityExist(entity) then
				surrendered[entity] = nil
			elseif #(GetEntityCoords(entity) - GetEntityCoords(PlayerPedId())) > Cfg.DistanceToEscape then
				surrendered[entity] = nil
				ClearPedTasks(entity)
				TaskReactAndFleePed(entity, PlayerPedId())
			end
		end
		Wait(2000)
	end
end)

RegisterNetEvent("npc_hostage:openMenuFunction", function(data)
	local action = data.action
	local entity = data.entity
	if action == 'release' then
		surrendered[entity] = nil
		if IsEntityPlayingAnim(entity, "random@arrests@busted", "idle_a", 3) then
			TaskPlayAnim(entity, "random@arrests@busted", "exit", 8.0, 1.0, -1, 2, 0, 0, 0, 0)
			Wait(3000)
			TaskPlayAnim(entity, "random@arrests", "kneeling_arrest_get_up", 8.0, 1.0, -1, 128, 0, 0, 0, 0)
			Wait(2000)
		end
		ClearPedTasks(entity)
		TaskReactAndFleePed(entity, PlayerPedId())
	elseif action == 'follow' then
		surrendered[entity] = "follow"
		TaskFollowToOffsetOfEntity(entity, PlayerPedId(), 0.5, -1.0, 0.0, 5.0, -1, 1.0, true)
		CreateThread(function()
			while surrendered[entity] == "follow" do
				Wait(1000)
				if IsPedInAnyVehicle(PlayerPedId()) and not IsPedInAnyVehicle(entity) then
					local veh = GetVehiclePedIsIn(PlayerPedId(), false)
	
					for i = 0, GetVehicleMaxNumberOfPassengers(veh) - 1 do
						if IsVehicleSeatFree(veh, i) then
							TaskEnterVehicle(entity, veh, 10000, i, 2.0, 1, 0)
							break
						end
					end
				elseif not IsPedInAnyVehicle(PlayerPedId()) and IsPedInAnyVehicle(entity) then
					TaskLeaveVehicle(entity, GetVehiclePedIsIn(entity, false), 0)
					TaskFollowToOffsetOfEntity(entity, PlayerPedId(), 0.5, -1.0, 0.0, 5.0, -1, 1.0, true)
				end
			end
		end)
	elseif action == 'kneel' then
		surrendered[entity] = "kneel"
		TaskPlayAnim(entity, "random@arrests", "idle_2_hands_up", 8.0, 1.0, -1, 2, 0, 0, 0, 0)
		Wait(4000)
		TaskPlayAnim(entity, "random@arrests", "kneeling_arrest_idle", 8.0, 1.0, -1, 2, 0, 0, 0, 0)
		Wait(500)
		TaskPlayAnim(entity, "random@arrests@busted", "enter", 8.0, 1.0, -1, 2, 0, 0, 0, 0)
		Wait(1000)
		TaskPlayAnim(entity, "random@arrests@busted", "idle_a", 8.0, 1.0, -1, 9, 0, 0, 0, 0)		
	elseif action == 'threaten' then
		if surrendered[entity] == "th" then
			return
		end
	
		surrendered[entity] = "th"
		RequestAnimDict("anim@gangops@hostage@")
		while not HasAnimDictLoaded("anim@gangops@hostage@") do
			Wait(0)
		end
		TaskPlayAnim(PlayerPedId(), "anim@gangops@hostage@", "perp_idle", 8.0, 1.0, -1, 49, 0, 0, 0, 0)
		TaskPlayAnim(entity, "anim@gangops@hostage@", "victim_idle", 8.0, 1.0, -1, 2, 0, 0, 0, 0)
		AttachEntityToEntity(entity, PlayerPedId(), 0, -0.24, 0.11, 0.0, 0.5, 0.5, 0.0	, false, false, false, false, 2, false)
	
		CreateThread(function()
			while surrendered[entity] == "th" do
				Wait(0)
				if IsControlJustPressed(0, Cfg.KillKey) then
					KillEntity(entity)
				end
				if IsControlJustPressed(0, Cfg.KneelKey) then
					KneelEntity(entity)
				end
			end
		end)
	elseif action == 'rob' then 
		RobEntity(entity)
	end
end)

function KillEntity(entity)
	local ped = PlayerPedId()
	ClearPedTasks(ped)
	DetachEntity(entity, true, false)
	SetEntityHealth(entity, 0)
	surrendered[entity] = nil
end

exports('KillEntity', KillEntity)

function KneelEntity(entity)
	local ped = PlayerPedId()
	ClearPedTasks(ped)
	DetachEntity(entity, true, false)
	ClearPedTasks(entity)
	surrendered[entity] = "kneel"
	TaskPlayAnim(entity, "random@arrests", "idle_2_hands_up", 8.0, 1.0, -1, 2, 0, 0, 0, 0)
	Wait(4000)
	TaskPlayAnim(entity, "random@arrests", "kneeling_arrest_idle", 8.0, 1.0, -1, 2, 0, 0, 0, 0)
	Wait(500)
	TaskPlayAnim(entity, "random@arrests@busted", "enter", 8.0, 1.0, -1, 2, 0, 0, 0, 0)
	Wait(1000)
	TaskPlayAnim(entity, "random@arrests@busted", "idle_a", 8.0, 1.0, -1, 9, 0, 0, 0, 0)	
end

exports('KneelEntity', KneelEntity)

function MakeNPCAggressive(entity, weaponHash)
	if not DoesEntityExist(entity) or not IsEntityAPed(entity) or IsPedAPlayer(entity) then
		return false
	end

	-- Evitar hacer agresivo un ped en blacklist (animales, etc.)
	if IsPedBlacklisted and IsPedBlacklisted(entity) then
		return false
	end
	
	AggressiveEntities[entity] = true

	ClearPedTasks(entity)
	SetPedCanRagdoll(entity, false)
	SetBlockingOfNonTemporaryEvents(entity, true)
	SetPedFleeAttributes(entity, 0, false)
	SetPedCombatAttributes(entity, 46, true)
	SetPedCombatAttributes(entity, 5, true)
	SetPedCombatAttributes(entity, 0, true)
	SetPedCombatAttributes(entity, 1, true)
	SetPedCombatAttributes(entity, 2, true)
	SetPedCombatMovement(entity, 2)
	SetPedCombatRange(entity, 2)
	SetPedSeeingRange(entity, 100.0)
	SetPedHearingRange(entity, 100.0)
	SetPedAlertness(entity, 3)

	if weaponHash then
		GiveWeaponToPed(entity, weaponHash, 250, false, true)
		SetCurrentPedWeapon(entity, weaponHash, true)
	else
		local weapon = GetRandomAggressiveWeapon()
		GiveWeaponToPed(entity, GetHashKey(weapon), 250, false, true)
		SetCurrentPedWeapon(entity, GetHashKey(weapon), true)
	end
	
	SetPedCurrentWeaponVisible(entity, true, true, true, true)

	TaskCombatPed(entity, PlayerPedId(), 0, 16)
	SetPedRelationshipGroupHash(entity, GetHashKey("HATES_PLAYER"))
	
	return true
end

exports('MakeNPCAggressive', MakeNPCAggressive)

function GetTableLength(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end

function IsPedBlacklisted(entity)
	if not DoesEntityExist(entity) or not IsEntityAPed(entity) then
		return true
	end
	
	local pedModel = GetEntityModel(entity)
	return Cfg.PedBlacklistSet and Cfg.PedBlacklistSet[pedModel] or false
end

function getRandomItem()
	local items = {}
	math.randomseed(GetGameTimer())
    for i, robItem in ipairs(Cfg.RobItems) do
        local chanceRoll = math.random(100)
        if chanceRoll <= robItem.chance then
            items[#items + 1] = {name = robItem.item, amount = math.random(robItem.min, robItem.max)}
        end
    end
    return items
end

function RobEntity(entity)
	local ped = PlayerPedId()

	if IsPedBlacklisted and IsPedBlacklisted(entity) then
		return
	end
	local dict = "anim@gangops@facility@servers@bodysearch@"
	local anim = "player_search"
	RequestAnimDict(dict)
	while not HasAnimDictLoaded(dict) do
		Wait(0)
	end
	TaskPlayAnim(ped, dict, anim, 8.0, 1.0, -1, 49, 0, 0, 0, 0)
	Wait(4000)
	ClearPedTasks(ped)
	if RobedEntities[entity] then
		return ShowNotification(Cfg.Translations['no_items'])
	end
	local items = getRandomItem()
	RobedEntities[entity] = true
	if #items == 0 then 
		return ShowNotification(Cfg.Translations['no_items'])
	end
	ShowNotification(Cfg.Translations['robbed_notify'])
	TriggerServerEvent("origen_hostage:server:robItems", items, GetEntityModel(entity))
end

function DoSurrender(entity)
	if AggressiveEntities[entity] then
		return
	end
	
	if FleeingEntities[entity] then
		return
	end
	
	if IsPedBlacklisted(entity) then
		return
	end
	
	if not surrendered[entity] and GetTableLength(surrendered) > Cfg.MaxHostages then
		ShowNotification(Cfg.Translations['max_hostages'])
		return
	end
	
	if not CanTakeHostage() then
		ShowNotification(string.format(Cfg.Translations['not_enough_police'], Cfg.MinimumPolice))
		return
	end
	
	if not IsEntityPlayingAnim(entity, "random@arrests@busted", "idle_a", 3) and not surrendered[entity] then
		math.randomseed(GetGameTimer())

		if math.random(0, 100) < Cfg.Percentage then
			sendPoliceAlert(GetEntityCoords(PlayerPedId()))
			
			FleeingEntities[entity] = GetGameTimer()
			TaskReactAndFleePed(entity, PlayerPedId())

			ShowNotification(Cfg.Translations['ignored'])
			return
		end

		if IsNPCAggressive() then
			local weapon = GetRandomAggressiveWeapon()
			ShowNotification(Cfg.Translations['npc_aggressive'])

			AggressiveEntities[entity] = true

			ClearPedTasks(entity)
			SetPedCanRagdoll(entity, false)
			SetBlockingOfNonTemporaryEvents(entity, true)
			SetPedFleeAttributes(entity, 0, false)
			SetPedCombatAttributes(entity, 46, true)
			SetPedCombatAttributes(entity, 5, true)
			SetPedCombatAttributes(entity, 0, true)
			SetPedCombatAttributes(entity, 1, true)
			SetPedCombatAttributes(entity, 2, true)
			SetPedCombatMovement(entity, 2)
			SetPedCombatRange(entity, 2)
			SetPedSeeingRange(entity, 100.0)
			SetPedHearingRange(entity, 100.0)
			SetPedAlertness(entity, 3)

			GiveWeaponToPed(entity, GetHashKey(weapon), 250, false, true)
			SetPedCurrentWeaponVisible(entity, true, true, true, true)
			SetCurrentPedWeapon(entity, GetHashKey(weapon), true)

			TaskCombatPed(entity, PlayerPedId(), 0, 16)
			SetPedRelationshipGroupHash(entity, GetHashKey("HATES_PLAYER"))

			sendPoliceAlert(GetEntityCoords(PlayerPedId()))
			return
		end
		
		FreezeEntityPosition(entity, true)

		SetBlockingOfNonTemporaryEvents(entity, true)
		
		RequestAnimDict("random@arrests")
		RequestAnimDict("random@arrests@busted")

		while not HasAnimDictLoaded("random@arrests@busted") or not HasAnimDictLoaded("random@arrests") do
			Wait(0)
		end
		
		TaskPlayAnim(entity, "random@arrests", "idle_2_hands_up", 8.0, 1.0, -1, 2, 0, 0, 0, 0)
		Wait(4000)
		TaskPlayAnim(entity, "random@arrests", "kneeling_arrest_idle", 8.0, 1.0, -1, 2, 0, 0, 0, 0)
		Wait(500)
		TaskPlayAnim(entity, "random@arrests@busted", "enter", 8.0, 1.0, -1, 2, 0, 0, 0, 0)
		Wait(1000)
		TaskPlayAnim(entity, "random@arrests@busted", "idle_a", 8.0, 1.0, -1, 9, 0, 0, 0, 0)

		SetEntityAsMissionEntity(entity, true, true)
		FreezeEntityPosition(entity, false)
		surrendered[entity] = true
		
		sendPoliceAlert(GetEntityCoords(PlayerPedId()))
	else
		NetworkRequestControlOfEntity(entity)
		local attempt = 0

		while not NetworkHasControlOfEntity(entity) and attempt < 100 and DoesEntityExist(entity) do
			Wait(100)
			NetworkRequestControlOfEntity(entity)
			attempt = attempt + 1
		end

		surrendered[entity] = true
		local notyth = false
		CreateThread(function()
			-- Termina cuando se suelta al rehén (surrendered a nil) o deja de
			-- existir: antes era un while true y quedaba un hilo vivo por cada
			-- rehén de la sesión. `false` no lo corta: es un paso intermedio.
			while DoesEntityExist(entity) and surrendered[entity] ~= nil do
				local wait = 1000
				if surrendered[entity] == 'th' then
					wait = 0
					if not notyth then
						if GetResourceState('origen_hud') == 'started' then
							exports['origen_hud']:setupControls({
								{ key = 'E', text = Cfg.Translations['Matar']['kill'] },
								{ key = 'BACKSPACE', text = Cfg.Translations['Matar']['kneel'] },
							})
						else
							ShowHelpNotification('E', Cfg.Translations['Matar']['fullText'], entity)
						end
						notyth = true
					end
				else
					if notyth then
						if GetResourceState('origen_hud') == 'started' then
							exports['origen_hud']:hideControls()
						else
							HideHelpNotification()
						end
						notyth = false
					end		
				end
				Wait(wait)
			end
			if notyth then
				if GetResourceState('origen_hud') == 'started' then
					exports['origen_hud']:hideControls()
				else
					HideHelpNotification()
				end
			end
		end)

		-- Menú unificado con org-menu (estilo Origen)
		local menu = {
			{
				isMenuHeader = true,
				header = Cfg.Translations['hostage_options'],
				icon = 'fa-solid fa-handcuffs',
			},
			{
				header = Cfg.Translations['release_hostage'],
				txt = Cfg.Translations['release_hostage_desc'],
				icon = 'fa-solid fa-user-check',
				params = {
					event = "npc_hostage:openMenuFunction",
					args = {action = "release", entity = entity}
				}
			},
			{
				header = Cfg.Translations['follow_hostage'],
				txt = Cfg.Translations['follow_hostage_desc'],
				icon = 'fa-solid fa-person-walking',
				params = {
					event = "npc_hostage:openMenuFunction",
					args = {action = "follow", entity = entity}
				}
			},
			{
				header = Cfg.Translations['kneel_hostage'],
				txt = Cfg.Translations['kneel_hostage_desc'],
				icon = 'fa-solid fa-person-praying',
				params = {
					event = "npc_hostage:openMenuFunction",
					args = {action = "kneel", entity = entity}
				}
			},
			{
				header = Cfg.Translations['threat_hostage'],
				txt = Cfg.Translations['threat_hostage_desc'],
				icon = 'fa-solid fa-user-shield',
				params = {
					event = "npc_hostage:openMenuFunction",
					args = {action = "threaten", entity = entity}
				}
			},
		}

		if Cfg.Rob then 
			table.insert(menu, {
				header = Cfg.Translations['rob_hostage'],
				txt = Cfg.Translations['rob_hostage_desc'],
				icon = 'fa-solid fa-people-robbery',
				params = {
					event = "npc_hostage:openMenuFunction",
					args = {action = "rob", entity = entity}
				}
			})
		end

		exports['org-menu']:openMenu(menu)
	end
end

function release(entity)
	noty = false
	HideHelpNotification()
	surrendered[entity] = nil
	if IsEntityPlayingAnim(entity, "random@arrests@busted", "idle_a", 3) then
		TaskPlayAnim(entity, "random@arrests@busted", "exit", 8.0, 1.0, -1, 2, 0, 0, 0, 0)
		Wait(3000)
		TaskPlayAnim(entity, "random@arrests", "kneeling_arrest_get_up", 8.0, 1.0, -1, 128, 0, 0, 0, 0)
		Wait(2000)
	end
	ClearPedTasks(entity)
	TaskReactAndFleePed(entity, PlayerPedId())
end


function follow(entity)
	noty = false
	HideHelpNotification()
	surrendered[entity] = "follow"
	TaskFollowToOffsetOfEntity(entity, PlayerPedId(), 0.5, -1.0, 0.0, 5.0, -1, 1.0, true)
	CreateThread(function()
		while surrendered[entity] == "follow" do
			Wait(1000)
			if IsPedInAnyVehicle(PlayerPedId()) and not IsPedInAnyVehicle(entity) then
				local veh = GetVehiclePedIsIn(PlayerPedId(), false)

				for i = 0, GetVehicleMaxNumberOfPassengers(veh) - 1 do
					if IsVehicleSeatFree(veh, i) then
						TaskEnterVehicle(entity, veh, 10000, i, 2.0, 1, 0)
						break
					end
				end
			elseif not IsPedInAnyVehicle(PlayerPedId()) and IsPedInAnyVehicle(entity) then
				TaskLeaveVehicle(entity, GetVehiclePedIsIn(entity, false), 0)
				TaskFollowToOffsetOfEntity(entity, PlayerPedId(), 0.5, -1.0, 0.0, 5.0, -1, 1.0, true)
			end
		end
	end)
end

exports('follow', follow)
exports('kneel', kneel)
exports('threaten', threaten)
exports('release', follow)

--[[ Consultar el estado, no solo cambiarlo.

     Hasta ahora este recurso solo exportaba ACCIONES: obligar a seguir, a
     arrodillarse, soltar. Nadie de fuera podia preguntar "¿este tio va contigo
     ahora mismo?", y eso hace falta para los objetivos de secuestro de
     origen_quests: sin esto habria que adivinarlo mirando animaciones, que
     falla en cuanto el NPC entra en un coche.

     Se devuelve el estado en crudo —"follow", "kneel", "th"— porque cada uno
     significa algo distinto y quien pregunte sabra cual le sirve. ]]
exports('EstadoDe', function(entity)
	return surrendered[entity]
end)

--- Los que van contigo ahora mismo. Solo los que SIGUEN: un NPC de rodillas
--- esta retenido, pero no te lo estas llevando a ninguna parte.
exports('Seguidores', function()
	local lista = {}
	for entity, estado in pairs(surrendered) do
		if estado == "follow" and DoesEntityExist(entity) and not IsEntityDead(entity) then
			lista[#lista + 1] = entity
		end
	end
	return lista
end)

function kneel(entity)
	noty = false
	HideHelpNotification()
	surrendered[entity] = "kneel"
	TaskPlayAnim(entity, "random@arrests", "idle_2_hands_up", 8.0, 1.0, -1, 2, 0, 0, 0, 0)
	Wait(4000)
	TaskPlayAnim(entity, "random@arrests", "kneeling_arrest_idle", 8.0, 1.0, -1, 2, 0, 0, 0, 0)
	Wait(500)
	TaskPlayAnim(entity, "random@arrests@busted", "enter", 8.0, 1.0, -1, 2, 0, 0, 0, 0)
	Wait(1000)
	TaskPlayAnim(entity, "random@arrests@busted", "idle_a", 8.0, 1.0, -1, 9, 0, 0, 0, 0)	
end


function threaten(entity)
	noty = false
	HideHelpNotification()
	if surrendered[entity] == "th" then
		return
	end

	surrendered[entity] = "th"
	RequestAnimDict("anim@gangops@hostage@")
	while not HasAnimDictLoaded("anim@gangops@hostage@") do
		Wait(0)
	end
	TaskPlayAnim(PlayerPedId(), "anim@gangops@hostage@", "perp_idle", 8.0, 1.0, -1, 49, 0, 0, 0, 0)
	TaskPlayAnim(entity, "anim@gangops@hostage@", "victim_idle", 8.0, 1.0, -1, 2, 0, 0, 0, 0)
	AttachEntityToEntity(entity, PlayerPedId(), 0, -0.24, 0.11, 0.0, 0.5, 0.5, 0.0	, false, false, false, false, 2, false)

	CreateThread(function()
		while surrendered[entity] == "th" do
			Wait(0)
			DisableControlAction(0, 25, true)
			if IsControlJustPressed(0, Cfg.KillKey) and CanKillNPC() then
				if GetResourceState('origen_hud') == 'started' then
					exports['origen_hud']:hideControls()
				end
				ClearPedTasks(PlayerPedId())
				DetachEntity(entity, true, false)
				SetEntityHealth(entity, 0)
				surrendered[entity] = false
			end
			if IsControlJustPressed(0, Cfg.KneelKey) then
				if GetResourceState('origen_hud') == 'started' then
					exports['origen_hud']:hideControls()
				end
				ClearPedTasks(PlayerPedId())
				DetachEntity(entity, true, false)
				ClearPedTasks(entity)
				surrendered[entity] = "kneel"
				TaskPlayAnim(entity, "random@arrests", "idle_2_hands_up", 8.0, 1.0, -1, 2, 0, 0, 0, 0)
				Wait(4000)
				TaskPlayAnim(entity, "random@arrests", "kneeling_arrest_idle", 8.0, 1.0, -1, 2, 0, 0, 0, 0)
				Wait(500)
				TaskPlayAnim(entity, "random@arrests@busted", "enter", 8.0, 1.0, -1, 2, 0, 0, 0, 0)
				Wait(1000)
				TaskPlayAnim(entity, "random@arrests@busted", "idle_a", 8.0, 1.0, -1, 9, 0, 0, 0, 0)				
			end
		end
	end)
	Wait(20)
	ForcePedMotionState(PlayerPedId(), -1871534317, true, 1, true)
end

function GetOnlinePoliceCount()
    if not Cfg.RequireMinimumPolice then
        return Cfg.MinimumPolice
    end

    local policeCount = 0
    local promise = promise.new()
    
    TriggerServerEvent('origen_hostage:server:getPoliceCount')
    
    RegisterNetEvent('origen_hostage:client:receivePoliceCount', function(count)
        promise:resolve(count)
    end)
    
    return Citizen.Await(promise)
end

function CanTakeHostage()
    if not Cfg.RequireMinimumPolice then
        return true
    end
    
    local policeCount = GetOnlinePoliceCount()
    return policeCount >= Cfg.MinimumPolice
end

function GetRandomAggressiveWeapon()
    if not Cfg.AggressiveNPCs then
        return nil
    end
    
    math.randomseed(GetGameTimer())
    local totalChance = 0

    for _, weaponData in ipairs(Cfg.AggressiveWeapons) do
        totalChance = totalChance + weaponData.chance
    end

    local randomNum = math.random(1, totalChance)
    local currentChance = 0

    for _, weaponData in ipairs(Cfg.AggressiveWeapons) do
        currentChance = currentChance + weaponData.chance
        if randomNum <= currentChance then
            return weaponData.weapon
        end
    end

    return Cfg.AggressiveWeapons[1] and Cfg.AggressiveWeapons[1].weapon or "WEAPON_KNIFE"
end

function IsNPCAggressive()
    if not Cfg.AggressiveNPCs then
        return false
    end
    
    math.randomseed(GetGameTimer())
    return math.random(0, 100) < Cfg.AggressiveChance
end