-- ┌─────────────────────────────────────────────────────────────────────────┐
-- │  origen_robberies — Creador Visual de Polyzones (Cámara Libre)          │
-- │  Implementa freecam y dibujo de polígonos en tiempo real con ox_lib.    │
-- └─────────────────────────────────────────────────────────────────────────┘

local Freecam = {
    active = false,
    cam = nil,
    maxDistance = 250.0,
    speed = 0.4,
    position = vector3(0.0, 0.0, 0.0),
    rotation = vector3(0.0, 0.0, 0.0),
}

function Freecam:CreateCam()
    if self.active then return end

    local x, y, z = table.unpack(GetGameplayCamCoord())
    local pitch, roll, yaw = table.unpack(GetGameplayCamRot(2))
    local fov = GetGameplayCamFov()

    self.cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    self.active = true

    SetCamCoord(self.cam, x, y, z + 15.0)
    SetCamRot(self.cam, pitch, roll, yaw, 2)
    SetCamFov(self.cam, fov)

    RenderScriptCams(true, true, 500, true, true)
    FreezeEntityPosition(cache.ped, true)
    SetEntityLocallyInvisible(cache.ped, true)

    CreateThread(function()
        while DoesCamExist(self.cam) and self.active do
            SetEntityLocallyInvisible(cache.ped, true)

            -- Desactivar controles (ataques, cámara nativa, movimiento)
            for _, control in ipairs({24, 25, 47, 58, 69, 70, 92, 114, 135, 140, 141, 142, 143, 199, 200, 202, 257, 263, 264, 331}) do
                DisableControlAction(0, control, true)
            end

            self:Controls()
            TriggerEvent('origen_robberies:client:freecamTick')
            Wait(0)
        end
    end)
end

function Freecam:Controls()
    local rAxisX = GetControlNormal(0, 220)
    local rAxisY = GetControlNormal(0, 221)
    local rotation = GetCamRot(self.cam, 2)

    local newX = rotation.x - (rAxisY * 5)
    newX = math.max(-89.0, math.min(89.0, newX))
    local newZ = rotation.z + (rAxisX * -10)
    newZ = (newZ < 0) and (newZ + 360) or ((newZ > 360) and (newZ - 360) or newZ)

    self.rotation = vector3(newX, 0.0, newZ)
    SetCamRot(self.cam, self.rotation, 2)

    local x, y, z = table.unpack(GetCamCoord(self.cam))
    local pitch, roll, yaw = table.unpack(GetCamRot(self.cam, 2))

    local dx = math.sin(-yaw * math.pi / 180) * self.speed
    local dy = math.cos(-yaw * math.pi / 180) * self.speed
    local dz = math.tan(pitch * math.pi / 180) * self.speed

    local dx2 = math.sin(math.floor(yaw + 90.0) % 360 * -1.0 * math.pi / 180) * self.speed
    local dy2 = math.cos(math.floor(yaw + 90.0) % 360 * -1.0 * math.pi / 180) * self.speed

    if IsControlPressed(0, 32) then -- W
        x = x + dx
        y = y + dy
    elseif IsControlPressed(0, 33) then -- S
        x = x - dx
        y = y - dy
    end

    if IsControlPressed(0, 35) then -- D
        x = x - dx2
        y = y - dy2
    elseif IsControlPressed(0, 34) then -- A
        x = x + dx2
        y = y + dy2
    end

    if IsControlPressed(0, 44) then -- Q (Subir)
        z = z + self.speed
    elseif IsControlPressed(0, 46) then -- E (Bajar)
        z = z - self.speed
    end

    -- Ajustar velocidad con Rueda Arriba / Rueda Abajo
    if IsControlPressed(0, 181) then
        self.speed = math.min(1.5, self.speed + 0.05)
    elseif IsControlPressed(0, 180) then
        self.speed = math.max(0.1, self.speed - 0.05)
    end

    local playerCoords = GetEntityCoords(cache.ped)
    if #(playerCoords - vector3(x, y, z)) <= self.maxDistance then
        self.position = vector3(x, y, z)
        SetCamCoord(self.cam, x, y, z)
    end
end

function Freecam:DestroyCam()
    FreezeEntityPosition(cache.ped, false)
    RenderScriptCams(false, true, 500, true, true)
    SetCamActive(self.cam, false)
    DestroyCam(self.cam, true)
    self.cam = nil
    self.active = false
    self.speed = 0.4
end

-- ── Sistema de Creación de Polígono ──

local ZoneCreator = {
    active = false,
    points = {},
    thickness = 50.0,
    initialHeight = nil,
    currentZone = nil,
    resultPromise = nil
}

local function RotationToDirection(rotation)
    local x = rotation.x * math.pi / 180.0
    local z = rotation.z * math.pi / 180.0
    local num = math.abs(math.cos(x))
    return vector3((-math.sin(z) * num), (math.cos(z) * num), math.sin(x))
end

local function GetScreenCoordsRaycast(distance, camPos, camRot)
    local direction = RotationToDirection(camRot)
    local destination = camPos + (direction * distance)
    local ray = StartShapeTestRay(camPos.x, camPos.y, camPos.z, destination.x, destination.y, destination.z, -1, cache.ped, 0)
    local _, hit, endCoords = GetShapeTestResult(ray)
    if hit == 1 then
        return true, endCoords
    end
    return false, destination
end

function ZoneCreator:RefreshPolyZone()
    if self.currentZone then
        self.currentZone:remove()
        self.currentZone = nil
    end

    if #self.points > 0 then
        local color = vec4(255, 0, 0, 80.0) -- Rojo si faltan puntos
        if #self.points == 1 then
            self.initialHeight = self.points[1].z
        elseif #self.points >= 4 then
            color = vec4(0, 255, 0, 80.0) -- Verde si está listo
        end

        -- Alinear la altura del último punto
        self.points[#self.points] = vector3(self.points[#self.points].x, self.points[#self.points].y, self.initialHeight)

        self.currentZone = lib.zones.poly({
            name = 'precinct_creation_' .. cache.serverId,
            debugColour = color,
            points = self.points,
            thickness = self.thickness,
            debug = true
        })
    end
end

function ZoneCreator:Start(existingPoints, existingThickness)
    if self.active then return end
    self.active = true
    self.points = {}
    self.thickness = existingThickness or 50.0
    self.initialHeight = nil
    self.resultPromise = promise.new()

    LocalPlayer.state:set('IsBusy', true, true)
    Freecam:CreateCam()

    -- Si editamos una zona existente
    if existingPoints and #existingPoints > 0 then
        for _, pt in ipairs(existingPoints) do
            table.insert(self.points, vector3(pt.x, pt.y, pt.z))
        end
        self.initialHeight = self.points[1].z
        self:RefreshPolyZone()
    else
        self.initialHeight = GetEntityCoords(cache.ped).z
    end

    -- Notificar controles a la NUI
    SendNUIMessage({
        action = 'placementMode',
        data = { active = true }
    })

    return self.resultPromise
end

function ZoneCreator:Stop(success)
    if not self.active then return end
    self.active = false

    if self.currentZone then
        self.currentZone:remove()
        self.currentZone = nil
    end

    Freecam:DestroyCam()
    LocalPlayer.state:set('IsBusy', false, true)

    SendNUIMessage({
        action = 'placementMode',
        data = { active = false }
    })

    if success and #self.points >= 4 then
        local coords = {
            points = {},
            thickness = self.thickness
        }
        for _, pt in ipairs(self.points) do
            table.insert(coords.points, { x = pt.x, y = pt.y, z = self.initialHeight })
        end
        self.resultPromise:resolve(coords)
    else
        self.resultPromise:resolve(nil)
    end

    self.points = {}
    self.initialHeight = nil
end

-- Tick handler
AddEventHandler('origen_robberies:client:freecamTick', function()
    if not ZoneCreator.active then return end

    local camPos = Freecam.position
    local camRot = Freecam.rotation

    local _, lookAt = GetScreenCoordsRaycast(250.0, camPos, camRot)

    if lookAt then
        DrawLine(lookAt.x, lookAt.y, 0.0, lookAt.x, lookAt.y, 2000.0, 255, 0, 0, 255)
    end

    -- Clic izquierdo / Enter en teclado numérico/mando: Colocar punto
    if IsControlJustPressed(0, 24) or IsDisabledControlJustPressed(0, 24) then
        table.insert(ZoneCreator.points, vector3(lookAt.x, lookAt.y, lookAt.z))
        ZoneCreator:RefreshPolyZone()
        PlaySoundFrontend(-1, 'CHECKPOINT_AHEAD', 'HUD_MINI_GAME_SOUNDSET', true)
    end

    -- Backspace / Cancelar: Quitar último punto
    if IsControlJustPressed(0, 177) or IsDisabledControlJustPressed(0, 177) then
        if #ZoneCreator.points > 0 then
            table.remove(ZoneCreator.points, #ZoneCreator.points)
            ZoneCreator:RefreshPolyZone()
            PlaySoundFrontend(-1, 'BACK', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
        else
            ZoneCreator:Stop(false)
        end
    end

    -- Enter: Finalizar
    if IsControlJustPressed(0, 215) or IsDisabledControlJustPressed(0, 215) then
        if #ZoneCreator.points >= 4 then
            ZoneCreator:Stop(true)
            PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
        else
            lib.notify({
                description = 'Necesitas al menos 4 puntos para definir la zona.',
                type = 'error'
            })
        end
    end

    -- Teclas + / - (ajustar grosor de zona)
    if IsControlPressed(0, 334) then -- Numpad +
        ZoneCreator.thickness = math.min(100.0, ZoneCreator.thickness + 0.5)
        ZoneCreator:RefreshPolyZone()
    elseif IsControlPressed(0, 335) then -- Numpad -
        ZoneCreator.thickness = math.max(10.0, ZoneCreator.thickness - 0.5)
        ZoneCreator:RefreshPolyZone()
    end
end)

-- NUI Callbacks
RegisterNUICallback('startPrecinctZonePlacement', function(data, cb)
    SetNuiFocus(false, false)
    
    local points = data.points
    local thickness = data.thickness
    
    local coords = Citizen.Await(ZoneCreator:Start(points, thickness))
    
    SetNuiFocus(true, true)
    cb(coords or false)
end)
