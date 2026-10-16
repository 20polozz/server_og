
local function updateVehState(key, value)
    SendNUIMessage({
        action = 'updateVehState',
        key = key,
        value = value,
    })
end

-- Variable global para controlar si el HUD del vehículo debe estar oculto
local vehicleHudHidden = false

--[[ Este HUD es SOLO de aviones y helicopteros. El de los coches (velocidad,
     marcha, gasolina...) lo pinta el minimapa de origen_map; antes aqui habia
     otro, viejo, que se apartaba preguntando a origen_map y que al reiniciar
     salia unos segundos hasta que origen_map contestaba. Ya no existe. ]]
local function EsAeronave(veh)
    local clase = GetVehicleClass(veh)
    return clase == 15 or clase == 16 -- 15 = helicopteros, 16 = aviones
end

local function vehHandlers(veh)
    local handlers = {}
    local netId = NetworkGetNetworkIdFromEntity(veh)

    table.insert(handlers, AddStateBagChangeHandler('fuel', ('entity:%s'):format(netId), function(_, _, value, _, replicated)
        if not replicated then
            updateVehState('fuel', value)
        end
    end))
    
    table.insert(handlers, AddStateBagChangeHandler('mileage', ('entity:%s'):format(netId), function(_, _, value, _, replicated)
        if not replicated then
            updateVehState('mileage', value.value and (math.floor(value.value) / 1000) or 0)
        end
    end))

    return handlers
end

local function setupHud()
    local vState = Entity(cache.vehicle).state
    updateVehState('mileage', vState.mileage and (math.floor(vState.mileage.value) / 1000) or 0)
    updateVehState('fuel', vState.fuel)
end

local function vehUpdate(veh)
    if not EsAeronave(veh) then return end
    CreateThread(function()
        setupHud()
        local handlers = vehHandlers(veh)

        while cache.vehicle do
            local data = {
                show = not vehicleHudHidden,
                speed = math.ceil(GetEntitySpeed(cache.vehicle) * 3.6),
                gear = GetVehicleCurrentGear(cache.vehicle),
                rpm = math.floor(GetVehicleCurrentRpm(cache.vehicle) * 100),
                health = GetVehicleEngineHealth(cache.vehicle),
                isAircraft = true,
            }

            do
                local coords = GetEntityCoords(cache.vehicle)
                local success, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, true)
                local velocity = GetEntityVelocity(cache.vehicle)
                local heading = GetEntityHeading(cache.vehicle)
                local rotation = GetEntityRotation(cache.vehicle, 2)
                
                data.altitude = math.floor(coords.z - (success and groundZ or 0.0)) -- Altura sobre el suelo
                data.verticalSpeed = math.floor(velocity.z * 3.6) -- Velocidad vertical
                data.heading = math.floor(heading) -- Dirección en grados
                data.pitch = math.floor(rotation.x) -- Inclinación
                data.landingGear = GetLandingGearState(cache.vehicle) -- 0=desplegado, 4=recogido, 5=desplegándose
            end
            
            SendNUIMessage({
                action = 'updateVeh',
                data = data
            })
            Wait(100)
        end

        for _, handler in ipairs(handlers) do
            RemoveStateBagChangeHandler(handler)
        end

        SendNUIMessage({
            action = 'updateVeh',
            data = {
                show = false,
            }
        })
    end)
end

exports('updateVehState', updateVehState)

RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
    DisplayRadar(false)
end)

lib.onCache('vehicle', function(veh)
    if veh then
        DisplayRadar(true)
        vehUpdate(veh)
    else
        DisplayRadar(false)
    end
end)

if cache.vehicle then
    vehUpdate(cache.vehicle)
end

DisplayRadar(IsPedInAnyVehicle(PlayerPedId(), false))

-- Evento para ocultar/mostrar el HUD del vehículo (por ejemplo, al abrir inventario)
RegisterNetEvent('origen_hud:client:hideVehicleHud', function(hide)
    vehicleHudHidden = hide
    if hide then
        SendNUIMessage({
            action = 'updateVeh',
            data = { show = false }
        })
    end
end)

-- Red de seguridad: si el jugador sale del vehículo, resetear la flag
-- para que nunca quede trabada (ej: salió del coche con el inventario abierto).
lib.onCache('vehicle', function(veh)
    if not veh then
        vehicleHudHidden = false
    end
end)