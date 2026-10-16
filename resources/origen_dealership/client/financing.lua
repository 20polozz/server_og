-- El primer punto de entrega del concesionario que no tenga un coche encima.
local function puntoEntregaLibre(dealership)
    local puntos = dealership and dealership.markers and dealership.markers.car_delivery
    for _, coords in ipairs(puntos or {}) do
        local vehicleInArea = GetClosestVehicle(coords.x, coords.y, coords.z, 3.0, 0, 71)
        if vehicleInArea == 0 or not DoesEntityExist(vehicleInArea) then
            return coords
        end
    end
end

RegisterNUICallback('financing:financeVehicle', function(data, cb)
    -- Antes de que el servidor cobre la entrada y guarde el plan: si no hay
    -- dónde entregar el coche, se dice ahora y no se cobra nada.
    if Config.VehiclePurchase.spawnVehicle then
        local dealership = data and dealershipsData[data.dealershipId]
        if not puntoEntregaLibre(dealership) then
            return cb({
                success = false,
                message = 'Todos los puntos de entrega están ocupados. Espera a que se libere alguno.'
            })
        end
    end

    local retval = lib.callback.await('origen_dealerships:financing:financeVehicle', false, data)
    cb(retval or { success = false, message = locale('errors.general') })
end)

-- Un color solo vale si trae sus tres canales; si no, se descarta.
local function colorValido(c)
    if type(c) == 'table' and tonumber(c.r) and tonumber(c.g) and tonumber(c.b) then
        return c
    end
end

-- Todo lo que hace la entrega del coche financiado. Va aparte para poder
-- llamarlo con pcall: si algo falla a mitad (o sale por una de sus salidas
-- tempranas), el evento de abajo tiene que soltar igualmente el ratón, quitar
-- el negro, limpiar la cámara y devolver el routing bucket.
local function entregarVehiculoFinanciado(data)
    local dealershipId = data.dealershipId
    local dealership = dealershipsData[dealershipId]

    if not dealership then
        return
    end

    DoScreenFadeOut(500)
    Wait(500)
    Custom.Notify(locale('notifications.vehicle_financed'), 'success')

    -- Fuera de la vista previa ANTES de sacar el coche: si se crea con el
    -- jugador todavía en su routing bucket privado, el coche se queda en esa
    -- instancia y al volver al mundo no está.
    -- cleanupPreviewCamera vacía vehicleColors: se guardan antes los tonos elegidos.
    local colores = { primary = vehicleColors.primary, secondary = vehicleColors.secondary }
    cleanupPreviewCamera()
    lib.callback.await('origen_dealership:routingBucketHandler', false)

    local hash = GetHashKey(data.model)
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end

    -- La entrada y el plan ya están cobrados y guardados. Si el coche no se
    -- puede sacar aquí (modelo que no carga, punto ocupado en este medio
    -- segundo, CreateVehicle que falla), se da de alta igual y queda en el garaje.
    local purchasedVehicle = nil
    local purchaseCoords = Config.VehiclePurchase.spawnVehicle and HasModelLoaded(hash) and puntoEntregaLibre(dealership)
    if purchaseCoords then
        purchasedVehicle = CreateVehicle(hash, purchaseCoords.x, purchaseCoords.y, purchaseCoords.z, purchaseCoords.heading, true, false)
    end

    if Config.VehiclePurchase.spawnVehicle and not (purchasedVehicle and DoesEntityExist(purchasedVehicle)) then
        SetModelAsNoLongerNeeded(hash)
        local dbResult = lib.callback.await('origen_dealerships:sv:addVehicleToDatabase', false, {
            vehicleModel = data.model,
            plate = data.plate
        })
        if dbResult and dbResult.success then
            Custom.Notify('No se pudo sacar el coche aquí: lo tienes en el garaje.', 'error')
        else
            Custom.Notify(locale('notifications.error_creating_vehicle'), 'error')
        end
        return
    end

    if Config.VehiclePurchase.spawnVehicle then

        SetModelAsNoLongerNeeded(hash)
        SetVehicleOnGroundProperly(purchasedVehicle)
        SetVehicleNumberPlateText(purchasedVehicle, data.plate)
        -- vehicleColors solo se llena si el jugador pulsó un tono (o hizo una
        -- prueba); sin eso está vacío y leer .primary.r petaba con la pantalla
        -- en negro. Primero lo que se vio en la vista previa, luego lo que mandó
        -- la NUI, y si no hay ninguno se deja el color de fábrica.
        local primario = colorValido(colores.primary) or colorValido(data.firstColor)
        local secundario = colorValido(colores.secondary) or colorValido(data.secondaryColor)
        if primario then
            SetVehicleCustomPrimaryColour(purchasedVehicle, primario.r, primario.g, primario.b)
        end
        if secundario then
            SetVehicleCustomSecondaryColour(purchasedVehicle, secundario.r, secundario.g, secundario.b)
        end
        SetEntityAsMissionEntity(purchasedVehicle, true, true)
        TaskWarpPedIntoVehicle(cache.ped, purchasedVehicle, -1)
        SetVehicleEngineOn(purchasedVehicle, true, true, false)
        SetVehicleUndriveable(purchasedVehicle, false)
        SetVehicleDirtLevel(purchasedVehicle, 0.0)
        
        Wait(200)

        TriggerEvent('vehiclekeys:client:SetOwner', GetVehicleNumberPlateText(purchasedVehicle))
        
        local props = Custom.GetVehicleProps(purchasedVehicle)
        
        local dbResult = lib.callback.await('origen_dealerships:sv:addVehicleToDatabase', false, {
            vehicleModel = data.model,
            plate = data.plate,
            props = props
        })
        
        if Config.Debug then
            print('^2[ORIGEN DEALERSHIPS] ^7Resultado DB financiamiento:', json.encode(dbResult))
        end
        
        if Config.VehiclePurchase.giveKeysOnPurchase then
            Custom.GiveKeys(purchasedVehicle, data.plate)
        end
    else
        SetModelAsNoLongerNeeded(hash)
        
        local props = {
            model = GetHashKey(data.model),
            plate = data.plate,
            bodyHealth = 1000.0,
            engineHealth = 1000.0,
            fuelLevel = 100.0,
            dirtLevel = 0.0,
            color1 = data.firstColor,
            color2 = data.secondaryColor
        }
        
        local dbResult = lib.callback.await('origen_dealerships:sv:addVehicleToDatabase', false, {
            vehicleModel = data.model,
            plate = data.plate,
            props = props
        })
        
        if Config.Debug then
            print('^2[ORIGEN DEALERSHIPS] ^7Resultado DB financiamiento:', json.encode(dbResult))
        end
    end
end

RegisterNetEvent('origen_dealerships:financing:finishingPayment', function(data)
    local ok, err = pcall(entregarVehiculoFinanciado, data or {})
    if not ok then
        print('^1[ORIGEN DEALERSHIPS] ^7Fallo al entregar el vehículo financiado:', tostring(err))
    end

    -- Salida común: pase lo que pase arriba, se quita el negro, se suelta el
    -- ratón y se limpia la cámara. La NUI ya ha cerrado el menú al recibir el
    -- success del servidor, así que si esto no llega el jugador queda preso.
    DoScreenFadeIn(2000)

    -- Cerrar NUI completamente y limpiar cámara después de completar la compra financiada
    SetNuiFocus(false, false)
    cleanupPreviewCamera()

    -- Restaurar routing bucket del jugador
    lib.callback.await('origen_dealership:routingBucketHandler', false)
end)