-- Client Permissions — called by the core before each action for immediate UX feedback.
-- Returning false cancels the action client-side. Server-side is always the authoritative check.

GraffitiPerms = {}

-- Called at the start of activateGraffiti(), before any async operation.
-- @param coords vector3  Player position when activating the spray.
-- @return boolean
function GraffitiPerms.canPaint(coords)
    return true
end

-- Called just before entering erase mode, after the target tag is identified.
-- @param coords vector3  Center of the tag to erase.
-- @return boolean
function GraffitiPerms.canErase(coords)
    return true
end

-- Called when the player presses E near a shop point, before opening the NUI.
-- @param coords vector3  Shop location coordinates.
-- @return boolean
function GraffitiPerms.canShop(coords)
    return true
end
