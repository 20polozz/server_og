--[[
    Origen Inventory - Unified World Point Management System
    Single modular controller for all world interaction points
    Author: Origen Development Team
]]

if not Config.WorldPoints.Enabled then
    debugger("WorldPointManager: World Points system is disabled in configuration. Skipping initialization.")
    return
end

local function table_count(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

local GetGameTimer = GetGameTimer
local Thread = CreateThread

-- ===============================================
-- MODULE CONFIGURATION & CONSTANTS
-- ===============================================

local CONFIG = {
    DEFAULT_MARKERS = Config.WorldPoints.DefaultMarkers,
    INIT_DELAYS = {
        TASK_REGISTRATION = Config.WorldPoints.Initialization.taskRegistrationDelay or 500,
        JOB_UPDATE_DELAY = Config.WorldPoints.Initialization.jobUpdateDelay or 500,
        INITIAL_LOAD = Config.WorldPoints.Initialization.initialLoadDelay or 1000
    },
    SERVER_CALLBACKS = {
        stash = 'origen_inventory:fetchCustomStashes',
        shop = 'origen_inventory:fetchShops',
        crafting = 'origen_inventory:fetchCraftingBoxes'
    }
}



-- ===============================================
-- UNIFIED WORLD POINT MANAGER
-- ===============================================

---@class WorldPointManager
---@field activePoints table<string, any>
---@field pointTypeConfigs table<string, table>
---@field isInitialized boolean
---@field _eventHandlers table<string, table>
---@field _jobUpdateTasks table<string, function[]>
---@field _loadedTypes table<string, boolean>
local WorldPointManager = {}
WorldPointManager.__index = WorldPointManager

---Create new WorldPointManager instance
---@return WorldPointManager
function WorldPointManager:new()
    local instance = setmetatable({
        activePoints = {},
        pointTypeConfigs = {},
        isInitialized = false,
        _eventHandlers = {},
        _jobUpdateTasks = {},
        _loadedTypes = {}
    }, self)


    for pType, typeData in pairs(Config.WorldPoints.PointTypes) do
        instance:registerPointType(pType, typeData)
    end

    return instance
end

-- ===============================================
-- UTILITY FUNCTIONS
-- ===============================================

local Utils = {}

---Validate point data structure
---@param pointId string
---@param pointData table
---@param pointType string
---@return boolean valid, string? error
function Utils.validatePointData(pointId, pointData, pointType)
    if not pointId or type(pointId) ~= 'string' or pointId == '' then
        return false, 'Invalid or empty point ID'
    end

    if not pointData or type(pointData) ~= 'table' then
        return false, 'Invalid point data structure'
    end

    if not pointData.coords and not pointData.position and not pointData.locations then
        return false, 'Missing coordinates (coords, position, or locations required)'
    end

    return true
end

---Normalize coordinates to consistent format
---@param coords any
---@return table
function Utils.normalizeCoords(coords)
    local coordType = type(coords)

    if coordType == 'vector3' or coordType == 'vector4' then
        return { coords }
    elseif coordType == 'table' then
        if coords.x and coords.y and coords.z then
            return { vector4(coords.x, coords.y, coords.z, coords.w or 0.0) }
        elseif #coords > 0 then
            return coords
        end
    end

    return { coords }
end

function Utils.executeAnimation(dict, anim)
    local ped = PlayerPedId()
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(0)
    end
    TaskPlayAnim(ped, dict, anim, 8.0, -8.0, 2000, 0, 0, false, false, false)
end

---Generate safe point configuration for WorldPoint.init()
---@param pointId string
---@param pointData table
---@param pointType string
---@param typeConfig table
---@return table
function Utils.buildWorldPointConfig(pointId, pointData, pointType, typeConfig)
    -- Determine coordinates
    local locations = pointData.locations or
        Utils.normalizeCoords(pointData.coords or pointData.position or pointData.locations)

    -- Build configuration that WorldPoint.init() expects
    local config = {
        id = pointId,
        type = pointType,
        locations = locations,
        groups = pointData.groups,
        jobs = pointData.jobs,
        label = pointData.label or pointData.name or ('Point: %s'):format(pointId),
        marker = pointData.marker or typeConfig.defaultMarker,
        blip = pointData.blip,
        enable = pointData.enable ~= false and pointData.enabled ~= false,
        distance = pointData.distance or pointData.distanceInteract or
            (typeConfig.defaultMarker and typeConfig.defaultMarker.distanceInteract) or 1.5,
        -- Additional properties that might be needed
        data = pointData.data or pointData or {},
        hooks = typeConfig.hooks or {
            interactIn = 'worldpoint-interact-in',
            interactOut = 'worldpoint-interact-out',
            nearby = 'worldpoint-area-nearby'
        },
        sprite = typeConfig.sprite,
        zoneDistance = typeConfig.zoneDistance,
        npc = pointData.npc or typeConfig.npc,
        prop = pointData.prop or typeConfig.prop,
        options = pointData.options or {}
    }

    return config
end

---Log debug message with context
---@param action string
---@param pointId string
---@param details? any
function Utils.logDebug(action, pointId, details)
    if Config.Debug then
        local message = ('[WorldPointManager] %s: %s'):format(action, pointId)
        if details then
            message = message .. (' | %s'):format(tostring(details))
        end
        print(message)
    end
end

-- ===============================================
-- POINT TYPE MANAGEMENT
-- ===============================================

---Register a new point type with specific configuration
---@param pointType string
---@param config table
function WorldPointManager:registerPointType(pointType, config)
    if not pointType or type(pointType) ~= 'string' then
        error('Point type must be a non-empty string')
    end

    self.pointTypeConfigs[pointType] = config or {}
    Utils.logDebug('Registered point type', pointType)
end

---Get configuration for a point type
---@param pointType string
---@return table?
function WorldPointManager:getPointTypeConfig(pointType)
    return self.pointTypeConfigs[pointType]
end

---Get all registered point types
---@return table<string, table>
function WorldPointManager:getPointTypes()
    return self.pointTypeConfigs
end

-- ===============================================
-- CORE POINT MANAGEMENT
-- ===============================================

---Create a world point with unified configuration
---@param pointId string
---@param pointData table
---@param pointType string
---@return boolean success
function WorldPointManager:createPoint(pointId, pointData, pointType)
    local isValid, error = Utils.validatePointData(pointId, pointData, pointType)
    if not isValid then
        Utils.logDebug('Creation failed', pointId, error)
        return false
    end

    -- Remove existing point if it exists
    self:removePoint(pointId)

    -- Get type configuration
    local typeConfig = self:getPointTypeConfig(pointType) or {}

    -- Build WorldPoint configuration
    local worldPointConfig = Utils.buildWorldPointConfig(pointId, pointData, pointType, typeConfig)

    -- Create WorldPoint instance
    local worldPoint = WorldPoint and WorldPoint.init(worldPointConfig)
    if not worldPoint then
        Utils.logDebug('WorldPoint creation failed', pointId)
        return false
    end

    -- Store point reference with metadata
    self.activePoints[pointId] = {
        instance = worldPoint,
        label = worldPointConfig.label,
        type = pointType,
        config = worldPointConfig,
        originalData = pointData,
        createdAt = GetGameTimer()
    }

    Utils.logDebug('Created point', pointId, pointType)
    return true
end

---Remove a specific point
---@param pointId string
---@return boolean success
function WorldPointManager:removePoint(pointId)
    local pointData = self.activePoints[pointId]
    if not pointData then
        return false
    end

    -- Safely destroy the WorldPoint instance
    if pointData.instance and pointData.instance.destroy then
        pcall(pointData.instance.destroy, pointData.instance)
    end

    self.activePoints[pointId] = nil
    Utils.logDebug('Removed point', pointId)

    TriggerEventHooks('worlpoint-onDestroy', {
        id = pointId,
        type = pointData.type,
    })

    return true
end

---Update an existing point or create if not exists
---@param pointId string
---@param pointData table
---@param pointType string
---@return boolean success
function WorldPointManager:updatePoint(pointId, pointData, pointType)
    -- If point is disabled, remove it
    if pointData.enable == false or pointData.enabled == false then
        return self:removePoint(pointId)
    end

    -- Otherwise create/update the point
    return self:createPoint(pointId, pointData, pointType)
end

---Enable or disable a specific point
---@param pointId string
---@param enabled boolean
---@return boolean success
function WorldPointManager:setPointEnabled(pointId, enabled)
    local pointData = self.activePoints[pointId]
    if not pointData or not pointData.instance then
        return false
    end

    if pointData.instance.setEnabled then
        pointData.instance:setEnabled(enabled)
        Utils.logDebug(enabled and 'Enabled' or 'Disabled', pointId)
        return true
    end

    return false
end

---Refresh a specific point
---@param pointId string
function WorldPointManager:refreshPoint(pointId)
    local pointData = self.activePoints[pointId]
    if pointData and pointData.instance and pointData.instance.refresh then
        pointData.instance:refresh()
        Utils.logDebug('Refreshed point', pointId)
    end
end

---Refresh all points or points of specific type
---@param pointType? string
function WorldPointManager:refreshAllPoints(pointType)
    local refreshCount = 0

    for pointId, pointData in pairs(self.activePoints) do
        if not pointType or pointData.type == pointType then
            if pointData.instance and pointData.instance.refresh then
                pointData.instance:refresh()
                refreshCount = refreshCount + 1
            end
        end
    end

    Utils.logDebug('Batch refresh complete',
        pointType or 'all types',
        ('refreshed: %d'):format(refreshCount))
end

---Clear all points or points of specific type
---@param pointType? string
function WorldPointManager:clearPoints(pointType)
    local clearedCount = 0

    for pointId, pointData in pairs(self.activePoints) do
        if not pointType or pointData.type == pointType then
            if self:removePoint(pointId) then
                clearedCount = clearedCount + 1
            end
        end
    end

    Utils.logDebug('Cleared points',
        pointType or 'all types',
        ('cleared: %d'):format(clearedCount))
end

-- ===============================================
-- BATCH OPERATIONS
-- ===============================================

---Create multiple points from configuration
---@param pointsData table
---@param pointType string
---@return number successCount
function WorldPointManager:createBatchPoints(pointsData, pointType)
    if not pointsData or type(pointsData) ~= 'table' then
        return 0
    end

    local successCount = 0

    for pointId, pointData in pairs(pointsData) do
        if self:createPoint(pointId, pointData, pointType) then
            successCount = successCount + 1
        end
    end

    Utils.logDebug('Batch creation complete',
        pointType or 'mixed',
        ('created: %d/%d'):format(successCount, table_count(pointsData)))
    return successCount
end

---Load points from server callback for specific type
---@param pointType string
function WorldPointManager:loadPointsFromServer(pointType)
    local typeConfig = self:getPointTypeConfig(pointType)

    if pointType == 'shop' then
        typeConfig.defaultCallback = CONFIG.SERVER_CALLBACKS.shop
    elseif pointType == 'stash' then
        typeConfig.defaultCallback = CONFIG.SERVER_CALLBACKS.stash
    elseif pointType == 'crafting' then
        typeConfig.defaultCallback = CONFIG.SERVER_CALLBACKS.crafting
    end

    if not typeConfig or not typeConfig.defaultCallback then
        Utils.logDebug('No server callback configured', pointType)
        return
    end

    Bridge.TriggerCallback(typeConfig.defaultCallback, function(serverData)
        if not serverData or not next(serverData) then
            Utils.logDebug('No data received from server', typeConfig.defaultCallback)
            return
        end

        local loadedCount = self:createBatchPoints(serverData, pointType)
        self._loadedTypes[pointType] = true
        Utils.logDebug('Server load complete', typeConfig.defaultCallback,
            ('loaded: %d points'):format(loadedCount))
    end)
end

---Load points from config for specific type
---@param pointType string
function WorldPointManager:loadPointsFromConfig(pointType)
    local typeConfig = self:getPointTypeConfig(pointType)
    if not typeConfig or not typeConfig.loadFromConfig then
        return 0
    end

    local configData = nil

    -- Load based on point type
    if pointType == 'shop' and Config and Config.Shops then
        configData = Config.Shops
    elseif pointType == 'stash' and Config and Config.Stashes then
        configData = Config.Stashes
    elseif pointType == 'crafting' and Config and Config.Crafting.zones then
        configData = Config.Crafting.zones
    end

    if not configData then
        return 0
    end


    -- Process config data
    local processedData = {}
    for id, data in pairs(configData) do
        if pointType == 'crafting' then
            Utils.logDebug('Loading crafting points from config', pointType)
            local craftingUtils = Crafting.Utils
            local isValidZone = craftingUtils.validateZoneData(id, configData)
            if not isValidZone then
                Utils.logDebug('Invalid crafting zone data in config', id)
                goto continue
            end

            local locations = Utils.normalizeCoords(data.locations)
            local recipes = craftingUtils.getCachedRecipes(id, data.items or {})

            data.locations = locations
            data.recipes = recipes
        end

        if id ~= 'default' then
            local pointData = table.clone(data)
            pointData.enabled = data.enable or data.enabled
            pointData.id = id
            processedData[id] = pointData
        end

        :: continue ::
    end

    local loadedCount = self:createBatchPoints(processedData, pointType)
    Utils.logDebug('Config load complete', pointType,
        ('loaded: %d points'):format(loadedCount))
    return loadedCount
end

-- ===============================================
-- QUERY & INFORMATION
-- ===============================================

---Get point data by ID
---@param pointId string
---@return table?
function WorldPointManager:getPoint(pointId)
    return self.activePoints[pointId]
end

---Get all points or points of specific type
---@param pointType? string
---@return table
function WorldPointManager:getPoints(pointType)
    if not pointType then
        return self.activePoints
    end

    local filteredPoints = {}
    for pointId, pointData in pairs(self.activePoints) do
        if pointData.type == pointType then
            filteredPoints[pointId] = pointData
        end
    end

    return filteredPoints
end

---Get count of active points
---@param pointType? string
---@return number
function WorldPointManager:getPointCount(pointType)
    if not pointType then
        return table_count(self.activePoints)
    end

    local count = 0
    for _, pointData in pairs(self.activePoints) do
        if pointData.type == pointType then
            count = count + 1
        end
    end

    return count
end

---Check if point exists
---@param pointId string
---@return boolean
function WorldPointManager:hasPoint(pointId)
    return self.activePoints[pointId] ~= nil
end

---Check if point type has been loaded
---@param pointType string
---@return boolean
function WorldPointManager:isTypeLoaded(pointType)
    return self._loadedTypes[pointType] == true
end

-- ===============================================
-- TYPE-SPECIFIC OPERATIONS
-- ===============================================

---Load all points for a specific type (config + server)
---@param pointType string
function WorldPointManager:loadType(pointType)
    if self:isTypeLoaded(pointType) then
        Utils.logDebug('Type already loaded', pointType)
        return
    end

    -- Load from config first
    self:loadPointsFromConfig(pointType)

    -- Then from server
    self:loadPointsFromServer(pointType)
end

---Get points by type with convenience accessors
---@param pointType string
---@return table
function WorldPointManager:getPointsByType(pointType)
    return self:getPoints(pointType)
end

-- Convenience methods for common operations
function WorldPointManager:getStashes()
    return self:getPointsByType('stash')
end

function WorldPointManager:getShops()
    return self:getPointsByType('shop')
end

function WorldPointManager:getCraftingStations()
    return self:getPointsByType('crafting')
end

function WorldPointManager:loadStashes()
    return self:loadType('stash')
end

function WorldPointManager:loadShops()
    return self:loadType('shop')
end

function WorldPointManager:loadCraftingStations()
    return self:loadType('crafting')
end

-- ===============================================
-- INITIALIZATION & LIFECYCLE
-- ===============================================

---Initialize the point management system
function WorldPointManager:initialize()
    if self.isInitialized then
        return
    end

    -- Wait for system readiness
    Wait(CONFIG.INIT_DELAYS.TASK_REGISTRATION)

    -- Register universal job update handler
    if Inventory and Inventory.__Internal_AddTask then
        Inventory.__Internal_AddTask("onJobUpdate", function()
            Wait(CONFIG.INIT_DELAYS.JOB_UPDATE_DELAY)

            -- Execute registered job update tasks for all types
            for pointType, tasks in pairs(self._jobUpdateTasks) do
                for _, task in ipairs(tasks) do
                    pcall(task)
                end
            end

            -- Refresh points that should refresh on job change
            for pointType, typeConfig in pairs(self.pointTypeConfigs) do
                if typeConfig.refreshOnJobChange then
                    self:refreshAllPoints(pointType)
                end
            end
        end)
    end

    self.isInitialized = true
    Utils.logDebug('System initialized', 'startup')
end

---Add job update task for point type
---@param pointType string
---@param task function
function WorldPointManager:addJobUpdateTask(pointType, task)
    if not self._jobUpdateTasks[pointType] then
        self._jobUpdateTasks[pointType] = {}
    end

    table.insert(self._jobUpdateTasks[pointType], task)
    Utils.logDebug('Added job update task', pointType)
end

---Cleanup system resources
function WorldPointManager:cleanup()
    self:clearPoints()
    self._eventHandlers = {}
    self._jobUpdateTasks = {}
    self._loadedTypes = {}
    self.isInitialized = false
    Utils.logDebug('System cleaned up', 'shutdown')
end

-- ===============================================
-- GLOBAL INSTANCE
-- ===============================================

-- Create single global instance
local GlobalWorldPointManager = WorldPointManager:new()

-- ===============================================
-- EVENT HANDLERS
-- ===============================================

-- Stash Events
RegisterNetEvent('origen_inventory:client:refreshOrCreateCustomStash', function(stashId, stashData)
    GlobalWorldPointManager:updatePoint(stashId, stashData, 'stash')
end)

RegisterNetEvent('origen_inventory:client:removeCustomStash', function(stashId)
    GlobalWorldPointManager:removePoint(stashId)
end)

-- Drops Events
RegisterNetEvent('origen_inventory:client:NewDrop', function(drop, ownerId)
    GlobalWorldPointManager:updatePoint(drop.id, drop, 'drop')

    if not ownerId or ownerId ~= GetPlayerServerId(PlayerId()) then return end
    Utils.executeAnimation("pickup_object", "pickup_low")
end)

RegisterNetEvent('origen_inventory:client:RemoveDrop', function(dropId)
    GlobalWorldPointManager:removePoint(dropId)
end)

-- Crafting Events
RegisterNetEvent('origen_inventory:client:refreshOrCreateCrafting', function(craftingId, craftingData)
    GlobalWorldPointManager:updatePoint(craftingId, craftingData, 'crafting')
end)

RegisterNetEvent('origen_inventory:client:removeCrafting', function(craftingId)
    GlobalWorldPointManager:removePoint(craftingId)
end)

-- Shop Events
RegisterNetEvent('origen_inventory:client:CreateShop', function(shopId, shopData)
    GlobalWorldPointManager:updatePoint(shopId, shopData, 'shop')
end)

RegisterNetEvent('origen_inventory:client:RemoveShop', function(shopId)
    GlobalWorldPointManager:removePoint(shopId)
end)

-- ===============================================
-- INITIALIZATION THREAD
-- ===============================================

CreateThread(function()

    while not Player do
        Wait(500)
    end

    -- Initialize the manager
    GlobalWorldPointManager:initialize()

    -- Load initial data
    Wait(CONFIG.INIT_DELAYS.INITIAL_LOAD)
    GlobalWorldPointManager:loadStashes()
    GlobalWorldPointManager:loadShops()
    GlobalWorldPointManager:loadCraftingStations()


    -- Setup hooks for stash points
    if exports.origen_inventory and exports.origen_inventory.registerHook then
        exports.origen_inventory:registerHook('worldpoint-interact-in', function(payload)
            Sprite.updateCrafting(false)

            if payload.type == 'drop' then
                Player:setActiveDrop(payload)
            end

            if payload.sprite and not payload.options.hideSprite then
                Sprite.loadDict()
                Sprite.update(payload.sprite.icon)

                if payload.type == 'crafting' then
                    if payload.sprite.showCraftingPanel and not payload.options.hideCraftingPanel then
                        TriggerServerEvent('origen_inventory:server:playerJoinCraftingZone', payload.id)
                        Sprite.updateCraftingSprite(payload.id)
                    end
                end
            end
        end)

        exports.origen_inventory:registerHook('worldpoint-interact-out', function(payload)
            if payload.sprite then
                Sprite.unload()

                if payload.type == 'crafting' then
                    if payload.sprite?.showCraftingPanel and not payload.options.hideCraftingPanel then
                        TriggerServerEvent('origen_inventory:server:playerLeaveCraftingZone', payload.id)
                    end
                end
            end

            if payload.type == 'drop' then
                Player:setActiveDrop(nil)
            end

            Sprite.updateCrafting(false)
        end)

        local VisualEffectsConfig = Config.WorldPoints.VisualEffects
        local nextCheckConfig = Config.WorldPoints.Initialization.craftingPanelSync or 5000
        local nextCheck = GetGameTimer() + nextCheckConfig
        exports.origen_inventory:registerHook('worldpoint-area-nearby', function(payload)
            if payload.sprite and not payload.options.hideSprite then
                local spriteOffset = payload.sprite.offset or vector3(0, 0, 0)
                Sprite.draw(payload.location + spriteOffset)

                if VisualEffectsConfig.sprites.enableFloatingLight then
                    Sprite.drawFloatingLight(payload.location + spriteOffset, VisualEffectsConfig.sprites)
                end

                if payload.type == 'crafting' then
                    if payload.sprite.showCraftingPanel and not payload.options.hideCraftingPanel then
                        if nextCheck < GetGameTimer() then
                            Thread(function() Sprite.updateCraftingSprite(payload.id) end)
                            nextCheck = GetGameTimer() + nextCheckConfig
                        end
                    end
                end
            end
        end)

        exports.origen_inventory:registerHook('worlpoint-onDestroy', function(payload)
            if payload.type == 'drop' then
                if Player.activeDrop and Player.activeDrop.id == payload.id then
                    Player:setActiveDrop(nil)
                    Player:CloseSecondInventory()
                end
            end
        end)
    end

    -- Load config stashes (legacy support)
    if Config and Config.Stashes then
        for id, stashData in pairs(Config.Stashes) do
            if id ~= 'default' then
                local configData = table.clone(stashData)
                configData.id = id
                configData.type = 'stash'
                configData.enable = true
                GlobalWorldPointManager:createPoint(id, configData, 'stash')
            end
        end
    end
end)

-- Resource cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    GlobalWorldPointManager:cleanup()
end)

-- ===============================================
-- EXPORTS - UNIFIED API
-- ===============================================

-- Core exports
exports('CreateWorldPoint', function(pointId, pointData, pointType)
    return GlobalWorldPointManager:createPoint(pointId, pointData, pointType)
end)

exports('RemoveWorldPoint', function(pointId)
    return GlobalWorldPointManager:removePoint(pointId)
end)

exports('SetWorldPointEnabled', function(pointId, enabled)
    return GlobalWorldPointManager:setPointEnabled(pointId, enabled)
end)

exports('GetWorldPointManager', function()
    return GlobalWorldPointManager
end)

-- Type-specific exports (backward compatibility)
exports('SetEnabled', function(shopId, enabled)
    return GlobalWorldPointManager:setPointEnabled(shopId, enabled)
end)

exports('SetShopLocalEnabled', function(shopId, enabled)
    return GlobalWorldPointManager:setPointEnabled(shopId, enabled)
end)

-- Batch operations
exports('CreateBatchPoints', function(pointsData, pointType)
    return GlobalWorldPointManager:createBatchPoints(pointsData, pointType)
end)

exports('ClearPoints', function(pointType)
    return GlobalWorldPointManager:clearPoints(pointType)
end)

exports('RefreshAllPoints', function(pointType)
    return GlobalWorldPointManager:refreshAllPoints(pointType)
end)

-- Information exports
exports('GetPoints', function(pointType)
    return GlobalWorldPointManager:getPoints(pointType)
end)

exports('GetPointCount', function(pointType)
    return GlobalWorldPointManager:getPointCount(pointType)
end)

exports('HasPoint', function(pointId)
    return GlobalWorldPointManager:hasPoint(pointId)
end)

-- Type management exports
exports('RegisterPointType', function(pointType, config)
    return GlobalWorldPointManager:registerPointType(pointType, config)
end)

exports('LoadPointType', function(pointType)
    return GlobalWorldPointManager:loadType(pointType)
end)

-- ===============================================
-- DEBUG COMMANDS
-- ===============================================

if Config.Debug then
    RegisterCommand('points_debug', function()
        local totalPoints = GlobalWorldPointManager:getPointCount()
        local stashCount = GlobalWorldPointManager:getPointCount('stash')
        local shopCount = GlobalWorldPointManager:getPointCount('shop')
        local craftingCount = GlobalWorldPointManager:getPointCount('crafting')

        print('^2[WorldPointManager Debug]^7')
        print(('Total Points: %d'):format(totalPoints))
        print(('Stashes: %d'):format(stashCount))
        print(('Shops: %d'):format(shopCount))
        print(('Crafting: %d'):format(craftingCount))

        -- Show registered types
        local pointTypes = GlobalWorldPointManager:getPointTypes()
        print('^3Registered Types:^7')
        for pointType in pairs(pointTypes) do
            print((' - %s'):format(pointType))
        end
    end, false)

    RegisterCommand('point_get_registereds', function(_, args)
        local pointType = args[1]
        local points = GlobalWorldPointManager:getPoints(pointType)
        print('^2[Registered Points]^7')
        for pointId, pointData in pairs(points) do
            print(('- ID: %s | Type: %s | Locations: %d'):format(
                pointId,
                pointData.type,
                #pointData.config.locations
            ))
        end
    end, false)

    local table_count = function(t)
        local count = 0
        for _ in pairs(t) do count = count + 1 end
        return count
    end

    RegisterCommand('worldpoint_debug', function()
        print("^2=== WorldPoint Debug Info ===^0")

        for id, instance in pairs(WorldPoint.instances) do
            print(("WorldPoint ID: %s | Internal ID: %s | Type: %s"):format(
                id, instance.internalId, instance.type))
            print(("  Points count: %d"):format(#instance.points))
            print(("  Entities count: %d"):format(table_count(instance.entities)))

            for entityId, entity in pairs(instance.entities) do
                print(("    Entity %s: %d (exists: %s)"):format(
                    entityId, entity, DoesEntityExist(entity)))
            end
        end
    end, false)

    RegisterCommand('point_info', function(_, args)
        local pointId = args[1]
        if not pointId then
            print('^1Usage: point_info <pointId>^7')
            return
        end

        local point = GlobalWorldPointManager:getPoint(pointId)
        if not point then
            print(('^1Point not found: %s^7'):format(pointId))
            return
        end

        print(('^2Point Info: %s^7'):format(pointId))
        print(('Type: %s'):format(point.type))
        print(('Created: %dms ago'):format(GetGameTimer() - point.createdAt))
        print(('Has Instance: %s'):format(point.instance and 'Yes' or 'No'))
        print(('Original Data: %s'):format(json.encode(point.originalData, { indent = true })))

        if point.instance then
            local info = point.instance.getInfo and point.instance:getInfo() or {}
            print(('Instance Info: %s'):format(json.encode(info, { indent = true })))
        end
    end, false)
end
