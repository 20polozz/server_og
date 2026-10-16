local isAllowed = false
local Weapons = {}
local Loaded = true
local realWeapons = Config.RealWeapons
local handgunFlag = 'backhandgun'
local rifleFlag = 'assault'
local offsetCoords = nil
local weaponCategoryOffsets = {}
local showPistol = true
-- entidad -> { red = id de red, modelo = hash }. Sirve para no borrar otra cosa
-- si el juego reutiliza el número, y para pedir el borrado al servidor cuando
-- el objeto ya no existe en este cliente (se quedó en otro routing bucket).
local datosArma = {}
local holstered  = true
local switched = false

if not Config.Holster then
    return
end

function IsHolsterAllowed()
	if Config.HolsterAllJobs then
		isAllowed = true
		return true
	end
	local PlayerData = FW_GetPlayerData(false)
	if PlayerData == nil or PlayerData.job == nil or PlayerData.job.name == nil then 
        isAllowed = false
        return false 
    end
	local jobCat = GetJobCategory(PlayerData.job.name)
	for _, allowedJob in pairs(Config.AllowedHolster) do
		if PlayerData.job.name == allowedJob or jobCat == allowedJob then
			isAllowed = true
			return true
		end
	end
	isAllowed = false
	return false
end

RegisterNetEvent('origen_police:holster:unarm', function()
	local ped = PlayerPedId()
    if showPistol then
        SetCurrentPedWeapon(ped, GetHashKey('WEAPON_UNARMED'), true)
		SetPedCanSwitchWeapon(ped, true)
        showPistol = false
		RemoveGears()
		ClearPedTasks(ped)
		ExecuteCommand (Config.Translations.DoHide)
    else
        showPistol = true
		SetGears()
		SetPedCanSwitchWeapon(ped, true)
		ExecuteCommand (Config.Translations.DoShow)
    end
end)

local holsterCanBeLoaded = false

local function SaveHolsterKvp(citizenid, hg, rf)
	if citizenid and citizenid ~= "" then
		if hg then SetResourceKvp("holster_hg_" .. citizenid, hg) end
		if rf then SetResourceKvp("holster_rf_" .. citizenid, rf) end
	end
	if hg then SetResourceKvp("origen_police_handgunflag", hg) end
	if rf then SetResourceKvp("origen_police_rifleflag", rf) end
end

local function LoadHolsterPreferences()
	local PlayerData = FW_GetPlayerData(true)
	local citizenid = PlayerData and PlayerData.citizenid

	-- 1. Intentar cargar primero de KVP local (específico por personaje o global)
	local kvpHg = citizenid and GetResourceKvpString("holster_hg_" .. citizenid) or GetResourceKvpString("origen_police_handgunflag")
	local kvpRf = citizenid and GetResourceKvpString("holster_rf_" .. citizenid) or GetResourceKvpString("origen_police_rifleflag")

	if kvpHg and kvpHg ~= "" then handgunFlag = kvpHg end
	if kvpRf and kvpRf ~= "" then rifleFlag = kvpRf end

	-- 2. Metadata del servidor (prioridad si el personaje ya tiene datos en base de datos)
	if PlayerData and PlayerData.metadata then
		local metaHandgun = PlayerData.metadata["handgunflag"]
		local metaRifle = PlayerData.metadata["rifleflag"]

		if metaHandgun and metaHandgun ~= "" then
			handgunFlag = metaHandgun
			SaveHolsterKvp(citizenid, metaHandgun, nil)
		elseif kvpHg and kvpHg ~= "" then
			-- Si KVP existe pero metadata no, sincronizar al servidor
			TriggerServerEvent("origen_police:SetMetaData", "handgunflag", kvpHg)
		end

		if metaRifle and metaRifle ~= "" then
			rifleFlag = metaRifle
			SaveHolsterKvp(citizenid, nil, metaRifle)
		elseif kvpRf and kvpRf ~= "" then
			TriggerServerEvent("origen_police:SetMetaData", "rifleflag", kvpRf)
		end
	else
		-- Si PlayerData no tiene metadata todavía, consultar por callback al servidor
		FW_TriggerCallback("origen_police:server:GetPlayerMetadata", function(meta)
			if meta and type(meta) == "table" then
				local mHg = meta["handgunflag"]
				local mRf = meta["rifleflag"]
				local changed = false
				if mHg and mHg ~= "" then
					handgunFlag = mHg
					SaveHolsterKvp(citizenid, mHg, nil)
					changed = true
				end
				if mRf and mRf ~= "" then
					rifleFlag = mRf
					SaveHolsterKvp(citizenid, nil, mRf)
					changed = true
				end
				if changed then
					RemoveGears()
				end
			end
		end)
	end

	holsterCanBeLoaded = true
end

-- Al arrancar el recurso (reinicio de script con /ensure o /restart), cargar de inmediato
CreateThread(function()
	if not Config.Holster then return end
	Wait(1000)
	local PlayerData = FW_GetPlayerData(true)
	if PlayerData and PlayerData.citizenid then
		LoadHolsterPreferences()
	else
		for _ = 1, 8 do
			Wait(500)
			PlayerData = FW_GetPlayerData(true)
			if PlayerData and PlayerData.citizenid then
				LoadHolsterPreferences()
				break
			end
		end
	end
	if not holsterCanBeLoaded then
		local kvpHg = GetResourceKvpString("origen_police_handgunflag")
		local kvpRf = GetResourceKvpString("origen_police_rifleflag")
		if (kvpHg and kvpHg ~= "") or (kvpRf and kvpRf ~= "") then
			if kvpHg and kvpHg ~= "" then handgunFlag = kvpHg end
			if kvpRf and kvpRf ~= "" then rifleFlag = kvpRf end
			holsterCanBeLoaded = true
		end
	end
end)

RegisterNetEvent('origen_police:client:OnJobUpdate', function(job)
	RemoveGears()
	Wait(1000)
end)

RegisterNetEvent("origen_police:client:OnPlayerLoaded", function()
	local attempts = 0
	local PlayerData = FW_GetPlayerData(true)
	while (not PlayerData or not PlayerData.citizenid) and attempts < 10 do
		Wait(500)
		attempts = attempts + 1
		PlayerData = FW_GetPlayerData(true)
	end
	LoadHolsterPreferences()
	RemoveGears()
end)

RegisterNetEvent("origen_police:client:OnPlayerUnload", function()
	holsterCanBeLoaded = false
	RemoveGears()
end)

RegisterNetEvent('qbx_core:client:onSetMetaData', function(meta, oldValue, newValue)
	local pData = FW_GetPlayerData(false)
	local cid = pData and pData.citizenid
	if meta == 'handgunflag' and newValue and newValue ~= '' then
		handgunFlag = newValue
		SaveHolsterKvp(cid, newValue, nil)
		RemoveGears()
	elseif meta == 'rifleflag' and newValue and newValue ~= '' then
		rifleFlag = newValue
		SaveHolsterKvp(cid, nil, newValue)
		RemoveGears()
	end
end)

RegisterNetEvent('QBCore:Client:OnMetaDataUpdate', function(key, value)
	local pData = FW_GetPlayerData(false)
	local cid = pData and pData.citizenid
	if type(key) == 'table' then
		if key.handgunflag and key.handgunflag ~= '' then
			handgunFlag = key.handgunflag
			SaveHolsterKvp(cid, key.handgunflag, nil)
			RemoveGears()
		end
		if key.rifleflag and key.rifleflag ~= '' then
			rifleFlag = key.rifleflag
			SaveHolsterKvp(cid, nil, key.rifleflag)
			RemoveGears()
		end
	elseif key == 'handgunflag' and value and value ~= '' then
		handgunFlag = value
		SaveHolsterKvp(cid, value, nil)
		RemoveGears()
	elseif key == 'rifleflag' and value and value ~= '' then
		rifleFlag = value
		SaveHolsterKvp(cid, nil, value)
		RemoveGears()
	end
end)

local inventoryCache = {}

-- Borra un arma colgada. Si aquí ya no existe (o no se deja borrar), la borra
-- el servidor por su id de red: al cambiar de routing bucket el objeto se queda
-- en el anterior, este cliente deja de verlo y antes se quedaba allí suelto.
local function BorrarArma(entity)
	local datos = datosArma[entity]
	datosArma[entity] = nil
	if entity and entity ~= 0 and DoesEntityExist(entity) and (not datos or GetEntityModel(entity) == datos.modelo) then
		SetEntityAsMissionEntity(entity, true, true)
		DeleteEntity(entity)
		if not DoesEntityExist(entity) then return end
	end
	if datos and datos.red then
		TriggerServerEvent('origen_police:holster:borrar', datos.red)
	end
end

-- SetPlayerModel cambia el ped: las armas se sueltan del ped viejo y hay que
-- borrarlas ya, sin esperar a la vuelta de 1,5 s (en ese hueco el jugador puede
-- irse lejos o cambiar de bucket). La vuelta normal las cuelga del ped nuevo.
CreateThread(function()
	local ultimoPed = PlayerPedId()
	while true do
		Wait(200)
		local ped = PlayerPedId()
		if ped ~= ultimoPed then
			ultimoPed = ped
			RemoveGears()
		end
	end
end)

HasPedGotWeapon = function(ped, weaponHash, bCheck)
	if not holsterCanBeLoaded then return false end
	if not inventoryCache.data or GetGameTimer() - inventoryCache.time > 10 then
		inventoryCache = {time = GetGameTimer(), data = GetPlayerItems(nil)}
	end
	for _, v in pairs(inventoryCache.data) do
		if GetHashKey(v.name) == weaponHash then
			return true
		end
	end
	return false
end

CreateThread(function()
    if not Config.Holster then
        return
    end
	while not Loaded do
		Wait(500)
	end

	Wait(5000)
	local playerPed = PlayerPedId()
	SetPedCanSwitchWeapon(playerPed, true)
	realWeapons = Config.RealWeapons
	weaponCategoryOffsets = Config.WeaponCategoryOffsets

	-- Hash de cada arma calculado una sola vez: antes eran 86 GetHashKey por vuelta
	local hashArma = {}
	for i=1, #realWeapons, 1 do
		hashArma[i] = GetHashKey(realWeapons[i].name)
	end

	while true do
		Wait(1500)
		playerPed = PlayerPedId()

		for weaponName, entity in pairs(Weapons) do
			if not DoesEntityExist(entity) or not IsEntityAttachedToEntity(entity, playerPed) then
				BorrarArma(entity)
				Weapons[weaponName] = nil
			end
		end

		if showPistol and holsterCanBeLoaded and (IsEntityVisible(playerPed) == 1 or IsEntityVisible(playerPed) == true) and GetEntityAlpha(playerPed) > 0.0 then
			-- El inventario se pide UNA vez por vuelta y se pasa a hashes; mismo
			-- resultado que HasPedGotWeapon por arma, sin recorrerlo 86 veces
			local tengo = {}
			for _, item in pairs(GetPlayerItems(nil)) do
				if item and item.name then
					tengo[GetHashKey(item.name)] = true
				end
			end
			local armaEnMano = GetSelectedPedWeapon(playerPed)
			for i=1, #realWeapons, 1 do
				local weaponHash = hashArma[i]
				if tengo[weaponHash] then
					if not Weapons[realWeapons[i].name] and weaponHash ~= armaEnMano then
						if realWeapons[i].model ~= nil then
							SetGear(realWeapons[i].name)
						end
					elseif weaponHash == armaEnMano then
						RemoveGear(realWeapons[i].name)
					end
				elseif Weapons[realWeapons[i].name] then
					RemoveGear(realWeapons[i].name)
				end
			end
		else
			RemoveGears()
		end
	end
end)

-- Remove only one weapon that's on the ped
function RemoveGear(weapon)
	local _Weapons = {}
	for weaponName, entity in pairs(Weapons) do
		if weaponName ~= weapon then
			_Weapons[weaponName] = entity
		else
			BorrarArma(entity)
		end
	end

	Weapons = _Weapons
end

-- Remove all weapons that are on the ped
function RemoveGears()
	for _, entity in pairs(Weapons) do
		BorrarArma(entity)
	end
	Weapons = {}
end

-- Get the coords for the specific category
function GetCoords(cat)

	for i=1, #weaponCategoryOffsets, 1 do
		if weaponCategoryOffsets[i].category == cat then
			return weaponCategoryOffsets[i].bone, weaponCategoryOffsets[i].x, weaponCategoryOffsets[i].y, weaponCategoryOffsets[i].z, weaponCategoryOffsets[i].xRot, weaponCategoryOffsets[i].yRot, weaponCategoryOffsets[i].zRot
		end
	end

end

-- Add one weapon on the ped
function SetGear(weapon)
	local bone       = nil
	local boneX      = 0.0
	local boneY      = 0.0
	local boneZ      = 0.0
	local boneXRot   = 0.0
	local boneYRot   = 0.0
	local boneZRot   = 0.0
	local playerPed  = PlayerPedId()
	local model      = nil
	local isPolice = nil

	if not IsHolsterAllowed() then return end

	for i=1, #realWeapons, 1 do
		if realWeapons[i].name == weapon then
			if realWeapons[i].category == 'handguns' or realWeapons[i].category == 'revolver' then
				offsetCoords = handgunFlag
			elseif realWeapons[i].category == 'machine' or realWeapons[i].category == 'assault' or realWeapons[i].category == 'shotgun' or realWeapons[i].category == 'sniper' or realWeapons[i].category == 'heavy' then
				offsetCoords = rifleFlag
			else
				offsetCoords = realWeapons[i].category
			end


			bone, boneX, boneY, boneZ, boneXRot, boneYRot, boneZRot = GetCoords(offsetCoords)
			model      = realWeapons[i].model

			break

		end
	end
	if Weapons[weapon] then
		BorrarArma(Weapons[weapon])
		Weapons[weapon] = nil
	end
	local pedCoords = GetEntityCoords(playerPed)
    local newObject = CreateObject(model, pedCoords.x, pedCoords.y, pedCoords.z, true, true, false)
	if not newObject or newObject == 0 then return end
    local boneIndex = GetPedBoneIndex(playerPed, bone)
	SetEntityCollision(newObject, false, false)
	AttachEntityToEntity(newObject, playerPed, boneIndex, boneX, boneY, boneZ, boneXRot, boneYRot, boneZRot, false, false, false, false, 2, true)
	SetEntityCollision(newObject, false, false)
	Weapons[weapon] = newObject
	datosArma[newObject] = {
		red = NetworkGetEntityIsNetworked(newObject) and NetworkGetNetworkIdFromEntity(newObject) or nil,
		modelo = GetEntityModel(newObject),
	}
end

-- Add all the weapons in the xPlayer's loadout
-- on the ped
function SetGears()
	local playerPed  = PlayerPedId()


	for j=1, #realWeapons, 1 do
		if HasPedGotWeapon(playerPed, GetHashKey(realWeapons[j].name), false) then
			SetGear(realWeapons[j].name)
		end
	end
end

RegisterCommand('holster', function(source, args)
	if IsHolsterAllowed() then
		if args[1] == nil then
			return FW_Notify(Config.Translations.SomethingWrong)
		elseif args[1] == 'handguns' or args[1] == 'waisthandgun' then
			handgunFlag = args[1]
			FW_Notify((Config.Translations.HipHolster))
		elseif args[1] == 'backhandgun' then
			handgunFlag = args[1]
			FW_Notify((Config.Translations.BackHolster))
		elseif args[1] == 'leghandgun' or args[1] == 'hiphandgun' or args[1] == 'handguns2' then
			handgunFlag = args[1]
			FW_Notify((Config.Translations.LegHolster))
		elseif args[1] == 'chesthandgun' then
			handgunFlag = args[1]
			FW_Notify((Config.Translations.UpperHolster))
		elseif args[1] == 'boxers' then
			handgunFlag = args[1]
			FW_Notify((Config.Translations.UnderPantsHolster))
		elseif args[1] == 'assault' then
			rifleFlag = args[1]
			FW_Notify((Config.Translations.LongHolsterBack))
		elseif args[1] == 'tacticalrifle' then
			rifleFlag = args[1]
			FW_Notify((Config.Translations.LongHolsterFront))
		else
			return FW_Notify(Config.Translations.SomethingWrong)
		end
		local pData = FW_GetPlayerData(false)
		SaveHolsterKvp(pData and pData.citizenid, handgunFlag, rifleFlag)
		TriggerServerEvent("origen_police:SetMetaData", "rifleflag", rifleFlag)
		TriggerServerEvent("origen_police:SetMetaData", "handgunflag", handgunFlag)
		holsterCanBeLoaded = true
		RemoveGears()
		switched = true
	end
end)

-- ========================	--
-- ANIMACIONES DE ARMAS		--
-- ======================== --
local HolsterAnimations = {
	draw = {
		['backhandgun'] = {dict = "reaction@intimidation@1h", anim = "intro"},
		['boxers'] = {dict = "combat@combat_reactions@pistol_1h_gang", anim = "0"},
		['chesthandgun'] = {dict = "combat@combat_reactions@pistol_1h_gang", anim = "0"},
		['leghandgun'] = {dict = "reaction@male_stand@big_variations@d", anim = "react_big_variations_m"},
		['default'] = {dict = "rcmjosh4", anim = "josh_leadout_cop2", useTaskPlayAnim = true},
		['tacticalrifle'] = {dict = "combat@combat_reactions@pistol_1h_hillbilly", anim = "0"},
		['rifle_default'] = {dict = "reaction@intimidation@1h", anim = "intro"}
	},
	holster = {
		['backhandgun'] = {dict = "reaction@intimidation@1h", anim = "outro"},
		['boxers'] = {dict = "combat@combat_reactions@pistol_1h_gang", anim = "0"},
		['chesthandgun'] = {dict = "combat@combat_reactions@pistol_1h_gang", anim = "0"},
		['leghandgun'] = {dict = "reaction@male_stand@big_variations@d", anim = "react_big_variations_m"},
		['default'] = {dict = "reaction@intimidation@cop@unarmed", anim = "outro"},
		['tacticalrifle'] = {dict = "combat@combat_reactions@pistol_1h_gang", anim = "0"},
		['rifle_default'] = {dict = "reaction@intimidation@1h", anim = "outro"}
	}
}

function loadAnimDict(dict)
	while not HasAnimDictLoaded(dict) do
		RequestAnimDict(dict)
		Wait(100)
	end
end

function CheckWeapon(ped, newWeap)
	if IsEntityDead(ped) then
		blocked = false
		return false
	else
		for i = 1, #realWeapons do
			if GetHashKey(realWeapons[i].name) == GetSelectedPedWeapon(ped) then
				return true
			end
		end

		return false
	end
end

function loadAnimDict2(dict)
	while ( not HasAnimDictLoaded(dict)) do
		RequestAnimDict(dict)
		Wait(0)
	end
end

local function PlayHolsterAnimation(ped, animationType, flagType, isRifle)
	local animConfig = HolsterAnimations[animationType][flagType] or 
	                   (isRifle and HolsterAnimations[animationType]['rifle_default'] or HolsterAnimations[animationType]['default'])
	
	if not animConfig then return end
	
	local pedCoords = GetEntityCoords(ped, true)
	local rot = GetEntityHeading(ped)
	local animSpeed = Config.AnimationSpeed["backhandgun"]["animSpeed"]
	local holsterSpeed = animationType == "holster" and 0.125 or animSpeed
	
	blocked = true
	
	if animConfig.useTaskPlayAnim then
		SetPedCurrentWeaponVisible(ped, 0, 1, 1, 1)
		SetPedCurrentWeaponVisible(ped, 1, 1, 1, 1)
		TaskPlayAnim(ped, animConfig.dict, animConfig.anim, 8.0, 2.0, -1, 48, 10, 0, 0, 0)
	else
		SetPedCurrentWeaponVisible(ped, 1, 1, 1, 1)
		TaskPlayAnimAdvanced(ped, animConfig.dict, animConfig.anim, pedCoords, 0, 0, rot, 8.0, 3.0, -1, 50, holsterSpeed, 0, 0)
	end
	
	Wait(Config.AnimationSpeed["backhandgun"]["clearAnimWait"])
	ClearPedTasks(ped)
	
	return true
end

CreateThread(function()
    if not Config.Holster then
        return
    end
	loadAnimDict("rcmjosh4")
    loadAnimDict("reaction@intimidation@cop@unarmed")
    loadAnimDict("reaction@intimidation@1h")
	loadAnimDict2("combat@combat_reactions@pistol_1h_gang")
	loadAnimDict2("combat@combat_reactions@pistol_1h_hillbilly")
	loadAnimDict2("reaction@male_stand@big_variations@d")
	local wepCat
	local lastWep
	
	local HANDGUN_TYPES = {416676503, 690389602}

	Wait(0)

	while (true) do
		local ped = PlayerPedId()
		Wait(50)

		if isAllowed and not IsPedInAnyVehicle(ped, true) then
			if (GetPedParachuteState(ped) == -1 or GetPedParachuteState(ped) == 0) and not IsPedInParachuteFreeFall(ped) then
				wepCat = GetWeapontypeGroup(GetSelectedPedWeapon(ped))
				local currentWeaponHash = GetSelectedPedWeapon(PlayerPedId())

				if CheckWeapon(ped) then
					local isHandgun = (wepCat == HANDGUN_TYPES[1] or wepCat == HANDGUN_TYPES[2])
					
					if holstered then
						if PlayHolsterAnimation(ped, "draw", isHandgun and handgunFlag or rifleFlag, not isHandgun) then
							holstered = false
							lastWep = GetSelectedPedWeapon(ped)
						end
					else
						blocked = false
					end
				else
					lastWeaponHash = currentWeaponHash
					local wasHandgun = (GetWeapontypeGroup(lastWep) == HANDGUN_TYPES[1] or GetWeapontypeGroup(lastWep) == HANDGUN_TYPES[2])

					if not holstered then
						if PlayHolsterAnimation(ped, "holster", wasHandgun and handgunFlag or rifleFlag, not wasHandgun) then
							holstered = true
						end
					end
				end
			elseif (GetVehiclePedIsTryingToEnter (ped) == 0) then
				holstered = false
			else
				SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
			end
		else
			holstered = true
		end

		if holstered then
			Wait(500)
		end
	end
end)

AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
		RemoveGears()
	end
end)

exports('IsHolsterAllowed', IsHolsterAllowed)