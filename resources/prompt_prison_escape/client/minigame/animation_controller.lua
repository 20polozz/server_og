local AnimationController = {}
AnimationController.__index = AnimationController

local SCREW_ANIMS = {
    "jail_work_left_up",
    "jail_work_left_down",
    "jail_work_right_up",
    "jail_work_right_down",
}

local ANIM_DICT = 'prompt@jail'

---@param ped number Ped handle
---@return table
function AnimationController.new(ped)
    local self = setmetatable({}, AnimationController)
    self.ped = ped
    self.currentAnim = nil
    self.animSpeed = 1.0
    return self
end

---@param screwIndex number
function AnimationController:playScrewAnim(screwIndex)
    local animName = SCREW_ANIMS[screwIndex]
    if not animName then return end

    self.currentAnim = animName
    lib.playAnim(self.ped, ANIM_DICT, animName, 8.0, -8.0, -1, 2)
end

---@param speed number
function AnimationController:setSpeed(speed)
    if not self.currentAnim then return end

    self.animSpeed = speed
    SetEntityAnimSpeed(self.ped, ANIM_DICT, self.currentAnim, speed)
end

---@return number
function AnimationController:getCurrentTime()
    if not self.currentAnim then return 0.0 end
    return GetEntityAnimCurrentTime(self.ped, ANIM_DICT, self.currentAnim)
end

---@param startTime number
---@param endTime number
---@return boolean
function AnimationController:isInTimeRange(startTime, endTime)
    local currentTime = self:getCurrentTime()
    return currentTime >= startTime and currentTime <= endTime
end

function AnimationController:stop()
    ClearPedTasks(self.ped)
    self.currentAnim = nil
end

return AnimationController
