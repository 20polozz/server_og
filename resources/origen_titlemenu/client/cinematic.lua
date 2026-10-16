local cincam = false
local lastpos = 0

--- Coloca la camara fija del menu.
---
--- @param blend number|nil milisegundos que tarda en encajar. Por defecto un
--- segundo, que es lo que se ve al volver al menu principal. Cuando se entra
--- en la seleccion la pantalla ya esta en negro por el fundido, asi que ese
--- segundo no se ve: es tiempo muerto y se pasa 0.
function StartCinematicCam(blend)
    blend = tonumber(blend) or 1000
    if not cincam then
        Citizen.CreateThread(function()
            DoScreenFadeIn(1000)
            local camcoords = Config.FixedCamera.xyz
            local camrotation = vector3(-5.0, 0.0, Config.FixedCamera.w)

            cincam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", camcoords, camrotation, 40.0, false, 2)
            SetCamActive(cincam, true)
            RenderScriptCams(true, blend > 0, blend, true, false)
        end)
    end
end

function StopCinematicCam()
    if cincam then
        -- DoScreenFadeOut(500)
        -- Citizen.Wait(1000)
        SetFocusEntity(PlayerPedId())
        RenderScriptCams(false, true, 1000, true, false)
        DestroyCam(cincam, false)
        cincam = false
    end
end

function DoCinematicCam()
    -- Disabled random fly-throughs
end


RegisterNUICallback("StartCinematicCam", function(data, cb)
    StartCinematicCam(data and data.blend)
    cb(true)
end)

RegisterNUICallback("StopCinematicCam", function(data, cb)
    StopCinematicCam()
    cb(true)
end)