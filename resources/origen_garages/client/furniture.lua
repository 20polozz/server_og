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

-- Al ped hay que volver a marcarlo invisible cada frame, pero solo mientras
-- se esta colocando un mueble. Antes esto era un hilo con Wait(0) que latia
-- toda la partida sin hacer nada; ahora el hilo se arranca al entrar en modo
-- colocacion y se muere solo al salir, sin coste ni retardo.
local function SetTempEntity(state)
    if tempEntity == state then return end

    tempEntity = state

    if not state then return end

    CreateThread(function()
        while tempEntity do
            SetEntityLocallyInvisible(PlayerPedId(), false)
            Wait(0)
        end
    end)
end

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
    currentGarage = nil,
    focus = false,
    lastState = false,
}

local function getCurrentGarage()
    return LocalPlayer.state.interiorId and cGarage.Get(LocalPlayer.state.interiorId) or nil
end

function Furniture:ToggleMenu(state)
    if state then

        local garage = getCurrentGarage()

        if not garage then
            -- Sin interior no hay menu que abrir, pero quien llama puede venir
            -- de colocar un mueble con el foco y KeepInput puestos: se sueltan
            -- aqui o el raton se quedaba cogido sin nada en pantalla.
            SetNuiFocus(false, false)
            SetNuiFocusKeepInput(false)
            return
        end

        self.currentGarage = garage

        LocalPlayer.state:set('IsBusy', true, true)

        if not self.active then 
            CreateThread(function()
                while self.active do
                    Utils.DisableControls({24, 25, 47, 58, 69, 70, 92, 114, 135, 140, 141, 142, 143, 199, 200, 202, 257, 263, 264, 331}, self.selected ~= nil)
                    if IsControlPressed(0, 21) then
                        rotationPoints = 1
                    else
                        rotationPoints = 5
                    end
                    --[[ if IsControlJustPressed(0, 217) and not self.focus then
                        SetNuiFocus(true, true)
                        Wait(200)
                        self.focus = true
                    end ]]
                    Wait(0)
                end
            end)
        end
    else
        SetTempEntity(false)
        self:TogglePlacement(false)
        table.wipe(self.createProps)
    end

    self.active = state
    local furniture = {}

    if self.lastState ~= self.active then
        --[[ if self.lastState then
            Custom.OnStopDecorate()
        else
            Custom.OnStartDecorate()
        end ]]
        self.lastState = self.active
    end

    if state and self.currentGarage then
        furniture = self.currentGarage.furniture
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

lib.addKeybind({
    name = 'furnitureMenu',
    description = 'Muebles: abrir el menú del garaje',
    defaultMapper = 'KEYBOARD',
    defaultKey = Config.Keybinds.furniture,
    onPressed = function(self)
        if Furniture.active then return end
        Furniture:ToggleMenu(true)
    end,
})

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
        -- El anterior ya se borro arriba: que no quede su handle muerto.
        self.entity = nil
        return false
    end

    lib.requestModel(self.model)

    local min, max = GetModelDimensions(self.model)
    local playerCoords = GetEntityCoords(cache.ped)
    local playerHeading = GetEntityHeading(cache.ped)
    local forwardOffset = 2.0
    local spawnCoords = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, forwardOffset, 0.0)

    if Utils.IsClearAhead(2.0) then
        Custom.Notify(locale('furniture_facing_wall'), 'error', 5000)
        self.entity = nil
        return
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

function Furniture:BuyObject(entity, data)
    _entity = nil
    SetTempEntity(false)
    local entity = entity or self.selected

    if not entity or not DoesEntityExist(entity) then
        return false
    end

    local id = tostring(math.random(100000, 999999)..self.currentGarage.id)

    local coords = (data and data.position) or GetEntityCoords(entity)
    local newCoords

    if self.currentGarage.isShell then
        newCoords = GetOffsetFromEntityGivenWorldCoords(self.currentGarage.shell, coords.x, coords.y, coords.z)
    else
        newCoords = coords
    end

    local objectData = {
        model = self.name,
        position = newCoords,
        rotation = (data and data.rotation) or GetEntityRotation(entity),
    }

    local canBuy = lib.callback.await('origen_garages:cb:server:BuyFurniture', false, {
        garageID = self.currentGarage.id,
        objectData = objectData,
        id = id,
    })

    if canBuy == true then
        -- Solo si ha comprado: si no, el modo muebles sigue abierto (el
        -- cuadro de compra a la vista) y con active a false CloseFurniture
        -- ya no recogia nada al salir.
        self.active = false
        -- Comprado, el modo muebles se acaba aqui y no pasa por CloseFurniture
        -- (active ya es false): sin esto IsBusy se quedaba a true y
        -- origen_housing seguia viendo al jugador ocupado.
        LocalPlayer.state:set('IsBusy', false, true)
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
    SetTempEntity(false)

    local entity = entity or self.selected

    if not entity or not DoesEntityExist(entity) then
        return false
    end

    local entityID = Entity(entity).state.entityID

    if not entityID then return end

    local coords = (data and data.position) or GetEntityCoords(entity)
    local newCoords

    if self.currentGarage.isShell then
        newCoords = GetOffsetFromEntityGivenWorldCoords(self.currentGarage.shell, coords.x, coords.y, coords.z)
    else
        newCoords = coords
    end
    
    local objectData = {
        position = newCoords,
        rotation = (data and data.rotation) or GetEntityRotation(entity),
    }

    local update = lib.callback.await('origen_garages:cb:server:UpdateFurniture', false, {
        garageID = self.currentGarage.id,
        objectData = objectData,
        id = entityID,
    })

    SetEntityCollision(entity, true, true)
    self:TogglePlacement(false)
    -- ResetEntityAlpha(entity)
    SetEntityAlpha(entity, 255, false)
    -- ResetEntityAlpha(self.entity)
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
    -- Aunque ya no quede modo muebles, lo que haya se suelta: este aviso lo
    -- manda el menu, asi que si llega la NUI tiene el foco, y salir sin
    -- soltarlo dejaba el raton preso. El mueble a medio colocar (sin
    -- entityID, sin comprar) tampoco se queda plantado.
    if not self.active then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        SetTempEntity(false)
        if self.entity and DoesEntityExist(self.entity) and not Entity(self.entity).state.entityID then
            DeleteEntity(self.entity)
        end
        self.entity = nil
        self.currentEntity = nil
        LocalPlayer.state:set('IsBusy', false, true)
        return
    end

    local entity = self.selected and self.selected or _entity

    -- Nui.ControlsNotify()
    self:ToggleMenu(false)
    -- ResetEntityAlpha(self.lastEntity)
    SetEntityAlpha(self.lastEntity, 255, false)
    -- ResetEntityAlpha(entity)
    SetEntityAlpha(entity, 255, false)
    SetEntityDrawOutline(self.lastEntity, false)
    SetEntityDrawOutline(entity, false)
    self.active = false
    self.mode = 'mouse'

    -- Antes iba al final y los dos return de abajo se lo saltaban: cerrar sin
    -- haber tocado ningun mueble dejaba IsBusy a true.
    LocalPlayer.state:set('IsBusy', false, true)

    if not entity then
        self.currentGarage = nil
        return 
    end

    local entityID = Entity(entity).state.entityID  
    
    if not entityID then
        self.currentGarage = nil
        self.selected = nil
        return 
    end
    
    local object = self.currentGarage.furniture[entityID]

    if object then
        SetEntityCoords(entity, object.position.x, object.position.y, object.position.z)
        SetEntityRotation(entity, object.rotation.x, object.rotation.y, object.rotation.z, 2, true)
        SetEntityCollision(entity, true, true)
    end

    self.currentGarage = nil
    self.selected = nil
end

RegisterNUICallback('spawnObject', function(data, cb)
    if not Furniture.active then return cb(false) end
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
        cb(false)
        return
    end
    Furniture.mode = 'mouse'
    SetTempEntity(true)

    Furniture:TogglePlacement(true)
    SetMouseCursorSprite(4)
    Furniture.selected = Furniture.entity

    SetNuiFocus(true, false)
    SetNuiFocusKeepInput(true) --todo
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
        -- ResetEntityAlpha(Furniture.entity)
        SetEntityAlpha(Furniture.entity, 255, false)
        SetEntityDrawOutline(Furniture.entity, false)
        SetMouseCursorSprite(1)

        Furniture:TogglePlacement(false, true)
        Furniture:ToggleMenu(true)

        if Furniture.mode == 'mouse' then
            -- Nui.ControlsNotify()
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

        local hit, entity = Utils.GetEntityOnScreen()

        if hit and IsEntityAnObject(entity) and GetEntityType(entity) == 3 then
            local entityID = Entity(entity).state.entityID
            if Furniture.action == 'create' and entityID then
                return cb(false)
            end

            if (not Furniture.createProps[entity] and not entityID) then
                return cb(false)
            end

            Furniture.selected = entity
            SetTempEntity(true)
            SetNuiFocus(true, false)
            SetNuiFocusKeepInput(true)
            SetMouseCursorSprite(4)

            cb(Furniture.selected)
        else
            cb(false)
        end
    end

    cb('ok')
end)

RegisterNUICallback('onMove', function(data, cb)
    -- Se contesta ya: llega en cada movimiento del raton y dos salidas de
    -- abajo no contestaban, dejando la peticion colgada en la NUI.
    cb('ok')
    if not Furniture.active then return end

    if Furniture.selected and IsEntityAnObject(Furniture.selected) and GetEntityType(Furniture.selected) == 3 then

        local entityID = Entity(Furniture.selected).state.entityID

        if Furniture.action == 'move' and not entityID then
            return
        end

        local offset = (Furniture.createProps[Furniture.selected] and Furniture.createProps[Furniture.selected].offset) or Entity(Furniture.selected).state.min

        local hit, coords = Utils.ScreenToWorld()

        local entityCoords = GetEntityCoords(Furniture.selected)

        local restrictedZone = Furniture.currentGarage.shellPoints

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
            -- ResetEntityAlpha(Furniture.entity)
            SetEntityAlpha(Furniture.entity, 255, false)
            SetEntityDrawOutline(Furniture.entity, false)
        end
    end
end)

RegisterCommand('deleteFurniture', function()
    if Furniture.selected and DoesEntityExist(Furniture.selected) and Furniture.action == 'move' then
        -- Nui.ControlsNotify()
        local data = {
            garageID = Furniture.currentGarage.id,
            entityID = Entity(Furniture.selected).state.entityID,
        }

        _entity = nil

        local deleted = lib.callback.await('origen_garages:server:DeleteFurniture', false, data)

        if deleted then
            Furniture:TogglePlacement(false, false)
            Furniture:ToggleMenu(true)
            Furniture.selected = nil
        end
    end
end)

RegisterKeyMapping('deleteFurniture', 'Muebles: borrar el objeto elegido', 'keyboard', 'DELETE')


RegisterNUICallback('onHover', function(data, cb)  
    if not Furniture.active or Furniture.selected then
        cb('error')        
        return
    end

    local hit, entity = Utils.GetEntityOnScreen()

    if hit and IsEntityAnObject(entity) and GetEntityType(entity) == 3 then 
        local entityID = Entity(entity).state.entityID
        if not entityID then 
            -- Limpiar el alpha de la última entidad antes de retornar
            if Furniture.lastEntity then

                -- ResetEntityAlpha(Furniture.lastEntity)
                SetEntityAlpha(Furniture.lastEntity, 255, false)
                SetEntityDrawOutline(Furniture.lastEntity, false)
                Furniture.lastEntity = nil
            end
            cb('error')
            return
        end

        if Furniture.lastEntity and Furniture.lastEntity ~= entity then
            -- ResetEntityAlpha(Furniture.lastEntity)
            SetEntityAlpha(Furniture.lastEntity, 255, false)
            SetEntityDrawOutline(Furniture.lastEntity, false)
            Furniture.lastEntity = nil
        end
        
        SetMouseCursorSprite(3)
        SetEntityAlpha(entity, 175, false)
        Furniture.lastEntity = entity
    else
        -- Limpiar el alpha de la última entidad cuando no hay hit o no es un objeto válido
        if Furniture.lastEntity then
            -- ResetEntityAlpha(Furniture.lastEntity)
            SetEntityAlpha(Furniture.lastEntity, 255, false)
            SetEntityDrawOutline(Furniture.lastEntity, false)
            Furniture.lastEntity = nil
        end
    end

    cb('ok')
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
        -- ResetEntityAlpha(Furniture.entity)
        SetEntityAlpha(Furniture.entity, 255, false)
        SetEntityDrawOutline(Furniture.entity, false)
        SetMouseCursorSprite(1)
        SetNuiFocus(true, true)
    else
        -- Sin mueble valido tambien sale el cuadro de compra: hay que
        -- devolverle el cursor y quitar KeepInput, o no se puede ni cancelar.
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(false)
    end

    cb('ok')
end)

RegisterNUICallback('cancelFurniturePurchase', function(data, cb)  
    if Furniture.selected and DoesEntityExist(Furniture.selected) then
        Furniture:ToggleMenu(true)
        -- ResetEntityAlpha(Furniture.selected)
        SetEntityAlpha(Furniture.selected, 255, false)
        SetEntityDrawOutline(Furniture.selected, false)
        SetMouseCursorSprite(1)

        Furniture.selected = nil
    else
        Furniture:ToggleMenu(true)
        SetMouseCursorSprite(1)
    end

    cb('ok')
end)

RegisterNUICallback('confirmBuyFurniture', function(data, cb)  
    local buy = Furniture:BuyObject()
    cb(buy)
end)

-- Handlers

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    if Furniture.entity and DoesEntityExist(Furniture.entity) then
        DeleteEntity(Furniture.entity)
    end

    -- Parar el recurso a medio colocar dejaba KeepInput encendido.
    if Furniture.active then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
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

    if self.currentGarage.shellPoints then 
        restrictedZone = self.currentGarage.shellPoints
    end

    if self.mode == 'mouse' then
        -- Aquí se llamaba a Nui.ControlsNotify(), que no existe en el recurso
        -- (error de Lua). El gizmo tampoco viene en el manifiesto: sin él no
        -- hay modo gizmo al que pasar, así que se queda en el modo ratón.
        -- (Las teclas del gizmo las pinta él mismo cuando exista.)
        if not Gizmo then return end
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
            self:BuyObject(_entity, object)
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

    local garage = getCurrentGarage()

    if not garage then 
        Furniture.active = false
        return
    end

    Furniture.currentGarage = garage
end

-- RegisterNuiCallback('toggleFurnitureModeh', function(data, cb)
--     if Furniture.mode == 'gizmo' then
--         Furniture:ToggleMode()
--     end
--     cb('ok')
-- end)

RegisterNuiCallback('onActionObject', function(data, cb)
    if not Furniture.active then return cb(false) end
    if not Furniture.currentGarage then return cb(false) end

    local garage = Furniture.currentGarage
    local objectID = data.id
    if not garage.furniture[objectID] then return cb(false) end

    local object = garage.furniture[objectID]
    local objectEntity = garage.createdFurniture[objectID]

    if data.action == 'delete' then 
        -- Nui.ControlsNotify()
        local data = {
            garageID = garage.id,
            entityID = object.id or Entity(objectEntity.entity).state.entityID,
        }

        _entity = nil

        local deleted = lib.callback.await('origen_garages:server:DeleteFurniture', false, data)

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
        SetTempEntity(true)
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
    if IsNuiFocused() and Furniture.focus then
        SetNuiFocus(false, false)
        Furniture.focus = false
    end
    cb('ok')
end)


-- RegisterCommand('toggleFurnitureMode', function()
--     Furniture:ToggleMode()
-- end)

-- RegisterKeyMapping('toggleFurnitureMode', 'Toggle furniture mode', 'keyboard', 'H')

--[[ Raton soltado a la fuerza (`soltarraton`, o la pantalla colgada): el
     recurso se queda como si se hubiera cerrado por la puerta de siempre.
     Sin esto el modo muebles seguia activo (controles bloqueados, IsBusy a
     true, el mueble a medio colocar) y la pagina pintada sin raton. Aqui no
     se coge el foco: CloseFurniture solo lo suelta. ]]
OrigenFoco.AlSoltar(function()
    if Furniture.active then
        -- En un hilo: CloseFurniture espera (el mueble se desvanece).
        CreateThread(function()
            Furniture:CloseFurniture()
        end)
    end

    -- Y las demas pantallas del recurso (garaje, compra, llaves), sin eco.
    SendNUIMessage({ action = 'forzarCierre' })
end)

RegisterNUICallback('getFurnitureData', function(data, cb)
    cb({
        categories = Config.FurnitureCategories,
        items = Config.Furniture,
    })
end)

RegisterNetEvent('origen_garages:client:updateFurniture', function(garageID, furnitureID, furnitureData)
    local garage = cGarage.Get(garageID)

    if not garage then return end

    garage.furniture[furnitureID] = furnitureData

    garage:UpdateObject(furnitureID, furnitureData)
end)