Nui = {}

Nui.ControlsNotify = function(data)
    SendNUIMessage({
        action = 'controls',
        title = data and data.title or nil,
        keys = data and data.keys or nil
    })
end

Nui.SetLoading = function(state)
    SendNUIMessage({
        action = 'setLoading',
        state = state
    })
end

Nui.SetTitleInfo = function(state, text)
    SendNUIMessage({
        action = 'setInfo',
        state = state,
        text = text
    })
end

Nui.ToggleManagementMenu = function(state)
    if not HouseData then 
        return 
    end
    
    SendNUIMessage({
        action = 'toggleManagement',
        houseList = HouseData,
        state = state
    })
    
    SetNuiFocus(state, state)
end

Nui.UpdateManagementMenu = function()
    SendNUIMessage({
        action = 'updateManagement',
        houseList = HouseData,
    })
end

Nui.OpenBuyHouse = function(data, garage)
    SendNUIMessage({
        action = 'buyHouse',
        data = data,
        garage = garage
    })
    SetNuiFocus(true, true)
end

Nui.OpenHouseMenu = function(data)
    SendNUIMessage({
        action = 'toggleHouseMenu',
        state = true,
        data = data
    })
    SetNuiFocus(true, true)
end

--- `sinSoltar`: la pagina esconde el panel sin contestar con fetch('close'),
--- para cuando detras se abre otra pantalla que coge el foco (los muebles):
--- ese eco llegaba tarde y se lo quitaba. El foco se suelta aqui igual.
Nui.CloseHouseMenu = function(sinSoltar)
    SendNUIMessage({
        action = 'toggleHouseMenu',
        state = false,
        sinSoltar = sinSoltar or nil,
    })
    SetNuiFocus(false, false)
end

Nui.togglePreviewOpacity = function(state)
    SendNUIMessage({
        action = 'togglePreviewOpacity',
        state = not state,
    })
    SetNuiFocus(state, state)
end

Nui.PlaySound = function()
    SendNUIMessage({
        action = 'playAlarm',
    })
end

Nui.UpdateSound = function(volume)
    SendNUIMessage({
        action = 'updateAlarm',
        volume = volume
    })
end

Nui.StopSound = function()
    SendNUIMessage({
        action = 'stopAlarm',
    })
end

Nui.OpenHousesMenu = function()
    if not playerIdentifier then
        return
    end

    local houses = lib.callback.await('origen_housing:server:getOwnedHouses', false, playerIdentifier)
    local focus = true

    local MyHouses = {}

    if houses and next(houses) then 
        for _, id in pairs(houses) do
            local house = House.get(id)
            house = house.houseData
            MyHouses[#MyHouses+1] = {
                id = id,
                name = house.name,
                location = house.data.location,
                locked = not house.settings.upgrades['domotic'],
            }
        end
    end

    houses = MyHouses

    if not next(houses) then focus = false end

    SendNUIMessage({
        action = 'toggleHousesMenu',
        houses = houses,
        show = true,
        focus = focus
    })

    SetNuiFocus(focus, focus)
end

Nui.ToggleElevatorMenu = function(state, data)
    if state and IsNuiFocused() then return end
    SendNUIMessage({
        action = 'toggleElevator',
        state = state,
        data = data
    })
    SetNuiFocus(state, state)
end

RegisterNUICallback('selectFloor', function(data, cb)
    -- No contestaba nunca; se contesta ya, lo de abajo tarda segundos.
    cb('ok')
    if not Garage.inside then return end

    local floors = Garage.floors

    if not floors or not floors[data.floor + 1] then return end

    local coords = floors[data.floor + 1].coords

    Nui.ToggleElevatorMenu(false)
    SetLocalPlayerAsGhost(true)
    DoScreenFadeOut(500)
    Wait(650)
    SetPedCoordsKeepVehicle(cache.ped, vector3(coords.x, coords.y, coords.z - 1 + 0.0))

    local veh = GetVehiclePedIsIn(cache.ped, false)

    SetEntityHeading(veh ~= 0 and veh or cache.ped, coords.w)
    SetGameplayCamRelativeHeading(0)
    Wait(1000)
    while not HasCollisionLoadedAroundEntity(veh ~= 0 and veh or cache.ped) do
		Wait(200)
	end
    if not fade then
        DoScreenFadeIn(500)
    end
    SetLocalPlayerAsGhost(false)
end)

RegisterNetEvent('origen_housing:client:openHousingMenu', function()
    Nui.ToggleManagementMenu(true)
end)


RegisterNUICallback('closeMenu', function(data, cb)
    Nui.ToggleManagementMenu(false)
    cb('ok')
    
    if Nui.openedFromHub then
        Nui.openedFromHub = false  -- Reset
        exports['origen_admin']:ReturnToScripts()
    end
end)

RegisterNUICallback('close', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('getAllData', function(data, cb)
    cb({
        translations = Config.Translations.nui,
        exteriors = Config.Exteriors,
        ipls = __indexIplsStyles,
        shells = __indexShellsData,
        stages = Config.BuildingStages,
        furnitureCategories = Config.FurnitureCategories,
        furnitureItems = Config.Furniture,
        upgrades = Config.Upgrades,
        doorLimit = Config.DoorLimit,
        allowedExtensions = Config.AllowedExtensions,
        defaultPrice = Config.DefaultPrice,
        paymentMethods = Config.PaymentMethods,
        mloBaseLimits = (Config.MloPoints and Config.MloPoints.baseLimits) or { stash = 3, wardrobe = 3 },
        mloSlotPrice = (Config.MloPoints and Config.MloPoints.slotPrice) or 5000,
    })
end)

RegisterNUICallback('startConstructionPlacement', function(data, cb)
    SetNuiFocus(false, false)
    local points = nil
    local markers = nil

    -- Casa de banda o de crew: va dentro del territorio de su banda (el
    -- principal) o crew, que es además su zona exterior
    -- (custom/client/propietario.lua). Sin territorio no hay casa.
    if PropietarioCliente then
        local vale, aviso = PropietarioCliente.Preparar(data.house.data)
        if not vale then
            Internal.Notify(aviso, 'error', 8000)
            return
        end
    end

    local place = Placement:new(nil, data.house.construction.model)

    local houseCoords = place:createPlacement()

    if houseCoords then 
        local object = place.object
        SetEntityAlpha(object, 255, false)
        FreezeEntityPosition(object, true)
        SetEntityCollision(object, true, false)
        Wait(200)
        -- Casa de banda: la zona exterior es el territorio de la banda y no
        -- se dibuja nunca (la pone el servidor).
        if PropietarioCliente and PropietarioCliente.Limite() then
            points = { banda = true }
        else
            points = Creation:CreateExteriorZone()
        end

        if not points then
            debugger('Cancel exterior zone creation')
            return
        end

        Wait(200)
        if data.house.useGarage then
            markers = place:placeMarkers()
        else
            markers = place:placeMarkers(0, true)
        end

        debugger('Markers', json.encode(markers, { indent = true }))

        if not markers or not next(markers) then 
            debugger('Cancel markers creation')
            return
        end
        place:stopPlacement()
    end

    if PropietarioCliente then PropietarioCliente.Soltar() end

    if not houseCoords or not markers or not points then
        place:stopPlacement() 
        debugger('Cancel creation')
        return
    end

    SetNuiFocus(true, true)
    --todo devolver cordenadas de construccion y puntos de exterior

    local _data = {
        constructionCoords = json.encode(houseCoords),
        entryCoords = json.encode(markers['entry'].coords),
        polyzoneCoords = points,
    }

    if data.house.useGarage then
        _data.garageCoords = json.encode(markers['garage'].coords)
    end

    cb(_data)
end)

RegisterNUICallback('TriggerCallback', function(data, cb)
    local trigger = data.trigger


    if trigger == 'origen_housing:server:createHouse' then
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local streetName = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
        local streetNameLabel = GetStreetNameFromHashKey(streetName)
        data.house.data.location = streetNameLabel
        data.house.construction.stage = #Config.BuildingStages
        Nui.ToggleManagementMenu(false)
        data = data.house

        data.id = nil

        data.furniture = {
            interior = {},
            exterior = {},
        }

        -- Casa de banda o de crew (cualquier modalidad): va dentro del
        -- territorio de su banda o crew, que es además su zona exterior. No
        -- se dibuja zona, y sin territorio no hay casa. Si la casa ya viene
        -- colocada (flujo con obra), no hay nada que preparar.
        if PropietarioCliente and (not next(data.exterior) or not next(data.positions)) then
            local vale, aviso = PropietarioCliente.Preparar(data.data)
            if not vale then return cb({ status = false, message = aviso }) end
        end

        local type = data.data.type
        local id = tostring(1)
        if type == 'shell' then
            data.doors = {
                [id] = {
                    name = Config.Translations.general.entry,
                    locked = true,
                }
            }
        elseif type == 'ipl' then
            data.doors = {
                [id] = {
                    name = Config.Translations.general.entry,
                    locked = true,
                }
            }

            local preview = Preview:new(nil, 'ipl', math.min(#Config.IPL, 1), Config.IPL)

            local selected = preview:createIPLPreview() 

            if not selected then
                return cb(false)
            end

            data.data.model = preview.items[selected].model
            local iplData = __indexIpls[data.data.model]

            if iplData and iplData.styles then
                data.data.style = iplData.styles.default
            end
        end

        Wait(200)

        data.settings = {}
        data.settings.upgrades = {
            ['alarm'] = false,
            ['cameras'] = false,
            ['doors'] = false,
            ['sensors'] = false,
            ['storage_security'] = false,
            ['domotic'] = false,
        }

        if not next(data.exterior) then
            -- Casa de banda: la zona exterior es el territorio de la banda y
            -- no se dibuja nunca (la pone el servidor).
            if PropietarioCliente and PropietarioCliente.Limite() then
                data.exterior = { banda = true }
            else
                data.exterior = Creation:CreateExteriorZone()
            end

            if not data.exterior then
                return cb(false)
            end
        end

        Wait(200)

        if not next(data.positions) then
            local markers = nil
            local place = Placement:new(nil, nil)

            if data.useGarage then 
                markers = place:placeMarkers()
            else
                markers = place:placeMarkers(0, true)
            end

            debugger('Markers', json.encode(markers, { indent = true }))

            if PropietarioCliente then PropietarioCliente.Soltar() end

            if not markers or not next(markers) then return cb(false) end

            data.positions = {}
            data.positions = {
                entry = markers['entry'].coords,
                garage = data.useGarage and markers['garage'].coords or {}
            }
        end

        Wait(200)

        data.garage = 'none'

        if not data.garage or data.garage == 'none' and data.useGarage then
            local preview = Preview:new(nil, 'garages', math.min(#Config.GarageInteriors, 1), Config.GarageInteriors)

            local selected = preview:createIPLPreview() 
    
            if not selected then 
                debugger('Cancel garage creation')
                return cb(false)
            end

            data.garage = Config.GarageInteriors[selected].model
        end

        Wait(200)
    elseif trigger == 'origen_housing:server:editHouse' then
        local house = House.get(data.houseID)
        if not house then return cb({status = false, message = Config.Translations.notify.error.notExistsHouse}) end
        local reposition = data.reposition
        
        local positions = {}

        -- Casa de banda o de crew: la zona no se redibuja (es el territorio)
        -- y la entrada y el garaje solo se recolocan dentro de él.
        local deBanda = false
        if PropietarioCliente and type(data.house.data) == 'table' and PropietarioCliente.ConTerritorio(data.house.data.uso) then
            local vale, aviso = PropietarioCliente.Preparar(data.house.data, not (reposition.entryPoint or reposition.garagePoint))
            if not vale then return cb({ status = false, message = aviso }) end
            deBanda = PropietarioCliente.Limite() ~= nil
        elseif PropietarioCliente then
            PropietarioCliente.Soltar()
        end

        Wait(200)
        if reposition.zone and not deBanda then
            positions.zone = Creation:CreateExteriorZone(house.houseData.exterior)

            if not positions.zone then
                positions.zone = nil
            end
        end

        if reposition.entryPoint then
            Wait(200)
            local marker = Placement:placeMarkers(0, true)

            if marker and marker['entry'] then 
                positions.entry = marker['entry'].coords
            else
                positions.entry = nil
            end
        end

        if data.house.useGarage and (reposition.garagePoint or not next(house.houseData.positions?.garage)) then
            Wait(200)
            local marker = Placement:placeMarkers(1, true)

            if marker and marker['garage'] then 
                positions.garage = marker['garage'].coords
            else
                positions.garage = nil
            end
        end

        if data.house.useGarage and data.house.garage == 'none' then
            local preview = Preview:new(nil, 'garages', math.min(#Config.GarageInteriors, 1), Config.GarageInteriors)

            local selected = preview:createIPLPreview() 

            data.house.garage = selected and Config.GarageInteriors[selected].model or 'none'
        end

        if PropietarioCliente then PropietarioCliente.Soltar() end

        data.reposition = positions
    end

    local retval = lib.callback.await(trigger, false, data)
    cb(retval)
end)

RegisterNUICallback('markHousePosition', function(data, cb)
    local houseID = data.id
    local house = House.get(houseID)

    if house then 
        local entryPoint = house.houseData.positions.entry
        SetNewWaypoint(entryPoint.x, entryPoint.y)
        cb(true)
    else
        cb(false)
    end
end)

RegisterNUICallback('closeBuyHouse', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('visitHouse', function(data, cb)
    SetNuiFocus(false, false)
    local house = House.get(tonumber(data.houseID))
    if not house.nearby then 
        return cb('ok')
    end
    if house then 
        house:EnterHouse()
    end
    cb('ok')
end)

RegisterNUICallback('toggleFurnitureMode', function(data, cb)
    local mode = data.mode
    Furniture.mode = mode
    cb('ok')
end)

RegisterNUICallback('createDoor', function(data, cb)
    local currentHouse = currentExteriorHouseID or currentInteriorHouseID

    local house = House.get(currentHouse)

    if not house then 
        Internal.Notify(Config.Translations.notify.error.notNearHouse, 'error', 5000)
        cb(false)
        return
    end

    if not house.nearby then 
        cb(false)
        return
    end

    if not house:hasKey() then
        Internal.Notify(Config.Translations.notify.error.noKey, 'error', 5000)
        cb(false)
        return
    end

    Nui.CloseHouseMenu()

    Doors:StartCreation({
        type = data.type,
        name = data.name,
        houseID = house.id,
        distance = tonumber(data.distance),
    })

    cb(true)
end)

RegisterNUICallback('reassignDoor', function(data, cb)
    local currentHouse = currentExteriorHouseID or currentInteriorHouseID
    local house = House.get(currentHouse)

    if not house or not house.nearby or not house:hasKey() then 
        cb(false)
        return
    end

    Nui.CloseHouseMenu()

    Doors:StartCreation({
        id = data.doorID,
        type = data.type,
        name = data.name,
        houseID = house.id,
        distance = tonumber(data.distance),
    })

    cb(true)
end)

RegisterNUICallback('startMloPointPlacement', function(data, cb)
    local currentHouse = currentExteriorHouseID or currentInteriorHouseID
    local house = House.get(currentHouse)

    if not house then 
        Internal.Notify(Config.Translations.notify.error.notNearHouse, 'error', 5000)
        cb(false)
        return
    end

    if not house.nearby or not house:hasKey() then 
        cb(false)
        return
    end

    Nui.CloseHouseMenu()
    cb(true)

    CreateThread(function()
        LocalPlayer.state:set('IsBusy', true, true)
        Nui.ControlsNotify({
            title = 'Colocar punto: ' .. (data.name or data.type or 'MLO'),
            keys = {
                { key = 'enter', text = 'Confirmar' },
            }
        })

        Wait(200)

        local confirmedCoords = nil
        while true do
            local ped = cache.ped
            local pcoords = GetEntityCoords(ped)
            local hit, screenCoords = Utils.GetScreenCoords()

            local targetX, targetY
            if hit and screenCoords then
                targetX, targetY = screenCoords.x, screenCoords.y
            else
                local fwd = GetEntityForwardVector(ped)
                targetX = pcoords.x + (fwd.x * 2.0)
                targetY = pcoords.y + (fwd.y * 2.0)
            end

            -- Determinar el suelo exacto para mantener siempre altura fija de cintura (~0.9m)
            local floorZ = nil
            local ray = StartShapeTestRay(targetX, targetY, pcoords.z + 0.5, targetX, targetY, pcoords.z - 3.5, 1, ped, 0)
            local _, hitG, groundHit = GetShapeTestResult(ray)
            if hitG == 1 and groundHit and groundHit.z ~= 0.0 then
                floorZ = groundHit.z
            else
                local s, gz = GetGroundZFor_3dCoord(targetX, targetY, pcoords.z, false)
                if s then
                    floorZ = gz
                else
                    floorZ = pcoords.z - 0.9
                end
            end

            local waistZ = floorZ + 0.9
            local coords = vector3(targetX, targetY, waistZ)

            DrawMarker(2, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.25, 0.25, 0.25, 216, 27, 85, 220, false, false, 2, true, nil, nil, false)

            if IsControlJustPressed(0, 191) or IsControlJustPressed(0, 201) or IsControlJustPressed(0, 38) then
                confirmedCoords = coords
                break
            end

            if IsControlJustPressed(0, 177) or IsControlJustPressed(0, 194) then
                break
            end

            Wait(0)
        end

        Nui.ControlsNotify()
        LocalPlayer.state:set('IsBusy', false, true)

        if confirmedCoords then
            local res = lib.callback.await('origen_housing:server:setMloPoint', false, {
                houseID = house.id,
                type = data.type,
                name = data.name,
                coords = { x = confirmedCoords.x, y = confirmedCoords.y, z = confirmedCoords.z, h = GetEntityHeading(cache.ped) }
            })

            if res and res.status then
                Internal.Notify('Punto colocado correctamente', 'success', 5000)
            else
                Internal.Notify((res and res.message) or 'Error al colocar punto', 'error', 5000)
            end
        end

        Wait(300)
        Nui.OpenHouseMenu(house.houseData)
    end)
end)

RegisterNUICallback('deleteMloPoint', function(data, cb)
    local currentHouse = currentExteriorHouseID or currentInteriorHouseID
    local house = House.get(currentHouse)
    if not house then return cb({ status = false, message = 'Casa no encontrada' }) end

    local res = lib.callback.await('origen_housing:server:deleteMloPoint', false, {
        houseID = house.id,
        pointId = data.pointId
    })
    cb(res)
end)

RegisterNUICallback('buyMloPointSlot', function(data, cb)
    local currentHouse = currentExteriorHouseID or currentInteriorHouseID
    local house = House.get(currentHouse)
    if not house then return cb({ status = false, message = 'Casa no encontrada' }) end

    local res = lib.callback.await('origen_housing:server:buyMloPointSlot', false, {
        houseID = house.id,
        type = data.type
    })
    cb(res)
end)

RegisterNUICallback('useCamera', function(data, cb)
    local houseID = data.houseID

    local house = House.get(houseID)

    house:UseCamera(data.cameraID)

    cb('ok')
end)

--[[ Los avisos de la NUI, TODOS a origen_notify (07/10).

     Antes solo pasaban por aqui los que llevaban `custom`; el resto se
     pintaba en una pila propia dentro de la NUI de las viviendas, con otro
     aspecto y en otro sitio. Ahora llegan todos, con su titulo si lo traen:
     «Error» + el motivo, «Carrito» + lo añadido...

     Si origen_notify no esta arrancado, el aviso del framework de siempre. ]]
local TIPOS_AVISO = { success = true, error = true, info = true, warning = true, primary = true, inform = true }

RegisterNUICallback('sendNotification', function(data, cb)
    cb('ok')
    data = type(data) == 'table' and data or {}

    local tipo = TIPOS_AVISO[data.type] and data.type or 'info'
    local titulo = type(data.title) == 'string' and data.title or ''
    local texto = type(data.message) == 'string' and data.message or ''

    -- Sin cuerpo, el titulo hace de texto y no se repite arriba.
    if texto == '' then
        texto, titulo = titulo, ''
    end
    if texto == '' then return end

    if GetResourceState('origen_notify') == 'started' then
        exports.origen_notify:Notify({
            title = titulo ~= '' and titulo or nil,
            description = texto,
            type = tipo,
            duration = 5000,
        })
    else
        Internal.Notify(texto, tipo, 5000)
    end
end)

RegisterNUICallback('loadHouse', function(data, cb)
    -- No contestaba nunca.
    cb('ok')
    OpenHouseMenu(data.id)
end)

RegisterNUICallback('canCreateDoor', function(data, cb)
    local houseID = data.houseID

    local house = House.get(houseID)

    if not house then 
        cb(false)
        return
    end

    if not house.houseData.doors or not next(house.houseData.doors) then
        cb(true)
        return
    end

    if Config.DoorLimit and Config.DoorLimit > 0 then
        local doorCount = 0
        for _, _ in pairs(house.houseData.doors) do
            doorCount = doorCount + 1
        end

        if doorCount >= Config.DoorLimit then
            cb(false)
            return
        end
    end

    cb(true)
end)


Nui.OpenRoomDetailPanel = function(room, hotel)
    local identifier = playerIdentifier
    debugger('Opening room detail panel:', room.room_number, '| Hotel:', hotel.name, '| My ID:', identifier)
    
    local isMyRoom = false
    if room.rented_by and identifier and room.rented_by == identifier then
        isMyRoom = true
    end
    
    local nuiData = {
        action = 'openRoomDetailPanel',
        room = {
            id = room.id,
            hotel_id = room.hotel_id,
            room_number = room.room_number,
            status = room.status,
            rented_by = isMyRoom and identifier or nil,
            rental_type = room.rental_type,
            rental_price = room.rental_price,
            rented_at = room.rented_at,
            expires_at = room.expires_at,
            auto_renew = room.auto_renew,
            door_locked = room.door_locked or 1
        },
        hotel = {
            id = hotel.id,
            name = hotel.name,
            rental_options = hotel.rental_options,
            auto_renew_available = hotel.auto_renew_available
        },
        isMyRoom = isMyRoom
    }
    
    SendNUIMessage(nuiData)
    SetNuiFocus(true, true)
end

RegisterNUICallback('rentHotelRoom', function(data, cb)
    lib.callback('origen_housing:server:rentHotelRoom', false, function(result)
        cb(result)
        if result.status then
            Internal.Notify(result.message, 'success', 5000)
        else
            Internal.Notify(result.message, 'error', 5000)
        end
    end, data)
end)

RegisterNUICallback('enterHotelRoomFromPanel', function(data, cb)
    local roomID = tonumber(data.roomID)
    local room = HotelRoom.get(roomID)

    --[[ Se contesta ya y se entra en hilo aparte: entrar tarda un par de
         segundos —fundido, salto y esperar a que cargue el suelo— y dejar la
         llamada de la NUI abierta todo ese rato atasca a las demas. ]]
    cb('ok')

    if not room then return end

    CreateThread(function()
        room:EnterRoom()
    end)
end)

RegisterNUICallback('renewHotelRoom', function(data, cb)
    lib.callback('origen_housing:server:renewHotelRoom', false, function(result)
        cb(result)
        if result.status then
            Internal.Notify(result.message, 'success', 5000)
        else
            Internal.Notify(result.message, 'error', 5000)
        end
    end, data.roomID)
end)

RegisterNUICallback('evictHotelRoom', function(data, cb)
    lib.callback('origen_housing:server:evictHotelRoom', false, function(result)
        cb(result)
        if result.status then
            Internal.Notify(result.message, 'success', 5000)
        else
            Internal.Notify(result.message, 'error', 5000)
        end
    end, data.roomID)
end)

RegisterNUICallback('setHotelRoomAutoRenew', function(data, cb)
    lib.callback('origen_housing:server:setHotelRoomAutoRenew', false, function(result)
        cb(result)
    end, data.roomID, data.autoRenew)
end)

RegisterNUICallback('toggleHotelRoomDoorLock', function(data, cb)
    lib.callback('origen_housing:server:toggleHotelRoomDoorLock', false, function(result)
        cb(result)
        if result.status then
            Internal.Notify(result.door_locked == 1 and Config.Translations.notify.info.doorLocked or Config.Translations.notify.info.doorUnlocked, 'success', 3000)
        else
            Internal.Notify(result.message, 'error', 5000)
        end
    end, data.roomID)
end)

RegisterNUICallback('createHotel', function(data, cb)
    lib.callback('origen_housing:server:createHotel', false, function(result)
        cb(result)
        if result.status then
            Internal.Notify(Config.Translations.nui.hotelCreatedSuccess, 'success', 5000)
            Nui.UpdateManagementMenu()
        else
            Internal.Notify(result.message, 'error', 5000)
        end
    end, data)
end)

RegisterNUICallback('updateHotel', function(data, cb)
    lib.callback('origen_housing:server:updateHotel', false, function(result)
        cb(result)
        if result.status then
            Internal.Notify(Config.Translations.nui.hotelUpdatedSuccess, 'success', 5000)
            Nui.UpdateManagementMenu()
        else
            Internal.Notify(result.message, 'error', 5000)
        end
    end, data.hotelID, data.data)
end)

RegisterNUICallback('deleteHotel', function(data, cb)
    lib.callback('origen_housing:server:deleteHotel', false, function(result)
        cb(result)
        if result.status then
            Internal.Notify(Config.Translations.nui.hotelDeletedSuccess, 'success', 5000)
            Nui.UpdateManagementMenu()
        else
            Internal.Notify(result.message, 'error', 5000)
        end
    end, data.hotelID)
end)

RegisterNUICallback('createHotelRoom', function(data, cb)
    lib.callback('origen_housing:server:createHotelRoom', false, function(result)
        cb(result)
        if result.status then
            Internal.Notify(Config.Translations.nui.roomCreatedSuccess, 'success', 5000)
        else
            Internal.Notify(result.message, 'error', 5000)
        end
    end, data)
end)

RegisterNUICallback('deleteHotelRoom', function(data, cb)
    lib.callback('origen_housing:server:deleteHotelRoom', false, function(result)
        cb(result)
        if result.status then
            Internal.Notify(Config.Translations.nui.roomDeletedSuccess, 'success', 5000)
        else
            Internal.Notify(result.message, 'error', 5000)
        end
    end, data.roomID)
end)

RegisterNUICallback('adminEvictHotelRoom', function(data, cb)
    lib.callback('origen_housing:server:adminEvictHotelRoom', false, function(result)
        cb(result)
        if result.status then
            Internal.Notify(result.message, 'success', 5000)
        else
            Internal.Notify(result.message, 'error', 5000)
        end
    end, data.roomID)
end)

RegisterNUICallback('getHotelsData', function(data, cb)
    lib.callback('origen_housing:server:getHotelsWithRooms', false, function(hotelsList)
        cb(hotelsList or {})
    end)
end)

RegisterNUICallback('getHotelIPLs', function(data, cb)
    cb(Config.Hotels.interiorIPLs)
end)

RegisterNUICallback('getPlayerCoords', function(data, cb)
    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    cb({
        x = coords.x,
        y = coords.y,
        z = coords.z,
        w = heading
    })
end)

RegisterCommand('myrooms', function()
    if not Config.Hotels or not Config.Hotels.enabled then return end
    Nui.OpenMyRoomsMenu()
end, false)

local function OpenManagementPanel()
    if HouseData then
    end
    
    if not HouseData or not next(HouseData) then
        local houses = lib.callback.await('origen_housing:server:getAllHouses', false)

        if houses and next(houses) then
            for _, v in pairs(houses) do
                HouseData[v.id] = v
            end
        end
    end
    Nui.ToggleManagementMenu(true)
end

-- RegisterCommand('housing', function()
--     OpenManagementPanel()
-- end, false)

Nui.openedFromHub = false

exports('openManagement', function()
    Nui.openedFromHub = true
    
    CreateThread(function()        
        if not HouseData or not next(HouseData) then
            local houses = lib.callback.await('origen_housing:server:getAllHouses', false)
            if houses and next(houses) then
                for _, v in pairs(houses) do
                    HouseData[v.id] = v
                end
            end
        end
        
        SendNUIMessage({
            action = 'toggleManagement',
            houseList = HouseData,
            state = true
        })
        
        Wait(200)
        
        SetNuiFocus(true, true)        
    end)
end)

--[[ ══ Colocar un punto con el laser ═══════════════════════════════════════
     Lo usan la puerta de una habitacion, el punto del hotel en el mapa y el
     mostrador. Era el mismo bucle copiado dos veces; ahora es uno solo con
     dos interruptores: el rotulo que se enseña arriba, y si la rueda del
     raton orienta el punto —la puerta lo necesita, un sitio en el suelo
     no—. ]]
local function ColocarConLaser(titulo, conGiro, cb)
    SetNuiFocus(false, false)

    SendNUIMessage({
        action = 'toggleManagement',
        state = false
    })

    Wait(100)

    local place = Placement:new(nil, nil)

    local teclas = {
        { key = 'enter', text = Config.Translations.controls.confirm },
    }

    if conGiro then
        teclas[#teclas + 1] = { key = 'wheel', text = Config.Translations.controls.rotate }
    end

    teclas[#teclas + 1] = { key = 'borrar', text = Config.Translations.controls.cancel }

    Nui.ControlsNotify({ title = titulo, keys = teclas })

    place.active = true
    local rotation = 0.0
    LocalPlayer.state:set('IsBusy', true, true)

    --  Salir es siempre lo mismo: quitar la ayuda de teclas, soltar al
    --  jugador, devolver el panel y contestarle a la NUI.
    local function cerrar(resultado)
        place.active = false
        Nui.ControlsNotify()
        LocalPlayer.state:set('IsBusy', false, true)

        SendNUIMessage({
            action = 'toggleManagement',
            state = true
        })
        SetNuiFocus(true, true)
        cb(resultado)
    end

    while place.active do
        local ped = cache.ped
        local pedCoords = GetEntityCoords(ped)
        local hit, coords = Utils.GetScreenCoords()

        DrawLine(pedCoords.x, pedCoords.y, pedCoords.z, coords.x, coords.y, coords.z, 216, 27, 85, 255)

        if conGiro then
            DrawMarker(20, coords.x, coords.y, coords.z + 1, 0.0, 0.0, 0.0, 90.0, rotation - 180, 0.0, 0.3, 0.3, 0.3, 216, 27, 85, 200, false, false, 0, false)

            if IsControlPressed(0, 241) then
                rotation = rotation + 5.0
                if rotation > 360.0 then
                    rotation = 0.0
                end
            end

            if IsControlPressed(0, 242) then
                rotation = rotation - 5.0
                if rotation < 0.0 then
                    rotation = 360.0
                end
            end
        else
            DrawMarker(20, coords.x, coords.y, coords.z + 1, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.5, 0.5, 0.5, 216, 27, 85, 200, true, true, 2, nil, nil, false)
        end

        if IsControlJustPressed(0, 177) then
            cerrar({ success = false })
            return
        end

        DisableControlAction(0, 24, true)
        if IsControlJustPressed(0, 176) or IsControlJustPressed(0, 191) or IsControlJustPressed(0, 201) then
            cerrar({
                success = true,
                coords = {
                    x = coords.x,
                    y = coords.y,
                    z = coords.z,
                    w = conGiro and rotation or nil
                }
            })
            return
        end

        Wait(0)
    end
end

RegisterNUICallback('startHotelDoorPlacement', function(data, cb)
    ColocarConLaser(Config.Translations.controls.hotelDoor, true, cb)
end)

RegisterNUICallback('startHotelEntrancePlacement', function(data, cb)
    ColocarConLaser(Config.Translations.controls.hotelBlip, false, cb)
end)

RegisterNUICallback('startHotelReceptionPlacement', function(data, cb)
    ColocarConLaser(Config.Translations.controls.hotelReception, false, cb)
end)

--[[ ══ El mostrador ═══════════════════════════════════════════════════════
     La lista llega ya recortada del servidor —de las habitaciones ajenas
     solo el numero y si estan libres—, asi que se pasa tal cual. ]]
Nui.OpenHotelReception = function(data)
    SendNUIMessage({
        action = 'openHotelReception',
        hotel = data.hotel,
        rooms = data.rooms,
    })

    SetNuiFocus(true, true)
end

--  Tras alquilar, renovar o dejar una habitacion, la lista que se esta
--  mirando ya no dice la verdad. Se vuelve a pedir sin cerrar el panel.
RegisterNUICallback('refreshReception', function(data, cb)
    local hotelID = tonumber(data.hotelID)
    if not hotelID then return cb(false) end

    --[[ Con callback y no con `lib.callback.await`: un await aqui dentro
         depende de que el manejador de NUI corra en corrutina, y si no
         arranca, `cb` no se llama NUNCA. La NUI se queda esperando una
         respuesta que no llega —abierta, con el raton preso y sin hacer
         nada—, que es lo peor que puede pasar aqui. Asi es ademas como
         piden datos todos los demas callbacks de este fichero. ]]
    lib.callback('origen_housing:server:getReceptionRooms', false, function(lista)
        cb(lista or false)
    end, hotelID)
end)

