local hiddenToilets = {}
local toiletModel = joaat('prompt_prison_toilet_withscrew')

RegisterNetEvent('prompt_prison_escape:toggleToiletVisibility', function(toggle, coords, id)
    if hiddenToilets[id] then
        hiddenToilets[id]:onExit(hiddenToilets[id])
        hiddenToilets[id]:remove()
        hiddenToilets[id] = nil
    end

    if toggle then
        return
    end

    hiddenToilets[id] = lib.points.new({
        coords = coords,
        distance = 50,
        onEnter = function(self)
            for _, obj in pairs(lib.getNearbyObjects(coords, 3.0)) do
                if not Entity(obj.object).state.isPrisonToilet and GetEntityModel(obj.object) == toiletModel then
                    SetEntityVisible(obj.object, false, 0)
                    SetEntityCollision(obj.object, false, false)
                    SetEntityAlpha(obj.object, 0, false)
                    self.entity = obj.object
                    break
                end
            end
        end,
        onExit = function(self)
            if self.entity and DoesEntityExist(self.entity) then
                SetEntityVisible(self.entity, true, 0)
                SetEntityCollision(self.entity, true, true)
                SetEntityAlpha(self.entity, 255, false)
            end
        end
    })
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then
        for _, point in pairs(hiddenToilets) do
            point:onExit(point)
            point:remove()
        end
    end
end)