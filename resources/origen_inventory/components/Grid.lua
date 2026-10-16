local mapMinX = -3700
local mapMinY = -4400
local mapMaxX = 4500
local mapMaxY = 8000
local xDelta = (mapMaxX - mapMinX) / 34
local yDelta = (mapMaxY - mapMinY) / 50
local grid = {}
local lastCell = {}
local gridCache = {}
local entrySet = {}

Grid = {}

---@class GridEntry
---@field coords vector
---@field length? number
---@field width? number
---@field radius? number
---@field [string] any

---@param point vector
---@param length number
---@param width number
---@return number, number, number, number
local function getGridDimensions(point, length, width)
    local minX = (point.x - width - mapMinX) // xDelta
    local maxX = (point.x + width - mapMinX) // xDelta
    local minY = (point.y - length - mapMinY) // yDelta
    local maxY = (point.y + length - mapMinY) // yDelta

    return minX, maxX, minY, maxY
end

---@param point vector
---@return number, number
function Grid.getCellPosition(point)
    local x = (point.x - mapMinX) // xDelta
    local y = (point.y - mapMinY) // yDelta

    return x, y
end

---@param point vector
---@return GridEntry[]
function Grid.getCell(point)
    local x, y = Grid.getCellPosition(point)

    if lastCell.x ~= x or lastCell.y ~= y then
        lastCell.x = x
        lastCell.y = y
        lastCell.cell = grid[y] and grid[y][x] or {}
    end

    return lastCell.cell
end

---@param point vector
---@param filter? fun(entry: GridEntry): boolean
---@return Array<GridEntry>
function Grid.getNearbyEntries(point, filter)
    local minX, maxX, minY, maxY = getGridDimensions(point, xDelta, yDelta)

    if gridCache.filter == filter and
        gridCache.minX == minX and
        gridCache.maxX == maxX and
        gridCache.minY == minY and
        gridCache.maxY == maxY then
        return gridCache.entries
    end

    local entries = {}
    local n = 0

    table.wipe(entrySet)

    for y = minY, maxY do
        local row = grid[y]

        for x = minX, maxX do
            local cell = row and row[x]

            if cell then
                for j = 1, #cell do
                    local entry = cell[j]

                    if not entrySet[entry] and (not filter or filter(entry)) then
                        n = n + 1
                        entrySet[entry] = true
                        entries[n] = entry
                    end
                end
            end
        end
    end

    gridCache.minX = minX
    gridCache.maxX = maxX
    gridCache.minY = minY
    gridCache.maxY = maxY
    gridCache.entries = entries
    gridCache.filter = filter

    return entries
end

---@param entry { coords: vector, length?: number, width?: number, radius?: number, [string]: any }
function Grid.addEntry(entry)
    entry.length = entry.length or entry.radius * 2
    entry.width = entry.width or entry.radius * 2
    local minX, maxX, minY, maxY = getGridDimensions(entry.coords, entry.length, entry.width)

    for y = minY, maxY do
        local row = grid[y] or {}

        for x = minX, maxX do
            local cell = row[x] or {}

            cell[#cell + 1] = entry
            row[x] = cell
        end

        grid[y] = row

        table.wipe(gridCache)
    end
end

---@param entry table A table that was added to the grid previously.
function Grid.removeEntry(entry)
    local minX, maxX, minY, maxY = getGridDimensions(entry.coords, entry.length, entry.width)
    local success = false

    for y = minY, maxY do
        local row = grid[y]

        if not row then goto continue end

        for x = minX, maxX do
            local cell = row[x]

            if cell then
                for i = 1, #cell do
                    if cell[i] == entry then
                        table.remove(cell, i)
                        success = true
                        break
                    end
                end

                if #cell == 0 then
                    row[x] = nil
                end
            end
        end

        if not next(row) then
            grid[y] = nil
        end

        ::continue::
    end

    table.wipe(gridCache)

    return success
end