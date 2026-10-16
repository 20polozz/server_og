cGarage = {
    Utils = {}
}
cGarage.__index = cGarage
cGarage.Table = {}
cGarage.Loaded = false
local props = {}

local function isTypeAllowed(vehicleType, allowedType)
    if vehicleType == 'automobile' or vehicleType == 'bike' then
        return lib.table.contains(allowedType, 'car')
    elseif vehicleType == 'heli' or vehicleType == 'plane' then
        return lib.table.contains(allowedType, 'air')
    elseif vehicleType == 'boat' or vehicleType == 'submarine' then
        return lib.table.contains(allowedType, 'boat')
    end
end

local function requestInteriorFurniture(id)
    local furniture = lib.callback.await('origen_garages:cb:server:getFurniture', false, id)

    return furniture
end

function cGarage.new(data)
    if cGarage.Table[data.id] then
        debugger('cGarage.new', 'Garage already exists', data.id)
        return cGarage.Table[data.id]
    end

    local self = setmetatable({}, cGarage)

    self.id = data.id
    self.name = data.name or ("cGarage " .. tostring(self.id))
    self.shared = data.shared
    self.label = data.label or "Garaje"
    self.capacity = data.capacity or 0
    self.interior = data.interior and { id = data.interior } or false
    self.restrictions = data.restrictions or false
    self.vehicleTypes = data.vehicleTypes or false
    self.states = data.states or { Config.VehicleStates.STORED }
    self.spawnPoints = data.spawnPoints or false
    self.spawner = data.spawner or {}
    self.stayCharge = data.stayCharge
    self.purchasable = data.purchasable or false
    self.price = data.price
    self.owner = data.owner or false
    self.furniture = {}
    self.pedData = data.ped or {}
    self.blipData = data.blip or {}
    self.location = self.pedData.coords and GetLabelText(GetNameOfZone(self.pedData.coords.x, self.pedData.coords.y, self.pedData.coords.z)) or "Desconocida"

    self.isShell = (self.interior and Config.Interiors[self.interior.id] and Config.Interiors[self.interior.id].type == 'shell') and true or false
    self.shell = nil
    self.shellPoints = nil

    self.createdFurniture = {}

    self.holders = data.holders or {}

    if self.pedData.model and self.pedData.coords then
        --[[ El NPC del garaje, solo con alguien cerca: aparece a 80 m y se
             borra al irte. Antes estaba desde que entrabas, ocupando sitio en
             el pool de peds de GTA (256 para todo el servidor). ]]
        local garaje = self
        local function crearPed()
        lib.requestModel(self.pedData.model)

        self.ped = CreatePed(4, self.pedData.model, self.pedData.coords.x, self.pedData.coords.y, self.pedData.coords.z, self.pedData.coords.w, false, true)
        SetEntityAsMissionEntity(self.ped, true, true)
        SetEntityInvincible(self.ped, true)
        SetBlockingOfNonTemporaryEvents(self.ped, true)
        SetPedCanPlayAmbientAnims(self.ped, false)
        SetPedCanRagdoll(self.ped, false)
        FreezeEntityPosition(self.ped, true)

        if self.pedData.skin and GetResourceState('origen_clothing') == 'started' then
            local safeSkin = {}
            for key, value in pairs(self.pedData.skin) do
                if key ~= "model" and key ~= "modelHash" then
                    safeSkin[key] = value
                end
            end
            CreateThread(function()
                Wait(500)
                if DoesEntityExist(self.ped) then
                    pcall(function()
                        exports.origen_clothing:SetAppearance(self.ped, safeSkin)
                    end)
                end
            end)
        end
        end

        self.pedPoint = lib.points.new({ coords = self.pedData.coords, distance = 80.0 })
        function self.pedPoint:onEnter()
            if not (garaje.ped and DoesEntityExist(garaje.ped)) then crearPed() end
        end
        function self.pedPoint:onExit()
            if garaje.ped and DoesEntityExist(garaje.ped) then DeleteEntity(garaje.ped) end
            garaje.ped = nil
        end

        self.point = lib.points.new({
            coords = self.pedData.coords,
            distance = 2.0,
            canInteractGarage = false
        })

        self.point.onEnter = function()
            self.canInteractGarage = self:canAccess(true)
        end

        self.point.onExit = function()
            self.canInteractGarage = false
            TextManager:RemoveText('garage_' .. self.id)
        end

        self.point.nearby = function(p)
            -- Con el menu abierto (o cualquier interfaz con foco) el aviso
            -- «Acceder a…» se quita: se volvia a pintar cada fotograma y se
            -- veia a traves del cristal del panel.
            if self.canInteractGarage and not gEntity and not IsNuiFocused() then
                if not cache.vehicle then
                    TextManager:ManageText('garage_' .. self.id, locale('access_garage', self.label), 'E', p.currentDistance, 1.5)
                else
                    TextManager:RemoveText('garage_' .. self.id)
                end

                if IsControlJustReleased(0, 38) then
                    if not self.owner and self.price then
                        -- exports['origen_garages']:openGarageBuy(self.id)
                        self:openGarageBuy()
                    else
                        if self.interior and Config.Interiors[self.interior.id] then
                            local forwardVector = GetEntityForwardVector(self.ped)
                            local interior = Interior:new({
                                id = self.id,
                                name = self.name,
                                shared = self.shared,
                                interior = Config.Interiors[self.interior.id].interior,
                                coords = self.pedData.coords,
                                isShell = self.isShell,
                                entry = vector4(
                                    GetEntityCoords(self.ped).x + forwardVector.x * 1.0,
                                    GetEntityCoords(self.ped).y + forwardVector.y * 1.0,
                                    GetEntityCoords(self.ped).z,
                                    GetEntityHeading(self.ped) + 180.0
                                ),
                                spawnPoints = self.spawnPoints
                            })

                            if self.isShell then
                                local furniture = requestInteriorFurniture(self.id)
                                self.furniture = furniture or {}
                                interior:CreateShell({
                                    onEnter = function(entity)
                                        self.shell = entity
                                        self.shellPoints = interior.zone
                                        self:LoadFurniture()
                                        LocalPlayer.state.interiorId = self.id
                                    end,
                                    onExit = function()
                                        -- Salir decorando dejaba el modo muebles abierto fuera.
                                        if Furniture.active then Furniture:CloseFurniture() end
                                        self:DeleteFurniture()
                                        self.shell = nil
                                        self.shellPoints = nil
                                        LocalPlayer.state.interiorId = nil
                                    end
                                })
                            else
                                interior:EnterIPL({
                                    onEnter = function()
                                        local furniture = lib.callback.await('origen_garages:cb:server:getFurniture', false, self.id)
                                        self.furniture = furniture or {}
                                        self:LoadFurniture()
                                        LocalPlayer.state.interiorId = self.id
                                    end,
                                    onExit = function()
                                        -- Salir decorando dejaba el modo muebles abierto fuera.
                                        if Furniture.active then Furniture:CloseFurniture() end
                                        self:DeleteFurniture()
                                        LocalPlayer.state.interiorId = nil
                                    end
                                })
                            end
                        else
                            self:openGarageMenu()
                        end
                    end
                    TextManager:RemoveText('garage_' .. self.id)
                end
            else
                TextManager:RemoveText('garage_' .. self.id)
            end
        end
    else
        self.ped = nil
        self.point = nil
        debugger('cGarage.new', 'Garage has no ped model/coords, skipping ped interaction point', self.id)
    end

    self:createBlips()

    local dropPointData = data.dropPoint or {}
    dropPointData.interactionDistance = dropPointData.interactionDistance and tonumber(dropPointData.interactionDistance) or 5.0
    if lib.table.contains(self.states, Config.VehicleStates.STORED) and dropPointData.x and dropPointData.y and dropPointData.z then
        local dropPoint = nil
        self.dropPoint = lib.points.new({
            coords = dropPointData,
            distance = dropPointData.interactionDistance,
        })

        self.dropPoint.onExit = function()
            dropPoint = false
            TextManager:RemoveText('drop_' .. self.id)
        end

        self.dropPoint.canInteractDrop = function()
            if not cache.vehicle or not cache.seat == -1 or not self:canAccess() then return end
            if not cGarage.Utils.isTypeAllowed(GetVehicleType(cache.vehicle), self.vehicleTypes) then return end
            return true
        end

        self.dropPoint.nearby = function(p)
            if self.dropPoint.canInteractDrop() then
                if dropPointData.marker then
                    DrawMarker(Config.Marker.type, vector3(self.dropPoint.coords.x, self.dropPoint.coords.y, self.dropPoint.coords.z + 1.0), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Marker.size.x, Config.Marker.size.y, Config.Marker.size.z, Config.Marker.color[1], Config.Marker.color[2], Config.Marker.color[3], Config.Marker.color[4], Config.Marker.bobUpAndDown, Config.Marker.faceCamera, 2, Config.Marker.rotate, nil, false)
                end

                TextManager:ManageText('drop_' .. self.id, self.stayCharge and locale('park_vehicle_stay_charge', self.stayCharge) or locale('park_vehicle'), 'E', p.currentDistance, dropPointData.interactionDistance)
                if p.currentDistance <= dropPointData.interactionDistance then
                    if IsControlJustReleased(0, 38) then
                        if not cache.vehicle or not cache.seat == -1 then return end
                        TextManager:RemoveText('drop_' .. self.id)
                        if self.interior and Config.Interiors[self.interior.id] then
                            if not self.ped then
                                Custom.Notify(locale('interior_not_found'), 'error')
                                return
                            end

                            local forwardVector = GetEntityForwardVector(self.ped)
                            local interior = Interior:new({
                                id = self.id,
                                name = self.name,
                                shared = self.shared,
                                interior = Config.Interiors[self.interior.id].interior,
                                coords = self.pedData.coords,
                                isShell = self.isShell,
                                entry = vector4(
                                    GetEntityCoords(self.ped).x + forwardVector.x * 1.0,
                                    GetEntityCoords(self.ped).y + forwardVector.y * 1.0,
                                    GetEntityCoords(self.ped).z,
                                    GetEntityHeading(self.ped) + 180.0
                                ),
                                spawnPoints = self.spawnPoints
                            })

                            if self.isShell then
                                local furniture = requestInteriorFurniture(self.id)
                                self.furniture = furniture or {}
                                interior:CreateShell({
                                    onEnter = function(entity)
                                        self.shell = entity
                                        self.shellPoints = interior.zone
                                        self:LoadFurniture()
                                        LocalPlayer.state.interiorId = self.id
                                    end,
                                    onExit = function()
                                        -- Salir decorando dejaba el modo muebles abierto fuera.
                                        if Furniture.active then Furniture:CloseFurniture() end
                                        self:DeleteFurniture()
                                        self.shell = nil
                                        self.shellPoints = nil
                                        LocalPlayer.state.interiorId = nil
                                    end
                                })
                            else
                                interior:EnterIPL({
                                    onEnter = function()
                                        local furniture = lib.callback.await('origen_garages:cb:server:getFurniture', false, self.id)
                                        self.furniture = furniture or {}
                                        self:LoadFurniture()
                                        LocalPlayer.state.interiorId = self.id
                                    end,
                                    onExit = function()
                                        -- Salir decorando dejaba el modo muebles abierto fuera.
                                        if Furniture.active then Furniture:CloseFurniture() end
                                        self:DeleteFurniture()
                                        LocalPlayer.state.interiorId = nil
                                    end
                                })
                            end
                        else
                            if Entity(cache.vehicle).state?.spawner == self.id then
                                local vehicle = cache.vehicle
                                SetVehicleDoorsLocked(vehicle, 2)
                                cGarage.Utils.kickOutPeds(vehicle)
                                Custom.RemoveVehicleKeys(GetVehicleNumberPlateText(vehicle))
                                Wait(2000)
                                DeleteEntity(vehicle)
                            else
                                self:storeVehicle(cache.vehicle)
                            end
                        end
                    end
                end
            else
                TextManager:RemoveText('drop_' .. self.id)
            end
        end
    end
    cGarage.Table[self.id] = self
    return self
end

--[[ El garaje, en el mapa.

     Ya no se crea un blip del juego: se registra el punto en origen_map y de
     ahi lo leen los tres mapas del servidor —el minimapa, el del menu de pausa
     y la pestaña de Ciudad del inventario—.

     Lo que se gana: el NOMBRE. Un blip solo sabe decir su numero de sprite, y
     los mapas de Leaflet tenian que adivinar de ahi que era cada cosa, asi que
     todos los garajes salian llamados «Garaje». Ahora sale el suyo, y el de
     uno en venta dice ademas por cuanto.

     El interruptor y el color del panel (`blipData`) se respetan igual: lo
     unico que cambia es donde se pinta. ]]
function cGarage:createBlips()
    local clave = 'garaje_' .. tostring(self.id)

    if not self.blipData.enabled or not self.pedData or not self.pedData.coords then
        OrigenMapa.Quitar(clave)
        return
    end

    local c = self.pedData.coords

    if self.price and not self.owner then
        OrigenMapa.Poner(clave, {
            x = c.x, y = c.y, z = c.z,
            cat = 'garages',
            nombre = locale('garage_for_sale', self.label, self.price),
        })
    elseif self:canAccess() then
        OrigenMapa.Poner(clave, {
            x = c.x, y = c.y, z = c.z,
            cat = 'garages',
            nombre = self.label,
            --- El color del panel manda, si lo han puesto.
            color = self.blipData.colorHex,
        })
    else
        --- Sin acceso no se marca: un garaje al que no puedes entrar en el mapa
        --- es una promesa que no se cumple.
        OrigenMapa.Quitar(clave)
    end
end

function cGarage:storeVehicle(vehicle)
    local plate = GetVehicleNumberPlateText(vehicle)
    local mods = lib.getVehicleProperties(vehicle)
    mods.fuelLevel = Custom.GetFuel and Custom.GetFuel(vehicle) or mods.fuelLevel
    mods.harness = Entity(vehicle).state.harness
    local result, msg = lib.callback.await('origen_garages:cb:storeVehicle', false, {
        plate = plate,
        garage = self.name,
        id = self.id,
        shared = self.shared,
        vehicleType = GetVehicleType(vehicle),
        mods = mods
    })

    if not result then Custom.Notify(msg, 'error') return end

    SetVehicleDoorsLocked(vehicle, 2)
    cGarage.Utils.kickOutPeds(vehicle)
    Custom.RemoveVehicleKeys(plate)
    Custom.SaveVehicleHealth(vehicle)
    Wait(2000)
    DeleteEntity(vehicle)
    Custom.Notify(msg, 'success')
end

function cGarage:delete()
    debugger('cGarage:delete', 'Deleting garage', self.id)
    
    TextManager:RemoveText('garage_' .. self.id)
    TextManager:RemoveText('drop_' .. self.id)
    
    if self.point then
        debugger('cGarage:delete', 'Deleting point', self.point)
        self.point:remove()
    end

    if self.dropPoint then
        debugger('cGarage:delete', 'Deleting dropPoint', self.dropPoint)
        self.dropPoint:remove()
    end

    if self.interiorPoint then
        debugger('cGarage:delete', 'Deleting interiorPoint', self.interiorPoint)
        self.interiorPoint:remove()
    end

    if self.pedPoint then
        self.pedPoint:remove()
        self.pedPoint = nil
    end

    if self.ped then
        debugger('cGarage:delete', 'Deleting ped', self.ped)
        DeleteEntity(self.ped)
    end
    
    if self.blip then
        debugger('cGarage:delete', 'Removing blip', self.blip)
        RemoveBlip(self.blip)
    end

    cGarage.Table[self.id] = nil
end

function cGarage:update(garageData)
    self:delete()
    cGarage.new(garageData)
end

function cGarage:canBuy()
    if not self.price then
        return false
    end

    if self.owner then
        return false
    end

    return true
end

function cGarage:getHolders()
    return self.holders
end

function cGarage:LoadFurniture()
    if not self.furniture or not next(self.furniture) then
        return
    end

    local function createAndSetupEntity(id, data)
        local coords = data.position
        local rotation = data.rotation

        if not IsModelValid(data.model) then
            -- debugger('Model not valid', data.model)
            return {
                id = id,
            }
        end

        lib.requestModel(data.model)

        local newCoords = nil

        if self.isShell then
            newCoords = GetOffsetFromEntityInWorldCoords(self.shell, coords.x, coords.y, coords.z)
        else
            newCoords = vector3(coords.x, coords.y, coords.z)
        end

        local min, max = GetModelDimensions(data.model)
        local entity = CreateObject(data.model, newCoords.x, newCoords.y, newCoords.z, false, true, false)
        SetEntityRotation(entity, rotation.x, rotation.y, rotation.z, 2, true)
        SetEntityCoords(entity, newCoords.x, newCoords.y, newCoords.z)
        SetEntityLodDist(entity, Config.RenderDistance)
        SetModelAsNoLongerNeeded(data.model)

        Entity(entity).state.entityID = id
        Entity(entity).state.min = vector3(0.0, 0.0, -min.z)

        props[#props + 1] = entity

        FreezeEntityPosition(entity, true)

        CreateThread(function()
            for alpha = 55, 255, 50 do
                SetEntityAlpha(entity, alpha, false)
                Wait(0)
            end
        end)

        return {
            entity = entity,
            id = id,
            model = data.model,
            position = coords,
            rotation = rotation,
            type = data.type,
        }
    end

    for id, data in pairs(self.furniture) do
        self.createdFurniture[id] = createAndSetupEntity(id, data)

        local furniture = self.createdFurniture[id]

        if furniture and furniture.entity then
            props[#props + 1] = furniture.entity
        end
    end
end

function cGarage:canAccess(buy)
    if not self.price and not self.owner then
        return cGarage.Utils.canInteract(self.restrictions)
    end

    if self.price and not self.owner and buy then
        return true
    end

    local identifier = Framework.GetPlayerIdentifier()
    
    if self.owner then
        return (self.owner == identifier or self.holders[identifier])
    end
    
    return false
end

function cGarage:DeleteFurniture()

    local furniture = self.createdFurniture

    if not next(furniture) then
        return
    end

    for _, data in pairs(furniture) do
        if data.entity and DoesEntityExist(data.entity) then
            DeleteEntity(data.entity)
        end
    end

    table.wipe(self.createdFurniture)
end

function cGarage:UpdateObject(id, data)
    _entity = nil

    local function handleObject(furniture, id, data)
        local object = furniture[id]
        if not object then
            local coords = data.position
            local rotation = data.rotation
            
            lib.requestModel(data.model)

            local newCoords = nil

            if self.isShell then
                newCoords = GetOffsetFromEntityInWorldCoords(self.shell, coords.x, coords.y, coords.z)
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

            CreateThread(function()
                for alpha = 55, 255, 50 do
                    SetEntityAlpha(entity, alpha, false)
                    Wait(0)
                end
            end)

            furniture[id] = {
                entity = entity,
                id = id,
                model = data.model,
                position = coords,
                rotation = rotation,
                type = data.type,
            }

            props[#props + 1] = entity
        else
            if not data then
                DeleteEntity(object.entity)
                furniture[id] = nil
            else
                local coords = data.position
                local rotation = data.rotation

                local newCoords = vector3(coords.x, coords.y, coords.z)

                if self.isShell then
                    newCoords = GetOffsetFromEntityInWorldCoords(self.shell, coords.x, coords.y, coords.z)
                else
                    newCoords = vector3(coords.x, coords.y, coords.z)
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
            end
        end
    end

    handleObject(self.createdFurniture, id, data)
end

function cGarage.Get(id)
    return cGarage.Table[id]
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        -- Limpiar el TextManager
        TextManager.activePoints = {}
        Custom.HideText()
        
        for _, garage in pairs(cGarage.Table) do
            if garage.ped then
                DeleteEntity(garage.ped)
            end
        end

        if props then
            for _, prop in pairs(props) do
                DeleteEntity(prop)
            end
        end
    end
end)

Citizen.CreateThread(function()
    if Framework.isPlayerLoaded() then
        Wait(1000)
        TriggerEvent('origen_garages:client:onPlayerLoad')
    end
end)

RegisterNetEvent('origen_garages:client:onPlayerLoad', function()
    if cGarage.Loaded then return end
    cGarage.Loaded = true
    local garages = lib.callback.await('origen_garages:server:getGarages', false)
    for name, data in pairs(garages) do
        cGarage.new(data)
    end
end)

RegisterNetEvent('origen_garages:client:onPlayerUnload', function()
    -- Limpiar el TextManager
    cGarage.Loaded = false
    TextManager.activePoints = {}
    Custom.HideText()
    
    for _, garage in pairs(cGarage.Table) do
        garage:delete()
    end
    cGarage.Table = {}
end)

RegisterNetEvent('origen_garages:client:onJobUpdate', function(job)
    for _, garage in pairs(cGarage.Table) do
        garage:createBlips()
    end
end)

lib.addKeybind({
    name = 'toggleManagement',
    description = 'Garaje: abrir o cerrar la gestión',
    defaultMapper = 'KEYBOARD',
    defaultKey = Config.Keybinds.keysManagement or 'J',
    onPressed = function(self)
        if not LocalPlayer.state.interiorId then return end
        local garage = cGarage.Get(LocalPlayer.state.interiorId)

        if not garage or garage.owner ~= Framework.GetPlayerIdentifier() then return end

        -- Con los muebles abiertos, el panel de llaves se ponia encima y al
        -- cerrarlo (SetNuiFocus false) les quitaba el raton.
        if Furniture.active then return end

        SendNUIMessage({
            action = 'toggleManagement',
            keys = garage:getHolders()
        })
    end
})


--- NUEVO CODIGO ---
function cGarage:openGarageMenu()
    local vehicles = lib.callback.await('origen_garages:cb:getVehicles', false, {
        garage = not Config.IgnoreGarageId and self.name or nil,
        states = self.states,
        select = { 'garage', 'mods', 'plate', 'label' },
        citizen = Framework.GetPlayerIdentifier(),
    })

    vehicles = cGarage.Utils.prepareVehicles(vehicles, false, self.vehicleTypes)

    if not vehicles or #vehicles == 0 and not self.spawner?.enabled then
        Custom.Notify(locale('no_vehicles_in_garage'), 'error')
        return
    end

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openGarage',
        data = {
            vehicles = vehicles,
            garage = {
                id = self.id,
                label = self.label,
                -- Las plazas, para la tira de la cabecera. 0 = sin tope conocido
                -- y la tira no se pinta.
                capacity = tonumber(self.capacity) or 0,
                spawner = self.spawner?.enabled and {
                    enabled = self.spawner.enabled,
                    models = cGarage.Utils.prepareVehicles(self.spawner.models, true, self.vehicleTypes)
                } or nil
            }
        }
    })
end

function cGarage:openGarageBuy()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openBuyGarageModal',
        data = {
            garage = {
                id = self.id,
                name = self.label,
                price = self.price,
                location = self.location,
                capacity = self.capacity,
                type = type(self.vehicleTypes) == "table" and self.vehicleTypes[1] or 'automobile', -- Gonna select the first type because I don't know why we can have multiple types in a single garage :(
            }
        }
    })
end

--[[ Quien abre el garaje puede colgarle una seccion de vehiculos perdidos.

     El garaje no sabe —ni tiene que saber— que es un negocio ni cuanto cuesta
     recuperar nada: recibe la lista ya hecha y el nombre de un evento al que
     avisar cuando el jugador elige uno. Asi esto vale igual para un negocio,
     una banda o lo que venga despues.

     Se guarda aqui, en el cliente, porque la NUI solo devuelve el id de lo
     elegido: el evento al que avisar no viaja a la interfaz. ]]
local recuperacionActiva = nil

local function ponerFotos(items)
    for _, item in ipairs(items or {}) do
        item.photo = item.photo or (item.model and cGarage.Utils.photoOf(item.model))
    end
end

RegisterNUICallback('recoverVehicle', function(data, cb)
    cb({})

    if not recuperacionActiva or not recuperacionActiva.evento then return end
    if not data or data.id == nil then return end

    TriggerEvent(recuperacionActiva.evento, data.id)
end)

--- Para que el que abrio el garaje pueda refrescar la lista sin volver a
--- abrirlo entero, despues de recuperar uno.
function cGarage.actualizarPerdidos(lista)
    if not recuperacionActiva then return end

    recuperacionActiva.items = lista or {}
    ponerFotos(recuperacionActiva.items)
    SendNUIMessage({
        action = 'updateRecovery',
        data = { items = recuperacionActiva.items }
    })
end

exports('actualizarPerdidos', cGarage.actualizarPerdidos)

function cGarage.openExternalGarage(id, coords, business, recuperacion)
    local function getCoordValue(value, key, index)
        if not value then return nil end

        if type(value) == 'table' then
            if value[key] ~= nil then
                return value[key]
            end
            return value[index]
        end

        local ok, coord = pcall(function()
            return value[key]
        end)

        if ok and coord ~= nil then
            return coord
        end

        ok, coord = pcall(function()
            return value[index]
        end)

        if ok and coord ~= nil then
            return coord
        end

        return nil
    end

    local externalCoords = {
        x = tonumber(getCoordValue(coords, 'x', 1)) or 0.0,
        y = tonumber(getCoordValue(coords, 'y', 2)) or 0.0,
        z = tonumber(getCoordValue(coords, 'z', 3)) or 0.0,
        w = tonumber(getCoordValue(coords, 'w', 4)) or 0.0
    }

    if cache.vehicle then
        cGarage.storeExternalVehicle(id, cache.vehicle, business)
    else
        local vehicles = lib.callback.await('origen_garages:cb:getVehicles', false, {
            garage = id,
            states = { Config.VehicleStates.STORED },
            select = { 'garage', 'mods', 'plate', 'label' },
            citizen = business and id or false,
        })

        vehicles = cGarage.Utils.prepareVehicles(vehicles)

        if not vehicles or #vehicles == 0 then
            Custom.Notify(locale('no_vehicles_in_garage'), 'error')
            return
        end

        recuperacionActiva = recuperacion

        ponerFotos(recuperacion and recuperacion.items)

        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'openGarage',
            data = {
                vehicles = vehicles,
                garage = {
                    id = id,
                    label = locale('external_garage'),
                    external = externalCoords
                },
                -- Solo lo que la interfaz necesita pintar: el evento se queda
                -- de este lado.
                recovery = recuperacion and {
                    label = recuperacion.label,
                    price = recuperacion.price,
                    items = recuperacion.items or {}
                } or nil
            }
        })
    end
end

function cGarage.storeExternalVehicle(garageId, vehicle, business)
    local plate = GetVehicleNumberPlateText(vehicle)
    local mods = lib.getVehicleProperties(vehicle)
    mods.fuelLevel = Custom.GetFuel and Custom.GetFuel(vehicle) or mods.fuelLevel
    mods.harness = Entity(vehicle).state.harness
    local result, msg = lib.callback.await('origen_garages:cb:storeVehicleExternal', false, {
        plate = plate,
        garage = garageId,
        id = garageId,
        mods = mods,
        business = business and garageId or false
    })

    if not result then Custom.Notify(msg, 'error') return end

    SetVehicleDoorsLocked(vehicle, 2)
    cGarage.Utils.kickOutPeds(vehicle)
    Custom.RemoveVehicleKeys(plate)
    Custom.SaveVehicleHealth(vehicle)
    Wait(2000)
    DeleteEntity(vehicle)
    Custom.Notify(msg, 'success')
end

function cGarage.openExternalInteriorGarage(id, entryCoords, interiorId, business, spawnPoints, shared, vehicleTypes)
    if not Config.Interiors[interiorId] then
        Custom.Notify(locale('interior_not_found'), 'error')
        return
    end
    
    TriggerServerEvent('origen_garages:sv:registerTemporaryGarage', {
        id = id,
        name = id,
        label = 'Garaje',
        capacity = Config.Interiors[interiorId] and #Config.Interiors[interiorId].interior.spawns or 10,
        interior = interiorId,
        shared = shared or false,
        vehicleTypes = vehicleTypes or {'car'},
        states = {Config.VehicleStates.STORED},
        spawnPoints = spawnPoints or {},
        owner = business or nil
    })
    
    Wait(100)
    
    local interior = Interior:new({
        id = id,
        name = id,
        shared = shared or false,
        interior = Config.Interiors[interiorId].interior,
        coords = entryCoords,
        isShell = false,
        entry = entryCoords,
        spawnPoints = spawnPoints or {}
    })
    
    if #interior.spawnPoints == 0 then
        table.insert(interior.spawnPoints, interior.entry)
    end

    local tempGarage = {
        id = id,
        furniture = {},
        isShell = false,
        createdFurniture = {},
        LoadFurniture = cGarage.LoadFurniture,
        DeleteFurniture = cGarage.DeleteFurniture,
        UpdateObject = cGarage.UpdateObject
    }

    interior:EnterIPL({
        onEnter = function()
            local furniture = lib.callback.await('origen_garages:cb:server:getFurniture', false, id)
            tempGarage.furniture = furniture or {}
            tempGarage:LoadFurniture()
            LocalPlayer.state.interiorId = id
        end,
        onExit = function()
            tempGarage:DeleteFurniture()
            LocalPlayer.state.interiorId = nil
        end
    })
end

exports('openExternalGarage', cGarage.openExternalGarage)
exports('openExternalInteriorGarage', cGarage.openExternalInteriorGarage)
