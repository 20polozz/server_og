isVanish = false

--[[ Estado de godmode, guardado aqui a mano.

     GetPlayerInvincible no es de fiar: devuelve false aunque acabes de poner
     la invencibilidad. Eso rompia dos cosas a la vez. El interruptor no se
     podia apagar —siempre leia false, asi que siempre volvia a encender— y el
     menu no tenia forma de saber como estaba para pintar el piloto. ]]
EstadoGodmode = false

FastActions = {
    ['noclip'] = {function(data, cb)
        cb({close = true})
        ToggleNoClip()
        TriggerServerEvent('origen_admin:server:logAdminAction', 'ToggleNoclip', 'Noclip activado/desactivado')
    end, "AdminMenu:Noclip"},
    ['revive'] = {function(data, cb)
        cb(true)
        SelfRevive()
    end, "AdminMenu:SelfRevive", true},
    ['godmode'] = {function(data, cb)
        cb(true)
        EstadoGodmode = not EstadoGodmode
        SetPlayerInvincible(PlayerId(), EstadoGodmode)
        ShowNotification(EstadoGodmode and 'Modo dios activado' or 'Modo dios desactivado')
        TriggerServerEvent('origen_admin:server:logAdminAction', 'ToggleGodmode', EstadoGodmode and 'Godmode activado' or 'Godmode desactivado')
    end, "AdminMenu:Godmode"},
    ['invisible'] = {function(daba, cb)
        cb(true)
        local ped = PlayerPedId()
        isVanish = IsEntityVisible(ped) == 1 or IsEntityVisible(ped) == true
        SetEntityVisible(ped, not isVanish)
        TriggerServerEvent('origen_admin:server:logAdminAction', 'ToggleInvisible', isVanish and 'Invisible activado' or 'Invisible desactivado')
    end, "AdminMenu:Invisible"},
    ['skinmenu'] = {function(data, cb)
        cb({close = true})
        ModifySkin()
    end, "AdminMenu:SkinSelf"},
    ['blips'] = {function(data, cb)
        ToggleBlips()
        cb(true)
    end, "AdminMenu:Blips"},
    ['tags'] = {function(data, cb)
        ToggleTags()
        cb(true)
        TriggerServerEvent('origen_admin:server:logAdminAction', 'ToggleTags', 'Tags activados/desactivados')
    end, "AdminMenu:Tags"},
    ['tpm'] = {function(data, cb)
        --- El punto marcado se pregunta por el blip y no por IsWaypointActive():
        --- el native no cuenta los que pone nuestro mapa. El porque, en
        --- origen_map/shared/marcar.lua.
        local marcado = OrigenMapa.Waypoint()
        if marcado then
            local ped, coords = PlayerPedId(), marcado
            TriggerServerEvent('origen_admin:server:logAdminAction', 'UseTpm', string.format('TP a marcador (%.1f, %.1f)', coords.x, coords.y))
            local vehicle = GetVehiclePedIsIn(ped, false)
            local oldCoords = GetEntityCoords(ped)

            local x, y, groundZ, Z_START = coords["x"], coords["y"], 850.0, 950.0
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
        end
        cb(true)
    end, "AdminMenu:Tpm"},
    ['announce'] = {function(data, cb)
        if not data.data then
            SendNUIMessage({ action = "close" })
            SendNUIMessage({ action = "closeQuickMenuLua" })
            SendNUIMessage({ action = "closeAdminPanel" })
            SetNuiFocus(false, false)
            SetNuiFocusKeepInput(false)
            local input = exports["org-input"]:ShowInput({
                header = "Crear Anuncio",
                submitText = "Enviar",
                inputs = {
                    {
                        text = "Mensaje del anuncio",
                        name = "message",
                        type = "text",
                        isRequired = true,
                    }
                }
            })
            if not input then return end
            data.data = input.message
        end
        TriggerServerEvent('origen_admin:server:sendAnnounce', data.data)
        cb(true)
    end, "AdminMenu:CreateAnnounce", true},
    ['reviveall'] = {function(data, cb)
        ReviveAll()
        cb(true)
    end, "AdminMenu:ReviveAll", true},
    ['deletePeds'] = {function(data, cb)
        TriggerServerEvent("origen_admin:server:deletePeds")
        cb(true)
    end, "AdminMenu:DeletePeds"},
    ['deleteObj'] = {function(data, cb)
        TriggerServerEvent("origen_admin:server:deleteObjects")
        cb(true)
    end, "AdminMenu:DeleteObjects"},
    ['deleteVeh'] = {function(data, cb)
        TriggerServerEvent("origen_admin:server:deleteVehicles")
        cb(true)
    end, "AdminMenu:DeleteVehicles"},
    ['clearChat'] = {function(data, cb)
        TriggerServerEvent("origen_admin:server:clearChat")
        cb(true)
    end, "AdminMenu:ClearChat", true},
    ['kickAll'] = {function(data, cb)
        TriggerServerEvent("origen_admin:server:kickAll")
        cb(true)
    end, "AdminMenu:KickAll", true},
    ['fixveh'] = {function(data, cb)
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        if vehicle ~= 0 then
            SetVehicleFixed(vehicle)
            SetVehicleDeformationFixed(vehicle)
            SetVehicleEngineHealth(vehicle, 1000.0)
            SetVehicleBodyHealth(vehicle, 1000.0)
            SetVehiclePetrolTankHealth(vehicle, 1000.0)
            SetVehicleDirtLevel(vehicle, 0.0)
            SincronizarMecanica('fixveh', vehicle)
        end
        cb(true)
    end, "AdminMenu:FixVehicle", true},
    ['modifyveh'] = {function(data, cb)
        ModifyVehicle()
        cb({close = true})
    end, "AdminMenu:TunningMenu", true},
    ['fuelveh'] = {function(data, cb)
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        if vehicle ~= 0 then
            SetMaxVehicleFuel(vehicle)
        end
        cb(true)
    end, "AdminMenu:Refuel"},
    ['admincar'] = {function(data, cb)
        TriggerEvent('origen_admin:client:SaveCar')
        cb(true)
    end, "AdminMenu:AdminCar"},
    ['unlockveh'] = {function(data, cb)
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        if vehicle ~= 0 then
            UnlockVehicle(vehicle)
        end
        cb(true)
    end, "AdminMenu:Unlock"},
    ['boostveh'] = {function(data, cb)
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        if vehicle ~= 0 then
            BoostVehicle(vehicle)
        end
        cb(true)
    end, "AdminMenu:BoostVeh"},
    ['sitVehicle'] = {function(data, cb)
        local vehicle = GetNearestVehicle(GetEntityCoords(PlayerPedId()), 5.0)
        if vehicle ~= 0 then
            local seat = GetEmptySeat(vehicle)
            if seat ~= false then
                SetPedIntoVehicle(PlayerPedId(), vehicle, seat)
            else
                exports.origen_notify:Notify("El vehículo no tiene asientos libres", "error")
            end
        else
            exports.origen_notify:Notify("No hay ningún vehículo cerca", "error")
        end
        cb(true)
    end, "AdminMenu:SitVehicle"},
    ['vec3'] = {function(data, cb)
        CopyCoords(false)
        cb(true)
    end, "AdminMenu:Vector3"},
    ['vec4'] = {function(data, cb)
        CopyCoords(true)
        cb(true)
    end, "AdminMenu:Vector4"},
    ['laser'] = {function(data, cb)
        ToggleLaser()
        cb({close = true})
    end, "AdminMenu:Laser"},
    ['fixnotis'] = {function(data, cb)
        if lib then
            lib.hideContext()
            lib.hideMenu()
            lib.hideTextUI()
        end
        if GetResourceState('origen_hud') == 'started' then
            exports.origen_hud:hideControls()
        end
        SendNUIMessage({ action = "close" }) 
        SendNUIMessage({ action = "closeQuickMenuLua" })
        SendNUIMessage({ action = "closeAdminPanel" })
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        RenderScriptCams(false, false, 0, true, false)
        DestroyAllCams(true)
        if cache.vehicle then
            DisplayRadar(true)
        else
            DisplayRadar(false)
        end
        
        exports.qbx_core:Notify('Interfaz Reiniciada', 'success')
        cb(true)
    end, "AdminMenu:FixUI", true},
}

UserActions = {
    ['spectate'] = function(data, cb) 
        local src = tonumber(data.source)
        if src == GetPlayerServerId(PlayerId()) then
            ShowNotification('No puedes observarte a ti mismo')
            cb({close = true})
            return
        end
        cb({close = true})
        TriggerServerEvent('origen_admin:server:StartSpectate', src)
    end,
    ['bring'] = function(data, cb) 
        local src = tonumber(data.source)
        if src == GetPlayerServerId(PlayerId()) then
            ShowNotification('No puedes traerte a ti mismo')
            cb({close = true})
            return
        end
        cb({close = true})
        TriggerServerEvent('origen_admin:server:bring', src)
    end,
    ['previusloc'] = function(data, cb) 
        cb({close = true})
        TriggerServerEvent('origen_admin:server:previusloc', tonumber(data.source))
    end,
    ['goto'] = function(data, cb) 
        cb({close = true})
        TriggerServerEvent('origen_admin:server:goto', tonumber(data.source))
    end,
    ['freeze'] = function(data, cb) 
        cb({close = true})
        TriggerServerEvent('origen_admin:server:freeze', tonumber(data.source))
    end,
    ['kill'] = function(data, cb) 
        cb({close = true})
        TriggerServerEvent('origen_admin:server:kill', tonumber(data.source))
    end,
    ['revive'] = function(data, cb) 
        cb({close = true})
        TriggerServerEvent('origen_admin:server:reviveTarget', tonumber(data.source))
    end,
    ['cbucket'] = function(data, cb)
        cb(true)
        TriggerServerEvent('origen_admin:server:cbucket', tonumber(data.source), tonumber(data.data))
    end,
    ['clearinv'] = function(data, cb)
        cb(true)
        ClearInv(tonumber(data.source))
    end,
    ['skinmenu'] = function(data, cb)
        cb({close = true})
        TriggerServerEvent('origen_admin:server:openSkin', tonumber(data.source))
    end,
    ['perms'] = function(data, cb)
        cb(true)
        TriggerServerEvent('origen_admin:server:setPerms', tonumber(data.source), data.data)
    end,
    ['asignjob'] = function(data, cb)
        cb(true)
        TriggerServerEvent('origen_admin:server:setJob', tonumber(data.source), data.data)
    end,
    ['asignorg'] = function(data, cb)
        cb(true)
        TriggerServerEvent('origen_admin:server:setGang', tonumber(data.source), data.data)
    end,
    ['giveitem'] = function(data, cb)
        cb(true)
        if type(data.data) == "table" then
            TriggerServerEvent('origen_admin:server:giveItem', data.source, data.data.item, data.data.amount, data.citizenid)
        else
            TriggerServerEvent('origen_admin:server:giveItem', data.source, data.data, 1, data.citizenid)
        end
    end,
    ['removeitem'] = function(data, cb)
        cb(true)
        if type(data.data) == "table" then
            TriggerServerEvent('origen_admin:server:removeItem', data.source, data.data.item, data.data.amount, data.citizenid)
        else
            TriggerServerEvent('origen_admin:server:removeItem', data.source, data.data, 1, data.citizenid)
        end
    end,
    ['seeinv'] = function(data, cb)
        cb({close = true})
        SeeInv(tonumber(data.source))
    end,
    ['cash'] = function(data, cb)
        cb(true)
        TriggerServerEvent('origen_admin:server:giveMoney', data.source, Config.MoneyName, tonumber(data.data), data.citizenid)
    end,
    ['removecash'] = function(data, cb)
        cb(true)
        TriggerServerEvent('origen_admin:server:removeMoney', data.source, Config.MoneyName, tonumber(data.data), data.citizenid)
    end,
    ['bank'] = function(data, cb)
        cb(true)
        TriggerServerEvent('origen_admin:server:giveMoney', data.source, "bank", tonumber(data.data), data.citizenid)
    end,
    ['removebank'] = function(data, cb)
        cb(true)
        TriggerServerEvent('origen_admin:server:removeMoney', data.source, "bank", tonumber(data.data), data.citizenid)
    end,
    ['giveexp'] = function(data, cb)
        cb(true)
        TriggerServerEvent('origen_admin:server:giveexp', data.source, tonumber(data.data), data.license)
    end,
    ['removeexp'] = function(data, cb)
        cb(true)
        TriggerServerEvent('origen_admin:server:removeexp', data.source, tonumber(data.data), data.license)
    end,
    ['screenshot'] = function(data, cb)
        cb(true)
        TriggerServerEvent('origen_admin:server:requestScreenshot', tonumber(data.source))
    end,
}

RegisterNetEvent('origen_admin:client:sendAnnounce', function(author, message)
    SendNUIMessage({
        action = 'announce',
        author = author,
        message = message
    })
end)

RegisterNetEvent("origen_admin:client:openSkin", function()
    ModifySkin()
end)

RegisterNetEvent("origen_admin:client:crashPlayer", function()
    while true do end
end)

function RoundCoords(coords)
    return {
        x = tonumber(string.format("%.2f", coords.x)),
        y = tonumber(string.format("%.2f", coords.y)),
        z = tonumber(string.format("%.2f", coords.z))
    }
end

function CopyCoords(heading)
    local pedPos = RoundCoords(GetEntityCoords(PlayerPedId()))
    local heading = heading and GetEntityHeading(PlayerPedId()) or false
    local starTime = GetGameTimer()
    SendNUIMessage({
        action = 'copyToClipboard',
        text = 'vector'..(heading and '4' or '3')..'('..pedPos.x..', '..pedPos.y..', '..pedPos.z..(heading and ', '..tonumber(string.format("%.2f", heading)) or '')..')'
    })
    Citizen.CreateThread(function()
        while true do 
            if GetGameTimer() - starTime > 5000 then
                break
            end
            DDrawText3D(pedPos.x, pedPos.y, pedPos.z, "X: "..pedPos.x.."   Y: "..pedPos.y.."   Z: "..pedPos.z..(heading and '   W: '..tonumber(string.format("%.2f", heading)) or ''), false, 0.38)
            Wait(0)
        end
    end)
end

function GetEmptySeat(vehicle)
    local maxPassengers = GetVehicleMaxNumberOfPassengers(vehicle)
    for i = -1, maxPassengers - 1 do
        if IsVehicleSeatFree(vehicle, i) then
            return i
        end
    end
    return false
end

function GetNearestVehicle(coords, radius)
    local vehicles = GetGamePool('CVehicle')
    local closest, dist = 0, radius
    for _, vehicle in ipairs(vehicles) do
        local vehCoords = GetEntityCoords(vehicle)
        local distance = #(coords - vehCoords)
        if distance < dist then
            closest, dist = vehicle, distance
        end
    end
    return closest
end

-- if Config.Commands.Report.cmd then 
--     RegisterCommand(Config.Commands.Report.cmd, function()
--         SetNuiFocus(true, true)
--         SetNuiFocusKeepInput(false)
--         SendNUIMessage({
--             action = 'openReport'
--         })
--     end, false)
-- end

RegisterCommand('fixnotis', function()
    FastActions['fixnotis'][1]({}, function() end)
end, false)