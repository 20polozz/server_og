Bridge = Bridge or {}
Bridge.Inventory = Bridge.Inventory or {}

local function GetInventoryType()
    if GetResourceState('origen_inventory') ~= 'missing' then return 'origen' end
    if GetResourceState('ox_inventory') ~= 'missing' then return 'ox' end
    if GetResourceState('qs-inventory') ~= 'missing' then return 'qs' end
    if GetResourceState('qb-inventory') ~= 'missing' then return 'qb' end
    return 'qb'
end

local invType = GetInventoryType()

-- ============================================================
-- GLOBAL INVENTORY BRIDGE FUNCTIONS (CLIENT)
-- ============================================================

function origenalbumcards_GetItemCount(item, metadata)
    if invType == 'origen' or invType == 'ox' then
        local result = exports.origen_inventory:Search('count', item, metadata)
        return result or 0
    elseif invType == 'qb' then
        local QBCore = exports['qb-core']:GetCoreObject()
        local count = 0
        local items = QBCore.Functions.GetPlayerData().items
        for _, v in pairs(items) do
            if v.name == item then
                -- Optional: metadata check if needed
                count = count + v.amount
            end
        end
        return count
    elseif invType == 'qs' then
        return exports['qs-inventory']:GetItemTotalAmount(item)
    end
    return 0
end

function origenalbumcards_HasItem(item, count, metadata)
    return origenalbumcards_GetItemCount(item, metadata) >= (count or 1)
end

function origenalbumcards_GetPlayerInventory()
    if invType == 'origen' or invType == 'ox' then
        return exports.origen_inventory:GetInventory()
    elseif invType == 'qb' then
        local QBCore = exports['qb-core']:GetCoreObject()
        return QBCore.Functions.GetPlayerData().items
    elseif invType == 'qs' then
        return exports['qs-inventory']:getUserInventory()
    end
    return {}
end

-- Map internal Bridge to Global functions
Bridge.Inventory.GetItemCount = origenalbumcards_GetItemCount
Bridge.Inventory.HasItem = origenalbumcards_HasItem
Bridge.Inventory.GetPlayerInventory = origenalbumcards_GetPlayerInventory
