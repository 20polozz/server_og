RegisterNetEvent("origen_police:client:UpdateTraffic", function(i, type)
    if Public.TrafficZones[i] then
        RemoveRoadNodeSpeedZone(Public.TrafficZones[i].id)
        Public.TrafficZones[i].type = type
        if Public.TrafficZones[i].type == "stop" then
            Public.TrafficZones[i].id = AddRoadNodeSpeedZone(Public.TrafficZones[i].coords, 50.0, 0.0, false)
        elseif Public.TrafficZones[i].type == "slow" then
            Public.TrafficZones[i].id = AddRoadNodeSpeedZone(Public.TrafficZones[i].coords, 50.0, 5.0, false)
        end

        --- El color del punto dice de que tipo es la zona: rojo el alto,
        --- amarillo el limite. Antes esto era un SetBlipColour.
        if Public.TrafficZones[i].blip then
            OrigenMapa.Tintar(Public.TrafficZones[i].blip,
                Public.TrafficZones[i].type == "stop" and '#ff3355' or '#f0c33c')
        end
    end
end)

RegisterNetEvent("origen_police:client:AddTrafficZone", function(data)
    --- Igual que las de arranque (civilians.lua): un punto con radio en
    --- origen_map, y la zona de velocidad aparte, que es lo que hace efecto.
    if data.type == "stop" then
        data.id = AddRoadNodeSpeedZone(data.coords, 50.0, 0.0, false)
    elseif data.type == "slow" then
        data.id = AddRoadNodeSpeedZone(data.coords, 50.0, 5.0, false)
    end

    if onduty then
        data.blip = 'trafico_' .. tostring(data.id or #Public.TrafficZones + 1)

        OrigenMapa.Poner(data.blip, {
            x = data.coords.x, y = data.coords.y, z = data.coords.z,
            cat = 'emergencias',
            nombre = data.type == "stop"
                and 'Control de trafico' or 'Limitacion de velocidad',
            radio = 50.0,
            color = data.type == "stop" and '#ff3355' or '#f0c33c',
        })
    end
    table.insert(Public.TrafficZones, data)
end)

RegisterNetEvent("origen_police:client:RemoveTraffic", function(i)
    if Public.TrafficZones[i] then
        if Public.TrafficZones[i].blip then
            OrigenMapa.Quitar(Public.TrafficZones[i].blip, 17)
        end
        RemoveRoadNodeSpeedZone(Public.TrafficZones[i].id)
        table.remove(Public.TrafficZones, i)
    end
end)