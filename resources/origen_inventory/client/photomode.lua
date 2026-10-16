PhotoMode = {}

PhotoMode.IsActive = false
PhotoMode.InSettings = false
PhotoMode.Cam = nil
PhotoMode.Settings = {
    useStopTime = false,
    useSmartDof = false,
    nearDofValue = 1.0,
    farDofValue = 1.0,
    useTimeControl = false,
    timeControl = 12.0,
    rotation = 0.0,
}

--[[ Lo que cada uno deja puesto se le queda (12/10): se guarda en su equipo
     y al abrir el modo sale como lo dejo. De serie, sin camara lenta y sin
     desenfoque. La hora y el angulo no: son de cada foto. ]]
local KVP_AJUSTES = 'origen_inventory:photomode'
local GUARDADOS = { useStopTime = 'boolean', useSmartDof = 'boolean', nearDofValue = 'number', farDofValue = 'number' }

do
    local ok, guardado = pcall(json.decode, GetResourceKvpString(KVP_AJUSTES) or '')
    if ok and type(guardado) == 'table' then
        for clave, tipo in pairs(GUARDADOS) do
            if type(guardado[clave]) == tipo then
                PhotoMode.Settings[clave] = tipo == 'number' and guardado[clave] + 0.0 or guardado[clave]
            end
        end
    end
end

local function GuardarAjustes()
    local datos = {}
    for clave in pairs(GUARDADOS) do datos[clave] = PhotoMode.Settings[clave] end
    SetResourceKvp(KVP_AJUSTES, json.encode(datos))
end

local hintsVisible = true
local isTakingPhoto = false

local function TakePhoto()
    if isTakingPhoto then return end
    isTakingPhoto = true
    InventoryUI.Emit({ action = 'photomode_ui_visibility', visible = false })
    CreateThread(function()
        Wait(200)
        -- La hace el servidor (server/photomode.lua) y la guarda en la galeria
        -- de origen_phone. La interfaz sigue escondida hasta que termina.
        local res = lib.callback.await('origen_inventory:photomode:capture', false) or {}
        InventoryUI.Emit({ action = 'photomode_ui_visibility', visible = true })
        InventoryUI.Emit({ action = 'photomode_photo_result', success = res.ok == true, message = res.message })
        isTakingPhoto = false
    end)
end

RegisterCommand('photomode_togglehints', function()
    if not PhotoMode.IsActive or PhotoMode.InSettings then return end
    hintsVisible = not hintsVisible
    InventoryUI.Emit({ action = 'photomode_togglehints', visible = hintsVisible })
end, false)
RegisterKeyMapping('photomode_togglehints', 'Modo foto: mostrar u ocultar la ayuda', 'keyboard', 'h')

local MaxDistance = 20.0

local function RotationToDirection(rot)
    local radZ = math.rad(rot.z)
    local radX = math.rad(rot.x)
    local num = math.abs(math.cos(radX))
    return vector3(-math.sin(radZ) * num, math.cos(radZ) * num, math.sin(radX))
end

local function CrossProduct(v1, v2)
    return vector3(
        v1.y * v2.z - v1.z * v2.y,
        v1.z * v2.x - v1.x * v2.z,
        v1.x * v2.y - v1.y * v2.x
    )
end

local function HandleSmartDof()
    if not PhotoMode.Cam then return end
    local pPed = PlayerPedId()
    local camPos = GetCamCoord(PhotoMode.Cam)
    local entityPos = GetEntityCoords(pPed)
    local dist = #(camPos - entityPos)
    local nearDof = dist - PhotoMode.Settings.nearDofValue
    local farDof = dist + PhotoMode.Settings.farDofValue
    SetUseHiDof()
    SetCamNearDof(PhotoMode.Cam, nearDof)
    SetCamFarDof(PhotoMode.Cam, farDof)
    SetCamUseShallowDofMode(PhotoMode.Cam, true)
    SetCamDofStrength(PhotoMode.Cam, 1.0)
    SetCamDofMaxNearInFocusDistanceBlendLevel(PhotoMode.Cam, nearDof)
    SetCamDofMaxNearInFocusDistance(PhotoMode.Cam, nearDof)
    SetCamDofFocusDistanceBias(PhotoMode.Cam, farDof)
end

local function BlockControls()
    DisableControlAction(0, 30, true)
    DisableControlAction(0, 31, true)
    DisableControlAction(0, 32, true)
    DisableControlAction(0, 33, true)
    DisableControlAction(0, 34, true)
    DisableControlAction(0, 35, true)
    DisableControlAction(0, 24, true)
    DisableControlAction(0, 25, true)
end

local function EnterSettingsMode()
    PhotoMode.InSettings = true
    SetNuiFocus(true, true)
    InventoryUI.Emit({ action = 'photomode_settingsmode', active = true })
end

local function ExitSettingsMode()
    PhotoMode.InSettings = false
    SetNuiFocus(false, false)
    InventoryUI.Emit({ action = 'photomode_settingsmode', active = false })
end

--[[ La voz sigue viva en el modo foto (27/09). Antes se apagaba entera
     (NetworkSetVoiceActive) por miedo a espiar con la camara, pero no hace
     falta:
       - Los demas te oyen desde tu PJ, no desde la camara: con
         voice_useNativeAudio la voz va pegada al ped, y pma-voice elige a
         quien le llega con GetEntityCoords(ped) (proximity.lua).
       - Con una camara de script pma-voice se pondria a escuchar a TODO el
         servidor (modo espectador), pero voice_disableAutomaticListenerOnCamera
         esta a 1 en cfg/voice.cfg. Si alguien lo quita, el modo foto vuelve a
         ser un microfono para espiar: dejarlo a 1.
       - Y tu oyes lo que tiene al lado tu PJ, no la camara: el juego pone el
         oido en la camara, asi que pma-voice (setListenFromPed, al final de
         client/init/main.lua) fuerza el volumen de cada uno por su distancia
         a tu ped mientras dura el modo. ]]
local function OirDesdePed(activo)
    if GetResourceState('pma-voice') ~= 'started' then return end
    pcall(function() exports['pma-voice']:setListenFromPed(activo) end)
end

function PhotoMode.Start()
    if PhotoMode.IsActive then return end
    -- La salida anterior aun esta soltando su camara (medio segundo): con la
    -- tecla se puede volver a entrar antes y se llevaria por delante la nueva.
    if PhotoMode.Cam then return end

    if Player and Player.isOpen then
        Player:CloseInventory()
        Wait(100)
    end

    local camPos = GetFinalRenderedCamCoord()
    local camRot = GetGameplayCamRot(2)
    local camFov = GetGameplayCamFov()

    PhotoMode.Settings.rotation = camRot.y
    PhotoMode.Settings.timeControl = GetClockHours()

    PhotoMode.Cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', false)
    SetCamCoord(PhotoMode.Cam, camPos.x, camPos.y, camPos.z)
    SetCamRot(PhotoMode.Cam, camRot.x, camRot.y, camRot.z, 2)
    SetCamFov(PhotoMode.Cam, camFov + 0.0)
    SetCamActive(PhotoMode.Cam, true)
    RenderScriptCams(true, false, 0, true, false)

    if PhotoMode.Settings.useStopTime then SetTimeScale(0.0) end
    DisplayHud(false)
    DisplayRadar(false)
    OirDesdePed(true)

    SetNuiFocus(false, false)
    PhotoMode.IsActive = true
    PhotoMode.InSettings = false

    InventoryUI.Emit({
        action = 'photomode_open',
        settings = PhotoMode.Settings,
    })

    local fovTarget = camFov
    local fovActual = camFov
    local rotTarget = camRot.y
    local lastRot = camRot

    CreateThread(function()
        while PhotoMode.IsActive do
            local pPed = PlayerPedId()

            if not PhotoMode.InSettings then
                BlockControls()

                if IsControlJustPressed(0, 241) then
                    local scale = fovTarget / 20.0
                    fovTarget = math.max(fovTarget - scale, 1.0)
                elseif IsControlJustPressed(0, 242) then
                    local scale = fovTarget / 20.0
                    fovTarget = math.min(fovTarget + scale, 120.0)
                end

                local mouseX = GetControlNormal(0, 1)
                local mouseY = GetControlNormal(0, 2)
                local currentFov = GetCamFov(PhotoMode.Cam)
                local scaleFactor = currentFov / 40.0

                local slow = IsDisabledControlPressed(0, 21) and 0.25 or 1.0
                local moveSpeed = 0.1 * slow

                local pos = GetCamCoord(PhotoMode.Cam)
                local rot = GetCamRot(PhotoMode.Cam, 2)
                local forward = RotationToDirection(rot)
                local up = vector3(0.0, 0.0, 1.0)
                local right = CrossProduct(forward, up)

                if IsDisabledControlPressed(0, 32) then pos = pos + forward * moveSpeed end
                if IsDisabledControlPressed(0, 33) then pos = pos - forward * moveSpeed end
                if IsDisabledControlPressed(0, 34) then pos = pos - right * moveSpeed end
                if IsDisabledControlPressed(0, 35) then pos = pos + right * moveSpeed end

                local pPos = GetEntityCoords(pPed)
                local dist = #(pos - pPos)
                if dist > MaxDistance then
                    local dir = (pos - pPos) / dist
                    pos = pPos + dir * MaxDistance
                end

                SetCamCoord(PhotoMode.Cam, pos.x, pos.y, pos.z)

                if not IsDisabledControlPressed(0, 24) then
                    rot = vector3(
                        rot.x - mouseY * 5.0 * scaleFactor * slow,
                        rot.y,
                        rot.z - mouseX * 5.0 * scaleFactor * slow
                    )
                end

                if IsControlJustPressed(0, 174) then
                    PhotoMode.Settings.rotation = PhotoMode.Settings.rotation - 3.5
                end
                if IsControlJustPressed(0, 175) then
                    PhotoMode.Settings.rotation = PhotoMode.Settings.rotation + 3.5
                end

                lastRot = rot

                if IsControlJustReleased(0, 38) then
                    EnterSettingsMode()
                end

                if IsDisabledControlJustPressed(0, 23) then
                    TakePhoto()
                end

                if IsDisabledControlJustReleased(0, 194) or IsDisabledControlJustReleased(0, 200) then
                    PhotoMode.Stop()
                end
            end

            rotTarget = rotTarget + ((PhotoMode.Settings.rotation - rotTarget) * 0.1)
            SetCamRot(PhotoMode.Cam, lastRot.x, rotTarget, lastRot.z, 2)

            fovActual = fovActual + ((fovTarget - fovActual) * 0.1)
            local fovToSet = fovActual
            if fovToSet % 1 == 0 then fovToSet = fovToSet + 0.0 end
            SetCamFov(PhotoMode.Cam, fovToSet)

            if PhotoMode.Settings.useSmartDof then
                HandleSmartDof()
            end

            if PhotoMode.Settings.useStopTime then
                SetTimeScale(0.0)
            else
                SetTimeScale(1.0)
            end

            if PhotoMode.Settings.useTimeControl then
                NetworkOverrideClockTime(math.floor(PhotoMode.Settings.timeControl), 0, 0)
            end

            Wait(1)
        end

        SetTimeScale(1.0)
        SetNuiFocus(false, false)

        if PhotoMode.Cam then
            SetCamActive(PhotoMode.Cam, false)
            RenderScriptCams(false, true, 500, true, false)
            Wait(500)
            DestroyCam(PhotoMode.Cam, false)
            PhotoMode.Cam = nil
        end

        DisplayHud(true)
        if cache.vehicle then DisplayRadar(true) end
    end)
end

function PhotoMode.Stop()
    if not PhotoMode.IsActive then return end
    PhotoMode.IsActive = false
    PhotoMode.InSettings = false
    SetNuiFocus(false, false)
    OirDesdePed(false)
    InventoryUI.Emit({ action = 'photomode_close' })
end

--[[ Tecla propia, sin ninguna puesta de serie: cada uno la elige en
     Ajustes > Asignaciones de teclas > FiveM > «Modo Foto - Abrir/Cerrar».
     Sin default a proposito: cualquier tecla libre hoy puede dejar de
     estarlo, y el default solo se aplica la primera vez que el perfil lo ve
     (ver TECLAS_VIEJAS en f_origen_accesos.lua).
     Con los ajustes del modo abiertos no llega (la NUI tiene el foco); para
     salir de ahi, E o Escape como siempre. ]]
RegisterCommand('photomode_toggle', function()
    if PhotoMode.IsActive then
        if not PhotoMode.InSettings then PhotoMode.Stop() end
        return
    end
    if IsPauseMenuActive() or IsNuiFocused() then return end
    local ped = PlayerPedId()
    if IsEntityDead(ped) or IsPedCuffed(ped) or LocalPlayer.state.isDead then return end
    CreateThread(PhotoMode.Start)
end, false)
RegisterKeyMapping('photomode_toggle', 'Modo foto: abrir o cerrar', 'keyboard', '')

RegisterNuiCallback('photomode_setting', function(data, cb)
    if data and data.key and PhotoMode.Settings[data.key] ~= nil then
        PhotoMode.Settings[data.key] = data.value
        if data.key == 'useSmartDof' and not data.value and PhotoMode.Cam then
            SetCamUseShallowDofMode(PhotoMode.Cam, false)
        end
        if GUARDADOS[data.key] then GuardarAjustes() end
    end
    cb(true)
end)

RegisterNuiCallback('photomode_settingsclose', function(_, cb)
    ExitSettingsMode()
    cb(true)
end)

RegisterNuiCallback('photomode_close', function(_, cb)
    PhotoMode.Stop()
    cb(true)
end)
