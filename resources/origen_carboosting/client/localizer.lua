local activeLocalizers = {}
local playerJob = nil

local function isPolice(jobName)
    for k, v in pairs(Config.PoliceJobName) do
        if v == jobName then
            return true
        end
    end
    return false
end

--[[ Los localizadores, en el mapa.

     Ya no son blips del juego: son puntos de origen_map. Poner uno con la
     clave que ya tenia lo MUEVE —el registro actualiza el punto en vez de
     crear otro— asi que aqui ya no hacen falta las dos ramas de antes: la de
     crearlo y la de recolocarlo son la misma llamada.

     Prioridad alta: un coche localizado importa este donde este, y el corte
     por distancia del minimapa se lo comeria. ]]
local function updateLocalizers()
    for id, data in pairs(activeLocalizers) do
        local clave = 'localizador_' .. tostring(id)
        activeLocalizers[id].blip = clave

        OrigenMapa.Poner(clave, {
            x = data.coords.x, y = data.coords.y, z = data.coords.z,
            cat = 'illegal',
            icono = 'coche',
            nombre = data.label or 'Vehiculo localizado',
            color = '#d81b55',
            prioridad = 10,
        })
    end
end

local function clearLocalizers()
    for id, data in pairs(activeLocalizers) do
        if activeLocalizers[id].blip then
            OrigenMapa.Quitar(activeLocalizers[id].blip)
            activeLocalizers[id].blip = nil
        end
    end
end

local function GetPedVehicleSeat(ped)
    local vehicle = GetVehiclePedIsIn(ped, false)
    for i=-2, GetVehicleMaxNumberOfPassengers(vehicle) do
        if(GetPedInVehicleSeat(vehicle, i) == ped) then 
            return i 
        end
    end
    return -2
end

RegisterNetEvent('origen_boosting:cl:removeLocalizer', function(id)
    if activeLocalizers[id] then
        OrigenMapa.Quitar(activeLocalizers[id].blip)
        activeLocalizers[id] = nil
    end
end)

AddStateBagChangeHandler('Localizers', 'global', function(_, _, data)
    if playerJob and isPolice(playerJob.name) and playerJob.onduty then
        for id, coords in pairs(data) do
            activeLocalizers[id] = activeLocalizers[id] or {}
            activeLocalizers[id].coords = {x = coords.x, y = coords.y, z = coords.z}
        end

        updateLocalizers()
    end
end)

RegisterNetEvent('origen_boosting:client:onPlayerLoaded', function(playerData)
    local player = playerData or Framework._GetPlayerData()
    if player then
        playerJob = {
            name = player.job.name,
            onduty = Custom.IsOnDuty and Custom.IsOnDuty() or player.job[Config.Framework == 'esx' and 'onDuty' or 'onduty']
        }

        if isPolice(playerJob.name) and playerJob.onduty then
            activeLocalizers = GlobalState['Localizers'] or {}
            updateLocalizers()
        end
    end
end)

RegisterNetEvent('origen_boosting:client:onPlayerUnload', function()
    playerJob = nil
    clearLocalizers()
end)

RegisterNetEvent('origen_boosting:client:onJobUpdate', function(jobInfo)
    playerJob = jobInfo
    playerJob.onduty = jobInfo[Config.Framework == 'esx' and 'onDuty' or 'onduty']
    
    if isPolice(playerJob.name) and playerJob.onduty then
        updateLocalizers()
    else
        clearLocalizers()
    end
end)

RegisterNetEvent('origen_boosting:client:onDutyUpdate', function(onduty)
    if playerJob then
        playerJob.onduty = type(onduty) == 'table' and onduty.onDuty or onduty
        
        if isPolice(playerJob.name) and playerJob.onduty then
            updateLocalizers()
        else
            clearLocalizers()
        end
    end
end)

RegisterNetEvent("origen_boosting:client:OpenHacking", function()
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)

    if veh == 0 then
        return Internal.Notify(locale('in_game.notifications.hack_not_in_vehicle'), 'error', 5000)
    end

    local state = Entity(veh).state

    if not state.hacks or state.hacks == 0 then
        return Internal.Notify(locale('in_game.notifications.hack_not_available'), 'error', 5000)
    end

    local seat = GetPedVehicleSeat(PlayerPedId())
    local speed = GetEntitySpeed(veh) * Config.Hack.SpeedMultiplier

    if Config.Hack.Restriction then
        if seat == -1 then
            return Internal.Notify(locale('in_game.notifications.hack_driver'), 'error', 5000)
        end

        if speed < (Config.Hack.MinimumSpeed or 0) then
            return Internal.Notify(locale('in_game.notifications.hack_too_slow', math.floor(Config.Hack.MinimumSpeed or 0)), 'error', 5000)
        end

        local maxSpeed = Config.Hack.MaximumSpeed
        if maxSpeed and speed > maxSpeed then
            return Internal.Notify(locale('in_game.notifications.hack_too_fast', math.floor(maxSpeed)), 'error', 5000)
        end
    end

    -- Monitor de condiciones durante el minijuego para evitar abuso en solitario
    -- Si el jugador baja de velocidad o cambia al asiento del conductor, el hack cuenta como fallido
    local hackAborted = false
    local hackFinished = false
    local abortReason = nil

    if Config.Hack.Restriction then
        Citizen.CreateThread(function()
            while not hackFinished do
                Citizen.Wait(250)
                if hackFinished then break end

                local currentVeh = GetVehiclePedIsIn(PlayerPedId(), false)

                -- Salió del vehículo
                if currentVeh == 0 or currentVeh ~= veh then
                    hackAborted = true
                    abortReason = 'seat'
                    break
                end

                -- Cambió al asiento del conductor
                local currentSeat = GetPedVehicleSeat(PlayerPedId())
                if currentSeat == -1 then
                    hackAborted = true
                    abortReason = 'seat'
                    break
                end

                -- Bajó de la velocidad mínima
                local currentSpeed = GetEntitySpeed(veh) * Config.Hack.SpeedMultiplier
                if currentSpeed < (Config.Hack.MinimumSpeed or 0) then
                    hackAborted = true
                    abortReason = 'speed'
                    break
                end
            end
        end)
    end

    local result = Custom.Minigame({
        category = state.category,
        hacks = state.hacks,
        fails = state.fails,
        minigame = state.minigame,
        minigameDifficulty = state.minigameDifficulty
    })

    hackFinished = true

    if result == nil then
        return Internal.Notify(locale('in_game.notifications.hack_minigame_not_started'), 'error', 5000)
    end

    -- Si se violaron las condiciones durante el minijuego → forzar fallo independientemente del resultado
    if hackAborted then
        if abortReason == 'seat' then
            Internal.Notify(locale('in_game.notifications.hack_driver'), 'error', 5000)
        else
            Internal.Notify(locale('in_game.notifications.hack_too_slow', math.floor(Config.Hack.MinimumSpeed or 0)), 'error', 5000)
        end
        result = false
    end

    TriggerServerEvent('origen_boosting:sv:hackLocalizer', Entity(veh).state.id, result)
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        local playerData = Framework._GetPlayerData()

        if playerData and playerData.job then
            playerJob = {
                name = playerData.job.name,
                onduty = Custom.IsOnDuty and Custom.IsOnDuty() or playerData.job[Config.Framework == 'esx' and 'onDuty' or 'onduty']
            }

            if isPolice(playerJob.name) and playerJob.onduty then
                activeLocalizers = GlobalState['Localizers'] or {}
                updateLocalizers()
            end
        end
    end
end)