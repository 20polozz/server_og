local AttachEntityToEntity            = AttachEntityToEntity
local ClearPedTasks                   = ClearPedTasks
local CreateObject                    = CreateObject
local CreateThread                    = CreateThread
local DetachEntity                    = DetachEntity
local Entity                          = Entity
local FreezeEntityPosition            = FreezeEntityPosition
local GetClosestObjectOfType          = GetClosestObjectOfType
local GetEntityAttachedTo             = GetEntityAttachedTo
local GetEntityModel                  = GetEntityModel
local GetEntityCoords                 = GetEntityCoords
local GetPlayerServerId               = GetPlayerServerId
local GetVehicleClassFromName         = GetVehicleClassFromName
local GetVehicleMaxNumberOfPassengers = GetVehicleMaxNumberOfPassengers
local IsControlJustReleased           = IsControlJustReleased
local IsEntityAttachedToEntity        = IsEntityAttachedToEntity
local IsEntityPlayingAnim             = IsEntityPlayingAnim
local IsVehicleSeatFree               = IsVehicleSeatFree
local NetworkGetEntityFromNetworkId   = NetworkGetEntityFromNetworkId
local NetworkGetPlayerIndexFromPed    = NetworkGetPlayerIndexFromPed
local PlayerPedId                     = PlayerPedId
local SetEntityAsMissionEntity        = SetEntityAsMissionEntity
local TaskPlayAnim                    = TaskPlayAnim
local TaskWarpPedIntoVehicle          = TaskWarpPedIntoVehicle
local Wait                            = Wait

local usingStretcher = false
local currentStretcher = nil
local patientOnStretcher = nil
local Config = lib.load("config")
local emsJobs = Config.emsJobs
local emsVehicles = Config.emsVehicles
local stretcherDefaultKey = Config.stretcherDefaultKey or "K"

-- Cache para no saturar comprobaciones de vehículos cercanos
local vehCache = { radio = nil, veh = nil, hasta = 0 }
local function vehiculoCercano(coords, radio)
    local ahora = GetGameTimer()
    if vehCache.radio ~= radio or ahora >= vehCache.hasta then
        vehCache.radio = radio
        vehCache.veh = lib.getClosestVehicle(coords, radio, true)
        vehCache.hasta = ahora + 250
    end
    if vehCache.veh and not DoesEntityExist(vehCache.veh) then vehCache.veh = nil end
    return vehCache.veh
end

local function getAmbulanceStretchers()
    return tonumber(GetEMSConfigVal("ambulanceStretchers", 2)) or 2
end

local function isEmsVehicle(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return false end
    local vehicleModel = GetEntityModel(vehicle)
    local vehicleClass = GetVehicleClass(vehicle)

    for model, value in pairs(emsVehicles) do
        if value then
            if joaat(model) == vehicleModel then return true end
        end
    end

    -- GTA Vehicle Class 18 is Emergency (Ambulances, Fire, Emergency EMS)
    if vehicleClass == 18 then
        return true
    end

    return false
end

local function useStretcher(stretcher)
    if not stretcher or stretcher == 0 or not DoesEntityExist(stretcher) then return end
    usingStretcher = true
    currentStretcher = stretcher

    local playerPed = cache.ped or PlayerPedId()
    local dict = lib.requestAnimDict("anim@heists@box_carry@")

    FreezeEntityPosition(stretcher, false)
    AttachEntityToEntity(stretcher, playerPed, GetPedBoneIndex(playerPed, 28422), -0.1681134, -1.0495786, -0.516176, 12.740244, 4.5091583, -8.204815, true, true, false, true, 1, true)
    SetEntityAsMissionEntity(stretcher, true, true)

    CreateThread(function()
        while usingStretcher and DoesEntityExist(stretcher) and IsEntityAttachedToEntity(stretcher, playerPed) do
            if not IsEntityPlayingAnim(playerPed, dict, 'idle', 3) then
                TaskPlayAnim(playerPed, dict, 'idle', 8.0, 8.0, -1, 50, 0, false, false, false)
            end
            Wait(500)
        end
    end)
end

function toggleStretcher(toggle)
    local playerPed = cache.ped or PlayerPedId()
    local playerCoords = cache.coords or GetEntityCoords(playerPed)

    if toggle then
        if usingStretcher and currentStretcher and DoesEntityExist(currentStretcher) then
            return
        end

        local stretcherModel = `prop_ld_binbag_01`
        lib.requestModel(stretcherModel, 5000)

        local forward = GetEntityForwardVector(playerPed)
        local spawnCoords = playerCoords + forward * 0.8
        local stretcher = CreateObject(stretcherModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, true, true, true)

        if not DoesEntityExist(stretcher) or stretcher == 0 then
            stretcher = CreateObject(stretcherModel, playerCoords.x, playerCoords.y, playerCoords.z, true, true, false)
        end

        SetEntityHeading(stretcher, GetEntityHeading(playerPed))
        PlaceObjectOnGroundProperly(stretcher)
        SetEntityAsMissionEntity(stretcher, true, true)
        currentStretcher = stretcher
        useStretcher(stretcher)
    else
        ClearPedTasks(playerPed)
        if currentStretcher and DoesEntityExist(currentStretcher) then
            DetachEntity(currentStretcher, true, true)
            DeleteEntity(currentStretcher)
        end
        currentStretcher = nil
        usingStretcher = false
        patientOnStretcher = nil
        lib.hideTextUI()
    end
end

RegisterNetEvent("origen_ambulancejob:toggleStretcherItem", function()
    if not Framework.hasJob(emsJobs) then
        return utils.showNotification("No tienes autorización médica para usar la camilla.", "error")
    end
    toggleStretcher(not usingStretcher)
end)

RegisterCommand("camilla", function()
    if not Framework.hasJob(emsJobs) then
        return utils.showNotification("No tienes autorización médica para usar la camilla.", "error")
    end
    toggleStretcher(not usingStretcher)
end, false)

local function handleStretcherAction()
    if not Framework.hasJob(emsJobs) then
        return utils.showNotification("No tienes autorización médica para usar la camilla.", "error")
    end
    if player and player.isDead then return end
    local playerPed = cache.ped or PlayerPedId()
    if cache.vehicle or IsPedInAnyVehicle(playerPed, false) then return end

    local playerCoords = cache.coords or GetEntityCoords(playerPed)

    -- Si ya está usando la camilla
    if usingStretcher and currentStretcher and DoesEntityExist(currentStretcher) then
        if not patientOnStretcher then
            local closestVeh = vehiculoCercano(playerCoords, 4.0)
            if closestVeh and isEmsVehicle(closestVeh) then
                local maxStretchers = getAmbulanceStretchers()
                if not Entity(closestVeh).state.stretcher then Entity(closestVeh).state.stretcher = maxStretchers end
                if Entity(closestVeh).state.stretcher >= maxStretchers then
                    utils.showNotification(locale("stretcher_limit_reached"), "error")
                else
                    Entity(closestVeh).state.stretcher += 1
                    toggleStretcher(false)
                    if lib.hideTextUI then lib.hideTextUI() end
                end
            else
                DetachEntity(currentStretcher, true, true)
                ClearPedTasks(playerPed)
                PlaceObjectOnGroundProperly(currentStretcher)
                FreezeEntityPosition(currentStretcher, true)
                usingStretcher = false
                if lib.hideTextUI then lib.hideTextUI() end
            end
        end
        return
    end

    -- 1. Camilla en el suelo a menos de 2.5m -> Cogerla
    local closestStretcher = GetClosestObjectOfType(playerCoords.x, playerCoords.y, playerCoords.z, 2.5, `prop_ld_binbag_01`, false)
    if closestStretcher ~= 0 and DoesEntityExist(closestStretcher) and not IsEntityAttachedToEntity(closestStretcher, playerPed) then
        local sCoords = GetEntityCoords(closestStretcher)
        local playerId, attachedPlayerPed = lib.getClosestPlayer(sCoords, 2.0, false)
        local isPatientAttached = attachedPlayerPed and GetEntityAttachedTo(attachedPlayerPed) == closestStretcher

        useStretcher(closestStretcher)
        if isPatientAttached then
            patientOnStretcher = attachedPlayerPed
        end
        if lib.hideTextUI then lib.hideTextUI() end
        return
    end

    -- 2. Ambulancia a menos de 3.5m -> Sacar camilla del vehículo
    local closestVeh = vehiculoCercano(playerCoords, 3.5)
    if closestVeh and isEmsVehicle(closestVeh) then
        local maxStretchers = getAmbulanceStretchers()
        if not Entity(closestVeh).state.stretcher then Entity(closestVeh).state.stretcher = maxStretchers end
        if Entity(closestVeh).state.stretcher < 1 then
            utils.showNotification(locale("no_stretcher_found"), "error")
        else
            toggleStretcher(true)
            Entity(closestVeh).state.stretcher -= 1
            if lib.hideTextUI then lib.hideTextUI() end
        end
        return
    end

    -- 3. Si no está ni junto a ambulancia ni camilla, spawnear/despawnear (como /camilla)
    toggleStretcher(not usingStretcher)
end

local stretcherKeybind = nil
if lib and lib.addKeybind then
    stretcherKeybind = lib.addKeybind({
        name = 'ems_stretcher',
        description = 'Sacar o recoger camilla médica (EMS)',
        defaultKey = stretcherDefaultKey,
        onPressed = function()
            handleStretcherAction()
        end
    })
else
    RegisterCommand('+ems_stretcher', function()
        handleStretcherAction()
    end, false)
    RegisterCommand('-ems_stretcher', function() end, false)
    RegisterKeyMapping('+ems_stretcher', 'Sacar o recoger camilla médica (EMS)', 'keyboard', stretcherDefaultKey)
end

local function getStretcherKeyLabel()
    if stretcherKeybind then
        local ok, key = pcall(function() return stretcherKeybind:getCurrentKey() end)
        if ok and type(key) == "string" and key ~= "" and not key:find("~") then
            return key:upper()
        end
    end
    return (stretcherDefaultKey or "K"):upper()
end

RegisterCommand("sacarcamilla", function()
    handleStretcherAction()
end, false)

function putOnStretcher(toggle, target)
    if not target or target == 0 then return end
    local data = {}
    data.toggle = toggle
    data.target = GetPlayerServerId(NetworkGetPlayerIndexFromPed(target))
    TriggerServerEvent("origen_ambulancejob:putOnStretcher", data)
    patientOnStretcher = toggle and target or nil
end

RegisterNetEvent("origen_ambulancejob:togglePatientFromVehicle", function(veh)
    local playerPed = cache.ped or PlayerPedId()
    local vehicle = NetworkGetEntityFromNetworkId(veh)
    local currentVehicle = cache.vehicle
    local seatToGo = nil

    DetachEntity(playerPed)

    if not currentVehicle then
        local seats = GetVehicleMaxNumberOfPassengers(vehicle)
        for i = 0, seats - 1 do
            if IsVehicleSeatFree(vehicle, i) then
                seatToGo = i
                break
            end
        end

        if seatToGo then
            TaskWarpPedIntoVehicle(playerPed, vehicle, seatToGo)
        end
    else
        TaskLeaveVehicle(playerPed, currentVehicle, 16)
    end
end)
RegisterNetEvent("ars_ambulancejob:togglePatientFromVehicle", function(veh)
    TriggerEvent("origen_ambulancejob:togglePatientFromVehicle", veh)
end)

RegisterNetEvent("origen_ambulancejob:putOnStretcher", function(toggle)
    local playerPed = cache.ped or PlayerPedId()
    local playerCoords = cache.coords or GetEntityCoords(playerPed)

    if toggle then
        local closestStretcher = GetClosestObjectOfType(playerCoords.x, playerCoords.y, playerCoords.z, 5.5, `prop_ld_binbag_01`, false)
        if closestStretcher ~= 0 then
            AttachEntityToEntity(playerPed, closestStretcher, 0, 0, 0.0, 1.0, 195.0, 0.0, 180.0, 0.0, false, false, false, false, 2)
        end
    else
        DetachEntity(playerPed)
        ClearPedTasks(playerPed)
    end
end)
RegisterNetEvent("ars_ambulancejob:putOnStretcher", function(toggle)
    TriggerEvent("origen_ambulancejob:putOnStretcher", toggle)
end)

-- Main Proximity Interaction Loop for Stretcher & EMS Vehicles
CreateThread(function()
    local currentShownText = nil

    local function showPrompt(text)
        if currentShownText ~= text then
            currentShownText = text
            lib.showTextUI(text, {
                position = "top-center",
                icon = 'bed',
                style = {
                    borderRadius = '8px',
                    backgroundColor = '#1e293b',
                    color = 'white',
                    padding = '10px',
                    boxShadow = '0 2px 4px rgba(0, 0, 0, 0.2)'
                }
            })
        end
    end

    local function hidePrompt()
        if currentShownText ~= nil then
            currentShownText = nil
            lib.hideTextUI()
        end
    end

    while true do
        local sleep = 500
        local playerPed = cache.ped or PlayerPedId()
        -- Este hilo corre para todo el mundo: quien no es sanitario mira cada 1,5 s.
        local esSanitario = Framework.hasJob(emsJobs)

        if not player.isDead and esSanitario then
            local playerCoords = cache.coords or GetEntityCoords(playerPed)

            if usingStretcher and currentStretcher and DoesEntityExist(currentStretcher) then
                sleep = 0
                local closestVeh = vehiculoCercano(playerCoords, 4.0)

                if closestVeh and isEmsVehicle(closestVeh) then
                    if patientOnStretcher then
                        showPrompt('[G] - ' .. locale('put_patient_in_vehicle') .. '  |  [H] - ' .. locale('control_drop_stretcher'))

                        if IsControlJustReleased(0, 47) then -- [G]
                            local dataToSend = {}
                            dataToSend.vehicle = NetworkGetNetworkIdFromEntity(closestVeh)
                            dataToSend.target = GetPlayerServerId(NetworkGetPlayerIndexFromPed(patientOnStretcher))
                            TriggerServerEvent('origen_ambulancejob:togglePatientFromVehicle', dataToSend)

                            Entity(closestVeh).state.patient = patientOnStretcher
                            patientOnStretcher = nil
                            Wait(300)
                        elseif IsControlJustReleased(0, 74) then -- [H]
                            DetachEntity(currentStretcher, true, true)
                            ClearPedTasks(playerPed)
                            PlaceObjectOnGroundProperly(currentStretcher)
                            FreezeEntityPosition(currentStretcher, true)
                            usingStretcher = false
                            hidePrompt()
                        end
                    else
                        showPrompt('[G] - ' .. locale('put_stretcher') .. '  |  [H] - ' .. locale('control_drop_stretcher'))

                        if IsControlJustReleased(0, 47) then -- [G]
                            local maxStretchers = getAmbulanceStretchers()
                            if not Entity(closestVeh).state.stretcher then Entity(closestVeh).state.stretcher = maxStretchers end
                            if Entity(closestVeh).state.stretcher >= maxStretchers then
                                utils.showNotification(locale("stretcher_limit_reached"), "error")
                            else
                                Entity(closestVeh).state.stretcher += 1
                                toggleStretcher(false)
                                hidePrompt()
                            end
                            Wait(300)
                        elseif IsControlJustReleased(0, 74) then -- [H]
                            DetachEntity(currentStretcher, true, true)
                            ClearPedTasks(playerPed)
                            PlaceObjectOnGroundProperly(currentStretcher)
                            FreezeEntityPosition(currentStretcher, true)
                            usingStretcher = false
                            hidePrompt()
                        end
                    end
                else
                    showPrompt('[G] - ' .. locale('control_drop_stretcher'))

                    if IsControlJustReleased(0, 47) then -- [G]
                        DetachEntity(currentStretcher, true, true)
                        ClearPedTasks(playerPed)
                        PlaceObjectOnGroundProperly(currentStretcher)
                        FreezeEntityPosition(currentStretcher, true)
                        usingStretcher = false
                        hidePrompt()
                    end
                end

            elseif not cache.vehicle then
                local closestStretcher = GetClosestObjectOfType(playerCoords.x, playerCoords.y, playerCoords.z, 2.5, `prop_ld_binbag_01`, false)
                local closestVeh = vehiculoCercano(playerCoords, 3.5)

                if closestStretcher ~= 0 and DoesEntityExist(closestStretcher) and not IsEntityAttachedToEntity(closestStretcher, playerPed) then
                    sleep = 0
                    local sCoords = GetEntityCoords(closestStretcher)
                    local playerId, attachedPlayerPed = lib.getClosestPlayer(sCoords, 2.0, false)
                    local isPatientAttached = attachedPlayerPed and GetEntityAttachedTo(attachedPlayerPed) == closestStretcher
                    local keyLabel = getStretcherKeyLabel()

                    if isPatientAttached then
                        showPrompt('[' .. keyLabel .. '] - ' .. locale('take_stretcher') .. '  |  [G] - ' .. locale('remove_from_stretcher'))

                        if IsControlJustReleased(0, 47) then -- [G]
                            putOnStretcher(false, attachedPlayerPed)
                            Wait(300)
                        end
                    else
                        showPrompt('[' .. keyLabel .. '] - ' .. locale('take_stretcher'))
                    end

                elseif closestVeh and isEmsVehicle(closestVeh) then
                    sleep = 0
                    local hasPatientInside = Entity(closestVeh).state?.patient
                    local keyLabel = getStretcherKeyLabel()

                    if hasPatientInside then
                        showPrompt('[' .. keyLabel .. '] - ' .. locale('take_stretcher') .. '  |  [G] - ' .. locale('take_patient_from_vehicle'))

                        if IsControlJustReleased(0, 47) then -- [G]
                            local pTarget = Entity(closestVeh).state?.patient
                            local dataToSend = {}
                            dataToSend.target = GetPlayerServerId(NetworkGetPlayerIndexFromPed(pTarget))
                            TriggerServerEvent('origen_ambulancejob:togglePatientFromVehicle', dataToSend)

                            Wait(250)
                            toggleStretcher(true)
                            putOnStretcher(true, pTarget)
                            Entity(closestVeh).state.patient = nil
                            hidePrompt()
                        end
                    else
                        showPrompt('[' .. keyLabel .. '] - ' .. locale('take_stretcher'))
                    end
                else
                    hidePrompt()
                end
            else
                hidePrompt()
            end
        else
            hidePrompt()
        end

        if not esSanitario then sleep = 1500 end
        Wait(sleep)
    end
end)

exports("isUsingStretcher", function()
    return usingStretcher
end)

exports("toggleStretcher", toggleStretcher)
exports("putOnStretcher", putOnStretcher)
