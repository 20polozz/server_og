local vehicleClassWhitelist = {
    [0] = true,
    [1] = true,
    [2] = true,
    [3] = true,
    [4] = true,
    [5] = true,
    [6] = true,
    [7] = true,
    [9] = true
}
local IsVehicleClassWhitelisted = function(vehicleClass)
    if not tonumber(vehicleClass) then return end
    if not vehicleClassWhitelist[vehicleClass] then return end
    return true
end

local Vehicle = {}
Vehicle.limiter = {}
Vehicle.limiter.speedLimiter = false


Vehicle.toggleLimiter = function()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    if not vehicle then
        Bridge.Notify(locale:t('notify.NoInVehicle'))
        return false
    end
    if vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= playerPed then
        Bridge.Notify(locale:t('notify.NoInVehicle'))
        return false
    end

    if Vehicle.limiter.speedLimiter then
        Vehicle.limiter.speedLimiter = false
        SetEntityMaxSpeed(vehicle, GetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveMaxFlatVel"))
        return true
    end

    Vehicle.limiter.speedLimiter = true
    local speed = GetEntitySpeed(vehicle)
    SetEntityMaxSpeed(vehicle, speed)

    CreateThread(function()
        while Vehicle.limiter.speedLimiter do
            Wait(100)

            if IsEntityInAir(vehicle) then
                Vehicle.toggleLimiter()
            end
        end
    end)

    debugger("Speed limiter set to " .. tostring(speed) .. " m/s")
    return true
end

eventPublisher:subscribe('origen_inventory:vehicle:limiter', function()
    Vehicle.toggleLimiter()
end)


Vehicle.cruiseControl = {}
Vehicle.cruiseControl.state = false

Vehicle.toggleCruiseMode = function()
    local ped     = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle > 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
        if Vehicle.cruiseControl.state then
            Vehicle.cruiseControl.state = false
        else
            Vehicle.cruiseControl.state = true

            local speed = GetEntitySpeed(vehicle)
            local timeturn = 0

            CreateThread(function()
                while Vehicle.cruiseControl.state do
                    local roll = GetEntityRoll(vehicle)
                    local sp = GetEntitySpeed(vehicle)

                    if not IsPedInAnyVehicle(PlayerPedId(), false) or IsControlJustPressed(0, 71) or IsControlJustPressed(0, 72) or IsControlJustPressed(0, 76) or speed - sp > 10 or IsEntityInAir(vehicle) or (roll > 75.0 or roll < -75.0) or GetVehicleClass(vehicle) == 14 or not IsVehicleOnAllWheels(vehicle) then
                        Vehicle.cruiseControl.state = false
                    end

                    if IsControlPressed(0, 63) or IsControlPressed(0, 64) or IsControlPressed(0, 69) then
                        timeturn = timeturn + 5
                    else
                        timeturn = 0
                    end
                    if sp >= 20 and timeturn >= 100 then
                        Vehicle.cruiseControl.state = false
                    end

                    SetVehicleForwardSpeed(vehicle, speed)

                    Wait(5)
                end
            end)
        end
    else
        Bridge.Notify(locale:t('notify.NoInVehicle'))
    end
end

eventPublisher:subscribe('origen_inventory:vehicle:cruise', function()
 --   Vehicle.toggleCruiseMode()
end)
Vehicle.toggleEngine = function()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    if vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= playerPed then
        Bridge.Notify(locale:t('notify.NoInVehicle'))
        return false
    end

    local canUseEngine = Bridge.CanUseEngine(vehicle)

    if not canUseEngine then return end

    if GetIsVehicleEngineRunning(vehicle) then
        SetVehicleEngineOn(vehicle, false, false, true)
        SetVehicleUndriveable(vehicle, true)
        Bridge.Notify(locale:t('notify.engineoff'))
    else
        SetVehicleEngineOn(vehicle, true, false, true)
        SetVehicleUndriveable(vehicle, false)
        Bridge.Notify(locale:t('notify.engineon'))
    end

    return true
end

--- Confirmar el uso de controles
-- RegisterKeyMapping("motor", "Encender/Apagar motor", "MOUSE_BUTTON", "MOUSE_MIDDLE")
-- RegisterCommand('motor', function(source, args, raw)
--     Vehicle.toggleEngine()
-- end, false)

eventPublisher:subscribe('origen_inventory:vehicle:engine', function()
    Vehicle.toggleEngine()
end)

Vehicle.windows = {}
Vehicle.windows.states = {
    [0] = false,
    [1] = false,
    [2] = false,
    [3] = false,
    [4] = false,
    [5] = false,
    [6] = false,
    [7] = false
}
Vehicle.toggleWindows = function(windowIndex)
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    local vehclass = GetVehicleClass(vehicle)

    if not vehicle or vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= playerPed then
        Bridge.Notify(locale:t('notify.NoInVehicle'))
        return false
    end

    if vehclass == 8 or vehclass == 14 then
        Bridge.Notify(locale:t('notify.nodoors'))
        return false
    end

    local index = windowIndex
    if not index then
        Bridge.Notify(locale:t('notify.doorid'))
        return false
    end

    if VentanaBajada(vehicle, index) then
        RollUpWindow(vehicle, index)
        Vehicle.windows.porCoche[vehicle][index] = nil
    else
        RollDownWindow(vehicle, index)
        Vehicle.windows.porCoche[vehicle] = Vehicle.windows.porCoche[vehicle] or {}
        Vehicle.windows.porCoche[vehicle][index] = true
    end

    return true
end

--[[ Si una ventanilla esta bajada. El juego no lo dice: una ventanilla bajada
     sigue "intacta" para IsVehicleWindowIntact, asi que la pestaña de
     Vehiculo nunca la pintaba abierta. Se lleva aqui, por coche —antes era
     una sola lista para todos, y bajar una en un coche la daba por bajada en
     el siguiente—. ]]
Vehicle.windows.porCoche = {}
function VentanaBajada(vehicle, index)
    local c = Vehicle.windows.porCoche[vehicle]
    if c and not DoesEntityExist(vehicle) then
        Vehicle.windows.porCoche[vehicle] = nil
        return false
    end
    return c ~= nil and c[index] == true
end

eventPublisher:subscribe('origen_inventory:vehicle:toggle-front-left-window', function()
    Vehicle.toggleWindows(0)
end)

eventPublisher:subscribe('origen_inventory:vehicle:toggle-front-right-window', function()
    Vehicle.toggleWindows(1)
end)

eventPublisher:subscribe('origen_inventory:vehicle:open-acrobatics', function()
    exports.origen_inventory:CloseInventory()
    TriggerEvent('origen_utils:client:trucos')
end)

eventPublisher:subscribe('origen_inventory:vehicle:toggle-drift', function()
    TriggerEvent('origen_utils:client:ToggleDriftKit')
end)

eventPublisher:subscribe('origen_inventory:vehicle:carradio', function()
    exports.origen_inventory:CloseInventory()
    exports['origen_speaker']:OpenCarRadio()
end)

eventPublisher:subscribe('origen_inventory:vehicle:toggle-back-left-window', function()
    Vehicle.toggleWindows(2)
end)

eventPublisher:subscribe('origen_inventory:vehicle:toggle-back-right-window', function()
    Vehicle.toggleWindows(3)
end)

Vehicle.toggleDoor = function(doorIndex)
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    local vehclass = GetVehicleClass(vehicle)

    if not vehicle or vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= playerPed then
        Bridge.Notify(locale:t('notify.NoInVehicle'))
        return false
    end

    if vehclass == 8 or vehclass == 14 then
        Bridge.Notify(locale:t('notify.nodoors'))
        return false
    end

    local index = doorIndex
    if not index then
        Bridge.Notify(locale:t('notify.doorid'))
        return false
    end

    if not vehicle or vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= playerPed then
        Bridge.Notify(locale:t('notify.NoInVehicle'))
        return false
    end

    if not DoesVehicleHaveDoor(vehicle, index) then
        Bridge.Notify(locale:t('notify.nothisdoor'), 'error')
        return false
    end

    if IsVehicleDoorDamaged(vehicle, index) then
        Bridge.Notify(locale:t('notify.nothisdoor'), 'error')
        return false
    end

    if GetVehicleDoorAngleRatio(vehicle, index) == 0 then
        SetVehicleDoorOpen(vehicle, index, false, false)
    else
        SetVehicleDoorShut(vehicle, index, false)
    end

    return true
end

eventPublisher:subscribe('origen_inventory:vehicle:toggle-front-left-door', function()
    Vehicle.toggleDoor(0)
end)

eventPublisher:subscribe('origen_inventory:vehicle:toggle-front-right-door', function()
    Vehicle.toggleDoor(1)
end)

eventPublisher:subscribe('origen_inventory:vehicle:toggle-back-left-door', function()
    Vehicle.toggleDoor(2)
end)

eventPublisher:subscribe('origen_inventory:vehicle:toggle-back-right-door', function()
    Vehicle.toggleDoor(3)
end)

eventPublisher:subscribe('origen_inventory:vehicle:toggle-front-hood', function()
    Vehicle.toggleDoor(4)
end)

eventPublisher:subscribe('origen_inventory:vehicle:toggle-trunk', function()
    Vehicle.toggleDoor(5)
end)

Vehicle.changeToNextEmptySeat = function()
    local playerPed = PlayerPedId()
    if not IsPedInAnyVehicle(playerPed, false) then
        Bridge.Notify(locale:t('notify.NoInVehicle'))
        return false
    end

    local vehicle = GetVehiclePedIsIn(playerPed, false)
    -- if GetPedInVehicleSeat(vehicle, -1) ~= playerPed then
    --     Bridge.Notify(locale:t('notify.notdriver'))
    --     return false
    -- end

    local maxSeats = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle)) - 2
    local currentSeat = -1
    for i = -1, maxSeats do
        if GetPedInVehicleSeat(vehicle, i) == playerPed then
            currentSeat = i
            break
        end
    end

    local newSeat = currentSeat + 1
    if newSeat > maxSeats then
        newSeat = -1
    end

    local isFree = IsVehicleSeatFree(vehicle, newSeat)
    if not isFree then
        Bridge.Notify(locale:t('notify.seatoccupied'))
        return false
    end

    TaskWarpPedIntoVehicle(playerPed, vehicle, newSeat)

    local isOnVehicle = true
    local isDriver = newSeat == -1
    InventoryUI.UpdateVehicleState(isOnVehicle, isDriver)

    return true
end

eventPublisher:subscribe('origen_inventory:vehicle:seat', function()
    Vehicle.changeToNextEmptySeat()
end)

Vehicle.drift = {}
Vehicle.drift.mode = false
Vehicle.drift.handleMods = {
    { "fInitialDragCoeff",         90.22 },
    { "fDriveInertia",             .31 },
    { "fSteeringLock",             22 },
    { "fTractionCurveMax",         -1.1 },
    { "fTractionCurveMin",         -.4 },
    { "fTractionCurveLateral",     2.5 },
    { "fLowSpeedTractionLossMult", -.57 }
}
Vehicle.drift.handleToHumanLabel = {
    InitialDragCoeff = 'fInitialDragCoeff',
    DriveInertia = 'fDriveInertia',
    SteeringLock = 'fSteeringLock',
    TractionCurveMax = 'fTractionCurveMax',
    TractionCurveMin = 'fTractionCurveMin',
    TractionCurveLateral = 'fTractionCurveLateral',
    LowSpeedTractionLossMult = 'fLowSpeedTractionLossMult'
}
Vehicle.drift.setup = function()
    for k, v in pairs(Config.DriftHandling) do
        for i, value in ipairs(Vehicle.drift.handleMods) do
            if value[1] == Vehicle.drift.handleToHumanLabel[k] then
                value[2] = v
            end
        end
    end
end

Vehicle.drift.checkBug = function(vehicle)
    if GetVehicleTopSpeedModifier(vehicle) >= 100 then
        ModifyVehicleTopSpeed(vehicle, 0.0)
    end

    if GetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDragCoeff") > 90 then
        for index, value in ipairs(Vehicle.drift.handleMods) do
            SetVehicleHandlingFloat(vehicle, "CHandlingData", value[1],
                GetVehicleHandlingFloat(vehicle, "CHandlingData", value[1]) + value[2] * -1)
        end
    end
end

Vehicle.drift.checkBugThread = function()
    CreateThread(function()
        while Vehicle.drift.mode do
            local playerPed = PlayerPedId()
            local mounted = false

            if IsPedInAnyVehicle(playerPed, false) then
                if not mounted then
                    local vehicle = GetVehiclePedIsIn(playerPed, false)
                    if GetPedInVehicleSeat(vehicle, -1) == playerPed then
                        Vehicle.drift.checkBug(vehicle)
                        mounted = true
                    end
                end
            end
            Wait(5000)
        end
    end)
end

Vehicle.drift.toggle = function(vehicle, active)
    local modifier = 1

    if GetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDragCoeff") > 90 then
        Vehicle.drift.mode = true
    else
        Vehicle.drift.mode = false
    end

    if Vehicle.drift.mode then
        modifier = -1
    end

    local SetVHF = SetVehicleHandlingFloat
    local GetVHF = GetVehicleHandlingFloat

    for index, value in ipairs(Vehicle.drift.handleMods) do
        if value[1] ~= 'fLowSpeedTractionLossMult' or not Vehicle.drift.mode and value[2] > 1 then
            SetVHF(vehicle, "CHandlingData", value[1], GetVHF(vehicle, "CHandlingData", value[1]) + value[2] * modifier)
        end
    end

    if active then return end

    if Vehicle.drift.mode then
        Bridge.Notify(locale:t('notify.driftoff'))
        return
    end

    Bridge.Notify(locale:t('notify.drifton'))

    local GetVehiclePedIsIn = GetVehiclePedIsIn
    local IsControlJustPressed = IsControlJustPressed

    CreateThread(function()
        local currentvehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        while not vehicle.drift.mode do
            if IsControlJustPressed(0, 75) or GetVehiclePedIsIn(PlayerPedId(), false) ~= currentvehicle then
                Bridge.Notify(locale:t('notify.driftpause'))

                if GetVHF(currentvehicle, "CHandlingData", "fDriveBiasFront") ~= 1 then
                    Vehicle.drift.toggle(currentvehicle, true)
                end
                if GetVHF(currentvehicle, "CHandlingData", "fInitialDragCoeff") < 90 then
                    ModifyVehicleTopSpeed(currentvehicle, 0.0)
                else
                    if GetVHF(currentvehicle, "CHandlingData", "fDriveBiasFront") == 0.0 then
                        ModifyVehicleTopSpeed(currentvehicle, 190.0)
                    else
                        ModifyVehicleTopSpeed(currentvehicle, 100.0)
                    end
                end
                break
            end

            Wait(5)
        end
    end)
end
Vehicle.toggleDrift = function()
    if not Config.EnableDriftMode then return false end

    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)

    if vehicle == 0 and GetPedInVehicleSeat(vehicle, -1) ~= playerPed then
        Bridge.Notify(locale:t('notify.NoInVehicle'))
        return false
    end

    local speed = GetEntitySpeed(vehicle)
    if speed > 0.0 then
        Bridge.Notify(locale:t('notify.DriftWhileMoving'))
        return false
    end

    local VHF = GetVehicleHandlingFloat
    local progressAction = function(result)
        if not result then
            Bridge.Notify(locale:t('notify.Cancel'))
            return false
        end

        local vHandlingFront = VHF(vehicle, "CHandlingData", "fDriveBiasFront") ~= 1
        local vehicleOnAllWheels = IsVehicleOnAllWheels(vehicle)
        local vehicleClassWhistelisted = IsVehicleClassWhitelisted(GetVehicleClass(vehicle))

        if vHandlingFront and vehicleOnAllWheels and vehicleClassWhistelisted then
            Vehicle.drift.checkBugThread()
            Vehicle.drift.toggle(vehicle)
        end

        if VHF(vehicle, "CHandlingData", "fInitialDragCoeff") < 90 then
            ModifyVehicleTopSpeed(vehicle, 0.0)
        else
            if VHF(vehicle, "CHandlingData", "fDriveBiasFront") == 0.0 then
                ModifyVehicleTopSpeed(vehicle, 190.0)
            else
                ModifyVehicleTopSpeed(vehicle, 100.0)
            end
        end
    end

    Bridge.ProgressBar('drift_toggle', locale:t('notify.ToggleDrift'), 5000, false, false, false, progressAction)
    return true
end

eventPublisher:subscribe('origen_inventory:vehicle:drift', function()
    Vehicle.toggleDrift()
end)

exports('ToggleDriftMode', function(toggle)
    Config.EnableDriftMode = toggle and toggle or not Config.EnableDriftMode
end)

Vehicle.drift.setup()
