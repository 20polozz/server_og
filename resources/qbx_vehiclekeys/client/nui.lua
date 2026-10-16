local config = require 'config.client'
local panelOpen = false
local fobOpen = false
local currentFobVeh = nil
local inputBlockerRunning = false

local function startInputBlocker()
    if inputBlockerRunning then return end
    inputBlockerRunning = true

    CreateThread(function()
        while panelOpen or fobOpen do
            Wait(0)

            -- Keep movement keys working, but block mouse camera + attacks/clicks.
            DisableControlAction(0, 1, true)   -- LOOK_LR
            DisableControlAction(0, 2, true)   -- LOOK_UD
            DisableControlAction(0, 24, true)  -- ATTACK
            DisableControlAction(0, 25, true)  -- AIM
            DisableControlAction(0, 68, true)  -- VEH_ATTACK
            DisableControlAction(0, 69, true)  -- VEH_ATTACK2
            DisableControlAction(0, 70, true)  -- VEH_ATTACK3
            DisableControlAction(0, 91, true)  -- VEH_PASSENGER_AIM
            DisableControlAction(0, 92, true)  -- VEH_PASSENGER_ATTACK
            DisableControlAction(0, 140, true) -- MELEE_ATTACK_LIGHT
            DisableControlAction(0, 141, true) -- MELEE_ATTACK_HEAVY
            DisableControlAction(0, 142, true) -- MELEE_ATTACK_ALTERNATE
            DisableControlAction(0, 257, true) -- ATTACK2
            DisableControlAction(0, 263, true) -- MELEE_ATTACK1
            DisableControlAction(0, 264, true) -- MELEE_ATTACK2

            DisablePlayerFiring(cache.playerId, true)
        end

        inputBlockerRunning = false
    end)
end

function IsFobOpen()
    return fobOpen
end

local function areDoorsOpen(veh)
    if not veh or not DoesEntityExist(veh) then return false end
    for i = 0, 3 do
        if GetVehicleDoorAngleRatio(veh, i) > 0.0 then
            return true
        end
    end
    return false
end

local function isTrunkOpen(veh)
    if not veh or not DoesEntityExist(veh) then return false end
    return GetVehicleDoorAngleRatio(veh, 5) > 0.0
end

local function getVehState(veh)
    if not veh or not DoesEntityExist(veh) then
        return { isLocked = false, engineOn = false, doorsOpen = false, trunkOpen = false }
    end
    return {
        isLocked = GetVehicleDoorLockStatus(veh) == 2,
        engineOn = GetIsVehicleEngineRunning(veh),
        doorsOpen = areDoorsOpen(veh),
        trunkOpen = isTrunkOpen(veh),
    }
end

function OpenFob(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end
    currentFobVeh = vehicle
    fobOpen = true

    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    startInputBlocker()

    local modelHash = GetEntityModel(vehicle)
    local displayName = GetDisplayNameFromVehicleModel(modelHash)
    local label = GetLabelText(displayName)
    if not label or label == 'NULL' then label = displayName end

    local plate = GetVehicleNumberPlateText(vehicle)
    local state = getVehState(vehicle)

    SendNUIMessage({
        action = 'openFob',
        data = {
            netId = VehToNet(vehicle),
            model = label,
            plate = plate,
            isLocked = state.isLocked,
            engineOn = state.engineOn,
            doorsOpen = state.doorsOpen,
            trunkOpen = state.trunkOpen
        }
    })

    CreateThread(function()
        while fobOpen do
            Wait(500)
            if not currentFobVeh or not DoesEntityExist(currentFobVeh) then
                CloseFob()
                break
            end
            local pedCoords = GetEntityCoords(cache.ped)
            local vehCoords = GetEntityCoords(currentFobVeh)
            local maxDist = (config.vehicleMaximumLockingDistance or 5.0) + 3.0
            if #(pedCoords - vehCoords) > maxDist and cache.vehicle ~= currentFobVeh then
                CloseFob()
                break
            end
        end
    end)
end

function CloseFob()
    if not fobOpen then return end
    fobOpen = false
    currentFobVeh = nil
    -- Y al reves: con el panel aun abierto debajo, el foco sigue siendo suyo.
    if not panelOpen then
        SetNuiFocusKeepInput(false)
        SetNuiFocus(false, false)
    end
    SendNUIMessage({
        action = 'closeFob'
    })
end

---@return number?
local function getPreferredVehicleNetId()
    local ped = cache.ped
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle == 0 then
        local coords = GetEntityCoords(ped)
        vehicle = lib.getClosestVehicle(coords, 6.0, true)
    end

    if not vehicle or vehicle == 0 then
        return nil
    end

    return NetworkGetNetworkIdFromEntity(vehicle)
end

local function closePanel()
    if not panelOpen then return end
    panelOpen = false
    -- Con el mando abierto encima, el foco es suyo: soltarlo aqui le dejaba
    -- la llave pintada sin raton.
    if not fobOpen then
        SetNuiFocusKeepInput(false)
        SetNuiFocus(false, false)
    end
    SendNUIMessage({
        action = 'close'
    })
end

local function getVehicleName(modelHash)
    local name = GetDisplayNameFromVehicleModel(modelHash)
    local label = GetLabelText(name)
    if not label or label == 'NULL' then label = name end
    return label
end

local function refreshPanelData()
    local panelData = lib.callback.await('qbx_vehiclekeys:server:getPanelData', false, getPreferredVehicleNetId())
    
    if panelData then
        if panelData.vehicle and panelData.vehicle.model then
            panelData.vehicle.model = getVehicleName(panelData.vehicle.model)
        end

        if panelData.ownedKeys then
            for i = 1, #panelData.ownedKeys do
                local keyData = panelData.ownedKeys[i]
                if keyData.model then
                    keyData.model = getVehicleName(keyData.model)
                end
            end
        end
    end

    SendNUIMessage({
        action = 'setData',
        data = panelData or {
            success = false,
            message = locale('notify.vehicle_not_near')
        }
    })
end

local function openPanel()
    if panelOpen then
        refreshPanelData()
        return
    end

    panelOpen = true
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    startInputBlocker()
    SendNUIMessage({
        action = 'open'
    })
    refreshPanelData()
end

-- RegisterCommand('keypanel', function()
--     openPanel()
-- end, false)

--[[ ── Las llaves viven ahora en el inventario ─────────────────────────────
     Este panel --el negro de aqui abajo-- se quedo sin sitio: las llaves son
     la pestaña Llaves del riel del inventario, que se abre estes donde estes y
     enseña ademas lo prestado y lo recibido.

     La K se conserva porque la gente la tiene en los dedos, pero ya no abre
     esta ventana: lleva al inventario por esa pestaña. Si el inventario no
     esta en marcha, se cae al panel viejo en vez de no hacer nada. ]]
local function abrirLlaves()
    if GetResourceState('origen_inventory') == 'started' then
        local ok = pcall(function()
            exports['origen_inventory']:AbrirEnPestana('keys')
        end)
        if ok then return end
    end

    openPanel()
end

lib.addKeybind({
    name = 'qbx_vehiclekeys_openpanel',
    description = 'Abrir panel de llaves',
    defaultKey = 'K',
    onPressed = abrirLlaves
})

exports('openManagement', abrirLlaves)

RegisterNUICallback('close', function(_, cb)
    closePanel()
    cb({ ok = true })
end)

RegisterNUICallback('refresh', function(_, cb)
    refreshPanelData()
    cb({ ok = true })
end)

RegisterNUICallback('giveKeys', function(data, cb)
    local targetId = tonumber(data and data.targetId)
    local netId = tonumber(data and data.netId) or getPreferredVehicleNetId()

    if not targetId or not netId then
        cb({
            success = false,
            message = locale('notify.not_near')
        })
        return
    end

    local result = lib.callback.await('qbx_vehiclekeys:server:transferKeysToPlayer', false, netId, targetId)
    if result and result.success then
        refreshPanelData()
    end

    cb(result or {
        success = false,
        message = locale('notify.not_near')
    })
end)

RegisterNetEvent('qbx_vehiclekeys:client:openPanel', abrirLlaves)

RegisterNuiCallback('toggleSearchFocus', function(data, cb)
    -- El blur del buscador llega después de cerrar; con el panel cerrado no se toca el foco
    if not panelOpen then return cb('ok') end
    SetNuiFocusKeepInput(not data.focus)
    cb('ok')
end)

RegisterNUICallback('getLentKeys', function(_, cb)
    local keys = lib.callback.await('origen_garages:cb:getLentKeys', false) or {}
    for i=1, #keys do
        if keys[i].modelHash and (not keys[i].vehicleLabel or keys[i].vehicleLabel == "Vehículo") then
            local displayName = GetDisplayNameFromVehicleModel(keys[i].modelHash)
            if displayName and displayName ~= "CARNOTFOUND" then
                local label = GetLabelText(displayName)
                keys[i].vehicleLabel = (label and label ~= "NULL") and label or displayName
            end
        end
    end
    cb(keys)
end)

RegisterNUICallback('getBorrowedKeys', function(_, cb)
    local keys = lib.callback.await('origen_garages:cb:getBorrowedKeys', false) or {}
    for i=1, #keys do
        if keys[i].modelHash and (not keys[i].vehicleLabel or keys[i].vehicleLabel == "Vehículo") then
            local displayName = GetDisplayNameFromVehicleModel(keys[i].modelHash)
            if displayName and displayName ~= "CARNOTFOUND" then
                local label = GetLabelText(displayName)
                keys[i].vehicleLabel = (label and label ~= "NULL") and label or displayName
            end
        end
    end
    cb(keys)
end)

RegisterNUICallback('revokeKey', function(data, cb)
    if not data or not data.plate or not data.targetCitizen then
        cb({ success = false, message = "Datos incompletos" })
        return
    end
    local success, msg = lib.callback.await('origen_garages:cb:revokeKeyRemotely', false, data.plate, data.targetCitizen)
    cb({ success = success, message = msg })
end)

RegisterNUICallback('returnKey', function(data, cb)
    if not data or not data.plate then
        cb({ success = false, message = "Datos incompletos" })
        return
    end
    local success, msg = lib.callback.await('origen_garages:cb:returnKeyRemotely', false, data.plate)
    cb({ success = success, message = msg })
end)

RegisterNUICallback('closeFob', function(_, cb)
    CloseFob()
    cb('ok')
end)

RegisterNUICallback('fobAction', function(data, cb)
    if not currentFobVeh or not DoesEntityExist(currentFobVeh) then
        CloseFob()
        return cb({ success = false, message = 'Vehículo no encontrado' })
    end

    local veh = currentFobVeh

    if not GetIsVehicleAccessible(veh) then
        CloseFob()
        exports.qbx_core:Notify(locale('notify.no_keys'), 'error')
        return cb({ success = false, message = locale('notify.no_keys') })
    end

    local action = data and data.action

    if action == 'toggleLock' then
        ToggleLock(veh)
    elseif action == 'toggleEngine' then
        NetworkRequestControlOfEntity(veh)
        local engineRunning = GetIsVehicleEngineRunning(veh)
        lib.playAnim(cache.ped, 'anim@mp_player_intmenu@key_fob@', 'fob_click', 3.0, 3.0, -1, 49)
        qbx.playAudio({ audioName = 'Remote_Control_Fob', audioRef = 'PI_Menu_Sounds', source = veh })

        if engineRunning then
            SetVehicleEngineOn(veh, false, true, true)
            exports.qbx_core:Notify('Motor apagado', 'success')
        else
            SetVehicleEngineOn(veh, true, true, false)
            SetVehicleKeepEngineOnWhenAbandoned(veh, true)
            exports.qbx_core:Notify('Motor encendido', 'success')
        end
        SetTimeout(400, function()
            ClearPedTasks(cache.ped)
        end)
    elseif action == 'toggleDoors' then
        NetworkRequestControlOfEntity(veh)
        lib.playAnim(cache.ped, 'anim@mp_player_intmenu@key_fob@', 'fob_click', 3.0, 3.0, -1, 49)
        qbx.playAudio({ audioName = 'Remote_Control_Fob', audioRef = 'PI_Menu_Sounds', source = veh })

        local doorsOpen = areDoorsOpen(veh)
        if doorsOpen then
            for i = 0, 3 do
                SetVehicleDoorShut(veh, i, false)
            end
            exports.qbx_core:Notify('Puertas cerradas', 'success')
        else
            if GetVehicleDoorLockStatus(veh) == 2 then
                SetVehicleDoorsLocked(veh, 1)
                Entity(veh).state:set('doorslockstate', 1, true)
                TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(veh), 1)
            end
            for i = 0, 3 do
                SetVehicleDoorOpen(veh, i, false, false)
            end
            exports.qbx_core:Notify('Puertas abiertas', 'success')
        end
        SetTimeout(400, function()
            ClearPedTasks(cache.ped)
        end)
    elseif action == 'toggleTrunk' then
        NetworkRequestControlOfEntity(veh)
        lib.playAnim(cache.ped, 'anim@mp_player_intmenu@key_fob@', 'fob_click', 3.0, 3.0, -1, 49)
        qbx.playAudio({ audioName = 'Remote_Control_Fob', audioRef = 'PI_Menu_Sounds', source = veh })

        local trunkOpen = isTrunkOpen(veh)
        if trunkOpen then
            SetVehicleDoorShut(veh, 5, false)
            exports.qbx_core:Notify('Maletero cerrado', 'success')
        else
            if GetVehicleDoorLockStatus(veh) == 2 then
                SetVehicleDoorsLocked(veh, 1)
                Entity(veh).state:set('doorslockstate', 1, true)
                TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', NetworkGetNetworkIdFromEntity(veh), 1)
            end
            SetVehicleDoorOpen(veh, 5, false, false)
            exports.qbx_core:Notify('Maletero abierto', 'success')
        end
        SetTimeout(400, function()
            ClearPedTasks(cache.ped)
        end)
    elseif action == 'close' then
        CloseFob()
        return cb({ success = true })
    end

    Wait(150)
    local state = getVehState(veh)
    cb({
        success = true,
        isLocked = state.isLocked,
        engineOn = state.engineOn,
        doorsOpen = state.doorsOpen,
        trunkOpen = state.trunkOpen
    })
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if not panelOpen and not fobOpen then return end
    -- Las teclas antes que el foco (ORDEN_AL_SOLTAR en foco.lua).
    SetNuiFocusKeepInput(false)
    SetNuiFocus(false, false)
end)

if OrigenFoco and OrigenFoco.AlSoltar then
    OrigenFoco.AlSoltar(function()
        panelOpen = false
        fobOpen = false
        currentFobVeh = nil
        SendNUIMessage({ action = 'close' })
        SendNUIMessage({ action = 'closeFob' })
    end)
end