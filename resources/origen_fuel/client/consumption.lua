local isLooping = false

local function loopConsumption()
    if isLooping then return end
    isLooping = true

    CreateThread(function()
        while cache.seat == -1 do
            if cache.vehicle and DoesEntityExist(cache.vehicle) and GetIsVehicleEngineRunning(cache.vehicle) then
                local vState = Entity(cache.vehicle).state
                
                if not vState.fuel then
                    -- Recién sacado del garaje el statebag puede estar llegando:
                    -- se le da un momento antes de rehacerlo con el native.
                    local hasta = GetGameTimer() + 3000
                    while not vState.fuel and GetGameTimer() < hasta and cache.vehicle do Wait(100) end
                end

                local fuel = vState.fuel
                if not fuel and cache.vehicle then
                    fuel = GetVehicleFuelLevel(cache.vehicle)
                    if fuel > 100.0 then fuel = 100.0 end
                    TriggerServerEvent('origen_fuel:createStatebag', NetworkGetNetworkIdFromEntity(cache.vehicle), fuel)
                    vState:set('fuel', fuel, true)
                end
                
                local fuelTank = vState.fuelTank
                if not fuelTank or type(fuelTank) ~= 'table' or #fuelTank == 0 or not fuelTank[1] then
                    if fuel and fuel > 0 then
                        fuelTank = {
                            {
                                type = 'C',
                                amount = fuel
                            }
                        }
                        vState:set('fuelTank', fuelTank, true)
                    else
                        fuelTank = {}
                    end
                end

                if fuel and fuel > 0 and fuelTank[1] and cache.vehicle then
                    local fType = fuelTank[1].type or 'C'
                    local fuelConfig = Config.Fuels[fType] or Config.Fuels['C']
                    local consumption = (fuelConfig and fuelConfig.consumption) or 0.0256

                    if GetVehicleClass(cache.vehicle) == 15 then
                        consumption = 0.0666
                    end

                    fuelTank[1].amount = math.max(0, (fuelTank[1].amount or fuel) - consumption)

                    if fuelTank[1].amount <= 0 then
                        table.remove(fuelTank, 1)
                    end

                    local newFuel = 0
                    for k, v in pairs(fuelTank) do
                        newFuel = newFuel + (v.amount or 0)
                    end
                    
                    SetVehicleFuelLevel(cache.vehicle, newFuel + 0.0)

                    if fuelConfig and fuelConfig.performance and GetVehicleTopSpeedModifier(cache.vehicle) ~= fuelConfig.performance then
                        ModifyVehicleTopSpeed(cache.vehicle, fuelConfig.performance)
                    end

                    vState:set('fuelTank', fuelTank, true)
                    vState:set('fuel', newFuel, true)
                end
            end

            Wait(1000)
        end
        isLooping = false
    end)
end

function AddFuel(fType, amount, veh)
    local targetVeh = veh or cache.vehicle
    if not targetVeh or not DoesEntityExist(targetVeh) then return end

    local vState = Entity(targetVeh).state
    local fuel = vState.fuel or GetVehicleFuelLevel(targetVeh) or 0
    local fuelTank = vState.fuelTank
    if not fuelTank or type(fuelTank) ~= 'table' then
        fuelTank = {}
    end

    local totalFuel = fuel + amount
    if totalFuel > 100 then
        amount = 100 - fuel
        totalFuel = 100
    end

    if amount > 0 then
        table.insert(fuelTank, {
            type = fType or 'C',
            amount = amount
        })

        SetVehicleFuelLevel(targetVeh, totalFuel + 0.0)

        vState:set('fuelTank', fuelTank, true)
        vState:set('fuel', totalFuel, true)

        local label = Config.Fuels[fType] and Config.Fuels[fType].label or fType or 'Gasolina'
        lib.notify({
            title = 'Combustible añadido',
            description = 'Se han añadido ' .. amount .. ' litros de ' .. label,
            type = 'success'
        })
    end
end

lib.onCache('seat', function(seat)
    if seat == -1 then
        loopConsumption()
    end
end)

-- Si el recurso se reinicia con el jugador ya sentado al volante:
CreateThread(function()
    if cache.seat == -1 then
        loopConsumption()
    end
end)

function SetFuel(veh, data)
    --[[ También con el número a secas: SetFuel(veh, 100.0). Así lo llaman la
         granja y el aserradero, y como solo se aceptaba { fuel = ... } petaba
         al indexar un número y el vehículo salía sin llenar (17/09). ]]
    if type(data) == 'number' then data = { fuel = data } end
    if type(data) ~= 'table' or not DoesEntityExist(veh) then return end

    local vState = Entity(veh).state
    local fuel = math.min(100.0, tonumber(data.fuel) or 0.0)
    local fuelTank = data.fuelTank

    if not fuelTank or type(fuelTank) ~= 'table' or #fuelTank == 0 then
        if fuel > 0 then
            fuelTank = {
                {
                    type = 'C',
                    amount = fuel
                }
            }
        else
            fuelTank = {}
        end
    end

    SetVehicleFuelLevel(veh, fuel + 0.0)
    vState:set('fuelTank', fuelTank, true)
    vState:set('fuel', fuel, true)

    --[[ Recién creado (garaje, taller...) el coche aún no está en red y lo de
         arriba se pierde: se repite desde el servidor cuando ya existe. Ver
         origen_fuel:fijarSalida en server/consumption.lua. ]]
    CreateThread(function()
        local hasta = GetGameTimer() + 10000
        while DoesEntityExist(veh) and not NetworkGetEntityIsNetworked(veh) and GetGameTimer() < hasta do
            Wait(100)
        end
        if not DoesEntityExist(veh) or not NetworkGetEntityIsNetworked(veh) then return end
        TriggerServerEvent('origen_fuel:fijarSalida', NetworkGetNetworkIdFromEntity(veh), fuel, fuelTank)
    end)
end

function CompleteFuel(veh)
    if not veh or not DoesEntityExist(veh) then return end

    local vState = Entity(veh).state
    local fuel = vState.fuel or GetVehicleFuelLevel(veh) or 0
    local fuelTank = vState.fuelTank
    if not fuelTank or type(fuelTank) ~= 'table' or #fuelTank == 0 then
        fuelTank = {
            {
                type = 'C',
                amount = fuel
            }
        }
    end

    local toAdd = 100 - fuel
    if toAdd > 0 then
        local found = false
        for k, v in pairs(fuelTank) do
            if v.type == 'C' then
                v.amount = (v.amount or 0) + toAdd
                found = true
                break
            end
        end

        if not found then
            table.insert(fuelTank, {
                type = 'C',
                amount = toAdd
            })
        end

        SetVehicleFuelLevel(veh, 100.0)

        vState:set('fuelTank', fuelTank, true)
        vState:set('fuel', 100, true)
    end
end

function GetFuel(veh)
    if not veh or not DoesEntityExist(veh) then
        return { fuel = 0, fuelTank = {} }
    end
    local vState = Entity(veh).state
    --[[ Sin statebag se devolvía 0, y el garaje guardaba el coche vacío. Mejor
         lo que marca el propio coche, que SetFuel también pone. ]]
    local fuel = vState.fuel or GetVehicleFuelLevel(veh) or 0
    local fuelTank = vState.fuelTank
    if not fuelTank or type(fuelTank) ~= 'table' or #fuelTank == 0 then
        if fuel > 0 then
            fuelTank = {
                {
                    type = 'C',
                    amount = fuel
                }
            }
        else
            fuelTank = {}
        end
    end
    return {
        fuel = fuel,
        fuelTank = fuelTank
    }
end

exports('AddFuel', AddFuel)
exports('GetFuel', GetFuel)
exports('SetFuel', SetFuel)
exports('CompleteFuel', CompleteFuel)

RegisterCommand('setfuel', function(source, args, rawCommand)
    local isAdmin = lib.callback.await('origen_fuel:cb:isAdmin', false)
    if not isAdmin then
        lib.notify({
            title = 'Gasolinera',
            description = 'No tienes permisos de administrador',
            type = 'error'
        })
        return
    end
    SetFuel(cache.vehicle, {
        fuel = tonumber(args[1]) or 0,
        fuelTank = {
            {
                type = 'A',
                amount = tonumber(args[1]) or 0
            }
        }
    })
end, false)

RegisterCommand('getfuel', function(source, args, rawCommand)
    print(json.encode(GetFuel(cache.vehicle), { indent = true }))
end, false)