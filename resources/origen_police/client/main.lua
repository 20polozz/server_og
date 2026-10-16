onduty = false
local location = {}
ValidVehicles = {}
local playerJobCategory = nil

if Config.Framework == "qbcore" then
    CreateThread(function()
        local PlayerData = Framework.Functions.GetPlayerData()

        if PlayerData.job then
            if PlayerData.job.onduty then
                SetDuty(true)
            end
        end
    end)

   RegisterNetEvent("origen_police:client:OnPlayerLoaded", function()
        local PlayerData = Framework.Functions.GetPlayerData()

        while not PlayerData.job do
            Wait(1000)
            PlayerData = Framework.Functions.GetPlayerData()
        end
        UpdatePlayerCategory(PlayerData.job.name)
        if PlayerData.job.onduty then
            SetDuty(true)
        end
        TriggerServerEvent("origen_police:admin:requestQuickmenuSync")
    end)
end

function UpdatePlayerCategory(jobName)
    if not jobName then
        local Player = FW_GetPlayerData(false)
        if Player and Player.job and Player.job.name then
            jobName = Player.job.name
        end
    end
    if not jobName then return end
    playerJobCategory = CanOpenTablet(jobName)[2]
end

function GetPlayerJobCategory()
    if playerJobCategory then
        return playerJobCategory
    end
    UpdatePlayerCategory()
    return playerJobCategory
end

RegisterNetEvent('origen_police:client:OnJobUpdate', function(jobData)
    local oldCat = playerJobCategory
    UpdatePlayerCategory(jobData.name)
    if oldCat ~= playerJobCategory then
        TriggerServerEvent("origen_police:admin:requestQuickmenuSync")
    end
end)

RegisterNetEvent("origen_police:client:enterOnDuty", function()
    if not CanOpenTablet(FW_GetPlayerData(false).job.name)[1] then return end
    TriggerEvent("origen_police:toggleDuty")
    SendNUIMessage({
        setDuty = true,
        duty = not onduty
    })
end)

RegisterNetEvent('origen_police:client:OnPlayerUnload', function()
    SetDuty(false)
    TriggerServerEvent("origen_police:server_esx:ForceDropDuty")
end)

RegisterNetEvent('origen_police:client:OnJobUpdate', function(job)
    local isPolice = CanOpenTablet(job.name)[1]
    if not isPolice then return SetDuty(false) end
    if job.onduty ~= nil and job.onduty ~= onduty then
        SetDuty(job.onduty)
    end
end)

function SetDuty(duty)
    local Player = FW_GetPlayerData(false)
    local openTablet = CanOpenTablet(Player.job.name)
    local jobCat = openTablet[2]
    if not duty then
        ToggleAlerts(false)
    end
    if openTablet[1] then
        SendNUIMessage({ action = "status", onduty = duty })
    end
    if duty == onduty or openTablet[1] == false then return end

    onduty = duty

    if not onduty then
        -- Salir de servicio:
        -- 1. Forzar retirada de referencia propia y ocultar referencias de compañeros
        if ClearReferencesOffDuty then
            ClearReferencesOffDuty()
        else
            pcall(function() exports["origen_police"]:ClearReferencesOffDuty() end)
        end

        -- 2. Forzar desconexión total de frecuencias de radio
        if DisconnectAllRadio then
            DisconnectAllRadio()
        else
            pcall(function() exports["origen_police"]:DisconnectAllRadio() end)
        end

        -- 3. Limpieza en servidor
        TriggerServerEvent("origen_police:server:offDutyCleanup")
        return
    end

    StartAlerts()

    CreateThread(function()
        StartReferences()
        local _, hash = AddRelationshipGroup("POLICEDOG")
        local _, hashc = AddRelationshipGroup("COP")
        SetRelationshipBetweenGroups(0, hash, hashc)
        SetRelationshipBetweenGroups(0, hashc, hash)
        SetPedRelationshipGroupHash(PlayerPedId(), hashc)
        CreateThread(function()
            local PlayerData = FW_GetPlayerData(false)
            if PlayerData.job.onduty then
                TriggerServerEvent("origen_police:server:ClockIn")
            end
        end)
        while onduty do
            local w = 500
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            if Tables.Markers then
                for u, markersList in pairs(Tables.Markers) do
                    if not Config.IgnoreSettings and MapOptions and MapOptions[u] and MapOptions[u].AllowedJobCat and not IsJobAllowed(MapOptions[u], jobCat) then
                        goto skip_map
                    end
                    if markersList and type(markersList) == "table" then
                        for i = 1, #markersList do
                            local p = markersList[i]
                            if p and p.coords then
                                local d = #(coords - p.coords.xyz)
                                if d < 30 then
                                    w = 0
                                    if Config.MarkersDraw and p.sprite and p.rgba then
                                        local drawDist = p.drawDistance or 30
                                        if d < drawDist then
                                            local markerScale = p.scale or 0.3
                                            DrawMarker(p.sprite, p.coords.x, p.coords.y, p.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, markerScale, markerScale, markerScale, p.rgba.r, p.rgba.g, p.rgba.b, p.rgba.a, false, false, 0, true)
                                        end
                                    end
                                    if d < (p.radius or 1) then
                                        if Config.CustomNotify then
                                            ShowHelpNotification("E", p.text)
                                            p.noty = true
                                        else
                                            if Config.Framework == "qbcore" then
                                                if not p.noty then
                                                    exports['qb-core']:DrawText("[E] " .. p.text, 'left')
                                                    p.noty = true
                                                end
                                            elseif Config.Framework == "esx" then
                                                Framework.ShowHelpNotification("~INPUT_PICKUP~ " .. p.text, true)
                                            end
                                        end
                                        if IsControlJustPressed(0, 38) then
                                            Debuger("Marker interact: ", u, i, json.encode(p))
                                            TriggerEvent(p.event, u, i, p.stationName)
                                        end
                                    elseif p.noty then
                                        HideHelpNotification()
                                        p.noty = nil
                                    end
                                elseif p.noty then
                                    HideHelpNotification()
                                    p.noty = nil
                                end
                            end
                        end
                    end
                    ::skip_map::
                end
            end

            local veh = GetVehiclePedIsIn(ped, false)
            if veh ~= 0 and Config.ShowCurrentStreet then
                if not location.enabled or GetGameTimer() - location.enabled > 500 then
                    local street, cardinal = GetStreetName(coords), GetCardinalFromHeading(GetEntityHeading(veh))
                    location.enabled = GetGameTimer()
                    if not location.street or not location.cardinal or location.street ~= street or location.cardinal ~= cardinal then
                        location.street = street
                        location.cardinal = cardinal
                        SendNUIMessage({
                            action = "Location",
                            street = street,
                            cardinal = cardinal
                        })
                    end
                end
            elseif location.enabled then
                SendNUIMessage({
                    action = "HideLocation"
                })
                location = {}
            end

            Wait(w)
        end
        SendNUIMessage({
            action = "HideLocation"
        })
        location = {}
        if Tables.Markers then
            for u, markersList in pairs(Tables.Markers) do
                if markersList and type(markersList) == "table" then
                    for i = 1, #markersList do
                        if markersList[i] and markersList[i].noty then
                            HideHelpNotification()
                            break
                        end
                    end
                end
            end
        end
        TriggerServerEvent("origen_police:server:ClockOut")
    end)

    return onduty
end

HandlerManager:AddCallback("vehicle_sit", function(current, previous)
    if current then
        ValidVehicles[current] = IsVehicleValid("any", current, "sirens")
        Debuger("Is vehicle valid (sirens): " .. tostring(ValidVehicles[current]))
    else
        ValidVehicles[previous] = nil
        Debuger("Vehicle left: " .. tostring(previous))
    end
end)

CreateThread(function()
    local horn = false
    local sended = false
    -- HideCarMegaphone solo al pasar de visible a oculto; empieza en true para
    -- mandar el primero igual que antes
    local megafonoVisible = true
    local function OcultarMegafono()
        if megafonoVisible then
            megafonoVisible = false
            SendNUIMessage({ action = "HideCarMegaphone" })
        end
    end
    while true do
        local w = 500
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)

        local shouldExit =  not Config.SirensSystem and
                            (not Config.Commands.CamOrRappel or not Config.Commands.CamOrRappel.key) and
                            (not Config.Commands.TalkMegaphone or not Config.Commands.TalkMegaphone.key)
        if shouldExit then
            break
        end

        if veh ~= 0 then
            -- Megáfono: amplifica la voz a Config.MegaphoneVoiceDist y transmite en el canal de radio activo
            if ValidVehicles[veh] == true and Config.Commands.TalkMegaphone and Config.Commands.TalkMegaphone.key then
                if IsControlJustPressed(0, Config.Commands.TalkMegaphone.key) then
                    SendNUIMessage({ action = "ShowCarMegaphone" })
                    megafonoVisible = true
                    LocalPlayer.state:set("submix", "radio", true)

                    local myPed    = PlayerPedId()
                    local myId     = GetPlayerServerId(PlayerId())
                    local megaDist = Config.MegaphoneVoiceDist or 45.0

                    -- 1. Ampliar el rango de proximidad de pma-voice
                    exports["pma-voice"]:overrideProximityRange(megaDist, true)

                    -- Función que recalcula y actualiza los voice targets dinámicamente
                    local function refreshTargets()
                        local myCoords = GetEntityCoords(PlayerPedId())
                        local nearbyTargets = {}

                        -- Jugadores cercanos dentro del rango
                        for _, playerId in ipairs(GetActivePlayers()) do
                            local serverId = GetPlayerServerId(playerId)
                            if serverId ~= myId then
                                if #(myCoords - GetEntityCoords(GetPlayerPed(playerId))) <= megaDist then
                                    nearbyTargets[serverId] = true
                                end
                            end
                        end

                        -- Jugadores del canal de radio activo
                        local radioOk, radio = pcall(function() return exports["origen_radio"]:GetRadio() end)
                        if radioOk and radio and radio.MultiFrec ~= "none" and radio.MultiFrecTargets and radio.MultiFrecTargets[radio.MultiFrec] then
                            for serverId, target in pairs(radio.MultiFrecTargets[radio.MultiFrec]) do
                                if not (target and target.muted) then
                                    nearbyTargets[tonumber(serverId)] = true
                                end
                            end
                        end

                        -- Actualizar voice targets de pma-voice
                        MumbleClearVoiceTargetPlayers(1)
                        if next(nearbyTargets) then
                            PlayerTargets(nearbyTargets)
                        end
                    end

                    -- 2. Obtener targets de radio para avisar al servidor
                    local radioTargets = {}
                    local radioOk, radio = pcall(function() return exports["origen_radio"]:GetRadio() end)
                    if radioOk and radio and radio.MultiFrec ~= "none" and radio.MultiFrecTargets and radio.MultiFrecTargets[radio.MultiFrec] then
                        for serverId, target in pairs(radio.MultiFrecTargets[radio.MultiFrec]) do
                            if not (target and target.muted) then
                                radioTargets[tonumber(serverId)] = true
                            end
                        end
                    end

                    -- 3. Aplicar targets iniciales y avisar al servidor (inicia loop de boost)
                    refreshTargets()
                    TriggerServerEvent("origen_police:megaphone:start", megaDist, radioTargets)

                    -- 4. Loop mientras Y esté pulsada: mantener mic activo y actualizar targets cada 500ms
                    local lastRefresh = GetGameTimer()
                    while IsControlPressed(0, Config.Commands.TalkMegaphone.key) do
                        Wait(0)
                        SetControlNormal(0, 249, 1.0)
                        SetControlNormal(1, 249, 1.0)
                        SetControlNormal(2, 249, 1.0)
                        -- Refrescar targets cada 500ms para detectar cambios de posición
                        if GetGameTimer() - lastRefresh >= 500 then
                            refreshTargets()
                            lastRefresh = GetGameTimer()
                        end
                    end

                    -- Al soltar Y: limpiar todo
                    TriggerServerEvent("origen_police:megaphone:stop")
                    MumbleClearVoiceTargetPlayers(1)
                    exports["pma-voice"]:clearProximityOverride()
                    OcultarMegafono()
                    LocalPlayer.state:set("submix", nil, true)
                end
            end

            if ValidVehicles[veh] == true then
                if Config.SirensSystem then
                    DisableControlAction(0, 85, true)
                    if Config.Commands.HornKey.disabledKey then
                        DisableControlAction(0, Config.Commands.HornKey.disabledKey, true)
                    end
                    SetVehRadioStation(veh, "OFF")
                    SetVehicleRadioEnabled(veh, false)
                    if GetPedInVehicleSeat(veh, -1) == ped then
                        if IsDisabledControlPressed(0, Config.Commands.HornKey.key) and not IsVehicleValid("heli", veh) then
                            if not sended then
                                sended = veh
                                TriggerServerEvent("origen_police:server:PoliceHornState", NetworkGetNetworkIdFromEntity(veh), true)
                            end
                        else
                            if sended then
                                sended = false
                                TriggerServerEvent("origen_police:server:PoliceHornState", NetworkGetNetworkIdFromEntity(veh), false)
                            end
                        end
                    end
                end
                w = 0
            elseif ValidVehicles[veh] == false then
                if horn and sended then
                    TriggerServerEvent("origen_police:server:PoliceHornState", NetworkGetNetworkIdFromEntity(sended), false)
                end
                horn = false
                sended = false
                OcultarMegafono()
            else
                -- ValidVehicles[veh] == nil: vehiculo aun no validado, esperar
            end

            -- Helicam: independent of sirens validation, uses its own vehicle check
            if Config.Commands.CamOrRappel and Config.Commands.CamOrRappel.key and IsControlJustPressed(0, Config.Commands.CamOrRappel.key) and GetVehicleClass(veh) == 15 then
                local isValidHeli = IsVehicleValid("any", veh)
                if isValidHeli then
                    local allowHelicam = true
                    local extraData = Config.ExtraVehiclesHashes and Config.ExtraVehiclesHashes[GetEntityModel(veh)]
                    if extraData and extraData.use_helicam == false then
                        allowHelicam = false
                    end
                    if allowHelicam then
                        DoCamOrRappel(veh)
                    end
                end
            end

            -- Por fotograma solo hace falta en vehiculo valido (megafono, sirenas,
            -- controles) o en helicoptero (IsControlJustPressed de la helicam);
            -- en el resto no hay nada que leer en cada fotograma
            if ValidVehicles[veh] == true or GetVehicleClass(veh) == 15 then
                w = 0
            else
                w = 250
            end
        else
            if horn and sended then
                TriggerServerEvent("origen_police:server:PoliceHornState", NetworkGetNetworkIdFromEntity(sended), false)
            end
            horn = false
            sended = false
            OcultarMegafono()
        end

        Wait(w)
    end
end)

RegisterNUICallback("duty", function(data, cb)
    local newDuty = (data and type(data) == "table" and data.duty ~= nil) and data.duty or (not onduty)
    if Config.Framework == "qbcore" then
        TriggerServerEvent("QBCore:ToggleDuty")
    elseif Config.Framework == "esx" then
        TriggerServerEvent("origen_police:server_esx:SetDuty", newDuty)
    end
    cb(newDuty)
end)

RegisterNetEvent("origen_police:ShowNotification", function(msg, type)
    ShowNotification(msg, type)
end)

RegisterNUICallback("GetWebhook", function(data, cb)
    GetCameraWebhook(function(url)
        if url then
            cb({url = url, fields = Config.Fields[Config.UploadMethod]})
        else
            cb(false)
            return ShowNotification(Config.UploadMethod == 'fivemanage' and "No hay URL de FiveManage configurada en config/logs/logs.lua" or "No hay webhook para las fotos en config/logs/logs.lua")
        end
    end)
end)

exports("GetPoliceDuty", function()
    return onduty
end)

exports("IsOnDuty", function()
    return onduty
end)

exports("GetPlayerJobCategory", GetPlayerJobCategory)