-- ============================================================
-- ORIGEN POLICE - VEHICLE FINGERPRINTS SYSTEM (CLIENT)
-- ============================================================

local maleNoGloves = {
    [0] = true, [1] = true, [2] = true, [3] = true, [4] = true, [5] = true, [6] = true, [7] = true,
    [8] = true, [9] = true, [10] = true, [11] = true, [12] = true, [13] = true, [14] = true, [15] = true,
    [18] = true, [26] = true, [52] = true, [53] = true, [54] = true, [55] = true, [56] = true, [57] = true,
    [58] = true, [59] = true, [60] = true, [61] = true, [62] = true, [112] = true, [113] = true, [114] = true,
    [118] = true, [125] = true, [132] = true
}

local femaleNoGloves = {
    [0] = true, [1] = true, [2] = true, [3] = true, [4] = true, [5] = true, [6] = true, [7] = true,
    [8] = true, [9] = true, [10] = true, [11] = true, [12] = true, [13] = true, [14] = true, [15] = true,
    [19] = true, [59] = true, [60] = true, [61] = true, [62] = true, [63] = true, [64] = true, [65] = true,
    [66] = true, [67] = true, [68] = true, [69] = true, [70] = true, [71] = true, [129] = true, [130] = true,
    [131] = true, [135] = true, [142] = true, [149] = true, [153] = true, [157] = true, [161] = true, [165] = true
}

--- Comprueba si el ped especificado lleva guantes puestos
---@param ped number
---@return boolean
local function IsPedWearingGloves(ped)
    local model = GetEntityModel(ped)
    local isMale = (model == `mp_m_freemode_01`)
    local armIndex = GetPedDrawableVariation(ped, 3)

    local list = isMale and maleNoGloves or femaleNoGloves
    return not (list[armIndex] == true)
end

-- ============================================================
-- DRIVER TRACKING THREAD
-- ============================================================
CreateThread(function()
    local lastVeh = 0
    local lastPlate = nil
    local lastGloveCheck = 0
    local lastHadGloves = nil

    while true do
        local sleep = 1000
        local ped = PlayerPedId()

        if IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)
            if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
                sleep = 500
                local now = GetGameTimer()
                local rawPlate = GetVehicleNumberPlateText(veh)
                local plate = rawPlate and rawPlate:gsub("^%s*(.-)%s*$", "%1"):upper() or ""

                if veh ~= lastVeh or plate ~= lastPlate or (now - lastGloveCheck > 8000) then
                    lastVeh = veh
                    lastPlate = plate
                    lastGloveCheck = now

                    local wearsGloves = IsPedWearingGloves(ped)
                    if wearsGloves ~= lastHadGloves or (now - lastGloveCheck > 8000) then
                        lastHadGloves = wearsGloves
                        local modelHash = GetEntityModel(veh)
                        local modelName = (Config.CustomCarLabels and Config.CustomCarLabels[modelHash])
                            or GetLabelText(GetDisplayNameFromVehicleModel(modelHash))
                        if modelName == "NULL" or not modelName or modelName == "" then
                            modelName = GetDisplayNameFromVehicleModel(modelHash)
                        end

                        TriggerServerEvent("origen_police:server:recordVehicleDriver", plate, modelName, wearsGloves)
                    end
                end
            else
                if lastVeh ~= 0 then
                    lastVeh = 0
                    lastPlate = nil
                    lastHadGloves = nil
                end
            end
        else
            if lastVeh ~= 0 then
                lastVeh = 0
                lastPlate = nil
                lastHadGloves = nil
            end
        end

        Wait(sleep)
    end
end)

-- ============================================================
-- VEHICLE FINGERPRINT INSPECTION POINT HANDLER
-- ============================================================
RegisterNetEvent("origen_police:client:inspectVehicleFingerprints", function(mapIndex, markerIndex, stationName)
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        ShowNotification("Debes estar subido como conductor en el vehículo que deseas inspeccionar.", "error")
        return
    end

    local veh = GetVehiclePedIsIn(ped, false)
    if GetPedInVehicleSeat(veh, -1) ~= ped then
        ShowNotification("Debes situarte en el asiento del conductor para tomar las muestras del volante.", "error")
        return
    end

    if GetEntitySpeed(veh) > 1.0 then
        ShowNotification("Detén completamente el vehículo antes de iniciar la inspección.", "error")
        return
    end

    local rawPlate = GetVehicleNumberPlateText(veh)
    if not rawPlate or rawPlate == "" then
        ShowNotification("No se puede identificar la matrícula del vehículo.", "error")
        return
    end
    local plate = rawPlate:gsub("^%s*(.-)%s*$", "%1"):upper()

    local modelHash = GetEntityModel(veh)
    local modelName = (Config.CustomCarLabels and Config.CustomCarLabels[modelHash])
        or GetLabelText(GetDisplayNameFromVehicleModel(modelHash))
    if modelName == "NULL" or not modelName or modelName == "" then
        modelName = GetDisplayNameFromVehicleModel(modelHash)
    end

    FreezeEntityPosition(veh, true)
    SetVehicleHandbrake(veh, true)

    local success = true
    if lib and lib.progressBar then
        success = lib.progressBar({
            duration = 15000,
            label = "Inspeccionando huellas del vehículo (15s)...",
            canCancel = true,
            disable = {
                move = true,
                car = true,
                combat = true
            },
            anim = {
                dict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@",
                clip = "machinic_loop_mechandplayer",
                flag = 49
            }
        })
    else
        local endTime = GetGameTimer() + 15000
        while GetGameTimer() < endTime do
            Wait(100)
        end
    end

    FreezeEntityPosition(veh, false)
    SetVehicleHandbrake(veh, false)
    ClearPedTasks(ped)

    if not success then
        ShowNotification("Inspección dactilar cancelada.", "error")
        return
    end

    TriggerServerEvent("origen_police:server:processVehicleFingerprints", plate, modelName)
end)
