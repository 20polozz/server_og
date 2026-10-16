__indexShells = {}
__indexShellsData = {}
local missingShells = {}
local shellCount = {
    small = 0,
    medium = 0,
    big = 0,
}

CreateThread(function()
    for category, _ in pairs(Config.Interiors) do
        __indexShellsData[category] = {}
        
        for id, shell in pairs(Config.Interiors[category]) do
            __indexShells[shell.model] = shell
            if Utils.CheckModelExist(shell.model) or shell.model:find('kq_') then
                __indexShellsData[category][shellCount[category]] = shell
                shellCount[category] = shellCount[category] + 1
            else
                missingShells[#missingShells+1] = shell.model
            end
        end
    end
end)

Shell = {
    model = nil,
    entity = nil,
    coords = nil,
    shellData = {},
    force = false,

    exitPoint = nil,
    exitCoords = nil,
    inside = false,

    createdShells = {},

    minMax = nil,

    zone = nil,
    shellZone = {},

    ipl = {},
}

function Shell:new(data)
    data = data or {}
    local instance = setmetatable({}, self)
    self.__index = self

    instance.shellData = data
    -- instance.force = false
    instance.inside = false
    instance.entity = nil
    instance.exitCoords = (__indexShells[data.data.model] and __indexShells[data.data.model].offset) or false
    instance.zone = {}
    instance.shellZone = nil
    instance.ipl = {}
    
    return instance
end

function Shell:CreateShell(data)
    self.model = GetHashKey(self.shellData.data.model) 

    if not IsModelValid(self.model) then
        print("^1DEBUG: Model is invalid:^7", self.shellData.data.model)
        debugger('Model not valid', self.model)
        return
    end

    lib.requestModel(self.model)

    local houseId = tonumber(self.shellData.id) or 1
    local gridX = houseId % 6
    local gridY = math.floor((houseId % 36) / 6)
    local gridZ = houseId % 10
    
    local entry = self.shellData.positions.entry
    self.coords = vector4(
        entry.x + (gridX * 25.0) - 62.5,
        entry.y + (gridY * 25.0) - 62.5,
        2000.0 + (gridZ * 40.0),
        entry.w or 0.0
    )

    self.entity = CreateObjectNoOffset(self.model, self.coords.x, self.coords.y, self.coords.z, false, false, false)
    
    FreezeEntityPosition(self.entity, true)
    SetEntityRotation(self.entity, self.coords.w, 2, true)
    SetLocalPlayerAsGhost(true)
    DoScreenFadeOut(500)
    SetModelAsNoLongerNeeded(self.model)
    Wait(300)

    local min, max = GetModelDimensions(self.model)

    self.minMax = self:getMinMax(vector3(self.coords.x, self.coords.y, self.coords.z), min, max)
    
    self.createdShells[#self.createdShells+1] = self

    self:CreateZone()

    -- Modalidad libre: el módulo es un ancla y la casa se monta alrededor,
    -- antes de llevar al jugador dentro (custom/client/obra.lua).
    if Obra then Obra.Montar(self.shellData, self.entity) end
    -- La entrada elegida por el dueño: dónde aparece quien entra y dónde queda
    -- el punto de salir (custom/client/entradas.lua).
    if Entradas then pcall(Entradas.AlCrear, self) end

    if data and data.onEnter then
        data.onEnter(self)
    end

    self.force = data.force

    self:Enter()

    if not self.force then
        DoScreenFadeIn(500)
    end
    self:CreateExitPoint()
end

function Shell:Enter()
    TriggerServerEvent('origen_housing:server:enterHouse', self.shellData.id)
    SetLocalPlayerAsGhost(true)
    DoScreenFadeOut(500)
    Wait(650)
    local ped = cache.ped
    Internal.DisableWeatherSync()
    local offset = GetOffsetFromEntityInWorldCoords(self.entity, self.exitCoords.x, self.exitCoords.y, self.exitCoords.z)

    if not self.force then
        SetPedCoordsKeepVehicle(ped, offset.x, offset.y, offset.z)
    end

    local house = House.get(self.shellData.id)
    if not house:hasKey() then
        local sensor = house.houseData.settings.upgrades.sensors
        if sensor then
            TriggerServerEvent('origen_housing:server:sensorAlert', self.shellData.id)
        end
    end
    
    self.inside = true
    currentInteriorHouseID = self.shellData.id
    SetLocalPlayerAsGhost(false)
end

function Shell:EnterIPL(data)
    self.ipl = data.ipl

    if data and data.onEnter then
        data.onEnter(self)
    end

    self.force = data.force

    debugger('Enter ipl with id: '..self.shellData.id, 'with force: '..tostring(force))

    TriggerServerEvent('origen_housing:server:enterHouse', self.shellData.id)
    SetLocalPlayerAsGhost(true)
    DoScreenFadeOut(500)
    Wait(650)

    local theme = self.shellData.data.style or false
    local iplStyles = __indexIpls[self.shellData.data.model]
    if iplStyles and theme then
        local iplData = iplStyles.GetData().Style
        if iplData and iplData.Theme then
            local styleData = iplData.Theme[theme]
            if styleData then
                iplData.Set(styleData, true)
            end
        end
    end

    local ped = cache.ped
    self.inside = true

    if not self.force then
        SetPedCoordsKeepVehicle(ped, self.ipl.enter.x, self.ipl.enter.y, self.ipl.enter.z)
    end

    SetLocalPlayerAsGhost(false)

    currentInteriorHouseID = self.shellData.id

    local house = House.get(self.shellData.id)
    if not house:hasKey() then
        local sensor = house.houseData.settings.upgrades.sensors
        if sensor then
            TriggerServerEvent('origen_housing:server:sensorAlert', self.shellData.id)
        end
    end
 
    self:CreateExitPoint()
    
    if not self.force then
        DoScreenFadeIn(500)
    end
end

function Shell:Exit(force)
    local coords

    force = force or false

    -- Salir decorando el interior (la E de la puerta sigue viva mientras se
    -- coloca un mueble) dejaba el modo muebles abierto fuera de la casa:
    -- controles bloqueados y el raton cogido. Se cierra por la puerta de siempre.
    if Furniture.active and Furniture.currentHouse and Furniture.currentHouse.id == self.shellData.id
        and Furniture.currentHouse.zone == 'interior' then
        Furniture:CloseFurniture()
    end

    if not force then
        if self.shellData.data.type == 'shell' then
            if self.exitCoords then
                coords = GetOffsetFromEntityInWorldCoords(self.entity, self.exitCoords.x, self.exitCoords.y, self.exitCoords.z)
            end
        else
            if self.ipl.enter then
                coords = vector3(self.ipl.enter.x, self.ipl.enter.y, self.ipl.enter.z)
            end
        end
    end

    local isIPL = self.shellData.data.type == 'ipl' and true or false
    
    currentInteriorHouseID = false
    DoScreenFadeOut(500)
    Wait(650)
    TriggerServerEvent('origen_housing:server:exitHouse', self.shellData.id)

    debugger('Exit shell with id: '..self.shellData.id, 'with force: '..tostring(force))
    
    if not force then
        SetPedCoordsKeepVehicle(cache.ped, self.shellData.positions.entry.x, self.shellData.positions.entry.y, self.shellData.positions.entry.z)
    end
    
    self.inside = false
    
    if not isIPL then
        self:RemoveShell(force)
        self:DestroyZone()
        Internal.EnableWeatherSync()
    end
    
    SetLocalPlayerAsGhost(false)
    DoScreenFadeIn(500)
    local house = House.get(self.shellData.id)
    house:DeleteFurniture('interior')
    
    if Config.ExternalInteractionSystem then
        Custom.RemoveCoordsInteraction('exit_house_'..self.shellData.id, coords)
    else
        if self.exitPoint then
            self.exitPoint:remove()
            self.exitPoint = nil
        end
    end
    
    Custom.OnExitHouse(self.id)
    debugger('Remove interior furniture')
end

function Shell:RemoveShell(force)
    local coords

    if not force then
        if self.shellData.data.type == 'shell' then
            if self.exitCoords then
                coords = GetOffsetFromEntityInWorldCoords(self.entity, self.exitCoords.x, self.exitCoords.y, self.exitCoords.z)
            end
        else
            if self.ipl.enter then
                coords = vector3(self.ipl.enter.x, self.ipl.enter.y, self.ipl.enter.z)
            end
        end
    end
    
    if self.entity and DoesEntityExist(self.entity) then 
        DeleteEntity(self.entity)
        self.entity = nil
    end

    if Config.ExternalInteractionSystem then
        Custom.RemoveCoordsInteraction('exit_house_'..self.shellData.id, coords)
    else
        if self.exitPoint then
            self.exitPoint:remove()
            self.exitPoint = nil
        end
    end
end

function Shell:CreateExitPoint()
    local coords

    if self.shellData.data.type == 'shell' then
        coords = GetOffsetFromEntityInWorldCoords(self.entity, self.exitCoords.x, self.exitCoords.y, self.exitCoords.z)
    else
        coords = vector3(self.ipl.enter.x, self.ipl.enter.y, self.ipl.enter.z)
    end

    local function OnExitHouse()
        -- (casas de modalidad libre: con el vehículo se sale por la entrada de garaje)
        if Entradas and Entradas.SalidaConCoche(self) then return end
        if self.shellData.owned then
            local mainDoor = self.shellData.doors and (self.shellData.doors['1'] or self.shellData.doors[1])
            local doorLocked = mainDoor and mainDoor.locked
            local house = House.get(self.shellData.id)
            
            if doorLocked then
                if (Config.KeyHoldersNeedDoorUnlocked and not house:hasKey()) or (not Config.KeyHoldersNeedDoorUnlocked and not house:hasKey()) then
                    Internal.Notify(Config.Translations.notify.error.doorLocked, 'error', 5000)
                    return
                end
            end
        end

        self:Exit()
    end

    if Config.ExternalInteractionSystem then 
        Custom.CreateCoordsInteraction('exit_house_'..self.shellData.id, coords, 10.0, 1.5, false, Config.Translations.drawtext.exit, OnExitHouse)

        if self.shellData.owned then
            local mainDoor = self.shellData.doors and (self.shellData.doors['1'] or self.shellData.doors[1])
            local isLocked = mainDoor and (mainDoor.locked == true or mainDoor.locked == 1)
            local lockLabel = isLocked and Config.Translations.drawtext.unlock or Config.Translations.drawtext.lock
            Custom.CreateCoordsInteraction('exit_house_lock_'..self.shellData.id, coords, 10.0, 1.5, false, lockLabel, function()
                local house = House.get(self.shellData.id)
                if house then
                    house:ToggleMainDoor()
                end
            end)
        end

        self.exitPoint = {
            coords = coords,
            distance = 10.0,
        }
    else
        local function nearby(data)
            DrawMarker(data.config.type, vec3(coords.x, coords.y, coords.z - 1) + data.config.coords, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, data.config.size.x, data.config.size.y, data.config.size.z, data.config.color[1], data.config.color[2], data.config.color[3], data.config.color[4], data.config.bobUpAndDown, data.config.faceCamera, 2, data.config.rotate, nil, false, false)
            if data.currentDistance < 2.0 then
                if self.shellData.owned then
                    local house = House.get(self.shellData.id)
                    local mainDoor = self.shellData.doors and (self.shellData.doors['1'] or self.shellData.doors[1])
                    local isLocked = mainDoor and (mainDoor.locked == true or mainDoor.locked == 1)
                    local lockText = isLocked and Config.Translations.drawtext.unlock or Config.Translations.drawtext.lock
                    local currentText = string.format("%s | [G] %s", Config.Translations.drawtext.exit, lockText)

                    if data.text ~= currentText or not data.noty then
                        Internal.DrawText(currentText, 'E')
                        data.text = currentText
                        data.noty = true
                    end

                    if IsControlJustPressed(0, 38) then -- E key
                        OnExitHouse()
                        if data.noty then
                            Internal.HideText()
                            data.noty = false
                            data.text = nil
                        end
                    elseif IsControlJustPressed(0, 47) then -- G key
                        if house then
                            house:ToggleMainDoor()
                        end
                    end
                else
                    if not data.noty and currentInteriorHouseID then
                        Internal.DrawText(Config.Translations.drawtext.exit, 'E')
                        data.noty = true
                    end
                    if IsControlJustPressed(0, 38) then
                        OnExitHouse()

                        if data.noty then
                            Internal.HideText()
                            data.noty = false
                            data.text = nil
                        end
                    end
                end
            else
                if data.noty then
                    Internal.HideText()
                    data.noty = false
                    data.text = nil
                end
            end
        end

        self.exitPoint = lib.points.new({
            coords = coords,
            distance = 5.0,
            noty = false,
            nearby = nearby,
            config = Config.Markers.general,
        })
    end
end

function Shell:CreateZone()
    local function onExit(data)
        Wait(1000)
        if not currentInteriorHouseID then
            return
        end
        self:Exit()
    end

    local height = self.minMax.max.z - self.minMax.min.z

    if not next(self.zone) then
        self.zone[#self.zone+1] = vector3(self.minMax.min.x, self.minMax.max.y, self.minMax.max.z - height / 2)
        self.zone[#self.zone+1] = vector3(self.minMax.min.x, self.minMax.min.y, self.minMax.max.z - height / 2)
        self.zone[#self.zone+1] = vector3(self.minMax.max.x, self.minMax.min.y, self.minMax.max.z - height / 2)
        self.zone[#self.zone+1] = vector3(self.minMax.max.x, self.minMax.max.y, self.minMax.max.z - height / 2)
    end
    
    self.shellZone = lib.zones.poly({
        points = self.zone,
        debug = false,
        thickness = height * 2,
        onExit = onExit
    })
end

function Shell:DestroyZone()
    if self.shellZone and next(self.shellZone) then
        self.shellZone:remove()
        self.shellZone = nil
    end
end

function Shell:getMinMax(coords, min, max)
    local min = vector3(coords.x + min.x, coords.y + min.y, coords.z + min.z)
    local max = vector3(coords.x + max.x, coords.y + max.y, coords.z + max.z)
    
    return {min = min, max = max}
end

function Shell:isInside(coords)
    local extent = self.minMax
    local isX = coords.x >= extent.min.x and coords.x <= extent.max.x
    local isY = coords.y >= extent.min.y and coords.y <= extent.max.y
    local isZ = coords.z >= extent.min.z and coords.z <= extent.max.z
    if isX and isY and isZ then
        return true
    end
    return false
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then
        return
    end

    if Shell.createdShells then
        for _, shell in pairs(Shell.createdShells) do
           DeleteEntity(shell.entity)
        end 
    end
end)