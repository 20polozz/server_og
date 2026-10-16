--[[ COMPRAVENTA DE VEHÍCULOS: lo que ve y hace el jugador.

     Estaba en `origen_compraventa`, un recurso aparte que solo se abría desde
     aquí y que solo escribía aquí. Ver `config/compraventa.lua` para por qué se
     juntó.

     La tarjeta flotante que sale al acercarte a un coche en exposición ya no
     tiene su propia página: se pinta en la interfaz de este recurso, en
     `ui/source/src/components/TarjetaVehiculo.vue`. El mensaje que la mueve
     sigue llamándose `updateCard`.
]]

local currentBusinessId = false
local hasBusinessAccess = false

local function GetBusinessId()
    local isOnDuty = LocalPlayer.state.isOnDuty
    if type(isOnDuty) == "string" or type(isOnDuty) == "number" then
        return isOnDuty
    end
    
    local PlayerData = exports.qbx_core:GetPlayerData()
    if PlayerData and PlayerData.job and PlayerData.job.onduty then
        return PlayerData.job.name
    end
    
    return false
end

CreateThread(function()
    while true do
        Wait(2000)
        local bId = GetBusinessId()
        if bId ~= currentBusinessId then
            currentBusinessId = bId
            if bId then
                lib.callback('origen_businesses:compraventa:server:IsBusinessAllowed', false, function(isAllowed)
                    hasBusinessAccess = isAllowed
                end, bId)
            else
                hasBusinessAccess = false
            end
        end
    end
end)

local function CanAccessBusiness()
    if not currentBusinessId then return false end
    return hasBusinessAccess and currentBusinessId or false
end

RegisterCommand('compraventa', function()
    local businessId = CanAccessBusiness()
    if not businessId then 
        lib.notify({ title = 'Sin Acceso', description = 'Debes estar de servicio en un negocio autorizado.', type = 'error' })
        return 
    end

    local menu = {
        {
            header = 'Menú de Compraventa',
            txt = 'Gestión del negocio',
            isMenuHeader = true,
            icon = 'fa-solid fa-car'
        },
        {
            header = 'Comprar Vehículo para el Local',
            txt = 'El negocio compra el coche y pasa al stock.',
            icon = 'fa-solid fa-handshake',
            params = { event = 'origen_businesses:compraventa:client:OpenBuyMenu', args = { businessId = businessId } }
        },
        {
            header = 'Garaje de Empresa (Stock)',
            txt = 'Ver vehículos en el garaje del negocio.',
            icon = 'fa-solid fa-warehouse',
            params = { event = 'origen_businesses:compraventa:client:OpenStockGarage', args = { businessId = businessId } }
        },
        {
            header = 'Gestionar Vehículo Actual',
            txt = 'Poner/quitar de exposición el vehículo en el que estás.',
            icon = 'fa-solid fa-tag',
            params = { event = 'origen_businesses:compraventa:client:ManageCurrentVehicle', args = { businessId = businessId } }
        },
        {
            header = 'Traspaso entre Particulares',
            txt = 'Transferir de un jugador a otro.',
            icon = 'fa-solid fa-file-contract',
            params = { event = 'origen_businesses:compraventa:client:OpenTransferMenu', args = { businessId = businessId } }
        }
    }

    exports['org-menu']:openMenu(menu)
end)

-- ==========================================
-- 1. COMPRAR PARA EL LOCAL
-- ==========================================
--[[ LAS CUATRO PUERTAS DE LA COMPRAVENTA

     Son las que abre el panel del negocio. Van como funciones con nombre —y el
     evento colgado de ellas— por dos motivos:

       - El panel las llama ahora directamente, sin pasar por el planificador
         de eventos, que es lo que se gana al estar en el mismo recurso.
       - Pero el menu de `/compraventa` las abre con `org-menu`, que dispara
         eventos por nombre. Asi que el evento tiene que seguir existiendo.

     Una sola implementacion, dos maneras de llegar. ]]
Compraventa = Compraventa or {}

function Compraventa.AbrirCompra(data)
    local businessId = data.businessId
    local coords = GetEntityCoords(PlayerPedId())
    local defaultPlate = ""
    
    local closestVehicle = lib.getClosestVehicle(coords, 5.0, true)
    if closestVehicle and closestVehicle ~= 0 then
        defaultPlate = GetVehicleNumberPlateText(closestVehicle) or ""
        defaultPlate = string.gsub(defaultPlate, "^%s*(.-)%s*$", "%1")
    end

    local input = exports['org-input']:ShowInput({
        header = 'Comprar para el Local',
        submitText = 'Hacer Oferta',
        icon = 'fa-solid fa-handshake',
        inputs = {
            { type = "text", name = "plate", text = "Matrícula del Vehículo", default = defaultPlate, isRequired = true },
            { type = "number", name = "sellerId", text = "ID Vendedor (Dueño)", isRequired = true },
            { type = "number", name = "price", text = "Precio de Compra ($) [Paga el negocio]", isRequired = true }
        }
    })
    
    if not input then return end
    TriggerServerEvent('origen_businesses:compraventa:server:StartBuyForBusiness', string.gsub(input.plate, "^%s*(.-)%s*$", "%1"), input.sellerId, input.price, businessId)
end

RegisterNetEvent('origen_businesses:compraventa:client:OpenBuyMenu', Compraventa.AbrirCompra)

RegisterNetEvent('origen_businesses:compraventa:client:ShowBusinessBuyProposal', function(plate, price, employeeName, businessName)
    local alert = exports['org-input']:ShowInput({
        header = 'Oferta de Compra',
        submitText = 'Responder Oferta',
        icon = 'fa-solid fa-file-signature',
        inputs = {
            { type = "radio", name = "confirm", text = "El local '"..businessName.."' (Emp: "..employeeName..") te ofrece $"..price.." por tu vehículo con matrícula "..plate..".", options = {
                {value = "yes", text = "Sí, vender mi vehículo"},
                {value = "no", text = "No, rechazar oferta"}
            }, isRequired = true }
        }
    })
    
    if alert and alert.confirm == "yes" then
        TriggerServerEvent('origen_businesses:compraventa:server:ConfirmBuyForBusiness', plate, price)
    else
        TriggerServerEvent('origen_businesses:compraventa:server:CancelTransfer', plate)
    end
end)

--[[ LA PROPUESTA QUE EL COMPRADOR NUNCA VEIA

     El traspaso entre particulares no ha funcionado nunca, y no por la fusion:
     ya estaba asi. El empleado lo empezaba, el servidor apuntaba el traspaso y
     le mandaba al comprador `ShowPurchaseProposal`... que no escuchaba nadie.

     Sin nadie escuchando, al comprador no se le preguntaba, y sin su respuesta
     no se disparaba `ConfirmTransfer`: la operacion se quedaba a medias para
     siempre. Salio al contar los eventos tras juntar los dos recursos —el
     servidor manda cinco al cliente y el cliente solo oia cuatro—, que es de
     las cosas que solo se ven cuando las dos mitades estan en la misma casa.

     Se escribe igual que su hermana `ShowBusinessBuyProposal`, que si estaba y
     si funciona: se pregunta, y con el si se confirma; con el no o cerrando, se
     cancela para que el traspaso no se quede colgado ocupando la matricula.

     El precio se devuelve tal cual llego: el servidor lo compara con el que
     apunto y rechaza la operacion si no cuadra, que es lo que impide que se
     confirme un precio distinto del que se enseño. ]]
RegisterNetEvent('origen_businesses:compraventa:client:ShowPurchaseProposal',
function(plate, vehicleModel, sellerName, price, employeeName, businessId)
    local alert = exports['org-input']:ShowInput({
        header = 'Propuesta de Compra',
        submitText = 'Responder',
        icon = 'fa-solid fa-file-contract',
        inputs = {
            { type = "radio", name = "confirm", text = ("%s te vende su %s (%s) por $%s. Da fe: %s.")
                :format(sellerName, vehicleModel or 'vehículo', plate, price, employeeName),
                options = {
                    { value = "yes", text = "Sí, comprar el vehículo" },
                    { value = "no", text = "No, rechazar" },
                }, isRequired = true }
        }
    })

    if alert and alert.confirm == "yes" then
        TriggerServerEvent('origen_businesses:compraventa:server:ConfirmTransfer', plate, price)
    else
        TriggerServerEvent('origen_businesses:compraventa:server:CancelTransfer', plate)
    end
end)

-- ==========================================
-- 2. GARAJE DE EMPRESA (STOCK)
-- ==========================================
function Compraventa.AbrirGaraje(data)
    lib.callback('origen_businesses:compraventa:server:GetBusinessStock', false, function(vehicles)
        local menu = {
            {
                header = 'Stock de ' .. string.upper(data.businessId),
                txt = 'Vehículos propiedad del negocio',
                isMenuHeader = true,
                icon = 'fa-solid fa-warehouse'
            }
        }

        if #vehicles == 0 then
            table.insert(menu, {
                header = 'Sin vehículos',
                txt = 'El negocio no tiene vehículos en stock.',
                icon = 'fa-solid fa-car-tunnel'
            })
        else
            for _, veh in ipairs(vehicles) do
                local stateTxt = veh.state == 1 and 'En Garaje' or 'Fuera'
                table.insert(menu, {
                    header = veh.vehicle .. ' [' .. veh.plate .. ']',
                    txt = 'Motor: ' .. math.floor(veh.engine/10) .. '% | Estado: ' .. stateTxt,
                    icon = 'fa-solid fa-car',
                    disabled = (veh.state == 0),
                    params = {
                        event = 'origen_businesses:compraventa:client:SpawnStockVehicle',
                        args = { plate = veh.plate, vehicle = veh.vehicle, state = veh.state, mods = veh.mods }
                    }
                })
            end
        end

        exports['org-menu']:openMenu(menu)
    end, data.businessId)
end

RegisterNetEvent('origen_businesses:compraventa:client:OpenStockGarage', Compraventa.AbrirGaraje)

RegisterNetEvent('origen_businesses:compraventa:client:SpawnStockVehicle', function(data)
    if data.state == 0 then
        lib.notify({title = 'Compraventa', description = 'Este vehículo ya está fuera.', type = 'error'})
        return
    end

    local coords = GetEntityCoords(PlayerPedId())
    local heading = GetEntityHeading(PlayerPedId())
    
    lib.callback('origen_businesses:compraventa:server:SpawnBusinessVehicle', false, function(netId)
        if netId then
            local veh = NetToVeh(netId)
            SetPedIntoVehicle(PlayerPedId(), veh, -1)
            TriggerEvent("vehiclekeys:client:SetOwner", data.plate)
            TriggerServerEvent("qb-vehiclekeys:server:AcquireVehicleKeys", data.plate)
            lib.notify({title = 'Garaje', description = 'Vehículo sacado del garaje.', type = 'success'})
        else
            lib.notify({title = 'Compraventa', description = 'No se ha podido sacar el vehículo. ¿Ya está fuera?', type = 'error'})
        end
    end, data.plate, coords, heading)
end)

-- ==========================================
-- 3. EXPOSICIÓN (PONER / QUITAR)
-- ==========================================
function Compraventa.GestionarVehiculoActual(data)
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        lib.notify({title = 'Compraventa', description = 'Debes estar dentro de un vehículo.', type = 'error'})
        return
    end

    local veh = GetVehiclePedIsIn(ped, false)
    if GetPedInVehicleSeat(veh, -1) ~= ped then
        lib.notify({title = 'Compraventa', description = 'Debes ser el conductor.', type = 'error'})
        return
    end

    local plate = string.gsub(GetVehicleNumberPlateText(veh), "^%s*(.-)%s*$", "%1")
    
    lib.callback('origen_businesses:compraventa:server:CheckExhibitionStatus', false, function(isExhibited, price, isOwnedByBusiness)
        if not isOwnedByBusiness then
            lib.notify({title = 'Compraventa', description = 'Este vehículo no pertenece a '..data.businessId..'.', type = 'error'})
            return
        end

        local menu = {
            {
                header = 'Gestionar Vehículo',
                isMenuHeader = true
            }
        }

        if isExhibited then
            table.insert(menu, {
                header = 'Retirar de Exposición',
                txt = 'Quita este vehículo de la venta.',
                icon = 'fa-solid fa-eye-slash',
                params = {
                    event = 'origen_businesses:compraventa:client:RemoveExhibitionInput',
                    args = { plate = plate, netId = NetworkGetNetworkIdFromEntity(veh) }
                }
            })
        else
            table.insert(menu, {
                header = 'Poner en Exposición',
                txt = 'Pone el vehículo en venta en este mismo punto.',
                icon = 'fa-solid fa-tag',
                params = {
                    event = 'origen_businesses:compraventa:client:SetExhibitionInput',
                    args = { plate = plate, businessId = data.businessId, netId = NetworkGetNetworkIdFromEntity(veh) }
                }
            })
            table.insert(menu, {
                header = 'Guardar en Garaje',
                txt = 'Guarda el vehículo en el stock de la empresa.',
                icon = 'fa-solid fa-warehouse',
                params = {
                    event = 'origen_businesses:compraventa:client:StoreVehicle',
                    args = { plate = plate, netId = NetworkGetNetworkIdFromEntity(veh) }
                }
            })
        end

        exports['org-menu']:openMenu(menu)
    end, plate, data.businessId)
end

RegisterNetEvent('origen_businesses:compraventa:client:ManageCurrentVehicle', Compraventa.GestionarVehiculoActual)

RegisterNetEvent('origen_businesses:compraventa:client:RemoveExhibitionInput', function(data)
    local input = exports['org-input']:ShowInput({
        header = 'Retirar de Exposición',
        submitText = 'Retirar Vehículo',
        icon = 'fa-solid fa-eye-slash',
        inputs = {
            { type = "radio", name = "confirm", text = "¿Retirar este vehículo de la exposición?", options = { {value = "yes", text = "Sí, retirar"} }, isRequired = true }
        }
    })
    if input and input.confirm == "yes" then
        TriggerServerEvent('origen_businesses:compraventa:server:RemoveFromExhibition', data.plate)
        if data.netId then
            CreateThread(function()
                Wait(1500) -- Esperar a que el servidor actualice la tabla de exposiciones
                local veh = NetToVeh(data.netId)
                if DoesEntityExist(veh) then
                    SetVehicleDoorsLocked(veh, 1)
                    FreezeEntityPosition(veh, false)
                    SetEntityInvincible(veh, false)
                    TriggerEvent("vehiclekeys:client:SetOwner", data.plate)
                    TriggerServerEvent("qb-vehiclekeys:server:AcquireVehicleKeys", data.plate)
                end
            end)
        end
    end
end)

RegisterNetEvent('origen_businesses:compraventa:client:UnfreezeVehicle', function(plate)
    local pool = GetGamePool('CVehicle')
    for i = 1, #pool do
        local veh = pool[i]
        local vehPlate = string.gsub(GetVehicleNumberPlateText(veh), "^%s*(.-)%s*$", "%1")
        if vehPlate == plate then
            SetVehicleDoorsLocked(veh, 1)
            FreezeEntityPosition(veh, false)
            SetEntityInvincible(veh, false)
            break
        end
    end
end)

RegisterNetEvent('origen_businesses:compraventa:client:SetExhibitionInput', function(data)
    local input = exports['org-input']:ShowInput({
        header = 'Poner en Exposición',
        submitText = 'Establecer Punto Aquí',
        icon = 'fa-solid fa-tag',
        inputs = {
            { type = "number", name = "price", text = "Precio de Venta en Exposición ($)", isRequired = true }
        }
    })
    if input and input.price then
        local veh = NetToVeh(data.netId)
        if DoesEntityExist(veh) then
            local coords = GetEntityCoords(veh)
            local heading = GetEntityHeading(veh)
            TriggerServerEvent('origen_businesses:compraventa:server:SetExhibition', data.plate, input.price, coords, heading, data.businessId)
        end
    end
end)

RegisterNetEvent('origen_businesses:compraventa:client:StoreVehicle', function(data)
    local veh = NetToVeh(data.netId)
    if DoesEntityExist(veh) then
        TriggerServerEvent('origen_businesses:compraventa:server:StoreVehicle', data.plate, data.netId)
    end
end)

-- ==========================================
-- 4. VENDER DESDE EXPOSICIÓN (CONTRATO)
-- ==========================================
RegisterNetEvent('origen_businesses:compraventa:client:SellExhibitionVehicle', function(data)
    local plate = data.plate
    local businessId = data.businessId

    local input = exports['org-input']:ShowInput({
        header = 'Contrato de Compraventa',
        submitText = 'Generar Contrato',
        icon = 'fa-solid fa-file-contract',
        inputs = {
            { type = "text", name = "plate", text = "Matrícula", default = plate, isRequired = true },
            { type = "number", name = "buyerId", text = "ID del Comprador", isRequired = true },
            { type = "number", name = "price", text = "Precio Final de Venta ($)", default = data.price, isRequired = true }
        }
    })
    
    if not input then return end
    TriggerServerEvent('origen_businesses:compraventa:server:StartSellExhibition', string.gsub(input.plate, "^%s*(.-)%s*$", "%1"), input.buyerId, input.price, businessId)
end)

RegisterNetEvent('origen_businesses:compraventa:client:ShowExhibitionSellProposal', function(plate, price, employeeName, businessName)
    local alert = exports['org-input']:ShowInput({
        header = 'Contrato de Compra de Vehículo',
        submitText = 'Firmar Contrato',
        icon = 'fa-solid fa-file-signature',
        inputs = {
            { type = "radio", name = "confirm", text = "El local '"..businessName.."' te vende el vehículo [Matrícula: "..plate.."] por $"..price..".", options = {
                {value = "yes", text = "Sí, firmo y compro el vehículo"},
                {value = "no", text = "No, rechazo el contrato"}
            }, isRequired = true }
        }
    })
    
    if alert and alert.confirm == "yes" then
        TriggerServerEvent('origen_businesses:compraventa:server:ConfirmSellExhibition', plate, price)
    else
        TriggerServerEvent('origen_businesses:compraventa:server:CancelTransfer', plate)
    end
end)

-- ==========================================
-- 5. TRASPASO ENTRE PARTICULARES (ORIGINAL)
-- ==========================================
function Compraventa.AbrirTraspaso(data)
    --[[ Aqui no hace falta el negocio: el servidor lo saca del empleado que
         pide el traspaso. Habia un `local businessId = data.businessId` que no
         leia nadie, y por eso nunca se noto que uno de los sitios que abre esto
         pasaba el TIPO del negocio en vez de una tabla. ]]
    local coords = GetEntityCoords(PlayerPedId())
    local defaultPlate = ""
    
    local closestVehicle = lib.getClosestVehicle(coords, 5.0, true)
    if closestVehicle and closestVehicle ~= 0 then
        defaultPlate = GetVehicleNumberPlateText(closestVehicle) or ""
        defaultPlate = string.gsub(defaultPlate, "^%s*(.-)%s*$", "%1")
    end

    local input = exports['org-input']:ShowInput({
        header = 'Traspaso de Vehículo',
        submitText = 'Confirmar Traspaso',
        icon = 'fa-solid fa-car',
        inputs = {
            { type = "text", name = "plate", text = "Matrícula del Vehículo", default = defaultPlate, isRequired = true },
            { type = "number", name = "sellerId", text = "ID Vendedor", isRequired = true },
            { type = "number", name = "buyerId", text = "ID Comprador", isRequired = true },
            { type = "number", name = "price", text = "Precio de la Transacción ($)", isRequired = true }
        }
    })
    
    if not input then return end
    
    local plate = string.gsub(input.plate, "^%s*(.-)%s*$", "%1")
    if input.sellerId == input.buyerId then
        lib.notify({ title = 'Compraventa', description = 'Vendedor y comprador no pueden ser el mismo.', type = 'error' })
        return
    end

    TriggerServerEvent('origen_businesses:compraventa:server:StartTransfer', plate, "Vehículo", input.sellerId, input.buyerId, input.price)
end

RegisterNetEvent('origen_businesses:compraventa:client:OpenTransferMenu', Compraventa.AbrirTraspaso)


-- Sistema de 3D Text para Exposiciones
local exhibitionVehicles = {}

RegisterNetEvent('origen_businesses:compraventa:client:SyncExhibitions', function(data)
    exhibitionVehicles = data
end)

-- Hilo para bloquear, congelar y hacer invencibles los coches de exposición continuamente
CreateThread(function()
    while true do
        Wait(1000)
        local pos = GetEntityCoords(PlayerPedId())

        for plate, exData in pairs(exhibitionVehicles) do
            local vCoords = vector3(exData.coords.x, exData.coords.y, exData.coords.z)
            
            -- Solo buscamos si estamos medianamente cerca del punto
            if #(pos - vCoords) < 50.0 then
                local veh = lib.getClosestVehicle(vCoords, 3.0, false)
                if veh and veh ~= 0 then
                    local vehPlate = string.gsub(GetVehicleNumberPlateText(veh), "^%s*(.-)%s*$", "%1")
                    if vehPlate == plate then
                        SetVehicleDoorsLocked(veh, 2)
                        FreezeEntityPosition(veh, true)
                        SetEntityInvincible(veh, true)
                    end
                end
            end
        end
    end
end)

-- Si la tarjeta está a la vista. Para mandar el «ocultar» una sola vez y no
-- cada segundo (o cada fotograma) que se pasa lejos de un coche en exposición.
local tarjetaVisible = false
local function OcultarTarjeta()
    if not tarjetaVisible then return end
    tarjetaVisible = false
    SendNUIMessage({ action = "updateCard", data = { visible = false } })
end

CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        local sleep = true
        
        local closestPlate = nil
        local closestDist = 2.0
        local closestData = nil
        
        for plate, exData in pairs(exhibitionVehicles) do
            local vCoords = vector3(exData.coords.x, exData.coords.y, exData.coords.z)
            local dist = #(pos - vCoords)
            
            if dist < closestDist then
                closestDist = dist
                closestPlate = plate
                closestData = exData
            end
        end
        
        if closestPlate then
            sleep = false
            local vCoords = vector3(closestData.coords.x, closestData.coords.y, closestData.coords.z)
            local onScreen, x, y = World3dToScreen2d(vCoords.x, vCoords.y, vCoords.z + 1.2)
            
            local isEmployee = false
            local bId = CanAccessBusiness()
            if tostring(bId) == tostring(closestData.business_id) then
                isEmployee = true
            end
            
            if onScreen then
                local modelName = "Vehículo"
                local veh = lib.getClosestVehicle(vCoords, 3.0, false)
                if veh and veh ~= 0 then
                    local hash = GetEntityModel(veh)
                    modelName = GetLabelText(GetDisplayNameFromVehicleModel(hash))
                    if modelName == "NULL" then
                        modelName = GetDisplayNameFromVehicleModel(hash)
                    end
                end
                
                --[[ Con los datos dentro de `data`, que es como los espera la
                     interfaz de este recurso (ver utils/useNuiEvent.ts). La
                     tarjeta tenia su propia pagina y sus propias reglas; ahora
                     comparte las de la casa. ]]
                tarjetaVisible = true
                SendNUIMessage({
                    action = "updateCard",
                    data = {
                        visible = true,
                        x = x,
                        y = y,
                        plate = closestPlate,
                        price = closestData.price,
                        model = modelName,
                        isEmployee = isEmployee,
                    },
                })
                
                if closestDist < 2.5 and isEmployee then
                    if IsControlJustPressed(0, 38) then -- E key
                        TriggerEvent('origen_businesses:compraventa:client:SellExhibitionVehicle', { plate = closestPlate, price = closestData.price, businessId = bId })
                    elseif IsControlJustPressed(0, 74) then -- H key
                        if veh and veh ~= 0 then
                            TriggerEvent('origen_businesses:compraventa:client:OpenManageMenuFromOutside', closestPlate, bId, NetworkGetNetworkIdFromEntity(veh))
                        end
                    end
                end
            else
                OcultarTarjeta()
            end
        else
            OcultarTarjeta()
        end
        
        if sleep then Wait(1000) end
    end
end)

RegisterNetEvent('origen_businesses:compraventa:client:OpenManageMenuFromOutside', function(plate, businessId, netId)
    local menu = {
        {
            header = 'Gestionar Exposición',
            isMenuHeader = true
        },
        {
            header = 'Retirar de Exposición',
            txt = 'Quita este vehículo de la venta.',
            icon = 'fa-solid fa-eye-slash',
            params = {
                event = 'origen_businesses:compraventa:client:RemoveExhibitionInput',
                args = { plate = plate, netId = netId }
            }
        },
        {
            header = 'Guardar en Garaje',
            txt = 'Retira de exposición y guarda en stock.',
            icon = 'fa-solid fa-warehouse',
            params = {
                event = 'origen_businesses:compraventa:client:StoreFromExhibition',
                args = { plate = plate, netId = netId }
            }
        }
    }
    exports['org-menu']:openMenu(menu)
end)

RegisterNetEvent('origen_businesses:compraventa:client:StoreFromExhibition', function(data)
    local input = exports['org-input']:ShowInput({
        header = 'Guardar en Garaje',
        submitText = 'Guardar Vehículo',
        icon = 'fa-solid fa-warehouse',
        inputs = {
            { type = "radio", name = "confirm", text = "¿Guardar este vehículo en el garaje de la empresa?", options = { {value = "yes", text = "Sí, guardar"} }, isRequired = true }
        }
    })
    if input and input.confirm == "yes" then
        TriggerServerEvent('origen_businesses:compraventa:server:RemoveFromExhibition', data.plate)
        TriggerServerEvent('origen_businesses:compraventa:server:StoreVehicle', data.plate, data.netId)
    end
end)
