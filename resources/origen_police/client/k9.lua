-- Qbox Compatibility Helpers
-- Framework & Utility Helpers
local function GetPlayerData()
    if GetResourceState('qbx_core') == 'started' then
        return exports.qbx_core:GetPlayerData()
    end
    if FW_GetPlayerData then
        return FW_GetPlayerData()
    end
    return {}
end

local function GetClosestVehicle()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local vehicles = GetGamePool('CVehicle')
    local closestVehicle, closestDistance = nil, -1
    
    for _, vehicle in ipairs(vehicles) do
        local vehicleCoords = GetEntityCoords(vehicle)
        local distance = #(coords - vehicleCoords)
        
        if closestDistance == -1 or distance < closestDistance then
            closestVehicle = vehicle
            closestDistance = distance
        end
    end
    
    return closestVehicle
end

local function TriggerCallback(name, cb, ...)
    lib.callback(name, false, cb, ...)
end

local k9Ped = nil
local k9Blip = nil
local k9Name = nil
local isFollowing = false

local CommandFollow, CommandSit, CommandLie, CommandSearchPerson, CommandSearchVehicle, CommandVehicleToggle, ToggleK9, StopGuard, CommandGuard, CommandEscort, CommandPet, CommandAttack, CommandFindVictim, CommandPaw, CommandBeg, CommandBark, CommandComponent, CommandComponentTexture, CommandTexture, CommandProp, CommandPropTexture, CommandExtra

local function DelayedAction(time, cb)
    CreateThread(function()
        Wait(time)
        cb()
    end)
end

local function PlaySignalAnim(dict, anim)
    if not k9Ped then return end
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end
    TaskPlayAnim(k9Ped, dict, anim, 8.0, -8.0, -1, 1, 0, false, false, false)
end

local function PlayScenario(scenario)
    if not k9Ped then return end
    ClearPedTasks(k9Ped)
    TaskStartScenarioInPlace(k9Ped, scenario, 0, true)
end

local function Notify(msg, type)
    if GetResourceState('qbx_core') == 'started' then
        exports.qbx_core:Notify(msg, type or 'primary')
    else
        ShowNotification(msg, type)
    end
end

CommandFollow = function()
    if not k9Ped then return end
    ClearPedTasks(k9Ped)
    isFollowing = true
    Notify(Config.K9Lang.k9_following)
    TaskFollowToOffsetOfEntity(k9Ped, PlayerPedId(), 0.5, -1.0, 0.0, 5.0, -1, 1.0, true)
end

CommandSit = function()
    if not k9Ped then return end
    isFollowing = false
    PlayScenario("WORLD_DOG_SITTING_RETRIEVER")
end

CommandLie = function()
    if not k9Ped then return end
    isFollowing = false
    ClearPedTasks(k9Ped)
    local dict = "creatures@rottweiler@amb@sleep_in_kennel@"
    local anim = "sleep_in_kennel"
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end
    TaskPlayAnim(k9Ped, dict, anim, 8.0, -8.0, -1, 1, 0, false, false, false)
end

local function GetClosestPlayer()
    local pPed = PlayerPedId()
    local player, distance = FW_GetClosestPlayer(GetEntityCoords(pPed))
    if player ~= -1 and distance <= 3.0 then
        return GetPlayerServerId(player), GetPlayerPed(player)
    end
    return nil, nil
end

CommandSearchPerson = function()
    if not k9Ped then return end
    local jobData = Config.K9AllowedJobs[GetPlayerData().job.name]
    if not jobData or jobData.type ~= 'police' then return end

    local pId, tPed = GetClosestPlayer()
    if not tPed then 
        Notify(Config.K9Lang.no_one_nearby, 'error')
        return 
    end

    TaskGoToEntity(k9Ped, tPed, -1, 1.0, 2.0, 0, 0)
    DelayedAction(2000, function()
        local dict = "creatures@rottweiler@indication@"
        local anim = "indicate_low"
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do Wait(10) end
        TaskPlayAnim(k9Ped, dict, anim, 8.0, -8.0, -1, 1, 0, false, false, false)
        
        Wait(3000)
        TriggerServerEvent('origen_police:server:k9:CheckPerson', pId)
    end)
end

CommandSearchVehicle = function()
    if not k9Ped then return end

    local jobData = Config.K9AllowedJobs[GetPlayerData().job.name]
    if not jobData or jobData.type ~= 'police' then return end
    local pPed = PlayerPedId()
    local coords = GetEntityCoords(pPed)
    local vehicle = GetClosestVehicle()
    
    if not vehicle or #(GetEntityCoords(vehicle) - coords) > 5.0 then
        Notify(Config.K9Lang.vehicle_too_far, 'error')
        return
    end

    local boneIndex = GetEntityBoneIndexByName(vehicle, 'boot')
    if boneIndex == -1 then boneIndex = GetEntityBoneIndexByName(vehicle, 'wheel_lr') end
    
    local offset = GetWorldPositionOfEntityBone(vehicle, boneIndex)
    TaskGoToCoordAnyMeans(k9Ped, offset.x, offset.y, offset.z, 2.0, 0, 0, 786603, 0xbf800000)

    DelayedAction(3000, function()
        local dict = "creatures@rottweiler@indication@"
        local anim = "indicate_low"
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do Wait(10) end
        TaskPlayAnim(k9Ped, dict, anim, 8.0, -8.0, -1, 1, 0, false, false, false)

        Wait(3000)
        TriggerServerEvent('origen_police:server:k9:CheckVehicle', GetVehicleNumberPlateText(vehicle))
    end)
end

local isGuarding = false
local guardTarget = nil

StopGuard = function()
    if isGuarding then
        isGuarding = false
        guardTarget = nil
        if k9Ped then ClearPedTasks(k9Ped) end
        Notify(Config.K9Lang.stop_guard)
    end
end

local function MonitorGuard(targetPed, targetServerId)
    TriggerCallback('origen_police:server:k9:IsTargetPolice', function(isPolice)
        CreateThread(function()
            local initialPos = GetEntityCoords(targetPed)
            while isGuarding and DoesEntityExist(targetPed) and DoesEntityExist(k9Ped) do
                local currentPos = GetEntityCoords(targetPed)
                local speed = GetEntitySpeed(targetPed)
                local isArmed = IsPedArmed(targetPed, 7)
                
                if (speed > 1.5) or (isArmed and not isPolice) then
                    isGuarding = false 
                    ClearPedTasksImmediately(k9Ped)
                    
                    local k9Group = GetPedRelationshipGroupHash(k9Ped)
                    local targetGroup = GetPedRelationshipGroupHash(targetPed)
                    SetRelationshipBetweenGroups(5, k9Group, targetGroup)
                    SetRelationshipBetweenGroups(5, targetGroup, k9Group)
                    
                    SetPedCombatAttributes(k9Ped, 46, true) 
                    SetPedCombatAttributes(k9Ped, 0, false)
                    SetPedCombatAbility(k9Ped, 2)           
                    
                    TaskPutPedDirectlyIntoMelee(k9Ped, targetPed, 0.0, -1.0, 0.0, 0)
                    
                    Notify("¡Objetivo huyendo! Interviniendo...", 'error')
                    break
                end
                
                Wait(50) 
            end
        end)
    end, targetServerId)
end

CommandGuard = function()
    if not k9Ped then return end

    local jobData = Config.K9AllowedJobs[GetPlayerData().job.name]
    if not jobData or jobData.type ~= 'police' then return end
    local pId, tPed = GetClosestPlayer()
    if not tPed then 
        Notify(Config.K9Lang.no_one_nearby, 'error')
        return 
    end
    
    isFollowing = false
    isGuarding = true
    guardTarget = tPed
    
    Notify(Config.K9Lang.guard_person .. "...", 'success')
    
    TaskGoToEntity(k9Ped, tPed, -1, 1.5, 5.0, 0, 0)
    
    DelayedAction(10, function()
        SetPedCombatAttributes(k9Ped, 46, true) 
        SetPedCombatAttributes(k9Ped, 5, true)
        SetPedCombatAttributes(k9Ped, 17, true) 
        SetPedCombatAttributes(k9Ped, 0, false) 
        SetPedCombatAbility(k9Ped, 2) 
        SetPedCombatMovement(k9Ped, 3) 
        SetPedCombatRange(0) 

        local dict = "creatures@rottweiler@amb@world_dog_sitting@base"
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do Wait(10) end
        TaskPlayAnim(k9Ped, dict, "base", 8.0, -8.0, -1, 1, 0, false, false, false)
        
        MonitorGuard(tPed, pId)
    end)
end

CommandEscort = function()
    if not k9Ped then return end

    local jobData = Config.K9AllowedJobs[GetPlayerData().job.name]
    if not jobData or jobData.type ~= 'police' then return end
    local pId, tPed = GetClosestPlayer()
    if not tPed then 
        Notify(Config.K9Lang.no_one_nearby, 'error')
        return 
    end
    
    isFollowing = false
    StopGuard()
    
    ClearPedTasks(k9Ped)
    TaskFollowToOffsetOfEntity(k9Ped, tPed, 0.5, 0.0, 0.0, 7.0, -1, 1.0, true)
end

local function GetDoorForSeat(seat)
    if seat == -1 then return 0 end
    if seat == 0 then return 1 end
    if seat == 1 then return 2 end
    if seat == 2 then return 3 end
    return 0
end

CommandVehicleToggle = function()
    if not k9Ped then return end
    local pPed = PlayerPedId()
    local dogInVeh = IsPedInAnyVehicle(k9Ped, false)
    local pInVeh = IsPedInAnyVehicle(pPed, false)
    local vehicle = pInVeh and GetVehiclePedIsIn(pPed, false) or (dogInVeh and GetVehiclePedIsIn(k9Ped, false))
    
    if not vehicle or vehicle == 0 then
        vehicle = GetClosestVehicle()
    end

    if not DoesEntityExist(vehicle) or vehicle == 0 then
        Notify(Config.K9Lang.no_vehicle_nearby, 'error')
        return
    end

    if dogInVeh then
        local seat = -1
        local maxPassengers = GetVehicleMaxNumberOfPassengers(vehicle)
        for i = -1, maxPassengers do
            if GetPedInVehicleSeat(vehicle, i) == k9Ped then
                seat = i
                break
            end
        end
        
        local door = GetDoorForSeat(seat)
        
        SetVehicleDoorOpen(vehicle, door, false, false)
        Wait(1000)
        
        ClearPedTasksImmediately(k9Ped)
        TaskLeaveVehicle(k9Ped, vehicle, 16) 
        Wait(200)
        
        local off = GetOffsetFromEntityInWorldCoords(vehicle, (door == 1 or door == 3) and 1.5 or -1.5, -1.0, 0.0)
        
        SetEntityCoords(k9Ped, off.x, off.y, off.z + 0.5) 
        SetEntityHeading(k9Ped, GetEntityHeading(vehicle))
        Wait(50)
        PlaceObjectOnGroundProperly(k9Ped)
        ClearPedTasksImmediately(k9Ped) 
        
        Wait(1000)
        SetVehicleDoorShut(vehicle, door, false)
        
        CommandFollow()
    else
        local maxSeats = GetVehicleMaxNumberOfPassengers(vehicle)
        local targetSeat = -1
        
        if maxSeats >= 3 then
            if IsVehicleSeatFree(vehicle, 1) then targetSeat = 1 
            elseif IsVehicleSeatFree(vehicle, 2) then targetSeat = 2 end
        end
        
        if targetSeat == -1 then
            for i=0, maxSeats-1 do
                if IsVehicleSeatFree(vehicle, i) then
                    targetSeat = i
                    break
                end
            end
        end
        
        if targetSeat ~= -1 then
            local door = GetDoorForSeat(targetSeat)
            
            local doorCoords = GetEntryPositionOfDoor(vehicle, door)
            TaskGoToCoordAnyMeans(k9Ped, doorCoords.x, doorCoords.y, doorCoords.z, 2.0, 0, 0, 786603, 0xbf800000)
            
            local dist = #(GetEntityCoords(k9Ped) - doorCoords)
            local timeout = 5000
            while dist > 1.5 and timeout > 0 do
                Wait(100)
                dist = #(GetEntityCoords(k9Ped) - doorCoords)
                timeout = timeout - 100
            end
            
            local vehDict = "creatures@rottweiler@in_vehicle@std_car"
            RequestAnimDict(vehDict)
            while not HasAnimDictLoaded(vehDict) do Wait(10) end

            SetVehicleDoorOpen(vehicle, door, false, false)
            Wait(300)

            isFollowing = false
            StopGuard()
            ClearPedTasksImmediately(k9Ped)
            TaskTurnPedToFaceEntity(k9Ped, vehicle, 500)
            Wait(500)
            
            TaskWarpPedIntoVehicle(k9Ped, vehicle, targetSeat)
            SetPedConfigFlag(k9Ped, 184, true) 
            
            Wait(300) 
            
            ClearPedTasks(k9Ped)
            TaskPlayAnim(k9Ped, vehDict, "sit", 8.0, -8.0, -1, 1, 0, false, false, false)
            
            Wait(1000)
            SetVehicleDoorShut(vehicle, door, false)
            
        else
            Notify(Config.K9Lang.no_seats, "error")
        end
    end
end

local function SaveK9Skin()
    if not k9Ped then return end
    
    local skin = {
        comps = {},
        props = {},
        extras = {},
        texture = 0
    }
    
    skin.texture = GetPedTextureVariation(k9Ped, 0)
    
    for i = 0, 11 do
        skin.comps[tostring(i)] = {
            drawable = GetPedDrawableVariation(k9Ped, i),
            texture = GetPedTextureVariation(k9Ped, i)
        }
    end
    
    for i = 0, 5 do
        local idx = GetPedPropIndex(k9Ped, i)
        if idx ~= -1 then
            skin.props[tostring(i)] = {
                drawable = idx,
                texture = GetPedPropTextureIndex(k9Ped, i)
            }
        end
    end
    
    for i = 1, 12 do
        if DoesExtraExist(k9Ped, i) then
            skin.extras[tostring(i)] = IsPedExtraTurnedOn(k9Ped, i)
        end
    end
    
    TriggerServerEvent('origen_police:server:k9:SaveDogSkin', skin)
end

CommandTexture = function(dir)
    if not k9Ped then return end
    dir = dir or 1
    local currentTexture = GetPedTextureVariation(k9Ped, 0)
    local maxTextures = GetNumberOfPedTextureVariations(k9Ped, 0, 0) 
    local newTexture = currentTexture + dir
    if newTexture >= maxTextures then
        newTexture = 0
    elseif newTexture < 0 then
        newTexture = maxTextures - 1
    end
    
    SetPedComponentVariation(k9Ped, 0, 0, newTexture, 0)
    SaveK9Skin()
end

CommandComponent = function(compId, dir)
    if not k9Ped then return end
    dir = dir or 1
    local current = GetPedDrawableVariation(k9Ped, compId)
    local max = GetNumberOfPedDrawableVariations(k9Ped, compId)
    
    local new = current + dir
    if new >= max then new = 0 
    elseif new < 0 then new = max - 1 end
    
    SetPedComponentVariation(k9Ped, compId, new, 0, 0)
    SaveK9Skin()
end

CommandComponentTexture = function(compId, dir)
    if not k9Ped then return end
    dir = dir or 1
    local drawable = GetPedDrawableVariation(k9Ped, compId)
    local current = GetPedTextureVariation(k9Ped, compId)
    local max = GetNumberOfPedTextureVariations(k9Ped, compId, drawable)
    
    local new = current + dir
    if new >= max then new = 0 
    elseif new < 0 then new = max - 1 end
    
    SetPedComponentVariation(k9Ped, compId, drawable, new, 0)
    SaveK9Skin()
end

CommandProp = function(propId, dir)
    if not k9Ped then return end
    dir = dir or 1
    local current = GetPedPropIndex(k9Ped, propId)
    local max = GetNumberOfPedPropDrawableVariations(k9Ped, propId)
    
    local new = current + dir
    if new >= max then new = -1 
    elseif new < -1 then new = max - 1 end
    
    if new == -1 then
        ClearPedProp(k9Ped, propId)
    else
        SetPedPropIndex(k9Ped, propId, new, 0, true)
    end
    SaveK9Skin()
end

CommandPropTexture = function(propId, dir)
    if not k9Ped then return end
    dir = dir or 1
    local drawable = GetPedPropIndex(k9Ped, propId)
    if drawable == -1 then return Notify("No hay accesorio puesto.", "error") end
    
    local current = GetPedPropTextureIndex(k9Ped, propId)
    local max = GetNumberOfPedTextureVariations(k9Ped, propId, drawable)
    
    local new = current + dir
    if new >= max then new = 0 
    elseif new < 0 then new = max - 1 end
    
    SetPedPropIndex(k9Ped, propId, drawable, new, true)
    SaveK9Skin()
end

CommandExtra = function(extraId)
    if not k9Ped then return end
    
    if DoesExtraExist(k9Ped, extraId) then
        if IsPedExtraTurnedOn(k9Ped, extraId) then
            SetPedExtra(k9Ped, extraId, 1) 
        else
            SetPedExtra(k9Ped, extraId, 0) 
        end
        SaveK9Skin()
    else
        Notify("Extra " .. extraId .. " no disponible en este modelo.", 'error')
    end
end

CommandPet = function()
    if not k9Ped then return end
    local pPed = PlayerPedId()
    local d1 = GetEntityCoords(k9Ped)
    local d2 = GetEntityCoords(pPed)
    
    if #(d1 - d2) > 2.0 then
        Notify("Acércate más a tu K9.", 'error')
        return
    end

    StopGuard()
    
    TaskTurnPedToFaceEntity(k9Ped, pPed, 1000)
    TaskTurnPedToFaceEntity(pPed, k9Ped, 1000)
    Wait(1000)
    
    local dict = "creatures@rottweiler@tricks@"
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(0) end
    
    TaskPlayAnim(pPed, dict, "petting_franklin", 8.0, -8.0, -1, 0, 0, false, false, false)
    TaskPlayAnim(k9Ped, dict, "petting_chop", 8.0, -8.0, -1, 0, 0, false, false, false)
    
    Notify("Buen chico...", 'success')
    
    Wait(5000)
    ClearPedTasks(pPed)
end

CommandAttack = function()
    if not k9Ped then return end
    
    local playerData = GetPlayerData()
    if not playerData.job.onduty then
        Notify("Debes estar de servicio para ordenar un ataque.", 'error')
        return
    end
    
    local pPed = PlayerPedId()
    local targetPed = nil
    
    local aimed, entity = GetEntityPlayerIsFreeAimingAt(PlayerId())
    if aimed and IsEntityAPed(entity) and not IsPedDeadOrDying(entity, true) then
        targetPed = entity
    end
    
    if targetPed then
        isFollowing = false
        StopGuard()
        
        SetEntityNoCollisionEntity(k9Ped, pPed, true)
        TaskCombatPed(k9Ped, targetPed, 0, 16)
        
        PlaySoundFromEntity(-1, "Bark", k9Ped, "ALS_General_Dog_Barks_SoundSet", false, 0)
        
        Notify("¡K9 atacando al objetivo!", 'success')
        
        CreateThread(function()
            local active = true
            while active and DoesEntityExist(targetPed) and DoesEntityExist(k9Ped) do
                if IsPedDeadOrDying(targetPed, true) then
                    active = false
                    CommandFollow()
                    Notify("Objetivo neutralizado. K9 regresando.", 'primary')
                elseif isFollowing then 
                    active = false
                elseif not IsPedInCombat(k9Ped, targetPed) then
                   TaskCombatPed(k9Ped, targetPed, 0, 16)
                end
                Wait(1000)
            end
        end)
    else
        Notify("No se encontró ningún objetivo válido para atacar.", 'error')
    end
end

RegisterCommand('k9attack', function()
    CommandAttack()
end, false)
RegisterKeyMapping('k9attack', 'K9: ordenar el ataque', 'keyboard', 'G')

CommandFindVictim = function()
    if not k9Ped then return end
    local pPed = PlayerPedId()
    local pCoords = GetEntityCoords(pPed)
    
    local players = GetActivePlayers()
    local closestVictim = -1
    local minDistance = 150.0
    
    for _, player in ipairs(players) do
        local tPed = GetPlayerPed(player)
        if tPed ~= pPed then
            local tCoords = GetEntityCoords(tPed)
            local dist = #(pCoords - tCoords)
            if dist < minDistance then
                minDistance = dist
                closestVictim = tPed
            end
        end
    end
    
    if closestVictim ~= -1 then
        isFollowing = false
        StopGuard()
        Notify("Buscando víctima...", 'primary')
        
        CreateThread(function()
            local victimFound = false
            local lastTargetPos = nil
            
            while DoesEntityExist(closestVictim) and not victimFound and not isFollowing do
                local vCoords = GetEntityCoords(closestVictim)
                local kCoords = GetEntityCoords(k9Ped)
                local dist = #(kCoords - vCoords)

                if not lastTargetPos or #(lastTargetPos - vCoords) > 2.0 or GetEntitySpeed(k9Ped) < 0.1 then
                    TaskGoToEntity(k9Ped, closestVictim, -1, 1.0, 3.0, 0, 0)
                    lastTargetPos = vCoords
                end
                
                if dist < 3.5 then
                    victimFound = true
                    ClearPedTasksImmediately(k9Ped)
                    local dict = "creatures@rottweiler@amb@world_dog_barking@idle_a"
                    RequestAnimDict(dict)
                    while not HasAnimDictLoaded(dict) do Wait(10) end
                    TaskPlayAnim(k9Ped, dict, "idle_a", 8.0, -8.0, 3000, 0, 0, false, false, false)
                    Wait(3000)
                    CommandSit()
                    Notify("¡Víctima localizada!", 'success')
                end
                Wait(500)
            end
        end)
    end
end

CommandPaw = function()
    if not k9Ped then return end
    StopGuard()
    
    local dict = "creatures@rottweiler@tricks@"
    local anim = "paw_right_loop"
    
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end
    
    TaskPlayAnim(k9Ped, dict, anim, 8.0, -8.0, -1, 1, 0, false, false, false)
    Notify("Dando la pata...", 'success')
end

CommandBeg = function()
    if not k9Ped then return end
    StopGuard()
    
    local dict = "creatures@rottweiler@tricks@"
    local anim = "beg_loop"
    
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end
    
    TaskPlayAnim(k9Ped, dict, anim, 8.0, -8.0, -1, 1, 0, false, false, false)
    Notify("Subiendo...", 'success')
end

CommandBark = function()
    if not k9Ped then return end
    StopGuard()
    
    local dict = "creatures@rottweiler@amb@world_dog_barking@idle_a"
    local anim = "idle_a"
    
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end
    
    TaskPlayAnim(k9Ped, dict, anim, 8.0, -8.0, -1, 1, 0, false, false, false)
    Notify("Ladrando...", 'success')
end

ToggleK9 = function()
    local playerData = GetPlayerData()
    local jobName = playerData.job.name
    
    if not Config.K9AllowedJobs[jobName] and string.sub(jobName, 1, 3) == "off" then
        local onDutyName = string.sub(jobName, 4)
        if Config.K9AllowedJobs[onDutyName] then
            jobName = onDutyName
        end
    end

    local jobData = Config.K9AllowedJobs[jobName]
    local jobGrade = playerData.job.grade.level
    
    if not jobData or jobGrade < jobData.minGrade then 
        Notify(Config.K9Lang.k9_spawn_error, 'error')
        return 
    end

    if k9Ped then
        DeleteEntity(k9Ped)
        OrigenMapa.Quitar(k9Blip)
        k9Ped = nil
        isFollowing = false
        TriggerServerEvent('origen_police:server:k9:K9Status', false)
        Notify(Config.K9Lang.dismiss_k9)
    else
        local isOffDuty = (playerData.job.onduty == false) or (string.sub(playerData.job.name, 1, 3) == "off")

        local spawnPos = nil
        local spawnHeading = 0.0
        local doorIndex = 2
        local nearVeh = 0

        if not isOffDuty then
            local pPed = PlayerPedId()
            local pCoords = GetEntityCoords(pPed)
            local vehicles = GetGamePool('CVehicle')
            local validVeh = false
            local closestDist = 20.0

            for _, vehicle in ipairs(vehicles) do
                local vCoords = GetEntityCoords(vehicle)
                local dist = #(pCoords - vCoords)
                
                if dist < closestDist then
                    local vModel = GetEntityModel(vehicle)
                    for _, name in ipairs(Config.K9AllowedVehicles) do
                        if vModel == GetHashKey(name) then
                            nearVeh = vehicle
                            closestDist = dist
                            validVeh = true
                            break
                        end
                    end
                end
            end
            
            if not validVeh then
                Notify("Debes estar cerca de un vehículo patrulla K9.", 'error')
                return
            end
            
            local vehCoords = GetEntityCoords(nearVeh)
            local vehForward = GetEntityForwardVector(nearVeh)
            local vehRight = vector3(-vehForward.y, vehForward.x, 0.0)
            local toPlayer = pCoords - vehCoords
            local dotProduct = toPlayer.x * vehRight.x + toPlayer.y * vehRight.y
            
            local spawnOffset = vector3(-2.0, -1.0, -1.0)
            
            if dotProduct > 0 then
                doorIndex = 3
                spawnOffset = vector3(2.0, -1.0, -1.0)
            end
            
            SetVehicleDoorOpen(nearVeh, doorIndex, false, false)
            spawnPos = GetOffsetFromEntityInWorldCoords(nearVeh, spawnOffset.x, spawnOffset.y, spawnOffset.z)
            spawnHeading = GetEntityHeading(nearVeh)
        else
            local pPed = PlayerPedId()
            spawnPos = GetOffsetFromEntityInWorldCoords(pPed, 1.0, 1.0, 0.0)
            spawnHeading = GetEntityHeading(pPed)
        end

        TriggerCallback('origen_police:server:k9:GetDogData', function(data)
            data = data or {}
            k9Name = data.name
            
            if not k9Name or k9Name == "" then
                local input = exports['org-input']:ShowInput({
                    header = 'Nombre del K9',
                    icon = 'fas fa-dog',
                    inputs = {
                        { name = 'name', text = 'Introduce el nombre de tu perro', type = 'text', isRequired = true, icon = 'fas fa-paw' }
                    }
                })
                
                if input and input.name and #input.name > 0 then
                    k9Name = input.name
                    TriggerServerEvent('origen_police:server:k9:SetDogName', k9Name)
                else
                    Notify("Debes asignar un nombre al K9 para desplegarlo.", 'error')
                    return
                end
            end
            
            local modelName = jobData.model or Config.K9DefaultModel
            local hash = GetHashKey(modelName)
            if not hash then modelName = Config.K9DefaultModel end
            hash = GetHashKey(modelName)
            RequestModel(hash)
            while not HasModelLoaded(hash) do Wait(10) end
    
            k9Ped = CreatePed(28, hash, spawnPos.x, spawnPos.y, spawnPos.z, spawnHeading, true, true)
            TriggerServerEvent('origen_police:server:k9:K9Status', true)
            
            Wait(100)
            
            SetEntityAsMissionEntity(k9Ped, true, true)
            
            local moveClip = "ROTTWEILER@MOVE"
            if modelName == 'a_c_dalmatian' or modelName == 'a_c_husky' then
                moveClip = "husky@move"
            elseif modelName == 'a_c_retriever' then
                moveClip = "retriever@move"
            end
            
            RequestAnimSet(moveClip)
            while not HasAnimSetLoaded(moveClip) do Wait(10) end
            SetPedMovementClipset(k9Ped, moveClip, 1.0)
            
            TaskGoToEntity(k9Ped, PlayerPedId(), -1, 1.5, 3.0, 0, 0)
            
            Citizen.SetTimeout(2500, function()
                if DoesEntityExist(nearVeh) and not isOffDuty then
                    SetVehicleDoorShut(nearVeh, doorIndex, false)
                end
            end)
            
            if data.skin then
                if data.skin.texture then
                    SetPedComponentVariation(k9Ped, 0, 0, data.skin.texture, 0)
                end

                if data.skin.comps then
                    for k, v in pairs(data.skin.comps) do
                        local compId = tonumber(k)
                        if compId then
                            SetPedComponentVariation(k9Ped, compId, v.drawable, v.texture, 0)
                        end
                    end
                end
                
                if data.skin.props then
                    for k, v in pairs(data.skin.props) do
                        local propId = tonumber(k)
                        if propId then
                            SetPedPropIndex(k9Ped, propId, v.drawable, v.texture, true)
                        end
                    end
                end
                
                if data.skin.extras then
                    for k, v in pairs(data.skin.extras) do
                        local extraId = tonumber(k)
                        if extraId then
                            SetPedExtra(k9Ped, extraId, v and 0 or 1)
                        end
                    end
                end
            else
                SetPedComponentVariation(k9Ped, 0, 0, 0, 0)
            end
            
            SetPedCanRagdoll(k9Ped, true)
            SetEntityInvincible(k9Ped, false)
            SetPedFleeAttributes(k9Ped, 0, 0)
            SetBlockingOfNonTemporaryEvents(k9Ped, true)
            SetPedCombatAttributes(k9Ped, 46, true)
            SetPedCombatAttributes(k9Ped, 5, true) 
            SetPedCombatAttributes(k9Ped, 17, true) 
            SetPedFleeAttributes(k9Ped, 0, 0)
            
            SetPedMoveRateOverride(k9Ped, 1.50)
            SetPedConfigFlag(k9Ped, 60, true)
    
            --[[ El perro, en el mapa. Un punto de origen_map con `entidad`,
                 que es lo que hace que siga al animal y que se borre solo
                 cuando el animal deja de existir. ]]
            k9Blip = 'k9'

            OrigenMapa.Poner(k9Blip, {
                entidad = k9Ped,
                cat = 'emergencias',
                icono = 'huella',
                nombre = k9Name,
            })
    
            if GetResourceState('ox_target') == 'started' then
                exports.ox_target:addLocalEntity(k9Ped, {
                    {
                        name = 'k9_follow',
                        icon = 'fa-solid fa-paw',
                        label = Config.K9Lang.follow,
                        onSelect = function() CommandFollow() end
                    },
                    {
                        name = 'k9_sit',
                        icon = 'fa-solid fa-arrow-down',
                        label = Config.K9Lang.sit,
                        onSelect = function() CommandSit() end
                    },
                    {
                        name = 'k9_lie',
                        icon = 'fa-solid fa-bed',
                        label = Config.K9Lang.lie_down,
                        onSelect = function() CommandLie() end
                    },
                    {
                        name = 'k9_vehicle',
                        icon = 'fa-solid fa-car',
                        label = Config.K9Lang.enter_vehicle,
                        onSelect = function() CommandVehicleToggle() end
                    },
                    {
                        name = 'k9_dismiss',
                        icon = 'fa-solid fa-xmark',
                        label = Config.K9Lang.dismiss_k9,
                        onSelect = function() ToggleK9() end
                    }
                })
            end
    
            Notify(k9Name .. " listo para el servicio.", 'success')
            Wait(100)
            CommandFollow()
        end)
    end
end

RegisterNetEvent('origen_police:client:k9:UseWhistle', function()
    local pPed = PlayerPedId()
    if not IsPedInAnyVehicle(pPed, false) then
        local dict = "rcmnigel1c"
        local anim = "hailing_whistle_waive_a"
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do Wait(10) end
        TaskPlayAnim(pPed, dict, anim, 8.0, -8.0, 2500, 49, 0, false, false, false)
    end
    ToggleK9()
end)

RegisterNetEvent('origen_police:client:k9:ToggleK9', function() ToggleK9() end)
RegisterNetEvent('origen_police:client:k9:CommandFollow', function() StopGuard() CommandFollow() end)
RegisterNetEvent('origen_police:client:k9:CommandSit', function() StopGuard() CommandSit() end)
RegisterNetEvent('origen_police:client:k9:CommandLie', function() StopGuard() CommandLie() end)
RegisterNetEvent('origen_police:client:k9:CommandBark', function() CommandBark() end)
RegisterNetEvent('origen_police:client:k9:CommandSearchPerson', function() CommandSearchPerson() end)
RegisterNetEvent('origen_police:client:k9:CommandSearchVehicle', function() CommandSearchVehicle() end)
RegisterNetEvent('origen_police:client:k9:CommandAttack', function() CommandAttack() end)
RegisterNetEvent('origen_police:client:k9:CommandVehicleToggle', function() CommandVehicleToggle() end)
RegisterNetEvent('origen_police:client:k9:CommandPet', function() CommandPet() end)
RegisterNetEvent('origen_police:client:k9:CommandGuard', function() CommandGuard() end)
RegisterNetEvent('origen_police:client:k9:CommandEscort', function() CommandEscort() end)
RegisterNetEvent('origen_police:client:k9:CommandPaw', function() CommandPaw() end)
RegisterNetEvent('origen_police:client:k9:CommandBeg', function() CommandBeg() end)
RegisterNetEvent('origen_police:client:k9:CommandFindVictim', function() CommandFindVictim() end)

RegisterNetEvent('origen_police:client:k9:CommandTexture', function(dir) CommandTexture(dir) end)
RegisterNetEvent('origen_police:client:k9:CommandComponent', function(id, dir) CommandComponent(tonumber(id), dir) end)
RegisterNetEvent('origen_police:client:k9:CommandComponentTexture', function(id, dir) CommandComponentTexture(tonumber(id), dir) end)
RegisterNetEvent('origen_police:client:k9:CommandProp', function(id, dir) CommandProp(tonumber(id), dir) end)
RegisterNetEvent('origen_police:client:k9:CommandPropTexture', function(id, dir) CommandPropTexture(tonumber(id), dir) end)
RegisterNetEvent('origen_police:client:k9:CommandExtra', function(id) CommandExtra(tonumber(id)) end)

RegisterNetEvent('origen_police:client:k9:NotifyResult', function(items, type)
    if items and #items > 0 then
        PlaySoundFrontend(-1, "Beep_Red", "DLC_HEIST_HACKING_SNAKE_SOUNDS", 1)
        
        local dict = "creatures@rottweiler@amb@world_dog_barking@idle_a"
        local anim = "idle_a"
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do Wait(10) end
        
        TaskPlayAnim(k9Ped, dict, anim, 8.0, -8.0, 3000, 0, 0, false, false, false)
        Wait(500)
        ClearPedTasksImmediately(k9Ped)
        CommandSit()

        local itemList = ""
        for i, item in ipairs(items) do
            itemList = itemList .. "- " .. item .. "\n"
        end

        local resultMenu = {
            {
                header = (type == 'person' and Config.K9Lang.search_person or Config.K9Lang.search_vehicle),
                icon = 'fas fa-exclamation-triangle',
                txt = "Se han encontrado rastros de:",
                isMenuHeader = true
            }
        }
        
        table.insert(resultMenu, {
            header = "Objeto o sustancia sospechosa",
            icon = 'fas fa-search',
            params = { isAction = true, event = function() end }
        })

        OpenMenu(resultMenu)
    else
        Notify(Config.K9Lang.nothing_found, 'primary')
        CommandFollow()
    end
end)

RegisterNetEvent('origen_police:client:k9:UpdateXP', function(newXp)
    -- Notificar al jugador en pantalla
    Notify("Tu K9 ha ganado XP. Total actual: " .. newXp, 'success')
    -- Actualizar la NUI si está abierta
    SendNUIMessage({
        action = 'updateK9XP',
        xp = newXp
    })
end)

RegisterNetEvent('origen_police:client:k9:SyncVehicles', function(vehicles)
    Config.K9AllowedVehicles = vehicles
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('origen_police:server:k9:RequestVehicleSync')
end)

AddEventHandler('qbx_core:client:playerLoaded', function()
    TriggerServerEvent('origen_police:server:k9:RequestVehicleSync')
end)

CreateThread(function()
    while true do
        Wait(1000)
        local playerData = GetPlayerData()
        if playerData and playerData.citizenid then
            TriggerServerEvent('origen_police:server:k9:RequestVehicleSync')
            break
        end
    end
end)

exports('GetK9AppearanceData', function()
    if not k9Ped or not DoesEntityExist(k9Ped) then return nil end
    
    local data = {
        skin = {
            texture = GetPedTextureVariation(k9Ped, 0),
            maxTexture = GetNumberOfPedTextureVariations(k9Ped, 0, 0)
        },
        components = {},
        props = {},
        extras = {}
    }
    
    for i = 0, 11 do
        local drawable = GetPedDrawableVariation(k9Ped, i)
        local maxDrawable = GetNumberOfPedDrawableVariations(k9Ped, i)
        if maxDrawable > 0 then
            data.components[tostring(i)] = {
                drawable = drawable,
                maxDrawable = maxDrawable,
                texture = GetPedTextureVariation(k9Ped, i),
                maxTexture = GetNumberOfPedTextureVariations(k9Ped, i, drawable)
            }
        end
    end
    
    for i = 0, 5 do
        local drawable = GetPedPropIndex(k9Ped, i)
        local maxDrawable = GetNumberOfPedPropDrawableVariations(k9Ped, i)
        if maxDrawable > 0 then
            data.props[tostring(i)] = {
                drawable = drawable,
                maxDrawable = maxDrawable,
                texture = GetPedPropTextureIndex(k9Ped, i),
                maxTexture = GetNumberOfPedPropTextureVariations(k9Ped, i, drawable)
            }
        end
    end
    
    for i = 1, 12 do
        if DoesExtraExist(k9Ped, i) then
            data.extras[tostring(i)] = IsPedExtraTurnedOn(k9Ped, i)
        end
    end
    
    return data
end)



RegisterNetEvent('origen_police:client:k9:UpdateSkills', function(skills)
    SendNUIMessage({
        action = 'updateK9Skills',
        skills = skills
    })
end)

-- Evento disparado por el servidor cuando un admin hace /k9reset
-- Limpia el estado en memoria del cliente y resetea la NUI
RegisterNetEvent('origen_police:client:k9:ForceResetState', function()
    k9Name = nil
    -- Resetear NUI
    SendNUIMessage({ action = 'updateK9XP',     xp     = 0  })
    SendNUIMessage({ action = 'updateK9Skills', skills = {} })
end)
