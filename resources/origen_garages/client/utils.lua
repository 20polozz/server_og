local glm_sincos = require 'glm'.sincos
local glm_rad = require 'glm'.rad
local math_abs = math.abs
local math_pi = math.pi

Utils.DisableControls = function(controls, cursor)
    if not controls then return end

    for i = 1, #controls do
        DisableControlAction(2, controls[i], true)
    end
    DisablePlayerFiring(PlayerId(), true)

    if cursor then
        SetMouseCursorActiveThisFrame()
    end
end

-- Furniture utils

local function rotationToDirection(camRotation)
    local sin, cos = glm_sincos(glm_rad(camRotation))
    local absCosX = math_abs(cos.x)
    return vec3(-sin.z * absCosX, cos.z * absCosX, sin.x)
end

local function RayCastGamePlayCamera(distance, camCoords, camRot)
    local cameraRotation = camRot or GetGameplayCamRot()
    local cameraCoord = camCoords or GetGameplayCamCoord()
    local direction = rotationToDirection(cameraRotation)
    local destination =
    {
        x = cameraCoord.x + direction.x * distance,
        y = cameraCoord.y + direction.y * distance,
        z = cameraCoord.z + direction.z * distance
    }
    local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0))
    return b, c, e
end

local function World3DToScreen2D(pos)
    local _, sX, sY = GetScreenCoordFromWorldCoord(pos.x, pos.y, pos.z)
    return vector2(sX, sY)
end

local function ScreenRelToWorld(camPos, camRot, cursor)
    local camForward = rotationToDirection(camRot)
    local rotUp = vector3(camRot.x + 1.0, camRot.y, camRot.z)
    local rotDown = vector3(camRot.x - 1.0, camRot.y, camRot.z)
    local rotLeft = vector3(camRot.x, camRot.y, camRot.z - 1.0)
    local rotRight = vector3(camRot.x, camRot.y, camRot.z + 1.0)
    local camRight = rotationToDirection(rotRight) - rotationToDirection(rotLeft)
    local camUp = rotationToDirection(rotUp) - rotationToDirection(rotDown)
    local rollRad = -(camRot.y * math.pi / 180.0)
    local camRightRoll = camRight * math.cos(rollRad) - camUp * math.sin(rollRad)
    local camUpRoll = camRight * math.sin(rollRad) + camUp * math.cos(rollRad)
    local point3DZero = camPos + camForward * 1.0
    local point3D = point3DZero + camRightRoll + camUpRoll
    local point2D = World3DToScreen2D(point3D)
    local point2DZero = World3DToScreen2D(point3DZero)
    local scaleX = (cursor.x - point2DZero.x) / (point2D.x - point2DZero.x)
    local scaleY = (cursor.y - point2DZero.y) / (point2D.y - point2DZero.y)
    local point3Dret = point3DZero + camRightRoll * scaleX + camUpRoll * scaleY
    local forwardDir = camForward + camRightRoll * scaleX + camUpRoll * scaleY
    return point3Dret, forwardDir
end

Utils.isInsidePolyzone = function(coords, polyzone)
    local x, y = coords.x, coords.y
    local inside = false
    local j = #polyzone

    for i = 1, #polyzone do
        local xi, yi = polyzone[i].x, polyzone[i].y
        local xj, yj = polyzone[j].x, polyzone[j].y

        if ((yi > y) ~= (yj > y)) and (x < (xj - xi) * (y - yi) / (yj - yi) + xi) then
            inside = not inside
        end
        
        j = i
    end

    return inside
end

Utils.IsClearAhead = function(distance)
    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    local forwardVector = GetEntityForwardVector(ped)

    local endCoords = vector3(
        pedCoords.x + forwardVector.x * distance,
        pedCoords.y + forwardVector.y * distance,
        pedCoords.z + forwardVector.z * distance
    )

    local rayHandle = StartShapeTestRay(pedCoords.x, pedCoords.y, pedCoords.z, endCoords.x, endCoords.y, endCoords.z, 1, ped, 0)
    local _, hit, _, _, _ = GetShapeTestResult(rayHandle)
    
    return hit == 1
end

Utils.GetEntityOnScreen = function(camPos, camRot)

    local camRot = camRot or GetGameplayCamRot(0)
    local camPos = camPos or GetGameplayCamCoord()
    local posX = GetControlNormal(0, 239)
    local posY = GetControlNormal(0, 240)
    local cursor = vector2(posX, posY)
    local cam3DPos, forwardDir = ScreenRelToWorld(camPos, camRot, cursor)
    local direction = camPos + forwardDir * 500.0
    local rayHandle = StartExpensiveSynchronousShapeTestLosProbe(cam3DPos, direction, 1, 0, 0)
    local _, hit, _, _, entityHit = GetShapeTestResult(rayHandle)

    local rayHandle2 = StartExpensiveSynchronousShapeTestLosProbe(cam3DPos, direction, 16, 0, 0)
    local _, hit2, _, _, entityHit2 = GetShapeTestResult(rayHandle2)

    if hit2 == 1 then
        return true, entityHit2 
    elseif hit == 1 then
        return true, entityHit 
    else
        return false, -1 
    end
end

Utils.GetScreenCoords = function(distance, camCoords, camRot)
	local hit, coords, entity = RayCastGamePlayCamera(distance or 1000.0, camCoords, camRot)
    return hit, coords, entity
end

Utils.ScreenToWorld = function(camPos, camRot)
    local camRot = camRot or GetGameplayCamRot(0)
    local camPos = camPos or GetGameplayCamCoord()
    local posX = GetControlNormal(0, 239)
    local posY = GetControlNormal(0, 240)
    local cursor = vector2(posX, posY)
    local cam3DPos, forwardDir = ScreenRelToWorld(camPos, camRot, cursor)
    local direction = camPos + forwardDir * 500.0
    local rayHandle = StartExpensiveSynchronousShapeTestLosProbe(cam3DPos, direction, 1, 0, 0)
    local _, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(rayHandle)
    
    return hit, endCoords
end