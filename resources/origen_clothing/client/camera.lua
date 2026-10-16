CurrentCameraZone = "whole"
local currentCamera = nil
local currentCameraPed = nil
local blendingHeading = false

function StartCamera(waitToEnd, overridePed)
    currentCameraPed = overridePed or PlayerPedId()
    if DoesCamExist(currentCamera) then
        DestroyCam(currentCamera, false)
    end
    currentCamera = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)

    SetCamCoord(currentCamera, GetPedBoneCoords(currentCameraPed, Config.CameraZones.whole.boneId, Config.CameraZones.whole.camOffset.x, Config.CameraZones.whole.camOffset.y, Config.CameraZones.whole.camOffset.z).xyz)
    SetCamRot(currentCamera, 0.0, 0.0, 0.0, 2)
    SetCamFov(currentCamera, Config.CameraZones.whole.fov)
    SetCamActive(currentCamera, true)
    PointCamAtCoord(currentCamera, GetPedBoneCoords(currentCameraPed, Config.CameraZones.whole.boneId, Config.CameraZones.whole.targetOffset.x, Config.CameraZones.whole.targetOffset.y, Config.CameraZones.whole.targetOffset.z).xyz)
    if waitToEnd then Wait(700) end
    RenderScriptCams(true, true, 700, true, true)
end

function GetPedCamera()
    return currentCameraPed or PlayerPedId()
end

local function getGenderHeight(zone)
    local headPosition = GetWorldPositionOfEntityBone(currentCameraPed, GetPedBoneIndex(currentCameraPed, 0x796E))
    local difference = (headPosition.z - GetEntityCoords(currentCameraPed).z) - 0.62
    if GetPedConfigFlag(currentCameraPed, 322) then
        debugger("Overwrite heels height")
        difference = 0.1
    end
    return Config.CameraZones[zone].camOffset.x + difference, Config.CameraZones[zone].targetOffset.x + difference
end

function MoveCamera(zone, onlyIfDifferent)
    -- if MenuType == "creation" and GetCreationTeleport() then
    --     if blendingHeading then return end
    --     blendingHeading = true
    --     while true do
    --         local currentHeading = GetEntityHeading(currentCameraPed)
    --         local targetHeading = Config.CreationCoords.w
    --         local headingDiff = targetHeading - currentHeading

    --         if NearlyEqual(currentHeading, Config.CreationCoords.w, 0.5) then
    --             blendingHeading = false
    --             break
    --         end
    --         if headingDiff > 180 then
    --             headingDiff = headingDiff - 360
    --         elseif headingDiff < -180 then
    --             headingDiff = headingDiff + 360
    --         end
            
    --         local lerpFactor = 0.05
    --         local newHeading = currentHeading + (headingDiff * lerpFactor)
            
    --         SetEntityHeading(currentCameraPed, newHeading)
            
    --         Wait(0)
    --     end
    -- end
    if onlyIfDifferent and zone == CurrentCameraZone then return end
    debugger("MOVE TO: ", zone)
    CurrentCameraZone = zone
    local camData = Config.CameraZones[zone]
    if not camData then
        debugger("Invalid camera zone: " .. zone)
        return
    end
    local offsetHeight, targetHeight = getGenderHeight(zone)

    local currentCameraCoords = GetCamCoord(currentCamera)
    local targetCoords = GetPedBoneCoords(currentCameraPed, camData.boneId, offsetHeight, camData.camOffset.y, camData.camOffset.z).xyz

    -- We should detect if the camera transition is going to hit the ped so we can show a fade out to not show the camera going through the ped
    -- The rays are not working as expected and never hit the ped, so we can leave this for later I guess
    -- local hit, entityHit, endCoords, surfaceNormal, materialHash = lib.raycast.fromCoords(currentCameraCoords, targetCoords, 511, 4)


    local newcam = CreateCamWithParams(
		'DEFAULT_SCRIPTED_CAMERA',
		targetCoords,
		0.0,
		0.0,
		0.0,
		camData.fov,
		false,
		0
	)
    PointCamAtCoord(newcam, GetPedBoneCoords(currentCameraPed, camData.boneId, targetHeight, camData.targetOffset.y, camData.targetOffset.z).xyz)
    SetCamUseShallowDofMode(newcam, true)
    SetCamNearDof(newcam, 0.2)
    SetCamFarDof(newcam, 1.0)
    SetCamDofStrength(newcam, 1.0)

    SetCamActiveWithInterp(newcam, currentCamera, 700, 1, 1)
    
    -- Destroy the old camera after transition
    local oldCamera = currentCamera
    currentCamera = newcam
    
    Citizen.CreateThread(function()
        Wait(700) -- Wait for transition to complete
        if DoesCamExist(oldCamera) then
            SetCamActive(oldCamera, false)
            DestroyCam(oldCamera, false)
        end
    end)
    
    Citizen.CreateThread(function()
        while DoesCamExist(newcam) and CurrentCameraZone == zone do
            SetUseHiDof()
            -- UpdateOrbitalCamera()
            Citizen.Wait(0)
        end
        debugger("HiDof finished")
    end)
    currentCamera = newcam
end

function StopCamera()
    debugger("Stop camera")
    
    -- blendingHeading = false
    
    if currentCamera and DoesCamExist(currentCamera) then
        debugger("Destroy camera")
        SetCamActive(currentCamera, false)
        DestroyCam(currentCamera, false)
    end
    
    currentCamera = nil
    currentCameraPed = nil
    
    RenderScriptCams(false, true, 500, true, true)
    
    Citizen.CreateThread(function()
        Wait(600)
        RenderScriptCams(false, false, 0, true, true)
        
        if DoesEntityExist(PlayerPedId()) then
            local playerCoords = GetEntityCoords(PlayerPedId())
            RequestCollisionAtCoord(playerCoords.x, playerCoords.y, playerCoords.z)
            
            SetFocusEntity(PlayerPedId())
        end
    end)
    
    CurrentCameraZone = "whole" -- Reset to default zone
end

local targetFov = nil
local isZooming = false

function ZoomCamera(direction)
    if not currentCamera or not DoesCamExist(currentCamera) then return end

    local currentFov = GetCamFov(currentCamera)
    local zoomStep = 5.0

    local baseFov = targetFov or currentFov

    if direction == "up" then
        targetFov = math.max(10.0, baseFov - zoomStep)
    elseif direction == "down" then
        targetFov = math.min(100.0, baseFov + zoomStep)
    else
        return
    end

    if isZooming then return end
    isZooming = true

    Citizen.CreateThread(function()
        local fov = GetCamFov(currentCamera)
        while math.abs(fov - targetFov) > 0.5 do
            fov = fov + (targetFov - fov) * 0.35
            SetCamFov(currentCamera, fov)
            Citizen.Wait(16)
        end
        SetCamFov(currentCamera, targetFov)
        isZooming = false
    end)
end

function AddCameraHeight(height)
    if not currentCamera or not DoesCamExist(currentCamera) then return end
    if not currentCameraPed or not DoesEntityExist(currentCameraPed) then return end

    local camCoords = GetCamCoord(currentCamera)
    local playerCoords = GetEntityCoords(currentCameraPed)
    local playerHeight = playerCoords.z
    local newHeight = camCoords.z + height
    newHeight = Clamp(newHeight, playerHeight - 0.8, playerHeight + 0.8)
    
    SetCamCoord(currentCamera, camCoords.x, camCoords.y, newHeight)
    StopCamPointing(currentCamera)
end

function ForceCleanupCameraSystem()
    debugger("Force cleanup camera system")
    
    blendingHeading = false
    
    if currentCamera and DoesCamExist(currentCamera) then
        SetCamActive(currentCamera, false)
        DestroyCam(currentCamera, false)
    end
    
    currentCamera = nil
    currentCameraPed = nil
    CurrentCameraZone = "whole"
    targetFov = nil
    isZooming = false
    
    RenderScriptCams(false, false, 0, true, true)
    
    Citizen.CreateThread(function()
        Wait(100)
        local playerPed = PlayerPedId()
        if DoesEntityExist(playerPed) then
            local playerCoords = GetEntityCoords(playerPed)
            
            RequestCollisionAtCoord(playerCoords.x, playerCoords.y, playerCoords.z)
            
            SetFocusEntity(playerPed)
            ClearFocus()
            
            for x = -50, 50, 25 do
                for y = -50, 50, 25 do
                    RequestCollisionAtCoord(playerCoords.x + x, playerCoords.y + y, playerCoords.z)
                end
            end
        end
    end)
end