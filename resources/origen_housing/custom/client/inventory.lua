--@param id Stash ID
--@param data (label, slots, weight)
Custom.OpenStash = function(id, data)
    -- Add your custom stash system here
end

--@param houseID House ID
--@param hasSecurity Has storage security upgrade
Custom.CanOpenStash = function(houseID, hasSecurity)
    return not hasSecurity
end