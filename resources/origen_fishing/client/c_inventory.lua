local QBCore = exports['qb-core']:GetCoreObject()
Inventory = {}

Inventory.GetInventoryIcon = function(itemName)
    local url = 'https://cfx-nui-qb-inventory/html/images/%s.png'
    return (url):format(itemName)
end

Inventory.GetItem = function(itemName)
    if not QBCore or not QBCore.Shared or not QBCore.Shared.Items then
        return { label = itemName }
    end
    local Items = QBCore.Shared.Items
    return Items[itemName] or Items[itemName:upper()] or { label = itemName }
end

Inventory.HasItem = function(item)
    local pData = QBCore.Functions.GetPlayerData()
    local amount = 0
    if pData and pData.items then
        for _, v in pairs(pData.items) do
            if v.name == item then
                amount = amount + (v.amount or v.count or 1)
            end
        end
    end
    if amount > 0 then
        return true, amount
    end
    return false, 0
end