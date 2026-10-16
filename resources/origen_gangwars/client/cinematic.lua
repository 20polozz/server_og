Cinematic = {
    cam = nil,
}

local function getNewCoords(centerCoords, camRadius)
    local newVect, distFromCenter

    repeat
        local angleXY = math.random() * (2 * math.pi)
        local distance = math.random() * camRadius

        local newX = centerCoords.x + math.cos(angleXY) * distance
        local newY = centerCoords.y + math.sin(angleXY) * distance

        newVect = vector3(newX, newY, centerCoords.z + 50.0)
        distFromCenter = #(centerCoords - newVect)

    until distFromCenter <= camRadius and distFromCenter > camRadius / 2

    return newVect
end

local function generateCamCoords(centerCoords, camCount, camRadius)
    local camCoords = {}

    for i = 1, camCount do
        camCoords[i] = getNewCoords(centerCoords, camRadius)
    end

    return camCoords
end

Cinematic.Start = function()
    Nui.ToggleHud(false)
    
    -- Obtener datos de la batalla para el NUI
    local battleName = GlobalState['orgStorms_' .. Storms.id .. '_name'] or 'Guerra de bandas'
    local battleImage = GlobalState['orgStorms_' .. Storms.id .. '_image'] or ''
    local playerCount = GlobalState['orgStorms_' .. Storms.id .. '_playerCount'] or 0
    local maxPlayers = GlobalState['orgStorms_' .. Storms.id .. '_maxPlayers'] or 100
    
    -- Mostrar NUI de cinemática con información
    SendNUIMessage({
        action = 'showCinematicInfo',
        data = {
            battleName = battleName,
            battleImage = battleImage,
            players = playerCount,
            maxPlayers = maxPlayers,
            weather = Storms.weather or 'CLEAR',
            time = Storms.time or 'day',
            radius = Storms.radius or 400
        }
    })
    
    local indexCam = 1
    local centerCoords = Storms.coords or GetEntityCoords(PlayerPed)
    local radius = Storms.radius or 400.0
    SetEntityCoords(PlayerPed, centerCoords.x, centerCoords.y, centerCoords.z + 300.0)
    FreezeEntityPosition(PlayerPed, true)

    local camCoords = generateCamCoords(centerCoords, 4, radius)

    Cinematic.cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 50.0)  -- FOV reducido para mejor encuadre
    SetCamActive(Cinematic.cam, true)
    RenderScriptCams(true, false, 0, false, true)

    while indexCam <= #camCoords do
        local camCoord = camCoords[indexCam]
        local toCoord = camCoords[indexCam + 1] or camCoords[1]
        
        SetFocusPosAndVel(camCoord, 0.0, 0.0, 0.0)
        
        -- Posicionar cámara más alta y siempre mirando al centro
        local heightOffset = 120.0
        SetCamCoord(Cinematic.cam, camCoord.x, camCoord.y, camCoord.z + heightOffset)
        
        -- Siempre apuntar al centro de la zona
        PointCamAtCoord(Cinematic.cam, centerCoords.x, centerCoords.y, centerCoords.z + 20.0)
        
        -- Movimiento suave hacia la siguiente posición
        SetCamParams(Cinematic.cam, 
            toCoord.x, 
            toCoord.y, 
            toCoord.z + heightOffset, 
            0.0,  -- rotX
            0.0,  -- rotY
            0.0,  -- rotZ
            50.0,  -- FOV
            5000,  -- Duración más corta
            1,  -- Tipo de interpolación (1 = suave)
            1,  -- Tipo de interpolación ROT
            2   -- ease type
        )
        
        DoScreenFadeIn(500)
        while not IsScreenFadedIn() do Wait(0) end
        
        indexCam = indexCam + 1
        Wait(4000)  -- Tiempo reducido por toma
        
        DoScreenFadeOut(500)
        while not IsScreenFadedOut() do Wait(0) end
    end

    -- Ocultar NUI de cinemática
    SendNUIMessage({
        action = 'showCinematicInfo',
        data = {
            show = false
        }
    })

    SetCamActive(Cinematic.cam, false)
    RenderScriptCams(false, false, 0, true, false)
    DestroyCam(Cinematic.cam, false)
    ClearFocus()
    Cinematic.cam = nil
    DoScreenFadeIn(2000)
    FreezeEntityPosition(PlayerPed, false)
    Nui.ToggleHud(true)
end