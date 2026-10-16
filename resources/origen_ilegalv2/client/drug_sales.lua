if not Config.DrugSales or not Config.DrugSales.Enable then
    return
end

local DrugSaleManager = {
    isActive = false,
    startCoords = nil,
    customers = {},
    activeCustomers = {},
    customerCount = 0,
    lastSaleTime = 0
}

local function GetPlayerItemCount(itemName)
    if not itemName or itemName == '' then return 0 end

    -- Prefer inventory bridge: this keeps compatibility with qbx/ox/origen_inventory.
    if Inventory and Inventory.GetItemCount then
        local ok, count = pcall(Inventory.GetItemCount, itemName)
        if ok and type(count) == 'number' then
            return count
        end
    end

    -- Fallback for frameworks that still expose item counts client-side.
    if Framework and Framework.GetItemCount then
        local ok, count = pcall(Framework.GetItemCount, itemName)
        if ok and type(count) == 'number' then
            return count
        end
    end

    -- Fallback for frameworks/inventories that expose only player inventory tables.
    if Framework and Framework.GetPlayerInventory then
        local ok, inventory = pcall(Framework.GetPlayerInventory)
        if ok and type(inventory) == 'table' then
            local total = 0
            for key, entry in pairs(inventory) do
                local item = entry
                if type(entry) ~= 'table' and type(key) == 'string' then
                    item = inventory[key]
                end
                if type(item) == 'table' and item.name == itemName then
                    local itemCount = tonumber(item.amount or item.count or 0) or 0
                    total = total + itemCount
                end
            end
            if total > 0 then
                return total
            end
        end
    end

    -- Last-resort fallback: some bridges expose only HasItem on client side.
    if Inventory and Inventory.HasItem then
        local ok, hasItem = pcall(Inventory.HasItem, itemName, 1)
        if ok and hasItem then
            return 1
        end
    end

    return 0
end

function DrugSaleManager:new()
    local obj = {}
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function DrugSaleManager:startSale()
    if self.isActive then
        Notify.SendNotify(locale:t('notify.drug_sale_active'), 'error')
        return false
    end

    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    if IsPedInAnyVehicle(playerPed, false) then
        Notify.SendNotify(locale:t('notify.cannot_sell_from_vehicle'), 'error')
        return false
    end

    local canSell, errorMessage = self:checkRequirements()
    if not canSell then
        Notify.SendNotify(errorMessage, 'error')
        return false
    end
    
    if self:isInBlacklistedZone(playerCoords) then
        Notify.SendNotify(locale:t('notify.drug_sale_blacklisted_zone'), 'error')
        return false
    end

    if self.lastSaleTime > 0 and (GetGameTimer() - self.lastSaleTime) < 60000 then
        local distance = #(playerCoords - self.startCoords)
        if distance < Config.DrugSales.MinDistanceBetweenSales then
            Notify.SendNotify(locale:t('notify.drug_sale_wait_cooldown'), 'error')
            return false
        end
    end

    self:playPhoneAnimation()

    self.isActive = true
    self.startCoords = playerCoords
    self.customerCount = 0
    self.customers = {}
    self.activeCustomers = {}

    Notify.SendNotify(locale:t('notify.drug_sale_started'), 'success')

    self:startCustomerSystem()
    
    return true
end

function DrugSaleManager:stopSale()
    if not self.isActive then
        Notify.SendNotify(locale:t('notify.drug_sale_no_active'), 'error')
        return false
    end

    self.isActive = false
    self:cleanupCustomers()
    self.startCoords = nil
    self.customerCount = 0
    self.customers = {}
    self.activeCustomers = {}

    if _G.StreetSaleManager then _G.StreetSaleManager.zoneActive = false end
    Notify.SendNotify(locale:t('notify.drug_sale_ended'), 'info')

    return true
end

function DrugSaleManager:checkRequirements()
    local policeCount = lib.callback.await('origen_gang:drugSales:getPoliceCount', false)
    
    if policeCount < Config.DrugSales.CopRequired then
        return false, locale:t('notify.drug_sale_not_enough_police', policeCount, Config.DrugSales.CopRequired)
    end
    
    return true
end

function DrugSaleManager:startCustomerSystem()
    CreateThread(function()
        while self.isActive do
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local distance = #(playerCoords - self.startCoords)
            
            if distance > Config.DrugSales.SaleRadius then
                Notify.SendNotify(locale:t('notify.drug_sale_too_far'), 'error')
                self:stopSale()
                break
            end

            if IsPedDeadOrDying(playerPed, true) then
                Notify.SendNotify(locale:t('notify.drug_sale_cancelled'), 'error')
                self:stopSale()
                break
            end

            self:cleanupDeadCustomers()

            local activeCustomerCount = #self.activeCustomers
            if activeCustomerCount < Config.DrugSales.MaxSimultaneousCustomers and self.customerCount < Config.DrugSales.MaxCustomer then
                local spawnTime = math.random(Config.DrugSales.CustomerSpawnTime.min, Config.DrugSales.CustomerSpawnTime.max)
                Wait(spawnTime * 1000)
                
                if self.isActive then
                    self:spawnCustomer()
                end
            end

            Wait(5000)
        end
    end)
end

function DrugSaleManager:spawnCustomer()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local spawnPoint = self:findSpawnPoint(playerCoords)
    
    if not spawnPoint then
        return
    end

    local pedModel = Config.DrugSales.CustomerPeds[math.random(1, #Config.DrugSales.CustomerPeds)]
    local hash = GetHashKey(pedModel)
    
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(1)
    end

    local customer = CreatePed(4, hash, spawnPoint.x, spawnPoint.y, spawnPoint.z, 0.0, true, true)
    SetEntityAsMissionEntity(customer, true, true)
    SetPedCanRagdoll(customer, false)
    SetPedCanBeTargetted(customer, false)
    SetEntityInvincible(customer, true)

    --[[ El cliente, en el mapa.

         Ya no es un blip del juego: es un punto de origen_map con `entidad`,
         que es lo que hace que siga al ped mientras camina —lo que antes hacia
         el blip de entidad— y que se borre solo cuando el ped desaparece.

         El interruptor del panel sigue mandando; el sprite y el color, no:
         aqui la chincheta es dibujo nuestro. ]]
    local blip = nil
    if Config.DrugSales.BlipSettings.enable ~= false then
        blip = 'cliente_' .. tostring(customer)

        OrigenMapa.Poner(blip, {
            entidad = customer,
            cat = 'illegal',
            icono = 'persona',
            nombre = 'Cliente',
        })
    end

    local customerData = {
        ped = customer,
        blip = blip,
        coords = spawnPoint,
        startTime = GetGameTimer(),
        isMoving = false,
        hasReachedPlayer = false,
        id = self.customerCount + 1,
        waitingMessage = self:getRandomMessage('waiting') or "Esperando turno...",
        lastMessageUpdate = GetGameTimer()
    }

    table.insert(self.activeCustomers, customerData)
    self.customerCount = self.customerCount + 1

    Notify.SendNotify(locale:t('notify.drug_sale_customer_coming'), 'info')

    self:startCustomerMovement(customerData)
    self:startCustomerInteraction(customerData)
end

function DrugSaleManager:startCustomerMovement(customer)
    CreateThread(function()
        if not customer then return end
        
        customer.isMoving = true
        
        while self.isActive and customer and DoesEntityExist(customer.ped) and not customer.hasReachedPlayer do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local customerCoords = GetEntityCoords(customer.ped)
            local distance = #(playerCoords - customerCoords)
            
            local distanceFromStart = #(playerCoords - self.startCoords)
            if distanceFromStart > Config.DrugSales.SaleRadius then
                self:makeCustomerRunAway(customer)
                break
            end
            
            if customer.isEscaping then
                break
            end
            
            if distance <= 1.8 then
                customer.hasReachedPlayer = true
                customer.isMoving = false
                ClearPedTasksImmediately(customer.ped)
                -- Posicionamiento preciso: mismo offset que la animación
                local playerPed2   = PlayerPedId()
                local ph           = GetEntityHeading(playerPed2)
                local destPos2     = GetOffsetFromEntityInWorldCoords(playerPed2, 0.0, 1.1, 0.0)
                local arrHead2     = (ph + 180.0) % 360.0
                SetEntityCoordsNoOffset(customer.ped, destPos2.x, destPos2.y, destPos2.z, false, false, false)
                SetEntityHeading(customer.ped, arrHead2)
                SetBlockingOfNonTemporaryEvents(customer.ped, true)
                TaskStandStill(customer.ped, 60000)
                Wait(400)
                FreezeEntityPosition(customer.ped, true)
                break
            else
                TaskGoToEntity(customer.ped, PlayerPedId(), -1, 1.0, 1.5, 1073741824, 0)
            end
            
            Wait(1000)
        end
    end)
end

function DrugSaleManager:startCustomerInteraction(customer)
    CreateThread(function()
        if not customer then return end
        
        local interactionTime = Config.DrugSales.CustomerInteractionTime * 1000
        local startTime = GetGameTimer()
        local interactionStarted = false

        while self.isActive and customer and DoesEntityExist(customer.ped) do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local customerCoords = GetEntityCoords(customer.ped)
            local distance = #(playerCoords - customerCoords)

            local distanceFromStart = #(playerCoords - self.startCoords)
            if distanceFromStart > Config.DrugSales.SaleRadius then
                self:makeCustomerRunAway(customer)
                break
            end

            if customer.isEscaping then
                break
            end

            if customer.hasReachedPlayer and not interactionStarted then
                interactionStarted = true
                -- Auto-trigger: el NPC ya está en posición, lanzar venta directamente
                if OrigenFoco and OrigenFoco.Tiene() then
                    --[[ Otro panel de este recurso delante (tienda, crafting,
                         garaje, portatil del lab). La tarjeta se abriria encima,
                         al cerrar uno se soltaba el foco de los dos y el otro se
                         quedaba pintado sin raton, con el jugador congelado.
                         Se espera: si no se cierra a tiempo, el cliente se va. ]]
                    interactionStarted = false
                elseif self:isClosestCustomer(customer) then
                    self:initiateSale(customer)
                else
                    -- Otro cliente esperando turno — mostrar mensaje y esperar
                    if Config.DrugSales.CustomerPriority.showWaitingMessages then
                        local customerCoords = GetEntityCoords(customer.ped)
                        self:DrawText3D(customerCoords.x, customerCoords.y, customerCoords.z + 1.0, customer.waitingMessage or 'Esperando turno...')
                    end
                    interactionStarted = false  -- volver a intentar cuando sea el más cercano
                end
            end

            if (GetGameTimer() - startTime) > interactionTime then
                Notify.SendNotify(locale:t('notify.drug_sale_customer_left'), 'error')
                self:makeCustomerRunAway(customer)
                break
            end

            Wait(1000)
        end
    end)
end

function DrugSaleManager:initiateSale(customer)
    if not customer then return end
    if _G.StreetSaleManager and _G.StreetSaleManager.saleInProgress then return end
    -- Antes de congelar a nadie: con otro panel de este recurso delante no se
    -- abre la tarjeta (ver startCustomerInteraction).
    if OrigenFoco and OrigenFoco.Tiene() then return end

    local availableDrugs = self:getAvailableDrugs()
    if not availableDrugs or #availableDrugs == 0 then
        Notify.SendNotify(locale:t('notify.drug_sale_no_drugs'), 'error')
        FreezeEntityPosition(customer.ped, false)
        SetBlockingOfNonTemporaryEvents(customer.ped, false)
        self:makeCustomerRunAway(customer)
        return
    end

    local selectedDrug = availableDrugs[math.random(1, #availableDrugs)]
    local drugConfig   = Config.DrugSales.DrugList[selectedDrug]
    if not drugConfig then
        FreezeEntityPosition(customer.ped, false)
        SetBlockingOfNonTemporaryEvents(customer.ped, false)
        self:makeCustomerRunAway(customer)
        return
    end

    local playerPed    = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    -- Escalado por nivel (mismas fórmulas que street sale)
    local streetLevel    = (_G.StreetSaleManager and _G.StreetSaleManager.cachedLevel) or 0
    local t              = streetLevel / 100.0
    local rejectChance   = drugConfig.rejectChance ~= nil and drugConfig.rejectChance or math.floor(80 - t * 60)
    local policeChance   = drugConfig.policeChance ~= nil and drugConfig.policeChance or math.floor(70 - t * 50)
    local qtyMultiplier  = 0.3 + t * 0.7
    local priceMultiplier= (0.5 + t * 0.5) * (Config.DrugSales.StreetSale.PriceMultiplier or 1.0)

    -- Cantidad: siempre 1 a nivel 0, escala hasta el máximo configurado a nivel 100
    local qtyMax   = 1 + math.floor((drugConfig.quantity.max - 1) * t)
    qtyMax = math.max(1, math.min(drugConfig.quantity.max, qtyMax))
    -- Desde el minimo de la droga: el servidor rechaza la venta por debajo.
    local qtyMin   = math.max(1, math.min(tonumber(drugConfig.quantity.min) or 1, qtyMax))
    local quantity = math.random(qtyMin, qtyMax)
    local itemCount = GetPlayerItemCount(selectedDrug)
    quantity = math.min(quantity, itemCount or 1)

    local pricePerUnit = math.floor(math.random(drugConfig.price.min, drugConfig.price.max))
    local totalPrice   = pricePerUnit * quantity

    -- Rechazo con animación de teléfono
    if math.random(1, 100) <= rejectChance then
        local rejectMessage = self:getRandomMessage('rejected')
        self:showCustomerMessage(customer, rejectMessage, 3000)
        Notify.SendNotify(locale:t('notify.customer_rejected_police'), 'error')
        -- Animación teléfono del NPC
        local phoneCfg = Config.DrugSales.Animations and Config.DrugSales.Animations.phoneCall
        if phoneCfg and phoneCfg.enabled then
            local dict = "cellphone@"
            RequestAnimDict(dict)
            local tw = 0
            while not HasAnimDictLoaded(dict) and tw < 1500 do Wait(50) tw = tw + 50 end
            if HasAnimDictLoaded(dict) then
                FreezeEntityPosition(customer.ped, false)
                SetBlockingOfNonTemporaryEvents(customer.ped, true)
                TaskPlayAnim(customer.ped, dict, "cellphone_call_listen_base", 8.0, -8.0, phoneCfg.duration, 49, 0, false, false, false)
                Wait(phoneCfg.duration)
                ClearPedTasks(customer.ped)
            end
        end
        if math.random(1, 100) <= policeChance then
            local vehData = nil
            local lastVeh = GetVehiclePedIsIn(playerPed, true)
            if lastVeh and lastVeh ~= 0 and DoesEntityExist(lastVeh) and #(playerCoords - GetEntityCoords(lastVeh)) < 15.0 then
                vehData = lastVeh
            end
            Dispatch.SendAlert({
                coords         = playerCoords,
                title          = locale:t('notify.police_alert_title'),
                message        = locale:t('notify.police_alert_message'),
                type           = 'DRUGS',
                jobs           = {'police', 'sheriff', 'fib'},
                ignoreCooldown = true,
                vehicle        = vehData,
            })
        end
        FreezeEntityPosition(customer.ped, false)
        SetBlockingOfNonTemporaryEvents(customer.ped, false)
        self:makeCustomerRunAway(customer)
        return
    end

    -- Freezar al jugador
    FreezeEntityPosition(playerPed, true)
    Wait(50)
    playerCoords = GetEntityCoords(playerPed)

    -- Guardar pendingSale (compartido con los handlers de confirm/cancel en drug_street_sale.lua)
    if _G.StreetSaleManager then
        _G.StreetSaleManager.saleInProgress = true
        _G.StreetSaleManager.pendingSale = {
            drugName     = selectedDrug,
            quantity     = quantity,
            pricePerUnit = pricePerUnit,
            totalPrice   = totalPrice,
            nearestPed   = customer.ped,
            playerPed    = playerPed,
            playerCoords = playerCoords,
            policeChance = policeChance,
            streetLevel  = streetLevel,
            onDone       = function()
                self:makeCustomerRunAway(customer)
            end
        }
    end

    OpenEmbeddedQuickMenu({
        {
            header       = 'Venta — ' .. (drugConfig.label or selectedDrug),
            txt          = string.format('Reputación: %d/100', math.floor(streetLevel)),
            isMenuHeader = true,
            icon         = 'fa-solid fa-syringe'
        },
        {
            header = 'Vender',
            txt    = string.format('%dx  •  $%d c/u  •  Total: $%d', quantity, math.floor(pricePerUnit), math.floor(totalPrice)),
            icon   = 'fa-solid fa-hand-holding-dollar',
            params = { event = 'origen_gang:streetSale:confirm', args = {} }
        },
        {
            header = 'Cancelar',
            txt    = 'No vender',
            icon   = 'fa-solid fa-xmark',
            params = { event = 'origen_gang:streetSale:cancel', args = {} }
        }
    })
end

function DrugSaleManager:getAvailableDrugs()
    local availableDrugs = {}

    for drugName, drugConfig in pairs(Config.DrugSales.DrugList) do
        -- Drogas estáticas del config (sin flag) son vendibles por defecto
        local forSale = drugConfig.forSale ~= false
        if forSale then
            local count = GetPlayerItemCount(drugName)
            if count and count > 0 then
                table.insert(availableDrugs, drugName)
            end
        end
    end

    return availableDrugs
end

function DrugSaleManager:findSpawnPoint(playerCoords)
    local attempts = 0
    local maxAttempts = 50
    
    while attempts < maxAttempts do
        local angle = math.random(0, 360) * math.pi / 180
        local distance = math.random(40, 80)
        local x = playerCoords.x + math.cos(angle) * distance
        local y = playerCoords.y + math.sin(angle) * distance
        local z = playerCoords.z
        
        local ground, groundZ = GetGroundZFor_3dCoord(x, y, z, false)
        if ground then
            local spawnPoint = vector3(x, y, groundZ)
            
            if not self:isInBlacklistedZone(spawnPoint) then
                return spawnPoint
            end
        end
        
        attempts = attempts + 1
    end
    
    return nil
end

function DrugSaleManager:isInBlacklistedZone(coords)
    for _, zone in pairs(Config.DrugSales.BlacklistedZones) do
        local distance = #(coords - zone.coords)
        if distance < zone.radius then
            return true
        end
    end
    return false
end

function DrugSaleManager:makeCustomerRunAway(customer)
    if not customer or not DoesEntityExist(customer.ped) then
        self:removeCustomerFromActive(customer)
        return
    end

    if customer.isEscaping then
        return
    end

    if not Config.DrugSales.CustomerEscape.enabled then
        self:removeCustomerFromActive(customer)
        return
    end

    customer.isEscaping = true

    local playerCoords = GetEntityCoords(PlayerPedId())
    local customerCoords = GetEntityCoords(customer.ped)
    
    local direction = customerCoords - playerCoords
    direction = direction / #direction
    
    local escapeDistance = math.random(Config.DrugSales.CustomerEscape.escapeDistance.min, Config.DrugSales.CustomerEscape.escapeDistance.max)
    local escapePoint = customerCoords + (direction * escapeDistance)
    
    TaskGoToCoordAnyMeans(customer.ped, escapePoint.x, escapePoint.y, escapePoint.z, 1.0, 0, false, 786603, 0xbf800000)
    
    CreateThread(function()
        Wait(Config.DrugSales.CustomerEscape.escapeTime)
        
        if DoesEntityExist(customer.ped) then
            DeleteEntity(customer.ped)
        end
        
        if customer.blip then
            OrigenMapa.Quitar(customer.blip)
        end
        
        self:removeCustomerFromActive(customer)
    end)
end

function DrugSaleManager:isClosestCustomer(customer)
    if not Config.DrugSales.CustomerPriority.enabled then
        if not customer or not DoesEntityExist(customer.ped) then
            return false
        end
        
        local playerCoords = GetEntityCoords(PlayerPedId())
        local customerCoords = GetEntityCoords(customer.ped)
        local customerDistance = #(playerCoords - customerCoords)
        
        return customerDistance <= 3.0 and customer.hasReachedPlayer
    end
    
    if not customer or not DoesEntityExist(customer.ped) then
        return false
    end
    
    local playerCoords = GetEntityCoords(PlayerPedId())
    local customerCoords = GetEntityCoords(customer.ped)
    local customerDistance = #(playerCoords - customerCoords)
    
    if customerDistance > 3.0 then
        return false
    end
    
    if not customer.hasReachedPlayer then
        return false
    end
    
    for _, otherCustomer in ipairs(self.activeCustomers) do
        if otherCustomer.id ~= customer.id and DoesEntityExist(otherCustomer.ped) then
            local otherCoords = GetEntityCoords(otherCustomer.ped)
            local otherDistance = #(playerCoords - otherCoords)
            
            if otherDistance < customerDistance and otherCustomer.hasReachedPlayer and otherDistance <= 3.0 then
                return false
            end
            
            if Config.DrugSales.CustomerPriority.priorityByArrival then
                if math.abs(otherDistance - customerDistance) < Config.DrugSales.CustomerPriority.distanceThreshold and otherCustomer.hasReachedPlayer and otherDistance <= 3.0 then
                    if otherCustomer.id < customer.id then
                        return false
                    end
                end
            end
        end
    end
    
    return true
end

function DrugSaleManager:removeCustomerFromActive(customer)
    for i, activeCustomer in ipairs(self.activeCustomers) do
        if activeCustomer.id == customer.id then
            table.remove(self.activeCustomers, i)
            break
        end
    end
end

function DrugSaleManager:cleanupDeadCustomers()
    for i = #self.activeCustomers, 1, -1 do
        local customer = self.activeCustomers[i]
        if not DoesEntityExist(customer.ped) then
            if customer.blip then
                OrigenMapa.Quitar(customer.blip)
            end
            table.remove(self.activeCustomers, i)
        end
    end
end

function DrugSaleManager:cleanupCustomers()
    for _, customer in ipairs(self.activeCustomers) do
        if DoesEntityExist(customer.ped) then
            DeleteEntity(customer.ped)
        end
        
        if customer.blip then
            OrigenMapa.Quitar(customer.blip)
        end
    end
    
    self.activeCustomers = {}
    self.customers = {}
end

function DrugSaleManager:playPhoneAnimation()
    if not Config.DrugSales.Animations.phoneCall.enabled then
        return
    end
    
    local playerPed = PlayerPedId()
    
    RequestAnimDict("cellphone@")
    while not HasAnimDictLoaded("cellphone@") do
        Wait(1)
    end
    
    local phoneModel = GetHashKey(Config.DrugSales.Animations.phoneCall.phoneModel)
    RequestModel(phoneModel)
    while not HasModelLoaded(phoneModel) do
        Wait(1)
    end
    
    local phone = CreateObject(phoneModel, 0.0, 0.0, 0.0, true, true, true)
    AttachEntityToEntity(phone, playerPed, GetPedBoneIndex(playerPed, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    
    TaskPlayAnim(playerPed, "cellphone@", "cellphone_call_listen_base", 8.0, -8.0, -1, 49, 0, false, false, false)
    
    CreateThread(function()
        Wait(Config.DrugSales.Animations.phoneCall.duration)
        ClearPedTasks(playerPed)
        DeleteObject(phone)
        SetModelAsNoLongerNeeded(phoneModel)
    end)
end

function DrugSaleManager:playExchangeAnimation(customer)
    if not Config.DrugSales.Animations.exchange.enabled then
        return
    end
    
    local playerPed = PlayerPedId()
    
    if not customer or not DoesEntityExist(customer.ped) then
        return
    end
    
    RequestAnimDict("mp_common")
    RequestAnimDict("mp_ped_interaction")
    
    while not HasAnimDictLoaded("mp_common") or not HasAnimDictLoaded("mp_ped_interaction") do
        Wait(1)
    end
    
    TaskTurnPedToFaceEntity(playerPed, customer.ped, -1)
    TaskTurnPedToFaceEntity(customer.ped, playerPed, -1)
    
    Wait(1000)
    
    TaskPlayAnim(playerPed, "mp_common", Config.DrugSales.Animations.exchange.playerAnim, 8.0, -8.0, -1, 0, 0, false, false, false)
    TaskPlayAnim(customer.ped, "mp_common", Config.DrugSales.Animations.exchange.npcAnim, 8.0, -8.0, -1, 0, 0, false, false, false)
    
    CreateThread(function()
        Wait(Config.DrugSales.Animations.exchange.duration)
        ClearPedTasks(playerPed)
    end)
end

function DrugSaleManager:alertPolice(reason)
    local playerCoords = GetEntityCoords(PlayerPedId())
    TriggerServerEvent('origen_gang:drugSales:alertPolice', playerCoords, reason)
end

function DrugSaleManager:drawDebugMarkers()
    if not Config.DrugSales.Debug.enabled then
        return
    end
    
    if Config.DrugSales.Debug.showBlacklistedZones then
        for _, zone in pairs(Config.DrugSales.BlacklistedZones) do
            DrawMarker(
                Config.DrugSales.Debug.markerSettings.type,
                zone.coords.x, zone.coords.y, zone.coords.z - 1.0,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                zone.radius * 2, zone.radius * 2, 1000.0,
                Config.DrugSales.Debug.markerSettings.color.r,
                Config.DrugSales.Debug.markerSettings.color.g,
                Config.DrugSales.Debug.markerSettings.color.b,
                Config.DrugSales.Debug.markerSettings.color.a,
                false, true, 2, false, nil, nil, false
            )
            
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - zone.coords)
            if distance < zone.radius + 10.0 then
                self:DrawText3D(zone.coords.x, zone.coords.y, zone.coords.z + 2.0, zone.name)
            end
        end
    end
    
    if Config.DrugSales.Debug.showSaleRadius and self.isActive and self.startCoords then
        DrawMarker(
            Config.DrugSales.Debug.markerSettings.type,
            self.startCoords.x, self.startCoords.y, self.startCoords.z - 1.0,
            0.0, 0.0, 0.0,
            0.0, 0.0, 0.0,
            Config.DrugSales.SaleRadius * 2, Config.DrugSales.SaleRadius * 2, 1000.0,
            Config.DrugSales.Debug.markerSettings.colorSaleRadius.r,
            Config.DrugSales.Debug.markerSettings.colorSaleRadius.g,
            Config.DrugSales.Debug.markerSettings.colorSaleRadius.b,
            Config.DrugSales.Debug.markerSettings.colorSaleRadius.a,
            false, true, 2, false, nil, nil, false
        )
    end
end

function DrugSaleManager:getRandomMessage(type)
    if not Config.DrugSales.Messages or not Config.DrugSales.Messages[type] then
        return nil
    end
    
    local messages = locale:t(Config.DrugSales.Messages[type])
    return messages[math.random(1, #messages)]
end

function DrugSaleManager:showCustomerMessage(customer, message, duration)
    if not message or not customer then return end
    
    duration = duration or 3000
    
    if DoesEntityExist(customer.ped) then
        CreateThread(function()
            local startTime = GetGameTimer()
            
            while (GetGameTimer() - startTime) < duration and customer and DoesEntityExist(customer.ped) do
                local coords = GetEntityCoords(customer.ped)
                self:DrawText3D(coords.x, coords.y, coords.z + 1.5, message)
                Wait(0)
            end
        end)
    end
end

-- El bocadillo sobre el cliente, en pegatina (client/functions/f_utils.lua).
function DrugSaleManager:DrawText3D(x, y, z, text)
    BocadilloPegatina(x, y, z, text)
end

local saleManager = DrugSaleManager:new()

-- El comando /startsell ya no funciona directamente:
-- debe usarse la opción del menú rápido (nivel >= 90 requerido)
RegisterCommand(Config.DrugSales.Commands.StartSell, function()
    local level = (_G.StreetSaleManager and _G.StreetSaleManager.cachedLevel) or 0
    if level < 90 then
        Notify.SendNotify(locale:t('notify.drug_sale_need_reputation_90', level), 'error')
        return
    end
    local playerPed = PlayerPedId()
    if IsPedDeadOrDying(playerPed, true) then
        Notify.SendNotify(locale:t('notify.drug_sale_cannot_dead'), 'error')
        return
    end
    saleManager:startSale()
end, false)

RegisterCommand(Config.DrugSales.Commands.StopSell, function()
    saleManager:stopSale()
end, false)

-- Toggle desde el menú rápido
AddEventHandler('origen_gang:client:toggleZoneSale', function()
    if saleManager.isActive then
        saleManager:stopSale()
        if _G.StreetSaleManager then _G.StreetSaleManager.zoneActive = false end
    else
        local level = (_G.StreetSaleManager and _G.StreetSaleManager.cachedLevel) or 0
        if level < 90 then
            Notify.SendNotify(locale:t('notify.drug_sale_need_reputation_90', level), 'error')
            return
        end
        local started = saleManager:startSale()
        if started and _G.StreetSaleManager then
            _G.StreetSaleManager.zoneActive = true
        end
    end
end)

-- Forzar parada cuando el nivel baja de 90
AddEventHandler('origen_gang:client:forceStopZoneSale', function()
    if saleManager.isActive then
        saleManager:stopSale()
    end
end)

CreateThread(function()
    while true do
        if Config.DrugSales.Debug.enabled then
            saleManager:drawDebugMarkers()
            Wait(0)
        else
            Wait(1000)
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        saleManager:cleanupCustomers()
    end
end)
