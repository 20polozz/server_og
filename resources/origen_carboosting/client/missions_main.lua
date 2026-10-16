local missionState = {
    active = false,
    key = nil,
    stages = {},
    currentStage = 1,
    editor = false,
}

local function startPropTrackerHack(stage)
    local minigame = stage and stage.metadata and stage.metadata.propTrackerMinigame or 'StartHacking'
    local difficulty = stage and stage.metadata and stage.metadata.propTrackerDifficulty or 'auto'
    local result = Custom.Minigame({
        category = 'prop',
        hacks = 1,
        fails = 1,
        minigame = minigame,
        minigameDifficulty = difficulty
    })
    TriggerServerEvent('origen_missions:server:PropDisableTracker', result)
end

local function isMissionFailedCondition(stage)
    if not stage or not stage.failConditions then
        return false
    end
    if stage.failConditions.onDeath and IsEntityDead(PlayerPedId()) then
        return true, "death"
    end
    return false, nil
end

local function removeStagePoint()
    if missionState.currentPoint then
        missionState.currentPoint:remove()
        missionState.currentPoint = nil
    end
end

local function startStage(index)
    removeStagePoint()
    local stage = missionState.stages[index]
    if not stage then
        TriggerServerEvent('origen_missions:server:CompleteMission')
        return
    end

    missionState.currentStage = index
    MissionAdapters.spawnForStage(stage)

    local coords = stage.spawn and stage.spawn.coords
    if not coords then
        TriggerServerEvent('origen_missions:server:AdvanceStage')
        return
    end

    local spawn = vector3(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
    local radius = (stage.objective and stage.objective.radius) or (Config.Missions and Config.Missions.DefaultObjectiveRadius) or 4.0

    missionState.currentPoint = lib.points.new({
        coords = spawn,
        distance = radius + 1.0,
        nearby = function(self)
            DrawMarker(1, spawn.x, spawn.y, spawn.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, radius * 2.0, radius * 2.0, 1.0, 216, 27, 85, 120, false, false, 2, false, nil, nil, false)
            local failed, reason = isMissionFailedCondition(stage)
            if failed then
                TriggerServerEvent('origen_missions:server:FailMission', reason)
                return
            end
            if self.currentDistance < radius and IsControlJustReleased(0, 38) then
                if stage.objective and stage.objective.objectiveType == 'prop' then
                    TriggerServerEvent('origen_missions:server:PropStealCompleted')
                elseif stage.objective and stage.objective.objectiveType == 'zone' and stage.objective.interaction == 'deliver' then
                    TriggerServerEvent('origen_missions:server:AdvanceStage')
                else
                    TriggerServerEvent('origen_missions:server:AdvanceStage')
                end
            end
        end,
        onEnter = function()
            if stage.objective and stage.objective.objectiveType == 'prop' then
                Custom.DrawText('E', 'Robar prop')
            elseif stage.objective and stage.objective.objectiveType == 'zone' and stage.objective.interaction == 'deliver' then
                Custom.DrawText('E', 'Entregar item robado')
            else
                Custom.DrawText('E', 'Interactuar con el objetivo')
            end
        end,
        onExit = function()
            Custom.HideText()
        end
    })
end

RegisterNetEvent('origen_missions:client:StartMission', function(data)
    missionState.active = true
    missionState.key = data.key
    missionState.stages = data.stages or {}
    missionState.currentStage = 1
    startStage(1)
end)

RegisterNetEvent('origen_missions:client:AdvanceStage', function(nextStage)
    startStage(nextStage)
end)

RegisterNetEvent('origen_missions:client:OnMissionFailed', function(data)
    removeStagePoint()
    MissionAdapters.cleanup()
    missionState.active = false
    missionState.key = nil
    missionState.stages = {}
    missionState.currentStage = 1
    Custom.HideText()
    local reason = data and data.reason or 'failed'
    if reason == 'death' then
        Internal.Notify('Mision fallida: has muerto durante el golpe.', 'error', 6000)
    elseif reason == 'disconnect' then
        Internal.Notify('Mision fallida: desconexion detectada.', 'error', 6000)
    end
end)

RegisterNetEvent('origen_missions:client:OnMissionCompleted', function(data)
    removeStagePoint()
    MissionAdapters.cleanup()
    missionState.active = false
    missionState.key = nil
    missionState.stages = {}
    missionState.currentStage = 1
    Custom.HideText()
end)

RegisterNetEvent('origen_missions:client:OpenPropTrackerHack', function(stage)
    startPropTrackerHack(stage or {})
end)

RegisterNetEvent('origen_missions:client:ToggleEditor', function()
    missionState.editor = not missionState.editor
    Internal.Notify(missionState.editor and 'Modo editor activado' or 'Modo editor desactivado', 'info', 4000)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then
        return
    end
    removeStagePoint()
    MissionAdapters.cleanup()
end)
