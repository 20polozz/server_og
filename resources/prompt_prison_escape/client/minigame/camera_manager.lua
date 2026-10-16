local CameraManager = {}
CameraManager.__index = CameraManager

---@param entity number
---@return table
function CameraManager.new(entity)
    local self = setmetatable({}, CameraManager)
    self.entity = entity
    self.cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    self.isActive = false
    return self
end

---@param camOffset table
---@param smooth boolean
---@param disableEntityRot boolean?
function CameraManager:setCamera(camOffset, smooth, disableEntityRot)
    if not DoesEntityExist(self.entity) then return end

    local camPos = GetOffsetFromEntityInWorldCoords(self.entity, camOffset[1].x, camOffset[1].y, camOffset[1].z)

    local finalRotation
    if not disableEntityRot then
        local entityRot = GetEntityRotation(self.entity)
        finalRotation = vec3(
            camOffset[2].x + entityRot.x,
            camOffset[2].y + entityRot.y,
            camOffset[2].z + entityRot.z
        )
    else
        finalRotation = camOffset[2]
    end

    if smooth and self.isActive then
        local newCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        SetCamCoord(newCam, camPos.x, camPos.y, camPos.z)
        SetCamRot(newCam, finalRotation.x, finalRotation.y, finalRotation.z, 2)
        SetCamFov(newCam, 30.0)
        SetCamActive(newCam, true)
        SetCamActiveWithInterp(newCam, self.cam, duration or 1500, 1, 1)

        SetCamActive(self.cam, false)
        DestroyCam(self.cam, false)
        self.cam = newCam
    else
        SetCamCoord(self.cam, camPos.x, camPos.y, camPos.z)
        SetCamRot(self.cam, finalRotation.x, finalRotation.y, finalRotation.z, 2)
        SetCamFov(self.cam, 30.0)
        if not self.isActive then
            SetCamActive(self.cam, true)
        end
    end
end

---@param smooth boolean
---@param duration number
function CameraManager:activate(smooth, duration)
    RenderScriptCams(true, smooth or false, duration or 0, true, true)
    self.isActive = true
end

---@param smooth boolean
---@param duration number
function CameraManager:deactivate(smooth, duration)
    RenderScriptCams(false, smooth or false, duration or 0, true, true)
    self.isActive = false
end

function CameraManager:destroy()
    if self.isActive then
        self:deactivate(true, 1500)
        Wait(1500)
    end

    if self.cam then
        DestroyCam(self.cam, false)
        self.cam = nil
    end

    self.isActive = false
end

return CameraManager
