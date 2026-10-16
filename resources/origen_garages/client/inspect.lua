local angleY = 0.0
local angleZ = 0.0
local cam = nil
local running = false
gEntity = nil
local gRadius = nil
local gRadiusMax = nil
local gRadiusMin = nil
local gFirstPersonEnabled = nil
local scaleform = nil
local scrollIncrements = nil
local isFirstPersonView = false

local function cos(degrees)
    return math.cos(math.rad(degrees))
end

local function sin(degrees)
    return math.sin(math.rad(degrees))
end

local function setCamPosition()
    local entityCoords = GetEntityCoords(gEntity)
    local mouseX = GetDisabledControlNormal(0, 1) * 8.0 -- 8x multiplier to make it more sensitive
    local mouseY = GetDisabledControlNormal(0, 2) * 8.0

    angleZ = angleZ - mouseX -- left / right
    angleY = angleY + mouseY -- up / down
    angleY = lib.math.clamp(angleY, 0.0, 89.0) -- >=90 degrees will flip the camera, < 0 is underground

    local cosAngleZ = cos(angleZ)
    local cosAngleY = cos(angleY)
    local sinAngleZ = sin(angleZ)
    local sinAngleY = sin(angleY)

    local offset = vec3(
        ((cosAngleZ * cosAngleY) + (cosAngleY * cosAngleZ)) / 2 * gRadius,
        ((sinAngleZ * cosAngleY) + (cosAngleY * sinAngleZ)) / 2 * gRadius,
        ((sinAngleY)) * gRadius
    )

    local camPos = vec3(entityCoords.x + offset.x, entityCoords.y + offset.y, entityCoords.z + offset.z)
    SetCamCoord(cam, camPos.x, camPos.y, camPos.z)
    PointCamAtCoord(cam, entityCoords.x, entityCoords.y, entityCoords.z + 0.5)
end

local function disablePlayerMovement()
    DisableControlAction(0, 21, true) -- INPUT_SPRINT | LEFT SHIFT
    DisableControlAction(0, 24, true) -- INPUT_ATTACK | LEFT MOUSE BUTTON
    DisableControlAction(0, 25, true) -- INPUT_AIM | RIGHT MOUSE BUTTON
    DisableControlAction(0, 30, true) -- INPUT_MOVE_LR | D
    DisableControlAction(0, 31, true) -- INPUT_MOVE_UD | S
    DisableControlAction(0, 36, true) -- INPUT_DUCK | LEFT CTRL
    DisableControlAction(0, 47, true) -- INPUT_DETONATE | G
    DisableControlAction(0, 58, true) -- INPUT_THROW_GRENADE | G
    DisableControlAction(0, 69, true) -- INPUT_VEH_ATTACK | LEFT MOUSE BUTTON
    DisableControlAction(0, 75, true) -- INPUT_VEH_EXIT | F
    DisableControlAction(0, 140, true) -- INPUT_MELEE_ATTACK_LIGHT | R
    DisableControlAction(0, 141, true) -- INPUT_MELEE_ATTACK_HEAVY | Q
    DisableControlAction(0, 142, true) -- INPUT_MELEE_ATTACK_ALTERNATE | LEFT MOUSE BUTTON
    DisableControlAction(0, 143, true) -- INPUT_MELEE_BLOCK | SPACEBAR
    DisableControlAction(0, 257, true) -- INPUT_ATTACK2 | LEFT MOUSE BUTTON
    DisableControlAction(0, 263, true) -- INPUT_MELEE_ATTACK1 | R
    DisableControlAction(0, 264, true) -- INPUT_MELEE_ATTACK2 | Q
end

local function disableCamMovement()
    DisableControlAction(0, 1, true) -- INPUT_LOOK_LR | MOUSE RIGHT
    DisableControlAction(0, 2, true) -- INPUT_LOOK_UD | MOUSE DOWN
    DisableControlAction(0, 3, true) -- INPUT_LOOK_UP_ONLY | (NONE)
    DisableControlAction(0, 4, true) -- INPUT_LOOK_DOWN_ONLY | MOUSE DOWN
    DisableControlAction(0, 5, true) -- INPUT_LOOK_LEFT_ONLY | (NONE)
    DisableControlAction(0, 6, true) -- INPUT_LOOK_RIGHT_ONLY | MOUSE RIGHT
    DisableControlAction(0, 12, true) -- INPUT_WEAPON_WHEEL_UD | MOUSE DOWN
    DisableControlAction(0, 13, true) -- INPUT_WEAPON_WHEEL_LR | MOUSE RIGHT
    DisableControlAction(0, 200, true) -- INPUT_FRONTEND_PAUSE_ALTERNATE | ESC
end

local function mouseDownListener()
    CreateThread(function()
        while running do
            setCamPosition()

            if IsDisabledControlJustReleased(0, 24) or IsControlJustReleased(0, 24) then
                SetMouseCursorSprite(3)
                return
            end

            Wait(0)
        end
    end)
end

local function inputListener()
    setCamPosition() -- Set initial cam position, otherwise cam will remain at player until first left click
    CreateThread(function()
        while running do
            DisableControlAction(0, 0, true) -- INPUT_NEXT_CAMERA | V
            -- ESC siempre, tambien en primera persona: sin esto abria el
            -- radial de origen_hud y al cerrarlo quedaban el cursor y la
            -- camara quieta, sin salir de la inspeccion.
            DisableControlAction(0, 200, true) -- INPUT_FRONTEND_PAUSE_ALTERNATE | ESC
            disablePlayerMovement()
            if not isFirstPersonView then
                SetMouseCursorActiveThisFrame()
                disableCamMovement()

                if IsDisabledControlJustPressed(0, 24) or IsControlJustPressed(0, 24) then
                    SetMouseCursorSprite(4)
                    mouseDownListener()
                end
            end

            if IsDisabledControlJustReleased(0, 14) or IsControlJustReleased(0, 14) then
                if gRadius + scrollIncrements <= gRadiusMax then
                    gRadius += scrollIncrements
                    setCamPosition()
                end
            elseif IsDisabledControlJustReleased(0, 15) or IsControlJustReleased(0, 15) then
                if gRadius - scrollIncrements >= gRadiusMin then
                    gRadius -= scrollIncrements
                    setCamPosition()
                end
            end

            if IsControlJustPressed(0, 22) or IsControlJustPressed(0, 22) then
                local doors = GetNumberOfVehicleDoors(gEntity)
                for i = 0, doors do
                    if GetVehicleDoorAngleRatio(gEntity, i) > 0 then
                        SetVehicleDoorShut(gEntity, i, false)
                    else
                        SetVehicleDoorOpen(gEntity, i, false, false)
                    end
                end
            end

            -- cancel button (Retroceso, y tambien ESC o si el personaje muere)
            if IsControlJustPressed(0, 194) or IsDisabledControlJustPressed(0, 194)
                or IsDisabledControlJustPressed(0, 200)
                or IsEntityDead(cache.ped) then
                -- stopDragCam()
                exports['origen_garages']:stopDragCam()
                return
            end

            if gFirstPersonEnabled then
                if  IsDisabledControlJustPressed(0, 0) or IsDisabledControlJustPressed(0, 0) then
                    isFirstPersonView = not isFirstPersonView
                    if isFirstPersonView then
                        SetCamViewModeForContext(1, 4)
                        RenderScriptCams(false, true, 0, true, false)
                    else
                        RenderScriptCams(true, true, 0, true, false)
                    end
                end
            end

            Wait(0)
        end
    end)
end

local function instructionalButton(controlId, text)
    ScaleformMovieMethodAddParamPlayerNameString(GetControlInstructionalButton(0, controlId, true))
    BeginTextCommandScaleformString('STRING')
    AddTextComponentSubstringKeyboardDisplay(text)
    EndTextCommandScaleformString()
end

---@param entity integer
---@param radiusOptions? {initial?: number, min?: number, max?: number, scrollIncrements?: number, firstPersonEnabled?: boolean}
local function startDragCam(entity, radiusOptions)
    running = true
    -- El radial de origen_hud no se abre con ESC mientras se mira una camara.
    LocalPlayer.state:set('mirandoCamara', true, false)
    gEntity = entity
    gRadius = radiusOptions?.initial or 5.0
    gRadiusMin = radiusOptions?.min or 2.5
    gRadiusMax = radiusOptions?.max or 10.0
    scrollIncrements = radiusOptions?.scrollIncrements or 0.5
    gFirstPersonEnabled = radiusOptions?.firstPersonEnabled or false
    cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    RenderScriptCams(true, true, 0, true, false)
    inputListener()
end

local function stopDragCam()
    if not running then return end
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do
        Wait(0)
    end
    running = false
    RenderScriptCams(false, true, 0, true, false)
    DestroyCam(cam, true)
    SetCamViewModeForContext(1, 1)
    SetScaleformMovieAsNoLongerNeeded(scaleform)
    if gEntity and DoesEntityExist(gEntity) then
        DeleteVehicle(gEntity)
        gEntity = nil
    end
    lib.hideTextUI()
    inspeccionando = false
    SendNUIMessage({
        action = 'showInterface'
    })
    SetNuiFocus(true, true)
    DoScreenFadeIn(500)
    -- Un poco despues: el ESC que ha cerrado la inspeccion aun se suelta
    -- ahora, y el radial lo cogeria.
    SetTimeout(400, function() LocalPlayer.state:set('mirandoCamara', false, false) end)
end

exports('startDragCam', startDragCam)
exports('stopDragCam', stopDragCam)

inspectVeh = nil
--- Hay una inspeccion en marcha (desde que se pide en showVehicleInfo hasta
--- stopDragCam): nui.lua no deja empezar otra encima.
inspeccionando = false

-- vData es opcional: showVehicleInfo ya lo trae para mirar el modelo antes
-- del fundido, y asi no se pide dos veces al servidor.
function inspectCar(plate, coords, vData)
    vData = vData or lib.callback.await('origen_garages:cb:getVehicle', false, plate)
    lib.requestModel(vData.mods.model)
    coords = coords or GetEntityCoords(PlayerPedId())
    inspectVeh = CreateVehicle(vData.mods.model, coords.x, coords.y, coords.z, coords.w or 0.0, false, false)
    
    SetVehicleOnGroundProperly(inspectVeh)
    SetVehicleDoorsLocked(inspectVeh, 2) -- Lock the vehicle
    SetVehicleDoorsLockedForAllPlayers(inspectVeh, true) -- Lock the vehicle for all players
    lib.setVehicleProperties(inspectVeh, vData.mods)
    cGarage.Utils.applyVehicleDamage(inspectVeh, vData.mods)

    exports['origen_garages']:startDragCam(inspectVeh, {
        initial = 6.0,
        min = 4.5,
        max = 8.0,
        scrollIncrements = 0.5,
    })
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    if inspectVeh then
        DeleteVehicle(inspectVeh)
        inspectVeh = nil
    end

    -- Parar el recurso a media inspeccion dejaba la camara puesta.
    if running then
        running = false
        RenderScriptCams(false, false, 0, true, false)
        if cam then DestroyCam(cam, true) end
        SetCamViewModeForContext(1, 1)
        LocalPlayer.state:set('mirandoCamara', false, false)
    end
end)