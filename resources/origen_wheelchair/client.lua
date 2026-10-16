-- ============================================================
-- origen_wheelchair | client.lua
-- Spawnea la silla de ruedas, muestra texto de recogida con E
-- El item se usa vía origen_inventory (client.export)
-- ============================================================

local myWheelchair = nil   -- entidad local de la silla spawneada
local myWheelchairNet = nil -- netId de la silla spawneada
local isSpawning = false    -- flag para evitar spam de spawn

-- ── Export que llama origen_inventory al usar el item ───────
exports('UseWheelchair', function(slot, item)
    if isSpawning then return end

    if myWheelchair and DoesEntityExist(myWheelchair) then
        exports.qbx_core:Notify('Ya tienes una silla de ruedas desplegada', 'error')
        return
    end

    isSpawning = true

    -- PRIMER PASO: El servidor debe quitar el item. Si tiene éxito, spawneamos.
    lib.callback('origen_wheelchair:server:consumeItem', false, function(success)
        if not success then
            exports.qbx_core:Notify('No se pudo usar el item o no lo tienes', 'error')
            isSpawning = false
            return
        end

        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        local forward = GetEntityForwardVector(ped)
        local spawnPos = coords + forward * Config.SpawnOffset

        local model = joaat(Config.VehicleModel)
        RequestModel(model)
        local timeout = 0
        while not HasModelLoaded(model) do
            Wait(10)
            timeout = timeout + 10
            if timeout > 5000 then
                isSpawning = false
                return
            end
        end

        local vehicle = CreateVehicle(model, spawnPos.x, spawnPos.y, spawnPos.z, heading, true, false)
        SetModelAsNoLongerNeeded(model)

        if not vehicle or vehicle == 0 then
            isSpawning = false
            -- Si falla el spawn, devolvemos el item por si acaso
            TriggerServerEvent('origen_wheelchair:server:returnItemFailure')
            return
        end

        SetVehicleNumberPlateText(vehicle, "SILLA" .. tostring(math.random(100, 999)))
        SetVehicleOnGroundProperly(vehicle)
        SetEntityAsMissionEntity(vehicle, true, true)
        SetVehicleDoorsLocked(vehicle, 1)
        SetVehicleFuelLevel(vehicle, 100.0)

        local netTimeout = 0
        while not NetworkGetEntityIsNetworked(vehicle) do
            Wait(10)
            netTimeout = netTimeout + 10
            if netTimeout > 3000 then break end
        end

        local netId = VehToNet(vehicle)
        myWheelchair = vehicle
        myWheelchairNet = netId

        TriggerServerEvent('origen_wheelchair:server:giveKeys', netId)
        exports.qbx_core:Notify('Has desplegado la silla de ruedas', 'success')
        isSpawning = false
    end)
end)

-- ── Hilo para mostrar texto de recogida con E ──────────────
local showingHelp = false
CreateThread(function()
    while true do
        local sleep = 1000

        if myWheelchair and DoesEntityExist(myWheelchair) then
            local ped = PlayerPedId()
            local playerCoords = GetEntityCoords(ped)
            local chairCoords = GetEntityCoords(myWheelchair)
            local dist = #(playerCoords - chairCoords)

            if dist <= Config.PickupDistance then
                -- Verificar que NO está dentro del vehículo
                local currentVeh = GetVehiclePedIsIn(ped, false)
                local isInChair = currentVeh == myWheelchair

                if not isInChair then
                    sleep = 0
                    -- Mostrar texto con origen_notify
                    if not showingHelp then
                        exports.origen_notify:DrawText('E', Config.PickupText)
                        showingHelp = true
                    end

                    -- Detectar pulsación de E (INPUT_CONTEXT = 38)
                    if IsControlJustReleased(0, 38) then
                        PickupWheelchair()
                    end
                elseif showingHelp then
                    exports.origen_notify:HideText()
                    showingHelp = false
                end
            elseif dist <= 10.0 then
                sleep = 500
                if showingHelp then
                    exports.origen_notify:HideText()
                    showingHelp = false
                end
            elseif showingHelp then
                exports.origen_notify:HideText()
                showingHelp = false
            end
        elseif showingHelp then
            exports.origen_notify:HideText()
            showingHelp = false
        end

        Wait(sleep)
    end
end)

-- ── Función para recoger la silla ──────────────────────────
function PickupWheelchair()
    if not myWheelchair or not DoesEntityExist(myWheelchair) then
        myWheelchair = nil
        myWheelchairNet = nil
        return
    end

    local netId = myWheelchairNet

    -- Limpiar referencia local
    myWheelchair = nil
    myWheelchairNet = nil

    if showingHelp then
        exports.origen_notify:HideText()
        showingHelp = false
    end

    -- Pedir al server que devuelva el item y borre el vehículo
    TriggerServerEvent('origen_wheelchair:server:pickupChair', netId)

    exports.qbx_core:Notify('Has recogido la silla de ruedas', 'success')
end

-- ── Limpiar al cambiar de personaje / desconectar ──────────
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if myWheelchair and DoesEntityExist(myWheelchair) then
        DeleteEntity(myWheelchair)
        myWheelchair = nil
        myWheelchairNet = nil
    end
end)
