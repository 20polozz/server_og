--[[
    ============================================================
    ORIGEN POLICE - CLIENTE: CITACIONES / MULTAS DE TRÁFICO
    ============================================================
    Prop oficial: "multa" (recurso [assets]/multa)
    Interacción directa con [E] para examinar y [G] para retirar.
]]

local LocalWindshieldCitationsByPlate = {}
local LocalWindshieldCitationsByNet = {}
local LocalWindshieldProps = {}
local isCitationPadOpen = false

local hasShownPrompt = false

-- Mostrar notificación / aviso de tecla oficial de Origen (origen_notify)
local function ShowWindshieldPrompt()
    if hasShownPrompt then return end
    hasShownPrompt = true

    if GetResourceState('origen_notify') == 'started' then
        pcall(function()
            exports['origen_notify']:DrawText('E', 'Examinar citación', { 'G', 'Retirar multa' })
            exports['origen_notify']:Notify({
                title = 'Citación de Tráfico',
                description = 'Presiona [E] para examinar o [G] para retirar la multa',
                type = 'info',
                duration = 4500
            })
        end)
    else
        TriggerEvent('origen_police:ShowNotification', 'Presiona [E] para examinar la citación o [G] para retirarla.', 'primary')
    end
end

-- Ocultar aviso de tecla oficial de Origen
local function HideWindshieldPrompt()
    if not hasShownPrompt then return end
    hasShownPrompt = false

    if GetResourceState('origen_notify') == 'started' then
        pcall(function()
            exports['origen_notify']:HideText()
        end)
    end
end

-- Cargar modelo "multa" (asset propio) con fallbacks si fuese necesario
local function LoadTicketModel()
    local mainModel = GetHashKey("multa")
    if not HasModelLoaded(mainModel) then
        RequestModel(mainModel)
        local timeout = GetGameTimer() + 2500
        while not HasModelLoaded(mainModel) and GetGameTimer() < timeout do
            Wait(10)
        end
    end
    if HasModelLoaded(mainModel) then
        return mainModel
    end

    -- Fallbacks estándar si no estuviese cargado el asset
    local fallbacks = { "prop_cliff_paper", "prop_notepad_01", "p_ld_id_card_002" }
    for _, name in ipairs(fallbacks) do
        local fHash = GetHashKey(name)
        RequestModel(fHash)
        local t = GetGameTimer() + 500
        while not HasModelLoaded(fHash) and GetGameTimer() < t do Wait(10) end
        if HasModelLoaded(fHash) then return fHash end
    end
    return nil
end

-- Solicitar citaciones activas al servidor al iniciar
CreateThread(function()
    Wait(2000)
    TriggerServerEvent("origen_police:server:requestWindshieldCitations")
end)

-- Obtener coordenadas estimadas del parabrisas del vehículo
local function GetWindshieldCoords(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
        return vector3(0, 0, 0)
    end
    local boneIdx = GetEntityBoneIndexByName(vehicle, "windscreen")
    if not boneIdx or boneIdx == -1 then
        boneIdx = GetEntityBoneIndexByName(vehicle, "windscreen_f")
    end
    if boneIdx and boneIdx ~= -1 then
        return GetWorldPositionOfEntityBone(vehicle, boneIdx)
    end
    return GetOffsetFromEntityInWorldCoords(vehicle, 0.25, 0.85, 0.45)
end

-- Limpieza de props de tickets
local function CleanPropForVehicle(vehicle, netId, plate)
    if vehicle and LocalWindshieldProps[vehicle] and DoesEntityExist(LocalWindshieldProps[vehicle]) then
        DeleteEntity(LocalWindshieldProps[vehicle])
        LocalWindshieldProps[vehicle] = nil
    end
    if netId and LocalWindshieldProps[netId] and DoesEntityExist(LocalWindshieldProps[netId]) then
        DeleteEntity(LocalWindshieldProps[netId])
        LocalWindshieldProps[netId] = nil
    end
    if plate and LocalWindshieldProps[plate] and DoesEntityExist(LocalWindshieldProps[plate]) then
        DeleteEntity(LocalWindshieldProps[plate])
        LocalWindshieldProps[plate] = nil
    end
end

-- Acoplar prop "multa" al parabrisas del vehículo físico
local function AttachTicketProp(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    local plate = GetVehicleNumberPlateText(vehicle)
    local cleanPlate = plate and string.upper(string.gsub(plate, "%s+", "")) or nil

    CleanPropForVehicle(vehicle, netId, cleanPlate)

    local model = LoadTicketModel()
    if not model then
        print("^1[origen_police] Error: No se pudo cargar el modelo 'multa'.^0")
        return
    end

    local coords = GetEntityCoords(vehicle)
    local prop = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)
    if not prop or prop == 0 or not DoesEntityExist(prop) then
        SetModelAsNoLongerNeeded(model)
        return
    end

    SetEntityCollision(prop, false, false)

    -- Buscar hueso del parabrisas delantero
    local boneIdx = GetEntityBoneIndexByName(vehicle, "windscreen")
    if not boneIdx or boneIdx == -1 then
        boneIdx = GetEntityBoneIndexByName(vehicle, "windscreen_f")
    end

    if boneIdx and boneIdx ~= -1 then
        AttachEntityToEntity(prop, vehicle, boneIdx, 0.18, -0.05, 0.02, 10.0, 5.0, 15.0, false, false, false, false, 2, true)
    else
        local minDim, maxDim = GetModelDimensions(GetEntityModel(vehicle))
        local forward = maxDim.y * 0.32
        local up = maxDim.z * 0.42
        AttachEntityToEntity(prop, vehicle, 0, 0.25, forward, up, 25.0, 0.0, 15.0, false, false, false, false, 2, true)
    end

    SetModelAsNoLongerNeeded(model)
    LocalWindshieldProps[vehicle] = prop
    if netId and netId > 0 then LocalWindshieldProps[netId] = prop end
    if cleanPlate and cleanPlate ~= "" then LocalWindshieldProps[cleanPlate] = prop end
end

-- Utilidad para encontrar vehículo cercano que tenga una citación activa en el parabrisas
-- (Detecta el vehículo físico por State Bag, NetId o matrícula real, sin depender de erratas al escribir)
local function FindNearbyVehicleWithCitation(maxDist)
    local ped = PlayerPedId()
    local pCoords = GetEntityCoords(ped)
    local dist = maxDist or 6.5
    local vehicles = GetGamePool('CVehicle')

    for _, veh in ipairs(vehicles) do
        if DoesEntityExist(veh) then
            local vCoords = GetEntityCoords(veh)
            if #(pCoords - vCoords) <= dist then
                -- 1. State bag nativa de la entidad vehículo
                local stateCitation = Entity(veh).state.windshieldCitation
                if stateCitation then
                    return veh, stateCitation
                end

                -- 2. Sincronización por Network ID de la entidad
                local netId = NetworkGetNetworkIdFromEntity(veh)
                if netId and netId > 0 and LocalWindshieldCitationsByNet[netId] then
                    return veh, LocalWindshieldCitationsByNet[netId]
                end

                -- 3. Sincronización por matrícula real física del vehículo
                local plate = GetVehicleNumberPlateText(veh)
                local cleanActual = plate and string.upper(string.gsub(plate, "%s+", "")) or ""
                if cleanActual ~= "" and LocalWindshieldCitationsByPlate[cleanActual] then
                    return veh, LocalWindshieldCitationsByPlate[cleanActual]
                end
            end
        end
    end
    return 0, nil
end

-- Utilidad para obtener el vehículo más cercano frente al jugador
local function GetNearbyVehicle(maxDist)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local dist = maxDist or 5.0
    local closestVeh = 0
    local closestDist = dist

    local vehicles = GetGamePool('CVehicle')
    for _, veh in ipairs(vehicles) do
        if DoesEntityExist(veh) then
            local vehCoords = GetEntityCoords(veh)
            local d = #(coords - vehCoords)
            if d < closestDist then
                closestDist = d
                closestVeh = veh
            end
        end
    end

    return closestVeh
end

-- Sincronización desde el servidor
RegisterNetEvent("origen_police:client:syncWindshieldCitation", function(targetData, citationData)
    if not targetData or not citationData then return end

    local vehNetId = nil
    local actualPlate = nil
    if type(targetData) == "table" then
        vehNetId = tonumber(targetData.vehNetId)
        actualPlate = targetData.actualPlate and string.upper(string.gsub(targetData.actualPlate, "%s+", "")) or nil
    elseif type(targetData) == "string" then
        actualPlate = string.upper(string.gsub(targetData, "%s+", ""))
    elseif type(targetData) == "number" then
        vehNetId = targetData
    end

    if actualPlate and actualPlate ~= "" then
        LocalWindshieldCitationsByPlate[actualPlate] = citationData
    end
    if vehNetId and vehNetId > 0 then
        LocalWindshieldCitationsByNet[vehNetId] = citationData
    end

    -- Si tenemos el vehículo en streaming cerca, acoplar el prop inmediatamente
    if vehNetId and vehNetId > 0 and NetworkDoesNetworkIdExist(vehNetId) then
        local veh = NetToVeh(vehNetId)
        if veh ~= 0 and DoesEntityExist(veh) then
            AttachTicketProp(veh)
            return
        end
    end

    local vehicle = GetNearbyVehicle(6.0)
    if vehicle ~= 0 and DoesEntityExist(vehicle) then
        local p = GetVehicleNumberPlateText(vehicle)
        local c = p and string.upper(string.gsub(p, "%s+", "")) or ""
        if c == actualPlate then
            AttachTicketProp(vehicle)
        end
    end
end)

RegisterNetEvent("origen_police:client:removeWindshieldCitation", function(targetData)
    if not targetData then return end

    local vehNetId = nil
    local actualPlate = nil
    local citationId = nil
    if type(targetData) == "table" then
        vehNetId = tonumber(targetData.vehNetId)
        actualPlate = targetData.actualPlate and string.upper(string.gsub(targetData.actualPlate, "%s+", "")) or nil
        citationId = tonumber(targetData.citationId)
    elseif type(targetData) == "string" then
        actualPlate = string.upper(string.gsub(targetData, "%s+", ""))
    elseif type(targetData) == "number" then
        vehNetId = targetData
    end

    if actualPlate then LocalWindshieldCitationsByPlate[actualPlate] = nil end
    if vehNetId then LocalWindshieldCitationsByNet[vehNetId] = nil end
    if citationId then
        for p, c in pairs(LocalWindshieldCitationsByPlate) do
            if c.id == citationId then
                if not actualPlate then actualPlate = p end
                if not vehNetId and c.vehNetId then vehNetId = c.vehNetId end
                LocalWindshieldCitationsByPlate[p] = nil
            end
        end
        for n, c in pairs(LocalWindshieldCitationsByNet) do
            if c.id == citationId then
                if not vehNetId then vehNetId = n end
                if not actualPlate and (c.actualPlate or c.plate) then actualPlate = c.actualPlate or c.plate end
                LocalWindshieldCitationsByNet[n] = nil
            end
        end
    end

    local veh = nil
    if vehNetId and vehNetId > 0 and NetworkDoesNetworkIdExist(vehNetId) then
        veh = NetToVeh(vehNetId)
    end
    CleanPropForVehicle(veh, vehNetId, actualPlate)
    HideWindshieldPrompt()
end)

RegisterNetEvent("origen_police:client:syncAllWindshieldCitations", function(allData)
    LocalWindshieldCitationsByPlate = {}
    LocalWindshieldCitationsByNet = {}

    for _, prop in pairs(LocalWindshieldProps) do
        if DoesEntityExist(prop) then DeleteEntity(prop) end
    end
    LocalWindshieldProps = {}

    if type(allData) == "table" then
        if allData.byPlate then
            for p, data in pairs(allData.byPlate) do
                local clean = string.upper(string.gsub(p, "%s+", ""))
                LocalWindshieldCitationsByPlate[clean] = data
            end
        end
        if allData.byNet then
            for netId, data in pairs(allData.byNet) do
                LocalWindshieldCitationsByNet[tonumber(netId)] = data
            end
        end
        if not allData.byPlate and not allData.byNet then
            for p, data in pairs(allData) do
                local clean = string.upper(string.gsub(p, "%s+", ""))
                LocalWindshieldCitationsByPlate[clean] = data
            end
        end
    end
end)

-- Bucle de comprobación de proximidad e interacción [E] / [G] (SIN TARGET)
CreateThread(function()
    while true do
        local wait = 800
        local ped = PlayerPedId()

        if not IsPedInAnyVehicle(ped, false) and not isCitationPadOpen then
            local vehicle, citation = FindNearbyVehicleWithCitation(6.5)

            if vehicle ~= 0 and citation then
                -- Asegurar que el prop "multa" esté acoplado al vehículo
                if not LocalWindshieldProps[vehicle] or not DoesEntityExist(LocalWindshieldProps[vehicle]) then
                    AttachTicketProp(vehicle)
                end

                local pedCoords = GetEntityCoords(ped)
                local wsCoords = GetWindshieldCoords(vehicle)
                local distToWindshield = #(pedCoords - wsCoords)

                -- Si está dentro del rango del parabrisas (hasta 3.2m), interacción a 0ms
                if distToWindshield <= 3.2 then
                    wait = 0

                    -- Mostrar notificación / aviso de tecla de Origen (SIN 3D ni texto nativo GTA)
                    ShowWindshieldPrompt()

                    -- Tecla [E] (INPUT_CONTEXT / 38): Examinar boleta en pantalla
                    if IsControlJustPressed(0, 38) then
                        HideWindshieldPrompt()
                        TriggerEvent("origen_police:client:viewCitation", citation)
                    end

                    -- Tecla [G] (INPUT_DETONATE / 47): Retirar boleta del parabrisas
                    if IsControlJustPressed(0, 47) then
                        HideWindshieldPrompt()
                        local dict = "anim@mp_player_intmenu@key_fob@"
                        RequestAnimDict(dict)
                        local t = GetGameTimer() + 1000
                        while not HasAnimDictLoaded(dict) and GetGameTimer() < t do Wait(10) end
                        TaskPlayAnim(ped, dict, "fob_click", 8.0, -8.0, 1000, 48, 0, false, false, false)
                        Wait(600)
                        ClearPedTasks(ped)

                        local netId = NetworkGetNetworkIdFromEntity(vehicle)
                        local p = GetVehicleNumberPlateText(vehicle)
                        local cleanActual = p and string.upper(string.gsub(p, "%s+", "")) or ""

                        TriggerServerEvent("origen_police:server:removeWindshieldCitation", {
                            vehNetId = netId,
                            actualPlate = cleanActual,
                            citationId = citation.id
                        })
                    end
                else
                    HideWindshieldPrompt()
                    wait = 100
                end
            else
                HideWindshieldPrompt()
            end
        else
            HideWindshieldPrompt()
        end

        Wait(wait)
    end
end)

-- Exportación para comprobar si la boleta está abierta
exports("IsCitationPadOpen", function()
    return isCitationPadOpen
end)

-- Función para abrir la libreta de citaciones (Modo redacción / oficial)
local function OpenCitationPad()
    local ped = PlayerPedId()
    local PlayerData = FW_GetPlayerData()
    if not PlayerData or not PlayerData.job then
        print("^1[origen_police] Error: PlayerData o job no disponible al abrir citación.^0")
        return
    end

    local canOpen = CanOpenTablet(PlayerData.job.name)
    local isCop = canOpen and canOpen[1]
    if not isCop then
        TriggerEvent("origen_police:ShowNotification", "No tienes autorización para emitir citaciones.", "error")
        return
    end

    if Config.Framework == "qbcore" and not (PlayerData.job.onduty or onduty) then
        TriggerEvent("origen_police:ShowNotification", "Debes estar de servicio para emitir citaciones.", "error")
        return
    end

    local firstName = (PlayerData.charinfo and PlayerData.charinfo.firstname) or PlayerData.firstName or "Oficial"
    local lastName = (PlayerData.charinfo and PlayerData.charinfo.lastname) or PlayerData.lastName or ""
    local officerName = (firstName .. " " .. lastName):gsub("^%s*(.-)%s*$", "%1")
    if officerName == "" then officerName = "Oficial de Policía" end

    local officerBadge = (PlayerData.metadata and PlayerData.metadata.police_badge) or (PlayerData.job.grade and tostring(PlayerData.job.grade.level)) or "0000"

    print("^2[origen_police] Abriendo boleta de citación para el agente: " .. tostring(officerName) .. " (Placa: " .. tostring(officerBadge) .. ")^0")

    isCitationPadOpen = true
    SetNuiFocus(true, true)

    SendNUIMessage({
        action = "OpenCitationPad",
        mode = "create",
        officer = {
            name = officerName,
            badge = officerBadge,
            job = PlayerData.job.label or PlayerData.job.name or "LSPD"
        },
        date = string.format("%02d/%02d/%04d %02d:%02d", GetClockDayOfMonth(), GetClockMonth() + 1, GetClockYear(), GetClockHours(), GetClockMinutes())
    })
end

RegisterNetEvent("origen_police:client:openCitationPad", function()
    CreateThread(function()
        OpenCitationPad()
    end)
end)

-- Ver boleta de citación en modo solo lectura (ciudadano o policía)
RegisterNetEvent("origen_police:client:viewCitation", function(citationData)
    if not citationData then return end
    isCitationPadOpen = true
    SetNuiFocus(true, true)

    SendNUIMessage({
        action = "OpenCitationPad",
        mode = "view",
        citation = citationData
    })
end)

-- Comandos /multar y /citacion
RegisterCommand("multar", function()
    OpenCitationPad()
end, false)

RegisterCommand("citacion", function()
    OpenCitationPad()
end, false)

-- NUI Callbacks
RegisterNUICallback("police:closeCitationPad", function(data, cb)
    isCitationPadOpen = false
    SetNuiFocus(false, false)
    DevolverFocoTrasCapa()
    cb(true)
end)

RegisterNUICallback("police:submitCitation", function(data, cb)
    local ped = PlayerPedId()

    if data.placement == "windshield" then
        local vehicle = GetNearbyVehicle(5.0)
        if vehicle == 0 or not DoesEntityExist(vehicle) then
            ShowNotification("Debes estar junto al vehículo para colocar la citación en el parabrisas.", "error")
            cb({ success = false, message = "no_vehicle" })
            return
        end

        local vehNetId = NetworkGetNetworkIdFromEntity(vehicle)
        local actualPlate = GetVehicleNumberPlateText(vehicle)
        local cleanActualPlate = actualPlate and string.upper(string.gsub(actualPlate, "%s+", "")) or ""

        -- Si el policía no rellenó la matrícula pero está frente al coche, usar la del coche por defecto
        if not data.plate or data.plate == "" then
            data.plate = actualPlate or "DESCONOCIDA"
        end

        -- Animación de colocar multa en el parabrisas
        local dict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@"
        RequestAnimDict(dict)
        local timeout = GetGameTimer() + 1500
        while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do Wait(10) end

        if HasAnimDictLoaded(dict) then
            TaskPlayAnim(ped, dict, "machinic_loop_mechandplayer", 3.0, 3.0, 1500, 48, 0, false, false, false)
        else
            TaskStartScenarioInPlace(ped, "PROP_HUMAN_PARKING_METER", 0, true)
        end

        Wait(1200)
        ClearPedTasks(ped)

        -- Acoplar prop "multa" inmediatamente en el vehículo
        AttachTicketProp(vehicle)

        -- Enviar al servidor pasando los datos del formulario (con la matrícula que haya escrito el policía)
        -- y los datos de la entidad física real del vehículo para vincular la nota al coche
        TriggerServerEvent("origen_police:server:createCitation", data, "windshield", {
            vehNetId = vehNetId,
            actualPlate = cleanActualPlate
        })

        isCitationPadOpen = false
        SetNuiFocus(false, false)
        DevolverFocoTrasCapa()
        cb({ success = true })

    elseif data.placement == "citizen" then
        local player, distance = FW_GetClosestPlayer()
        if player == -1 or distance > 3.0 then
            ShowNotification("No hay ningún ciudadano lo suficientemente cerca para entregar la citación en mano.", "error")
            cb({ success = false, message = "no_citizen" })
            return
        end

        -- Animación de entrega
        local dict = "mp_common"
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do Wait(10) end
        TaskPlayAnim(ped, dict, "givetake2_a", 4.0, 4.0, 1500, 48, 0, false, false, false)
        Wait(1000)
        ClearPedTasks(ped)

        TriggerServerEvent("origen_police:server:createCitation", data, "citizen", GetPlayerServerId(player))

        isCitationPadOpen = false
        SetNuiFocus(false, false)
        DevolverFocoTrasCapa()
        cb({ success = true })

    else
        isCitationPadOpen = false
        SetNuiFocus(false, false)
        DevolverFocoTrasCapa()
        cb({ success = false })
    end
end)

-- Limpieza de entidades al parar el recurso
AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    HideWindshieldPrompt()
    for _, prop in pairs(LocalWindshieldProps) do
        if DoesEntityExist(prop) then
            DeleteEntity(prop)
        end
    end
    LocalWindshieldProps = {}
end)

-- Notificar a la NUI de la tablet que la lista de citaciones ha cambiado
RegisterNetEvent("origen_police:client:citationsUpdated", function()
    SendNUIMessage({
        action = "updateCitations"
    })
end)

