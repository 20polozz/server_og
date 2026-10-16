Camera = {
    houseID = nil,
    house = nil,
    shell = nil,
    cameras = {},
    zone = nil,

    model = nil,
    entity = nil,
    coords = nil,
    rotation = nil,
    broken = false,
    cam = nil,

    cacheCloned = {},

    currentInterior = nil,
}

function Camera:new(data)
    data = data or {}
    local instance = setmetatable({}, self)
    self.__index = self

    instance.houseID = data.houseID
    instance.house = data.house
    instance.shell = data.shell
    instance.cameras = data.cameras
    instance.zone = data.zone

    return instance
end

function Camera:SetupCamera(id)
    local cam = self.cameras[id]

    if self.zone == 'exterior' then
        local center = vector3(self.house.positions.entry.x, self.house.positions.entry.y, self.house.positions.entry.z)
        if currentInteriorHouseID then
            self.currentInterior = currentInteriorHouseID
            local house = House.get(self.currentInterior)

            if not house then
                return
            end

            self:ClonePed()

            house:ExitHouse(true)

            self:SePlayerPosition(center, false)

            while not cam.entity or not DoesEntityExist(cam.entity) do
                Wait(100)
            end

            DoScreenFadeOut(250)
            Nui.SetLoading(true)

            self:StartCamera(id, cam)
        else
            local distance = #(GetEntityCoords(cache.ped) - center)

            DoScreenFadeOut(250)
            Nui.SetLoading(true)

            if distance < Config.RenderDistance then
                self:StartCamera(id, cam)
            else
                local cloned = self:ClonePed()
                if not cloned then
                    DoScreenFadeIn(250)
                    return
                end
                self:SePlayerPosition(center, false)
                while not cam.entity or not DoesEntityExist(cam.entity) do
                    Wait(100)
                end

                debugger('Camera created', cam.entity, cam.model)

                self:StartCamera(id, cam)
            end
        end
    elseif self.zone == 'interior' then
        local ped = cache.ped
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)

        if currentInteriorHouseID and currentInteriorHouseID ~= self.houseID then
            self.currentInterior = currentInteriorHouseID

            local house = House.get(self.currentInterior)

            if not house then
                return
            end

            self:ClonePed()

            house:ExitHouse(true)

            -- meter en la cassa de la camara
            local houseCam = House.get(self.houseID)
            if not houseCam then
                debugger('No house found')
                return
            end


            houseCam:EnterHouse(true)

            while not houseCam.shellData do
                debugger('Waiting loading exit point')
                Wait(100)
            end

            while not cam.entity or not DoesEntityExist(cam.entity) do
                Wait(100)
            end

            self:SePlayerPosition(houseCam.shellData.exitPoint.coords, {
                coords = coords,
                heading = heading,
            })

            self:StartCamera(id, cam)
        else
            local shell = self.shell
            
            if currentInteriorHouseID and not shell then
                debugger('No shell found')
                return
            end

            DoScreenFadeOut(250)
            Nui.SetLoading(true)

            if currentInteriorHouseID then
                if shell and shell.shellData and currentInteriorHouseID == shell.shellData.id then
                    self:StartCamera(id, cam)
                end
            else
                local house = House.get(self.houseID)

                if not house then
                    debugger('No house found')
                    return
                end

                local cloned = self:ClonePed()

                house:EnterHouse(true)

                while not house.shellData do
                    debugger('Waiting loading exit point')
                    Wait(100)
                end

                while not cam.entity or not DoesEntityExist(cam.entity) do
                    Wait(100)
                end

                self:SePlayerPosition(house.shellData.exitPoint.coords, {
                    coords = coords,
                    heading = heading,
                })

                self:StartCamera(id, cam)
            end
        end
    end
end

function Camera:StartCamera(id, cam)
    Nui.CloseHouseMenu()

    local maxRotation = Config.Cameras[cam.model] and Config.Cameras[cam.model].rotation or Config.DefaultRotation
    local offset = Config.Cameras[cam.model] and Config.Cameras[cam.model].offset or vector3(0.0, 0.0, 0.0)

    if self.cam then
        Wait(300)
        DestroyCam(self.cam)
        RenderScriptCams(false, false, 0, true, true)
        ClearFocus()
        ClearTimecycleModifier('scanline_cam_cheap')
        self.cam = nil
    end

    LocalPlayer.state:set('IsBusy', true, true)
    
    Wait(500)
    
    local rotation = cam.rotation
    if rotation then
        rotation = vector3(rotation.x + offset.x, rotation.y + offset.y, rotation.z + offset.z + 180.0)
    else
        rotation = vector3(-35.0, 0.0, 180.0)
    end
    
    self.cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', cam.coords.x, cam.coords.y, cam.coords.z, rotation, GetGameplayCamFov(), 1, 2)
    SetCamActive(self.cam, true)
    RenderScriptCams(true, true, 5, true, true)
    SetCamCoord(self.cam, cam.coords.x, cam.coords.y, cam.coords.z - 0.5)
    
    SetCamRot(self.cam, rotation)
    SetFocusPosAndVel(vec3(cam.coords.x, cam.coords.y, cam.coords.z), 0.0, 0.0, 0.0)
    Wait(1000)
    DoScreenFadeIn(300)
    Nui.SetLoading(false)
    
    SetTimecycleModifier('scanline_cam_cheap')
    SetTimecycleModifierStrength(1.0)
    
    Nui.ControlsNotify({
        keys = {
            { key= 'farriba', text = Config.Translations.controls.up },
            { key= 'fabajo', text = Config.Translations.controls.down },
            { key= 'fizquierda', text = Config.Translations.controls.left },
            { key= 'fderecha', text = Config.Translations.controls.right },
            { key = 'wheel', text = Config.Translations.controls.zoom },
            { key = 'borrar', text = Config.Translations.controls.exit },
        }
    })

    local initialRotation = GetCamRot(self.cam, 2).z
    local currentRotation = 0
    
    while self.cam do

        Utils.DisableControls({24, 25, 47, 58, 69, 70, 92, 114, 135, 140, 141, 142, 143, 199, 200, 202, 257, 263, 264, 331}, false)

        local camRot = GetCamRot(self.cam, 2)
        local camFov = GetCamFov(self.cam)
        
        local rotationSpeedFactor = camFov / 50
        
        if IsControlPressed(0, 172) then
            if camRot.x <= 0.0 then
                SetCamRot(self.cam, camRot.x + (0.7 * rotationSpeedFactor), 0.0, camRot.z, 2) 
            end 
        end
        
        if IsControlPressed(0, 173) then
            if camRot.x >= -50.0 then 
                SetCamRot(self.cam, camRot.x - (0.7 * rotationSpeedFactor), 0.0, camRot.z, 2) 
            end 
        end
        
        if IsControlPressed(0, 174) then -- gira a la izquierda
            if currentRotation <= maxRotation / 2 then
                currentRotation = currentRotation + (0.7 * rotationSpeedFactor)
                SetCamRot(self.cam, camRot.x, 0.0, camRot.z + (0.7 * rotationSpeedFactor), 2) 
            end 
        end
        
        if IsControlPressed(0, 175) then -- gira a la derecha
            if currentRotation >= -maxRotation / 2 then
                currentRotation = currentRotation - (0.7 * rotationSpeedFactor)
                SetCamRot(self.cam, camRot.x, 0.0, camRot.z - (0.7 * rotationSpeedFactor), 2) 
            end 
        end
        
        if IsControlPressed(0, 242) then 
            if camFov <= 50.0 then 
                SetCamFov(self.cam, camFov + 1) 
            end 
        end
        
        if IsControlPressed(0, 241) then 
            if camFov >= 5.0 then 
                SetCamFov(self.cam, camFov - 1) 
            end 
        end
        
        if IsControlJustPressed(0, 177) then
            self:StopCamera()
            break
        end
        
        Wait(0)
    end
end

function Camera:ClonePed()

    local ped = cache.ped
    local pedCoords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    self.cacheCloned.ped = ClonePed(ped, true, true, true)
    local attempt = 0

    while not NetworkHasControlOfEntity(self.cacheCloned.ped) and attempt < 100 and DoesEntityExist(self.cacheCloned.ped) do
        Wait(100)
        NetworkRequestControlOfEntity(self.cacheCloned.ped)
        attempt = attempt + 1
    end

    FreezeEntityPosition(self.cacheCloned.ped, true)
    SetBlockingOfNonTemporaryEvents(self.cacheCloned.ped, true)
    SetPedConfigFlag(self.cacheCloned.ped, 79, true)
    SetEntityHeading(self.cacheCloned.ped, heading)
    SetPedRelationshipGroupHash(self.cacheCloned.ped, GetHashKey('PLAYER'))

    self.cacheCloned.ped = NetworkGetNetworkIdFromEntity(self.cacheCloned.ped)

    return true
end

function Camera:SePlayerPosition(coords, interior)
    local ped = cache.ped
    local pedCoords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    
    interior = interior or false
    SetEntityVisible(cache.ped, false)
    SetEntityCoords(cache.ped, coords - vector3(0.0, 0.0, 5.0))
    FreezeEntityPosition(cache.ped, true)

    if interior then
        self.cacheCloned.coords = interior.coords
        self.cacheCloned.heading = interior.heading
    else
        self.cacheCloned.coords = pedCoords
        self.cacheCloned.heading = heading
    end
end

function Camera:StopCamera() --todo Si se le mata al ped, matar al player cuando se cierra el camera
    if self.cam then
        DoScreenFadeOut(250)
        Wait(300)
        DestroyCam(self.cam)
        RenderScriptCams(false, false, 0, true, true)
        ClearFocus()
        ClearTimecycleModifier('scanline_cam_cheap')
        self.cam = nil
        Nui.ControlsNotify()
        Wait(500)
        DoScreenFadeIn(300)
    end

    if self.cacheCloned.ped then
        TriggerServerEvent('origen_housing:server:deleteEntity', self.cacheCloned.ped)

        local house = House.get(self.currentInterior or self.houseID)
        if not house then
            debugger('No house found')
            return
        end

        if self.currentInterior then 
            house:EnterHouse(true)

            Wait(300)

            DoScreenFadeIn(500)
        else
            house:ExitHouse(true)
        end


        SetEntityCoords(cache.ped, self.cacheCloned.coords.x, self.cacheCloned.coords.y, self.cacheCloned.coords.z - 1)
        SetEntityHeading(cache.ped, self.cacheCloned.heading)
        FreezeEntityPosition(cache.ped, false)
        SetEntityVisible(cache.ped, true)

    end
    self.cacheCloned = {}
    self.currentInterior = nil

    LocalPlayer.state:set('IsBusy', false, true)
end


AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then
        return
    end

    ClearTimecycleModifier('scanline_cam_cheap')

    LocalPlayer.state:set('IsBusy', false, true)
end)