local spawnedVehicle = nil

--- Cuantas veces se ha abierto el garaje (la sube OpenGarage, locations.lua).
GarajeBandaVez = 0

local dbg = Debug:new({ 
    enabled = Config.Debug 
})

local function SpawnGangVehicle(vehicleData, spawnCoords)
    local model = GetHashKey(vehicleData.model)
    
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(50)
    end
    
    local coords = vector3(spawnCoords.x, spawnCoords.y, spawnCoords.z)
    -- Forzar float con + 0.0: CreateVehicle y SetEntityHeading requieren float.
    -- Si llega como integer (ej: 0 en vez de 0.0 por JSON), la nativa lo ignora.
    local heading = (tonumber(spawnCoords.w) or 0.0) + 0.0
    
    local vehicle = CreateVehicle(model, coords.x, coords.y, coords.z, heading, true, false)
    
    while not DoesEntityExist(vehicle) do
        Wait(50)
    end
    
    SetVehicleNumberPlateText(vehicle, vehicleData.plate)
    SetEntityHeading(vehicle, heading)
    SetVehicleEngineOn(vehicle, false, false, true)
    SetVehicleUndriveable(vehicle, false)
    
    if vehicleData.properties and next(vehicleData.properties) then
        lib.setVehicleProperties(vehicle, vehicleData.properties)
    end
    
    if VehicleKey and VehicleKey.GiveKeys then
        VehicleKey.GiveKeys(vehicle, vehicleData.plate)
    end
    
    TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
    
    SetModelAsNoLongerNeeded(model)
    
    spawnedVehicle = vehicle
    
    Notify.SendNotify(locale:t('notify.vehicle_taken_out'), 'success')
end

RegisterNUICallback('takeOutVehicle', function(data, cb)
    -- ── Resolver spawn point ───────────────────────────────────────────────────
    -- Prioridad:
    --   1. Coords del punto de garage configurado por la banda (data.garageLocation)
    --   2. Fallback: posición del jugador + offset para no quedarse encima del ped

    local spawnCoords

    local garageLoc = data.garageLocation
    if garageLoc and garageLoc.x and garageLoc.y and garageLoc.z then
        -- Forzar float en todos los campos: NUI→Lua via JSON puede deserializar
        -- enteros donde se necesitan floats. CreateVehicle requiere float en heading.
        spawnCoords = {
            x = (tonumber(garageLoc.x) or 0.0) + 0.0,
            y = (tonumber(garageLoc.y) or 0.0) + 0.0,
            z = (tonumber(garageLoc.z) or 0.0) + 0.0,
            w = (tonumber(garageLoc.h) or tonumber(garageLoc.heading) or 0.0) + 0.0,
        }
        dbg:info('[CLIENT GARAGE] Using gang garage location as spawn point')
    else
        -- Fallback: cerca del jugador
        local ped      = PlayerPedId()
        local coords   = GetEntityCoords(ped)
        local pedHeading = GetEntityHeading(ped)
        local offset   = Config.Garage and Config.Garage.SpawnDistance or 5.0
        -- Proyectar delante del ped para no soltar el vehículo encima
        local rad = math.rad(pedHeading)
        spawnCoords = {
            x = coords.x + math.sin(-rad) * offset,
            y = coords.y + math.cos(-rad) * offset,
            z = coords.z,
            w = pedHeading,
        }
        dbg:info('[CLIENT GARAGE] No garage location — using player offset as spawn point')
    end

    dbg:info('[CLIENT GARAGE] Taking out vehicle:', data.vehicleId)
    dbg:info('[CLIENT GARAGE] Spawn coords:', json.encode(spawnCoords))

    lib.callback('origen_gangs:server:takeOutVehicle', false, function(response)
        dbg:info('[CLIENT GARAGE] Take out response:', json.encode(response or {}))

        if response.success then
            -- El foco primero: el spawn espera al modelo y, mientras, el raton
            -- seguia preso con la pantalla ya cerrandose.
            SetNuiFocus(false, false)
            cb(response)
            SpawnGangVehicle(response.vehicle, spawnCoords)
        else
            Notify.SendNotify(response.message, 'error')
            cb(response)
        end
    end, data.vehicleId, spawnCoords)
end)

RegisterNUICallback('purchaseVehicle', function(data, cb)
    dbg:info('[CLIENT GARAGE] Purchase callback received')
    dbg:info('[CLIENT GARAGE] Data:', json.encode(data))
    
    lib.callback('origen_gangs:server:purchaseVehicle', false, function(response)
        dbg:info('[CLIENT GARAGE] Server response:', json.encode(response or {}))
        
        if response and response.success then
            Notify.SendNotify(response.message, 'success')
            cb(response)
        elseif response then
            Notify.SendNotify(response.message, 'error')
            cb(response)
        else
            Notify.SendNotify(locale:t('notify.purchase_error'), 'error')
            cb({success = false, message = locale:t('notify.purchase_error')})
        end
    end, data.gangId, data.catalogId)
end)

RegisterNUICallback('recoverVehicle', function(data, cb)
    dbg:info('[CLIENT GARAGE] Recover vehicle callback:', data.vehicleId)
    
    lib.callback('origen_gangs:server:recoverVehicle', false, function(response)
        dbg:info('[CLIENT GARAGE] Recover response:', json.encode(response or {}))
        
        if response and response.success then
            Notify.SendNotify(response.message, 'success')
            cb(response)
        elseif response then
            Notify.SendNotify(response.message, 'error')
            cb(response)
        else
            Notify.SendNotify(locale:t('notify.vehicle_recover_error'), 'error')
            cb({success = false, message = locale:t('notify.vehicle_recover_error')})
        end
    end, data.vehicleId)
end)

--[[ El foco se suelta YA y el desmontaje espera a que acabe la salida
     (260 ms en GarajeBanda.vue). Al reves, el raton se quedaba preso el rato
     en que la pantalla ya parecia cerrada. ]]
RegisterNUICallback('closeGarageMenu', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')

    -- Si en esos 280 ms se ha vuelto a abrir, no se cierra el nuevo.
    local vez = GarajeBandaVez
    SetTimeout(280, function()
        if vez ~= GarajeBandaVez then return end
        SendNUIMessage({
            action = 'closeGarageMenu'
        })
    end)
end)

-- Si el raton se suelta a la fuerza (`soltarraton`, pagina vacia o colgada;
-- ver origen_map/shared/foco.lua), el garaje se quita de la pantalla: aqui no
-- hay marca de abierto, y sin foco este recurso ya no tiene panel que atender.
-- Si no estaba abierto, el mensaje no cambia nada.
if OrigenFoco then
    OrigenFoco.AlSoltar(function()
        SendNUIMessage({ action = 'closeGarageMenu' })
    end)
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if spawnedVehicle and DoesEntityExist(spawnedVehicle) then
            DeleteVehicle(spawnedVehicle)
        end
    end
end)
