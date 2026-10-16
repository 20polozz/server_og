local usingcamera = false
RegisterNetEvent("origen_police:client:usecamera", function(data, hour, webhook)
    if IsPedInAnyVehicle(PlayerPedId(), false) then return end
        usingcamera = true
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
			RenderScriptCams(true, true, 2000, true, false)
            TaskStartScenarioInPlace(ped,"WORLD_HUMAN_PAPARAZZI", 0, 1)
            DisplayRadar(false)
            -- Por el visor no se ve el HUD: fuera el minimapa (origen_map), el
            -- HUD y la caja de misiones mientras la camara esta abierta.
            local function FueraHud(fuera)
                TriggerEvent('qv2:suppressHud', fuera)
                pcall(function() exports.origen_hud:toggleHud(not fuera) end)
                if GetResourceState('origen_map') == 'started' then
                    pcall(function() exports.origen_map:Apartar(fuera) end)
                end
            end
            FueraHud(true)
            local lst = GetGameTimer()
            Wait(2000)
            SetTimecycleModifier("helicamfirst")
            SetTimecycleModifierStrength(0.85)
            local street = GetStreetNameFromHashKey(GetStreetNameAtCoord(camcoords.x, camcoords.y, camcoords.z))
            local notify = false
            
            -- Las evidencias se ven con sus placas mientras la cámara está
            -- abierta (client/evidencias.lua).
            -- Controles oficiales Origen HUD
            pcall(function()
                exports.origen_hud:setupControls({
                    { key = 'E', text = 'Hacer foto' },
                    { key = 'WHEEL', text = 'Zoom' },
                    { key = 'ESCAPE', text = 'Cancelar' }
                })
            end)
            -- 12/10: aqui se pintaba ADEMAS la barra propia de la interfaz de
            -- policia («Camara de Evidencias»), encima de la de origen_hud: dos
            -- barras de teclas pisandose. Se queda la del HUD, que trae las tres.

            local isUploading = false
            local uploadStartTime = 0

            while usingcamera do
                Wait(0)

                -- Evidence rendering moved to a separate thread
                if not isUploading then
                    fov = HandleZoom(cam, fov, min_fov)
                    CheckInputRotation(cam, fov)
                end

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

                if hour then
                    -- Arriba: abajo quedaba debajo de la barra de teclas.
                    Draw2DText(0.5, 0.03, street .. " · " .. hour, 0.7)
                end

                if IsDisabledControlJustPressed(0, 38) and GetGameTimer() - lst > 2000 and not isUploading then
                    lst = GetGameTimer()
                    isUploading = true
                    uploadStartTime = GetGameTimer()

                    -- Ocultar controles durante la captura
                    pcall(function() exports.origen_hud:hideControls() end)
                    SendNUIMessage({ action = "setCameraControls", active = false })

                    --[[ Evento LOCAL: se ha hecho una foto, desde donde, hacia
                         donde y con que zoom. Lo escucha origen_mision para saber
                         si en la foto sale lo que hay que fotografiar (el cuerpo,
                         la matricula); si no lo escucha nadie, no pasa nada. ]]
                    TriggerEvent('origen_police:camara:foto', GetCamCoord(cam), GetCamRot(cam, 2), fov)

                    CreateThread(function()
                        Wait(120)
                        while isUploading do
                            local elapsed = (GetGameTimer() - uploadStartTime) / 1000.0
                            SendNUIMessage({
                                action = "cameraUploadProgress",
                                visible = true,
                                status = "subiendo",
                                elapsed = elapsed,
                                title = "SUBIENDO EVIDENCIA",
                                message = "Procesando fotografía policial..."
                            })
                            Wait(50)
                        end
                    end)

                    CreateThread(function()
                        local photoUrl = TakePhoto(webhook)
                        local totalElapsed = (GetGameTimer() - uploadStartTime) / 1000.0
                        if photoUrl then
                            SendNUIMessage({
                                action = "cameraUploadProgress",
                                visible = true,
                                status = "completado",
                                elapsed = totalElapsed,
                                title = "EVIDENCIA GUARDADA",
                                message = "Fotografía guardada en tu inventario"
                            })
                            TriggerServerEvent("origen_police:server:savephoto", photoUrl)
                            Wait(600)
                            isUploading = false
                            SendNUIMessage({ action = "cameraUploadProgress", visible = false })
                            usingcamera = false
                            if GetResourceState("origen_notify") == "started" then
                                exports.origen_notify:Notify({
                                    title = "FOTOGRAFÍA POLICIAL",
                                    description = "Fotografía guardada en tu inventario.",
                                    type = "success",
                                    duration = 4000
                                })
                            else
                                ShowNotification("Fotografía guardada en tu inventario.", "success")
                            end
                        else
                            SendNUIMessage({
                                action = "cameraUploadProgress",
                                visible = true,
                                status = "error",
                                elapsed = totalElapsed,
                                title = "ERROR AL SUBIR",
                                message = "Error al procesar la fotografía"
                            })
                            Wait(1000)
                            isUploading = false
                            SendNUIMessage({ action = "cameraUploadProgress", visible = false })
                            usingcamera = false
                            if GetResourceState("origen_notify") == "started" then
                                exports.origen_notify:Notify({
                                    title = "FOTOGRAFÍA POLICIAL",
                                    description = "Error al procesar la fotografía.",
                                    type = "error",
                                    duration = 4500
                                })
                            else
                                ShowNotification("Error al procesar la fotografía.", "error")
                            end
                        end
                    end)
                end
                if IsDisabledControlJustPressed(0, 177) and not isUploading then
                    pcall(function() exports.origen_hud:hideControls() end)
                    SendNUIMessage({ action = "setCameraControls", active = false })
                    SendNUIMessage({ action = "cameraUploadProgress", visible = false })
                    usingcamera = false
                end
            end
            pcall(function() exports.origen_hud:hideControls() end)
            SendNUIMessage({ action = "setCameraControls", active = false })
            SendNUIMessage({ action = "cameraUploadProgress", visible = false })
            HideHelpNotification()
            if EvidenciasModoFoto then EvidenciasModoFoto(false) end
            ClearTimecycleModifier()
            DisplayRadar(radar)
            FueraHud(false)
            if GetResourceState('pma-voice') == 'started' then
                pcall(function() exports['pma-voice']:setListenFromPed(false) end)
            end
            ClearPedTasks(ped)
            SetCamActive(cam, false)
            DestroyCam(cam, true)
            RenderScriptCams(false, true, 2000, true, false)
        end)
end)

--[[ Si el recurso se para con la camara abierta (un restart), el bucle muere
     sin llegar a su limpieza y el jugador se queda con la pose, el filtro y
     la barra de teclas puestos y sin forma de salir (12/10). ]]
AddEventHandler("onResourceStop", function(recurso)
    if recurso ~= GetCurrentResourceName() or not usingcamera then return end
    usingcamera = false
    ClearPedTasksImmediately(PlayerPedId())
    ClearTimecycleModifier()
    RenderScriptCams(false, false, 0, true, false)
    DisplayRadar(true)
    pcall(function() exports.origen_hud:hideControls() end)
    pcall(function() exports.origen_hud:toggleHud(true) end)
    TriggerEvent("qv2:suppressHud", false)
    if GetResourceState("origen_map") == "started" then
        pcall(function() exports.origen_map:Apartar(false) end)
    end
    if GetResourceState("pma-voice") == "started" then
        pcall(function() exports["pma-voice"]:setListenFromPed(false) end)
    end
end)

RegisterNetEvent("origen_police:client:showphoto", function(url)
    if not url then
        print("[origen_police] No photo url received")
        return
    end
    SendNUIMessage({
        action = "showphoto",
        url = url
    })
    SetNuiFocus(true, true)
end)

RegisterNUICallback("closePhoto", function(data, cb)
    -- Con el panel F7 debajo se le devuelve el raton en vez de soltarlo y
    -- dejarlo a la vista sin cursor; ver DevolverFocoTrasCapa.
    DevolverFocoTrasCapa()
    cb(true)
end)

-- Raton soltado a la fuerza: la foto se quita de la vista, o se quedaria
-- tapando la pantalla sin cursor para cerrarla. Sin foto, no hace nada.
if OrigenFoco and OrigenFoco.AlSoltar then
    OrigenFoco.AlSoltar(function()
        SendNUIMessage({ action = "showphoto" })
    end)
end

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

function Draw2DText(x, y, text, scale)
    SetTextFont(4)
    SetTextProportional(7)
    SetTextScale(scale, scale)
    SetTextColour(255, 255, 255, 255)
    SetTextEdge(4, 0, 0, 0, 255)
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
    local factor = (string.len(text)) / 270
    DrawRect(x, y + 0.025, 0.095 + factor, 0.05, 0, 0, 0, 155)
end

if Config.DebugRestrictZones then
    CreateThread(function()
        while true do
            local playerCoords = GetEntityCoords(PlayerPedId())
            for n = 1, #Config.RestrictedAlertZones do
                local inside = isInside(Config.RestrictedAlertZones[n], playerCoords.x, playerCoords.y)
                for i = 1, #Config.RestrictedAlertZones[n] do
                    local current = Config.RestrictedAlertZones[n][i]
                    local previous = Config.RestrictedAlertZones[n][i-1]
                    Draw3DText(current[1], current[2], playerCoords.z, 0.7, i)
                    DrawLine(current[1], current[2], -10.0, current[1], current[2], 100.0, 255.0, 0.0, 0.0, 255)
                    local wallColor = inside and {0, 255, 0, 100} or {255, 0, 0, 100}
                    if previous then
                        DrawLine(current[1], current[2], 100.0, previous[1], previous[2], 100.0, 255.0, 0.0, 0.0, 255)
                        DrawWall(vector3(current[1], current[2], 0.0), vector3(previous[1], previous[2], 0.0), -10.0, 100.0, table.unpack(wallColor))
                    else
                        DrawLine(current[1], current[2], 100.0, Config.RestrictedAlertZones[n][#Config.RestrictedAlertZones[n]][1], Config.RestrictedAlertZones[n][#Config.RestrictedAlertZones[n]][2], 100.0, 255.0, 0.0, 0.0, 255)
                        DrawWall(vector3(current[1], current[2], 0.0), vector3(Config.RestrictedAlertZones[n][#Config.RestrictedAlertZones[n]][1], Config.RestrictedAlertZones[n][#Config.RestrictedAlertZones[n]][2], 0.0), -10.0, 100.0, table.unpack(wallColor))
                    end
                end
            end
            
            Wait(0)
        end
    end)
end