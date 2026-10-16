local Utils = {}

---@param entity number
---@param radius number
---@return boolean
function Utils.IsCursorOnEntity(entity, radius)
    if not entity or not DoesEntityExist(entity) then
        return false
    end

    local cursorX, cursorY = GetNuiCursorPosition()
    local resX, resY = GetActiveScreenResolution()

    local entCoords = GetEntityCoords(entity)
    local onScreen, screenX, screenY = World3dToScreen2d(entCoords.x, entCoords.y, entCoords.z)
    if not onScreen then
        return false
    end

    -- Get model dimensions to calculate screen bounding box
    local model = GetEntityModel(entity)
    local min, max = GetModelDimensions(model)
    local sizeX = math.abs(max.x - min.x)
    local sizeY = math.abs(max.y - min.y)
    local sizeZ = math.abs(max.z - min.z)
    local maxSize = math.max(sizeX, sizeY, sizeZ)
    
    -- Calculate effective radius based on model size and distance
    local camCoords = GetFinalRenderedCamCoord()
    local distance = #(camCoords - entCoords)
    local screenRadius = radius + (maxSize * 100.0 / math.max(distance, 1.0))

    local entX = screenX * resX
    local entY = screenY * resY

    local dx = cursorX - entX
    local dy = cursorY - entY
    local distSq = dx * dx + dy * dy

    return distSq <= (screenRadius * screenRadius)
end

return Utils
