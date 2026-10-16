local QBCore = exports['qbx_core']
local activeMenu = false
local currentVehicle = 0

-- Cache: only call ForceVehicleEngineAudio when the sound name actually changes
local forcedSounds = {}

local function ApplyEngineSound(veh, soundName)
    if not DoesEntityExist(veh) then return end
    soundName = soundName or ""
    if forcedSounds[veh] == soundName then return end
    forcedSounds[veh] = soundName
    ForceVehicleEngineAudio(veh, soundName)
end

local function GetModelName(veh)
    return string.lower(GetDisplayNameFromVehicleModel(GetEntityModel(veh)))
end

local function GetVehicleLabel(model)
    local name  = GetDisplayNameFromVehicleModel(model)
    local label = GetLabelText(name)
    return (label == "CARNOTFOUND") and name or label
end

-- Nombre del modelo en minúsculas por hash: no cambia, no hace falta pedirlo en cada vuelta
local modelNameByHash = {}

-- ── Scope monitor: apply model sound settings from GlobalState every 2s ──
CreateThread(function()
    while true do
        local modelSounds = GlobalState.ModelSounds or {}

        for _, veh in ipairs(GetGamePool('CVehicle')) do
            if DoesEntityExist(veh) then
                local hash      = GetEntityModel(veh)
                local modelName = modelNameByHash[hash]
                if not modelName then
                    modelName = string.lower(GetDisplayNameFromVehicleModel(hash))
                    modelNameByHash[hash] = modelName
                end
                local data      = modelSounds[modelName]

                if data then
                    ApplyEngineSound(veh, data.sound or "")
                else
                    ApplyEngineSound(veh, "")
                end
            end
        end

        Wait(2000)
    end
end)

-- ── Cleanup deleted vehicles from caches ──
CreateThread(function()
    while true do
        for veh in pairs(forcedSounds) do
            if not DoesEntityExist(veh) then forcedSounds[veh] = nil end
        end
        Wait(10000)
    end
end)

--[[ Volver a la pestaña Scripts del panel de admin. Lo hace ESC al cerrar, y
     tambien cuando el menu no llega a abrirse (sin coche, sin permiso): el
     admin ya se aparto y el jugador se quedaria sin nada delante.
     origen_admin solo vuelve si este panel salio de su lista; con el comando
     no hace nada. ]]
local function VolverAScripts()
    if GetResourceState('origen_admin') ~= 'started' then return end
    SetTimeout(80, function()
        pcall(function() exports['origen_admin']:ReturnToScripts() end)
    end)
end

-- ── Open UI ──
local function OpenSoundsMenu()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    --[[ A pie el panel se abre igual y lo dice dentro (06/10): antes avisaba con
         una notificacion que el propio admin tapaba y parecia que no abria. ]]
    local sinCoche = veh == 0 or GetPedInVehicleSeat(veh, -1) ~= ped

    -- Verificar permisos en el servidor antes de abrir el menú
    lib.callback('origen_vehiclesounds:server:checkPermission', false, function(hasPermission)
        if not hasPermission then
            exports.qbx_core:Notify('No tienes permisos para usar este comando', 'error')
            VolverAScripts()
            return
        end

        currentVehicle = sinCoche and 0 or veh
        local data = {}
        if not sinCoche then
            local modelSounds = GlobalState.ModelSounds or {}
            data = modelSounds[GetModelName(veh)] or {}
        end

        activeMenu = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'openMenu',
            data = {
                sinCoche     = sinCoche,
                vehicleName  = (not sinCoche) and GetVehicleLabel(GetEntityModel(veh)) or nil,
                currentSound = data.sound or "",
                sounds       = Config.Sounds,
                categories   = Config.Categories,
            }
        })
    end)
end

RegisterCommand(Config.MenuCommand, OpenSoundsMenu, false)
exports('OpenSoundsMenu', OpenSoundsMenu)
exports('openManagement', OpenSoundsMenu) -- Required by origen_hub

-- Allow the admin hub (origen_admin) to trigger this menu remotely
RegisterNUICallback('OpenSoundsHub', function(data, cb)
    cb('ok')
    OpenSoundsMenu()
end)

-- ── NUI: preview sound (local, not saved) ──
RegisterNUICallback('previewSound', function(data, cb)
    cb('ok')
    if currentVehicle ~= 0 and DoesEntityExist(currentVehicle) then
        forcedSounds[currentVehicle] = data.audioName
        ForceVehicleEngineAudio(currentVehicle, data.audioName)
    end
end)

-- ── NUI: cancel preview → restore saved sound ──
RegisterNUICallback('resetPreview', function(data, cb)
    cb('ok')
    if currentVehicle ~= 0 and DoesEntityExist(currentVehicle) then
        local modelName   = GetModelName(currentVehicle)
        local modelSounds = GlobalState.ModelSounds or {}
        local saved       = (modelSounds[modelName] or {}).sound or ""
        forcedSounds[currentVehicle] = saved
        ForceVehicleEngineAudio(currentVehicle, saved)
    end
end)

-- ── NUI: save sound for this model (server-wide) ──
RegisterNUICallback('saveVehicleSoundChanges', function(data, cb)
    if currentVehicle == 0 or not DoesEntityExist(currentVehicle) then cb(false) return end

    local audioName = data.audioName or ""
    local modelName = GetModelName(currentVehicle)
    -- El nombre que se lee (la etiqueta del juego); si no la hay, el del modelo
    -- con solo la primera en mayúscula: «Zentorno», no «ZENTORNO».
    local hash = GetEntityModel(currentVehicle)
    local etiqueta = GetVehicleLabel(hash)
    if not etiqueta or etiqueta == '' or etiqueta == 'NULL' or etiqueta == GetDisplayNameFromVehicleModel(hash) then
        etiqueta = modelName:sub(1, 1):upper() .. modelName:sub(2)
    end

    lib.callback('origen_vehiclesounds:server:saveModelChanges', false, function(ok)
        if ok then
            exports.qbx_core:Notify(('Sonido guardado para todos los %s del servidor.'):format(etiqueta), 'success')
        end
        cb(ok)
    end, modelName, audioName)
end)

-- ── NUI: restore original (remove model entry) ──
RegisterNUICallback('restoreOriginalSound', function(data, cb)
    if currentVehicle == 0 or not DoesEntityExist(currentVehicle) then cb(false) return end

    local modelName = GetModelName(currentVehicle)
    lib.callback('origen_vehiclesounds:server:restoreModelSound', false, function(ok)
        if ok then
            exports.qbx_core:Notify('Sonido original restaurado para este modelo.', 'success')
        end
        cb(ok)
    end, modelName)
end)

-- ── NUI: close menu ──
RegisterNUICallback('closeMenu', function(data, cb)
    cb('ok')
    activeMenu = false
    SetNuiFocus(false, false)
    VolverAScripts()
    -- Restore saved sound if player was previewing
    if currentVehicle ~= 0 and DoesEntityExist(currentVehicle) then
        local modelName   = GetModelName(currentVehicle)
        local modelSounds = GlobalState.ModelSounds or {}
        local saved       = (modelSounds[modelName] or {}).sound or ""
        forcedSounds[currentVehicle] = saved
        ForceVehicleEngineAudio(currentVehicle, saved)
    end
    currentVehicle = 0
end)
