-- origen_propplacer | client/placement.lua
-- Sistema de colocación con raycast + gizmo nativo

Placement          = {}
Placement.active   = false
Placement.entity   = nil
Placement.model    = nil
Placement.mode     = 'raycast'
Placement.distance = nil  -- se inicializa en UpdateLoop con Config.PlacementDefaultDist

local _onConfirm  = nil
local _onCancel   = nil
local snapEnabled = false

-- ─────────────────────────────────────────────
-- Raycast desde la cámara
-- ─────────────────────────────────────────────
local function RotationToDirection(rot)
    local rx = math.rad(rot.x)
    local rz = math.rad(rot.z)
    return {
        x = -math.sin(rz) * math.abs(math.cos(rx)),
        y =  math.cos(rz) * math.abs(math.cos(rx)),
        z =  math.sin(rx),
    }
end

local function RayCastCamera(distance)
    local camRot   = GetGameplayCamRot()
    local camCoord = GetGameplayCamCoord()
    local dir      = RotationToDirection(camRot)
    local dest     = {
        x = camCoord.x + dir.x * distance,
        y = camCoord.y + dir.y * distance,
        z = camCoord.z + dir.z * distance,
    }
    local _, hit, coords = GetShapeTestResult(
        StartShapeTestRay(camCoord.x, camCoord.y, camCoord.z, dest.x, dest.y, dest.z, -1, PlayerPedId(), 0)
    )
    return hit == 1, coords
end

-- ─────────────────────────────────────────────
-- Carga de modelo
-- ─────────────────────────────────────────────
local function loadModel(model)
    local hash = type(model) == 'number' and model or GetHashKey(model)
    if not IsModelValid(hash) then return nil end
    RequestModel(hash)
    local t = 0
    while not HasModelLoaded(hash) and t < 10000 do Wait(50); t = t + 50 end
    if not HasModelLoaded(hash) then return nil end
    return hash
end

-- ─────────────────────────────────────────────
-- Placement.Start — nuevo prop
-- ─────────────────────────────────────────────
function Placement.Start(model, onConfirm, onCancel)
    if Placement.active then Placement.Stop() end
    _onConfirm       = onConfirm
    _onCancel        = onCancel
    Placement.model  = model
    Placement.active = true
    Placement.mode   = 'raycast'
    snapEnabled      = false
    Placement.distance = Config.PlacementDefaultDist or 15.0

    CreateThread(function()
        local hash = loadModel(model)
        if not hash then
            Placement.active = false
            if _onCancel then _onCancel() end
            return
        end
        local pedCoords  = GetEntityCoords(PlayerPedId())
        Placement.entity = CreateObject(hash, pedCoords.x, pedCoords.y, pedCoords.z, false, false, false)
        SetEntityAlpha(Placement.entity, 175, false)
        FreezeEntityPosition(Placement.entity, true)
        SetEntityCollision(Placement.entity, false, false)
        SetModelAsNoLongerNeeded(hash)
        Placement.UpdateLoop()
    end)
end

-- ─────────────────────────────────────────────
-- Placement.StartEdit — gizmo sobre entidad existente
-- ─────────────────────────────────────────────
function Placement.StartEdit(entity, onConfirm, onCancel)
    if Placement.active then return end
    if not entity or not DoesEntityExist(entity) then
        if onCancel then onCancel() end
        return
    end
    Placement.active = true
    Placement.mode   = 'gizmo'
    _onConfirm       = onConfirm
    _onCancel        = onCancel
    SetEntityCollision(entity, false, false)
    CreateThread(function()
        local result = Gizmo:StartGizmo(entity)
        Placement.active = false
        Placement.mode   = 'raycast'
        SetEntityCollision(entity, true, true)
        FreezeEntityPosition(entity, true)
        if result and result.entity then
            local cb = _onConfirm; _onConfirm = nil; _onCancel = nil
            if cb then cb({
                coords   = { x = result.position.x, y = result.position.y, z = result.position.z },
                rotation = { x = result.rotation.x, y = result.rotation.y, z = result.rotation.z },
            }) end
        else
            local cb = _onCancel; _onConfirm = nil; _onCancel = nil
            if cb then cb() end
        end
    end)
end

-- ─────────────────────────────────────────────
-- Loop de raycast + controles
-- ─────────────────────────────────────────────
function Placement.UpdateLoop()
    CreateThread(function()
        local rotation   = GetEntityHeading(PlayerPedId())
        local snapAngle  = Config.SnapAngle or 45.0
        local minDist    = Config.PlacementMinDistance  or 2.0
        local maxDist    = Config.PlacementMaxDistance  or 100.0
        local scrollStep = Config.PlacementScrollStep   or 1.0

        -- Asegurar que distance tenga valor inicial
        if not Placement.distance then Placement.distance = Config.PlacementDefaultDist or 15.0 end

        while Placement.active do
            Wait(0)
            if Placement.mode == 'gizmo' then goto continue end

            -- ── Ctrl + Scroll → ajustar distancia ──────────────────────
            if IsControlPressed(0, 36) then  -- CTRL
                if IsControlJustPressed(0, 14) then  -- scroll up
                    Placement.distance = math.min(Placement.distance + scrollStep, maxDist)
                    SendNUIMessage({ action = "distanceUpdated", distance = Placement.distance })
                elseif IsControlJustPressed(0, 15) then  -- scroll down
                    Placement.distance = math.max(Placement.distance - scrollStep, minDist)
                    SendNUIMessage({ action = "distanceUpdated", distance = Placement.distance })
                end
            else
                -- ── Scroll normal → rotar ───────────────────────────────
                if not FreeCam.active then
                    if snapEnabled then
                        if IsControlJustPressed(0, 14) then
                            rotation = (math.floor(rotation / snapAngle + 0.5) * snapAngle + snapAngle) % 360
                        elseif IsControlJustPressed(0, 15) then
                            rotation = (math.floor(rotation / snapAngle + 0.5) * snapAngle - snapAngle + 360) % 360
                        end
                    else
                        if IsControlPressed(0, 14) then rotation = (rotation + 2.0) % 360.0
                        elseif IsControlPressed(0, 15) then rotation = (rotation - 2.0) % 360.0 end
                    end
                end
            end

            -- ── Posicionar con raycast a la distancia actual ────────────
            local hit, coords = RayCastCamera(Placement.distance)
            local pos
            if hit and coords then
                pos = coords
            else
                local ped = PlayerPedId()
                local fwd = GetEntityForwardVector(ped)
                local pp  = GetEntityCoords(ped)
                local d   = Placement.distance
                pos = vector3(pp.x + fwd.x * d, pp.y + fwd.y * d, pp.z)
            end

            if Placement.entity and DoesEntityExist(Placement.entity) then
                SetEntityCoords(Placement.entity, pos.x, pos.y, pos.z, false, false, false, false)
                SetEntityHeading(Placement.entity, rotation)
            end

            -- ── Z → toggle snap ─────────────────────────────────────────
            if IsControlJustPressed(0, 20) then
                snapEnabled = not snapEnabled
                SendNUIMessage({ action = "snapToggled", enabled = snapEnabled })
                if snapEnabled then rotation = math.floor(rotation / snapAngle + 0.5) * snapAngle % 360 end
            end

            -- ── ALT → ajustar al suelo ───────────────────────────────────
            if IsControlJustPressed(0, 19) and Placement.entity and DoesEntityExist(Placement.entity) then
                PlaceObjectOnGroundProperly(Placement.entity)
            end

            -- ── F → cámara libre ─────────────────────────────────────────
            if IsControlJustPressed(0, 166) and Placement.mode == 'raycast' then
                FreeCam.Toggle(); goto continue
            end

            -- ── G → modo gizmo ────────────────────────────────────────────
            if IsControlJustPressed(0, 47) and Placement.entity and DoesEntityExist(Placement.entity) then
                FreeCam.ForceStop()
                Placement.mode = 'gizmo'
                FreezeEntityPosition(Placement.entity, false)
                CreateThread(function()
                    local result = Gizmo:StartGizmo(Placement.entity)
                    if not Placement.active then return end
                    if result and result.confirmed then
                        local pos2, rot2 = result.position, result.rotation
                        local cb         = _onConfirm
                        Placement.Stop()
                        if cb then cb({
                            coords   = { x = pos2.x, y = pos2.y, z = pos2.z },
                            rotation = { x = rot2.x, y = rot2.y, z = rot2.z },
                        }) end
                    elseif result then
                        if Placement.entity and DoesEntityExist(Placement.entity) then
                            local p, r = result.position, result.rotation
                            SetEntityCoords(Placement.entity, p.x, p.y, p.z, false, false, false, false)
                            SetEntityRotation(Placement.entity, r.x, r.y, r.z, 2, true)
                            rotation = r.z
                            FreezeEntityPosition(Placement.entity, true)
                        end
                        Placement.mode = 'raycast'
                    else
                        if Placement.entity and DoesEntityExist(Placement.entity) then
                            FreezeEntityPosition(Placement.entity, true)
                        end
                        Placement.mode = 'raycast'
                    end
                end)
                goto continue
            end

            -- ── ENTER → confirmar ─────────────────────────────────────────
            if IsControlJustPressed(0, 191) then
                local finalPos = Placement.entity and GetEntityCoords(Placement.entity)  or vector3(0, 0, 0)
                local finalRot = Placement.entity and GetEntityRotation(Placement.entity) or vector3(0, 0, 0)
                FreeCam.ForceStop()
                local cb = _onConfirm
                Placement.Stop()
                if cb then cb({
                    coords   = { x = finalPos.x, y = finalPos.y, z = finalPos.z },
                    rotation = { x = finalRot.x, y = finalRot.y, z = finalRot.z },
                }) end
                return
            end

            -- ── BACKSPACE → cancelar ───────────────────────────────────────
            if IsControlJustPressed(0, 177) then
                FreeCam.ForceStop()
                local cb = _onCancel
                Placement.Stop()
                if cb then cb() end
                return
            end

            DisableControlAction(0, 24,  true)
            DisableControlAction(0, 25,  true)
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)

            ::continue::
        end
    end)
end

-- ─────────────────────────────────────────────
-- Placement.Stop
-- ─────────────────────────────────────────────
function Placement.Stop()
    if not Placement.active then return end
    FreeCam.ForceStop()
    if Gizmo.enabled then Gizmo:StopGizmo() end
    Placement.active   = false
    Placement.mode     = 'raycast'
    Placement.distance = Config.PlacementDefaultDist or 15.0
    snapEnabled        = false
    if Placement.entity and DoesEntityExist(Placement.entity) then
        DeleteEntity(Placement.entity)
    end
    Placement.entity = nil
    Placement.model  = nil
    _onConfirm       = nil
    _onCancel        = nil
end
