--@param text Text to show
--@param type Notification type
--@param length Duration of the notification
Custom.Notify = function(text, type, length)
    lib.notify({
        description = text,
        type = type,
        duration = length,
    })
end

--@param text Text to show
--@param key Key to show
Custom.DrawText = function(text, key)
    exports.origen_notify:DrawText(key, text)
end

Custom.HideText = function()
    lib.hideTextUI()
end


-- This functions are only for the external interaction system

--@param id Interaction ID
--@param coords Coordinates
--@param drawDistance Draw distance
--@param distance Distance
--@param inVehicle If the interaction is in a vehicle
--@param label Label
--@param onSelect Callback when the interaction is selected
Custom.CreateCoordsInteraction = function(id, coords, drawDistance, distance, inVehicle, label, onSelect)

end

--@param id Interaction ID
--@param coords Coordinates
Custom.RemoveCoordsInteraction = function(id, coords)

end

--@param id Interaction ID
--@param type Interaction type
--@param entity Entity
--@param drawDistance Draw distance
--@param distance Distance
--@param label Label
--@param onSelect Callback when the interaction is selected
Custom.CreateEntityInteraction = function(id, type, entity, drawDistance, distance, label, onSelect)

end

--@param id Interaction ID
--@param entity Entity
Custom.RemoveEntityInteraction = function(id, entity)

end