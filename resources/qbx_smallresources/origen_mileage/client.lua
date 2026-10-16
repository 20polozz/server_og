local function logMileage()
    CreateThread(function()
        while cache.vehicle do
            local vState = Entity(cache.vehicle).state
            Wait(1500)
            if cache.seat == -1 then
                local coords = GetEntityCoords(cache.vehicle)
                if not vState.mileage then
                    vState:set('mileage', {value = 0, lastCoords = coords}, true)
                else
                    local distance = #(coords - vState.mileage.lastCoords)
                    if distance > 0 then
                        vState:set('mileage', {value = vState.mileage.value + distance, lastCoords = coords}, true)
                    end
                end
            end
        end
    end)
end

lib.onCache('vehicle', function(veh, lastVeh)
    if veh then logMileage() end
end)