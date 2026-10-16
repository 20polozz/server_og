-- La pantalla de resultado al acabar la partida. Antes era el muro de
-- celebracion de GTA (scaleforms mp_celebration, heist_celebration_bg y
-- mp_celebration_fg); ahora es una NUI en pegatina (ui-new-vue,
-- components/Resultado.vue) con el podio y tu puesto, que se quita sola como
-- aquel. La escena (fundidos, camara, personajes posando) sigue igual.

--- Lo que se tiene en pantalla el resultado, en ms (el muro de GTA rondaba
--- los 8 s con sus 3 de margen).
local DURACION_RESULTADO = 8000

local inScene = false

--- Espera a que `listo()` se cumpla, con tope (5 s por defecto). Los bucles
--- sin tope dejaban la escena colgada con el foco cogido: si un fundido no
--- termina, EndScene.Stop no llegaba nunca.
local function esperar(listo, tope)
    local hasta = GetGameTimer() + (tope or 5000)
    while not listo() do
        if GetGameTimer() > hasta then return false end
        Wait(0)
    end
    return true
end

EndScene = {
    cam = nil,
    peds = {}
}

local scenes = {
    [1] = {
        camera = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA",416.00051879883,-980.78601074219,-99.104194641113,3.3999314308167,-7.4705189945234e-07,22.791131973267,42.0, true, 2),
        peds = {
            [1] = vector4(414.2, -977.08, -100.0, 203.08),
            [2] = vector4(411.88, -976.93, -100.0, 230.03),
            [3] = vector4(415.79, -974.78, -100.0, 165.75)
        },
        focusCoords = vector4(416.00051879883,-980.78601074219,-99.104194641113,3.3999314308167),
    }
}

EndScene.Start = function(top3, playerPosition)
    DoScreenFadeOut(500)
    esperar(IsScreenFadedOut)
    EndScene.cam = scenes[1].camera
    SetFocusPosAndVel(scenes[1].focusCoords, 0, 0, 0)
    SetCamActive(EndScene.cam, true)
    RenderScriptCams(true, false, 0, false, true)
    for i, data in ipairs(top3) do
        if data.src == GetPlayerServerId(PlayerId()) then
            SetNuiFocus(true, false)  
            inScene = true
            local lastCoords = GetEntityCoords(PlayerPed)
            SetEntityCoords(PlayerPed, scenes[1].peds[i].x, scenes[1].peds[i].y, scenes[1].peds[i].z, false, false, false, false)
            SetEntityHeading(PlayerPed, scenes[1].peds[i].w)
            TaskStartScenarioInPlace(PlayerPed, (i == 1) and "WORLD_HUMAN_MUSCLE_FLEX" or "WORLD_HUMAN_STAND_IMPATIENT", 0, true)
        end
    end
    Wait(1000)
    DoScreenFadeIn(500)
    esperar(IsScreenFadedIn)
    if not top3[1] then
        EndScene.Stop()
        return
    end
    -- En pcall: si algo falla aqui, Start se cortaria sin llegar a Stop, y el
    -- foco cogido arriba no se soltaria nunca.
    local ok, err = pcall(EndScene.Resultado, top3, playerPosition)
    if not ok then
        print('^1[gangwars] escena final: ' .. tostring(err) .. '^0')
        SendNUIMessage({ action = 'gwResultado', data = { show = false } })
    end
    Wait(1000)
    EndScene.Stop()
end

--- Enseña el resultado en la NUI y espera a que se vaya. top3 son las filas
--- de finalScore del servidor (src, name, level, team, position).
EndScene.Resultado = function(top3, playerPosition)
    local yo = GetPlayerServerId(PlayerId())
    local filas = {}
    for i, data in ipairs(top3) do
        local nombre = data.name
        if not nombre or nombre == '' then
            nombre = GetPlayerName(GetPlayerFromServerId(data.src)) or ('Jugador ' .. tostring(data.src))
        end
        filas[#filas + 1] = {
            puesto = tonumber(data.position) or i,
            nombre = nombre,
            nivel = tonumber(data.level),
            equipo = type(data.team) == 'string' and data.team or nil,
            yo = tonumber(data.src) == yo,
        }
    end

    SendNUIMessage({
        action = 'gwResultado',
        data = {
            show = true,
            top = filas,
            puesto = tonumber(playerPosition),
            duracion = DURACION_RESULTADO,
        }
    })
    Wait(DURACION_RESULTADO)
    SendNUIMessage({ action = 'gwResultado', data = { show = false } })
    -- Lo que tarda en irse (la transicion de salida), antes del fundido.
    Wait(300)
end

EndScene.Stop = function()
    DoScreenFadeOut(500)
    esperar(IsScreenFadedOut)
    ClearFocus()
    SetCamActive(EndScene.cam, false)
    RenderScriptCams(false, false, 0, true, false)
    if inScene then
        inScene = false
        ClearPedTasks(PlayerPed)
        SetEntityCoords(PlayerPed, 545.68, 2687.52, 42.32, false, false, false, false)
        SetEntityHeading(PlayerPed, 230.03)
        SetNuiFocus(false, false)
    end
    EndScene.cam = nil
    EndScene.peds = {}
    Wait(500)
    DoScreenFadeIn(500)
    esperar(IsScreenFadedIn)
end

RegisterNetEvent('origen_gangwars:client:EndScene', function(top3, playerPosition)
    EndScene.Start(top3, playerPosition)
end)