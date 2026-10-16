--[[
This feature controls whether or not you can use the vehicle's engine from the inventory (or command).

Here you can do things like:
- Check if you have keys
- Send notifications
- And whatever you want to do...

It should return 'true' if you can start the vehicle or 'false' otherwise.
]]
Bridge.CanUseEngine = function(vehicle)
    return true
end