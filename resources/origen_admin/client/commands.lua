-- origen_admin | client commands
RegisterCommand('goto', function(source, args, rawCommand)
    local src = tonumber(args[1])
    if src == GetPlayerServerId(PlayerId()) then
        ShowNotification("No puedes ir a ti mismo")
        return
    end
    TriggerServerEvent('origen_admin:server:goto', src)
end, false)

RegisterCommand('bring', function(source, args, rawCommand)
    local src = tonumber(args[1])
    if src == GetPlayerServerId(PlayerId()) then
        ShowNotification("No puedes traerte a ti mismo")
        return
    end
    TriggerServerEvent('origen_admin:server:bring', src)
end, false)

RegisterCommand('bringback', function(source, args, rawCommand)
    TriggerServerEvent('origen_admin:server:previusloc', tonumber(args[1]))
end, false)

RegisterCommand('checkdimension', function(source, args, rawCommand)
    TriggerServerEvent("origen_admin:server:checkbucket", tonumber(args[1]))
end, false)

RegisterCommand('changedimension', function(source, args, rawCommand)
    TriggerServerEvent('origen_admin:server:cbucket', tonumber(args[1]), tonumber(args[2]))
end, false)

RegisterCommand('tags', function(source, args, rawCommand)
    if not HasPermission("AdminMenu:Tags") then
        ShowNotification("No tienes permiso para usar este comando")
        return
    end
    ToggleTags()
    TriggerServerEvent('origen_admin:server:logAdminAction', 'ToggleTags', 'Tags activados/desactivados')
end, false)

RegisterCommand('freezeweather', function(source, args, rawCommand)
    TriggerServerEvent("origen_admin:server:SetWeatherFreezed", GlobalState.weatherFrozen == nil and true or not GlobalState.weatherFrozen)
end, false)

RegisterCommand('darcoche', function(source, args, rawCommand)
    local data = {
        targetId = tonumber(args[1]),
        model = args[2],
        garage = args[3]
    }
    FW_TriggerCallback('origen_admin:server:GiveVehicleToPlayer', function(result)
        if result.success then
            ShowNotification("Vehículo entregado con éxito")
        else
            ShowNotification("Error al entregar el vehículo: " .. result.message)
        end
    end, data)
end, false)

RegisterCommand('quitarcoche', function(source, args, rawCommand)
    local data = {
        plate = args[1]
    }
    FW_TriggerCallback('origen_admin:server:DeletePlayerVehicle', function(result)
        if result.success then
            ShowNotification("Vehículo removido con éxito")
        else
            ShowNotification("Error al remover el vehículo: " .. result.message)
        end
    end, data)
end, false)

local isGodVeh = false
local lastGodVeh = 0

local function ToggleGodVehicleState(veh, state)
    if not veh or veh == 0 or not DoesEntityExist(veh) then return end
    
    if state then
        SetEntityInvincible(veh, true)
        SetVehicleCanBeVisiblyDamaged(veh, false)
        SetVehicleEngineCanDegrade(veh, false)
        SetVehicleFixed(veh)
        SetVehicleDirtLevel(veh, 0.0)
        SetVehicleStrong(veh, true)
        SetVehicleHasStrongAxles(veh, true)
        SetVehicleDamageModifier(veh, 0.0)
        SetVehicleExplodesOnHighExplosionDamage(veh, false)
        SincronizarMecanica('godveh', veh)
        lastGodVeh = veh
    else
        SetEntityInvincible(veh, false)
        SetVehicleCanBeVisiblyDamaged(veh, true)
        SetVehicleEngineCanDegrade(veh, true)
        SetVehicleStrong(veh, false)
        SetVehicleHasStrongAxles(veh, false)
        SetVehicleDamageModifier(veh, 1.0)
        SetVehicleExplodesOnHighExplosionDamage(veh, true)
        lastGodVeh = 0
    end
end

RegisterCommand('godveh', function()
    if not HasPermission("Comando:godveh") then
        ShowNotification("No tienes permiso para usar este comando")
        return
    end
    
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    
    if veh == 0 then
        ShowNotification("No estás en un vehículo")
        return
    end
    
    isGodVeh = not isGodVeh
    ToggleGodVehicleState(veh, isGodVeh)
    
    if isGodVeh then
        ShowNotification("MD activado")
        TriggerServerEvent('origen_admin:server:logAdminAction', 'ToggleGodveh', 'Activado')
    else
        ShowNotification("MD desactivado")
        TriggerServerEvent('origen_admin:server:logAdminAction', 'ToggleGodveh', 'Desactivado')
    end
end, false)

CreateThread(function()
    while true do
        if isGodVeh then
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            
            if veh ~= 0 then
                if IsVehicleDamaged(veh) or GetVehicleEngineHealth(veh) < 1000.0 or GetVehicleBodyHealth(veh) < 1000.0 then
                    SetVehicleFixed(veh)
                    SetVehicleDeformationFixed(veh)
                    SetVehicleDirtLevel(veh, 0.0)
                    SetVehicleEngineHealth(veh, 1000.0)
                    SetVehicleBodyHealth(veh, 1000.0)
                    SetVehiclePetrolTankHealth(veh, 1000.0)
               end
            else
                -- Desactivar automáticamente al bajar
                if lastGodVeh ~= 0 then
                    ToggleGodVehicleState(lastGodVeh, false)
                end
                isGodVeh = false
                ShowNotification("MD desactivado")
            end
        end
        Wait(isGodVeh and 100 or 1000)
    end
end)

-- ─── Comando /arnes — Arnés Administrativo ───────────────────
RegisterCommand('arnes', function()
    if not HasPermission("Comando:arnes") then
        ShowNotification("No tienes permiso para usar este comando")
        return
    end
    
    local ped = PlayerPedId()
    -- Flag 32: CPED_CONFIG_FLAG_WillFlyThroughWindscreen
    local currentVal = GetPedConfigFlag(ped, 32, true)
    local newVal = not currentVal
    
    SetPedConfigFlag(ped, 32, newVal)
    
    if not newVal then
        ShowNotification("Arnés colocado.", "info")
        TriggerServerEvent('origen_admin:server:logAdminAction', 'ToggleArnes', 'Activado')
    else
        ShowNotification("Arnés quitado.", "info")
        TriggerServerEvent('origen_admin:server:logAdminAction', 'ToggleArnes', 'Desactivado')
    end
end, false)

-- ─── Comando /givekeys — Obtener llaves del vehículo actual ───
RegisterCommand('givekeys', function()
    if not HasPermission("Comando:givekeys") then
        ShowNotification("No tienes permiso para usar este comando")
        return
    end

    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    
    if veh == 0 then
        ShowNotification("No estás dentro de ningún vehículo")
        return
    end

    local plate = GetVehicleNumberPlateText(veh)
    
    TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', plate)
    
    ShowNotification("Has recibido las llaves del vehículo con matrícula " .. plate .. ".", "success")
    TriggerServerEvent('origen_admin:server:logAdminAction', 'GiveKeys', 'Obtenidas llaves del vehículo ' .. plate)
end, false)

-- ─── Comando /givecar — Traspasar propiedad del vehículo actual ──
RegisterCommand('givecar', function(source, args, rawCommand)
    if not HasPermission("Comando:givecar") then
        ShowNotification("No tienes permiso para usar estos comandos")
        return
    end

    local targetId = tonumber(args[1])
    if not targetId then
        ShowNotification("Uso: /givecar [ID]")
        return
    end

    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    
    if veh == 0 then
        ShowNotification("No estás dentro de ningún vehículo")
        return
    end

    local plate = GetVehicleNumberPlateText(veh)
    local model = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
    
    TriggerServerEvent('origen_admin:server:GiveCarCommand', targetId, plate, model)
end, false)

RegisterNetEvent('origen_admin:client:FixCar', function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then
        SetVehicleFixed(veh)
        SetVehicleDeformationFixed(veh)
        SetVehicleEngineHealth(veh, 1000.0)
        SetVehicleBodyHealth(veh, 1000.0)
        SetVehiclePetrolTankHealth(veh, 1000.0)
        SetVehicleDirtLevel(veh, 0.0)
        ShowNotification("Tu vehículo ha sido reparado por un administrador", "success")
    else
        ShowNotification("No estás dentro de ningún vehículo", "error")
    end
end)

RegisterCommand('tpmp', function(source, args, rawCommand)
    if not HasPermission("AdminMenu:TpTo") then
        ShowNotification("No tienes permiso para usar este comando")
        return
    end

    local targetId = tonumber(args[1])
    if not targetId then
        ShowNotification("Uso: /tpmp [ID]")
        return
    end

    --- Por el blip, no por IsWaypointActive(): ese native no cuenta los puntos
    --- que pone nuestro mapa. Ver origen_map/shared/marcar.lua.
    local coords = OrigenMapa.Waypoint()
    if not coords then
        ShowNotification("No tienes ningún punto marcado en el mapa", "error")
        return
    end

    TriggerServerEvent('origen_admin:server:tpmp', targetId, coords.x, coords.y)
end, false)

RegisterNetEvent("origen_admin:client:tpmp", function(x, y)
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    local oldCoords = GetEntityCoords(ped)

    local groundZ, Z_START = 850.0, 950.0
    local found = false
    FreezeEntityPosition(vehicle > 0 and vehicle or ped, true)

    for i = Z_START, 0, -25.0 do
        local z = i
        if (i % 2) ~= 0 then
            z = Z_START - i
        end

        NewLoadSceneStart(x, y, z, x, y, z, 50.0, 0)
        local curTime = GetGameTimer()
        while IsNetworkLoadingScene() do
            if GetGameTimer() - curTime > 1000 then
                break
            end
            Wait(0)
        end
        NewLoadSceneStop()
        SetPedCoordsKeepVehicle(ped, x, y, z)

        while not HasCollisionLoadedAroundEntity(ped) do
            RequestCollisionAtCoord(x, y, z)
            if GetGameTimer() - curTime > 1000 then
                break
            end
            Wait(0)
        end

        found, groundZ = GetGroundZFor_3dCoord(x, y, z, false)
        if found then
            Wait(0)
            SetPedCoordsKeepVehicle(ped, x, y, groundZ)
            break
        end
        Wait(0)
    end

    FreezeEntityPosition(vehicle > 0 and vehicle or ped, false)
    if not found then
        SetPedCoordsKeepVehicle(ped, oldCoords["x"], oldCoords["y"], oldCoords["z"] - 1.0)
    end
    SetPedCoordsKeepVehicle(ped, x, y, groundZ)
    ShowNotification("Has sido teletransportado por un administrador", "info")
end)

RegisterNetEvent('origen_admin:client:clearAdminEffects', function()
    if not isGodVeh then return end

    if lastGodVeh ~= 0 and DoesEntityExist(lastGodVeh) then
        ToggleGodVehicleState(lastGodVeh, false)
    end
    isGodVeh = false
end)
