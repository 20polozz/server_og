local lastReport = 0

--[[ Lo llama `vehiclehandler`, que ya escucha `entityDamaged` y ya conoce la
     velocidad previa al impacto y el daño de chapa. Duplicar aqui esa escucha
     seria un segundo listener del mismo evento para calcular lo mismo. ]]
local function ReportCollision(vehicle, speedKmh, bodyDamage)
    if not Config.Collision.Enabled then return false end
    if cache.seat ~= -1 or not vehicle or vehicle ~= cache.vehicle then return false end
    if not DoesEntityExist(vehicle) or not NetworkGetEntityIsNetworked(vehicle) then return false end

    local speed = tonumber(speedKmh)
    if not speed or speed ~= speed or speed < Config.Collision.MinImpactSpeedKmh then return false end

    local damage = tonumber(bodyDamage)
    if not damage or damage <= 0 then return false end

    if not Mechanic.IsTrackableClass(GetVehicleClass(vehicle)) then return false end

    local now = GetGameTimer()
    if (now - lastReport) < Config.Collision.CooldownMs then return false end
    lastReport = now

    TriggerServerEvent('origen_mechanic:server:reportCollision', {
        netId = VehToNet(vehicle),
        speed = math.min(speed, Config.Collision.MaxImpactSpeedKmh)
    })

    return true
end
exports('ReportCollision', ReportCollision)
