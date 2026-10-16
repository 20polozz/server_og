--[[
    Origen Inventory - Advanced Crafting System
    Modular crafting zone management with WorldPointManager integration
    Author: Origen Development Team
]]

-- ===============================================
-- CRAFTING SYSTEM CLASS
-- ===============================================

---@class CraftingSystem
---@field instances table<string, table>
---@field isInitialized boolean
---@field _recipeCache table<string, table>
local CraftingSystem = {}
CraftingSystem.__index = CraftingSystem

--- Crea una nueva instancia de CraftingSystem
---@return CraftingSystem
function CraftingSystem:new()
    return setmetatable({
        instances = {},
        isInitialized = false,
        _recipeCache = {}
    }, self)
end

-- ===============================================
-- UTILIDADES
-- ===============================================

local Utils = {
    _recipeCache = {}
}

--- Valida la estructura de datos de una zona
---@param zoneName string
---@param zoneData table
---@return boolean valid, string? error
function Utils.validateZoneData(zoneName, zoneData)
    if type(zoneName) ~= 'string' or zoneName == '' then
        return false, 'Invalid zone name'
    end
    if type(zoneData) ~= 'table' then
        return false, 'Invalid zone data structure'
    end
    if not zoneData.locations then
        return false, 'Missing zone locations'
    end
    if type(zoneData.items) ~= 'table' then
        return false, 'Missing or invalid items configuration'
    end
    return true
end

--- Formatea las recetas a partir de los ítems configurados
---@param items table
---@return table
function Utils.formatRecipes(items)
    if type(items) ~= 'table' then return {} end

    local formattedRecipes, slot = {}, 1

    for itemName, itemData in pairs(Config.Crafting.items or {}) do
        for _, allowedItem in ipairs(items) do
            if itemName ~= allowedItem then goto continue end

            local resultItem = itemData.resultItem or itemName
            local resultCount = itemData.resultCount or 1

            if not resultItem or resultItem == '' or not Items(resultItem) then
                debugger('CraftingSystem: Invalid or missing result item:', resultItem)
                goto continue
            end

            local itemInfo = Items(resultItem)
            if not itemInfo then
                debugger('CraftingSystem: Item info missing for:', resultItem)
                goto continue
            end

            local recipe = {
                name = resultItem,
                duration = (itemData.time or 5000) / 1000,
                count = resultCount,
                internalName = itemName,
                slot = slot,
                ingredients = {}
            }

            if itemData.ingredients then
                local valid = true
                for ingredientName, amount in pairs(itemData.ingredients) do
                    if not Items(ingredientName) then
                        debugger('CraftingSystem: Ingredient not found:', ingredientName)
                        valid = false
                        break
                    end
                    recipe.ingredients[ingredientName] = amount
                end
                if not valid then goto continue end
            end

            table.insert(formattedRecipes, recipe)
            slot = slot + 1

            ::continue::
        end
    end

    Utils.logDebug('Formatted recipes', 'batch', ('count: %d'):format(#formattedRecipes))
    return formattedRecipes
end

--- Obtiene recetas desde caché o las genera si no existen
---@param zoneName string
---@param items table
---@return table
function Utils.getCachedRecipes(zoneName, items)
    if not Utils._recipeCache[zoneName] then
        Utils._recipeCache[zoneName] = Utils.formatRecipes(items)
    end
    return Utils._recipeCache[zoneName]
end

--- Registra un mensaje de depuración
---@param action string
---@param zoneName string
---@param details? any
function Utils.logDebug(action, zoneName, details)
    if GetConvar('origen_debug', 'false') ~= 'true' then return end
    local msg = ('[CraftingSystem] %s: %s'):format(action, zoneName)
    if details then msg = msg .. (' | %s'):format(tostring(details)) end
    print(msg)
end

-- ===============================================
-- COMPATIBILIDAD RETROACTIVA
-- ===============================================

Crafting = {
    formatItems = Utils.formatRecipes,
    Utils = Utils,
    getCachedRecipes = Utils.getCachedRecipes
}
