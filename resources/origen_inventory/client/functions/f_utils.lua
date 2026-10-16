local StartShapeTestLosProbe = StartShapeTestLosProbe
local GetShapeTestResultIncludingMaterial = GetShapeTestResultIncludingMaterial
local glm_sincos = require 'glm'.sincos
local glm_rad = require 'glm'.rad
local math_abs = math.abs
local math_floor = math.floor
local math_sqrt = math.sqrt
local math_pi = math.pi
local math_cos = math.cos
local math_sin = math.sin
local GetFinalRenderedCamCoord = GetFinalRenderedCamCoord
local GetFinalRenderedCamRot = GetFinalRenderedCamRot
local GetScreenCoordFromWorldCoord = GetScreenCoordFromWorldCoord
local string_format = string.format
local PlayerPedId = PlayerPedId

local function vectorMagnitude(vector)
    return math_sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
end

local function normalizeVector(vector)
    local mag = vectorMagnitude(vector)
    if mag == 0 then return vec3(0, 0, 0) end
    return vec3(vector.x / mag, vector.y / mag, vector.z / mag)
end

local function degreesToRadians(degrees)
    return degrees * (math_pi / 180.0)
end

local function rotationToDirection(camRotation)
    local sin, cos = glm_sincos(glm_rad(camRotation))
    local absCosX = math_abs(cos.x)
    return vec3(-sin.z * absCosX, cos.z * absCosX, sin.x)
end

local function worldToScreen(worldPos)
    local success, screenX, screenY = GetScreenCoordFromWorldCoord(worldPos.x, worldPos.y, worldPos.z)
    return success, vec2(screenX, screenY)
end

local function screenToWorld(camPos, camRot, screenCoord)
    local camForward = rotationToDirection(camRot)
    local rotUp = camRot + vec3(10, 0, 0)
    local rotDown = camRot + vec3(-10, 0, 0)
    local rotLeft = camRot + vec3(0, 0, -10)
    local rotRight = camRot + vec3(0, 0, 10)

    local camRight = rotationToDirection(rotRight) - rotationToDirection(rotLeft)
    local camUp = rotationToDirection(rotUp) - rotationToDirection(rotDown)

    local rollRad = -degreesToRadians(camRot.y)

    local camRightRoll = camRight * math_cos(rollRad) - camUp * math_sin(rollRad)
    local camUpRoll = camRight * math_sin(rollRad) + camUp * math_cos(rollRad)

    local point3D = camPos + camForward * 10.0 + camRightRoll + camUpRoll
    local success, point2D = worldToScreen(point3D)
    if not success then return camPos + camForward * 10.0 end

    local point3DZero = camPos + camForward * 10.0
    local success2, point2DZero = worldToScreen(point3DZero)
    if not success2 then return camPos + camForward * 10.0 end

    local epsilon = 0.001
    if math_abs(point2D.x - point2DZero.x) < epsilon 
    or math_abs(point2D.y - point2DZero.y) < epsilon then
        return camPos + camForward * 10.0
    end

    local scaleX = (screenCoord.x - point2DZero.x) / (point2D.x - point2DZero.x)
    local scaleY = (screenCoord.y - point2DZero.y) / (point2D.y - point2DZero.y)
    return camPos + camForward * 10.0 + camRightRoll * scaleX + camUpRoll * scaleY
end

local function castRay(startPos, endPos, flags, ignoreEntity)
    local handle = StartShapeTestLosProbe(
        startPos.x, startPos.y, startPos.z,
        endPos.x, endPos.y, endPos.z,
        flags or -1, PlayerPedId(), ignoreEntity or 4
    )

    while true do
        Wait(0)
        local retval, hit, endCoords, surfaceNormal, material, entityHit = GetShapeTestResultIncludingMaterial(handle)
        if retval ~= 1 then
            return hit, entityHit, endCoords, surfaceNormal, material
        end
    end
end

function RaycastFromScreen(screenCoord, camPos, camRot)
    local giveDistance = Config.Player.GiveDistance
    local camPerspective = GetFollowPedCamViewMode()
    if camPerspective > 0 and camPerspective < 4 then
        giveDistance = giveDistance * 2
    end
    local raycastEndDistance = giveDistance + (0.5)
    local raycastStartOffset = 1.0

    local targetWorldPos = screenToWorld(camPos, camRot, screenCoord)
    local sourceWorldPos = camPos

    local direction = targetWorldPos - sourceWorldPos
    direction = normalizeVector(direction)

    local hit, entityHit, endCoords, surfaceNormal, material = castRay(
        sourceWorldPos + direction * raycastStartOffset,
        sourceWorldPos + direction * raycastEndDistance
    )

    return hit, entityHit, endCoords
end