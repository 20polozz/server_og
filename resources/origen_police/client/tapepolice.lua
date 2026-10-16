local placingTape = false
local startPos = nil
local currentItemSlot = nil
local ghostEntity = nil
local currentModelHash = nil

local tapeModels = {
    {dist = 1, model = "prop_police_tape_01", realLen = 1.0},
    {dist = 2, model = "prop_police_tape_02", realLen = 2.0},
    {dist = 3, model = "prop_police_tape_03", realLen = 3.0},
    {dist = 4, model = "prop_police_tape_04", realLen = 4.0},
    {dist = 6, model = "prop_police_tape_05", realLen = 6.0},
    {dist = 8, model = "prop_police_tape_06", realLen = 8.0},
    {dist = 10, model = "prop_police_tape_07", realLen = 10.0},
    {dist = 12, model = "prop_police_tape_08b", realLen = 12.0},
    {dist = 16, model = "prop_police_tape_09b", realLen = 16.0},
    {dist = 20, model = "prop_police_tape_10b", realLen = 20.0},
    {dist = 25, model = "prop_police_tape_11b", realLen = 25.0},
    {dist = 30, model = "prop_police_tape_12b", realLen = 30.0},
    {dist = 40, model = "prop_police_tape_13b", realLen = 40.0},
    {dist = 50, model = "prop_police_tape_14b", realLen = 50.0},
}

-- Pre-load models y calcular longitudes reales una sola vez
CreateThread(function()
    for i, data in ipairs(tapeModels) do
        local hash = GetHashKey(data.model)
        RequestModel(hash)
        while not HasModelLoaded(hash) do Wait(1) end
        
        local min, max = GetModelDimensions(hash)
        local len = math.abs(max.y - min.y)
        if len < 0.1 then len = math.abs(max.x - min.x) end
        tapeModels[i].realLen = len
    end
end)

-- RegisterNetEvent('origen_police:useTape', function(slot)
--     placingTape = true
--     startPos = nil
--     currentItemSlot = slot
--     exports.origen_hud:setupControls({
--         { key = "E", text = "Marcar punto de inicio" }
--     })
-- end)

local function DeleteGhost()
    if ghostEntity and DoesEntityExist(ghostEntity) then
        DeleteObject(ghostEntity)
    end
    ghostEntity = nil
    currentModelHash = nil
end

local function UpdateGhost(p1, p2, hash)
    if currentModelHash ~= hash then
        DeleteGhost()
        currentModelHash = hash
        ghostEntity = CreateObject(hash, p2.x, p2.y, p2.z, false, false, false)
        SetEntityAlpha(ghostEntity, 150, false)
        SetEntityCollision(ghostEntity, false, false)
        SetEntityInvincible(ghostEntity, true)
    end

    if ghostEntity and DoesEntityExist(ghostEntity) then
        local center = (p1 + p2) / 2
        local dx, dy, dz = p2.x - p1.x, p2.y - p1.y, p2.z - p1.z
        local heading = math.deg(math.atan2(-dx, dy))
        local dist2d = math.sqrt(dx*dx + dy*dy)
        local pitch = math.deg(math.atan2(dz, dist2d)) 
        
        SetEntityCoordsNoOffset(ghostEntity, center.x, center.y, center.z, true, false, false, true)
        SetEntityRotation(ghostEntity, pitch, 0.0, heading, 2, true)
    end
end

RegisterNetEvent("origen_police:removetape", function()
    local playerPed = PlayerPedId()
    local playerPos = GetEntityCoords(playerPed)
    local objects = GetGamePool('CObject')
    local nearbyTapes = {}
    
    for _, object in ipairs(objects) do
        if DoesEntityExist(object) then
            local model = GetEntityModel(object)
            local isTape = false
            for _, data in ipairs(tapeModels) do
                if model == GetHashKey(data.model) then isTape = true break end
            end
            if isTape then
                table.insert(nearbyTapes, {entity = object, dist = #(playerPos - GetEntityCoords(object))})
            end
        end
    end

    if #nearbyTapes > 0 then
        table.sort(nearbyTapes, function(a, b) return a.dist < b.dist end)
        if nearbyTapes[1].dist < 5.0 then
            local netId = NetworkGetNetworkIdFromEntity(nearbyTapes[1].entity)
            TriggerServerEvent("origen_police:server:deleteTape", netId)
        end
    else
        Notify("No hay cintas cerca.", "error")
    end
end)

RegisterNetEvent("origen_police:client:tapeDeleted", function()
    Notify("Cinta eliminada.", "success")
end)

-- CreateThread(function()
--     while true do
--         local wait = 500
--         if placingTape then
--             wait = 0
--             local hit, pos, entity = RaycastFromCamera(30.0)
            
--             if not startPos then
--                 if hit then
--                     DrawMarker(28, pos.x, pos.y, pos.z, 0,0,0, 0,0,0, 0.2, 0.2, 0.2, 0, 0, 0, 155, false, true, 2, false, nil, nil, false)
--                     if IsControlJustPressed(0, 38) then
--                         startPos = pos
--                         exports.origen_hud:hideControls()
--                         Wait(100)
--                         exports.origen_hud:setupControls({
--                             { key = "E", text = "Fijar cinta" },
--                             { key = "CLICK DERECHO", text = "Cancelar" }
--                         })
--                     end
--                 end
--                 if IsControlJustPressed(0, 25) or IsControlJustPressed(0, 177) then 
--                     placingTape = false
--                     exports.origen_hud:hideControls()
--                 end
--             else
--                 if hit then
--                     local dist = #(startPos - pos)
--                     if dist > 0.1 then -- Evitar división por cero
--                         local bestModel = GetBestModel(dist)
--                         local dir = pos - startPos
--                         local unitDir = dir / dist
--                         local finalPos = startPos + (unitDir * bestModel.realLen)
                        
--                         UpdateGhost(startPos, finalPos, GetHashKey(bestModel.model))
                        
--                         DrawMarker(28, startPos.x, startPos.y, startPos.z, 0,0,0, 0,0,0, 0.1, 0.1, 0.1, 0, 0, 0, 155, false, true, 2, false, nil, nil, false)


--                         if IsControlJustPressed(0, 38) then
--                             SpawnTape(startPos, finalPos, bestModel.model)
--                             Notify("Cinta colocada.", "success")
--                             TriggerServerEvent('origen_police:tapePlaced', currentItemSlot)
--                             DeleteGhost()
--                             placingTape = false
--                             startPos = nil
--                             exports.origen_hud:hideControls()
--                         end
--                     else
--                         DeleteGhost()
--                     end
--                 end

--                 if IsControlJustPressed(0, 25) or IsControlJustPressed(0, 177) then
--                     DeleteGhost()
--                     startPos = nil
--                     placingTape = false
--                     exports.origen_hud:hideControls()
--                     Notify("Cancelado.", "error")
--                 end
--             end
--         end
--         Wait(wait)
--     end
-- end)

function SpawnTape(p1, p2, model)
    local hash = GetHashKey(model)
    local center = (p1 + p2) / 2
    local dx, dy, dz = p2.x - p1.x, p2.y - p1.y, p2.z - p1.z
    local heading = math.deg(math.atan2(-dx, dy))
    local dist2d = math.sqrt(dx*dx + dy*dy)
    local pitch = math.deg(math.atan2(dz, dist2d)) 
    
    local obj = CreateObject(hash, center.x, center.y, center.z, true, true, true)
    SetEntityCoordsNoOffset(obj, center.x, center.y, center.z, true, false, false, true)
    SetEntityRotation(obj, pitch, 0.0, heading, 2, true)
    SetEntityInvincible(obj, true)
    FreezeEntityPosition(obj, true)
    return obj
end

function GetBestModel(dist)
    -- Lógica de modelo más cercano para suavidad visual
    local best = tapeModels[1]
    local minDist = 999.0
    for i, data in ipairs(tapeModels) do
        local diff = math.abs(dist - data.realLen)
        if diff < minDist then
            minDist = diff
            best = data
        end
    end
    return best
end

function RaycastFromCamera(distance)
    local camRot = GetGameplayCamRot(2)
    local camPos = GetGameplayCamCoord()
    local dir = RotationToDirection(camRot)
    local target = camPos + (dir * distance)
    local ray = StartShapeTestRay(camPos.x, camPos.y, camPos.z, target.x, target.y, target.z, -1, PlayerPedId(), 0)
    local _, hit, pos, _, entity = GetShapeTestResult(ray)
    return hit, pos, entity
end

function RotationToDirection(rot)
    local z, x = math.rad(rot.z), math.rad(rot.x)
    local num = math.abs(math.cos(x))
    return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
end

function Notify(text, type)
    local cleanText = text:gsub("~[a-z]~", ""):gsub("~s~", "")
    exports.origen_notify:showNotification({
        title = "CINTA POLICIAL",
        description = cleanText,
        type = type or 'primary',
        duration = 5000
    })
end



AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    DeleteGhost()
end)
