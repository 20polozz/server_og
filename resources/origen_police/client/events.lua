--[[ ── Donde sacar el vehiculo del garaje de faccion (24/09) ─────────────

     Antes: si habia CUALQUIER coche a menos de 4 m del punto de salida (uno
     aparcado encima, el de otro compañero), solo salia «ExistVehicleInSpawn»
     y nadie podia sacar nada hasta que alguien lo moviera. Ahora se prueba el
     punto y, si esta ocupado, huecos a los lados (perpendicular al morro) y
     delante/detras, a pasos del tamaño del vehiculo. Un hueco vale si no hay
     vehiculo cerca y, en tierra, si el suelo esta a la misma altura (no cae
     dentro de un muro, de un tejado ni fuera del helipuerto). Solo si no queda
     ninguno libre sale el aviso de siempre. ]]
local HUECOS = {
    car  = { radio = 2.8, lateral = 3.2, largo = 6.5, pasos = 3, suelo = true },
    heli = { radio = 7.0, lateral = 12.0, largo = 12.0, pasos = 1, suelo = true },
    boat = { radio = 4.0, lateral = 7.0, largo = 12.0, pasos = 2, suelo = false },
}

local function HuecoLibre(x, y, z, cfg)
    if IsAnyVehicleNearPoint(x + 0.0, y + 0.0, z + 0.0, cfg.radio) then return nil end
    if not cfg.suelo then return z end
    local ok, gz = GetGroundZFor_3dCoord(x + 0.0, y + 0.0, z + 2.0, false)
    if not ok or math.abs(gz - z) > 1.5 then return nil end
    return math.max(z, gz)
end

function HuecoDeSalida(spawn, tipo)
    local cfg = HUECOS[tipo] or HUECOS.car
    local x, y, z, w = spawn.x + 0.0, spawn.y + 0.0, spawn.z + 0.0, (spawn.w or 0.0) + 0.0

    -- El punto configurado, con el criterio de siempre (4 m) para no cambiar
    -- nada cuando esta libre.
    local cerca = FW_GetClosestVehicle(vector3(x, y, z))
    if not cerca or cerca == 0 or cerca == -1 or #(vector3(x, y, z) - GetEntityCoords(cerca)) > 4 then
        return vector4(x, y, z, w)
    end

    local rad = math.rad(w)
    local fx, fy = -math.sin(rad), math.cos(rad)   -- hacia el morro
    local lx, ly = fy, -fx                         -- hacia el costado

    local candidatos = {}
    for i = 1, cfg.pasos do
        local d = cfg.lateral * i
        candidatos[#candidatos + 1] = { x + lx * d, y + ly * d }
        candidatos[#candidatos + 1] = { x - lx * d, y - ly * d }
    end
    candidatos[#candidatos + 1] = { x + fx * cfg.largo, y + fy * cfg.largo }
    candidatos[#candidatos + 1] = { x - fx * cfg.largo, y - fy * cfg.largo }

    for i = 1, #candidatos do
        local cx, cy = candidatos[i][1], candidatos[i][2]
        local cz = HuecoLibre(cx, cy, z, cfg)
        if cz then return vector4(cx, cy, cz, w) end
    end
    return nil
end

RegisterNetEvent("origen_police:client:buyveh", function(u, mIndex)
    local p = Tables.Markers[u][mIndex]
    local playerData = FW_GetPlayerData()
    local job = playerData.job.name
    local menu = {
        {
            header = Config.Translations.RequestVeh,
            isMenuHeader = true,
        }
    }
    
    -- Extra Vehicles
    if Config.ExtraVehicles then
        for model, data in pairs(Config.ExtraVehicles) do
            local isAllowed = false
            if not data.is_heli then
                if not data.jobs or #data.jobs == 0 then
                    isAllowed = true
                else
                    for _, j in ipairs(data.jobs) do
                        if j == job then isAllowed = true break end
                    end
                end
            end

            if isAllowed then
                table.insert(menu, {
                    header = data.label,
                    txt = Config.Translations.RequestVeh,
                    icon = "fa-solid fa-car",
                    params = {
                        isAction = true,
                        event = function()
                            local salida = HuecoDeSalida(p.spawn, "car")
                            if salida then
                                FW_SpawnVehicle(model, function(vehicle)
                                    SetVehicleFuel(vehicle, 100.0)
                                    SetEntityHeading(vehicle, p.spawn.w)
                                    TriggerEvent("vehiclekeys:client:SetOwner", GetVehiclePlate(vehicle))
                                    if GetResourceState("qs-vehiclekeys") == "started" then
                                        exports['qs-vehiclekeys']:GiveKeys(GetVehiclePlate(vehicle), GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)), true)
                                    end
                                    local entityModel = GetEntityModel(vehicle)
                                    local label = data.label or (Config.CustomCarLabels[entityModel] and Config.CustomCarLabels[entityModel] or GetLabelText(GetDisplayNameFromVehicleModel(entityModel)))
                                    TriggerServerEvent("origen_police:server:TrackVehicle", NetworkGetNetworkIdFromEntity(vehicle), label)
                                    GiveKeys('car', vehicle)
                                    AddVehicleExtras('car', vehicle, model)
                                end, salida.xyz, true)
                            else
                                ShowNotification(Config.Translations.ExistVehicleInSpawn)
                            end
                        end
                    }
                })
            end
        end
    end

    for category, vehicles in pairs(Config.Vehicles) do
        if category == "car" then
            if vehicles[job] then
                for name, data in pairs(vehicles[job]) do
                    if playerData.job.grade.level < data.grade then goto skip_this_veh end
                    table.insert(menu, {
                        header = data.label,
                        txt = Config.Translations.RequestVeh,
                        icon = "fa-solid fa-car",
                        params = {
                            isAction = true,
                            event = function()
                                local salida = HuecoDeSalida(p.spawn, "car")
                                if salida then
                                    FW_SpawnVehicle(name, function(vehicle)
                                        SetVehicleFuel(vehicle, 100.0)
                                        SetEntityHeading(vehicle, p.spawn.w)
                                        TriggerEvent("vehiclekeys:client:SetOwner", GetVehiclePlate(vehicle))

                                        if GetResourceState("qs-vehiclekeys") == "started" then
                                            exports['qs-vehiclekeys']:GiveKeys(GetVehiclePlate(vehicle), GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)), true)
                                        end
                                        local entityModel = GetEntityModel(vehicle)
                                        local label = Config.CustomCarLabels[entityModel] and Config.CustomCarLabels[entityModel] or GetLabelText(GetDisplayNameFromVehicleModel(entityModel))
                                        TriggerServerEvent("origen_police:server:TrackVehicle", NetworkGetNetworkIdFromEntity(vehicle), label)
                                        GiveKeys('car', vehicle)
                                        AddVehicleExtras('car', vehicle, name)
                                    end, salida.xyz, true)
                                else
                                    ShowNotification(Config.Translations.ExistVehicleInSpawn)
                                end
                            end
                        }
                    })
                    ::skip_this_veh::
                end
            end
        end
    end

    OpenMenu(menu)
end)

RegisterNetEvent("origen_police:client:deletevehicle", function()
    local vehicle = GetVehicleInCamera()

    if vehicle ~= 0 and #(GetEntityCoords(vehicle) - GetEntityCoords(PlayerPedId())) < 7 then
        if GetResourceState("qs-vehiclekeys") == "started" then
            exports['qs-vehiclekeys']:RemoveKeys(GetVehiclePlate(vehicle), GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
        end
        TaskLeaveVehicle(PlayerPedId(), vehicle, 64)
        RemoveKeys(vehicle)
        Wait(2000)
        FW_DeleteVehicle(vehicle)
    else
        ShowNotification(Config.Translations.MustLook)
    end
end)

RegisterNetEvent("origen_police:client:helicop", function(u, mIndex)
    local p = Tables.Markers[u][mIndex]
    local playerData = FW_GetPlayerData()
    local job = playerData.job.name
    local helis_menu = {
        {
            header = Config.Translations.Heliport,
            isMenuHeader = true,
        },
    }

    -- Extra Helicopters
    if Config.ExtraVehicles then
        for model, data in pairs(Config.ExtraVehicles) do
            local isAllowed = false
            if data.is_heli then
                if not data.jobs or #data.jobs == 0 then
                    isAllowed = true
                else
                    for _, j in ipairs(data.jobs) do
                        if j == job then isAllowed = true break end
                    end
                end
            end

            if isAllowed then
                table.insert(helis_menu, {
                    header = data.label,
                    txt = Config.Translations.TakeOutHeli,
                    icon = "fa-solid fa-helicopter",
                    params = {
                        isAction = true,
                        event = function()
                            local salida = HuecoDeSalida(p.spawn, "heli")
                            if salida then
                                FW_SpawnVehicle(model, function(vehicle)
                                    SetVehicleFuel(vehicle, 100.0)
                                    SetEntityHeading(vehicle, p.spawn.w)
                                    TriggerEvent("vehiclekeys:client:SetOwner", GetVehiclePlate(vehicle))
                                    if GetResourceState("qs-vehiclekeys") == "started" then
                                        exports['qs-vehiclekeys']:GiveKeys(GetVehiclePlate(vehicle), GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)), true)
                                    end
                                    GiveKeys('helicopter', vehicle)
                                    AddVehicleExtras('helicopter', vehicle, model)

                                    -- Custom Livery setting
                                    local modelHash = type(model) == "number" and model or GetHashKey(model)
                                    if modelHash == GetHashKey("hvpdconada") or modelHash == GetHashKey("hvpolmav") then
                                        local livery = nil
                                        if job == "police" or job == "sapd" then
                                            livery = 0
                                        elseif job == "sheriff" then
                                            livery = 1
                                        elseif job == "ambulance" then
                                            livery = 2
                                        end
                                        if livery then
                                            SetVehicleModKit(vehicle, 0)
                                            SetVehicleMod(vehicle, 48, livery, false)
                                            SetVehicleLivery(vehicle, livery)
                                        end
                                    end
                                end, salida.xyz, true)
                            else
                                ShowNotification(Config.Translations.ExistHelicopterInSpawn)
                            end
                        end
                    }
                })
            end
        end
    end

    for category, vehicles in pairs(Config.Vehicles) do
        if category == "heli" then
            if vehicles[job] then
                for name, data in pairs(vehicles[job]) do
                    if playerData.job.grade.level < data.grade then goto skip_this_veh end
                    table.insert(helis_menu, {
                        header = data.label,
                        txt = Config.Translations.TakeOutHeli,
                        icon = "fa-solid fa-helicopter",
                        params = {
                            isAction = true,
                            event = function()
                                local salida = HuecoDeSalida(p.spawn, "heli")
                                if salida then
                                    FW_SpawnVehicle(name, function(vehicle)
                                        SetVehicleFuel(vehicle, 100.0)
                                        SetEntityHeading(vehicle, p.spawn.w)
                                        TriggerEvent("vehiclekeys:client:SetOwner", GetVehiclePlate(vehicle))

                                        if GetResourceState("qs-vehiclekeys") == "started" then
                                            exports['qs-vehiclekeys']:GiveKeys(GetVehiclePlate(vehicle), GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)), true)
                                        end
                                        GiveKeys('helicopter', vehicle)
                                        AddVehicleExtras('helicopter', vehicle, name)

                                        -- Custom Livery setting
                                        local modelHash = type(name) == "number" and name or GetHashKey(name)
                                        if modelHash == GetHashKey("hvpdconada") or modelHash == GetHashKey("hvpolmav") then
                                            local livery = nil
                                            if job == "police" or job == "sapd" then
                                                livery = 0
                                            elseif job == "sheriff" then
                                                livery = 1
                                            elseif job == "ambulance" then
                                                livery = 2
                                            end
                                            if livery then
                                                SetVehicleModKit(vehicle, 0)
                                                SetVehicleMod(vehicle, 48, livery, false)
                                                SetVehicleLivery(vehicle, livery)
                                            end
                                        end
                                    end, salida.xyz, true)
                                else
                                    ShowNotification(Config.Translations.ExistHelicopterInSpawn)
                                end
                            end
                        }
                    })
                    ::skip_this_veh::
                end
            end
        end
    end
    
    OpenMenu(helis_menu)

    helis_menu = nil
end)

RegisterNetEvent("origen_police:client:boat", function(u, mIndex)
    local p = Tables.Markers[u][mIndex]
    local playerData = FW_GetPlayerData()
    local job = playerData.job.name
    local boats_menu = {
        {
            header = Config.Translations.Pier,
            isMenuHeader = true,
        },
    }

    for category, vehicles in pairs(Config.Vehicles) do
        if category == "boat" then
            if vehicles[job] then
                for name, data in pairs(vehicles[job]) do
                    if playerData.job.grade.level < data.grade then goto skip_this_veh end
                    table.insert(boats_menu, {
                        header = data.label,
                        txt = Config.Translations.TakeOutBoat,
                        icon = "fa-solid fa-ship",
                        params = {
                            isAction = true,
                            event = function()
                                local salida = HuecoDeSalida(p.spawn, "boat")
                                if salida then
                                    FW_SpawnVehicle(name, function(vehicle)
                                        SetVehicleFuel(vehicle, 100.0)
                                        SetEntityHeading(vehicle, p.spawn.w)
                                        TriggerEvent("vehiclekeys:client:SetOwner", GetVehiclePlate(vehicle))

                                        if GetResourceState("qs-vehiclekeys") == "started" then
                                            exports['qs-vehiclekeys']:GiveKeys(GetVehiclePlate(vehicle), GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)), true)
                                        end
                                        GiveKeys('boat', vehicle)
                                        AddVehicleExtras('boat', vehicle, name)
                                    end, salida.xyz, true)
                                else
                                    ShowNotification(Config.Translations.ExistBoatInSpawn)
                                end
                            end
                        }
                    })
                    ::skip_this_veh::
                end
            end
        end
    end
    
    OpenMenu(boats_menu)
end)

RegisterNetEvent("origen_police:client:inventory", function(u, mIndex)
    local p = Tables.Markers[u][mIndex]

    OpenMenu({
        {
            header = Config.Translations.PoliceEquipment,
            isMenuHeader = true,
        },
        {
            header = Config.Translations.Equipment,
            txt = Config.Translations.EquipmentDesc,
            icon = 'fa-solid fa-gun',
            params = {
                isAction = true,
                event = function()
                    OpenArmoury()
                end
            }
        },
        {
            header = Config.Translations.LeaveEquipment,
            txt = Config.Translations.LeaveEquipmentDesc,
            icon = 'fa-solid fa-shield',
            params = {
                isAction = true,
                event = function()
                    LeavePoliceEquipment(p)
                end
            }
        },
        {
            header = Config.Translations.PoliceInventory,
            txt = Config.Translations.PoliceInventoryDesc,
            icon = 'fa-solid fa-box',
            params = {
                isAction = true,
                event = function()
                    PoliceInventory(p)
                end
            }
        },
        {
            header = Config.Translations.PersonalLocker or "Taquilla personal",
            txt = Config.Translations.PersonalLockerDesc or "Acceso a inventario privado",
            icon = 'fa-solid fa-lock',
            params = {
                isAction = true,
                event = function()
                    PersonalLocker(p)
                end
            }
        },
        {
            header = Config.Translations.EvidenceProof,
            txt = Config.Translations.EvidenceProofDesc,
            icon = 'fa-solid fa-receipt',
            params = {
                isAction = true,
                event = function()
                    OpenEvidenceInventory(p)
                end
            }
        }
    })
end)

RegisterNetEvent("origen_police:client:stash", function(u, mIndex)
    local p = Tables.Markers[u][mIndex]
    PoliceInventory(p)
end)

RegisterNetEvent("origen_police:client:ambulance_inventory", function(u, mIndex)
    local p = Tables.Markers[u][mIndex]

    OpenMenu({
        {
            header = "Armería y Taquilla Médica",
            isMenuHeader = true,
        },
        {
            header = "Equipamiento Médico",
            txt = "Acceso a la armería médica y equipo básico.",
            icon = 'fa-solid fa-notes-medical',
            params = {
                isAction = true,
                event = function()
                    OpenAmbulanceArmoury()
                end
            }
        },
        {
            header = Config.Translations.PersonalLocker or "Taquilla personal",
            txt = Config.Translations.PersonalLockerDesc or "Acceso a inventario privado",
            icon = 'fa-solid fa-lock',
            params = {
                isAction = true,
                event = function()
                    PersonalLocker(p)
                end
            }
        }
    })
end)

RegisterNetEvent("origen_police:client:vehicledata", function()
    local ped = PlayerPedId()
    local yo = GetEntityCoords(ped)
    local vehicle = GetVehicleInCamera()
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        vehicle = GetClosestVehicle(yo.x, yo.y, yo.z, 6.0, 0, 71)
    end

    local maxDist = Config.VehicleDataDist or 3.0
    if maxDist < 6.0 then maxDist = 6.0 end

    if vehicle ~= 0 and DoesEntityExist(vehicle) and #(GetEntityCoords(vehicle) - yo) <= maxDist then
        local rawPlate = GetVehiclePlate(vehicle) or ""
        local plate = rawPlate:gsub('^%s+', ''):gsub('%s+$', '')

        local modelHash = GetEntityModel(vehicle)
        local modelShort = GetDisplayNameFromVehicleModel(modelHash) or "Desconocido"
        local modelName = GetLabelText(modelShort)
        if not modelName or modelName == "" or modelName == "NULL" then
            modelName = modelShort
        end

        FW_TriggerCallback("origen_police:callback:vehicledata", function(result)
            local ownerName = (result and result ~= "") and result or "Desconocido"

            local function CopiarCampo(etiqueta, valor)
                local str = tostring(valor or "")
                if str == "" then return end
                pcall(function()
                    if exports['ox_lib'] and exports['ox_lib'].setClipboard then
                        exports['ox_lib']:setClipboard(str)
                    end
                end)
                SendNUIMessage({
                    action = "copy",
                    value = str
                })
                ShowNotification("Copiado al portapapeles (" .. etiqueta .. "): " .. str, "success")
            end

            OpenMenu({
                {
                    header = Config.Translations.VehicleInformation or "INFORMACIÓN DEL VEHÍCULO",
                    isMenuHeader = true,
                    hascursor = true,
                    cursor = true,
                },
                {
                    header = Config.Translations.Model or "Modelo",
                    txt = modelName,
                    icon = 'fa-solid fa-car',
                    copy = modelName,
                    noclose = true,
                    params = {
                        isAction = true,
                        copy = modelName,
                        event = function()
                            CopiarCampo(Config.Translations.Model or "Modelo", modelName)
                        end
                    }
                },
                {
                    header = Config.Translations.LicensePlate or "Matrícula",
                    txt = plate,
                    icon = 'fa-solid fa-id-card',
                    copy = plate,
                    noclose = true,
                    params = {
                        isAction = true,
                        copy = plate,
                        event = function()
                            CopiarCampo(Config.Translations.LicensePlate or "Matrícula", plate)
                        end
                    }
                },
                {
                    header = Config.Translations.Owner or "Dueño",
                    txt = ownerName,
                    icon = 'fa-solid fa-user',
                    copy = ownerName,
                    noclose = true,
                    params = {
                        isAction = true,
                        copy = ownerName,
                        event = function()
                            CopiarCampo(Config.Translations.Owner or "Dueño", ownerName)
                        end
                    }
                }
            })
        end, plate)
    else
        ShowNotification(Config.Translations.MustLook or "Debes mirar a un vehículo", "error")
    end
end)

RegisterNetEvent("origen_police:client:incautar", function()
    ConfiscateVeh('deposito', 'impound')
end)

RegisterNetEvent("origen_police:client:confiscar", function()
    ConfiscateVeh(Config.ConfiscateParkName, 'confiscate')
end)

RegisterNetEvent("origen_police:client:openveh", function()
    local vehicle = GetVehicleInCamera()

    if vehicle ~= 0 and #(GetEntityCoords(vehicle) - GetEntityCoords(PlayerPedId())) < 2 then
        local attempt = 0

        while not NetworkHasControlOfEntity(vehicle) and attempt < 100 and DoesEntityExist(vehicle) do
            Wait(100)
            NetworkRequestControlOfEntity(vehicle)
            attempt = attempt + 1
        end

        if DoesEntityExist(vehicle) and NetworkHasControlOfEntity(vehicle) then
            RequestAnimDict('anim@amb@clubhouse@tutorial@bkr_tut_ig3@')

            while not HasAnimDictLoaded('anim@amb@clubhouse@tutorial@bkr_tut_ig3@') do
                Wait(7)
            end

            TaskPlayAnim(PlayerPedId(), 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@' ,'machinic_loop_mechandplayer', 8.0, -8.0, -1, 1, 0, false, false, false)
            Wait(3000)
            ClearPedTasks(PlayerPedId())
            SetVehicleDoorsLocked(vehicle, 0)
            SetVehicleDoorsLockedForAllPlayers(vehicle, false) -- Fix completo
            GiveVehicleKeys(vehicle)
        else
            ShowNotification(Config.Translations.CouldntOpenLock)
        end
    else
        ShowNotification(Config.Translations.MustLook)
    end
end)

RegisterNetEvent("origen_police:client:vehevidences", function()
    local vehicle = GetVehicleInCamera()

    if vehicle ~= 0 and #(GetEntityCoords(vehicle) - GetEntityCoords(PlayerPedId())) < 2 then
        TriggerServerEvent("origen_police:server:GetEvidence", false, { type = "FinguerPrint", fkserie = GetVehiclePlate(vehicle) })
    else
        ShowNotification(Config.Translations.MustLook)
    end
end)

RegisterNetEvent("origen_police:client:makereport", function()
    local pData = FW_GetPlayerData(true) or {}
    local items = pData.items or {}
    local hasEvidence = false
    for _, v in pairs(items) do
        if v and v.name and string.find(v.name, '^evidence_') ~= nil then
            hasEvidence = true
            break
        end
    end

    if not hasEvidence then
        return ShowNotification(Config.Translations.NoEvidence or "No tienes evidencias para procesar")
    end

    local hecho = true
    if lib and lib.progressBar then
        hecho = lib.progressBar({
            duration = 2500,
            label = "Procesando evidencias...",
            canCancel = true,
            disable = { move = true, car = true, combat = true },
            anim = { dict = "missheistdockssetup1clipboard@base", clip = "base", flag = 49 },
        })
        ClearPedTasks(PlayerPedId())
    end

    if not hecho then return end

    TriggerServerEvent("origen_police:server:processEvidences")
end)

RegisterNetEvent("origen_police:client:onEvidenceProcessed", function(reportMeta)
    if reportMeta and reportMeta.list then
        SendNUIMessage({
            action = "AnalizeEvidences",
            list = reportMeta.list,
            date = reportMeta.time or GetCloudTimeAsInt()
        })
    end
end)

RegisterNetEvent("origen_police:client:makeFingerprintReport", function(metadata)
    local meta = metadata or {}
    local url = nil
    if GenerateEvidenceDocumentSVG then
        url = GenerateEvidenceDocumentSVG(meta, meta.type == "GSR" and "evidence_gsr" or "evidence_ne")
    end
    if not url or url == "" then
        url = meta.url
    end
    if url and url ~= "" then
        TriggerEvent("origen_police:client:showphoto", url)
    else
        FW_TriggerCallback("OsTime", function(time)
            SendNUIMessage({
                action = "AnalizeEvidences",
                list = {meta},
                date = time
            })
        end)
    end
end)

RegisterNetEvent("origen_police:client:makeRadarReport", function(metadata)
    local meta = metadata or {}
    local url = nil
    if GenerateEvidenceDocumentSVG then
        url = GenerateEvidenceDocumentSVG(meta, "ticket_radar")
    end
    if not url or url == "" then
        url = meta.url
    end
    if url and url ~= "" then
        TriggerEvent("origen_police:client:showphoto", url)
    else
        FW_TriggerCallback("OsTime", function(time)
            SendNUIMessage({
                action = "AnalizeEvidences",
                list = {meta},
                date = time
            })
        end)
    end
end)

RegisterNUICallback("focus", function(data, cb)
    -- El menu rapido deja de estar delante. Ver MenuRapidoAbierto.
    MenuRapidoAbierto = false
    --[[ Vuelve el seguimiento de misiones, salvo si lo que queda delante es
         la tablet: ahi sigue estorbando y lo esconde ella. ]]
    if not exports["origen_police"]:InTablet() then
        TriggerEvent('qv2:suppressHud', false)
    end

    local isCitationOpen = false
    pcall(function()
        if exports["origen_police"].IsCitationPadOpen then
            isCitationOpen = exports["origen_police"]:IsCitationPadOpen()
        end
    end)

    if not exports["origen_police"]:InTablet() and not isCitationOpen and not badgeVisible then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end
    cb(true)
end)

RegisterNUICallback("savereportevidence", function(data, cb)
    TriggerServerEvent("origen_police:server:savereportevidence", data.url)
    cb(true)
end)

RegisterNetEvent("origen_police:client:showbadge", function(data)
    local isCard = data.type == "SeguroMedico" or data.type == "Licencia" or data.type == "IDCard" or data.type == "Certificado" or data.type == "VehiclePapers" or data.isVehiclePapers or data.licenseType ~= nil or data.patientName ~= nil
    local PlayerData = FW_GetPlayerData()
    local isPolice = false
    
    if PlayerData and type(PlayerData.job) == "table" and PlayerData.job.name then
        local access = CanOpenTablet(PlayerData.job.name)
        if access and type(access) == "table" then
            isPolice = access[1]
        end
    end

    if Config.ShowBadgePreview or data.type == "VehiclePapers" or data.isVehiclePapers then
        TriggerEvent("origen_police:client:viewbadge", data)
    end
    
    if not isPolice and not Config.NotPoliceCanShowBadge and not isCard then return end
    
    local player, distance = FW_GetClosestPlayer()
    if player ~= -1 and distance <= 3.0 and distance > 0 then
        local dict = "paper_1_rcm_alt1-8"
        local anim = "player_one_dual-8"

        RequestAnimDict(dict)

        while not HasAnimDictLoaded(dict) do
            Wait(0)
        end

        local badgeConfig = GetBadgeConfig(nil, data.type)
        local model = badgeConfig and badgeConfig.model or (isCard and "prop_franklin_dl" or "prop_lspd_badge")

        RequestModel(model)

        while not HasModelLoaded(GetHashKey(model)) do
            Wait(0)
        end

        local prop = CreateObject(GetHashKey(model), GetEntityCoords(PlayerPedId()), true, true, true)
        TaskPlayAnim(PlayerPedId(), dict, anim, 8.0, 8.0, -1, 50, 0, false, false, false)
        if isCard then
            AttachEntityToEntity(prop, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 57005), 0.10, 0.02, -0.03, -90.00, 170.00, 78.99, true, true, false, true, 1, true)
        else
            AttachEntityToEntity(prop, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 28422), 0.09, 0.00, -0.05, -90.00, -180.00, 70.9, true, true, false, true, 1, true)
        end
        TriggerServerEvent("origen_police:server:showbadge", GetPlayerServerId(player), data)

        Wait(5000)
        ClearPedTasks(PlayerPedId())
        DeleteObject(prop)
	else
        if data.type ~= "VehiclePapers" and not data.isVehiclePapers and not data.isSelfPreview then
		    ShowNotification(Config.Translations.NoPersonNear, "error")
        end
	end
end)

local badgeVisible = false

--[[ La placa se cierra desde la interfaz (Escape o clic: BadgeOverlay manda
     closeBadge). Antes habia ademas un hilo leyendo IsControlJustPressed, pero
     con la NUI teniendo el foco el juego no recibe esas teclas y no llegaba a
     disparar nunca: se quito. ]]
RegisterNetEvent("origen_police:client:viewbadge", function(data)
    -- Un `type = 'none'` es el mensaje de CERRAR la placa: abrirla con el
    -- cogeria el raton para una pantalla que la interfaz no pinta.
    if type(data) ~= "table" or data.type == "none" then return end
    data.action = "ViewBadge"
    SendNUIMessage(data)
    SetNuiFocus(true, true)
    badgeVisible = true
end)

RegisterNUICallback("closeBadge", function(data, cb)
    if badgeVisible then
        badgeVisible = false
        -- Con el panel F7 debajo se le devuelve el raton; ver DevolverFocoTrasCapa.
        DevolverFocoTrasCapa()
    end
    cb(true)
end)

if OrigenFoco and OrigenFoco.AlSoltar then
    OrigenFoco.AlSoltar(function()
        if not badgeVisible then return end
        badgeVisible = false
        SendNUIMessage({
            action = "ViewBadge",
            type = "none"
        })
    end)
end

-- Radio
RegisterNUICallback("LoadRadio", function(data, cb)
    local PlayerData = FW_GetPlayerData(false)
    local myfrec = exports["origen_police"]:GetMultiFrec()
    if (not myfrec or myfrec == "none" or myfrec == "" or myfrec == false) and CurrentFrec and CurrentFrec ~= "none" and CurrentFrec ~= "" then
        myfrec = CurrentFrec
    end
    if (not myfrec or myfrec == "none" or myfrec == "" or myfrec == false) and Radio and Radio.MultiFrec and Radio.MultiFrec ~= "none" and Radio.MultiFrec ~= "" then
        myfrec = Radio.MultiFrec
    end
    if (not myfrec or myfrec == "none" or myfrec == "" or myfrec == false) and LocalPlayer and LocalPlayer.state and LocalPlayer.state.radioChannel and LocalPlayer.state.radioChannel > 0 then
        myfrec = tostring(LocalPlayer.state.radioChannel)
    end
    if not Config.NeedRadioForDispatch then
        exports["origen_police"]:Toggle(true)
        return cb({
            freclist = Config.MultifrecOrdered,
            myfrec = myfrec or "none"
        })
    end
    local count = exports.origen_inventory:Search('count', 'radio')
    if count > 0 then
        exports["origen_police"]:Toggle(true)
        return cb({ freclist = Config.MultifrecOrdered, myfrec = myfrec or "none" })
    end
    cb(false)
end)

RegisterNetEvent("origen_police:client:AddPlayerMultiFrec", function(id, frec, data)
    SendNUIMessage({
        radio = "AddPlayerMultiFrec",
        id = id,
        frec = frec,
        data = data,
        i = id == GetPlayerServerId(PlayerId())
    })
end)

RegisterNetEvent("origen_police:client:Disconnected", function()
    SendNUIMessage({
        radio = "Disconnected"
    })
end)

RegisterNetEvent("origen_police:client:talking", function(target, value)
    SendNUIMessage({
        radio = "Talking",
        target = target,
        value = value
    })
end)

RegisterNetEvent("origen_police:client:RemovePlayerMultiFrec", function(id, frec)
    SendNUIMessage({
        radio = "RemovePlayerMultiFrec",
        id = id,
        frec = frec
    })
end)

RegisterNetEvent("origen_police:client:SetMuted", function(id, value)
    SendNUIMessage({
        radio = "SetMuted",
        id = id,
        value = value
    })
end)

RegisterNetEvent("origen_police:client:SetReady", function(id, value)
    SendNUIMessage({
        radio = "SetReady",
        id = id,
        value = value
    })
end)
--[[ El nombre y el estado de un vehiculo se resuelven aqui porque el servidor
     no tiene los labels del juego: solo guarda el hash y el garaje.

     `otherwise` es lo que se ensena cuando el garaje no es policial: en el
     buscador de vehiculos, el nombre del garaje; en la ficha del ciudadano,
     nada. ]]
local function ShapeVehicle(v, otherwise)
    if type(v) ~= "table" then return end

    v.label = GetLabelText(GetDisplayNameFromVehicleModel(tonumber(v.hash) or 0))
    if v.label == "NULL" or v.label == "" then
        v.label = Config.CustomCarLabels[tonumber(v.hash) or 0] or 'UNKNOWN'
    end

    local garage = type(v.garage) == "string" and v.garage or nil
    if garage and garage:find("police_confiscate_veh") then
        v.status = Config.Translations.Confiscated
    elseif garage and garage:find("police_") then
        v.status = Config.Translations.PoliceFacilities
    else
        v.status = otherwise(garage)
    end

    v.garage = nil
    v.hash = nil
end

local function ownGarage(garage)
    return garage or (Config.Translations.Unknown or "Unknown")
end

local function noGarage()
    return ""
end

local function ShapeAnswer(name, retval)
    if type(retval) ~= "table" then return end

    if name == "origen_police:police:GetCitizen" then
        local vehicles = type(retval.vehicles) == "table" and retval.vehicles or nil
        if not vehicles then return end
        for i = 1, #vehicles do
            ShapeVehicle(vehicles[i], noGarage)
        end
    elseif name == "origen_police:police:SearchVehicle" then
        for i = 1, #retval do
            ShapeVehicle(retval[i], ownGarage)
        end
    elseif name == "origen_police:police:GetVehicle" then
        ShapeVehicle(retval, noGarage)
    elseif name == "origen_police:callback:GetStationsList" then
        for _, v in pairs(retval) do
            if type(v) == "table" then
                if not v.coords then
                    v.coords = {0, 0, 0}
                end
                v.street = GetStreetName(v.coords)
            end
        end
    end
end

RegisterNUICallback("TriggerCallback", function(data, cb)
    if not data.name:find("^origen_police") then return cb(false) end
    FW_TriggerCallback(data.name, function(retval)
        Debuger("Callback", json.encode(data, {indent = true}), json.encode(retval, {indent = true}))

        --[[ Dar forma a la respuesta no puede impedir contestarla.

             Cuando el servidor devolvia `false` — una ficha que no existe, una
             consulta que fallo — esto hacia `#retval.vehicles` sobre un
             booleano y reventaba ANTES de llamar a cb(). La interfaz no recibe
             nada, se queda esperando hasta el tope de 15 s y despues ensena una
             pantalla vacia sin decir por que. ]]
        local ok, err = pcall(ShapeAnswer, data.name, retval)
        if not ok then
            print(("^3[origen_police]^0 respuesta de %s sin dar forma: %s"):format(data.name, err))
        end

        cb(retval)
    end, data)
end)

RegisterNetEvent("origen_police:client:SyncQuick", function(data)
    if SetLocalReferenceOverride and (data.sprite or data.color) then
        SetLocalReferenceOverride(data.sprite, data.color)
    end
    data.action = "SyncQuick"
    SendNUIMessage(data)
end)

RegisterNetEvent("origen_police:client:SetWantedLevel", function(level)
    SetWantedLevel(level)
end)

RegisterNetEvent("origen_police:client:clothing", function(u, i, stationName)
    OpenClothing(stationName)
end)

RegisterNetEvent("origen_police:client:CriminalClothes", function()
    local PlayerData = FW_GetPlayerData(true)
    local ped = PlayerPedId()
    local gender = GetEntityModel(ped) == GetHashKey("mp_m_freemode_01") and "male" or GetEntityModel(ped) == GetHashKey("mp_f_freemode_01") and "female" or false

    SetCriminalClothes(gender, PlayerData)
end)

RegisterNetEvent("origen_police:client:PatientClothes", function()
    local PlayerData = FW_GetPlayerData(true)
    local ped = PlayerPedId()
    local gender = GetEntityModel(ped) == GetHashKey("mp_m_freemode_01") and "male" or GetEntityModel(ped) == GetHashKey("mp_f_freemode_01") and "female" or false

    SetPatientClothes(gender, PlayerData)
end)


RegisterNetEvent("origen_police:client:pertenences", function(mIndex)
    local p = Public.Markers[mIndex]
    TriggerServerEvent("origen_police:server:pertenences", p.station or 0)
end)

RegisterNetEvent("origen_police:client:modifyveh", function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 then
        return ShowNotification(Config.Translations.VehicleCannotBeFound)
    end
    SetVehicleModKit(vehicle, 0)
    if not IsVehicleValid("any", vehicle) then
        return ShowNotification(Config.Translations.InvalidVeh)
    end

    -- Forward declarations of menu functions
    local OpenCallsignMenu
    local OpenDigitAdjustmentMenu
    local OpenCallsignColorMenu
    local OpenEquipmentMenu
    local OpenModOptionsSubmenu
    local OpenExtrasMenu
    local OpenLiveriesMenu

    -- Helper to open Origen Menu (org-menu)
    local function ShowOrigenMenu(data)
        if GetResourceState('org-menu') == 'started' then
            exports['org-menu']:openMenu(data)
        else
            OpenMenu(data)
        end
    end

    -- Helper to sync and save vehicle modifications
    local function SyncAndSaveVehicleMods(veh)
        if not DoesEntityExist(veh) then return end
        SetVehicleModKit(veh, 0)
        local plate = GetVehicleNumberPlateText(veh)
        if not plate or plate == "" then return end
        plate = tostring(plate):gsub("^%s*(.-)%s*$", "%1")

        local props = nil
        if lib and lib.getVehicleProperties then
            props = lib.getVehicleProperties(veh)
        elseif QBCore and QBCore.Functions.GetVehicleProperties then
            props = QBCore.Functions.GetVehicleProperties(veh)
        end

        if props then
            Entity(veh).state:set('ox_lib:setVehicleProperties', props, true)
            TriggerServerEvent("origen_police:server:saveVehicleMods", plate, props)
        end
    end

    -- Detect callsign slots for current vehicle
    local function GetVehicleCallsignInfo(veh)
        SetVehicleModKit(veh, 0)
        local num5 = GetNumVehicleMods(veh, 5)
        local num42 = GetNumVehicleMods(veh, 42)
        local num43 = GetNumVehicleMods(veh, 43)
        local num44 = GetNumVehicleMods(veh, 44)
        local num45 = GetNumVehicleMods(veh, 45)

        -- 5-slot callsign system (tstudio police packs): Mod 5 (A), 42 (B), 43 (C), 44 (D), 45 (E)
        if num45 > 0 and num5 > 0 and num42 > 0 and num43 > 0 and num44 > 0 then
            return {
                type = "5slot",
                slots = {
                    { modId = 5,  label = "Dígito 1 (Posición A)", pos = 1 },
                    { modId = 42, label = "Dígito 2 (Posición B)", pos = 2 },
                    { modId = 43, label = "Dígito 3 (Posición C)", pos = 3 },
                    { modId = 44, label = "Dígito 4 (Posición D)", pos = 4 },
                    { modId = 45, label = "Dígito 5 (Posición E)", pos = 5 },
                },
                callsignModIds = { [5] = true, [42] = true, [43] = true, [44] = true, [45] = true }
            }
        end

        -- 3-slot legacy callsign system (42, 43, 44)
        if num42 > 0 and num43 > 0 and num44 > 0 then
            return {
                type = "3slot",
                slots = {
                    { modId = 42, label = "Dígito 1 (Posición 1)", pos = 1 },
                    { modId = 43, label = "Dígito 2 (Posición 2)", pos = 2 },
                    { modId = 44, label = "Dígito 3 (Posición 3)", pos = 3 },
                },
                callsignModIds = { [42] = true, [43] = true, [44] = true }
            }
        end

        -- Fallback for custom slots
        local fallback = {}
        local callsignModIds = {}
        for _, m in ipairs({5, 42, 43, 44, 45}) do
            if GetNumVehicleMods(veh, m) > 0 then
                table.insert(fallback, { modId = m, label = "Callsign (Mod " .. m .. ")", pos = #fallback + 1 })
                callsignModIds[m] = true
            end
        end
        if #fallback > 0 then
            return { type = "custom", slots = fallback, callsignModIds = callsignModIds }
        end

        return nil
    end

    -- Clear all callsign slots to -1
    local function ClearAllCallsigns(veh, callsignInfo)
        if not DoesEntityExist(veh) then return end
        SetVehicleModKit(veh, 0)
        if callsignInfo and callsignInfo.slots then
            for _, slot in ipairs(callsignInfo.slots) do
                SetVehicleMod(veh, slot.modId, -1, false)
            end
        end
        if callsignInfo and callsignInfo.type == "5slot" then
            SetVehicleMod(veh, 5, -1, false)
            SetVehicleMod(veh, 42, -1, false)
            SetVehicleMod(veh, 43, -1, false)
            SetVehicleMod(veh, 44, -1, false)
            SetVehicleMod(veh, 45, -1, false)
        end
        SyncAndSaveVehicleMods(veh)
    end

    -- Apply a callsign number string
    local function ApplyCallsignDigits(veh, numberStr, callsignInfo)
        if not DoesEntityExist(veh) or not callsignInfo then return false end
        SetVehicleModKit(veh, 0)

        local cleanDigits = tostring(numberStr or ""):gsub("%D", "")
        if cleanDigits == "" then return false end

        if callsignInfo.type == "5slot" then
            -- 5-slot tstudio system: Mod 5 = A, 42 = B, 43 = C, 44 = D, 45 = E
            if #cleanDigits == 1 then
                cleanDigits = "00" .. cleanDigits
            elseif #cleanDigits == 2 then
                cleanDigits = "0" .. cleanDigits
            end

            if #cleanDigits == 3 then
                -- 3 digits centered in B, C, D (slots 42, 43, 44). Slots A (5) and E (45) are disabled (-1)
                local d1 = tonumber(cleanDigits:sub(1, 1))
                local d2 = tonumber(cleanDigits:sub(2, 2))
                local d3 = tonumber(cleanDigits:sub(3, 3))

                SetVehicleMod(veh, 5, -1, false)
                SetVehicleMod(veh, 42, d1, false)
                SetVehicleMod(veh, 43, d2, false)
                SetVehicleMod(veh, 44, d3, false)
                SetVehicleMod(veh, 45, -1, false)
            elseif #cleanDigits == 4 then
                local d1 = tonumber(cleanDigits:sub(1, 1))
                local d2 = tonumber(cleanDigits:sub(2, 2))
                local d3 = tonumber(cleanDigits:sub(3, 3))
                local d4 = tonumber(cleanDigits:sub(4, 4))

                SetVehicleMod(veh, 5, d1, false)
                SetVehicleMod(veh, 42, d2, false)
                SetVehicleMod(veh, 43, d3, false)
                SetVehicleMod(veh, 44, d4, false)
                SetVehicleMod(veh, 45, -1, false)
            else
                -- 5 or more digits
                local d1 = tonumber(cleanDigits:sub(1, 1))
                local d2 = tonumber(cleanDigits:sub(2, 2))
                local d3 = tonumber(cleanDigits:sub(3, 3))
                local d4 = tonumber(cleanDigits:sub(4, 4))
                local d5 = tonumber(cleanDigits:sub(5, 5))

                SetVehicleMod(veh, 5, d1, false)
                SetVehicleMod(veh, 42, d2, false)
                SetVehicleMod(veh, 43, d3, false)
                SetVehicleMod(veh, 44, d4, false)
                SetVehicleMod(veh, 45, d5, false)
            end
        elseif callsignInfo.type == "3slot" then
            if #cleanDigits == 1 then
                cleanDigits = "00" .. cleanDigits
            elseif #cleanDigits == 2 then
                cleanDigits = "0" .. cleanDigits
            elseif #cleanDigits > 3 then
                cleanDigits = cleanDigits:sub(-3)
            end
            local d1 = tonumber(cleanDigits:sub(1, 1))
            local d2 = tonumber(cleanDigits:sub(2, 2))
            local d3 = tonumber(cleanDigits:sub(3, 3))

            SetVehicleMod(veh, 42, d1, false)
            SetVehicleMod(veh, 43, d2, false)
            SetVehicleMod(veh, 44, d3, false)
        else
            for i, slot in ipairs(callsignInfo.slots) do
                if i <= #cleanDigits then
                    local d = tonumber(cleanDigits:sub(i, i))
                    SetVehicleMod(veh, slot.modId, d, false)
                else
                    SetVehicleMod(veh, slot.modId, -1, false)
                end
            end
        end

        SyncAndSaveVehicleMods(veh)
        return true, cleanDigits
    end

    -- Helper for user text input dialog (prioritizes org-input)
    local function PromptCustomInput(title, placeholder, cb, onCancel)
        if GetResourceState('org-menu') == 'started' then
            exports['org-menu']:closeMenu()
        end
        SetNuiFocus(false)
        SetNuiFocusKeepInput(false)

        CreateThread(function()
            Wait(120)
            SetNuiFocusKeepInput(false)
            if GetResourceState('org-input') == 'started' then
                local input = exports['org-input']:ShowInput({
                    header = title,
                    submitText = 'Confirmar',
                    icon = 'fa-solid fa-hashtag',
                    inputs = {
                        {
                            name = "value",
                            text = placeholder or title,
                            type = "text",
                            isRequired = true
                        }
                    }
                })
                SetNuiFocusKeepInput(false)
                Wait(100)
                if input and input.value and input.value ~= "" then
                    cb(tostring(input.value))
                elseif onCancel then
                    onCancel()
                end
            elseif lib and lib.inputDialog then
                local input = lib.inputDialog(title, {
                    { type = 'input', label = placeholder or title, placeholder = placeholder, required = true }
                })
                SetNuiFocusKeepInput(false)
                Wait(100)
                if input and input[1] and input[1] ~= "" then
                    cb(tostring(input[1]))
                elseif onCancel then
                    onCancel()
                end
            end
        end)
    end

    -- Callsign Colors Submenu
    OpenCallsignColorMenu = function(veh)
        local colors = {
            { label = "Blanco Hielo", colorId = 111, icon = "fa-solid fa-circle" },
            { label = "Negro", colorId = 0, icon = "fa-solid fa-circle" },
            { label = "Azul Policial", colorId = 64, icon = "fa-solid fa-circle" },
            { label = "Amarillo / Oro", colorId = 88, icon = "fa-solid fa-circle" },
            { label = "Rojo", colorId = 27, icon = "fa-solid fa-circle" },
            { label = "Gris Plata", colorId = 4, icon = "fa-solid fa-circle" },
        }

        local colorMenu = {
            {
                header = "COLOR DE PLACA / CALLSIGN",
                icon = "fa-solid fa-palette",
                isMenuHeader = true
            }
        }

        for _, col in ipairs(colors) do
            table.insert(colorMenu, {
                header = col.label,
                icon = col.icon,
                noclose = true,
                params = {
                    isAction = true,
                    event = function()
                        SetVehicleInteriorColour(veh, col.colorId)
                        SetVehicleDashboardColour(veh, col.colorId)
                        SyncAndSaveVehicleMods(veh)
                        TriggerEvent('origen_notify:client:Notify', 'Info', 'Color cambiado a ' .. col.label, 'success')
                    end
                }
            })
        end

        table.insert(colorMenu, {
            header = Config.Translations.Back,
            icon = "fa-solid fa-arrow-left",
            params = {
                isAction = true,
                event = function()
                    OpenCallsignMenu(veh)
                end
            }
        })

        ShowOrigenMenu(colorMenu)
    end

    -- Digit-by-digit adjustment menu
    OpenDigitAdjustmentMenu = function(veh, callsignInfo)
        local digitMenu = {
            {
                header = "AJUSTAR DÍGITO A DÍGITO",
                icon = "fa-solid fa-arrow-down-1-9",
                isMenuHeader = true
            }
        }

        for _, slot in ipairs(callsignInfo.slots) do
            local cur = GetVehicleMod(veh, slot.modId)
            local curTxt = cur == -1 and "Ninguno (Desactivado)" or tostring(cur)
            table.insert(digitMenu, {
                header = slot.label,
                txt = "Actual: " .. curTxt .. " (Click para cambiar 0-9)",
                icon = "fa-solid fa-rotate",
                noclose = true,
                params = {
                    isAction = true,
                    event = function()
                        local nextMod = cur + 1
                        if nextMod > 9 then
                            nextMod = -1
                        end
                        SetVehicleMod(veh, slot.modId, nextMod, false)
                        SyncAndSaveVehicleMods(veh)
                        OpenDigitAdjustmentMenu(veh, callsignInfo)
                    end
                }
            })
        end

        table.insert(digitMenu, {
            header = "LIMPIAR TODOS",
            icon = "fa-solid fa-eraser",
            txt = "Poner todas las posiciones a Ninguno",
            noclose = true,
            params = {
                isAction = true,
                event = function()
                    ClearAllCallsigns(veh, callsignInfo)
                    OpenDigitAdjustmentMenu(veh, callsignInfo)
                end
            }
        })

        table.insert(digitMenu, {
            header = Config.Translations.Back,
            icon = "fa-solid fa-arrow-left",
            params = {
                isAction = true,
                event = function()
                    OpenCallsignMenu(veh)
                end
            }
        })

        ShowOrigenMenu(digitMenu)
    end

    -- Callsign Management Menu
    OpenCallsignMenu = function(veh)
        local callsignInfo = GetVehicleCallsignInfo(veh)
        local menu = {}

        if not callsignInfo or #callsignInfo.slots == 0 then
            table.insert(menu, {
                header = "NO TIENE CALLSIGNS",
                txt = "Este vehículo no dispone de modificaciones de callsign o número de placa.",
                icon = "fa-solid fa-ban",
                isMenuHeader = true
            })
            table.insert(menu, {
                header = Config.Translations.Back,
                icon = "fa-solid fa-arrow-left",
                params = {
                    isAction = true,
                    event = function()
                        TriggerEvent("origen_police:client:modifyveh")
                    end
                }
            })
            return ShowOrigenMenu(menu)
        end

        table.insert(menu, {
            header = "GESTIÓN DE CALLSIGNS / PLACA",
            icon = "fa-solid fa-hashtag",
            isMenuHeader = true
        })

        -- 1. Escribir Número Manual
        table.insert(menu, {
            header = "ESCRIBIR CALLSIGN MANUAL",
            icon = "fa-solid fa-keyboard",
            txt = "Escribe cualquier número o distintivo (ej. 104, 054, 12, 12345...)",
            params = {
                isAction = true,
                event = function()
                    PromptCustomInput("Número de Callsign / Placa", "Ej: 104, 054, 12, 12345", function(val)
                        local success, formatted = ApplyCallsignDigits(veh, val, callsignInfo)
                        if success then
                            TriggerEvent('origen_notify:client:Notify', 'Éxito', 'Callsign aplicado: ' .. formatted, 'success')
                            OpenCallsignMenu(veh)
                        else
                            TriggerEvent('origen_notify:client:Notify', 'Error', 'El texto introducido no contiene números válidos.', 'error')
                            OpenCallsignMenu(veh)
                        end
                    end, function()
                        OpenCallsignMenu(veh)
                    end)
                end
            }
        })

        -- 2. Ajustar Dígito a Dígito
        table.insert(menu, {
            header = "AJUSTAR DÍGITO A DÍGITO",
            icon = "fa-solid fa-arrow-down-1-9",
            txt = "Configurar individualmente cada posición (" .. #callsignInfo.slots .. " posiciones)",
            params = {
                isAction = true,
                event = function()
                    OpenDigitAdjustmentMenu(veh, callsignInfo)
                end
            }
        })

        -- 3. Color del número de placa
        table.insert(menu, {
            header = "COLOR DEL NÚMERO DE PLACA",
            icon = "fa-solid fa-palette",
            txt = "Cambiar color de los distintivos (Blanco, Negro, Azul, Oro...)",
            params = {
                isAction = true,
                event = function()
                    OpenCallsignColorMenu(veh)
                end
            }
        })

        -- 4. Limpiar todos los callsigns
        table.insert(menu, {
            header = "LIMPIAR TODOS LOS CALLSIGNS",
            icon = "fa-solid fa-eraser",
            txt = "Quitar todos los números y dejar el techo limpio",
            noclose = true,
            params = {
                isAction = true,
                event = function()
                    ClearAllCallsigns(veh, callsignInfo)
                    TriggerEvent('origen_notify:client:Notify', 'Info', 'Todos los callsigns han sido retirados.', 'success')
                    OpenCallsignMenu(veh)
                end
            }
        })

        -- Volver
        table.insert(menu, {
            header = Config.Translations.Back,
            icon = "fa-solid fa-arrow-left",
            params = {
                isAction = true,
                event = function()
                    TriggerEvent("origen_police:client:modifyveh")
                end
            }
        })

        ShowOrigenMenu(menu)
    end

    -- Known police equipment category definitions
    local PoliceEquipmentMap = {
        [35] = { label = "Defensa Delantera / Pushbar", icon = "fa-solid fa-shield-halved" },
        [8]  = { label = "Foco Policial (Izquierdo)", icon = "fa-solid fa-lightbulb" },
        [9]  = { label = "Foco Policial (Derecho)", icon = "fa-solid fa-lightbulb" },
        [10] = { label = "Antenas de Techo", icon = "fa-solid fa-tower-broadcast" },
        [49] = { label = "Cámaras ALPR (Lector de Matrículas)", icon = "fa-solid fa-camera" },
        [30] = { label = "Mampara de Detenidos", icon = "fa-solid fa-bars" },
        [34] = { label = "Consola Policial / Radio y Sirena", icon = "fa-solid fa-walkie-talkie" },
        [28] = { label = "Radar / Pantalla Salpicadero", icon = "fa-solid fa-desktop" },
        [46] = { label = "Rótulos de Puertas (Unit Tag)", icon = "fa-solid fa-tag" },
        [6]  = { label = "Parrilla Delantera", icon = "fa-solid fa-car" },
        [25] = { label = "Soporte de Matrícula", icon = "fa-solid fa-id-card" },
        [37] = { label = "Equipamiento de Maletero", icon = "fa-solid fa-box-open" },
        [0]  = { label = "Alerón / Barra Trasera", icon = "fa-solid fa-angles-up" },
        [1]  = { label = "Parachoques Delantero", icon = "fa-solid fa-car-side" },
        [2]  = { label = "Parachoques Trasero", icon = "fa-solid fa-car-side" },
        [3]  = { label = "Faldones Laterales", icon = "fa-solid fa-car-side" },
        [7]  = { label = "Capó", icon = "fa-solid fa-car" },
        [27] = { label = "Molduras / Detalles Interiores", icon = "fa-solid fa-car" },
    }

    -- Submenu to pick options for a specific equipment slot
    OpenModOptionsSubmenu = function(veh, mod, callsignInfo)
        local numMods = GetNumVehicleMods(veh, mod.modId)
        local curMod = GetVehicleMod(veh, mod.modId)

        local subMenu = {
            {
                header = mod.label,
                icon = mod.icon or "fa-solid fa-wrench",
                isMenuHeader = true
            },
            {
                header = "Desmontar / Ninguno",
                icon = (curMod == -1) and "fa-solid fa-circle-check" or "fa-solid fa-ban",
                txt = (curMod == -1) and "Actualmente desmontado" or "Quitar este accesorio",
                noclose = true,
                params = {
                    isAction = true,
                    event = function()
                        SetVehicleMod(veh, mod.modId, -1, false)
                        SyncAndSaveVehicleMods(veh)
                        OpenModOptionsSubmenu(veh, mod, callsignInfo)
                    end
                }
            }
        }

        for i = 0, numMods - 1 do
            local isSelected = (curMod == i)
            table.insert(subMenu, {
                header = "Opción " .. (i + 1),
                icon = isSelected and "fa-solid fa-circle-check" or "fa-solid fa-wrench",
                txt = isSelected and "Instalado actualmente" or ("Seleccionar opción " .. (i + 1)),
                noclose = true,
                params = {
                    isAction = true,
                    event = function()
                        SetVehicleMod(veh, mod.modId, i, false)
                        SyncAndSaveVehicleMods(veh)
                        OpenModOptionsSubmenu(veh, mod, callsignInfo)
                    end
                }
            })
        end

        table.insert(subMenu, {
            header = Config.Translations.Back,
            icon = "fa-solid fa-arrow-left",
            params = {
                isAction = true,
                event = function()
                    OpenEquipmentMenu(veh, callsignInfo)
                end
            }
        })

        ShowOrigenMenu(subMenu)
    end

    -- Equipment Menu
    OpenEquipmentMenu = function(veh, callsignInfo)
        callsignInfo = callsignInfo or GetVehicleCallsignInfo(veh)
        local callsignSlots = callsignInfo and callsignInfo.callsignModIds or {}

        local excludedMods = {
            [11] = true, -- Engine
            [12] = true, -- Brakes
            [13] = true, -- Transmission
            [14] = true, -- Horn
            [15] = true, -- Suspension
            [16] = true, -- Armour
            [18] = true, -- Turbo
            [20] = true, -- Tire Smoke
            [21] = true, -- Hydraulics
            [22] = true, -- Xenon
            [23] = true, -- Wheels
            [24] = true, -- Back Wheels
            [26] = true, -- Vanity Plate
            [38] = true, -- Hydro
            [48] = true, -- Livery mod
        }

        local availableEquipment = {}
        for modId = 0, 49 do
            if not callsignSlots[modId] and not excludedMods[modId] then
                local count = GetNumVehicleMods(veh, modId)
                if count > 0 then
                    local info = PoliceEquipmentMap[modId] or {
                        label = "Accesorio (Mod " .. modId .. ")",
                        icon = "fa-solid fa-wrench"
                    }
                    table.insert(availableEquipment, {
                        modId = modId,
                        label = info.label,
                        icon = info.icon,
                        count = count
                    })
                end
            end
        end

        local equipMenu = {}
        if #availableEquipment == 0 then
            table.insert(equipMenu, {
                header = "SIN EQUIPAMIENTO EXTRA",
                txt = "Este vehículo no dispone de equipamiento policial modificable.",
                icon = "fa-solid fa-ban",
                isMenuHeader = true
            })
        else
            table.insert(equipMenu, {
                header = "EQUIPAMIENTO POLICIAL",
                icon = "fa-solid fa-shield-halved",
                isMenuHeader = true
            })

            for _, eq in ipairs(availableEquipment) do
                local cur = GetVehicleMod(veh, eq.modId)
                local statusTxt = (cur == -1) and "Desmontado" or ("Instalado (Opción " .. (cur + 1) .. ")")
                table.insert(equipMenu, {
                    header = eq.label,
                    icon = eq.icon,
                    txt = "Variaciones: " .. eq.count .. " | " .. statusTxt,
                    params = {
                        isAction = true,
                        event = function()
                            OpenModOptionsSubmenu(veh, eq, callsignInfo)
                        end
                    }
                })
            end
        end

        table.insert(equipMenu, {
            header = Config.Translations.Back,
            icon = "fa-solid fa-arrow-left",
            params = {
                isAction = true,
                event = function()
                    TriggerEvent("origen_police:client:modifyveh")
                end
            }
        })

        ShowOrigenMenu(equipMenu)
    end

    -- Extras Menu
    OpenExtrasMenu = function()
        local extras = GetVehicleExtras(vehicle)
        local hasExtras = false
        for _ in pairs(extras) do hasExtras = true break end

        local extraMenu = {}
        if hasExtras then
            table.insert(extraMenu, {
                header = "EXTRAS DEL VEHÍCULO",
                icon = "fa-solid fa-puzzle-piece",
                isMenuHeader = true,
            })
            for extraId, enabled in pairs(extras) do
                table.insert(extraMenu, {
                    header = "EXTRA " .. tostring(extraId),
                    noclose = true,
                    txt = enabled and Config.Translations.Enabled or Config.Translations.Disabled,
                    icon = enabled and "fa-solid fa-circle-check" or "fa-solid fa-circle-xmark",
                    params = {
                        isAction = true,
                        event = function()
                            local disableArg = enabled and 1 or 0
                            SetVehicleExtra(vehicle, extraId, disableArg)
                            SyncAndSaveVehicleMods(vehicle)
                            OpenExtrasMenu()
                        end
                    }
                })
            end
        else
            table.insert(extraMenu, {
                header = "NO TIENE EXTRAS",
                txt = "Este vehículo no dispone de extras configurables.",
                icon = "fa-solid fa-ban",
                isMenuHeader = true
            })
        end
        table.insert(extraMenu, {
            header = Config.Translations.Back,
            icon = "fa-solid fa-arrow-left",
            params = {
                isAction = true,
                event = function()
                    TriggerEvent("origen_police:client:modifyveh")
                end
            }
        })
        ShowOrigenMenu(extraMenu)
    end

    -- Liveries Menu
    OpenLiveriesMenu = function()
        local modCount = GetNumVehicleMods(vehicle, 48)
        local liveryCount = GetVehicleLiveryCount(vehicle)
        local hasLiveries = modCount > 0 or liveryCount > 0

        local liveryMenu = {}
        if hasLiveries then
            table.insert(liveryMenu, {
                header = "LIVERIES / VINILOS",
                icon = "fa-solid fa-paint-brush",
                isMenuHeader = true,
            })

            table.insert(liveryMenu, {
                header = "QUITAR LIVERY",
                icon = "fa-solid fa-eraser",
                noclose = true,
                params = {
                    isAction = true,
                    event = function()
                        SetVehicleMod(vehicle, 48, -1)
                        SetVehicleLivery(vehicle, -1)
                        SyncAndSaveVehicleMods(vehicle)
                        OpenLiveriesMenu()
                    end
                }
            })

            if modCount > 0 then
                for liveryId = 0, modCount - 1 do
                    table.insert(liveryMenu, {
                        header = "LIVERY " .. tostring(liveryId + 1),
                        noclose = true,
                        icon = "fa-solid fa-paint-brush",
                        params = {
                            isAction = true,
                            event = function()
                                SetVehicleMod(vehicle, 48, liveryId)
                                SetVehicleLivery(vehicle, liveryId)
                                SyncAndSaveVehicleMods(vehicle)
                                OpenLiveriesMenu()
                            end
                        }
                    })
                end
            else
                for liveryId = 0, liveryCount - 1 do
                    table.insert(liveryMenu, {
                        header = "LIVERY " .. tostring(liveryId + 1),
                        noclose = true,
                        icon = "fa-solid fa-paint-brush",
                        params = {
                            isAction = true,
                            event = function()
                                SetVehicleLivery(vehicle, liveryId)
                                SetVehicleMod(vehicle, 48, liveryId)
                                SyncAndSaveVehicleMods(vehicle)
                                OpenLiveriesMenu()
                            end
                        }
                    })
                end
            end
        else
            table.insert(liveryMenu, {
                header = "NO TIENE LIVERIES",
                txt = "Este vehículo no dispone de liveries.",
                icon = "fa-solid fa-ban",
                isMenuHeader = true
            })
        end

        table.insert(liveryMenu, {
            header = Config.Translations.Back,
            icon = "fa-solid fa-arrow-left",
            params = {
                isAction = true,
                event = function()
                    TriggerEvent("origen_police:client:modifyveh")
                end
            }
        })
        ShowOrigenMenu(liveryMenu)
    end

    -- Main Modification Menu
    local menu = {
        {
            header = Config.Translations.VehicleMods,
            icon = "fa-solid fa-gear",
            isMenuHeader = true,
        },
        {
            header = "NÚMERO DE PLACA / CALLSIGNS",
            icon = "fa-solid fa-hashtag",
            txt = "Asignar callsign manual, por dígitos o color",
            params = {
                isAction = true,
                event = function()
                    OpenCallsignMenu(vehicle)
                end
            }
        },
        {
            header = "EQUIPAMIENTO POLICIAL",
            icon = "fa-solid fa-shield-halved",
            txt = "Pushbars, focos, antenas, mamparas, radar, ALPR...",
            params = {
                isAction = true,
                event = function()
                    OpenEquipmentMenu(vehicle)
                end
            }
        },
        {
            header = "LIVERIES / VINILOS",
            icon = "fa-solid fa-paint-brush",
            txt = "Diseños y rotulaciones de la patrulla",
            params = {
                isAction = true,
                event = function()
                    OpenLiveriesMenu()
                end
            }
        },
        {
            header = "EXTRAS",
            icon = "fa-solid fa-puzzle-piece",
            txt = "Luces secundarias y accesorios por extra",
            params = {
                isAction = true,
                event = function()
                    OpenExtrasMenu()
                end
            }
        },
        {
            header = "COLOR DEL NÚMERO DE PLACA",
            icon = "fa-solid fa-palette",
            txt = "Cambiar color de los números del techo",
            params = {
                isAction = true,
                event = function()
                    OpenCallsignColorMenu(vehicle)
                end
            }
        },
        {
            header = "LIMPIAR PATRULLA",
            icon = "fa-solid fa-soap",
            txt = "Lavar y limpiar suciedad del vehículo",
            params = {
                isAction = true,
                event = function()
                    SetVehicleDirtLevel(vehicle, 0.0)
                    WashDecalsFromVehicle(vehicle, 1.0)
                    SyncAndSaveVehicleMods(vehicle)
                    ShowNotification("Vehículo limpiado")
                end
            }
        }
    }

    ShowOrigenMenu(menu)
end)

RegisterNUICallback("SetVolume", function(data, cb)
    local volume = nil
    if type(data) == "table" then
        volume = tonumber(data.volume or data.value)
    elseif type(data) == "number" or type(data) == "string" then
        volume = tonumber(data)
    end

    if volume then
        if volume < 0 then volume = 0 end
        if volume > 100 then volume = 100 end
        volume = math.floor(volume + 0.5)
        SetResourceKvp("origen_police_radio_vol", tostring(volume))
        SetRadioVolume(volume)
    end

    if cb then cb("ok") end
end)

RegisterNUICallback("GetRadioVolume", function(data, cb)
    local vol = GetRadioVolume()
    if cb then cb(vol or 50) end
end)

CreateThread(function()
    Wait(2000)
    local savedVolStr = GetResourceKvpString("origen_police_radio_vol")
    if savedVolStr then
        local savedVol = tonumber(savedVolStr)
        if savedVol and savedVol >= 0 and savedVol <= 100 then
            SetRadioVolume(math.floor(savedVol + 0.5))
        end
    end
end)

RegisterNetEvent("origen_police:client:GenerateMugshotBadge", function(name, source, webhook)
    local mugshot = GetMugShotBase64(PlayerPedId(),false, webhook)
    TriggerServerEvent("origen_police:server:SaveMugshot", mugshot, name, source)
end)

RegisterNetEvent("origen_police:client:UpdateReport", function(reportid)
    SendNUIMessage({
        action = "UpdateReport",
        reportid = reportid
    })
end)

RegisterNetEvent("origen_police:client:DeleteReport", function(reportid)
    SendNUIMessage({
        action = "DeleteReport",
        reportid = reportid
    })
end)