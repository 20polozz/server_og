local vehicleClasses = {
    [0] = 'automobile',
    [1] = 'automobile',
    [2] = 'automobile',
    [3] = 'automobile',
    [4] = 'automobile',
    [5] = 'automobile',
    [6] = 'automobile',
    [7] = 'automobile',
    [8] = 'bike',
    [9] = 'automobile',
    [10] = 'automobile',
    [11] = 'automobile',
    [12] = 'automobile',
    [13] = 'bike',
    [14] = 'boat',
    [15] = 'heli',
    [16] = 'plane',
    [17] = 'automobile',
    [18] = 'automobile',
    [19] = 'automobile',
    [20] = 'automobile',
    [21] = 'automobile',
    [22] = 'automobile',
}

local function getVehicleClass(model)
    local modelHash = type(model) == 'number' and model or type(model) == 'string' and GetHashKey(model)
    if not modelHash then return nil end

    return GetVehicleClassFromName(modelHash)
end

function cGarage:GetVehicles(data)
    local vehicles = lib.callback.await('origen_garages:cb:getVehicles', false, data)
    return vehicles or {}
end

cGarage.Utils.canInteract = function(restrictions)
    local job = Framework.GetPlayerJob()
    local gang = Framework.GetPlayerGang()

    if not restrictions.enabled then return true end

    if restrictions.job[job.name] and job.grade >= restrictions.job[job.name] or restrictions.gang[gang.name] and gang.grade >= restrictions.gang[gang.name] then
        return true
    end
    
    return false
end

cGarage.Utils.kickOutPeds = function(vehicle)
    for i = -1, 5, 1 do
        local seat = GetPedInVehicleSeat(vehicle, i)
        if seat then
            TaskLeaveVehicle(seat, vehicle, 0)
        end
    end
end

local FOTOS_TTL = 5 * 60 * 1000
local fotosPorHash, fotosLeidas = {}, nil

-- El hash de mods.model llega firmado o sin firmar segun quien guardo el coche.
local function hashSinSigno(hash)
    local entero = math.tointeger(hash)
    return entero and (entero & 0xFFFFFFFF) or nil
end

cGarage.Utils.photoOf = function(model)
    if not fotosLeidas or GetGameTimer() - fotosLeidas > FOTOS_TTL then
        fotosLeidas = GetGameTimer()
        fotosPorHash = {}
        for nombre, url in pairs(lib.callback.await('origen_garages:cb:getVehiclePhotos', false) or {}) do
            fotosPorHash[hashSinSigno(GetHashKey(nombre))] = url
        end
    end

    local hash = hashSinSigno(type(model) == 'string' and GetHashKey(model) or tonumber(model))
    return hash and fotosPorHash[hash] or nil
end

cGarage.Utils.prepareVehicles = function(vehicles, spawner, allowedTypes)
    local formatted = {}
    for id, vehicle in pairs(vehicles) do
        local model = spawner and vehicle or vehicle.mods.model
        vehicle = spawner and {} or vehicle
        vehicle.id = id
        vehicle.model = GetDisplayNameFromVehicleModel(model)

        local vehicleClass = getVehicleClass(model)

        if allowedTypes and not cGarage.Utils.isTypeAllowed(vehicleClasses[vehicleClass] or 'car', allowedTypes) then
            debugger("Vehicle "..vehicle.model.." skipped due to type restrictions.")
            goto continue
        end

        vehicle.name = GetLabelText(vehicle.model)
        vehicle.brand = GetLabelText(GetMakeNameFromVehicleModel(model))
        vehicle.hash = type(model) == "number" and model or GetHashKey(model)
        vehicle.photo = cGarage.Utils.photoOf(vehicle.hash)
        vehicle.class = GetLabelText("VEH_CLASS_"..tostring(vehicleClass or 0))
        -- Sin bodyHealth guardado (un coche dado por admin, recien comprado,
        -- que nunca ha salido) el coche esta nuevo: 1000, no 0. Con `or 0`
        -- salia averiado con la carroceria a cero sin haberlo sacado nunca.
        --[[ En modo `spawner` el vehiculo se reconstruye vacio unas lineas mas
             arriba y no tiene `mods`. ]]
        local props = vehicle.mods or {}
        local carroceria = tonumber(props.bodyHealth) or 1000
        --[[ La barra pinta la peor de las dos saludes: un coche con la chapa
             intacta y el motor fundido salia como sano y el jugador lo sacaba
             sin saber que no iba a arrancar. ]]
        local motor = tonumber(props.engineHealth) or 1000
        local peor = math.min(carroceria, motor)
        vehicle.stats = not spawner and {
            fuel = tonumber(props.fuelLevel) or 100,
            damage = math.max(0, math.min(100, 100 - math.round(peor / 10))),
        } or nil
        vehicle.mods = nil
        table.insert(formatted, vehicle)

        ::continue::
    end

    return formatted
end

cGarage.Utils.isTypeAllowed = function(vehType, allowedTypes)
    if vehType == 'automobile' or vehType == 'bike' then
        return lib.table.contains(allowedTypes, 'car')
    elseif vehType == 'heli' or vehType == 'plane' then
        return lib.table.contains(allowedTypes, 'air')
    elseif vehType == 'boat' or vehType == 'submarine' then
        return lib.table.contains(allowedTypes, 'boat')
    end
end

cGarage.Utils.getVehicleType = function(model)
    return vehicleClasses[getVehicleClass(model)] or 'car'
end

cGarage.Utils.centerCamera = function()
    SetGameplayCamRelativeHeading(0.0)
    SetGameplayCamRelativePitch(0.0, 1.0)
end

local function writeVehicleDamage(vehicle, props)
    if not DoesEntityExist(vehicle) then return end

    if props.bodyHealth then SetVehicleBodyHealth(vehicle, props.bodyHealth + 0.0) end
    if props.engineHealth then SetVehicleEngineHealth(vehicle, props.engineHealth + 0.0) end
    if props.tankHealth then SetVehiclePetrolTankHealth(vehicle, props.tankHealth + 0.0) end
    if props.dirtLevel then SetVehicleDirtLevel(vehicle, props.dirtLevel + 0.0) end

    if type(props.tyreBurstCompletely) == 'table' then
        for tyre, burst in pairs(props.tyreBurstCompletely) do
            if burst then SetVehicleTyreBurst(vehicle, tonumber(tyre), true, 1000.0) end
        end
    end

    if type(props.tyresBurst) == 'table' then
        for tyre, burst in pairs(props.tyresBurst) do
            if burst then SetVehicleTyreBurst(vehicle, tonumber(tyre), false, 1000.0) end
        end
    end

    if type(props.windowsDamaged) == 'table' then
        for window, damaged in pairs(props.windowsDamaged) do
            if damaged then SmashVehicleWindow(vehicle, tonumber(window)) end
        end
    end

    if type(props.doorsBroken) == 'table' then
        for door, broken in pairs(props.doorsBroken) do
            if broken then SetVehicleDoorBroken(vehicle, tonumber(door), true) end
        end
    end
end

--[[ `lib.setVehicleProperties` ya escribe la salud y las roturas, pero el
     motor de fisica las pisa mientras sincroniza la entidad recien creada: un
     coche que entro averiado salia del garaje como nuevo. Se repite la
     escritura medio segundo despues, cuando la entidad ya se ha asentado. ]]
cGarage.Utils.applyVehicleDamage = function(vehicle, props)
    if not vehicle or vehicle == 0 or type(props) ~= 'table' then return end

    writeVehicleDamage(vehicle, props)

    CreateThread(function()
        Wait(500)
        writeVehicleDamage(vehicle, props)
    end)
end
