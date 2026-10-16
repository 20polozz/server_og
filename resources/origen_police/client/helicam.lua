if not Config.HeliCam then return end

local helicam = false
local night_vision = false
local thermal_vision = false
local fov = (Config.Camara.fov_max+Config.Camara.fov_min)*0.5
HelicamLockedVehicle = nil

function DoCamOrRappel(vehicle)
	local ped = PlayerPedId()
	
	if not helicam then
		if GetPedInVehicleSeat(vehicle, -1) == ped or GetPedInVehicleSeat(vehicle, 0) == ped then
			CreateThread(function()
				local scaleform = RequestScaleformMovie("HELI_CAM")
                while not HasScaleformMovieLoaded(scaleform) do
					Wait(0)
                end
                local cam = CreateCam("DEFAULT_SCRIPTED_FLY_CAMERA", true)
                AttachCamToEntity(cam, vehicle, 0.0,0.0,-1.5, true)
                SetCamRot(cam, 0.0,0.0, GetEntityHeading(vehicle))
                SetCamFov(cam, fov)
                RenderScriptCams(true, false, 0, 1, 0)
                PopScaleformMovieFunctionVoid()

				helicam = true
				HelicamLockedVehicle = nil
				local lost_visual_time = 0
				while helicam and not IsEntityDead(ped) and GetEntityHeightAboveGround(vehicle) > 1.5 do
					Wait(0)


					if Config.HeliCam.NightVision and IsControlJustPressed(0, 25) then -- Night vision
						PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
						if night_vision then
							SetNightvision(false)
							SetSeethrough(false)
							night_vision = false
							thermal_vision = false
						else
							SetNightvision(true)
							SetSeethrough(false)
							night_vision = true
							thermal_vision = false
						end
					elseif Config.HeliCam.ThermalVision and IsControlJustPressed(0, 24) then -- Thermal vision
						PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
						if thermal_vision then
							SetNightvision(false)
							SetSeethrough(false)
							night_vision = false
							thermal_vision = false
						else
							SetNightvision(true)
							SetSeethrough(true)
							night_vision = false
							thermal_vision = true
						end
					end

					if IsControlJustPressed(0, 22) then -- space
						if HelicamLockedVehicle then
							HelicamLockedVehicle = nil
							StopCamPointing(cam)
							PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
						else
							local vehicle_detected = GetVehicleInView(cam)
							if vehicle_detected then
								HelicamLockedVehicle = vehicle_detected
								PointCamAtEntity(cam, HelicamLockedVehicle, 0.0, 0.0, 0.0, true)
								PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
							end
						end
					end


					if HelicamLockedVehicle then
						if DoesEntityExist(HelicamLockedVehicle) then
							if HasEntityClearLosToEntity(vehicle, HelicamLockedVehicle, 17) then
								lost_visual_time = 0
							else
								if lost_visual_time == 0 then
									lost_visual_time = GetGameTimer()
								end
								if GetGameTimer() - lost_visual_time > 2000 then
									HelicamLockedVehicle = nil
									StopCamPointing(cam)
								end
							end
						else
							HelicamLockedVehicle = nil
							StopCamPointing(cam)
						end
					end

					local zoomvalue_h = (1.0/(Config.Camara.fov_max-Config.Camara.fov_min))*(fov-Config.Camara.fov_min)
					if not HelicamLockedVehicle then
						CheckInputRotation_h(cam, zoomvalue_h)
					end

					local vehicle_detected = GetVehicleInView(cam)
					if HelicamLockedVehicle then
						vehicle_detected = HelicamLockedVehicle
					end

					if DoesEntityExist(vehicle_detected) then
						RenderVehicleInfo(vehicle_detected, HelicamLockedVehicle ~= nil)
					else
						SendNUIMessage({
							action = "HelicamUpdate",
							toggle = true,
							vehicle = false
						})
					end

					HandleZoom_h(cam)

					PushScaleformMovieFunction(scaleform, "SET_ALT_FOV_HEADING")
					PushScaleformMovieFunctionParameterFloat(GetEntityCoords(vehicle).z)
					PushScaleformMovieFunctionParameterFloat(zoomvalue_h)
					PushScaleformMovieFunctionParameterFloat(GetCamRot(cam, 2).z)
					PopScaleformMovieFunctionVoid()
					DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255)
				end

				SendNUIMessage({ action = "HelicamUpdate", toggle = false })
				HelicamLockedVehicle = nil
				helicam = false
                night_vision = false
                RenderScriptCams(false, false, 0, 1, 0)
                SetScaleformMovieAsNoLongerNeeded(scaleform)
                StopCamPointing(cam)
                DestroyCam(cam, false)
                SetNightvision(false)
				SetSeethrough(false)
			end)
		elseif GetEntityHeightAboveGround(vehicle) > 5 then
			PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
			TaskRappelFromHeli(PlayerPedId(), 0x41200000)
			CreateThread(function()
				while GetEntityHeightAboveGround(PlayerPedId()) > 2 do
					Wait(0)
				end
				ClearPedTasks(PlayerPedId())
			end)
		end
	else
		helicam = false
	end
end

function HandleZoom_h(cam)
	DisableControlAction(0, 14)
	DisableControlAction(0, 15)
	DisableControlAction(0, 241)
	DisableControlAction(0, 242)
	if IsDisabledControlJustPressed(0,241) then
		fov = math.max(fov - Config.Camara.zoomspeed, Config.Camara.fov_min)
	end
	if IsDisabledControlJustPressed(0,242) then
		fov = math.min(fov + Config.Camara.zoomspeed, Config.Camara.fov_max)
	end
	local current_fov = GetCamFov(cam)
	if math.abs(fov-current_fov) < 0.1 then
		fov = current_fov
	end
	SetCamFov(cam, current_fov + (fov - current_fov)*0.05)
end


function CheckInputRotation_h(cam, zoomvalue_h)
	local rightAxisX = GetDisabledControlNormal(0, 220)
	local rightAxisY = GetDisabledControlNormal(0, 221)
	local rotation = GetCamRot(cam, 2)
	if rightAxisX ~= 0.0 or rightAxisY ~= 0.0 then
		local new_z = rotation.z + rightAxisX*-1.0*(Config.Camara.speed_ud)*(zoomvalue_h+0.1)
		local new_x = math.max(math.min(20.0, rotation.x + rightAxisY*-1.0*(Config.Camara.speed_lr)*(zoomvalue_h+0.1)), -89.5)
		SetCamRot(cam, new_x, 0.0, new_z, 2)
	end
end

function GetVehicleInView(cam)
	local coords = GetCamCoord(cam)
	local forward_vector = RotAnglesToVec(GetCamRot(cam, 2))

	local rayhandle = CastRayPointToPoint(coords, coords+(forward_vector*500.0), 10, GetVehiclePedIsIn(PlayerPedId()), 0)
	local _, _, _, _, entityHit = GetRaycastResult(rayhandle)
	if entityHit>0 and IsEntityAVehicle(entityHit) then
		return entityHit
	else
		return nil
	end
end

function RotAnglesToVec(rot)
	local z = math.rad(rot.z)
	local x = math.rad(rot.x)
	local num = math.abs(math.cos(x))
	return vector3(-math.sin(z)*num, math.cos(z)*num, math.sin(x))
end

local GTA_CLASSES = {
    [0] = "C", [1] = "B", [2] = "B", [3] = "B", [4] = "A", [5] = "A",
    [6] = "S", [7] = "S+", [8] = "M", [9] = "C", [10] = "D", [11] = "D",
    [12] = "D", [13] = "D", [14] = "D", [15] = "H", [16] = "P", [17] = "D",
    [18] = "EM", [19] = "D", [20] = "D", [21] = "D", [22] = "A"
}

local function GetHeliCarClassAndColor(veh)
    local vehClass = "D"
    local vehColor = "#fff"

    if GetResourceState('origen_vehicleclasses') == 'started' then
        local ok, fStats = pcall(function()
            return exports['origen_vehicleclasses']:GetVehicleStats(veh)
        end)
        if ok and fStats and fStats.class then
            vehClass = fStats.class
            vehColor = (fStats.classData and fStats.classData.color) or "#fff"
            return vehClass, vehColor
        end
    end

    local gtaClass = GetVehicleClass(veh)
    vehClass = GTA_CLASSES[gtaClass] or "D"
    return vehClass, vehColor
end

local checkedPlatesHeli = {}
local lastHeliPlateAlert = ""

function RenderVehicleInfo(vehicle, isLocked)
	local entityModel = GetEntityModel(vehicle)
    local label = Config.CustomCarLabels[entityModel] and Config.CustomCarLabels[entityModel] or GetLabelText(GetDisplayNameFromVehicleModel(entityModel))
	if label == "NULL" or not label or label == "" then
		label = GetDisplayNameFromVehicleModel(entityModel)
	end

	local licenseplate = GetVehiclePlate(vehicle)
	local speed = math.floor(GetEntitySpeed(vehicle) * 3.6) -- KMH integer

	local isWanted = false
	if checkedPlatesHeli[licenseplate] ~= nil then
		isWanted = checkedPlatesHeli[licenseplate]
	else
		FW_TriggerCallback("origen_police:server:IsPlateWanted", function(wanted)
			checkedPlatesHeli[licenseplate] = wanted
			if wanted and licenseplate ~= lastHeliPlateAlert then
				lastHeliPlateAlert = licenseplate
				PlaySoundFrontend(-1, "Beep_Red", "DLC_HEIST_HACKING_SNAKE_SOUNDS", 1)
				PlaySoundFrontend(-1, "Event_Message_Purple", "GTAO_FM_Events_Soundset", false)
			end
		end, licenseplate)
	end

	local vehClass, vehColor = GetHeliCarClassAndColor(vehicle)
	
	SendNUIMessage({
		action = "HelicamUpdate",
		toggle = true,
		vehicle = {
			name = label,
			plate = licenseplate,
			kmh = speed,
			wanted = isWanted,
			locked = isLocked,
			class = vehClass,
			color = vehColor
		}
	})
end

RegisterCommand(Config.Commands.Heli254V.cmd, function()
    if helicam and HelicamLockedVehicle then
        local plate = GetVehiclePlate(HelicamLockedVehicle)
        local model = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(HelicamLockedVehicle)))
        if model == "NULL" then model = GetDisplayNameFromVehicleModel(GetEntityModel(HelicamLockedVehicle)) end
        local street = GetStreetName(GetEntityCoords(HelicamLockedVehicle))
        local text = Config.Translations["254-V"]:format(model, plate, street)
        ExecuteCommand('rpol ' .. text)
        PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
    end
end)

RegisterKeyMapping(Config.Commands.Heli254V.cmd, Config.Commands.Heli254V.description, 'keyboard', Config.Commands.Heli254V.key)