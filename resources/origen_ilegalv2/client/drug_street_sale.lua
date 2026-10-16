if not Config.DrugSales or not Config.DrugSales.Enable or not Config.DrugSales.StreetSale or not Config.DrugSales.StreetSale.Enable then
    return
end

local StreetSaleManager = {
    lastSaleTime   = 0,
    cooldownActive = false,
    usedPeds       = {},
    saleInProgress = false,  -- guard contra ventas simultáneas
    cachedLevel    = 0,      -- nivel 0-100 cacheado del servidor
    zoneActive     = false   -- espejo del isActive del sistema startsell
}

local function syncDrugListFromServer()
    local list = lib.callback.await('origen_gang:drugSales:getDrugList', false)
    if type(list) == 'table' then
        Config.DrugSales = Config.DrugSales or {}
        Config.DrugSales.DrugList = list
        return true
    end
    return false
end

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

function StreetSaleManager:isInCooldown()
    return self.cooldownActive
end

function StreetSaleManager:startCooldown()
    self.cooldownActive = true
    SetTimeout(Config.DrugSales.StreetSale.CooldownTime, function()
        self.cooldownActive = false
    end)
end

function StreetSaleManager:isValidPed(ped)
    if not DoesEntityExist(ped) then
        return false
    end

    if Config.DrugSales.StreetSale.IgnoreDeadPeds and (IsPedDeadOrDying(ped, true) or IsPedFatallyInjured(ped)) then
        return false
    end

    if Config.DrugSales.StreetSale.ExcludePlayerPeds and IsPedAPlayer(ped) then
        return false
    end

    if Config.DrugSales.StreetSale.OnlyPeds and not IsPedHuman(ped) then
        return false
    end

    if self.usedPeds[ped] then
        return false
    end

    return true
end

function StreetSaleManager:findNearestPed()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local nearestPed = nil
    local nearestDistance = Config.DrugSales.StreetSale.MaxDistance

    local peds = GetGamePool('CPed')
    
    for i = 1, #peds do
        local ped = peds[i]
        
        if ped ~= playerPed and self:isValidPed(ped) then
            local pedCoords = GetEntityCoords(ped)
            local distance = #(playerCoords - pedCoords)
            
            if distance < nearestDistance then
                nearestDistance = distance
                nearestPed = ped
            end
        end
    end

    return nearestPed, nearestDistance
end

function StreetSaleManager:isInBlacklistedZone(coords)
    for _, zone in pairs(Config.DrugSales.BlacklistedZones) do
        local distance = #(coords - zone.coords)
        if distance < zone.radius then
            return true
        end
    end
    return false
end

function StreetSaleManager:attemptSale(drugName)
    if self.saleInProgress then
        return false
    end
    -- Otro panel de este recurso delante: la tarjeta se abriria encima y el
    -- jugador quedaria congelado con un panel sin raton (ver drug_sales.lua).
    if OrigenFoco and OrigenFoco.Tiene() then
        return false
    end
    if self:isInCooldown() then
        Notify.SendNotify(locale:t('notify.must_wait_to_sell'), 'error')
        return false
    end
    self.saleInProgress = true

    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    local function abort(msg)
        self.saleInProgress = false
        FreezeEntityPosition(playerPed, false)
        if msg then Notify.SendNotify(msg, 'error') end
    end

    if IsPedDeadOrDying(playerPed, true) then
        abort(locale:t('notify.drug_sale_cannot_dead')) return false
    end

    if IsPedInAnyVehicle(playerPed, false) then
        abort(locale:t('notify.cannot_sell_from_vehicle')) return false
    end

    if self:isInBlacklistedZone(playerCoords) then
        abort(locale:t('notify.drug_sale_blacklisted_zone')) return false
    end

    local policeCount = lib.callback.await('origen_gang:drugSales:getPoliceCount', false)
    if policeCount < Config.DrugSales.CopRequired then
        abort(locale:t('notify.drug_sale_not_enough_police', policeCount, Config.DrugSales.CopRequired)) return false
    end

    local drugConfig = Config.DrugSales.DrugList[drugName]
    if not drugConfig then
        abort(locale:t('server.invalid_drug')) return false
    end

    local itemCount = GetPlayerItemCount(drugName)
    if not itemCount or itemCount <= 0 then
        abort(locale:t('notify.drug_sale_no_drugs')) return false
    end

    local nearestPed, distance = self:findNearestPed()
    if not nearestPed then
        abort(locale:t('notify.no_players_nearby')) return false
    end

    -- Leer nivel de venta (0–100) y calcular multiplicadores dinámicos
    local streetLevel = lib.callback.await('origen_gang:drugSales:getStreetLevel', false)
    streetLevel = math.max(0, math.min(100, streetLevel or 0))
    local t = streetLevel / 100.0   -- 0.0 (sin nivel) → 1.0 (máximo)

    -- Rechazo: 80% a nivel 0, 20% a nivel 100 — override por droga si está configurado
    local rejectChance  = drugConfig.rejectChance ~= nil and drugConfig.rejectChance or math.floor(80 - t * 60)
    -- Policía: 70% a nivel 0, 20% a nivel 100 — override por droga si está configurado
    local policeChance  = drugConfig.policeChance ~= nil and drugConfig.policeChance or math.floor(70 - t * 50)
    -- Cantidad: mínimo al 30% del rango a nivel 0, 100% a nivel 100
    local qtyMultiplier = 0.3 + t * 0.7
    -- Precio: 50% del precio base a nivel 0, 100% a nivel 100
    local priceMultiplier = (0.5 + t * 0.5) * (Config.DrugSales.StreetSale.PriceMultiplier or 1.0)

    -- Parar al jugador antes de calcular posiciones
    FreezeEntityPosition(playerPed, true)
    Wait(100)
    -- Recalcular coordenadas ya parado
    playerCoords = GetEntityCoords(playerPed)

    -- Cantidad: siempre 1 a nivel 0, escala hasta el máximo configurado a nivel 100
    local qtyMax = 1 + math.floor((drugConfig.quantity.max - 1) * t)
    qtyMax = math.max(1, math.min(drugConfig.quantity.max, qtyMax))
    -- Desde el minimo de la droga: el servidor rechaza la venta por debajo.
    local qtyMin = math.max(1, math.min(tonumber(drugConfig.quantity.min) or 1, qtyMax))
    local quantity = math.random(qtyMin, qtyMax)
    quantity = math.min(quantity, itemCount)

    local territoryType = lib.callback.await('origen_gang:drugSales:getTerritoryType', false)
    local minPrice = drugConfig.price.min
    local maxPrice = drugConfig.price.max
    local pricePerUnit = minPrice

    if territoryType == 'own' then
        local p1 = math.random(minPrice, maxPrice)
        local p2 = math.random(minPrice, maxPrice)
        pricePerUnit = math.max(p1, p2)
    elseif territoryType == 'enemy' then
        local p1 = math.random(minPrice, maxPrice)
        local p2 = math.random(minPrice, maxPrice)
        pricePerUnit = math.min(p1, p2)
    else
        pricePerUnit = math.random(minPrice, maxPrice)
    end
    
    pricePerUnit = math.floor(pricePerUnit)
    local totalPrice = pricePerUnit * quantity

    -- Rechazo escalado por nivel
    if math.random(1, 100) <= rejectChance then
        local rejectedMessages = locale:t(Config.DrugSales.Messages.rejected)
        self:showPedMessage(nearestPed, rejectedMessages[math.random(1, #rejectedMessages)], 3000)
        Notify.SendNotify(locale:t('notify.customer_rejected_police'), 'error')
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
        -- Animación de teléfono antes de irse
        local phoneCfg = Config.DrugSales.Animations and Config.DrugSales.Animations.phoneCall
        if phoneCfg and phoneCfg.enabled then
            CreateThread(function()
                local dict = "cellphone@"
                RequestAnimDict(dict)
                local t = 0
                while not HasAnimDictLoaded(dict) and t < 2000 do Wait(50) t = t + 50 end
                if not HasAnimDictLoaded(dict) then
                    StreetSaleManager:makePedWalkAway(nearestPed)
                    return
                end
                -- Spawn prop teléfono en la mano del NPC
                local phoneModel = GetHashKey(phoneCfg.phoneModel or "prop_npc_phone_02")
                RequestModel(phoneModel)
                local pt = 0
                while not HasModelLoaded(phoneModel) and pt < 2000 do Wait(50) pt = pt + 50 end

                local phoneProp = nil
                if HasModelLoaded(phoneModel) then
                    phoneProp = CreateObject(phoneModel, 0, 0, 0, true, true, false)
                    AttachEntityToEntity(phoneProp, nearestPed, GetPedBoneIndex(nearestPed, 28422), -- bone "PH_R_Hand"
                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
                end

                SetBlockingOfNonTemporaryEvents(nearestPed, true)
                TaskPlayAnim(nearestPed, dict, "cellphone_call_listen_base", 8.0, -8.0, phoneCfg.duration, 49, 0, false, false, false)

                Wait(phoneCfg.duration)

                if DoesEntityExist(phoneProp) then DeleteObject(phoneProp) end
                ClearPedTasks(nearestPed)
                SetBlockingOfNonTemporaryEvents(nearestPed, false)
                StreetSaleManager:makePedWalkAway(nearestPed)
            end)
        else
            self:makePedWalkAway(nearestPed)
        end
        abort(nil) return false
    end

    -- Heading de llegada: NPC llega ya mirando al jugador
    local playerHeading  = GetEntityHeading(playerPed)
    local arrivalHeading = (playerHeading + 180.0) % 360.0

    -- Punto destino: exactamente donde estará durante la animación (mismo offset)
    local destPos = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 1.1, 0.0)

    -- Bloquear IA del NPC para que no reaccione a estímulos externos
    SetBlockingOfNonTemporaryEvents(nearestPed, true)

    -- Caminar al punto con heading de llegada ya correcto (TaskGoStraightToCoord)
    local pedDist = #(GetEntityCoords(nearestPed) - destPos)
    if pedDist > 0.5 then
        if pedDist > 2.5 then
            Notify.SendNotify(locale:t('notify.customer_approaching'), 'info')
        end
        -- distToSlide 0.0 = parada exacta en el punto, sin corrección posterior
        TaskGoStraightToCoord(nearestPed, destPos.x, destPos.y, destPos.z, 1.0, 15000, arrivalHeading, 0.0)

        -- Animación idle del jugador mientras espera: nervioso (/e nervous)
        local idleDict = "amb@world_human_bum_standing@twitchy@idle_a"
        local idleAnim = "idle_c"
        RequestAnimDict(idleDict)
        local idleLoaded = 0
        while not HasAnimDictLoaded(idleDict) and idleLoaded < 1000 do
            Wait(50) idleLoaded = idleLoaded + 50
        end
        if HasAnimDictLoaded(idleDict) then
            -- flag 1 = loop, flag 48 = upper body blend para que los pies sigan en sitio
            TaskPlayAnim(playerPed, idleDict, idleAnim, 2.0, -2.0, -1, 1, 0, false, false, false)
        end

        local timeout, elapsed = 12000, 0
        while elapsed < timeout do
            if not DoesEntityExist(nearestPed) then
                SetBlockingOfNonTemporaryEvents(nearestPed, false)
                abort(locale:t('notify.drug_sale_customer_left')) return false
            end
            -- Detectar llegada con margen amplio para cortar la tarea antes de que el motor intente corregir
            if #(GetEntityCoords(nearestPed) - destPos) <= 0.6 then break end
            Wait(100)
            elapsed = elapsed + 100
        end

        if elapsed >= timeout then
            SetBlockingOfNonTemporaryEvents(nearestPed, false)
            ClearPedTasks(nearestPed)
            abort('El cliente no pudo acercarse') return false
        end
    end

    -- Cortar tarea + snap al punto exacto
    ClearPedTasksImmediately(nearestPed)
    SetEntityCoordsNoOffset(nearestPed, destPos.x, destPos.y, destPos.z, false, false, false)
    SetEntityHeading(nearestPed, arrivalHeading)

    -- Parar la animación idle del jugador
    ClearPedTasks(playerPed)
    SetEntityHeading(playerPed, playerHeading)

    -- TaskStandStill hace blend de caminar → idle; esperamos a que la transición termine
    TaskStandStill(nearestPed, 60000)
    Wait(400)

    -- Ahora el NPC está en pose idle: congelamos posición para que no se mueva nada
    FreezeEntityPosition(nearestPed, true)

    -- Guardar datos de la venta pendiente
    StreetSaleManager.pendingSale = {
        drugName     = drugName,
        quantity     = quantity,
        pricePerUnit = pricePerUnit,
        totalPrice   = totalPrice,
        nearestPed   = nearestPed,
        playerPed    = playerPed,
        playerCoords = playerCoords,
        policeChance = policeChance,
        streetLevel  = streetLevel
    }
    StreetSaleManager.pendingSaleToken = GetGameTimer()

    -- Failsafe: si el menú se cierra sin seleccionar opción, soltamos freeze.
    local saleToken = StreetSaleManager.pendingSaleToken
    CreateThread(function()
        Wait(45000)
        if StreetSaleManager.pendingSale and StreetSaleManager.pendingSaleToken == saleToken then
            StreetSaleManager:forceReleasePendingSale(true, locale:t('notify.drug_sale_cancelled'))
        end
    end)

    OpenEmbeddedQuickMenu({
        {
            header = 'Venta callejera — ' .. ((Config.DrugSales.DrugList[drugName] and Config.DrugSales.DrugList[drugName].label) or drugName),
            txt = string.format('Reputación callejera: %d/100', math.floor(streetLevel)),
            isMenuHeader = true,
            icon = 'fa-solid fa-syringe'
        },
        {
            header = 'Vender',
            txt = string.format('%dx unidad(es)  •  $%d c/u  •  Total: $%d', quantity, math.floor(pricePerUnit), math.floor(totalPrice)),
            icon = 'fa-solid fa-hand-holding-dollar',
            params = {
                event = 'origen_gang:streetSale:confirm',
                args  = {}
            }
        },
        {
            header = 'Cancelar',
            txt = 'No vender',
            icon = 'fa-solid fa-xmark',
            params = {
                event = 'origen_gang:streetSale:cancel',
                args  = {}
            }
        }
    })

    return true
end

function StreetSaleManager:makePedWalkAway(ped)
    if not DoesEntityExist(ped) then
        return
    end

    local pedCoords = GetEntityCoords(ped)
    local angle = math.random(0, 360) * math.pi / 180
    local distance = math.random(20, 40)
    local x = pedCoords.x + math.cos(angle) * distance
    local y = pedCoords.y + math.sin(angle) * distance
    local z = pedCoords.z
    
    TaskGoToCoordAnyMeans(ped, x, y, z, 1.0, 0, false, 786603, 0xbf800000)
end

function StreetSaleManager:showPedMessage(ped, message, duration)
    if not message or not DoesEntityExist(ped) then return end
    
    duration = duration or 3000
    
    CreateThread(function()
        local startTime = GetGameTimer()
        
        while (GetGameTimer() - startTime) < duration and DoesEntityExist(ped) do
            local coords = GetEntityCoords(ped)
            self:DrawText3D(coords.x, coords.y, coords.z + 1.0, message)
            Wait(0)
        end
    end)
end

-- El bocadillo sobre el cliente, en pegatina (client/functions/f_utils.lua).
function StreetSaleManager:DrawText3D(x, y, z, text)
    BocadilloPegatina(x, y, z, text)
end

function StreetSaleManager:forceReleasePendingSale(shouldWalkAway, notifyMsg)
    local sale = self.pendingSale
    self.pendingSale = nil
    self.pendingSaleToken = nil
    self.saleInProgress = false

    local currentPed = PlayerPedId()
    if DoesEntityExist(currentPed) then
        FreezeEntityPosition(currentPed, false)
        ClearPedTasks(currentPed)
    end

    if sale and sale.playerPed and DoesEntityExist(sale.playerPed) then
        FreezeEntityPosition(sale.playerPed, false)
        ClearPedTasks(sale.playerPed)
    end

    if sale and sale.nearestPed and DoesEntityExist(sale.nearestPed) then
        FreezeEntityPosition(sale.nearestPed, false)
        SetBlockingOfNonTemporaryEvents(sale.nearestPed, false)
        ClearPedTasks(sale.nearestPed)
        if shouldWalkAway then
            if sale.onDone then
                sale.onDone()
            else
                self:makePedWalkAway(sale.nearestPed)
            end
        end
    end

    if notifyMsg and notifyMsg ~= '' then
        Notify.SendNotify(notifyMsg, 'error')
    end
end

_G.StreetSaleManager = StreetSaleManager

exports('SellDrugToNearestPed', function(drugName)
    CreateThread(function()
        StreetSaleManager:attemptSale(drugName)
    end)
end)

local function openDrugUseMenu(drugName, drugConfig, forSale, forConsumption)
    local itemImage = (drugConfig.image and drugConfig.image ~= '') and drugConfig.image or nil
    local menu = {
        {
            header       = drugConfig.label or drugName,
            txt          = '¿Qué quieres hacer con este objeto?',
            isMenuHeader = true,
            icon         = itemImage,
        }
    }

    if forSale then
        menu[#menu + 1] = {
            header = 'Vender',
            txt    = 'Intentar vender a un NPC cercano',
            icon   = 'fa-solid fa-hand-holding-dollar',
            params = { event = 'origen_gang:drugs:menuVender', args = { name = drugName } }
        }
    end

    if forConsumption then
        menu[#menu + 1] = {
            header = 'Consumir',
            txt    = 'Aplicar el efecto configurado para esta droga',
            icon   = 'fa-solid fa-flask',
            params = { event = 'origen_gang:drugs:menuConsumir', args = { name = drugName } }
        }
    end

    OpenEmbeddedQuickMenu(menu)
end

RegisterNetEvent('origen_gang:drugSales:useDrug', function(drugName)
    if not drugName then return end

    -- Si la droga no está en el config del cliente todavía (p. ej. se conectó antes
    -- de que el admin la creara en caliente), forzamos sync y reintentamos lookup.
    if not Config.DrugSales.DrugList[drugName] then
        syncDrugListFromServer()
    end

    if not Config.DrugSales.DrugList[drugName] then
        Notify.SendNotify(locale:t('notify.drug_not_recognized'), 'error')
        return
    end

    local drugConfig     = Config.DrugSales.DrugList[drugName]
    -- Defaults de compatibilidad para drogas estáticas del config
    local forSale        = drugConfig.forSale ~= false
    local forConsumption = drugConfig.forConsumption ~= nil and drugConfig.forConsumption or false

    -- Comportamiento unificado: al usar item siempre abrir menú de decisión.
    if not forSale and not forConsumption then
        Notify.SendNotify(locale:t('notify.drug_not_recognized'), 'error')
        return
    end

    openDrugUseMenu(drugName, drugConfig, forSale, forConsumption)
end)

RegisterNetEvent('origen_gang:drugs:menuVender', function(data)
    local name = (type(data) == 'table' and data.name) or (type(data) == 'string' and data) or nil
    if not name then return end
    CreateThread(function()
        StreetSaleManager:attemptSale(name)
    end)
end)

RegisterNetEvent('origen_gang:drugs:menuConsumir', function(data)
    local name = (type(data) == 'table' and data.name) or (type(data) == 'string' and data) or nil
    if not name then return end
    consumeDrug(name)
end)

RegisterNetEvent('origen_gang:drugs:menuCancelar', function()
end)

-- Confirmación de venta desde el menú interno
RegisterNetEvent('origen_gang:streetSale:confirm', function()
    local sale = StreetSaleManager.pendingSale
    if not sale then return end
    StreetSaleManager.pendingSale = nil
    StreetSaleManager.pendingSaleToken = nil

    local playerPed  = sale.playerPed
    local nearestPed = sale.nearestPed

    StreetSaleManager:startCooldown()

    -- Barra de progreso: 5 s de espera antes del intercambio (da tiempo a la policía)
    ProgressBar.Open({ duration = 5000, label = locale:t('notify.drug_sale_progress'), canCancel = false })
    Wait(5000)

    if Config.DrugSales.Animations.exchange.enabled then
        local animDict = Config.DrugSales.Animations.exchange.dict or "mp_common"
        lib.requestAnimDict(animDict)

        -- Prop de la droga en la mano derecha del jugador
        local drugProp   = nil
        local drugCfg    = Config.DrugSales.DrugList[sale.drugName]
        local propName   = drugCfg and drugCfg.prop
        if propName then
            local propHash = GetHashKey(propName)
            RequestModel(propHash)
            local propWait = 0
            while not HasModelLoaded(propHash) and propWait < 2000 do
                Wait(50) propWait = propWait + 50
            end
            if HasModelLoaded(propHash) then
                drugProp = CreateObject(propHash, 0.0, 0.0, 0.0, true, true, false)
                -- Bone 28422 = PH_R_Hand (mano derecha, pensado para props)
                AttachEntityToEntity(
                    drugProp, playerPed, GetPedBoneIndex(playerPed, 28422),
                    0.0, 0.05, 0.0,   -- offset: ligeramente hacia adelante en la palma
                    0.0, 0.0, 0.0,    -- rotación: ajustar si hace falta
                    true, true, false, true, 1, true
                )
                SetModelAsNoLongerNeeded(propHash)
            end
        end

        local duration = Config.DrugSales.Animations.exchange.duration

        -- El NPC ya está en la posición y heading exactos gracias al snap+freeze.
        -- Soltar freeze y arrancar ambas anims desde donde están: sin reposicionamiento, sin salto.
        FreezeEntityPosition(nearestPed, false)

        TaskPlayAnim(
            nearestPed, animDict, Config.DrugSales.Animations.exchange.npcAnim,
            8.0, -8.0, duration, 0, 0, false, false, false
        )
        TaskPlayAnim(
            playerPed, animDict, Config.DrugSales.Animations.exchange.playerAnim,
            8.0, -8.0, duration, 0, 0, false, false, false
        )

        -- Primera mitad: el jugador tiene la droga en la mano
        Wait(duration / 2)

        -- Transferir prop al NPC en el punto del intercambio
        -- Bone 60309 = SKEL_L_Hand (mano izquierda del NPC, la que extiende en givetake1_b)
        if DoesEntityExist(drugProp) then
            DetachEntity(drugProp, false, false)
            AttachEntityToEntity(
                drugProp, nearestPed, GetPedBoneIndex(nearestPed, 28422),
                0.0, 0.05, 0.0,
                0.0, 0.0, 0.0,
                true, true, false, true, 1, true
            )
        end

        -- Segunda mitad: el NPC ya tiene la droga
        Wait(duration / 2)
        ClearPedTasks(playerPed)

        -- Guardar referencia del prop para borrarlo cuando el NPC se vaya
        sale.drugProp = drugProp
    end

    lib.callback('origen_gang:drugSales:processSale', false, function(success, message)
        if success then
            local acceptedMessages = locale:t(Config.DrugSales.Messages.accepted)
            StreetSaleManager:showPedMessage(nearestPed, acceptedMessages[math.random(1, #acceptedMessages)], 3000)
            Notify.SendNotify(string.format('Venta exitosa! Ganaste $%d (%dx $%d)', sale.totalPrice, sale.quantity, sale.pricePerUnit), 'success')

            if Config.DrugSales.PoliceAlerts.onAccept.enabled and math.random(1, 100) <= (sale.policeChance or Config.DrugSales.PoliceAlerts.onAccept.percentage) then
                local vehData = nil
                local lastVeh = GetVehiclePedIsIn(PlayerPedId(), true)
                if lastVeh and lastVeh ~= 0 and DoesEntityExist(lastVeh) and #(sale.playerCoords - GetEntityCoords(lastVeh)) < 15.0 then
                    vehData = lastVeh
                end
                Dispatch.SendAlert({
                    coords         = sale.playerCoords,
                    title          = locale:t('notify.drug_sale_accept_alert_title') or locale:t('notify.police_alert_title'),
                    message        = locale:t('notify.drug_sale_accept_alert_message'),
                    type           = 'DRUGS',
                    jobs           = {'police', 'sheriff', 'fib'},
                    ignoreCooldown = true,
                    vehicle        = vehData,
                })
            end

            StreetSaleManager.usedPeds[nearestPed] = true
        else
            Notify.SendNotify(message or 'Error en la venta', 'error')
        end

        -- Borrar prop de la mano del NPC justo antes de que se vaya
        if DoesEntityExist(sale.drugProp) then
            DeleteObject(sale.drugProp)
            sale.drugProp = nil
        end
        StreetSaleManager.saleInProgress = false
        FreezeEntityPosition(playerPed, false)
        ClearPedTasks(playerPed)
        SetBlockingOfNonTemporaryEvents(nearestPed, false)
        ClearPedTasks(nearestPed)
        if sale.onDone then sale.onDone() else StreetSaleManager:makePedWalkAway(nearestPed) end
    end, sale.drugName, sale.quantity, sale.totalPrice)
end)

-- Cancelación desde el menú interno
RegisterNetEvent('origen_gang:streetSale:cancel', function()
    if not StreetSaleManager.pendingSale then return end
    StreetSaleManager:forceReleasePendingSale(true)
end)

-- Si se cierra el menú por fuera (sin opción), limpiar una venta pendiente.
AddEventHandler('origen_gang:quickMenu:closed', function()
    if StreetSaleManager and StreetSaleManager.pendingSale then
        -- Flujo "como el antiguo": cerrar fuera equivale a pulsar Cancelar.
        TriggerEvent('origen_gang:streetSale:cancel')
    end
end)

-- Sincronización silenciosa del nivel tras cada venta
RegisterNetEvent('origen_gang:drugSales:levelSync', function(newLevel)
    StreetSaleManager.cachedLevel = math.max(0, math.min(100, newLevel))
end)

-- Notificación y cache al subir de nivel
RegisterNetEvent('origen_gang:drugSales:levelUp', function(newLevel)
    StreetSaleManager.cachedLevel = newLevel
    Notify.SendNotify(locale:t('notify.drug_street_rep_improved', newLevel), 'success')
end)

-- Notificación y cache al bajar por inactividad
RegisterNetEvent('origen_gang:drugSales:levelDecay', function(newLevel)
    StreetSaleManager.cachedLevel = newLevel
    -- Si baja de 90 y la zona estaba activa, la paramos
    if newLevel < 90 and StreetSaleManager.zoneActive then
        StreetSaleManager.zoneActive = false
        TriggerEvent('origen_gang:client:forceStopZoneSale')
        Notify.SendNotify(locale:t('notify.reputation_lost_zone_off'), 'error')
    else
        Notify.SendNotify(locale:t('notify.reputation_decaying', newLevel), 'error')
    end
end)

-- La venta en zona del menú rápido la atiende drug_sales.lua. Aquí había un
-- manejador que volvía a lanzar el mismo evento desde dentro: se llamaba a sí
-- mismo sin fin.

-- Inicializar nivel al arrancar
CreateThread(function()
    Wait(2000)  -- esperar a que la conexión esté lista
    syncDrugListFromServer()
    local level = lib.callback.await('origen_gang:drugSales:getStreetLevel', false)
    StreetSaleManager.cachedLevel = math.max(0, math.min(100, level or 0))
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    CreateThread(function()
        Wait(1000)
        syncDrugListFromServer()
    end)
end)

AddEventHandler('origen:Client:OnPlayerLoaded', function()
    CreateThread(function()
        Wait(1200)
        syncDrugListFromServer()
    end)
end)

-- Limpiar usedPeds solo cuando el NPC ya no exista en el mundo (evita revender al mismo NPC)
CreateThread(function()
    while true do
        Wait(5000)
        for ped, _ in pairs(StreetSaleManager.usedPeds) do
            if not DoesEntityExist(ped) then
                StreetSaleManager.usedPeds[ped] = nil
            end
        end
    end
end)
