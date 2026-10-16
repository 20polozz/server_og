function Utils.EntityPositioning(type, model, coords)
    local isPositioning = true
    local finish = false
    local cancel = false
    local precise = false
    local entity = nil
    local entityHeading = coords and coords.w or 0.0
    local entityCoords = nil
    local seatPreviewPed = nil
    local seatAnims = {
        { dict = "timetable@ron@ig_5_p3",            anim = "ig_5_p3_base" },
        { dict = "timetable@reunited@ig_10",          anim = "base_amanda" },
        { dict = "timetable@ron@ig_3_couch",          anim = "base" },
        { dict = "timetable@jimmy@mics3_ig_15@",      anim = "mics3_15_base_tracy" },
        { dict = "timetable@maid@couch@",             anim = "base" },
        { dict = "timetable@ron@ron_ig_2_alt1",       anim = "ig_2_alt1_base" },
        { dict = "sitcouch@joker",                    anim = "sitcouch_clip" },
    }
    local currentSeatAnim = 1
    
    SetPedConfigFlag(cache.ped, 122, true)
    local modelHash
    local previa = type == 'tarea' and Config.Tienda.Previa[model] or nil
    local ultimaPos, ultimaAnim = nil, 0
    if type == 'tarea' then
        --[[ Los puntos de tienda (caja, estantería, nevera…): un clon de tu
             personaje, transparente, haciendo la tarea (30/09, el usuario:
             «que se previsualice la tarea con un clon de mi pj en alpha
             haciendo la animación»). Así se ve si mira a la balda o a la
             pared antes de guardarlo. ]]
        entity = ClonePed(cache.ped, false, false, false)
        SetEntityAlpha(entity, 160, false)
        SetEntityInvincible(entity, true)
        SetBlockingOfNonTemporaryEvents(entity, true)
        SetPedConfigFlag(entity, 79, true)
        SetEntityCollision(entity, false, false)
        SetEntityCompletelyDisableCollision(entity, false, false)
        FreezeEntityPosition(entity, true)
        if not coords or (tonumber(coords.w) or 0) == 0 then entityHeading = GetEntityHeading(cache.ped) end
    elseif type ~= 'marker' and type ~= 'asiento' then
        modelHash = lib.requestModel(model)

        if type == 'vehicle' then
            entity = CreateVehicle(modelHash, 0.0, 0.0, 0.0, 0.0, false, false)
            SetEntityCompletelyDisableCollision(entity, false, false)
            SetModelAsNoLongerNeeded(modelHash)
            SetEntityAlpha(entity, 150, false)
            FreezeEntityPosition(entity, true)
        elseif type == 'prop' then
            -- El mueble de la cocina, sin colisión para que el rayo no choque
            -- con él mismo y se venga hacia la cámara.
            entity = CreateObject(modelHash, 0.0, 0.0, 0.0, false, false, false)
            -- Un mueble nuevo sale con el frente hacia la cámara (en estos
            -- modelos el frente es su -Y): así se ven los mandos y el horno.
            if not coords or (tonumber(coords.w) or 0) == 0 then
                entityHeading = GetGameplayCamRot(2).z
            end
            SetEntityAlpha(entity, 170, false)
            SetEntityCollision(entity, false, false)
            FreezeEntityPosition(entity, true)
            SetModelAsNoLongerNeeded(modelHash)
        elseif type == 'ped' then
            entity = CreatePed(4, modelHash, 0.0, 0.0, 0.0, 0.0, false, true)
            SetEntityAlpha(entity, 150, false)
            FreezeEntityPosition(entity, true)
            SetEntityInvincible(entity, true)
            SetBlockingOfNonTemporaryEvents(entity, true)
            SetPedConfigFlag(entity, 79, true)
            SetEntityCollision(entity, false, false)
            SetEntityCompletelyDisableCollision(entity, false, false)
            SetModelAsNoLongerNeeded(modelHash)
        end
    elseif type == 'asiento' then
        -- Create a ped preview with sitting animation
        modelHash = lib.requestModel(model or 'player_one')
        seatPreviewPed = CreatePed(4, modelHash, 0.0, 0.0, 0.0, 0.0, false, true)
        SetEntityAlpha(seatPreviewPed, 150, false)
        FreezeEntityPosition(seatPreviewPed, true)
        SetEntityInvincible(seatPreviewPed, true)
        SetBlockingOfNonTemporaryEvents(seatPreviewPed, true)
        SetPedConfigFlag(seatPreviewPed, 79, true)
        SetEntityCollision(seatPreviewPed, false, false)
        SetEntityCompletelyDisableCollision(seatPreviewPed, false, false)
        SetModelAsNoLongerNeeded(modelHash)
        
        -- Load and play sitting animation on the preview ped
        local animData = seatAnims[currentSeatAnim]
        if not HasAnimDictLoaded(animData.dict) then
            RequestAnimDict(animData.dict)
            local timeout = GetGameTimer() + 5000
            while not HasAnimDictLoaded(animData.dict) and GetGameTimer() < timeout do
                Wait(0)
            end
        end
        TaskPlayAnim(seatPreviewPed, animData.dict, animData.anim, 8.0, -8.0, -1, 1, 0, false, false, false)
        entity = seatPreviewPed
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
    local function nextAnim()
        if isPositioning and type == 'asiento' then
            currentSeatAnim = currentSeatAnim + 1
            if currentSeatAnim > #seatAnims then currentSeatAnim = 1 end
            local animData = seatAnims[currentSeatAnim]
            lib.requestAnimDict(animData.dict)
            TaskPlayAnim(seatPreviewPed, animData.dict, animData.anim, 8.0, -8.0, -1, 1, 0, false, false, false)
        end
    end
    local function prevAnim()
        if isPositioning and type == 'asiento' then
            currentSeatAnim = currentSeatAnim - 1
            if currentSeatAnim < 1 then currentSeatAnim = #seatAnims end
            local animData = seatAnims[currentSeatAnim]
            lib.requestAnimDict(animData.dict)
            TaskPlayAnim(seatPreviewPed, animData.dict, animData.anim, 8.0, -8.0, -1, 1, 0, false, false, false)
        end
    end

    RegisterCommand('entity_rotateleft', rotateLeft, false)
    RegisterCommand('entity_rotateright', rotateRight, false)
    RegisterCommand('+entity_precise_mode', function() setPrecise(true) end, false)
    RegisterCommand('-entity_precise_mode', function() setPrecise(false) end, false)
    RegisterCommand('entity_confirm', confirm, false)
    RegisterCommand('entity_cancel', doCancel, false)
    RegisterCommand('entity_nextanim', nextAnim, false)
    RegisterCommand('entity_prevanim', prevAnim, false)

    RegisterKeyMapping('entity_rotateleft', 'Colocar: girar a la izquierda', 'MOUSE_WHEEL', 'IOM_WHEEL_UP')
    RegisterKeyMapping('entity_rotateright', 'Colocar: girar a la derecha', 'MOUSE_WHEEL', 'IOM_WHEEL_DOWN')
    RegisterKeyMapping('+entity_precise_mode', 'Colocar: modo preciso', 'keyboard', 'LSHIFT')
    RegisterKeyMapping('entity_confirm', 'Colocar: confirmar', 'MOUSE_BUTTON', 'MOUSE_LEFT')
    RegisterKeyMapping('entity_cancel', 'Colocar: cancelar', 'MOUSE_BUTTON', 'MOUSE_RIGHT')
    RegisterKeyMapping('entity_nextanim', 'Colocar: animación siguiente', 'keyboard', 'RIGHT')
    RegisterKeyMapping('entity_prevanim', 'Colocar: animación anterior', 'keyboard', 'LEFT')
    
    local controls = {
        { key = 'R-Click', text = 'Cancelar' },
        { key = 'L-Click', text = 'Confirmar' },
        { key = 'Wheel', text = 'Rotar' },
        { key = 'Shift', text = 'Modo Preciso' }
    }
    
    if type == 'asiento' then
        table.insert(controls, { key = '← / →', text = 'Cambiar Animación' })
    end
    
    exports.origen_hud:setupControls(controls)

    while isPositioning do
        Wait(0)
        local hit, _, endCoords = lib.raycast.fromCamera(511, 4, 25.0)
        if hit then
            local waterSuccess, waterHeight = GetWaterHeight(endCoords.x, endCoords.y, endCoords.z)
            if waterSuccess and waterHeight > endCoords.z then
                endCoords = vector3(endCoords.x, endCoords.y, waterHeight)
            end
        end
        if type == 'marker' then
            if hit then
                local m = Config.Marker
                local offset = m.Offset or vector3(0.0, 0.0, 1.0)
                DrawMarker(m.Type, endCoords.x, endCoords.y, endCoords.z + offset.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, m.Size.x, m.Size.y, m.Size.z, m.Color.r, m.Color.g, m.Color.b, m.Color.a, m.BobUpAndDown, m.FaceCamera, 2, m.Rotate, nil, nil, false)
            end
        elseif type == 'asiento' then
            -- Move the seated preview ped to cursor position
            if seatPreviewPed and DoesEntityExist(seatPreviewPed) then
                if not hit then
                    SetEntityCoords(seatPreviewPed, 0.0, 0.0, 0.0, false, false, false, false)
                else
                    SetEntityCoords(seatPreviewPed, endCoords.x, endCoords.y, endCoords.z, false, false, false, false)
                    SetEntityHeading(seatPreviewPed, entityHeading)
                    -- Re-apply sitting animation if needed (entity might reset after teleport)
                    local animData = seatAnims[currentSeatAnim]
                    if not IsEntityPlayingAnim(seatPreviewPed, animData.dict, animData.anim, 3) then
                        TaskPlayAnim(seatPreviewPed, animData.dict, animData.anim, 8.0, -8.0, -1, 1, 0, false, false, false)
                    end
                end
            end
        elseif type == 'tarea' then
            -- Solo se mueve cuando cambia el sitio: recolocarlo en cada
            -- fotograma cortaba la animación del escenario
            if hit and (not ultimaPos or #(endCoords - ultimaPos) > 0.02) then
                SetEntityCoords(entity, endCoords.x, endCoords.y, endCoords.z, false, false, false, false)
                ultimaPos = endCoords
            elseif not hit and ultimaPos then
                SetEntityCoords(entity, 0.0, 0.0, 0.0, false, false, false, false)
                ultimaPos = nil
            end
            SetEntityHeading(entity, entityHeading)
            if previa and GetGameTimer() - ultimaAnim > 700 and not TareasAnimando(entity, previa) then
                ultimaAnim = GetGameTimer()
                TareasAnimar(entity, previa)
            end
        else
            if not hit then
                SetEntityCoords(entity, 0.0, 0.0, 0.0, false, false, false, false)
            else
                SetEntityCoords(entity, endCoords.x, endCoords.y, endCoords.z, false, false, false, false)
            end
            SetEntityHeading(entity, entityHeading)
        end

        if cancel then
            if DoesEntityExist(entity) then
                DeleteEntity(entity)
            end
            isPositioning = false
            entityCoords = nil
        end

        if finish then
            entityCoords = endCoords
            entityHeading = DoesEntityExist(entity) and (GetEntityHeading(entity) + 0.1) or entityHeading
            if DoesEntityExist(entity) then
                DeleteEntity(entity)
            end
            isPositioning = false
        end
    end

    exports.origen_hud:hideControls()
    lib.hideTextUI()
    SetPedConfigFlag(cache.ped, 122, false)

    return entityCoords and vector4(entityCoords.x, entityCoords.y, entityCoords.z, entityHeading) or nil
end