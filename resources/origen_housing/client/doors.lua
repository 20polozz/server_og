Doors = {
    lastEntity = 0,
    creatingDoor = false,

    doors = {},
    data = {},
}

function Doors:StartCreation(data)
    
    if self.creatingDoor or not data.type then return end
    local originalHouse = currentExteriorHouseID
    
    self.data = data

    local count = self.data.type == 'double' and 2 or 1

    Nui.ControlsNotify({
        keys = {
            { key= 'lclick', text = Config.Translations.controls.addDoor},
            { key= 'rclick', text = Config.Translations.controls.cancel },
        }
    })

    self.creatingDoor = true

    LocalPlayer.state:set('IsBusy', true, true)

    while true do
        if originalHouse ~= currentExteriorHouseID then
            break
        end
        local ped = cache.ped 
        local pedCoords = GetEntityCoords(ped)

        Utils.DisableControls({24, 25}, false)

        local hit, coords, entity = Utils.GetScreenCoords()
        local doorA = self.doors[1]?.entity

        local newEntity = self.lastEntity ~= entity

        if newEntity and self.lastEntity ~= doorA then
            self:DrawEntity(self.lastEntity, false)
        end

        self.lastEntity = entity

        if hit and entity > 0 and GetEntityType(entity) == 3 and (count == 1 or doorA ~= entity) then
            if newEntity then
                self:DrawEntity(entity, true)
            end

            DrawLine(pedCoords, coords.x, coords.y, coords.z, 255, 255, 255, 100)

            if IsDisabledControlJustPressed(0, 24) then
                self:addDoor(entity)

                if #self.doors == count then
                    self:FinishCreation()
                    break
                end
            end

        end
        if IsDisabledControlJustPressed(0, 25) then
            break
        end

        Wait(0)
    end

    self.creatingDoor = false

    LocalPlayer.state:set('IsBusy', false, true)

    Nui.ControlsNotify()

    self:DrawEntity(self.lastEntity, false)
end

function Doors:FinishCreation()
    if #self.doors == 2 then
        SetEntityDrawOutline(self.doors[1].entity, false)
        SetEntityDrawOutline(self.doors[2].entity, false)
        self.doors[1].entity = nil
        self.doors[2].entity = nil
        self.data.doors = self.doors
    else
        SetEntityDrawOutline(self.doors[1].entity, false)
        self.data.model = self.doors[1].model
        self.data.coords = self.doors[1].coords
        self.data.heading = self.doors[1].heading
    end
    TriggerServerEvent('origen_housing:server:createDoor', self.data)

    self.doors = {}
    self.lastEntity = 0
    self.data = {}
end

function Doors:addDoor(entity)
    local house = House.get(currentExteriorHouseID or currentInteriorHouseID)

    if not house then
        return
    end

    local restrictedZone = false
    local zone = currentInteriorHouseID and 'interior' or 'exterior'
    
    if zone == 'exterior' then
        restrictedZone = house.houseData.polyzone
    elseif zone == 'interior' and house.houseData.data.type == 'shell' then
        restrictedZone = house.houseData.shell and house.houseData.shell.zone
    end

    local model = GetEntityModel(entity)
    local coords = GetEntityCoords(entity)
    
    local isInside = true
    if restrictedZone then
        isInside = Utils.isInsidePolyzone(vector3(coords.x, coords.y, coords.z), restrictedZone)
    end

    if not isInside then return end

    local isFurniture = Entity(entity).state

    if isFurniture.entityID then 
        self.data.id = isFurniture.entityID
        self.data.isFurniture = true
    end
    
    AddDoorToSystem(`temp`, model, coords.x, coords.y, coords.z, false, false, false)
    DoorSystemSetDoorState(`temp`, 4, false, false)
    self:DrawEntity(entity, true)

    self.doors[#self.doors + 1] = {
        entity = entity,
        model = model,
        coords = coords,
        heading = math.floor(GetEntityHeading(entity) + 0.5)
    }

    RemoveDoorFromSystem(`temp`)
end

function Doors:DrawEntity(entity, bool)
    SetEntityDrawOutline(entity, bool)
    SetEntityDrawOutlineColor(255, 255, 255, 100)
    SetEntityDrawOutlineShader(1)
end