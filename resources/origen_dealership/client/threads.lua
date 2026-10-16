dealershipsData = {}
vehicleColors = {}
local clientUpdateTime = 0
local previewVehicle
local onDealership = false
local previewCamera = nil
local loadedElements = {
    npcs = {},
    markers = {},
    exhibitors = {},
    zones = {}
}

local createdNPCS = {}
local loadingDealerships = {}

--[[ El concesionario, en el mapa.

     Ya no se crea un blip del juego: se registra el punto en origen_map y de
     ahi lo leen los tres mapas del servidor. Lo que se gana es el nombre —un
     blip solo sabe decir su numero de sprite, asi que en los mapas de Leaflet
     todos los concesionarios salian llamados «Concesionario»— y que el ajuste
     del panel de administracion llegue: el sprite se elige alli, y los mapas
     buscaban por numero, asi que cambiarlo hacia desaparecer el sitio.

     `blipConfig` se sigue leyendo del panel; lo unico que ya no se usa es el
     numero de sprite, porque aqui el dibujo es nuestro. ]]
local function marcarConcesionario(dealershipId, dealershipData, coords)
    if not coords then return end

    OrigenMapa.Poner('concesionario_' .. tostring(dealershipId), {
        x = coords.x, y = coords.y, z = coords.z,
        cat = 'garages',
        icono = 'llave',
        nombre = dealershipData.name or locale('ui.admin_panel.title'),
    })
end

local cameraControls = {
    zoom = 1.0,
    rotation = 0.0,
    baseDistance = 5.0,
    height = 1.5,
    targetZoom = 1.0,
    targetRotation = 0.0,
    targetHeight = 1.5,
    smoothSpeed = 0.1,
    isAnimating = false,
    -- Variables para mantener el estado entre cambios de vehículo
    savedZoom = nil,
    savedRotation = nil,
    savedHeight = nil,
    -- Límites de seguridad
    minZoom = 0.8,
    maxZoom = 3.0,
    minHeight = 0.3,
    maxHeight = 4.0,
    minDistance = 2.0,
    maxDistance = 8.0
}

-- Preview fijo solicitado para mejorar consistencia visual en dealership.
local FIXED_PREVIEW_VEHICLE_COORDS = vec4(1047.18, 4887.14, -31.8, 186.92)
local FIXED_PREVIEW_CAMERA_COORDS = vec4(1047.45, 4881.61, -30.9, 1.08)
local FIXED_PREVIEW_LOOK_AT = vector3(1047.18, 4887.14, -31.35)

local helpShown = {
    marker = false,
    npc = false,
    exhibitor = false
}

local currentInteractionContext = {
    type = nil,
    allowPurchase = true,
    allowTestDrive = true
}

local function HudFadeOut(time)
    local t = tonumber(time) or 350
    if GetResourceState('origen_hud') == 'started' then
        SetNuiZindex(1)
        exports['origen_hud']:DoScreenFadeOut(t)
        Wait(t + 20)
    else
        DoScreenFadeOut(t)
        while not IsScreenFadedOut() do Wait(0) end
    end
end

local function HudFadeIn(time)
    local t = tonumber(time) or 450
    if GetResourceState('origen_hud') == 'started' then
        SetNuiZindex(99999)
        exports['origen_hud']:DoScreenFadeIn(t)
    else
        DoScreenFadeIn(t)
    end
end

-- Si la NUI ya avisó con previewReady de esta apertura del catálogo, y qué
-- apertura es. Lo usa la red de handlePress para no dejar la pantalla en negro.
local previewListo = false
local aperturaPreview = 0

function lerp(a, b, t)
    return a + (b - a) * t
end

function table.count(t)
    local count = 0
    for _ in pairs(t) do count = count + 1  end
    return count
end

local function clearAllElements()

    for id, npc in pairs(loadedElements.npcs) do
        if DoesEntityExist(npc.ped) then
            DeleteEntity(npc.ped)
        end
    end
    loadedElements.npcs = {}
    
    for id, exhibitor in pairs(loadedElements.exhibitors) do
        if DoesEntityExist(exhibitor.vehicle) then
            DeleteEntity(exhibitor.vehicle)
        end
    end
    loadedElements.exhibitors = {}
    
    loadedElements.markers = {}

    -- Guardar los blips en lugar de eliminarlos
    local savedBlips = {}
    for id, zone in pairs(loadedElements.zones) do
        if zone.blip and zone.coords then
            savedBlips[id] = {
                blip = zone.blip,
                coords = zone.coords
            }
        end
    end
    
    -- Restaurar solo los blips
    loadedElements.zones = {}
    for id, data in pairs(savedBlips) do
        loadedElements.zones[id] = {
            blip = data.blip,
            coords = data.coords,
            loaded = false
        }
    end
end

local function getElementCoords(element)
    if not element or type(element) ~= "table" then
        return nil
    end

    local function resolveHeading(data)
        if type(data) ~= "table" then
            return 0.0
        end

        local raw = data.heading
        if raw == nil then raw = data.w end
        if raw == nil and data.coords and type(data.coords) == "table" then
            raw = data.coords.heading
            if raw == nil then raw = data.coords.w end
        end

        local heading = tonumber(raw) or 0.0
        heading = heading % 360.0
        if heading < 0.0 then heading = heading + 360.0 end
        return heading
    end

    
    if element.coords and type(element.coords) == "table" then
        local coords = element.coords
        if coords.x and coords.y and coords.z then
            return {
                x = coords.x,
                y = coords.y,
                z = coords.z,
                w = resolveHeading(coords)
            }
        end
    end
    
    if element.x and element.y and element.z then
        return {
            x = element.x,
            y = element.y,
            z = element.z,
            w = resolveHeading(element)
        }
    end
    
    if type(element) == "table" and element[1] and element[2] and element[3] then
        return {
            x = element[1],
            y = element[2],
            z = element[3],
            w = tonumber(element[4]) or 0.0
        }
    end
    
    return nil
end

local function getRandomCarFromStock(stocks, allowedVehicles)
    local availableCars = {}
    local allCars = {}
    
    for categoryId, categoryData in pairs(stocks) do
        if type(categoryData) == "table" and categoryData.categoryStock then
            for _, carData in pairs(categoryData.categoryStock) do
                if type(carData) == "table" and carData.model then
                    local model = carData.model
                    
                    -- Si hay autos permitidos configurados, solo usar esos
                    if allowedVehicles and #allowedVehicles > 0 then
                        local isAllowed = false
                        for _, allowedModel in ipairs(allowedVehicles) do
                            if allowedModel == model then
                                isAllowed = true
                                break
                            end
                        end
                        if not isAllowed then
                            goto continue
                        end
                    end
                    
                    table.insert(allCars, model)
                    
                    if carData.stock and carData.stock > 0 then
                        table.insert(availableCars, model)
                    end
                    
                    ::continue::
                end
            end
        end
    end
    
    local carsToUse = #availableCars > 0 and availableCars or allCars
    
    if #carsToUse > 0 then
        local selected = carsToUse[math.random(1, #carsToUse)]
        return selected
    end
    
    return nil
end

local function createNPC(npcData, dealershipId)
    local coords = getElementCoords(npcData)
    if not coords then
        return nil
    end
    
    local model = npcData.model or npcData.hash or "a_m_y_business_01"
    local modelHash = GetHashKey(model)
    
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    if not HasModelLoaded(modelHash) then
        return nil
    end
    
    local ped = CreatePed(4, modelHash, coords.x, coords.y, coords.z, coords.w + 1.0 or 0.0, false, true)

    table.insert(createdNPCS, ped)
    
    if not DoesEntityExist(ped) then
        SetModelAsNoLongerNeeded(modelHash)
        return nil
    end
    
    SetEntityAsMissionEntity(ped, true, true)
    SetPedRandomComponentVariation(ped, false)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    
    local npcId = string.format("%s_npc_%s", dealershipId, math.floor(coords.x) .. math.floor(coords.y))
    
    loadedElements.npcs[npcId] = {
        ped = ped,
        coords = coords,
        dealership = dealershipId,
        data = npcData
    }
    
    SetModelAsNoLongerNeeded(modelHash)
    return npcId
end

local function createExhibitor(exhibitorData, dealershipId, vehicleModel, exhibitorIndex)
    if not vehicleModel then
        return nil
    end
    
    local coords = getElementCoords(exhibitorData)
    if not coords then
        return nil
    end
    
    
    local modelHash = GetHashKey(vehicleModel)
    
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    if not HasModelLoaded(modelHash) then
        return nil
    end
    local spawnHeading = tonumber(coords.w) or 0.0
    spawnHeading = spawnHeading % 360.0
    if spawnHeading < 0.0 then spawnHeading = spawnHeading + 360.0 end
    local roundedX = math.floor((coords.x or 0.0) * 100.0 + 0.5) / 100.0
    local roundedY = math.floor((coords.y or 0.0) * 100.0 + 0.5) / 100.0
    local roundedZ = math.floor((coords.z or 0.0) * 100.0 + 0.5) / 100.0
    local exhibitorId = string.format("%s_exhibitor_%s_%s_%s", dealershipId, tostring(roundedX), tostring(roundedY), tostring(roundedZ))

    local existing = loadedElements.exhibitors[exhibitorId]
    if existing and existing.vehicle and DoesEntityExist(existing.vehicle) then
        DeleteEntity(existing.vehicle)
    end

    -- Seguridad: si cambian índices/orden al guardar, elimina cualquier exhibidor del mismo concesionario
    -- que esté en el mismo punto para evitar duplicados y superposiciones.
    for id, exhibitor in pairs(loadedElements.exhibitors) do
        if id ~= exhibitorId and exhibitor and exhibitor.dealership == dealershipId and exhibitor.coords then
            local dx = math.abs((exhibitor.coords.x or 0.0) - (coords.x or 0.0))
            local dy = math.abs((exhibitor.coords.y or 0.0) - (coords.y or 0.0))
            local dz = math.abs((exhibitor.coords.z or 0.0) - (coords.z or 0.0))
            if dx <= 0.15 and dy <= 0.15 and dz <= 0.25 then
                if exhibitor.vehicle and DoesEntityExist(exhibitor.vehicle) then
                    DeleteEntity(exhibitor.vehicle)
                end
                loadedElements.exhibitors[id] = nil
            end
        end
    end

    local vehicle = CreateVehicle(modelHash, coords.x, coords.y, coords.z, spawnHeading, false, false)
    
    if not DoesEntityExist(vehicle) then
        SetModelAsNoLongerNeeded(modelHash)
        return nil
    end
    
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleOnGroundProperly(vehicle)
    SetEntityHeading(vehicle, spawnHeading)
    -- Reaplicar heading tras un frame para evitar inversiones puntuales de orientación.
    Wait(0)
    SetEntityHeading(vehicle, spawnHeading)
    SetEntityInvincible(vehicle, true)
    FreezeEntityPosition(vehicle, true)
    SetVehicleDoorsLocked(vehicle, 2)
    SetVehicleUndriveable(vehicle, true)
    SetVehicleDirtLevel(vehicle, 0.0)
    -- Configuración estética
    SetVehicleModKit(vehicle, 0)
    SetVehicleWindowTint(vehicle, 1)
    
    loadedElements.exhibitors[exhibitorId] = {
        vehicle = vehicle,
        coords = coords,
        dealership = dealershipId,
        model = vehicleModel,
        data = exhibitorData,
        baseHeading = spawnHeading,
        rotationHeading = spawnHeading
    }
    
    SetModelAsNoLongerNeeded(modelHash)
    return exhibitorId
end

local function findCenterCoords(markers)
    
    if markers.center and type(markers.center) == "table" then
        local coords = getElementCoords(markers.center)
        if coords then
            return coords
        end
    end
    
    if markers.npcs and next(markers.npcs) then
        for i, npc in pairs(markers.npcs) do
            local coords = getElementCoords(npc)
            if coords then
                return coords
            end
        end
    end
    
    if markers.cars_exhibitor and next(markers.cars_exhibitor) then
        for i, exhibitor in pairs(markers.cars_exhibitor) do
            local coords = getElementCoords(exhibitor)
            if coords then
                return coords
            end
        end
    end
    
    if markers.markers and next(markers.markers) then
        for i, marker in pairs(markers.markers) do
            local coords = getElementCoords(marker)
            if coords then
                return coords
            end
        end
    end
    
    return nil
end

local function createMarkers(markersData, dealershipId)
    local markerIds = {}
    if markersData.markers then
        for i, marker in pairs(markersData.markers) do
            
            local coords = getElementCoords(marker)
            if coords then
                local markerId = string.format("%s_marker_%s", dealershipId, i)
                loadedElements.markers[markerId] = {
                    coords = coords,
                    dealership = dealershipId,
                    data = marker,
                    markerType = 'general'
                }
                table.insert(markerIds, markerId)
            end
        end
    end
    
    return markerIds
end

local function clearDealershipVisualElements(dealershipId)
    for npcId, npc in pairs(loadedElements.npcs) do
        if npc and npc.dealership == dealershipId then
            if npc.ped and DoesEntityExist(npc.ped) then
                DeleteEntity(npc.ped)
            end
            loadedElements.npcs[npcId] = nil
        end
    end

    for exhibitorId, exhibitor in pairs(loadedElements.exhibitors) do
        if exhibitor and exhibitor.dealership == dealershipId then
            if exhibitor.vehicle and DoesEntityExist(exhibitor.vehicle) then
                DeleteEntity(exhibitor.vehicle)
            end
            loadedElements.exhibitors[exhibitorId] = nil
        end
    end

    for markerId, marker in pairs(loadedElements.markers) do
        if marker and marker.dealership == dealershipId then
            loadedElements.markers[markerId] = nil
        end
    end
end

local function loadDealership(dealershipId, dealershipData)
    if loadingDealerships[dealershipId] then
        return
    end
    loadingDealerships[dealershipId] = true

    local function finish()
        loadingDealerships[dealershipId] = nil
    end

    -- Si ya existe una entrada para este concesionario, verificar si solo tiene blip o está completamente cargado
    local existingZone = loadedElements.zones[dealershipId]
    local hasBlipOnly = existingZone and not existingZone.loaded
    
    -- Si ya está completamente cargado, no hacer nada
    if existingZone and existingZone.loaded then
        finish()
        return
    end
    
    local markers = dealershipData.markers or {}
    local stocks = dealershipData.stocks or {}

    -- Limpieza previa para evitar duplicados cuando llegan recargas simultáneas.
    clearDealershipVisualElements(dealershipId)
    
    if markers.npcs and next(markers.npcs) then
        for i, npc in pairs(markers.npcs) do
            local npcId = createNPC(npc, dealershipId)
            if npcId then
                local npcElement = loadedElements.npcs[npcId]
                if npcElement and Custom and Custom.HandleInteraction then
                    local interactionData = {
                        type = 'npc',
                        dealership = {
                            id = dealershipId,
                            name = dealershipData.name or "Concesionario",
                            data = dealershipData
                        },
                        entity = npcElement.ped,
                        coords = vector3(npcElement.coords.x, npcElement.coords.y, npcElement.coords.z),
                        distance = 0,
                        onInteract = function()
                            handlePress('npc', {
                                entity = npcElement.ped,
                                coords = vector3(npcElement.coords.x, npcElement.coords.y, npcElement.coords.z)
                            })
                        end
                    }
                    local customHandled = Custom.HandleInteraction(interactionData)
                    if not customHandled then
                        npcElement.useDefaultInteraction = true
                    end
                end
            end
        end
    end
    
    if markers.cars_exhibitor and next(markers.cars_exhibitor) then
        for i, exhibitor in pairs(markers.cars_exhibitor) do
            local fixedModel = exhibitor.fixedVehicleModel
            local selectedModel = nil
            if fixedModel and fixedModel ~= "" then
                selectedModel = fixedModel
            else
                local allowedVehicles = exhibitor.allowedVehicles or {}
                if #allowedVehicles > 0 then
                    selectedModel = allowedVehicles[1]
                else
                    selectedModel = getRandomCarFromStock(stocks, allowedVehicles)
                end
            end
            if selectedModel then
                createExhibitor(exhibitor, dealershipId, selectedModel, i)
            end
        end
    end
    
    local markerIds = createMarkers(markers, dealershipId)
    
    -- Si ya tiene un blip, mantenerlo y solo actualizar el estado a cargado
    if hasBlipOnly then
        loadedElements.zones[dealershipId].loaded = true
        finish()
        return
    end
    
    local centerCoords = findCenterCoords(markers)
    
    if centerCoords then
        marcarConcesionario(dealershipId, dealershipData, centerCoords)

        loadedElements.zones[dealershipId] = {
            blip = true,
            coords = centerCoords,
            loaded = true
        }
    else
        loadedElements.zones[dealershipId] = {
            blip = nil,
            coords = nil,
            loaded = true
        }
    end

    finish()
end

local function unloadDealership(dealershipId)
    if not loadedElements.zones[dealershipId] then
        return
    end
    
    -- Guardar referencia al blip y coordenadas antes de descargar
    local zone = loadedElements.zones[dealershipId]
    local blip = zone.blip
    local coords = zone.coords
    
    for npcId, npc in pairs(loadedElements.npcs) do
        if npc.dealership == dealershipId then
            if DoesEntityExist(npc.ped) then
                DeleteEntity(npc.ped)
            end
            loadedElements.npcs[npcId] = nil
        end
    end
    
    for exhibitorId, exhibitor in pairs(loadedElements.exhibitors) do
        if exhibitor.dealership == dealershipId then
            if DoesEntityExist(exhibitor.vehicle) then
                DeleteEntity(exhibitor.vehicle)
            end
            loadedElements.exhibitors[exhibitorId] = nil
        end
    end
    
    for markerId, marker in pairs(loadedElements.markers) do
        if marker.dealership == dealershipId then
            loadedElements.markers[markerId] = nil
        end
    end
    
    -- Mantener el blip pero marcar el concesionario como no cargado
    if blip and coords then
        loadedElements.zones[dealershipId] = {
            blip = blip,
            coords = coords,
            loaded = false -- Marcar como no cargado pero mantener el blip
        }
    else
        loadedElements.zones[dealershipId] = nil
    end
end

local function createGlobalBlips()
    for dealershipId, dealershipData in pairs(dealershipsData) do
        if not loadedElements.zones[dealershipId] or not loadedElements.zones[dealershipId].blip then
            local markers = dealershipData.markers or {}
            local centerCoords = findCenterCoords(markers)
            
            if centerCoords then
                marcarConcesionario(dealershipId, dealershipData, centerCoords)

                loadedElements.zones[dealershipId] = {
                    blip = true,
                    coords = centerCoords,
                    loaded = false
                }
            end
        end
    end
end

CreateThread(function()
    -- Esperar a que los datos de los concesionarios estén disponibles
    while not next(dealershipsData) do
        Wait(500)
    end
    
    -- Crear blips globales para todos los concesionarios
    createGlobalBlips()
    
    -- Luego continuar con la carga dinámica de elementos
    while true do
        local playerPed = cache.ped
        local playerCoords = GetEntityCoords(playerPed)
        
        for dealershipId, dealershipData in pairs(dealershipsData) do
            local shouldLoad = false
            local minDistance = math.huge
            
            if dealershipData.markers then
                for elementType, elements in pairs(dealershipData.markers) do
                    if type(elements) == "table" then
                        for _, element in pairs(elements) do
                            local coords = getElementCoords(element)
                            if coords then
                                local distance = #(playerCoords - vector3(coords.x, coords.y, coords.z))
                                if distance < minDistance then
                                    minDistance = distance
                                end
                            end
                        end
                    end
                end
            end
            
            shouldLoad = minDistance <= Config.LoadDistance
            local isLoaded = loadedElements.zones[dealershipId] and loadedElements.zones[dealershipId].loaded
            
            if shouldLoad and not isLoaded then
                -- Cargar elementos del concesionario pero mantener el blip existente
                if loadedElements.zones[dealershipId] then
                    local existingBlip = loadedElements.zones[dealershipId].blip
                    local existingCoords = loadedElements.zones[dealershipId].coords
                    loadDealership(dealershipId, dealershipData)
                    -- Restaurar el blip si existe
                    if existingBlip and existingCoords then
                        loadedElements.zones[dealershipId].blip = existingBlip
                        loadedElements.zones[dealershipId].coords = existingCoords
                    end
                else
                    loadDealership(dealershipId, dealershipData)
                end
            elseif not shouldLoad and isLoaded and minDistance > Config.UnloadDistance then
                -- Descargar elementos pero mantener el blip
                local existingBlip = loadedElements.zones[dealershipId].blip
                local existingCoords = loadedElements.zones[dealershipId].coords
                unloadDealership(dealershipId)
                -- Restaurar el blip
                if existingBlip and existingCoords then
                    loadedElements.zones[dealershipId] = {
                        blip = existingBlip,
                        coords = existingCoords,
                        loaded = false
                    }
                end
            end
        end
        
        Wait(Config.UpdateInterval)
    end
end)

CreateThread(function()
    while true do
        for _, exhibitor in pairs(loadedElements.exhibitors or {}) do
            if exhibitor and exhibitor.vehicle and DoesEntityExist(exhibitor.vehicle) then
                local rotateEnabled = exhibitor.data and exhibitor.data.rotateEnabled
                if rotateEnabled == nil then rotateEnabled = false end

                if rotateEnabled then
                    local speed = (exhibitor.data and tonumber(exhibitor.data.rotateSpeed)) or 12.0
                    exhibitor.rotationHeading = (exhibitor.rotationHeading or exhibitor.baseHeading or 0.0) - (speed * 0.05)
                    if exhibitor.rotationHeading >= 360.0 then
                        exhibitor.rotationHeading = exhibitor.rotationHeading - 360.0
                    elseif exhibitor.rotationHeading < 0.0 then
                        exhibitor.rotationHeading = exhibitor.rotationHeading + 360.0
                    end
                    SetEntityHeading(exhibitor.vehicle, exhibitor.rotationHeading)
                else
                    local fixedHeading = exhibitor.baseHeading or 0.0
                    SetEntityHeading(exhibitor.vehicle, fixedHeading)
                    exhibitor.rotationHeading = fixedHeading
                end
            end
        end
        Wait(50)
    end
end)

CreateThread(function()
    while true do
        local playerCoords = GetEntityCoords(cache.ped)
        local shouldDraw = false
        local markerInRange = 0
        local npcInRange = 0
        local exhibitorInRange = 0
        --[[ Lo mas cerca que queda cualquier cosa del concesionario. Antes el
             hilo daba la vuelta a todo cada fotograma aunque estuvieras en la
             otra punta del mapa (16/09); ahora, lejos de todo, duerme. ]]
        local masCerca = math.huge

        for elementId, element in pairs(loadedElements.markers or {}) do
            local distance = #(playerCoords - vector3(element.coords.x, element.coords.y, element.coords.z))
            if distance < masCerca then masCerca = distance end

            if distance <= 50.0 then
                shouldDraw = true
                DrawMarker(2, element.coords.x, element.coords.y, element.coords.z + 1, 
                          0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 
                          0, 0, 0, 255, false, false, 0, true)

                if distance <= 2.0 then
                    markerInRange = markerInRange + 1
                    if IsControlJustReleased(0, 38) then
                        handlePress('marker', {
                            entity = nil,
                            coords = vector3(element.coords.x, element.coords.y, element.coords.z)
                        })
                    end
                end
            end
        end
        
        for npcId, npc in pairs(loadedElements.npcs or {}) do
            if npc.useDefaultInteraction then
                local distance = #(playerCoords - vector3(npc.coords.x, npc.coords.y, npc.coords.z))
                if distance < masCerca then masCerca = distance end
                if distance <= Config.NPCInteractDistance then
                    npcInRange = npcInRange + 1
                    if IsControlJustReleased(0, 38) then
                        handlePress('npc', {
                            entity = npc.ped,
                            coords = vector3(npc.coords.x, npc.coords.y, npc.coords.z)
                        })
                    end
                end
            end
        end

        local promptText = nil
        for exhibitorId, exhibitor in pairs(loadedElements.exhibitors or {}) do
            if exhibitor and exhibitor.vehicle and DoesEntityExist(exhibitor.vehicle) then
                local interactable = exhibitor.data and exhibitor.data.interactable
                if interactable == nil then interactable = true end
                if interactable then
                    local distance = #(playerCoords - vector3(exhibitor.coords.x, exhibitor.coords.y, exhibitor.coords.z))
                    if distance < masCerca then masCerca = distance end
                    if distance <= 3.6 then
                        exhibitorInRange = exhibitorInRange + 1
                        
                        promptText = "Revisar coche"
                        if IsControlJustReleased(0, 38) then
                            local allowPurchase = true
                            local allowTestDrive = true
                            local allowedVehicles = {}
                            if exhibitor.data then
                                if exhibitor.data.allowPurchase ~= nil then
                                    allowPurchase = exhibitor.data.allowPurchase
                                end
                                if exhibitor.data.allowTestDrive ~= nil then
                                    allowTestDrive = exhibitor.data.allowTestDrive
                                end
                                if exhibitor.data.allowedVehicles then
                                    allowedVehicles = exhibitor.data.allowedVehicles
                                end
                            end
                            handlePress('exhibitor', {
                                model = exhibitor.model,
                                dealershipId = exhibitor.dealership,
                                coords = vector3(exhibitor.coords.x, exhibitor.coords.y, exhibitor.coords.z),
                                allowPurchase = allowPurchase,
                                allowTestDrive = allowTestDrive,
                                allowedVehicles = allowedVehicles,
                                exhibitorId = exhibitorId
                            })
                        end
                    end
                end
            end
        end
        
        if not promptText then
            if markerInRange > 0 or npcInRange > 0 then
                promptText = locale('ui.help.interact')
            end
        end

        if promptText then
            Custom.DrawText(promptText, 'E')
            helpShown.marker = markerInRange > 0
            helpShown.npc = npcInRange > 0
            helpShown.exhibitor = exhibitorInRange > 0
        else
            if helpShown.marker or helpShown.npc or helpShown.exhibitor then
                Custom.HideText()
                helpShown.marker = false
                helpShown.npc = false
                helpShown.exhibitor = false
            end
        end

        --[[ Los marcadores se pintan a 50 m. Se duerme medio segundo solo por
             encima de 100: yendo en coche normal no se cruzan esos 50 m de
             margen en lo que dura la siesta. ]]
        Wait(masCerca > 100.0 and 500 or 0)
    end
end)

local function getNearestDealership()
    local playerCoords = GetEntityCoords(cache.ped)
    local nearestDealership = nil
    local minDistance = math.huge
    
    for dealershipId, dealershipData in pairs(dealershipsData) do
        local markers = dealershipData.markers
        if not markers then goto continue end
        
        for _, elements in pairs(markers) do
            if type(elements) == "table" then
                for _, element in pairs(elements) do
                    local coords = getElementCoords(element)
                    if coords then
                        local distance = #(playerCoords - vector3(coords.x, coords.y, coords.z))
                        if distance < minDistance then
                            minDistance = distance
                            nearestDealership = {
                                id = dealershipId,
                                data = dealershipData,
                                distance = distance
                            }
                        end
                    end
                end
            end
        end
        
        ::continue::
    end
    
    return nearestDealership
end

local function formatVehicleStock(stocks)
    local formattedStock = {}
    
    if not stocks or type(stocks) ~= "table" then
        return formattedStock
    end
    
    for categoryId, categoryData in pairs(stocks) do
        if type(categoryData) == "table" and categoryData.categoryStock then
            if categoryData.job and categoryData.job ~= "" then
                local playerJob = Custom.GetPlayerJob()
                local allowed = false
                
                if not playerJob then
                    goto next_category
                end
                
                if type(categoryData.job) == "table" then
                    for _, job in ipairs(categoryData.job) do
                        if string.lower(playerJob) == string.lower(job) then
                            allowed = true
                            break
                        end
                    end
                elseif type(categoryData.job) == "string" then
                    for job in string.gmatch(categoryData.job, "([^,]+)") do
                        job = job:gsub("%s+", "")
                        if string.lower(playerJob) == string.lower(job) then
                            allowed = true
                            break
                        end
                    end
                end
                
                if not allowed then
                    goto next_category
                end
            end

            local categoryVehicles = {}
            if type(categoryData.categoryStock) == "table" then
                for i = 1, #categoryData.categoryStock do
                    local carData = categoryData.categoryStock[i]
                    if type(carData) == "table" and carData.model then
                        local vehicleInfo = {
                            stock = carData.stock or 0,
                            stockEnabled = carData.stockEnabled or false,
                            class = carData.class or "A",
                            xp = carData.xp or 0,
                            img = carData.img or carData.image or "",
                            model = carData.model,
                            label = carData.label or carData.name or carData.model,
                            price = carData.price or 0,
                            financing = carData.financing or false,
                            paymentMethods = carData.paymentMethods or { cash = true, bank = true, xp = (carData.xp or 0) > 0, company = false },
                            prices = carData.prices or { cash = carData.price or 0, bank = carData.price or 0, xp = carData.xp or 0, company = 0 }
                        }
                        table.insert(categoryVehicles, vehicleInfo)
                    end
                end
            end

            if #categoryVehicles > 0 then
                formattedStock[categoryId] = {
                    label = categoryData.label or categoryId,
                    categoryStock = categoryVehicles
                }
            end
        end
        ::next_category::
    end

    return formattedStock
end

local function formatVehicleStockForModels(stocks, targetModels)
    local formattedStock = formatVehicleStock(stocks)
    if not targetModels or type(targetModels) ~= "table" or #targetModels == 0 then
        return formattedStock
    end

    local modelsMap = {}
    for _, m in ipairs(targetModels) do modelsMap[m] = true end

    local filteredStock = {}
    for categoryId, categoryData in pairs(formattedStock) do
        if categoryData.categoryStock then
            local newCategoryStock = {}
            for _, vehicleInfo in ipairs(categoryData.categoryStock) do
                if modelsMap[vehicleInfo.model] then
                    table.insert(newCategoryStock, vehicleInfo)
                end
            end
            if #newCategoryStock > 0 then
                filteredStock[categoryId] = {
                    label = categoryData.label,
                    categoryStock = newCategoryStock
                }
            end
        end
    end

    return filteredStock
end

local function getVehicleStatsByModel(model)
    local modelHash = type(model) == 'number' and model or GetHashKey(model)
    if not modelHash or modelHash == 0 then
        return {
            power = 0.0,
            high_speed = 0.0,
            acceleration = 0.0,
            braking = 0.0
        }
    end

    local power = GetVehicleModelEstimatedMaxSpeed(modelHash) or 0.0
    local highSpeed = GetVehicleModelEstimatedMaxSpeed(modelHash) or 0.0
    local acceleration = GetVehicleModelAcceleration(modelHash) or 0.0
    local braking = GetVehicleModelMaxBraking(modelHash) or 0.0

    return {
        power = power,
        high_speed = highSpeed,
        acceleration = acceleration,
        braking = braking
    }
end

CreateThread(function()
    while true do
        if previewCamera and cameraControls.isAnimating then
            local zoomChanged = math.abs(cameraControls.zoom - cameraControls.targetZoom) > 0.01
            local rotationChanged = math.abs(cameraControls.rotation - cameraControls.targetRotation) > 0.01
            local heightChanged = math.abs(cameraControls.height - cameraControls.targetHeight) > 0.01
            
            if zoomChanged or rotationChanged or heightChanged then
                cameraControls.zoom = lerp(cameraControls.zoom, cameraControls.targetZoom, cameraControls.smoothSpeed)
                cameraControls.rotation = lerp(cameraControls.rotation, cameraControls.targetRotation, cameraControls.smoothSpeed)
                cameraControls.height = lerp(cameraControls.height, cameraControls.targetHeight, cameraControls.smoothSpeed)
                
                local carCoords = getCurrentPreviewCoords()
                if carCoords then
                    updateCameraPosition(carCoords)
                end
            else
                cameraControls.isAnimating = false
                cameraControls.zoom = cameraControls.targetZoom
                cameraControls.rotation = cameraControls.targetRotation
                cameraControls.height = cameraControls.targetHeight
            end
        end
        -- Sin cámara de previa no hay nada que suavizar: no despertar cada 16 ms.
        Wait(previewCamera and 16 or 250)
    end
end)

function smoothTransition(newZoom, newRotation, newHeight, speed)
    -- Aplicar límites de seguridad
    if newZoom then
        newZoom = math.max(cameraControls.minZoom, math.min(cameraControls.maxZoom, newZoom))
    end
    if newHeight then
        newHeight = math.max(cameraControls.minHeight, math.min(cameraControls.maxHeight, newHeight))
    end
    
    cameraControls.targetZoom = newZoom or cameraControls.targetZoom
    cameraControls.targetRotation = newRotation or cameraControls.targetRotation
    cameraControls.targetHeight = newHeight or cameraControls.targetHeight
    cameraControls.smoothSpeed = speed or cameraControls.smoothSpeed
    cameraControls.isAnimating = true
end

local function getFixedPreviewCoords()
    return vec4(
        FIXED_PREVIEW_VEHICLE_COORDS.x,
        FIXED_PREVIEW_VEHICLE_COORDS.y,
        FIXED_PREVIEW_VEHICLE_COORDS.z,
        FIXED_PREVIEW_VEHICLE_COORDS.w
    )
end

local function applyFixedPreviewView()
    if not previewCamera then return end

    SetCamCoord(previewCamera, FIXED_PREVIEW_CAMERA_COORDS.x, FIXED_PREVIEW_CAMERA_COORDS.y, FIXED_PREVIEW_CAMERA_COORDS.z)

    if previewVehicle and DoesEntityExist(previewVehicle) then
        SetFocusEntity(previewVehicle)
        SetFocusPosAndVel(FIXED_PREVIEW_VEHICLE_COORDS.x, FIXED_PREVIEW_VEHICLE_COORDS.y, FIXED_PREVIEW_VEHICLE_COORDS.z, 0.0, 0.0, 0.0)
        -- Mantener el coche absolutamente anclado para que rote sobre su eje sin desplazarse.
        SetEntityCoordsNoOffset(previewVehicle, FIXED_PREVIEW_VEHICLE_COORDS.x, FIXED_PREVIEW_VEHICLE_COORDS.y, FIXED_PREVIEW_VEHICLE_COORDS.z, false, false, false)
        FreezeEntityPosition(previewVehicle, true)
        SetVehicleHandbrake(previewVehicle, true)
        SetEntityVelocity(previewVehicle, 0.0, 0.0, 0.0)
        local targetHeading = (FIXED_PREVIEW_VEHICLE_COORDS.w + (cameraControls.rotation or 0.0)) % 360.0
        SetEntityHeading(previewVehicle, targetHeading)

        local zoom = cameraControls.zoom or 1.0
        local camFov = math.max(24.0, math.min(70.0, 68.0 - ((zoom - 1.0) * 18.0)))
        SetCamFov(previewCamera, camFov)

        PointCamAtCoord(previewCamera, FIXED_PREVIEW_LOOK_AT.x, FIXED_PREVIEW_LOOK_AT.y, FIXED_PREVIEW_LOOK_AT.z)
    else
        SetCamRot(previewCamera, 0.0, 0.0, FIXED_PREVIEW_CAMERA_COORDS.w, 2)
    end
end

--[[ Un solo coche en la vista previa.

     Cada callback de NUI corre en su propia corrutina, y montar el coche lleva
     sus esperas (cargar el modelo). Cambiando de coche deprisa —o al abrir el
     menú, que monta uno y acto seguido la interfaz pide el suyo— se solapaban
     dos montajes: el primero borraba el coche anterior y se iba a esperar al
     modelo, el segundo ya no encontraba nada que borrar, y acababan creando los
     dos. El que perdía la carrera se quedaba dentro del otro para siempre,
     porque al salir solo se borra `previewVehicle`, que apunta al ganador.

     Ahora cada montaje se apunta su turno y, al volver de una espera, el que ya
     no es el último se retira. Además el modelo se carga ANTES de borrar el
     coche anterior: entre el borrado y el nuevo no queda ninguna espera, así
     que ni hay dos a la vez ni un hueco vacío. ]]
local previewGeneration = 0
local previewModelHash = nil

--- Todo coche montado para la previa se apunta aquí, para que un sobrante de
--- una carrera no se quede en el sitio. Solo toca los suyos: nunca barre
--- coches de otros recursos.
local previasCreadas = {}

local function limpiarPreviasSobrantes(conservar)
    for i = #previasCreadas, 1, -1 do
        local vehiculo = previasCreadas[i]
        if vehiculo ~= conservar then
            if DoesEntityExist(vehiculo) then
                SetEntityAsMissionEntity(vehiculo, true, true)
                DeleteVehicle(vehiculo)
            end
            table.remove(previasCreadas, i)
        end
    end
end

--- Monta el coche de la vista previa. Devuelve nil si el modelo no carga o si
--- mientras cargaba entró otra petición (esa otra deja el coche puesto).
local function montarVehiculoPrevia(modelo)
    local hash = type(modelo) == 'number' and modelo or GetHashKey(modelo)
    if not hash or hash == 0 then return nil end

    previewGeneration = previewGeneration + 1
    local turno = previewGeneration

    RequestModel(hash)
    local intentos = 0
    while not HasModelLoaded(hash) and intentos < 50 do
        Wait(100)
        intentos = intentos + 1
    end

    -- Esperando al modelo pudo entrar otro cambio, o cerrarse el menú: el que
    -- llega tarde no pinta nada y se retira sin tocar lo que hay puesto.
    if turno ~= previewGeneration or not HasModelLoaded(hash) then
        SetModelAsNoLongerNeeded(hash)
        return nil
    end

    local carCoords = getFixedPreviewCoords()

    -- De aquí a CreateVehicle no se cede el turno: nadie puede colarse en medio.
    if previewVehicle and DoesEntityExist(previewVehicle) then
        DeleteVehicle(previewVehicle)
    end
    previewVehicle = nil
    previewModelHash = nil

    local vehiculo = CreateVehicle(hash, carCoords.x, carCoords.y, carCoords.z, carCoords.w, false, false)
    SetModelAsNoLongerNeeded(hash)

    if not vehiculo or vehiculo == 0 or not DoesEntityExist(vehiculo) then
        limpiarPreviasSobrantes(nil)
        return nil
    end

    previasCreadas[#previasCreadas + 1] = vehiculo
    previewVehicle = vehiculo
    previewModelHash = hash

    SetVehicleDirtLevel(vehiculo, 0.0)
    SetEntityHeading(vehiculo, carCoords.w)
    SetEntityCoordsNoOffset(vehiculo, carCoords.x, carCoords.y, carCoords.z, false, false, false)
    FreezeEntityPosition(vehiculo, true)
    SetVehicleHandbrake(vehiculo, true)
    SetEntityVelocity(vehiculo, 0.0, 0.0, 0.0)
    SetVehicleEngineOn(vehiculo, false, true, true)

    limpiarPreviasSobrantes(vehiculo)

    return vehiculo
end

function setupCameras(dm, previewModel)
    local carCoords = getFixedPreviewCoords()

    local routingBucket = lib.callback.await('origen_dealership:routingBucketHandler', false, true)

    if routingBucket then
        onDealership = true

        local montado = montarVehiculoPrevia(previewModel or Config.DealershipMenu.defaultVehicleModel)
        
        -- Sin coche montado es o que el modelo no cargó, o que la interfaz pidió
        -- otro mientras cargaba: si ese otro ya está puesto, la cámara igual.
        if not montado and not (previewVehicle and DoesEntityExist(previewVehicle)) then
            return nil
        end
        
        Wait(500)
        setupPreviewCamera(carCoords)
    end
end

-- Variable para suavizar la posición de la cámara cuando hay colisión
local smoothedCamPos = nil

function setupPreviewCamera(vehicleCoords)
    if previewCamera then
        DestroyCam(previewCamera, false)
    end

    previewCamera = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    smoothedCamPos = nil -- Resetear posición suavizada
    
    local initialRotation = cameraControls.savedRotation or 0.0
    local initialZoom = cameraControls.savedZoom or 1.0
    local initialHeight = cameraControls.savedHeight or 1.5
    
    cameraControls.zoom = initialZoom
    cameraControls.rotation = initialRotation
    cameraControls.height = initialHeight
    cameraControls.targetZoom = initialZoom
    cameraControls.targetRotation = initialRotation
    cameraControls.targetHeight = initialHeight
    cameraControls.isAnimating = false
    
    -- Esperar un frame para asegurar que el vehículo esté completamente cargado
    Wait(50)
    
    applyFixedPreviewView()
    SetCamActive(previewCamera, true)
    RenderScriptCams(true, false, 0, true, true)
end

function setupDepthOfField()
    if not previewCamera or not DoesEntityExist(previewVehicle) then return end

    SetCamUseShallowDofMode(previewCamera, true)

    local camCoords = GetCamCoord(previewCamera)
    local vehCoords = GetEntityCoords(previewVehicle)
    local distance = #(camCoords - vehCoords)

    local buffer = 0.3
    SetCamNearDof(previewCamera, distance - buffer)
    SetCamFarDof(previewCamera, distance + buffer)
    SetCamDofStrength(previewCamera, 1.0)

    CreateThread(function()
        while DoesCamExist(previewCamera) do
            SetUseHiDof()
            Wait(0)
        end
    end)
end

function checkCameraCollisions(vehicleCoords, desiredCamPos, maxDistance)
    -- Punto de origen del raycast: centro del vehículo, ligeramente elevado
    local origin = vector3(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z + 0.5)
    
    -- Raycast desde el centro del vehículo hacia la posición deseada de la cámara
    -- Flags: 1 (world/map) + 16 (objetos) = 17
    local rayHandle = StartShapeTestLosProbe(
        origin.x, origin.y, origin.z,
        desiredCamPos.x, desiredCamPos.y, desiredCamPos.z,
        17,
        previewVehicle,
        4
    )
    
    local _, hit, hitCoords, surfaceNormal, hitEntity = GetShapeTestResult(rayHandle)
    
    if hit == 1 and hitCoords then
        -- Hay colisión — calcular posición segura antes del impacto
        local collisionDistance = #(hitCoords - origin)
        local safeDistance = math.max(collisionDistance - 0.5, 1.5)
        
        local direction = desiredCamPos - origin
        local dirLength = #direction
        if dirLength > 0.01 then
            direction = direction / dirLength
        end
        
        return origin + (direction * safeDistance)
    end
    
    return desiredCamPos
end

function updateCameraPosition(vehicleCoords)
    applyFixedPreviewView()
end

function updateDepthOfField(distance)
    -- if not previewCamera or not DoesEntityExist(previewVehicle) then return end

    -- -- Si se proporciona distancia, usarla; sino calcularla
    -- if not distance then
    --     local camCoords = GetCamCoord(previewCamera)
    --     local vehCoords = GetEntityCoords(previewVehicle)
    --     distance = #(camCoords - vehCoords)
    -- end

    -- if distance > 10.0 then
    --     SetCamUseShallowDofMode(previewCamera, false)
    --     return
    -- end

    -- SetCamUseShallowDofMode(previewCamera, true)

    -- local nearDof, farDof, strength

    -- if distance > 5.0 then
    --     nearDof = distance - 1.0
    --     farDof = distance + 1.0
    --     strength = 0.5
    -- elseif distance > 2.0 then
    --     nearDof = distance - 5.7
    --     farDof = distance + 5.7
    --     strength = 0.7
    -- else
    --     nearDof = distance - 5.3
    --     farDof = distance + 5.3
    --     strength = 0.4
    -- end
    
    -- SetCamNearDof(previewCamera, nearDof)
    -- SetCamFarDof(previewCamera, farDof)
    -- SetCamDofStrength(previewCamera, strength)

    -- CreateThread(function()
    --     while DoesCamExist(previewCamera) do
    --         SetUseHiDof()
    --         Wait(0)
    --     end
    -- end)
end

RegisterNUICallback('origen_dealerships:ui:changeVehiclePreview', function(data, cb)
    local model = GetHashKey(data.model)

    if currentInteractionContext.type == 'exhibitor' and currentInteractionContext.exhibitorId then
        local exhibitor = loadedElements.exhibitors[currentInteractionContext.exhibitorId]
        if exhibitor then
            CreateThread(function()
                local rHeading = exhibitor.rotationHeading
                local newId = createExhibitor(exhibitor.data, exhibitor.dealership, data.model, 0)
                if newId and loadedElements.exhibitors[newId] then
                    loadedElements.exhibitors[newId].rotationHeading = rHeading
                    -- Ensure we update the model explicitly
                    loadedElements.exhibitors[newId].model = data.model
                end
            end)
            
            local vehicleStats = getVehicleStatsByModel(data.model)
            cb({
                power = vehicleStats.power,
                high_speed = vehicleStats.high_speed,
                acceleration = vehicleStats.acceleration,
                braking = vehicleStats.braking
            })
            return
        end
    end

    -- Coche nuevo en la vista previa, de fábrica: los tonos del anterior no
    -- valen (la NUI también devuelve la paleta a cero al cambiar de coche).
    local teniaTonos = vehicleColors.primary ~= nil or vehicleColors.secondary ~= nil
    vehicleColors = {}

    -- Seguridad extra: asegurar instancia individual para que no se solapen previews.
    local routingBucket = lib.callback.await('origen_dealership:routingBucketHandler', false, true)
    if not routingBucket then
        cb({
            power = 0.0,
            high_speed = 0.0,
            acceleration = 0.0,
            braking = 0.0
        })
        return
    end

    -- Guardar el estado actual antes de cambiar el vehículo
    cameraControls.savedZoom = cameraControls.zoom
    cameraControls.savedRotation = cameraControls.rotation
    cameraControls.savedHeight = cameraControls.height
    
    -- Al abrir el menú el coche ya lo montó setupCameras, y la interfaz pide
    -- acto seguido el suyo: si es el mismo y sigue de fábrica, rehacerlo solo
    -- sirve para que dos montajes se pisen.
    local yaEstaPuesto = previewVehicle and DoesEntityExist(previewVehicle)
        and previewModelHash == model and not teniaTonos

    if not yaEstaPuesto then
        montarVehiculoPrevia(model)
    end

    -- Usar los valores guardados para mantener el estado
    local newZoom = cameraControls.savedZoom or 1.0
    local newRotation = cameraControls.savedRotation or 0.0
    local newHeight = cameraControls.savedHeight or 1.0
    smoothTransition(newZoom, newRotation, newHeight, 0.15)

    -- Las cifras salen del modelo, no del coche montado: así se contesta igual
    -- aunque este montaje se haya retirado por otro más nuevo (si no se
    -- contesta, la interfaz se queda esperando y el negro no se levanta). Es
    -- además lo que ya usan el expositor y la apertura del menú.
    local vehicleStats = getVehicleStatsByModel(model)

    cb({
        power = vehicleStats.power,
        high_speed = vehicleStats.high_speed,
        acceleration = vehicleStats.acceleration,
        braking = vehicleStats.braking
    })
end)

RegisterNUICallback('origen_dealerships:ui:updateCameraControls', function(data, cb)
    local speed = data.speed or 0.1
    
    -- Aplicar límites de seguridad a los valores recibidos
    if data.zoom then
        data.zoom = math.max(cameraControls.minZoom, math.min(cameraControls.maxZoom, data.zoom))
        cameraControls.savedZoom = data.zoom
    end
    if data.height then
        data.height = math.max(cameraControls.minHeight, math.min(cameraControls.maxHeight, data.height))
        cameraControls.savedHeight = data.height
    end
    if data.rotation then
        cameraControls.savedRotation = data.rotation
    end
    
    -- Si la velocidad es alta (arrastre), aplicar directamente sin animación
    if speed > 0.1 then
        cameraControls.zoom = data.zoom or cameraControls.zoom
        cameraControls.rotation = data.rotation or cameraControls.rotation
        cameraControls.height = data.height or cameraControls.height
        cameraControls.targetZoom = cameraControls.zoom
        cameraControls.targetRotation = cameraControls.rotation
        cameraControls.targetHeight = cameraControls.height
        cameraControls.isAnimating = false
        
        -- Aplicar inmediatamente sobre vehículo + cámara fija
        applyFixedPreviewView()
    else
        -- Para zoom/rotación, usar animación suave
        smoothTransition(data.zoom, data.rotation, data.height, speed)
    end
    
    cb('ok')
end)

function getCurrentPreviewCoords()
    if previewVehicle then
        local coords = GetEntityCoords(previewVehicle)
        local heading = GetEntityHeading(previewVehicle)
        return vec4(coords.x, coords.y, coords.z, heading)
    end
    return nil
end

function cleanupPreviewCamera()
    cameraControls.isAnimating = false
    smoothedCamPos = nil
    
    -- Resetear los valores guardados para que la próxima vez se calcule desde cero
    cameraControls.savedZoom = nil
    cameraControls.savedRotation = nil
    cameraControls.savedHeight = nil
    
    if previewCamera then
        SetCamActive(previewCamera, false)
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(previewCamera, false)
        previewCamera = nil
    end
    
    -- Saliendo puede haber un montaje esperando al modelo: pasar de turno hace
    -- que se retire en vez de dejar un coche puesto con el menú ya cerrado.
    previewGeneration = previewGeneration + 1
    previewModelHash = nil

    if previewVehicle and DoesEntityExist(previewVehicle) then
        DeleteVehicle(previewVehicle)
    end
    previewVehicle = nil
    limpiarPreviasSobrantes(nil)

    ClearFocus()

    -- Los tonos de la paleta son del coche que se estaba mirando: si se quedan,
    -- el siguiente coche que se compra sale con el color de otro.
    vehicleColors = {}

    onDealership = false
    currentInteractionContext = {
        type = nil,
        allowPurchase = true,
        allowTestDrive = true
    }
end


--- Mientras el servidor contesta si puedes entrar: sin esto, mantener la E
--- lanzaba una pregunta a Discord por fotograma. Es el momento hasta el que
--- se espera (o false): si el servidor no contesta nunca, a los 10 s se
--- puede volver a pulsar en vez de quedarse sin concesionario hasta reconectar.
local comprobandoEntrada = false

function handlePress(type, entityData)
    local nearestDealership = getNearestDealership()
    if type == 'exhibitor' and entityData and entityData.dealershipId and dealershipsData[entityData.dealershipId] then
        nearestDealership = {
            id = entityData.dealershipId,
            data = dealershipsData[entityData.dealershipId]
        }
    end

    if not nearestDealership then
        if Custom and Custom.Notify then
            Custom.Notify(locale('notifications.no_nearby_dealership'), "error")
        end
        return
    end

    --[[ Concesionario VIP: el servidor pregunta a Discord si tienes el rol
         cada vez que intentas entrar (server/vip.lua). Hasta que conteste no
         se pinta nada, y si dice que no, no se abre. Se pregunta siempre, no
         solo en los VIP: quien decide si lo es tambien es el servidor. ]]
    if comprobandoEntrada and GetGameTimer() < comprobandoEntrada then return end
    comprobandoEntrada = GetGameTimer() + 10000
    local entrada = lib.callback.await('origen_dealerships:sv:puedeEntrar', false, nearestDealership.id)
    comprobandoEntrada = false
    if not entrada or not entrada.ok then
        if Custom and Custom.Notify then
            Custom.Notify((entrada and entrada.mensaje) or 'No puedes entrar en este concesionario.', "error")
        end
        return
    end
    
    if type == 'npc' or type == 'marker' or type == 'exhibitor' then
        local allowCatalog = true
        if nearestDealership.data.settings and nearestDealership.data.settings.allowCatalog ~= nil then
            allowCatalog = nearestDealership.data.settings.allowCatalog
        end
        local exhibitorAllowPurchase = true
        local exhibitorAllowTestDrive = true
        if type == 'exhibitor' and entityData then
            if entityData.allowPurchase ~= nil then
                exhibitorAllowPurchase = entityData.allowPurchase
            end
            if entityData.allowTestDrive ~= nil then
                exhibitorAllowTestDrive = entityData.allowTestDrive
            end
        end

        local targetModel = entityData and entityData.model or nil
        local allowedVehicles = (type == 'exhibitor' and entityData and entityData.allowedVehicles) or {}
        
        local dealershipStock = nil
        if type == 'exhibitor' then
            if #allowedVehicles > 0 then
                dealershipStock = formatVehicleStockForModels(nearestDealership.data.stocks, allowedVehicles)
            elseif targetModel then
                dealershipStock = formatVehicleStockForModels(nearestDealership.data.stocks, {targetModel})
            else
                dealershipStock = formatVehicleStock(nearestDealership.data.stocks)
            end
        else
            dealershipStock = formatVehicleStock(nearestDealership.data.stocks)
        end

        if (type == 'npc' or type == 'marker') and not allowCatalog then
            if Custom and Custom.Notify then
                Custom.Notify("Este concesionario vende solo coches expuestos.", "error")
            end
            return
        end

        if not dealershipStock or not next(dealershipStock) then
            Custom.Notify(locale('notifications.no_vehicles_available'), "error")
            return
        end

        if type == 'exhibitor' and targetModel then
            local selectedVehicle = nil
            local selectedCategory = nil
            for categoryId, categoryData in pairs(dealershipStock) do
                if categoryData and categoryData.categoryStock then
                    for _, vehicleInfo in ipairs(categoryData.categoryStock) do
                        if vehicleInfo.model == targetModel then
                            selectedVehicle = vehicleInfo
                            selectedCategory = categoryId
                            break
                        end
                    end
                end
                if selectedVehicle then break end
            end

            if not selectedVehicle then
                Custom.Notify(locale('notifications.no_vehicles_available'), "error")
                return
            end

            local stats = getVehicleStatsByModel(targetModel)
            currentInteractionContext = {
                type = type,
                allowPurchase = exhibitorAllowPurchase,
                allowTestDrive = exhibitorAllowTestDrive,
                exhibitorId = (type == 'exhibitor' and entityData.exhibitorId) or nil
            }

            SendNUIMessage({
                action = "openDealership",
                dealershipMenu = {
                    visible = true,
                    dealershipStock = dealershipStock,
                    dealershipInfo = {
                        id = nearestDealership.id,
                        name = nearestDealership.data.name or "Concesionario",
                        type = nearestDealership.data.type or "dealership",
                        interactionType = type,
                        liveInspect = true,
                        allowCatalog = (#allowedVehicles > 1),
                        focusVehicleModel = targetModel,
                        selectedCategory = selectedCategory,
                        selectedVehicle = selectedVehicle,
                        currentVehicleStats = {
                            { label = 'Potencia', value = stats.power },
                            { label = 'Velocidad punta', value = stats.high_speed },
                            { label = 'Aceleración', value = stats.acceleration * 100 },
                            { label = 'Frenado', value = stats.braking * 100 }
                        },
                        exhibitorAccess = {
                            allowPurchase = exhibitorAllowPurchase,
                            allowTestDrive = exhibitorAllowTestDrive
                        },
                        updateTime = clientUpdateTime,
                        settings = nearestDealership.data.settings or {
                            allowTestDrive = true,
                            testDriveTime = 5,
                            allowCatalog = false
                        }
                    }
                }
            })

            SetNuiFocus(true, true)
            return
        end

        HudFadeOut(350)
        setupCameras(nearestDealership, targetModel)
        currentInteractionContext = {
            type = type,
            allowPurchase = exhibitorAllowPurchase,
            allowTestDrive = exhibitorAllowTestDrive,
            exhibitorId = (type == 'exhibitor' and entityData.exhibitorId) or nil
        }
        
        local totalCategories = 0
        local totalVehicles = 0
        for categoryId, categoryData in pairs(dealershipStock) do
            totalCategories = totalCategories + 1
            totalVehicles = totalVehicles + #categoryData.categoryStock
        end

        SendNUIMessage({
            action = "openDealership",
            dealershipMenu = {
                visible = true,
                dealershipStock = dealershipStock,
                dealershipInfo = {
                    id = nearestDealership.id,
                    name = nearestDealership.data.name or "Concesionario",
                    type = nearestDealership.data.type or "dealership",
                    interactionType = type,
                    allowCatalog = allowCatalog,
                    focusVehicleModel = targetModel,
                    exhibitorAccess = {
                        allowPurchase = exhibitorAllowPurchase,
                        allowTestDrive = exhibitorAllowTestDrive
                    },
                    updateTime = clientUpdateTime,
                    settings = nearestDealership.data.settings or {
                        allowTestDrive = true,
                        testDriveTime = 5,
                        allowCatalog = true
                    }
                }
            }
        })

        SetNuiFocus(true, true)

        -- Red: el único HudFadeIn de esta apertura está en previewReady. Si la
        -- NUI no llega a mandarlo (no cargó la vista previa, la llamada petó...)
        -- la pantalla se queda en negro con el cursor encima. A los 3 s se quita
        -- el negro igualmente; la apertura evita que una vieja toque a la nueva.
        aperturaPreview = aperturaPreview + 1
        previewListo = false
        local estaApertura = aperturaPreview
        SetTimeout(3000, function()
            if not previewListo and aperturaPreview == estaApertura then
                HudFadeIn(420)
            end
        end)
    end
end

RegisterNUICallback('origen_dealerships:ui:previewReady', function(_, cb)
    if onDealership then
        previewListo = true
        HudFadeIn(420)
    end
    cb('ok')
end)

RegisterNUICallback('origen_dealerships:ui:changePrimary', function(data, cb)
    local r, g, b = data.r, data.g, data.b
    local veh = previewVehicle
    
    if DoesEntityExist(veh) then
        vehicleColors.primary = {r = r, g = g, b = b}
        SetVehicleCustomPrimaryColour(veh, r, g, b)
        cb('ok')
    else
        cb('error')
    end
end)

RegisterNUICallback('origen_dealerships:ui:changeSecondary', function(data, cb)
    local r, g, b = data.r, data.g, data.b
    local veh = previewVehicle
    
    if DoesEntityExist(veh) then
        vehicleColors.secondary = {r = r, g = g, b = b}
        SetVehicleCustomSecondaryColour(veh, r, g, b)
        cb('ok')
    else
        cb('error')
    end
end)

RegisterNetEvent('origen_dealerships:updateAll', function(newDealershipsData, updateTime)
    clearAllElements()
    dealershipsData = newDealershipsData
    clientUpdateTime = updateTime
    
end)

-- Función para forzar recarga de todos los elementos visuales
local function forceReloadAllElements()
    -- Obtener lista de concesionarios cargados actualmente
    local loadedDealerships = {}
    for dealershipId, _ in pairs(loadedElements.zones) do
        loadedDealerships[dealershipId] = true
    end
    
    -- Descargar todos los elementos actuales
    clearAllElements()
    
    -- Recargar concesionarios que estaban cargados
    for dealershipId, _ in pairs(loadedDealerships) do
        local dealershipData = dealershipsData[dealershipId]
        if dealershipData then
            loadDealership(dealershipId, dealershipData)
        end
    end
end

RegisterNetEvent('origen_dealerships:receiveData', function(dealerships, updateTime)
    local oldData = dealershipsData

    --[[ Un concesionario borrado en el panel tiene que irse tambien del mapa.
         Con blips esto lo hacia el RemoveBlip de la descarga; con puntos
         registrados hay que decirlo, porque un punto se queda puesto a
         proposito aunque el concesionario no este cargado. ]]
    for dealershipId in pairs(oldData) do
        if not dealerships[dealershipId] then
            OrigenMapa.Quitar('concesionario_' .. tostring(dealershipId))
        end
    end

    dealershipsData = dealerships
    clientUpdateTime = updateTime
    
    if next(oldData) then
        forceReloadAllElements()
    end
end)

--[[ El panel de administracion ha cambiado como se marca un concesionario.

     Antes esto repintaba el blip del juego; ahora vuelve a registrar el punto
     en origen_map, que es donde lo leen los tres mapas. Es el mismo evento y
     el mismo boton del panel: lo unico que cambia es donde acaba el cambio. ]]
RegisterNetEvent('origen_dealerships:updateBlips', function()
    for dealershipId, dealershipData in pairs(dealershipsData) do
        local zone = loadedElements.zones[dealershipId]
        if zone and zone.blip and zone.coords then
            marcarConcesionario(dealershipId, dealershipData, zone.coords)
        end
    end
end)

local testDriveVehicle = false
RegisterNUICallback('origen_dealerships:ui:testDriveVehicle', function(data,cb)
    if currentInteractionContext.type == 'exhibitor' and currentInteractionContext.allowTestDrive == false then
        cb({
            success = false,
            message = 'La prueba de manejo esta desactivada para este exhibidor'
        })
        return
    end

    -- Concesionario VIP: sin el rol de Discord tampoco hay prueba (server/vip.lua).
    local prueba = lib.callback.await('origen_dealerships:sv:puedeProbar', false, data and data.dealershipId)
    if not prueba or not prueba.ok then
        cb({ success = false, message = (prueba and prueba.mensaje) or 'No puedes probar este coche.' })
        return
    end

    local coords = GetEntityCoords(cache.ped)
    local dealership = nil
    if data and data.dealershipId and dealershipsData[data.dealershipId] then
        dealership = {
            id = data.dealershipId,
            data = dealershipsData[data.dealershipId]
        }
    else
        dealership = getNearestDealership()
    end
    if not dealership then
        cb(false)
        return
    end
    local testDriveCoords = nil
    if dealership.data.markers.car_testdrive then
        for _, coords in ipairs(dealership.data.markers.car_testdrive) do
            local vehicleInArea = GetClosestVehicle(coords.x, coords.y, coords.z, 3.0, 0, 71)
            if vehicleInArea == 0 or not DoesEntityExist(vehicleInArea) then
                testDriveCoords = coords
                break
            end
        end
    end

    if not testDriveCoords then
        Custom.Notify('No hay puntos de prueba de manejo libres. Espera a que se libere alguno.', 'error')
        cb({
            success = false,
            message = 'Todos los puntos de prueba están ocupados'
        })
        return
    end

    local routingBucket = lib.callback.await('origen_dealership:routingBucketHandler', false, true)
    if not routingBucket then
        cb(false)
        return
    end

    if testDriveVehicle and DoesEntityExist(testDriveVehicle) then
        SetEntityAsMissionEntity(testDriveVehicle, true, true)
        DeleteVehicle(testDriveVehicle)
        testDriveVehicle = false
    end

    local model = GetHashKey(data.model)

    RequestModel(model)

    local timeout = 0

    while not HasModelLoaded(model) and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end

    -- Sin coche no hay prueba: se devuelve la instancia que se acaba de
    -- pedir, o el jugador se quedaba solo en su mundo hasta reconectar.
    if not HasModelLoaded(model) then
        lib.callback.await('origen_dealership:routingBucketHandler', false)
        cb(false)
        return
    end

    -- El punto de test drive ya fue verificado al inicio

    testDriveVehicle = CreateVehicle(model, testDriveCoords.x, testDriveCoords.y, testDriveCoords.z, testDriveCoords.heading, false, false)
    DoScreenFadeOut(500)

    if not DoesEntityExist(testDriveVehicle) then
        SetModelAsNoLongerNeeded(model)
        lib.callback.await('origen_dealership:routingBucketHandler', false)
        DoScreenFadeIn(2000)
        cb(false)
        return
    end
    SetModelAsNoLongerNeeded(model)
    SetEntityAsMissionEntity(testDriveVehicle, true, true)
    SetVehicleOnGroundProperly(testDriveVehicle)
    SetVehicleNumberPlateText(testDriveVehicle, Config.TestDrive.plate)
    TaskWarpPedIntoVehicle(cache.ped, testDriveVehicle, -1)
    SetVehicleEngineOn(testDriveVehicle, true, true, false)
    SetVehicleUndriveable(testDriveVehicle, false)
    -- Cada color por separado, como en la compra: el que no se tocó se queda
    -- de fábrica. Antes, con uno solo elegido, los dos salían blancos y además
    -- se apuntaba el blanco en vehicleColors, así que la compra de después
    -- también salía blanca.
    if vehicleColors.primary then
        SetVehicleCustomPrimaryColour(testDriveVehicle, vehicleColors.primary.r, vehicleColors.primary.g, vehicleColors.primary.b)
    end
    if vehicleColors.secondary then
        SetVehicleCustomSecondaryColour(testDriveVehicle, vehicleColors.secondary.r, vehicleColors.secondary.g, vehicleColors.secondary.b)
    end
    SetVehicleDirtLevel(testDriveVehicle,0.0)
    DoScreenFadeIn(100)

    TriggerServerEvent('origen_dealerships:sv:testDriveStarted', {
        dealershipId = dealership.data.id,
        dealershipName = dealership.data.name,
        vehicleModel = data.model,
        vehicleLabel = data.label,
        duration = dealership.data.settings and dealership.data.settings.testDriveTime or 5
    })

    CreateThread(function()
        while testDriveVehicle and DoesEntityExist(testDriveVehicle) do
            Wait(500)
            if not IsPedInVehicle(cache.ped, testDriveVehicle, false) then
                SetEntityAsMissionEntity(testDriveVehicle, true, true)
                DeleteVehicle(testDriveVehicle)
                testDriveVehicle = false
                DoScreenFadeOut(500)
                
                SendNUIMessage({
                action = "closeTestDrive",
                })
                
                Wait(500)
                SetEntityCoords(cache.ped, coords.x, coords.y, coords.z)
                Wait(1000)
                DoScreenFadeIn(1000)
                if Custom and Custom.Notify then
                    Custom.Notify(locale('notifications.test_drive_cancelled'), "error")
                end
                
                TriggerServerEvent('origen_dealerships:sv:testDriveEnded', {
                    dealershipId = dealership.data.id,
                    dealershipName = dealership.data.name,
                    vehicleModel = data.model,
                    vehicleLabel = data.label,
                    status = 'cancelled'
                })
                
                lib.callback.await('origen_dealership:routingBucketHandler', false)
                break
            end
        end
    end)

    local testDriveTime = (dealership.data.settings and dealership.data.settings.testDriveTime or 5) * 60 * 1000
    -- El temporizador mira SU coche, no la global: si esta prueba se cancelaba
    -- y empezaba otra, al cumplirse el tiempo de la primera se cortaba la segunda.
    local cocheDeEstaPrueba = testDriveVehicle
    SetTimeout(testDriveTime,function()
        if testDriveVehicle == cocheDeEstaPrueba and DoesEntityExist(testDriveVehicle) then
            DoScreenFadeOut(0)
            Wait(500)
            SetEntityAsMissionEntity(testDriveVehicle, true, true)
            DeleteVehicle(testDriveVehicle)
            testDriveVehicle = false
            SetEntityCoords(cache.ped, coords.x, coords.y, coords.z)
            Wait(2000)
            DoScreenFadeIn(2000)
            if Custom and Custom.Notify then
                Custom.Notify(locale('notifications.test_drive_finished'), "success")
            end
            SendNUIMessage({
                action = "closeTestDrive",
            })
            
            TriggerServerEvent('origen_dealerships:sv:testDriveEnded', {
                dealershipId = dealership.data.id,
                dealershipName = dealership.data.name,
                vehicleModel = data.model,
                vehicleLabel = data.label,
                status = 'completed'
            })
            
            lib.callback.await('origen_dealership:routingBucketHandler', false)
        end
        
    end)
    cb({
        success = true,
        timer = testDriveTime
    })
end)

-- La compra al contado. Va aparte para llamarla con pcall desde el callback de
-- abajo: aquí `cb` solo apunta la respuesta, y es el callback el que la manda.
local function comprarVehiculo(data, cb)
    if currentInteractionContext.type == 'exhibitor' and currentInteractionContext.allowPurchase == false then
        return cb({
            success = false,
            message = 'La compra esta desactivada para este exhibidor'
        })
    end
    
    local dealership = nil
    if data and data.dealershipId and dealershipsData[data.dealershipId] then
        dealership = {
            id = data.dealershipId,
            data = dealershipsData[data.dealershipId]
        }
    else
        dealership = getNearestDealership()
    end
    
    if not dealership then
        cb(false)
        return
    end
    local purchaseCoords = nil
    if dealership.data.markers.car_delivery then
        for _, coords in ipairs(dealership.data.markers.car_delivery) do
            local vehicleInArea = GetClosestVehicle(coords.x, coords.y, coords.z, 3.0, 0, 71)
            if vehicleInArea == 0 or not DoesEntityExist(vehicleInArea) then
                purchaseCoords = coords
                break
            end
        end
    end
    -- Lo que puede impedir entregar el coche se mira ANTES de cobrar. Antes el
    -- servidor cobraba, restaba stock y daba los papeles, y luego aquí se veía
    -- que el punto de entrega estaba ocupado: dinero fuera y ningún coche.
    if Config.VehiclePurchase.spawnVehicle and not purchaseCoords then
        return cb({
            success = false,
            message = 'Todos los puntos de entrega están ocupados. Espera a que se libere alguno.'
        })
    end

    local hash = GetHashKey(data.vehicleModel)
    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then
        return cb({
            success = false,
            message = locale('notifications.error_loading_vehicle')
        })
    end

    local dataResult = lib.callback.await('origen_dealerships:sv:purchaseVehicle', false, data)


    if dataResult and dataResult.success then
        if not dataResult.plate then
            SetNuiFocus(false, false)
            local errorMsg = dataResult.error or "Error desconocido"
            Custom.Notify(locale('notifications.error_purchasing_vehicle') .. ': ' .. errorMsg, 'error')
            return cb(
                {
                    success = false,
                    message = 'Error al comprar el vehículo: ' .. errorMsg
                }
            )
        end

        SetNuiFocus(false, false)

        DoScreenFadeOut(500)
        Wait(500)
        Custom.Notify(locale('notifications.vehicle_purchased'), 'success')

        -- La NUI ya no cierra el concesionario antes de comprar (así una compra
        -- fallida deja la vista previa como estaba): se recoge aquí, y el
        -- routing bucket se devuelve ANTES de sacar el coche, que si no nace en
        -- la instancia privada de la vista previa y el jugador no lo ve.
        -- cleanupPreviewCamera vacía vehicleColors: se guardan antes los tonos elegidos.
        local colores = { primary = vehicleColors.primary, secondary = vehicleColors.secondary }
        cleanupPreviewCamera()
        lib.callback.await('origen_dealership:routingBucketHandler', false)

        RequestModel(hash)
        local timeout = 0
        while not HasModelLoaded(hash) and timeout < 50 do
            Wait(100)
            timeout = timeout + 1
        end
        local plate = dataResult.plate

        -- Ya está pagado: si el coche no se puede sacar aquí (el modelo no
        -- carga, alguien ocupó el punto en este medio segundo, CreateVehicle
        -- falla), se da de alta igual y queda en el garaje.
        local purchasedVehicle = nil
        if Config.VehiclePurchase.spawnVehicle and HasModelLoaded(hash) then
            local vehicleInArea = GetClosestVehicle(purchaseCoords.x, purchaseCoords.y, purchaseCoords.z, 3.0, 0, 71)
            if vehicleInArea == 0 or not DoesEntityExist(vehicleInArea) then
                purchasedVehicle = CreateVehicle(hash, purchaseCoords.x, purchaseCoords.y, purchaseCoords.z, purchaseCoords.heading, true, false)
            end
        end

        if Config.VehiclePurchase.spawnVehicle and not (purchasedVehicle and DoesEntityExist(purchasedVehicle)) then
            SetModelAsNoLongerNeeded(hash)
            local dbResult = lib.callback.await('origen_dealerships:sv:addVehicleToDatabase', false, {
                vehicleModel = data.vehicleModel,
                plate = plate
            })
            if dbResult and dbResult.success then
                Custom.Notify('No se pudo sacar el coche aquí: lo tienes en el garaje.', 'error')
            else
                Custom.Notify(locale('notifications.error_creating_vehicle'), 'error')
            end
            DoScreenFadeIn(2000)
            return cb({
                success = true,
                message = 'Vehículo comprado con éxito'
            })
        end

        if Config.VehiclePurchase.spawnVehicle then

            SetModelAsNoLongerNeeded(hash)
            SetVehicleOnGroundProperly(purchasedVehicle)
            SetVehicleNumberPlateText(purchasedVehicle, plate)
            SetEntityAsMissionEntity(purchasedVehicle, true, true)
            TaskWarpPedIntoVehicle(cache.ped, purchasedVehicle, -1)
            SetVehicleEngineOn(purchasedVehicle, true, true, false)
            SetVehicleUndriveable(purchasedVehicle, false)
            SetVehicleDirtLevel(purchasedVehicle, 0.0)

            -- Cada color por separado: con un solo tono pulsado, next() daba
            -- verdadero y el otro .r petaba con la pantalla en negro. El que no
            -- se tocó se queda de fábrica, que es como se veía en la vista previa.
            if colores.primary then
                SetVehicleCustomPrimaryColour(purchasedVehicle, colores.primary.r, colores.primary.g, colores.primary.b)
            end
            if colores.secondary then
                SetVehicleCustomSecondaryColour(purchasedVehicle, colores.secondary.r, colores.secondary.g, colores.secondary.b)
            end
            
            -- Esperar un momento para que el vehículo se inicialice completamente
            Wait(200)
            
            -- Obtener propiedades del vehículo para guardar en la base de datos
            local props = Custom.GetVehicleProps(purchasedVehicle)

            TriggerEvent('vehiclekeys:client:SetOwner', GetVehicleNumberPlateText(purchasedVehicle))
            
            -- Agregar el vehículo a la base de datos en el servidor
            local dbResult = lib.callback.await('origen_dealerships:sv:addVehicleToDatabase', false, {
                vehicleModel = data.vehicleModel,
                plate = plate,
                props = props
            })
            
            if Config.Debug then
                print('^2[ORIGEN DEALERSHIPS] ^7Resultado DB:', json.encode(dbResult))
            end
            
            -- Dar llaves si está configurado
            if Config.VehiclePurchase.giveKeysOnPurchase then
                Custom.GiveKeys(purchasedVehicle, plate)
            end

            -- Eliminar camara 
            cleanupPreviewCamera()
        else
            -- Solo guardar en la base de datos sin spawnear
            SetModelAsNoLongerNeeded(hash)
            
            -- Crear propiedades básicas para la base de datos
            local props = {
                model = GetHashKey(data.vehicleModel),
                plate = plate,
                bodyHealth = 1000.0,
                engineHealth = 1000.0,
                fuelLevel = 100.0,
                dirtLevel = 0.0,
                color1 = data.primaryColor,
                color2 = data.secondaryColor
            }
            
            -- Agregar el vehículo a la base de datos en el servidor
            local dbResult = lib.callback.await('origen_dealerships:sv:addVehicleToDatabase', false, {
                vehicleModel = data.vehicleModel,
                plate = plate,
                props = props
            })
            
            if Config.Debug then
                print('^2[ORIGEN DEALERSHIPS] ^7Resultado DB:', json.encode(dbResult))
            end
        end
        DoScreenFadeIn(2000)

        return cb(
            {
                success = true,
                message = 'Vehículo comprado con éxito'
            }
        )
    else
        local errorMsg = dataResult and dataResult.error or locale('errors.general')
        Custom.Notify(locale('notifications.error_purchasing_vehicle') .. ': ' .. errorMsg, 'error')

        -- La vista previa sigue en pie: antes la NUI la cerraba antes de
        -- comprar y aquí se volvía a montar, y desde un exhibidor eso mandaba
        -- al jugador a la sala de la vista previa.
        return cb(
            {
                success = false,
                message = errorMsg
            }
        )
    end
end

RegisterNUICallback('origen_dealerships:ui:purchaseVehicle', function(data, cb)
    local respuesta
    local ok, err = pcall(comprarVehiculo, data, function(r) respuesta = r end)
    if not ok then
        print('^1[ORIGEN DEALERSHIPS] ^7Fallo en la compra del vehículo:', tostring(err))
    end

    -- Salida común: si algo petó (o salió antes) con el fundido a negro puesto,
    -- se quita; y la NUI siempre recibe respuesta, o su promesa se queda colgada.
    if IsScreenFadedOut() or IsScreenFadingOut() then
        DoScreenFadeIn(2000)
    end

    cb(respuesta or {
        success = false,
        message = 'Error al comprar el vehículo'
    })
end)

--[[ Sondeo de cambios del panel de concesionarios, cada 30 s.

     NO volver a capar esto con `if next(dealershipsData) then`. Estaba asi, y
     un concesionario recien creado no le llegaba nunca a quien todavia no
     tenia ninguno. Para taparlo, el servidor mandaba la cache entera a TODOS
     los jugadores con un TriggerClientEvent(-1): 127 KB por cabeza, 25 MB de
     golpe con 200 personas, y la gente se caia por timeout (ver el comentario
     de repartirConcesionarios en server/main.lua).

     Sondear siempre no cuesta: cuando no hay novedad el servidor contesta con
     fullUpdate=false y una tabla vacia. Y como cada cliente arranca su hilo al
     conectarse, los sondeos van repartidos en el tiempo. ]]
CreateThread(function()
    while true do
        -- La espera va delante: la primera carga ya la hace el hilo de abajo
        -- al entrar. Si sondearamos nada mas arrancar, cada jugador que entra
        -- se traeria los datos dos veces.
        Wait(30000)

        local success, response = pcall(function()
            return lib.callback.await('origen_dealerships:getDealershipsData', false, clientUpdateTime)
        end)

        if success and response and response.fullUpdate and response.dealerships then
            local oldData = dealershipsData
            dealershipsData = response.dealerships
            clientUpdateTime = response.updateTime

            -- Esto solo repinta lo que ya estaba cargado. De los concesionarios
            -- nuevos se encarga el hilo de proximidad, que recorre
            -- dealershipsData y los carga al acercarse.
            if next(oldData) then
                forceReloadAllElements()
            end
        end
    end
end)

CreateThread(function()
    while not cache.ped or cache.ped == 0 do
        Wait(100)
    end
    
    Wait(1000)
    
    local success, response = pcall(function()
        return lib.callback.await('origen_dealerships:getDealershipsData', false, 0)
    end)
    
    if success and response and response.dealerships then
        dealershipsData = response.dealerships
        clientUpdateTime = response.updateTime or GetGameTimer()
    else
        Wait(1000)
        TriggerServerEvent('origen_dealerships:requestInitialData')
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        -- eliminar NPCs creados
        for _, ped in ipairs(createdNPCS) do
            if DoesEntityExist(ped) then
                DeletePed(ped)
            end
        end

        for _, exhibitor in pairs(loadedElements.exhibitors or {}) do
            if exhibitor and exhibitor.vehicle and DoesEntityExist(exhibitor.vehicle) then
                DeleteEntity(exhibitor.vehicle)
            end
        end

        if previewVehicle and DoesEntityExist(previewVehicle) then
            DeleteEntity(previewVehicle)
        end

        if testDriveVehicle and DoesEntityExist(testDriveVehicle) then
            DeleteEntity(testDriveVehicle)
        end

        -- Si se para con el catálogo abierto, la NUI desaparece pero el foco,
        -- la cámara y el negro se quedaban. El HUD solo se toca si estábamos en
        -- la vista previa, que es cuando lo bajamos nosotros con HudFadeOut.
        -- El routing bucket no se devuelve aquí: pedirlo al servidor exige un
        -- callback de este mismo recurso, que también se está parando.
        local enVistaPrevia = onDealership
        SetNuiFocus(false, false)
        cleanupPreviewCamera()
        if CleanupPreviews then
            CleanupPreviews()
        end
        if enVistaPrevia then
            HudFadeIn(0)
        end
        if IsScreenFadedOut() or IsScreenFadingOut() then
            DoScreenFadeIn(500)
        end
    end
end)

--[[ Si el vigilante comun (@origen_map/shared/foco.lua) suelta el raton a la
     fuerza, se hace lo mismo que el cierre normal (callback 'close' de
     main.lua): la pagina se esconde, la camara y el coche de la vista previa
     fuera, el HUD de vuelta y fuera de la instancia. Sin esto se quedaba el
     catalogo pintado sin raton, con la camara clavada en el garaje y el
     jugador solo en su mundo. La instancia NO se toca con una prueba en
     marcha: esa la devuelve la propia prueba al acabar. ]]
if OrigenFoco then
    OrigenFoco.AlSoltar(function()
        SendNUIMessage({ action = 'forceClose' })

        local enVistaPrevia = onDealership or previewCamera ~= nil
        if not enVistaPrevia then return end

        cleanupPreviewCamera()
        pcall(HudFadeIn, 0)
        if IsScreenFadedOut() or IsScreenFadingOut() then
            DoScreenFadeIn(500)
        end

        if _G.DealershipHubIntegration then
            _G.DealershipHubIntegration.openedFromHub = false
        end

        if not (testDriveVehicle and DoesEntityExist(testDriveVehicle)) then
            CreateThread(function()
                lib.callback.await('origen_dealership:routingBucketHandler', false)
            end)
        end
    end)
end