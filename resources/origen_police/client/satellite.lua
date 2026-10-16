local isSatelliteActive = false
local satCam = nil
local currentFilter = 1
local filterText = "NORMAL"

-- Get street name at clicked map coordinates (NUI callback)
RegisterNUICallback("GetLocationDetails", function(data, cb)
    local x = tonumber(data.x)
    local y = tonumber(data.y)
    if not x or not y then 
        return cb({ street = "Desconocido" }) 
    end

    local streetHash, crossingRoad = GetStreetNameAtCoord(x, y, 0.0)
    local streetName = "Zona Desconocida"
    if streetHash and streetHash ~= 0 then
        streetName = GetStreetNameFromHashKey(streetHash)
    end
    cb({ street = streetName })
end)

-- Function to apply satellite filters
local function ApplySatelliteFilter(id)
    SetNightvision(false)
    SetSeethrough(false)
    ClearTimecycleModifier()
    
    if id == 1 then
        filterText = "NORMAL"
    elseif id == 2 then
        -- Thermal Vision
        SetNightvision(true)
        SetSeethrough(true)
        filterText = "TERMICO"
    elseif id == 3 then
        -- Night Vision
        SetNightvision(true)
        SetSeethrough(false)
        filterText = "VISION NOCTURNA"
    elseif id == 4 then
        -- High Contrast Digital Filter
        SetTimecycleModifier("helicamfirst")
        SetTimecycleModifierStrength(0.75)
        filterText = "DIGITAL"
    end
end

local function CanUseSatellite()
    local PlayerData = FW_GetPlayerData()
    if not PlayerData or not PlayerData.job then return false end
    if PlayerData.job.name == "sapd" then return true end

    local jobName = PlayerData.job.name
    local perms = Config.Permissions and Config.Permissions[jobName]
    if not perms and Config.Permissions then
        for k, v in pairs(Config.Permissions) do
            if string.lower(tostring(k)) == string.lower(tostring(jobName)) then
                perms = v
                break
            end
        end
    end
    if not perms then
        perms = Config.Permissions and (Config.Permissions.police or Config.Permissions[Config.PoliceJobName])
    end

    if not perms or perms.SeeSatelliteCamera == nil then
        return false
    end

    local playerGrade = (type(PlayerData.job.grade) == "table" and PlayerData.job.grade.level) or PlayerData.job.grade or 0
    return tonumber(playerGrade) >= tonumber(perms.SeeSatelliteCamera)
end

-- Start satellite camera sequence (NUI callback)
RegisterNUICallback("StartSatelliteView", function(data, cb)
    if not CanUseSatellite() then
        cb(false)
        pcall(function()
            exports['origen_notify']:Notify({
                title = 'Satélite',
                description = (Config.Translations and Config.Translations.NoPermissionSatellite) or 'No tienes permisos para usar la vigilancia satelital',
                type = 'error',
                duration = 3500
            })
        end)
        return
    end

    local x = tonumber(data.x)
    local y = tonumber(data.y)
    
    if not x or not y then 
        cb(false)
        return 
    end

    if isSatelliteActive then
        cb(false)
        return
    end

    isSatelliteActive = true
    cb(true)

    CreateThread(function()
        DoScreenFadeOut(300)
        Wait(400)

        -- Freeze player and vehicle to prevent movement during satellite surveillance
        local ped = PlayerPedId()
        local parentVehicle = GetVehiclePedIsIn(ped, false)
        FreezeEntityPosition(ped, true)
        if parentVehicle and parentVehicle ~= 0 then
            FreezeEntityPosition(parentVehicle, true)
        end

        -- Determine initial heights
        local initialGroundZ = 0.0
        local retval, z = GetGroundZFor_3dCoord(x, y, 1000.0, false)
        if retval then
            initialGroundZ = z
        end

        local currentX = x
        local currentY = y
        local satHeight = 180.0
        local currentFov = 60.0

        -- Create start camera (orbit height)
        local camStart = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", currentX, currentY, initialGroundZ + 1000.0, -90.0, 0.0, 0.0, 75.0, true, 2)
        -- Create end camera (surveillance height)
        local camEnd = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", currentX, currentY, initialGroundZ + satHeight, -90.0, 0.0, 0.0, currentFov, true, 2)

        SetCamActive(camStart, true)
        RenderScriptCams(true, false, 0, true, true)
        SetFocusPosAndVel(currentX, currentY, initialGroundZ, 0.0, 0.0, 0.0)

        Wait(200)
        DoScreenFadeIn(300)
        
        -- High-tech transition sounds & smooth zoom interpolation
        PlaySoundFrontend(-1, "Camera_Connect", "DLC_HEIST_BIOLAB_SOUNDS", 1)
        SetCamActiveWithInterp(camEnd, camStart, 3000, 1, 1)

        -- Transition loop
        local startTimer = GetGameTimer()
        while GetGameTimer() - startTimer < 3000 do
            Wait(0)
            DisableAllControlActions(0)
        end

        -- Swap active camera and destroy temporary start camera
        satCam = camEnd
        DestroyCam(camStart, false)
        ApplySatelliteFilter(currentFilter)

        local lastHudUpdate = 0
        local displayedRadar = IsRadarHidden()

        while isSatelliteActive do
            Wait(0)
            
            -- Hide mini-map/radar
            DisplayRadar(false)

            -- Disable player controls to prevent ped/vehicle movement
            DisableControlAction(0, 30, true)  -- Move LR (Left/Right)
            DisableControlAction(0, 31, true)  -- Move UD (Up/Down)
            DisableControlAction(0, 32, true)  -- Move W (Forward)
            DisableControlAction(0, 33, true)  -- Move S (Backward)
            DisableControlAction(0, 34, true)  -- Move A (Left)
            DisableControlAction(0, 35, true)  -- Move D (Right)
            DisableControlAction(0, 1, true)   -- Look LR
            DisableControlAction(0, 2, true)   -- Look UD
            DisableControlAction(0, 220, true) -- Look LR
            DisableControlAction(0, 221, true) -- Look UD
            DisableControlAction(0, 71, true)  -- Vehicle Accelerate
            DisableControlAction(0, 72, true)  -- Vehicle Brake
            DisableControlAction(0, 73, true)  -- Vehicle Handbrake
            DisableControlAction(0, 59, true)  -- Vehicle Steering LR
            DisableControlAction(0, 60, true)  -- Vehicle Steering UD
            DisableControlAction(0, 75, true)  -- Vehicle Exit
            DisableControlAction(0, 80, true)  -- Vehicle Cinema Cam
            DisableControlAction(0, 86, true)  -- Vehicle Horn
            DisableControlAction(0, 81, true)  -- Vehicle Radio
            DisableControlAction(0, 85, true)  -- Vehicle Radio Wheel
            DisableControlAction(0, 347, true) -- Vehicle Fly Attack
            DisableControlAction(0, 24, true)  -- Attack
            DisableControlAction(0, 25, true)  -- Aim / Zoom in-game camera

            -- Keep focus loaded on current ground target
            local retval, groundZ = GetGroundZFor_3dCoord(currentX, currentY, 300.0, false)
            if not retval then
                retval, groundZ = GetGroundZFor_3dCoord(currentX, currentY, 1000.0, false)
            end
            if not retval then
                groundZ = initialGroundZ
            end
            SetFocusPosAndVel(currentX, currentY, groundZ, 0.0, 0.0, 0.0)

            -- Adjust FOV and height dynamically with Mouse Scroll (Hybrid Zoom)
            if IsControlPressed(0, 15) or IsDisabledControlPressed(0, 15) then -- Scroll Up (Zoom in)
                if satHeight > 180.0 then
                    satHeight = math.max(180.0, satHeight - 10.0)
                else
                    currentFov = math.max(2.0, currentFov - 1.5)
                end
            elseif IsControlPressed(0, 14) or IsDisabledControlPressed(0, 14) then -- Scroll Down (Zoom out)
                if currentFov < 120.0 then
                    currentFov = math.min(120.0, currentFov + 1.5)
                else
                    satHeight = math.min(800.0, satHeight + 10.0)
                end
            end

            -- Apply FOV zoom
            SetCamFov(satCam, currentFov)

            -- WASD panning speed scales with current FOV and camera height to keep controls responsive
            local panSpeed = (currentFov / 60.0) * 2.0 * (satHeight / 180.0)
            local forward = 0.0
            local right = 0.0

            if IsControlPressed(0, 32) or IsDisabledControlPressed(0, 32) then -- W
                forward = forward + panSpeed
            end
            if IsControlPressed(0, 33) or IsDisabledControlPressed(0, 33) then -- S
                forward = forward - panSpeed
            end
            if IsControlPressed(0, 34) or IsDisabledControlPressed(0, 34) then -- A
                right = right - panSpeed
            end
            if IsControlPressed(0, 35) or IsDisabledControlPressed(0, 35) then -- D
                right = right + panSpeed
            end

            currentX = currentX + right
            currentY = currentY + forward

            -- Set camera height dynamically, ensuring it stays at least 10m above ground to prevent clipping
            local targetZ = initialGroundZ + satHeight
            if targetZ < groundZ + 10.0 then
                targetZ = groundZ + 10.0
            end
            SetCamCoord(satCam, currentX, currentY, targetZ)

            -- Left Click (Attack / Cellphone Select / Cursor Accept) to send police dispatch alert (entorno)
            if IsControlJustPressed(0, 24) or IsDisabledControlJustPressed(0, 24) or 
               IsControlJustPressed(0, 176) or IsDisabledControlJustPressed(0, 176) or 
               IsControlJustPressed(0, 237) or IsDisabledControlJustPressed(0, 237) then
                
                PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
                
                local streetHash, crossingRoad = GetStreetNameAtCoord(currentX, currentY, groundZ)
                local streetName = "Zona Desconocida"
                if streetHash and streetHash ~= 0 then
                    streetName = GetStreetNameFromHashKey(streetHash)
                end

                TriggerServerEvent("SendAlert:police", {
                    coords = vector3(currentX, currentY, groundZ),
                    title = "Marcación Satélite",
                    type = "GENERAL",
                    message = "Posición marcada por el satélite SAPD-SAT-01 en " .. streetName,
                    job = {"police", "sheriff", "sapd"},
                    ignoreCooldown = true
                })

                TriggerEvent("origen_police:ShowNotification", "Posición enviada al despacho: " .. streetName, "success")
            end

            -- [E] Toggle Satellite Vision Filter
            if IsControlJustPressed(0, 38) or IsDisabledControlJustPressed(0, 38) then
                PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
                currentFilter = currentFilter + 1
                if currentFilter > 4 then
                    currentFilter = 1
                end
                ApplySatelliteFilter(currentFilter)
            end

            -- Exit satellite view (Backspace or Escape)
            if IsControlJustPressed(0, 177) or IsDisabledControlJustPressed(0, 177) or IsControlJustPressed(0, 200) then
                PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
                break
            end

            -- Update NUI HUD information (rate-limited)
            local now = GetGameTimer()
            if now - lastHudUpdate > 150 then
                lastHudUpdate = now
                local zoomMultiplier = string.format("%.1f", (85.0 / currentFov) * (180.0 / satHeight))
                
                local streetHash, crossingRoad = GetStreetNameAtCoord(currentX, currentY, groundZ)
                local streetName = "Zona Desconocida"
                if streetHash and streetHash ~= 0 then
                    streetName = GetStreetNameFromHashKey(streetHash)
                end

                SendNUIMessage({
                    action = "UpdateSatelliteHUD",
                    altitude = math.floor(targetZ - groundZ) .. "M",
                    zoom = zoomMultiplier .. "X",
                    filter = filterText,
                    coords = string.format("%.1f, %.1f", currentX, currentY)
                })
            end
        end

        -- Exit Sequence
        DoScreenFadeOut(300)
        Wait(400)

        isSatelliteActive = false
        SetCamActive(satCam, false)
        DestroyCam(satCam, true)
        RenderScriptCams(false, false, 0, true, false)
        satCam = nil

        ClearFocus()
        FreezeEntityPosition(ped, false)
        if parentVehicle and DoesEntityExist(parentVehicle) then
            FreezeEntityPosition(parentVehicle, false)
        end
        DisplayRadar(not displayedRadar)

        -- Clear active vision effects
        SetNightvision(false)
        SetSeethrough(false)
        ClearTimecycleModifier()

        -- Hide overlay in NUI
        SendNUIMessage({
            action = "StopSatelliteView"
        })

        Wait(300)
        DoScreenFadeIn(300)
    end)
end)
