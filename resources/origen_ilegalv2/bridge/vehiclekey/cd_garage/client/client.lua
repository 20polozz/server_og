---@diagnostic disable: duplicate-set-field
local resourceName = "cd_garage"
local configValue = BridgeConfig.VehicleKey
if (configValue == "auto" and GetResourceState(resourceName) ~= "started") or (configValue ~= "auto" and configValue ~= resourceName) then return end

VehicleKey = VehicleKey or {}

---Gives the player (self) the keys of the specified vehicle.
---@param vehicle number The vehicle entity handle.
---@param plate? string The plate of the vehicle.
---@return nil
VehicleKey.GiveKeys = function(vehicle, plate)
    assert(vehicle, "vehicle is nil")
    assert(DoesEntityExist(vehicle), "vehicle does not exist")

    if not plate then
        plate = GetVehicleNumberPlateText(vehicle)
    end

    TriggerEvent('cd_garage:AddKeys', plate)
end

---Removes the keys of the specified vehicle from the player (self).
---@param vehicle number The vehicle entity handle.
---@param plate? string The plate of the vehicle.
---@return boolean false — cd_garage does not support removing keys
VehicleKey.RemoveKeys = function(vehicle, plate)
    return false
end

VehicleKey.GetResourceName = function()
    return resourceName
end
