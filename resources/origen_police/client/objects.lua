local prop = 0
local prevent = GetGameTimer()
local objects = {}
local objectsData = {}

CreateThread(function()
    while true do
        local playerCoords = GetEntityCoords(PlayerPedId())
        for placerId, objectList in pairs(objectsData) do
            for objectId, data in pairs(objectList) do
                local dist = #(playerCoords - data.coords)
                if dist < 100.0 then
                    if not objects[placerId] or not DoesEntityExist(objects[placerId][objectId]) then
                        local model = type(data.model) == "string" and GetHashKey(data.model) or data.model
                        if LoadModel(model, 2000) then
                            objects[placerId] = objects[placerId] or {}
                            local obj = CreateObject(model, data.coords.x, data.coords.y, data.coords.z, false, true, false)
                            SetEntityHeading(obj, data.heading)
                            FreezeEntityPosition(obj, data.freeze)
                            objects[placerId][objectId] = obj
                        end
                    end
                elseif dist > 150.0 then
                    if objects[placerId] and DoesEntityExist(objects[placerId][objectId]) then
                        DeleteEntity(objects[placerId][objectId])
                        objects[placerId][objectId] = nil
                    end
                end
            end
        end
        Wait(1000)
    end
end)

CreateThread(function()
    Wait(1000)
    TriggerServerEvent("origen_police:server:syncObjects")
end)

RegisterCommand("plceobj", function(_, args)
    local PlayerData = FW_GetPlayerData(false)

    if CanOpenTablet(PlayerData.job.name)[1] and PlayerData.job.onduty and GetGameTimer() - prevent > 1500 then
        prevent = GetGameTimer()
        local category = table.concat(args, " ")
        if Config.Props[category] then
            FW_TriggerCallback("origen_police:server:HasItem", function(hasItem)
                if hasItem then
                    SlectPropAndPos(Config.Props[category], Config.Props[category].Text, Config.Props[category].Animations, category)
                else
                    ShowNotification(Config.Translations.NoItem or "No tienes el objeto necesario")
                end
            end, category)
        end
    end
end)

RegisterNetEvent("origen_police:client:useItemObj", function(category)
    if GetGameTimer() - prevent > 1500 then
        prevent = GetGameTimer()
        if Config.Props[category] then
            FW_TriggerCallback("origen_police:server:HasItem", function(hasItem)
                if hasItem then
                    SlectPropAndPos(Config.Props[category], Config.Props[category].Text, Config.Props[category].Animations, category)
                else
                    ShowNotification(Config.Translations.NoItem or "No tienes el objeto necesario")
                end
            end, category)
        end
    end
end)

function FindNearPlacedObject()
    local nearestDistance = 2.0
    local nearestPlacerId, nearestObjectId, nearestObject = nil, nil, nil

    local playerCoords = GetEntityCoords(PlayerPedId())

    for placerId, objectList in pairs(objectsData) do
        for objectId, data in pairs(objectList) do
            local distance = #(playerCoords - data.coords)
            if distance < nearestDistance then
                -- Ensure entity exists if we are this close
                if not objects[placerId] or not DoesEntityExist(objects[placerId][objectId]) then
                    local model = type(data.model) == "string" and GetHashKey(data.model) or data.model
                    if LoadModel(model, 1000) then
                        objects[placerId] = objects[placerId] or {}
                        local obj = CreateObject(model, data.coords.x, data.coords.y, data.coords.z, false, true, false)
                        SetEntityHeading(obj, data.heading)
                        FreezeEntityPosition(obj, data.freeze)
                        objects[placerId][objectId] = obj
                    end
                end

                local object = objects[placerId] and objects[placerId][objectId]
                if DoesEntityExist(object) then
                    local coords = GetEntityCoords(object)
                    if GetEntityModel(object) == `prop_cctv_pole_01a` then
                        coords = vector3(coords.x, coords.y, coords.z + 7.0)
                    end
                    distance = #(playerCoords - coords)
                    if distance < nearestDistance then
                        nearestDistance = distance
                        nearestPlacerId, nearestObjectId, nearestObject = placerId, objectId, object
                    end
                end
            end
        end
    end

    return nearestPlacerId, nearestObjectId, nearestObject
end

RegisterCommand("rmveobj", function()
    local PlayerData = FW_GetPlayerData(false)

    if CanOpenTablet(PlayerData.job.name)[1] and PlayerData.job.onduty then
        if GetGameTimer() - prevent > 1500 then
            prevent = GetGameTimer()

            local placerId, objectId, object = FindNearPlacedObject()
            if object then
                RequestAnimDict('pickup_object')
                while not HasAnimDictLoaded('pickup_object') do
                    Wait(7)
                end

                TaskPlayAnim(PlayerPedId(), 'pickup_object' ,'pickup_low', 8.0, -8.0, -1, 1, 0, false, false, false)
                Citizen.SetTimeout(700, function()
                    TriggerServerEvent("origen_police:callback:rmveobj", placerId, objectId, GetEntityCoords(object))
                end)
                Wait(1000)
                ClearPedTasks(PlayerPedId())
            end
        else
            ShowNotification(Config.Translations.CantFast)
        end
    end
end)

function SlectPropAndPos(value, text, anim, category)
    local ped = PlayerPedId()
    local pcords = GetEntityCoords()

    local currentobjectnumber = 1
    local currentobject = value.Props[currentobjectnumber]
    DeleteEntity(prop)
    prop = 0
    HideHelpNotification()
    Wait(500)
    prop = GenerateObject(currentobject.model, pcords, anim.dict)
    AttachEntityToEntity(prop, ped, currentobject.bone, currentobject.x+0.0, currentobject.y+0.0, currentobject.z+0.0, currentobject.xr+0.0, currentobject.yr+0.0, currentobject.zr+0.0, true, true, false, true, 1, true)

    CreateThread(function()
        local noty = false
        while prop ~= 0 do
            Wait(5)

            pcords = GetEntityCoords(ped)
            if not noty then
                noty = true
                
                if GetResourceState('origen_hud') == 'started' then
                    exports['origen_hud']:setupControls({
                        { key = 'E', text = 'Colocar' },
                        { key = '< >', text = 'Cambiar objeto' },
                    })
                elseif lib then
                    local text = Config.Translations.objects.fullText:format('[E]', '[LEFT]', '[RIGHT]', '[BACKSPACE]')
                    lib.showTextUI(text, { position = "right-center", icon = 'cube' })
                elseif Config.CustomNotify and GetResourceState("origen_notify") == "started" then
                    ShowHelpNotification("E", Config.Translations.objects.place)
                    ShowHelpNotification("left", Config.Translations.objects.prev)
                    ShowHelpNotification("right", Config.Translations.objects.next)
                    ShowHelpNotification("backspace", Config.Translations.objects.cancel)
                    if Config.Framework == "esx" then
                        CreateThread(function()
                            Wait(0)
                            noty = false
                        end)
                    end
                elseif Config.Framework == "qbcore" then
                    local text = Config.Translations.objects.fullText:format('[E]', '[LEFT]', '[RIGHT]', '[BACKSPACE]')
                    exports["qb-core"]:DrawText(text)
                elseif Config.Framework == "esx" then
                    Framework.ShowHelpNotification(Config.Translations.objects.fullText:format('~INPUT_CONTEXT~', '~INPUT_CELLPHONE_LEFT~', '~INPUT_CELLPHONE_RIGHT~', '~INPUT_FRONTEND_RRIGHT~'))
                else
                    local text = Config.Translations.objects.fullText:format('[E]', '[LEFT]', '[RIGHT]', '[BACKSPACE]')
                    ShowHelpNotification("E", text)
                end
            end

            if anim.dict and anim.anim then
                if not IsEntityPlayingAnim(ped, anim.dict, anim.anim, 3) then
                    TaskPlayAnim(ped, anim.dict, anim.anim, 8.0, 8.0, -1, 51, false, false, false)
                end
            end

            if IsControlJustPressed(0, 38) then
                local objectCoords,  objectHeading
                if anim.dictponer and anim.animponer then
                    RequestAnimDict(anim.dictponer)

                    while not HasAnimDictLoaded(anim.dictponer) do
                        Wait(1)
                    end
                    TaskPlayAnim(ped, anim.dictponer, anim.animponer, 8.0, 8.0, -1, 0, false, false, false)
                    Wait(1000)
                    local forward = GetEntityForwardVector(ped)
                    objectCoords = (vector3(pcords.x, pcords.y, pcords.z - 1) + forward * 1.0)
                    objectHeading = GetEntityHeading(ped)
                    if currentobject.model == "prop_air_conelight" then
                        objectCoords = objectCoords - vector3(0, 0, 0.15)
                    end
                else
                    objectCoords = GetEntityCoords(prop)
                    objectHeading = GetEntityHeading(prop)
                end
                if currentobject.type == "speed" or currentobject.type == "plate" then
                    local p_c = GetEntityCoords(prop)
                    local p_f = GetEntityForwardVector(prop)
                    if currentobject.type == "speed" then
                        objectCoords = objectCoords - vector3(0, 0, 1)

                        OpenMenu('dialog', GetCurrentResourceName(), 'radarmaxspeed', {
                            title = Config.Translations.EnterMaxSpeed
                        }, function(data, menu)
                            if data and data.value and tonumber(data.value) then
                                TriggerServerEvent("origen_police:server:placeradar", {
                                    objectCoords = objectCoords,
                                    coords = objectCoords - p_f * 22.5,
                                    value = tonumber(data.value),
                                    type = 1
                                })
                                menu.close()
                            else
                                ShowNotification(Config.Translations.MustEnterNumber)
                            end
                        end, function(data, menu)
                            menu.close()
                        end)
                    else
                        local p = GenerateObject(currentobject.model, p_c)
                        SetEntityHeading(p, GetEntityHeading(PlayerPedId()))
                        local fwv = GetEntityForwardVector(p)
                        DeleteEntity(p)
                        OpenMenu('dialog', GetCurrentResourceName(), 'radarplate', {
                            title = Config.Translations.EnterPlate,
                        }, function(data, menu)
                            if data and data.value then
                                TriggerServerEvent("origen_police:server:placeradar", {
                                    objectCoords = objectCoords,
                                    coords = objectCoords - fwv * 22.5,
                                    value = data.value,
                                    type = 2
                                })
                                menu.close()
                            else
                                ShowNotification(Config.Translations.MustEnterNumber)
                            end
                        end, function(data, menu)
                            menu.close()
                        end)
                    end
                    TriggerServerEvent("origen_police:server:placeobj", currentobject.model, objectCoords,  objectHeading, not currentobject.physics, category)
                    DeleteEntity(prop)
                    if anim.dict and anim.anim then
                        ClearPedTasks(GetPlayerPed(-1))
                    end
                    break
                end
                TriggerServerEvent("origen_police:server:placeobj", currentobject.model, objectCoords,  objectHeading, not currentobject.physics, category)
                DeleteEntity(prop)
                if anim.dict and anim.anim then
                    ClearPedTasks(GetPlayerPed(-1))
                end
                break
            end

            if IsControlJustPressed(0, 174) then
                local newcurrentobjectnumber = currentobjectnumber - 1
                if value.Props[newcurrentobjectnumber] then
                    DeleteEntity(prop)
                    currentobjectnumber = newcurrentobjectnumber
                    currentobject = value.Props[currentobjectnumber]
                    prop = GenerateObject(currentobject.model, pcords)
                    AttachEntityToEntity(prop, ped, currentobject.bone, currentobject.x+0.0, currentobject.y+0.0, currentobject.z+0.0, currentobject.xr+0.0, currentobject.yr+0.0, currentobject.zr+0.0, true, true, false, true, 1, true)
                end
            end

            if IsControlJustPressed(0, 175) then
                local newcurrentobjectnumber = currentobjectnumber + 1
                if value.Props[newcurrentobjectnumber] then
                    DeleteEntity(prop)
                    currentobjectnumber = newcurrentobjectnumber
                    currentobject = value.Props[currentobjectnumber]
                    prop = GenerateObject(currentobject.model, pcords)
                    AttachEntityToEntity(prop, ped, currentobject.bone, currentobject.x+0.0, currentobject.y+0.0, currentobject.z+0.0, currentobject.xr+0.0, currentobject.yr+0.0, currentobject.zr+0.0, true, true, false, true, 1, true)
                end
            end

            if IsControlJustPressed(0, 202) then
                DeleteEntity(prop)
                if anim.dict and anim.anim then
                    ClearPedTasks(GetPlayerPed(-1))
                end
                break
            end
        end
        ClearPedTasks(PlayerPedId())
        HideHelpNotification()
        if GetResourceState('origen_hud') == 'started' then
            exports['origen_hud']:hideControls()
        elseif lib then 
            lib.hideTextUI() 
        end
    end)
end

function GenerateObject(p, c, a)
    if a then
        RequestAnimDict(a)

		while not HasAnimDictLoaded(a) do
			Wait(1)
		end
    end
    RequestModel(p)
    while not HasModelLoaded(p) do
        Wait(10)
    end
    return CreateObject(GetHashKey(p), c.x, c.y, c.z, false, true, true)
end

AddEventHandler('onResourceStop', function(resource) -- Mostly for development, restart the resource and it will put all the clothes back on.
	if resource == GetCurrentResourceName() then
		DeleteEntity(prop)
	end
end)

RegisterNetEvent("origen_police:client:placeradar", function(data)
    table.insert(Public.Radars, data)
end)

RegisterNetEvent("origen_police:client:removeradar", function(i)
    table.remove(Public.Radars, i)
end)

RegisterNetEvent("origen_police:client:placeobj", function(placerData, objectData)
    objectsData[placerData.source] = objectsData[placerData.source] or {}
    objectsData[placerData.source][placerData.objectId] = objectData
    
    local model = type(objectData.model) == "string" and GetHashKey(objectData.model) or objectData.model
    if not LoadModel(model, 5000) then
        print("Could not load model to place: " .. objectData.model)
        objects[placerData.source] = objects[placerData.source] or {}
        objects[placerData.source][placerData.objectId] = 1 -- Dummy value to prevent object ordering
        return
    end
    local obj = CreateObject(model, objectData.coords.x, objectData.coords.y, objectData.coords.z, false, true, false)
    SetEntityHeading(obj, objectData.heading)
    FreezeEntityPosition(obj, objectData.freeze)

    objects[placerData.source] = objects[placerData.source] or {}
    objects[placerData.source][placerData.objectId] = obj
end)

RegisterNetEvent("origen_police:client:rmveobj", function(placerData)
    Debuger("Remove object, placer data: ", json.encode(placerData))
    if objectsData[placerData.source] then
        objectsData[placerData.source][placerData.objectId] = nil
    end
    if objects[placerData.source] and objects[placerData.source][placerData.objectId] then
        local object = objects[placerData.source][placerData.objectId]
        if DoesEntityExist(object) then
            DeleteEntity(object)
        end
        objects[placerData.source][placerData.objectId] = nil
        if not next(objects[placerData.source]) then
            objects[placerData.source] = nil
        end
    end
end)