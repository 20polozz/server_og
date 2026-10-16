local config = lib.load('config.main')

MarkerManager = {}
local markers = {}
local markerList = {}

local indexMap = {}
local nextId = 0

function MarkerManager.create(data)
    nextId += 1
    local id = nextId

    local marker = Marker.new(id, data)

    local idx = #markerList + 1
    markerList[idx] = marker
    markers[id] = marker
    indexMap[id] = idx
    return id
end

function MarkerManager.remove(id)
    local marker = markers[id]
    if not marker then return end

    if marker.isRendering and marker.duiId then
        DuiPool.free(marker.duiId)
    end

    marker:cleanup()

    local idx = indexMap[id]
    local lastIdx = #markerList

    if idx ~= lastIdx then
        local last = markerList[lastIdx]
        markerList[idx] = last
        indexMap[last.id] = idx
    end

    markerList[lastIdx] = nil
    markers[id] = nil
    indexMap[id] = nil
end

function MarkerManager.clearAll()
    for i = #markerList, 1, -1 do
        MarkerManager.remove(markerList[i].id)
    end
end

function MarkerManager.update(id, data)
    local marker = markers[id]
    if marker then
        marker:refresh(data)
    end
end

function MarkerManager.find(id)
    return markers[id]
end

function MarkerManager.getAll()
    return markerList
end

function MarkerManager.startRender(marker)
    if marker.isRendering then return true end

    local dui, duiId = DuiPool.get()
    if not dui then
        return false
    end

    marker.dui = dui
    marker.duiId = duiId
    marker.isRendering = true

    marker:setupDui()

    return true
end

function MarkerManager.stopRender(marker)
    if not marker.isRendering then return end

    if marker.duiId then
        DuiPool.free(marker.duiId)
    end

    marker.dui = nil
    marker.duiId = nil
    marker.isRendering = false
    marker.lastDistance = nil
    marker.nextDistanceUpdate = nil
end

function MarkerManager.canShow(marker, cam)
    return marker:canShow(cam)
end

function MarkerManager.draw(marker, cam, playerPos)
    local success = marker:draw(cam, playerPos)

    if not success then
        MarkerManager.stopRender(marker)
        return false
    end

    return true
end

function MarkerManager.updateRendering(cam)
    for _, marker in ipairs(markerList) do
        if MarkerManager.canShow(marker, cam) then
            MarkerManager.startRender(marker)
        else
            MarkerManager.stopRender(marker)
        end
    end
end