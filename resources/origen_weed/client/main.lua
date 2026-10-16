local QBCore = exports['qb-core']:GetCoreObject()

local initialPlayerData = QBCore.Functions.GetPlayerData() or {}
local PlayerJob  = initialPlayerData.job or {}
local placingSeed = false
-- Datos del clon/semilla en curso (strain para enviar al servidor al confirmar la colocación)
local pendingPlantStrain = nil
local pendingCloneData   = nil
local wasInsidePlantZone = false
local lastPlantZoneNotifyAt = 0

-- Todas las plantas que el servidor conoce: {[dbId] = {coords=vector3, stage=n}}
-- Poblado por SyncPlants/AddPlant. NO contiene entidades, solo datos.
local KnownPlants = {}

-- Props spawneados actualmente (solo los que están dentro del streamDistance):
-- {[dbId] = entityHandle}
local LocalPlants = {}
-- La maceta de tela de cada planta (08/10): {[dbId] = entityHandle}. Se queda
-- puesta al cambiar de fase; solo la planta de encima se cambia.
local LocalPots = {}

-- Nearby plant detection state
local nearbyPlantDbId   = nil
local nearbyPlantEntity = nil
local nearbyPlantCoords = nil

local function round(value, decimals)
    if not decimals then return math.floor(value + 0.5) end
    local power = 10 ^ decimals
    return math.floor((value * power) + 0.5) / power
end

local function loadModel(model)
    if HasModelLoaded(model) then return end
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end
end

local function loadAnimDict(dict)
    if HasAnimDictLoaded(dict) then return end
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(0) end
end

local function playKneelAction(ped)
    loadAnimDict('amb@medic@standing@kneel@base')
    TaskPlayAnim(ped, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, -1, 1, 0.0, false, false, false)
end

local function stopKneelAction(ped)
    ClearPedTasks(ped)
    RemoveAnimDict('amb@medic@standing@kneel@base')
end

local function toDirection(rot)
    local rotZ = math.rad(rot.z)
    local rotX = math.rad(rot.x)
    local cosX = math.abs(math.cos(rotX))
    return vector3(-math.sin(rotZ) * cosX, math.cos(rotZ) * cosX, math.sin(rotX))
end

local function rayCastFromCamera(distance)
    local cameraRot = GetGameplayCamRot()
    local cameraPos = GetGameplayCamCoord()
    local direction = toDirection(cameraRot)
    local destination = cameraPos + (direction * distance)
    local ray = StartShapeTestRay(cameraPos.x, cameraPos.y, cameraPos.z, destination.x, destination.y, destination.z, 17, -1, 0)
    local _, hit, endPos, _, _ = GetShapeTestResult(ray)
    if hit == 0 then endPos = destination end
    return hit, endPos
end

local function isCopOnDuty()
    return PlayerJob and PlayerJob.name == Config.Weed.CopJob and PlayerJob.onduty
end

-- Para client/policia.lua (olor, cámara térmica): las plantas que se conocen
-- y si el jugador es policía de servicio
function WeedPlantasConocidas() return KnownPlants end
function WeedEsPoli() return isCopOnDuty() end

local function safeNotify(message, notifyType)
    local map = {
        primary = 'info',
        success = 'success',
        error   = 'error',
        warning = 'warning',
        info    = 'info'
    }
    exports['origen_notify']:Notify({
        description = message,
        type = map[notifyType or 'primary'] or 'info',
        duration = 3000
    })
end

--- Wrapper progressbar de origen_inventory
local function progressBar(opts, finish)
    exports['origen_inventory']:progressBar({
        name             = opts.name or 'origen_weed_action',
        duration         = opts.duration or 3000,
        label            = opts.label or '...',
        useWhileDead     = false,
        canCancel        = true,
        controlDisables  = {
            disableMovement    = opts.disableMovement    or false,
            disableCarMovement = opts.disableCarMovement or false,
            disableMouse       = opts.disableMouse       or false,
            disableCombat      = opts.disableCombat      or false,
        },
        animation = opts.animation or {}
    }, nil, nil, finish)
end

--- Controles HUD (usa el export de origen_hud para el panel de controles)
local function showControls(controls)
    if not controls or #controls == 0 then return end
    exports['origen_hud']:setupControls(controls)
end

local function hideControls()
    exports['origen_hud']:hideControls()
end

--- Elimina una entidad local de forma segura y persistente.
--- Colisión OFF es la primera operación (prioridad máxima).
local function safeDeleteEntity(entity)
    if not entity or entity == 0 then return end
    if not DoesEntityExist(entity) then return end

    -- 1. Colisión desactivada INMEDIATAMENTE (antes que cualquier otra cosa)
    SetEntityCollision(entity, false, false)
    -- 2. Ocultar visualmente
    SetEntityVisible(entity, false, false)

    -- 3. Liberar ownership y borrar en background con reintentos
    CreateThread(function()
        Wait(0)
        if not DoesEntityExist(entity) then return end
        FreezeEntityPosition(entity, false)
        SetEntityAsMissionEntity(entity, false, true)
        DeleteObject(entity)

        -- Reintentos cada 500 ms hasta que desaparezca (max 10 seg)
        local tries = 0
        while DoesEntityExist(entity) and tries < 20 do
            Wait(500)
            tries = tries + 1
            -- Mantener colisión desactivada en cada intento por si acaso
            SetEntityCollision(entity, false, false)
            SetEntityAsMissionEntity(entity, false, true)
            DeleteObject(entity)
        end
        if DoesEntityExist(entity) then
            -- Último recurso: DeleteEntity (más agresivo)
            DeleteEntity(entity)
        end
    end)
end

--- Spawn/despawn de entidades locales
local function spawnLocalPlant(dbId, coords, stage)
    -- Despawn existente si hay
    local prev = LocalPlants[dbId]
    LocalPlants[dbId] = nil
    if prev and prev ~= 0 then
        safeDeleteEntity(prev)
    end

    local model = Config.Weed.Props[stage] or Config.Weed.Props[1]
    loadModel(model)

    --[[ En cuesta la maceta flotaba por el lado de abajo (su base es plana y
         se ponía a la altura del centro). Se hunde hasta el punto más bajo del
         suelo bajo su borde (0,3 m), con un tope de 25 cm. ]]
    local z = coords.z
    for _, o in ipairs({ { 0.3, 0.0 }, { -0.3, 0.0 }, { 0.0, 0.3 }, { 0.0, -0.3 } }) do
        local ok, gz = GetGroundZExcludingObjectsFor_3dCoord(coords.x + o[1], coords.y + o[2], coords.z + 1.0, false)
        if ok and gz < z and coords.z - gz < 0.25 then z = gz end
    end

    local entity = CreateObjectNoOffset(model,
        coords.x, coords.y, z + Config.Weed.World.objectZOffset,
        false, false, false)

    if not entity or entity == 0 then
        LocalPlants[dbId] = nil
        return nil
    end

    SetEntityAsMissionEntity(entity, true, true)
    FreezeEntityPosition(entity, true)
    SetEntityCollision(entity, true, true)
    LocalPlants[dbId] = entity

    -- La maceta de tela, a la misma altura: tapa la negra de plástico del modelo
    if not (LocalPots[dbId] and DoesEntityExist(LocalPots[dbId])) and Config.Weed.Pot then
        local pot = joaat(Config.Weed.Pot.prop)
        if IsModelInCdimage(pot) then
            loadModel(pot)
            local m = CreateObjectNoOffset(pot, coords.x, coords.y, z + Config.Weed.World.objectZOffset, false, false, false)
            if m and m ~= 0 then
                SetEntityHeading(m, ((tonumber(dbId) or 0) * 137) % 360 + 0.0)   -- cada una girada a su manera
                FreezeEntityPosition(m, true)
                SetEntityAsMissionEntity(m, true, true)
                LocalPots[dbId] = m
            end
        end
    end
    return entity
end

-- `mantenerMaceta`: al cambiar de fase solo se cambia la planta
local function despawnLocalPlant(dbId, mantenerMaceta)
    local entity = LocalPlants[dbId]
    LocalPlants[dbId] = nil  -- sacar de la tabla PRIMERO (evita que el loop lo vuelva a usar)
    safeDeleteEntity(entity)
    if not mantenerMaceta then
        local pot = LocalPots[dbId]
        LocalPots[dbId] = nil
        safeDeleteEntity(pot)
    end
end

--- Buscar planta mas cercana en LocalPlants
local function tryGetClosestPlant(coords)
    local closestDbId, closestEntity, closestCoords, closestDist = nil, nil, nil, Config.Weed.World.interactDistance + 1
    for dbId, entity in pairs(LocalPlants) do
        if DoesEntityExist(entity) then
            local entCoords = GetEntityCoords(entity)
            local dist = #(coords - entCoords)
            if dist < closestDist then
                closestDist = dist
                closestDbId = dbId
                closestEntity = entity
                closestCoords = entCoords
            end
        end
    end
    return closestDbId, closestEntity, closestCoords
end

-- ─────────────────────────────────────────────────────────────────────────────
--  Reconciliación periódica: borra props locales que el servidor ya no conoce
--  Evita "fantasmas" si RemovePlant llegó tarde o DeleteObject falló antes.
-- ─────────────────────────────────────────────────────────────────────────────
CreateThread(function()
    while true do
        Wait(30000) -- cada 30 segundos
        if next(LocalPlants) == nil then goto continue end

        QBCore.Functions.TriggerCallback('origen_weed:server:GetActivePlantIds', function(activeIds)
            if not activeIds then return end
            local activeSet = {}
            for _, id in ipairs(activeIds) do activeSet[id] = true end

            -- Limpiar KnownPlants de entradas que el servidor ya no conoce
            for dbId in pairs(KnownPlants) do
                if not activeSet[dbId] then
                    KnownPlants[dbId] = nil
                    despawnLocalPlant(dbId)
                end
            end
            -- También limpiar cualquier prop spawneado sin entrada en KnownPlants
            for dbId in pairs(LocalPlants) do
                if not activeSet[dbId] then
                    despawnLocalPlant(dbId)
                end
            end
        end)

        ::continue::
    end
end)

--- Eventos de framework
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerJob = QBCore.Functions.GetPlayerData().job or {}
    TriggerServerEvent('origen_weed:server:RequestSync')
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerJob = {}
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(jobInfo)
    PlayerJob = jobInfo or {}
end)

--- Sincronizacion de plantas desde servidor
-- ─────────────────────────────────────────────────────────────────────────────
--  Sync / streaming handlers
-- ─────────────────────────────────────────────────────────────────────────────

-- Recibe la lista completa del servidor → solo guarda datos, NO spawnea nada.
-- El thread de streaming se encargará de hacer spawn según distancia.
RegisterNetEvent('origen_weed:client:SyncPlants', function(plantList)
    -- Despawnear todos los props actuales
    for dbId in pairs(LocalPlants) do
        despawnLocalPlant(dbId)
    end
    KnownPlants = {}

    for _, plant in ipairs(plantList) do
        KnownPlants[plant.id] = {
            coords = vector3(plant.coords.x, plant.coords.y, plant.coords.z),
            stage  = plant.stage or 1,
        }
    end
end)

-- Nueva planta plantada por cualquier jugador
RegisterNetEvent('origen_weed:client:AddPlant', function(plant)
    local id = plant.id
    KnownPlants[id] = {
        coords = vector3(plant.coords.x, plant.coords.y, plant.coords.z),
        stage  = plant.stage or 1,
    }
    -- Si el jugador local ya está cerca, spawnear inmediatamente
    local ped    = PlayerPedId()
    local myPos  = GetEntityCoords(ped)
    local dist   = #(myPos - KnownPlants[id].coords)
    if dist <= Config.Weed.World.streamDistance then
        CreateThread(function()
            spawnLocalPlant(id, KnownPlants[id].coords, KnownPlants[id].stage)
        end)
    end
end)

-- Planta eliminada (harvest, burn, clear, police)
RegisterNetEvent('origen_weed:client:RemovePlant', function(dbId)
    dbId = tonumber(dbId) or dbId
    KnownPlants[dbId] = nil
    despawnLocalPlant(dbId)
    if nearbyPlantDbId == dbId then
        nearbyPlantDbId   = nil
        nearbyPlantEntity = nil
        nearbyPlantCoords = nil
    end
    hideControls()
end)

-- Planta cambió de stage (crecimiento)
RegisterNetEvent('origen_weed:client:UpdatePlant', function(dbId, stage)
    dbId = tonumber(dbId) or dbId
    if KnownPlants[dbId] then
        KnownPlants[dbId].stage = stage
    end
    -- Si el prop está spawneado, reemplazarlo con el modelo del nuevo stage
    if LocalPlants[dbId] then
        local coords = KnownPlants[dbId] and KnownPlants[dbId].coords
            or (DoesEntityExist(LocalPlants[dbId]) and GetEntityCoords(LocalPlants[dbId]))
        if coords then
            CreateThread(function()
                despawnLocalPlant(dbId, true)
                spawnLocalPlant(dbId, coords, stage)
            end)
        end
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  Thread de streaming: spawn/despawn según distancia al jugador
-- ─────────────────────────────────────────────────────────────────────────────
CreateThread(function()
    while true do
        Wait(Config.Weed.World.streamCheckInterval)

        local ped    = PlayerPedId()
        local myPos  = GetEntityCoords(ped)
        local radius = Config.Weed.World.streamDistance

        for dbId, data in pairs(KnownPlants) do
            local dist = #(myPos - data.coords)
            if dist <= radius then
                -- Dentro del radio → spawn si no existe
                if not LocalPlants[dbId] then
                    spawnLocalPlant(dbId, data.coords, data.stage)
                end
            else
                -- Fuera del radio → despawn si existe
                if LocalPlants[dbId] then
                    despawnLocalPlant(dbId)
                end
            end
        end
    end
end)

--- Función interna de colocación (compartida por semilla y clon)
local function enterPlacementMode(isClone)
    local ped = PlayerPedId()
    if GetVehiclePedIsIn(ped, false) ~= 0 or placingSeed then return end

    placingSeed = true

    -- El fantasma es la maceta de tela (si está el modelo): es lo que se pone
    local seedProp = Config.Weed.Pot and joaat(Config.Weed.Pot.prop)
    if not seedProp or not IsModelInCdimage(seedProp) then seedProp = Config.Weed.Props[isClone and 2 or 1] end
    loadModel(seedProp)

    local hit, destination = rayCastFromCamera(Config.Weed.World.raycastDistance)
    local ghost = CreateObject(seedProp, destination.x, destination.y, destination.z + Config.Weed.World.objectZOffset, false, false, false)
    SetEntityCollision(ghost, false, false)
    SetEntityAlpha(ghost, 150, true)

    local controlLabel = isClone and 'Plantar esqueje' or 'Colocar'
    -- E Colocar → notify DrawText (arriba derecha)
    exports['origen_notify']:DrawText('E', controlLabel)
    -- Sin barra de «⌫ Cancelar»: que Retroceso cancela ya se sabe (08/10)

    local function cancelPlacement()
        exports['origen_notify']:HideText()
        hideControls()
        DeleteEntity(ghost)
        placingSeed = false
        pendingPlantStrain = nil
        pendingCloneData   = nil
    end

    while placingSeed do
        Wait(0)
        hit, destination = rayCastFromCamera(Config.Weed.World.raycastDistance)

        if hit == 1 then
            SetEntityCoords(ghost, destination.x, destination.y, destination.z + Config.Weed.World.objectZOffset, false, false, false, false)
        end

        if IsControlJustPressed(0, 194) then -- Backspace (retroceder): cancelar
            cancelPlacement()
            return
        end

        if IsControlJustPressed(0, 38) then -- E confirmar
            if hit ~= 1 then
                safeNotify('Apunta a una superficie valida', 'error')
                goto continue
            end
            exports['origen_notify']:HideText()
            hideControls()
            DeleteEntity(ghost)

            local placeDest = destination
            local cloneSnap = pendingCloneData
            local strainSnap = pendingPlantStrain

            progressBar({
                name            = 'origen_weed_place',
                duration        = Config.Weed.Progress.placePlant,
                label           = isClone and 'Plantando esqueje...' or 'Colocando maceta...',
                disableMovement = true,
                disableCombat   = true,
                animation = {
                    animDict = 'amb@medic@standing@kneel@base',
                    anim     = 'base',
                    flags    = 1
                }
            }, function(cancelled)
                stopKneelAction(ped)
                placingSeed = false
                pendingPlantStrain = nil
                pendingCloneData   = nil
                if cancelled then
                    safeNotify('Cancelado', 'error')
                    return
                end
                if isClone then
                    TriggerServerEvent('origen_weed:server:PlantClone', {
                        x = placeDest.x, y = placeDest.y, z = placeDest.z
                    }, cloneSnap)
                else
                    TriggerServerEvent('origen_weed:server:CreatePlant', {
                        x = placeDest.x, y = placeDest.y, z = placeDest.z
                    }, strainSnap)
                end
            end)

            playKneelAction(ped)
            return
        end
        ::continue::
    end
end

--- Colocar semilla hembra (recibe cepa de la metadata del item)
RegisterNetEvent('origen_weed:client:UseFemaleSeed', function(strainKey)
    pendingPlantStrain = strainKey or Config.Weed.DefaultStrain
    pendingCloneData   = nil
    enterPlacementMode(false)
end)

--- Plantar esqueje/clon
RegisterNetEvent('origen_weed:client:UseClone', function(cloneData)
    pendingCloneData   = cloneData
    pendingPlantStrain = nil
    enterPlacementMode(true)
end)

exports('UseFemaleSeedItem', function()
    TriggerEvent('origen_weed:client:UseFemaleSeed', Config.Weed.DefaultStrain)
end)

--- Callback de planta cercana → abre NUI
RegisterNetEvent('origen_weed:client:CheckPlant', function(dbId)
    QBCore.Functions.TriggerCallback('origen_weed:server:GetPlantData', function(result)
        if not result then
            safeNotify('No hay datos de esta planta', 'error')
            return
        end
        -- Verificar que el jugador sigue cerca (evita abrir el menú si se alejó)
        if nearbyPlantDbId ~= dbId then return end

        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'openPlantMenu',
            data   = {
                dbId         = dbId,
                stage        = result.stage,
                health       = result.health,
                water        = result.water,
                fertilizer   = result.fertilizer,
                growth       = result.growth,
                gender       = result.gender,
                strain       = result.strain,
                strainLabel  = result.strainLabel,
                genetics     = result.genetics,
                geneticsTier = result.geneticsTier,
                tierRarity   = result.tierRarity,
                tierBranches = result.tierBranches,
                strainMaxGen = result.strainMaxGen,
                canClone     = result.canClone,
                isCop        = isCopOnDuty(),
                -- Plaga y mutación: el servidor las mandaba pero no se pasaban,
                -- y en el menú nunca salía la plaga ni el botón de curar (07/10)
                pest          = result.pest,
                pestLabel     = result.pestLabel,
                mutation      = result.mutation,
                mutationLabel = result.mutationLabel,
                mutationBadge = result.mutationBadge,
                -- La ficha completa (08/10): cuenta atrás, previsión, diario...
                ficha         = result.ficha,
            }
        })
    end, dbId)
end)

--[[ Si el vigilante suelta el raton a la fuerza (`soltarraton`, o la pagina
     sin nada delante), todas las pantallas fuera: planta, regadera, tendal,
     mesa y el minijuego. Lo de cada menu (tendal, mesa) lo recoge su fichero. ]]
OrigenFoco.AlSoltar(function()
    SendNUIMessage({ action = 'closeAll' })
end)

--- Callbacks NUI → Lua
RegisterNUICallback('closeMenu', function(_, cb)
    SetNuiFocus(false, false)
    cb({})
end)

RegisterNUICallback('weedAction', function(data, cb)
    SetNuiFocus(false, false)
    cb({})

    local action = data.action
    local dbId   = tonumber(data.dbId) or nearbyPlantDbId

    local routes = {
        clear          = 'origen_weed:client:ClearPlant',
        harvest        = 'origen_weed:client:HarvestPlant',
        water          = 'origen_weed:client:GiveWater',
        fertilizer     = 'origen_weed:client:GiveFertilizer',
        male_seed      = 'origen_weed:client:AddMaleSeed',
        clone          = 'origen_weed:client:ClonePlant',
        burn           = 'origen_weed:client:BurnPlant',
        cure           = 'origen_weed:client:CurePlant',
        police_destroy = 'origen_weed:client:PoliceDestroy',
        sample         = 'origen_weed:client:TomarMuestra',
        fill_water     = 'origen_weed:client:FillWater',
    }

    local ev = routes[action]
    if not ev then return end

    if action == 'fill_water' then
        TriggerEvent(ev)
        return
    end

    if not dbId then
        safeNotify('No se pudo identificar la planta. Acércate y prueba de nuevo.', 'error')
        return
    end

    local bonus = tonumber(data.bonus) or 1.0
    TriggerEvent(ev, dbId, bonus)
end)

-- Comprueba si el jugador tiene el item necesario antes de abrir el minijuego
RegisterNUICallback('checkMinigame', function(data, cb)
    local action = data.action
    local items  = Config.Weed.Items

    local required = {
        water      = items.fullCan,
        fertilizer = items.fertilizer,
        male_seed  = items.maleSeed,
    }

    local itemName = required[action]
    if not itemName then
        cb({ ok = true })
        return
    end

    local hasItem = QBCore.Functions.HasItem(itemName)
    if hasItem then
        cb({ ok = true })
    else
        local labels = {
            water      = 'Necesitas una regadera llena',
            fertilizer = 'No tienes fertilizante',
            male_seed  = 'No tienes semillas masculinas',
        }
        local msg = labels[action] or 'No tienes el item necesario'
        cb({ ok = false, message = msg })
        safeNotify(msg, 'error')
    end
end)

-- Callback exclusivo del minijuego: ejecuta la acción sin cerrar el NUI
RegisterNUICallback('minigameAction', function(data, cb)
    cb({})

    local action = data.action
    local dbId   = tonumber(data.dbId) or nearbyPlantDbId
    local bonus  = tonumber(data.bonus) or 1.0

    if not dbId then return end

    -- Notificación visual según resultado del minijuego
    local actionNames = {
        water      = 'Riego',
        fertilizer = 'Fertilización',
        male_seed  = 'Polinización',
        clone      = 'Esqueje',
    }
    local actionLabel = actionNames[action] or 'Acción'

    local isClone = action == 'clone'
    if bonus >= 2.0 then
        exports['origen_notify']:Notify({
            title       = '¡Perfecto!',
            description = isClone and 'Corte limpio · genética al 100%' or (actionLabel .. ' perfecta · genética ×2'),
            type        = 'success',
            duration    = 4000,
        })
    elseif bonus >= 1.3 then
        exports['origen_notify']:Notify({
            title       = 'Bien hecho',
            description = isClone and 'Buen corte · genética al 85%' or (actionLabel .. ' correcta · genética ×1.3'),
            type        = 'primary',
            duration    = 3500,
        })
    else
        exports['origen_notify']:Notify({
            title       = 'Fallaste',
            description = isClone and 'Corte malo · genética al 60%' or (actionLabel .. ' con poco efecto · genética ×0.5'),
            type        = 'error',
            duration    = 3500,
        })
    end

    local ped      = PlayerPedId()
    local myCoords = GetEntityCoords(ped)
    local coords   = { x = myCoords.x, y = myCoords.y, z = myCoords.z }

    local serverRoutes = {
        water      = 'origen_weed:server:GiveWater',
        fertilizer = 'origen_weed:server:GiveFertilizer',
        male_seed  = 'origen_weed:server:AddMaleSeed',
        clone      = 'origen_weed:server:ClonePlant',
    }

    local ev = serverRoutes[action]
    if not ev then return end

    playKneelAction(ped)
    Wait(800)
    stopKneelAction(ped)

    TriggerServerEvent(ev, dbId, coords, bonus)
end)

--- Accion generica con progressbar + kneel
local function doPlantAction(dbId, key, label, duration, serverEvent, bonus)
    dbId = tonumber(dbId) or dbId
    if not dbId then
        safeNotify('Error: planta no válida', 'error')
        return
    end

    local entity = LocalPlants[dbId]
    local ped = PlayerPedId()

    if entity and DoesEntityExist(entity) then
        TaskTurnPedToFaceEntity(ped, entity, 1.0)
        Wait(1000)
    end

    playKneelAction(ped)

    progressBar({
        name               = key,
        duration           = duration,
        label              = label,
        disableMovement    = true,
        disableCarMovement = true,
        disableCombat      = true,
        animation = {
            animDict = 'amb@medic@standing@kneel@base',
            anim     = 'base',
            flags    = 1
        }
    }, function(cancelled)
        stopKneelAction(ped)
        if cancelled then
            safeNotify('Cancelado', 'error')
            return
        end
        local myCoords = GetEntityCoords(ped)
        local bonusMult = bonus or 1.0
        TriggerServerEvent(serverEvent, dbId, { x = myCoords.x, y = myCoords.y, z = myCoords.z }, bonusMult)
    end)
end

RegisterNetEvent('origen_weed:client:ClearPlant', function(dbId)
    doPlantAction(dbId, 'origen_weed_clear', 'Limpiando planta...', Config.Weed.Progress.clearDead, 'origen_weed:server:ClearPlant')
end)

RegisterNetEvent('origen_weed:client:HarvestPlant', function(dbId)
    doPlantAction(dbId, 'origen_weed_harvest', 'Cosechando planta...', Config.Weed.Progress.harvest, 'origen_weed:server:HarvestPlant')
end)

RegisterNetEvent('origen_weed:client:ClonePlant', function(dbId)
    doPlantAction(dbId, 'origen_weed_clone', 'Tomando esqueje...', Config.Weed.Progress.addMaleSeed, 'origen_weed:server:ClonePlant')
end)

RegisterNetEvent('origen_weed:client:PoliceDestroy', function(dbId)
    local entity = LocalPlants[dbId]
    local ped = PlayerPedId()
    if entity and DoesEntityExist(entity) then
        TaskTurnPedToFaceEntity(ped, entity, 1.0)
        Wait(500)
    end
    ClearPedTasks(ped)
    TriggerServerEvent('origen_weed:server:PoliceDestroy', dbId)
end)

-- Tomar una muestra para el MDT (policía): agachado un momento
RegisterNetEvent('origen_weed:client:TomarMuestra', function(dbId)
    local ped = PlayerPedId()
    progressBar({
        name = 'origen_weed_muestra', duration = 3500, label = 'Tomando una muestra...',
        disableMovement = true, disableCombat = true,
        animation = { animDict = 'amb@medic@standing@kneel@base', anim = 'base', flags = 1 },
    }, function(cancelled)
        stopKneelAction(ped)
        if not cancelled then TriggerServerEvent('origen_weed:server:TomarMuestra', dbId) end
    end)
end)

RegisterNetEvent('origen_weed:client:BurnPlant', function(dbId)
    doPlantAction(dbId, 'origen_weed_burn', 'Quemando planta...', Config.Weed.Progress.burn, 'origen_weed:server:BurnPlant')
end)

RegisterNetEvent('origen_weed:client:CurePlant', function(dbId)
    doPlantAction(dbId, 'origen_weed_cure', 'Tratando la planta...', Config.Weed.Progress.cure, 'origen_weed:server:CurePlant')
end)

RegisterNetEvent('origen_weed:client:FireFx', function(coords)
    local ped = PlayerPedId()
    local fireCoords = vector3(coords.x, coords.y, coords.z)
    if #(GetEntityCoords(ped) - fireCoords) > 300.0 then return end

    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('core') do Wait(0) end

    SetPtfxAssetNextCall('core')
    local effect = StartParticleFxLoopedAtCoord('ent_ray_paleto_gas_flames', fireCoords.x, fireCoords.y, fireCoords.z + 0.5, 0.0, 0.0, 0.0, 0.6, false, false, false, false)
    Wait(Config.Weed.World.fireTimeMs)
    StopParticleFxLooped(effect, 0)
end)

--- Regar planta
RegisterNetEvent('origen_weed:client:GiveWater', function(dbId, bonus)
    if not QBCore.Functions.HasItem(Config.Weed.Items.fullCan, 1) then
        safeNotify('Necesitas una regadera llena', 'error')
        return
    end

    local entity = LocalPlants[dbId]
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    -- La regadera propia (08/10); si no está el modelo, la del juego como antes
    local hp    = Config.Weed.HandProps and Config.Weed.HandProps.water
    local model = hp and joaat(hp.model)
    if not model or not IsModelInCdimage(model) then hp, model = nil, `prop_wateringcan` end

    if entity and DoesEntityExist(entity) then
        TaskTurnPedToFaceEntity(ped, entity, 1.0)
        Wait(1000)
    end

    loadModel(model)
    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('core') do Wait(0) end

    local obj = CreateObject(model, coords.x, coords.y, coords.z, true, true, true)
    local effect
    if hp then
        AttachEntityToEntity(obj, ped, GetPedBoneIndex(ped, hp.bone), hp.pos.x, hp.pos.y, hp.pos.z, hp.rot.x, hp.rot.y, hp.rot.z, true, true, false, true, 1, true)
        SetPtfxAssetNextCall('core')
        effect = StartParticleFxLoopedOnEntity('ent_sht_water', obj, hp.ptfx.x, hp.ptfx.y, hp.ptfx.z, 0.0, 0.0, 0.0, 2.0, false, false, false)
    else
        AttachEntityToEntity(obj, ped, GetPedBoneIndex(ped, 28422), 0.4, 0.1, 0.0, 90.0, 180.0, 0.0, true, true, false, true, 1, true)
        SetPtfxAssetNextCall('core')
        effect = StartParticleFxLoopedOnEntity('ent_sht_water', obj, 0.35, 0.0, 0.25, 0.0, 0.0, 0.0, 2.0, false, false, false)
    end

    progressBar({
        name               = 'origen_weed_water',
        duration           = Config.Weed.Progress.water,
        label              = 'Regando...',
        disableMovement    = true,
        disableCarMovement = true,
        disableCombat      = true,
        animation = {
            animDict = 'weapon@w_sp_jerrycan',
            anim     = 'fire',
            flags    = 1
        }
    }, function(cancelled)
        ClearPedTasks(ped)
        DeleteEntity(obj)
        StopParticleFxLooped(effect, 0)
        if cancelled then
            safeNotify('Cancelado', 'error')
            return
        end
        local myCoords = GetEntityCoords(ped)
        TriggerServerEvent('origen_weed:server:GiveWater', dbId, { x = myCoords.x, y = myCoords.y, z = myCoords.z }, bonus or 1.0)
    end)
end)

--- Menu llenar regadera → NUI
RegisterNetEvent('origen_weed:client:OpenFillWaterMenu', function()
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'openFillWaterMenu' })
end)

exports('UseEmptyCanItem', function()
    TriggerEvent('origen_weed:client:OpenFillWaterMenu')
end)

RegisterNetEvent('origen_weed:client:FillWater', function()
    if not QBCore.Functions.HasItem(Config.Weed.Items.waterSource, 1) then
        safeNotify('Te falta agua para llenar la regadera', 'error')
        return
    end

    progressBar({
        name               = 'origen_weed_fill_can',
        duration           = Config.Weed.Progress.fillCan,
        label              = 'Llenando regadera...',
        disableMovement    = true,
        disableCarMovement = true,
        disableCombat      = true
    }, function(cancelled)
        if cancelled then
            safeNotify('Cancelado', 'error')
            return
        end
        TriggerServerEvent('origen_weed:server:FillWaterCan')
    end)
end)

--- Fertilizar
RegisterNetEvent('origen_weed:client:GiveFertilizer', function(dbId, bonus)
    if not QBCore.Functions.HasItem(Config.Weed.Items.fertilizer, 1) then
        safeNotify('No tienes fertilizante', 'error')
        return
    end

    local entity = LocalPlants[dbId]
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    -- La garrafa de abono propia (08/10); antes era un bidón de gasolina
    local hp    = Config.Weed.HandProps and Config.Weed.HandProps.fertilizer
    local model = hp and joaat(hp.model)
    if not model or not IsModelInCdimage(model) then hp, model = nil, `w_am_jerrycan_sf` end

    if entity and DoesEntityExist(entity) then
        TaskTurnPedToFaceEntity(ped, entity, 1.0)
        Wait(1000)
    end

    loadModel(model)
    local obj = CreateObject(model, coords.x, coords.y, coords.z, true, true, true)
    if hp then
        AttachEntityToEntity(obj, ped, GetPedBoneIndex(ped, hp.bone), hp.pos.x, hp.pos.y, hp.pos.z, hp.rot.x, hp.rot.y, hp.rot.z, true, true, false, true, 1, true)
    else
        AttachEntityToEntity(obj, ped, GetPedBoneIndex(ped, 28422), 0.3, 0.1, 0.0, 90.0, 180.0, 0.0, true, true, false, true, 1, true)
    end

    progressBar({
        name               = 'origen_weed_fertilizer',
        duration           = Config.Weed.Progress.fertilizer,
        label              = 'Fertilizando...',
        disableMovement    = true,
        disableCarMovement = true,
        disableCombat      = true,
        animation = {
            animDict = 'weapon@w_sp_jerrycan',
            anim     = 'fire',
            flags    = 1
        }
    }, function(cancelled)
        ClearPedTasks(ped)
        DeleteEntity(obj)
        if cancelled then
            safeNotify('Cancelado', 'error')
            return
        end
        local myCoords = GetEntityCoords(ped)
        TriggerServerEvent('origen_weed:server:GiveFertilizer', dbId, { x = myCoords.x, y = myCoords.y, z = myCoords.z }, bonus or 1.0)
    end)
end)

--- Semilla macho
RegisterNetEvent('origen_weed:client:AddMaleSeed', function(dbId, bonus)
    if not QBCore.Functions.HasItem(Config.Weed.Items.maleSeed, 1) then
        safeNotify('No tienes semillas masculinas', 'error')
        return
    end
    doPlantAction(dbId, 'origen_weed_add_male_seed', 'Añadiendo...', Config.Weed.Progress.addMaleSeed, 'origen_weed:server:AddMaleSeed', bonus or 1.0)
end)

--- Loop de deteccion de planta cercana
local interactControlsVisible = false

CreateThread(function()
    -- Request sync when resource starts (for players already in-game)
    Wait(2000)
    TriggerServerEvent('origen_weed:server:RequestSync')
end)

-- Aviso al entrar en zona de plantación
CreateThread(function()
    while true do
        local sleep = 2000
        local zones = (Config.Weed.Planting and Config.Weed.Planting.validZones) or {}

        if #zones > 0 then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local isInside = false

            for _, zone in ipairs(zones) do
                if #(coords - zone.coords) <= zone.radius then
                    isInside = true
                    break
                end
            end

            if isInside and not wasInsidePlantZone then
                local now = GetGameTimer()
                if (now - lastPlantZoneNotifyAt) > 15000 then
                    exports['origen_notify']:Notify({
                        description = 'Parece que por aqui huele a maria! Cuidado puede ser que haya gente peligrosa plantando!',
                        type = 'warning',
                        duration = 7000
                    })
                    lastPlantZoneNotifyAt = now
                end
            end

            wasInsidePlantZone = isInside
            sleep = isInside and 1200 or 2000
        else
            wasInsidePlantZone = false
        end

        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        local sleep = 1000

        if not placingSeed then
            local ped    = PlayerPedId()
            local coords = GetEntityCoords(ped)

            if not nearbyPlantDbId then
                nearbyPlantDbId, nearbyPlantEntity, nearbyPlantCoords = tryGetClosestPlant(coords)
            end

            if nearbyPlantDbId and nearbyPlantEntity and DoesEntityExist(nearbyPlantEntity) then
                local distance = #(coords - nearbyPlantCoords)
                if distance <= Config.Weed.World.interactDistance then
                    sleep = 0
                    if not interactControlsVisible then
                        interactControlsVisible = true
                        exports['origen_notify']:DrawText('E', 'Verificar planta')
                    end
                    if IsControlJustPressed(0, 38) then
                        TriggerEvent('origen_weed:client:CheckPlant', nearbyPlantDbId)
                    end
                else
                    if interactControlsVisible then
                        interactControlsVisible = false
                        exports['origen_notify']:HideText()
                    end
                    nearbyPlantDbId   = nil
                    nearbyPlantEntity = nil
                    nearbyPlantCoords = nil
                end
            else
                if interactControlsVisible then
                    interactControlsVisible = false
                    hideControls()
                end
                nearbyPlantDbId   = nil
                nearbyPlantEntity = nil
                nearbyPlantCoords = nil
            end
        end

        Wait(sleep)
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  DEBUG: Visualización de zonas válidas de plantación
--  Solo activo cuando Config.Weed.Debug = true
-- ─────────────────────────────────────────────────────────────────────────────
if Config.Weed.Debug then
    local CIRCLE_STEPS   = 80       -- segmentos del perímetro
    local RENDER_DIST    = 1200.0   -- distancia máxima de renderizado

    -- Dibuja texto 3D en el mundo
    local function drawText3D(x, y, z, text, r, g, b)
        local onScreen, sx, sy = World3dToScreen2d(x, y, z)
        if not onScreen then return end
        local camCoords = GetGameplayCamCoord()
        local dist = #(vector3(x, y, z) - camCoords)
        local scale = (1 / dist) * 2.0
        scale = math.min(math.max(scale, 0.2), 0.8)
        SetTextScale(scale, scale)
        SetTextFont(4)
        SetTextProportional(true)
        SetTextColour(r or 255, g or 255, b or 255, 230)
        SetTextOutline()
        SetTextEntry('STRING')
        AddTextComponentString(text)
        DrawText(sx, sy)
    end

    -- Dibuja el perímetro de una zona circular en el suelo
    local function drawZoneCircle(zone, inside)
        local cx, cy, cz = zone.coords.x, zone.coords.y, zone.coords.z
        local r          = zone.radius

        -- Color: verde (dentro) o naranja (fuera)
        local lr, lg, lb, la = inside and 30 or 255, inside and 200 or 140, inside and 30 or 0, 220

        -- Perímetro
        for s = 0, CIRCLE_STEPS - 1 do
            local a1 = (s       / CIRCLE_STEPS) * math.pi * 2
            local a2 = ((s + 1) / CIRCLE_STEPS) * math.pi * 2
            DrawLine(
                cx + math.cos(a1) * r, cy + math.sin(a1) * r, cz,
                cx + math.cos(a2) * r, cy + math.sin(a2) * r, cz,
                lr, lg, lb, la
            )
        end

        -- Cruz central
        DrawLine(cx - 4.0, cy, cz, cx + 4.0, cy, cz, lr, lg, lb, la)
        DrawLine(cx, cy - 4.0, cz, cx, cy + 4.0, cz, lr, lg, lb, la)

        -- Pilón vertical en el centro (linea al cielo)
        DrawLine(cx, cy, cz, cx, cy, cz + 60.0, lr, lg, lb, 150)

        -- Marker de suelo en el centro
        DrawMarker(
            25,                                  -- tipo: círculo plano
            cx, cy, cz - 0.1,                   -- posición
            0.0, 0.0, 0.0,                       -- dirección
            0.0, 0.0, 0.0,                       -- rotación
            4.0, 4.0, 0.5,                       -- escala (pequeño para el centro)
            lr, lg, lb, 120,                     -- color
            false, false, 2, false, nil, nil, false
        )
    end

    CreateThread(function()
        while true do
            local sleep      = 500
            local zones      = Config.Weed.Planting.validZones or {}
            local ped        = PlayerPedId()
            local plyCoords  = GetEntityCoords(ped)
            local camCoords  = GetGameplayCamCoord()

            for i, zone in ipairs(zones) do
                local distToZone = #(plyCoords - zone.coords)

                if distToZone < RENDER_DIST then
                    sleep = 0  -- sube el tick cuando hay algo que dibujar

                    local inside = distToZone <= zone.radius
                    drawZoneCircle(zone, inside)

                    -- Etiqueta central (solo si la cámara está relativamente cerca)
                    local camDist = #(camCoords - zone.coords)
                    if camDist < RENDER_DIST then
                        local statusTxt = inside and '✓ Puedes plantar' or '✗ Fuera de zona'
                        local enforceTxt = Config.Weed.Planting.enforceValidZones and '' or ' [SIN RESTRICCION]'
                        drawText3D(
                            zone.coords.x, zone.coords.y, zone.coords.z + 4.0,
                            ('[ZONA %d] %s  Radio: %dm%s%s'):format(
                                i,
                                zone.label or ('Zona ' .. i),
                                math.floor(zone.radius),
                                enforceTxt,
                                '\n' .. statusTxt
                            ),
                            inside and 100 or 255,
                            inside and 220 or 180,
                            inside and 100 or 0
                        )
                    end
                end
            end

            Wait(sleep)
        end
    end)
end

--[[ Al parar el recurso (restart) se borra todo lo puesto AQUI MISMO, sin
     hilos: el borrado normal va en un CreateThread que ya no llega a correr
     con el recurso parandose, y quedaban macetas fantasma en el suelo, sin
     dueño, encima de las nuevas (visto el 07/10). ]]
AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    local function fuera(e)
        if e and e ~= 0 and DoesEntityExist(e) then
            SetEntityAsMissionEntity(e, true, true)
            DeleteObject(e)
            if DoesEntityExist(e) then DeleteEntity(e) end
        end
    end
    for _, e in pairs(LocalPlants) do fuera(e) end
    for _, e in pairs(LocalPots) do fuera(e) end
    LocalPlants, LocalPots = {}, {}
end)
