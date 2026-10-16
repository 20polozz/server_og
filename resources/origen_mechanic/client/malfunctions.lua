local session = 0
local effectActive = false
local engineLocked = false
local pendingRestore = nil
local lastLockNotify = 0
local lastOverdueWarn = 0

local function Alive(vehicle)
    return vehicle and vehicle ~= 0 and DoesEntityExist(vehicle)
end

local function Notify(description, kind)
    if not Config.Malfunctions.Notify then return end

    Custom.Notify({
        title = 'Mecánica',
        description = description,
        type = kind or 'error'
    })
end

local function IsCompatible(componentType, electric)
    if componentType == Mechanic.FuelType.BOTH then return true end
    if electric then return componentType == Mechanic.FuelType.ELECTRIC end

    return componentType == Mechanic.FuelType.COMBUSTION
end

local function GetHandling(vehicle, field)
    return GetVehicleHandlingFloat(vehicle, 'CHandlingData', field)
end

local function SetHandling(vehicle, field, value)
    if not Alive(vehicle) then return end
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', field, value + 0.0)
end

local function ResetPower(vehicle)
    if not Alive(vehicle) then return end
    SetVehicleEnginePowerMultiplier(vehicle, 0.0)
end

local function PowerCycles(vehicle, params)
    for _ = 1, params.cycles do
        if not Alive(vehicle) then return end
        SetVehicleEnginePowerMultiplier(vehicle, params.power)
        Wait(params.cutMs)

        if not Alive(vehicle) then return end
        SetVehicleEnginePowerMultiplier(vehicle, 0.0)
        Wait(params.restMs)
    end
end

local function CutEngine(vehicle, ms)
    if not Alive(vehicle) then return end

    SetVehicleEngineOn(vehicle, false, true, true)
    Wait(ms)

    if not Alive(vehicle) then return end
    SetVehicleEngineOn(vehicle, true, true, false)
end

--[[ Cada efecto devuelve primero su restauracion y despues su cuerpo. La
     restauracion se crea ANTES de tocar nada porque `GetVehicleHandlingFloat`
     devuelve el valor vigente: si se leyera despues, el valor original ya estaria
     perdido. Nunca hay dos efectos a la vez por la misma razon. ]]
local Effects = {}

Effects.motor = function(vehicle, params)
    local temperature = params.temperature and GetVehicleEngineTemperature(vehicle) or nil

    return function()
        ResetPower(vehicle)
        if temperature and Alive(vehicle) then SetVehicleEngineTemperature(vehicle, temperature) end
    end, function()
        if params.temperature and Alive(vehicle) then
            SetVehicleEngineTemperature(vehicle, params.temperature)
        end

        PowerCycles(vehicle, params)
    end
end

Effects.transmision = function(vehicle, params)
    local upShift = GetHandling(vehicle, 'fClutchChangeRateScaleUpShift')
    local downShift = GetHandling(vehicle, 'fClutchChangeRateScaleDownShift')

    return function()
        ResetPower(vehicle)
        SetHandling(vehicle, 'fClutchChangeRateScaleUpShift', upShift)
        SetHandling(vehicle, 'fClutchChangeRateScaleDownShift', downShift)
    end, function()
        SetHandling(vehicle, 'fClutchChangeRateScaleUpShift', upShift * params.clutchScale)
        SetHandling(vehicle, 'fClutchChangeRateScaleDownShift', downShift * params.clutchScale)

        if Alive(vehicle) then SetVehicleEnginePowerMultiplier(vehicle, params.power) end
        Wait(params.duration)
    end
end

Effects.frenos = function(vehicle, params)
    local brakeForce = GetHandling(vehicle, 'fBrakeForce')

    return function()
        SetHandling(vehicle, 'fBrakeForce', brakeForce)
    end, function()
        SetHandling(vehicle, 'fBrakeForce', brakeForce * params.brakeScale)
        Wait(params.duration)
    end
end

Effects.refrigeracion = function(vehicle, params)
    local temperature = GetVehicleEngineTemperature(vehicle)

    return function()
        if not Alive(vehicle) then return end
        SetVehicleEngineTemperature(vehicle, temperature)
        --[[ Solo se reenciende si el efecto llego a cortar: si no, se le estaria
             arrancando el coche a un jugador que lo habia apagado el mismo. ]]
        if params.engineOffMs then SetVehicleEngineOn(vehicle, true, true, false) end
    end, function()
        if Alive(vehicle) then SetVehicleEngineTemperature(vehicle, params.temperature) end
        if params.engineOffMs then CutEngine(vehicle, params.engineOffMs) end

        Wait(params.duration)
    end
end

Effects.inyeccion = function(vehicle, params)
    return function()
        ResetPower(vehicle)
    end, function()
        PowerCycles(vehicle, params)
    end
end

Effects.direccion = function(vehicle, params)
    local steeringLock = GetHandling(vehicle, 'fSteeringLock')

    return function()
        SetHandling(vehicle, 'fSteeringLock', steeringLock)
    end, function()
        SetHandling(vehicle, 'fSteeringLock', steeringLock * params.steeringScale)
        Wait(params.duration)
    end
end

Effects.alternador = function(vehicle, params)
    return function()
        if not Alive(vehicle) then return end
        SetVehicleLights(vehicle, 0)
        SetVehicleEngineOn(vehicle, true, true, false)
    end, function()
        if not params.cycles then
            if params.lights and Alive(vehicle) then SetVehicleLights(vehicle, 1) end
            CutEngine(vehicle, params.engineOffMs)
            return
        end

        for _ = 1, params.cycles do
            if not Alive(vehicle) then return end
            if params.lights then SetVehicleLights(vehicle, 1) end
            SetVehicleEngineOn(vehicle, false, true, true)
            Wait(params.engineOffMs)

            if not Alive(vehicle) then return end
            if params.lights then SetVehicleLights(vehicle, 2) end
            SetVehicleEngineOn(vehicle, true, true, false)
            Wait(params.engineOnMs)
        end
    end
end

Effects.suspension = function(vehicle, params)
    local tractionMax = GetHandling(vehicle, 'fTractionCurveMax')
    local tractionMin = GetHandling(vehicle, 'fTractionCurveMin')
    local rebound = GetHandling(vehicle, 'fSuspensionReboundDamp')

    return function()
        SetHandling(vehicle, 'fTractionCurveMax', tractionMax)
        SetHandling(vehicle, 'fTractionCurveMin', tractionMin)
        SetHandling(vehicle, 'fSuspensionReboundDamp', rebound)
    end, function()
        --[[ Los dos puntos de la curva se escalan por el mismo factor: si el
             minimo quedase por encima del maximo el manejo se vuelve errático de
             forma imprevisible. ]]
        SetHandling(vehicle, 'fTractionCurveMax', tractionMax * params.tractionScale)
        SetHandling(vehicle, 'fTractionCurveMin', tractionMin * params.tractionScale)
        SetHandling(vehicle, 'fSuspensionReboundDamp', rebound * params.reboundScale)
        Wait(params.duration)
    end
end

Effects.motor_electrico = function(vehicle, params)
    return function()
        ResetPower(vehicle)
        if not Alive(vehicle) or params.cycles then return end

        SetVehicleLights(vehicle, 0)
        SetVehicleEngineOn(vehicle, true, true, false)
    end, function()
        if params.cycles then
            PowerCycles(vehicle, params)
            return
        end

        if params.lights and Alive(vehicle) then SetVehicleLights(vehicle, 1) end
        CutEngine(vehicle, params.engineOffMs)
    end
end

Effects.bateria_ev = function(vehicle, params)
    return function()
        ResetPower(vehicle)
    end, function()
        if Alive(vehicle) then SetVehicleEnginePowerMultiplier(vehicle, params.power) end
        Wait(params.duration)
    end
end

local function CollectDegraded(health, electric)
    local degraded = {}

    for name, value in pairs(health.components) do
        local component = Config.Components[name]

        if component and IsCompatible(component.type, electric) and Effects[name] then
            local condition = Mechanic.GetComponentCondition(value)

            if condition == Mechanic.ComponentCondition.WORN or condition == Mechanic.ComponentCondition.CRITICAL then
                degraded[#degraded + 1] = { name = name, label = component.label, condition = condition }
            end
        end
    end

    return degraded
end

local function GetFailedLabel(health, electric)
    for name, value in pairs(health.components) do
        local component = Config.Components[name]

        if component and IsCompatible(component.type, electric) then
            if Mechanic.GetComponentCondition(value) == Mechanic.ComponentCondition.FAILED then
                return component.label
            end
        end
    end

    return nil
end

local CONDITION_MESSAGES = {
    [Mechanic.ComponentCondition.WORN] = 'Fallo mecánico en %s',
    [Mechanic.ComponentCondition.CRITICAL] = 'Fallo grave en %s'
}

local function TryEffect(vehicle, health, electric)
    if Config.Malfunctions.SkipWhileAirborne and IsEntityInAir(vehicle) then return end
    if (GetEntitySpeed(vehicle) * 3.6) < Config.Malfunctions.MinSpeedKmh then return end

    local degraded = CollectDegraded(health, electric)
    if #degraded == 0 then return end

    local selected = degraded[math.random(1, #degraded)]
    if math.random() > (Config.Malfunctions.Chance[selected.condition] or 0) then return end

    local params = Config.MalfunctionEffects[selected.name]
    params = params and params[selected.condition]
    if not params then return end

    effectActive = true
    Notify((CONDITION_MESSAGES[selected.condition] or '%s'):format(selected.label))

    CreateThread(function()
        local restore, body = Effects[selected.name](vehicle, params)
        pendingRestore = restore

        local ok, err = pcall(body)

        pendingRestore = nil
        pcall(restore)
        effectActive = false

        if not ok then
            print(('[origen_mechanic] Efecto de avería fallido en %s: %s'):format(selected.name, tostring(err)))
        end
    end)
end

local function WarnOverdue(health)
    local now = GetGameTimer()
    if (now - lastOverdueWarn) < Config.Malfunctions.OverdueWarnMs then return end
    if type(health.services) ~= 'table' then return end

    for name, since in pairs(health.services) do
        local service = Config.Services[name]
        local interval = service and Mechanic.GetEffectiveInterval(name, health.class)

        if interval and interval > 0 and since > interval then
            lastOverdueWarn = now
            Notify(('%s vencido: está dañando el motor y demás piezas asociadas'):format(service.label), 'warning')
            return
        end
    end
end

local function EnforceLock(vehicle, mySession)
    while mySession == session and engineLocked do
        if not Alive(vehicle) then return end

        if GetIsVehicleEngineRunning(vehicle) or IsVehicleEngineStarting(vehicle) then
            SetVehicleEngineOn(vehicle, false, true, true)
        end

        Wait(Config.EngineLock.EnforceMs)
    end
end

local function Track(vehicle)
    session = session + 1
    local mySession = session

    engineLocked = false

    if not Config.Malfunctions.Enabled and not Config.EngineLock.Enabled then return end
    if not Alive(vehicle) then return end
    if not NetworkGetEntityIsNetworked(vehicle) then return end
    if not Mechanic.IsTrackableClass(GetVehicleClass(vehicle)) then return end

    local electric = GetIsVehicleElectric(GetEntityModel(vehicle))
    local elapsed = 0

    lastOverdueWarn = GetGameTimer()

    while true do
        Wait(1000)

        if mySession ~= session then break end
        if cache.seat ~= -1 or not Alive(vehicle) then break end

        local health = Entity(vehicle).state[Mechanic.StateKey]

        if type(health) == 'table' and type(health.components) == 'table' then
            local failed = Config.EngineLock.Enabled and GetFailedLabel(health, electric) or nil

            if failed and not engineLocked then
                engineLocked = true
                lastLockNotify = GetGameTimer()
                Notify(('%s averiado: el motor no arranca'):format(failed))

                CreateThread(function() EnforceLock(vehicle, mySession) end)
            elseif failed and (GetGameTimer() - lastLockNotify) >= Config.EngineLock.NotifyMs then
                lastLockNotify = GetGameTimer()
                Notify(('%s averiado: el motor no arranca'):format(failed))
            elseif not failed and engineLocked then
                engineLocked = false
                SetVehicleEngineOn(vehicle, true, true, false)
            end

            if Config.Malfunctions.Enabled and not engineLocked and not effectActive then
                elapsed = elapsed + 1

                if elapsed >= Config.Malfunctions.IntervalSeconds then
                    elapsed = 0
                    TryEffect(vehicle, health, electric)
                end
            end

            WarnOverdue(health)
        end
    end

    --[[ Al bajarse se deja de reafirmar el bloqueo pero NO se enciende el motor:
         el coche sigue averiado y el siguiente que se siente lo volvera a
         bloquear desde su propio cliente. ]]
    engineLocked = false
end

lib.onCache('seat', function(seat)
    if seat ~= -1 then
        session = session + 1
        return
    end

    CreateThread(function()
        Track(GetVehiclePedIsIn(PlayerPedId(), false))
    end)
end)

CreateThread(function()
    if cache.seat == -1 then
        Track(GetVehiclePedIsIn(PlayerPedId(), false))
    end
end)

--[[ Un reinicio del recurso en mitad de un efecto dejaria el `fBrakeForce` o el
     multiplicador de potencia alterados hasta que el jugador cambiase de
     vehiculo. ]]
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if pendingRestore then pcall(pendingRestore) end
end)
