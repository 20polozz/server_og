Create = {}

Create.SelectDoors = function(data, cb)
    local playedId = PlayerId()
    CreatingDoor = true
    data.state = data.locked
    data.maxDistance = tonumber(data.maxDistance)

    local configuredRate = tonumber(data.rate) or tonumber(data.doorRate) or 1.0
    if configuredRate < 0.1 then configuredRate = 0.1 end
    if configuredRate > 10.0 then configuredRate = 10.0 end
    data.rate = tonumber(string.format('%.1f', configuredRate))

    if data.autolock then
        data.autolock = tonumber(data.autolock)
    else
        data.autolock = 0
    end
    local doorCount = data.doors and 2 or 1
    local lastEntity = 0
    
    -- Mostrar el NUI de selección
    SendNUIMessage({
        action = 'showDoorSelection',
        isDouble = doorCount == 2,
        firstSelected = false
    })

    repeat 
        local ped = PlayerPedId()
        local pedCoords = GetEntityCoords(ped)
        
        -- Bloqueo agresivo de combate
        DisablePlayerFiring(playedId, true)
        SetPlayerCanDoDriveBy(playedId, false)
        DisableControlAction(0, 24, true) -- INPUT_ATTACK
        DisableControlAction(0, 25, true) -- INPUT_AIM
        DisableControlAction(0, 37, true) -- INPUT_SELECT_WEAPON
        DisableControlAction(0, 44, true) -- INPUT_COVER
        DisableControlAction(0, 45, true) -- INPUT_RELOAD
        DisableControlAction(0, 140, true) -- INPUT_MELEE_ATTACK_LIGHT
        DisableControlAction(0, 141, true) -- INPUT_MELEE_ATTACK_HEAVY
        DisableControlAction(0, 142, true) -- INPUT_MELEE_ATTACK_ALTERNATE
        DisableControlAction(0, 257, true) -- INPUT_ATTACK2
        DisableControlAction(0, 263, true) -- INPUT_MELEE_ATTACK1
        DisableControlAction(0, 264, true) -- INPUT_MELEE_ATTACK2

        -- Métodos para evitar combate y permitir selección en cristales
        SetPedConfigFlag(ped, 128, true) -- CPED_CONFIG_FLAG_PreventAllMeleeAbilities
        SetPedConfigFlag(ped, 427, true) -- Bloquear ataque físico
        
        local hit, entity, coords = Utils.Raycast(511) -- Flag 511 para detectar TODO (incluido cristal)
        local changedEntity = lastEntity ~= entity
        local doorA = tempData[1]?.entity
        local isValidTarget = false

        if changedEntity and lastEntity ~= doorA then
            debugger('[Raycast] Entity changed. Old:', lastEntity, 'New:', entity)
            Utils.DrawEntity(lastEntity, false)
        end

        lastEntity = entity

        -- Aumentamos el rango de detección para incluir objetos del mapa si es necesario
        if hit and entity > 0 and (GetEntityType(entity) == 3 or GetEntityType(entity) == 0) and (doorCount == 1 or doorA ~= entity) and Utils.IsNotDoor(entity) then
            isValidTarget = true
            
            if changedEntity then
                Utils.DrawEntity(entity, true)
            end

            DrawLine(pedCoords, coords.x, coords.y, coords.z, 255, 255, 255, 100)

            if IsDisabledControlJustPressed(0, 24) then
                Utils.addDoorlock(entity)
                
                -- Actualizar el NUI si se seleccionó la primera puerta
                if doorCount == 2 and tempData[1] then
                    SendNUIMessage({
                        action = 'updateDoorSelection',
                        firstSelected = true,
                        validTarget = false
                    })
                end
            end
        end
        
        -- Actualizar el estado del NUI con la validez del target
        SendNUIMessage({
            action = 'updateDoorSelection',
            validTarget = isValidTarget,
            firstSelected = tempData[1] ~= nil
        })

        if IsDisabledControlJustPressed(0, 25) then
            Utils.DrawEntity(entity, false)

            if not doorA then
                CreatingDoor = false
                Utils.DrawEntity(lastEntity, false)
                
                -- Ocultar el NUI
                SendNUIMessage({
                    action = 'hideDoorSelection'
                })
                
                cb(false)
                return 
            end

            Utils.DrawEntity(doorA, false)
            tempData = {}
        end
        
        Wait(0)
    until tempData[doorCount]
    
    -- Ocultar el NUI al terminar
    SendNUIMessage({
        action = 'hideDoorSelection'
    })

    Utils.DrawEntity(lastEntity, false)
    SetEntityDrawOutline(tempData[1].entity, false)

    if data.doors then
        SetEntityDrawOutline(tempData[2].entity, false)
        tempData[1].entity = nil
        tempData[2].entity = nil
        data.doors = tempData
    else
        data.model = tempData[1].model
        data.coords = tempData[1].coords
        data.heading = tempData[1].heading
    end

    CreatingDoor = false
    tempData = {}
    
    local ped = PlayerPedId()
    SetPedConfigFlag(ped, 128, false)
    debugger('[SelectDoors] Finished selection. Success:', true)
    cb(true)
end

RegisterNUICallback('createDoor', function(data, cb)
    local _data = {}

    _data.name = data.name
    _data.type = data.double and 'double' or 'normal'
    if data.double then
        _data.doors = {}
    end

    _data.maxDistance = tonumber(data.distance) or 1.5

    if data.groups and next(data.groups) then
        _data.groups = {}
        for _, goroupData in pairs(data.groups) do
            _data.groups[goroupData.name] = tonumber(goroupData.grade)
        end
    end

    if data.players and next(data.players) then
        _data.players = {}
        for _, playerData in pairs(data.players) do
            _data.players[playerData.identifier] = true
        end
    end

    _data.lockpick = data.lockpick and 1 or 0
    _data.passcode = data.passcode or false
    _data.locked = data.locked and data.locked == true and 1 or 0
    _data.autolock = tonumber(data.autolock) or 0
    _data.rate = tonumber(data.rate) or 1.0

    cb(true) -- Responder inmediatamente al NUI
    
    -- Quitar el NUI focus completamente para que funcione el raycast
    debugger('[NUI Callback] Starting door selection...')
    SetNuiFocus(false, false)
    
    Create.SelectDoors(_data, function(success)
        debugger('[NUI Callback] Selection callback success:', success)
        if success then
            debugger('[NUI Callback] Sending CreateDoor request to server...')
            local created = lib.callback.await('origen_doorlock:server:CreateDoor', false, _data)
            debugger('[NUI Callback] Server response for CreateDoor:', created)
            if created then
                -- Obtener la lista de puertas del servidor para el NUI sin sobrescribir la tabla global de objetos
                local serverDoors = lib.callback.await('origen_doorlock:server:GetAdminDoors', false) or {}
                
                Custom.Notify('Puerta creada correctamente', 'success')
                
                -- Reabrir el panel con la lista actualizada
                SendNUIMessage({
                    action = 'openMenu',
                    state = true
                })
                
                -- Esperar un poco antes de enviar las puertas actualizadas
                Wait(100)
                
                SendNUIMessage({
                    action = 'updateDoors',
                    doors = serverDoors
                })
                
                -- Restaurar el NUI focus al panel
                SetNuiFocus(true, true)
            else
                Custom.Notify('Error al crear la puerta', 'error')
                
                -- Reabrir el panel
                SendNUIMessage({
                    action = 'openMenu',
                    state = true
                })
                
                SetNuiFocus(true, true)
            end
        else
            -- Cancelado por el usuario - Volver al formulario de creación con los datos ORIGINALES
            Custom.Notify('Volviendo al formulario de creación...', 'info')
            
            -- Reabrir el panel
            SendNUIMessage({
                action = 'openMenu',
                state = true
            })
            
            Wait(100)
            
            -- Reabrir el modal de creación con los datos originales del NUI (data, no _data)
            SendNUIMessage({
                action = 'restoreCreationData',
                data = data  -- Enviar los datos ORIGINALES del formulario
            })
            
            -- Restaurar el NUI focus
            SetNuiFocus(true, true)
        end
    end)
end)

-- Actualizar opciones de una puerta existente sin selección física
RegisterNUICallback('updateDoor', function(data, cb)
    local id = tonumber(data.id)
    if not id then cb(false) return end

    local _data = {
        name      = data.name,
        maxDistance = tonumber(data.distance) or 1.5,
        rate      = tonumber(data.rate) or 1.0,
        autolock  = tonumber(data.autolock) or 0,
        locked    = (data.locked == true) and 1 or 0,
        lockpick  = (data.lockpick == true) and 1 or 0,
        automatic = data.automatic or false,
        passcode  = data.passcode or false,
        -- Siempre van (aunque vacíos): así el servidor sabe que se han quitado.
        groups    = {},
        players   = {},
    }

    if data.groups and next(data.groups) then
        for _, g in pairs(data.groups) do
            _data.groups[g.name] = tonumber(g.grade)
        end
    end

    if data.players and next(data.players) then
        for _, p in pairs(data.players) do
            _data.players[p.identifier] = true
        end
    end

    local updated = lib.callback.await('origen_doorlock:server:UpdateDoor', false, { id = id, data = _data })

    if updated then
        Custom.Notify('Puerta actualizada correctamente', 'success')
        local serverDoors = lib.callback.await('origen_doorlock:server:GetAdminDoors', false) or {}
        SendNUIMessage({ action = 'updateDoors', doors = serverDoors })
    else
        Custom.Notify('Error al actualizar la puerta', 'error')
    end

    cb(updated)
end)