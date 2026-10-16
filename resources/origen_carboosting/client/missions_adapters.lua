MissionAdapters = MissionAdapters or {}

local spawnedEntity = nil

local function requestModel(model)
    local hash = model
    if type(hash) == 'string' then
        hash = GetHashKey(hash)
    end
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(0)
    end
    return hash
end

function MissionAdapters.cleanup()
    if spawnedEntity and DoesEntityExist(spawnedEntity) then
        DeleteEntity(spawnedEntity)
    end
    spawnedEntity = nil
end

function MissionAdapters.spawnForStage(stage)
    local objective = stage.objective or {}
    if objective.shouldSpawn == false then
        return true
    end
    local spawn = stage.spawn and stage.spawn.coords
    if not spawn then
        return true
    end

    local objectiveType = objective.objectiveType
    if objectiveType == 'vehicle' then
        local model = objective.model or 'blista'
        local hash = requestModel(model)
        local veh = CreateVehicle(hash, spawn.x, spawn.y, spawn.z, spawn.w or 0.0, true, true)
        SetVehicleFuelLevel(veh, 100.0)
        SetVehicleDoorsLocked(veh, 2)
        spawnedEntity = veh
        stage.runtimeEntity = veh
        return true
    elseif objectiveType == 'prop' then
        local model = objective.model or 'prop_box_wood01a'
        local hash = requestModel(model)
        local obj = CreateObject(hash, spawn.x, spawn.y, spawn.z, true, true, true)
        PlaceObjectOnGroundProperly(obj)
        spawnedEntity = obj
        stage.runtimeEntity = obj
        return true
    elseif objectiveType == 'ped' then
        local model = objective.model or 'g_m_y_mexgang_01'
        local hash = requestModel(model)
        local ped = CreatePed(4, hash, spawn.x, spawn.y, spawn.z, spawn.w or 0.0, true, true)
        SetPedKeepTask(ped, true)
        SetEntityAsMissionEntity(ped, true, true)
        spawnedEntity = ped
        stage.runtimeEntity = ped
        return true
    elseif objectiveType == 'zone' then
        return true
    end

    return true
end
