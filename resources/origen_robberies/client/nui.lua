local anims

RegisterNUICallback('getRobs', function(data, cb)
    local anims = anims or exports.origen_anims:getAllAnims()
    
    lib.callback('origen_robberies:getRobberies', false, function(robberies)
        --- Los minijuegos nuevos los cuenta origen_minijuegos: asi el editor
        --- ofrece lo que hay de verdad, con sus dificultades y sus topes.
        local minijuegos = {}
        if GetResourceState('origen_minijuegos') == 'started' then
            local ok, lista = pcall(function() return exports.origen_minijuegos:Catalogo() end)
            if ok and type(lista) == 'table' then minijuegos = lista end
        end

        cb({
            robberies = robberies,
            anims = anims.Emotes,
            minijuegos = minijuegos
        })
    end, true)
end)

RegisterNUICallback('saveRob', function(data, cb)
    if data and data.start then
        if data.start.requiredItem == '' then data.start.requiredItem = nil end
        if data.start.startMinigame and data.start.startMinigame.requiredItem == '' then
            data.start.startMinigame.requiredItem = nil
        end
    end
    if data and data.safe and data.safe.minigame and data.safe.minigame.requiredItem == '' then
        data.safe.minigame.requiredItem = nil
    end
    if data and data.lootPoints then
        for _, lp in pairs(data.lootPoints) do
            if lp.minigame and lp.minigame.requiredItem == '' then
                lp.minigame.requiredItem = nil
            end
        end
    end
    local success, motivo = lib.callback.await('origen_robberies:saveRobbery', false, data)
    if not success and motivo then
        lib.notify({ description = motivo, type = 'error' })
    end
    cb(success)
end)

RegisterNUICallback('deleteRob', function(data, cb)
    local success = lib.callback.await('origen_robberies:removeRobbery', false, data.id)
    cb(success)
end)

function round(num, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

RegisterNUICallback('getCoords', function(data, cb)
    local coords = GetEntityCoords(cache.ped, false)
    local heading = GetEntityHeading(cache.ped)
    coords = {
        x = round(coords.x, 2),
        y = round(coords.y, 2),
        z = round(coords.z, 2),
        w = round(heading, 2)
    }
    cb(coords)
end)

RegisterNUICallback('setRobWaypoint', function(data, cb)
    if data.coords then
        SetNewWaypoint(data.coords.x, data.coords.y)
        cb(true)
    else
        cb(false)
    end
end)

RegisterNUICallback('setRobState', function(data, cb)
    local success = lib.callback.await('origen_robberies:setRobState', false, data.id, data.state)
    cb(success)
end)

RegisterNUICallback('getStats', function(data, cb)
    lib.callback('origen_robberies:getStats', false, function(stats)
        cb(stats)
    end)
end)

RegisterNUICallback('getGangs', function(data, cb)
    local ok, gangs = pcall(function() return exports['origen_ilegalv2']:GetGangs() end)
    if ok and gangs then
        local list = {}
        for _, g in pairs(gangs) do
            table.insert(list, { id = tostring(g.id), label = g.label })
        end
        table.sort(list, function(a, b) return a.label < b.label end)
        cb(list)
    else
        cb({})
    end
end)

RegisterNUICallback('getItems', function(data, cb)
    cb(lib.callback.await('origen_robberies:getItems', false) or {})
end)

RegisterNUICallback('closeAdmin', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('closeMenu', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
    
    if exports['origen_robberies']:IsOpenedFromHub() then
        exports['origen_robberies']:ResetHubFlag()
        exports['origen_admin']:ReturnToScripts()
    end
end)

RegisterNUICallback('startPlacement', function(data, cb)
    if not data then
        cb(false)
        return
    end

    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    --[[ Si Placement.Start revienta a medias (un modelo que no carga, una
         entidad que no se crea), el panel se quedaba en modo colocar y sin
         raton: ni se colocaba nada ni se podia volver. Se deshace y se le
         devuelve el raton al panel, como hace el propio Start al cancelar. ]]
    local ok, err = pcall(Placement.Start, data.objectType, data.model, data.requestId)
    if not ok then
        print('^1[origen_robberies] Placement.Start ha fallado: ' .. tostring(err) .. '^0')
        Placement.active = false
        if Placement.entity and DoesEntityExist(Placement.entity) then
            DeleteEntity(Placement.entity)
        end
        Placement.entity = nil
        SendNUIMessage({ action = 'placementCancelled', requestId = data.requestId })
        SendNUIMessage({ action = 'placementMode', data = { active = false } })
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(false)
    end
    cb(ok)
end)

local openedFromHub = false

-- Exports auxiliares para el flag
exports('IsOpenedFromHub', function() return openedFromHub end)
exports('ResetHubFlag', function() openedFromHub = false end)

-- Export para origen_hub
exports('openManagement', function()
    -- Marcar que fue abierto desde el hub
    openedFromHub = true
    
    CreateThread(function()
        SendNUIMessage({
            action = 'openAdmin'
        })
        
        -- Wait(2800)
        
        SetNuiFocus(true, true)
    end)
end)

RegisterNUICallback('deliverEscape', function(data, cb)
    local robbery = Robberies.get(LocalPlayer.state.activeRobbery)

    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'hideEscapePanel' })

    -- Sin robo en curso (fallo o expiro con el panel abierto) no hay nada
    -- que entregar: robbery seria nil y reventaba aqui.
    if not robbery then return cb('ok') end

    robbery:deliverEscape()
    cb('ok')
end)

RegisterNUICallback('closeEscapePanel', function(data, cb)
    local robbery = Robberies.get(LocalPlayer.state.activeRobbery)
    
    if robbery and robbery.escape and robbery.escape.point then
        robbery.escape.point.busy = false
    end
    
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'hideEscapePanel' })
    cb('ok')
end)

--[[ Si el vigilante suelta el raton a la fuerza (`soltarraton`, o la pagina
     sin nada delante), las pantallas con raton se cierran de verdad: el
     panel del contacto (y su punto vuelve a estar libre para hablar otra vez)
     y el panel de administracion. El reloj del robo no, que va sin raton. ]]
OrigenFoco.AlSoltar(function()
    SendNUIMessage({ action = 'hideEscapePanel' })
    SendNUIMessage({ action = 'closeAdmin' })

    local robbery = LocalPlayer.state.activeRobbery and Robberies.get(LocalPlayer.state.activeRobbery)
    if robbery and robbery.escape and robbery.escape.point then
        robbery.escape.point.busy = false
    end
end)

RegisterNUICallback('teleportToCoords', function(data, cb)
    if data and data.x and data.y and data.z then
        local coords = vector3(data.x, data.y, data.z)
        SetEntityCoords(cache.ped, coords.x, coords.y, coords.z, false, false, false, true)
        cb(true)
    else
        cb(false)
    end
end)

RegisterNUICallback('getPrecincts', function(data, cb)
    lib.callback('origen_robberies:getPrecincts', false, function(precincts)
        cb(precincts or {})
    end)
end)

RegisterNUICallback('savePrecinct', function(data, cb)
    local success = lib.callback.await('origen_robberies:savePrecinct', false, data)
    cb(success)
end)

RegisterNUICallback('deletePrecinct', function(data, cb)
    local success = lib.callback.await('origen_robberies:deletePrecinct', false, data.id)
    cb(success)
end)