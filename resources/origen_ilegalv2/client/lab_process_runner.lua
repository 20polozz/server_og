-- ── Lab Process Runner — Motor genérico de laboratorios (cliente) ─────────────
--
-- Permite registrar labs sin escribir código repetido.
-- Cada lab se registra con su config y el runner gestiona:
--   • lib.points por stage
--   • DrawMarker por stage
--   • HelpText contextual (solo muestra el step activo)
--   • Callback al servidor (nombre auto-generado por convención)
--   • Animaciones (simples y networked con props)
--   • Barra de progreso
--   • Estado de producción (stage, animRunning, runTimers, runModifiers)
--   • Lifecycle: OnEnter / OnExit / OnPlayerUnload / onResourceStop
--
-- CONVENCIÓN DE CALLBACKS AL SERVIDOR:
--   Primer stage del lab → 'origen_gang:labs:{type}:stage_{stageId}'
--   Stages intermedios   → 'origen_gang:labs:{type}:stage_{stageId}'
--   Último stage (bag)   → 'origen_gang:labs:{type}:stage_{stageId}'
--   El servidor recibe el mismo callback para todos.
--   El servidor decide qué es "primer stage" y qué es "último" por la secuencia.
--
-- MODO CUSTOM:
--   Si el lab pasa hooks { onEnter, onExit } en Register(), el runner los llama
--   además de la lógica estándar. Útil para labs con comportamiento especial
--   (ej: weed → buscar plantas tomadas antes de entrar).
--
-- USO MÍNIMO (en config/lab_heroin.lua o client/lab_heroin.lua):
--   if Config.LabHeroin and Config.LabHeroin.Enabled then
--       LabProcessRunner.Register('heroin', Config.LabHeroin)
--   end

local dbg = Debug:new({ enabled = Config.Debug })

LabProcessRunner = {}

-- ── Fallback de animación garantizado ────────────────────────────────────────
local FALLBACK_DICT = "missheistdockssetup1clipboard@idle_a"
local FALLBACK_CLIP = "idle_a"

-- ── Helpers de carga de recursos ─────────────────────────────────────────────

local function requestDict(dict)
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local t = 0
    while not HasAnimDictLoaded(dict) and t < 3000 do
        Wait(50) ; t = t + 50
    end
    return HasAnimDictLoaded(dict)
end

local function requestModel(hash)
    if HasModelLoaded(hash) then return true end
    RequestModel(hash)
    local t = 0
    while not HasModelLoaded(hash) and t < 3000 do
        Wait(50) ; t = t + 50
    end
    return HasModelLoaded(hash)
end

-- ── Animaciones ───────────────────────────────────────────────────────────────

local function playSimpleAnim(anim, durationMs, labType)
    local dict = anim.dict
    local clip = anim.clip

    if not requestDict(dict) then
        dbg:warning('[Runner:'..labType..'] Dict no cargó:', dict, '— usando fallback')
        dict = FALLBACK_DICT
        clip = FALLBACK_CLIP
        if not requestDict(dict) then return end
    end

    local ped = PlayerPedId()
    if anim.freeze then FreezeEntityPosition(ped, true) end
    TaskPlayAnim(ped, dict, clip,
        anim.blendIn or 4.0, anim.blendOut or -8.0,
        durationMs, anim.flag or 49,
        0, false, false, false
    )
    Wait(durationMs)
    StopAnimTask(ped, dict, clip, 3.0)
    if anim.freeze then FreezeEntityPosition(ped, false) end
    RemoveAnimDict(dict)
end

local function playNetworkedAnim(anim, baseCoords, durationMs)
    if not requestDict(anim.dict) then return end

    local ped       = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    local off       = anim.offset   or vector3(0.0, 0.0, 0.0)
    local rot       = anim.rotation or vector3(0.0, 0.0, 0.0)
    local scenePos  = vector3(baseCoords.x + off.x, baseCoords.y + off.y, baseCoords.z + off.z)

    SetEntityCoords(ped, baseCoords.x, baseCoords.y, baseCoords.z, false, false, false, false)
    Wait(1)

    local scene = NetworkCreateSynchronisedScene(
        scenePos.x, scenePos.y, scenePos.z,
        rot.x, rot.y, rot.z,
        2, false, false, 1065353216, 0, 1.3
    )
    NetworkAddPedToSynchronisedScene(ped, scene, anim.dict, anim.clip,
        anim.blendIn or 1.5, anim.blendOut or -4.0, 1, 16, 1148846080, 0
    )

    local objects = {}
    for _, obj in ipairs(anim.objects or {}) do
        local modelHash = GetHashKey(obj.hash)
        if requestModel(modelHash) then
            local o = CreateObjectNoOffset(obj.hash, pedCoords, true, true, true)
            SetModelAsNoLongerNeeded(modelHash)
            NetworkAddEntityToSynchronisedScene(o, scene, anim.dict, obj.clip, 4.0, -8.0, 1)
            objects[#objects + 1] = o
        end
    end

    if anim.freeze then FreezeEntityPosition(ped, true) end
    NetworkStartSynchronisedScene(scene)
    Wait(durationMs)
    NetworkStopSynchronisedScene(scene)

    for _, o in ipairs(objects) do DeleteEntity(o) end
    if anim.freeze then FreezeEntityPosition(ped, false) end
    RemoveAnimDict(anim.dict)
end

-- Lanza la animación en un hilo paralelo (no bloquea la barra de progreso).
local function spawnAnim(anim, coords, durationMs, labType)
    if not anim then return end
    CreateThread(function()
        if anim.networked then
            playNetworkedAnim(anim, coords, durationMs)
        else
            playSimpleAnim(anim, durationMs, labType)
        end
    end)
end

-- ── DrawMarker helper ─────────────────────────────────────────────────────────

local DEFAULT_MARKER = {
    type         = 22,
    offset       = { x = 0.0, y = 0.0, z = 0.0 },
    scale        = { x = 0.25, y = 0.25, z = 0.25 },
    color        = { r = 0, g = 0, b = 0, a = 180 },
    bobUpAndDown = true,
    faceCamera   = true,
    rotationOrder = 2,
    rotate       = false,
}

local function drawStageMarker(mk, coords)
    mk = mk or DEFAULT_MARKER
    DrawMarker(
        mk.type or DEFAULT_MARKER.type,
        coords.x + (mk.offset and mk.offset.x or 0.0),
        coords.y + (mk.offset and mk.offset.y or 0.0),
        coords.z + (mk.offset and mk.offset.z or 0.0),
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        (mk.scale and mk.scale.x or DEFAULT_MARKER.scale.x),
        (mk.scale and mk.scale.y or DEFAULT_MARKER.scale.y),
        (mk.scale and mk.scale.z or DEFAULT_MARKER.scale.z),
        (mk.color and mk.color.r or DEFAULT_MARKER.color.r),
        (mk.color and mk.color.g or DEFAULT_MARKER.color.g),
        (mk.color and mk.color.b or DEFAULT_MARKER.color.b),
        (mk.color and mk.color.a or DEFAULT_MARKER.color.a),
        mk.bobUpAndDown ~= false,
        mk.faceCamera   ~= false,
        mk.rotationOrder or DEFAULT_MARKER.rotationOrder,
        mk.rotate == true,
        nil, nil, false
    )
end

-- ── Instancia de runner por tipo de lab ──────────────────────────────────────

-- _runners[labType] = { cfg, stages, production, points, currentTextUI, hooks }
local _runners = {}

-- Construye la tabla de stages ordenados desde Config.Stages (array).
-- Copia label_key, help_key y done_key para que el runner los use al
-- construir las keys de locale sin depender del stageId directamente.
--   label_key → progress bar:  notify.{labType}_{label_key}
--   help_key  → HelpText:      notify.{labType}_help_{help_key}  (fallback: label_key)
--   done_key  → notif done:    notify.{labType}_{done_key}        (fallback: label_key..'_done')
local function buildStageList(stages)
    local list = {}
    for i, s in ipairs(stages) do
        list[i] = {
            id        = s.id,
            index     = i,
            prevId    = i > 1 and stages[i - 1].id or nil,
            label_key = s.label_key or s.id,
            help_key  = s.help_key  or s.label_key or s.id,
            done_key  = s.done_key  or (s.label_key or s.id) .. '_done',
        }
    end
    return list
end

-- Devuelve el stage_id anterior al dado, o nil si es el primero.
local function getPrevStageId(stageList, stageId)
    for _, s in ipairs(stageList) do
        if s.id == stageId then return s.prevId end
    end
    return nil
end

-- Devuelve el entry completo del stage (con label_key, help_key, done_key).
local function getStageEntry(stageList, stageId)
    for _, s in ipairs(stageList) do
        if s.id == stageId then return s end
    end
    return nil
end

-- Título de los avisos del laboratorio según la marca (setr origen:marca)
local TITULO_LAB = (GetConvar('origen:marca', 'origen') == 'nacion') and 'Nación Ilegal' or 'Origen Ilegal'

local function sendLabNotify(message, notifyType)
    if not message or message == '' then return end
    if Notify and Notify.SendNotification then
        return Notify.SendNotification(TITULO_LAB, message, notifyType or 'info', 5000)
    end
    return Notify.SendNotify(message, notifyType or 'info')
end

local function buildOutputNotifyMessage(outputs)
    if type(outputs) ~= 'table' or #outputs == 0 then return nil end

    local parts = {}
    for _, out in ipairs(outputs) do
        local amount = tonumber(out.amount) or 0
        local label = tostring(out.label or out.item or 'item')
        if label:find('_') and not label:find('%s') then
            label = label:gsub('_', ' ')
        end
        parts[#parts + 1] = ('%sx %s'):format(amount, label)
    end

    if #parts == 0 then return nil end
    return 'Recibiste: ' .. table.concat(parts, ', ')
end

-- ── Lógica de ejecución de un stage ──────────────────────────────────────────

local function executeStage(runner, stageId)
    local cfg       = runner.cfg
    local prod      = runner.production
    local stageList = runner.stageList
    local labType   = runner.labType
    local INTER     = cfg.Interactions or {}
    local TIMERS    = cfg.Timers or {}
    local ANIMS     = cfg.Animations or {}
    local COORDS    = cfg.Coords or {}

    -- Guard: animación corriendo
    if prod.animRunning then
        sendLabNotify(locale:t('notify.' .. labType .. '_already_in_progress'), 'error')
        return
    end

    -- Guard: stage anterior correcto
    local prevId = getPrevStageId(stageList, stageId)
    if prod.stage ~= prevId then
        sendLabNotify(locale:t('notify.' .. labType .. '_wrong_stage'), 'error')
        return
    end

    -- Guard: dentro del lab correcto
    local insideLab = exports[GetCurrentResourceName()]:GetInsideLab()
    local activeType = insideLab and (insideLab.gameplay_type or insideLab.lab_type)
    if not activeType or activeType ~= labType then return end

    prod.animRunning = true

    -- Callback al servidor (nombre unificado por convención)
    local cbName = 'origen_gang:labs:' .. labType .. ':stage_' .. stageId
    local result = lib.callback.await(cbName, false)

    if not result or not result.success then
        local errMsg = result and result.message or 'error'

        local notifyText
        if (errMsg == 'missing_item' or errMsg == 'missing_required') and result.item then
            -- El servidor manda item, needed y has — mostrar exactamente qué falta
            local needed = tostring(result.needed or '?')
            local has = tostring(result.has or 0)
            local itemLabel = tostring(result.item or 'item')
            if itemLabel:find('_') and not itemLabel:find('%s') then
                itemLabel = itemLabel:gsub('_', ' ')
            end
            -- Fallback fijo en español para evitar mensajes en inglés por locale runtime.
            notifyText = ('Te faltan %sx %s (tenés %s)'):format(needed, itemLabel, has)
        else
            local msgs = {
                not_in_lab             = locale:t('notify.' .. labType .. '_not_in_lab'),
                wrong_lab_type         = locale:t('notify.' .. labType .. '_wrong_lab_type'),
                on_cooldown            = locale:t('notify.' .. labType .. '_on_cooldown'),
                already_in_progress    = locale:t('notify.' .. labType .. '_already_in_progress'),
                wrong_stage            = locale:t('notify.' .. labType .. '_wrong_stage'),
                too_far                = locale:t('notify.' .. labType .. '_wrong_stage'),
                requires_basic_upgrade = locale:t('notify.' .. labType .. '_requires_basic_upgrade'),
            }
            notifyText = msgs[errMsg] or locale:t('notify.error')
        end

        sendLabNotify(notifyText, 'error')
        prod.animRunning = false
        return
    end

    -- El primer stage (prevId == nil) puede devolver timers y modifiers efectivos
    if prevId == nil then
        prod.runTimers    = result.timers    or nil
        prod.runModifiers = result.modifiers or nil
    end

    -- Determinar duración efectiva
    local baseDuration = TIMERS[stageId] or 8000
    local duration     = (prod.runTimers and prod.runTimers[stageId]) or baseDuration

    -- Hook pre-stage: lógica custom antes de arrancar anim/progress de un stage.
    if runner.hooks and runner.hooks.onStageStart then
        runner.hooks.onStageStart(stageId, result)
    end

    -- Lanzar animación y barra en paralelo
    local animCfg = ANIMS[stageId]
    local coord   = COORDS[stageId]
    if animCfg and coord then
        spawnAnim(animCfg, coord, duration, labType)
    end

    -- Obtener el entry del stage (tiene label_key, help_key, done_key)
    local stageEntry = getStageEntry(stageList, stageId)
    local labelKey   = stageEntry and stageEntry.label_key or stageId
    local doneKey    = stageEntry and stageEntry.done_key  or (labelKey .. '_done')

    ProgressBar.Open({
        duration  = duration,
        label     = locale:t('notify.' .. labType .. '_' .. labelKey),
        canCancel = false,
    })

    -- Avanzar estado
    prod.stage       = stageId
    prod.animRunning = false

    -- Si es el último stage, leer outputs y resetear ciclo
    local isLast = stageList[#stageList].id == stageId
    local outputMsg = buildOutputNotifyMessage(result.outputs)
    if isLast then
        if outputMsg then
            sendLabNotify(outputMsg, 'success')
        else
            sendLabNotify(locale:t('notify.' .. labType .. '_' .. doneKey), 'success')
        end
        prod.stage        = nil
        prod.runTimers    = nil
        prod.runModifiers = nil
    else
        -- Notificación de etapa intermedia usando done_key del stage
        sendLabNotify(outputMsg or locale:t('notify.' .. labType .. '_' .. doneKey), 'success')
    end

    -- Hook post-stage: permite al lab hacer lógica custom después de que el runner
    -- completa un stage (ej: meth → attach/detach tray prop).
    if runner.hooks and runner.hooks.onStageComplete then
        runner.hooks.onStageComplete(stageId, result)
    end
end

-- ── Construcción de points ────────────────────────────────────────────────────

local function removePoint(runner, stageId)
    if runner.points[stageId] then
        runner.points[stageId]:remove()
        runner.points[stageId] = nil
    end
end

local function createPoint(runner, stageId)
    removePoint(runner, stageId)

    local cfg       = runner.cfg
    local prod      = runner.production
    local stageList = runner.stageList
    local INTER     = cfg.Interactions or {}
    local COORDS    = cfg.Coords or {}
    local labType   = runner.labType

    local coords = COORDS[stageId]
    if not coords then
        dbg:warning('[Runner:'..labType..'] Sin coords para stage', stageId)
        return
    end

    local p = lib.points.new({
        coords    = coords,
        distance  = INTER.PointDistance or 40.0,
        stageName = stageId,
    })

    function p:nearby()
        -- Guard: dentro del lab correcto y sin anim corriendo
        local insideLab = exports[GetCurrentResourceName()]:GetInsideLab()
        local activeType = insideLab and (insideLab.gameplay_type or insideLab.lab_type)
        if not activeType or activeType ~= labType then return end
        if prod.animRunning then return end

        local ped  = PlayerPedId()
        local dist = #(GetEntityCoords(ped) - coords)

        -- Dibujar marker
        if dist < (INTER.DrawDistance or 8.0) then
            local mk = cfg.Markers and cfg.Markers[stageId]
            drawStageMarker(mk, coords)
        end

        -- Mostrar HelpText solo si es el turno de este stage
        if dist < (INTER.InteractDistance or 1.8) then
            local prevId = getPrevStageId(stageList, stageId)
            local isMyTurn = (prod.stage == prevId)

            if isMyTurn then
                if runner.currentTextUI ~= stageId then
                    -- Usar help_key del stage (definida en Config.Stages)
                    -- Construye: notify.{labType}_help_{help_key}
                    local stageEntry = getStageEntry(runner.stageList, stageId)
                    local helpKey    = stageEntry and stageEntry.help_key or stageId
                    local helpText   = locale:t('notify.' .. labType .. '_help_' .. helpKey)
                    HelpText.ShowHelpText(helpText)
                    runner.currentTextUI = stageId
                end

                if IsControlJustReleased(0, 38) then
                    HelpText.HideHelpText()
                    runner.currentTextUI = nil
                    executeStage(runner, stageId)
                end
            elseif runner.currentTextUI == stageId then
                HelpText.HideHelpText()
                runner.currentTextUI = nil
            end
        elseif runner.currentTextUI == stageId then
            HelpText.HideHelpText()
            runner.currentTextUI = nil
        end
    end

    runner.points[stageId] = p
end

local function createAllPoints(runner)
    local cfg = runner.cfg
    for _, s in ipairs(cfg.Stages or {}) do
        createPoint(runner, s.id)
    end
    dbg:info('[Runner:'..runner.labType..'] Puntos creados')
end

local function removeAllPoints(runner)
    for stageId in pairs(runner.points) do
        removePoint(runner, stageId)
    end
    if runner.currentTextUI then
        HelpText.HideHelpText()
        runner.currentTextUI = nil
    end
end

-- ── Reset de producción ───────────────────────────────────────────────────────

local function resetProduction(runner)
    local prod = runner.production
    prod.stage        = nil
    prod.animRunning  = false
    prod.runTimers    = nil
    prod.runModifiers = nil
    -- Si el lab tiene un hook de reset custom (ej: meth → detachTrayProp)
    if runner.hooks and runner.hooks.onReset then
        runner.hooks.onReset()
    end
end

-- ── API pública ───────────────────────────────────────────────────────────────

--[[
    LabProcessRunner.Register(labType, cfg, hooks?)

    labType  : string — clave del lab (ej: 'heroin')
    cfg      : table  — Config.LabHeroin completo
                Campos requeridos: Stages (array), Coords, Timers, Interactions
                Campos opcionales: Markers, Animations
    hooks    : table? — hooks opcionales
                { onEnter(labType), onExit(labType), onReset() }

    Registra el runner para el lab y escucha los eventos genéricos de ciclo de vida.
]]
function LabProcessRunner.Register(labType, cfg, hooks)
    if not labType or not cfg then
        dbg:error('[Runner] Register: labType y cfg son obligatorios')
        return
    end

    if not cfg.Stages or #cfg.Stages == 0 then
        dbg:error('[Runner:'..labType..'] Register: cfg.Stages debe ser un array no vacío')
        return
    end

    local runner = {
        labType      = labType,
        cfg          = cfg,
        stageList    = buildStageList(cfg.Stages),
        production   = {
            stage        = nil,
            animRunning  = false,
            runTimers    = nil,
            runModifiers = nil,
        },
        points       = {},
        currentTextUI = nil,
        hooks        = hooks or {},
    }

    _runners[labType] = runner

    -- ── Lifecycle: OnEnter ────────────────────────────────────────────────────
    AddEventHandler('origen:Lab:OnEnter', function(type)
        if type ~= labType then return end
        createAllPoints(runner)
        if runner.hooks and runner.hooks.onEnter then
            runner.hooks.onEnter(labType)
        end
    end)

    -- ── Lifecycle: OnExit ─────────────────────────────────────────────────────
    AddEventHandler('origen:Lab:OnExit', function(type)
        if type ~= labType then return end
        resetProduction(runner)
        removeAllPoints(runner)
        if runner.hooks and runner.hooks.onExit then
            runner.hooks.onExit(labType)
        end
    end)

    -- ── Player unload ─────────────────────────────────────────────────────────
    AddEventHandler('origen:Client:OnPlayerUnload', function()
        resetProduction(runner)
        removeAllPoints(runner)
    end)

    -- ── Resource stop ─────────────────────────────────────────────────────────
    AddEventHandler('onResourceStop', function(resourceName)
        if GetCurrentResourceName() ~= resourceName then return end
        resetProduction(runner)
        removeAllPoints(runner)
    end)

    dbg:info('[Runner:'..labType..'] Registrado con', #cfg.Stages, 'stages')
end

--[[
    LabProcessRunner.GetProduction(labType)
    Devuelve el estado de producción actual del lab. Útil para hooks externos.
]]
function LabProcessRunner.GetProduction(labType)
    local runner = _runners[labType]
    return runner and runner.production or nil
end

--[[
    LabProcessRunner.ResetProduction(labType)
    Fuerza el reset del ciclo. Expuesto como export en cada lab via esta función.
]]
function LabProcessRunner.ResetProduction(labType)
    local runner = _runners[labType]
    if runner then resetProduction(runner) end
end
