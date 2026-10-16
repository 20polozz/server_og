local placedProps      = {}
local hiddenCategories = {}
local categoryColors   = {}
local isAdmin          = false
local permLevel        = "none"
local menuOpen         = false
local propsLoaded      = false
local _pendingOpen     = false
local undoStackSize    = 0

local function log(msg)
    if not Config.StreamLogs then return end
    print(("^5[PropPlacer]^7 %s"):format(msg))
end

local function notify(msg, tipo)
    if GetResourceState("origen_notify") == "started" then
        exports.origen_notify:Notify({
            title       = "Objetos",
            description = msg,
            type        = tipo or "info",
            duration    = 5000
        })
    else
        BeginTextCommandThefeedPost("STRING")
        AddTextComponentSubstringPlayerName(msg)
        EndTextCommandThefeedPostTicker(false, false)
    end
end

local function spawnEntity(data)
    local hash = GetHashKey(data.model)
    RequestModel(hash)
    local t = 0
    while not HasModelLoaded(hash) and t < 5000 do Wait(50); t = t + 50 end
    if not HasModelLoaded(hash) then
        log(("WARN  modelo no cargado: %s (id %s)"):format(data.model, tostring(data.dbId)))
        return
    end
    local ent = CreateObject(hash, data.x, data.y, data.z, false, false, false)
    SetEntityAsMissionEntity(ent, true, true)
    SetEntityRotation(ent, data.rx or 0, data.ry or 0, data.rz or 0, 2, true)
    FreezeEntityPosition(ent, true)
    if data.ghost then
        SetEntityAlpha(ent, 100, false)
        SetEntityCollision(ent, false, false)
    end
    SetModelAsNoLongerNeeded(hash)
    if placedProps[data.dbId] then placedProps[data.dbId].entity = ent end
    log(("IN    id=%-6s  model=%-30s%s"):format(tostring(data.dbId), data.model, data.ghost and " [GHOST]" or ""))
end

local function despawnEntity(dbId)
    local data = placedProps[dbId]
    if not data then return end
    if data.entity and DoesEntityExist(data.entity) then
        DeleteEntity(data.entity)
        log(("OUT   id=%-6s  model=%-30s"):format(tostring(dbId), data.model))
    end
    data.entity = nil
end

local function inStreamRangeSq(px, py, pz, data, rangeSq)
    local dx = px - data.x
    local dy = py - data.y
    local dz = pz - data.z
    return (dx * dx + dy * dy + dz * dz) <= rangeSq
end

local function startStreamer()
    CreateThread(function()
        while true do
            local interval = tonumber(Config.StreamInterval) or 500
            if interval < 200 then interval = 200 end
            if not next(placedProps) then
                Wait(math.max(interval, 1500))
                goto continue
            end

            Wait(interval)
            if Placement.active then goto continue end
            local ped    = PlayerPedId()
            if ped == 0 then goto continue end

            local pCoord = GetEntityCoords(ped)
            local px, py, pz = pCoord.x, pCoord.y, pCoord.z
            local range  = Config.StreamRange
            local rangeSq = range * range
            local spawnBudget = 25
            local despawnBudget = 40

            for dbId, data in pairs(placedProps) do
                local ent = data.entity

                if hiddenCategories[data.category or 'General'] then
                    if ent and DoesEntityExist(ent) and despawnBudget > 0 then
                        despawnEntity(dbId)
                        despawnBudget = despawnBudget - 1
                    end
                    goto nextProp
                end

                if inStreamRangeSq(px, py, pz, data, rangeSq) then
                    if (not ent or not DoesEntityExist(ent)) and spawnBudget > 0 then
                        spawnEntity(data)
                        spawnBudget = spawnBudget - 1
                    end
                else
                    if ent and DoesEntityExist(ent) and despawnBudget > 0 then
                        despawnEntity(dbId)
                        despawnBudget = despawnBudget - 1
                    end
                end

                if spawnBudget <= 0 and despawnBudget <= 0 then
                    break
                end
                ::nextProp::
            end
            ::continue::
        end
    end)
end

local function countProps()
    local n = 0; for _ in pairs(placedProps) do n = n + 1 end; return n
end

local function getPlacedPropsList()
    local list = {}
    for id, data in pairs(placedProps) do
        table.insert(list, {
            id       = id,
            model    = data.model,
            label    = data.label or data.model,
            notes    = data.notes or "",
            category = data.category or 'General',
            active   = data.entity ~= nil and DoesEntityExist(data.entity),
            locked   = data.locked or false,
            ghost    = data.ghost  or false,
            tags     = data.tags   or "",
            x        = data.x,
            y        = data.y,
            z        = data.z,
        })
    end
    return list
end

local function closeNUI()
    menuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "forceClose" })
end

-- Raton soltado a la fuerza (soltarraton, pantalla colgada): el menu se da
-- por cerrado y se esconde, o no volveria a abrirse.
OrigenFoco.AlSoltar(function()
    menuOpen = false
    SendNUIMessage({ action = "forceClose" })
end)

local function restoreMenuFocus()
    if not menuOpen then
        menuOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            action         = "openMenu",
            props          = Config.Props,
            count          = countProps(),
            placedProps    = getPlacedPropsList(),
            categoryColors = categoryColors,
            hiddenCategories = hiddenCategories,
            undoStackSize  = undoStackSize,
            permLevel      = permLevel,
            locale         = Config.Locale or "es",
            config = {
                StreamRange    = Config.StreamRange,
                StreamInterval = Config.StreamInterval,
                DeleteRadius   = Config.DeleteRadius,
                StreamLogs     = Config.StreamLogs,
            },
        })
    end
end

-- Sin permiso no se dice nada: /propplacer sale en las sugerencias del chat
-- de todo el mundo, y el aviso le llegaba a jugadores que solo lo probaban.
local function openMenu()
    if not isAdmin then return end
    menuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action         = "openMenu",
        props          = Config.Props,
        count          = countProps(),
        placedProps    = getPlacedPropsList(),
        categoryColors = categoryColors,
        hiddenCategories = hiddenCategories,
        undoStackSize  = undoStackSize,
        permLevel      = permLevel,
        locale         = Config.Locale or "es",
        config = {
            StreamRange    = Config.StreamRange,
            StreamInterval = Config.StreamInterval,
            DeleteRadius   = Config.DeleteRadius,
            StreamLogs     = Config.StreamLogs,
        },
    })
end

local function enterPlacementMode(model, label, category)
    if Placement.active then return end
    SendNUIMessage({ action = "showPlacingControls", label = label, mode = "raycast", distance = Placement.distance })
    Placement.Start(model,
        function(result)
            SendNUIMessage({ action = "hidePlacingControls" })
            TriggerServerEvent("propplacer:server:placeProp", {
                model    = model,
                x        = result.coords.x,   y  = result.coords.y,   z  = result.coords.z,
                rx       = result.rotation.x, ry = result.rotation.y, rz = result.rotation.z,
                category = category or 'General',
                label    = label,
            })
            notify("Objeto colocado.", "success")
        end,
        function()
            SendNUIMessage({ action = "hidePlacingControls" })
            notify("Colocación cancelada.", "error")
        end
    )
end

local function editPlacementMode(dbId)
    if Placement.active then return end
    local propData = placedProps[dbId]
    if not propData then notify("No se encuentra el objeto.", "error"); return end
    if propData.locked then notify("El objeto está bloqueado.", "error"); return end
    if not propData.entity or not DoesEntityExist(propData.entity) then
        notify("Acércate más al objeto para editarlo.", "error"); return
    end
    SendNUIMessage({ action = "showPlacingControls", label = (propData.label and propData.label ~= "") and ("Editando «" .. propData.label .. "»") or "Editando objeto", mode = "gizmo", distance = 0 })
    Placement.StartEdit(propData.entity,
        function(result)
            SendNUIMessage({ action = "hidePlacingControls" })
            TriggerServerEvent("propplacer:server:updateProp", {
                id = dbId,
                x  = result.coords.x,   y  = result.coords.y,   z  = result.coords.z,
                rx = result.rotation.x, ry = result.rotation.y, rz = result.rotation.z,
            })
        end,
        function()
            SendNUIMessage({ action = "hidePlacingControls" })
            if propData.entity and DoesEntityExist(propData.entity) then
                SetEntityCoordsNoOffset(propData.entity, propData.x, propData.y, propData.z, false, false, false, false)
                SetEntityRotation(propData.entity, propData.rx, propData.ry, propData.rz, 2, true)
                FreezeEntityPosition(propData.entity, true)
            end
            notify("Edición cancelada.", "error")
        end
    )
end

RegisterNetEvent("propplacer:client:setAdmin", function(val, level)
    isAdmin      = val
    adminChecked = true
    permLevel    = level or (val and "editor" or "none")
    if _pendingOpen then
        _pendingOpen = false
        if isAdmin then openMenu() end
    end
end)

RegisterNetEvent("propplacer:client:notify", function(msg, tipo)
    notify(msg, tipo)
end)

RegisterNetEvent("propplacer:client:loadProps", function(serverProps, hiddenCats, colors)
    for _, data in pairs(placedProps) do
        if data.entity and DoesEntityExist(data.entity) then DeleteEntity(data.entity) end
    end
    placedProps      = {}
    hiddenCategories = hiddenCats   or {}
    categoryColors   = colors       or {}
    propsLoaded      = true
    for _, prop in ipairs(serverProps) do
        placedProps[prop.id] = {
            entity   = nil,
            model    = prop.model,
            label    = prop.label or prop.model,
            notes    = prop.notes or "",
            dbId     = prop.id,
            x        = prop.x,     y  = prop.y,  z  = prop.z,
            rx       = prop.rx or 0, ry = prop.ry or 0, rz = prop.rz or 0,
            category = prop.category or 'General',
            locked   = prop.locked or false,
            ghost    = prop.ghost  or false,
            tags     = prop.tags   or "",
        }
    end
    log(("%d props loaded — range:%.0fm tick:%dms"):format(#serverProps, Config.StreamRange, Config.StreamInterval))
end)

local function notifyMenuIfOpen(action, payload)
    if menuOpen then
        payload.action = action
        SendNUIMessage(payload)
    end
end

RegisterNetEvent("propplacer:client:addProp", function(data)
    placedProps[data.id] = {
        entity   = nil,
        model    = data.model,  label    = data.label or data.model,
        notes    = data.notes or "",  dbId     = data.id,
        x        = data.x,     y  = data.y,  z  = data.z,
        rx       = data.rx or 0, ry = data.ry or 0, rz = data.rz or 0,
        category = data.category or 'General',
        locked   = data.locked or false,
        ghost    = data.ghost  or false,
        tags     = data.tags   or "",
    }
    notifyMenuIfOpen("addPlacedProp", { prop = {
        id = data.id, model = data.model, label = data.label or data.model,
        notes = data.notes or "", category = data.category or 'General',
        active = false, locked = false, ghost = data.ghost or false,
        tags = data.tags or "", x = data.x, y = data.y, z = data.z,
    }})
end)

RegisterNetEvent("propplacer:client:removeProp", function(dbId)
    if placedProps[dbId] then
        local ent = placedProps[dbId].entity
        if ent and DoesEntityExist(ent) then
            DeleteEntity(ent)
            log(("REMOVE id=%-6s  model=%s"):format(tostring(dbId), placedProps[dbId].model))
        end
        placedProps[dbId] = nil
    end
end)

RegisterNetEvent("propplacer:client:updateProp", function(data)
    local dbId = data.id
    if not placedProps[dbId] then return end
    local ent = placedProps[dbId].entity
    if ent and DoesEntityExist(ent) then
        SetEntityCoordsNoOffset(ent, data.x, data.y, data.z, false, false, false, false)
        SetEntityRotation(ent, data.rx or 0, data.ry or 0, data.rz or 0, 2, true)
        FreezeEntityPosition(ent, true)
    end
    placedProps[dbId].x  = data.x;  placedProps[dbId].y  = data.y;  placedProps[dbId].z  = data.z
    placedProps[dbId].rx = data.rx; placedProps[dbId].ry = data.ry; placedProps[dbId].rz = data.rz
end)

RegisterNetEvent("propplacer:client:updatePropLabel",    function(dbId, v) if placedProps[dbId] then placedProps[dbId].label    = v end; notifyMenuIfOpen("updatePropLabel",    { id=dbId, label    = v }) end)
RegisterNetEvent("propplacer:client:updatePropNotes",    function(dbId, v) if placedProps[dbId] then placedProps[dbId].notes    = v end; notifyMenuIfOpen("updatePropNotes",    { id=dbId, notes    = v }) end)
RegisterNetEvent("propplacer:client:updatePropTags",     function(dbId, v) if placedProps[dbId] then placedProps[dbId].tags     = v end; notifyMenuIfOpen("updatePropTags",     { id=dbId, tags     = v }) end)
RegisterNetEvent("propplacer:client:updatePropCategory", function(dbId, v) if placedProps[dbId] then placedProps[dbId].category = v end; notifyMenuIfOpen("updatePropCategory", { id=dbId, category = v }) end)

RegisterNetEvent("propplacer:client:updatePropLocked", function(dbId, locked)
    if placedProps[dbId] then placedProps[dbId].locked = locked end
    notifyMenuIfOpen("updatePropLocked", { id = dbId, locked = locked })
end)

RegisterNetEvent("propplacer:client:updatePropGhost", function(dbId, ghost)
    if placedProps[dbId] then
        placedProps[dbId].ghost = ghost
        local ent = placedProps[dbId].entity
        if ent and DoesEntityExist(ent) then
            if ghost then
                SetEntityAlpha(ent, 100, false)
                SetEntityCollision(ent, false, false)
            else
                ResetEntityAlpha(ent)
                SetEntityCollision(ent, true, true)
            end
        end
    end
    notifyMenuIfOpen("updatePropGhost", { id = dbId, ghost = ghost })
end)

RegisterNetEvent("propplacer:client:updateConfig", function(data)
    if data.StreamRange    then Config.StreamRange    = data.StreamRange    end
    if data.StreamInterval then Config.StreamInterval = data.StreamInterval end
    if data.DeleteRadius   then Config.DeleteRadius   = data.DeleteRadius   end
    if data.StreamLogs ~= nil then Config.StreamLogs  = data.StreamLogs     end
    SendNUIMessage({ action = "configUpdated", config = data })
end)

RegisterNetEvent("propplacer:client:setCategoryColor", function(cat, color)
    categoryColors[cat] = color
    notifyMenuIfOpen("setCategoryColor", { category = cat, color = color })
end)

RegisterNetEvent("propplacer:client:allCategoryColors", function(colors)
    categoryColors = colors
    notifyMenuIfOpen("allCategoryColors", { colors = colors })
end)

RegisterNetEvent("propplacer:client:setCategoryVisibility", function(category, hidden)
    hiddenCategories[category] = hidden
    notifyMenuIfOpen("setCategoryVisibility", { category = category, hidden = hidden })
end)

RegisterNetEvent("propplacer:client:onlinePlayers", function(players, savedPerms)
    SendNUIMessage({ action = "onlinePlayers", players = players, savedPerms = savedPerms })
end)

RegisterNetEvent("propplacer:client:exportData",  function(jsonStr)  SendNUIMessage({ action = "exportData",  data      = jsonStr }) end)
RegisterNetEvent("propplacer:client:historyData", function(history)  SendNUIMessage({ action = "historyData", history   = history }) end)
RegisterNetEvent("propplacer:client:templateData",function(tmplList) SendNUIMessage({ action = "templateData",templates = tmplList }) end)
RegisterNetEvent("propplacer:client:backupList",  function(list)     SendNUIMessage({ action = "backupList",  backups   = list    }) end)
RegisterNetEvent("propplacer:client:categoryTour",function(tourList) SendNUIMessage({ action = "categoryTour",list      = tourList }) end)

RegisterNetEvent("propplacer:client:undoStackSize", function(n)
    undoStackSize = n
    notifyMenuIfOpen("undoStackSize", { size = n })
end)

RegisterNUICallback("closeMenu", function(_, cb)
    closeNUI(); cb(true)

    -- ESC: si el panel se abrió desde la pestaña Scripts del admin, se vuelve
    -- a ella. origen_admin solo vuelve si este panel salió de su lista; con
    -- /propplacer, ESC cierra y nada más. Colocar o editar un prop cierra por
    -- otro camino (closeNUI a secas) y no vuelve.
    if GetResourceState("origen_admin") == "started" then
        SetTimeout(80, function()
            pcall(function() exports["origen_admin"]:ReturnToScripts() end)
        end)
    end
end)

RegisterNUICallback("placeProp", function(data, cb)
    if not data.model or data.model == "" then cb(true); notify("Modelo inválido.", "error"); return end
    closeNUI(); cb(true)
    CreateThread(function()
        Wait(150)
        enterPlacementMode(data.model, data.label or data.model, data.category)
    end)
end)

RegisterNUICallback("editPropFromUI", function(data, cb)
    local pd = placedProps[data.id]
    if not pd then cb(true); notify("No se encuentra el objeto.", "error"); return end
    if pd.locked then cb(true); notify("El objeto está bloqueado.", "error"); return end
    if not pd.entity or not DoesEntityExist(pd.entity) then
        cb(true); notify("Acércate al objeto antes de editarlo.", "error"); return
    end
    closeNUI(); cb(true)
    CreateThread(function() Wait(150); editPlacementMode(data.id) end)
end)

RegisterNUICallback("deletePropFromUI",     function(data, cb) cb(true); TriggerServerEvent("propplacer:server:deletePropById",  data.id)       end)
RegisterNUICallback("deleteCategoryFromUI", function(data, cb) cb(true); if data.category then TriggerServerEvent("propplacer:server:deleteCategory", data.category) end end)
RegisterNUICallback("toggleCategoryFromUI", function(data, cb) cb(true); if data.category then TriggerServerEvent("propplacer:server:toggleCategory",  data.category) end end)
RegisterNUICallback("clearAllProps",        function(_, cb)    cb(true); TriggerServerEvent("propplacer:server:clearAll")                        end)

RegisterNUICallback("teleportToProp", function(data, cb)
    closeNUI(); cb(true)
    local pd = placedProps[data.id]
    if pd then
        SetEntityCoords(PlayerPedId(), pd.x, pd.y, pd.z + 1.5, false, false, false, false)
        SetEntityHeading(PlayerPedId(), 0.0)
        notify("Te has llevado al objeto #" .. data.id, "success")
    else notify("No se encuentra el objeto.", "error") end
end)

RegisterNUICallback("markLocation", function(data, cb)
    cb(true)
    local pd = placedProps[data.id]
    if pd then SetNewWaypoint(pd.x, pd.y); notify("Ubicación marcada.", "success")
    else notify("No se encuentra el objeto.", "error") end
end)

RegisterNUICallback("updatePropLabel", function(data, cb)
    cb(true)
    if placedProps[data.id] then placedProps[data.id].label = data.label end
    TriggerServerEvent("propplacer:server:updateLabel", { id = data.id, label = data.label })
end)

RegisterNUICallback("updateNotes", function(data, cb)
    cb(true)
    if placedProps[data.id] then placedProps[data.id].notes = data.notes end
    TriggerServerEvent("propplacer:server:updateNotes", { id = data.id, notes = data.notes })
end)

RegisterNUICallback("updateTags", function(data, cb)
    cb(true)
    if placedProps[data.id] then placedProps[data.id].tags = data.tags end
    TriggerServerEvent("propplacer:server:updateTags", { id = data.id, tags = data.tags })
end)

RegisterNUICallback("toggleLock",  function(data, cb) cb(true); TriggerServerEvent("propplacer:server:toggleLock",  data.id) end)
RegisterNUICallback("toggleGhost", function(data, cb) cb(true); TriggerServerEvent("propplacer:server:toggleGhost", data.id) end)

RegisterNUICallback("undoLastDelete", function(_, cb)
    cb(true); TriggerServerEvent("propplacer:server:undoLastDelete")
end)

RegisterNUICallback("snapToGround", function(data, cb)
    cb(true)
    local pd = placedProps[data.id]
    if pd and pd.entity and DoesEntityExist(pd.entity) then
        PlaceObjectOnGroundProperly(pd.entity)
        Wait(50)
        local pos = GetEntityCoords(pd.entity)
        local rot = GetEntityRotation(pd.entity)
        TriggerServerEvent("propplacer:server:updateProp", {
            id = data.id, x = pos.x, y = pos.y, z = pos.z, rx = rot.x, ry = rot.y, rz = rot.z,
        })
        notify("Objeto pegado al suelo.", "success")
    else notify("El objeto está lejos, acércate primero.", "error") end
end)

RegisterNUICallback("recategorizeProp", function(data, cb)
    cb(true)
    if placedProps[data.id] then placedProps[data.id].category = data.category end
    TriggerServerEvent("propplacer:server:recategorizeProp", data.id, data.category)
end)

RegisterNUICallback("batchDelete",       function(data, cb) cb(true); TriggerServerEvent("propplacer:server:batchDelete",       data.ids)                  end)
RegisterNUICallback("batchRecategorize", function(data, cb) cb(true); TriggerServerEvent("propplacer:server:batchRecategorize", data.ids, data.category)   end)
RegisterNUICallback("duplicateWithOffset",function(data, cb) cb(true); TriggerServerEvent("propplacer:server:duplicateWithOffset", data)                   end)

RegisterNUICallback("moveCategoryOffset", function(data, cb)
    cb(true)
    TriggerServerEvent("propplacer:server:moveCategoryOffset", data.category, data.dx, data.dy, data.dz)
end)

RegisterNUICallback("setCategoryColor", function(data, cb)
    cb(true)
    categoryColors[data.category] = data.color
    TriggerServerEvent("propplacer:server:setCategoryColor", data.category, data.color)
end)

RegisterNUICallback("exportProps", function(data, cb) cb(true); TriggerServerEvent("propplacer:server:exportProps", data.category or "") end)
RegisterNUICallback("importProps", function(data, cb) cb(true); TriggerServerEvent("propplacer:server:importProps", data.json, data.category or "") end)

RegisterNUICallback("createBackup",  function(data, cb) cb(true); TriggerServerEvent("propplacer:server:createBackup",  data.name) end)
RegisterNUICallback("getBackups",    function(_, cb)    cb(true); TriggerServerEvent("propplacer:server:getBackups")               end)
RegisterNUICallback("restoreBackup", function(data, cb) cb(true); TriggerServerEvent("propplacer:server:restoreBackup", data.id)   end)

RegisterNUICallback("getHistory",      function(_, cb)    cb(true); TriggerServerEvent("propplacer:server:getHistory")                                      end)
RegisterNUICallback("getTemplates",    function(_, cb)    cb(true); TriggerServerEvent("propplacer:server:getTemplates")                                     end)
RegisterNUICallback("saveTemplate",    function(data, cb) cb(true); TriggerServerEvent("propplacer:server:saveTemplate",   data)                             end)
RegisterNUICallback("deleteTemplate",  function(data, cb) cb(true); TriggerServerEvent("propplacer:server:deleteTemplate", data.name)                        end)
RegisterNUICallback("getSavedPerms",   function(_, cb)    cb(true); TriggerServerEvent("propplacer:server:getSavedPerms")                                    end)
RegisterNUICallback("grantPermission", function(data, cb) cb(true); TriggerServerEvent("propplacer:server:grantPermission",  data)                           end)
RegisterNUICallback("revokePermission",function(data, cb) cb(true); TriggerServerEvent("propplacer:server:revokePermission", data)                           end)

RegisterNUICallback("startCategoryTour", function(data, cb)
    closeNUI(); cb(true)
    TriggerServerEvent("propplacer:server:getCategoryTour", data.category)
end)

RegisterNUICallback("applyTemplate", function(data, cb)
    closeNUI(); cb(true)
    TriggerServerEvent("propplacer:server:applyTemplate", data.name, nil, nil, nil, data.category or "")
end)

RegisterNUICallback("saveTemplateFromCategory", function(data, cb)
    cb(true)
    local catProps  = {}
    local ox, oy, oz
    for _, pd in pairs(placedProps) do
        if pd.category == data.category then
            if not ox then ox, oy, oz = pd.x, pd.y, pd.z end
            table.insert(catProps, {
                model = pd.model, label = pd.label,
                dx = pd.x - ox, dy = pd.y - oy, dz = pd.z - oz,
                rx = pd.rx or 0, ry = pd.ry or 0, rz = pd.rz or 0,
                category = pd.category,
            })
        end
    end
    if #catProps == 0 then notify("No hay objetos en esta categoría.", "error"); return end
    TriggerServerEvent("propplacer:server:saveTemplate", {
        name = data.name, description = data.description or "", props = catProps,
    })
end)

RegisterNUICallback("hotUpdateConfig", function(data, cb)
    cb(true)
    if data.StreamRange    then Config.StreamRange    = tonumber(data.StreamRange)    end
    if data.StreamInterval then Config.StreamInterval = tonumber(data.StreamInterval) end
    if data.DeleteRadius   then Config.DeleteRadius   = tonumber(data.DeleteRadius)   end
    if data.StreamLogs ~= nil then Config.StreamLogs  = data.StreamLogs end
    TriggerServerEvent("propplacer:server:updateConfig", data)
end)

local tourActive    = false
local tourList      = {}
local tourIdx       = 1
local adminChecked  = false

RegisterNetEvent("propplacer:client:categoryTour", function(list)
    if not list or #list == 0 then
        notify("No hay objetos en esta categoría.", "error")
        restoreMenuFocus()
        return
    end
    tourList   = list
    tourIdx    = 1
    tourActive = true
    SendNUIMessage({ action = "categoryTour", list = list, currentIdx = 1 })
    notify(("Recorrido: %d objetos. /tournext y /tourprev para avanzar y volver"):format(#list), "success")
    SetEntityCoords(PlayerPedId(), tourList[1].x, tourList[1].y, tourList[1].z + 1.5, false, false, false, false)
end)

RegisterCommand("tournext", function()
    if not tourActive or #tourList == 0 then return end
    tourIdx = (tourIdx % #tourList) + 1
    SetEntityCoords(PlayerPedId(), tourList[tourIdx].x, tourList[tourIdx].y, tourList[tourIdx].z + 1.5, false, false, false, false)
    SendNUIMessage({ action = "tourNext", currentIdx = tourIdx })
    notify(("[%d/%d] %s"):format(tourIdx, #tourList, tourList[tourIdx].label), "info")
end, false)

RegisterCommand("tourprev", function()
    if not tourActive or #tourList == 0 then return end
    tourIdx = tourIdx > 1 and (tourIdx - 1) or #tourList
    SetEntityCoords(PlayerPedId(), tourList[tourIdx].x, tourList[tourIdx].y, tourList[tourIdx].z + 1.5, false, false, false, false)
    SendNUIMessage({ action = "tourPrev", currentIdx = tourIdx })
    notify(("[%d/%d] %s"):format(tourIdx, #tourList, tourList[tourIdx].label), "info")
end, false)

RegisterCommand("tourstop", function()
    tourActive = false; tourList = {}; tourIdx = 1
    SendNUIMessage({ action = "tourStop" })
    notify("Recorrido terminado.", "info")
end, false)

RegisterCommand("propplacer", function()
    if menuOpen then return end
    if isAdmin then openMenu()
    else _pendingOpen = true; TriggerServerEvent("propplacer:server:checkAdmin") end
end, false)

-- Export usado por origen_hub (adminRoute = "export")
exports("openManagement", function()
    if menuOpen then return true end
    if isAdmin then
        openMenu()
        return true
    end
    _pendingOpen = true
    TriggerServerEvent("propplacer:server:checkAdmin")
    return true
end)

RegisterCommand("propundo", function()
    if not isAdmin then notify("Sin permisos.", "error"); return end
    TriggerServerEvent("propplacer:server:undoLastDelete")
end, false)

RegisterCommand("deleteprop",    function() if not isAdmin then return end; TriggerServerEvent("propplacer:server:deleteNearest") end, false)
RegisterCommand("clearallprops", function() if not isAdmin then return end; TriggerServerEvent("propplacer:server:clearAll")       end, false)

RegisterCommand("propstream", function()
    if not isAdmin then return end
    local visible, hidden, total = 0, 0, 0
    for _, data in pairs(placedProps) do
        total = total + 1
        if data.entity and DoesEntityExist(data.entity) then visible = visible + 1 else hidden = hidden + 1 end
    end
    print(("^5[PropPlacer]^7 Total:%d | Active:^2%d^7 | Out:^3%d^7 | Range:%.0fm"):format(
        total, visible, hidden, Config.StreamRange))
end, false)

AddEventHandler("onClientResourceStart", function(res)
    if res ~= GetCurrentResourceName() then return end
    Wait(2000)
    TriggerServerEvent("propplacer:server:checkAdmin")
    if not propsLoaded then TriggerServerEvent("propplacer:server:requestProps") end
    startStreamer()
end)

AddEventHandler("playerSpawned", function()
    if not adminChecked then
        TriggerServerEvent("propplacer:server:checkAdmin")
    end
    if not propsLoaded then
        TriggerServerEvent("propplacer:server:requestProps")
    end
end)
