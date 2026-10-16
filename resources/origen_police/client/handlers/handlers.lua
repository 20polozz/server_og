VehicleSitHandler = {
    name = "vehicle_sit",
    lastVehicle = nil,

    check = function(self)
        local ped = PlayerPedId()
        local currentRaw = GetVehiclePedIsIn(ped, false)   -- 0 si no está en vehículo
        local current = nil

        if currentRaw ~= 0 then
            current = currentRaw      -- si está en un vehículo, current = su ID
        end

        local previous = self.lastVehicle   -- guardamos el ID anterior (o nil)
        -- Actualizamos lastVehicle para la siguiente iteración
        self.lastVehicle = current

        return current, previous
    end
}