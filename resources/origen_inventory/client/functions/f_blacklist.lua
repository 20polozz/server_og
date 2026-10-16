---@diagnostic disable: missing-fields
-- Client Blacklist System

local BlacklistedItems = {}

-- Fetch blacklisted items from server
local function fetchBlacklistedItems()
    Bridge.TriggerCallback('origen_inventory:getBlacklistedItems', function(items)
        if items and type(items) == 'table' then
            BlacklistedItems = {}
            for _, itemName in pairs(items) do
                if itemName:match('weapon_') then
                    itemName = string.upper(itemName)
                end
                BlacklistedItems[itemName] = true
            end
            -- Sin print: volcaba la lista negra entera en la consola del
            -- cliente cada vez que se actualiza.

            -- Trigger NUI update
            SendNUIMessage({
                action = 'updateBlacklist',
                blacklistedItems = BlacklistedItems
            })
        end
    end)
end

-- Check if an item is blacklisted for the player
function IsItemBlacklisted(itemName)
    if not itemName then return false end
    return BlacklistedItems[itemName] == true
end

-- Refresh blacklist (called when blacklist changes on server)
RegisterNetEvent('origen_inventory:client:refreshBlacklist', function()
    -- Sin print: es la pareja del de arriba, y se escribia en cada refresco.
    fetchBlacklistedItems()
end)

-- Initial fetch on resource start
CreateThread(function()
    Wait(1000)
    Inventory.__Internal_AddTask("onJobUpdate", function()
        Wait(500)
        fetchBlacklistedItems()
    end)

    Wait(1000) -- Wait for player to load
    fetchBlacklistedItems()
end)


-- Export for other scripts
exports('IsItemBlacklisted', IsItemBlacklisted)
