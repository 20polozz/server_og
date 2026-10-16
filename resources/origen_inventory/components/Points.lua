---@diagnostic disable: cast-local-type, param-type-mismatch, inject-field
--[[
    Origen Inventory - Points System
    Advanced spatial point management with grid optimization
    Refactored for better organization and maintainability
]]

if IsDuplicityVersion() then return end

-- ===============================================
-- TYPE DEFINITIONS & INTERFACES
-- ===============================================

---@class PointProperties
---@field coords vector3 Point coordinates in world space
---@field distance number Detection radius for the point
---@field onEnter? fun(self: CPoint) Callback when player enters point radius
---@field onExit? fun(self: CPoint) Callback when player exits point radius
---@field nearby? fun(self: CPoint) Callback while player is near point
---@field [string] any Additional custom properties

---@class CPoint : PointProperties
---@field id number Unique point identifier
---@field currentDistance number Current distance from player
---@field isClosest? boolean Whether this is the closest point
---@field inside? boolean Whether player is inside the point
---@field radius number Alias for distance (backward compatibility)
---@field remove fun(self: CPoint) Remove this point from the system
---@field [string] fun() Additional custom properties

-- ===============================================
-- MODULE STATE & CONFIGURATION
-- ===============================================

---@type table<number, CPoint>
Points = {}

---@type CPoint[]
local nearbyPoints = {}

---@type number
local nearbyCount = 0

---@type CPoint?
local closestPoint = nil

---@type number?
local nearbyTickId = nil

-- Cache for performance optimization
local cache = {
    lastCellX = nil,
    lastCellY = nil,
    playerPed = PlayerPedId(),
    lastCoords = vec3(0, 0, 0)
}

-- Configuration constants
local CONFIG = {
    UPDATE_INTERVAL = 300,     -- ms between position updates
    NEARBY_TICK_INTERVAL = 3   -- ms between nearby callbacks (0 = every frame)
}

-- ===============================================
-- UTILITY FUNCTIONS
-- ===============================================

---Safely convert coordinates to vector3
---@param coords any Coordinates in various formats
---@return vector3
local function normalizeCoords(coords)
    local coordType = type(coords)
    
    if coordType == 'vector3' then
        return coords
    elseif coordType == 'table' or coordType == 'vector4' then
        return vec3(
            coords[1] or coords.x or 0,
            coords[2] or coords.y or 0,
            coords[3] or coords.z or 0
        )
    end
    
    error(("Invalid coordinates type: expected 'vector3' or 'table', received '%s'"):format(coordType))
end

---Calculate 3D distance between two points
---@param coords1 vector3
---@param coords2 vector3
---@return number
local function calculateDistance(coords1, coords2)
    return #(coords1 - coords2)
end

---Check if point is valid and has required properties
---@param point CPoint
---@return boolean
local function validatePoint(point)
    return point and point.coords and point.radius and point.id
end

---Clean up point references and callbacks
---@param point CPoint
local function cleanupPoint(point)
    -- Trigger exit callback if inside
    if point.inside and point.onExit then
        point:onExit()
    end
    
    -- Clear point state
    point.inside = nil
    point.currentDistance = nil
    point.isClosest = nil
end

-- ===============================================
-- POINT MANAGEMENT
-- ===============================================

---Remove a point from the system
---@param self CPoint
local function removePoint(self)
    if not validatePoint(self) then
        return
    end
    
    -- Clear closest point reference if this is it
    if closestPoint and closestPoint.id == self.id then
        closestPoint = nil
    end
    
    -- Clean up point state
    cleanupPoint(self)
    
    -- Remove from grid system
    if Grid and Grid.removeEntry then
        Grid.removeEntry(self)
    end
    
    -- Remove from points registry
    Points[self.id] = nil
end


---Find and set the closest point
local function updateClosestPoint()
    local newClosest = nil
    local closestDistance = math.huge
    
    for i = 1, nearbyCount do
        local point = nearbyPoints[i]
        if validatePoint(point) and point.currentDistance then
            if point.currentDistance < closestDistance then
                closestDistance = point.currentDistance
                newClosest = point
            end
        end
    end
    
    -- Update closest point reference
    if closestPoint and closestPoint ~= newClosest then
        closestPoint.isClosest = nil
    end
    
    if newClosest then
        newClosest.isClosest = true
    end
    
    closestPoint = newClosest
end

---Handle point entry logic
---@param point CPoint
local function handlePointEntry(point)
    if not point.inside then
        point.inside = true
        if point.onEnter then
            point:onEnter()
        end
    end
end

---Handle point exit logic
---@param point CPoint
local function handlePointExit(point)
    if point.inside then
        point.inside = nil
        point.currentDistance = nil
        if point.onExit then
            point:onExit()
        end
    end
end

-- ===============================================
-- GRID CELL OPTIMIZATION
-- ===============================================

---Handle grid cell change logic
---@param playerCoords vector3
local function handleGridCellChange(playerCoords)
    -- Check points that might need exit callbacks
    for i = 1, nearbyCount do
        local point = nearbyPoints[i]
        if validatePoint(point) and point.inside then
            local distance = calculateDistance(playerCoords, point.coords)
            if distance > point.radius then
                handlePointExit(point)
            end
        end
    end
end

-- ===============================================
-- MAIN UPDATE LOOP
-- ===============================================

---Process nearby points and handle enter/exit logic
---@param playerCoords vector3
---@param newPoints CPoint[]
local function processNearbyPoints(playerCoords, newPoints)
    -- Clear previous nearby points
    if nearbyCount > 0 then
        table.wipe(nearbyPoints)
        nearbyCount = 0
    end
    
    -- Process new nearby points
    for i = 1, #newPoints do
        local point = newPoints[i]
        if validatePoint(point) then
            local distance = calculateDistance(playerCoords, point.coords)
            
            if distance <= point.radius then
                -- Point is within range
                point.currentDistance = distance
                nearbyCount = nearbyCount + 1
                nearbyPoints[nearbyCount] = point
                
                handlePointEntry(point)
            elseif point.currentDistance then
                -- Point was nearby but now out of range
                handlePointExit(point)
            end
        end
    end
    
    -- Update closest point
    updateClosestPoint()
end

---Manage the nearby points tick system
local function manageNearbyTick()
    if not nearbyTickId and nearbyCount > 0 then
        nearbyTickId = true
        CreateThread(function()
            while nearbyTickId and nearbyCount > 0 do
                for i = nearbyCount, 1, -1 do
                    local point = nearbyPoints[i]
                    if validatePoint(point) and point.nearby then
                        point:nearby()
                    end
                end
                Wait(CONFIG.NEARBY_TICK_INTERVAL)
            end
            nearbyTickId = nil
        end)
    elseif nearbyTickId and nearbyCount == 0 then
        nearbyTickId = false
    end
end

-- ===============================================
-- MAIN THREAD
-- ===============================================

-- Filtro declarado una vez: si se creaba en cada vuelta, la cache de
-- Grid.getNearbyEntries (compara gridCache.filter == filter) nunca acertaba
local function esPuntoDelSistema(entry)
    return entry.remove == removePoint
end

---Main points system update thread
CreateThread(function()
    while true do
        -- Update player ped reference periodically
        if cache.playerPed ~= PlayerPedId() then
            cache.playerPed = PlayerPedId()
        end
        
        local playerCoords = GetEntityCoords(cache.playerPed)
        
        -- Get nearby points from grid system
        local newPoints = {}
        if Grid and Grid.getNearbyEntries then
            newPoints = Grid.getNearbyEntries(playerCoords, esPuntoDelSistema) --[[@as CPoint[] ]]
        end
        
        -- Check for grid cell changes
        local cellX, cellY = 0, 0
        if Grid and Grid.getCellPosition then
            cellX, cellY = Grid.getCellPosition(playerCoords)
        end
        
        if cellX ~= cache.lastCellX or cellY ~= cache.lastCellY then
            handleGridCellChange(playerCoords)
            cache.lastCellX = cellX
            cache.lastCellY = cellY
        end
        
        -- Process nearby points
        processNearbyPoints(playerCoords, newPoints)
        
        -- Manage nearby callback system
        manageNearbyTick()
        
        -- Cache current position
        cache.lastCoords = playerCoords
        
        Wait(CONFIG.UPDATE_INTERVAL)
    end
end)

-- ===============================================
-- PUBLIC API
-- ===============================================

---Create a new point in the system
---@return CPoint
---@overload fun(data: PointProperties): CPoint
---@overload fun(coords: vector3, distance: number, data?: PointProperties): CPoint
function Points.new(...)
    local args = { ... }
    local pointId = #Points + 1
    local pointData
    
    -- Handle different parameter formats
    if type(args[1]) == 'table' and args[1].coords then
        -- Single table with all properties
        pointData = args[1]
    else
        -- Separate coordinates and distance
        pointData = {
            coords = args[1],
            distance = args[2]
        }
        
        -- Merge additional properties if provided
        if args[3] and type(args[3]) == 'table' then
            for key, value in pairs(args[3]) do
                pointData[key] = value
            end
        end
    end
    
    -- Validate required properties
    if not pointData.coords then
        error("Point creation failed: 'coords' property is required")
    end
    
    if not pointData.distance or pointData.distance <= 0 then
        error("Point creation failed: 'distance' property must be a positive number")
    end
    
    -- Create point object
    local point = {
        id = pointId,
        coords = normalizeCoords(pointData.coords),
        distance = pointData.distance,
        radius = pointData.distance, -- Backward compatibility
        remove = removePoint,
        
        -- Copy additional properties
        onEnter = pointData.onEnter,
        onExit = pointData.onExit,
        nearby = pointData.nearby
    }
    
    -- Copy any additional custom properties
    for key, value in pairs(pointData) do
        if not point[key] then
            point[key] = value
        end
    end
    
    -- Add to grid system
    if Grid and Grid.addEntry then
        Grid.addEntry(point)
    end
    
    -- Register point
    Points[pointId] = point
    
    return point
end

---Get all registered points
---@return table<number, CPoint>
function Points.getAllPoints()
    return Points
end

---Get currently nearby points
---@return CPoint[]
function Points.getNearbyPoints()
    return nearbyPoints
end

---Get the closest point to player
---@return CPoint?
function Points.getClosestPoint()
    return closestPoint
end

---Get number of nearby points
---@return number
function Points.getNearbyCount()
    return nearbyCount
end

---Check if a specific point exists
---@param pointId number
---@return boolean
function Points.exists(pointId)
    return Points[pointId] ~= nil
end

---Remove a point by ID
---@param pointId number
---@return boolean success
function Points.removeById(pointId)
    local point = Points[pointId]
    if point then
        point:remove()
        return true
    end
    return false
end

---Clear all points from the system
function Points.clear()
    for pointId, point in pairs(Points) do
        if type(point) == 'table' and point.remove then
            point:remove()
        end
    end
    
    -- Force clear arrays
    table.wipe(nearbyPoints)
    nearbyCount = 0
    closestPoint = nil
    
    -- Stop nearby tick
    if nearbyTickId then
        nearbyTickId = false
    end
end

-- ===============================================
-- BACKWARD COMPATIBILITY
-- ===============================================

---@deprecated Use Points.getClosestPoint() instead
Points.closest = Points.getClosestPoint

-- ===============================================
-- DEBUG AND DIAGNOSTICS
-- ===============================================

if Config.Debug then
    ---Debug function to debugger point system statistics
    function Points.debug()
        local totalPoints = 0
        for _ in pairs(Points) do
            totalPoints = totalPoints + 1
        end
        
        debugger(("^2[Points Debug]^7 Total Points: %d, Nearby: %d, Closest: %s"):format(
            totalPoints,
            nearbyCount,
            closestPoint and tostring(closestPoint.id) or "none"
        ))
    end
    
    -- Register debug command
    RegisterCommand('points_debug', Points.debug, false)
end