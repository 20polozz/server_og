local VehicleInteractions = {}
VehicleInteractions.__index = VehicleInteractions

function VehicleInteractions:new()
    local instance = setmetatable({}, VehicleInteractions)
    instance.config = lib.loadJson('qbx_vehiclepush.config')
    instance.isUiVisible = false
    instance.currentText = nil
    return instance
end

function VehicleInteractions:updateUI(show, text)
    if show then
        if not self.isUiVisible or self.currentText ~= text then
            exports['origen_hud']:setupControls({{ key = 'SHIFT + E', text = text }})
            self.isUiVisible = true
            self.currentText = text
        end
    else
        if self.isUiVisible then
            exports['origen_hud']:hideControls()
            self.isUiVisible = false
            self.currentText = nil
        end
    end
end

function VehicleInteractions:isVehicleValid(vehicle)
    local class = GetVehicleClass(vehicle)
    return class ~= 13 and class ~= 14 and class ~= 15 and class ~= 16
end

function VehicleInteractions:canPush(vehicle)
    local engineHealth = GetVehicleEngineHealth(vehicle)
    local fuelLevel = Entity(vehicle).state.fuel or 100
    return IsVehicleSeatFree(vehicle, -1) and (engineHealth <= self.config.damageNeeded or fuelLevel < 3)
end

function VehicleInteractions:flipVehicle(vehicle)
    self:updateUI(false)
    local success = lib.progressBar({
        duration = 5000,
        label = 'Volteando vehículo...',
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true },
        anim = {
            dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
            clip = 'machinic_loop_mechandplayer',
            flag = 17,
        }
    })

    if success then
        SetVehicleOnGroundProperly(vehicle)
    else
        ClearPedTasks(cache.ped)
    end
end

function VehicleInteractions:pushVehicle(vehicle)
    self:updateUI(false)
    NetworkRequestControlOfEntity(vehicle)

    local ped = cache.ped
    local dimensions = GetModelDimensions(GetEntityModel(vehicle))
    local vehicleCoords = GetEntityCoords(vehicle)
    local vehicleForward = GetEntityForwardVector(vehicle)
    local pedCoords = GetEntityCoords(ped)
    
    local isInFront = #(vehicleCoords - pedCoords + vehicleForward) < #(vehicleCoords - pedCoords - vehicleForward)
    local attachOffset = isInFront and {y = dimensions.y * -1 + 0.1, heading = 180.0} or {y = dimensions.y - 0.3, heading = 0.0}

    AttachEntityToEntity(ped, vehicle, GetPedBoneIndex(ped, 6286), 0.0, attachOffset.y, dimensions.z + 1.0, 0.0, 0.0, attachOffset.heading, false, false, false, true, 0, true)
    
    lib.requestAnimDict('missfinale_c2ig_11')
    TaskPlayAnim(ped, 'missfinale_c2ig_11', 'pushcar_offcliff_m', 2.0, -8.0, -1, 35, 0, false, false, false)

    while not cache.vehicle and IsDisabledControlPressed(0, 21) do
        Wait(0)
        if IsDisabledControlPressed(0, 34) then TaskVehicleTempAction(ped, vehicle, 11, 1) end
        if IsDisabledControlPressed(0, 9) then TaskVehicleTempAction(ped, vehicle, 10, 1) end

        SetVehicleForwardSpeed(vehicle, isInFront and -1.0 or 1.0)

        if HasEntityCollidedWithAnything(vehicle) then
            SetVehicleOnGroundProperly(vehicle)
        end
    end

    DetachEntity(ped, false, false)
    StopAnimTask(ped, 'missfinale_c2ig_11', 'pushcar_offcliff_m', 2.0)
    FreezeEntityPosition(ped, false)
end

function VehicleInteractions:start()
    CreateThread(function()
        while true do
            local sleep = 1000
            --[[ `invBusy` la levanta ox_lib en cada progressBar y la mantienen los
                 recursos que dejan al jugador con algo en las manos. Sin esto, el
                 aviso de empujar sale encima del suyo y los dos escuchan la [E]. ]]
            if LocalPlayer.state.invBusy then
                self:updateUI(false)
                goto continuar
            end

            do
            --[[ Buscar el coche mas cercano recorre TODOS los vehiculos cargados
                 (lib.getClosestVehicle tira de GetGamePool), y el statebag del
                 combustible es otra lectura. Antes se hacia cada fotograma en
                 cuanto habia un coche a 3 m —en un parking, siempre—: era lo que
                 mas pesaba de todo el servidor en el resmon (16/09).

                 Ahora se busca cada cuarto de segundo, y entre busqueda y
                 busqueda solo se mira la tecla, que si tiene que ser por
                 fotograma para no perder la pulsacion. ]]
            local pedCoords = GetEntityCoords(cache.ped)
            local vehicle = not cache.vehicle and lib.getClosestVehicle(pedCoords, 3.0)

            if vehicle then
                sleep = 250
                local isFlipped = not IsVehicleOnAllWheels(vehicle) and not GetVehicleTypeRaw(vehicle) == 11
                local canPush = self:isVehicleValid(vehicle) and self:canPush(vehicle)

                if isFlipped or canPush then
                    local actionText = isFlipped and 'Voltear' or 'Empujar'
                    self:updateUI(true, actionText)

                    local hasta = GetGameTimer() + 250
                    repeat
                        if IsControlPressed(0, 21) and IsControlJustPressed(0, 38) then
                            if isFlipped then self:flipVehicle(vehicle) else self:pushVehicle(vehicle) end
                            break
                        end
                        Wait(0)
                    until GetGameTimer() >= hasta or cache.vehicle or LocalPlayer.state.invBusy
                    sleep = 0
                else
                    self:updateUI(false)
                end
            else
                self:updateUI(false)
            end
            end

            ::continuar::
            Wait(sleep)
        end
    end)
end

local manager = VehicleInteractions:new()
manager:start()