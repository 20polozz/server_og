Bridge.CanOpenShop = function(id)
    return true
end




-- A list of peds that can be use custom clothes
--[[
Example:
Bridge.CustomPeds = {
    miCustomPedName = 'Male',
    miOtherPed = 'Female',
}
]]
Bridge.CustomPeds = {}


---- If you want disable parachute inventory item, just DELETE this function and event. (Just its a fastly way to use parachute)
local function equipParachuteAnim()
    loadAnimDict('clothingshirt')
    TaskPlayAnim(PlayerPedId(), 'clothingshirt', 'try_shirt_positive_d', 8.0, 1.0, -1, 49, 0, false, false, false)
end

RegisterNetEvent('consumables:client:UseParachute', function()
    equipParachuteAnim()
    InventoryUI.Notify('remove', "Parachute")
    GiveWeaponToPed(PlayerPedId(), `GADGET_PARACHUTE`, 1, false, false)

    Wait(1000)
    ClearPedTasks(PlayerPedId())
end)