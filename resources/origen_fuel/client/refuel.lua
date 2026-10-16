-- Sistema de repostaje usando polyzones
local refueling = false
local currentStation = nil
local showingTextUI = false

-- Función para obtener la gasolinera actual basada en polyzone
local function GetCurrentStation()
    local coords = GetEntityCoords(PlayerPedId())
    local stations = GlobalState.Stations or {}
    
    for id, station in pairs(stations) do
        if station.polyzone and exports['origen_fuel']:IsPointInZone(coords, station.polyzone) then
            if station.active then
                return tonumber(id), station
            end
        end
    end
    
    return nil, nil
end

--[[ Lo que se enseña del coche que estas repostando.

     Antes la pantalla solo sabia el porcentaje de deposito: repostabas a
     ciegas, sin ver siquiera de que coche se trataba. Estando de pie al lado
     del surtidor con el coche delante eso es raro, y con dos coches aparcados
     juntos no sabias cual estabas llenando.

     Todo sale de la entidad, que la tenemos aqui. El deposito NO va en esta
     ficha: viene aparte en currentFuel y es el mismo dato.

     Devuelve nil si el vehiculo ya no existe —te lo han robado mientras
     mirabas el menu— y entonces la pantalla no pinta la ficha. ]]
function FichaDelCoche(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return nil end

    local modelo = GetEntityModel(vehicle)
    local nombre = GetLabelText(GetDisplayNameFromVehicleModel(modelo))

    -- GetLabelText devuelve "NULL" con los coches que no traen nombre puesto
    -- (los de mods, casi siempre). Ahi vale mas el nombre interno que nada.
    if nombre == "NULL" or nombre == "" then
        nombre = GetDisplayNameFromVehicleModel(modelo)
    end

    local matricula = GetVehicleNumberPlateText(vehicle)

    return {
        nombre = nombre,
        matricula = matricula and matricula:gsub("%s+$", "") or nil,
        clase = GetVehicleClassFromName(modelo),
        -- La salud del motor, de 0 a 1000 en GTA, pasada a porcentaje: un coche
        -- reventado se nota en lo que gasta, asi que aqui viene bien.
        motor = math.floor(math.max(0, GetVehicleEngineHealth(vehicle)) / 10),
        electrico = IsThisModelAnElectricVehicle and IsThisModelAnElectricVehicle(modelo) or false,
    }
end

--[[ Lo que llevas encima, para decidir con que pagas.

     La pantalla ofrece efectivo o banco, y hasta ahora los ofrecia a ciegas:
     elegias uno, el servidor te decia que no tenias bastante y volvias a
     empezar. Sabiendo el saldo se ve de antemano cual de los dos llega.

     Va con pcall porque el framework puede no estar listo todavia; si falla,
     la pantalla simplemente no ensena los saldos. ]]
local function LoQueLlevas()
    local ok, datos = pcall(function() return exports.qbx_core:GetPlayerData() end)
    if not ok or not datos or not datos.money then return nil end

    return {
        efectivo = datos.money.cash or datos.money['cash'] or 0,
        banco = datos.money.bank or datos.money['bank'] or 0,
    }
end

function OpenRefuelMenu(stationId, station, vehicle, currentFuel)
    if not stationId or not station then
        stationId, station = GetCurrentStation()
    end

    refueling = true
    
    SetNuiFocus(true, true)
    -- El rastreador de misiones y el logo caen donde va la columna.
    ApartarHud(true)
    
    SendNUIMessage({
        action = 'openFuel',
        data = {
            stationId = stationId,
            currentFuel = currentFuel,
            fuelTypes = Config.Fuels,
            vehicle = vehicle,
            -- La ficha del coche que estas repostando. La sabe el cliente, que
            -- tiene la entidad delante; la pantalla solo la pinta.
            coche = FichaDelCoche(vehicle),
            -- El nombre y los precios de ESTA gasolinera, no los de la
            -- configuracion: cada una pone el suyo y el de arriba manda.
            estacion = station.name,
            prices = station.prices,
            -- Lo que le queda en los tanques. El servidor rechaza el pago si
            -- pides mas de lo que hay, asi que mas vale verlo antes de pagar.
            stock = station.stock,
            -- Y lo que caben esos tanques, para poder pintar cuanto les queda
            -- en vez de un numero suelto sin escala.
            maxCapacity = station.maxCapacity,
            dinero = LoQueLlevas(),
        }
    })
end

local pendingRefuel = nil

function GetPendingRefuel()
    return pendingRefuel
end

function ClearPendingRefuel()
    pendingRefuel = nil
end

exports('GetPendingRefuel', GetPendingRefuel)
exports('ClearPendingRefuel', ClearPendingRefuel)

function CompleteRefueling(vehicle)
    if not pendingRefuel then return end
    
    local data = pendingRefuel
    local ped = PlayerPedId()

    TaskTurnPedToFaceEntity(ped, vehicle, 1000)
    Wait(500)
    
    if lib.progressCircle({
        duration = data.amount * 500,
        label = "Repostando...",
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,

        anim = { 
            dict = 'timetable@gardener@filling_can', 
            clip = 'gar_ig_5_filling_can' 
        },
        disable = { move = true, car = true, combat = true },
    }) then
        AddFuel(data.fuelType, data.amount, vehicle)
        TriggerEvent('QBCore:Notify', 'Repostaje completado', 'success')
        pendingRefuel = nil
        return true
    else
        TriggerEvent('QBCore:Notify', 'Repostaje cancelado', 'error')
        pendingRefuel = nil
        return false
    end
end

exports('CompleteRefueling', CompleteRefueling)

RegisterNUICallback('payFuel', function(data, cb)
    data.amount = math.ceil(data.amount)
    
    local stationId, station = GetCurrentStation()

    if data.target == 'jerrycan' then
        lib.callback('origen_fuel:cb:removeFuel', false, function(response)
            if response.success then
                SendNUIMessage({ action = 'closeFuel' })
                SetNuiFocus(false, false)
                ApartarHud(false)
                TriggerServerEvent('origen_fuel:server:buyOrFillJerrycan', data.amount)
                TriggerEvent('QBCore:Notify', 'Has llenado un bidón con ' .. data.amount .. 'L de gasolina', 'success')
            else
                TriggerEvent('QBCore:Notify', response.message, 'error')
            end
        -- El destino va detrás: el servidor recalcula el precio y el bidón vacío
        -- solo se suma (y se entrega) si se compra un bidón.
        end, stationId, data.fuelType, data.amount, data.price, data.payType, 'jerrycan')
        cb({})
        return
    end

    lib.callback('origen_fuel:cb:removeFuel', false, function(response)
        if response.success then
            SendNUIMessage({ action = 'closeFuel' })
            SetNuiFocus(false, false)
            ApartarHud(false)

            pendingRefuel = {
                fuelType = data.fuelType,
                amount = data.amount,
                stationId = stationId
            }
            
            TriggerEvent('QBCore:Notify', 'Pago autorizado. Coja la manguera para repostar.', 'success')
        else
            TriggerEvent('QBCore:Notify', response.message, 'error')
        end
    end, stationId, data.fuelType, data.amount, data.price, data.payType, 'vehicle')
    cb({})
end)

RegisterNUICallback('closeMenu', function(data, cb)
    SetNuiFocus(false, false)
    ApartarHud(false)
    refueling = false
    cb({})
end)

--[[ Si el vigilante comun (@origen_map/shared/foco.lua) suelta el raton a la
     fuerza, el surtidor y el panel de admin se esconden (seguian pintados sin
     raton ni Escape que les llegara), el HUD vuelve y el repostaje se da por
     cerrado. ]]
if OrigenFoco then
    OrigenFoco.AlSoltar(function()
        SendNUIMessage({ action = 'closeFuel' })
        SendNUIMessage({ action = 'closeAdminFuel' })
        ApartarHud(false)
        refueling = false
    end)
end

function UsarBidon(exportTable, slot, item)
    if not item then 
        item = slot
        slot = exportTable
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local vehicle = lib.getClosestVehicle(coords, 3.0, false)
    if not vehicle then
        TriggerEvent('QBCore:Notify', 'No hay ningún vehículo cerca', 'error')
        return
    end
    
    local vState = Entity(vehicle).state
    local currentFuel = vState.fuel or 0
    if currentFuel >= 99 then
        TriggerEvent('QBCore:Notify', 'El vehículo ya tiene el depósito lleno', 'error')
        return
    end

    local jerrycanFuel = item.metadata and tonumber(item.metadata.fuel) or 0
    if jerrycanFuel <= 0 then
        TriggerEvent('QBCore:Notify', 'El bidón está vacío', 'error')
        return
    end

    local amountToAdd = math.min(jerrycanFuel, 100 - currentFuel)

    TaskTurnPedToFaceEntity(ped, vehicle, 1000)
    Wait(500)
    
    if lib.progressCircle({
        duration = math.ceil(amountToAdd) * 200,
        label = "Echando " .. math.ceil(amountToAdd) .. "L de gasolina...",
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        anim = { 
            dict = 'timetable@gardener@filling_can', 
            clip = 'gar_ig_5_filling_can' 
        },
        disable = { move = true, car = true, combat = true },
    }) then
        TriggerServerEvent('origen_fuel:server:useJerrycan', VehToNet(vehicle), item.slot, amountToAdd)
    else
        TriggerEvent('QBCore:Notify', 'Repostaje cancelado', 'error')
    end
end
exports('UsarBidon', UsarBidon)

RegisterNetEvent('origen_fuel:client:addJerrycanFuel', function(netId, amount)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if vehicle and vehicle ~= 0 then
        AddFuel('C', amount, vehicle)
    end
end)

