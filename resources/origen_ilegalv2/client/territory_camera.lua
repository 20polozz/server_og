-- ── territory_camera.lua ─────────────────────────────────────────────────────
--[[ La camara instantanea en manos de una banda: se levanta, se mira por el
     visor y se dispara al grafiti.

     Este lado NO decide nada. Solo dice al servidor a que punto del mundo
     apuntaba la camara al disparar; que grafiti hay ahi, de quien es y si eso
     descubre el territorio lo comprueba server/territory_camera.lua. ]]

local activa = false

-- Controles (ver https://docs.fivem.net/docs/game-references/controls/)
local C_MIRAR_X, C_MIRAR_Y = 1, 2
local C_DISPARO            = 24   -- clic izquierdo
local C_APUNTAR            = 25   -- clic derecho: salir
local C_RUEDA_ARRIBA       = 241
local C_RUEDA_ABAJO        = 242
local C_RETROCESO          = 177
local C_PAUSA              = 200

local FOV_MIN, FOV_MAX, FOV_INICIO = 15.0, 70.0, 50.0

local function Direccion(rot)
    local rx, rz = math.rad(rot.x), math.rad(rot.z)
    local c = math.abs(math.cos(rx))
    return vector3(-math.sin(rz) * c, math.cos(rz) * c, math.sin(rx))
end

--- Las cuatro esquinas del visor y la cruz del centro. Lo justo para que se
--- entienda que se esta mirando por una camara, sin tapar lo que se fotografia.
local function DibujarVisor()
    local a, g = 0.045, 0.0025
    local blanco = { 255, 255, 255, 200 }
    local esquinas = {
        { 0.2, 0.2, 1, 1 }, { 0.8, 0.2, -1, 1 }, { 0.2, 0.8, 1, -1 }, { 0.8, 0.8, -1, -1 },
    }
    for _, e in ipairs(esquinas) do
        local x, y, sx, sy = e[1], e[2], e[3], e[4]
        DrawRect(x + sx * a / 2, y, a, g * 1.8, blanco[1], blanco[2], blanco[3], blanco[4])
        DrawRect(x, y + sy * a * 1.7 / 2, g, a * 1.7, blanco[1], blanco[2], blanco[3], blanco[4])
    end
    -- La cruz, en el rosa de la pegatina (216,27,85).
    DrawRect(0.5, 0.5, 0.012, 0.0018, 216, 27, 85, 220)
    DrawRect(0.5, 0.5, 0.0010, 0.02, 216, 27, 85, 220)
end

RegisterNetEvent('origen_gang:client:camaraGrafiti', function()
    if activa then return end

    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) or IsEntityDead(ped) then
        TriggerEvent('origen_ilegalv2:client:notify', 'No puedes usar la cámara ahora.', 'error')
        return
    end

    activa = true

    CreateThread(function()
        -- La camara en la mano, en la postura del paparazzi.
        local modelo = `prop_pap_camera_01`
        local dict = 'amb@world_human_paparazzi@male@base'
        lib.requestModel(modelo, 5000)
        lib.requestAnimDict(dict, 5000)

        local pos = GetEntityCoords(ped)
        local objeto = CreateObject(modelo, pos.x, pos.y, pos.z, true, true, false)
        AttachEntityToEntity(objeto, ped, GetPedBoneIndex(ped, 28422),
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
        TaskPlayAnim(ped, dict, 'base', 3.0, 3.0, -1, 49, 0, false, false, false)
        SetModelAsNoLongerNeeded(modelo)

        -- La vista: pegada a la cabeza, mirando hacia donde miraba el jugador.
        local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        AttachCamToPedBone(cam, ped, 31086, 0.0, 0.12, 0.05, true)
        local rotJuego = GetGameplayCamRot(2)
        SetCamRot(cam, math.max(-60.0, math.min(40.0, rotJuego.x)), 0.0, rotJuego.z, 2)
        local fov = FOV_INICIO
        SetCamFov(cam, fov)
        RenderScriptCams(true, true, 250, true, false)

        -- Las teclas en el pie de origen_hud (MostrarTeclas, functions/f_utils.lua)
        MostrarTeclas({
            { key = 'LCLICK',    text = 'Hacer foto' },
            { key = 'WHEEL',     text = 'Zoom' },
            { key = 'RCLICK',    text = 'Guardar' },
            { key = 'BACKSPACE', text = 'Guardar' },
        })

        local ultimaFoto, flashHasta = 0, 0

        while activa do
            Wait(0)

            DisableAllControlActions(0)
            EnableControlAction(0, 249, true) -- pulsar para hablar
            EnableControlAction(0, 245, true) -- chat
            HideHudAndRadarThisFrame()
            -- La vista va pegada a la cabeza: la camara de la mano y los brazos
            -- tapaban medio encuadre. Solo en esta pantalla; los demas lo ven.
            SetEntityLocallyInvisible(ped)
            if DoesEntityExist(objeto) then SetEntityLocallyInvisible(objeto) end

            -- Mirar con el raton. Mas despacio cuanto mas zoom, o con el tele
            -- no hay manera de encuadrar nada.
            local sens = 7.0 * (fov / FOV_INICIO)
            local mx = GetDisabledControlNormal(0, C_MIRAR_X)
            local my = GetDisabledControlNormal(0, C_MIRAR_Y)
            local r = GetCamRot(cam, 2)
            local nz = r.z - mx * sens
            local nx = math.max(-60.0, math.min(40.0, r.x - my * sens))
            SetCamRot(cam, nx, 0.0, nz, 2)
            SetEntityHeading(ped, nz)

            if IsDisabledControlJustPressed(0, C_RUEDA_ARRIBA) then fov = math.max(FOV_MIN, fov - 5.0) end
            if IsDisabledControlJustPressed(0, C_RUEDA_ABAJO) then fov = math.min(FOV_MAX, fov + 5.0) end
            SetCamFov(cam, fov)

            DibujarVisor()

            local ahora = GetGameTimer()
            if ahora < flashHasta then
                local resto = (flashHasta - ahora) / 180.0
                DrawRect(0.5, 0.5, 1.0, 1.0, 255, 255, 255, math.floor(230 * resto))
            end

            if IsDisabledControlJustPressed(0, C_DISPARO) and ahora - ultimaFoto > 1500 then
                ultimaFoto = ahora
                flashHasta = ahora + 180
                PlaySoundFrontend(-1, 'Camera_Shoot', 'Phone_Soundset_Franklin', true)
                --[[ El mismo aviso LOCAL que la camara de origen_police: una foto,
                     desde donde, hacia donde y con que zoom. Lo escucha
                     origen_mision (la foto del cuerpo para Bastida). ]]
                TriggerEvent('origen_police:camara:foto', GetCamCoord(cam), GetCamRot(cam, 2), fov)

                -- A que punto del mundo apunta el centro del visor. El grafiti
                -- es una textura sobre la pared: el rayo choca con la pared y
                -- ese punto cae encima del grafiti.
                local desde = GetCamCoord(cam)
                local hasta = desde + Direccion(GetCamRot(cam, 2)) * 30.0
                local rayo = StartExpensiveSynchronousShapeTestLosProbe(
                    desde.x, desde.y, desde.z, hasta.x, hasta.y, hasta.z, 1 | 16, ped, 7)
                local _, choca, punto = GetShapeTestResult(rayo)
                if choca ~= 1 then punto = hasta end

                TriggerServerEvent('origen_gang:server:fotoGrafiti', { x = punto.x, y = punto.y, z = punto.z })
            end

            if IsDisabledControlJustPressed(0, C_APUNTAR)
                or IsDisabledControlJustPressed(0, C_RETROCESO)
                or IsDisabledControlJustPressed(0, C_PAUSA)
                or IsEntityDead(ped) or IsPedRagdoll(ped) or IsPedInAnyVehicle(ped, false) then
                activa = false
            end
        end

        -- Recoger
        QuitarTeclas()
        RenderScriptCams(false, true, 250, true, false)
        DestroyCam(cam, false)
        StopAnimTask(ped, dict, 'base', 2.0)
        RemoveAnimDict(dict)
        if DoesEntityExist(objeto) then
            DetachEntity(objeto, true, false)
            DeleteEntity(objeto)
        end
    end)
end)

AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() or not activa then return end
    activa = false
    QuitarTeclas()
    RenderScriptCams(false, false, 0, true, false)
    DestroyAllCams(true)
end)
