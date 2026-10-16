local inTrunk = false
local isTextUIShown = false
local currentAction = nil

local function loadDict(dict)
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
            Wait(0)
        end
    end
end

CreateThread(function()
    while true do
        --[[ `sleep` va fuera del if. Estaba declarado dentro, asi que el
             Wait(sleep) del final leia una global que no existe: Wait(nil), y el
             hilo corria cada fotograma para todos, con el export de la manguera
             incluido (16/09, lo segundo que mas pesaba en el resmon). ]]
        local sleep = 1000
        local HasNozzle = exports['origen_fuel']:HasNozzle()
        if not HasNozzle then
            local playerPed = cache.ped
            
            if inTrunk then
                sleep = 0
                local vehicle = GetEntityAttachedTo(playerPed)
                if DoesEntityExist(vehicle) and not IsPedDeadOrDying(playerPed) and not IsPedFatallyInjured(playerPed) then
                    local coords = GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, 'boot'))
                    SetEntityCollision(playerPed, false, false)
                    
                    if not isTextUIShown then
                        lib.showTextUI(locale('actions.leave_trunk'))
                        isTextUIShown = true
                        currentAction = 'leave'
                    end
    
                    if GetVehicleDoorAngleRatio(vehicle, 5) < 0.9 then
                        SetEntityVisible(playerPed, false, false)
                    else
                        if not IsEntityPlayingAnim(playerPed, 'timetable@floyd@cryingonbed@base', 3) then
                            loadDict('timetable@floyd@cryingonbed@base')
                            TaskPlayAnim(playerPed, 'timetable@floyd@cryingonbed@base', 'base', 8.0, -8.0, -1, 1, 0, false, false, false)
                            SetEntityVisible(playerPed, true, false)
                        end
                    end
    
                    if IsControlJustReleased(0, 38) then
                        lib.hideTextUI()
                        isTextUIShown = false
                        currentAction = nil
                        SetCarBootOpen(vehicle)
                        
                        local exitCoords = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, -3.0, -0.5)
                        
                        SetEntityCollision(playerPed, true, true)
                        Wait(750)
                        inTrunk = false
                        DetachEntity(playerPed, true, true)
                        SetEntityVisible(playerPed, true, false)
                        ClearPedTasks(playerPed)
                        SetEntityCoords(playerPed, exitCoords.x, exitCoords.y, exitCoords.z)
                        Wait(250)
                        SetVehicleDoorShut(vehicle, 5)
                    end
                else
                    if isTextUIShown then
                        lib.hideTextUI()
                        isTextUIShown = false
                        currentAction = nil
                    end
                    SetEntityCollision(playerPed, true, true)
                    DetachEntity(playerPed, true, true)
                    SetEntityVisible(playerPed, true, false)
                    ClearPedTasks(playerPed)
                    local pCoords = GetEntityCoords(playerPed)
                    SetEntityCoords(playerPed, pCoords.x, pCoords.y, pCoords.z)
                    inTrunk = false
                end
            elseif LocalPlayer.state.invBusy or LocalPlayer.state.minaJornada then
                --[[ minaJornada: de jornada en la cantera la trasera de la camioneta
                     es de la mina (subir/bajar la carretilla, echar piedra): su E se
                     pisaba con esconderse (27/09). ]]
                --[[ Solo se corta la entrada. Quien YA esta dentro tiene que poder
                     salir siempre: su aviso vive en la rama de arriba. ]]
                if isTextUIShown then
                    lib.hideTextUI()
                    isTextUIShown = false
                    currentAction = nil
                end
            else
                local playerCoords = GetEntityCoords(playerPed)
                local vehicle = GetClosestVehicle(playerCoords.x, playerCoords.y, playerCoords.z, 10.0, 0, 70)
                local closeToTrunk = false
    
                if DoesEntityExist(vehicle) and IsVehicleSeatFree(vehicle, -1) then
                    local trunk = GetEntityBoneIndexByName(vehicle, 'boot')
                    if trunk ~= -1 then
                        local coords = GetWorldPositionOfEntityBone(vehicle, trunk)
                        local dist = #(playerCoords - coords)
                        
                        if dist <= 1.5 then
                            closeToTrunk = true
                            sleep = 0
                            local lockStatus = GetVehicleDoorLockStatus(vehicle)
                            local isTrunkOpen = GetVehicleDoorAngleRatio(vehicle, 5) >= 0.9
    
                            if isTextUIShown then 
                                if isTrunkOpen and currentAction == 'open' then
                                    lib.hideTextUI()
                                    isTextUIShown = false
                                elseif not isTrunkOpen and currentAction == 'hide' then
                                    lib.hideTextUI()
                                    isTextUIShown = false
                                end
                            end
    
                            if not isTrunkOpen then
                                if not isTextUIShown then
                                    lib.showTextUI(locale('actions.open_trunk'))
                                    isTextUIShown = true
                                    currentAction = 'open'
                                end
    
                                if IsControlJustReleased(0, 38) then
                                    if lockStatus == 1 then
                                        SetCarBootOpen(vehicle)
                                    elseif lockStatus == 2 then
                                        lib.notify({description = locale('error.trunk_locked'), type = 'error'})
                                    end
                                end
                            else
                                if not isTextUIShown then
                                    lib.showTextUI(locale('actions.hide_trunk'))
                                    isTextUIShown = true
                                    currentAction = 'hide'
                                end
    
                                if IsControlJustReleased(0, 38) then
                                    if lockStatus == 1 then
                                        local closestPlayer, closestDist = lib.getClosestPlayer(playerCoords, 5.0, false)
                                        local closestPlayerPed = closestPlayer and GetPlayerPed(closestPlayer)
                                        
                                        local canEnter = true
                                        if closestPlayerPed and closestDist < 5.0 then
                                            if IsEntityAttachedToEntity(closestPlayerPed, vehicle) then
                                                canEnter = false
                                            end
                                        end
    
                                        if canEnter then
                                            if isTextUIShown then
                                                lib.hideTextUI()
                                                isTextUIShown = false
                                                currentAction = nil
                                            end
                                            SetCarBootOpen(vehicle)
                                            Wait(350)
                                            AttachEntityToEntity(playerPed, vehicle, -1, 0.0, -2.2, 0.5, 0.0, 0.0, 0.0, false, false, false, false, 20, true)
                                            loadDict('timetable@floyd@cryingonbed@base')
                                            TaskPlayAnim(playerPed, 'timetable@floyd@cryingonbed@base', 'base', 8.0, -8.0, -1, 1, 0, false, false, false)
                                            Wait(50)
                                            inTrunk = true
                                            Wait(1500)
                                            SetVehicleDoorShut(vehicle, 5)
                                        else
                                            lib.notify({description = locale('error.trunk_occupied'), type = 'error'})
                                        end
                                    elseif lockStatus == 2 then
                                        lib.notify({description = locale('error.trunk_locked'), type = 'error'})
                                    end
                                end
                            end
                        end
                    end
                end
    
                if not closeToTrunk and isTextUIShown then
                    lib.hideTextUI()
                    isTextUIShown = false
                    currentAction = nil
                end
            end
        end
        
        Wait(sleep)
    end
end)