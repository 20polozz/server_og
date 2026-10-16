local config = lib.load('config.main')

local activeMarkers = {}
local renderList = {}
local isDrawing = false

local function startDrawing()
    if isDrawing then return end
    isDrawing = true

    CreateThread(function()
        while #activeMarkers > 0 do
            local cam = GetFinalRenderedCamCoord()
            local ped = GetEntityCoords(cache.ped)

            for i = 1, #activeMarkers do
                local marker = activeMarkers[i]
                MarkerManager.draw(marker, cam, ped)
            end

            Wait(0)
        end

        isDrawing = false
    end)
end

local currentMarkerMarker = nil

CreateThread(function()
    while true do
        local newActive = {}
        local newRenderList = {}
        local cam = GetFinalRenderedCamCoord()

        local markers = MarkerManager.getAll()

        for i = 1, #markers do
            local marker = markers[i]

            if MarkerManager.canShow(marker, cam) then
                if not marker.isRendering then
                    MarkerManager.startRender(marker)
                end

                if marker.isRendering then
                    newActive[#newActive + 1] = marker
                    newRenderList[marker.id] = true
                end
            end
        end

        for id in pairs(renderList) do
            if not newRenderList[id] then
                local marker = MarkerManager.find(id)
                if marker then
                    MarkerManager.stopRender(marker)
                end
            end
        end

        activeMarkers = newActive
        renderList = newRenderList

        if #activeMarkers > 0 and not isDrawing then
            startDrawing()
        end

        Wait(config.rendering.updateInterval)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then
        MarkerManager.clearAll()
    end
end)

exports('Create', MarkerManager.create)
exports('Update', MarkerManager.update)
exports('Remove', MarkerManager.remove)
exports('ClearAll', MarkerManager.clearAll)
exports('Get', MarkerManager.find)

--[[ local markerId = exports.origen_markers:Create({
    coords = vector3(0, 0, 0),
    type = 'checkpoint',
    label = 'Quinoto 1', 
    size = 1.0,
    drawDistance = 600.0,
    removeDistance = 50.0,
})

exports.origen_markers:Update(markerId, {
    coords = vector3(0.0, 0.0, 0.0),
    label = 'Quinoto 2'
})

exports.origen_markers:Remove(markerId)

exports.origen_markers:ClearAll() ]]