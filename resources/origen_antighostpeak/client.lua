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

function RayCastGamePlayWeapon(weapon, distance, flag, ped)
    local cameraRotation = GetGameplayCamRot()
    local weapCoord = GetEntityCoords(weapon)
    local cameraCoord = GetGameplayCamCoord()
	local direction = RotationToDirection(cameraRotation)
	
	-- The destination should be projected from the camera forward
	local destination =  vector3(cameraCoord.x + direction.x * distance, 
		cameraCoord.y + direction.y * distance, 
		cameraCoord.z + direction.z * distance 
    )
    
	-- 17 evaluates IntersectMapObjects + IntersectPeds/Vehicles
	local a, hit, coords, surface, entityHit = GetShapeTestResult(StartShapeTestRay(weapCoord.x, weapCoord.y, weapCoord.z, destination.x, destination.y, destination.z, flag or 17, ped, 1))
	return hit, coords, entityHit, destination
end

function RayCastGamePlayCamera(distance, flag, ped)
    local cameraRotation = GetGameplayCamRot()
    local cameraCoord = GetGameplayCamCoord()
	local direction = RotationToDirection(cameraRotation)
	
	local destination =  vector3(cameraCoord.x + direction.x * distance, 
		cameraCoord.y + direction.y * distance, 
		cameraCoord.z + direction.z * distance 
    )

	local a, hit, coords, surface, entityHit = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, flag or 17, ped, 1))
	return hit, coords, entityHit, destination
end

CreateThread(function()
    while true do
        local sleep = 500 
        local ped = PlayerPedId()
        local weapon = GetCurrentPedWeaponEntityIndex(ped)
        
        if weapon > 0 and IsPlayerFreeAiming(PlayerId()) and not IsPedInAnyVehicle(ped, false) then
            sleep = 0
            
            -- We ignore 'ped', using 17 to intersect world and entities
            local hitC, coordsC, entityC, destC = RayCastGamePlayCamera(100.0, 17, ped)
            
            -- Tracing from the weapon to a decent distance towards camera aiming point
            local hitW, coordsW, entityW, destW = RayCastGamePlayWeapon(weapon, 100.0, 17, ped)
            
            -- If weapon hits something, but it's not what the camera hit, and the points are misaligned...
            if hitW > 0 then
                -- Compare proper distance between the two impact points!
                local dist = #(coordsW - coordsC)
                
                -- Usually, if difference is more than 1.5 - 2.0 meters, it's ghost peaking
                -- Also we must check if weapon hit something really close to the player, which is typically a wall they are hiding behind.
                local distToImpact = #(GetEntityCoords(ped) - coordsW)
                
                if dist > 2.0 and distToImpact < 3.0 then
                    if Config.All['displaytext'] then 
                        Draw3DText(coordsW.x, coordsW.y, coordsW.z, Config.All['text'])
                    end
                    DisablePlayerFiring(ped, true) 
                    DisableControlAction(0, 106, true) 
                end
            end
        else
            Wait(1000)
        end    
        Wait(sleep)
    end
end)

function Draw3DText(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x,y,z)
    if onScreen then
        SetTextScale(0.3, 0.3)
        SetTextFont(0)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end
