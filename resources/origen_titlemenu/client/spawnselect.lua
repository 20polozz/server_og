local spawncam = false

local function HudFadeOut(time)
    local t = time or 500
    if GetResourceState('origen_hud') == 'started' then
        exports['origen_hud']:DoScreenFadeOut(t)
    else
        DoScreenFadeOut(t)
    end
end

local function HudFadeIn(time)
    local t = time or 500
    if GetResourceState('origen_hud') == 'started' then
        exports['origen_hud']:DoScreenFadeIn(t)
    else
        DoScreenFadeIn(t)
    end
end

function SpawnCamera()
    if Config.SkySpawnCinematicDisable then 
        return
    end

    if not spawncam then
        HudFadeOut(500)
        Citizen.Wait(750)
        UnselectCharacter(true)
        StopCinematicCam()

        spawncam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", Config.SpawnCam.coords, Config.SpawnCam.rot, GetGameplayCamFov())
        SetCamActive(spawncam, true)
        RenderScriptCams(true, false, 0, true, false)
        Citizen.Wait(100)
        HudFadeIn(500)
    end
end

function SelectCoords(x, y)
    SetCamParams(spawncam, x, y, 800.01, -90.0, 0.0, 0.0, GetGameplayCamFov(), 1500, 0, 0, 2)
    ShakeCam(spawncam, "HAND_SHAKE", 2.0)
end

function StopSpawnCamera(final, instant)
    if Config.SkySpawnCinematicDisable then 
        return
    end

    if spawncam then
        --[[ Si la camara de llegada ya esta puesta, la del mapa se retira sin
             tocar el render: apagarlo devolveria la vista al jugador de golpe y
             se cargaria la bajada desde el cielo, que en ese momento acaba de
             empezar. Pasa cuando se abre el mapa de ubicaciones y luego se
             entra igualmente por el ultimo sitio. ]]
        if CamaraLlegadaActiva and CamaraLlegadaActiva() then
            DestroyCam(spawncam, false)
            spawncam = false
            return
        end

        if final then

            if Config.ExperimentalVersion then 
                NewLoadSceneStop()
                debug("EXPERIMENTAL VERSION IN SPAWNSELECT.LUA ENABLED")
            end

            RenderScriptCams(false, true, 2000, true, false)
            Citizen.Wait(2000)
            DestroyCam(spawncam, false)
            spawncam = false
        elseif instant then
            RenderScriptCams(false, false, 0, true, false)
            DestroyCam(spawncam, false)
            spawncam = false
        else
            HudFadeOut(500)
            Citizen.Wait(1000)
            RenderScriptCams(false, false, 0, true, false)
            DestroyCam(spawncam, false)
            spawncam = false
        end
    end
end

function GetMyApartments(citizenid)
    local retval, lastplace

    QBCore.Functions.TriggerCallback('origen_titlemenu:GetOwnedApartment', function(result, _lastplace)
        lastplace = _lastplace
        if result ~= nil then
            retval = result
        else
            retval = false
        end
    end, citizenid)

    while retval == nil do
        Wait(0)
    end

    return retval, Apartments.Locations, lastplace
end