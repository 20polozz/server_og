Freecam = {
    active = false,
    cam = nil,
    maxDistance = 0,

    hide = false,

    position = vector3(0.0, 0.0, 0.0),
    rotation = vector3(0.0, 0.0, 0.0),

    restrictedZone = nil,

    speed = 0.3,
}

function Freecam:new(data)
    data = data or {}
    setmetatable(data, self)
    self.__index = self
    return data
end

function Freecam:CreateCam(hide, distance, height, zone)

    if self.active then return end

    local x, y, z = table.unpack(GetGameplayCamCoord())
    local pitch, roll, yaw = table.unpack(GetGameplayCamRot(2))
    local fov = GetGameplayCamFov()

    self.cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)

    self.active = true
    self.hide = hide or false
    self.maxDistance = distance or 100
    if zone then self.restrictedZone = zone end

    SetCamCoord(self.cam, x, y, z + height or 10.0)
    SetCamRot(self.cam, pitch, roll, yaw, 2)
    SetCamFov(self.cam, fov)

    RenderScriptCams(true, true, 500, true, true)
    FreezeEntityPosition(cache.ped, true)

    -- Custom.OnFreecam(true)

    CreateThread(function()
        while DoesCamExist(self.cam) and self.active do
        if self.hide then
            SetEntityLocallyInvisible(cache.ped, true)
        end

        DisableControls({24, 25, 47, 58, 69, 70, 92, 114, 135, 140, 141, 142, 143, 199, 200, 202, 257, 263, 264, 331})

        self:Controls()

        TriggerEvent('freecam:onTick')
        Wait(0)
        end
    end)
end

function Freecam:Controls()
    local newX
    local rAxisX = GetControlNormal(0, 220)
    local rAxisY = GetControlNormal(0, 221)
    local rotation = GetCamRot(self.cam, 2)

    local yValue = rAxisY * 5
    local newXval = rotation.x - yValue
    if (newXval >= -89.0) and (newXval <= 89.0) then
        newX = newXval
    elseif newXval < -89.0 then
        newX = -89.0
    elseif newXval > 89.0 then
        newX = 89.0
    end

    local newZ = rotation.z + (rAxisX * -10)

    if newZ < 0 then
        newZ = newZ + 360
    elseif newZ > 360 then
        newZ = newZ - 360
    end

    if newX ~= nil then
        self.rotation = vector3(newX, 0.0, newZ)
        SetCamRot(self.cam, self.rotation, 2)
    end

    local x, y, z = table.unpack(GetCamCoord(self.cam))
    local pitch, roll, yaw = table.unpack(GetCamRot(self.cam, 2))

    local dx = math.sin(-yaw * math.pi / 180) * self.speed
    local dy = math.cos(-yaw * math.pi / 180) * self.speed
    local dz = math.tan(pitch * math.pi / 180) * self.speed

    local dx2 = math.sin(math.floor(yaw + 90.0) % 360 * -1.0 * math.pi / 180) * self.speed
    local dy2 = math.cos(math.floor(yaw + 90.0) % 360 * -1.0 * math.pi / 180) * self.speed

    if IsControlPressed(0, 32) then
        x = x + dx
        y = y + dy
    elseif IsControlPressed(0, 33) then
        x = x - dx
        y = y - dy
    end

    if IsControlPressed(0, 35) then
        x = x - dx2
        y = y - dy2
    elseif IsControlPressed(0, 34) then
        x = x + dx2
        y = y + dy2
    end

    if IsControlPressed(0, 44) then
        z = z + self.speed
    elseif IsControlPressed(0, 46) then
        z = z - self.speed
    end

    if IsControlPressed(0, 181) then
        self.speed = self.speed + 0.1
        if self.speed >= 0.3 then
            self.speed = 0.3
        end
    elseif IsControlPressed(0, 180) then
        self.speed = self.speed - 0.1

        if self.speed <= 0.1 then 
            self.speed = 0.1
        end
    end

    if self.restrictedZone then
        --[[ local isInside = Utils.isInsidePolyzone(vector3(x, y, z), self.restrictedZone)
        if isInside then
            self.position = vector3(x, y, z)
            SetCamCoord(self.cam, x, y, z)
        end ]]
    else
        local playercoords = GetEntityCoords(cache.ped)
        if #(playercoords - vector3(x, y, z)) <= self.maxDistance then
            self.position = vector3(x, y, z)
            SetCamCoord(self.cam, x, y, z)
        end
    end
end

function Freecam:DestroyCam()
    FreezeEntityPosition(cache.ped, false)
    RenderScriptCams(false, true, 500, true, true)
    SetCamActive(self.cam, false)
    DetachCam(self.cam)
    DestroyCam(self.cam, true)
    -- Custom.OnFreecam(false)
    self.active = false
    self.restrictedZone = nil
    self.speed = 0.2
end

function Freecam:GetPosition()
    return self.position
end

function Freecam:GetRotation()
    return self.rotation
end