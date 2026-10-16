local nozzleGrabTime = 0
local NOZZLE_COOLDOWN = 2000 -- 2 seconds in ms

CreateThread(function()
    local gasPumpModels = {
        `prop_gas_pump_1a`,
        `prop_gas_pump_1b`,
        `prop_gas_pump_1c`,
        `prop_gas_pump_1d`,
        `prop_gas_pump_old2`,
        `prop_gas_pump_old3`,
        `prop_vintage_pump`
    }

    local uiState = nil

    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        
        -- Buscar surtidor cercano
        local closestPump = nil
        local closestDist = 3.0
        
        for _, model in ipairs(gasPumpModels) do
            local pump = GetClosestObjectOfType(coords.x, coords.y, coords.z, 3.0, model, false, false, false)
            if pump ~= 0 then
                local pumpCoords = GetEntityCoords(pump)
                local dist = #(coords - pumpCoords)
                if dist < closestDist then
                    closestDist = dist
                    closestPump = pump
                end
            end
        end

        -- Son del propio recurso (nozzle.lua y refuel.lua): llamarlas por export
        -- cruzaba la frontera de exports para nada, y junto al surtidor, cada fotograma.
        local hasNozzle = HasNozzle()
        local pendingRefuel = GetPendingRefuel()

        -- PRIORIDAD 1: Si tiene manguera + vehículo cerca + repostaje pendiente → Repostar
        if hasNozzle and pendingRefuel then
            sleep = 0
            local vehicle = lib.getClosestVehicle(coords, 4.0, false)

            if vehicle then
                if uiState ~= 'refuel' then
                    lib.showTextUI('[E] Iniciar carga', {
                        position = "left-center",
                        icon = "gas-pump"
                    })
                    uiState = 'refuel'
                end

                if IsControlJustPressed(0, 38) then -- E
                    local success = exports['origen_fuel']:CompleteRefueling(vehicle)
                    if success then
                    end
                    lib.hideTextUI()
                    uiState = nil
                end
            else
                -- Tiene manguera pero no hay vehículo cerca, ocultar UI
                if uiState then
                    lib.hideTextUI()
                    uiState = nil
                end
            end

        -- PRIORIDAD 2: Si tiene manguera + cerca del surtidor + sin repostaje pendiente → Devolver (con cooldown)
        elseif hasNozzle and closestPump then
            sleep = 0
            local timeSinceGrab = GetGameTimer() - nozzleGrabTime
            if timeSinceGrab >= NOZZLE_COOLDOWN then
                if uiState ~= 'return' then
                    lib.showTextUI('[E] Devolver manguera', {
                        position = "left-center",
                        icon = "hand"
                    })
                    uiState = 'return'
                end

                if IsControlJustPressed(0, 38) then -- E
                    exports['origen_fuel']:ReturnNozzle()
                    nozzleGrabTime = 0
                end
            else
                if uiState then
                    lib.hideTextUI()
                    uiState = nil
                end
            end

        -- PRIORIDAD 3: Cerca del surtidor + sin manguera → Configurar o coger
        elseif closestPump and not hasNozzle then
            sleep = 0
            if not pendingRefuel then
                if uiState ~= 'config' then
                    lib.showTextUI('[E] Configurar repostaje', {
                        position = "left-center",
                        icon = "gas-pump"
                    })
                    uiState = 'config'
                end

                if IsControlJustPressed(0, 38) then -- E
                    local stationId = 1
                    local station = { name = "Gasolinera", prices = {}, stock = {} }
                    
                    local vehicle = lib.getClosestVehicle(coords, 10.0, false)
                    local currentFuel = 0
                    if vehicle then
                         currentFuel = Entity(vehicle).state.fuel or 0
                    end

                    OpenRefuelMenu(stationId, station, vehicle, currentFuel)
                end
            else
                 if uiState ~= 'grab' then
                    lib.showTextUI('[E] Coger manguera', {
                        position = "left-center",
                        icon = "hand"
                    })
                    uiState = 'grab'
                end

                if IsControlJustPressed(0, 38) then -- E
                    exports['origen_fuel']:GrabNozzle(closestPump)
                    nozzleGrabTime = GetGameTimer()
                end
            end

        -- Nada relevante, ocultar UI
        else
            if uiState then
                lib.hideTextUI()
                uiState = nil
            end
            sleep = 1000
        end

        Wait(sleep)
    end
end)