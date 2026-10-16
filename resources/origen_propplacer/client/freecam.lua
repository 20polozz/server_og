-- origen_propplacer | client/freecam.lua
-- Cámara libre integrada con el sistema de placement
-- Activar/desactivar con F: durante colocación

FreeCam = {
    active   = false,
    cam      = nil,
    speed    = 0.3,
    fastMult = 4.0,
}

local function createFreeCam()
    local ped    = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local rot    = GetGameplayCamRot()

    local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(cam, coords.x, coords.y, coords.z + 2.0)
    SetCamRot(cam, rot.x, rot.y, rot.z, 2)
    SetCamFov(cam, 60.0)
    RenderScriptCams(true, true, 500, true, true)

    return cam
end

local function destroyFreeCam()
    if FreeCam.cam then
        RenderScriptCams(false, true, 500, true, true)
        DestroyCam(FreeCam.cam, false)
        FreeCam.cam = nil
    end
end

-- ─────────────────────────────────────────────
-- Loop de cámara libre
-- ─────────────────────────────────────────────
local function runFreeCamLoop()
    CreateThread(function()
        while FreeCam.active do
            Wait(0)

            local cam    = FreeCam.cam
            local rot    = GetCamRot(cam, 2)
            local pos    = GetCamCoord(cam)
            local speed  = FreeCam.speed
            local isFast = IsDisabledControlPressed(0, 21) -- Shift

            if isFast then speed = speed * FreeCam.fastMult end

            -- Dirección de la cámara
            local rx = math.rad(rot.x)
            local rz = math.rad(rot.z)

            local fwd = {
                x = -math.sin(rz) * math.abs(math.cos(rx)),
                y =  math.cos(rz) * math.abs(math.cos(rx)),
                z =  math.sin(rx),
            }
            local right = {
                x =  math.cos(rz),
                y =  math.sin(rz),
                z =  0.0,
            }

            local nx, ny, nz = pos.x, pos.y, pos.z

            -- WASD / flechas para mover
            if IsDisabledControlPressed(0, 32) then  -- W
                nx = nx + fwd.x * speed
                ny = ny + fwd.y * speed
                nz = nz + fwd.z * speed
            end
            if IsDisabledControlPressed(0, 33) then  -- S
                nx = nx - fwd.x * speed
                ny = ny - fwd.y * speed
                nz = nz - fwd.z * speed
            end
            if IsDisabledControlPressed(0, 34) then  -- A
                nx = nx - right.x * speed
                ny = ny - right.y * speed
            end
            if IsDisabledControlPressed(0, 35) then  -- D
                nx = nx + right.x * speed
                ny = ny + right.y * speed
            end
            -- Q/E para subir y bajar
            if IsDisabledControlPressed(0, 44) then  -- Q
                nz = nz - speed
            end
            if IsDisabledControlPressed(0, 38) then  -- E
                nz = nz + speed
            end

            SetCamCoord(cam, nx, ny, nz)

            -- Ratón para rotar
            local mouseX = GetDisabledControlNormal(0, 1) * 5.0
            local mouseY = GetDisabledControlNormal(0, 2) * 5.0

            local newRot = {
                x = math.max(-89.0, math.min(89.0, rot.x - mouseY * 3.0)),
                y = rot.y,
                z = rot.z - mouseX * 3.0,
            }
            SetCamRot(cam, newRot.x, newRot.y, newRot.z, 2)

            -- Scroll para zoom (FOV)
            local fov = GetCamFov(cam)
            if IsDisabledControlJustPressed(0, 14) then
                SetCamFov(cam, math.max(20.0, fov - 5.0))
            end
            if IsDisabledControlJustPressed(0, 15) then
                SetCamFov(cam, math.min(90.0, fov + 5.0))
            end

            -- Bloquear controles del jugador
            DisableAllControlActions(0)
            EnableControlAction(0, 1, true)   -- Mouse X
            EnableControlAction(0, 2, true)   -- Mouse Y
            EnableControlAction(0, 14, true)  -- Scroll Up
            EnableControlAction(0, 15, true)  -- Scroll Down
            EnableControlAction(0, 21, true)  -- Shift (sprint)
            EnableControlAction(0, 32, true)  -- W
            EnableControlAction(0, 33, true)  -- S
            EnableControlAction(0, 34, true)  -- A
            EnableControlAction(0, 35, true)  -- D
            EnableControlAction(0, 38, true)  -- E
            EnableControlAction(0, 44, true)  -- Q
        end

        destroyFreeCam()
    end)
end

-- ─────────────────────────────────────────────
-- API pública
-- ─────────────────────────────────────────────
function FreeCam.Toggle()
    if not Placement.active and not Gizmo.enabled then return end
    if Gizmo.enabled then return end  -- No permitir freecam en modo gizmo

    if FreeCam.active then
        FreeCam.active = false
        SendNUIMessage({ action = "updatePlacingMode", mode = "raycast" })
    else
        FreeCam.active = true
        FreeCam.cam    = createFreeCam()
        runFreeCamLoop()
        SendNUIMessage({ action = "updatePlacingMode", mode = "freecam" })
    end
end

function FreeCam.ForceStop()
    if FreeCam.active then
        FreeCam.active = false
        destroyFreeCam()
    end
end
