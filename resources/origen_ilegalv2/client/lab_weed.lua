-- ── Weed Lab — Gameplay Cliente ──────────────────────────────────────────────
-- Sistema completo fiel a md-drugs:
--   - 14 plantas dentro del lab con respawn por timer
--   - 4 spots de secado independientes y simultáneos
--   - Grinder en punto del lab (requiere weedgrinder en inventario)
--   - Embolsadora en punto del lab
-- Sin target: lib.points + DrawMarker + HelpText + tecla E.

local dbg = Debug:new({ enabled = Config.Debug })

if not Config.LabWeed or not Config.LabWeed.Enabled then return end

local CFG   = Config.LabWeed
local INTER = CFG.Interactions
local TIMERS = CFG.Timers
local ANIMS = CFG.Animations

-- ── Estado ────────────────────────────────────────────────────────────────────
-- Plantas: [index] = entidad prop | nil si fue cosechada
local plantEntities = {}
-- Points de plantas: [index] = lib.points handle
local plantPoints   = {}

-- Spots de secado: [index] = { prop, ready, point }
local drySlots = {}
for i = 1, #CFG.DrySpots do
    drySlots[i] = { prop = nil, ready = false, point = nil }
end

-- Points de estaciones fijas
local stationPoints = {}  -- { grinder = p, bagger = p }

local currentTextUI = nil
local animRunning   = false

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function ensureInWeedLab()
    local lab = exports[GetCurrentResourceName()]:GetInsideLab()
    return lab and (lab.gameplay_type or lab.lab_type) == 'weed'
end

local function requestDict(dict)
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local t = 0
    while not HasAnimDictLoaded(dict) and t < 3000 do Wait(50) ; t = t + 50 end
    return HasAnimDictLoaded(dict)
end

local function requestModel(hash)
    if HasModelLoaded(hash) then return true end
    RequestModel(hash)
    local t = 0
    while not HasModelLoaded(hash) and t < 3000 do Wait(50) ; t = t + 50 end
    return HasModelLoaded(hash)
end

local FALLBACK_DICT = "missheistdockssetup1clipboard@idle_a"
local FALLBACK_CLIP = "idle_a"

local function playSimpleAnim(animKey, durationMs)
    local anim = ANIMS[animKey]
    if not anim then return end
    local dict, clip = anim.dict, anim.clip
    if not requestDict(dict) then
        dbg:warning('[WeedLab] Dict no cargó:', dict)
        dict, clip = FALLBACK_DICT, FALLBACK_CLIP
        if not requestDict(dict) then return end
    end
    local ped = PlayerPedId()
    if anim.freeze then FreezeEntityPosition(ped, true) end
    TaskPlayAnim(ped, dict, clip, anim.blendIn or 4.0, anim.blendOut or -8.0,
        durationMs, anim.flag or 49, 0, false, false, false)
    Wait(durationMs)
    StopAnimTask(ped, dict, clip, 3.0)
    if anim.freeze then FreezeEntityPosition(ped, false) end
    RemoveAnimDict(dict)
end

local function playNetworkedAnim(animKey, baseCoords, durationMs)
    local anim = ANIMS[animKey]
    if not anim or not requestDict(anim.dict) then return end
    local ped       = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    local off       = anim.offset   or vector3(0.0, 0.0, 0.0)
    local rot       = anim.rotation or vector3(0.0, 0.0, 0.0)
    local scenePos  = vector3(baseCoords.x + off.x, baseCoords.y + off.y, baseCoords.z + off.z)
    SetEntityCoords(ped, baseCoords.x, baseCoords.y, baseCoords.z, false, false, false, false)
    Wait(1)
    local scene = NetworkCreateSynchronisedScene(
        scenePos.x, scenePos.y, scenePos.z, rot.x, rot.y, rot.z,
        2, false, false, 1065353216, 0, 1.3)
    NetworkAddPedToSynchronisedScene(ped, scene, anim.dict, anim.clip,
        anim.blendIn or 1.5, anim.blendOut or -4.0, 1, 16, 1148846080, 0)
    local objects = {}
    for _, obj in ipairs(anim.objects or {}) do
        local h = GetHashKey(obj.hash)
        if requestModel(h) then
            local o = CreateObjectNoOffset(obj.hash, pedCoords, true, true, true)
            SetModelAsNoLongerNeeded(h)
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

local function spawnAnim(animKey, coords, durationMs)
    CreateThread(function()
        local anim = ANIMS[animKey]
        if not anim then return end
        if anim.networked then
            playNetworkedAnim(animKey, coords, durationMs)
        else
            playSimpleAnim(animKey, durationMs)
        end
    end)
end

local function runProgressBar(labelKey, durationMs)
    ProgressBar.Open({
        duration  = durationMs,
        label     = locale:t('notify.weed_' .. labelKey),
        canCancel = false,
    })
end

local function serverError(result)
    local msgs = {
        missing_item           = locale:t('notify.weed_missing_item'),
        missing_tool           = locale:t('notify.weed_missing_tool'),
        not_in_lab             = locale:t('notify.weed_not_in_lab'),
        already_taken          = locale:t('notify.weed_already_taken'),
        slot_occupied          = locale:t('notify.weed_slot_occupied'),
        slot_not_ready         = locale:t('notify.weed_slot_not_ready'),
        too_far                = locale:t('notify.weed_too_far'),
        requires_basic_upgrade = locale:t('notify.weed_requires_basic_upgrade'),
    }
    local msg = result and result.message or ''
    Notify.SendNotify(msgs[msg] or locale:t('notify.error'), 'error')
end

local function drawMarker(markerKey, coords)
    local mk = CFG.Markers[markerKey]
    if not mk then return end
    DrawMarker(mk.type,
        coords.x + mk.offset.x, coords.y + mk.offset.y, coords.z + mk.offset.z,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        mk.scale.x, mk.scale.y, mk.scale.z,
        mk.color.r, mk.color.g, mk.color.b, mk.color.a,
        mk.bobUpAndDown, mk.faceCamera, mk.rotationOrder, mk.rotate,
        nil, nil, false)
end

-- ── PLANTAS ───────────────────────────────────────────────────────────────────

local function spawnPlantProp(idx)
    if plantEntities[idx] and DoesEntityExist(plantEntities[idx]) then return end
    local plant = CFG.Plants[idx]
    local modelHash = GetHashKey(CFG.PlantModel)
    if not requestModel(modelHash) then return end
    local e = CreateObject(modelHash,
        plant.location.x, plant.location.y, plant.location.z,
        false, true, true)
    SetModelAsNoLongerNeeded(modelHash)
    SetEntityHeading(e, plant.heading)
    FreezeEntityPosition(e, true)
    plantEntities[idx] = e
    dbg:info('[WeedLab] Planta spawneada:', idx)
end

local function removePlantProp(idx)
    if plantEntities[idx] and DoesEntityExist(plantEntities[idx]) then
        DeleteEntity(plantEntities[idx])
    end
    plantEntities[idx] = nil
end

local function removePlantPoint(idx)
    if plantPoints[idx] then
        plantPoints[idx]:remove()
        plantPoints[idx] = nil
    end
end

local function createPlantPoint(idx)
    removePlantPoint(idx)
    local plant  = CFG.Plants[idx]
    local coords = plant.location
    -- Coords con Z a nivel del jugador para comparación de distancia correcta
    local markerOffset = CFG.Markers.plant.offset
    local interactCoords = vector3(coords.x, coords.y, coords.z + (markerOffset.z or 0.0))

    local p = lib.points.new({ coords = coords, distance = INTER.PointDistance })

    function p:nearby()
        if not ensureInWeedLab() or animRunning then return end
        if not plantEntities[idx] then return end

        local dist = #(GetEntityCoords(PlayerPedId()) - interactCoords)

        if dist < INTER.DrawDistance then
            drawMarker('plant', coords)
        end

        if dist < INTER.InteractDistance then
            local key = 'plant_' .. idx
            if currentTextUI ~= key then
                HelpText.ShowHelpText(locale:t('notify.weed_help_pick_plant'))
                currentTextUI = key
            end

            if IsControlJustReleased(0, 38) then
                HelpText.HideHelpText()
                currentTextUI = nil
                animRunning = true

                local result = lib.callback.await('origen_gang:labs:weed:pickPlant', false, idx)
                if not result or not result.success then
                    serverError(result)
                    animRunning = false
                    return
                end

                -- Animar + barra
                spawnAnim('pick_plant', coords, TIMERS.PlantPickup)
                runProgressBar('picking_plant', TIMERS.PlantPickup)

                -- Quitar prop localmente (el server ya marcó como tomada)
                removePlantProp(idx)

                animRunning = false
                Notify.SendNotify(locale:t('notify.weed_plant_picked'), 'success')
            end
        elseif currentTextUI == 'plant_' .. idx then
            HelpText.HideHelpText()
            currentTextUI = nil
        end
    end

    plantPoints[idx] = p
end

-- ── SPOTS DE SECADO ───────────────────────────────────────────────────────────

local function removeDrySlotPoint(idx)
    if drySlots[idx].point then
        drySlots[idx].point:remove()
        drySlots[idx].point = nil
    end
end

-- Limpia solo el estado del slot (prop + ready) SIN destruir el point.
-- El point sigue activo para que el slot quede inmediatamente disponible otra vez.
local function cleanupDrySlot(idx)
    if drySlots[idx].prop and DoesEntityExist(drySlots[idx].prop) then
        DeleteEntity(drySlots[idx].prop)
    end
    drySlots[idx].prop  = nil
    drySlots[idx].ready = false
end

-- Limpia todo incluyendo el point — solo para teardown completo al salir del lab.
local function teardownDrySlot(idx)
    removeDrySlotPoint(idx)
    if drySlots[idx].prop and DoesEntityExist(drySlots[idx].prop) then
        DeleteEntity(drySlots[idx].prop)
    end
    drySlots[idx].prop  = nil
    drySlots[idx].ready = false
end

local function createDrySlotPoint(idx)
    removeDrySlotPoint(idx)
    local coords = CFG.DrySpots[idx]

    local p = lib.points.new({ coords = coords, distance = INTER.PointDistance })

    function p:nearby()
        if not ensureInWeedLab() or animRunning then return end

        local slot = drySlots[idx]
        local dist = #(GetEntityCoords(PlayerPedId()) - coords)

        -- Dibujar marker según estado del slot
        if dist < INTER.DrawDistance then
            if slot.ready then
                drawMarker('dry_ready', coords)
            elseif not slot.prop then
                drawMarker('dry_spot', coords)
            end
        end

        if dist < INTER.InteractDistance then
            local key = 'dry_' .. idx

            -- Slot libre → colocar wetcannabis
            if not slot.prop and not slot.ready then
                if currentTextUI ~= key then
                    HelpText.ShowHelpText(locale:t('notify.weed_help_place_dry'))
                    currentTextUI = key
                end

                if IsControlJustReleased(0, 38) then
                    HelpText.HideHelpText()
                    currentTextUI = nil
                    animRunning = true

                    local result = lib.callback.await('origen_gang:labs:weed:placeDry', false, idx)
                    if not result or not result.success then
                        serverError(result)
                        animRunning = false
                        return
                    end

                    -- Crear prop de secado
                    local mh = GetHashKey(CFG.DryCoordsModel)
                    if requestModel(mh) then
                        slot.prop = CreateObject(mh, coords.x, coords.y + 0.2, coords.z, true, false, false)
                        SetModelAsNoLongerNeeded(mh)
                        FreezeEntityPosition(slot.prop, true)
                    end

                    animRunning = false
                    Notify.SendNotify(locale:t('notify.weed_placed_drying'), 'success')

                    -- Timer de secado: usa el tiempo efectivo devuelto por el servidor.
                    -- El servidor es la fuente de verdad (ready_at); este Wait es solo visual.
                    local dryWaitMs = (result and result.dry_wait_ms) or TIMERS.DryWait
                    CreateThread(function()
                        Wait(dryWaitMs)
                        if not slot.prop then return end  -- fue cancelado
                        slot.ready = true
                        Notify.SendNotify(locale:t('notify.weed_ready_to_pickup'), 'success')
                    end)
                end

            -- Slot listo → recoger drycannabis
            elseif slot.ready then
                if currentTextUI ~= key .. '_ready' then
                    HelpText.ShowHelpText(locale:t('notify.weed_help_pickup'))
                    currentTextUI = key .. '_ready'
                end

                if IsControlJustReleased(0, 38) then
                    HelpText.HideHelpText()
                    currentTextUI = nil
                    animRunning = true

                    local result = lib.callback.await('origen_gang:labs:weed:pickupDry', false, idx)
                    if not result or not result.success then
                        serverError(result)
                        animRunning = false
                        return
                    end

                    cleanupDrySlot(idx)
                    animRunning = false
                    Notify.SendNotify(locale:t('notify.weed_dry_done'), 'success')
                end

            -- Slot ocupado secando
            elseif slot.prop and not slot.ready then
                if currentTextUI ~= key .. '_drying' then
                    HelpText.ShowHelpText(locale:t('notify.weed_still_drying'))
                    currentTextUI = key .. '_drying'
                end
            end
        else
            local key = 'dry_' .. idx
            if currentTextUI == key or currentTextUI == key .. '_ready' or currentTextUI == key .. '_drying' then
                HelpText.HideHelpText()
                currentTextUI = nil
            end
        end
    end

    drySlots[idx].point = p
end

-- ── GRINDER ───────────────────────────────────────────────────────────────────

local function createGrinderPoint()
    if stationPoints.grinder then stationPoints.grinder:remove() end
    local coords = CFG.GrinderCoord

    local p = lib.points.new({ coords = coords, distance = INTER.PointDistance })

    function p:nearby()
        if not ensureInWeedLab() or animRunning then return end

        local dist = #(GetEntityCoords(PlayerPedId()) - coords)

        if dist < INTER.DrawDistance then
            drawMarker('grinder', coords)
        end

        if dist < INTER.InteractDistance then
            if currentTextUI ~= 'grinder' then
                HelpText.ShowHelpText(locale:t('notify.weed_help_grind'))
                currentTextUI = 'grinder'
            end

            if IsControlJustReleased(0, 38) then
                HelpText.HideHelpText()
                currentTextUI = nil
                animRunning = true

                local result = lib.callback.await('origen_gang:labs:weed:grindWeed', false)
                if not result or not result.success then
                    serverError(result)
                    animRunning = false
                    return
                end

                local grindMs = (result and result.grind_ms) or TIMERS.GrindWeed
                spawnAnim('grind_weed', coords, grindMs)
                runProgressBar('grinding', grindMs)

                animRunning = false
                Notify.SendNotify(locale:t('notify.weed_grind_done'), 'success')
            end
        elseif currentTextUI == 'grinder' then
            HelpText.HideHelpText()
            currentTextUI = nil
        end
    end

    stationPoints.grinder = p
end

-- ── EMBOLSADORA ───────────────────────────────────────────────────────────────

local function createBaggerPoint()
    if stationPoints.bagger then stationPoints.bagger:remove() end
    local coords = CFG.BaggerCoord

    local p = lib.points.new({ coords = coords, distance = INTER.PointDistance })

    function p:nearby()
        if not ensureInWeedLab() or animRunning then return end

        local dist = #(GetEntityCoords(PlayerPedId()) - coords)

        if dist < INTER.DrawDistance then
            drawMarker('bagger', coords)
        end

        if dist < INTER.InteractDistance then
            if currentTextUI ~= 'bagger' then
                HelpText.ShowHelpText(locale:t('notify.weed_help_bag'))
                currentTextUI = 'bagger'
            end

            if IsControlJustReleased(0, 38) then
                HelpText.HideHelpText()
                currentTextUI = nil
                animRunning = true

                local result = lib.callback.await('origen_gang:labs:weed:bagWeed', false)
                if not result or not result.success then
                    serverError(result)
                    animRunning = false
                    return
                end

                local bagMs = (result and result.bag_ms) or TIMERS.BagWeed
                spawnAnim('bag_weed', coords, bagMs)
                runProgressBar('bagging', bagMs)

                local amount = CFG.Recipe.bag.outputs[1] and CFG.Recipe.bag.outputs[1].amount or 0
                animRunning = false
                Notify.SendNotify(locale:t('notify.weed_bag_done', amount), 'success')
            end
        elseif currentTextUI == 'bagger' then
            HelpText.HideHelpText()
            currentTextUI = nil
        end
    end

    stationPoints.bagger = p
end

-- ── LIFECYCLE ─────────────────────────────────────────────────────────────────

local function spawnAllPlants()
    for i = 1, #CFG.Plants do
        spawnPlantProp(i)
        createPlantPoint(i)
    end
    dbg:info('[WeedLab] Plantas spawneadas:', #CFG.Plants)
end

local function createAllDrySlots()
    for i = 1, #CFG.DrySpots do
        createDrySlotPoint(i)
    end
    dbg:info('[WeedLab] Spots de secado creados:', #CFG.DrySpots)
end

-- ── Limpiar plantas del IPL ───────────────────────────────────────────────────
-- El interior de weed (247297) tiene entity sets de plantas por defecto
-- (weed_growtha_stage1/2/3 ... weed_growthg_stage1/2/3).
-- Los desactivamos para que solo queden nuestros props interactivos.
local WEED_INTERIOR_ID = 247297
local WEED_PLANT_ENTITY_SETS = {
    -- Plantas stage 1/2/3 — 9 plantas (a→i)
    'weed_growtha_stage1', 'weed_growtha_stage2', 'weed_growtha_stage3',
    'weed_growthb_stage1', 'weed_growthb_stage2', 'weed_growthb_stage3',
    'weed_growthc_stage1', 'weed_growthc_stage2', 'weed_growthc_stage3',
    'weed_growthd_stage1', 'weed_growthd_stage2', 'weed_growthd_stage3',
    'weed_growthe_stage1', 'weed_growthe_stage2', 'weed_growthe_stage3',
    'weed_growthf_stage1', 'weed_growthf_stage2', 'weed_growthf_stage3',
    'weed_growthg_stage1', 'weed_growthg_stage2', 'weed_growthg_stage3',
    'weed_growthh_stage1', 'weed_growthh_stage2', 'weed_growthh_stage3',
    'weed_growthi_stage1', 'weed_growthi_stage2', 'weed_growthi_stage3',
    -- Luces de plantas (standard + upgrade)
    'light_growtha_stage23_standard', 'light_growtha_stage23_upgrade',
    'light_growthb_stage23_standard', 'light_growthb_stage23_upgrade',
    'light_growthc_stage23_standard', 'light_growthc_stage23_upgrade',
    'light_growthd_stage23_standard', 'light_growthd_stage23_upgrade',
    'light_growthe_stage23_standard', 'light_growthe_stage23_upgrade',
    'light_growthf_stage23_standard', 'light_growthf_stage23_upgrade',
    'light_growthg_stage23_standard', 'light_growthg_stage23_upgrade',
    'light_growthh_stage23_standard', 'light_growthh_stage23_upgrade',
    'light_growthi_stage23_standard', 'light_growthi_stage23_upgrade',
    -- Mangueras
    'weed_hosea', 'weed_hoseb', 'weed_hosec', 'weed_hosed', 'weed_hosee',
    'weed_hosef', 'weed_hoseg', 'weed_hoseh', 'weed_hosei',
    -- Equipamiento y decoración que trae props de plantas/producción
    'weed_standard_equip', 'weed_upgrade_equip',
    'weed_production', 'weed_drying',
    'weed_set_up', 'weed_chairs',
    'weed_low_security', 'weed_security_upgrade',
}

local function clearIplPlants()
    for _, entitySet in ipairs(WEED_PLANT_ENTITY_SETS) do
        if IsInteriorEntitySetActive(WEED_INTERIOR_ID, entitySet) then
            DeactivateInteriorEntitySet(WEED_INTERIOR_ID, entitySet)
        end
    end
    RefreshInterior(WEED_INTERIOR_ID)
    dbg:info('[WeedLab] Entity sets de plantas del IPL desactivados')
end

local function setupAll()
    -- Primero limpiar el IPL, después spawnear nuestros props
    clearIplPlants()
    spawnAllPlants()
    createAllDrySlots()
    createGrinderPoint()
    createBaggerPoint()
    dbg:info('[WeedLab] Lab listo')
end

local function teardownAll()
    -- Plantas
    for i = 1, #CFG.Plants do
        removePlantPoint(i)
        removePlantProp(i)
    end
    -- Slots de secado — teardown completo incluyendo el point
    for i = 1, #CFG.DrySpots do
        teardownDrySlot(i)
    end
    -- Estaciones
    if stationPoints.grinder then stationPoints.grinder:remove() ; stationPoints.grinder = nil end
    if stationPoints.bagger  then stationPoints.bagger:remove()  ; stationPoints.bagger  = nil end
    -- UI
    if currentTextUI then HelpText.HideHelpText() ; currentTextUI = nil end
    animRunning = false
    dbg:info('[WeedLab] Lab limpiado')
end

-- Resincronizar plantas desde el servidor al entrar al lab
-- El servidor notifica cuáles están tomadas vía GlobalState o callback
RegisterNetEvent('origen:LabWeed:RespawnPlant', function(idx)
    spawnPlantProp(idx)
    dbg:info('[WeedLab] Planta respawneada:', idx)
end)

RegisterNetEvent('origen:LabWeed:RemovePlant', function(idx)
    removePlantProp(idx)
    dbg:info('[WeedLab] Planta removida:', idx)
end)

-- ── Eventos de entrada/salida ─────────────────────────────────────────────────

AddEventHandler('origen:LabWeed:OnEnter', function(takenPlants)
    -- takenPlants: tabla de índices que están tomados al momento de entrar
    setupAll()
    -- Remover plantas que ya estaban tomadas
    if takenPlants then
        for _, idx in ipairs(takenPlants) do
            removePlantProp(idx)
        end
    end
end)

AddEventHandler('origen:LabWeed:OnExit', function()
    teardownAll()
end)

--[[ El enganche con la puerta del laboratorio.

     Los dos manejadores de arriba esperan `origen:LabWeed:OnEnter/OnExit`, y
     eso no lo lanzaba nadie: la puerta (labs.lua) avisa con el evento comun
     `origen:Lab:OnEnter`, con el tipo de laboratorio. En el de maria no salian
     ni las plantas ni los puntos de secar, moler y embolsar. ]]
AddEventHandler('origen:Lab:OnEnter', function(tipo)
    if tipo ~= 'weed' then return end
    local tomadas = lib.callback.await('origen_gang:labs:weed:getTakenPlants', false)
    TriggerEvent('origen:LabWeed:OnEnter', type(tomadas) == 'table' and tomadas or {})
end)

AddEventHandler('origen:Lab:OnExit', function(tipo)
    if tipo ~= 'weed' then return end
    TriggerEvent('origen:LabWeed:OnExit')
end)

AddEventHandler('origen:Client:OnPlayerUnload', function()
    teardownAll()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    teardownAll()
end)
