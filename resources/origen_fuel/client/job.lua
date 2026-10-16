function getClosestStation()
    local coords = GetEntityCoords(cache.ped)
    for k, v in pairs(Config.Stations) do
        local distance = #(coords - v.coords)
        if distance < 20.0 then
            return k
        end
    end
    return nil
end