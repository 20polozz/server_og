local DynamicRadioCodes = {}

function GetDynamicRadioCodes()
    return DynamicRadioCodes
end

local vehicleColors = {
    [0] = "Negro", [1] = "Negro", [2] = "Negro", [3] = "Negro", [4] = "Gris", [5] = "Gris", [6] = "Gris", [7] = "Gris", [8] = "Gris", [9] = "Gris",
    [10] = "Gris", [11] = "Negro", [12] = "Negro", [13] = "Negro", [14] = "Negro", [15] = "Negro", [16] = "Negro", [17] = "Negro", [18] = "Negro", [19] = "Negro",
    [20] = "Negro", [21] = "Negro", [22] = "Negro", [23] = "Negro", [24] = "Negro", [25] = "Negro", [26] = "Negro", [27] = "Rojo", [28] = "Rojo", [29] = "Rojo",
    [30] = "Rojo", [31] = "Rojo", [32] = "Rojo", [33] = "Rojo", [34] = "Rojo", [35] = "Rojo", [36] = "Rojo", [37] = "Rojo", [38] = "Rojo", [39] = "Naranja",
    [40] = "Naranja", [41] = "Naranja", [42] = "Naranja", [43] = "Rojo", [44] = "Rojo", [45] = "Rojo", [46] = "Rojo", [47] = "Rojo", [48] = "Rojo", [49] = "Verde",
    [50] = "Verde", [51] = "Verde", [52] = "Verde", [53] = "Verde", [54] = "Verde", [55] = "Verde", [56] = "Verde", [57] = "Verde", [58] = "Verde", [59] = "Azul",
    [60] = "Azul", [61] = "Azul", [62] = "Azul", [63] = "Azul", [64] = "Azul", [65] = "Azul", [66] = "Azul", [67] = "Azul", [68] = "Azul", [69] = "Azul",
    [70] = "Azul", [71] = "Azul", [72] = "Azul", [73] = "Azul", [74] = "Azul", [75] = "Azul", [76] = "Azul", [77] = "Azul", [78] = "Azul", [79] = "Azul",
    [80] = "Azul", [81] = "Azul", [82] = "Azul", [83] = "Azul", [84] = "Azul", [85] = "Azul", [86] = "Azul", [87] = "Azul", [88] = "Amarillo", [89] = "Amarillo",
    [90] = "Amarillo", [91] = "Amarillo", [92] = "Verde", [93] = "Verde", [94] = "Verde", [95] = "Verde", [96] = "Marrón", [97] = "Marrón", [98] = "Marrón", [99] = "Marrón",
    [100] = "Marrón", [101] = "Marrón", [102] = "Marrón", [103] = "Marrón", [104] = "Marrón", [105] = "Marrón", [106] = "Marrón", [107] = "Marrón", [108] = "Marrón", [109] = "Marrón",
    [110] = "Marrón", [111] = "Blanco", [112] = "Blanco", [113] = "Blanco", [114] = "Marrón", [115] = "Marrón", [116] = "Marrón", [117] = "Negro", [118] = "Negro", [119] = "Negro",
    [120] = "Gris", [121] = "Blanco", [122] = "Blanco", [123] = "Naranja", [124] = "Naranja", [125] = "Verde", [126] = "Amarillo", [127] = "Verde", [128] = "Verde", [129] = "Marrón",
    [130] = "Naranja", [131] = "Blanco", [132] = "Blanco", [133] = "Blanco", [134] = "Blanco", [135] = "Rosa", [136] = "Rosa", [137] = "Rosa", [138] = "Naranja", [139] = "Verde",
    [140] = "Azul", [141] = "Azul", [142] = "Negro", [143] = "Rojo", [144] = "Gris", [145] = "Morado", [146] = "Morado", [147] = "Negro", [148] = "Morado", [149] = "Morado",
    [150] = "Rojo", [151] = "Gris", [152] = "Gris", [153] = "Gris", [154] = "Gris", [155] = "Gris", [156] = "Gris", [157] = "Azul", [158] = "Negro", [159] = "Negro",
    [160] = "Negro"
}

local function safe_replace(str, placeholder, replacement)
    if not replacement then replacement = "" end
    local safe_repl = tostring(replacement):gsub("%%", "%%%%")
    return str:gsub(placeholder, safe_repl)
end

RegisterNetEvent("origen_police:client:SyncRadioCodes", function(data)
    DynamicRadioCodes = data
    SendNUIMessage({
        action = "UpdateRadioCodes",
        codes = data
    })
    SendNUIMessage({
        action = "adminRadioCodesUpdated",
        codes = data
    })
end)

CreateThread(function()
    Wait(5000)
    TriggerServerEvent("origen_police:server:RequestRadioCodes")
end)

local function GetJobRadioCommand()
    return 'rpol'
end

function Calls(id)
    local cmd = GetJobRadioCommand()
    local PlayerData = FW_GetPlayerData(true)
    local userData = CanOpenTablet(PlayerData.job.name)
    local jobCategory = userData[2] or "police"
    
    -- Check if it's a dynamic code first
    if DynamicRadioCodes[jobCategory] then
        for _, code in ipairs(DynamicRadioCodes[jobCategory]) do
            if (code.label == id or tostring(code.id) == tostring(id)) and code.hidden ~= 1 then
                if code.action_type == "native" then
                    id = code.label
                    break -- Let the fallback handle it
                end
                
                local msg = code.message_template
                if msg == "" then msg = nil end
                local dispMsg = code.dispatch_template
                if dispMsg == "" then dispMsg = nil end
                
                if msg or dispMsg then
                    -- Process template variables
                    local targetPlate = "N/A"
                    local targetModel = "N/A"
                    local targetColor = "N/A"
                    
                    local targetVeh = 0
                    local ped = PlayerPedId()
                    if HelicamLockedVehicle and DoesEntityExist(HelicamLockedVehicle) then
                        targetVeh = HelicamLockedVehicle
                    else
                        local entity = IsPedInAnyVehicle(ped, false) and GetVehiclePedIsIn(ped, false) or ped
                        local _, _, _, _, e = GetShapeTestResult(StartShapeTestCapsule(GetOffsetFromEntityInWorldCoords(entity, 0.0, 1.0, 1.0), GetOffsetFromEntityInWorldCoords(entity, 0.0, 105.0, 0.0), 3.0, 10, entity, 7))
                        if e and DoesEntityExist(e) and IsEntityAVehicle(e) then
                            targetVeh = e
                        elseif IsPedInAnyVehicle(ped, false) then
                            targetVeh = GetVehiclePedIsIn(ped, false)
                        else
                            local coords = GetEntityCoords(ped)
                            local closest = FW_GetClosestVehicle(coords)
                            if closest and closest ~= 0 and #(coords - GetEntityCoords(closest)) <= 15.0 then
                                targetVeh = closest
                            end
                        end
                    end
                    
                    if targetVeh and targetVeh ~= 0 and DoesEntityExist(targetVeh) then
                        targetPlate = GetVehiclePlate(targetVeh) or "N/A"
                        
                        local modelHash = GetEntityModel(targetVeh)
                        targetModel = GetLabelText(GetDisplayNameFromVehicleModel(modelHash))
                        if targetModel == "NULL" then
                            targetModel = GetDisplayNameFromVehicleModel(modelHash)
                        end
                        
                        local primaryColor, secondaryColor = GetVehicleColours(targetVeh)
                        targetColor = vehicleColors[primaryColor] or "Desconocido"
                    end
                    
                    local agentName = ""
                    if PlayerData.charinfo and PlayerData.charinfo.firstname then
                        agentName = PlayerData.charinfo.firstname .. " " .. PlayerData.charinfo.lastname
                        if PlayerData.metadata and PlayerData.metadata.police_badge then
                            agentName = agentName .. " (" .. PlayerData.metadata.police_badge .. ")"
                        end
                    else
                        agentName = GetPlayerName(PlayerId())
                    end

                    local currentFrecName = nil
                    if Radio then
                        if Radio.MultiFrec and Radio.MultiFrec ~= "none" and Radio.MultiFrec ~= "" then
                            currentFrecName = Radio.MultiFrec
                        elseif Radio.Frec and Radio.Frec ~= 0 then
                            currentFrecName = "Frec. " .. tostring(Radio.Frec)
                        end
                    end
                    if not currentFrecName or currentFrecName == "none" then
                        pcall(function()
                            local f = exports["origen_police"]:GetCurrentFrequencyName()
                            if f and f ~= "none" and f ~= "" then
                                currentFrecName = f
                            end
                        end)
                    end
                    if not currentFrecName or currentFrecName == "none" then
                        currentFrecName = CurrentFrec
                    end

                    local unitName = "Sin Unidad"
                    if PlayerData.metadata and PlayerData.metadata.callsign and PlayerData.metadata.callsign ~= "NO CALLSIGN" and PlayerData.metadata.callsign ~= "" then
                        unitName = tostring(PlayerData.metadata.callsign)
                    elseif currentFrecName and currentFrecName ~= "none" and currentFrecName ~= "" then
                        unitName = tostring(currentFrecName)
                    end

                    if msg then
                        msg = safe_replace(msg, "{street}", GetStreetName(GetEntityCoords(PlayerPedId())))
                        msg = safe_replace(msg, "{vehiculo}", targetModel)
                        msg = safe_replace(msg, "{color}", targetColor)
                        msg = safe_replace(msg, "{matricula}", targetPlate)
                        msg = safe_replace(msg, "{agente}", agentName)
                        msg = safe_replace(msg, "{unit}", unitName)
                    end
                    
                    if dispMsg then
                        dispMsg = safe_replace(dispMsg, "{street}", GetStreetName(GetEntityCoords(PlayerPedId())))
                        dispMsg = safe_replace(dispMsg, "{vehiculo}", targetModel)
                        dispMsg = safe_replace(dispMsg, "{color}", targetColor)
                        dispMsg = safe_replace(dispMsg, "{matricula}", targetPlate)
                        dispMsg = safe_replace(dispMsg, "{agente}", agentName)
                        dispMsg = safe_replace(dispMsg, "{unit}", unitName)
                    end
                    
                    if code.action_type == "rpol" then
                        if msg then
                            ExecuteCommand(cmd .. ' ' .. msg)
                        end
                    elseif code.action_type == "dispatch" or code.action_type == "entorno" then
                        if code.action_type == "entorno" and msg then
                            ExecuteCommand(cmd .. ' ' .. msg)
                        end
                        if userData[1] then
                            local jobs = {}
                            local hasExactJobs = false
                            if code.alert_jobs and #code.alert_jobs > 0 then
                                jobs = code.alert_jobs
                                hasExactJobs = true
                            else
                                jobs = {userData[2]}
                                if userData[2] == "police" then table.insert(jobs, "fib") elseif userData[2] == "fib" then table.insert(jobs, "police") end
                            end
                            
                            local title = code.label
                            if code.alert_title and code.alert_title ~= "" then
                                title = code.alert_title
                            end
                            
                            if title then
                                title = safe_replace(title, "{street}", GetStreetName(GetEntityCoords(PlayerPedId())))
                                title = safe_replace(title, "{vehiculo}", targetModel)
                                title = safe_replace(title, "{color}", targetColor)
                                title = safe_replace(title, "{matricula}", targetPlate)
                                title = safe_replace(title, "{agente}", agentName)
                                title = safe_replace(title, "{unit}", unitName)
                            end

                            local alertColor = code.alert_color
                            if not alertColor or alertColor == "" then
                                alertColor = code.button_color
                            end
                            if not alertColor or alertColor == "" then
                                alertColor = nil
                            end

                            local alertSound = code.alert_sound
                            if not alertSound or alertSound == "" then
                                alertSound = nil
                            end

                            TriggerServerEvent("SendAlert:police", {
                                coords = GetEntityCoords(PlayerPedId()),
                                title = title,
                                color = alertColor,
                                sound = alertSound,
                                job = jobs,
                                message = dispMsg,
                                metadata = {
                                    name = (PlayerData.job.grade.label or PlayerData.job.grade.name) .. " " .. PlayerData.charinfo.lastname .. " (" .. (PlayerData.metadata.police_badge or "0000") .. ")",
                                },
                                ignoreCooldown = true,
                                exactJobs = hasExactJobs
                            })
                            -- Optionally update ref color for dispatch (only for QRR/Emergency codes)
                            local function IsEmergencyCode(lbl)
                                if not lbl then return false end
                                local l = tostring(lbl):lower()
                                return l:find("qrr") ~= nil or l:find("emergency") ~= nil or l:find("emergencia") ~= nil
                            end

                            if code.action_type == "dispatch" and IsEmergencyCode(title or code.label) then
                                TriggerServerEvent("origen_police:server:updateref", { color = 1 })
                            end
                        end
                    end
                end
                return -- Stop processing since we found a dynamic code match
            end
        end
    end
    -- Fallback to hardcoded codes if not dynamic
    if id == "10.8" then
        UseCommand(cmd, Config.Translations["10.8"])
    elseif id == "10.10" then
        UseCommand(cmd, Config.Translations["10.10"])
    elseif id == "Cod 7" then
        local text = Config.Translations["Cod 7"]:format(GetStreetName(GetEntityCoords(PlayerPedId())))
        ExecuteCommand(cmd .. ' ' .. text)
    elseif id == "Parada Técnica" then
        local text = Config.Translations["Cod 7"]:format(GetStreetName(GetEntityCoords(PlayerPedId())))
        ExecuteCommand(cmd .. ' ' .. text)

    elseif id == "254-V" then
        local fplate, fmodel, targetCoords
        if HelicamLockedVehicle and DoesEntityExist(HelicamLockedVehicle) then
            fplate = GetVehiclePlate(HelicamLockedVehicle)
            fmodel = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(HelicamLockedVehicle)))
            if fmodel == "NULL" then fmodel = GetDisplayNameFromVehicleModel(GetEntityModel(HelicamLockedVehicle)) end
            targetCoords = GetEntityCoords(HelicamLockedVehicle)
        else
            fplate, fmodel = GetRadarVehicle()
            targetCoords = GetEntityCoords(PlayerPedId())
        end

        if fplate then
            local text = Config.Translations["254-V"]:format(fmodel, fplate, GetStreetName(targetCoords))
            ExecuteCommand('rpol ' .. text)
        end
    elseif id == "487-V" then
        local fplate, fmodel = GetRadarVehicle()

        if fplate then
            local text = Config.Translations["487-V"]:format(fmodel, fplate)
            ExecuteCommand('rpol ' .. text)
        end
    elseif id == "Cod 2" then
        UseCommand(cmd, Config.Translations["Cod 2"])
    elseif id == "10.22" then
        UseCommand(cmd, Config.Translations["10.22"])
    elseif id == "6-Adam" then
        UseCommand(cmd, Config.Translations["6-Adam"])
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)

        if vehicle == 0 or (GetPedInVehicleSeat(vehicle, -1) ~= ped and GetPedInVehicleSeat(vehicle, 0) ~= ped) then
            TriggerServerEvent("origen_police:server:updateref", {
                color = 50
            })
        else
            local players = {}
            for i = -1, 0 do
                local p = GetPedInVehicleSeat(vehicle, i)
                if p ~= 0 then
                    table.insert(players, GetPlayerServerId(NetworkGetPlayerIndexFromPed(p)))
                end
            end
            TriggerServerEvent("origen_police:server:updateref", {
                color = 50
            }, players)
        end
        SendNUIMessage({
            action = "SyncQuick",
            color = 50
        })
    elseif id == "10.98" then
        UseCommand(cmd, Config.Translations["10.98"])
    elseif id == "Veh 488" then
        local fplate, fmodel = GetRadarVehicle()

        if fplate then
            local text = Config.Translations["Veh 488"]:format(GetStreetName(GetEntityCoords(PlayerPedId())), fmodel, fplate)
            ExecuteCommand('rpol ' .. text)
        end
    elseif id == "Veh 487" then
        local fplate, fmodel = GetRadarVehicle()

        if fplate then
            local text = Config.Translations["Veh 487"]:format(GetStreetName(GetEntityCoords(PlayerPedId())), fmodel, fplate)
            ExecuteCommand('rpol ' .. text)
        end
    elseif id == "Veh Alt" then
        local fplate, fmodel = GetRadarVehicle()

        if fplate then
            local text = Config.Translations["Veh Alt"]:format(fmodel, fplate, GetStreetName(GetEntityCoords(PlayerPedId())))
            ExecuteCommand('rpol ' .. text)
        end
    elseif id == "10.6" then
        local fplate, fmodel = GetRadarVehicle()

        if fplate then
            local text = Config.Translations["10.6"]:format(fmodel, fplate, GetStreetName(GetEntityCoords(PlayerPedId())))
            ExecuteCommand(cmd .. ' ' .. text)
        end
    elseif id == "Ubicacion" then
        local PlayerData = FW_GetPlayerData(true)
        local userData = CanOpenTablet(PlayerData.job.name)
        UseCommand('me', Config.Translations["10-20ME"])
        local jobs = {"ambulance"}
        if userData[1] then
            table.insert(jobs, userData[2])
            if userData[2] == "police" then table.insert(jobs, "fib") elseif userData[2] == "fib" then table.insert(jobs, "police") end
        end
        TriggerServerEvent("SendAlert:police", {
            coords = GetEntityCoords(PlayerPedId()),
            title = "10-20",
            metadata = {
                name = (PlayerData.job.grade.label or PlayerData.job.grade.name) .. " " .. PlayerData.charinfo.lastname .. " (" .. (PlayerData.metadata.police_badge or "0000") .. ")",
            },
            job = jobs,
            ignoreCooldown = true
        })
    elseif id == "10-20" then
        local PlayerData = FW_GetPlayerData(true)
        local userData = CanOpenTablet(PlayerData.job.name)
        if userData[1] then
            UseCommand('me', Config.Translations["10-20ME"])
            local jobs = {userData[2]}
            if userData[2] == "police" then table.insert(jobs, "fib") elseif userData[2] == "fib" then table.insert(jobs, "police") end
            TriggerServerEvent("SendAlert:police", {
                coords = GetEntityCoords(PlayerPedId()),
                title = "10-20",
                job = jobs,
                metadata = {
                    name = (PlayerData.job.grade.label or PlayerData.job.grade.name) .. " " .. PlayerData.charinfo.lastname .. " (" .. (PlayerData.metadata.police_badge or "0000") .. ")",
                },
                ignoreCooldown = true
            })
        end
    elseif id == "QRR" then
        local PlayerData = FW_GetPlayerData(true)
        local userData = CanOpenTablet(PlayerData.job.name)
        if userData[1] then
            UseCommand('me', Config.Translations["QRRME"])
            local jobs = {userData[2]}
            if userData[2] == "police" then table.insert(jobs, "fib") elseif userData[2] == "fib" then table.insert(jobs, "police") end
            TriggerServerEvent("SendAlert:police", {
                coords = GetEntityCoords(PlayerPedId()),
                title = "QRR",
                job = jobs,
                message = Config.Translations["Agentatrisk"],
                metadata = {
                    name = (PlayerData.job.grade.label or PlayerData.job.grade.name) .. " " .. PlayerData.charinfo.lastname .. " (" .. (PlayerData.metadata.police_badge or "0000") .. ")",
                },
                ignoreCooldown = true
            })
            TriggerServerEvent("origen_police:server:updateref", {
                color = 1
            })
        end
    elseif id == "QRR-B" then
        local PlayerData = FW_GetPlayerData(true)
        local userData = CanOpenTablet(PlayerData.job.name)
        if userData[1] then
            UseCommand('me', Config.Translations["QRR-BME"])
            local jobs = {userData[2]}
            if userData[2] == "police" then table.insert(jobs, "fib") elseif userData[2] == "fib" then table.insert(jobs, "police") end
            TriggerServerEvent("SendAlert:police", {
                coords = GetEntityCoords(PlayerPedId()),
                title = "QRR-B (No prioritario)",
                job = jobs,
                message = Config.Translations["QRR-B"],
                metadata = {
                    name = (PlayerData.job.grade.label or PlayerData.job.grade.name) .. " " .. PlayerData.charinfo.lastname .. " (" .. (PlayerData.metadata.police_badge or "0000") .. ")",
                },
                ignoreCooldown = true
            })
            TriggerServerEvent("origen_police:server:updateref", {
                color = 1
            })
        end
    elseif id == "QRR-C" then
        local PlayerData = FW_GetPlayerData(true)
        local userData = CanOpenTablet(PlayerData.job.name)
        if userData[1] then
            UseCommand('me', Config.Translations["QRR-CME"])
            local jobs = {userData[2]}
            if userData[2] == "police" then table.insert(jobs, "fib") elseif userData[2] == "fib" then table.insert(jobs, "police") end
            TriggerServerEvent("SendAlert:police", {
                coords = GetEntityCoords(PlayerPedId()),
                title = "QRR-C (Robo)",
                job = jobs,
                message = Config.Translations["QRR-C"],
                metadata = {
                    name = (PlayerData.job.grade.label or PlayerData.job.grade.name) .. " " .. PlayerData.charinfo.lastname .. " (" .. (PlayerData.metadata.police_badge or "0000") .. ")",
                },
                ignoreCooldown = true
            })
            TriggerServerEvent("origen_police:server:updateref", {
                color = 1
            })
        end
    elseif id == "Emergency" then
        local PlayerData = FW_GetPlayerData(true)
        local userData = CanOpenTablet(PlayerData.job.name)
        if userData[1] then
            UseCommand('me', Config.Translations["QRRME"])
            local jobs = {userData[2]}
            if userData[2] == "police" then table.insert(jobs, "fib") elseif userData[2] == "fib" then table.insert(jobs, "police") end
            TriggerServerEvent("SendAlert:police", {
                coords = GetEntityCoords(PlayerPedId()),
                title = "Emergencia",
                job = jobs,
                message = Config.Translations["EMSRisk"],
                metadata = {
                    name = (PlayerData.job.grade.label or PlayerData.job.grade.name) .. " " .. PlayerData.charinfo.lastname .. " (" .. (PlayerData.metadata.police_badge or "0000") .. ")",
                },
                ignoreCooldown = true
            })
            TriggerServerEvent("origen_police:server:updateref", {
                color = 1
            })
        end
    elseif Config.Translations[id] then
        local PlayerData = FW_GetPlayerData(false)
        local jobType = GetJobCategory(PlayerData.job.name)
        if jobType == "ambulance" then
            ExecuteCommand('rpol ' .. Config.Translations[id])
        end
    end
end

RegisterCommand("rpol", function(source, args, raw) -- If you don't know what you're doing, don't touch anything.
    local PlayerData = FW_GetPlayerData(true)
    if CanOpenTablet(PlayerData.job.name)[1] and PlayerData.job.onduty then
        local myLevel = (type(PlayerData.job.grade) == "table" and (PlayerData.job.grade.level or PlayerData.job.grade.grade)) or PlayerData.job.grade or 0
        myLevel = tonumber(myLevel) or 0
        local isStateAdmin = (PlayerData.job.name == "sapd")
        local reqGrade = GetMinimunGrade(PlayerData.job.name, "RPOL")
        local canUse = isStateAdmin or (reqGrade == nil and IsBoss(myLevel)) or (reqGrade ~= nil and myLevel >= tonumber(reqGrade))
        if not canUse then
            FW_Notify("No tienes permisos para usar la radio RPOL.", "error")
            return
        end

        local message = table.concat(args, " ")

        local header = "^4"

        local unit = exports["origen_police"]:GetMultiFrec()
        if unit ~= "none" then
            header = header .. "[" .. unit:upper() .. "] "
        end

        header = header .. (PlayerData.job.grade.label or PlayerData.job.grade.name) .. " " .. PlayerData.charinfo.lastname .. " (" .. (PlayerData.metadata.police_badge or "0000") .. ")"
        TriggerServerEvent("origen_police:server:rpol", PlayerData.job.name, header .. "  ^0" .. message)
    end
end)


RegisterCommand("rpolems", function(source, args, raw)
    local PlayerData = FW_GetPlayerData(true)
    if CanOpenTablet(PlayerData.job.name)[1] and PlayerData.job.onduty then
        local myLevel = (type(PlayerData.job.grade) == "table" and (PlayerData.job.grade.level or PlayerData.job.grade.grade)) or PlayerData.job.grade or 0
        myLevel = tonumber(myLevel) or 0
        local isStateAdmin = (PlayerData.job.name == "sapd")
        local reqGrade = GetMinimunGrade(PlayerData.job.name, "RPOL")
        local canUse = isStateAdmin or (reqGrade == nil and IsBoss(myLevel)) or (reqGrade ~= nil and myLevel >= tonumber(reqGrade))
        if not canUse then
            FW_Notify("No tienes permisos para usar la radio RPOL.", "error")
            return
        end

        local message = table.concat(args, " ")
        local header = "^3[EMS-SAPD] "
        header = header .. (PlayerData.job.grade.label or PlayerData.job.grade.name) .. " " .. PlayerData.charinfo.lastname .. " (" .. (PlayerData.metadata.police_badge or "0000") .. ")"
        TriggerServerEvent("origen_police:server:rpolems", PlayerData.job.name, header .. "  ^0" .. message)
    end
end)
RegisterCommand("254-V", function(source, args, raw)
    Calls("254-V")
end)

RegisterCommand("cambiojurisdiccion", function(source, args, raw)
    local PlayerData = FW_GetPlayerData(false)
    if CanOpenTablet(PlayerData.job.name)[1] and PlayerData.job.onduty then
        if PlayerData.job.name == 'police' then
            ExecuteCommand('rpol ' .. Config.Translations['CambioJurisdiccionNorth'])
        elseif PlayerData.job.name == 'sheriff' then
            ExecuteCommand('rpol ' .. Config.Translations['CambioJurisdiccionSouth'])
        else
            ExecuteCommand('rpol ' .. Config.Translations['CambioJurisdiccionText'])
        end
    end
end)