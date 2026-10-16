local holdingpepperspray = false
local usingpepperspray = false
local peppersprayModel = "w_am_flare"
local animDict = "weapons@first_person@aim_rng@generic@projectile@shared@core"
local animName = "idlerng_med"
local particleDict = "scr_bike_business"
local particleName = "scr_bike_spraybottle_spray"
local actionTime = 8
local pepperspray_net = nil
local currentSlot = nil

---------------------------------------------------------------------------
-- Toggling pepperspray --
---------------------------------------------------------------------------
RegisterNetEvent("pepperspray:Togglepepperspray")
AddEventHandler("pepperspray:Togglepepperspray", function(forceOff, slot)
    local ped = PlayerPedId()
    if not holdingpepperspray and not forceOff then
        local modelHash = GetHashKey(peppersprayModel)
        RequestModel(modelHash)
        while not HasModelLoaded(modelHash) do
            Citizen.Wait(5)
        end

        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do
            Citizen.Wait(5)
        end

        local plyCoords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.0, -5.0)
        local peppersprayspawned = CreateObject(modelHash, plyCoords.x, plyCoords.y, plyCoords.z, true, true, true)
        SetModelAsNoLongerNeeded(modelHash)
        
        Citizen.Wait(100)
        local netid = ObjToNet(peppersprayspawned)
        SetNetworkIdExistsOnAllMachines(netid, true)
        NetworkSetNetworkIdDynamic(netid, true)
        SetNetworkIdCanMigrate(netid, false)
        AttachEntityToEntity(peppersprayspawned, ped, GetPedBoneIndex(ped, 28422), 0.05, -0.05, 0.0, 260.0, 0.0, 0.0, true, true, false, true, 0, true)
        TaskPlayAnim(ped, animDict, animName, 1.0, -1, -1, 50, 0, 0, 0, 0)
        pepperspray_net = netid
        holdingpepperspray = true
        currentSlot = slot
    else
        ClearPedSecondaryTask(ped)
        local obj = NetToObj(pepperspray_net)
        if DoesEntityExist(obj) then
            DetachEntity(obj, true, true)
            DeleteEntity(obj)
        end
        pepperspray_net = nil
        holdingpepperspray = false
        usingpepperspray = false
        currentSlot = nil
    end
end)

---------------------------------------------------------------------------
-- Start Particles --
---------------------------------------------------------------------------
RegisterNetEvent("pepperspray:StartParticles")
AddEventHandler("pepperspray:StartParticles", function(peppersprayid)
    local entity = NetToObj(peppersprayid)
    if not DoesEntityExist(entity) then return end

    RequestNamedPtfxAsset(particleDict)
    while not HasNamedPtfxAssetLoaded(particleDict) do
        Citizen.Wait(5)
    end

    UseParticleFxAssetNextCall(particleDict)
    local particleEffect = StartParticleFxLoopedOnEntity(particleName, entity, 0.2, 0.002, 0.0, 0.0, -95.0, 180.0, Config.Intensity, false, false, false)
    RemoveNamedPtfxAsset(particleDict)
end)

---------------------------------------------------------------------------
-- Stop Particles --
---------------------------------------------------------------------------
RegisterNetEvent("pepperspray:StopParticles")
AddEventHandler("pepperspray:StopParticles", function(peppersprayid)
    local entity = NetToObj(peppersprayid)
    if DoesEntityExist(entity) then
        RemoveParticleFxFromEntity(entity)
    end
end)

---------------------------------------------------------------------------
-- Play Effect
---------------------------------------------------------------------------
local isSprayed = false

RegisterNetEvent("pepperspray:PlayerEffect")
AddEventHandler("pepperspray:PlayerEffect", function()
    local ped = PlayerPedId()
	if not isSprayed and not IsPedInAnyVehicle(ped, true) then
        isSprayed = true
		SetTimecycleModifier("drunk")
		SetTimecycleModifierStrength(2.0)

        if Config.RagdollTarget then
            SetPedToRagdollWithFall(ped, Config.SprayEffectTime * 1000, Config.SprayEffectTime * 1000, 1, -GetEntityForwardVector(ped), 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
        end

        if Config.PlayCoughAnimation then
            RequestAnimDict("amb@code_human_cough@male@idle_a")
            while not HasAnimDictLoaded("amb@code_human_cough@male@idle_a") do
                Citizen.Wait(5)
            end
            TaskPlayAnim(ped, "amb@code_human_cough@male@idle_a", "idle_b", 8.0, -8.0, Config.SprayEffectTime * 1000, 48, 0, false, false, false)
        end

		Citizen.Wait(Config.SprayEffectTime * 1000)

        if Config.PlayCoughAnimation then
            ClearPedTasks(ped)
        end
		ClearTimecycleModifier()
        isSprayed = false
	end
end)

---------------------------------------------------------------------------
-- Spraying Pepper Spray --
---------------------------------------------------------------------------
Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        if holdingpepperspray then
            sleep = 0
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) or IsEntityDead(ped) then
                TriggerEvent("pepperspray:Togglepepperspray", true)
            end
            for i=140, 143 do
                DisableControlAction(0, i, true)
            end
            if IsControlJustPressed(0, 24) and not usingpepperspray then
                FireSpray()
            end
        end
        Citizen.Wait(sleep)
    end
end)

function FireSpray()
    Citizen.CreateThread(function()
        usingpepperspray = true
        local count = Config.TimeUntilReload
		TriggerServerEvent("pepperspray:SyncStartParticles", pepperspray_net)
	
		local foundPed = FindPedInRaycast()
		if foundPed ~= 0 then
            local plyPed = PlayerPedId()
            local plyCoords = GetEntityCoords(plyPed)
            local targetCoords = GetEntityCoords(foundPed)
            local targetForward = GetEntityForwardVector(foundPed)

            local direction = targetCoords - plyCoords
            local dist = #(direction)
            if dist > 0 then
                direction = direction / dist
            end

            -- El dot product entre la dirección del disparo y el frente del objetivo.
            -- Si están de frente, debe dar un valor negativo (cercano a -1.0).
            local dot = (direction.x * targetForward.x) + (direction.y * targetForward.y)

            if dot < -0.3 then
                if IsPedAPlayer(foundPed) then
                    local playerid = GetPlayerFromPed(foundPed)
                    if playerid ~= -1 then
                        TriggerServerEvent("pepperspray:TriggerPlayerEffect", GetPlayerServerId(playerid))
                    end
                else
                    if Config.RagdollTarget then
                        SetPedToRagdollWithFall(foundPed, 7000, 7000, 1, -GetEntityForwardVector(foundPed), 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
                    end
                    if Config.PlayCoughAnimation then
                        RequestAnimDict("amb@code_human_cough@male@idle_a")
                        while not HasAnimDictLoaded("amb@code_human_cough@male@idle_a") do
                            Citizen.Wait(5)
                        end
                        TaskPlayAnim(foundPed, "amb@code_human_cough@male@idle_a", "idle_b", 8.0, -8.0, 7000, 48, 0, false, false, false)
                    end
                end
            end
		end

        while IsControlPressed(0, 24) and count > 0 do
            if not holdingpepperspray then
                usingpepperspray = false
                TriggerServerEvent("pepperspray:SyncStopParticles", pepperspray_net)
                return
            end
            
            -- Consumir durabilidad en el servidor
            if currentSlot then
                TriggerServerEvent('pepperspray:server:useDurability', currentSlot)
            end

            Citizen.Wait(1000)
            count = count - 1.0
        end
        TriggerServerEvent("pepperspray:SyncStopParticles", pepperspray_net)
        usingpepperspray = false
    end)
end

function FindPedInRaycast()
	local plyPed = PlayerPedId()
	local plyPos = GetEntityCoords(plyPed, false)
	local plyOffset = GetOffsetFromEntityInWorldCoords(plyPed, 0.0, Config.SprayRange, 0.0)
	local rayHandle = StartShapeTestCapsule(plyPos.x, plyPos.y, plyPos.z, plyOffset.x, plyOffset.y, plyOffset.z, 1.0, 12, plyPed, 7)
	local _, _, _, _, ped = GetShapeTestResult(rayHandle)
	return ped
end

function GetPlayerFromPed(ped)
	local players = GetActivePlayers()
	for _, player in ipairs(players) do
		if GetPlayerPed(player) == ped then
			return player
		end
	end
	return -1
end