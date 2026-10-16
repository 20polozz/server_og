RegisterNUICallback('closeGarage', function(_, cb)
    
    
    SetNuiFocus(false, false)
    -- Los muebles encienden KeepInput al colocar; si se sale por aqui a medio
    -- mover, sin esto el juego seguia leyendo el teclado con el cursor fuera.
    SetNuiFocusKeepInput(false)
    cb(true)

    -- Y si el modo muebles seguia activo, su hilo pintaba el cursor cada frame.
    if Furniture.active then Furniture:CloseFurniture() end

    -- Si fue abierto desde el hub, volver al hub con pantalla de carga
    if exports['origen_garages']:IsOpenedFromHub() then
        
        exports['origen_garages']:ResetHubFlag()
        exports['origen_admin']:ReturnToScripts()
    else
        
    end
end)

RegisterNUICallback('takeOutVehicle', function(data, cb)
    SetNuiFocus(false, false)
    if not data.external then
        local result, msg = lib.callback.await('origen_garages:cb:takeOutVehicle', false, {
            plate = data.plate,
            spawner = data.spawner,
            garage = data.garage
        })

        if not result then
            Custom.Notify(msg, 'error')
            cb(false)
            return
        end
        
        local model = data.spawner and data.spawner or result.vehicle.mods.model
        
        if not IsModelValid(model) then
            Custom.Notify(locale('invalid_model'), 'error')
            cb(false)
            return
        end

        DoScreenFadeOut(500)
        while not IsScreenFadedOut() do Wait(0) end

        lib.requestModel(model)
        local veh = CreateVehicle(model, result.spawn.x, result.spawn.y, result.spawn.z, result.spawn.w, true, true)
        SetEntityAsMissionEntity(veh, true, true)
        SetVehicleHasBeenOwnedByPlayer(veh, true)
        local plate = data.spawner and GetVehicleNumberPlateText(veh) or data.plate

        local netId = NetworkGetNetworkIdFromEntity(veh)
        SetNetworkIdExistsOnAllMachines(netId, true)
        TriggerServerEvent('origen_garages:server:SyncVehicleBucket', netId, result.vehicle and result.vehicle.owner)


        Internal.GiveVehicleKeys(VehToNet(veh), plate)
        if not data.spawner then
            lib.setVehicleProperties(veh, result.vehicle.mods)
            cGarage.Utils.applyVehicleDamage(veh, result.vehicle.mods)
            if Custom.SetFuel then
                Custom.SetFuel(veh, result.vehicle.mods.fuelLevel)
            end
            if result.vehicle.mods.harness then
                Entity(veh).state:set('harness', true, true)
            end
        end
        if data.spawner then Entity(veh).state['spawner'] = data.garage end
        SetVehicleOnGroundProperly(veh)
        SetVehicleDoorsLocked(veh, 1)
        TaskWarpPedIntoVehicle(cache.ped, veh, -1)
        SetModelAsNoLongerNeeded(model)
        TriggerEvent('vehiclekeys:client:SetOwner', GetVehicleNumberPlateText(veh))
        DoScreenFadeIn(500)
        while not IsScreenFadedIn() do Wait(0) end
        cb(true)
    else
        local result, msg = lib.callback.await('origen_garages:cb:takeOutExternal', false, {
            plate = data.plate,
            garage = data.garage
        })

        if not result then
            Custom.Notify(msg, 'error')
            cb(false)
            return
        end

        DoScreenFadeOut(500)
        while not IsScreenFadedOut() do Wait(0) end

        local model = result.vehicle.mods.model
        local externalCoords = data.external or {}
        local spawnX = tonumber(externalCoords.x) or 0.0
        local spawnY = tonumber(externalCoords.y) or 0.0
        local spawnZ = tonumber(externalCoords.z) or 0.0
        local spawnW = tonumber(externalCoords.w) or 0.0
        spawnW = math.floor(spawnW * 100) / 100
        lib.requestModel(model)
        local veh = CreateVehicle(model, spawnX, spawnY, spawnZ, spawnW, true, true)
        SetEntityHeading(veh, spawnW)
        SetEntityAsMissionEntity(veh, true, true)
        SetVehicleHasBeenOwnedByPlayer(veh, true)

        local netId = NetworkGetNetworkIdFromEntity(veh)
        SetNetworkIdExistsOnAllMachines(netId, true)
        TriggerServerEvent('origen_garages:server:SyncVehicleBucket', netId, result.vehicle and result.vehicle.owner)


        Internal.GiveVehicleKeys(VehToNet(veh), data.plate)
        lib.setVehicleProperties(veh, result.vehicle.mods)
        cGarage.Utils.applyVehicleDamage(veh, result.vehicle.mods)

        if Custom.SetFuel then
            Custom.SetFuel(veh, result.vehicle.mods.fuelLevel)
        end

        if result.vehicle.mods.harness then
            Entity(veh).state:set('harness', true, true)
        end

        SetVehicleOnGroundProperly(veh)
        SetVehicleDoorsLocked(veh, 1)
        TaskWarpPedIntoVehicle(cache.ped, veh, -1)
        SetModelAsNoLongerNeeded(model)
        TriggerEvent('vehiclekeys:client:SetOwner', GetVehicleNumberPlateText(veh))
        DoScreenFadeIn(500)
        while not IsScreenFadedIn() do Wait(0) end
        cb(true)
    end
end)

RegisterNUICallback('renameVehicle', function(data, cb)
    -- await no lleva funcion de vuelta (el segundo argumento es la espera):
    -- con la funcion ahi, cb no se llamaba nunca y la peticion se quedaba
    -- colgada en la NUI.
    local success = lib.callback.await('origen_garages:cb:renameVehicle', false, data.plate, data.newLabel)
    cb(success)
end)


RegisterNUICallback('getLocales', function(data, cb)
    cb(getLocale('nui'))
end)

RegisterNUICallback('useRaycast', function(data, cb)
    SetNuiFocus(false, false)
    local model = data.model or data.type == 'vehicle' and 'sultan' or 'player_one'
    -- Con pcall: si peta (un modelo que no existe, lib.requestModel que se
    -- cansa de esperar) la NUI se quedaba esperando la respuesta con la
    -- interfaz escondida y sin raton. Asi responde nil y el panel vuelve.
    local ok, coords = pcall(entityPositioning, data.type, model)
    if not ok then
        print(('[origen_garages] useRaycast: %s'):format(coords))
        coords = nil
        SetPedConfigFlag(cache.ped, 122, false)
        lib.hideTextUI()
    end

    SetNuiFocus(true, true)
    if coords then
        local coordsTable = {
            x = math.floor(coords.x * 100) / 100,
            y = math.floor(coords.y * 100) / 100,
            z = math.floor(coords.z * 100) / 100,
            w = math.floor(coords.w * 100) / 100
        }
        cb(coordsTable)
    else
        cb(nil)
    end
end)

RegisterNUICallback('updateGarage', function(data,cb)
    local response = lib.callback.await('origen_garages:cb:editGarage', false, data)
    cb(response)
end)

RegisterNUICallback('deleteGarage', function(data, cb)
    local response = lib.callback.await('origen_garages:cb:deleteGarage', false, data)
    cb(response)
end)

RegisterNUICallback('showVehicleInfo', function(data, cb)
    -- Una sola a la vez: dos peticiones seguidas (la I pulsada dos veces
    -- durante el fundido) creaban dos camaras y dos coches, y la segunda
    -- camara se quedaba puesta al salir de la primera.
    if inspeccionando then return cb(false) end
    inspeccionando = true

    -- La NUI ya se ha escondido al pedir esto. Cualquier salida que no acabe
    -- en la camara tiene que devolverle la interfaz y el raton: si no, el
    -- garaje se quedaba invisible (o la pantalla en negro) y sin salida.
    local function volverAlGaraje()
        inspeccionando = false
        SendNUIMessage({ action = 'showInterface' })
        SetNuiFocus(true, true)
    end

    -- El modelo se mira ANTES del fundido: lib.requestModel peta con uno que
    -- ya no existe, y con la pantalla en negro no habia vuelta atras.
    local vData = lib.callback.await('origen_garages:cb:getVehicle', false, data.plate)
    local model = vData and vData.mods and vData.mods.model
    if not model or not IsModelValid(model) then
        Custom.Notify(locale('invalid_model'), 'error')
        volverAlGaraje()
        cb(false)
        return
    end

    SetNuiFocus(false, false)
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do
        Wait(0)
    end

    local ok, err = pcall(function()
        inspectCar(data.plate, cGarage.Get(data.garage).spawnPoints[1], vData)
    end)
    if not ok then
        print(('[origen_garages] showVehicleInfo: %s'):format(err))
        if inspectVeh and DoesEntityExist(inspectVeh) then DeleteVehicle(inspectVeh) end
        inspectVeh = nil
        DoScreenFadeIn(500)
        volverAlGaraje()
        cb(false)
        return
    end

    DoScreenFadeIn(500)
    cb(true)
end)

RegisterNUICallback('exitVehicleView', function(data, cb)
    local response = lib.callback.await('origen_garages:cb:exitVehicleView', false, data.netId, data.bucket)
    cb(response)
end)

RegisterNUICallback('addGarage', function(data, cb)
    local response = lib.callback.await('origen_garages:cb:addGarage', false, data)
    cb(response)
end)

RegisterNUICallback('editVehicle', function(data, cb)
    local response = lib.callback.await('origen_garages:cb:editVehicle', false, data)
    cb(response)
end)

RegisterNUICallback('searchVehicle', function(plate, cb)
    local response = lib.callback.await('origen_garages:cb:searchVehicle', false, plate, false, true)
    if response then
        response.mods = json.decode(response.mods)
        response.model = GetDisplayNameFromVehicleModel(response.mods.model)
        response.photo = cGarage.Utils.photoOf(response.mods.model)
        response.mods = nil
        cb(response)
    else
        cb(nil)
    end
end)

RegisterNUICallback('getGarageVehicles', function(data, cb)
    local response = lib.callback.await('origen_garages:cb:searchVehicle', false, false, data.name, false)

    for _, vehicle in pairs(response) do
        vehicle.mods = json.decode(vehicle.mods)
        vehicle.model = GetDisplayNameFromVehicleModel(vehicle.mods.model)
        vehicle.photo = cGarage.Utils.photoOf(vehicle.mods.model)
        vehicle.mods = nil
    end
    
    cb(response)
end)



-- Estos tres no contestaban nunca: la peticion se quedaba colgada en la
-- NUI y, amontonadas, las siguientes (el `closeGarage` tambien) no llegaban.
RegisterNUICallback('confirmGaragePurchase', function(data, cb)
    cb('ok')
    SetNuiFocus(false, false)
    local canBuy = lib.callback.await('origen_garages:cb:buyGarage', false, data.garage)
    if not canBuy then
        Custom.Notify(locale('garages_cant_buy'), 'error', 5000)
        return
    end
    Custom.Notify(locale('garages_success_buy'), 'success', 5000)
end)

RegisterNUICallback('SetNuiFocus', function(focus, cb)
    SetNuiFocus(focus, focus)
    -- Nunca debe quedar KeepInput encendido de una colocacion de muebles.
    SetNuiFocusKeepInput(false)
    cb('ok')
end)

RegisterNUICallback('addHolder', function(data, cb)
    local response = lib.callback.await('origen_garages:cb:addHolder', false, {
        id = LocalPlayer.state.interiorId,
        identifier = data
    })
    if response then
        Custom.Notify(locale('garages_success_add_holder'), 'success', 5000)
        cb(response)
    else
        Custom.Notify(locale('garages_cant_add_holder'), 'error', 5000)
        cb(false)
    end
end)

RegisterNUICallback('removeHolder', function(data, cb)
    local response = lib.callback.await('origen_garages:cb:removeHolder', false, {
        id = LocalPlayer.state.interiorId,
        identifier = data
    })
    if response then
        Custom.Notify(locale('garages_success_remove_holder'), 'success', 5000)
        cb(response)
    else
        Custom.Notify(locale('garages_cant_remove_holder'), 'error', 5000)
        cb(false)
    end
end)

RegisterNUICallback('setIgnoreGarageId', function(data, cb)
    TriggerServerEvent('origen_garages:setIgnoreGarageId', data.ignore)
    cb('ok')
end)

local function openManagementMenu(delayFocus)
    local response = lib.callback.await('origen_garages:cb:hasAdminPerms', false)
    if not response.hasPerms then return false end

    local garages = lib.callback.await('origen_garages:cb:getGarages', false)
    local newGarages = {}

    for _, garage in ipairs(garages) do
        
        if not garage.temporary then
            garage.location = GetLabelText(GetNameOfZone(garage.ped.coords.x, garage.ped.coords.y, garage.ped.coords.z))
            table.insert(newGarages, garage)
        end
    end

    SendNUIMessage({
        action = 'openAdminGarages',
        data = {
            garages = newGarages,
            interiors = Config.Interiors,
            ignoreGarageId = response.ignoreGarageId,
        }
    })
    
    -- Solo activar focus si no se especifica delayFocus
    if not delayFocus then
        SetNuiFocus(true, true)
    end
    
    return true
end

RegisterCommand(Config.OpenAdministrationMenu, function(source, args, rawCommand)
    openManagementMenu()
end)

-- Variable para rastrear si fue abierto desde el hub
local openedFromHub = false

-- Exports auxiliares para el flag
exports('IsOpenedFromHub', function() return openedFromHub end)
exports('ResetHubFlag', function() openedFromHub = false end)

-- Export para el hub de Origen
exports('openManagement', function()
    -- Marcar que fue abierto desde el hub
    openedFromHub = true
    
    CreateThread(function()
        -- Abrir el panel pero SIN activar el focus todavía
        local success = openManagementMenu(true)  -- true = delayFocus
        
        if success then
            -- Esperar 300 milisegundos
            Wait(300)
            -- AHORA activar el focus
            SetNuiFocus(true, true)
        else
            openedFromHub = false
        end
    end)
end)

RegisterNUICallback('teleportToGarage', function(data, cb)
    SetNuiFocus(false, false)
    if data and data.coords then
        local ped = cache.ped
        DoScreenFadeOut(500)
        while not IsScreenFadedOut() do Wait(0) end
        
        SetEntityCoords(ped, data.coords.x, data.coords.y, data.coords.z, false, false, false, true)
        if data.coords.w then
            SetEntityHeading(ped, data.coords.w)
        end
        
        Wait(500)
        DoScreenFadeIn(500)
    end
    cb(true)
end)

RegisterCommand('vestirgaraje', function()
    local hasAdmin = lib.callback.await('origen_garages:cb:hasAdminPerms', false)
    if not hasAdmin then
        Custom.Notify("No tienes permisos de administrador", 'error')
        return
    end

    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local closestGarage = nil
    local closestDist = 5.0

    for id, garage in pairs(cGarage.Table) do
        if garage.ped and DoesEntityExist(garage.ped) then
            local pedCoords = GetEntityCoords(garage.ped)
            local dist = #(playerCoords - pedCoords)
            if dist < closestDist then
                closestDist = dist
                closestGarage = garage
            end
        end
    end

    if not closestGarage then
        Custom.Notify("No hay ningún NPC de garaje cerca", 'error')
        return
    end

    local model = GetEntityModel(closestGarage.ped)
    if model ~= GetHashKey("mp_m_freemode_01") and model ~= GetHashKey("mp_f_freemode_01") then
        Custom.Notify("El NPC de garaje debe usar el modelo mp_m_freemode_01 o mp_f_freemode_01", 'error')
        return
    end

    local heading = GetEntityHeading(closestGarage.ped)
    Custom.Notify("Abriendo menú de ropa...", 'success')
    
    local clothing = exports['origen_clothing']:startPedCreation(true, 0, closestGarage.ped, true)
    if clothing then
        SetEntityHeading(closestGarage.ped, heading)
        local safeSkin = {}
        for key, value in pairs(clothing) do
            if key ~= "model" and key ~= "modelHash" then
                safeSkin[key] = value
            end
        end
        TriggerServerEvent('origen_garages:server:updatePedSkin', closestGarage.id, safeSkin)
        Custom.Notify("Ropa del NPC guardada y sincronizada correctamente", 'success')
    else
        Custom.Notify("Modificación cancelada", 'error')
    end
end)

RegisterNUICallback('changeNPCOutfit', function(data, cb)
    SetNuiFocus(false, false)
    
    CreateThread(function()
        local garageId = tostring(data.id)
        local garage = cGarage.Get(garageId)
        if not garage or not garage.ped or not DoesEntityExist(garage.ped) then
            Custom.Notify("No se pudo encontrar al NPC de este garaje en el juego", 'error')
            Wait(500)
            SendNUIMessage({ action = 'showInterface' })
            SetNuiFocus(true, true)
            return
        end

        local model = GetEntityModel(garage.ped)
        if model ~= GetHashKey("mp_m_freemode_01") and model ~= GetHashKey("mp_f_freemode_01") then
            Custom.Notify("El NPC de garaje debe usar el modelo mp_m_freemode_01 o mp_f_freemode_01", 'error')
            Wait(500)
            SendNUIMessage({ action = 'showInterface' })
            SetNuiFocus(true, true)
            return
        end

        local heading = GetEntityHeading(garage.ped)
        Custom.Notify("Abriendo menú de ropa...", 'success')
        
        -- Con pcall: si origen_clothing no esta arrancado o peta, el hilo moria
        -- aqui y el panel se quedaba escondido para siempre. Asi cuenta como
        -- cancelado y se vuelve al panel como siempre.
        local ok, clothing = pcall(function()
            return exports['origen_clothing']:startPedCreation(true, 0, garage.ped, true)
        end)
        if not ok then
            print(('[origen_garages] changeNPCOutfit: %s'):format(clothing))
            clothing = nil
        end
        if clothing then
            SetEntityHeading(garage.ped, heading)
            local safeSkin = {}
            for key, value in pairs(clothing) do
                if key ~= "model" and key ~= "modelHash" then
                    safeSkin[key] = value
                end
            end
            TriggerServerEvent('origen_garages:server:updatePedSkin', garage.id, safeSkin)
            Custom.Notify("Ropa del NPC guardada y sincronizada correctamente", 'success')
        else
            Custom.Notify("Modificación cancelada", 'error')
        end
        
        Wait(500)
        SendNUIMessage({ action = 'showInterface' })
        SetNuiFocus(true, true)
    end)
    cb(true)
end)


