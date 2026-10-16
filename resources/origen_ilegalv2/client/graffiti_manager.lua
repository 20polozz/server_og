-- ── Guard: si el sistema interno de graffiti está desactivado, no registrar nada ──
if not Config.Graffiti or not Config.Graffiti.Enable then return end

local graffitiPoints  = {}
local duiCounter      = 0
local duiSessionId    = tostring(GetGameTimer())  -- unique per resource start
local isCleaningGraffiti = false

-- ── Cleaning animation ───────────────────────────────────────────────────────
local MALE_DICT   = 'anim@scripted@freemode@postertag@graffiti_spray@male@'
local FEMALE_DICT = 'anim@scripted@freemode@postertag@graffiti_spray@heeled@'
local ERASE_ANIM_M = 'spray_can_var_01_male'
local ERASE_ANIM_F = 'spray_can_var_01_female'
local CLEAN_DURATION = Config.Graffiti.CleanDuration

local function IsMalePed(ped)
    return GetEntityModel(ped) ~= GetHashKey('mp_f_freemode_01')
end

local function LoadAnimDict(dict)
    if HasAnimDictLoaded(dict) then return end
    RequestAnimDict(dict)
    local t = 0
    while not HasAnimDictLoaded(dict) and t < 30 do Wait(100); t = t + 1 end
end

local cleanProp = nil

local function AttachSponge(ped)
    local model = GetHashKey('prop_sponge_01')
    RequestModel(model)
    local t = 0
    while not HasModelLoaded(model) and t < 30 do Wait(100); t = t + 1 end
    local prop      = CreateObject(model, 0.0, 0.0, 0.0, true, true, false)
    local boneIndex = GetPedBoneIndex(ped, 28422)
    AttachEntityToEntity(
        prop, ped, boneIndex,
        0.0, 0.0, 0.13, 0.0, 90.0, 0.0,
        true, true, false, true, 1, true
    )
    SetModelAsNoLongerNeeded(model)
    return prop
end

local function DetachSponge()
    if cleanProp and DoesEntityExist(cleanProp) then
        DeleteObject(cleanProp)
    end
    cleanProp = nil
end

local function CreateGraffitiDui(url)
    if not url then return nil end

    duiCounter = duiCounter + 1
    -- Include session ID to avoid TXD name collisions after resource restarts
    local txd = 'placed_graffiti_txd_' .. duiSessionId .. '_' .. duiCounter
    local txn = 'placed_graffiti_tex_' .. duiSessionId .. '_' .. duiCounter

    local resourceName = GetCurrentResourceName()
    local dui = CreateDui(('nui://%s/ui/graffiti_viewer.html'):format(resourceName), 512, 512)

    -- Esperar a que el WebKit process esté disponible ANTES de obtener el handle
    local timeout = 0
    while not IsDuiAvailable(dui) and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end

    -- Crear la textura runtime DESPUÉS de que el DUI esté disponible
    local txdHandle = CreateRuntimeTxd(txd)
    local duiHandle = GetDuiHandle(dui)
    CreateRuntimeTextureFromDuiHandle(txdHandle, txn, duiHandle)

    -- Breve espera para que el DOM esté listo
    Wait(300)

    -- Enviar loadImage con reintentos
    local msg = json.encode({ action = 'loadImage', url = url })
    SendDuiMessage(dui, msg)
    Wait(300)
    SendDuiMessage(dui, msg)  -- retry 1
    Wait(300)
    SendDuiMessage(dui, msg)  -- retry 2
    Wait(100)

    return { dui = dui, txd = txd, txn = txn }
end

local function DrawGraffitiMarker(graffiti, duiData)
    local config = graffiti.config

    local rotX = config.rotation - graffiti.coords.w
    local rotY = config.ground and 270.0 or 90.0
    local rotZ = config.ground and 90.0 or 0.0

    -- Offset para que no quede dentro de la superficie (z-fighting)
    -- Para graffitis colocados antes del fix, se aplica aquí también.
    local offset = 0.04
    local x = graffiti.coords.x
    local y = graffiti.coords.y
    local z = graffiti.coords.z
    if config.ground then
        z = z + offset  -- suelo: desplazar hacia arriba
    end
    -- Para paredes el offset ya viene baked en coords desde la v. actual.
    -- Este +Z sólo corrige graffitis de suelo colocados antes del fix.

    DrawMarker(
        3,
        x, y, z,
        0.0, 0.0, 0.0,
        rotX, rotY, rotZ,
        config.scale, config.scale, config.scale,
        255, 255, 255, config.transparencia,
        false, false, 2, false,
        duiData.txd, duiData.txn, false
    )
end

local function CreateGraffitiPoint(graffiti)
    local point = lib.points.new({
        coords = graffiti.coords.xyz,
        distance = 100.0,
        graffiti = graffiti,
        duiData = nil
    })

    function point:onEnter()
        self.pendingDelete = false

        if not self.graffiti.imageUrl then
            return
        end

        CreateThread(function()
            self.duiData = CreateGraffitiDui(self.graffiti.imageUrl)
        end)
    end

    function point:onExit()
        if self.duiData then
            DestroyDui(self.duiData.dui)
            self.duiData = nil
        end
    end

    function point:nearby()
        if self.duiData then
            DrawGraffitiMarker(self.graffiti, self.duiData)
        end
    end

    graffitiPoints[graffiti.id] = point
    return point
end

CreateThread(function()
    Wait(2000)
    
    
    local result = lib.callback.await('origen_gang:server:getPlacedGraffitis', false)
    
    if result then
        
        for _, graffiti in ipairs(result) do
            CreateGraffitiPoint(graffiti)
        end
    end
end)

RegisterNetEvent('origen_gang:client:updatePlacedGraffiti', function(graffiti)
    
    if graffitiPoints[graffiti.id] then
        local point = graffitiPoints[graffiti.id]
        if point.duiData then
            DestroyDui(point.duiData.dui)
        end
        point:remove()
    end
    
    CreateGraffitiPoint(graffiti)
end)

RegisterNetEvent('origen_gang:client:removePlacedGraffiti', function(id)
    if graffitiPoints[id] then
        local point = graffitiPoints[id]
        if point.duiData then
            DestroyDui(point.duiData.dui)
        end
        point:remove()
        graffitiPoints[id] = nil
    end
end)

-- ── Cleaning rag: start the cleaning process ─────────────────────────────────

RegisterNetEvent('origen_gang:client:startGraffitiCleaning', function()
    if isCleaningGraffiti then return end

    -- Find nearest graffiti within 2.5m
    local ped      = PlayerPedId()
    local pos      = GetEntityCoords(ped)
    local nearest  = nil
    local nearDist = 2.5

    for id, point in pairs(graffitiPoints) do
        if point.currentDistance and point.currentDistance <= nearDist then
            nearest  = point.graffiti
            nearDist = point.currentDistance
        end
    end

    if not nearest then
        Notify.SendNotification(locale:t('notify.error_title'), locale:t('notify.graffiti_none_nearby'), 'error')
        return
    end

    isCleaningGraffiti = true
    local graffitiId   = nearest.id
    local isMale       = IsMalePed(ped)
    local dict         = isMale and MALE_DICT or FEMALE_DICT
    local anim         = isMale and ERASE_ANIM_M or ERASE_ANIM_F

    -- Adjuntar esponja + animación full body (flag 1 = cuerpo completo, loop, sin movimiento)
    CreateThread(function()
        DetachSponge()
        cleanProp = AttachSponge(ped)
        LoadAnimDict(dict)
        TaskPlayAnim(ped, dict, anim, 8.0, -1.0, -1, 1, 0.0, false, false, false)
    end)

    MostrarTeclas({ { key = 'BACKSPACE', text = locale:t('ui.cancel') } })

    local cancelled = false

    -- Thread progressbar: propio thread para no bloquear la lógica
    CreateThread(function()
        ProgressBar.Open({ duration = CLEAN_DURATION, label = locale:t('notify.graffiti_cleaning_progress'), canCancel = false })
    end)

    -- Cancel + movimiento bloqueado: DisableControl en lugar de FreezeEntity para que la anim funcione
    CreateThread(function()
        while isCleaningGraffiti do
            DisableControlAction(0, 30, true)   -- move LR
            DisableControlAction(0, 31, true)   -- move UD
            DisableControlAction(0, 21, true)   -- sprint
            DisableControlAction(0, 322, true)  -- ESC
            DisableControlAction(0, 177, true)  -- BACKSPACE
            DisablePlayerFiring(ped, true)
            if IsDisabledControlJustPressed(0, 322) or IsDisabledControlJustPressed(0, 177) then
                cancelled = true
                isCleaningGraffiti = false
            end
            Wait(0)
        end
    end)

    -- Timer thread
    CreateThread(function()
        local elapsed = 0
        while elapsed < CLEAN_DURATION and isCleaningGraffiti do
            Wait(500)
            elapsed = elapsed + 500
        end

        -- Cleanup
        ClearPedTasksImmediately(ped)
        DetachSponge()
        QuitarTeclas()
        isCleaningGraffiti = false

        if not cancelled then
            TriggerServerEvent('origen_gang:server:finishGraffitiCleaning', graffitiId)
        else
            Notify.SendNotification(locale:t('notify.cancelled_title'), locale:t('notify.graffiti_cleaning_cancelled'), 'error')
        end
    end)
end)
