function GetStreetName(coords)
    if coords.x == nil then
        coords = vector3(coords[1], coords[2], coords[3])
    end
    local streetName, streetName2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    streetName = GetStreetNameFromHashKey(streetName)
    streetName2 = GetStreetNameFromHashKey(streetName2)

    if streetName2 == "" then
        return streetName
    else
        return streetName .. " & " .. streetName2
    end
end

function GetCardinalFromHeading(h)
    if h < 22.5 then
        return "N"
    elseif h < 67.5 then
        return "NO"
    elseif h < 112.5 then
        return "O"
    elseif h < 157.5 then
        return "SO"
    elseif h < 202.5 then
        return "S"
    elseif h < 247.5 then
        return "SE"
    elseif h < 292.5 then
        return "E"
    elseif h < 337.5 then
        return "NE"
    else
        return "N"
    end
end

function GetRadarVehicle()
    local ped = PlayerPedId()
    local entity = IsPedInAnyVehicle(ped, false) and GetVehiclePedIsIn(ped, false) or ped
    local _, _, _, _, e = GetShapeTestResult(StartShapeTestCapsule(GetOffsetFromEntityInWorldCoords(entity, 0.0, 1.0, 1.0), GetOffsetFromEntityInWorldCoords(entity, 0.0, 105.0, 0.0), 3.0, 10, entity, 7))
    return GetVehiclePlate(e), GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(e)))
end

function IsBeingSeen()
    local coords = GetEntityCoords(PlayerPedId())
    local cam = GetClosestObjectOfType(coords.x, coords.y, coords.z, 50.0, GetHashKey("prop_cctv_cam_06a"), false, false, false)
    local peds = Fw_GetPeds()
    local peds_aux = false
    for i = 1, #peds do
        if not IsPedAPlayer(peds[i]) and #(GetEntityCoords(peds[i]) - coords) < 200 and GetPedType(peds[i]) ~= 28 and not GetPedConfigFlag(peds[i], 79) then
            peds_aux = true
            break
        end
    end
    return cam > 0 or peds_aux
end

function SetWantedLevel(level)
    level = tonumber(level)
    if not level then return end
    CreateThread(function()
        SetPoliceRadarBlips(false)
        SetMaxWantedLevel(5)
        SetPlayerWantedLevel(PlayerId(), level, false)
        SetPlayerWantedLevelNow(PlayerId(), true)
        while GetPlayerWantedLevel(PlayerId()) > 0 do
            Wait(1000)
            SendNUIMessage({
                action = "WantedLevel",
                value = GetPlayerWantedLevel(PlayerId())
            })

            if IsPedInAnyVehicle(PlayerPedId(), false) then
                local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                
                for i = -1, GetVehicleMaxNumberOfPassengers(vehicle) do
                    local ped = GetPedInVehicleSeat(vehicle, i)
                    if ped ~= 0 and ped ~= PlayerPedId() then
                        if GetPlayerWantedLevel(PlayerId()) > GetPlayerWantedLevel(NetworkGetPlayerIndexFromPed(ped)) then
                            TriggerServerEvent("origen_police:server:SetWantedLevel", GetPlayerServerId(NetworkGetPlayerIndexFromPed(ped)), GetPlayerWantedLevel(PlayerId()))
                        end
                    end
                end
            end
        end
        SetMaxWantedLevel(0)
        SendNUIMessage({
            action = "WantedLevel",
            value = 0
        })
    end)
end

exports("SetWantedLevel", SetWantedLevel)
exports("IsBeingSeen", IsBeingSeen)

function GetVehicleInCamera()
	local _, _, vehicle = RayCastGamePlayCamera(1000.0)
		
	if #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(vehicle)) > 100 then vehicle = FW_GetClosestVehicle() end

    if #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(vehicle)) > 30 then vehicle = false end

	if IsPedInAnyVehicle(PlayerPedId()) then
        vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    end

    return vehicle or 0
end

function GetScreenCoords(distance)
	local hit, coords, entity = RayCastGamePlayCamera(distance or 1000.0)
    return hit, coords, entity
end

function RotationToDirection(rotation)
	local adjustedRotation =
	{
		x = (math.pi / 180) * rotation.x,
		y = (math.pi / 180) * rotation.y,
		z = (math.pi / 180) * rotation.z
	}
	local direction =
	{
		x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
		y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
		z = math.sin(adjustedRotation.x)
	}
	return direction
end

function RayCastGamePlayCamera(distance)
    local cameraRotation = GetGameplayCamRot()
	local cameraCoord = GetGameplayCamCoord()
	local direction = RotationToDirection(cameraRotation)
	local destination =
	{
		x = cameraCoord.x + direction.x * distance,
		y = cameraCoord.y + direction.y * distance,
		z = cameraCoord.z + direction.z * distance
	}
	local _, b, c, _, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0))
	return b, c, e
end

function TakePhoto(url)
    local retval = false
    local finished = false
    SendNUIMessage({
        action = "playsound",
        soundid = "take-photo.mp3"
    })
    local field = (Config.Fields and Config.Fields[Config.UploadMethod]) or "image"
    
    local options = {
        headers = {},
        encoding = "webp",
        quality = 0.92
    }

    if url then
        local apiKey = string.match(url, "apiKey=([^&]+)")
        if apiKey then
            options.headers["Authorization"] = apiKey
        end
    end

    local ok = pcall(function()
        if GetResourceState("screenshot-basic") == "started" or GetResourceState("screencapture") == "started" then
            exports['screenshot-basic']:requestScreenshotUpload(url, field, options, function(response)
                if response then
                    local decoded = nil
                    if type(response) == "table" then
                        decoded = response
                    elseif type(response) == "string" then
                        pcall(function()
                            decoded = json.decode(response)
                        end)
                    end
                    if decoded and type(decoded) == "table" then
                        retval = GetCustomUrlFromResponse(decoded)
                    else
                        Debuger("Error response from screenshot: ", response)
                    end
                end
                finished = true
            end)
        else
            finished = true
        end
    end)
    
    if not ok then
        finished = true
    end

    local timer = 0
    while not finished and timer < 12000 do
        Wait(50)
        timer = timer + 50
    end
    
    if not finished then
        print("[origen_police] TakePhoto timed out waiting for screenshot upload")
    end
    
    return retval
end

exports("TakePhoto", TakePhoto)

function SetDimension(dimension)
    local wait = true
    FW_TriggerCallback('origen_police:SetDimension', function()
        wait = false
    end, dimension)
    while wait do
        Wait(1)
    end
end

function GetGender()
    return GetEntityModel(PlayerPedId()) == GetHashKey("mp_m_freemode_01") and "Male" or "Female"
end

function GetVehicleExtras(vehicle)
    local extras = {}

    for extraId=0, Config.ExtrasMaxCount do
        if DoesExtraExist(vehicle, extraId) then
            local state = IsVehicleExtraTurnedOn(vehicle, extraId) == 1
            extras[extraId] = state
        end
    end
    return extras
end