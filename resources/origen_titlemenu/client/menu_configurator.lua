-- Titlemenu in-game configurator menu (ox_lib).
-- Command is configurable in Config.MenuConfigurator.command

local state = {
    creation = nil,      -- vector4
    hidden = nil,        -- vector4
    fixedCam = nil,      -- vector4
    spawnCamCoords = nil,-- vector3
    spawnCamRot = nil,   -- vector3
    walkSpawn = nil,     -- vector4 (debug walk start)
    previewPed = nil,
    previewModel = 'mp_m_freemode_01',
    previewCam = nil
}

local function round(n, decimals)
    local m = 10 ^ (decimals or 2)
    return math.floor((n * m) + 0.5) / m
end

local function v4line(name, v)
    return ("%s = vector4(%.2f, %.2f, %.2f, %.2f)"):format(name, round(v.x, 2), round(v.y, 2), round(v.z, 2), round(v.w, 2))
end

local function v3line(name, v)
    return ("%s = vector3(%.2f, %.2f, %.2f)"):format(name, round(v.x, 2), round(v.y, 2), round(v.z, 2))
end

local function notify(msg, typ)
    if lib and lib.notify then
        lib.notify({
            title = 'Titlemenu Config',
            description = msg,
            type = typ or 'inform'
        })
    end
end

local function setConfiguratorNuiPreview(show)
    SendNUIMessage({
        action = 'configPreview',
        show = show and true or false
    })
end

local function getPlayerVector4()
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    local h = GetEntityHeading(ped)
    return vector4(c.x, c.y, c.z, h)
end

local function captureGameplayCamera()
    local pos = GetGameplayCamCoord()
    local rot = GetGameplayCamRot(2)
    state.fixedCam = vector4(pos.x, pos.y, pos.z, rot.z)
    state.spawnCamCoords = vector3(pos.x, pos.y, pos.z)
    state.spawnCamRot = vector3(rot.x, rot.y, rot.z)
end

local function ensureModel(model)
    local hash = tonumber(model) or GetHashKey(model)
    if not IsModelInCdimage(hash) then
        notify(('Modelo no valido: %s'):format(tostring(model)), 'error')
        return nil
    end
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end
    return hash
end

local function clearPreviewPed()
    if state.previewPed and DoesEntityExist(state.previewPed) then
        DeleteEntity(state.previewPed)
    end
    state.previewPed = nil
end

local function stopPreviewCamera()
    if state.previewCam and DoesCamExist(state.previewCam) then
        RenderScriptCams(false, true, 400, true, false)
        DestroyCam(state.previewCam, false)
    end
    state.previewCam = nil
    setConfiguratorNuiPreview(false)
end

local function startPreviewCamera()
    if not state.fixedCam then
        notify('Primero captura la camara actual para FixedCamera.', 'error')
        return false
    end

    stopPreviewCamera()
    state.previewCam = CreateCamWithParams(
        "DEFAULT_SCRIPTED_CAMERA",
        state.fixedCam.x,
        state.fixedCam.y,
        state.fixedCam.z,
        -5.0, -- same style used in titlemenu peds.lua
        0.0,
        state.fixedCam.w,
        40.0,
        false,
        2
    )
    SetCamActive(state.previewCam, true)
    RenderScriptCams(true, true, 600, true, false)
    return true
end

local function getDefaultWalkSpawnFromCreation()
    if not state.creation then return nil end
    local sideOffset = 2.5
    local headingRad = math.rad(state.creation.w)
    local forwardX = -math.sin(headingRad)
    local forwardY = math.cos(headingRad)
    local rightX = forwardY
    local rightY = -forwardX
    local leftPos = vector3(
        state.creation.x + (rightX * sideOffset),
        state.creation.y + (rightY * sideOffset),
        state.creation.z
    )
    local walkHeading = state.creation.w + 90.0
    if walkHeading >= 360.0 then walkHeading = walkHeading - 360.0 end
    return vector4(leftPos.x, leftPos.y, leftPos.z, walkHeading)
end

local function spawnPreviewPed()
    local origin = state.walkSpawn or state.creation
    if not origin then
        notify('Primero guarda Creation o WalkSpawn.', 'error')
        return
    end

    local hash = ensureModel(state.previewModel)
    if not hash then return end

    clearPreviewPed()
    state.previewPed = CreatePed(4, hash, origin.x, origin.y, origin.z, origin.w, false, true)
    SetEntityInvincible(state.previewPed, true)
    SetBlockingOfNonTemporaryEvents(state.previewPed, true)
    SetEntityAsMissionEntity(state.previewPed, true, true)
    SetEntityVisible(state.previewPed, true)
    SetEntityCollision(state.previewPed, true, true)
    SetEntityAlpha(state.previewPed, 255, false)
    PlaceObjectOnGroundProperly(state.previewPed)
    FreezeEntityPosition(state.previewPed, true)
    TaskStartScenarioInPlace(state.previewPed, "WORLD_HUMAN_GUARD_STAND", 0, true)
    SetModelAsNoLongerNeeded(hash)

    notify('NPC preview creado.', 'success')
end

local function testWalk()
    if not state.previewPed or not DoesEntityExist(state.previewPed) then
        notify('Crea primero el NPC preview.', 'error')
        return
    end
    if not state.walkSpawn or not state.creation then
        notify('Necesitas WalkSpawn y Creation para el test.', 'error')
        return
    end

    SetEntityCoords(state.previewPed, state.walkSpawn.x, state.walkSpawn.y, state.walkSpawn.z, false, false, false, false)
    SetEntityHeading(state.previewPed, state.walkSpawn.w)
    SetEntityVisible(state.previewPed, true)
    SetEntityAlpha(state.previewPed, 255, false)
    PlaceObjectOnGroundProperly(state.previewPed)
    FreezeEntityPosition(state.previewPed, false)
    ClearPedTasksImmediately(state.previewPed)

    TaskGoStraightToCoord(
        state.previewPed,
        state.creation.x,
        state.creation.y,
        state.creation.z,
        1.0,
        7000,
        state.creation.w,
        0.05
    )

    CreateThread(function()
        local timeout = GetGameTimer() + 7000
        while state.previewPed and DoesEntityExist(state.previewPed) and GetGameTimer() < timeout do
            local dist = #(GetEntityCoords(state.previewPed) - vector3(state.creation.x, state.creation.y, state.creation.z))
            if dist <= 0.15 then break end
            Wait(100)
        end

        if state.previewPed and DoesEntityExist(state.previewPed) then
            ClearPedTasks(state.previewPed)
            SetEntityCoords(state.previewPed, state.creation.x, state.creation.y, state.creation.z, false, false, false, false)
            SetEntityHeading(state.previewPed, state.creation.w)
            FreezeEntityPosition(state.previewPed, true)
            TaskStartScenarioInPlace(state.previewPed, "WORLD_HUMAN_GUARD_STAND", 0, true)
        end
    end)

    notify('Test ejecutado: spawn -> centro.', 'success')
end

local function testFullSequenceFromCamera()
    if not state.creation then
        notify('Necesitas CreationCoords para el test completo.', 'error')
        return
    end

    if not state.previewPed or not DoesEntityExist(state.previewPed) then
        spawnPreviewPed()
        if not state.previewPed or not DoesEntityExist(state.previewPed) then return end
    end

    local spawnPoint = state.walkSpawn or getDefaultWalkSpawnFromCreation()
    if not spawnPoint then
        notify('No hay WalkSpawn y no se pudo calcular uno.', 'error')
        return
    end

    if not startPreviewCamera() then
        return
    end

    setConfiguratorNuiPreview(true)

    local sideOffset = 2.5
    local headingRad = math.rad(state.creation.w)
    local forwardX = -math.sin(headingRad)
    local forwardY = math.cos(headingRad)
    local rightX = forwardY
    local rightY = -forwardX
    local exitPos = vector3(
        state.creation.x - (rightX * sideOffset),
        state.creation.y - (rightY * sideOffset),
        state.creation.z
    )
    local walkHeading = state.creation.w + 90.0
    if walkHeading >= 360.0 then walkHeading = walkHeading - 360.0 end

    SetEntityCoords(state.previewPed, spawnPoint.x, spawnPoint.y, spawnPoint.z, false, false, false, false)
    SetEntityHeading(state.previewPed, spawnPoint.w)
    SetEntityVisible(state.previewPed, true)
    SetEntityAlpha(state.previewPed, 255, false)
    PlaceObjectOnGroundProperly(state.previewPed)
    FreezeEntityPosition(state.previewPed, false)
    ClearPedTasksImmediately(state.previewPed)

    TaskGoStraightToCoord(state.previewPed, state.creation.x, state.creation.y, state.creation.z, 1.0, 7000, walkHeading, 0.05)

    CreateThread(function()
        local function finishPreview()
            stopPreviewCamera()
            -- reopen menu automatically so you can continue tuning
            if lib and lib.showContext then
                Wait(120)
                lib.showContext('titlemenu_configurator_main')
            end
            notify('Preview finalizada. Menu reabierto para seguir configurando.', 'success')
        end

        local timeout = GetGameTimer() + 7000
        while state.previewPed and DoesEntityExist(state.previewPed) and GetGameTimer() < timeout do
            local dist = #(GetEntityCoords(state.previewPed) - vector3(state.creation.x, state.creation.y, state.creation.z))
            if dist <= 0.15 then break end
            Wait(100)
        end

        if not state.previewPed or not DoesEntityExist(state.previewPed) then
            finishPreview()
            return
        end

        ClearPedTasks(state.previewPed)
        TaskAchieveHeading(state.previewPed, state.creation.w, 1200)
        Wait(1200)
        SetEntityHeading(state.previewPed, state.creation.w)
        FreezeEntityPosition(state.previewPed, true)
        TaskStartScenarioInPlace(state.previewPed, "WORLD_HUMAN_GUARD_STAND", 0, true)

        -- stay in center for 2s as requested
        Wait(2000)

        FreezeEntityPosition(state.previewPed, false)
        ClearPedTasksImmediately(state.previewPed)
        TaskAchieveHeading(state.previewPed, walkHeading, 900)
        Wait(900)
        TaskGoStraightToCoord(state.previewPed, exitPos.x, exitPos.y, exitPos.z, 1.0, 5000, walkHeading, 0.1)
        Wait(2600)

        if state.previewPed and DoesEntityExist(state.previewPed) then
            SetEntityVisible(state.previewPed, false)
            FreezeEntityPosition(state.previewPed, true)
            ClearPedTasks(state.previewPed)
            SetEntityCoords(state.previewPed, spawnPoint.x, spawnPoint.y, spawnPoint.z, false, false, false, false)
        end

        finishPreview()
    end)

    notify('Test completo iniciado (camara + entrada + espera + salida).', 'success')
end

local function printConfigBlock()
    
    if state.hidden then  end
    if state.creation then  end
    if state.fixedCam then  end
    if state.spawnCamCoords then  end
    if state.spawnCamRot then  end

    if state.creation then
        
        for i = 1, 5 do
            
            
            
            
            
        end
        
    end

    if state.walkSpawn then
        
    end
    
    notify('Bloque impreso en F8 listo para pegar en config.lua', 'success')
end

local function saveFromPlayer(targetKey, label)
    state[targetKey] = getPlayerVector4()
    notify(label .. ' guardado.', 'success')
end

local function setPreviewModel()
    local result = lib.inputDialog('Modelo NPC preview', {
        { type = 'input', label = 'Model', description = 'Ej: mp_m_freemode_01', default = state.previewModel, required = true }
    })
    if not result then return end
    state.previewModel = result[1]
    notify(('Modelo preview: %s'):format(state.previewModel), 'success')
end

local function clearAll()
    clearPreviewPed()
    stopPreviewCamera()
    state.creation = nil
    state.hidden = nil
    state.fixedCam = nil
    state.spawnCamCoords = nil
    state.spawnCamRot = nil
    state.walkSpawn = nil
    notify('Configurador limpiado.', 'success')
end

local function markerThread()
    CreateThread(function()
        while true do
            local sleep = 700

            if state.creation then
                sleep = 0
                DrawMarker(1, state.creation.x, state.creation.y, state.creation.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.35, 0.35, 0.22, 255, 60, 160, 180, false, false, 2, false, nil, nil, false)
            end

            if state.walkSpawn then
                sleep = 0
                DrawMarker(1, state.walkSpawn.x, state.walkSpawn.y, state.walkSpawn.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.35, 0.35, 0.22, 60, 180, 255, 180, false, false, 2, false, nil, nil, false)
            end

            Wait(sleep)
        end
    end)
end

local function openConfiguratorMenu()
    lib.registerContext({
        id = 'titlemenu_configurator_main',
        title = 'Configurador Titlemenu',
        options = {
            {
                title = 'Guardar CreationCoords (centro)',
                description = 'Usa tu posicion + heading actual.',
                icon = 'crosshairs',
                onSelect = function() saveFromPlayer('creation', 'CreationCoords') end
            },
            {
                title = 'Guardar HiddenCoords',
                description = 'Posicion de ocultacion del jugador real.',
                icon = 'eye-slash',
                onSelect = function() saveFromPlayer('hidden', 'HiddenCoords') end
            },
            {
                title = 'Guardar WalkSpawn (inicio caminata)',
                description = 'Punto donde empieza a caminar el NPC.',
                icon = 'shoe-prints',
                onSelect = function() saveFromPlayer('walkSpawn', 'WalkSpawn') end
            },
            {
                title = 'Capturar camara actual (3ra persona)',
                description = 'Guarda FixedCamera + SpawnCam desde gameplay cam.',
                icon = 'video',
                onSelect = function()
                    captureGameplayCamera()
                    notify('Camara capturada para FixedCamera/SpawnCam.', 'success')
                end
            },
            {
                title = 'Modelo NPC preview',
                description = ('Actual: %s'):format(state.previewModel),
                icon = 'user-tag',
                onSelect = setPreviewModel
            },
            {
                title = 'Crear/Respawnear NPC preview',
                description = 'Crea NPC en WalkSpawn o Creation.',
                icon = 'user-plus',
                onSelect = spawnPreviewPed
            },
            {
                title = 'TEST: mover NPC (spawn -> centro)',
                description = 'Simula el recorrido de entrada del menu.',
                icon = 'person-walking',
                onSelect = testWalk
            },
            {
                title = 'TEST COMPLETO DESDE CAMARA',
                description = 'Entrada -> centro -> animacion 2s -> salida.',
                icon = 'clapperboard',
                onSelect = testFullSequenceFromCamera
            },
            {
                title = 'Cerrar camara preview',
                description = 'Vuelve a la camara del jugador.',
                icon = 'camera-rotate',
                onSelect = function()
                    stopPreviewCamera()
                    notify('Camara preview cerrada.', 'success')
                end
            },
            {
                title = 'Imprimir bloque config listo (F8)',
                description = 'Pega este bloque en config.lua',
                icon = 'file-code',
                onSelect = printConfigBlock
            },
            {
                title = 'Limpiar todo',
                description = 'Borra NPC preview y resetea puntos.',
                icon = 'trash',
                onSelect = clearAll
            },
        }
    })

    lib.showContext('titlemenu_configurator_main')
end

CreateThread(function()
    markerThread()

    local cfg = Config.MenuConfigurator or {}
    if not cfg.enabled then
        return
    end

    local commandName = cfg.command or 'confgtitlemenu'
    RegisterCommand(commandName, function()
        if not lib then
            notify('ox_lib no disponible. No se puede abrir el menu.', 'error')
            return
        end
        openConfiguratorMenu()
    end, false)

    notify(('Comando configurador activo: /%s'):format(commandName), 'success')
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    clearPreviewPed()
    stopPreviewCamera()
    setConfiguratorNuiPreview(false)
end)

