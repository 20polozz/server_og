---@diagnostic disable: inject-field
local Thread = CreateThread

WorldPoint = {}
WorldPoint.__index = WorldPoint

WorldPoint.instances = {}

local wpInteractionConfig = Config.WorldPoints.Interaction
local wpSecurityConfig = Config.WorldPoints.Security

function WorldPoint.init(pointData)
    local instance = {
        id = RandomStr(10),

        internalId = pointData.id or nil,
        type = pointData.type or 'stash',
        label = pointData.label or 'WorldPoint',
        enable = pointData.enable,

        locations = pointData.locations or {},
        zoneDistance = pointData.zoneDistance or 10.0,
        groups = pointData.groups or {},

        blipInfo = pointData.blip,
        markerInfo = pointData.marker,

        points = {},
        blips = {},
        entities = {},
        data = pointData.data or {},
        npc = pointData.npc,
        prop = pointData.prop,
        options = pointData.options,
        sprite = pointData.sprite,
        hooks = pointData.hooks,

        -- Security
        security = {
            interactionsPerSecond = 0
        },
    }
    local self = setmetatable(instance, WorldPoint)

    self:setDefaults()
    self:refresh()

    WorldPoint.instances[self.id] = self
    self:debug('success', "Created WorldPoint")
    return self
end

function WorldPoint:setDefaults()
    if self.npc == nil then
        self.npc = false
    else
        if not self.npc.locations then
            self.npc.locations = {}
        end
    end

    if self.prop == nil then
        self.prop = false
    else
        if not self.prop.locations then
            self.prop.locations = {}
        end
    end

    ---@diagnostic disable-next-line: undefined-field
    if type(self.npc) == "table" and (not self.npc.model or self.npc.model == '') then
        self.npc = false
    end

    ---@diagnostic disable-next-line: undefined-field
    if type(self.prop) == "table" and (not self.prop.model or self.prop.model == '') then
        self.prop = false
    end

    if not self.markerInfo then
        self.markerInfo = {
            type = 20,
            size = vector3(0.3, 0.3, 0.3),
            color = { r = 216, g = 27, b = 85, a = 255 },
            distanceView = 5,
            distanceInteract = 1
        }
    else
        if not self.markerInfo.type then
            self.markerInfo.type = 20
        end
        if not self.markerInfo.size then
            self.markerInfo.size = vector3(0.3, 0.3, 0.3)
        end
        if not self.markerInfo.color then
            self.markerInfo.color = { r = 216, g = 27, b = 85, a = 255 }
        end

        if not self.markerInfo.drawOverEnts then
            self.markerInfo.drawOverEnts = false
        end

        if not self.markerInfo.bobUpAndDown then
            self.markerInfo.bobUpAndDown = false
        end

        if not self.markerInfo.faceCamera then
            self.markerInfo.faceCamera = false
        end

        if not self.markerInfo.distanceView then
            self.markerInfo.distanceView = 5
        end
        if not self.markerInfo.distanceInteract then
            self.markerInfo.distanceInteract = 1.5
        end

        if self.markerInfo.distanceInteract > self.markerInfo.distanceView then
            self.markerInfo.distanceInteract = self.markerInfo.distanceView - 1
        end
    end

    if not self.blipInfo then
        self.blipInfo = {
            enabled = false,
            sprite = 52,
            color = 2,
            scale = 0.8,
            name = nil,
            drawOverEnts = false,
            bobUpAndDown = false,
            faceCamera = false,
        }
    else
        if type(self.blipInfo.enabled) == 'nil' then
            self.blipInfo.enabled = false
        end
        if not self.blipInfo.sprite then
            self.blipInfo.sprite = 52
        end
        if not self.blipInfo.color then
            self.blipInfo.color = 2
        end
        if not self.blipInfo.scale then
            self.blipInfo.scale = 0.8
        end

        if not self.blipInfo.name then
            self.blipInfo.name = nil
        end
    end

    if self.type == 'stash' then
        if not self.data then
            self.data = {
                slots = 20,
                maxweight = 100000
            }
        else
            if not self.data.slots then
                self.data.slots = 20
            end
            if not self.data.maxweight then
                self.data.maxweight = 100000
            end
        end
    elseif self.type == 'shop' then
        if not self.data then
            self.data = {
                items = {},
                slots = self.data.slots or 20,
                owner = self.data.owner
            }
        else
            if not self.data.items then
                self.data.items = {}
            end

            if not self.data.slots then
                self.data.slots = 20
            end

            if not self.data.owner then
                self.data.owner = nil
            end
        end
    end
end

function WorldPoint:drawMarker(location, asDebug)
    local m = self.markerInfo
    local mType = not asDebug and m.type or 1
    local color = not asDebug and m.color or { r = 216, g = 27, b = 85, a = 150 }
    local size = not asDebug and m.size or vector3(0.4, 0.4, 0.4)

    ---@diagnostic disable-next-line: param-type-mismatch, trailing-space, missing-parameter
    DrawMarker(mType,
        location.x,
        location.y,
        location.z,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        size.x, size.y, size.z,
        color.r, color.g, color.b, color.a,
        m.bobUpAndDown, m.faceCamera, 0, m.rotate, nil, nil, m.drawOverEnts
    )
end

function WorldPoint:requestModel(modelHash)
    local model = type(modelHash) == 'number' and modelHash or GetHashKey(modelHash)
    local checkTimes = 0
    if not HasModelLoaded(model) then
        RequestModel(model)
        while not HasModelLoaded(model) do
            Wait(100)
            checkTimes = checkTimes + 1
            if checkTimes > 50 then
                self:debug('error', ("Failed to load model for WorldPoint NPC/Prop: %s"):format(modelHash))
                return false
            end
        end
    end

    return model
end

function WorldPoint:spawnProp(locationIndex, location, propID)
    local propData = self.prop
    if not propData then return end

    local propModel = self:requestModel(propData.model)
    if not propModel then return end

    ---@diagnostic disable-next-line: missing-parameter, param-type-mismatch
    local prop = CreateObject(propModel, location.x, location.y, location.z, false, true, true)
    if not prop then return end

    self.entities[propID] = prop
    SetEntityAsMissionEntity(prop, true, true)
    FreezeEntityPosition(prop, true)
    SetEntityInvincible(prop, true)
    SetBlockingOfNonTemporaryEvents(prop, true)
    SetModelAsNoLongerNeeded(propModel)
    SetEntityHeading(prop, location.w)

    if propData.locations and propData.locations[locationIndex] and propData.locations[locationIndex].x ~= 0 then
        local loc = propData.locations[locationIndex]
        SetEntityCoordsNoOffset(prop, loc.x or location.x, loc.y or location.y, loc.z or location.z, false, false, false)
        SetEntityHeading(prop, loc.w or location.w)
    end

    if propData.setOnGround then
        PlaceObjectOnGroundProperly(prop)
    end

    if propData.collisions == false then
        SetEntityCollision(prop, false, false)
    end

    if propData.bucket then
        TriggerServerEvent('orgInv:setEntityToRouting', NetworkGetNetworkIdFromEntity(prop), propData.bucket)
    end

    return prop
end

function WorldPoint:despawnProp(propID)
    if self.entities[propID] then
        DeleteEntity(self.entities[propID])
    end

    self.entities[propID] = nil
end

function WorldPoint:spawnNPC(locationIndex, location, npcID)
    local npcData = self.npc
    if not npcData then return end

    local npcModel = self:requestModel(npcData.model)
    if not npcModel then return end

    if self.entities[npcID] then
        if DoesEntityExist(self.entities[npcID]) then
            DeleteEntity(self.entities[npcID])
            self.entities[npcID] = nil
        end
    end

    ClearAreaOfPeds(location.x, location.y, location.z, 5.0, false)
    local npc = CreatePed(0, npcModel, location.x, location.y, location.z, location.w, false, false)

    if not npc then return end

    self.entities[npcID] = npc
    SetEntityAsMissionEntity(npc, true, true)
    FreezeEntityPosition(npc, true)
    SetEntityInvincible(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    SetEntityCanBeDamaged(npc, false)
    SetEntityCanBeTargetedWithoutLos(npc, false)
    SetPedCanEvasiveDive(npc, false)
    SetPedConfigFlag(npc, 43, true)
    SetPedCanBeTargettedByPlayer(npc, PlayerId(), false)
    SetPedPrimaryLookat(npc, PlayerPedId())
    SetModelAsNoLongerNeeded(npcModel)
    SetEntityHeading(npc, location.w)

    if npcData.locations and npcData.locations[locationIndex] and npcData.locations[locationIndex].x ~= 0 then
        local loc = npcData.locations[locationIndex]
        SetEntityCoordsNoOffset(npc, loc.x, loc.y, loc.z, false, false, false)
        SetEntityHeading(npc, loc.w)
    end

    if npcData.scenario and npcData.scenario.enabled then
        TaskStartScenarioInPlace(
            npc,
            npcData.scenario.id,
            0,
            true
        )
    end

    self:debug('info', ("Spawning NPC for WorldPoint: %s"):format(self.internalId))

    return npc
end

function WorldPoint:despawnNPC(npcID)
    if self.entities[npcID] then
        DeleteEntity(self.entities[npcID])
    end

    self.entities[npcID] = nil
end

function WorldPoint:generatePoints()
    -- Un sitio sin x/y/z no se pinta. Antes se convertia en 0,0,0 y ahi se
    -- juntaron las 600 y pico taquillas de policia que no tenian coordenadas.
    local locations = {}
    for k, location in pairs(self.locations) do
        local tipo = type(location)
        local indexable = tipo == 'table' or tipo == 'vector3' or tipo == 'vector4'
        if indexable and tonumber(location.x) and tonumber(location.y) and tonumber(location.z) then
            locations[k] = location
        else
            self:debug('info', ("WorldPoint sin coordenadas, no se pinta: %s"):format(self.internalId))
        end
    end

    for k, location in pairs(locations) do
        local x, y, z, w = tonumber(location.x) or 0.0, tonumber(location.y) or 0.0, tonumber(location.z) or 0.0, tonumber(location.w) or 0.0
        local locationV4 = vec4(x, y, z, w)
        local locationVec3 = vec3(x, y, z)

        local interacting = false
        local hookSended = false

        local npcID = string.format("%s_npc_%s", self.id, k)
        local propID = string.format("%s_prop_%s", self.id, k)

        local onInteractKey = function()
            Thread(function()
                while interacting and self.enable do
                    -- print(interacting, self.enable)
                    local cooldownMs = 0

                    local pCoords = GetEntityCoords(PlayerPedId())
                    local currentDistance = #(locationVec3 - pCoords)
                    local interactDistance = self.markerInfo.distanceInteract

                    if currentDistance > interactDistance then
                        cooldownMs = wpInteractionConfig.behavior.cooldownMs or 200
                        break
                    end

                    if wpInteractionConfig.behavior.allowInteractionInVehicle and IsPedInAnyVehicle(PlayerPedId(), false) then
                        cooldownMs = wpInteractionConfig.behavior.cooldownMs or 200
                        goto continue
                    end
                    if wpSecurityConfig.checkPlayerState then
                        if IsEntityDead(PlayerPedId()) then
                            cooldownMs = wpInteractionConfig.behavior.cooldownMs or 200
                            goto continue
                        end
                    end

                    if IsControlJustReleased(0, wpInteractionConfig.keys.interact) then
                        local canInteract = TriggerEventHooks('worldpoint-canInteract', {
                            type = self.type,
                            id = self.internalId,
                        })

                        if canInteract then
                            if wpInteractionConfig.feedback.playSounds then
                                PlaySoundFrontend(-1, wpInteractionConfig.feedback.interactSound.name,
                                    wpInteractionConfig.feedback.interactSound.set, true)
                            end

                            self:onInteract()
                        end

                        cooldownMs = wpInteractionConfig.behavior.cooldownMs or 200
                    end

                    :: continue ::

                    Wait(cooldownMs)
                end
            end)
        end

        local worldPointsDebug = Config.WorldPoints.Debug

        local nearby = function()
            local pCoords = GetEntityCoords(PlayerPedId())
            local distance = #(locationVec3 - pCoords)
            local markerDistanceDraw = self.markerInfo.distanceView

            if distance > markerDistanceDraw then return end

            TriggerEventHooks('worldpoint-area-nearby', {
                type = self.type,
                id = self.internalId,
                location = locationVec3,
                label = self.label,
                data = self.data,
                sprite = self.sprite,
                options = self.options
            })

            local showMarker = self.markerInfo.show
            if (not self.npc and not self.prop) and (showMarker or type(showMarker) == 'nil') then
                self:drawMarker(locationVec3)
            end

            local interactDistance = self.markerInfo.distanceInteract
            if distance <= interactDistance then
                if not interacting then
                    interacting = true
                    onInteractKey()
                end


                if not hookSended then
                    hookSended = true
                    TriggerEventHooks(self.hooks.interactIn, {
                        type = self.type,
                        id = self.internalId,
                        location = locationVec3,
                        label = self.label,
                        sprite = self.sprite,
                        options = self.options

                    })
                end
            else
                if interacting then
                    interacting = false
                    if Player and Player.isOpen then
                        Player:CloseSecondInventory()
                    end
                end

                if hookSended then
                    TriggerEventHooks(self.hooks.interactOut, {
                        type = self.type,
                        id = self.internalId,
                        location = locationVec3,
                        label = self.label,
                        sprite = self.sprite,
                        options = self.options
                    })
                    hookSended = false
                end
            end
        end


        local onEnter = function()
            self:debug('info', ("Player entered WorldPoint area: %s"):format(self.internalId))
            if self.npc and not self.entities[npcID] then
                self:spawnNPC(k, locationV4, npcID)
            end

            if not self.entities[npcID] and (self.prop and not self.entities[propID]) then
                self:debug('info', ("Spawning Prop for WorldPoint: %s"):format(self.internalId))
                self:spawnProp(k, locationV4, propID)
            end

            TriggerEventHooks('worldpoint-area-in', {
                type = self.type,
                id = self.internalId,
                location = locationVec3,
                label = self.label,
            })
        end

        local onExit = function()
            if self.npc and self.entities[npcID] then
                self:debug('info', ("Despawning NPC for WorldPoint: %s"):format(self.internalId))
                self:despawnNPC(npcID)
            end

            if self.prop and self.entities[propID] then
                self:debug('info', ("Despawning Prop for WorldPoint: %s"):format(self.internalId))
                self:despawnProp(propID)
            end

            TriggerEventHooks('worldpoint-area-out', {
                type = self.type,
                id = self.internalId,
                location = locationVec3,
                label = self.label
            })

            Player:CloseInventory()
        end

        local pointId = string.format("%s_%s", self.id, k)
        local distance = self.zoneDistance
        local point = Points.new({
            id = pointId,
            coords = locationVec3,
            type = self.type,
            distance = distance,
            nearby = nearby,
            onEnter = onEnter,
            onExit = onExit,
            debug = Config.Debug
        })
        table.insert(self.points, point)

        if worldPointsDebug.enabled and (worldPointsDebug.showDebugMarkers or worldPointsDebug.showPointLabels) then
            local nearby = function()
                if worldPointsDebug.showDebugMarkers then
                    self:drawMarker(locationVec3, true)
                end

                if worldPointsDebug.showPointLabels then
                    Helper.draw3dText({
                        coords = locationVec3 + vector3(0, 0, 2.0),
                        text = ("[Punto: %s] %s\nID: %s\nDistancia: %.2f m"):format(self.type, self.label,
                            self.internalId, distance),
                        textMaxLenght = 150
                    })
                end
            end
            local point = Points.new({
                id = "debug_" .. pointId,
                coords = locationVec3,
                type = self.type,
                distance = 100,
                nearby = nearby,
                debug = Config.Debug
            })
            table.insert(self.points, point)
        end

        self:debug('info', ("Generated WorldPoint location for: %s"):format(pointId))
    end
end

function WorldPoint:hasAccess()
    if not Player then return false end
    local jobData, gangData, _ = Bridge.GetPlayerInfo()

    if not self.enable then return false end
    if not self.groups or Helper.tableCount(self.groups) == 0 then
        return true
    end

    local playerJob = jobData and jobData.name or nil
    local playerGang = gangData and gangData.name or nil

    for group, grade in pairs(self.groups) do
        if (playerJob and (playerJob == group)) or (playerGang and (playerGang == group)) then

            if jobData then
                if jobData.grade >= grade then
                    return true
                end
            end

            if gangData then
                if gangData.grade >= grade then
                    return true
                end
            end
            
            return true
        end
    end

    return false
end

function WorldPoint:onInteract()

    if not self.enable then
        self:debug('warn', ("Interaction blocked - WorldPoint '%s' is disabled"):format(self.internalId))
        return
    end

    local pCoords = GetEntityCoords(PlayerPedId())
    local isNearLocation = false
    local closestDistance = 999999

    for _, location in pairs(self.locations) do
        local distance = #(vec3(location.x, location.y, location.z) - pCoords)
        if distance < closestDistance then
            closestDistance = distance
        end

        if distance <= self.markerInfo.distanceInteract then
            isNearLocation = true
            break
        end
    end

    if not isNearLocation then
        self:debug('warn', ("Interaction blocked - Player not near any location. Closest: %.2fm"):format(closestDistance))
        return
    end

    if self.security.interactionsPerSecond >= wpSecurityConfig.maxInteractionsPerSecond then
        self:debug('warn', "Interaction rate limit exceeded")
        return
    end

    self.security.interactionsPerSecond = self.security.interactionsPerSecond + 1
    SetTimeout(1100, function()
        self.security.interactionsPerSecond = math.max(0, self.security.interactionsPerSecond - 1)
    end)

    if self.type == 'stash' then
        Inventory.open('stash', self.internalId, {
            owner = self.data.owner,
            label = self.label
        })
    elseif self.type == 'drop' then
        if Player and Player.activeDrop then
            Inventory.open('drop', Player.activeDrop.id)
        end
    elseif self.type == 'shop' then
        if Bridge.CanOpenShop then
            local canOpen = Bridge.CanOpenShop(self.internalId)
            if not canOpen then
                return
            end
        end

        Inventory.open('shop', self.internalId, {
            items = self.data.items,
            slots = self.data.slots,
            label = self.label,
            maxweight = self.data.maxweight or 120000,
            weight = self.data.weight,
        })
    elseif self.type == 'crafting' then
        Inventory.open('crafting', self.internalId, {
            label = self.label,
            recipes = self.data.recipes,
        })
    end
end

--[[ Los puntos del mundo, en el mapa.

     Ya no son blips del juego: se registran en origen_map y de ahi los leen
     los tres mapas del servidor. El sprite y el color que se eligen en el
     panel siguen mandando, traducidos del numero de GTA por OrigenMapa.Icono
     y OrigenMapa.Color. Y ademas llega el nombre, que es lo que antes se
     escribia en el rotulo del blip y los mapas de Leaflet no podian leer. ]]
function WorldPoint:generateBlips()
    for k, location in pairs(self.locations) do
        local clave = ('punto_%s_%s'):format(tostring(self.internalId or self.label), tostring(k))

        OrigenMapa.Poner(clave, {
            x = location.x, y = location.y, z = location.z,
            cat = 'shops',
            --- Del sprite al dibujo: una armeria y un 24/7 ya no salen con la misma
            --- cesta. Un sprite que no este en la tabla deja mandar a la categoria.
            icono = OrigenMapa.Icono(self.blipInfo.sprite),
            nombre = self.blipInfo.name or self.label or 'Punto',
            --- Del numero de GTA al color de la chincheta. Un numero que no
            --- este en la tabla deja mandar al de la categoria.
            color = OrigenMapa.Color(self.blipInfo.color),
        })

        table.insert(self.blips, clave)
    end
end

function WorldPoint:clear()
    for _, point in pairs(self.points) do
        point:remove()
    end
    self.points = {}

    for _, entity in pairs(self.entities) do
        if DoesEntityExist(entity) then
            SetEntityAsMissionEntity(entity, false, false)
            SetEntityAsNoLongerNeeded(entity)
            DeleteEntity(entity)
        end
        self.entities[entity] = nil
    end

    self.entities = {}

    for _, clave in pairs(self.blips) do
        OrigenMapa.Quitar(clave)
    end

    self.blips = {}

    Sprite.unload()
    Sprite.updateCrafting(false)
end

function WorldPoint:refresh()
    self:clear()
    if self.enable then
        if not self:hasAccess() then return end
        self:generatePoints()

        if not self.blipInfo.enabled then return end
        self:generateBlips()
    end
end

function WorldPoint:destroy()
    self.enable = false
    self:clear()
    WorldPoint.instances[self.id] = nil
end

function WorldPoint:setEnabled(value)
    self.enable = value
    self:refresh()
end

function WorldPoint:debug(type, msg)
    local typeColor = {
        info = '^2',
        warn = '^3',
        error = '^1',
        success = '^5',
    }
    debugger(("%s[WorldPoint]^6[%s|%s|%s]^0: %s"):format(typeColor[type] or typeColor.info, self.id, self.type,
        self.internalId, msg))
end

function WorldPoint:getInfo()
    return {
        id = self.id,
        internalId = self.internalId,
        type = self.type,
        label = self.label,
        enable = self.enable,
        locations = self.locations,
        zoneDistance = self.zoneDistance,
        groups = self.groups,
        blipInfo = self.blipInfo,
        markerInfo = self.markerInfo,
        data = self.data
    }
end
