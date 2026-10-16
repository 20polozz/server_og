-- ─────────────────────────────────────────────────────────────────────────────
--  origen_weed · Tendal de Secado — Cliente
-- ─────────────────────────────────────────────────────────────────────────────
local QBCore = exports['qb-core']:GetCoreObject()

-- ── Estado global ─────────────────────────────────────────────────────────────
local KnownTendals = {}   -- [id] = { id, coords, heading, slotOccupancy }
local LocalTendals = {}   -- [id] = { entity, branches = { [slotIdx] = entity } }

local nearbyTendalId     = nil
local nearbyTendalCoords = nil
local lastTendalHint     = ''
local placingTendal      = false
local openTendalId       = nil   -- tendal cuyo menú está abierto ahora mismo

-- ── Helpers ───────────────────────────────────────────────────────────────────
-- Con tope: si el modelo no existe (el tendal se quedaba así, esperando para
-- siempre a origen_tenderomaria), devuelve false en vez de colgar el hilo.
local function loadTendalModel(model)
    if HasModelLoaded(model) then return true end
    if not IsModelInCdimage(model) then
        print(('[origen_weed] Falta el modelo %s'):format(model))
        return false
    end
    RequestModel(model)
    local hasta = GetGameTimer() + 10000
    while not HasModelLoaded(model) do
        if GetGameTimer() > hasta then return false end
        Wait(0)
    end
    return true
end

-- Reutilizamos safeDeleteEntity de main.lua (mismo entorno Lua del recurso)
local function tendalSafeDelete(entity)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return end
    SetEntityCollision(entity, false, false)
    SetEntityVisible(entity, false, false)
    CreateThread(function()
        Wait(0)
        if not DoesEntityExist(entity) then return end
        FreezeEntityPosition(entity, false)
        SetEntityAsMissionEntity(entity, false, true)
        DeleteObject(entity)
        local tries = 0
        while DoesEntityExist(entity) and tries < 20 do
            Wait(500)
            tries = tries + 1
            SetEntityCollision(entity, false, false)
            DeleteObject(entity)
        end
        if DoesEntityExist(entity) then DeleteEntity(entity) end
    end)
end

-- ── Spawn / Despawn de props ──────────────────────────────────────────────────
local function spawnTendalBranch(tendalId, slotIdx, tendalEntity)
    local cfg    = Config.Weed.Tendal
    local model  = GetHashKey(cfg.branchProp)
    if not loadTendalModel(model) then return nil end

    local offset = cfg.slotOffsets[slotIdx]
    if not offset then return nil end

    local bEnt = CreateObject(model, 0.0, 0.0, 0.0, false, false, false)
    if not bEnt or bEnt == 0 then return nil end

    SetEntityAsMissionEntity(bEnt, true, true)
    AttachEntityToEntity(bEnt, tendalEntity, -1,
        offset.x, offset.y, offset.z,
        offset.rx or 0.0, offset.ry or 0.0, offset.rz or 0.0,
        false, false, false, false, 0, true)
    return bEnt
end

local function spawnTendalProp(id, coords, heading, slotOccupancy)
    local prev = LocalTendals[id]
    if prev then
        if prev.branches then
            for _, b in pairs(prev.branches) do tendalSafeDelete(b) end
        end
        tendalSafeDelete(prev.entity)
        LocalTendals[id] = nil
    end

    local cfg   = Config.Weed.Tendal
    local model = GetHashKey(cfg.prop)
    if not loadTendalModel(model) then return end

    local entity = CreateObjectNoOffset(model,
        coords.x, coords.y, coords.z, false, false, false)
    if not entity or entity == 0 then return end

    SetEntityHeading(entity, heading)
    FreezeEntityPosition(entity, true)
    SetEntityAsMissionEntity(entity, true, true)
    SetEntityCollision(entity, true, true)

    LocalTendals[id] = { entity = entity, branches = {} }

    -- Spawn branch props for occupied slots
    if slotOccupancy then
        for i = 1, cfg.slots do
            if slotOccupancy[i] then
                local bEnt = spawnTendalBranch(id, i, entity)
                if bEnt then LocalTendals[id].branches[i] = bEnt end
            end
        end
    end
end

local function despawnTendalProp(id)
    local data = LocalTendals[id]
    if not data then return end
    LocalTendals[id] = nil
    if data.branches then
        for _, b in pairs(data.branches) do tendalSafeDelete(b) end
    end
    tendalSafeDelete(data.entity)
end

-- ── Streaming loop ─────────────────────────────────────────────────────────────
CreateThread(function()
    while true do
        Wait(Config.Weed.Tendal.streamCheckInterval)
        local playerCoords = GetEntityCoords(PlayerPedId())
        local streamDist   = Config.Weed.Tendal.streamDistance

        for id, t in pairs(KnownTendals) do
            local dist = #(playerCoords - t.coords)
            if dist <= streamDist then
                if not LocalTendals[id] then
                    spawnTendalProp(id, t.coords, t.heading, t.slotOccupancy)
                end
            else
                if LocalTendals[id] then despawnTendalProp(id) end
            end
        end
    end
end)

-- ── Nearby detection loop ─────────────────────────────────────────────────────
CreateThread(function()
    while true do
        Wait(500)
        if not SetNuiFocusCursor then Wait(1000) end  -- safety
        local playerCoords = GetEntityCoords(PlayerPedId())
        local interactDist = Config.Weed.Tendal.interactDistance

        nearbyTendalId     = nil
        nearbyTendalCoords = nil

        for id, data in pairs(LocalTendals) do
            if DoesEntityExist(data.entity) then
                local entCoords = GetEntityCoords(data.entity)
                if #(playerCoords - entCoords) <= interactDist then
                    nearbyTendalId     = id
                    nearbyTendalCoords = entCoords
                    break
                end
            end
        end

        if nearbyTendalId then
            if lastTendalHint ~= 'tendal' then
                lastTendalHint = 'tendal'
                exports['origen_notify']:DrawText('E', 'Inspeccionar tendal')
            end
        else
            if lastTendalHint == 'tendal' then
                lastTendalHint = ''
                exports['origen_notify']:HideText()
            end
        end
    end
end)

-- ── Helper: pedir datos frescos al servidor y enviarlos al NUI ────────────────
local function refreshTendalNUI(tendalId)
    local ped    = PlayerPedId()
    local coords = GetEntityCoords(ped)
    QBCore.Functions.TriggerCallback('origen_weed:server:GetTendalData', function(data)
        if not data then return end
        local gtaHour = GetClockHours()
        local cfg     = Config.Weed.Tendal
        -- La hora y el ritmo los manda el servidor (la de su reloj); esto es
        -- solo por si llega sin ellos
        data.gtaHour     = data.gtaHour or gtaHour
        data.currentMult = data.currentMult or ((gtaHour >= cfg.dayStart and gtaHour < cfg.dayEnd)
            and cfg.timeMultipliers.day or cfg.timeMultipliers.night)
        SendNUIMessage({ action = 'openTendalMenu', data = data })
    end, tendalId, { x = coords.x, y = coords.y, z = coords.z })
end

-- ── E key: open menu ──────────────────────────────────────────────────────────
CreateThread(function()
    while true do
        -- Por fotograma solo con un tendal cerca (nearbyTendalId se refresca cada 500 ms)
        Wait(nearbyTendalId and 0 or 500)
        if nearbyTendalId and not placingTendal and IsControlJustPressed(0, 38) then
            openTendalId = nearbyTendalId
            local ped    = PlayerPedId()
            local coords = GetEntityCoords(ped)
            QBCore.Functions.TriggerCallback('origen_weed:server:GetTendalData', function(data)
                if not data then
                    exports['origen_notify']:Notify({
                        description = 'No se pudo obtener datos del tendal',
                        type = 'error', duration = 3000
                    })
                    openTendalId = nil
                    return
                end
                local gtaHour = GetClockHours()
                local cfg     = Config.Weed.Tendal
                data.gtaHour     = data.gtaHour or gtaHour
                data.currentMult = data.currentMult or ((gtaHour >= cfg.dayStart and gtaHour < cfg.dayEnd)
                    and cfg.timeMultipliers.day or cfg.timeMultipliers.night)

                SetNuiFocus(true, true)
                SendNUIMessage({ action = 'openTendalMenu', data = data })
            end, nearbyTendalId, coords)
        end
    end
end)

-- ── Placement mode ────────────────────────────────────────────────────────────
-- Doble raycast: dirección cámara + fallback vertical hacia abajo.
-- Esto garantiza detectar el suelo aunque el terreno sea irregular.
local function tendalRayCast(rayDist)
    local camRot = GetGameplayCamRot()
    local camPos = GetGameplayCamCoord()
    local rotRad = math.rad(camRot.z)
    local cosX   = math.abs(math.cos(math.rad(camRot.x)))
    local dir    = vector3(-math.sin(rotRad) * cosX, math.cos(rotRad) * cosX, math.sin(math.rad(camRot.x)))
    local dest   = camPos + dir * rayDist

    -- 1º Rayo en dirección cámara (flag 1 = world, sin agua)
    local ray = StartShapeTestRay(
        camPos.x, camPos.y, camPos.z,
        dest.x,   dest.y,   dest.z,
        1, -1, 0)
    local _, hit, hitPos = GetShapeTestResult(ray)
    if hit == 1 then return hit, hitPos end

    -- 2º Fallback: rayo vertical hacia abajo desde el punto destino
    local downRay = StartShapeTestRay(
        dest.x, dest.y, dest.z + 5.0,
        dest.x, dest.y, dest.z - 50.0,
        1, -1, 0)
    local _, hit2, hitPos2 = GetShapeTestResult(downRay)
    if hit2 == 1 then return hit2, hitPos2 end

    -- 3º Último recurso: GetGroundZFor_3dCoord
    local found, gz = GetGroundZFor_3dCoord(dest.x, dest.y, dest.z, false)
    if found then return 1, vector3(dest.x, dest.y, gz) end

    return 0, dest
end

local function enterTendalPlacementMode()
    local ped = PlayerPedId()
    if GetVehiclePedIsIn(ped, false) ~= 0 or placingTendal then return end
    placingTendal = true

    local cfg     = Config.Weed.Tendal
    local model   = GetHashKey(cfg.prop)
    if not loadTendalModel(model) then
        placingTendal = false
        exports['origen_notify']:Notify({ description = 'No se pudo cargar el tendal', type = 'error', duration = 3000 })
        return
    end

    local rayDist   = Config.Weed.World.raycastDistance or 7.0
    local zOffset   = 0.0    -- ↑↓: ajuste de altura (+/- 0.05 m por frame)
    local rotOffset = 0.0    -- Q/E: ajuste de rotación (+-10°)
    local lastDest  = GetEntityCoords(ped)
    local lastHit   = 0

    local hit, dest = tendalRayCast(rayDist)
    if hit == 1 then lastDest = dest end

    local ghost = CreateObject(model, lastDest.x, lastDest.y, lastDest.z, false, false, false)
    SetEntityCollision(ghost, false, false)
    SetEntityAlpha(ghost, 150, true)

    -- E Colocar → notify DrawText (arriba derecha)
    exports['origen_notify']:DrawText('E', 'Colocar')
    exports['origen_hud']:setupControls({
        { key = '↑↓', text = 'Altura'   },
        { key = '←→', text = 'Rotar'    },
    })

    local finalHeading = GetEntityHeading(ped)
    local finalPos     = lastDest

    while placingTendal do
        Wait(0)

        -- Capturar flechas ANTES de que el juego las use para cámara/movimiento
        DisableControlAction(0, 172, true)   -- ↑
        DisableControlAction(0, 173, true)   -- ↓
        DisableControlAction(0, 174, true)   -- ←
        DisableControlAction(0, 175, true)   -- →

        hit, dest = tendalRayCast(rayDist)
        if hit == 1 then
            lastDest = dest
            finalPos = vector3(dest.x, dest.y, dest.z + zOffset)
        else
            finalPos = vector3(lastDest.x, lastDest.y, lastDest.z + zOffset)
        end

        -- Altura: ↑↓ (continuo mientras se mantiene)
        if IsDisabledControlPressed(0, 172) then      -- ↑ Subir
            zOffset = math.min(zOffset + 0.02, 8.0)
        elseif IsDisabledControlPressed(0, 173) then  -- ↓ Bajar
            zOffset = math.max(zOffset - 0.02, -3.0)
        end

        -- Rotación: ← → (una pulsación = 15°)
        if IsDisabledControlJustPressed(0, 175) then  -- → +15°
            rotOffset = (rotOffset + 15.0) % 360.0
        elseif IsDisabledControlJustPressed(0, 174) then  -- ← -15°
            rotOffset = (rotOffset - 15.0) % 360.0
        elseif IsControlJustPressed(0, 44) then       -- Q también rota -15°
            rotOffset = (rotOffset - 15.0) % 360.0
        end

        -- Heading = cámara + rotación manual
        finalHeading = (GetGameplayCamRot().z + rotOffset) % 360.0

        -- Actualizar ghost
        SetEntityCoords(ghost, finalPos.x, finalPos.y, finalPos.z, false, false, false, false)
        SetEntityHeading(ghost, finalHeading)

        -- Backspace (retroceder): cancelar
        if IsControlJustPressed(0, 194) then
            exports['origen_notify']:HideText()
            exports['origen_hud']:hideControls()
            DeleteEntity(ghost)
            placingTendal = false
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
                name            = 'origen_weed_place_tendal',
                duration        = Config.Weed.Progress.placePlant or 2000,
                label           = 'Montando el tendal...',
                useWhileDead    = false,
                canCancel       = true,
                controlDisables = { disableMovement = true, disableCombat = true },
                animation       = { animDict = 'amb@medic@standing@kneel@base', anim = 'base', flags = 1 },
            }, nil, nil, function(cancelled)
                ClearPedTasks(ped)
                placingTendal = false
                if cancelled then
                    exports['origen_notify']:Notify({ description = 'Cancelado', type = 'error', duration = 2000 })
                    return
                end
                TriggerServerEvent('origen_weed:server:CreateTendal', {
                    x = placeDest.x, y = placeDest.y, z = placeDest.z
                }, placeHeading)
            end)

            TaskPlayAnim(ped, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, -1, 1, 0, false, false, false)
            return
        end
    end
end

-- ── Validación de zona (cliente, mismo config compartido que el servidor) ─────
local function clientIsInValidZone()
    local rules = Config.Weed.Planting
    if not rules or not rules.enforceValidZones then return true end
    local pos = GetEntityCoords(PlayerPedId())
    for _, zone in ipairs(rules.validZones or {}) do
        if #(pos - zone.coords) <= zone.radius then return true end
    end
    return false
end

-- ── Use item → placement mode ─────────────────────────────────────────────────
RegisterNetEvent('origen_weed:client:UseTendalItem', function()
    if not clientIsInValidZone() then
        exports['origen_notify']:Notify({
            description = 'No puedes colocar el tendal aquí. Busca una zona de cultivo.',
            type        = 'error',
            duration    = 4000,
        })
        return
    end
    CreateThread(enterTendalPlacementMode)
end)

-- ── Server → Client sync events ───────────────────────────────────────────────
RegisterNetEvent('origen_weed:client:SyncTendals', function(list)
    for id in pairs(LocalTendals) do despawnTendalProp(id) end
    KnownTendals = {}
    for _, t in ipairs(list or {}) do
        KnownTendals[t.id] = {
            id            = t.id,
            coords        = vector3(t.coords.x, t.coords.y, t.coords.z),
            heading       = t.heading,
            slotOccupancy = t.slotOccupancy,
        }
    end
end)

RegisterNetEvent('origen_weed:client:AddTendal', function(t)
    KnownTendals[t.id] = {
        id            = t.id,
        coords        = vector3(t.coords.x, t.coords.y, t.coords.z),
        heading       = t.heading,
        slotOccupancy = t.slotOccupancy or {},
    }
    -- Spawn immediamente si el jugador está cerca
    local playerCoords = GetEntityCoords(PlayerPedId())
    if #(playerCoords - KnownTendals[t.id].coords) <= Config.Weed.Tendal.streamDistance then
        spawnTendalProp(t.id, KnownTendals[t.id].coords, KnownTendals[t.id].heading, KnownTendals[t.id].slotOccupancy)
    end
end)

RegisterNetEvent('origen_weed:client:RemoveTendal', function(tendalId)
    KnownTendals[tendalId] = nil
    despawnTendalProp(tendalId)
    if nearbyTendalId == tendalId then
        nearbyTendalId = nil
        exports['origen_notify']:HideText()
    end
end)

RegisterNetEvent('origen_weed:client:UpdateTendalSlots', function(tendalId, slotOccupancy)
    local t = KnownTendals[tendalId]
    if not t then return end
    t.slotOccupancy = slotOccupancy

    local localData = LocalTendals[tendalId]
    if not localData then return end

    local cfg = Config.Weed.Tendal
    loadTendalModel(GetHashKey(cfg.branchProp))

    for i = 1, cfg.slots do
        local occupied = slotOccupancy[i]
        local existing = localData.branches[i]

        if occupied and not existing then
            local bEnt = spawnTendalBranch(tendalId, i, localData.entity)
            if bEnt then localData.branches[i] = bEnt end
        elseif not occupied and existing then
            tendalSafeDelete(existing)
            localData.branches[i] = nil
        end
    end

    -- Si el menú de este tendal está abierto, actualizar el NUI con datos frescos
    if openTendalId == tendalId then
        refreshTendalNUI(tendalId)
    end
end)

-- ── NUI Callbacks ─────────────────────────────────────────────────────────────
--[[ Si el vigilante suelta el raton a la fuerza, el menu del tendal se da
     por cerrado: si no, el refresco de UpdateTendalSlots lo volvia a pintar.
     La pantalla la cierra el AlSoltar de main.lua ('closeAll'). ]]
OrigenFoco.AlSoltar(function()
    openTendalId = nil
end)

RegisterNUICallback('closeTendalMenu', function(_, cb)
    SetNuiFocus(false, false)
    openTendalId = nil
    cb({})
end)

RegisterNUICallback('tendalAction', function(data, cb)
    -- El menú sigue abierto con todo (colgar, recoger, voltear...): el servidor
    -- manda TendalRefrescar y se repinta con datos nuevos. Solo se cierra al
    -- desmontar el tendal.
    if data.action == 'remove_tendal' then
        SetNuiFocus(false, false)
        openTendalId = nil
        SendNUIMessage({ action = 'closeAll' })
    end
    cb({})

    local action   = data.action
    local tendalId = tonumber(data.tendalId) or nearbyTendalId
    if not tendalId then return end

    local ped    = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local pCoords = { x = coords.x, y = coords.y, z = coords.z }
    local gtaHour = GetClockHours()

    if action == 'add_branch' then
        TriggerServerEvent('origen_weed:server:TendalAddBranch',
            tendalId, tonumber(data.slotIdx), data.item, pCoords, gtaHour)

    elseif action == 'collect_slot' then
        TriggerServerEvent('origen_weed:server:TendalCollectSlot',
            tendalId, tonumber(data.slotIdx), pCoords, gtaHour)

    elseif action == 'collect_all' then
        TriggerServerEvent('origen_weed:server:TendalCollectAll', tendalId, pCoords, gtaHour)

    elseif action == 'remove_tendal' then
        TriggerServerEvent('origen_weed:server:RemoveTendal', tendalId, pCoords, gtaHour)

    elseif action == 'hang_all' then
        TriggerServerEvent('origen_weed:server:TendalHangAll', tendalId)

    elseif action == 'flip' then
        TriggerServerEvent('origen_weed:server:TendalFlip', tendalId, tonumber(data.slotIdx))

    elseif action == 'unhang' then
        TriggerServerEvent('origen_weed:server:TendalUnhang', tendalId, tonumber(data.slotIdx))
    end
end)

-- Algo ha cambiado en el tendal que tengo abierto (aunque no cambien los huecos)
RegisterNetEvent('origen_weed:client:TendalRefrescar', function(tendalId)
    if openTendalId == tendalId then refreshTendalNUI(tendalId) end
end)

-- Request sync on resource start
AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    Wait(1000)
    TriggerServerEvent('origen_weed:server:RequestTendalSync')
end)

--[[ Al parar el recurso (restart) se borra todo lo puesto AQUI MISMO, sin
     hilos: el borrado normal va en un CreateThread que ya no llega a correr
     con el recurso parandose, y quedaban tendales fantasma en el suelo, sin
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
    for _, d in pairs(LocalTendals) do
        for _, b in pairs(d.branches or {}) do fuera(b) end
        fuera(d.entity)
    end
    LocalTendals = {}
end)
