Internal.OpenStash = function(stashID)
    
end

Internal.HasItem = function(item, requiredCount)
    requiredCount = requiredCount or 1

    if Inventory and type(Inventory.HasItem) == 'function' then
        return Inventory.HasItem(item, requiredCount) == true
    end

    if Framework and type(Framework.HasItem) == 'function' then
        return Framework.HasItem(item, requiredCount) == true
    end

    return false
end
