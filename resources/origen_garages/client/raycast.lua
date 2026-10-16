function entityPositioning(type, model, coords)
    local isPositioning = true
    local finish = false
    local cancel = false
    local precise = false
    local entity = nil
    local entityHeading = coords and coords.w or 0.0
    local entityCoords = nil
    
    SetPedConfigFlag(cache.ped, 122, true)
    local modelHash = lib.requestModel(model)

    if type == 'vehicle' then
        entity = CreateVehicle(modelHash, 0.0, 0.0, 0.0, 0.0, false, false)
        SetEntityCompletelyDisableCollision(entity, false, false)
        SetModelAsNoLongerNeeded(modelHash)
        SetEntityAlpha(entity, 150, false)
        FreezeEntityPosition(entity, true)
    elseif type == 'ped' then
        entity = CreatePed(4, modelHash, 0.0, 0.0, 0.0, 0.0, false, true)
        SetEntityAlpha(entity, 150, false)
        FreezeEntityPosition(entity, true)
        SetEntityInvincible(entity, true)
        SetBlockingOfNonTemporaryEvents(entity, true)
        SetPedConfigFlag(entity, 79, true)
        SetEntityCollision(entity, false)
        SetEntityCompletelyDisableCollision(entity, false, false)
        SetModelAsNoLongerNeeded(modelHash)
    end

    local function rotateLeft()
        if isPositioning then
            entityHeading = entityHeading + (precise and 1.0 or 10.0)
            SetEntityHeading(entity, entityHeading)
        end
    end
    local function rotateRight()
        if isPositioning then
            entityHeading = entityHeading - (precise and 1.0 or 10.0)
            SetEntityHeading(entity, entityHeading)
        end
    end
    local function setPrecise(val)
        precise = val
    end
    local function confirm()
        if isPositioning then
            finish = true
        end
    end
    local function doCancel()
        if isPositioning then
            cancel = true
        end
    end

    RegisterCommand('entity_rotateleft', rotateLeft, false)
    RegisterCommand('entity_rotateright', rotateRight, false)
    RegisterCommand('+entity_precise_mode', function() setPrecise(true) end, false)
    RegisterCommand('-entity_precise_mode', function() setPrecise(false) end, false)
    RegisterCommand('entity_confirm', confirm, false)
    RegisterCommand('entity_cancel', doCancel, false)

    RegisterKeyMapping('entity_rotateleft', 'Colocar: girar a la izquierda', 'MOUSE_WHEEL', 'IOM_WHEEL_UP')
    RegisterKeyMapping('entity_rotateright', 'Colocar: girar a la derecha', 'MOUSE_WHEEL', 'IOM_WHEEL_DOWN')
    RegisterKeyMapping('+entity_precise_mode', 'Colocar: modo preciso', 'keyboard', 'LSHIFT')
    RegisterKeyMapping('entity_confirm', 'Colocar: confirmar', 'MOUSE_BUTTON', 'MOUSE_LEFT')
    RegisterKeyMapping('entity_cancel', 'Colocar: cancelar', 'MOUSE_BUTTON', 'MOUSE_RIGHT')

    while isPositioning do
        Wait(0)
        local hit, _, endCoords = lib.raycast.fromCamera(511, 4, 25.0)
        if not hit then
            SetEntityCoords(entity, 0.0, 0.0, 0.0, false, false, false, false)
        else
            SetEntityCoords(entity, endCoords.x, endCoords.y, endCoords.z, false, false, false, false)
        end
        SetEntityHeading(entity, entityHeading)

        if cancel then
            if DoesEntityExist(entity) then
                DeleteEntity(entity)
            end
            isPositioning = false
            entityCoords = nil
        end

        if finish then
            entityCoords = endCoords
            entityHeading = GetEntityHeading(entity) + 0.1
            if DoesEntityExist(entity) then
                DeleteEntity(entity)
            end
            isPositioning = false
        end
    end

    lib.hideTextUI()
    SetPedConfigFlag(cache.ped, 122, false)

    return entityCoords and vector4(entityCoords.x, entityCoords.y, entityCoords.z, entityHeading) or nil
end