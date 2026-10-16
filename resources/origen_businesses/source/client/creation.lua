Creation = {
    active = false,
    coords = {},
    
    initialHeight = nil,
    currentZone = nil,
    points = {},
    thickness = 15,
    colors = {
        normal = vec4(255, 0, 0, 50.0),
        complete = vec4(0, 255, 0, 50.0),
    }
}

local function RotationToDirection(rotation)
    local x = rotation.x * math.pi / 180.0
    local z = rotation.z * math.pi / 180.0
    local num = math.abs(math.cos(x))
    return vector3((-math.sin(z) * num), (math.cos(z) * num), math.sin(x))
end

local function RayCastGamePlayCamera(distance, camCoords, camRot)
    local cameraRotation = camRot or GetGameplayCamRot()
    local cameraCoord = camCoords or GetGameplayCamCoord()
    local direction = RotationToDirection(cameraRotation)
    local destination =
    {
        x = cameraCoord.x + direction.x * distance,
        y = cameraCoord.y + direction.y * distance,
        z = cameraCoord.z + direction.z * distance
    }
    local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0))
    return b, c, e
end

function Creation:Start()
    if self.active then return end
    self.active = true
    self.points = {}
    self.coords = {}
    self.thickness = 15
    
    LocalPlayer.state:set('IsBusy', true, true)
    
    -- Usamos la camara normal o activamos una freecam si fuera necesario, 
    -- pero para este localizador vamos a usar la logica de origen_housing adaptada.
    -- origen_housing usa una freecam propia. 
    -- Como no quiero copiar todo el script de freecam si no es necesario, 
    -- intentare usar una logica similar pero mas ligera o integrada.
    
    -- El usuario quiere que sea COMO origen_housing, asi que mejor copio la Freecam basica aqui.
end

Freecam = {
    active = false,
    cam = nil,
    maxDistance = 100,
    position = vector3(0.0, 0.0, 0.0),
    rotation = vector3(0.0, 0.0, 0.0),
    speed = 0.3,
}

function Freecam:CreateCam()
    if self.active then return end
    local x, y, z = table.unpack(GetGameplayCamCoord())
    local pitch, roll, yaw = table.unpack(GetGameplayCamRot(2))
    local fov = GetGameplayCamFov()

    self.cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    self.active = true

    SetCamCoord(self.cam, x, y, z + 5.0)
    SetCamRot(self.cam, pitch, roll, yaw, 2)
    SetCamFov(self.cam, fov)

    RenderScriptCams(true, true, 500, true, true)
    FreezeEntityPosition(cache.ped, true)

    CreateThread(function()
        while DoesCamExist(self.cam) and self.active do
            self:Controls()
            Wait(0)
        end
    end)
end

function Freecam:Controls()
    local rAxisX = GetControlNormal(0, 220)
    local rAxisY = GetControlNormal(0, 221)
    local rotation = GetCamRot(self.cam, 2)

    local newX = rotation.x - (rAxisY * 5)
    if newX < -89.0 then newX = -89.0 elseif newX > 89.0 then newX = 89.0 end
    local newZ = rotation.z + (rAxisX * -10)
    
    self.rotation = vector3(newX, 0.0, newZ)
    SetCamRot(self.cam, self.rotation, 2)

    local x, y, z = table.unpack(GetCamCoord(self.cam))
    local pitch, roll, yaw = table.unpack(GetCamRot(self.cam, 2))

    local speed = self.speed
    if IsControlPressed(0, 21) then -- SHIFT
        speed = speed * 2.5
    end

    local dx = math.sin(-yaw * math.pi / 180) * speed
    local dy = math.cos(-yaw * math.pi / 180) * speed
    
    local dx2 = math.sin(math.floor(yaw + 90.0) % 360 * -1.0 * math.pi / 180) * speed
    local dy2 = math.cos(math.floor(yaw + 90.0) % 360 * -1.0 * math.pi / 180) * speed

    if IsControlPressed(0, 32) then -- W
        x, y = x + dx, y + dy
    elseif IsControlPressed(0, 33) then -- S
        x, y = x - dx, y - dy
    end

    if IsControlPressed(0, 35) then -- D
        x, y = x - dx2, y - dy2
    elseif IsControlPressed(0, 34) then -- A
        x, y = x + dx2, y + dy2
    end

    if IsControlPressed(0, 44) then -- Q
        z = z + speed
    elseif IsControlPressed(0, 46) then -- E
        z = z - speed
    end

    SetCamCoord(self.cam, x, y, z)
    self.position = vector3(x, y, z)
end

function Freecam:DestroyCam()
    FreezeEntityPosition(cache.ped, false)
    RenderScriptCams(false, true, 500, true, true)
    SetCamActive(self.cam, false)
    DestroyCam(self.cam, true)
    self.active = false
end

function Creation:CreateZone()
    if self.active then return end
    self.active = true
    self.points = {}
    self.success = false
    self.initialHeight = GetEntityCoords(cache.ped).z
    self.thickness = 15

    Freecam:CreateCam()
    
    exports.origen_hud:setupControls({
        { key = 'LCLICK', text = 'Colocar punto' },
        { key = 'BACKSPACE', text = 'Borrar anterior' },
        { key = 'ENTER', text = 'Finalizar' },
        { key = 'ESC', text = 'Cancelar' },
        { key = 'WHEEL', text = 'Grosor (+/-)' }
    })

    local results = nil
    local results = nil
    Wait(200) -- Pequeño margen para limpiar teclas pulsadas antes
    while self.active do
        Wait(0)
        DisableAllControlActions(0)
        
        -- Cámara y Ratón
        EnableControlAction(0, 1, true) -- Look LR
        EnableControlAction(0, 2, true) -- Look UD
        EnableControlAction(0, 220, true) -- Axis X
        EnableControlAction(0, 221, true) -- Axis Y
        
        -- Movimiento (WASDQE + SHIFT)
        EnableControlAction(0, 32, true)
        EnableControlAction(0, 33, true)
        EnableControlAction(0, 34, true)
        EnableControlAction(0, 35, true)
        EnableControlAction(0, 44, true)
        EnableControlAction(0, 46, true)
        EnableControlAction(0, 21, true)
        
        -- Botones de acción
        EnableControlAction(0, 24, true) -- LClick
        EnableControlAction(0, 177, true) -- Backspace
        EnableControlAction(0, 191, true) -- Enter
        EnableControlAction(0, 202, true) -- Esc
        
        -- Scroll
        EnableControlAction(0, 334, true)
        EnableControlAction(0, 335, true)
        EnableControlAction(0, 14, true) 
        EnableControlAction(0, 15, true)
        EnableControlAction(0, 16, true)
        EnableControlAction(0, 17, true)

        local camPos = Freecam.position or GetCamCoord(Freecam.cam)
        local camRot = Freecam.rotation or GetCamRot(Freecam.cam, 2)
        
        local hit, lookAt = RayCastGamePlayCamera(250.0, camPos, camRot)
        
        -- Dibujar la línea de guía donde apunta el ratón
        DrawLine(lookAt.x, lookAt.y, 0.0, lookAt.x, lookAt.y, 2000.0, 255, 0, 0, 255)
        
        local t_half = (self.thickness or 15.0) / 2.0
        
        -- Dibujar los puntos ya colocados
        for i, point in ipairs(self.points) do
            local pz_bottom = point.z - t_half
            local pz_top = point.z + t_half
            
            DrawMarker(28, point.x, point.y, point.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.2, 0.2, 216, 27, 85, 150, false, false, 2, nil, nil, false)
            
            -- Pilar vertical
            DrawLine(point.x, point.y, pz_bottom, point.x, point.y, pz_top, 220, 221, 224, 255)
            
            if i > 1 then
                local prev = self.points[i-1]
                local prev_bottom = prev.z - t_half
                local prev_top = prev.z + t_half
                
                -- Linea inferior
                DrawLine(prev.x, prev.y, prev_bottom, point.x, point.y, pz_bottom, 220, 221, 224, 255)
                -- Linea superior
                DrawLine(prev.x, prev.y, prev_top, point.x, point.y, pz_top, 220, 221, 224, 255)
                -- Centro
                DrawLine(prev.x, prev.y, prev.z, point.x, point.y, point.z, 255, 255, 255, 255)
            end
        end

        local count = #self.points
        if count >= 3 then
            -- Dibujar línea de cierre del polígono
            local first = self.points[1]
            local last = self.points[count]
            local f_bottom = first.z - t_half
            local f_top = first.z + t_half
            local l_bottom = last.z - t_half
            local l_top = last.z + t_half
            
            -- Linea inferior cierre
            DrawLine(last.x, last.y, l_bottom, first.x, first.y, f_bottom, 220, 221, 224, 255)
            -- Linea superior cierre
            DrawLine(last.x, last.y, l_top, first.x, first.y, f_top, 220, 221, 224, 255)
            -- Centro cierre
            DrawLine(last.x, last.y, last.z, first.x, first.y, first.z, 220, 221, 224, 255)
        end

        if IsDisabledControlJustPressed(0, 24) then -- LClick
            self.points[#self.points + 1] = vector3(lookAt.x, lookAt.y, self.initialHeight)
            PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
            self:RefreshPolyZone()
        end

        if IsDisabledControlJustPressed(0, 177) then -- Backspace / Right Click alternatively
            if #self.points > 0 then
                self.points[#self.points] = nil
                self:RefreshPolyZone()
            else
                self.active = false
            end
        end

        if IsDisabledControlJustPressed(0, 191) then -- Enter
            if #self.points >= 3 then
                self.active = false
                self.success = true
            else
                Custom.Notify({
                    title = 'Negocio',
                    description = 'Necesitas al menos 3 puntos',
                    type = 'error'
                })
            end
        end

        if IsDisabledControlJustPressed(0, 202) then -- Esc
            self.active = false
            self.success = false
        end

        if IsDisabledControlPressed(0, 334) then -- Scroll Up (grosor)
            self.thickness = self.thickness + 0.1
            self:RefreshPolyZone()
        elseif IsDisabledControlPressed(0, 335) then -- Scroll Down
            self.thickness = math.max(0.1, self.thickness - 0.1)
            self:RefreshPolyZone()
        end
    end

    exports.origen_hud:hideControls()
    Freecam:DestroyCam()
    self:RemoveZone()
    
    if self.success then
        results = {
            points = self.points,
            thickness = self.thickness
        }
    end

    self.active = false
    self.points = {}
    return results
end

function Creation:RefreshPolyZone()
    self:RemoveZone()
    -- Vaciado intencionalmente. Al no crear el lib.zones.poly interactivamente aquí, 
    -- evitamos el bucle infinito de triangulación que provocaba el freeze ("se queda pillado").
    -- Las paredes de la polyzone temporal ahora se dibujan nativamente desde el bucle superior de forma superflua y ligera.
end

function Creation:RemoveZone()
    if self.currentZone then
        pcall(function() self.currentZone:remove() end)
        self.currentZone = nil
    end
end
