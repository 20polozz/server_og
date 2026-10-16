function NumberEquals(a, b, tolerance)
    return math.abs(a - b) < (tolerance or 0.5)
end

RegisterNUICallback("GotoMarker", function(data, cb)
    local coords = vector3(tonumber(data.x), tonumber(data.y), tonumber(data.z))
    SetEntityCoords(PlayerPedId(), coords)
    cb(true)
end)

RegisterNUICallback("GetJobCategories", function(data, cb)
    local jobCats = Config.JobCategory
    local retval = {}
    for k, v in pairs(jobCats) do
        retval[k] = {}
        for _, jobData in pairs(v) do
            retval[k][#retval[k] + 1] = jobData.name
        end
    end
    cb(retval)
end)

RegisterNUICallback("SetMarkerPos", function(data, cb)
    SetNewPos(data.station, data.markerName, data.markerIndex, data.multiple)
    cb(true)
end)

RegisterNUICallback("CreateMarker", function(data, cb)
    SetNewPos(data.station, data.markerName, nil, data.multiple, true)
    cb(true)
end)

function SetNewPos(station, markerName, markerIndex, multiple, isCreating)
    local sprite = 20
    if MarkersList[markerName] then
        sprite = MarkersList[markerName].sprite
    elseif PublicMarkerList[markerName] then
        sprite = PublicMarkerList[markerName].sprite
    end
    local times = 0
    local creatingData = {}
    CreateThread(function()
        while true do
            Wait(10)

            local hit, coords = GetScreenCoords(100)

            if Config.CustomNotify then
                ShowHelpNotification("E", ((multiple and times >= 1) and "Colocar punto de aparición" or "Colocar marcador"))
            else
                if Config.Framework == "qbcore" then
                    exports['qb-core']:DrawText("[E] "..((multiple and times >= 1) and "Colocar punto de aparición" or "Colocar marcador"), 'left')
                elseif Config.Framework == "esx" then
                    Framework.ShowHelpNotification("~INPUT_PICKUP~ "..((multiple and times >= 1) and "Colocar punto de aparición" or "Colocar marcador"), true)
                end
            end

            if hit then
                local pcoords = GetEntityCoords(PlayerPedId())
                DrawLine(pcoords.x, pcoords.y, pcoords.z, coords.x, coords.y, coords.z, 255, 255, 255, 100)
                DrawMarker(sprite, coords.x, coords.y, coords.z + 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 0, 0, 0, 100, false, false, 0, true)
                if IsControlJustPressed(0, 38) then
                    times = times + 1
                    creatingData[times == 1 and "coords" or "spawn"] = {coords.x, coords.y, coords.z + 1.0, GetEntityHeading(PlayerPedId())}
                    HideHelpNotification()
                    if not isCreating then
                        FW_TriggerCallback("origen_police:callback:UpdateMarkerPos", function(data)
                            Debuger("Update marker pos: ", json.encode(data))
                        end, {
                            station = station,
                            markerName = markerName,
                            markerIndex = tonumber(markerIndex) + 1,
                            x = coords.x,
                            y = coords.y,
                            z = coords.z + 1.0,
                            w = GetEntityHeading(PlayerPedId()),
                            isMultiple = times > 1
                        })
                    elseif (multiple and times > 1) or (not multiple and times == 1) then
                        FW_TriggerCallback("origen_police:callback:CreateMarker", function(data)
                            Debuger("Create marker: ", json.encode(data))
                        end, {
                            station = station,
                            markerName = markerName,
                            creatingData = creatingData,
                        })
                    end
                    if not multiple or times > 1 then exports["origen_police"]:openManagement() break end
                elseif IsControlJustPressed(0, 177) then
                    exports["origen_police"]:openManagement()
                    break
                end
            end
        end

        HideHelpNotification()
    end)
end

function GetStationIndex(station)
    for k, v in pairs(Config.Maps) do
        if v == station then return tonumber(k) end
    end
end

RegisterNetEvent("origen_police:client:UpdateMarkerPos", function(data)
    if data.markerName == "BillsNPC" or data.markerName == "DocumentsNPC" then
        ReloadMarkers()
        return ShowNotification("La posición del NPC se ha actualizado correctamente")
    end
    local isPublic = PublicMarkerList[data.markerName] ~= nil
    local Ref = isPublic and Public.Markers or Tables.Markers[GetStationIndex(data.station)]
    local event = isPublic and PublicMarkerList[data.markerName].event or MarkersList[data.markerName].event
    for _, v in pairs(Ref) do
        if v.event == event then
            v[data.isMultiple and "spawn" or "coords"] = vector4(data.x, data.y, data.z, data.w)
            if data.markerName == "ConfiscatedVehicles" and data.isMultiple then
                local stationIndex = GetStationIndex(data.station)
                SpawnConfiscatedVehicles[stationIndex] = v.spawn
            end
            break
        end
    end
end)

RegisterNetEvent("origen_police:client:RemoveMarker", function(data)
    if data.markerName == "BillsNPC" or data.markerName == "DocumentsNPC" then
        ReloadMarkers()
        return ShowNotification("El NPC ha sido eliminado")
    end
    local isPublic = PublicMarkerList[data.markerName] ~= nil
    local Ref = isPublic and Public.Markers or Tables.Markers[GetStationIndex(data.station)]
    local event = isPublic and PublicMarkerList[data.markerName].event or MarkersList[data.markerName].event
    for k, v in pairs(Ref) do
        if v.event == event and NumberEquals(v.coords.x, data.coords[1]) and NumberEquals(v.coords.y, data.coords[2]) and NumberEquals(v.coords.z, data.coords[3]) then
            table.remove(Ref, k)
            break
        end
    end
end)

RegisterNetEvent("origen_police:client:CreateMarker", function(data)
    if data.markerName == "BillsNPC" or data.markerName == "DocumentsNPC" then
        ReloadMarkers()
        return ShowNotification("El NPC se ha creado correctamente")
    end
    -- Translate legacy names to valid MarkersList/PublicMarkerList keys
    if data.markerName == "Dressing" then
        data.markerName = "DressingRoom"
    elseif data.markerName == "Armory" or data.markerName == "Armoury" then
        data.markerName = "Inventory/Armoury"
    elseif data.markerName == "Evidence" then
        data.markerName = "EvidenceReport"
    elseif data.markerName == "Helipad" then
        data.markerName = "RequestHelicopter"
    elseif data.markerName == "Garage" then
        data.markerName = "RequestVehicle"
    end
    local isPublic = PublicMarkerList[data.markerName] ~= nil
    local markerData = isPublic and PublicMarkerList[data.markerName] or MarkersList[data.markerName]
    local stationIndex = GetStationIndex(data.station)
    local Ref = isPublic and Public.Markers or Tables.Markers[stationIndex]
    if Ref == nil and not isPublic then
        Tables.Markers[stationIndex] = {}
        Ref = Tables.Markers[stationIndex]
    end
    if markerData then
        local index = #Ref + 1
        Ref[index] = Shallowcopy(markerData)
        Ref[index].coords = vector4(data.creatingData.coords[1], data.creatingData.coords[2], data.creatingData.coords[3], data.creatingData.coords[4])
        if data.creatingData.spawn then
            Ref[index].spawn = vector4(data.creatingData.spawn[1], data.creatingData.spawn[2], data.creatingData.spawn[3], data.creatingData.spawn[4])
            if data.markerName == "ConfiscatedVehicles" then
                SpawnConfiscatedVehicles[stationIndex] = Ref[index].spawn
            end
        end
        Debuger("Create Marker Data: ", json.encode(Ref, {indent = true}))
    else
        print("^1[origen_police] Warning: Unknown marker type '" .. tostring(data.markerName) .. "' ignored.^7")
    end
end)

RegisterNetEvent("origen_police:client:ActiveStation", function(data)
    if not data.active then
        for k, v in pairs(Config.Maps) do
            if v == data.station then
                Config.Maps[k] = nil
                break
            end
        end
        if CachedMapData then CachedMapData[data.station] = nil end
        ReloadMarkers()
        return
    end
    Config.Maps[#Config.Maps + 1] = data.station
    if not CachedMapData then CachedMapData = {} end
    CachedMapData[data.station] = data.stationData
    ReloadMarkers()
end)

RegisterNetEvent("origen_police:client:syncSingleStationData", function(stationName, stationData)
    if not CachedMapData then CachedMapData = {} end
    CachedMapData[stationName] = stationData
    local isActive = false
    for _, v in pairs(Config.Maps) do
        if v == stationName then
            isActive = true
            break
        end
    end
    if isActive then
        ReloadMarkers()
    end
end)

RegisterNetEvent("origen_police:client:UpdateMarkerPos", function(data, stationData)
    if not CachedMapData then CachedMapData = {} end
    CachedMapData[data.station] = stationData
    local isActive = false
    for _, v in pairs(Config.Maps) do
        if v == data.station then
            isActive = true
            break
        end
    end
    if isActive then
        ReloadMarkers()
    end
end)

RegisterNetEvent("origen_police:client:RemoveMarker", function(data, stationData)
    if not CachedMapData then CachedMapData = {} end
    CachedMapData[data.station] = stationData
    local isActive = false
    for _, v in pairs(Config.Maps) do
        if v == data.station then
            isActive = true
            break
        end
    end
    if isActive then
        ReloadMarkers()
    end
end)

RegisterNetEvent("origen_police:client:CreateMarker", function(data, stationData)
    if not CachedMapData then CachedMapData = {} end
    CachedMapData[data.station] = stationData
    local isActive = false
    for _, v in pairs(Config.Maps) do
        if v == data.station then
            isActive = true
            break
        end
    end
    if isActive then
        ReloadMarkers()
    end
end)

local markersLoaded = false

RegisterNetEvent("origen_police:client:OnPlayerLoaded", function()
    if Config.IgnoreSettings or markersLoaded then return end
    markersLoaded = true
    
    FW_TriggerCallback("origen_police:callback:GetActiveMapsData", function(mapNames, mapData)
        CachedMapData = mapData or {}
        Config.Maps = mapNames or {}
        if #Config.Maps == 0 then
            print("^3WARNING: NO ACTIVE MAPS, PLEASE ADD SOME IN THE SETTING TAB OF THE POLICE TABLET^0")
        end
        ReloadMarkers()
    end)

    TriggerServerEvent("origen_police:server:requestDivisionsSync")
    TriggerServerEvent("origen_police:server:requestLicensesSync")

    local myCategory = GetPlayerJobCategory()
    if myCategory then
        TriggerServerEvent("origen_police:server:requestQuickmenuVisibilitySync", myCategory)
    end
end)

RegisterNetEvent("origen_police:client:syncDBConfigs", function()
    FW_TriggerCallback("origen_police:callback:GetActiveMapsData", function(mapNames, mapData)
        CachedMapData = mapData or {}
        Config.Maps = mapNames or {}
        ReloadMarkers()
    end)
end)