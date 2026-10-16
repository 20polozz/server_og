if Config.Progressbar ~= 'default' then return end
local Action = {
    name = "",
    duration = 0,
    label = "",
    useWhileDead = false,
    canCancel = true,
	disarm = true,
    controlDisables = {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = false,
    },
    animation = {
        animDict = nil,
        anim = nil,
        flags = 0,
        task = nil,
    },
    prop = {
        model = nil,
        bone = nil,
        coords = { x = 0.0, y = 0.0, z = 0.0 },
        rotation = { x = 0.0, y = 0.0, z = 0.0 },
    },
    propTwo = {
        model = nil,
        bone = nil,
        coords = { x = 0.0, y = 0.0, z = 0.0 },
        rotation = { x = 0.0, y = 0.0, z = 0.0 },
    },
}

local isDoingAction = false
local disableMouse = false
local wasCancelled = false
local isAnim = false
local isProp = false
local isPropTwo = false
local prop_net = nil
local propTwo_net = nil
local runProgThread = false
--- Cada barra lleva su numero y su hora de fin. Los hilos y avisos de una
--- barra vieja no tocan la siguiente.
local vueltaBarra = 0
local terminaEn = 0

RegisterNetEvent('origen_inventory:progressbar:ToggleBusyness', function(bool)
    isDoingAction = bool
end)

function Progress(action, finish)
	Process(action, nil, nil, finish)
end

function ProgressWithStartEvent(action, start, finish)
	Process(action, start, nil, finish)
end

function ProgressWithTickEvent(action, tick, finish)
	Process(action, nil, tick, finish)
end

function ProgressWithStartAndTick(action, start, tick, finish)
	Process(action, start, tick, finish)
end

function Process(action, start, tick, finish)
    if not action then return end
    Action = action
    local ped = PlayerPedId()
    if not IsEntityDead(ped) or Action.useWhileDead then
        if not isDoingAction then
            isDoingAction = true
            wasCancelled = false
            isAnim = false
            isProp = false
            isPropTwo = false

            vueltaBarra = vueltaBarra + 1
            local mia = vueltaBarra
            local duracion = tonumber(Action.duration) or 5000
            terminaEn = GetGameTimer() + duracion

            ActionStart()
            -- El dibujo es del HUD; con pcall, que si el HUD no esta la barra
            -- tiene que acabar igual.
            pcall(function() exports.origen_hud:ShowProgress(duracion, Action.label) end)

            --[[ LA BARRA SE TERMINA AQUI, CON SU PROPIO RELOJ (27/09).

                 Antes solo terminaba cuando la pagina del HUD acababa su
                 animacion y llamaba a `finishProgress`. Si ese aviso no
                 llegaba —HUD en modo cine (el anillo no se monta), el HUD
                 reiniciado o recargandose, la animacion frenada con el juego
                 en segundo plano— la barra seguia viva y DisableActions
                 bloqueaba la camara hasta el tope de seguridad, sin ninguna
                 pantalla con el raton: el «raton preso» de los videos, con el
                 radial abriendo y la camara quieta. Visto en el F8 de un
                 jugador: «[PROGRESSBAR] Safety timeout reached». ]]
            CreateThread(function()
                Wait(duracion)
                if isDoingAction and vueltaBarra == mia then
                    Finish()
                end
            end)

            CreateThread(function ()
                if start ~= nil then
                    start()
                end
                while isDoingAction do
                    Wait(1)
                    if tick ~= nil then
                        tick()
                    end
                    if IsControlJustPressed(0, 200) and Action.canCancel then
                        TriggerEvent("progressbar:client:cancel")
                    end

                    if IsEntityDead(ped) and not Action.useWhileDead then
                        TriggerEvent("progressbar:client:cancel")
                    end
                end
                if finish ~= nil then
                    finish(wasCancelled)
                end
            end)
        else

            Bridge.Notify(locale:t('notify.prog_alredy_use'), "error")
        end
    else
        Bridge.Notify(locale:t('notify.cantAction'), "error")
    end
end

function ActionStart()
    runProgThread = true
    LocalPlayer.state:set("inv_busy", true, true) -- Busy
    CreateThread(function()
        while runProgThread do
            if isDoingAction then
                if not isAnim then
                    if Action.animation then
                        if Action.animation.task ~= nil then
                            TaskStartScenarioInPlace(PlayerPedId(), Action.animation.task, 0, true)
                        elseif Action.animation.animDict ~= nil and Action.animation.anim ~= nil then
                            if Action.animation.flags == nil then
                                Action.animation.flags =  Action.animation.flag or 49
                            end

                            local player = PlayerPedId()
                            if (DoesEntityExist(player) and not IsEntityDead(player)) then
                                RequestAnimDict(Action.animation.animDict)
                                Wait(50)
                                TaskPlayAnim(player, Action.animation.animDict, Action.animation.anim, 3.0, 3.0, -1, Action.animation.flags, 0, 0, 0, 0 )     
                            end
                        end
                    end

                    isAnim = true
                end
                if not isProp and Action.prop and Action.prop.model ~= nil then
                    local ped = PlayerPedId()
                    RequestModel(Action.prop.model)

                    while not HasModelLoaded(GetHashKey(Action.prop.model)) do
                        Wait(0)
                    end

                    local pCoords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.0, 0.0)
                    local modelSpawn = CreateObject(GetHashKey(Action.prop.model), pCoords.x, pCoords.y, pCoords.z, true, true, true)

                    local netid = ObjToNet(modelSpawn)
                    SetNetworkIdExistsOnAllMachines(netid, true)
                    NetworkSetNetworkIdDynamic(netid, true)
                    SetNetworkIdCanMigrate(netid, false)
                    if Action.prop.bone == nil then
                        Action.prop.bone = 60309
                    end

                    if Action.prop.coords == nil then
                        Action.prop.coords = { x = 0.0, y = 0.0, z = 0.0 }
                    end

                    if Action.prop.rotation == nil then
                        Action.prop.rotation = { x = 0.0, y = 0.0, z = 0.0 }
                    end

                    AttachEntityToEntity(modelSpawn, ped, GetPedBoneIndex(ped, Action.prop.bone), Action.prop.coords.x, Action.prop.coords.y, Action.prop.coords.z, Action.prop.rotation.x, Action.prop.rotation.y, Action.prop.rotation.z, 1, 1, 0, 1, 0, 1)
                    prop_net = netid

                    isProp = true
                    
                    if not isPropTwo and Action.propTwo ~= nil and Action.propTwo.model ~= nil then
                        RequestModel(Action.propTwo.model)

                        while not HasModelLoaded(GetHashKey(Action.propTwo.model)) do
                            Wait(0)
                        end

                        local pCoords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.0, 0.0)
                        local modelSpawn = CreateObject(GetHashKey(Action.propTwo.model), pCoords.x, pCoords.y, pCoords.z, true, true, true)

                        local netid = ObjToNet(modelSpawn)
                        SetNetworkIdExistsOnAllMachines(netid, true)
                        NetworkSetNetworkIdDynamic(netid, true)
                        SetNetworkIdCanMigrate(netid, false)
                        if Action.propTwo.bone == nil then
                            Action.propTwo.bone = 60309
                        end

                        if Action.propTwo.coords == nil then
                            Action.propTwo.coords = { x = 0.0, y = 0.0, z = 0.0 }
                        end

                        if Action.propTwo.rotation == nil then
                            Action.propTwo.rotation = { x = 0.0, y = 0.0, z = 0.0 }
                        end

                        AttachEntityToEntity(modelSpawn, ped, GetPedBoneIndex(ped, Action.propTwo.bone), Action.propTwo.coords.x, Action.propTwo.coords.y, Action.propTwo.coords.z, Action.propTwo.rotation.x, Action.propTwo.rotation.y, Action.propTwo.rotation.z, 1, 1, 0, 1, 0, 1)
                        propTwo_net = netid

                        isPropTwo = true
                    end
                end

                DisableActions(ped)
            end
            Wait(0)
        end
    end)
end

function Cancel()
    isDoingAction = false
    wasCancelled = true
    LocalPlayer.state:set("inv_busy", false, true) -- Not Busy
    ActionCleanup()

    exports.origen_hud:HideProgress()
end


function Finish()
    terminaEn = 0
    isDoingAction = false
    ActionCleanup()
    LocalPlayer.state:set("inv_busy", false, true) -- Not Busy
    return true
end

FinishProgress = Finish

--[[ El aviso de la pagina del HUD al acabar la animacion. Ya no hace falta
     (la barra lleva su reloj), pero se atiende si llega a tiempo. Solo si la
     barra en curso ya ha cumplido: el aviso de una barra anterior, con el
     anillo sin remontar, cortaba la siguiente antes de hora. ]]
exports('FinishProgress', function()
    if not isDoingAction then return end
    if GetGameTimer() + 250 < terminaEn then return end
    Finish()
end)

--[[ Cancelar (ESC o morir, desde el hilo de Process). Nadie escuchaba este
     evento: la barra no se podia cancelar de ninguna forma. ]]
AddEventHandler('progressbar:client:cancel', function()
    if not isDoingAction then return end
    local ped = PlayerPedId()
    local muerto = IsEntityDead(ped) and not Action.useWhileDead
    if not Action.canCancel and not muerto then return end
    Cancel()
end)

function ActionCleanup()
    local ped = PlayerPedId()

    if Action.animation then
        if Action.animation.task ~= nil or (Action.animation.animDict ~= nil and Action.animation.anim ~= nil) then
            ClearPedSecondaryTask(ped)
           -- debuger ('progress',ped, Action.animation.animDict, Action.animation.anim)
            StopAnimTask(ped, Action.animation.animDict, Action.animation.anim, 1.0)
        else
            ClearPedTasks(ped)
        end
    end

    if prop_net then
        DetachEntity(NetToObj(prop_net), 1, 1)
        DeleteEntity(NetToObj(prop_net))
    end
    if propTwo_net then
        DetachEntity(NetToObj(propTwo_net), 1, 1)
        DeleteEntity(NetToObj(propTwo_net))
    end
    prop_net = nil
    propTwo_net = nil
    runProgThread = false
end


function DisableActions(ped)
    if not Action.controlDisables then return end
    if Action.controlDisables.disableMouse then
        DisableControlAction(0, 1, true) -- LookLeftRight
        DisableControlAction(0, 2, true) -- LookUpDown
        DisableControlAction(0, 106, true) -- VehicleMouseControlOverride
    end

    if Action.controlDisables.disableMovement then
        DisableControlAction(0, 30, true) -- disable left/right
        DisableControlAction(0, 36, true) -- Left CTRL
        DisableControlAction(0, 31, true) -- disable forward/back
        DisableControlAction(0, 36, true) -- INPUT_DUCK
        DisableControlAction(0, 21, true) -- disable sprint
        DisableControlAction(0, 75, true)  -- Disable exit vehicle
        DisableControlAction(27, 75, true) -- Disable exit vehicle 
    end

    if Action.controlDisables.disableCarMovement then
        DisableControlAction(0, 63, true) -- veh turn left
        DisableControlAction(0, 64, true) -- veh turn right
        DisableControlAction(0, 71, true) -- veh forward
        DisableControlAction(0, 72, true) -- veh backwards
        DisableControlAction(0, 75, true) -- disable exit vehicle
    end

    if Action.controlDisables.disableCombat then
        DisablePlayerFiring(PlayerId(), true) -- Disable weapon firing
        DisableControlAction(0, 24, true) -- disable attack
        DisableControlAction(0, 25, true) -- disable aim
        DisableControlAction(1, 37, true) -- disable weapon select
        DisableControlAction(0, 47, true) -- disable weapon
        DisableControlAction(0, 58, true) -- disable weapon
        DisableControlAction(0, 140, true) -- disable melee
        DisableControlAction(0, 141, true) -- disable melee
        DisableControlAction(0, 142, true) -- disable melee
        DisableControlAction(0, 143, true) -- disable melee
        DisableControlAction(0, 263, true) -- disable melee
        DisableControlAction(0, 264, true) -- disable melee
        DisableControlAction(0, 257, true) -- disable melee
    end
end

function isDoingSomething()
    return isDoingAction
end

RegisterNetEvent('origen_inventory:progressbar:progress', function(action, finish)
	Process(action, nil, nil, finish)
end)

exports('progressBar', Process)

RegisterNetEvent('origen_inventory:progressbar:ProgressWithStartEvent', function(action, start, finish)
	Process(action, start, nil, finish)
end)

RegisterNetEvent('origen_inventory:progressbar:ProgressWithTickEvent', function(action, tick, finish)
	Process(action, nil, tick, finish)
end)

RegisterNetEvent('origen_inventory:progressbar:ProgressWithStartAndTick', function(action, start, tick, finish)
	Process(action, start, tick, finish)
end)

RegisterNetEvent('origen_inventory:progressbar:cancel', function()
	Cancel()
end)

local progressCallback = nil
local progressId = 0

exports('ShowProgressUI', function(duration, label, callback)
    if progressCallback then
        progressCallback(false)
    end
    
    progressId = progressId + 1
    local currentId = progressId
    progressCallback = callback

    exports.origen_hud:ShowProgress(duration, label)
    
    CreateThread(function()
        Wait(duration)
        if progressId == currentId and progressCallback then
            local cb = progressCallback
            progressCallback = nil
            cb(true)
        end
    end)
end)

exports('CancelProgressUI', function()
    progressId = progressId + 1

    exports.origen_hud:HideProgress()
    
    if progressCallback then
        progressCallback(false)
        progressCallback = nil
    end
end)
