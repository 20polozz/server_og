-- ─────────────────────────────────────────────────────────────────────────────
--  origen_weed · Mesa de Procesado — Cliente
-- ─────────────────────────────────────────────────────────────────────────────
local QBCore = exports['qb-core']:GetCoreObject()

local KnownTables   = {}   -- [id] = { id, coords, heading }
local LocalTables   = {}   -- [id] = { entity, chair }

local nearbyTableId     = nil
local nearbyTableCoords = nil
local lastTableHint     = ''
local placingTable      = false
local seatedAtTable     = nil   -- tableId actual si está sentado
local seatedChairEnt    = nil   -- entity de la silla spawneada
local isProcessing      = false -- true mientras el servidor procesa (para cancelar al salir)

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function tableIsInValidZone()
    local rules = Config.Weed.Planting
    if not rules or not rules.enforceValidZones then return true end
    local pos = GetEntityCoords(PlayerPedId())
    for _, zone in ipairs(rules.validZones or {}) do
        if #(pos - zone.coords) <= zone.radius then return true end
    end
    return false
end

-- Con tope (como el del tendal): sin el, un modelo que falte colgaba el hilo.
local function loadTableModel(model)
    if HasModelLoaded(model) then return true end
    if not IsModelInCdimage(model) then return false end
    RequestModel(model)
    local hasta = GetGameTimer() + 10000
    while not HasModelLoaded(model) do
        if GetGameTimer() > hasta then return false end
        Wait(0)
    end
    return true
end

local function tableSafeDelete(entity)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return end
    SetEntityCollision(entity, false, false)
    SetEntityVisible(entity, false, false)
    CreateThread(function()
        Wait(0)
        if not DoesEntityExist(entity) then return end
        SetEntityAsMissionEntity(entity, false, true)
        DeleteObject(entity)
        local tries = 0
        while DoesEntityExist(entity) and tries < 20 do
            Wait(500); tries = tries + 1
            DeleteObject(entity)
        end
        if DoesEntityExist(entity) then DeleteEntity(entity) end
    end)
end

-- ── Spawn / Despawn ───────────────────────────────────────────────────────────
local function spawnTableProp(id, coords, heading)
    if LocalTables[id] then return end
    local cfg   = Config.Weed.Table
    local model = GetHashKey(cfg.prop)
    if not loadTableModel(model) then return end
    local ent = CreateObjectNoOffset(model, coords.x, coords.y, coords.z, false, false, false)
    if not ent or ent == 0 then return end
    SetEntityHeading(ent, heading)
    FreezeEntityPosition(ent, true)
    SetEntityAsMissionEntity(ent, true, true)
    LocalTables[id] = { entity = ent, chair = nil, decor = {} }

    -- Lo de encima de la mesa (08/10): cogollos, tijeras, báscula, bolsitas
    for _, d in ipairs(cfg.decor or {}) do
        local h = joaat(d.model)
        if loadTableModel(h) then
            local p = GetOffsetFromEntityInWorldCoords(ent, d.pos.x, d.pos.y, d.pos.z)
            local o = CreateObjectNoOffset(h, p.x, p.y, p.z, false, false, false)
            if o and o ~= 0 then
                SetEntityHeading(o, (heading + (d.rot or 0.0)) % 360.0)
                SetEntityCollision(o, false, false)
                FreezeEntityPosition(o, true)
                SetEntityAsMissionEntity(o, true, true)
                table.insert(LocalTables[id].decor, o)
            end
        end
    end
end

local function despawnTableProp(id)
    local data = LocalTables[id]
    if not data then return end
    LocalTables[id] = nil
    if data.chair then tableSafeDelete(data.chair) end
    for _, o in ipairs(data.decor or {}) do tableSafeDelete(o) end
    tableSafeDelete(data.entity)
end

-- ── Streaming ─────────────────────────────────────────────────────────────────
CreateThread(function()
    while true do
        Wait(Config.Weed.Table.streamCheckInterval)
        local ped      = PlayerPedId()
        local myPos    = GetEntityCoords(ped)
        local maxDist  = Config.Weed.Table.streamDistance

        for id, t in pairs(KnownTables) do
            if #(myPos - t.coords) <= maxDist then
                if not LocalTables[id] then
                    spawnTableProp(id, t.coords, t.heading)
                end
            else
                if LocalTables[id] then despawnTableProp(id) end
            end
        end
    end
end)

-- ── Nearby detection ─────────────────────────────────────────────────────────
CreateThread(function()
    while true do
        Wait(500)
        local ped       = PlayerPedId()
        local myPos     = GetEntityCoords(ped)
        local maxDist   = Config.Weed.Table.interactDistance

        nearbyTableId     = nil
        nearbyTableCoords = nil

        for id, data in pairs(LocalTables) do
            if DoesEntityExist(data.entity) then
                local entPos = GetEntityCoords(data.entity)
                if #(myPos - entPos) <= maxDist then
                    nearbyTableId     = id
                    nearbyTableCoords = entPos
                    break
                end
            end
        end

        if nearbyTableId then
            if lastTableHint ~= 'table' then
                lastTableHint = 'table'
                exports['origen_notify']:DrawText('E', 'Usar mesa de procesado')
            end
        else
            if lastTableHint == 'table' then
                lastTableHint = ''
                exports['origen_notify']:HideText()
                -- Si el jugador se aleja de la mesa, levantarlo
                if seatedAtTable and seatedAtTable == nearbyTableId then
                    -- nearbyTableId ya es nil aquí, no levantamos automáticamente
                end
            end
        end
    end
end)

-- ── Helper: calcula la posición y heading del scenario para sentarse ──────────
-- Devuelve: scenarioPos (vector3), scenarioHead (float)
local function calcTableSeatPos(tableEnt, cfg)
    cfg = cfg or Config.Weed.Table
    local tablePos  = GetEntityCoords(tableEnt)
    local tableHead = GetEntityHeading(tableEnt)

    -- 1. Posición de la silla (local space de la mesa)
    local rad = math.rad(tableHead)
    local co  = cfg.chairOffset or { x = 0.0, y = -0.85, z = 0.0 }
    local seatPos = vector3(
        tablePos.x + (co.x * math.cos(rad) - co.y * math.sin(rad)),
        tablePos.y + (co.x * math.sin(rad) + co.y * math.cos(rad)),
        tablePos.z + (co.z or 0.0)
    )
    local seatHead = (tableHead + (cfg.chairRotOffset or 0.0)) % 360.0

    -- 2. Offset adicional del PJ dentro de la silla (local space de la silla)
    local po = cfg.pedOffset or { x = 0.0, y = 0.0, z = 0.0 }
    local chairRad = math.rad(seatHead)
    local scenarioPos = vector3(
        seatPos.x + (po.x * math.cos(chairRad) - po.y * math.sin(chairRad)),
        seatPos.y + (po.x * math.sin(chairRad) + po.y * math.cos(chairRad)),
        seatPos.z + (po.z or 0.0)
    )
    local scenarioHead = (seatHead + (cfg.pedRotOffset or 0.0)) % 360.0
    return seatPos, seatHead, scenarioPos, scenarioHead
end

-- ── Sentarse y abrir NUI ──────────────────────────────────────────────────────
local function unseatPlayer()
    if seatedChairEnt then
        tableSafeDelete(seatedChairEnt)
        seatedChairEnt = nil
    end
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    seatedAtTable = nil
    exports['origen_notify']:HideText()
end

local function openTableNUI(tableId)
    local ped    = PlayerPedId()
    local coords = GetEntityCoords(ped)
    QBCore.Functions.TriggerCallback('origen_weed:server:GetTableData', function(data)
        -- La respuesta llega tarde: si mientras tanto se levanto (cerro el
        -- menu, la mesa se quito), abrirlo ahora cogia el raton sin mesa.
        if seatedAtTable ~= tableId then return end
        if not data then
            exports['origen_notify']:Notify({ description = 'No se pudo obtener datos de la mesa', type = 'error', duration = 3000 })
            unseatPlayer()
            return
        end
        -- Añadir hora GTA para ajustes
        data.gtaHour = GetClockHours()
        SendNUIMessage({ action = 'openTableMenu', data = data })
        SetNuiFocus(true, true)
    end, tableId, { x = coords.x, y = coords.y, z = coords.z })
end

local function seatAndOpenTable(tableId)
    if seatedAtTable == tableId then return end

    local cfg     = Config.Weed.Table
    local tableData = LocalTables[tableId]
    if not tableData or not DoesEntityExist(tableData.entity) then return end

    local tableEnt  = tableData.entity
    local seatPos, seatHead, scenarioPos, scenarioHead = calcTableSeatPos(tableEnt, cfg)

    -- Spawn silla
    local chairModel = GetHashKey(cfg.chairProp)
    loadTableModel(chairModel)
    local chair = CreateObjectNoOffset(chairModel, seatPos.x, seatPos.y, seatPos.z, false, false, false)
    SetEntityHeading(chair, seatHead)
    SetEntityAsMissionEntity(chair, true, true)
    SetEntityCollision(chair, false, false)
    tableData.chair = chair
    seatedChairEnt  = chair

    seatedAtTable = tableId

    -- Sentar jugador con escenario GTA V
    local ped = PlayerPedId()
    TaskStartScenarioAtPosition(ped, 'PROP_HUMAN_SEAT_CHAIR_MP_PLAYER',
        scenarioPos.x, scenarioPos.y, scenarioPos.z, scenarioHead, -1, true, true)

    Wait(800)
    exports['origen_notify']:HideText()
    openTableNUI(tableId)
end

-- ── E key ─────────────────────────────────────────────────────────────────────
CreateThread(function()
    while true do
        -- Por fotograma solo con una mesa cerca (nearbyTableId se refresca cada 500 ms)
        Wait(nearbyTableId and 0 or 500)
        if nearbyTableId and not placingTable and not seatedAtTable
            and IsControlJustPressed(0, 38) then
            seatAndOpenTable(nearbyTableId)
        end
    end
end)

-- ── NUI Callbacks ─────────────────────────────────────────────────────────────
RegisterNUICallback('closeTableMenu', function(_, cb)
    SetNuiFocus(false, false)
    cb({})
    -- Si cierra el menú con un proceso en marcha, cancelar y recuperar items
    if isProcessing then
        TriggerServerEvent('origen_weed:server:CancelProcessing')
        isProcessing = false
    end
    unseatPlayer()
end)

--[[ Si el vigilante suelta el raton a la fuerza con el menu de la mesa
     abierto: como cerrarlo a mano. Un procesado en marcha se cancela (el
     servidor devuelve los items) y el jugador se levanta de la silla. La
     pantalla la cierra el AlSoltar de main.lua ('closeAll'). ]]
OrigenFoco.AlSoltar(function()
    if isProcessing then
        TriggerServerEvent('origen_weed:server:CancelProcessing')
        isProcessing = false
    end
    if seatedAtTable then unseatPlayer() end
end)

RegisterNUICallback('tableAction', function(data, cb)
    cb({})
    local action  = data.action
    local tableId = tonumber(data.tableId) or nearbyTableId
    if not tableId then return end

    local ped    = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local pCoords = { x = coords.x, y = coords.y, z = coords.z }

    if action == 'process' then
        isProcessing = true
        -- Hasta 20 por tanda, como el servidor; la animacion y la cuenta atras
        -- empiezan cuando el servidor lo acepta (ProcessAccepted). Antes
        -- arrancaban ya, y si el servidor decia que no la NUI seguia contando.
        local qty = math.floor(math.max(1, math.min(tonumber(data.amount) or 1, 20)))
        -- `resultado`: el del minijuego de manicura al desojar (perfect/good/miss)
        TriggerServerEvent('origen_weed:server:ProcessItems',
            tableId, data.operation, data.inputItem, qty, pCoords, data.resultado)

    elseif action == 'process_all' then
        isProcessing = true
        TriggerServerEvent('origen_weed:server:ProcessAll', tableId, data.resultado)

    elseif action == 'remove_table' then
        SetNuiFocus(false, false)
        unseatPlayer()
        TriggerServerEvent('origen_weed:server:RemoveTable', tableId, pCoords)

    elseif action == 'refresh' then
        -- Reabrir NUI con datos frescos
        openTableNUI(tableId)
    end
end)

-- ── El servidor acepta o rechaza el procesado ────────────────────────────────
RegisterNetEvent('origen_weed:client:ProcessAccepted', function(qty, ms)
    local cfg     = Config.Weed.Table
    local totalMs = tonumber(ms) or (cfg.processTimeMs * (tonumber(qty) or 1))
    local ped     = PlayerPedId()
    local dict, clip, flags = cfg.processAnim.dict, cfg.processAnim.clip, cfg.processAnim.flags
    CreateThread(function()
        RequestAnimDict(dict)
        local t = 0
        while not HasAnimDictLoaded(dict) and t < 30 do Wait(100); t = t + 1 end
        if HasAnimDictLoaded(dict) then
            TaskPlayAnim(ped, dict, clip, 8.0, -8.0, totalMs, flags, 0.0, false, false, false)
        end
    end)
    -- La duración real, para que la NUI muestre la cuenta atrás correcta
    SendNUIMessage({ action = 'processingStarted', duration = totalMs })
end)

RegisterNetEvent('origen_weed:client:ProcessRejected', function()
    isProcessing = false
    SendNUIMessage({ action = 'processingRejected' })
    local cfg = Config.Weed.Table
    StopAnimTask(PlayerPedId(), cfg.processAnim.dict, cfg.processAnim.clip, 1.0)
    if seatedAtTable then openTableNUI(seatedAtTable) end
end)

-- ── Animación de procesado terminada → notificar NUI ─────────────────────────
RegisterNetEvent('origen_weed:client:ProcessDone', function()
    isProcessing = false
    -- Parar la animación de brazos sin interrumpir el escenario de sentado
    local ped = PlayerPedId()
    local cfg = Config.Weed.Table
    StopAnimTask(ped, cfg.processAnim.dict, cfg.processAnim.clip, 1.0)
    -- Refrescar NUI con nuevo inventario (el PJ sigue sentado, no relanzar escenario)
    if seatedAtTable then
        openTableNUI(seatedAtTable)
    end
end)

-- ── Placement mode ────────────────────────────────────────────────────────────
local function tableRayCast(rayDist)
    local camRot = GetGameplayCamRot()
    local camPos = GetGameplayCamCoord()
    local rotRad = math.rad(camRot.z)
    local cosX   = math.abs(math.cos(math.rad(camRot.x)))
    local dir    = vector3(-math.sin(rotRad) * cosX, math.cos(rotRad) * cosX, math.sin(math.rad(camRot.x)))
    local dest   = camPos + dir * rayDist

    local ray = StartShapeTestRay(camPos.x, camPos.y, camPos.z, dest.x, dest.y, dest.z, 1, -1, 0)
    local _, hit, hitPos = GetShapeTestResult(ray)
    if hit == 1 then return hit, hitPos end

    local downRay = StartShapeTestRay(dest.x, dest.y, dest.z + 5.0, dest.x, dest.y, dest.z - 50.0, 1, -1, 0)
    local _, hit2, hitPos2 = GetShapeTestResult(downRay)
    if hit2 == 1 then return hit2, hitPos2 end

    local found, gz = GetGroundZFor_3dCoord(dest.x, dest.y, dest.z, false)
    if found then return 1, vector3(dest.x, dest.y, gz) end

    return 0, dest
end

local function enterTablePlacementMode()
    local ped = PlayerPedId()
    if GetVehiclePedIsIn(ped, false) ~= 0 or placingTable then return end
    placingTable = true

    local cfg   = Config.Weed.Table
    local model = GetHashKey(cfg.prop)
    loadTableModel(model)

    local rayDist   = Config.Weed.World.raycastDistance or 7.0
    local zOffset   = 0.0
    local rotOffset = 0.0
    local lastDest  = GetEntityCoords(ped)

    local hit, dest = tableRayCast(rayDist)
    if hit == 1 then lastDest = dest end

    local ghost = CreateObject(model, lastDest.x, lastDest.y, lastDest.z, false, false, false)
    SetEntityCollision(ghost, false, false)
    SetEntityAlpha(ghost, 150, true)

    -- E Colocar → notify DrawText (arriba derecha)
    exports['origen_notify']:DrawText('E', 'Colocar mesa')
    exports['origen_hud']:setupControls({
        { key = '↑↓', text = 'Altura'   },
        { key = '←→', text = 'Rotar'    },
    })

    local finalHeading = GetEntityHeading(ped)
    local finalPos     = lastDest

    while placingTable do
        Wait(0)

        DisableControlAction(0, 172, true)
        DisableControlAction(0, 173, true)
        DisableControlAction(0, 174, true)
        DisableControlAction(0, 175, true)

        hit, dest = tableRayCast(rayDist)
        if hit == 1 then
            lastDest = dest
            finalPos = vector3(dest.x, dest.y, dest.z + zOffset)
        else
            finalPos = vector3(lastDest.x, lastDest.y, lastDest.z + zOffset)
        end

        if IsDisabledControlPressed(0, 172) then
            zOffset = math.min(zOffset + 0.02, 5.0)
        elseif IsDisabledControlPressed(0, 173) then
            zOffset = math.max(zOffset - 0.02, -2.0)
        end

        if IsDisabledControlJustPressed(0, 175) then
            rotOffset = (rotOffset + 15.0) % 360.0
        elseif IsDisabledControlJustPressed(0, 174) then
            rotOffset = (rotOffset - 15.0) % 360.0
        end

        finalHeading = (GetGameplayCamRot().z + rotOffset) % 360.0
        SetEntityCoords(ghost, finalPos.x, finalPos.y, finalPos.z, false, false, false, false)
        SetEntityHeading(ghost, finalHeading)

        -- Backspace: cancelar
        if IsControlJustPressed(0, 194) then
            exports['origen_notify']:HideText()
            exports['origen_hud']:hideControls()
            DeleteEntity(ghost)
            placingTable = false
            return
        end

        -- E: confirmar
        if IsControlJustPressed(0, 38) then
            exports['origen_notify']:HideText()
            exports['origen_hud']:hideControls()
            DeleteEntity(ghost)

            local placeDest    = finalPos
            local placeHeading = finalHeading

            RequestAnimDict('amb@medic@standing@kneel@base')
            local tries = 0
            while not HasAnimDictLoaded('amb@medic@standing@kneel@base') and tries < 30 do
                Wait(50); tries = tries + 1
            end

            exports['origen_inventory']:progressBar({
                name            = 'origen_weed_place_table',
                duration        = Config.Weed.Progress.placePlant or 2000,
                label           = 'Montando la mesa...',
                useWhileDead    = false,
                canCancel       = true,
                controlDisables = { disableMovement = true, disableCombat = true },
                animation       = { animDict = 'amb@medic@standing@kneel@base', anim = 'base', flags = 1 },
            }, nil, nil, function(cancelled)
                ClearPedTasks(ped)
                placingTable = false
                if cancelled then
                    exports['origen_notify']:Notify({ description = 'Cancelado', type = 'error', duration = 2000 })
                    return
                end
                TriggerServerEvent('origen_weed:server:CreateTable', {
                    x = placeDest.x, y = placeDest.y, z = placeDest.z
                }, placeHeading)
            end)

            TaskPlayAnim(ped, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, -1, 1, 0, false, false, false)
            return
        end
    end
end

-- ── Use item ──────────────────────────────────────────────────────────────────
RegisterNetEvent('origen_weed:client:UseTableItem', function()
    -- La mesa puede colocarse en cualquier lugar (sin restricción de zona)
    CreateThread(enterTablePlacementMode)
end)

-- ── Server → Client sync ──────────────────────────────────────────────────────
RegisterNetEvent('origen_weed:client:SyncTables', function(list)
    for id in pairs(LocalTables) do despawnTableProp(id) end
    KnownTables = {}
    for _, t in ipairs(list or {}) do
        KnownTables[t.id] = {
            id      = t.id,
            coords  = vector3(t.coords.x, t.coords.y, t.coords.z),
            heading = t.heading,
        }
    end
end)

RegisterNetEvent('origen_weed:client:AddTable', function(t)
    KnownTables[t.id] = {
        id      = t.id,
        coords  = vector3(t.coords.x, t.coords.y, t.coords.z),
        heading = t.heading,
    }
    local ped  = PlayerPedId()
    local dist = #(GetEntityCoords(ped) - KnownTables[t.id].coords)
    if dist <= Config.Weed.Table.streamDistance then
        spawnTableProp(t.id, KnownTables[t.id].coords, KnownTables[t.id].heading)
    end
end)

RegisterNetEvent('origen_weed:client:RemoveTable', function(tableId)
    KnownTables[tableId] = nil
    despawnTableProp(tableId)
    if seatedAtTable == tableId then
        -- Sentado con el menu abierto: sin mesa no hay menu, y el raton
        -- se quedaba cogido sobre el.
        isProcessing = false
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'closeAll' })
        unseatPlayer()
    end
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    Wait(1000)
    TriggerServerEvent('origen_weed:server:RequestTableSync')
end)

--[[ Al parar el recurso (restart) se borra todo lo puesto AQUI MISMO, sin
     hilos: el borrado normal va en un CreateThread que ya no llega a correr
     con el recurso parandose, y quedaban mesas fantasma en el suelo, sin
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
    for _, d in pairs(LocalTables) do
        fuera(d.chair)
        for _, o in ipairs(d.decor or {}) do fuera(o) end
        fuera(d.entity)
    end
    LocalTables = {}
end)
