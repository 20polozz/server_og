-- =============================================
-- origen_anticheat — Client: Velocidad de Vehículo
-- =============================================

function CheckVehicleSpeed()
    if not Config.Modules.VehicleSpeed.enabled then return end

    local ped     = PlayerPedId()
    if not DoesEntityExist(ped) then return end
    if not IsPedInAnyVehicle(ped, false) then return end

    local vehicle = GetVehiclePedIsIn(ped, false)
    if not DoesEntityExist(vehicle) then return end

    -- Ignorar si el jugador no es el conductor
    if GetPedInVehicleSeat(vehicle, -1) ~= ped then return end

    local speed = GetEntitySpeed(vehicle)  -- en m/s

    if speed > Config.Thresholds.VehicleMaxSpeed then
        local speedKmh = math.floor(speed * 3.6)
        ReportViolation(
            AC.Modules.VehicleSpeed,
            string.format('Velocidad de vehículo excesiva: %d km/h (%.1f m/s)', speedKmh, speed)
        )
    end
end
