local mappedVehicles = {}
local isGuiOpen = false
local focusModel = nil
local isFocused = false
local pendingLiveOpen = nil
local pendingModelValidation = {}
local validationRequestCounter = 0
local liveSession = {
    active = false,
    model = nil,
    hash = nil,
    category = "General",
    data = nil
}
local focusControl = 47 -- INPUT_DETONATE (tecla G)
local cachedQBCore = nil
local cachedESX = nil

local function GetLocaleCode()
    return (Config and Config.Locale) or 'en'
end

local function GetLocaleTable()
    local locales = (Config and Config.Locales) or {}
    local code = GetLocaleCode()
    return locales[code] or locales.en or {}
end

local function T(key, fallback, vars)
    local locale = GetLocaleTable()
    local text = locale[key] or fallback or key
    if vars then
        for k, v in pairs(vars) do
            text = text:gsub("{" .. tostring(k) .. "}", tostring(v))
        end
    end
    return text
end

local function FallbackFeedNotify(message)
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, false)
end

local function Notify(message, msgType, duration)
    local notifyCfg = Config.Notify or {}
    local provider = notifyCfg.provider or 'origen_notify'
    local title = notifyCfg.title or T('mainTitle', 'Vehicle Handling')
    local finalType = msgType or 'info'
    local finalDuration = duration or notifyCfg.duration or 5000

    if provider == 'custom' and type(Config.CustomNotify) == 'function' then
        local ok = pcall(Config.CustomNotify, message, finalType, finalDuration, title)
        if ok then return end
    end

    if provider == 'origen_notify' then
        local ok = pcall(function()
            TriggerEvent('origen_notify:SendNotification', {
                title = title,
                description = message,
                type = finalType,
                duration = finalDuration
            })
        end)
        if ok then return end
    elseif provider == 'ox_lib' then
        local ok = pcall(function()
            if lib and lib.notify then
                lib.notify({
                    title = title,
                    description = message,
                    type = finalType,
                    duration = finalDuration
                })
            else
                error('ox_lib notify unavailable')
            end
        end)
        if ok then return end
    elseif provider == 'qbcore' then
        local ok = pcall(function()
            if not cachedQBCore and GetResourceState('qb-core') == 'started' then
                cachedQBCore = exports['qb-core']:GetCoreObject()
            end
            if cachedQBCore and cachedQBCore.Functions and cachedQBCore.Functions.Notify then
                cachedQBCore.Functions.Notify(message, finalType, finalDuration)
            else
                error('QBCore notify unavailable')
            end
        end)
        if ok then return end
    elseif provider == 'esx' then
        local ok = pcall(function()
            if not cachedESX and GetResourceState('es_extended') == 'started' then
                cachedESX = exports['es_extended']:getSharedObject()
            end
            if cachedESX then
                cachedESX.ShowNotification(message)
            else
                error('ESX notify unavailable')
            end
        end)
        if ok then return end
    elseif provider == 'chat' then
        TriggerEvent('chat:addMessage', {
            color = { 255, 255, 255 },
            multiline = true,
            args = { title, message }
        })
        return
    end

    FallbackFeedNotify(message)
end

--[[ Todos los valores salen del catalogo (shared/campos.lua). Los de
     antes llevan valor por defecto; los nuevos, sin valor, no se tocan. ]]
local function BuildHandlingData(raw, model, category)
    if not raw then return nil end
    local data = HandlingNormalizar(raw)
    data.name = model
    data.category = category or raw.category or "General"
    return data
end

-- Las banderas son 32 bits sin signo y el native las quiere con signo.
local function AEntero32(n)
    n = math.floor(n)
    if n >= 0x80000000 then n = n - 0x100000000 end
    return n
end

--- Lee un valor del coche. nil si el coche no lo tiene (p. ej. una moto no
--- tiene CCarHandlingData).
local function LeerCampo(vehicle, campo)
    local ok, v
    if campo.tipo == 'vec' then
        ok, v = pcall(GetVehicleHandlingVector, vehicle, campo.clase, campo.meta)
        if ok and v then v = v[campo.eje] end
    elseif campo.tipo == 'int' or campo.tipo == 'flags' then
        ok, v = pcall(GetVehicleHandlingInt, vehicle, campo.clase, campo.meta)
        if ok and type(v) == 'number' and campo.tipo == 'flags' and v < 0 then v = v + 0x100000000 end
    else
        ok, v = pcall(GetVehicleHandlingFloat, vehicle, campo.clase, campo.meta)
    end
    if not ok or type(v) ~= 'number' or v ~= v then return nil end
    return v
end

local function ReadVehicleHandlingDefaults(modelName)
    local hash = GetHashKey(modelName)
    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then
        return nil, "invalid_model"
    end

    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(10) end

    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local vehicle = CreateVehicle(hash, pos.x, pos.y, pos.z - 50.0, 0.0, false, false)
    SetEntityVisible(vehicle, false, false)
    SetEntityCollision(vehicle, false, false)
    SetEntityAsMissionEntity(vehicle, true, true)

    local data = {}
    for _, campo in ipairs(HandlingCampos) do
        data[campo.key] = LeerCampo(vehicle, campo)
    end

    DeleteVehicle(vehicle)
    SetModelAsNoLongerNeeded(hash)
    return data, nil
end

local function ActivateLiveSession(modelName, category, baseData)
    local hash = GetHashKey(modelName)
    liveSession.active = true
    liveSession.model = modelName
    liveSession.hash = hash
    liveSession.category = category or "General"
    liveSession.data = BuildHandlingData(baseData, modelName, category)
end

local function ClearLiveSession()
    liveSession.active = false
    liveSession.model = nil
    liveSession.hash = nil
    liveSession.category = "General"
    liveSession.data = nil
end

--[[ Conducir con el panel abierto, como con el inventario.

     Con el raton cogido las teclas tambien llegan al juego (KeepInput), y un
     hilo apaga todo menos moverse y conducir: sin el, cada clic en el panel
     seria ademas un disparo o un puñetazo. Asi se puede ir tocando un valor y
     notarlo al volante sin soltar el raton cada vez.

     Mientras hay un campo con el cursor dentro, las teclas dejan de llegar
     al juego: si no, poner «sadwa» moveria el coche y escribir un «5» usaria
     el hueco 5 del inventario. Intro o pinchar fuera suelta el campo y se
     vuelve a conducir.

     KeepInput va DESPUES de SetNuiFocus: el vigilante del foco
     (origen_map/shared/foco.lua) lo apaga al coger el foco. ]]
local TECLAS_CON_PANEL = { 30, 31, 32, 33, 34, 35, 21, 22, 59, 60, 61, 62, 63, 64, 71, 72, 76, 87, 88, 89, 90, 129, 130, 133, 134, 249 }
local escribiendo = false
local hiloTeclas = 0

local function ControlesConPanel()
    hiloTeclas = hiloTeclas + 1
    local mio = hiloTeclas

    CreateThread(function()
        local jugador = PlayerId()
        while isGuiOpen and isFocused and hiloTeclas == mio do
            DisableAllControlActions(0)
            for i = 1, #TECLAS_CON_PANEL do
                EnableControlAction(0, TECLAS_CON_PANEL[i], true)
            end
            DisablePlayerFiring(jugador, true)
            Wait(0)
        end
    end)
end

local function PonerFoco(si)
    isFocused = si == true
    SetNuiFocus(isFocused, isFocused)
    if isFocused then
        SetNuiFocusKeepInput(not escribiendo)
        ControlesConPanel()
    else
        escribiendo = false
        SetNuiFocusKeepInput(false)
    end
end

RegisterNUICallback('escribiendo', function(data, cb)
    cb('ok')
    escribiendo = data and data.si == true
    if isGuiOpen and isFocused then SetNuiFocusKeepInput(not escribiendo) end
end)

local function ToggleNuiFocusState()
    if not isGuiOpen then return end
    PonerFoco(not isFocused)
    SendNUIMessage({ action = "focusStatus", focus = isFocused })
end

local function GetNuiI18nPayload()
    return {
        localeCode = GetLocaleCode(),
        locale = GetLocaleTable(),
        -- Las casillas del editor: cuales hay, sus textos y sus barras.
        grupos = HandlingGrupos,
        campos = HandlingCampos
    }
end

RegisterNetEvent('origen_vehiclehandling:modelValidationResult')
AddEventHandler('origen_vehiclehandling:modelValidationResult', function(requestId, isValid)
    pendingModelValidation[requestId] = isValid == true
end)

local function ValidateModelWithServer(model)
    validationRequestCounter = validationRequestCounter + 1
    local requestId = ("vh:%s:%s"):format(GetGameTimer(), validationRequestCounter)
    pendingModelValidation[requestId] = nil
    TriggerServerEvent('origen_vehiclehandling:validateVehicleModel', requestId, model)

    local timeoutMs = 3000
    local waited = 0
    while pendingModelValidation[requestId] == nil and waited < timeoutMs do
        Wait(50)
        waited = waited + 50
    end

    local result = pendingModelValidation[requestId]
    pendingModelValidation[requestId] = nil
    return result == true
end

local function StartLiveFromCurrentVehicle(showErrors)
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        if showErrors then Notify(T('mustBeDrivingForLive', 'You must be driving to start Live Handling.'), "error") end
        return false
    end

    local vehicle = GetVehiclePedIsIn(ped, false)
    if GetPedInVehicleSeat(vehicle, -1) ~= ped then
        if showErrors then Notify(T('mustBeDriverForLive', 'You must be the driver to start Live Handling.'), "error") end
        return false
    end

    pendingLiveOpen = nil
    local modelHash = GetEntityModel(vehicle)
    local modelName = nil
    local category = "General"
    for _, data in pairs(mappedVehicles) do
        if GetHashKey(data.name) == modelHash then
            modelName = data.name
            category = data.category or "General"
            break
        end
    end
    if not modelName then
        modelName = string.lower(GetDisplayNameFromVehicleModel(modelHash))
    end

    local base = mappedVehicles[modelHash]
    if base then
        pendingLiveOpen = {
            model = modelName,
            category = category,
            data = base
        }
    else
        local defaults = ReadVehicleHandlingDefaults(modelName)
        if not defaults then
            if showErrors then Notify(T('vehicleDefaultsError', 'Could not fetch model defaults.'), "error") end
            return false
        end
        pendingLiveOpen = {
            model = modelName,
            category = category,
            data = defaults
        }
    end

    focusModel = modelName
    TriggerServerEvent('origen_vehiclehandling:requestOpen', modelName, true)
    return true
end

local function StartLiveForModel(modelName, category, baseData, showErrors)
    if not modelName or modelName == '' then
        if showErrors then Notify(T('invalidModel', 'Invalid model.'), "error") end
        return false
    end

    pendingLiveOpen = nil
    local resolvedCategory = category or "General"
    local hash = GetHashKey(modelName)
    local mapped = mappedVehicles[hash]
    local data = baseData or mapped

    if mapped and mapped.category then
        resolvedCategory = mapped.category
    end

    if not data then
        local defaults = ReadVehicleHandlingDefaults(modelName)
        if not defaults then
            if showErrors then Notify(T('vehicleDefaultsError', 'Could not fetch model defaults.'), "error") end
            return false
        end
        data = defaults
    end

    pendingLiveOpen = {
        model = modelName,
        category = resolvedCategory,
        data = data
    }
    focusModel = modelName
    TriggerServerEvent('origen_vehiclehandling:requestOpen', modelName, true)
    return true
end

-- Sincronizar desde servidor
RegisterNetEvent('origen_vehiclehandling:sync')
AddEventHandler('origen_vehiclehandling:sync', function(data)
    mappedVehicles = {}
    local count = 0
    for model, handlingData in pairs(data) do
        count = count + 1
        local hash = GetHashKey(model)
        mappedVehicles[hash] = BuildHandlingData(handlingData, model, handlingData.category)
    end
    if Config.Debug then
        print("^2[Origen VehicleHandling] Sincronizados " .. tostring(count) .. " vehículos.^7")
    end
    
    if isGuiOpen then
        SendNUIMessage({
            action = "open",
            data = data,
            live = liveSession.active,
            i18n = GetNuiI18nPayload()
        })
    end

    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        local vehicle = GetVehiclePedIsIn(ped, false)
        if GetPedInVehicleSeat(vehicle, -1) == ped then
            local model = GetEntityModel(vehicle)
            local sourceData = nil
            if liveSession.active and liveSession.hash == model and liveSession.data then
                sourceData = liveSession.data
            else
                sourceData = mappedVehicles[model]
            end
            if sourceData then
                ApplyHandling(vehicle, sourceData)
            end
        end
    end
end)

--[[ Un solo modelo, en vez de la tabla entera.

     Cuando un admin guarda o borra el handling de UN coche, a todo el mundo le
     llega solo ese por aqui. La tabla completa (63 KB) ya solo se manda al
     entrar y al admin que ha hecho el cambio, que es quien tiene el panel
     abierto. `datos` a nil significa que ese handling se ha borrado y el coche
     vuelve al de fabrica. ]]
RegisterNetEvent('origen_vehiclehandling:syncOne')
AddEventHandler('origen_vehiclehandling:syncOne', function(model, datos)
    if type(model) ~= 'string' or model == '' then return end

    local hash = GetHashKey(model)

    if datos then
        mappedVehicles[hash] = BuildHandlingData(datos, model, datos.category)
    else
        mappedVehicles[hash] = nil
    end

    -- Si el jugador va conduciendo justo ese coche, que lo note sin esperar.
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        local vehicle = GetVehiclePedIsIn(ped, false)
        if GetPedInVehicleSeat(vehicle, -1) == ped and GetEntityModel(vehicle) == hash then
            local sourceData = mappedVehicles[hash]
            if liveSession.active and liveSession.hash == hash and liveSession.data then
                sourceData = liveSession.data
            end
            if sourceData then
                ApplyHandling(vehicle, sourceData)
            end
        end
    end
end)

-- Comprobación periódica (cada 2 segundos)
Citizen.CreateThread(function()
    Wait(2000)
    TriggerServerEvent('origen_vehiclehandling:requestSync')
    
    while true do
        Wait(Config.CheckInterval or 2000)
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            if GetPedInVehicleSeat(vehicle, -1) == ped then
                local model = GetEntityModel(vehicle)
                local data = nil
                if liveSession.active and liveSession.hash == model and liveSession.data then
                    data = liveSession.data
                else
                    data = mappedVehicles[model]
                end
                
                if data then
                    -- Re-aplicar si el modelo cambió o si el vehículo ha sido reparado (comprobamos un valor canary)
                    local currentMaxSpeed = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveMaxFlatVel')
                    if Entity(vehicle).state.handlingApplied ~= model or math.abs(currentMaxSpeed - data.maxSpeed) > 0.1 then
                        ApplyHandling(vehicle, data)
                        Entity(vehicle).state:set('handlingApplied', model, true)
                    end
                end
            end
        end
    end
end)

function ApplyHandling(vehicle, data)
    local vectores = {}
    for _, campo in ipairs(HandlingCampos) do
        local v = data[campo.key]
        -- Sin «bajar marcha» propio va igual que al subir, como antes.
        if v == nil and campo.key == 'shiftDown' then v = data.shiftSpeed end
        if v ~= nil then
            if campo.tipo == 'vec' then
                vectores[campo.meta] = vectores[campo.meta] or { clase = campo.clase }
                vectores[campo.meta][campo.eje] = v + 0.0
            elseif campo.tipo == 'int' or campo.tipo == 'flags' then
                pcall(SetVehicleHandlingInt, vehicle, campo.clase, campo.meta, AEntero32(v))
            else
                pcall(SetVehicleHandlingFloat, vehicle, campo.clase, campo.meta, v + 0.0)
            end
        end
    end

    -- Los vectores van enteros: lo que no se haya tocado se queda como esta.
    for meta, ejes in pairs(vectores) do
        local ok, actual = pcall(GetVehicleHandlingVector, vehicle, ejes.clase, meta)
        if ok and actual then
            pcall(SetVehicleHandlingVector, vehicle, ejes.clase, meta,
                vector3(ejes.x or actual.x, ejes.y or actual.y, ejes.z or actual.z))
        end
    end

    -- MARCHAS: cambiar el handling no basta con el coche ya hecho: la caja
    -- coge la marcha alta de SetVehicleHighGear.
    if data.gears then
        SetVehicleHighGear(vehicle, data.gears)
    end

    ModifyVehicleTopSpeed(vehicle, 1.0)

    if Config.Debug then
        print(string.format("^2[Origen VehicleHandling] Applied to %s^7", data.name))
    end
end

-- Exports NUI
exports('openManagement', function()
    if isGuiOpen then return end
    TriggerServerEvent('origen_vehiclehandling:requestOpen', focusModel, liveSession.active)
    focusModel = nil
end)

RegisterNetEvent('origen_vehiclehandling:openAuthorized', function(focus, data, liveAllowed)
    isGuiOpen = true
    PonerFoco(true)
    SendNUIMessage({
        action = "pre-open", 
        focus = focus,
        i18n = GetNuiI18nPayload()
    })
    SendNUIMessage({
        action = "open",
        data = data,
        focus = focus,
        live = liveAllowed or liveSession.active,
        i18n = GetNuiI18nPayload()
    })
    if pendingLiveOpen and pendingLiveOpen.data then
        ActivateLiveSession(pendingLiveOpen.model, pendingLiveOpen.category, pendingLiveOpen.data)
        SendNUIMessage({
            action = "openLiveSession",
            data = liveSession.data,
            model = liveSession.model,
            category = liveSession.category
        })
        pendingLiveOpen = nil
    end
end)

RegisterNetEvent('origen_vehiclehandling:sendClientData')
AddEventHandler('origen_vehiclehandling:sendClientData', function(data)
    if data == false then
        isGuiOpen = false
        PonerFoco(false)
        focusModel = nil
        return
    end
    SendNUIMessage({
        action = "open",
        data = data,
        focus = focusModel,
        live = liveSession.active,
        i18n = GetNuiI18nPayload()
    })
    if pendingLiveOpen and pendingLiveOpen.data then
        ActivateLiveSession(pendingLiveOpen.model, pendingLiveOpen.category, pendingLiveOpen.data)
        SendNUIMessage({
            action = "openLiveSession",
            data = liveSession.data,
            model = liveSession.model,
            category = liveSession.category
        })
        pendingLiveOpen = nil
    end
    focusModel = nil
end)

RegisterNUICallback('getVehicleDefaults', function(model, cb)
    local data = nil
    data = select(1, ReadVehicleHandlingDefaults(model))
    if not data then return cb('error') end

    SendNUIMessage({
        action = "vehicleDefaults",
        data = data
    })
    cb('ok')
end)

-- Los de fabrica solo para ENSEÑARLOS al lado de cada casilla (no rellena
-- nada): asi se ve que se ha cambiado y se puede volver a lo de fabrica.
RegisterNUICallback('leerFabrica', function(model, cb)
    cb('ok')
    if type(model) ~= 'string' or model == '' then return end
    local data = select(1, ReadVehicleHandlingDefaults(model))
    SendNUIMessage({ action = "fabrica", model = model, data = data or {} })
end)

RegisterNUICallback('saveVehicle', function(data, cb)
    TriggerServerEvent('origen_vehiclehandling:saveVehicle', data)
    cb('ok')
end)

RegisterNUICallback('applyLiveVehicle', function(data, cb)
    local model = data.model
    if not model then
        cb('error')
        return
    end

    ActivateLiveSession(model, data.category or "General", data)
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        local vehicle = GetVehiclePedIsIn(ped, false)
        if GetPedInVehicleSeat(vehicle, -1) == ped and GetEntityModel(vehicle) == liveSession.hash then
            ApplyHandling(vehicle, liveSession.data)
            Entity(vehicle).state:set('handlingApplied', liveSession.hash, true)
        end
    end
    cb('ok')
end)

RegisterNUICallback('saveLiveVehicle', function(data, cb)
    if not liveSession.active then
        cb('error')
        return
    end
    TriggerServerEvent('origen_vehiclehandling:saveVehicle', data)
    cb('ok')
end)

RegisterNUICallback('discardLiveVehicle', function(_, cb)
    ClearLiveSession()
    cb('ok')
end)

RegisterNUICallback('createVehicleDraft', function(data, cb)
    local model = data and data.model or nil
    local category = data and data.category or "General"
    if not model or model == '' then
        cb('error')
        return
    end

    local valid = ValidateModelWithServer(model)
    if not valid then
        -- Fallback local: algunos runtimes devuelven false/timeout en validación server-side de modelo.
        local hash = GetHashKey(model)
        valid = IsModelInCdimage(hash) and IsModelAVehicle(hash)
    end
    if not valid then
        SendNUIMessage({
            action = "vehicleDraftError",
            message = T('invalidModel', 'Invalid model.')
        })
        cb('error')
        return
    end

    local defaults = ReadVehicleHandlingDefaults(model)
    if not defaults then
        SendNUIMessage({
            action = "vehicleDraftError",
            message = T('vehicleDefaultsError', 'Could not fetch model defaults.')
        })
        cb('error')
        return
    end

    SendNUIMessage({
        action = "vehicleDraftCreated",
        model = model,
        category = category,
        data = defaults
    })
    cb('ok')
end)

RegisterNUICallback('openLiveFromCurrent', function(_, cb)
    local ok = StartLiveFromCurrentVehicle(false)
    cb(ok and 'ok' or 'error')
end)

RegisterNUICallback('spawnVehicleAndOpenLive', function(data, cb)
    local model = data and data.model or nil
    local category = data and data.category or "General"
    if not model or model == '' then
        cb('error')
        return
    end

    local hash = GetHashKey(model)
    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then
        Notify(T('invalidModelSpawn', 'Invalid model for spawn.'), "error")
        cb('error')
        return
    end

    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(10) end

    local ped = PlayerPedId()
    local spawnPos = GetOffsetFromEntityInWorldCoords(ped, 0.0, 4.0, 0.0)
    local heading = GetEntityHeading(ped)
    local vehicle = CreateVehicle(hash, spawnPos.x, spawnPos.y, spawnPos.z, heading, true, false)
    SetVehicleOnGroundProperly(vehicle)
    SetPedIntoVehicle(ped, vehicle, -1)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetModelAsNoLongerNeeded(hash)

    -- Con sus llaves y arrancado: sin llaves, el sistema de llaves lo deja
    -- apagado y no se podia probar nada. Es el mismo evento que usa el garaje.
    local plate = (GetVehicleNumberPlateText(vehicle) or ''):gsub('^%s*(.-)%s*$', '%1')
    if plate ~= '' then
        TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', plate)
    end
    SetVehicleFuelLevel(vehicle, 100.0)
    CreateThread(function()
        -- Las llaves tardan un instante en llegar; hasta entonces el sistema
        -- de llaves vuelve a apagar el motor.
        for _ = 1, 10 do
            if not DoesEntityExist(vehicle) then return end
            SetVehicleEngineOn(vehicle, true, true, false)
            Wait(300)
        end
    end)

    local ok = StartLiveForModel(model, category, nil, true)
    cb(ok and 'ok' or 'error')
end)

RegisterNUICallback('deleteVehicle', function(model, cb)
    TriggerServerEvent('origen_vehiclehandling:deleteVehicle', model)
    cb('ok')
end)

RegisterNUICallback('close', function(data, cb)
    isGuiOpen = false
    PonerFoco(false)
    focusModel = nil
    cb('ok')

    -- ESC: si el panel se abrió desde la pestaña Scripts del admin, se vuelve
    -- a ella. origen_admin solo vuelve si este panel salió de su lista; con el
    -- comando, ESC cierra y nada más.
    if GetResourceState('origen_admin') == 'started' then
        SetTimeout(80, function()
            pcall(function() exports['origen_admin']:ReturnToScripts() end)
        end)
    end
end)

-- Raton soltado a la fuerza (soltarraton, pantalla colgada): el panel se da
-- por cerrado y se esconde; si no, la G volveria a coger el raton para una
-- pantalla que no se ve.
OrigenFoco.AlSoltar(function()
    isGuiOpen = false
    isFocused = false
    escribiendo = false
    SetNuiFocusKeepInput(false)
    focusModel = nil
    SendNUIMessage({ action = "close" })
end)

RegisterNUICallback('toggleFocus', function(data, cb)
    if data and data.focus ~= nil then
        PonerFoco(data.focus == true)
    else
        PonerFoco(not isFocused)
    end
    SendNUIMessage({ action = "focusStatus", focus = isFocused })
    cb('ok')
end)

-- ─── COMANDO ADMIN (sin keybind, restringido por ACE) ─────────
RegisterCommand('openHandlingV2', function()
    local ped = PlayerPedId()
    if isGuiOpen then
        ToggleNuiFocusState()
        return
    end

    if IsPedInAnyVehicle(ped, false) then
        local vehicle = GetVehiclePedIsIn(ped, false)
        if GetPedInVehicleSeat(vehicle, -1) == ped then
            local model = GetEntityModel(vehicle)
            for h, data in pairs(mappedVehicles) do
                if h == model then
                    focusModel = data.name
                    break
                end
            end
        end
    end

    exports['origen_vehiclehandling']:openManagement()
end, true)

RegisterCommand('vh', function()
    if isGuiOpen then
        ToggleNuiFocusState()
        return
    end
    StartLiveFromCurrentVehicle(true)
end, false)

RegisterCommand('vhnew', function(_, args)
    local ped = PlayerPedId()
    local model = args[1]
    local category = args[2] or "General"
    if not model or model == "" then
        if IsPedInAnyVehicle(ped, false) and GetPedInVehicleSeat(GetVehiclePedIsIn(ped, false), -1) == ped then
            model = string.lower(GetDisplayNameFromVehicleModel(GetEntityModel(GetVehiclePedIsIn(ped, false))))
        else
            Notify(T('commandUsageVhnew', 'Usage: /vhnew <model> [category]'), "error")
            return
        end
    end

    local defaults, err = ReadVehicleHandlingDefaults(model)
    if not defaults then
        Notify(T('invalidModel', 'Invalid model.'), "error")
        if Config.Debug then print("^1[Origen VehicleHandling] vhnew error: " .. tostring(err) .. "^7") end
        return
    end

    StartLiveForModel(model, category, defaults, true)
end, false)

-- Comando directo para abrir el menú principal (lista de categorías/coches)
RegisterCommand('vhmenu', function()
    if isGuiOpen then
        ToggleNuiFocusState()
        return
    end
    focusModel = nil
    TriggerServerEvent('origen_vehiclehandling:requestOpen', nil, false)
end, false)

RegisterCommand('vhsave', function()
    if not liveSession.active or not liveSession.data then
        Notify(T('noLiveSession', 'There is no active live session.'), "error")
        return
    end

    local payload = BuildHandlingData(liveSession.data, liveSession.model, liveSession.category)
    payload.model = liveSession.model
    payload.category = liveSession.category
    TriggerServerEvent('origen_vehiclehandling:saveVehicle', payload)
    Notify(T('liveSavedDb', 'Live handling saved to database.'), "success")
end, false)

RegisterCommand('vhdiscard', function()
    if not liveSession.active then
        Notify(T('noLiveSession', 'There is no active live session.'), "error")
        return
    end
    ClearLiveSession()
    SendNUIMessage({ action = "liveDiscarded" })
    Notify(T('liveDiscarded', 'Live session discarded.'), "info")
end, false)

RegisterCommand('toggleHandlingFocus', function()
    ToggleNuiFocusState()
end, true)

Citizen.CreateThread(function()
    while true do
        if isGuiOpen then
            Wait(0)
            if IsControlJustPressed(0, focusControl) then
                ToggleNuiFocusState()
            end
        else
            Wait(500)
        end
    end
end)

-- ─── DISABLE MOTORCYCLE KICKING ──────────────────────────────
Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            if GetVehicleClass(vehicle) == 8 then -- Clase 8: Motos
                sleep = 0
                -- Desactivar controles de combate en moto (X + Click Izquierdo/Derecho)
                DisableControlAction(0, 345, true) -- INPUT_VEH_MELEE_HOLD
                DisableControlAction(0, 346, true) -- INPUT_VEH_MELEE_LEFT
                DisableControlAction(0, 347, true) -- INPUT_VEH_MELEE_RIGHT
            end
        end
        Wait(sleep)
    end
end)

RegisterCommand('clase', function()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        local vehicle = GetVehiclePedIsIn(ped, false)
        local class = nil
        
        -- Prioridad 1: origen_vehicleclasses (Sistema de PI)
        if GetResourceState('origen_vehicleclasses') == 'started' then
            class = exports['origen_vehicleclasses']:GetVehicleClass(vehicle)
        end
        
        -- Prioridad 2: Categoría de origen_vehiclehandling
        if not class or class == "" or class == "General" then
            local hash = GetEntityModel(vehicle)
            if mappedVehicles[hash] and mappedVehicles[hash].category then
                class = mappedVehicles[hash].category
            end
        end
        
        -- Prioridad 3: Clase nativa como último recurso
        if not class or class == "" or class == "General" then
             local nativeClass = GetVehicleClass(vehicle)
             local classes = { [0]="Compacto", [1]="Berlina", [2]="Todoterreno SUV", [3]="Cupé", [4]="Muscle", [5]="Clásico deportivo", [6]="Deportivo", [7]="Superdeportivo", [8]="Moto", [9]="Todoterreno", [10]="Industrial", [11]="Utilitario", [12]="Furgoneta", [13]="Bicicleta", [14]="Barco", [15]="Helicóptero", [16]="Avión", [17]="Servicio", [18]="Emergencias", [19]="Militar", [20]="Comercial", [21]="Tren", [22]="Monoplaza" }
             class = classes[nativeClass] or "Desconocida"
        end

        Notify(T('vehicleClass', 'Vehicle Class: {class}', { class = class }), "info")
    else
        Notify(T('notInVehicle', 'You must be in a vehicle to use this command.'), "error")
    end
end, false)
