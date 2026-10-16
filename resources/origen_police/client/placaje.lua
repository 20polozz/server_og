local placaje = false
local isRagdoll = false

RegisterCommand('placaje', function(source, args, rawCommand)
    if IsPedInAnyVehicle(PlayerPedId(), false) then return end
    local PlayerData = FW_GetPlayerData(false)
    if PlayerData == nil or PlayerData.job == nil or PlayerData.job.name == nil then return false end
    local canTackle = (GetMinimunGrade(PlayerData.job.name, "CanTackle") <= PlayerData.job.grade.level)
    if not canTackle then return FW_Notify(Config.Translations.CantDoThis) end
	if CanOpenTablet(PlayerData.job.name)[1] and PlayerData.job.onduty then
        local player, distance = FW_GetClosestPlayer()
        local targetped = GetPlayerPed(player)
        if player ~= -1 and distance <= 1.5 and distance > 0 and not IsPedInAnyVehicle(targetped, false) and not IsPedInAnyVehicle(PlayerPedId(), false) and not IsEntityDead(targetped) and not IsEntityDead(PlayerPedId()) then
            if not placaje then
                TriggerServerEvent('origen_police:placaje_sv', GetPlayerServerId(player))
                placaje = true

                RequestAnimDict("missmic2ig_11")

                while not HasAnimDictLoaded("missmic2ig_11") do
                    Wait(10)
                end

                TaskPlayAnim(PlayerPedId(), "missmic2ig_11", "mic_2_ig_11_intro_goon", 8.0, -8.0, 3000, 0, 0, false, false, false)

                Wait(3000)

                placaje = false
            end
            return
        elseif Config.Actions.RagdollInTackleFail then
            ShowNotification(Config.Translations.PersonFar)

            RequestAnimDict("missmic2ig_11")

            while not HasAnimDictLoaded("missmic2ig_11") do
                Wait(10)
            end

            TaskPlayAnim(PlayerPedId(), "missmic2ig_11", "mic_2_ig_11_intro_goon", 8.0, -8.0, 3000, 0, 0, false, false, false)

            Wait(2200)

            isRagdoll = true
            CreateThread(function()
                while true do
                    Wait(5)

                    if isRagdoll then
                        SetPedToRagdoll(GetPlayerPed(-1), 1000, 1000, 0, 0, 0, 0)
                    else
                        break
                    end
                end
            end)
            Wait(3000)
            isRagdoll = false
        end
        Debuger("Tackle failed data, targetped: " .. targetped .. ", player: " .. player .. ", distance(max 1.5 min 0.01): " .. distance)
	end
end)

RegisterNetEvent('origen_police:placaje_cl')
AddEventHandler('origen_police:placaje_cl', function(target)
	if not placaje then
		placaje = true

		local targetPed = GetPlayerPed(GetPlayerFromServerId(target))

		RequestAnimDict("missmic2ig_11")

		while not HasAnimDictLoaded("missmic2ig_11") do
			Wait(10)
		end

		AttachEntityToEntity(GetPlayerPed(-1), targetPed, 11816, 0.25, 0.5, 0.0, 0.5, 0.5, 180.0, false, false, false, false, 2, false)
		TaskPlayAnim(GetPlayerPed(-1), "missmic2ig_11", "mic_2_ig_11_intro_p_one", 8.0, -8.0, 3000, 0, 0, false, false, false)

		Wait(2200)
		DetachEntity(GetPlayerPed(-1), true, false)

		isRagdoll = true
		CreateThread(function()
			while true do
				Wait(5)

				if isRagdoll then
					SetPedToRagdoll(GetPlayerPed(-1), 1000, 1000, 0, 0, 0, 0)
				else
					break
				end
			end
		end)
		Wait(3000)
		isRagdoll = false

		placaje = false
	end
end)