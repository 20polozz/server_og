Placement = {}
Placement.active = false
Placement.entity = nil
Placement.entityType = nil
Placement.model = nil
Placement.offset = vector3(0, 0, 0)
Placement.requestId = nil
Placement.markerCoords = nil
Placement.mode = 'raycast'

local function RotationToDirection(rotation)
    local adjustedRotation = {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    local direction = {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        z = math.sin(adjustedRotation.x)
    }
    return direction
end

local function RayCastGamePlayCamera(distance)
    local cameraRotation = GetGameplayCamRot()
    local cameraCoord = GetGameplayCamCoord()
    local direction = RotationToDirection(cameraRotation)
    local destination = {
        x = cameraCoord.x + direction.x * distance,
        y = cameraCoord.y + direction.y * distance,
        z = cameraCoord.z + direction.z * distance
    }
    local _, hit, coords, _, entity = GetShapeTestResult(
        StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0)
    )
    return hit, coords, entity
end

local function ShowRaycastControls()
    if GetResourceState('origen_hud') == 'started' then
        exports.origen_hud:setupControls()
        exports.origen_hud:setupControls({
            { key = 'Rueda', text = 'Girar' },
            { key = 'G', text = 'Mover con flechas' },
            { key = 'Intro', text = 'Confirmar' },
        })
    end
end

local function ShowGizmoControls()
    if GetResourceState('origen_hud') == 'started' then
        exports.origen_hud:setupControls()
        exports.origen_hud:setupControls({
            { key = 'W', text = 'Mover' },
            { key = 'R', text = 'Rotar' },
            { key = 'Q', text = 'Local/Mundo' },
            { key = 'ALT', text = 'Ajustar al suelo' },
            { key = 'G', text = 'Mover apuntando' },
            { key = 'Intro', text = 'Confirmar posición' },
        })
    end
end

function Placement.Start(entityType, model, requestId)
    if Placement.active then
        Placement.Stop()
    end

    Placement.entityType = entityType
    Placement.model = model
    Placement.requestId = requestId
    Placement.active = true
    Placement.markerCoords = nil
    Placement.mode = 'raycast'

    -- Un modelo que no existe haria reventar lib.requestModel con Placement
    -- ya activo; mejor cancelar como con el modelo vacio.
    if entityType ~= 'loot_marker' and (not model or model == '' or not IsModelInCdimage(model)) then
        Placement.active = false
        SendNUIMessage({
            action = 'placementCancelled',
            requestId = requestId
        })
        SendNUIMessage({
            action = 'placementMode',
            data = { active = false }
        })
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(false)
        return
    end

    local playerCoords = GetEntityCoords(cache.ped)
    if entityType ~= 'loot_marker' then
        lib.requestModel(model)

        if entityType == 'npc' then
            Placement.entity = CreatePed(4, model, playerCoords.x, playerCoords.y, playerCoords.z, 0.0, false, false)
        else
            Placement.entity = CreateObjectNoOffset(model, playerCoords.x, playerCoords.y, playerCoords.z, false, false, false)
        end

        SetEntityAlpha(Placement.entity, 200, false)
        FreezeEntityPosition(Placement.entity, true)
        SetEntityCollision(Placement.entity, false, false)
    end

    ShowRaycastControls()

    SendNUIMessage({
        action = 'placementMode',
        data = { active = true }
    })

    Placement.UpdateLoop()
end

function Placement.UpdateLoop()
    CreateThread(function()
        local rotation = 0.0

        while Placement.active do
            Wait(0)

            if Placement.mode == 'gizmo' then
                goto continue
            end

            local hit, coords = RayCastGamePlayCamera(50.0)

            if hit and coords then
                local finalCoords = coords + vector3(0, 0, 0.0)
                Placement.markerCoords = finalCoords

                if Placement.entity and DoesEntityExist(Placement.entity) then
                    SetEntityCoords(Placement.entity, finalCoords.x, finalCoords.y, finalCoords.z, false, false, false, false)
                    SetEntityHeading(Placement.entity, rotation)
                end
            elseif Placement.entity then
                local pedCoords = GetEntityCoords(cache.ped)
                local forward = GetEntityForwardVector(cache.ped)
                local fallbackCoords = pedCoords + (forward * 2.0)
                Placement.markerCoords = fallbackCoords
                SetEntityCoords(Placement.entity, fallbackCoords.x, fallbackCoords.y, fallbackCoords.z, false, false, false, false)
                SetEntityHeading(Placement.entity, rotation)
            end

            if IsControlPressed(0, 14) then
                rotation = (rotation + 2.0) % 360.0
            elseif IsControlPressed(0, 15) then
                rotation = (rotation - 2.0) % 360.0
            end

            if IsControlJustPressed(0, 47) and Placement.entity and DoesEntityExist(Placement.entity) then
                Placement.mode = 'gizmo'
                ShowGizmoControls()
                FreezeEntityPosition(Placement.entity, false)
                CreateThread(function()
                    local result = Gizmo:StartGizmo(Placement.entity)
                    if Placement.active then
                        if result and result.confirmed then
                            local finalCoords = result.position
                            local finalHeading = result.rotation.z
                            local requestId = Placement.requestId

                            Placement.Stop()

                            SendNUIMessage({
                                action = 'placementComplete',
                                requestId = requestId,
                                coords = {
                                    x = finalCoords.x,
                                    y = finalCoords.y,
                                    z = finalCoords.z,
                                    w = finalHeading
                                }
                            })
                        elseif result then
                            local pos = result.position
                            local rot = result.rotation
                            SetEntityCoords(Placement.entity, pos.x, pos.y, pos.z, false, false, false, false)
                            SetEntityRotation(Placement.entity, rot.x, rot.y, rot.z, 2, true)
                            rotation = rot.z
                            FreezeEntityPosition(Placement.entity, true)
                            Placement.mode = 'raycast'
                            ShowRaycastControls()
                        else
                            FreezeEntityPosition(Placement.entity, true)
                            Placement.mode = 'raycast'
                            ShowRaycastControls()
                        end
                    end
                end)
                goto continue
            end

            if IsControlJustPressed(0, 191) then
                local finalCoords = Placement.entity and GetEntityCoords(Placement.entity) or Placement.markerCoords
                local finalHeading = Placement.entity and GetEntityHeading(Placement.entity) or rotation
                local requestId = Placement.requestId

                Placement.Stop()

                SendNUIMessage({
                    action = 'placementComplete',
                    requestId = requestId,
                    coords = {
                        x = finalCoords.x,
                        y = finalCoords.y,
                        z = finalCoords.z,
                        w = finalHeading
                    }
                })

                return
            end

            if IsControlJustPressed(0, 177) then
                local requestId = Placement.requestId
                Placement.Stop()
                SendNUIMessage({
                    action = 'placementCancelled',
                    requestId = requestId
                })
                return
            end

            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)

            if Placement.entityType == 'loot_marker' and Placement.markerCoords then
                DrawMarker(
                    2,
                    Placement.markerCoords.x, Placement.markerCoords.y, Placement.markerCoords.z + 0.05,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    0.18, 0.18, 0.18,
                    216, 27, 85, 200,
                    false, true, 2, nil, nil, false
                )
            end

            ::continue::
        end
    end)
end

function Placement.Stop()
    if not Placement.active then return end

    if Gizmo.enabled then
        Gizmo:DeleteGizmo()
    end

    Placement.active = false
    Placement.mode = 'raycast'

    if Placement.entity and DoesEntityExist(Placement.entity) then
        DeleteEntity(Placement.entity)
    end

    Placement.entity = nil
    Placement.entityType = nil
    Placement.model = nil
    Placement.requestId = nil
    Placement.markerCoords = nil

    if GetResourceState('origen_hud') == 'started' then
        exports.origen_hud:hideControls()
    end

    SendNUIMessage({
        action = 'placementMode',
        data = { active = false }
    })
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
end