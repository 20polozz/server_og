function HasPoliceNearby(radius)
    local refs = GlobalState.References
    if not refs or type(refs) ~= 'table' then return false end
    local playerCoords = GetEntityCoords(cache.ped)
    for _, officers in pairs(refs) do
        if type(officers) == 'table' then
            for _, officer in pairs(officers) do
                if officer and officer.coords then
                    local c = officer.coords
                    local dist = #(playerCoords - vector3(c.x or 0, c.y or 0, c.z or 0))
                    if dist <= radius then
                        return true
                    end
                end
            end
        end
    end
    return false
end