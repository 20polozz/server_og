IsCreatingZone = false

Creation = {
    active = false,
    coords = {},
    
    initialHeight = nil,
    currentZone = nil,
    points = {},
    thickness = 50,
    colors = {
        normal = vec4(255, 0, 0, 50.0),
        complete = vec4(0, 255, 0, 50.0),
    }
}

AddEventHandler('freecam:onTick', function()
    if not Creation.active then return end

    local camPos = Freecam:GetPosition()
    local camRot = Freecam:GetRotation()

    local _, lookAt = GetScreenCoords(250.0, camPos, camRot)

    if lookAt and camPos then 
        DrawLine(lookAt.x, lookAt.y, 0.0, lookAt.x, lookAt.y, 2000.0, 255, 0, 0, 255)
    end

    if IsControlJustPressed(0, 24) or IsDisabledControlJustPressed(0, 24) then
        if not Creation.currentZone then

        end

        Creation.points[#Creation.points + 1] = vector3(lookAt.x, lookAt.y, lookAt.z)
        Creation:RefreshPolyZone()
    end

    if IsControlJustPressed(0, 177) or IsDisabledControlJustPressed(0, 177) then -- Backspace, return
        if Creation.currentZone then 
            if #Creation.points > 1 then
                Creation.points[#Creation.points] = nil
                Creation:RefreshPolyZone()
            else
                Creation:RemoveZone()
            end
        else
            Creation.active = false
            Creation:RemoveZone()
            Freecam:DestroyCam()
        end
    end

    if IsControlJustPressed(0, 215) or IsDisabledControlJustPressed(0, 215) then -- Enter
        if Creation.currentZone and #Creation.points >= 4 then
            local coords = {
                points = {},
                thickness = Creation.thickness,
            }
            for k,v in pairs(Creation.points) do
                coords.points[#coords.points + 1] = { x = v.x, y = v.y, z = Creation.initialHeight }
            end

            Creation.coords = coords

            Creation:RemoveZone()
            Freecam:DestroyCam()
            Creation.active = false
        else
            -- Custom.Notify(Config.Translations.notify.error.notEnoughAnyPoints, 'error', 5000)
        end
    end

    if IsControlPressed(0, 334) then
        if Creation.thickness > 10 then
            Creation.thickness = Creation.thickness - 1
            Creation:RefreshPolyZone()
        end
    elseif IsControlPressed(0, 335) then
        Creation.thickness = Creation.thickness + 1
        Creation:RefreshPolyZone()
    end
end)

function Creation:CreateExteriorZone(zone)

    if self.active then
        -- return Custom.Notify(Config.Translations.notify.error.alreadyCreating, 'error', 5000)
        return
    end
    
    self.active = true
    IsCreatingZone = true

    -- Quitar NUI focus antes de entrar a freecam
    SetNuiFocus(false, false)

    Freecam:CreateCam(true, 200, 10.0)

    if zone then 
        self.points = zone.points
        self.thickness = zone.thickness
        self.initialHeight = zone.points[1].z

        self:RefreshPolyZone()
    else
        self.initialHeight = GetEntityCoords(cache.ped).z
    end

    while self.active do 
        Wait(1000)
    end
    
    Freecam:DestroyCam()
    self.initialHeight = nil
    self.points = {}
    self.thickness = 50
    IsCreatingZone = false

    -- Restaurar NUI focus para el panel admin
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)

    if not self.coords or not next(self.coords) then
        return false
    end

    return self.coords
end

function Creation:RefreshPolyZone()
    self:RemoveZone()

    if #self.points > 0 then
        local color = self.colors.normal
        if #self.points == 1 then 
            self.initialHeight = self.points[1].z
        elseif #self.points >= 4 then
            color = self.colors.complete
        end
        self.points[#self.points] = vector3(self.points[#self.points].x, self.points[#self.points].y, self.initialHeight)

        self.currentZone = lib.zones.poly({
            name = 'newHouse_'..cache.serverId,
            debugColour = color,
            points = self.points,
            thickness = self.thickness,
            debug = true
        })
    end
end

function Creation:RemoveZone()
    if self.currentZone then
        self.currentZone:remove()
        self.currentZone = nil
    end
end