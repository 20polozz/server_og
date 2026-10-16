local IsPositionOccupied       = IsPositionOccupied
local CreateVehicle            = CreateVehicle
local SetModelAsNoLongerNeeded = SetModelAsNoLongerNeeded
local NetworkFadeInEntity      = NetworkFadeInEntity
local TaskEnterVehicle         = TaskEnterVehicle
local GetPedInVehicleSeat      = GetPedInVehicleSeat
local IsControlJustReleased    = IsControlJustReleased
local TaskLeaveVehicle         = TaskLeaveVehicle
local FreezeEntityPosition     = FreezeEntityPosition
local NetworkFadeOutEntity     = NetworkFadeOutEntity
local DeleteVehicle            = DeleteVehicle
local DrawMarker               = DrawMarker
local Wait                     = Wait
local TaskVehicleDriveWander   = TaskVehicleDriveWander
local DeletePed                = DeletePed

local useOrigenPolicePoints = lib.load("config").useOrigenPolicePoints
if useOrigenPolicePoints then
    function initGarage() end
    function unloadGarage() end
    return
end

local depositPositions         = {}
local giveVehicleKeys          = lib.load("config").giveVehicleKeys
local removeVehicleKeys        = lib.load("config").removeVehicleKeys

local function openCarList(garage)
    local menu = {
        {
            header = locale("vehiclemenu_label") or "Garaje SAMS",
            isMenuHeader = true,
            icon = "fas fa-ambulance",
        }
    }
    local playerPed = cache.ped
    local jobGrade = Framework.getPlayerJobGrade()

    for k, v in pairs(garage.vehicles) do
        if jobGrade >= v.min_grade then
            table.insert(menu, {
                header = v.label,
                txt = "Sacar vehículo del garaje médico",
                icon = "fas fa-car-side",
                params = {
                    isAction = true,
                    event = function()
                        local isPosOccupied = IsPositionOccupied(garage.spawn.x, garage.spawn.y, garage.spawn.z, 10, false, true, true, false, false, 0, false)

                        if isPosOccupied then return utils.showNotification("El punto de salida está ocupado", "error") end

                        local model = lib.requestModel(v.spawn_code)

                        if not model then return end

                        local vehicle = CreateVehicle(model, garage.spawn.x, garage.spawn.y, garage.spawn.z, garage.spawn.w, true, false)
                        SetModelAsNoLongerNeeded(model)
                        NetworkFadeInEntity(vehicle, 1)
                        lib.setVehicleProperties(vehicle, v.modifications)

                        local plate = lib.getVehicleProperties(vehicle).plate
                        giveVehicleKeys(vehicle, plate)

                        TaskEnterVehicle(playerPed, vehicle, -1, -1, 1.0, 1, 0)
                        utils.closeMenu()
                    end
                }
            })
        end
    end

    menu[#menu + 1] = {
        header = "Cerrar",
        txt = "Cerrar garaje",
        icon = "fas fa-xmark",
        params = {
            isAction = true,
            event = function()
                utils.closeMenu()
            end
        }
    }

    utils.openMenu(menu)
end

local usePedToDepositVehicle = lib.load("config").usePedToDepositVehicle

local function depositVehicle(data)
    if Framework.hasJob(data.jobs) then
        local playerPed = cache.ped
        local playerVehicle = cache.vehicle
        if playerVehicle and GetPedInVehicleSeat(playerVehicle, -1) ~= 0 then
            DrawMarker(0, data.coords.x, data.coords.y, data.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.8,
                0.8, 0.8, 220, 221, 224, 160, false, true, 2, nil, nil, false)

            if data.currentDistance < 2 and IsControlJustReleased(0, 38) then
                TaskLeaveVehicle(playerPed, playerVehicle, 64)

                while cache.vehicle do Wait(100) end

                local vehicleToDelete = playerVehicle

                local plate = lib.getVehicleProperties(playerVehicle).plate
                removeVehicleKeys(playerVehicle, plate)

                lib.hideTextUI()

                if usePedToDepositVehicle then
                    local emsDriver = utils.createPed(data.model, data.driverSpawnCoords)
                    FreezeEntityPosition(emsDriver, false)

                    TaskEnterVehicle(emsDriver, vehicleToDelete, -1, -1, 1.0, 1, 0)

                    Wait(1000)

                    while GetPedInVehicleSeat(vehicleToDelete, 0) ~= 0 do Wait(1) end
                    while GetPedInVehicleSeat(vehicleToDelete, 1) ~= 0 do Wait(1) end
                    while GetPedInVehicleSeat(vehicleToDelete, 2) ~= 0 do Wait(1) end

                    TaskVehicleDriveWander(emsDriver, vehicleToDelete, 60.0, 8)

                    Wait(20 * 1000) -- 20 seconds

                    NetworkFadeOutEntity(vehicleToDelete, false, true)
                    NetworkFadeOutEntity(emsDriver, false, true)

                    Wait(1 * 1000)

                    DeletePed(emsDriver)
                    emsDriver = nil
                end

                DeleteVehicle(vehicleToDelete)
                vehicleToDelete = nil
            end
        end
    end
end

function initGarage(data, jobs)
    for index, garage in pairs(data) do
        local ped = utils.createPed(garage.model, garage.pedPos)

        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)

        -- Interaction Point for Garage Ped
        local pedPoint = lib.points.new({
            coords = garage.pedPos.xyz,
            distance = 2.5,
            onEnter = function(self)
                if not cache.vehicle and Framework.hasJob(jobs) then
                    lib.showTextUI('[E] - ' .. locale('garage_interact_label'))
                end
            end,
            onExit = function(self)
                lib.hideTextUI()
            end,
            nearby = function(self)
                if not cache.vehicle and Framework.hasJob(jobs) then
                    if self.currentDistance < 2.0 and IsControlJustReleased(0, 38) then
                        openCarList(garage)
                    end
                end
            end
        })
        table.insert(depositPositions, pedPoint)

        -- Deposit Point for Vehicles
        local depositPoint = lib.points.new({
            coords = garage.deposit,
            distance = 5,
            onEnter = function(self)
                if cache.vehicle and Framework.hasJob(jobs) then
                    lib.showTextUI('[E] - ' .. locale('deposit_vehicle'))
                end
            end,
            onExit = function(self)
                lib.hideTextUI()
            end,
            nearby = function(self)
                self.model = garage.model
                self.driverSpawnCoords = garage.driverSpawnCoords
                self.jobs = jobs
                depositVehicle(self)
            end
        })
        table.insert(depositPositions, depositPoint)
    end
end

function unloadGarage()
    for _, point in pairs(depositPositions) do
        point:remove()
        utils.debug("Point", _, "removed")
    end
    depositPositions = {}
end
