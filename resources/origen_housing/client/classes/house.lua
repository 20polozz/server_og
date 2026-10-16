HouseData = {}
currentExteriorHouseID = false
currentInteriorHouseID = false
currentDoorID = false

MyHouses = {}

House = {}
House.__index = House
House.table = {}

local props = {}
local peds = {}

function House.new(data)
    if House.table[data.id] then return House.table[data.id] end

    local self = setmetatable({}, House)
    self.houseData = data
    self.houseData.furniture = {
        interior = {},
        exterior = {}
    }
    self.id = data.id
    self.owned = data.citizenid or false
    self.nearby = false
    self.renderZone = nil
    self.exteriorZone = nil
    self.entryPoint = nil
    self.garagePoint = nil

    self.exteriorFurniture = {}
    self.interiorFurniture = {}
    self.exteriorInterectable = {}
    self.interiorInterectable = {}

    self.blip = nil

    self.building = {
        model = nil,
        object = nil,
        stage = 0,
        props = {},
        peds = {},
    }

    self.garage = (__indexGarages[data.garage] and __indexGarages[data.garage]) or false

    self.shell = nil
    self.shellData = nil

    self.cameras = {}
    self.lights = {}
    self.lightPoints = {}
    self.doors = {}
    self.doorPoints = {}
    self.boards = {}
    self.teles = {}
    self.mloPoints = {}

    House.table[self.id] = self

    if Config.EnablePreloadMethod then
        local preload = Preload.get(self.id)

        if preload then
            preload:removeRender()
        end
    end

    return self
end

function House.get(id, filters)
    id = tonumber(id)
    if filters then
        if filters.getFurniture then
            if filters.zone then
                return House.table[id] and House.table[id].houseData.furniture[filters.zone] or {}
            else
                return House.table[id] and House.table[id].houseData.furniture or {}
            end
        end
    end
    return House.table[id] or false
end

function House:hasKey(checkOwner)
    if playerIdentifier == self.owned then return true end

    if not self.houseData.holders then
        debugger('House has no holders', self.id) -- Aca se le frena
        return false
    end

    local holder = self.houseData.holders[playerIdentifier]

    if not holder then return false end
    if checkOwner then
        debugger('User is owner', self.id)
        return holder.owner or false
    end
    return true
end

local function requestFurniture(houseID, zone)
    local house = House.get(houseID)
    if not house then return end
    if not next(house.houseData.furniture[zone]) then
        local furniture = lib.callback.await('origen_housing:server:getFurniture', false, { houseID = houseID, zone = zone })
        if furniture then 
            house.houseData.furniture[zone] = furniture
        end
    end
end

function House.CreateBlip(houseID)
    local house = House.get(houseID)
    if not house then return end

    local clave = 'casa_' .. tostring(houseID)
    house.blip = nil

    --[[ Quien ve una casa en el mapa

         SIN DUENO: todo el mundo. Una casa que el admin pone a la venta tiene
         que verse en los dos mapas de Origen para poder ir a verla; si no, la
         unica forma de encontrarla es tropezarse con ella por la calle.

         CON DUENO: solo quien tiene llave. En cuanto alguien la compra, el
         punto se va del mapa de los demas y al dueno le queda marcada como su
         casa. El cambio llega solo: el servidor avisa a todos los clientes y
         cada uno vuelve a pasar por aqui.

         `hideBlip` es la salida para una casa concreta que no se quiera
         anunciar. Se mira antes que nada y tapa los dos casos. ]]
    if house.houseData.data.hideBlip then
        Utils.QuitarDelMapa(clave)
        return
    end

    if house.owned and not house:hasKey() then
        Utils.QuitarDelMapa(clave)
        return
    end

    local blipName = (house.owned and Config.Translations.general.houseBlipName:format(house.houseData.data.number)) or Config.Translations.general.houseInSale:format(house.houseData.data.number)

    if Config.UseNameInBlipInsteadOfId then
        blipName = (house.owned and Config.Translations.general.houseBlipName:format(house.houseData.name)) or Config.Translations.general.houseInSale:format(house.houseData.name)
    end
    
    --[[ En venta o tuya. Con dueño solo llega aqui quien tiene llave (ver
         arriba), asi que «comprada» ya es «tuya»: tu casa, en rosa y con la
         chincheta de lo propio. La que no tiene dueño lleva el cartel de venta. ]]
    house.blip = Utils.MarcarEnMapa(clave, house.houseData.positions.entry, blipName, nil, {
        icono = house.owned and 'casa' or 'casa_venta',
        mia = house.owned and true or false,
    })
end

function House:CreateHouse()

    local function onEnter(data)
        debugger('Enter house range with id: '..self.id)
        self:CreateExteriorZone()

        self:CreateEntryPoint()

        if self.owned and self.houseData.positions.garage and next(self.houseData.positions.garage) then
            self:CreateGaragePoint()
        end

        if self.houseData.data.type == 'mlo' and self.owned then
            self:CreateMloPoints()
        end

        if self.houseData.construction and self.houseData.construction.enabled then
            self:CreateBuilding()
        end

        if not Config.LoadFurnitureOnlyInPolyzone then
            requestFurniture(self.id, 'exterior')
            self:LoadFurniture('exterior')
        end

        if Config.Blip.showBlipInDistance then 
            House.CreateBlip(self.id)
        end

        self.nearby = true
    end

    local function onExit(data)
        debugger('Exit house range with id: '..self.id)
        if self.entryPoint then
            if Config.ExternalInteractionSystem then
                local coords = vector3(self.houseData.positions.entry.x, self.houseData.positions.entry.y, self.houseData.positions.entry.z + 1.0)
                Custom.RemoveCoordsInteraction('entry_house_'..self.id, coords)
            else
                self.entryPoint:remove()
            end
        end
        if self.garagePoint then
            if Config.ExternalInteractionSystem then
                local coords = vector3(self.houseData.positions.garage.x, self.houseData.positions.garage.y, self.houseData.positions.garage.z + 1.0)
                Custom.RemoveCoordsInteraction('garage_house_'..self.id, coords)
            else
                self.garagePoint:remove()
            end
        end

        Internal.RemoveGarage(self.id)

        if self.exteriorZone then
            self.exteriorZone:remove()
        end

        if self.houseData.construction and self.houseData.construction.enabled then
            self:RemoveBuilding()
        end

        if not Config.LoadFurnitureOnlyInPolyzone then
            self:DeleteFurniture('exterior')
            self:RemoveExteriorInteractable()
        end

        if self.mloPoints then
            self:RemoveMloPoints()
        end

        --- El ajuste de "solo se marca cuando estas cerca": al alejarte, el
        --- punto se quita del mapa igual que antes se quitaba el blip.
        if Config.Blip.showBlipInDistance then
            Utils.QuitarDelMapa('casa_' .. tostring(self.id))
            self.blip = nil
        end

        -- Solo si se esta decorando ESTA casa. Antes cualquier casa que
        -- quedaba atras cerraba el modo muebles a medias (active a false sin
        -- CloseFurniture: IsBusy a true) y soltaba el foco de cualquier
        -- panel del recurso que estuviera abierto.
        if Furniture.active and Furniture.currentHouse and Furniture.currentHouse.id == self.id then
            Furniture:CloseFurniture()
        end

        self.nearby = false
    end

    -- Se guardan para poder rehacer el punto cuando cambia el radio de carga
    -- (House:RehacerZonaExterior).
    self.alEntrarEnRango = onEnter
    self.alSalirDeRango = onExit
    self:CrearPuntoDeCarga()

    if not Config.Blip.showBlipInDistance then
        House.CreateBlip(self.id)
    end


    LoadDoors(self.id)

    House.table[self.id] = self
    HouseData[self.id] = self.houseData

    debugger('Created house', self.id)
end

--[[ La zona exterior que vale: en una casa de banda con territorio, el
     polígono del territorio principal de la banda (lo resuelve el servidor,
     custom/server/propietario.lua, y llega en `exteriorBanda`); en las demás,
     la dibujada a mano. ]]
function House:ZonaDeBanda()
    local zona = self.houseData.exteriorBanda
    if type(zona) == 'table' and type(zona.points) == 'table' and #zona.points >= 3 then return zona end
    return nil
end

-- El punto que carga la casa al acercarse. En una casa de banda el radio
-- llega hasta el vértice más lejano del territorio: los muebles de fuera
-- pueden estar en cualquier parte de él.
function House:CrearPuntoDeCarga()
    local center = self.houseData.positions.entry
    local zona = self:ZonaDeBanda()
    local radio = Config.RenderDistance
    if zona and tonumber(zona.radio) and zona.radio > radio then radio = zona.radio + 0.0 end

    self.renderZone = lib.points.new({
        coords = vector3(center.x, center.y, center.z),
        distance = radio,
        onEnter = self.alEntrarEnRango,
        onExit = self.alSalirDeRango,
    })
end

-- La zona exterior ha cambiado (otra banda, otro territorio, o ya ninguno):
-- se descarga la casa como al alejarse y se vuelve a cargar con la zona nueva.
function House:RehacerZonaExterior()
    if not self.renderZone then return end
    if self.nearby and self.alSalirDeRango then self.alSalirDeRango() end
    if currentExteriorHouseID == self.id then currentExteriorHouseID = false end
    self.exteriorZone = nil
    self.renderZone:remove()
    self:CrearPuntoDeCarga()
end

function House:CreateExteriorZone()
    -- El territorio de una banda es enorme y dentro hay otras casas con su
    -- zona: la de banda nunca le quita el sitio a la de una casa normal.
    local deBanda = self:ZonaDeBanda()

    local function onEnter(data)
        if not deBanda or not currentExteriorHouseID then
            currentExteriorHouseID = data.houseID
        end
        if Config.LoadFurnitureOnlyInPolyzone then
            requestFurniture(self.id, 'exterior')
            self:LoadFurniture('exterior')
        end

        -- Si los muebles aún no han llegado (al entrar al servidor junto a la
        -- casa), no hay cuadros todavía: los pinta LoadFurniture al acabar.
        self:PintarCuadros('exterior')
    end

    local function onExit(data)
        if not deBanda or currentExteriorHouseID == self.id then
            currentExteriorHouseID = false
        end

        CreateThread(function()
            -- Colocando un mueble fuera se puede salir andando de la zona:
            -- el modo muebles de esta casa se cierra por la puerta de siempre.
            if Furniture.active and Furniture.currentHouse and Furniture.currentHouse.id == self.id
                and Furniture.currentHouse.zone == 'exterior' then
                Furniture:CloseFurniture()
            end

            -- DestroyBoard espera el id (la clave), no la tabla del cuadro:
            -- con la tabla no encontraba nada y la DUI no se liberaba nunca.
            -- Solo los de fuera: al entrar a la casa esta salida llega después
            -- de pintar los del interior y los apagaba.
            for k, cuadro in pairs(self.boards) do
                if cuadro.zone ~= 'interior' then
                    self:DestroyBoard(k)
                end
            end

            if Config.LoadFurnitureOnlyInPolyzone then
                self:DeleteFurniture('exterior')
                self:RemoveExteriorInteractable()
            end
        end)
    end

    local function inside(data)
        if not currentExteriorHouseID then
            currentExteriorHouseID = data.houseID
        end
    end

    local thickness = 50.0
    local points = self.houseData.exterior

    if self.houseData.exterior and self.houseData.exterior.points then
        points = self.houseData.exterior.points
        thickness = self.houseData.exterior.thickness
    end

    if deBanda then
        points = deBanda.points
        thickness = tonumber(deBanda.thickness) or 600.0
    end

    self.houseData.polyzone = points

    self.exteriorZone = lib.zones.poly({
        points = points,
        debug = false,
        thickness = thickness,
        houseID = self.id,
        inside = inside,
        onEnter = onEnter,
        onExit = onExit,
    })
end

function House:ToggleMainDoor()
    if not self:hasKey() then
        Internal.Notify(Config.Translations.notify.error.noKey, 'error', 5000)
        return
    end

    local res = lib.callback.await('origen_housing:server:toggleLock', false, {
        houseID = self.id,
        doorID = '1',
    })

    if res and res.status then
        Utils.PlayAnim(cache.ped, 'anim@heists@humane_labs@finale@keycards', 'ped_a_fail_d', 500)
        if res.message then
            Internal.Notify(res.message, res.locked and 'error' or 'success', 3000)
        end
    end
end

function House:CreateEntryPoint()
    local function OnEnterHouse()
        if not self.owned then
            local houseID = self.id
            self.houseData.id = houseID
            local garageData = false
            if Config.GarageInteriors[self.garage] then
                garageData = Config.GarageInteriors[self.garage]
            end
            Nui.OpenBuyHouse(self.houseData, garageData)
        else
            if self.houseData.construction and self.houseData.construction.enabled and self.houseData.construction.time > 0 then
                Internal.Notify(Config.Translations.notify.error.houseUnderConstruction:format(Utils.FormatTime(self.houseData.construction.time)), 'error', 5000)
                return
            end

            if not Custom.CanAccessHouse(self.id) then return end

            local mainDoor = self.houseData.doors and (self.houseData.doors['1'] or self.houseData.doors[1])
            local doorLocked = mainDoor and mainDoor.locked
            if doorLocked then
                if not Config.KeyHoldersNeedDoorUnlocked and self:hasKey() then
                    goto continue
                end
                Internal.Notify(Config.Translations.notify.error.doorLocked, 'error', 5000)
                return
            end

            ::continue::

            local allowVehicles = self.houseData.data.allowVehicles

            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)

            -- (casas de modalidad libre: con el vehículo se entra por la entrada de garaje)
            if vehicle ~= 0 and Entradas and Entradas.PuertaConCoche(self) then return end

            if vehicle ~= 0 and not allowVehicles then
                Internal.Notify(Config.Translations.notify.error.vehicleNotAllowed, 'error', 5000)
                return
            end

            self:EnterHouse()
            
            Custom.OnEnterHouse(self.id)
        end
    end

    if Config.ExternalInteractionSystem then
        if self.houseData.data.type == 'mlo' and self.owned then
            goto skip
        end

        local coords = vector3(self.houseData.positions.entry.x, self.houseData.positions.entry.y, self.houseData.positions.entry.z + 1.0)
        local label = self.owned and Config.Translations.drawtext.enter or Config.Translations.drawtext.viewHouse

        Custom.CreateCoordsInteraction('entry_house_'..self.id, coords, 10.0, 1.5, false, label, OnEnterHouse)

        if self.owned and (self.houseData.data.type == 'shell' or self.houseData.data.type == 'ipl') then
            local mainDoor = self.houseData.doors and (self.houseData.doors['1'] or self.houseData.doors[1])
            local isLocked = mainDoor and (mainDoor.locked == true or mainDoor.locked == 1)
            local lockLabel = isLocked and Config.Translations.drawtext.unlock or Config.Translations.drawtext.lock
            Custom.CreateCoordsInteraction('entry_house_lock_'..self.id, coords, 10.0, 1.5, false, lockLabel, function()
                self:ToggleMainDoor()
            end)
        end

        self.entryPoint = {
            coords = coords,
            distance = 10.0,
        }
    else
        local function nearby(data)
            if data.type == 'mlo' and self.owned then
                if data.noty then
                    Internal.HideText()
                    data.noty = false
                    data.text = nil
                end
                return
            end
            DrawMarker(data.config.type, vec3(data.coords.x, data.coords.y, data.coords.z) + data.config.coords, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, data.config.size.x, data.config.size.y, data.config.size.z, data.config.color[1], data.config.color[2], data.config.color[3], data.config.color[4], data.config.bobUpAndDown, data.config.faceCamera, 2, data.config.rotate, nil, false, false)
            Custom.OnNearbyEntryPoint(self.id, data.currentDistance, self.owned and true or false, {
                name = self.houseData.name,
                location = self.houseData.data.location,
                coords = data.coords,
                number = self.houseData.data.number,
            })
            if data.currentDistance < 1.5 then
                local isShellOrIpl = self.owned and (self.houseData.data.type == 'shell' or self.houseData.data.type == 'ipl')
                local mainDoor = self.houseData.doors and (self.houseData.doors['1'] or self.houseData.doors[1])
                local isLocked = mainDoor and (mainDoor.locked == true or mainDoor.locked == 1)

                local currentText
                if isShellOrIpl then
                    local lockText = isLocked and Config.Translations.drawtext.unlock or Config.Translations.drawtext.lock
                    currentText = string.format("%s | [G] %s", Config.Translations.drawtext.enter, lockText)
                else
                    currentText = self.owned and Config.Translations.drawtext.enter or Config.Translations.drawtext.viewHouse
                end

                if data.text ~= currentText or not data.noty then
                    Internal.DrawText(currentText, 'E')
                    data.text = currentText
                    data.noty = true
                end

                if IsControlJustPressed(0, 38) then
                    OnEnterHouse()
                elseif isShellOrIpl and IsControlJustPressed(0, 47) then
                    self:ToggleMainDoor()
                end
            elseif data.noty then
                Internal.HideText()
                data.noty = false
                data.text = nil
            end
        end

        self.entryPoint = lib.points.new({
            coords = vector3(self.houseData.positions.entry.x, self.houseData.positions.entry.y, self.houseData.positions.entry.z),
            distance = 10.0,
            nearby = nearby,
            houseID = self.id,
            noty = false,
            type = self.houseData.data.type,
            config = Config.Markers.general,
        })
    end

    ::skip::
end

function House:EnterHouse(force)
    force = force or false
    local function requestInteriorFurniture()
        local interiorFurniture = lib.callback.await('origen_housing:server:getFurniture', false, { houseID = self.id, zone = 'interior' })

        self.houseData.furniture.interior = interiorFurniture

        --[[ Los muebles se crean ya DENTRO, no antes (10/10).

             Antes se creaban aqui mismo, con el jugador todavia en la puerta:
             en una casa de shell el interior esta a 2.000 m de altura, y eran
             cien o doscientos objetos creados a dos kilometros de quien los
             iba a ver. A cada jugador le faltaban unos distintos, y cambiaban
             al salir y volver a entrar. Ahora se espera a estar dentro, y
             mientras se este un vigilante repone el que falte. ]]
        CreateThread(function()
            local limite = GetGameTimer() + 6000
            while GetGameTimer() < limite and currentInteriorHouseID == self.id
                and not (self.shellData and self.shellData.inside) do
                Wait(50)
            end
            if currentInteriorHouseID ~= self.id then return end
            Wait(150)

            self:LoadFurniture('interior')
            debugger('Load interior furniture')
            self:VigilarMuebles()
        end)
    end

    if not self.houseData.furniture then
        self.houseData.furniture = {}
    end

    if not self.houseData.furniture.interior then
        self.houseData.furniture.interior = {}
    end

    self.houseData.owned = self.owned

    local shell = Shell:new(self.houseData)

    if self.houseData.data.type == 'shell' then
        shell:CreateShell({
            instance = true,
            force = force,
            onEnter = function(data)
                currentExteriorHouseID = false
                Internal.HideText()
                self.houseData.shell = {
                    zone = data.zone,
                    entity = data.entity,
                }
                self.shellData = data
                currentInteriorHouseID = self.id
                requestInteriorFurniture()
                LoadDoors(self.id)
            end,
        })
    elseif self.houseData.data.type == 'ipl' then
        local data = __indexIpls[self.houseData.data.model]

        shell:EnterIPL({
            ipl = data,
            force = force,
            onEnter = function(data)
                currentExteriorHouseID = false
                Internal.HideText()
                self.shellData = data
                currentInteriorHouseID = self.id
                requestInteriorFurniture()
                LoadDoors(self.id)
            end,
        })
    end
end

function House:ExitHouse(force)
    local shell = Shell:new(self.houseData)
    shell:Exit(force)
    
    if self.doors then
        for k,v in pairs(self.doors) do
            if v.coords then
                local entryCoords = self.houseData.positions.entry
                local dist = #(vector3(entryCoords.x, entryCoords.y, entryCoords.z) - vector3(v.coords.x, v.coords.y, v.coords.z))
                if dist > 50.0 then
                    self:DeleteDoor(k)
                end
            end
        end
    end
end

function House:CreateGaragePoint()
    if not Config.GarageInteriors[self.garage] then return end

    local function OnEnterGarage()
        if self.houseData.construction and self.houseData.construction.enabled and self.houseData.construction.time > 0 then
            Internal.Notify(Config.Translations.notify.error.houseUnderConstruction:format(Utils.FormatTime(self.houseData.construction.time)), 'error', 5000)
            return
        end

        if not self:hasKey() then
            Internal.Notify(Config.Translations.notify.error.noKey, 'error', 5000)
            return
        end

        if Config.GarageNeedMainDoorUnlocked and (self.houseData.data.type == 'ipl' or self.houseData.data.type == 'shell') then
            local mainDoor = self.houseData.doors and (self.houseData.doors['1'] or self.houseData.doors[1])
            local doorLocked = mainDoor and mainDoor.locked
            if doorLocked then
                Internal.Notify(Config.Translations.notify.error.doorLocked, 'error', 5000)
                return
            end
        end

        if not self.garage then
            debugger('No garage data')
            return
        end

        local garageHeading = tonumber(self.houseData.positions.garage.w) or 0.0
        Internal.OpenGarage(self.id, self.garage, vec4(self.houseData.positions.garage.x, self.houseData.positions.garage.y, self.houseData.positions.garage.z, garageHeading))
    end

    if Config.ExternalInteractionSystem then
        local coords = vector3(self.houseData.positions.garage.x, self.houseData.positions.garage.y, self.houseData.positions.garage.z + 1)
        local label = Config.Translations.drawtext.enterGarage

        Custom.CreateCoordsInteraction('garage_house_'..self.id, coords, 15.0, 3.0, true, label, OnEnterGarage)

        self.garagePoint = {
            coords = coords,
            distance = 15.0,
        }
    else
        local function nearby(data)
            DrawMarker(data.config.type, vec3(data.coords.x, data.coords.y, data.coords.z) + data.config.coords, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, data.config.size.x, data.config.size.y, data.config.size.z, data.config.color[1], data.config.color[2], data.config.color[3], data.config.color[4], data.config.bobUpAndDown, data.config.faceCamera, 2, data.config.rotate, nil, false, false)
            if Internal.useCustomGarage then return end
            if data.currentDistance < 3.0 then
                if not data.noty then
                    Internal.DrawText(Config.Translations.drawtext.enterGarage, 'E')
                    data.noty = true
                end
                if IsControlJustPressed(0, 38) then
                    OnEnterGarage()

                    if data.noty then
                        Internal.HideText()
                        data.noty = false
                    end
                end
            else
                if data.noty then
                    Internal.HideText()
                    data.noty = false
                end
            end
        end

        self.garagePoint = lib.points.new({
            coords = vector3(self.houseData.positions.garage.x, self.houseData.positions.garage.y, self.houseData.positions.garage.z),
            distance = 15.0,
            houseID = self.id,
            owned = self.owned,
            noty = false,
            nearby = nearby,
            onEnter = function()
                if not Internal.useCustomGarage then return end
                local garageHeading = tonumber(self.houseData.positions.garage.w) or 0.0
                Internal.OpenGarage(self.id, self.garage, vec4(self.houseData.positions.garage.x, self.houseData.positions.garage.y, self.houseData.positions.garage.z, garageHeading))
            end,
            config = Config.Markers.garage,
        })
    end

    Internal.RegisterGarage(self.id, self.houseData.positions.garage, self.houseData.name)
end

function House:CreateBuilding()

    if self.houseData.construction.stage > 0 then
        self:CreateBuildingStage()
        return
    end

    debugger('Creating building', self.houseData.construction.model)

    self.building.model = GetHashKey(self.houseData.construction.model)

    lib.requestModel(self.building.model)

    self.building.object = CreateObject(self.houseData.construction.model, self.houseData.construction.coords.x, self.houseData.construction.coords.y, self.houseData.construction.coords.z, false, false, false)
    SetEntityHeading(self.building.object, self.houseData.construction.coords.w)
    FreezeEntityPosition(self.building.object, true)
    SetEntityAlpha(self.building.object, 50, false)
    SetEntityLodDist(self.building.object, Config.RenderDistance)
    SetEntityCollision(self.building.object, true, false)
    SetEntityCoords(self.building.object, self.houseData.construction.coords.x, self.houseData.construction.coords.y, self.houseData.construction.coords.z)
    SetModelAsNoLongerNeeded(self.building.model)

    props[#props + 1] = self.building.object

    CreateThread(function()
        for alpha = 55, 255, 10 do
            SetEntityAlpha(self.building.object, alpha, false)
            Wait(0)
        end
    end)
end

function House:RemoveBuilding()
    if self.houseData.construction.stage > 0 then
        self:RemoveBuildingStage()
        return
    end

    if not DoesEntityExist(self.building.object) then return end

    for alpha = 255, 0, -10 do
        SetEntityAlpha(self.building.object, alpha, false)
        Wait(0)
    end

    DeleteEntity(self.building.object)

    self.building.object = nil
end

function House:CreateBuildingStage()
    debugger('Creating building stage', self.houseData.construction.stage)

    local center = self.houseData.construction.coords
    local stage = self.houseData.construction.stage

    if Config.BuildingStages[stage] and next(Config.BuildingStages[stage].props) then
        for i = 1, #Config.BuildingStages[stage].props do
            local info = Config.BuildingStages[stage].props[i]

            local offsetX = info.offset.x * math.cos(math.rad(center.w)) + info.offset.y * math.sin(math.rad(center.w))
            local offsetY = -info.offset.x * math.sin(math.rad(center.w)) + info.offset.y * math.cos(math.rad(center.w))

            local position = vector3(center.x + offsetX, center.y + offsetY, center.z + info.offset.z)

            lib.requestModel(info.model)

            local object = CreateObject(info.model, position.x, position.y, position.z, 0.0, false, false, false)
            SetEntityHeading(object, center.w + info.heading)
            FreezeEntityPosition(object, true)
            PlaceObjectOnGroundProperly(object)
            SetEntityLodDist(object, Config.RenderDistance)
            SetModelAsNoLongerNeeded(info.model)

            CreateThread(function()
                for alpha = 55, 255, 10 do
                    SetEntityAlpha(object, alpha, false)
                    Wait(0)
                end
            end)

            props[#props + 1] = object

            self.building.props[#self.building.props + 1] = object
        end
    end

    if Config.BuildingStages[stage] and next(Config.BuildingStages[stage].peds) then
        for i = 1, #Config.BuildingStages[stage].peds do
            local info = Config.BuildingStages[stage].peds[i]
            local offsetX = info.offset.x * math.cos(math.rad(center.w)) + info.offset.y * math.sin(math.rad(center.w))
            local offsetY = -info.offset.x * math.sin(math.rad(center.w)) + info.offset.y * math.cos(math.rad(center.w))

            local position = vector3(center.x + offsetX, center.y + offsetY, center.z + info.offset.z)

            lib.requestModel(info.model)

            local ped = CreatePed(4, info.model, position.x, position.y, position.z, center.w + info.heading, false, false)
            PlaceObjectOnGroundProperly(ped)
            SetEntityInvincible(ped, true)
            TaskWanderInArea(ped, position.x, position.y, position.z, 5.0, 2.0, 10.0)
            SetModelAsNoLongerNeeded(info.model)

            if info.scenario then
                TaskStartScenarioInPlace(ped, info.scenario, 0, true)
            end

            if info.anim then
                TaskPlayAnim(ped, info.anim.dict, info.anim.name, 8.0, 0.0, -1, 1, 0, 0, 0, 0)
            end

            CreateThread(function()
                for alpha = 55, 255, 50 do
                    SetEntityAlpha(ped, alpha, false)
                    Wait(0)
                end
            end)

            peds[#peds + 1] = ped
            self.building.peds[#self.building.peds + 1] = ped
        end
    end
end

function House:RemoveBuildingStage()
    if self.building.props then
        for _, prop in pairs(self.building.props) do
            DeleteEntity(prop)
        end
    end
    if self.building.peds then
        for _, ped in pairs(self.building.peds) do
            DeleteEntity(ped)
        end
    end
end

--- Un mueble que no ha salido, dicho una vez por modelo: en la consola (F8)
--- de quien lo sufre queda cual es y por que, que es lo que hace falta saber.
local faltasDichas = {}
function MuebleQueFalta(houseID, modelo, motivo)
    local clave = tostring(houseID) .. ':' .. tostring(modelo)
    if faltasDichas[clave] then return end
    faltasDichas[clave] = true
    print(('^3[origen_housing]^7 casa %s: el mueble %s no ha salido (%s)'):format(tostring(houseID), tostring(modelo), tostring(motivo)))
end

--[[ El vigilante de los muebles de dentro (10/10).

     Mientras se esta en la casa, cada pocos segundos compara lo que deberia
     haber (la lista del servidor) con lo que hay de verdad en el mundo y
     vuelve a crear lo que falte: el que no se creo al entrar, o el que el
     juego se haya llevado despues. Tres intentos por mueble y entrada; al
     tercero se da por imposible (un modelo que este servidor no tiene).

     No actua mientras se decora: el modo muebles quita y pone la pieza que
     se esta moviendo, y reponerla seria pelearse con el. ]]
function House:VigilarMuebles()
    self.turnoMuebles = self.turnoMuebles or {}
    local turno = self.turnoMuebles.interior
    local intentos = {}

    local function sigue()
        return currentInteriorHouseID == self.id and self.turnoMuebles.interior == turno
    end

    while sigue() do
        Wait(4000)
        if not sigue() then break end

        local lista = self.houseData.furniture and self.houseData.furniture.interior
        local crear = self.crearMueble and self.crearMueble.interior
        if type(lista) == 'table' and crear and not (Furniture and Furniture.active) then
            local faltan = {}
            for id, data in pairs(lista) do
                local m = self.interiorFurniture[id]
                local hay = m and m.entity and DoesEntityExist(m.entity)
                if hay then
                    -- (una lámpara apagada está escondida a propósito: custom/client/luces.lua)
                    if not IsEntityVisible(m.entity) and not (Luces and Luces.Apagada(m.entity)) then SetEntityVisible(m.entity, true, false) end
                elseif type(data) == 'table' and (intentos[id] or 0) < 3 and IsModelValid(data.model) then
                    faltan[#faltan + 1] = id
                end
            end

            for _, id in ipairs(faltan) do
                if not sigue() or (Furniture and Furniture.active) then break end
                local data = lista[id]
                local m = self.interiorFurniture[id]
                if type(data) == 'table' and not (m and m.entity and DoesEntityExist(m.entity)) then
                    intentos[id] = (intentos[id] or 0) + 1
                    local ok, res = pcall(crear, id, data)
                    if ok and type(res) == 'table' and res.entity then
                        self.interiorFurniture[id] = res
                        print(('^2[origen_housing]^7 casa %s: repuesto el mueble %s'):format(tostring(self.id), tostring(data.model)))
                    elseif not ok then
                        MuebleQueFalta(self.id, data.model, tostring(res))
                    end
                end
            end
        end
    end
end

--[[ /mueblescasa — diagnostico (10/10), para quitar cuando se sepa la causa.

     Dentro de una casa, escribe en F8 que pasa con cada mueble que deberia
     haber: si no esta creado, si esta pero oculto, si su modelo no esta en
     memoria (existe y no se dibuja) o si no esta donde toca. Solo lee. ]]
RegisterCommand('mueblescasa', function()
    local house = currentInteriorHouseID and House.get(currentInteriorHouseID)
    local lista = house and house.houseData.furniture and house.houseData.furniture.interior
    if type(lista) ~= 'table' then
        print('^3[origen_housing]^7 mueblescasa: no estas dentro de una casa')
        return
    end

    local shell = house.houseData.data.type == 'shell' and house.houseData.shell and house.houseData.shell.entity
    local total, creados, sinCrear, ocultos, sinModelo, movidos = 0, 0, {}, {}, {}, {}
    for id, data in pairs(lista) do
        if type(data) == 'table' then
            total = total + 1
            local m = house.interiorFurniture[id]
            local ent = m and m.entity
            if not ent or not DoesEntityExist(ent) then
                sinCrear[#sinCrear + 1] = tostring(data.model)
            else
                creados = creados + 1
                if not IsEntityVisible(ent) or GetEntityAlpha(ent) < 250 then
                    ocultos[#ocultos + 1] = ('%s(alfa %d)'):format(tostring(data.model), GetEntityAlpha(ent))
                end
                if not HasModelLoaded(GetEntityModel(ent)) then sinModelo[#sinModelo + 1] = tostring(data.model) end
                local p = data.position
                if type(p) == 'table' then
                    local debe = shell and GetOffsetFromEntityInWorldCoords(shell, p.x + 0.0, p.y + 0.0, p.z + 0.0)
                        or vector3(p.x + 0.0, p.y + 0.0, p.z + 0.0)
                    local d = #(GetEntityCoords(ent) - debe)
                    if d > 1.5 then movidos[#movidos + 1] = ('%s(%.1f m)'):format(tostring(data.model), d) end
                end
            end
        end
    end

    print(('^2[origen_housing]^7 casa %s: %d muebles en la lista, %d creados, %d sin crear, %d ocultos, %d con el modelo fuera de memoria, %d fuera de su sitio')
        :format(tostring(house.id), total, creados, #sinCrear, #ocultos, #sinModelo, #movidos))
    if #sinCrear > 0 then print('  sin crear: ' .. table.concat(sinCrear, ', ')) end
    if #ocultos > 0 then print('  ocultos: ' .. table.concat(ocultos, ', ')) end
    if #sinModelo > 0 then print('  modelo fuera de memoria: ' .. table.concat(sinModelo, ', ')) end
    if #movidos > 0 then print('  fuera de su sitio: ' .. table.concat(movidos, ', ')) end
    print(('  objetos del juego ahora mismo: %d'):format(#GetGamePool('CObject')))
end, false)

function House:LoadFurniture(zone)
    if not self.houseData.furniture or not next(self.houseData.furniture) then
        return
    end

    local furniture = self.houseData.furniture[zone]

    if not furniture then return end

    local function createAndSetupEntity(id, data)
        local coords = data.position
        local rotation = data.rotation

        if not IsModelValid(data.model) then
            debugger('Model not valid', data.model)
            -- Antes se saltaba sin decir nada, y era justo lo que pasaba con
            -- los props de interior del juego (ver fxmanifest.lua).
            MuebleQueFalta(self.id, data.model, 'el juego no tiene ese modelo cargado ahora')
            return {
                id = id,
            }
        end

        -- Con tope y sin que un modelo que no carga tire la fila entera:
        -- lib.requestModel lanza un error a los 30 s, y sin recogerlo todos
        -- los muebles de detras se quedaban sin crear.
        if not pcall(lib.requestModel, data.model, 10000) then
            MuebleQueFalta(self.id, data.model, 'el modelo no ha cargado')
            return {
                id = id,
            }
        end

        local newCoords

        if zone == 'interior' and self.houseData.data.type == 'shell' and self.houseData.shell and self.houseData.shell.entity then
            local finalCoords = coords
            if coords.z > 1000.0 then
                local entry = self.houseData.positions.entry
                local oldModel = GetHashKey(self.houseData.data.model)
                lib.requestModel(oldModel)
                local tempEntity = CreateObjectNoOffset(oldModel, entry.x, entry.y, 2000.0, false, false, false)
                if DoesEntityExist(tempEntity) then
                    SetEntityRotation(tempEntity, 0.0, 0.0, entry.w or 0.0, 2, true)
                    finalCoords = GetOffsetFromEntityGivenWorldCoords(tempEntity, coords.x, coords.y, coords.z)
                    DeleteEntity(tempEntity)
                    data.position = finalCoords
                    TriggerServerEvent('origen_housing:server:convertFurnitureCoords', self.id, id, zone, finalCoords)
                end
            end
            newCoords = GetOffsetFromEntityInWorldCoords(self.houseData.shell.entity, finalCoords.x, finalCoords.y, finalCoords.z)
        else
            newCoords = vector3(coords.x, coords.y, coords.z)
        end

        local min, max = GetModelDimensions(data.model)
        local entity = CreateObject(data.model, newCoords.x, newCoords.y, newCoords.z, false, true, false)
        -- Puede no crearse (sin sitio, modelo a medio cargar): se dice y el
        -- vigilante lo vuelve a intentar, en vez de apuntarlo como hecho.
        if not entity or entity == 0 or not DoesEntityExist(entity) then
            SetModelAsNoLongerNeeded(data.model)
            MuebleQueFalta(self.id, data.model, 'no se ha creado')
            return {
                id = id,
            }
        end
        SetEntityRotation(entity, rotation.x, rotation.y, rotation.z, 2, true)
        SetEntityCoords(entity, newCoords.x, newCoords.y, newCoords.z)
        SetEntityLodDist(entity, Config.RenderDistance)
        -- Como hace UpdateObject con los que se ponen en vivo: sin esto el
        -- juego puede llevarse el objeto cuando le parece que sobra.
        SetEntityAsMissionEntity(entity, true, true)
        SetModelAsNoLongerNeeded(data.model)

        Entity(entity).state.entityID = id
        Entity(entity).state.min = vector3(0.0, 0.0, -min.z)

        props[#props + 1] = entity

        if data.type == 'door' then
            if self.houseData.doors[id] then
                self:CreateDoor(id, self:FormatDoor(id))
            end
        else
            if data.type == 'camera' then

                if not self.cameras[id] then
                    self.cameras[id] = {
                        model = data.model,
                        entity = entity,
                        coords = newCoords,
                        rotation = rotation,
                        zone = zone,
                    }
                else
                    self.cameras[id].entity = entity
                    self.cameras[id].coords = newCoords
                    self.cameras[id].rotation = rotation
                end
            elseif data.type == 'light' then
                self.lightPoints[id] = self:DrawLight({
                    id = id,
                    label = data.label,
                    entity = entity,
                    state = data.state,
                    color = data.color,
                    opacity = data.opacity,
                    coords = newCoords,
                    rotation = rotation,
                    model = data.model,
                })
            end
            FreezeEntityPosition(entity, true)
        end

        CreateThread(function()
            for alpha = 55, 255, 50 do
                SetEntityAlpha(entity, alpha, false)
                Wait(0)
            end
        end)

        -- Con parentesis: sin ellos el `and not ...` solo iba con 'stash' y un
        -- armario creaba un punto nuevo encima del que ya tuviera.
        if (data.type == 'wardrobe' or data.type == 'stash') and not self.exteriorInterectable[id] and not self.interiorInterectable[id] then
            local point = self:CreateInteractablePoint({
                id = id,
                entity = entity,
                coords = newCoords,
                model = data.model,
                type = data.type,
                zone = zone,
            })

            if zone == 'exterior' then
                self.exteriorInterectable[id] = point
            else
                self.interiorInterectable[id] = point
            end
        end

        if data.type == 'board' then
            -- Si ya estaba (se recargan los muebles), se guarda su DUI: con
            -- una tabla nueva la vieja se quedaba abierta sin nadie que la cerrara.
            local anterior = self.boards[id]
            self.boards[id] = {
                id = id,
                entity = entity,
                model = data.model,
                url = data.url,
                zone = zone,
                data = anterior and anterior.data or {},
            }
        end

        self:RegistrarTele(id, entity, zone, data.model)

        return {
            entity = entity,
            id = id,
            model = data.model,
            position = coords,
            rotation = rotation,
            type = data.type,
        }
    end

    -- El vigilante (VigilarMuebles) usa la misma funcion para reponer.
    self.crearMueble = self.crearMueble or {}
    self.crearMueble[zone] = createAndSetupEntity

    -- Si se sale o se vuelve a cargar a mitad, esta tanda se deja.
    self.turnoMuebles = self.turnoMuebles or {}
    local turno = (self.turnoMuebles[zone] or 0) + 1
    self.turnoMuebles[zone] = turno

    --[[ Se recorre una COPIA de los ids. Crear cada mueble espera a su modelo,
         y en esa espera puede llegar un mueble nuevo (alguien decorando):
         añadir una clave a la tabla que se esta recorriendo con pairs rompe
         el recorrido, y los de detras no se creaban. ]]
    local ids = {}
    for id in pairs(furniture) do ids[#ids + 1] = id end

    local puestos = zone == 'exterior' and self.exteriorFurniture or self.interiorFurniture
    for _, id in ipairs(ids) do
        if self.turnoMuebles[zone] ~= turno then return end
        local data = furniture[id]
        -- Puede haberlo puesto ya un aviso en vivo mientras se cargaban los demas.
        local yaEsta = puestos[id] and puestos[id].entity and DoesEntityExist(puestos[id].entity)
        if type(data) == 'table' and not yaEsta then
            -- Cada uno por separado: si uno falla, los demas se siguen creando.
            local ok, res = pcall(createAndSetupEntity, id, data)
            if not ok then
                MuebleQueFalta(self.id, data.model, tostring(res))
                res = { id = id }
            end
            puestos[id] = res
        end
    end

    -- Los cuadros se pintan al entrar en la zona, pero al entrar al servidor
    -- junto a la casa la zona salta antes de que lleguen los muebles y no
    -- había cuadros que pintar: salía el logo de serie hasta salir y volver.
    if (zone == 'exterior' and currentExteriorHouseID == self.id)
        or (zone == 'interior' and currentInteriorHouseID == self.id) then
        self:PintarCuadros(zone)
    end
end

function House:UseCamera(id)
    if not self:hasKey() then
        Internal.Notify(Config.Translations.notify.error.noKey, 'error', 5000)
        return
    end

    if not self.cameras or not next(self.cameras) then return end

    local camera = self.cameras[id]

    if not camera then return end

    local zone = camera.zone

    local camera = Camera:new({
        houseID = self.id,
        house = self.houseData,
        shell = self.shellData and self.shellData or false,
        cameras = self.cameras,
        zone = camera.zone,
    })

    camera:SetupCamera(id)
end

function House:UpdateObject(id, data, interior)
    _entity = nil
    local function handleObject(furniture, id, data)
        local object = furniture[id]
        -- Quitar un mueble que aqui no estaba puesto: nada que hacer.
        if not object and not data then return end
        if not object then
            local coords = data.position
            local rotation = data.rotation

            lib.requestModel(data.model)

            local newCoords

            if interior and self.houseData.data.type == 'shell' and self.houseData.shell and self.houseData.shell.entity then
                newCoords = GetOffsetFromEntityInWorldCoords(self.houseData.shell.entity, coords.x, coords.y, coords.z)
            else
                newCoords = vector3(coords.x, coords.y, coords.z)
            end

            local min, max = GetModelDimensions(data.model)
            local entity = CreateObject(data.model, newCoords.x, newCoords.y, newCoords.z, false, true, false)
            SetEntityRotation(entity, rotation.x, rotation.y, rotation.z, 2, true)
            SetEntityCoords(entity, newCoords.x, newCoords.y, newCoords.z)
            SetEntityLodDist(entity, Config.RenderDistance)
            SetEntityAsMissionEntity(entity, true, true)
            SetModelAsNoLongerNeeded(data.model)

            Entity(entity).state.entityID = id
            Entity(entity).state.min = vector3(0.0, 0.0, -min.z)

            if data.type == 'door' then
            else
                if data.type == 'camera' then
                    if not self.cameras[id] then
                        self.cameras[id] = {
                            model = data.model,
                            entity = entity,
                            coords = newCoords,
                            rotation = rotation,
                            zone = interior and 'interior' or 'exterior',
                        }
                    end
                elseif data.type == 'light' then
                    self.lightPoints[id] = self:DrawLight({
                        id = id,
                        label = data.label,
                        entity = entity,
                        state = data.state,
                        color = data.color,
                        opacity = data.opacity,
                        coords = newCoords,
                        rotation = rotation,
                        model = data.model,
                    })
                elseif data.type == 'board' then
                    if not self.boards[id] then
                        self.boards[id] = {
                            id = id,
                            entity = entity,
                            model = data.model,
                            url = data.url,
                            zone = interior and 'interior' or 'exterior',
                            data = {},
                        }
                    end
                end
                FreezeEntityPosition(entity, true)
            end

            CreateThread(function()
                for alpha = 55, 255, 50 do
                    SetEntityAlpha(entity, alpha, false)
                    Wait(0)
                end
            end)

            -- Mira la tabla de SU zona (antes siempre la de fuera, y un mueble
            -- de dentro podia acabar con dos puntos).
            local puntos = interior and self.interiorInterectable or self.exteriorInterectable
            if (data.type == 'wardrobe' or data.type == 'stash') and not puntos[id] then
                local point = self:CreateInteractablePoint({
                    id = id,
                    entity = entity,
                    coords = newCoords,
                    model = data.model,
                    type = data.type,
                    zone = interior and 'interior' or 'exterior',
                })
                if not interior then
                    self.exteriorInterectable[id] = point
                else
                    self.interiorInterectable[id] = point
                end
            end

            furniture[id] = {
                entity = entity,
                id = id,
                model = data.model,
                position = coords,
                rotation = rotation,
                type = data.type,
            }

            props[#props + 1] = entity

            self:RegistrarTele(id, entity, interior and 'interior' or 'exterior', data.model)
        else
            if not data then
                self:QuitarTele(id)
                DeleteEntity(object.entity)
                self:RemoveInteractablePoint(id, interior)
                self:RemoveLight(id)
                furniture[id] = nil

                if self.cameras and self.cameras[id] then
                    self.cameras[id] = nil
                end

                if self.boards and self.boards[id] then
                    self.boards[id] = nil
                end

                if self.doors and self.doors[id] then
                    local deleteDoor = lib.callback.await('origen_housing:server:deleteDoor', false, {
                        houseID = self.id,
                        doorID = id,
                    })

                    if deleteDoor then
                        if self.doorPoints[id] then
                            self.doorPoints[id]:remove()
                            self.doorPoints[id] = nil
                        end

                        self.doors[id] = nil
                    end
                end
            else
                local coords = data.position
                local rotation = data.rotation

                local newCoords

                if interior and self.houseData.data.type == 'shell' and self.houseData.shell and self.houseData.shell.entity then
                    newCoords = GetOffsetFromEntityInWorldCoords(self.houseData.shell.entity, coords.x, coords.y, coords.z)
                else
                    newCoords = vector3(coords.x, coords.y, coords.z)
                end

                self:UpdateInteractablePoint(id, newCoords, interior)
                if self.teles[id] and self.teles[id].point then
                    self.teles[id].point.coords = newCoords
                end

                SetEntityCoords(object.entity, newCoords.x, newCoords.y, newCoords.z)
                SetEntityRotation(object.entity, rotation.x, rotation.y, rotation.z, 2, true)

                furniture[id] = {
                    entity = object.entity,
                    id = id,
                    model = data.model,
                    position = newCoords,
                    rotation = rotation,
                    type = data.type,
                }

                if data.type == 'camera' then
                    if not self.cameras[id] then
                        self.cameras[id] = {
                            model = data.model,
                            entity = entity,
                            coords = newCoords,
                            rotation = rotation,
                            zone = interior and 'interior' or 'exterior',
                        }
                    else
                        self.cameras[id].coords = newCoords
                        self.cameras[id].rotation = rotation
                        self.cameras[id].entity = entity
                    end
                elseif data.type == 'light' then
                    self.lightPoints[id].coords = newCoords
                    self.lightPoints[id].rotation = rotation
                end
            end
        end
    end

    handleObject(interior and self.interiorFurniture or self.exteriorFurniture, id, data)
end

function House:DeleteFurniture(zone)

    -- Una carga a medias (o el vigilante) de esta zona deja de crear muebles.
    self.turnoMuebles = self.turnoMuebles or {}
    self.turnoMuebles[zone] = (self.turnoMuebles[zone] or 0) + 1

    local furniture = zone == 'interior' and self.interiorFurniture or self.exteriorFurniture

    self:QuitarTeles(zone)

    for idCuadro, cuadro in pairs(self.boards or {}) do
        if cuadro.zone == zone then
            self:DestroyBoard(idCuadro)
        end
    end

    if not next(furniture) then
        return
    end

    for _, data in pairs(furniture) do
        if data.entity and DoesEntityExist(data.entity) then
            DeleteEntity(data.entity)
        end
    end

    if zone == 'interior' then
        table.wipe(self.interiorFurniture)
        --[[ Los puntos se QUITAN antes de vaciar la tabla. Antes solo se
             vaciaba: el lib.point seguia vivo y al volver a entrar se creaba
             otro en el mismo sitio. Con dos, una E abria el baul dos veces y
             la segunda apertura (origen_inventory: si ya esta abierto, cierra)
             lo cerraba al instante; con tres se abria, cerraba y abria... ]]
        for idPunto in pairs(self.interiorInterectable) do
            self:RemoveInteractablePoint(idPunto, true)
        end
        table.wipe(self.interiorInterectable)
    else
        table.wipe(self.exteriorFurniture)
    end
end

function House:CreateInteractablePoint(data)

    local min, max = GetModelDimensions(data.model)

    local distance = math.max(max.x - min.x, max.y - min.y, max.z - min.z)

    if distance < 1.2 then
        distance = 1.3
    end

    local stash, stashId = nil, nil

    if data.type == 'stash' and __indexFurniture[data.model] and __indexFurniture[data.model].stash then
        stash = type(__indexFurniture[data.model].stash) == 'table' and __indexFurniture[data.model].stash or Config.StashesTypes[__indexFurniture[data.model].stash]
        stashId = 'stashHousing_'..data.id..'_'..data.zone
    end

    local frigorifico = Config.Almacenajes and Config.Almacenajes.frigorificos
        and Config.Almacenajes.frigorificos[data.model] == true
    local textoAbrir = frigorifico and Config.Translations.general.openFridge or Config.Translations.general.openStash

    local function onSelect()
        if not self.owned then
            return
        end

        if not stash then
            Internal.Wardrobe('wardrobe_'..data.id..'_'..data.zone) 
        else
            local hasSecurity = self.houseData.settings.upgrades.storage_security
            local canOpenStash = Custom.CanOpenStash(self.id, hasSecurity)
            local hashKey = self:hasKey()

            if hashKey then goto continue end

            if hasSecurity and not canOpenStash then
                Internal.Notify(Config.Translations.notify.error.storageHasSecurity, 'error', 5000)
                return
            end
            if not canOpenStash then return end

            ::continue::

            stash.label = frigorifico and Config.Translations.general.fridgeStash or Config.Translations.general.houseStash
            Internal.OpenStash(stashId, stash)
        end
    end

    local point

    if Config.ExternalInteractionSystem then
        local label = data.type == 'wardrobe' and Config.Translations.general.openWardrobe or textoAbrir
        Custom.CreateEntityInteraction('interactable_furniture_'..data.id, data.type, data.entity, 5.0, distance, label, onSelect)

        point = {
            id = data.id,
            coords = data.coords,
            distance = distance,
        }

        if stash and stashId then
            point.stash = stash
            point.stashId = stashId
        end
    else
        local function onExit(point)
            Internal.HideText()
            point.noty = false
        end

        local function nearby(point)
            if not point.noty then
                Internal.DrawText(point.text, 'E')
                point.noty = true
            end
            if Config.Debug then
                DrawMarker(1, point.coords.x, point.coords.y, point.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, point.distance * 2, point.distance * 2, 0.3, 0, 0, 0, 200, false, true, 2, nil, nil, false) -- temporal
            end
            if IsControlJustReleased(0, 38) then
                onSelect()
            end
        end

        point = lib.points.new({
            coords = data.coords,
            distance = distance,
            onExit = onExit,
            nearby = nearby,
            text = data.type == 'wardrobe' and Config.Translations.general.openWardrobe or textoAbrir,
            noty = false,
        })

        if stash and stashId then
            point.stash = stash
            point.stashId = stashId
        end
    end

    return point
end

function House:UpdateInteractablePoint(id, coords, interior)
    local point

    if interior then
        point = self.interiorInterectable[id]
    else
        point = self.exteriorInterectable[id]
    end

    if not point then
        return
    end
    point.coords = coords
end

function House:RemoveInteractablePoint(id, interior)
    local point
    if interior then
        point = self.interiorInterectable[id]
    else
        point = self.exteriorInterectable[id]
    end
    if not point then return end

    if Config.ExternalInteractionSystem then
        Custom.RemoveEntityInteraction('interactable_furniture_'..id, point.entity)
        point = nil
    else
        point:remove()
    end
end

function House:RemoveExteriorInteractable()
    if not self.exteriorInterectable or not next(self.exteriorInterectable) then
        return
    end

    for _, point in pairs(self.exteriorInterectable) do
        if Config.ExternalInteractionSystem then
            Custom.RemoveEntityInteraction('interactable_exterior_'..point.id, point.entity)
        else
            point:remove()
        end
    end

    table.wipe(self.exteriorInterectable)
end

local function ToVector3(c)
    if not c then return nil end
    if type(c) == 'vector3' then return c end
    if type(c) == 'table' and c.x and c.y and c.z then
        return vector3(tonumber(c.x) or 0.0, tonumber(c.y) or 0.0, tonumber(c.z) or 0.0)
    end
    return nil
end

function House:RemoveMloPoints()
    if not self.mloPoints then return end
    for id, pt in pairs(self.mloPoints) do
        if pt.point then
            if pt.point.noty then Internal.HideText() end
            pt.point:remove()
        end
    end
    self.mloPoints = {}
end

function House:CreateMloPoints()
    self:RemoveMloPoints()
    if not self.houseData or not self.houseData.positions or not self.houseData.positions.points then return end

    self.mloPoints = {}
    for ptId, ptData in pairs(self.houseData.positions.points) do
        local coords = ToVector3(ptData.coords)
        if coords then
            local label = ptData.name or (ptData.type == 'stash' and 'Almacén' or 'Vestidor')

            -- Buscar el suelo real y fijar el marcador a la altura exacta de la cintura (~0.9m)
            local markerZ = coords.z
            local ray = StartShapeTestRay(coords.x, coords.y, coords.z + 0.5, coords.x, coords.y, coords.z - 3.5, 1, cache.ped or 0, 0)
            local _, hitG, groundHit = GetShapeTestResult(ray)
            if hitG == 1 and groundHit and groundHit.z ~= 0.0 then
                markerZ = groundHit.z + 0.9
            else
                local s, gz = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, false)
                if s then
                    markerZ = gz + 0.9
                end
            end

            local markerCoords = vector3(coords.x, coords.y, markerZ)
            local ptObj = { id = ptId, type = ptData.type, name = label, coords = markerCoords }

            local function onSelect()
                if not self.owned then return end
                if not self:hasKey() then
                    Internal.Notify(Config.Translations.notify.error.noKey, 'error', 5000)
                    return
                end

                if ptData.type == 'stash' then
                    local hasSecurity = self.houseData.settings and self.houseData.settings.upgrades and self.houseData.settings.upgrades.storage_security
                    local canOpenStash = Custom.CanOpenStash(self.id, hasSecurity)
                    if hasSecurity and not canOpenStash and not self:hasKey() then
                        Internal.Notify(Config.Translations.notify.error.storageHasSecurity, 'error', 5000)
                        return
                    end
                    local stashId = 'stashHousing_mlo_' .. self.id .. '_' .. ptId
                    Internal.OpenStash(stashId, { label = label, slots = 50, weight = 100000 })
                elseif ptData.type == 'wardrobe' then
                    Internal.Wardrobe('wardrobe_mlo_' .. self.id .. '_' .. ptId)
                end
            end

            ptObj.point = lib.points.new({
                coords = markerCoords,
                distance = 8.0,
                onExit = function(point)
                    if point.noty then
                        Internal.HideText()
                        point.noty = false
                    end
                end,
                nearby = function(point)
                    DrawMarker(2, markerCoords.x, markerCoords.y, markerCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.25, 0.25, 0.25, 216, 27, 85, 220, false, false, 2, true, nil, nil, false)

                    if point.currentDistance < 1.5 and self.owned then
                        if not point.noty then
                            Internal.DrawText(label, 'E')
                            point.noty = true
                        end
                        if IsControlJustReleased(0, 38) then
                            Internal.HideText()
                            point.noty = false
                            onSelect()
                        end
                    elseif point.noty then
                        Internal.HideText()
                        point.noty = false
                    end
                end,
                noty = false,
            })

            self.mloPoints[ptId] = ptObj
        end
    end
end

function House:DrawLight(data)
    local function nearby(point)
        if not point.state then
            return
        end

        if not data.entity or not DoesEntityExist(data.entity) then
            return
        end

        local coords = GetEntityCoords(data.entity)
        local rotation = GetEntityRotation(data.entity)

        local pitch = math.rad(rotation.x)
        local roll = math.rad(rotation.y)
        local yaw = math.rad(rotation.z)

        local direction = vector3(
            -math.sin(yaw) * math.cos(pitch),
            math.cos(yaw) * math.cos(pitch),
            math.sin(pitch)
        )

        DrawSpotLight(
            coords.x,
            coords.y,
            coords.z,
            direction.x,
            direction.y,
            direction.z,
            point.color[1],
            point.color[2],
            point.color[3],
            5.0,
            point.opacity,
            10.0,
            55.0,
            10.0
        )

        -- DrawCorona(coords.x, coords.y, coords.z, 0.3, point.color[1], point.color[2], point.color[3], 100.0, 0.06, 100.0, direction.x, direction.y, direction.z, 10.0, 5.0, 8.25, 64)
    end

    self.lights[data.id] = {
        color = data.color,
        state = data.state,
        opacity = data.opacity,
        label = data.label,
    }

    local point = lib.points.new({
        coords = vector3(data.coords.x, data.coords.y, data.coords.z),
        distance = 30.0,
        nearby = nearby,
        state = data.state,
        color = data.color,
        opacity = tonumber(string.format('%.1f', data.opacity / 10)),
    })

    return point
end

function House:UpdateLight(id, data)
    if not self.lights[id] then
        return
    end

    self.lights[id] = data

    self.lightPoints[id].state = data.state
    self.lightPoints[id].color = data.color
    self.lightPoints[id].opacity = tonumber(string.format('%.1f', data.opacity / 10))
    self.lightPoints[id].label = data.label
end

function House:RemoveLight(id)
    if self.lightPoints[id] then
        self.lightPoints[id]:remove()
        self.lightPoints[id] = nil
    end
    self.lights[id] = nil
end

-- Pone la imagen a los cuadros de una zona que la tengan y aún no estén pintados.
function House:PintarCuadros(zone)
    for _, cuadro in pairs(self.boards or {}) do
        if cuadro.zone == zone and cuadro.url and cuadro.url ~= '' and not (cuadro.data and cuadro.data.dui) then
            self:CreateBoardDui(cuadro)
        end
    end
end

function House:CreateBoardDui(data)
    if not data.url or data.url == '' then
        return
    end

    local objectData = Config.Boards[data.model]

    local board = self.boards[data.id].data

    board.dui = CreateDui(data.url, 512, 512)
    board.duiHandle = GetDuiHandle(board.dui)
    board.txdid = 'board_' ..data.id
    board.textureid = 'board_texture_' ..data.id

    board.txd = CreateRuntimeTxd(board.txdid)

    CreateRuntimeTextureFromDuiHandle(board.txd, board.textureid, board.duiHandle)

    lib.requestStreamedTextureDict(objectData.dict)

    RemoveReplaceTexture(objectData.dict, objectData.texture)
    AddReplaceTexture(objectData.dict, objectData.texture, board.txdid, board.textureid)

    SetStreamedTextureDictAsNoLongerNeeded(objectData.dict)
end

function House:UpdateBoard(id, data, zone)
    if not self.boards[id] then
        return
    end

    data.id = id
    self.boards[id].url = data.url

    if zone == 'exterior' and (not currentExteriorHouseID or currentExteriorHouseID ~= self.id) then
        debugger('Player not in exterior', currentExteriorHouseID, self.id)
        return
    end
    -- La DUI de antes se cierra: cambiar la imagen dejaba la vieja abierta.
    self:DestroyBoard(id)
    self:CreateBoardDui(data)
end


function House:DestroyBoard(id)
    if not self.boards[id] then
        return
    end

    local board = self.boards[id].data

    if board.dui then
        DestroyDui(board.dui)
    end

    board.dui = nil
end

-- ════════════════════════════════════════════════════════════════════
--  Teles
--
--  Las pinta y sincroniza origen_screens: aquí solo se dan de alta mientras
--  el mueble existe y se pone el aviso de [E] para abrir el mando. Quién puede
--  usarla (llave de la casa) lo decide el servidor en TelePermiso
--  (server/modules/furniture.lua).
-- ════════════════════════════════════════════════════════════════════

local function EsTele(model)
    local item = __indexFurniture[model]
    return item ~= nil and item.type == 'tv'
end

local function TelesDisponibles()
    return GetResourceState('origen_screens') == 'started'
end

function House:RegistrarTele(id, entity, zone, model)
    if not EsTele(model) or not entity or not DoesEntityExist(entity) then return end
    if self.teles[id] then self:QuitarTele(id) end

    local teleId = ('casa:%s:%s'):format(self.id, id)
    local tele = { teleId = teleId, entity = entity, zone = zone }
    self.teles[id] = tele

    if TelesDisponibles() then
        pcall(function()
            -- mirarInterior = false: la casa ya separa por shell o por cubo; el
            -- interior de GTA de un mueble creado por script no es fiable.
            exports.origen_screens:RegistrarTele(teleId, { entidad = entity, mirarInterior = false, despertar = true })
        end)
    end

    local function onSelect()
        if not self:hasKey() then
            Internal.Notify(Config.Translations.notify.error.noKey, 'error', 5000)
            return
        end
        if not TelesDisponibles() then return end
        exports.origen_screens:AbrirMando(teleId)
    end

    local min, max = GetModelDimensions(model)
    local distance = math.max(1.3, math.max(max.x - min.x, max.y - min.y) * 0.5 + 1.2)
    local label = Config.Translations.general.useTv or 'Mando de la tele'

    if Config.ExternalInteractionSystem then
        Custom.CreateEntityInteraction('tele_' .. id, 'tv', entity, 5.0, distance, label, onSelect)
        return
    end

    tele.point = lib.points.new({
        coords = GetEntityCoords(entity),
        distance = distance,
        onExit = function(point)
            if point.noty then Internal.HideText() end
            point.noty = false
        end,
        nearby = function(point)
            if not point.noty then
                Internal.DrawText(label, 'E')
                point.noty = true
            end
            if IsControlJustReleased(0, 38) then
                Internal.HideText()
                point.noty = false
                onSelect()
            end
        end,
        noty = false,
    })
end

function House:QuitarTele(id)
    local tele = self.teles and self.teles[id]
    if not tele then return end
    if tele.point then
        if tele.point.noty then Internal.HideText() end
        tele.point:remove()
    elseif Config.ExternalInteractionSystem then
        Custom.RemoveEntityInteraction('tele_' .. id, tele.entity)
    end
    if TelesDisponibles() then
        pcall(function() exports.origen_screens:QuitarTele(tele.teleId) end)
    end
    self.teles[id] = nil
end

function House:QuitarTeles(zone)
    if not self.teles then return end
    for id, tele in pairs(self.teles) do
        if not zone or tele.zone == zone then self:QuitarTele(id) end
    end
end

-- Si origen_screens se reinicia, pierde el registro: se vuelven a dar de alta.
AddEventHandler('origen_screens:motorListo', function()
    for _, house in pairs(House.table) do
        for _, tele in pairs(house.teles or {}) do
            if DoesEntityExist(tele.entity) then
                pcall(function()
                    exports.origen_screens:RegistrarTele(tele.teleId, { entidad = tele.entity, mirarInterior = false, despertar = true })
                end)
            end
        end
    end
end)

-- Doors

function House:FormatDoor(id)
    local data = self.houseData.doors[id]

    if not data or (not data.coords and not data.doors) then
        return nil
    end

    if data.doors then
        for i = 1, 2 do
            if not data.doors[i] or not data.doors[i].coords then
                return nil
            end
            data.doors[i].hash = joaat(string.format('door-%s-%s-%s', id, self.id, i))

            local coords = data.doors[i].coords
            data.doors[i].coords = vector3(coords.x, coords.y, coords.z)
        end

        if not data.coords then
            data.coords = data.doors[1].coords - ((data.doors[1].coords - data.doors[2].coords) / 2)
        end
    else
        data.hash = joaat(string.format('door-%s-%s', id, self.id))
    end

    if not data.coords then
        return nil
    end

    data.coords = vector3(data.coords.x, data.coords.y, data.coords.z)
    data.locked = data.locked and 1 or 0
    data.doorRate = data.type == 'garage' and 1.0 or 10.0
    
    data.distance = tonumber(data.distance) or Config.DoorDistances[data.type] or 2.0

    self.doors[id] = data
    self.doors[id].lastUsed = 0

    return data
end

function LoadDoors(houseID)
    local house = House.get(houseID)

    if not house then
        return
    end

    CreateThread(function()
        for id, data in pairs(house.houseData.doors) do
            if data and not data.furniture then 
                local door = house:FormatDoor(id)
                if door then
                    house:CreateDoor(id, door)
                end
            end
        end
    end)
end

function House:CreateDoor(id, data)
    local function addDoorToSystem(hash, model, x, y, z, state, doorRate)
        AddDoorToSystem(hash, model, x, y, z, false, false, false)
        DoorSystemSetDoorState(hash, 4, false, false)
        DoorSystemSetDoorState(hash, state, false, false)
        DoorSystemSetAutomaticRate(hash, doorRate, false, false)
    end

    local function nearby(data)
        if data.currentDistance < data.distance and self.owned then
            if not data.noty then
                currentDoorID = id
                Internal.DrawText(data.text, 'E')
                data.noty = true
            end
            if IsDisabledControlJustReleased(0, 38) then
                self:useDoor(data.doorID)
            end
        end
    end

    local function onExit(data)
        if data.noty then
            Internal.HideText()
            data.noty = false
        end
        currentDoorID = false
    end

    if data.doors then
        for _, door in ipairs(data.doors) do
            addDoorToSystem(door.hash, door.model, door.coords.x, door.coords.y, door.coords.z, data.locked, data.doorRate)
        end
    else
        addDoorToSystem(data.hash, data.model, data.coords.x, data.coords.y, data.coords.z, data.locked, data.doorRate)
    end

    if self.doorPoints[id] then
        self.doorPoints[id]:remove()
        self.doorPoints[id] = nil
    end

    self.doorPoints[id] = lib.points.new({
        coords = vector3(data.coords.x, data.coords.y, data.coords.z),
        distance = data.distance,
        onExit = onExit,
        nearby = nearby,
        text = data.locked == 1 and Config.Translations.drawtext.unlock or Config.Translations.drawtext.lock,
        noty = false,
        doorID = id,
    })
end

function House:DeleteDoor(id)
    local data = self.doors[id]

    if not data then
        debugger('Door not found')
        return
    end

    if data.doors then
        DoorSystemSetDoorState(data.doors[1].hash, 0, false, false)
        DoorSystemSetDoorState(data.doors[2].hash, 0, false, false)
    else
        DoorSystemSetDoorState(data.hash, 0, false, false)
    end

    self.houseData.doors[id] = nil

    if self.doorPoints[id] then
        self.doorPoints[id]:remove()
        self.doorPoints[id] = nil
    end

    self.doors[id] = nil
end

function House:useDoor(id)
    local houseID = self.id

    if not self.doors[id] then
        return
    end

    if not self:hasKey() then
        Internal.Notify(Config.Translations.notify.error.noKey, 'error', 5000)
        return
    end

    if self.doors[id].lastUsed + 1000 > GetGameTimer() then
        return
    end

    if (GetGameTimer() - self.doors[id].lastUsed) > 500 then
        self.doors[id].lastUsed = GetGameTimer()
        TriggerServerEvent('origen_housing:server:updateDoorState', houseID, id, not self.doors[id].locked)
        Utils.PlayAnim(cache.ped, 'anim@heists@humane_labs@finale@keycards', 'ped_a_fail_d', 500)

        self.doorPoints[id].text = self.doors[id].locked == 1 and Config.Translations.drawtext.unlock or Config.Translations.drawtext.lock

        if  self.doorPoints[id].noty then
            Internal.HideText()
            self.doorPoints[id].noty = false
        end
    end
end

function House:ToggleDoorState(id, locked)

    local data = self.doors[id]

    data.locked = locked and 1 or 0

    if data.doors then
        DoorSystemSetDoorState(data.doors[1].hash, data.locked, false, false)
        DoorSystemSetDoorState(data.doors[2].hash, data.locked, false, false)

        if data.type == 'garage' then
            DoorSystemSetHoldOpen(data.doors[1].hash, door.locked == 0)
            DoorSystemSetHoldOpen(data.doors[2].hash, door.locked == 0)
        end

        while data.locked == 1 and (not IsDoorClosed(data.doors[1].hash) or not IsDoorClosed(data.doors[2].hash)) do
            Wait(10)
        end
    else
        DoorSystemSetDoorState(data.hash, data.locked, false, false)

        if data.type == 'garage' then
            DoorSystemSetHoldOpen(data.hash, data.locked == 0)
        end

        while data.locked == 1 and not IsDoorClosed(data.hash) do
            Wait(0)
        end
    end
end

function House:StartAlarm()
    local duration = Config.AlarmDuration * 60000

    Nui.PlaySound()
    Nui.UpdateSound(0)

    debugger('Alarm activate for house with id: '..self.id, 'Duration: '..duration)

    local lastValidCoords = nil

    CreateThread(function()
        while duration > 0 do
            local sleep = 1000
            local initialZone
            local initialCoordsCheck = nil
            local distance = 0

            if currentExteriorHouseID or currentInteriorHouseID then
                initialZone = currentExteriorHouseID and 'exterior' or 'interior'

                if initialZone == 'exterior' and self.entryPoint then
                    initialCoordsCheck = vector3(self.entryPoint.coords)
                elseif initialZone == 'interior' and self.shellData and self.shellData.exitPoint then
                    initialCoordsCheck = vector3(self.shellData.exitPoint.coords)
                end

                if initialCoordsCheck then
                    lastValidCoords = initialCoordsCheck
                end
            end

            if lastValidCoords and distance < 100 then
                sleep = 100
                distance = #(GetEntityCoords(PlayerPedId()) - lastValidCoords)
                local volume = (0.01) / (distance/ 50)

                Nui.UpdateSound(volume)
            end

            duration = duration - 100
            Wait(sleep)
        end

        Nui.StopSound()

        debugger('Alarm deactivated for house with id: '..self.id)
    end)
end

function House:UpdateHouseData(key, value)
    local function splitKey(key)
        local keys = {}
        for subKey in string.gmatch(key, "[^%.]+") do
            keys[#keys+1] = subKey
        end
        return keys
    end

    local keys = splitKey(key)
    local data = self

    if #keys == 1 then
        data[keys[1]] = value
        debugger('Updated key', key, 'with value', value)
    else
        for i = 1, #keys - 1 do
            if not data[keys[i]] then
                debugger('Key not found', keys[i])
                return
            end
            data = data[keys[i]]
        end

        local finalKey = keys[#keys]
        if not data[finalKey] then
            debugger('Key not found', finalKey)
            return
        end

        data[finalKey] = value
        debugger('Updated key', key, 'with value', value)
    end
end

function House:DeleteHouse()
    if self.renderZone then
        self.renderZone:remove()
    end
    if self.exteriorZone then
        self.exteriorZone:remove()
    end
    if self.entryPoint then
        if Config.ExternalInteractionSystem then
            local coords = vector3(self.houseData.positions.entry.x, self.houseData.positions.entry.y, self.houseData.positions.entry.z + 1.0)
            Custom.RemoveCoordsInteraction('entry_house_'..self.id, coords)
        else
            self.entryPoint:remove()
        end
    end
    if self.garagePoint then
        if Config.ExternalInteractionSystem then
            local coords = vector3(self.houseData.positions.garage.x, self.houseData.positions.garage.y, self.houseData.positions.garage.z + 1.0)
            Custom.RemoveCoordsInteraction('garage_house_'..self.id, coords)
        else
            self.garagePoint:remove()
        end
    end

    Internal.RemoveGarage(self.id)

    if self.building.object then
        DeleteEntity(self.building.object)
    end

    if self.building.props then
        for _, prop in pairs(self.building.props) do
            DeleteEntity(prop)
        end
    end
    if self.building.peds then
        for _, ped in pairs(self.building.peds) do
            DeleteEntity(ped)
        end
    end

    Utils.QuitarDelMapa('casa_' .. tostring(self.id))
    self.blip = nil

    if self.doors then
        for k,v in pairs(self.doors) do
            self:DeleteDoor(k)
        end
    end

    self:DeleteFurniture('exterior')

    self:RemoveExteriorInteractable()
    self:RemoveMloPoints()

    if currentExteriorHouseID == self.id then
        currentExteriorHouseID = false
    end

    if currentInteriorHouseID == self.id then
        currentInteriorHouseID = false
    end

    House.table[self.id] = nil
    HouseData[self.id] = nil
end

RegisterNetEvent('origen_housing:client:buyHouse', function(id, data)
    local house = House.get(id)
    if not house then return debugger('Cant buy house with id: ' .. id) end
    house:UpdateHouseData('owned', data.citizenid)

    HouseData[id] = house.houseData
    HouseData[id].citizenid = data.citizenid

    if house.houseData.positions.garage and next(house.houseData.positions.garage) then
        house:CreateGaragePoint()
    end

    if not Config.Blip.showBlipInDistance or (Config.Blip.showBlipInDistance and house.nearby) then
        House.CreateBlip(house.id)
    end

    if Config.ExternalInteractionSystem then
        local coords = vector3(house.houseData.positions.entry.x, house.houseData.positions.entry.y, house.houseData.positions.entry.z + 1.0)
        Custom.RemoveCoordsInteraction('entry_house_'..house.id, coords)
    end

    if Config.ShowHousePanelOnBuy and (data.citizenid == playerIdentifier and currentExteriorHouseID == id) then
        Wait(200)
        OpenHouseMenu(id)
    end
end)

RegisterNetEvent('origen_housing:client:resetHouse', function(houseID)
    local house = House.get(houseID)
    if not house then return end

    house:UpdateHouseData('owned', nil)
    house.houseData.holders = {}
    house.houseData.holdersCount = 0
    house.houseData.citizenid = nil

    if not Config.Blip.showBlipInDistance or (Config.Blip.showBlipInDistance and house.nearby) then
        House.CreateBlip(house.id)
    end

    if house.garagePoint then
        if Config.ExternalInteractionSystem then
            local coords = vector3(house.houseData.positions.garage.x, house.houseData.positions.garage.y, house.houseData.positions.garage.z + 1.0)
            Custom.RemoveCoordsInteraction('garage_house_'..house.id, coords)
        else
            house.garagePoint:remove()
        end
    end

    HouseData[houseID] = house.houseData

    Nui.UpdateManagementMenu()
end)

RegisterNetEvent('origen_housing:client:updateHouse', function(houseID, data)
    local house = House.get(houseID)
    if not house then return end

    local oldGarageCoords = house.houseData.positions?.garage
    local oldEntryCoords = house.houseData.positions?.entry
    
    house.houseData.name = data.name
    house.houseData.data = data.data
    house.houseData.positions = data.positions
    house.houseData.exterior = data.exterior
    house.houseData.garage = data.garage

    house.garage = (__indexGarages[data.garage] and __indexGarages[data.garage]) or false

    if not Config.Blip.showBlipInDistance or (Config.Blip.showBlipInDistance and house.nearby) then
        House.CreateBlip(house.id)
    end

    if house.nearby then 
        if data.reposition.zone then
            if house.exteriorZone then
                house.exteriorZone:remove()
            end

            house:CreateExteriorZone()
        end
           
        if data.reposition.entry then
            if house.entryPoint then
                if Config.ExternalInteractionSystem then
                    local coords = vector3(oldEntryCoords.x, oldEntryCoords.y, oldEntryCoords.z + 1.0)
                    Custom.RemoveCoordsInteraction('entry_house_'..house.id, coords)
                else
                    house.entryPoint:remove()
                end
            end

            house:CreateEntryPoint()
        end
    
        if data.reposition.garage then
            if house.garagePoint then
                if Config.ExternalInteractionSystem then
                    local coords = vector3(oldGarageCoords.x, oldGarageCoords.y, oldGarageCoords.z + 1.0)
                    Custom.RemoveCoordsInteraction('garage_house_'..house.id, coords)
                else
                    house.garagePoint:remove()
                end
            end

            Internal.RemoveGarage(house.id)

            if house.owned and house.houseData.positions.garage and next(house.houseData.positions.garage) then
                house:CreateGaragePoint()
            end
        end
    end

    HouseData[houseID] = house.houseData

    Nui.UpdateManagementMenu()
end)

RegisterNetEvent('origen_housing:client:updateDoorState', function(houseID, doorID, state)
    local house = House.get(houseID)
    if not house then return end
    doorID = tostring(doorID)
    if not house.houseData.doors then house.houseData.doors = {} end
    if not house.houseData.doors[doorID] then
        house.houseData.doors[doorID] = { name = Config.Translations.general.entry or 'Entrada', locked = state }
    else
        house.houseData.doors[doorID].locked = state
    end

    if house.shellData then
        if not house.shellData.doors then house.shellData.doors = {} end
        if not house.shellData.doors[doorID] then
            house.shellData.doors[doorID] = { name = Config.Translations.general.entry or 'Entrada', locked = state }
        else
            house.shellData.doors[doorID].locked = state
        end
    end

    if house.doors[doorID] then
        house:ToggleDoorState(doorID, state)

        if house.doorPoints[doorID] and house.doorPoints[doorID].noty then
            house.doorPoints[doorID].text = (house.doors[doorID].locked == 1 or house.doors[doorID].locked == true) and Config.Translations.drawtext.unlock or Config.Translations.drawtext.lock
            house.doorPoints[doorID].noty = false

            Internal.HideText()
        end
    end

    debugger('Door state updated', doorID, state)
end)

RegisterNetEvent('origen_housing:client:createDoor', function(houseID, data)
    local house = House.get(houseID)
    if not house then return end

    house.houseData.doors[data.id] = data

    local door = house:FormatDoor(data.id)

    house:CreateDoor(data.id, door)

    debugger('Door created', data.id)
end)

RegisterNetEvent('origen_housing:client:deleteDoor', function(houseID, doorID)
    local house = House.get(houseID)
    if not house then return end

    --[[ if not house.nearby then
        return
    end ]]

    house:DeleteDoor(doorID)

    debugger('Deleted door', doorID)
end)

RegisterNetEvent('origen_housing:client:updateHolders', function(houseID, holders, resumen)
    local house = House.get(houseID)
    if not house then return end

    house:UpdateHouseData('houseData.holders', holders)
    -- la cuenta de llaves («2/3»…), para la lista del dueño y la ficha del admin
    if type(resumen) == 'table' then
        house.houseData.llaves = resumen
        SendNUIMessage({ action = 'llavesResumen', id = houseID, llaves = resumen })
    end

    if not Config.Blip.showBlipInDistance or (Config.Blip.showBlipInDistance and house.nearby) then
        House.CreateBlip(house.id)
    end

    Nui.UpdateManagementMenu()
end)

RegisterNetEvent('origen_housing:client:DeleteHouse', function(id)
    local house = House.get(id)
    if not house then return end

    house:DeleteHouse()
end)

RegisterNetEvent('origen_housing:client:updateConstruction', function(id, construction, update)
    local house = House.get(id)

    if not house then return end

    house:UpdateHouseData('houseData.construction', construction)

    if not house.nearby or not update then
        return
    end

    house:RemoveBuildingStage()
    Wait(1000)
    house:CreateBuilding()
end)

RegisterNetEvent('origen_housing:client:updateSettings', function(id, data, setting)
    local house = House.get(id)

    if not house then return end

    if setting == 'upgrades' then
        house:UpdateHouseData('houseData.settings.upgrades', data)
    elseif setting == 'lights' then
        house:UpdateHouseData('houseData.settings.lights', data)
    end
end)

RegisterNetEvent('origen_housing:client:updateFurniture', function(houseID, zone, furnitureID, furnitureData, interior)
    local house = House.get(houseID)

    if not house then return end

    if not house.houseData.furniture[zone] then
        house.houseData.furniture[zone] = {}
    end

    house.houseData.furniture[zone][furnitureID] = furnitureData

    if not interior and not house.nearby then
        return
    end

    house:UpdateObject(furnitureID, furnitureData, interior)
end)

RegisterNetEvent('origen_housing:client:kickFromHouse', function(houseID)
    local house = House.get(houseID)
    if not house then return end

    local interiorData = house.shellData

    if not interiorData then return end

    interiorData:Exit()
end)

--- La casa se ha vaciado (CK del dueño). Los muebles de dentro se guardan aqui
--- la primera vez que se entra y no se vuelven a pedir: sin esto, quien ya
--- hubiera entrado seguiria viendo los del dueño anterior.
RegisterNetEvent('origen_housing:client:mueblesVaciados', function(houseID)
    local house = House.get(houseID)
    if not house or type(house.houseData.furniture) ~= 'table' then return end
    house.houseData.furniture.interior = {}
end)

RegisterNetEvent('origen_housing:client:updateHouseStyle', function(houseID, style)
    local house = House.get(houseID)
    if not house then return end
    house:UpdateHouseData('houseData.data.style', style)
end)

RegisterNetEvent('origen_housing:client:updateLight', function(houseID, lightID, data, zone)

    local house = House.get(houseID)
    if not house then return end

    if not house.houseData.furniture[zone] then
        return
    end

    house.houseData.furniture[zone][lightID] = data

    if not house.nearby and not currentInteriorHouseID then
        return
    end

    house:UpdateLight(lightID, data)
end)


RegisterNetEvent('origen_housing:client:updateBoard', function(houseID, boardID, data, zone)
    local house = House.get(houseID)
    if not house then return end

    if not house.houseData.furniture[zone] then
        return
    end

    house.houseData.furniture[zone][boardID] = data

    house:UpdateBoard(boardID, data, zone)
end)

RegisterNetEvent('origen_housing:client:syncMloPoints', function(houseID, points)
    local house = House.get(houseID)
    if not house then return end

    house.houseData.positions = house.houseData.positions or {}
    house.houseData.positions.points = points

    if house.nearby and house.owned and house.houseData.data.type == 'mlo' then
        house:CreateMloPoints()
    end

    HouseData[houseID] = house.houseData
    Nui.UpdateManagementMenu()
end)

RegisterNetEvent('origen_housing:client:syncMloLimits', function(houseID, limits)
    local house = House.get(houseID)
    if not house then return end

    house.houseData.positions = house.houseData.positions or {}
    house.houseData.positions.limits = limits

    HouseData[houseID] = house.houseData
    Nui.UpdateManagementMenu()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for _, house in pairs(House.table) do
        house:QuitarTeles()
        for k in pairs(house.boards or {}) do house:DestroyBoard(k) end
    end

    if props then
        for _, prop in pairs(props) do
            DeleteEntity(prop)
        end
    end
    if peds then
        for _, ped in pairs(peds) do
            DeleteEntity(ped)
        end
    end

    if createdGarages then
        for houseID, _ in pairs(createdGarages) do
            Internal.RemoveGarage(houseID)
        end
    end
end)

local function loadFurnitureData(houseID)
    local house = House.get(houseID)
    if not house then return end

    for zone, furniture in pairs(house.houseData.furniture) do
        if furniture then 
            for id, object in pairs(furniture) do
                if object.type == 'camera' then
                    if not house.cameras[id] then
                        house.cameras[id] = {
                            model = object.model,
                            zone = zone,
                            coords = nil,
                            rotation = nil,
                            entity = nil,
                        }
                    end
                elseif object.type == 'light' then
                    if not house.lights[id] then
                        house.lights[id] = {
                            label = object.label,
                            state = object.state,
                            color = object.color,
                            opacity = object.opacity,
                        }
                    end
                elseif object.type == 'board' then
                    if not house.boards[id] then
                        house.boards[id] = {
                            id = id,
                            entity = nil,
                            model = object.model,
                            url = object.url,
                            zone = zone,
                            data = {},
                        }
                    end
                end
            end
        end
    end
end

function OpenHouseMenu(id)
    local houseID

    if id then
        houseID = id
    else
        if not currentExteriorHouseID and not currentInteriorHouseID then
            return
        end
        houseID = currentExteriorHouseID and currentExteriorHouseID or currentInteriorHouseID
    end
    local house = House.get(tonumber(houseID))

    if not house then return end

    if not house:hasKey() then
        Internal.Notify(Config.Translations.notify.error.noKey, 'error', 5000)
        return
    end

    if not Custom.CanOpenHouseMenu() then return end

    requestFurniture(houseID, 'exterior')
    requestFurniture(houseID, 'interior')

    loadFurnitureData(houseID)

    house.houseData.cameras = house.cameras
    house.houseData.lights = house.lights
    house.houseData.boards = house.boards

    Nui.OpenHouseMenu(house.houseData)
end

if Config.Commands.OpenManagementMenu.enabled then 
    lib.addKeybind({
        name = Config.Commands.OpenManagementMenu.cmd,
        description = Config.Translations.commands.OpenManagementMenu,
        defaultKey = Config.Commands.OpenManagementMenu.key,
        onPressed = function(self)
            if not currentExteriorHouseID and not currentInteriorHouseID then
                if IsNuiFocused() then return end
                Nui.OpenHousesMenu()
                return
            end
        
            if IsNuiFocused() then return end
            OpenHouseMenu()
        end,
    })
end

--[[ ── Soltar la O ──────────────────────────────────────────────────────────

     Quitar la tecla del config no basta: FiveM se guarda los atajos en los
     ajustes del jugador, asi que al que ya la tenia atada le sigue abriendo el
     menu de propiedades con la O aunque el recurso ya no la pida.

     Esto la suelta una sola vez por maquina y deja una marca para no repetirlo
     en cada arranque. El mismo apaño que usa origen_inventory con F5, F6 y F7.

     El respiro de ocho segundos es porque al arrancar los recursos todavia
     estan registrando sus propios atajos, y desatar en mitad de eso puede no
     prender o pelearse con un registro que llega justo despues. ]]
local MARCA_O_SUELTA = 'origen_housing_tecla_o_vieja_v1'

CreateThread(function()
    if GetResourceKvpString(MARCA_O_SUELTA) == 'hecho' then return end

    Wait(8000)
    ExecuteCommand('unbind keyboard o')
    SetResourceKvp(MARCA_O_SUELTA, 'hecho')
end)

RegisterNetEvent('origen_housing:client:sensorAlert', function(houseID)
    local house = House.get(houseID)

    if not house then
        return
    end

    if not house:hasKey() then return end

    local houseID = house.id
    local houseName = house.houseData.name
    
    if (currentExteriorHouseID and currentExteriorHouseID == houseID) or (currentInteriorHouseID and currentInteriorHouseID == houseID) then
        debugger('Sensor alert | House id match')
        return
    end

    Internal.Notify(Config.Translations.notify.info.sensorAlert:format(houseName), 'error', 5000)
end)

RegisterNetEvent('origen_housing:client:startAlarm', function(houseID)
    local house = House.get(houseID)
    if not house then
        return
    end
    house:StartAlarm()
end)

local tryLockpickCount = 0
local lockpickData = {
    advanced = false,
    houseID = false,
    doorID = false,
}

local function resetLockpickData()
    lockpickData.advanced = false
    lockpickData.doorID = false
    lockpickData.houseID = false
end

function LockpickResult(success)
    if success then
        Internal.Notify(Config.Translations.notify.success.lockpickSuccess, 'success', 5000)
        TriggerServerEvent('origen_housing:server:lockpickDoor', lockpickData.houseID, lockpickData.doorID)
        tryLockpickCount = 0
    else
        Internal.Notify(Config.Translations.notify.error.lockpickFail, 'error', 5000)
        tryLockpickCount = tryLockpickCount + 1
        if tryLockpickCount > Config.Lockpick.maxTry then
            Internal.Notify(Config.Translations.notify.error.lockpickBroken, 'error', 5000)
            TriggerServerEvent('origen_housing:server:removeLockpick', lockpickData.advanced)
            tryLockpickCount = 0
        end
    end
end

local dispatchCooldownSeconds = 30
local dispatchSend = 0

local function getClosestDoorID(houseId, distance)
    local house = House.get(houseId)
    if not house then return end

    local coords = GetEntityCoords(cache.ped)
    if house.houseData.data.type == 'ipl' or house.houseData.data.type == 'shell' then
        local entryPoint = house.entryPoint
        if entryPoint then
            local entryPointCoords = entryPoint.coords
            local entryPointDistance = #(coords - entryPointCoords)
            if entryPointDistance < distance then
                return 1
            end
        end
        return false
    end

    if currentDoorID then
        return currentDoorID
    end
    return false
end

local function startLockpickProcess(advancedItem)

    if not Config.Lockpick.enabled then return debugger('Lockpicking disabled') end

    debugger('Lockpick started | Advanced Item: '..tostring(advancedItem))
    resetLockpickData()

    local house = House.get(currentExteriorHouseID or currentInteriorHouseID)
    if not house then return end

    if not house.houseData.holders or not next(house.houseData.holders) then
        debugger('House not owned, cant rob')
        return
    end

    local doorID = getClosestDoorID(house.id, 2.0)
    if not doorID then return end

    local doorsUpgrade = house.houseData.settings.upgrades.doors

    local alarm = house.houseData.settings.upgrades.alarm
    if alarm then
        local currentTime = GetGameTimer()
        if not dispatchSend or (currentTime - dispatchSend > dispatchCooldownSeconds * 1000) then
            local playerCoords = GetEntityCoords(cache.ped)
            debugger('^3Sending dispatch to coords^0', json.encode(playerCoords))
            Custom.Dispatch(playerCoords)
            dispatchSend = currentTime
        end
    end

    lockpickData.advanced = advancedItem
    lockpickData.houseID = house.id
    lockpickData.doorID = doorID

    if doorsUpgrade and not lockpickData.advanced then
        Internal.Notify(Config.Translations.notify.info.lockpickAdvancedNeeded, 'error', 5000)
        return
    end

    local function initiateLockpick()
        if Config.Lockpick.customLockpickMinigame then
            Custom.LockpickMinigame(lockpickData.advanced)
            return
        end

        --[[ El minijuego de la casa va primero.

             La autodeteccion de arriba (init.lua) solo busca qb-lockpick y
             lockpick, y en ORIGEN no esta ninguno de los dos: LockpickSystem
             se quedaba en "No lockpick resource found" y esta funcion no hacia
             NADA. Ni error ni aviso: pulsabas la ganzua y no pasaba nada.

             origen_minijuegos si esta, y es el mismo minijuego que ya usa
             origen_carboosting. La ganzua avanzada abre la version dificil,
             que es lo que la distingue de la normal. ]]
        if GetResourceState('origen_minijuegos') == 'started' then
            exports.origen_minijuegos:StartLockpick(
                lockpickData.advanced and 'hard' or 'medium',
                function(exito) LockpickResult(exito) end
            )
            return
        end

        if Config.LockpickSystem == 'qb-lockpick' then
            TriggerEvent('qb-lockpick:client:openLockpick', LockpickResult)
        elseif Config.LockpickSystem == 'lockpick' then
            local result = exports['lockpick']:startLockpick()
            LockpickResult(result)
        else
            -- Que no haya minijuego no puede ser un silencio: se dice.
            Internal.Notify('No hay sistema de ganzua disponible', 'error', 5000)
        end
    end

    initiateLockpick()
end

RegisterNetEvent('origen_housing:client:startLockpick', startLockpickProcess)

RegisterNetEvent('lockpicks:UseLockpick', startLockpickProcess)

--** EXPORTS **--

function getPlayerHouses(identifier)
    identifier = identifier or playerIdentifier

    if not identifier then
        return false
    end

    local houses = lib.callback.await('origen_housing:server:getOwnedHouses', false, identifier)
    local retval = {}

    if not houses or not next(houses) then
        return false
    end

    for _, houseID in pairs(houses) do
        local house = House.get(houseID)
        if house then 
            local id = houseID
            house = house.houseData
            retval[id] = house
            retval[id].label = house.name
            retval[id].location = house.data.location
            retval[id].desc = "House"
            retval[id].icon = "house.svg"
            retval[id].coords = vector4(house.positions.entry.x, house.positions.entry.y, house.positions.entry.z, house.positions.entry.w)
        end
    end

    return retval
end

function insideHouse()
    local houseID = currentInteriorHouseID or currentExteriorHouseID

    if not houseID then
        return false, 'no_house'
    end

    local house = House.get(houseID)

    if not house then
        return false, 'invalid_house'
    end

    local houseType = house.houseData.data.type

    if houseType == 'mlo' then
        return true, 'mlo'
    else
        return true, currentInteriorHouseID and 'interior' or 'exterior'
    end
end

function CloseHouseMenu()
    Nui.CloseHouseMenu()
end

function getNearbyHouse()
    return currentInteriorHouseID or currentExteriorHouseID
end

function setHousePosition(houseID)
    local house = House.get(houseID)

    if not house then return end

    local entry = house.houseData.positions.entry
    SetNewWaypoint(entry.x, entry.y)
end

function toggleDoor(id, door)
    local house = House.get(id)

    if not house then return end

    if not door then
        return false
    end

    local data = lib.callback.await('origen_housing:server:toggleLock', false, {
        houseID = id,
        doorID = door,
    })

    return data and data.status and data.locked
end

function getHouseDoor(id)
    local house = House.get(id)
    if not house then return end

    local door = nil

    if house.houseData.data.type == 'ipl' or house.houseData.data.type == 'shell' then
        door = 1
    elseif house.houseData.data.type == 'mlo' then

        if not house.houseData.doors or not next(house.houseData.doors) then
            return nil
        end

        for k,v in pairs(house.houseData.doors) do
            door = k
            break
        end
    end

    return door
end

function addKeyHolder(houseID, target)
    local addKey = lib.callback.await('origen_housing:server:addKeyHolder', false, {
        houseID = houseID,
        target = target,
    })

    return addKey
end

function removeKeyHolder(houseID, identifier)
    local removeKey = lib.callback.await('origen_housing:server:removeKeyHolder', false, {
        houseID = houseID,
        identifier = identifier,
    })

    return removeKey
end

function getHouses()
    return HouseData
end

exports('insideHouse', insideHouse) -- exports['origen_housing']:insideHouse()
exports('getNearbyHouse', getNearbyHouse) -- exports['origen_housing']:getNearbyHouse()
exports('OpenHouseMenu', OpenHouseMenu) -- exports['origen_housing']:OpenHouseMenu()
exports('CloseHouseMenu', CloseHouseMenu) -- exports['origen_housing']:CloseHouseMenu()
exports('getPlayerHouses', getPlayerHouses) -- exports['origen_housing']:getPlayerHouses(identifier) -- label | locacion | desc | entryCoords
exports('setHousePosition', setHousePosition) -- exports['origen_housing']:setHousePosition(houseID)
exports('toggleDoor', toggleDoor) -- exports['origen_housing']:toggleMainDoor(houseID)
exports('getHouseDoor', getHouseDoor) -- exports['origen_housing']:getHouseDoor(houseID)

exports('addKeyHolder', addKeyHolder) -- exports['origen_housing']:addKeyHolder(houseID, target)
exports('removeKeyHolder', removeKeyHolder) -- exports['origen_housing']:removeKeyHolder(houseID, identifier)
exports('getHouses', getHouses) -- exports['origen_housing']:getHouses()

exports('isBusy', function()
    return LocalPlayer.state.IsBusy
end)

local function playAnim()
    lib.requestAnimDict(Config.Raid.animation.dict)

    TaskPlayAnim(cache.ped, Config.Raid.animation.dict, Config.Raid.animation.anim, 8.0, -8.0, -1, 0, 0, false, false, false)

    RemoveAnimDict(Config.Raid.animation.dict)
end

RegisterNetEvent('origen_housing:client:startRaid', function()
    local house = House.get(currentExteriorHouseID or currentInteriorHouseID)
    if not house then return end

    if not house.houseData.holders or not next(house.houseData.holders) then
        return
    end

    local doorID = getClosestDoorID(house.id, 2.0)
    if not doorID then return end

    debugger('Raid started | House id: '..house.id..' | Door id: '..doorID)

    if Config.Raid.skillcheck then
        playAnim()
        local success = Custom.RaidSkillcheck()
        StopAnimTask(cache.ped, Config.Raid.animation.dict, Config.Raid.animation.anim, 1.0)
        if not success then
            Internal.Notify(Config.Translations.notify.error.raidSkillcheckFailed, 'error', 5000)
            return
        end
    end

    local canEnter = lib.callback.await('origen_housing:server:canRaid', false, {
        houseID = house.id,
        doorID = doorID,
    })

    if canEnter then 
        local allowVehicles = house.houseData.data.allowVehicles

        local vehicle = GetVehiclePedIsIn(cache.ped, false)

        if vehicle ~= 0 and not allowVehicles then
            Internal.Notify(Config.Translations.notify.error.vehicleNotAllowed, 'error', 5000)
            return
        end

        Wait(500)

        house:EnterHouse()
        
        Custom.OnEnterHouse(house.id)
    end
end)
