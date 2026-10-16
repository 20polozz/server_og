-- ============================================================
-- ORIGEN POLICE — ADMIN PANEL CLIENT
-- ============================================================

Config.ExtraVehiclesHashes = Config.ExtraVehiclesHashes or {}

local adminOpen = false

-- ─── Abrir panel ─────────────────────────────────────────────
local function OpenAdminPanel()
    if adminOpen then return end
    
    FW_TriggerCallback("origen_police:admin:getGrades", function(gradeData)
        if not gradeData then
            ShowNotification(Config.Translations["NoPermission"] or "Sin permisos para el panel admin.")
            return
        end

        FW_TriggerCallback("origen_police:admin:getPermissions", function(permsData)
            FW_TriggerCallback("origen_police:admin:getQuickmenuReferences", function(quickData)
                FW_TriggerCallback("origen_police:admin:getExtraVehicles", function(extraVehicles)
                    FW_TriggerCallback("origen_police:admin:getReportTags", function(tagsData)
                        FW_TriggerCallback("origen_police:admin:getRadioCodes", function(radioCodesData)
                            FW_TriggerCallback("origen_police:admin:getArmouries", function(armouriesData)
                                FW_TriggerCallback("origen_police:callback:GetStationsList", function(stationsData)
                                    FW_TriggerCallback("origen_police:admin:getOutfits", function(outfitsData)
                                        FW_TriggerCallback("origen_police:admin:getQuickmenuTabsVisibility", function(tabsVisibilityData)
                                            FW_TriggerCallback("origen_police:admin:getCalloutsState", function(calloutsData)
                                                FW_TriggerCallback("origen_police:admin:getDealershipVehicles", function(dealershipVehs)
                                                    FW_TriggerCallback("origen_police:admin:getDealershipPoints", function(dealershipPts)
                                                        local playerJob = FW_GetPlayerData().job.name or "police"
                                                        FW_TriggerCallback("origen_police:admin:getSocietyBalance", function(socBalance)
                                                            adminOpen = true
                                                            TriggerServerEvent('origen_police:server:subscribeReferences')
                                                            SetNuiFocus(true, true)
                                                            SendNUIMessage({
                                                                action = "openAdminPanel",
                                                                data   = {
                                                                    jobs               = gradeData.jobs  or {},
                                                                    radio              = gradeData.radio or {},
                                                                    radioServices      = gradeData.radioServices or {},
                                                                    radioBinds         = gradeData.radioBinds or {},
                                                                    permissions        = permsData       or {},
                                                                    quickmenu          = quickData       or {},
                                                                    extraVehicles      = extraVehicles   or {},
                                                                    reportTags         = tagsData        or {},
                                                                    radioCodes         = radioCodesData  or {},
                                                                    armouries          = armouriesData   or {},
                                                                    stations           = stationsData    or {},
                                                                    outfits            = outfitsData     or {},
                                                                    quickmenuTabs      = tabsVisibilityData or {},
                                                                    callouts           = calloutsData    or {},
                                                                    dealershipVehicles = dealershipVehs  or {},
                                                                    dealershipPoints   = dealershipPts   or {},
                                                                    societyBalance     = socBalance      or 0
                                                                }
                                                            })
                                                        end, playerJob)
                                                    end)
                                                end)
                                            end)
                                        end)
                                    end)
                                end)
                            end)
                        end)
                    end)
                end)
            end)
        end)
    end)
end

exports("openManagement", OpenAdminPanel)

RegisterNetEvent("origen_police:client:openAdminPanel", function()
    OpenAdminPanel()
end)

CreateThread(function()
    Wait(1000)
    local cmdCfg = (Config and Config.Commands and Config.Commands.OpenPoliceAdmin) or {}
    local mainCmd = cmdCfg.cmd or 'policeadmin'
    TriggerEvent('chat:addSuggestion', '/' .. mainCmd, cmdCfg.description or 'Abrir panel de administración policial')
    if cmdCfg.aliases and type(cmdCfg.aliases) == 'table' then
        for _, alias in ipairs(cmdCfg.aliases) do
            TriggerEvent('chat:addSuggestion', '/' .. alias, cmdCfg.description or 'Abrir panel de administración policial')
        end
    end
end)

-- ─── Cerrar panel ─────────────────────────────────────────────
RegisterNUICallback("op_admin_close", function(_, cb)
    if not adminOpen then return cb("ok") end
    adminOpen = false
    if not onduty then
        TriggerServerEvent('origen_police:server:unsubscribeReferences')
    end
    SetNuiFocus(false, false)
    cb("ok")

    -- ESC: si el panel se abrió desde la pestaña Scripts del admin, se vuelve
    -- a ella. origen_admin solo vuelve si este panel salió de su lista; por
    -- cualquier otro camino, ESC cierra y nada más. (origen_hub ya no existe.)
    if GetResourceState("origen_admin") == "started" then
        SetTimeout(80, function()
            pcall(function() exports["origen_admin"]:ReturnToScripts() end)
        end)
    end
end)

RegisterNUICallback("op_admin_close_temp", function(_, cb)
    adminOpen = false
    SetNuiFocus(false, false)
    cb("ok")
end)

--[[ Raton soltado a la fuerza con el panel de administracion abierto: se
     esconde (el mismo mensaje que usa la colocacion de camillas) y se apaga
     la bandera, o no volveria a abrirse. Sin panel abierto, no hace nada. ]]
if OrigenFoco and OrigenFoco.AlSoltar then
    OrigenFoco.AlSoltar(function()
        if not adminOpen then return end
        adminOpen = false
        SendNUIMessage({ action = "tempHideAdmin" })
        if not onduty then
            TriggerServerEvent('origen_police:server:unsubscribeReferences')
        end
    end)
end

-- ─── Rangos ───────────────────────────────────────────────────
RegisterNUICallback("op_admin_addGrade", function(data, cb)
    TriggerServerEvent("origen_police:admin:addGrade", data)
    cb("ok")
end)

RegisterNUICallback("op_admin_updateGrade", function(data, cb)
    TriggerServerEvent("origen_police:admin:updateGrade", data)
    cb("ok")
end)

RegisterNUICallback("op_admin_removeGrade", function(data, cb)
    TriggerServerEvent("origen_police:admin:removeGrade", data)
    cb("ok")
end)

-- ─── Categorías de departamento ───────────────────────────────
RegisterNUICallback("op_admin_addCategory", function(data, cb)
    TriggerServerEvent("origen_police:admin:addCategory", data)
    cb("ok")
end)

RegisterNUICallback("op_admin_removeCategory", function(data, cb)
    TriggerServerEvent("origen_police:admin:removeCategory", data)
    cb("ok")
end)

-- ─── Radio: categorías ────────────────────────────────────────
RegisterNUICallback("op_admin_addRadioCategory", function(data, cb)
    TriggerServerEvent("origen_police:admin:addRadioCategory", data)
    cb("ok")
end)

RegisterNUICallback("op_admin_removeRadioCategory", function(data, cb)
    TriggerServerEvent("origen_police:admin:removeRadioCategory", data)
    cb("ok")
end)

-- ─── Radio: canales ───────────────────────────────────────────
RegisterNUICallback("op_admin_addRadioChannel", function(data, cb)
    TriggerServerEvent("origen_police:admin:addRadioChannel", data)
    cb("ok")
end)

RegisterNUICallback("op_admin_removeRadioChannel", function(data, cb)
    TriggerServerEvent("origen_police:admin:removeRadioChannel", data)
    cb("ok")
end)

-- ─── Radio: reordenar ─────────────────────────────────────────
RegisterNUICallback("op_admin_updateRadioCategory", function(data, cb)
    TriggerServerEvent("origen_police:admin:updateRadioCategory", data)
    cb("ok")
end)

RegisterNUICallback("op_admin_updateRadioChannel", function(data, cb)
    TriggerServerEvent("origen_police:admin:updateRadioChannel", data)
    cb("ok")
end)

RegisterNUICallback("op_admin_moveRadioChannel", function(data, cb)
    TriggerServerEvent("origen_police:admin:moveRadioChannel", data)
    cb("ok")
end)

RegisterNUICallback("op_admin_reorderRadioCats", function(data, cb)
    TriggerServerEvent("origen_police:admin:reorderRadioCategories", data)
    cb("ok")
end)

RegisterNUICallback("op_admin_reorderRadioChannels", function(data, cb)
    TriggerServerEvent("origen_police:admin:reorderRadioChannels", data)
    cb("ok")
end)

-- ─── Radio: bindeos ───────────────────────────────────────────
RegisterNUICallback("op_admin_addRadioBind", function(data, cb)
    TriggerServerEvent("origen_police:admin:addRadioBind", data)
    cb("ok")
end)

RegisterNUICallback("op_admin_updateRadioBind", function(data, cb)
    TriggerServerEvent("origen_police:admin:updateRadioBind", data)
    cb("ok")
end)

RegisterNUICallback("op_admin_removeRadioBind", function(data, cb)
    TriggerServerEvent("origen_police:admin:removeRadioBind", data)
    cb("ok")
end)

RegisterNUICallback("op_admin_reorderRadioBinds", function(data, cb)
    TriggerServerEvent("origen_police:admin:reorderRadioBinds", data)
    cb("ok")
end)

-- ─── Radio: codes ───────────────────────────────────────────
RegisterNUICallback("op_admin_addRadioCode", function(data, cb)
    TriggerServerEvent("origen_police:admin:addRadioCode", data)
    cb("ok")
end)

RegisterNUICallback("op_admin_updateRadioCode", function(data, cb)
    TriggerServerEvent("origen_police:admin:updateRadioCode", data)
    cb("ok")
end)

RegisterNUICallback("op_admin_removeRadioCode", function(data, cb)
    TriggerServerEvent("origen_police:admin:removeRadioCode", data)
    cb("ok")
end)

RegisterNUICallback("op_admin_toggleRadioCodeVisibility", function(data, cb)
    TriggerServerEvent("origen_police:admin:toggleRadioCodeVisibility", data)
    cb("ok")
end)

RegisterNUICallback("op_admin_reorderRadioCodes", function(data, cb)
    TriggerServerEvent("origen_police:admin:reorderRadioCodes", data)
    cb("ok")
end)

RegisterNUICallback("op_admin_copyRadioCodes", function(data, cb)
    TriggerServerEvent("origen_police:admin:copyRadioCodes", data)
    cb("ok")
end)

RegisterNetEvent("origen_police:client:SyncRadioCodes", function(codes)
    if not adminOpen then return end
    SendNUIMessage({
        action = "adminRadioCodesUpdated",
        codes = codes or {}
    })
end)

-- ─── Permisos ─────────────────────────────────────────────────
RegisterNUICallback("op_admin_updatePermission", function(data, cb)
    TriggerServerEvent("origen_police:admin:updatePermission", data)
    cb("ok")
end)

RegisterNUICallback("op_admin_updatePermissionsBatch", function(data, cb)
    TriggerServerEvent("origen_police:admin:updatePermissionsBatch", data)
    cb("ok")
end)

-- ─── Sync: rangos ─────────────────────────────────────────────
RegisterNetEvent("origen_police:admin:gradesUpdated")
AddEventHandler("origen_police:admin:gradesUpdated", function(jobName, grades)
    if not adminOpen then return end
    SendNUIMessage({ action = "adminGradesUpdated", job = jobName, grades = grades })
end)

RegisterNetEvent("origen_police:admin:jobAdded")
AddEventHandler("origen_police:admin:jobAdded", function(job, category)
    -- Registrar en el Config local del cliente para acceso inmediato
    category = category or "police"
    Config.JobCategory[category] = Config.JobCategory[category] or {}
    
    local found = false
    for _, j in ipairs(Config.JobCategory[category]) do
        if j.name == job.name then found = true; break end
    end
    
    if not found then
        table.insert(Config.JobCategory[category], {
            name = job.name,
            titleListLabel = job.label,
            color = job.color or "#3b82f6",
            badge = "lspd_badge",
            penalFilter = "police",
            society = "police",
        })
        -- Refrescar la caché de shared.lua
        exports["origen_police"]:ParseConfigJobs()
    end

    if adminOpen then
        SendNUIMessage({ action = "adminJobAdded", job = job })
    end
end)

RegisterNetEvent("origen_police:admin:jobRemoved")
AddEventHandler("origen_police:admin:jobRemoved", function(jobName)
    for cat, jobs in pairs(Config.JobCategory or {}) do
        for i = #jobs, 1, -1 do
            if jobs[i].name == jobName then
                table.remove(jobs, i)
            end
        end
    end
    exports["origen_police"]:ParseConfigJobs()
    if adminOpen then
        SendNUIMessage({ action = "adminJobRemoved", jobName = jobName })
    end
end)

RegisterNetEvent("origen_police:admin:syncAllJobs")
AddEventHandler("origen_police:admin:syncAllJobs", function(allJobs, deletedList)
    for _, delJob in ipairs(deletedList or {}) do
        for cat, jobs in pairs(Config.JobCategory or {}) do
            for i = #jobs, 1, -1 do
                if jobs[i].name == delJob then
                    table.remove(jobs, i)
                end
            end
        end
    end
    for _, job in ipairs(allJobs or {}) do
        local category = job.parent or "police"
        Config.JobCategory[category] = Config.JobCategory[category] or {}
        
        local found = false
        for _, j in ipairs(Config.JobCategory[category]) do
            if j.name == job.name then found = true; break end
        end
        
        if not found then
            table.insert(Config.JobCategory[category], {
                name = job.name,
                titleListLabel = job.label,
                color = job.color or "#3b82f6",
                badge = "lspd_badge",
                penalFilter = "police",
                society = "police",
                isCustom = true
            })
        end
    end
    -- Refrescar caché access
    exports["origen_police"]:ParseConfigJobs()
end)

RegisterNetEvent("origen_police:admin:permissionsUpdated")
AddEventHandler("origen_police:admin:permissionsUpdated", function(perms)
    Config.Permissions = perms or {}
    if adminOpen then
        SendNUIMessage({ action = "adminPermissionsUpdated", perms = Config.Permissions })
    end
end)

-- ─── Sync: radio (recibido por TODOS los clientes) ────────────
-- Actualiza Config.MultifrecOrdered y Config.Multifrec localmente.
-- Si el panel admin está abierto, también actualiza la UI.
RegisterNetEvent("origen_police:admin:radioUpdated")
AddEventHandler("origen_police:admin:radioUpdated", function(radioData, channelServices)
    -- Actualizar el config local para que el radio use los nuevos canales
    Config.MultifrecOrdered = radioData or {}
    Config.RadioChannelServices = channelServices or {}
    Config.Multifrec = {}
    for _, v in ipairs(Config.MultifrecOrdered) do
        Config.Multifrec[v.category] = v.freqs
    end

    -- Si el panel admin está abierto, refrescar la pestaña Radio
    if adminOpen then
        SendNUIMessage({ action = "adminRadioUpdated", radio = Config.MultifrecOrdered, channelServices = Config.RadioChannelServices })
    end

    -- Refrescar el quickmenu y el PCAD de radio (solo si el admin NO está abierto,
    -- porque el admin ya actualizó su UI arriba y no debe llamar Toggle/LoadRadio)
    SendNUIMessage({ radioMenu = "RefreshFrequencies", adminOpen = adminOpen })
end)

RegisterNetEvent("origen_police:admin:radioBindsUpdated")
AddEventHandler("origen_police:admin:radioBindsUpdated", function(binds)
    Config.BindFreqsOrdered = binds or {}
    Config.BindFreqs = {}
    for _, bind in ipairs(Config.BindFreqsOrdered) do
        local expanded = {}
        for _, freq in ipairs(bind.freqs) do
            if Config.Multifrec and Config.Multifrec[freq] then
                for _, freq2 in ipairs(Config.Multifrec[freq]) do
                    table.insert(expanded, freq2:lower())
                end
            else
                table.insert(expanded, freq)
            end
        end
        Config.BindFreqs[bind.label] = expanded
    end

    if adminOpen then
        SendNUIMessage({ action = "adminRadioBindsUpdated", binds = Config.BindFreqsOrdered })
    end
end)

RegisterNetEvent("origen_police:client:updateQuickmenuReferences")
AddEventHandler("origen_police:client:updateQuickmenuReferences", function(payload)
    -- payload = { category = "police"|"ambulance", data = { sprites, labels, colors } }
    local cat = payload and payload.category
    local data = payload and payload.data

    if adminOpen then
        SendNUIMessage({ action = "adminQuickmenuUpdated", category = cat, data = data })
    end
    -- Send to the tablet NUI — it will filter by the player's category
    local myCategory = GetPlayerJobCategory()
    if not cat or cat == myCategory then
        SendNUIMessage({ action = "updateQuickmenuReferences", data = data })
    end
end)

RegisterNUICallback("op_admin_saveQuickmenuReferences", function(data, cb)
    TriggerServerEvent("origen_police:admin:saveQuickmenuReferences", data)
    cb("ok")
end)

-- ─── Vehículos Autorizados ────────────────────────────────────
RegisterNUICallback("op_admin_addExtraVehicle", function(data, cb)
    TriggerServerEvent("origen_police:admin:addExtraVehicle", data)
    cb("ok")
end)

RegisterNUICallback("op_admin_removeExtraVehicle", function(data, cb)
    TriggerServerEvent("origen_police:admin:removeExtraVehicle", data.model)
    cb("ok")
end)

RegisterNUICallback("op_admin_startOffsetEditor", function(data, cb)
    cb("ok")
    SetNuiFocus(false, false)
    --[[ Si origen_boattow no esta arrancado (o su export falla), el panel se
         quedaba a la vista con el raton ya soltado: se le devuelve. ]]
    local ok = pcall(function()
        exports['origen_boattow']:StartOffsetEditor(data.model, function(offsetStr)
            if not adminOpen then return end
            SetNuiFocus(true, true)
            SendNUIMessage({ action = "op_admin_offsetEditorFinished", offset = offsetStr })
        end)
    end)
    if not ok and adminOpen then
        SetNuiFocus(true, true)
        ShowNotification("No se pudo abrir el editor de posicion (origen_boattow).", "error")
    end
end)

-- ─── Tags de Informes ─────────────────────────────────────────
RegisterNUICallback("op_admin_addReportTag", function(data, cb)
    TriggerServerEvent("origen_police:admin:addReportTag", data)
    cb("ok")
end)

RegisterNUICallback("op_admin_removeReportTag", function(data, cb)
    TriggerServerEvent("origen_police:admin:removeReportTag", data)
    cb("ok")
end)

RegisterNetEvent("origen_police:client:updateExtraVehicles", function(extraVehicles)
    Config.ExtraVehicles = extraVehicles or {}
    -- Convertir a hashes para búsqueda rápida
    Config.ExtraVehiclesHashes = {}
    for model, data in pairs(Config.ExtraVehicles) do
        Config.ExtraVehiclesHashes[GetHashKey(model)] = data
    end

    if adminOpen then
        SendNUIMessage({ action = "adminExtraVehiclesUpdated", data = Config.ExtraVehicles })
    end
end)

RegisterNetEvent("origen_police:admin:reportTagsUpdated", function(tags)
    if adminOpen then
        SendNUIMessage({ action = "adminReportTagsUpdated", tags = tags })
    end
end)

-- ─── Armerías NUI y Sync ──────────────────────────────────────
RegisterNUICallback("op_admin_saveArmory", function(data, cb)
    TriggerServerEvent("origen_police:admin:saveArmory", data)
    cb("ok")
end)

RegisterNUICallback("op_admin_deleteArmory", function(data, cb)
    TriggerServerEvent("origen_police:admin:deleteArmory", data.job)
    cb("ok")
end)

RegisterNetEvent("origen_police:client:updateJobArmories", function(jobArmories)
    Config.JobArmories = jobArmories or {}
    
    -- Sync backwards compatibility
    local PlayerData = FW_GetPlayerData()
    local jobName = PlayerData and PlayerData.job and PlayerData.job.name or "police"
    if Config.JobArmories[jobName] then
        Config.Armory.items = Config.JobArmories[jobName].items
        Config.Armory.label = Config.JobArmories[jobName].label
    end
    if Config.JobArmories["ambulance"] then
        Config.AmbulanceArmory.items = Config.JobArmories["ambulance"].items
        Config.AmbulanceArmory.label = Config.JobArmories["ambulance"].label
    end

    if adminOpen then
        SendNUIMessage({ action = "adminArmouriesUpdated", armouries = Config.JobArmories })
    end
end)

-- ─── Sincronización inicial al cargar el recurso ──────────────
CreateThread(function()
    Wait(5000) -- esperar un poco a que todo cargue
    TriggerServerEvent("origen_police:admin:requestRadioSync")
    TriggerServerEvent("origen_police:admin:requestRadioBindsSync")
    TriggerServerEvent("origen_police:admin:requestJobsSync")
    TriggerServerEvent("origen_police:admin:requestQuickmenuSync")
    TriggerServerEvent("origen_police:admin:requestExtraVehiclesSync")
    TriggerServerEvent("origen_police:admin:requestJobArmoriesSync")
end)

-- ─── SAMS Minigames Admin ─────────────────────────────────────
RegisterNUICallback("op_admin_getMinigamesConfig", function(_, cb)
    FW_TriggerCallback("origen_police:admin:getMinigamesConfig", function(config)
        cb(config or {})
    end)
end)

RegisterNUICallback("op_admin_saveMinigamesConfig", function(data, cb)
    TriggerServerEvent("origen_police:admin:saveMinigamesConfig", data)
    cb("ok")
end)

RegisterNetEvent("origen_police:client:syncMinigamesConfigAdmin", function(config)
    if adminOpen then
        SendNUIMessage({ action = "adminMinigamesConfigUpdated", config = config })
    end
end)

-- ─── SAMS Quickmenu Actions Admin ──────────────────────────────
RegisterNUICallback("op_admin_getQuickmenuActionsConfig", function(_, cb)
    FW_TriggerCallback("origen_police:admin:getQuickmenuActionsConfig", function(config)
        cb(config or {})
    end)
end)

RegisterNUICallback("op_admin_saveQuickmenuActionsConfig", function(data, cb)
    TriggerServerEvent("origen_police:admin:saveQuickmenuActionsConfig", data)
    cb("ok")
end)

RegisterNetEvent("origen_police:client:syncQuickmenuActionsAdmin", function(config)
    if adminOpen then
        SendNUIMessage({ action = "adminQuickmenuActionsUpdated", config = config })
    end
end)

-- ─── Police System Config Admin ──────────────────────────────
RegisterNUICallback("op_admin_getPoliceConfig", function(_, cb)
    FW_TriggerCallback("origen_police:admin:getPoliceConfig", function(config)
        cb(config or {})
    end)
end)

RegisterNUICallback("op_admin_savePoliceConfig", function(data, cb)
    TriggerServerEvent("origen_police:admin:savePoliceConfig", data)
    cb("ok")
end)

RegisterNetEvent("origen_police:client:syncPoliceConfigAdmin", function(config)
    if adminOpen then
        SendNUIMessage({ action = "adminPoliceConfigUpdated", config = config })
    end
end)

-- ─── EMS System Config Admin ─────────────────────────────────
RegisterNUICallback("op_admin_getEmsConfig", function(_, cb)
    FW_TriggerCallback("origen_police:admin:getEmsConfig", function(config)
        cb(config or {})
    end)
end)

RegisterNUICallback("op_admin_saveEmsConfig", function(data, cb)
    TriggerServerEvent("origen_police:admin:saveEmsConfig", data)
    cb("ok")
end)

RegisterNetEvent("origen_police:client:syncEmsConfigAdmin", function(config)
    if adminOpen then
        SendNUIMessage({ action = "adminEmsConfigUpdated", config = config })
    end
end)


-- ─── Vestuario Admin ──────────────────────────────────────────
RegisterNUICallback("op_admin_saveOutfit", function(data, cb)
    TriggerServerEvent("origen_police:admin:saveOutfit", data)
    cb("ok")
end)

RegisterNUICallback("op_admin_deleteOutfit", function(data, cb)
    TriggerServerEvent("origen_police:admin:deleteOutfit", data.id)
    cb("ok")
end)

RegisterNUICallback("op_admin_getOutfits", function(_, cb)
    FW_TriggerCallback("origen_police:admin:getOutfits", function(outfitsData)
        cb(outfitsData or {})
    end)
end)

RegisterNUICallback("op_admin_getCurrentOutfit", function(_, cb)
    local appearance = GetCurrentPedAppearance()
    local gender = GetGender()
    cb({
        data = appearance,
        gender = gender
    })
end)

RegisterNetEvent("origen_police:client:syncOutfits", function()
    if not adminOpen then return end
    FW_TriggerCallback("origen_police:admin:getOutfits", function(outfitsData)
        SendNUIMessage({
            action = "syncOutfits",
            outfits = outfitsData or {}
        })
    end)
end)

-- ─── Admin DB Configs Sync ────────────────────────────────────
RegisterNetEvent("origen_police:client:syncDBConfigs", function()
    if not adminOpen then return end
    FW_TriggerCallback("origen_police:callback:GetStationsList", function(stationsData)
        FW_TriggerCallback("origen_police:admin:getQuickmenuTabsVisibility", function(tabsVisibilityData)
            SendNUIMessage({
                action = "syncDBConfigs",
                stations = stationsData or {},
                quickmenuTabs = tabsVisibilityData or {}
            })
        end)
    end)
end)

-- ─── NUI Callbacks: Stations ──────────────────────────────────
RegisterNUICallback("op_admin_createStation", function(data, cb)
    TriggerServerEvent("origen_police:server:CreateStation", data.name, data.label)
    cb("ok")
end)

RegisterNUICallback("op_admin_deleteStation", function(data, cb)
    TriggerServerEvent("origen_police:server:deleteStation", data.station)
    cb("ok")
end)

RegisterNUICallback("op_admin_toggleStationActive", function(data, cb)
    TriggerServerEvent("origen_police:server:toggleStationActive", data.station, data.active)
    cb("ok")
end)

RegisterNUICallback("op_admin_toggleStationRepair", function(data, cb)
    TriggerServerEvent("origen_police:server:toggleStationRepair", data.station, data.active)
    cb("ok")
end)

RegisterNUICallback("op_admin_updateStationLabel", function(data, cb)
    TriggerServerEvent("origen_police:server:updateStationLabel", data.station, data.label)
    cb("ok")
end)

RegisterNUICallback("op_admin_addStationJobCat", function(data, cb)
    TriggerServerEvent("origen_police:server:addStationJobCat", data.station, data.category)
    cb("ok")
end)

RegisterNUICallback("op_admin_removeStationJobCat", function(data, cb)
    TriggerServerEvent("origen_police:server:removeStationJobCat", data.station, data.category)
    cb("ok")
end)

RegisterNUICallback("op_admin_removeMarker", function(data, cb)
    FW_TriggerCallback("origen_police:callback:RemoveMarker", function(success)
        if success then
            cb("ok")
        else
            cb("error")
        end
    end, data)
end)

-- ─── NUI Callbacks: Divisions ─────────────────────────────────
RegisterNUICallback("op_admin_getDivisions", function(_, cb)
    FW_TriggerCallback("origen_police:admin:getDivisions", function(data)
        if type(data) == "string" then
            pcall(function() data = json.decode(data) end)
            if type(data) == "string" then
                pcall(function() data = json.decode(data) end)
            end
        end
        cb(data or {})
    end)
end)

RegisterNUICallback("op_admin_saveDivisions", function(data, cb)
    TriggerServerEvent("origen_police:admin:saveDivisions", data.divisions)
    cb("ok")
end)

-- ─── NUI Callbacks: Licenses ──────────────────────────────────
RegisterNUICallback("op_admin_getLicenses", function(_, cb)
    FW_TriggerCallback("origen_police:admin:getLicenses", function(data)
        if type(data) == "string" then
            pcall(function() data = json.decode(data) end)
            if type(data) == "string" then
                pcall(function() data = json.decode(data) end)
            end
        end
        cb(data or {})
    end)
end)

RegisterNUICallback("op_admin_saveLicenses", function(data, cb)
    TriggerServerEvent("origen_police:admin:saveLicenses", data.licenses)
    cb("ok")
end)

-- ─── NUI Callbacks: Quickmenu Visibility ──────────────────────
RegisterNUICallback("op_admin_getQuickmenuTabsVisibility", function(_, cb)
    FW_TriggerCallback("origen_police:admin:getQuickmenuTabsVisibility", function(data)
        cb(data or {})
    end)
end)

RegisterNUICallback("op_admin_saveQuickmenuTabsVisibility", function(data, cb)
    TriggerServerEvent("origen_police:admin:saveQuickmenuTabsVisibility", data.category, data.hiddenTabs)
    cb("ok")
end)

-- ─── NUI Callbacks: Discord Sync ──────────────────────────────
RegisterNUICallback("op_admin_getDiscordConfig", function(_, cb)
    FW_TriggerCallback("origen_police:admin:getDiscordConfig", function(data)
        if type(data) == "string" then
            pcall(function() data = json.decode(data) end)
        end
        cb(data or {})
    end)
end)

RegisterNUICallback("op_admin_saveDiscordConfig", function(data, cb)
    TriggerServerEvent("origen_police:admin:saveDiscordConfig", data and data.config or data)
    cb("ok")
end)

RegisterNUICallback("op_admin_testDiscordConnection", function(data, cb)
    FW_TriggerCallback("origen_police:admin:testDiscordConnection", function(res)
        cb(res or { success = false, message = "Sin respuesta del servidor." })
    end, data or {})
end)

-- ─── Sync Client Events ───────────────────────────────────────
RegisterNetEvent("origen_police:client:syncQuickmenuTabsVisibility")
AddEventHandler("origen_police:client:syncQuickmenuTabsVisibility", function(category, hiddenTabs)
    if adminOpen then
        SendNUIMessage({ action = "adminQuickmenuTabsVisibilityUpdated", category = category, data = hiddenTabs })
    end
    local myCategory = GetPlayerJobCategory()
    if not category or category == myCategory then
        QuickmenuHiddenTabsConfig = hiddenTabs or {}
    end
end)

RegisterNetEvent("origen_police:client:updateDivisionsData", function(newDivisions)
    Translations.DivisionsData = newDivisions
    if Config and Config.Translations then
        Config.Translations.DivisionsData = newDivisions
    end
    SendNUIMessage({
        action = "updateDivisionsData",
        divisions = newDivisions
    })
    SendNUIMessage({
        action = "translations",
        translations = Config.Translations
    })
end)

RegisterNetEvent("origen_police:client:updatePoliceLicenses", function(newLicenses)
    Translations.PoliceLicenses = newLicenses
    if Config then
        if not Config.Translations then Config.Translations = {} end
        Config.Translations.PoliceLicenses = newLicenses
    end
    SendNUIMessage({
        action = "updatePoliceLicenses",
        licenses = newLicenses
    })
    SendNUIMessage({
        action = "translations",
        translations = Config.Translations
    })
end)

RegisterNUICallback("op_getPoliceLicenses", function(_, cb)
    if Config and Config.Translations and Config.Translations.PoliceLicenses and next(Config.Translations.PoliceLicenses) ~= nil then
        cb(Config.Translations.PoliceLicenses)
    else
        FW_TriggerCallback("origen_police:admin:getLicenses", function(data)
            if data then
                Translations.PoliceLicenses = data
                if Config then
                    if not Config.Translations then Config.Translations = {} end
                    Config.Translations.PoliceLicenses = data
                end
            end
            cb(data or {})
        end)
    end
end)

RegisterNUICallback("op_getDivisionsData", function(_, cb)
    if Config and Config.Translations and Config.Translations.DivisionsData and next(Config.Translations.DivisionsData) ~= nil then
        cb(Config.Translations.DivisionsData)
    else
        FW_TriggerCallback("origen_police:admin:getDivisions", function(data)
            if type(data) == "string" then
                pcall(function() data = json.decode(data) end)
                if type(data) == "string" then
                    pcall(function() data = json.decode(data) end)
                end
            end
            if data and type(data) == "table" and next(data) ~= nil then
                if not Config.Translations then Config.Translations = {} end
                Config.Translations.DivisionsData = data
                if Translations then Translations.DivisionsData = data end
            end
            cb(data or {})
        end)
    end
end)

-- ─── NUI Callbacks: Concesionario de Emergencias (Dealership) ──
RegisterNUICallback("op_admin_getDealershipData", function(data, cb)
    FW_TriggerCallback("origen_police:admin:getDealershipVehicles", function(vehs)
        FW_TriggerCallback("origen_police:admin:getDealershipPoints", function(pts)
            local jobToFetch = (data and data.job) or FW_GetPlayerData().job.name or "police"
            FW_TriggerCallback("origen_police:admin:getSocietyBalance", function(bal)
                cb({
                    vehicles = vehs or {},
                    points = pts or {},
                    societyBalance = bal or 0
                })
            end, jobToFetch)
        end)
    end)
end)

RegisterNUICallback("op_admin_saveDealershipVehicle", function(data, cb)
    TriggerServerEvent("origen_police:admin:saveDealershipVehicle", data)
    cb("ok")
end)

RegisterNUICallback("op_admin_addDealershipVehicle", function(data, cb)
    TriggerServerEvent("origen_police:admin:addDealershipVehicle", data)
    cb("ok")
end)

RegisterNUICallback("op_admin_deleteDealershipVehicle", function(data, cb)
    TriggerServerEvent("origen_police:admin:deleteDealershipVehicle", data and data.model)
    cb("ok")
end)

RegisterNUICallback("op_admin_deleteAllDealershipVehicles", function(_, cb)
    TriggerServerEvent("origen_police:admin:deleteAllDealershipVehicles")
    cb("ok")
end)

RegisterNUICallback("op_admin_saveDealershipPoints", function(data, cb)
    TriggerServerEvent("origen_police:admin:saveDealershipPoints", data and data.points)
    cb("ok")
end)

RegisterNUICallback("op_admin_addSocietyFunds", function(data, cb)
    TriggerServerEvent("origen_police:admin:addSocietyFunds", data)
    cb("ok")
end)

RegisterNetEvent("origen_police:client:syncDealershipVehicles", function(vehs)
    if adminOpen then
        SendNUIMessage({ action = "adminDealershipVehiclesUpdated", vehicles = vehs or {} })
    end
end)

RegisterNetEvent("origen_police:client:syncDealershipPoints", function(pts)
    if adminOpen then
        SendNUIMessage({ action = "adminDealershipPointsUpdated", points = pts or {} })
    end
end)

RegisterNetEvent("origen_police:client:societyFundsUpdated", function(info)
    if adminOpen then
        SendNUIMessage({ action = "adminSocietyFundsUpdated", data = info })
    end
end)

-- ─── NUI Callbacks: Callouts Admin ────────────────────────────
RegisterNUICallback("op_admin_getCalloutsState", function(_, cb)
    FW_TriggerCallback("origen_police:admin:getCalloutsState", function(data)
        cb(data or {})
    end)
end)

RegisterNUICallback("op_admin_saveCalloutsGeneralConfig", function(data, cb)
    TriggerServerEvent("origen_police:admin:saveCalloutsGeneralConfig", data)
    cb("ok")
end)

RegisterNUICallback("op_admin_saveCalloutScenario", function(data, cb)
    TriggerServerEvent("origen_police:admin:saveCalloutScenario", data)
    cb("ok")
end)

RegisterNUICallback("op_admin_deleteCalloutScenario", function(data, cb)
    TriggerServerEvent("origen_police:admin:deleteCalloutScenario", data and data.name)
    cb("ok")
end)

RegisterNUICallback("op_admin_saveCalloutLocation", function(data, cb)
    TriggerServerEvent("origen_police:admin:saveCalloutLocation", data)
    cb("ok")
end)

RegisterNUICallback("op_admin_deleteCalloutLocation", function(data, cb)
    TriggerServerEvent("origen_police:admin:deleteCalloutLocation", data and data.index)
    cb("ok")
end)

RegisterNUICallback("op_admin_triggerCallout", function(data, cb)
    TriggerServerEvent("origen_police:admin:triggerCallout", data and data.scenario)
    cb("ok")
end)

RegisterNUICallback("op_admin_cancelCallout", function(data, cb)
    TriggerServerEvent("origen_police:admin:cancelCallout", data and data.id)
    cb("ok")
end)

RegisterNUICallback("op_admin_toggleCallouts", function(data, cb)
    TriggerServerEvent("origen_police:admin:toggleCallouts", data and data.enabled)
    cb("ok")
end)

RegisterNUICallback("op_admin_getCurrentCoords", function(_, cb)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash)
    local zoneKey = GetNameOfZone(coords.x, coords.y, coords.z)
    local zoneLabel = GetLabelText(zoneKey)
    if zoneLabel == "NULL" or not zoneLabel or zoneLabel == "" then
        zoneLabel = zoneKey
    end
    cb({
        coords = {
            x = tonumber(string.format("%.2f", coords.x)),
            y = tonumber(string.format("%.2f", coords.y)),
            z = tonumber(string.format("%.2f", coords.z))
        },
        heading = tonumber(string.format("%.1f", heading)),
        street = streetName or "Ubicación actual",
        zone = zoneLabel or "Los Santos"
    })
end)

-- ─── Sync Callouts Event ──────────────────────────────────────
RegisterNetEvent("origen_police:admin:calloutsUpdated", function(calloutsState)
    if adminOpen then
        SendNUIMessage({ action = "adminCalloutsUpdated", data = calloutsState })
    end
end)

-- ============================================================
-- MODO DE COLOCACIÓN INTERACTIVO 3D DE CAMILLAS & SPAWNPOINTS
-- CON VISTA PREVIA EN VIVO DE ANIMACIÓN (timetable@tracy@sleep@ base)
-- ============================================================

local isPlacingBed = false

local function RotationToDirection(rot)
    local rx = math.rad(rot.x)
    local rz = math.rad(rot.z)
    return vector3(
        -math.sin(rz) * math.abs(math.cos(rx)),
        math.cos(rz) * math.abs(math.cos(rx)),
        math.sin(rx)
    )
end

local function RayCastGameCam(distance, ignoreEntity)
    local camRot = GetGameplayCamRot(2)
    local camCoord = GetGameplayCamCoord()
    local dir = RotationToDirection(camRot)
    local dest = camCoord + (dir * distance)
    local ray = StartShapeTestRay(camCoord.x, camCoord.y, camCoord.z, dest.x, dest.y, dest.z, -1, ignoreEntity or PlayerPedId(), 0)
    local _, hit, coords, _, entityHit = GetShapeTestResult(ray)
    if hit == 1 then
        return true, coords, entityHit
    end
    return false, dest, nil
end

-- Las teclas de la colocacion van en la barra de controles de origen_hud
-- (estilo de la casa), no en una caja dibujada con DrawRect/DrawText.
local function MostrarControlesColocacion(pointType)
    if GetResourceState("origen_hud") ~= "started" then return end
    pcall(function()
        exports["origen_hud"]:setupControls({
            { key = "E", text = "Confirmar" },
            { key = "RUEDA", text = "Girar" },
            { key = "Q / Z", text = "Subir / bajar" },
            { key = "SHIFT", text = "Más rápido" },
            { key = "R", text = "Altura a cero" },
        })
    end)
end

local function QuitarControlesColocacion()
    if GetResourceState("origen_hud") ~= "started" then return end
    pcall(function() exports["origen_hud"]:hideControls() end)
end

local function StartInteractiveBedPlacement(pointType, initialCoords, onResult)
    if isPlacingBed then return end
    isPlacingBed = true

    -- Ocultar temporalmente el menú admin NUI
    SetNuiFocus(false, false)
    adminOpen = false
    SendNUIMessage({ action = "tempHideAdmin" })

    CreateThread(function()
        local playerPed = PlayerPedId()
        local playerModel = GetEntityModel(playerPed)
        
        RequestModel(playerModel)
        local loadTimeout = 0
        while not HasModelLoaded(playerModel) and loadTimeout < 5000 do
            Wait(50)
            loadTimeout = loadTimeout + 50
        end

        local pCoords = GetEntityCoords(playerPed)
        local pHeading = GetEntityHeading(playerPed)

        local startX = initialCoords and tonumber(initialCoords.x) or pCoords.x
        local startY = initialCoords and tonumber(initialCoords.y) or pCoords.y
        local startZ = initialCoords and tonumber(initialCoords.z) or pCoords.z
        local currentHeading = initialCoords and (tonumber(initialCoords.w) or tonumber(initialCoords.h)) or pHeading
        local currentZOffset = 0.0

        local previewPed = CreatePed(4, playerModel, startX, startY, startZ, currentHeading, false, false)
        SetEntityAlpha(previewPed, 205, false)
        SetEntityCollision(previewPed, false, false)
        FreezeEntityPosition(previewPed, true)
        SetEntityInvincible(previewPed, true)
        SetBlockingOfNonTemporaryEvents(previewPed, true)

        if pointType == "bed" then
            lib.requestAnimDict("timetable@tracy@sleep@")
            TaskPlayAnim(previewPed, "timetable@tracy@sleep@", "base", 8.0, -8.0, -1, 1, 0, false, false, false)
        else
            lib.requestAnimDict("amb@world_human_hang_out_street@male_c@idle_a")
            TaskPlayAnim(previewPed, "amb@world_human_hang_out_street@male_c@idle_a", "idle_b", 8.0, -8.0, -1, 1, 0, false, false, false)
        end

        local lastHitCoords = vector3(startX, startY, startZ)

        ShowNotification(pointType == "bed"
            and "Colocando camilla: el muñeco tumbado enseña dónde quedará."
            or "Colocando el punto donde se levanta el paciente.", "info")
        MostrarControlesColocacion(pointType)

        while isPlacingBed do
            Wait(0)
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 14, true) -- Wheel down
            DisableControlAction(0, 15, true) -- Wheel up
            DisableControlAction(0, 16, true)
            DisableControlAction(0, 17, true)
            DisableControlAction(0, 37, true) -- Tab
            DisableControlAction(0, 44, true) -- Q
            DisableControlAction(0, 20, true) -- Z

            local hit, hitCoords = RayCastGameCam(15.0, previewPed)
            if hit then
                lastHitCoords = hitCoords
            end

            -- Rotación: Rueda de ratón / A / D / Flechas
            if IsDisabledControlPressed(0, 14) or IsControlPressed(0, 34) or IsControlPressed(0, 174) then
                currentHeading = (currentHeading - 2.0) % 360.0
            elseif IsDisabledControlPressed(0, 15) or IsControlPressed(0, 35) or IsControlPressed(0, 175) then
                currentHeading = (currentHeading + 2.0) % 360.0
            end

            -- Altura Z: Q (subir), Z (bajar), Shift (rápido)
            local step = IsControlPressed(0, 21) and 0.05 or 0.01
            if IsDisabledControlPressed(0, 44) or IsControlPressed(0, 27) then
                currentZOffset = currentZOffset + step
            elseif IsDisabledControlPressed(0, 20) or IsControlPressed(0, 173) then
                currentZOffset = currentZOffset - step
            end

            -- Reset altura con R
            if IsControlJustPressed(0, 45) then
                currentZOffset = 0.0
            end

            -- Actualizar posición y rotación del ped de previsualización
            SetEntityCoords(previewPed, lastHitCoords.x, lastHitCoords.y, lastHitCoords.z + currentZOffset, false, false, false, false)
            SetEntityHeading(previewPed, currentHeading)

            -- Mantener animación de acostado en bucle continuo
            if pointType == "bed" then
                if not IsEntityPlayingAnim(previewPed, "timetable@tracy@sleep@", "base", 3) then
                    TaskPlayAnim(previewPed, "timetable@tracy@sleep@", "base", 8.0, -8.0, -1, 1, 0, false, false, false)
                end
            end


            -- Confirmar: [E] (38) o [ENTER] (201 / 18)
            if IsControlJustPressed(0, 38) or IsControlJustPressed(0, 201) or IsControlJustPressed(0, 18) then
                isPlacingBed = false
                QuitarControlesColocacion()
                PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                if DoesEntityExist(previewPed) then
                    DeleteEntity(previewPed)
                end
                
                local finalCoords = {
                    x = tonumber(string.format("%.2f", lastHitCoords.x)),
                    y = tonumber(string.format("%.2f", lastHitCoords.y)),
                    z = tonumber(string.format("%.2f", lastHitCoords.z + currentZOffset)),
                    w = tonumber(string.format("%.1f", currentHeading))
                }
                
                adminOpen = true
                SetNuiFocus(true, true)
                onResult(finalCoords)
                break
            end

            -- Cancelar: [ESC] (322 / 200) o [BACKSPACE] (177)
            if IsControlJustPressed(0, 322) or IsControlJustPressed(0, 177) or IsControlJustPressed(0, 200) then
                isPlacingBed = false
                QuitarControlesColocacion()
                PlaySoundFrontend(-1, "CANCEL", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                if DoesEntityExist(previewPed) then
                    DeleteEntity(previewPed)
                end
                
                adminOpen = true
                SetNuiFocus(true, true)
                onResult(nil)
                break
            end
        end
    end)
end

-- Callbacks NUI de colocación de camillas y spawn
RegisterNUICallback("op_admin_startPlacingBedPoint", function(data, cb)
    cb("ok")
    StartInteractiveBedPlacement("bed", data and data.currentCoords, function(coords)
        if coords then
            SendNUIMessage({
                action = "adminBedPointPlaced",
                hospital = data and data.hospital or "pillbox",
                bedIndex = data and data.bedIndex or 0,
                pointType = "bed",
                coords = coords
            })
        else
            SendNUIMessage({
                action = "adminBedPlacementCancelled"
            })
        end
    end)
end)

RegisterNUICallback("op_admin_startPlacingSpawnPoint", function(data, cb)
    cb("ok")
    StartInteractiveBedPlacement("spawn", data and data.currentCoords, function(coords)
        if coords then
            SendNUIMessage({
                action = "adminBedPointPlaced",
                hospital = data and data.hospital or "pillbox",
                bedIndex = data and data.bedIndex or 0,
                pointType = "spawn",
                coords = coords
            })
        else
            SendNUIMessage({
                action = "adminBedPlacementCancelled"
            })
        end
    end)
end)

-- Callbacks NUI de datos de camillas
RegisterNUICallback("op_admin_getHospitalBeds", function(_, cb)
    FW_TriggerCallback("origen_police:admin:getHospitalBeds", function(beds)
        cb(beds or {})
    end)
end)

RegisterNUICallback("op_admin_saveHospitalBeds", function(data, cb)
    TriggerServerEvent("origen_police:admin:saveHospitalBeds", data)
    cb("ok")
end)

RegisterNetEvent("origen_police:client:syncHospitalBedsAdmin", function(beds)
    if adminOpen then
        SendNUIMessage({ action = "adminHospitalBedsUpdated", beds = beds })
    end
end)


