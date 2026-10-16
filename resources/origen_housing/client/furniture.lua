CreateThread(function()
    local categories = {}

    table.sort(Config.Furniture, function(a, b)
        return a.label < b.label
    end)

    for _, category in pairs(Config.Furniture) do
        categories[#categories + 1] = {
            label = category.label,
            icon = category.icon,
        }
    end

    Config.FurnitureCategories = categories
end)

_entity = nil
local tempEntity = nil

local rotationPoints = 5


Furniture = {
    active = false,
    model = nil,
    name = nil,
    entity = nil,
    mode = 'mouse',
    action = 'move',
    currentEntity = nil,
    lastEntity = nil,
    createProps = {},
    currentHouse = nil,
    focus = false,
    lastState = false,
    cartEntities = {},
    cartItems = {},
}

local function FreecamControls()
    Nui.ControlsNotify({
        title = Config.Translations.general.furniture,
        keys = {
            { key= 'CAPS', text = Config.Translations.general.freeMode },
        }
    })
end

local function getCurrentHouse()
    if not currentExteriorHouseID and not currentInteriorHouseID then
        return nil
    end

    local currentHouse = currentExteriorHouseID or currentInteriorHouseID

    local house = House.get(currentHouse)

    if not house then return nil end

    if not house.owned then return nil end

    if not house:hasKey() then
        Internal.Notify(Config.Translations.notify.error.noKey, 'error', 5000)
        return nil
    end

    local zone = currentInteriorHouseID and 'interior' or 'exterior'

    if not Config.FurnitureEnable[zone] then return end
    

    return house, zone
end

function Furniture:ToggleMenu(state)
    if state then

        local house, zone = getCurrentHouse()

        if not house or not zone then
            -- Sin casa no hay menu que abrir, pero quien llama puede venir de
            -- colocar un mueble con el foco y KeepInput puestos (onClick,
            -- cancelFurniturePurchase...): antes se salia sin soltar nada y el
            -- raton se quedaba preso. Si el modo muebles estaba abierto se
            -- cierra entero; si no, solo se suelta lo que haya.
            if self.active then
                self:ToggleMenu(false)
                self.currentHouse = nil
                self.selected = nil
                LocalPlayer.state:set('IsBusy', false, true)
            else
                SendNUIMessage({ action = 'toggleFurnitureMenu', state = false })
                SetNuiFocus(false, false)
            end
            SetNuiFocusKeepInput(false)
            return
        end

        self.currentHouse = house

        self.currentHouse.zone = zone

        LocalPlayer.state:set('IsBusy', true, true)

        local restrictedZone = false

        if self.currentHouse.zone == 'exterior' then
            restrictedZone = self.currentHouse.houseData.polyzone
        elseif self.currentHouse.zone == 'interior' and self.currentHouse.houseData.data.type == 'shell' then
            restrictedZone = self.currentHouse.houseData.shell.zone
        end

        if Config.UseFreecam then 
            Freecam:CreateCam(true, restrictedZone and 100 or 30.0, 0.3, restrictedZone)
        end

        if not self.active then 

            if Config.UseFreecam then 
                FreecamControls()
            end

            CreateThread(function()
                while self.active do
                    Utils.DisableControls({24, 25, 47, 58, 69, 70, 92, 114, 135, 140, 141, 142, 143, 199, 200, 202, 257, 263, 264, 331}, self.selected ~= nil)
                    if IsControlPressed(0, 21) then
                        rotationPoints = 1
                    else
                        rotationPoints = 5
                    end
                    -- Bloq Mayus devuelve el cursor que la freecam quita. Sin
                    -- freecam el menu ya lo tiene y `focus` no se lleva: se
                    -- quedaba alternando el raton con el menu a la vista.
                    if Config.UseFreecam and IsControlJustPressed(0, 217) and not self.focus then
                        SetNuiFocus(true, true)
                        Wait(200)
                        self.focus = true
                    end
                    Wait(0)
                end
            end)
        end
    else
        if Config.UseFreecam then  
            if Freecam.active then Freecam:DestroyCam() end
            Nui.ControlsNotify()
        end
        tempEntity = false
        self:TogglePlacement(false)
        table.wipe(self.createProps)
    end

    self.active = state
    local furniture = {}

    if self.lastState ~= self.active then
        if self.lastState then
            Custom.OnStopDecorate()
        else
            Custom.OnStartDecorate()
        end
        self.lastState = self.active
    end

    if state and self.currentHouse then
        furniture = self.currentHouse.houseData.furniture[self.currentHouse.zone]
    end

    SendNUIMessage({
        action = 'toggleFurnitureMenu',
        state = state,
        furniture = furniture,
    })
    SetNuiFocus(state, state)

    if Config.UseFreecam then 
        self.focus = state
    end
end

RegisterNuiCallback('openFurnitureMenu', function(data, cb)
    -- Sin eco: el panel de la casa, al cerrarse, contestaba con un
    -- fetch('close') que podia llegar DESPUES de abrir los muebles y les
    -- quitaba el foco con el menu a la vista. El foco se suelta aqui.
    Nui.CloseHouseMenu(true)
    Wait(250)
    Furniture:ToggleMenu(true)
    cb('ok')
end)

if Config.Commands.OpenFurnitureMenu.enabled then 
    lib.addKeybind({
        name = Config.Commands.OpenFurnitureMenu.cmd,
        description = Config.Translations.commands.OpenFurnitureMenu,
        defaultKey = Config.Commands.OpenFurnitureMenu.key,
        onPressed = function(self)
            if Furniture.active then return end
            Furniture:ToggleMenu(true)
        end,
    })
end

-- Object logic

function Furniture:CreateObject(object)
    self.name = object
    self.model = type(object) == 'string' and joaat(object) or GetHashKey(object)

    if self.currentEntity and DoesEntityExist(self.currentEntity) then
        DeleteEntity(self.currentEntity)
        self.currentEntity = nil
    end

    if not IsModelValid(self.model) then
        debugger('Model not valid', self.model)
        return false
    end

    lib.requestModel(self.model)

    local min, max = GetModelDimensions(self.model)
    local spawnCoords = nil
    if not Config.UseFreecam then 
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local playerHeading = GetEntityHeading(playerPed)
        local forwardOffset = 2.0
        spawnCoords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, forwardOffset, 0.0)
    
        if Utils.IsClearAhead(2.0) then
            Internal.Notify(Config.Translations.notify.error.furnitureFacingWall, 'error', 5000)
            return
        end
    else
        local camPos = Freecam:GetPosition()
        local camRot = Freecam:GetRotation()
    
        local _, lookAt = Utils.GetScreenCoords(10.0, camPos, camRot)

        spawnCoords = lookAt
    
        if not spawnCoords then return false end
    end

    local isNetworked = Config.SyncPropOnDecorate

    self.entity = CreateObject(self.model, spawnCoords.x, spawnCoords.y, spawnCoords.z, isNetworked, true, true)

    SetEntityDrawOutline(self.entity, true)
    SetEntityDrawOutlineColor(255, 255, 255, 255)
    SetEntityDrawOutlineShader(1)
    SetEntityHeading(self.entity, playerHeading)
    FreezeEntityPosition(self.entity, true)
    SetEntityCollision(self.entity, false, false)
    PlaceObjectOnGroundProperly(self.entity)
    SetEntityAlpha(self.entity, 0, false)

    SetModelAsNoLongerNeeded(self.model)

    Entity(self.entity).state.isFurniture = true

    self.createProps[self.entity] = {
        offset = vector3(0.0, 0.0, -min.z),
    }

    self.action = 'create'

    self.currentEntity = self.entity

    for alpha = 55, 255, 10 do
        SetEntityAlpha(self.entity, alpha, false)
        Wait(0)
    end

    return object
end

function Furniture:TogglePlacement(state, force)
    if state then 
        SetEntityCollision(self.entity, true, true)
        SetNuiFocusKeepInput(false)
    else
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)

        if not force then 
            if self.entity and DoesEntityExist(self.entity) then
                for alpha = 255, 0, -10 do
                    SetEntityAlpha(self.entity, alpha, false)
                    Wait(0)
                end
                DeleteEntity(self.entity)
            end
    
            self.entity = nil
            self.currentEntity = nil
        end

        SetMouseCursorSprite(1)
    end

    SendNUIMessage({
        action = 'toggleFurnitureMoving',
        state = state
    })
end

function Furniture:AddToCart(entity, data)
    _entity = nil
    tempEntity = false
    local entity = entity or self.selected or self.entity or self.currentEntity

    if not entity or not DoesEntityExist(entity) then
        return false
    end

    if not self.currentHouse then
        return false
    end

    local zone = self.currentHouse.zone
    local id = tostring(math.random(100000, 999999) .. self.currentHouse.id)
    local cartId = 'cart_' .. id .. '_' .. tostring(GetGameTimer())

    local coords = (data and data.position) or GetEntityCoords(entity)
    local newCoords

    if self.currentHouse.zone == 'interior' and self.currentHouse.houseData.data.type == 'shell' and self.currentHouse.houseData.shell and self.currentHouse.houseData.shell.entity then
        newCoords = GetOffsetFromEntityGivenWorldCoords(self.currentHouse.houseData.shell.entity, coords.x, coords.y, coords.z)
    else
        newCoords = coords
    end

    local rotation = (data and data.rotation) or GetEntityRotation(entity)
    local modelName = (data and data.model) or self.name

    local objectData = {
        model = modelName,
        position = newCoords,
        rotation = rotation,
    }

    -- Mantener el mueble en el mundo colocado y visible como preview
    FreezeEntityPosition(entity, true)
    SetEntityCollision(entity, true, true)
    ResetEntityAlpha(entity)
    SetEntityDrawOutline(entity, false)

    if not self.cartEntities then self.cartEntities = {} end
    if not self.cartItems then self.cartItems = {} end

    self.cartEntities[cartId] = entity
    table.insert(self.cartItems, {
        cartId = cartId,
        id = id,
        model = modelName,
        objectData = objectData,
    })

    if self.createProps then
        self.createProps[entity] = nil
    end

    self.selected = nil
    self.entity = nil
    self.currentEntity = nil
    self:TogglePlacement(false, true)
    self.mode = 'mouse'
    SetMouseCursorSprite(1)
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    self:ToggleMenu(true)

    return {
        status = true,
        cartId = cartId,
        id = id,
        model = modelName,
    }
end

function Furniture:BuyObject(entity, data)
    _entity = nil
    tempEntity = false
    local entity = entity or self.selected

    if not entity or not DoesEntityExist(entity) then
        return false
    end

    local zone = self.currentHouse.zone

    local id = tostring(math.random(100000, 999999)..self.currentHouse.id)

    local coords = (data and data.position) or GetEntityCoords(entity)
    local newCoords

    if self.currentHouse.zone == 'interior' and self.currentHouse.houseData.data.type == 'shell' and self.currentHouse.houseData.shell and self.currentHouse.houseData.shell.entity then
        newCoords = GetOffsetFromEntityGivenWorldCoords(self.currentHouse.houseData.shell.entity, coords.x, coords.y, coords.z)
    else
        newCoords = coords
    end

    local objectData = {
        model = self.name,
        position = newCoords,
        rotation = (data and data.rotation) or GetEntityRotation(entity),
    }

    local canBuy = lib.callback.await('origen_housing:server:BuyFurniture', false, {
        houseID = self.currentHouse.id,
        objectData = objectData,
        zone = zone,
        id = id,
        paymentMethod = data and data.paymentMethod,
    })

    if canBuy == true then 
        self.selected = nil
        SetEntityDrawOutline(entity, false)
        self:TogglePlacement(false)
        self.mode = 'mouse'
        return true
    else
        return canBuy
    end

    return false
end

function Furniture:UpdateFurniture(entity, data)
    tempEntity = false

    local entity = entity or self.selected

    if not entity or not DoesEntityExist(entity) then
        return false
    end

    local entityID = Entity(entity).state.entityID

    if not entityID then return end

    local coords = (data and data.position) or GetEntityCoords(entity)
    local newCoords

    if self.currentHouse.zone == 'interior' and self.currentHouse.houseData.data.type == 'shell' and self.currentHouse.houseData.shell and self.currentHouse.houseData.shell.entity then
        newCoords = GetOffsetFromEntityGivenWorldCoords(self.currentHouse.houseData.shell.entity, coords.x, coords.y, coords.z)
    else
        newCoords = coords
    end
    
    local objectData = {
        position = newCoords,
        rotation = (data and data.rotation) or GetEntityRotation(entity),
    }

    local update = lib.callback.await('origen_housing:server:UpdateFurniture', false, {
        houseID = self.currentHouse.id,
        objectData = objectData,
        zone = self.currentHouse.zone,
        id = entityID,
    })

    SetEntityCollision(entity, true, true)
    self:TogglePlacement(false)
    ResetEntityAlpha(entity)
    ResetEntityAlpha(self.entity)
    SetEntityDrawOutline(self.entity, false)
    SetEntityDrawOutline(entity, false)
    SetMouseCursorSprite(1)
    SetNuiFocus(true, true)
    self.selected = nil
    self.action = 'move'
    self.mode = 'mouse'

    return update
end

-- Nui callbacks

RegisterNUICallback('closeFurniture', function(data, cb)
    Furniture:CloseFurniture()
    cb('ok')
end)

function Furniture:CloseFurniture()
    -- Aunque ya no quede nada que cerrar, el foco se suelta: este aviso lo
    -- manda el menu de muebles, asi que si llega es que la NUI lo tiene, y
    -- salir sin soltarlo deja el raton preso.
    if not self.active then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        LocalPlayer.state:set('IsBusy', false, true)
        return
    end

    local entity = self.selected and self.selected or _entity

    Nui.ControlsNotify()
    self:ToggleMenu(false)
    ResetEntityAlpha(self.lastEntity)
    ResetEntityAlpha(entity)
    SetEntityDrawOutline(self.lastEntity, false)
    SetEntityDrawOutline(entity, false)
    self.active = false
    self.mode = 'mouse'

    if self.cartEntities then
        for cartId, ent in pairs(self.cartEntities) do
            if DoesEntityExist(ent) then
                DeleteEntity(ent)
            end
        end
        self.cartEntities = {}
        self.cartItems = {}
    end

    -- Antes iba al final y los dos return de abajo se lo saltaban: cerrar sin
    -- haber tocado ningun mueble dejaba IsBusy a true.
    LocalPlayer.state:set('IsBusy', false, true)

    if not entity then
        self.currentHouse = nil
        return
    end

    local entityID = Entity(entity).state.entityID  
    
    if not entityID then
        self.currentHouse = nil
        self.selected = nil
        return 
    end
    
    local object = nil

    if self.currentHouse.zone == 'interior' then
        object = self.currentHouse.interiorFurniture[entityID]
    elseif self.currentHouse.zone == 'exterior' then
        object = self.currentHouse.exteriorFurniture[entityID]
    end

    if object then
        SetEntityCoords(entity, object.position.x, object.position.y, object.position.z)
        SetEntityRotation(entity, object.rotation.x, object.rotation.y, object.rotation.z, 2, true)
        SetEntityCollision(entity, true, true)
    end

    self.currentHouse = nil
    self.selected = nil
end

RegisterNUICallback('spawnObject', function(data, cb)
    if not Furniture.active then return cb(false) end
    if Config.Debug then
        lib.setClipboard(data.model)
    end
    local spawned = Furniture:CreateObject(data.model)

    cb(spawned)
end)

RegisterNUICallback('selectCategory', function(data, cb)
    Furniture.action = 'create'
    cb('ok')
end)

RegisterNUICallback('backCategory', function(data, cb)
    Furniture.action = 'move'

    if Furniture.entity and DoesEntityExist(Furniture.entity) then
        for alpha = 255, 0, -10 do
            SetEntityAlpha(Furniture.entity, alpha, false)
            Wait(0)
        end
        DeleteEntity(Furniture.entity)
    end

    Furniture.entity = nil
    Furniture.currentEntity = nil
    cb('ok')
end)

RegisterNUICallback('startPlacement', function(data, cb)
    -- Sin mueble vivo (borrado, o de cara a la pared) se responde false: la
    -- NUI esconde el menu solo si esto sale bien. Antes salia sin cb.
    if not Furniture.active or not Furniture.entity or not DoesEntityExist(Furniture.entity) then
        return cb(false)
    end
    Furniture.mode = 'mouse'
    tempEntity = true
    
    local restrictedZone = false

    if Furniture.currentHouse.zone == 'exterior' then
        restrictedZone = Furniture.currentHouse.houseData.polyzone
    elseif Furniture.currentHouse.zone == 'interior' and Furniture.currentHouse.houseData.data.type == 'shell' and Furniture.currentHouse.houseData.shell then
        restrictedZone = Furniture.currentHouse.houseData.shell.zone
    end

    Furniture:TogglePlacement(true)
    SetMouseCursorSprite(4)
    Furniture.selected = Furniture.entity

    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    SetCursorLocation(0.5, 0.5)
    SendNUIMessage({
        action = 'updateFurnitureData',
        entity = Furniture.entity
    })

    cb('ok')
end)

RegisterNUICallback('onClick', function(data, cb)
    if not Furniture.active then return cb(false) end
    if Furniture.selected then 
        SetEntityCollision(Furniture.selected, true, false)
        ResetEntityAlpha(Furniture.entity)
        SetEntityDrawOutline(Furniture.entity, false)
        SetMouseCursorSprite(1)

        Furniture:TogglePlacement(false, true)
        Furniture:ToggleMenu(true)

        -- Sin casa, ToggleMenu ya lo ha cerrado todo: no hay nada que guardar.
        if not Furniture.active then return cb(false) end

        if Furniture.mode == 'mouse' then
            Nui.ControlsNotify()
        end

        if Config.UseFreecam then 
            FreecamControls()
        end

        if data and data.action == 'update' then
            Furniture:UpdateFurniture()
            return cb(false)
        end
        Furniture.selected = nil
        cb(false)
    else
        if Furniture.mode == 'gizmo' then
            return cb(false)
        end

        local camPos = nil
        local camRot = nil

        if Config.UseFreecam then 
            camPos = Freecam:GetPosition()
            local camRot = Freecam:GetRotation()
        end

        local hit, entity = Utils.GetEntityOnScreen(camPos, camRot)

        if hit and IsEntityAnObject(entity) and GetEntityType(entity) == 3 then
            local entityID = Entity(entity).state.entityID
            if Furniture.action == 'create' and entityID then
                return cb(false)
            end

            if (not Furniture.createProps[entity] and not entityID) then
                return cb(false)
            end

            Furniture.selected = entity
            tempEntity = true
            SetNuiFocus(true, false)
            SetNuiFocusKeepInput(true)
            SetMouseCursorSprite(4)

            cb(Furniture.selected)
        else
            cb(false)
        end
    end
end)

RegisterNUICallback('onMove', function(data, cb)
    -- Se contesta ya: llega en cada movimiento del raton y varias salidas de
    -- abajo no contestaban, dejando la peticion colgada en la NUI.
    cb('ok')
    if not Furniture.active then return end
    Nui.ControlsNotify({
        title = Config.Translations.general.furniture,
        keys = {
            { key= 'lclick', text = Config.Translations.controls.place, },
            { key= 'wheel', text = Config.Translations.controls.rotate, },
            { key = 'shift', text = Config.Translations.controls.slowRotate, },
            { key= 'H', text = Config.Translations.controls.toggleModetoGizmo, },
            { key= 'delete', text = Config.Translations.controls.delete, },
        }
    })

    if Furniture.selected and IsEntityAnObject(Furniture.selected) and GetEntityType(Furniture.selected) == 3 then

        local entityID = Entity(Furniture.selected).state.entityID

        if Furniture.action == 'move' and not entityID then
            return
        end

        local offset = (Furniture.createProps[Furniture.selected] and Furniture.createProps[Furniture.selected].offset) or Entity(Furniture.selected).state.min

        local camPos = nil  
        local camRot = nil

        if Config.UseFreecam then 
            camPos = Freecam:GetPosition()
            camRot = Freecam:GetRotation()
        end

        local hit, coords = Utils.ScreenToWorld(camPos, camRot)

        local entityCoords = GetEntityCoords(Furniture.selected)

        local restrictedZone = false

        if not restrictedZone then 
            if Furniture.currentHouse.zone == 'exterior' then
                restrictedZone = Furniture.currentHouse.houseData.polyzone
            elseif Furniture.currentHouse.zone == 'interior' and Furniture.currentHouse.houseData.data.type == 'shell' and Furniture.currentHouse.houseData.shell then
                restrictedZone = Furniture.currentHouse.houseData.shell.zone
            end
        end

        local isInside = false

        if restrictedZone then 
            isInside = Utils.isInsidePolyzone(coords, restrictedZone)
        end

        SetEntityCollision(Furniture.selected, false, false)

        if hit then
            SetEntityAlpha(Furniture.selected, 175, false)

            if restrictedZone then 
                if isInside then
                    SetEntityDrawOutlineColor(255, 255, 255, 150)
                    SetEntityCoords(Furniture.selected, coords + offset)
                else
                    SetEntityDrawOutlineColor(255, 0, 0, 150)
                end
            else
                SetEntityCoords(Furniture.selected, coords + offset)
                SetEntityDrawOutlineColor(255, 255, 255, 150)
            end
        else
            ResetEntityAlpha(Furniture.entity)
            SetEntityDrawOutline(Furniture.entity, false)
        end
    end
end)

RegisterCommand('deleteFurniture', function()
    if Furniture.selected and DoesEntityExist(Furniture.selected) and Furniture.action == 'move' then
        Nui.ControlsNotify()
        local data = {
            houseID = Furniture.currentHouse.id,
            entityID = Entity(Furniture.selected).state.entityID,
            zone = Furniture.currentHouse.zone,
        }

        _entity = nil

        local deleted = lib.callback.await('origen_housing:server:DeleteFurniture', false, data)

        if deleted then
            Furniture:TogglePlacement(false, false)
            Furniture:ToggleMenu(true)
            Furniture.selected = nil
        end
    end
end)

RegisterKeyMapping('deleteFurniture', Config.Translations.general.bindHelpDeleteFurniture, 'keyboard', 'DELETE')


RegisterNUICallback('onHover', function(data, cb)
    -- Se contesta ya, como onMove: varias salidas de abajo no lo hacian.
    cb('ok')
    if not Furniture.active then return end
    if Furniture.selected then return end

    local camPos = nil  
    local camRot = nil

    if Config.UseFreecam then 
        camPos = Freecam:GetPosition()
        camRot = Freecam:GetRotation()
    end

    local hit, entity = Utils.GetEntityOnScreen(camPos, camRot)

    if hit and IsEntityAnObject(entity) and GetEntityType(entity) == 3 then 
        local entityID = Entity(entity).state.entityID
        if not entityID then return end

        if Furniture.lastEntity and Furniture.lastEntity ~= entity then
            ResetEntityAlpha(Furniture.lastEntity)
            SetEntityDrawOutline(Furniture.lastEntity, false)
            Furniture.lastEntity = nil
        end
        
        SetMouseCursorSprite(3)
        SetEntityAlpha(entity, 175, false)
        Furniture.lastEntity = entity
    else
        ResetEntityAlpha(Furniture.lastEntity)
        SetEntityDrawOutline(Furniture.lastEntity, false)
        Furniture.lastEntity = nil
    end
end)

RegisterNUICallback('onRotate', function(data, cb)
    if Furniture.selected and IsEntityAnObject(Furniture.selected) then
        local rotation = GetEntityRotation(Furniture.selected)
        if data.direction == 'left' then 
            SetEntityRotation(Furniture.selected, rotation.x, rotation.y, rotation.z - rotationPoints)
        elseif data.direction == 'right' then
            SetEntityRotation(Furniture.selected, rotation.x, rotation.y, rotation.z + rotationPoints)
        end
    end

    cb('ok')
end)

RegisterNUICallback('stopPlacement', function(data, cb)  
    if Furniture.selected and IsEntityAnObject(Furniture.selected) then
        Furniture:TogglePlacement(false, true)
        ResetEntityAlpha(Furniture.entity)
        SetEntityDrawOutline(Furniture.entity, false)
        SetMouseCursorSprite(1)
        SetNuiFocus(true, true)
    end

    cb('ok')
end)

RegisterNUICallback('cancelFurniturePurchase', function(data, cb)
    -- No contestaba nunca.
    cb('ok')
    if Furniture.selected and DoesEntityExist(Furniture.selected) then
        Furniture:ToggleMenu(true)
        ResetEntityAlpha(Furniture.selected)
        SetEntityDrawOutline(Furniture.selected, false)
        SetMouseCursorSprite(1)

        Furniture.selected = nil
    else
        Furniture:ToggleMenu(true)
        SetMouseCursorSprite(1)
    end
end)

RegisterNUICallback('addToCart', function(data, cb)
    local res = Furniture:AddToCart(nil, data)
    cb(res)
end)

RegisterNUICallback('removeCartItem', function(data, cb)
    if not data or not data.cartId then return cb(false) end
    local cartId = data.cartId

    if Furniture.cartEntities and Furniture.cartEntities[cartId] then
        local ent = Furniture.cartEntities[cartId]
        if DoesEntityExist(ent) then
            DeleteEntity(ent)
        end
        Furniture.cartEntities[cartId] = nil
    end

    if Furniture.cartItems then
        for i, item in ipairs(Furniture.cartItems) do
            if item.cartId == cartId then
                table.remove(Furniture.cartItems, i)
                break
            end
        end
    end

    cb('ok')
end)

RegisterNUICallback('clearCart', function(data, cb)
    if Furniture.cartEntities then
        for cartId, ent in pairs(Furniture.cartEntities) do
            if DoesEntityExist(ent) then
                DeleteEntity(ent)
            end
        end
        Furniture.cartEntities = {}
        Furniture.cartItems = {}
    end
    cb('ok')
end)

RegisterNUICallback('checkoutCart', function(data, cb)
    if not Furniture.active or not Furniture.currentHouse then
        return cb({ status = false, message = 'No estás decorando una casa' })
    end

    if not Furniture.cartItems or #Furniture.cartItems == 0 then
        return cb({ status = false, message = 'El carrito está vacío' })
    end

    local paymentMethod = (data and data.paymentMethod) or 'cash'
    if paymentMethod ~= 'cash' and paymentMethod ~= 'bank' then
        paymentMethod = 'cash'
    end

    local itemsPayload = {}
    for _, item in ipairs(Furniture.cartItems) do
        table.insert(itemsPayload, {
            cartId = item.cartId,
            id = item.id,
            objectData = item.objectData,
        })
    end

    local result = lib.callback.await('origen_housing:server:BuyFurnitureCart', false, {
        houseID = Furniture.currentHouse.id,
        zone = Furniture.currentHouse.zone,
        paymentMethod = paymentMethod,
        items = itemsPayload,
    })

    if result and result.status then
        if Furniture.cartEntities then
            for cartId, ent in pairs(Furniture.cartEntities) do
                if DoesEntityExist(ent) then
                    DeleteEntity(ent)
                end
            end
            Furniture.cartEntities = {}
            Furniture.cartItems = {}
        end

        cb(result)
    else
        cb(result or { status = false, message = 'Error al procesar el carrito' })
    end
end)

RegisterNUICallback('confirmBuyFurniture', function(data, cb)  
    local buy = Furniture:AddToCart(nil, data)
    cb(buy)
end)

-- Handlers

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    if Furniture.entity and DoesEntityExist(Furniture.entity) then
        DeleteEntity(Furniture.entity)
    end

    if Furniture.cartEntities then
        for cartId, ent in pairs(Furniture.cartEntities) do
            if DoesEntityExist(ent) then
                DeleteEntity(ent)
            end
        end
    end

    -- Parar el recurso a medio colocar dejaba KeepInput encendido.
    if Furniture.active then
        SetNuiFocusKeepInput(false)
        SetNuiFocus(false, false)
    end
end)

function Furniture:ToggleMode()

    if not self.active then return end

    local action = self.action

    if not _entity then 
        _entity = self.selected
    end

    if not _entity then return end

    local restrictedZone = false
    if not restrictedZone then 
        if self.currentHouse.zone == 'exterior' then
            restrictedZone = self.currentHouse.houseData.polyzone
        elseif self.currentHouse.zone == 'interior' and self.currentHouse.houseData.data.type == 'shell' and self.currentHouse.houseData.shell then
            restrictedZone = self.currentHouse.houseData.shell.zone
        end
    end

    if self.mode == 'mouse' then
        Nui.ControlsNotify()
        self.mode = 'gizmo'
        SendNUIMessage({
            action = 'toggleGizmoMode',
            state = true
        })
        self.selected = nil
        self:TogglePlacement(false, true)
        local object = Gizmo:StartGizmo(_entity, restrictedZone)
        if not object then return end

        local entityID = Entity(_entity).state.entityID

        SendNUIMessage({
            action = 'toggleGizmoMode',
            state = false
        })

        if entityID then 
            self:UpdateFurniture(_entity, object)
        else
            local res = self:AddToCart(_entity, object)
            if res and res.status then
                SendNUIMessage({
                    action = 'addedToCartFromGizmo',
                    cartId = res.cartId,
                    id = res.id,
                    model = self.name,
                })
            end
        end
        if Config.UseFreecam then   
            FreecamControls()
        end

        SendNUIMessage({
            action = 'toggleFurnitureMenu',
            state = true,
        })
        SetNuiFocus(true, true)

        _entity = nil
    else
        self.mode = 'mouse'
        SendNUIMessage({
            action = 'toggleGizmoMode',
            state = false
        })
        Gizmo:DeleteGizmo()
        self:TogglePlacement(true)
        local entityID = Entity(_entity).state and Entity(_entity).state.entityID

        if self.action == 'create' and entityID then
            return
        end

        if (not self.createProps[_entity] and not entityID) then
            return
        end

        self.selected = _entity
        SetNuiFocus(true, false)
        SetNuiFocusKeepInput(true)
        SetMouseCursorSprite(4)
    end
end

function Furniture:CancelEdit()
    Wait(200)

    -- La casa se mira ANTES de reabrir el menu. Si ya no se esta en ella
    -- (por ejemplo, sin llave), reabrirlo cogia el foco y luego se salia
    -- con `active = false`, y CloseFurniture ya no hacia nada: raton preso.
    -- Se sale por la puerta de siempre, ToggleMenu(false), que quita el
    -- menu, la freecam y el foco.
    local house, zone = getCurrentHouse()

    if not house or not zone then
        _entity = nil
        Furniture.mode = 'mouse'
        SendNUIMessage({
            action = 'toggleGizmoMode',
            state = false
        })
        Furniture:ToggleMenu(false)
        SetNuiFocusKeepInput(false)
        Furniture.currentHouse = nil
        Furniture.selected = nil
        LocalPlayer.state:set('IsBusy', false, true)
        return
    end

    SendNUIMessage({
        action = 'toggleFurnitureMenu',
        state = true,
    })
    SetNuiFocus(true, true)
    Furniture.active = true

    if Config.UseFreecam then 
        Furniture.focus = true
        FreecamControls()
    end

    Furniture.mode = 'mouse'
    SendNUIMessage({
        action = 'toggleGizmoMode',
        state = false
    })
    _entity = nil

    Furniture.currentHouse = house

    Furniture.currentHouse.zone = zone
end

RegisterNuiCallback('toggleFurnitureModeh', function(data, cb)
    if Furniture.mode == 'gizmo' then
        Furniture:ToggleMode()
    end
    cb('ok')
end)

RegisterNuiCallback('onActionObject', function(data, cb)
    if not Furniture.active then return cb(false) end
    if not Furniture.currentHouse then return cb(false) end

    local house = Furniture.currentHouse
    local objectID = data.id
    local zone = Furniture.currentHouse.zone
    if not house.houseData.furniture[zone][objectID] then return cb(false) end

    local object = house.houseData.furniture[zone][objectID]
    local objectEntity = zone == 'interior' and house.interiorFurniture[objectID] or house.exteriorFurniture[objectID]

    if data.action == 'delete' then 
        Nui.ControlsNotify()
        local data = {
            houseID = house.id,
            entityID = objectEntity.id or Entity(objectEntity.entity).state.entityID,
            zone = zone,
        }

        _entity = nil

        local deleted = lib.callback.await('origen_housing:server:DeleteFurniture', false, data)

        if deleted then
            Furniture:TogglePlacement(false, false)
            Furniture:ToggleMenu(true)
            Furniture.selected = nil
        end
    elseif data.action == 'edit' then
        if not objectEntity or not DoesEntityExist(objectEntity.entity) then return cb(false) end
        local entityID = Entity(objectEntity.entity).state.entityID
        if Furniture.action == 'create' and entityID then
            return cb(false)
        end

        if (not Furniture.createProps[objectEntity.entity] and not entityID) then
            return cb(false)
        end

        Furniture:TogglePlacement(true)
        Furniture.selected = objectEntity.entity
        tempEntity = true
        SetNuiFocus(true, false)
        SetNuiFocusKeepInput(true)
        SetMouseCursorSprite(4)
        SetCursorLocation(0.5, 0.5)

        cb(Furniture.selected)
        return
    elseif data.action == 'select' then
        if Furniture.lastEntity and Furniture.lastEntity ~= objectEntity.entity then
            ResetEntityAlpha(Furniture.lastEntity)
            SetEntityDrawOutline(Furniture.lastEntity, false)
            Furniture.lastEntity = nil
        end

        SetEntityAlpha(objectEntity.entity, 175, false)
        SetEntityDrawOutline(objectEntity.entity, true)
        SetEntityDrawOutlineColor(255, 255, 255, 255)
        SetEntityDrawOutlineShader(1)

        Furniture.lastEntity = objectEntity.entity
    end

    cb('ok')
end)

RegisterNUICallback('toggleFurnitureFocus', function(data, cb)
    -- Solo con freecam: sin ella el menu necesita el cursor y quitarlo lo
    -- dejaba a la vista sin raton.
    if Config.UseFreecam and IsNuiFocused() and Furniture.focus then
        SetNuiFocus(false, false)
        Furniture.focus = false
    end
    cb('ok')
end)


RegisterCommand('toggleFurnitureMode', function()
    Furniture:ToggleMode()
end)

RegisterKeyMapping('toggleFurnitureMode', Config.Translations.general.bindHelpToggleFurnitureMode, 'keyboard', 'H')

--[[ Raton soltado a la fuerza (`soltarraton`, o la pantalla colgada): el
     recurso se queda como si se hubiera cerrado por la puerta de siempre.
     Sin esto el modo muebles seguia activo (controles bloqueados, IsBusy a
     true, el mueble a medio colocar) y el menu pintado sin raton. Aqui no se
     coge el foco: CloseFurniture solo lo suelta. ]]
OrigenFoco.AlSoltar(function()
    if Gizmo.enabled then Gizmo:DeleteGizmo() end

    if Furniture.active then
        -- En un hilo: CloseFurniture espera (el mueble se desvanece).
        CreateThread(function()
            Furniture:CloseFurniture()
        end)
    end

    -- Y las demas pantallas del recurso, sin eco hacia Lua.
    SendNUIMessage({ action = 'forzarCierre' })
end)

CreateThread(function()
    while true do
        if tempEntity then
            if not Config.UseFreecam then
                SetEntityLocallyInvisible(PlayerPedId(), false)
            end
            if IsControlJustPressed(0, 191) or IsDisabledControlJustPressed(0, 191) then
                SendNUIMessage({ action = 'confirmFurniturePlacement' })
            end
        end
        Wait(tempEntity and 0 or 200)
    end
end)