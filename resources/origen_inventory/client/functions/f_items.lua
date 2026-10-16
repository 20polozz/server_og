---@deprecated Use exports.origen_inventory:HasItem instead
function HasItem(item, amount)
    if not item then return false end
    if not amount then amount = 1 end

    Wait(0)
    local p = promise.new()
    
    Bridge.TriggerCallback('inventory:server:HasItem', function(result)
        p:resolve(result)
    end, item, amount)
    
    return Citizen.Await(p)
end

exportsQB('HasItem', HasItem)
exports('HasItem', HasItem)


RegisterNetEvent('origen_inventory:client:executeItemFunctions', function(itemName, total)
    local item = Items(itemName)
    if not item then return end

    if not item.client then return end

    if item.client.add then
        item.client.add(total)
    end

    if item.client.add then
        item.client.remove(total)
    end
end)

RegisterNetEvent('inventory:client:qs-smartphone-pro:itemAdded', function()
    TriggerServerEvent('phone:itemAdd')
end)