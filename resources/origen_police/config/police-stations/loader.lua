-- DONT TOUCH ANYTHING ABOVE;

function ParseVector4(data)
    return vector4(data[1], data[2], data[3], data[4])
end

function IsVecZero(vec)
    return vec.x == 0 and vec.y == 0 and vec.z == 0
end

function ParseCoords(data)
    local retval = {}
    for k,v in pairs(data) do
        if k == "Options" then
            goto continue
        end
        for _, marker in pairs(v) do
            if marker.coords then
                marker.coords = ParseVector4(marker.coords)
                if IsVecZero(marker.coords) then
                    print("^3WARNING: YOU HAVE A MARKER WITH COORDS IN THE WORLD COORDS; YOU SHOULD REMOVE IT TO AVOID ISSUES WITH HELP NOTIFICATIONS^0")
                end
            end
            if marker.spawn then
                marker.spawn = ParseVector4(marker.spawn)
            end

        end
        ::continue::
        retval[k] = v
    end
    return retval
end

CachedMapData = {}

function LoadMarkersData(mapName)
    if not IsDuplicityVersion() and CachedMapData and CachedMapData[mapName] then
        local copiedData = json.decode(json.encode(CachedMapData[mapName]))
        return ParseCoords(copiedData)
    end
    local data = LoadResourceFile(GetCurrentResourceName(), "config/police-stations/"..mapName..".json")
    if not data then
        Debuger("The map "..mapName.." does not exist, loading default gta map.^0")
        return
    end
    return ParseCoords(json.decode(data))
end

exports("LoadMarkers", LoadMarkersData)