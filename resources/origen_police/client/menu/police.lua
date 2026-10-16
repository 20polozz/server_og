local heatAlerts = nil
local loadingHeatAlerts = false

RegisterNUICallback("LoadPolicePage", function(data, cb)
    local retval, PlayerData = {}, exports["origen_police"]:FW_GetPlayerData(true)

    if data.page == "home" then
        retval.service = PlayerData.job.onduty
        local res = false
        exports["origen_police"]:FW_TriggerCallback("origen_police:server:GetPoliceCount", function(result)
            retval.cops = result
            res = true
        end)
        while not res do Wait(0) end
    elseif data.page == "radio" or data.page == "central" then
        if loadingHeatAlerts then return end
        retval = false
        local count = exports.origen_inventory:Search('count', 'radio')

        if count > 0 then
            retval = exports["origen_police"]:GetMultiFrec() or "none"
            exports["origen_police"]:Toggle(true)
        end

        if not retval then
            retval = not exports["origen_police"]:GetConfig("NeedRadioForDispatch") and exports["origen_police"]:GetMultiFrec() or false
        end
        if Config.HeatMapAlerts and data.page == "central" and not heatAlerts then
            loadingHeatAlerts = true
            FW_TriggerCallback("origen_police:server:GetHeatAlerts", function(result)
                heatAlerts = result or {}
            end)
        elseif not Config.HeatMapAlerts and data.page == "central" then
            heatAlerts = {}
        end
        while not heatAlerts and data.page == "central" do Wait(0) end
        if data.page == "central" then
            retval = heatAlerts
            loadingHeatAlerts = false
            
            -- Cargar alertas almacenadas de ambulance (sin sonido, en mapa y lista)
            local canOpen = exports["origen_police"]:CanOpenTablet(PlayerData.job.name)
            if canOpen and canOpen[2] == "ambulance" then
                CreateThread(function()
                    Wait(500) -- Esperar a que el DOM esté listo
                    FW_TriggerCallback("origen_police:server:GetStoredAlerts", function(alerts)
                        if alerts and #alerts > 0 then
                            for i = 1, #alerts do
                                TriggerEvent("origen_police_menu:client:LoadStoredAlert", alerts[i])
                            end
                        end
                    end)
                end)
            end
        end
    elseif data.page == "penalcode" then
        retval.boss = PlayerData.job.isboss or PlayerData.job.name == "sapd"
    elseif data.page == "agents" then
        if GetResourceState("origen_police") == "started" then
            if GetMinimunGrade(PlayerData.job.name, "AgentManagement") <= PlayerData.job.grade.level then
                retval = true
            else
                retval = false
            end
        else
            retval = true
        end
    end

    cb(retval)
end)

RegisterNUICallback("GetInventory", function(data, cb)
    local items = {}
    if exports["origen_police"] and exports["origen_police"].GetPlayerItems then
        items = exports["origen_police"]:GetPlayerItems() or {}
    else
        local PlayerData = exports["origen_police"]:FW_GetPlayerData(false)
        items = PlayerData and PlayerData.items or {}
    end

    local retval = {}
    local filterList = (type(data) == "table" and #data > 0) and data or nil

    for _, v in pairs(items) do
        if v and type(v) == "table" then
            local vName = v.name or v.item or ""
            local matches = true
            if filterList then
                matches = InSmallArray(vName, filterList)
            end

            if matches then
                local meta = v.info or v.metadata or {}
                local url = meta.url or meta.image or nil
                local serie = meta.serie or meta.serial or nil
                if (vName == "evidence_gsr" or vName == "evidence_ne" or vName == "ticket_radar" or vName == "evidence_dna") and GenerateEvidenceDocumentSVG then
                    url = GenerateEvidenceDocumentSVG(meta, vName)
                elseif (not url or url == "") and (vName == "report_evidence") and GenerateEvidenceDocumentSVG then
                    url = GenerateEvidenceDocumentSVG(meta, vName)
                end
                table.insert(retval, {
                    slot = v.slot,
                    name = vName,
                    label = v.label or vName,
                    count = v.count or v.amount or 1,
                    info = meta,
                    metadata = meta,
                    url = url,
                    serie = serie
                })
            end
        end
    end

    cb(retval)
end)

RegisterNUICallback("OpenReportEvidenceStash", function(data, cb)
    local reportId = tostring(data.reportid or data.id or "")
    if reportId ~= "" then
        -- Con el panel F7 detras se cierra tambien: si no, se quedaba con el
        -- foco a la vez que el alijo. Ver ApartarTablet.
        ApartarTablet()
        Wait(200)
        local stashData = Config.Stashes and Config.Stashes.Evidence or { label = "Cajón de Evidencias", slots = 100, weight = 100000 }
        OpenStash("org_police_evidence_" .. reportId, (stashData.label or "Cajón de Evidencias") .. " #" .. reportId, stashData.slots or 100, stashData.weight or 100000, nil, false)
        cb(true)
    else
        cb(false)
    end
end)

RegisterNetEvent("origen_police:client:CloseRadioTab", function()
    SendNUIMessage({
        action = "CloseRadioTab"
    })
end)

RegisterNetEvent("origen_police:toggleDuty", function(wait)
    if wait then Wait(2000) end
    TriggerServerEvent("QBCore:ToggleDuty")
    TriggerServerEvent("origen_police:server_esx:SetDuty", not exports["origen_police"]:GetPoliceDuty())
end)

function GetCameraWebhook(cb)
    FW_TriggerCallback("origen_police:server:GetCameraUrl", function(url)
        if url then
            cb(url)
        else
            cb(nil)
        end
    end)
end

exports('GetWebhook', GetCameraWebhook)

local usingcamera = false
RegisterNUICallback("TakePicture", function(data, cb)
    if not usingcamera then
        -- Con la tablet dentro del panel, el panel se va con ella: si no, se
        -- quedaba con el foco y la camara no recibia ni la foto ni el Escape.
        local conPanel = ApartarTablet()
        GetCameraWebhook(function(url)
            if not url or url == '' then
                cb(false)
                usingcamera = false
                Wait(200)
                VolverALaTablet(conPanel)
                local msg = Config.UploadMethod == 'fivemanage' and "Configura FiveManage en config/logs/logs.lua para usar la cámara" or "Configura el webhook de Discord en config/logs/logs.lua para usar la camara"
                if GetResourceState("origen_notify") == "started" then
                    exports.origen_notify:Notify({
                        title = "FOTOGRAFÍA POLICIAL",
                        description = msg,
                        type = "error",
                        duration = 4500
                    })
                else
                    ShowNotification(msg, "error")
                end
                return
            end
            usingcamera = true

            -- Activar escucha de voz desde el personaje en pma-voice
            if GetResourceState('pma-voice') == 'started' then
                pcall(function() exports['pma-voice']:setListenFromPed(true) end)
            end

            CreateThread(function()
                local fov = GetGameplayCamFov()
                local ped = PlayerPedId()
                local camcoords = GetEntityCoords(ped) + vector3(0, 0, 0.6) + GetEntityForwardVector(ped) * 0.7
                local cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", camcoords, GetEntityRotation(ped, 2), fov)
                local min_fov = fov
                local radar = IsMinimapRendering()
                SetCamActive(cam, true)
                RenderScriptCams(true, true, 500, true, false)
                DisplayRadar(false)

                -- Controles en barra oficial Origen HUD (pegatina)
                pcall(function()
                    exports.origen_hud:setupControls({
                        { key = "ENTER", text = "Tomar Fotografía" },
                        { key = "WHEEL", text = "Zoom" },
                        { key = "ESCAPE", text = "Cancelar" }
                    })
                end)
                SendNUIMessage({
                    action = "setCameraControls",
                    active = true,
                    title = "Cámara Policial",
                    actionKey = "Intro",
                    actionLabel = "Tomar foto"
                })

                Wait(500)
                local teken = false
                local isUploading = false
                local uploadStartTime = 0

                while usingcamera do
                    Wait(0)

                    if not isUploading then
                        fov = HandleZoom(cam, fov, min_fov)
                        CheckInputRotation(cam, fov)
                    end

                    -- Deshabilitar acciones de juego pero permitir hablar por voz y radio
                    DisableAllControlActions(0)
                    EnableControlAction(0, 249, true) -- PTT nativo / normal (N)
                    EnableControlAction(1, 249, true)
                    EnableControlAction(2, 249, true)
                    EnableControlAction(0, 137, true) -- Caps Lock (Radio habitual)
                    EnableControlAction(1, 137, true)
                    EnableControlAction(2, 137, true)
                    EnableControlAction(0, 19, true)  -- Left Alt (Radio alternativa)
                    EnableControlAction(1, 19, true)
                    EnableControlAction(2, 19, true)
                    EnableControlAction(0, 245, true) -- Chat de texto (tecla T)

                    if IsDisabledControlJustPressed(0, 176) and not teken then
                        teken = true
                        isUploading = true
                        uploadStartTime = GetGameTimer()

                        -- Ocultar los controles de inmediato para no ensuciar la toma
                        pcall(function() exports.origen_hud:hideControls() end)
                        SendNUIMessage({ action = "setCameraControls", active = false })

                        -- Actualizar la mini pantalla de carga en la NUI (diseño oficial Origen)
                        CreateThread(function()
                            -- Breve margen de 120ms para que screencapture capture el fotograma limpio
                            Wait(120)

                            while isUploading do
                                local elapsed = (GetGameTimer() - uploadStartTime) / 1000.0
                                SendNUIMessage({
                                    action = "cameraUploadProgress",
                                    visible = true,
                                    status = "subiendo",
                                    elapsed = elapsed,
                                    title = "TOMANDO FOTOGRAFÍA",
                                    message = "Subiendo captura a FiveManage..."
                                })
                                Wait(50)
                            end
                        end)

                        CreateThread(function()
                            local photoUrl = exports["origen_police"]:TakePhoto(url)
                            local totalElapsed = (GetGameTimer() - uploadStartTime) / 1000.0
                            if photoUrl then
                                SendNUIMessage({
                                    action = "cameraUploadProgress",
                                    visible = true,
                                    status = "completado",
                                    elapsed = totalElapsed,
                                    title = "FOTOGRAFÍA GUARDADA",
                                    message = "Guardada en la ficha ciudadana"
                                })
                                local targetEvent = (data.type == "police" or data.isPolice) and "origen_police:police:UpdatePoliceImage" or "origen_police:police:UpdateCitizenImage"
                                exports["origen_police"]:FW_TriggerCallback(targetEvent, function(result)
                                    Wait(600)
                                    isUploading = false
                                    SendNUIMessage({
                                        action = "cameraUploadProgress",
                                        visible = false
                                    })
                                    usingcamera = false
                                    cb(result and photoUrl or false)
                                    VolverALaTablet(conPanel)
                                    if GetResourceState("origen_notify") == "started" then
                                        exports.origen_notify:Notify({
                                            title = "FOTOGRAFÍA POLICIAL",
                                            description = "Fotografía guardada correctamente en la ficha",
                                            type = "success",
                                            duration = 4000
                                        })
                                    end
                                end, {citizenid = data.citizenid, value = photoUrl, column = "image"})
                            else
                                SendNUIMessage({
                                    action = "cameraUploadProgress",
                                    visible = true,
                                    status = "error",
                                    elapsed = totalElapsed,
                                    title = "ERROR AL SUBIR",
                                    message = "No se pudo subir la foto a FiveManage"
                                })
                                Wait(1000)
                                isUploading = false
                                SendNUIMessage({
                                    action = "cameraUploadProgress",
                                    visible = false
                                })
                                usingcamera = false
                                cb(false)
                                VolverALaTablet(conPanel)
                                if GetResourceState("origen_notify") == "started" then
                                    exports.origen_notify:Notify({
                                        title = "FOTOGRAFÍA POLICIAL",
                                        description = "Error al procesar la fotografía",
                                        type = "error",
                                        duration = 4500
                                    })
                                else
                                    ShowNotification("Error al procesar la fotografía.", "error")
                                end
                            end
                        end)
                    end
                    if IsDisabledControlJustPressed(0, 177) and not teken then
                        pcall(function() exports.origen_hud:hideControls() end)
                        SendNUIMessage({ action = "setCameraControls", active = false })
                        SendNUIMessage({ action = "cameraUploadProgress", visible = false })
                        cb(false)
                        usingcamera = false
                        VolverALaTablet(conPanel)
                    end
                end

                -- Limpieza al cerrar la cámara
                pcall(function() exports.origen_hud:hideControls() end)
                SendNUIMessage({ action = "setCameraControls", active = false })
                SendNUIMessage({ action = "cameraUploadProgress", visible = false })

                -- Restaurar escucha de pma-voice
                if GetResourceState('pma-voice') == 'started' then
                    pcall(function() exports['pma-voice']:setListenFromPed(false) end)
                end

                DisplayRadar(radar)
                ClearPedTasks(ped)
                SetCamActive(cam, false)
                DestroyCam(cam, true)
                RenderScriptCams(false, true, 500, true, false)
            end)
        end)
    end
end)

function CheckInputRotation(cam, zoomvalue)
	local rightAxisX = GetDisabledControlNormal(0, 220)
	local rightAxisY = GetDisabledControlNormal(0, 221)
	local rotation = GetCamRot(cam, 2)
	if rightAxisX ~= 0.0 or rightAxisY ~= 0.0 then
        local new_z = rotation.z + rightAxisX*-1.0*(0.1)*(zoomvalue+0.1)
		local new_x = math.max(math.min(65.0, rotation.x + rightAxisY*-1.0*(0.1)*(zoomvalue+0.1)), -65.0)
		SetCamRot(cam, new_x, 0.0, new_z, 2)
	end
end

function HandleZoom(cam, _fov, min_fov)
	if IsDisabledControlJustPressed(0,241) then -- Scrollup
		_fov = math.max(_fov - 3.0, 5.0)
	end
	if IsDisabledControlJustPressed(0,242) then
		_fov = math.min(_fov + 3.0, min_fov) -- ScrollDown
	end
	local current_fov = GetCamFov(cam)
	if math.abs(_fov-current_fov) < 0.1 then -- the difference is too small, just set the value directly to avoid unneeded updates to FOV of order 10^-5
		_fov = current_fov
	end
	SetCamFov(cam, current_fov + (_fov - current_fov)*0.05) -- Smoothing of camera zoom
    return _fov
end

function InSmallArray(key, array)
    for i = 0, #array do if array[i] == key then return true end end
    return false
end

RegisterNUICallback("ShowBodycam", function(data, cb)
    TriggerServerEvent("origen_police:server:ShowBodycam", tonumber(data.id))
    cb(true)
end)

RegisterNUICallback("ShowCarcam", function(data, cb)
    TriggerServerEvent("origen_police:server:ShowCarcam", tonumber(data.netid))
    cb(true)
end)

RegisterNUICallback("GetPoliceGrades", function(data, cb)
    local Jobs = Framework.Shared.Jobs
    if not Jobs then
        Debuger("The Framework.Shared.Jobs appear to be nil, please check your framework configuration.")
        return cb({})
    end
    if not Jobs[data.job] then
        Debuger("The job '" .. data.job .. "' does not exist in Framework.Shared.Jobs.")
        return cb({})
    end
    if not Jobs[data.job].grades then
        Debuger("The job '" .. data.job .. "' does not have grades defined in Framework.Shared.Jobs.")
        return cb({})
    end
    cb(Jobs[data.job].grades)
end)

-- New callback to get ALL grades from ALL jobs in the same category (police, sheriff, sapd)
RegisterNUICallback("GetAllCategoryGrades", function(data, cb)
    local Jobs = Framework.Shared.Jobs
    local PlayerData = exports["origen_police"]:FW_GetPlayerData(false)
    if not Jobs then
        Debuger("The Framework.Shared.Jobs appear to be nil, please check your framework configuration.")
        return cb({})
    end
    
    -- Get the category of the requesting player
    local canOpen = exports["origen_police"]:CanOpenTablet(PlayerData.job.name)
    if not canOpen or not canOpen[2] then
        Debuger("Player job category not found")
        return cb({})
    end
    local category = canOpen[2]
    
    -- Get all jobs in this category
    local categoryJobs = exports["origen_police"]:GetConfig("JobCategory")[category]
    if not categoryJobs then
        Debuger("No jobs found in category: " .. category)
        return cb({})
    end
    
    -- Build result with all jobs and their grades
    local result = {}
    for _, jobConfig in pairs(categoryJobs) do
        local jobName = jobConfig.name
        if Jobs[jobName] and Jobs[jobName].grades then
            result[jobName] = {
                label = Jobs[jobName].label or jobName,
                grades = Jobs[jobName].grades
            }
        end
    end
    
    cb(result)
end)

RegisterNetEvent("origen_police:client:HideCamHud", function()
    SendNUIMessage({
        action = "HideCamHud"
    })
    TogglePause(true)
end)

RegisterNetEvent("origen_police:client:rpol", function(message)
    SendNUIMessage({
        action = "RpolMessage",
        message = message
    })
end)

RegisterNUICallback("SendRpolMessage", function(data, cb)
    local PlayerData = FW_GetPlayerData(true)
    if PlayerData and PlayerData.job then
        local myGrade = PlayerData.job.grade
        local myLevel = (type(myGrade) == "table" and (myGrade.level or myGrade.grade)) or myGrade or 0
        myLevel = tonumber(myLevel) or 0
        local isBoss = PlayerData.job.isboss or (type(PlayerData.job.grade) == "table" and PlayerData.job.grade.isboss) or false
        local isStateAdmin = (PlayerData.job.name == "sapd")
        local reqGrade = GetMinimunGrade(PlayerData.job.name, "RPOL")
        local canUse = isStateAdmin or isBoss or (reqGrade ~= nil and reqGrade ~= 888 and myLevel >= tonumber(reqGrade)) or (reqGrade == 888)
        if not canUse then
            FW_Notify("No tienes permisos para usar la radio RPOL.", "error")
            cb(false)
            return
        end
    end
    UseCommand('rpol', data.message)
    cb(true)
end)

local lastAlertSoundCode = nil
local lastAlertSoundTime = 0

function PlayDispatchAlertSound(alert)
    if not alert then return end

    local code = alert.code or alert.id
    local now = GetGameTimer()

    -- Evitar reproducir el sonido si este mismo aviso ya sonó hace menos de 2.5s (despacho doble central/mini-dispatch)
    if code and lastAlertSoundCode == code and (now - lastAlertSoundTime) < 2500 then
        return
    end

    -- Cooldown mínimo entre avisos diferentes para evitar solapamientos y ecos
    if (now - lastAlertSoundTime) < 350 then
        return
    end

    lastAlertSoundCode = code
    lastAlertSoundTime = now

    if Config.QRRSound and Config.QRRSound.enabled and alert.title and (alert.title == "QRR" or alert.title:find("^QRR$") or alert.title:find("^QRR%s")) then
        SendNUIMessage({
            action = "PlayCustomSound",
            url = Config.QRRSound.url,
            volume = Config.QRRSound.volume
        })
    elseif Config.Ten13BSound and Config.Ten13BSound.enabled and alert.title and alert.title:find("QRR%-B") then
        SendNUIMessage({
            action = "PlayCustomSound",
            url = Config.Ten13BSound.url,
            volume = Config.Ten13BSound.volume
        })
    elseif Config.Ten13CSound and Config.Ten13CSound.enabled and alert.title and alert.title:find("QRR%-C") then
        SendNUIMessage({
            action = "PlayCustomSound",
            url = Config.Ten13CSound.url,
            volume = Config.Ten13CSound.volume
        })
    elseif Config.CancelSound and Config.CancelSound.enabled and alert.title and alert.title:find("Cancelado") then
        SendNUIMessage({
            action = "PlayCustomSound",
            url = Config.CancelSound.url,
            volume = Config.CancelSound.volume
        })
    elseif alert.command == "auxilio" or (alert.title and (alert.title:find("Auxilio") or alert.title:find("auxilio"))) then
        local soundUrl = (Config.AuxilioSound and Config.AuxilioSound.enabled and Config.AuxilioSound.url)
            or (Config.DefaultAlertSound and Config.DefaultAlertSound.url)
            or "https://r2.fivemanage.com/hKHnIwIXgeaTI05Xdks2b/sonidoalertas.mp3"
        SendNUIMessage({
            action = "PlayCustomSound",
            url = soundUrl,
            volume = (Config.AuxilioSound and Config.AuxilioSound.volume) or 0.5
        })
    elseif alert.command == "entorno" or (alert.title and (alert.title:find("911") or alert.title:find("Entorno") or alert.title:find("entorno"))) then
        local soundUrl = (Config.EntornoSound and Config.EntornoSound.enabled and Config.EntornoSound.url)
            or (Config.DefaultAlertSound and Config.DefaultAlertSound.url)
            or "https://r2.fivemanage.com/hKHnIwIXgeaTI05Xdks2b/sonidoalertas.mp3"
        SendNUIMessage({
            action = "PlayCustomSound",
            url = soundUrl,
            volume = (Config.EntornoSound and Config.EntornoSound.volume) or 0.5
        })
    elseif alert.sound and alert.sound ~= "" then
        local soundUrl = alert.sound
        if not soundUrl:find("^http") and not soundUrl:find("^sounds/") and not soundUrl:find("^nui://") then
            soundUrl = "sounds/" .. soundUrl
        end
        SendNUIMessage({
            action = "PlayCustomSound",
            url = soundUrl,
            volume = 0.5
        })
    elseif Config.EMSSound and Config.EMSSound.enabled and alert.title == "Emergencia" then
        SendNUIMessage({
            action = "PlayCustomSound",
            url = Config.EMSSound.url,
            volume = Config.EMSSound.volume
        })
    else
        local defaultUrl = (Config.DefaultAlertSound and Config.DefaultAlertSound.enabled and Config.DefaultAlertSound.url)
            or "https://r2.fivemanage.com/hKHnIwIXgeaTI05Xdks2b/sonidoalertas.mp3"
        SendNUIMessage({
            action = "PlayCustomSound",
            url = defaultUrl,
            volume = (Config.DefaultAlertSound and Config.DefaultAlertSound.volume) or 0.5
        })
    end
end

RegisterNetEvent("origen_police_menu:client:ReceiveAlert", function(alert)
    if AvisosDetenidos and AvisosDetenidos() then return end
    local PlayerData = FW_GetPlayerData()
    local myJobName = PlayerData and PlayerData.job and PlayerData.job.name
    if myJobName and myJobName ~= "" then
        local myGrade = PlayerData.job.grade
        local myLevel = (type(myGrade) == "table" and (myGrade.level or myGrade.grade)) or myGrade or 0
        myLevel = tonumber(myLevel) or 0
        local isBoss = PlayerData.job.isboss or (type(PlayerData.job.grade) == "table" and PlayerData.job.grade.isboss) or false
        local isStateAdmin = (myJobName == "sapd")
        local reqGrade = GetMinimunGrade(myJobName, "ReceiveAlerts")
        local canReceive = isStateAdmin or isBoss or (reqGrade ~= nil and reqGrade ~= 888 and myLevel >= tonumber(reqGrade)) or (reqGrade == 888)
        if not canReceive then return end
    end

    if type(alert.coords) == "table" then
        alert.coords = vector3(alert.coords.x, alert.coords.y, alert.coords.z)
    end
    alert.distance = #(GetEntityCoords(PlayerPedId()) - alert.coords)

    if alert.distance < 1000 then
        alert.distance = FW_Round(alert.distance, 2) .. ' m'
    else
        alert.distance = FW_Round(alert.distance/1000, 2) .. ' Km'
    end
    alert.street = GetStreetNameFromHashKey(GetStreetNameAtCoord(alert.coords.x, alert.coords.y, alert.coords.z))
    alert.time = 0

    PlayDispatchAlertSound(alert)

    SendNUIMessage({
        action = "ReceiveAlert",
        alert = alert
    })
end)

RegisterNetEvent('origen_police_menu:client:ReceiveAlertLowCall', function(alert)
    if AvisosDetenidos and AvisosDetenidos() then return end
    local PlayerData = FW_GetPlayerData()
    local myJobName = PlayerData and PlayerData.job and PlayerData.job.name
    if myJobName and myJobName ~= "" then
        local myGrade = PlayerData.job.grade
        local myLevel = (type(myGrade) == "table" and (myGrade.level or myGrade.grade)) or myGrade or 0
        myLevel = tonumber(myLevel) or 0
        local isBoss = PlayerData.job.isboss or (type(PlayerData.job.grade) == "table" and PlayerData.job.grade.isboss) or false
        local isStateAdmin = (myJobName == "sapd")
        local reqGrade = GetMinimunGrade(myJobName, "ReceiveAlerts")
        local canReceive = isStateAdmin or isBoss or (reqGrade ~= nil and reqGrade ~= 888 and myLevel >= tonumber(reqGrade)) or (reqGrade == 888)
        if not canReceive then return end
    end
    if type(alert.coords) == "table" then
        alert.coords = vector3(alert.coords.x, alert.coords.y, alert.coords.z)
    end
    alert.distance = #(GetEntityCoords(PlayerPedId()) - alert.coords)

    if alert.distance < 1000 then
        alert.distance = FW_Round(alert.distance, 2) .. ' m'
    else
        alert.distance = FW_Round(alert.distance/1000, 2) .. ' Km'
    end
    alert.street = GetStreetNameFromHashKey(GetStreetNameAtCoord(alert.coords.x, alert.coords.y, alert.coords.z))
    alert.time = 0
    SendNUIMessage({
        action = "recieveLowCall",
        alert = alert
    })
end)

-- Nuevo evento para cargar alertas almacenadas sin sonido (solo en el mapa)
RegisterNetEvent("origen_police_menu:client:LoadStoredAlert", function(alert)
    if type(alert.coords) == "table" then
        alert.coords = vector3(alert.coords.x, alert.coords.y, alert.coords.z)
    end
    alert.distance = #(GetEntityCoords(PlayerPedId()) - alert.coords)

    if alert.distance < 1000 then
        alert.distance = FW_Round(alert.distance, 2) .. ' m'
    else
        alert.distance = FW_Round(alert.distance/1000, 2) .. ' Km'
    end
    alert.street = GetStreetNameFromHashKey(GetStreetNameAtCoord(alert.coords.x, alert.coords.y, alert.coords.z))
    alert.time = 0

    -- Enviar alerta al NUI sin reproducir sonido y marcada como "stored" para que solo aparezca en el mapa
    SendNUIMessage({
        action = "LoadStoredAlert",
        alert = alert
    })
end)

RegisterNetEvent("origen_police_menu:client:EditAlert", function(data)
    SendNUIMessage({
        action = "EditAlert",
        data = data
    })
end)

RegisterNetEvent("origen_police_menu:client:removeAlert", function(alertData)
    local code = nil
    if type(alertData) == "table" then
        code = alertData.code or alertData.id
    else
        code = alertData
    end
    if not code then return end

    SendNUIMessage({
        action = "removeAlert",
        id = code,
        code = code
    })
end)

RegisterNetEvent("origen_police:client:AddCentralMark", function(id, data)
    SendNUIMessage({
        action = "AddCentralMark",
        id = id,
        data = data
    })
end)

RegisterNetEvent("origen_police:client:UpdateCentralMark", function(id, data)
    SendNUIMessage({
        action = "UpdateCentralMark",
        id = id,
        data = data
    })
end)

RegisterNetEvent("origen_police:client:RemoveCentralMark", function(id)
    SendNUIMessage({
        action = "RemoveCentralMark",
        id = id
    })
end)

RegisterNetEvent("origen_police:client:UpdateCentralPositions", function(VehicleTrackeds, Cops)
    SendNUIMessage({
        action = "UpdateCentralPositions",
        VehicleTrackeds = VehicleTrackeds,
        Cops = Cops
    })
end)