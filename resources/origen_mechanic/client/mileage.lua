--[[ Contador de sesion en vez de un booleano `tracking`: al salir y volver a
     entrar rapido el bucle viejo todavia no ha llegado a su tick y un booleano
     dejaria al nuevo sin arrancar. ]]
local session = 0

local function SyncMileage(netId, km)
    if km <= 0 then return end

    TriggerServerEvent('origen_mechanic:server:syncMileage', {
        netId = netId,
        km = math.min(km, Config.Mileage.MaxKmPerSync)
    })
end

--[[ Recien spawneado el vehiculo la matricula todavia puede venir vacia y el
     servidor aun no ve al jugador sentado, asi que se reintenta antes de rendirse. ]]
local function EnsureState(vehicle, netId, mySession)
    for _ = 1, 3 do
        if mySession ~= session then return false end
        if not DoesEntityExist(vehicle) or cache.seat ~= -1 then return false end

        local response = lib.callback.await('origen_mechanic:cb:ensureVehicleState', false, {
            netId = netId,
            class = GetVehicleClass(vehicle),
            model = GetEntityModel(vehicle)
        })

        if type(response) == 'table' and response.success then return true end

        Wait(1000)
    end

    return false
end

local function TrackVehicle(vehicle)
    session = session + 1
    local mySession = session

    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end
    if not NetworkGetEntityIsNetworked(vehicle) then return end
    if not Mechanic.IsTrackableClass(GetVehicleClass(vehicle)) then return end

    local netId = VehToNet(vehicle)

    Wait(1000)
    if mySession ~= session then return end

    if not EnsureState(vehicle, netId, mySession) then return end

    local lastCoords = GetEntityCoords(vehicle)
    local pending = 0.0

    while true do
        Wait(Config.Mileage.TickMs)

        if mySession ~= session then break end
        if cache.seat ~= -1 or not DoesEntityExist(vehicle) then break end
        if GetVehiclePedIsIn(PlayerPedId(), false) ~= vehicle then break end

        local coords = GetEntityCoords(vehicle)
        local distance = #(coords - lastCoords)
        lastCoords = coords

        if distance > Config.Mileage.MinDistance and distance <= Config.Mileage.MaxDistancePerTick then
            pending = pending + (distance * 0.001)

            if pending >= Config.Mileage.SyncThresholdKm then
                SyncMileage(netId, pending)
                pending = 0.0
            end
        end
    end

    SyncMileage(netId, pending)
end

--[[ El vehiculo se resuelve con la nativa y no con `cache.vehicle`: cuando salta
     el cambio de asiento el orden de actualizacion de la cache no esta
     garantizado y puede venir todavia vacia. ]]
lib.onCache('seat', function(seat)
    if seat ~= -1 then
        session = session + 1
        return
    end

    CreateThread(function()
        TrackVehicle(GetVehiclePedIsIn(PlayerPedId(), false))
    end)
end)

CreateThread(function()
    if cache.seat == -1 then
        TrackVehicle(GetVehiclePedIsIn(PlayerPedId(), false))
    end
end)
